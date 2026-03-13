#!/usr/bin/env bash
# postgres-mcp-wrapper.sh
# Infers DB credentials from project config files and launches postgres-mcp.
#
# Search priority (first match wins):
#   1. .env                    — DATABASE_URI / DATABASE_URL / BBDD_* keys
#   2. gradle.properties       — bbdd.sid, bbdd.port, bbdd.user, bbdd.password
#   3. config/Openbravo.properties — bbdd.url, bbdd.sid, bbdd.user, bbdd.password
#   4. Openbravo.properties    — same as above
#
# Falls back to DATABASE_URI env var if no config file is found.
#
# Usage:
#   postgres-mcp-wrapper.sh                          # uses CWD or PROJECT_DIR env
#   PROJECT_DIR=/path/to/project postgres-mcp-wrapper.sh  # explicit project dir

set -euo pipefail

# ── Resolve project directory ────────────────────────────────────────────────

SEARCH_DIR="${PROJECT_DIR:-$PWD}"

# ── Helpers ──────────────────────────────────────────────────────────────────

die() { echo "[postgres-mcp-wrapper] ERROR: $*" >&2; exit 1; }
log() { echo "[postgres-mcp-wrapper] $*" >&2; }

# Read a key from a .properties file (handles = and spaces)
read_prop() {
  local file="$1" key="$2"
  grep -m1 "^${key}=" "$file" 2>/dev/null | sed "s/^${key}=\s*//" | tr -d '\r'
}

# Read a key from a .env file (handles quotes and exports)
read_env() {
  local file="$1" key="$2"
  grep -m1 "^\(export \)\?${key}=" "$file" 2>/dev/null \
    | sed "s/^\(export \)\?${key}=\s*//" \
    | sed "s/^[\"']//" | sed "s/[\"']$//" \
    | tr -d '\r'
}

# Extract host and port from JDBC URL: jdbc:postgresql://host\:port or host:port
parse_jdbc_url() {
  local url="$1"
  # Remove jdbc:postgresql:// prefix
  url="${url#jdbc:postgresql://}"
  # Remove backslash escapes (Openbravo uses \: for port separator)
  url="${url//\\:/\:}"
  # Split host:port
  JDBC_HOST="${url%%:*}"
  JDBC_PORT="${url##*:}"
  # Clean trailing slashes or db names
  JDBC_HOST="${JDBC_HOST%%/*}"
  JDBC_PORT="${JDBC_PORT%%/*}"
}

# ── Search for config files (walk up from CWD) ──────────────────────────────

find_config() {
  local dir="$SEARCH_DIR"
  while [[ "$dir" != "/" ]]; do
    # Priority 1: .env
    if [[ -f "$dir/.env" ]]; then
      CONFIG_TYPE="env"
      CONFIG_FILE="$dir/.env"
      return 0
    fi
    # Priority 2: gradle.properties
    if [[ -f "$dir/gradle.properties" ]]; then
      CONFIG_TYPE="gradle"
      CONFIG_FILE="$dir/gradle.properties"
      return 0
    fi
    # Priority 3: config/Openbravo.properties
    if [[ -f "$dir/config/Openbravo.properties" ]]; then
      CONFIG_TYPE="openbravo"
      CONFIG_FILE="$dir/config/Openbravo.properties"
      return 0
    fi
    # Priority 4: Openbravo.properties (root)
    if [[ -f "$dir/Openbravo.properties" ]]; then
      CONFIG_TYPE="openbravo"
      CONFIG_FILE="$dir/Openbravo.properties"
      return 0
    fi
    dir="$(dirname "$dir")"
  done
  return 1
}

# ── Parse credentials from config file ───────────────────────────────────────

DB_HOST="localhost"
DB_PORT="5432"
DB_NAME=""
DB_USER=""
DB_PASS=""

