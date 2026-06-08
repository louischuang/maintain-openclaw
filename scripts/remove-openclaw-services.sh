#!/usr/bin/env bash
set -u

APP_NAME="openclaw"
CONFIRM=false
YES_FLAG=false

if [ -f .env ]; then
  set -a
  # shellcheck disable=SC1091
  . ./.env
  set +a
fi

OPENCLAW_GATEWAY_PORT="${OPENCLAW_GATEWAY_PORT:-18789}"

usage() {
  cat <<'USAGE'
Usage:
  scripts/remove-openclaw-services.sh [--dry-run]
  scripts/remove-openclaw-services.sh --confirm --yes-i-understand-this-removes-openclaw-services

Default mode is dry-run. It inventories OpenClaw-related services, processes,
Docker resources, cron entries, and listening ports without deleting anything.
It also inventories common OpenClaw npm, config, source, and tmp paths.

Deletion mode is destructive and requires both confirmation flags.
USAGE
}

log() {
  printf '%s\n' "$*"
}

have() {
  command -v "$1" >/dev/null 2>&1
}

run_or_show() {
  if [ "$CONFIRM" = true ]; then
    log "+ $*"
    "$@"
  else
    log "[dry-run] $*"
  fi
}

section() {
  printf '\n== %s ==\n' "$1"
}

grep_openclaw() {
  grep -i "$APP_NAME" || true
}

collect_systemd_units() {
  if have systemctl; then
    systemctl list-unit-files --no-pager 2>/dev/null | grep_openclaw | awk '{print $1}' || true
    systemctl list-units --all --no-pager 2>/dev/null | grep_openclaw | awk '{print $1}' || true
  fi
}

collect_docker_containers() {
  if have docker; then
    docker ps -a --format '{{.Names}}' 2>/dev/null | grep_openclaw || true
  fi
}

collect_docker_images() {
  if have docker; then
    docker images --format '{{.Repository}}:{{.Tag}}' 2>/dev/null | grep_openclaw || true
  fi
}

collect_docker_volumes() {
  if have docker; then
    docker volume ls --format '{{.Name}}' 2>/dev/null | grep_openclaw || true
  fi
}

collect_docker_networks() {
  if have docker; then
    docker network ls --format '{{.Name}}' 2>/dev/null | grep_openclaw || true
  fi
}

collect_launchd_plists() {
  if have find; then
    find "$HOME/Library/LaunchAgents" /Library/LaunchAgents /Library/LaunchDaemons -iname "*${APP_NAME}*" 2>/dev/null || true
  fi
}

collect_processes() {
  if have pgrep; then
    pgrep -af "$APP_NAME" 2>/dev/null | awk '!/remove-openclaw-services\.sh/ && !/grep -vi/ {print}' || true
  else
    ps aux 2>/dev/null | grep_openclaw | awk '!/remove-openclaw-services\.sh/ && !/grep -vi/ {print}' || true
  fi
}

collect_process_pids() {
  collect_processes | awk '{print $1}' | grep '^[0-9][0-9]*$' || true
}

collect_openclaw_paths() {
  local uid
  uid="$(id -u 2>/dev/null || printf unknown)"

  for path in \
    "$HOME/.openclaw" \
    "$HOME/openclaw" \
    "$HOME/.config/systemd/user/openclaw-gateway.service" \
    "$HOME/.config/systemd/user/openclaw-gateway.service.bak" \
    "$HOME/.npm-global/bin/openclaw" \
    "$HOME/.npm-global/lib/node_modules/openclaw" \
    "/tmp/openclaw" \
    "/tmp/openclaw-${uid}" \
    "/tmp/remove-openclaw-services.sh"; do
    [ -e "$path" ] && printf '%s\n' "$path"
  done
}

show_ports() {
  local found=false

  if have lsof; then
    collect_process_pids | while IFS= read -r pid; do
      [ -n "$pid" ] || continue
      lsof -Pan -p "$pid" -i 2>/dev/null || true
    done
    found=true
  fi

  if have ss; then
    ss -ltnp 2>/dev/null | grep_openclaw
    found=true
  fi

  if [ "$found" = false ]; then
    log "lsof/ss not found"
  fi

  collect_processes | grep -E -- '--port[ =]?[0-9]+' || true
}

