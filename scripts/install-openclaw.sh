#!/usr/bin/env bash
set -euo pipefail

DRY_RUN=false
SKIP_MODEL_CHECK=false

if [ -f .env ]; then
  set -a
  # shellcheck disable=SC1091
  . ./.env
  set +a
fi

OPENCLAW_NPM_VERSION="${OPENCLAW_NPM_VERSION:-latest}"
OPENCLAW_WORKSPACE_DIR="${OPENCLAW_WORKSPACE_DIR:-$HOME/.openclaw/workspace}"
OPENCLAW_GATEWAY_PORT="${OPENCLAW_GATEWAY_PORT:-18789}"
OPENCLAW_GATEWAY_BIND="${OPENCLAW_GATEWAY_BIND:-loopback}"
OPENCLAW_GATEWAY_AUTH="${OPENCLAW_GATEWAY_AUTH:-none}"
OPENCLAW_INSTALL_SERVICE="${OPENCLAW_INSTALL_SERVICE:-false}"
OPENCLAW_START_GATEWAY="${OPENCLAW_START_GATEWAY:-false}"
OPENCLAW_OLLAMA_BASE_URL="${OPENCLAW_OLLAMA_BASE_URL:-http://127.0.0.1:11434}"
OPENCLAW_OLLAMA_MODEL="${OPENCLAW_OLLAMA_MODEL:-gemma4:26b}"
OPENCLAW_OLLAMA_PROVIDER_ID="${OPENCLAW_OLLAMA_PROVIDER_ID:-local-ollama}"
OPENCLAW_OLLAMA_TIMEOUT_SECONDS="${OPENCLAW_OLLAMA_TIMEOUT_SECONDS:-600}"

usage() {
  cat <<'USAGE'
Usage:
  scripts/install-openclaw.sh [--dry-run] [--skip-model-check]

Installs OpenClaw from npm, initializes local config, configures an Ollama
provider, validates config, and optionally creates/starts a user systemd service.

Configuration is read from .env when present. See .env.example.
USAGE
}

log() {
  printf '%s\n' "$*"
}

have() {
  command -v "$1" >/dev/null 2>&1
}

run_or_show() {
  if [ "$DRY_RUN" = true ]; then
    log "[dry-run] $*"
  else
    log "+ $*"
    "$@"
  fi
}

require_command() {
  if ! have "$1"; then
    log "Missing required command: $1"
    exit 1
  fi
}

wait_for_gateway() {
  if ! have curl; then
    sleep 2
    return 0
  fi

  log "Waiting for OpenClaw gateway on 127.0.0.1:${OPENCLAW_GATEWAY_PORT}..."
  for _ in $(seq 1 30); do
    if curl -fsS "http://127.0.0.1:${OPENCLAW_GATEWAY_PORT}/" >/dev/null 2>&1; then
      return 0
    fi
    sleep 1
  done

  log "WARN: Gateway did not become HTTP-reachable within 30 seconds."
}

json_escape() {
  node -e 'process.stdout.write(JSON.stringify(process.argv[1]))' "$1"
}

write_config_patch() {
  local patch_file="$1"
  local base_url_json model_json provider_json workspace_json

  base_url_json="$(json_escape "$OPENCLAW_OLLAMA_BASE_URL")"
  model_json="$(json_escape "$OPENCLAW_OLLAMA_MODEL")"
  provider_json="$(json_escape "$OPENCLAW_OLLAMA_PROVIDER_ID")"
  workspace_json="$(json_escape "$OPENCLAW_WORKSPACE_DIR")"

  cat >"$patch_file" <<PATCH
{
  gateway: {
    mode: "local",
    port: ${OPENCLAW_GATEWAY_PORT},
    bind: "${OPENCLAW_GATEWAY_BIND}"
  },
  agents: {
    defaults: {
      workspace: ${workspace_json}
    }
  },
  models: {
    mode: "merge",
    providers: {
      ${provider_json}: {
        baseUrl: ${base_url_json},
        api: "ollama",
        timeoutSeconds: ${OPENCLAW_OLLAMA_TIMEOUT_SECONDS},
        models: [
          {
            id: ${model_json},
            name: ${model_json}
          }
        ]
      }
    }
  }
}
PATCH
}