parse_env_file() {
  local file="$1"

  # Check for a full connection string first
  local uri
  uri=$(read_env "$file" "DATABASE_URI")
  [[ -z "$uri" ]] && uri=$(read_env "$file" "DATABASE_URL")
  if [[ -n "$uri" ]]; then
    DATABASE_URI="$uri"
    return 0
  fi

  # Etendo Docker .env format (BBDD_* keys)
  DB_USER=$(read_env "$file" "BBDD_USER")
  DB_PASS=$(read_env "$file" "BBDD_PASSWORD")
  DB_NAME=$(read_env "$file" "BBDD_SID")
  DB_PORT=$(read_env "$file" "BBDD_PORT")

  local bbdd_url
  bbdd_url=$(read_env "$file" "BBDD_URL")
  if [[ -n "$bbdd_url" ]]; then
    parse_jdbc_url "$bbdd_url"
    DB_HOST="${JDBC_HOST:-localhost}"
    [[ -z "$DB_PORT" ]] && DB_PORT="${JDBC_PORT:-5432}"
  fi

  # Fallback: generic DB_HOST / DB_PORT / DB_NAME / DB_USER / DB_PASSWORD
  [[ -z "$DB_HOST" || "$DB_HOST" == "localhost" ]] && {
    local h; h=$(read_env "$file" "DB_HOST"); [[ -n "$h" ]] && DB_HOST="$h"
  }
  [[ -z "$DB_PORT" || "$DB_PORT" == "5432" ]] && {
    local p; p=$(read_env "$file" "DB_PORT"); [[ -n "$p" ]] && DB_PORT="$p"
  }
  [[ -z "$DB_NAME" ]] && DB_NAME=$(read_env "$file" "DB_NAME")
  [[ -z "$DB_USER" ]] && DB_USER=$(read_env "$file" "DB_USER")
  [[ -z "$DB_PASS" ]] && DB_PASS=$(read_env "$file" "DB_PASSWORD")

  [[ -n "$DB_NAME" && -n "$DB_USER" ]] && return 0
  return 1
}

parse_gradle_file() {
  local file="$1"
  DB_NAME=$(read_prop "$file" "bbdd.sid")
  DB_PORT=$(read_prop "$file" "bbdd.port")
  DB_USER=$(read_prop "$file" "bbdd.user")
  DB_PASS=$(read_prop "$file" "bbdd.password")
  # gradle.properties doesn't usually have host — default to localhost
  DB_HOST="localhost"
  [[ -z "$DB_PORT" ]] && DB_PORT="5432"

  [[ -n "$DB_NAME" && -n "$DB_USER" ]] && return 0
  return 1
}

parse_openbravo_file() {
  local file="$1"
  DB_NAME=$(read_prop "$file" "bbdd.sid")
  DB_USER=$(read_prop "$file" "bbdd.user")
  DB_PASS=$(read_prop "$file" "bbdd.password")

  local bbdd_url
  bbdd_url=$(read_prop "$file" "bbdd.url")
  if [[ -n "$bbdd_url" ]]; then
    parse_jdbc_url "$bbdd_url"
    DB_HOST="${JDBC_HOST:-localhost}"
    DB_PORT="${JDBC_PORT:-5432}"
  else
    DB_HOST="localhost"
    DB_PORT="5432"
  fi

  [[ -n "$DB_NAME" && -n "$DB_USER" ]] && return 0
  return 1
}

# ── Build DATABASE_URI ───────────────────────────────────────────────────────

build_uri() {
  if [[ -n "$DB_PASS" ]]; then
    DATABASE_URI="postgresql://${DB_USER}:${DB_PASS}@${DB_HOST}:${DB_PORT}/${DB_NAME}"
  else
    DATABASE_URI="postgresql://${DB_USER}@${DB_HOST}:${DB_PORT}/${DB_NAME}"
  fi
}

# ── Main ─────────────────────────────────────────────────────────────────────

DATABASE_URI="${DATABASE_URI:-}"

if [[ -z "$DATABASE_URI" ]]; then
  if find_config; then
    log "Found config: $CONFIG_FILE ($CONFIG_TYPE)"

    case "$CONFIG_TYPE" in
      env)       parse_env_file "$CONFIG_FILE" || true ;;
      gradle)    parse_gradle_file "$CONFIG_FILE" || true ;;
      openbravo) parse_openbravo_file "$CONFIG_FILE" || true ;;
    esac

    # Build URI if not already set by parse_env_file (DATABASE_URI/DATABASE_URL)
    if [[ -z "$DATABASE_URI" && -n "$DB_NAME" && -n "$DB_USER" ]]; then
      build_uri
    fi
  fi
fi

# ── --print-env mode: export URI for sourcing, don't launch MCP ──────────────

if [[ "${1:-}" == "--print-env" ]]; then
  [[ -z "$DATABASE_URI" ]] && die "Could not infer DATABASE_URI. No config file found and PROJECT_DIR is not set."
  echo "export DATABASE_URI=\"$DATABASE_URI\""
  exit 0
fi

# ── Launch MCP server ────────────────────────────────────────────────────────

if [[ -z "$DATABASE_URI" ]]; then
  # Fallback: connect to default local postgres so MCP server starts.
  # The agent will resolve project-specific credentials via --print-env + psql.
  DATABASE_URI="postgresql://postgres@localhost:5432/postgres"
  log "No config found — using default: $DATABASE_URI"
else
  log "Connecting to: ${DATABASE_URI%%@*}@***"
fi

export DATABASE_URI
exec uvx postgres-mcp --access-mode=unrestricted "$@"
