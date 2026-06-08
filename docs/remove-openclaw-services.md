# 刪除 OpenClaw 所有服務流程

本文件定義如何安全刪除 OpenClaw 相關服務。這是破壞性操作，預設應先盤點與 dry run，確認後才真正停止、停用或刪除服務。

## 測試環境

目前可使用下列 VM 測試流程：

```sh
source .env
ssh "$OPENCLAW_TEST_VM_SSH_TARGET"
```

測試 VM 的實際位置與帳號放在本地 `.env`，不可提交。執行前請先確認登入的是測試 VM，不是正式環境。

## 原則

- 先盤點，再備份，再確認，最後才刪除。
- 不依賴單一服務名稱，先找出所有可能與 OpenClaw 相關的服務。
- 刪除前要保留服務定義、設定檔與版本資訊。
- 刪除後必須重新檢查程序、port、服務、自動啟動項與日誌。
- 腳本預設應為 dry run；必須加入明確確認參數才允許刪除。

## 建議流程

### 1. 確認目標主機

```sh
hostname
whoami
pwd
uname -a
```

確認主機資訊符合預期後，再繼續操作。

### 2. 盤點 OpenClaw 程序

```sh
ps aux | grep -i openclaw
pgrep -af openclaw
```

記錄程序名稱、PID、啟動參數與執行使用者。

### 3. 盤點服務管理器

Linux systemd：

```sh
systemctl list-units --type=service --all | grep -i openclaw
systemctl list-unit-files | grep -i openclaw
systemctl list-timers --all | grep -i openclaw
```

macOS launchd：

```sh
launchctl list | grep -i openclaw
find ~/Library/LaunchAgents /Library/LaunchAgents /Library/LaunchDaemons -iname '*openclaw*' 2>/dev/null
```

### 4. 盤點 Docker 資源

```sh
docker ps -a --format '{{.ID}} {{.Names}} {{.Image}} {{.Status}}' | grep -i openclaw
docker images --format '{{.Repository}}:{{.Tag}} {{.ID}}' | grep -i openclaw
docker volume ls | grep -i openclaw
docker network ls | grep -i openclaw
```

若 OpenClaw 使用 Docker Compose，也要找出 compose 專案目錄與 compose 檔案。

### 5. 盤點 port 與網路

```sh
ss -ltnp | grep -i openclaw
lsof -i -P -n | grep -i openclaw
```

若 `ss` 不存在，使用 `netstat` 或 `lsof` 替代。

### 6. 盤點排程與自動啟動

```sh
crontab -l | grep -i openclaw
sudo crontab -l | grep -i openclaw
find /etc/cron.d /etc/cron.daily /etc/cron.hourly /etc/cron.weekly -iname '*openclaw*' 2>/dev/null
```

### 7. 備份刪除前狀態

建議建立一個帶時間戳的備份目錄：

```sh
mkdir -p ~/openclaw-removal-backup
```

至少保存：

- 服務清單與狀態。
- OpenClaw 版本。
- OpenClaw 設定檔。
- OpenClaw 相關 service、timer、plist、compose 檔。
- 重要日誌路徑與最近錯誤摘要。

### 8. 停止與停用服務

Linux systemd 範例：

```sh
sudo systemctl stop OPENCLAW_SERVICE_NAME
sudo systemctl disable OPENCLAW_SERVICE_NAME
```

macOS launchd 範例：

```sh
launchctl bootout gui/$(id -u) PATH_TO_OPENCLAW_PLIST
sudo launchctl bootout system PATH_TO_OPENCLAW_PLIST
```

Docker 範例：

```sh
docker stop OPENCLAW_CONTAINER_NAME
docker rm OPENCLAW_CONTAINER_NAME
```

請先將 `OPENCLAW_SERVICE_NAME`、`PATH_TO_OPENCLAW_PLIST`、`OPENCLAW_CONTAINER_NAME` 替換為盤點得到的實際值。

### 9. 刪除服務定義

Linux systemd 範例：