inventory() {
  section "Target"
  log "host: $(hostname 2>/dev/null || printf unknown)"
  log "user: $(whoami 2>/dev/null || printf unknown)"
  log "kernel: $(uname -a 2>/dev/null || printf unknown)"
  log "mode: $([ "$CONFIRM" = true ] && printf confirm || printf dry-run)"

  section "Processes"
  collect_processes

  section "systemd"
  if have systemctl; then
    systemctl list-units --type=service --all --no-pager 2>/dev/null | grep_openclaw
    systemctl list-unit-files --no-pager 2>/dev/null | grep_openclaw
    systemctl list-timers --all --no-pager 2>/dev/null | grep_openclaw
  else
    log "systemctl not found"
  fi

  section "launchd"
  if have launchctl; then
    launchctl list 2>/dev/null | grep_openclaw
  else
    log "launchctl not found"
  fi
  collect_launchd_plists

  section "Docker"
  if have docker; then
    docker ps -a --format '{{.ID}} {{.Names}} {{.Image}} {{.Status}}' 2>/dev/null | grep_openclaw
    docker images --format '{{.Repository}}:{{.Tag}} {{.ID}}' 2>/dev/null | grep_openclaw
    docker volume ls 2>/dev/null | grep_openclaw
    docker network ls 2>/dev/null | grep_openclaw
  else
    log "docker not found"
  fi

  section "Ports"
  show_ports

  section "Cron"
  crontab -l 2>/dev/null | grep_openclaw
  if have sudo; then
    sudo -n crontab -l 2>/dev/null | grep_openclaw
  fi
  if have find; then
    find /etc/cron.d /etc/cron.daily /etc/cron.hourly /etc/cron.weekly -iname "*${APP_NAME}*" 2>/dev/null || true
  fi

  section "OpenClaw paths"
  collect_openclaw_paths
  if have npm; then
    npm list -g --depth=0 2>/dev/null | grep_openclaw
  fi
}

remove_processes() {
  section "Remove OpenClaw processes"
  collect_process_pids | while IFS= read -r pid; do
    [ -n "$pid" ] || continue
    run_or_show kill "$pid"
  done

  if have lsof; then
    lsof -tiTCP:"$OPENCLAW_GATEWAY_PORT" -sTCP:LISTEN 2>/dev/null | while IFS= read -r pid; do
      [ -n "$pid" ] || continue
      run_or_show kill "$pid"
    done
  fi
}

remove_systemd() {
  have systemctl || return 0
  section "Remove systemd units"
  if ! collect_systemd_units | grep -q .; then
    log "no systemd OpenClaw units found"
    return 0
  fi
  collect_systemd_units | sort -u | while IFS= read -r unit; do
    [ -n "$unit" ] || continue
    case "$unit" in
      *.service|*.timer|*.socket)
        run_or_show sudo systemctl stop "$unit"
        run_or_show sudo systemctl disable "$unit"
        ;;
    esac
  done
  run_or_show sudo systemctl daemon-reload
  run_or_show sudo systemctl reset-failed

  if [ -e "$HOME/.config/systemd/user/openclaw-gateway.service" ]; then
    run_or_show systemctl --user stop openclaw-gateway.service
    run_or_show systemctl --user disable openclaw-gateway.service
    run_or_show systemctl --user daemon-reload
    run_or_show systemctl --user reset-failed
  fi
}

remove_launchd() {
  have launchctl || return 0
  section "Remove launchd plists"
  collect_launchd_plists | while IFS= read -r plist; do
    [ -n "$plist" ] || continue
    case "$plist" in
      "$HOME"/Library/LaunchAgents/*)
        run_or_show launchctl bootout "gui/$(id -u)" "$plist"
        run_or_show rm "$plist"
        ;;
      /Library/LaunchAgents/*|/Library/LaunchDaemons/*)
        run_or_show sudo launchctl bootout system "$plist"
        run_or_show sudo rm "$plist"
        ;;
    esac
  done
}

remove_docker() {
  have docker || return 0
  section "Remove Docker resources"
  collect_docker_containers | while IFS= read -r name; do
    [ -n "$name" ] || continue
    run_or_show docker stop "$name"
    run_or_show docker rm "$name"
  done
  collect_docker_images | while IFS= read -r image; do
    [ -n "$image" ] || continue
    run_or_show docker rmi "$image"
  done
  collect_docker_volumes | while IFS= read -r volume; do
    [ -n "$volume" ] || continue
    run_or_show docker volume rm "$volume"
  done
  collect_docker_networks | while IFS= read -r network; do
    [ -n "$network" ] || continue
    run_or_show docker network rm "$network"
  done
}

remove_npm_and_paths() {
  section "Remove npm package and OpenClaw paths"
  if have npm; then
    if npm list -g --depth=0 2>/dev/null | grep -qi "$APP_NAME"; then
      run_or_show npm uninstall -g openclaw
    fi
  fi

  collect_openclaw_paths | while IFS= read -r path; do
    [ -n "$path" ] || continue
    run_or_show rm -rf "$path"
  done
}

while [ $# -gt 0 ]; do
  case "$1" in
    --dry-run)
      CONFIRM=false
      ;;
    --confirm)
      CONFIRM=true
      ;;
    --yes-i-understand-this-removes-openclaw-services)
      YES_FLAG=true
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

if [ "$CONFIRM" = true ] && [ "$YES_FLAG" != true ]; then
  log "Refusing destructive mode without --yes-i-understand-this-removes-openclaw-services"
  exit 2
fi

inventory
remove_processes
remove_systemd
remove_launchd
remove_docker
remove_npm_and_paths

section "Post-check"
inventory

if [ "$CONFIRM" = true ]; then
  log "Removal attempt complete. Review the post-check output for remaining OpenClaw resources."
else
  log "Dry-run complete. No services or files were removed."
fi
