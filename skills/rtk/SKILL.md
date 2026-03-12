---
name: rtk
description: >
  Rust Token Killer — CLI proxy for token-optimized bash output (60-90% savings).
  Trigger: ALWAYS load this skill. Apply to every Bash tool call automatically.
  Prefix supported commands with rtk before execution.
license: Apache-2.0
metadata:
  author: gentleman-programming
  version: "1.0"
---

## When to Use

**ALWAYS.** This skill applies to every Bash tool call. Before executing any bash command, check if it matches a supported command below and prefix it with `rtk`.

## Command Rewrite Table

| Instead of               | Use                        |
| ------------------------ | -------------------------- |
| `git status`             | `rtk git status`           |
| `git diff`               | `rtk git diff`             |
| `git log`                | `rtk git log`              |
| `git branch`             | `rtk git branch`           |
| `gh pr list`             | `rtk gh pr list`           |
| `gh pr create ...`       | `rtk gh pr create ...`     |
| `docker ps`              | `rtk docker ps`            |
| `docker logs`            | `rtk docker logs`          |
| `kubectl get pods`       | `rtk kubectl get pods`     |
| `tree`                   | `rtk tree`                 |
| `ls`                     | `rtk ls`                   |
| `cat <file>`             | `rtk read <file>`          |
| `find . -name '*.ext'`   | `rtk find . -name '*.ext'` |
| `grep -r pattern .`      | `rtk grep -r pattern .`    |
| `diff a b`               | `rtk diff a b`             |
| `curl <url>`             | `rtk curl <url>`           |
| `wget <url>`             | `rtk wget <url>`           |
| `aws s3 ls`              | `rtk aws s3 ls`            |
| `psql -c 'query'`        | `rtk psql -c 'query'`      |
| `cargo build`            | `rtk cargo build`          |
| `cargo test`             | `rtk cargo test`           |
| `pnpm install`           | `rtk pnpm install`         |
| `npm run build`          | `rtk npm run build`        |
| `pip install pkg`        | `rtk pip install pkg`      |
| `pytest`                 | `rtk pytest`               |
| `ruff check .`           | `rtk ruff check .`         |
| `npx tsc`                | `rtk tsc`                  |
| `npx prisma`             | `rtk prisma`               |
| `npx eslint .`           | `rtk lint .`               |
| `npx prettier --check .` | `rtk prettier --check .`   |

## Do NOT Rewrite

These commands have NO rtk support — use them raw:

`npm install`, `gradle`, `echo`, `mkdir`, `cp`, `mv`, `rm`, `wc`, `chmod`, `chown`, `tar`, `zip`, `unzip`, `ssh`, `scp`

## Special Rewrites

Note these commands change name, not just prefix:

| Original       | RTK             | Why                                                    |
| -------------- | --------------- | ------------------------------------------------------ |
| `cat file`     | `rtk read file` | `read` is RTK's file viewer with intelligent filtering |
| `npx tsc`      | `rtk tsc`       | Drops `npx`, groups TypeScript errors                  |
| `npx eslint .` | `rtk lint .`    | Drops `npx`, groups rule violations                    |
| `npx prisma`   | `rtk prisma`    | Drops `npx`, strips ASCII art                          |

## Meta Commands

Use these directly (not as prefix):

```bash
rtk gain              # Show token savings analytics
rtk gain --history    # Show command usage history
rtk discover          # Analyze missed savings opportunities
```

## Chained Commands

When commands are chained with `&&`, rewrite each supported command individually:

```bash
# Bad
git add . && git commit -m "msg"

# Good
rtk git status && git add . && git commit -m "msg"
```

Only rewrite the commands that have rtk support. Leave `git add`, `git commit`, `git push` as-is (they produce minimal output — rtk savings are negligible).

## Pipeline Commands

Do NOT rewrite commands inside pipes or subshells — rtk may alter output format:

```bash
# Don't rewrite — grep is filtering git output
git log --oneline | grep "fix"

# Do rewrite — standalone command
rtk git log
```