```sh
sudo rm /etc/systemd/system/OPENCLAW_SERVICE_NAME.service
sudo systemctl daemon-reload
sudo systemctl reset-failed
```

macOS launchd 範例：

```sh
rm PATH_TO_OPENCLAW_PLIST
```

Docker 資源刪除需先確認資料是否需要保留：

```sh
docker rmi OPENCLAW_IMAGE_NAME
docker volume rm OPENCLAW_VOLUME_NAME
docker network rm OPENCLAW_NETWORK_NAME
```

### 10. 驗證沒有殘留

```sh
pgrep -af openclaw
systemctl list-units --type=service --all | grep -i openclaw
systemctl list-unit-files | grep -i openclaw
docker ps -a | grep -i openclaw
docker volume ls | grep -i openclaw
lsof -i -P -n | grep -i openclaw
```

預期結果是沒有仍在執行的 OpenClaw 程序、服務與 port。

## 未來腳本設計

預計建立：

```sh
scripts/remove-openclaw-services.sh
```

建議模式：

```sh
./scripts/remove-openclaw-services.sh --dry-run
./scripts/remove-openclaw-services.sh --confirm
```

實際確認模式需要兩個參數：

```sh
./scripts/remove-openclaw-services.sh --confirm --yes-i-understand-this-removes-openclaw-services
```

`--dry-run` 只盤點與顯示將處理的項目。確認模式才允許停止、停用與刪除服務。

## 操作紀錄模板

```text
日期:
操作者:
主機:
OpenClaw 版本:
刪除前服務:
刪除前程序:
刪除前 port:
已備份項目:
已刪除項目:
刪除後檢查結果:
待處理問題:
```

## 測試紀錄

### 2026-06-08 VM dry-run

測試主機：

```text
$OPENCLAW_TEST_VM_SSH_TARGET
hostname: test-vm
kernel: Linux aarch64
```

執行：

```sh
bash /tmp/remove-openclaw-services.sh --dry-run
bash /tmp/remove-openclaw-services.sh --confirm
```

結果：

- dry-run 成功，沒有刪除任何服務或檔案。
- 偵測到 OpenClaw gateway 程序：`node ... openclaw ... gateway --port $OPENCLAW_GATEWAY_PORT`。
- 偵測到監聽 port：`TCP *:$OPENCLAW_GATEWAY_PORT (LISTEN)`。
- 未偵測到 OpenClaw systemd unit。
- 未偵測到 OpenClaw Docker 資源。
- 未偵測到 OpenClaw cron 項目。
- 只執行 `--confirm` 時，腳本正確拒絕破壞性模式，訊息為：`Refusing destructive mode without --yes-i-understand-this-removes-openclaw-services`。

未執行真正刪除。若要刪除 VM 上目前偵測到的 OpenClaw gateway，需再次確認後執行完整確認模式。

### 2026-06-08 VM actual removal

依使用者要求，已在 `$OPENCLAW_TEST_VM_SSH_TARGET` 真正刪除 OpenClaw。

刪除項目：

- 停止 OpenClaw gateway listener。
- 移除 npm global package：`openclaw@2026.6.1`。
- 移除 user systemd service：`~/.config/systemd/user/openclaw-gateway.service` 與 `.bak`。
- 移除設定與狀態目錄：`~/.openclaw`。
- 移除 npm global binary 與 package 目錄：`~/.npm-global/bin/openclaw`、`~/.npm-global/lib/node_modules/openclaw`。
- 移除 source 目錄：`~/openclaw`。
- 移除暫存目錄與測試腳本：`/tmp/openclaw`、`/tmp/openclaw-1001`、`/tmp/remove-openclaw-services.sh`。

最終驗證：

- 無 OpenClaw 程序。
- gateway port 無 listener。
- npm global list 無 OpenClaw。
- OpenClaw binary 與 npm package 目錄不存在。
- user systemd service 不存在。
- `~/.openclaw` 不存在。
- `~/openclaw` 不存在。
- `/tmp` 內無 OpenClaw 暫存項目。
