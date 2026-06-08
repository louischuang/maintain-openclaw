# OpenClaw 安裝流程

本文件說明如何使用本專案安裝 OpenClaw，並設定 VM 連到本機 Ollama。

## 前置條件

- VM 可透過 SSH 連線。
- VM 已安裝 Node.js 與 npm。
- 本機 Ollama API 可被 VM 存取。
- Ollama 已有目標模型，例如 `gemma4:26b`。

## 私密設定

先建立本地 `.env`：

```sh
cp .env.example .env
$EDITOR .env
```

重要欄位：

```sh
OPENCLAW_TEST_VM_SSH_TARGET=your-user@your-vm-host
OPENCLAW_OLLAMA_BASE_URL=http://host-visible-ollama:11434
OPENCLAW_OLLAMA_MODEL=gemma4:26b
OPENCLAW_GATEWAY_PORT=18789
```

`.env` 不可提交。請只提交 `.env.example`。

## 安裝

在目標 VM 或本機 clone 內執行：

```sh
source .env
./scripts/install-openclaw.sh
```

安裝腳本會：

- 安裝 `openclaw` npm package。
- 執行 `openclaw setup --non-interactive` 建立 config/workspace。
- 設定 Ollama provider。
- 設定 default model。
- 檢查 Ollama API 與模型清單。
- 驗證 OpenClaw config。
- 視 `.env` 設定選擇是否啟動 gateway。

## 啟動 Gateway

若要安裝後自動啟動 gateway：

```sh
OPENCLAW_START_GATEWAY=true
```

預設建議：

```sh
OPENCLAW_GATEWAY_BIND=loopback
OPENCLAW_GATEWAY_AUTH=none
```

loopback 模式適合搭配 SSH 使用，不會把 gateway 直接暴露到 LAN。

## 操作介面建議

### 1. SSH + TUI

最推薦用於 VM 維護：

```sh
ssh "$OPENCLAW_TEST_VM_SSH_TARGET"
openclaw tui
```

優點是不用開放 gateway port 到外部網路。

### 2. Dashboard + SSH Tunnel

需要瀏覽器 UI 時使用：

```sh
ssh -L 18789:127.0.0.1:18789 "$OPENCLAW_TEST_VM_SSH_TARGET"
```

然後在本機瀏覽器開：

```text
http://127.0.0.1:18789/
```

### 3. Messaging Channels

之後若需要長期通知或遠端操作，可再接 Telegram、Slack、LINE 等 channel。這些 channel 需要額外 token、owner 設定與權限控管，不建議放在 MVP 第一階段。

## 測試紀錄

### 2026-06-08 VM install test

測試內容：

- 從乾淨狀態安裝 OpenClaw。
- 設定 Ollama provider。
- 使用 `gemma4:26b` 作為 default model。
- 啟動 gateway。
- 執行 one-shot model inference。

結果：

- `npm install -g openclaw@latest` 成功。
- `openclaw config validate` 成功。
- default model 設定為 `local-ollama/gemma4:26b`。
- gateway 成功在 loopback port 啟動。
- `openclaw infer model run --local --model local-ollama/gemma4:26b --prompt "Reply with exactly: OK" --json` 回傳 `OK`。