check_ollama_model() {
  if [ "$SKIP_MODEL_CHECK" = true ]; then
    log "Skipping Ollama model check."
    return 0
  fi

  if ! have curl; then
    log "curl not found; skipping Ollama model check."
    return 0
  fi

  log "Checking Ollama API at ${OPENCLAW_OLLAMA_BASE_URL}..."
  if ! curl -fsS "${OPENCLAW_OLLAMA_BASE_URL}/api/tags" >/tmp/openclaw-ollama-tags.json 2>/dev/null; then
    log "WARN: Ollama API is not reachable from this machine."
    log "      Set OPENCLAW_OLLAMA_BASE_URL in .env to the host-visible Ollama URL."
    return 0
  fi

  if ! grep -q "\"name\":\"${OPENCLAW_OLLAMA_MODEL}\"" /tmp/openclaw-ollama-tags.json; then
    log "WARN: Ollama model '${OPENCLAW_OLLAMA_MODEL}' was not found."
    log "      Pull it on the Ollama host or change OPENCLAW_OLLAMA_MODEL in .env."
    log "      Available model names:"
    tr ',' '\n' </tmp/openclaw-ollama-tags.json | grep '"name"' | sed 's/^/      /' || true
  fi
}

install_user_service() {
  local service_dir service_file openclaw_bin
  service_dir="$HOME/.config/systemd/user"
  service_file="$service_dir/openclaw-gateway.service"
  openclaw_bin="$(command -v openclaw)"

  mkdir -p "$service_dir"
  cat >"$service_file" <<SERVICE
[Unit]
Description=OpenClaw Gateway
After=network-online.target

[Service]
Type=simple
ExecStart=${openclaw_bin} gateway run --port ${OPENCLAW_GATEWAY_PORT} --bind ${OPENCLAW_GATEWAY_BIND} --auth ${OPENCLAW_GATEWAY_AUTH}
Restart=on-failure
RestartSec=5

[Install]
WantedBy=default.target
SERVICE

  run_or_show systemctl --user daemon-reload
  run_or_show systemctl --user enable openclaw-gateway.service
}

while [ $# -gt 0 ]; do
  case "$1" in
    --dry-run)
      DRY_RUN=true
      ;;
    --skip-model-check)
      SKIP_MODEL_CHECK=true
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      log "Unknown argument: $1"
      usage
      exit 2
      ;;
  esac
  shift
done

require_command node
require_command npm

if [ "$DRY_RUN" = true ]; then
  log "[dry-run] npm install -g openclaw@${OPENCLAW_NPM_VERSION}"
  log "[dry-run] openclaw setup --non-interactive --accept-risk --mode local --workspace ${OPENCLAW_WORKSPACE_DIR}"
  log "[dry-run] openclaw config patch --file <generated>"
  log "[dry-run] openclaw config validate"
  exit 0
fi

run_or_show npm install -g "openclaw@${OPENCLAW_NPM_VERSION}"
require_command openclaw

mkdir -p "$OPENCLAW_WORKSPACE_DIR"
if ! openclaw setup --non-interactive --accept-risk --mode local --workspace "$OPENCLAW_WORKSPACE_DIR"; then
  log "WARN: openclaw setup returned non-zero, likely because the gateway is not running yet."
  log "      Continuing because setup creates config/workspace before the reachability probe."
fi

patch_file="$(mktemp)"
trap 'rm -f "$patch_file" /tmp/openclaw-ollama-tags.json' EXIT
write_config_patch "$patch_file"
run_or_show openclaw config patch --file "$patch_file"
run_or_show openclaw config validate
run_or_show openclaw models set "${OPENCLAW_OLLAMA_PROVIDER_ID}/${OPENCLAW_OLLAMA_MODEL}"
check_ollama_model

if [ "$OPENCLAW_INSTALL_SERVICE" = true ]; then
  install_user_service
fi

if [ "$OPENCLAW_START_GATEWAY" = true ]; then
  if [ "$OPENCLAW_INSTALL_SERVICE" = true ] && have systemctl; then
    run_or_show systemctl --user restart openclaw-gateway.service
  else
    if have lsof && lsof -tiTCP:"$OPENCLAW_GATEWAY_PORT" -sTCP:LISTEN >/dev/null 2>&1; then
      log "Restarting existing listener on port ${OPENCLAW_GATEWAY_PORT}..."
      lsof -tiTCP:"$OPENCLAW_GATEWAY_PORT" -sTCP:LISTEN | while IFS= read -r pid; do
        [ -n "$pid" ] || continue
        kill "$pid" 2>/dev/null || true
      done
      sleep 2
    fi
    log "Starting OpenClaw gateway in background..."
    nohup openclaw gateway run --port "$OPENCLAW_GATEWAY_PORT" --bind "$OPENCLAW_GATEWAY_BIND" --auth "$OPENCLAW_GATEWAY_AUTH" >"$HOME/.openclaw/gateway.log" 2>&1 &
    log "Gateway PID: $!"
  fi
  wait_for_gateway
fi

run_or_show openclaw status
