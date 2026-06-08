# TODO.md

OpenClaw 安裝與維護專案待辦。

## 立即待辦

- [ ] 確認 OpenClaw 的官方來源、版本與安裝方式。
- [ ] 確認目標環境：作業系統、CPU 架構、網路條件、權限限制。
- [ ] 決定 OpenClaw 安裝目錄與設定檔目錄。
- [ ] 建立 `docs/installation.md`。
- [ ] 建立 `docs/operations.md`。
- [ ] 建立 `docs/troubleshooting.md`。
- [x] 建立 `.env.example`。
- [ ] 建立 `scripts/install-openclaw.sh`。
- [ ] 建立 `scripts/check-openclaw.sh`。
- [x] 建立 `scripts/remove-openclaw-services.sh`。
- [x] 建立 `service-helper.html` 教育文件。
- [x] 在測試 VM `$OPENCLAW_TEST_VM_SSH_TARGET` 驗證刪除服務 dry-run 流程。

## 安裝腳本待辦

- [ ] 檢查必要指令是否存在。
- [ ] 檢查作業系統與 CPU 架構。
- [ ] 下載或安裝 OpenClaw。
- [ ] 建立必要目錄。
- [ ] 安裝或註冊服務。
- [ ] 建立設定檔範例。
- [ ] 安裝後執行健康檢查。

## 狀態檢查待辦

- [ ] 檢查 OpenClaw binary 或服務是否存在。
- [ ] 檢查 OpenClaw 版本。
- [ ] 檢查服務程序是否執行中。
- [ ] 檢查必要 port 是否監聽。
- [ ] 檢查設定檔是否存在。
- [ ] 檢查最近日誌中的錯誤。
- [ ] 檢查磁碟空間。
- [ ] 檢查必要依賴。
- [ ] 輸出總結與修復建議。

## 維護待辦

- [ ] 定義備份流程。
- [ ] 定義更新流程。
- [ ] 定義回滾流程。
- [ ] 定義刪除 OpenClaw 所有服務的安全流程。
- [ ] 定義日誌收集流程。
- [ ] 定義故障排除決策樹。
- [ ] 記錄常見錯誤訊息與解法。

## 刪除服務待辦

- [ ] 盤點 OpenClaw 實際服務名稱。
- [ ] 盤點 OpenClaw 相關 port。
- [ ] 盤點 systemd 服務與 timer。
- [ ] 盤點 launchd plist。
- [ ] 盤點 Docker container、image、volume 與 network。
- [ ] 盤點 cron job。
- [ ] 盤點背景程序與自動啟動項。
- [x] 建立 dry-run 模式。
- [x] 建立需要確認參數的刪除模式。
- [x] 刪除後重新執行狀態檢查。
- [x] 將 VM dry-run 測試輸出摘要寫回文件。

## 之後可做

- [ ] 加入 CI 檢查 shell script 語法。
- [ ] 加入 shellcheck。
- [ ] 加入狀態檢查輸出的 JSON 模式。
- [ ] 加入 systemd 或 launchd 範例。
- [ ] 加入 Docker 或 container 化部署選項。
- [ ] 加入版本升級紀錄。
