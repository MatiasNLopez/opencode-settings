#!/usr/bin/env bash
# postgres-mcp-wrapper.sh
# Reads DB connection from Openbravo.properties and launches postgres-mcp
# Usage: Called by opencode as MCP server command

set -euo pipefail

# --- Resolve project root ---
# Try current working directory first, then fallback to explicit path
find_properties() {
  local dir="${1:-.}"
  local props_file="$dir/config/Openbravo.properties"
  if [[ -f "$props_file" ]]; then
    echo "$props_file"
    return 0
  fi
  return 1
}

PROPS_FILE=""
if find_properties "." >/dev/null 2>&1; then
  PROPS_FILE=$(find_properties ".")
elif [[ -n "${ETENDO_SOURCE_PATH:-}" ]] && find_properties "$ETENDO_SOURCE_PATH" >/dev/null 2>&1; then
  PROPS_FILE=$(find_properties "$ETENDO_SOURCE_PATH")
else
  echo "ERROR: Cannot find config/Openbravo.properties" >&2
  echo "Set ETENDO_SOURCE_PATH or run from project root" >&2
  exit 1
fi

# --- Parse properties ---
get_prop() {
  local key="$1"
  grep -E "^${key}=" "$PROPS_FILE" | head -1 | cut -d'=' -f2- | tr -d '[:space:]'
}

BBDD_URL=$(get_prop "bbdd.url")
BBDD_SID=$(get_prop "bbdd.sid")
BBDD_USER=$(get_prop "bbdd.user")
BBDD_PASSWORD=$(get_prop "bbdd.password")

# Extract host:port from jdbc URL (jdbc:postgresql://host:port)
HOST_PORT=$(echo "$BBDD_URL" | sed 's|jdbc:postgresql://||')

# Build PostgreSQL URI
export DATABASE_URI="postgresql://${BBDD_USER}:${BBDD_PASSWORD}@${HOST_PORT}/${BBDD_SID}"

# --- Launch postgres-mcp ---
exec uvx postgres-mcp --access-mode=unrestricted
