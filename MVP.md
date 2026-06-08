# MVP.md

本文件定義 `maintain-openclaw` 的第一版最小可用範圍。

## MVP 目標

第一版要讓使用者能夠：

- 知道如何安裝 OpenClaw。
- 透過腳本檢查 OpenClaw 是否正常。
- 找到 OpenClaw 的設定位置與設定範例。
- 在 OpenClaw 異常時取得初步排查方向。
- 安全地移除 OpenClaw 相關服務。
- 透過教育文件理解專案操作順序。

## MVP 範圍

### 1. 安裝文件

交付：

- `docs/installation.md`
- 說明支援的作業系統與前置需求。
- 說明 OpenClaw 來源、下載方式與安裝步驟。
- 說明安裝完成後的驗證方式。

完成標準：

- 新環境可依文件完成一次安裝。
- 文件中沒有未替換的敏感資訊。

### 2. 設定範例

交付：

- `.env.example`

完成標準：

- 包含必要設定欄位。
- 每個欄位都有簡短註解。
- 不包含真實密碼、token 或 private key。

### 3. 安裝腳本

交付：

- `scripts/install-openclaw.sh`

完成標準：

- 可重複執行。
- 遇到錯誤時停止並輸出清楚訊息。
- 不覆蓋使用者現有設定，除非使用者明確指定。

### 4. 狀態檢查腳本

交付：

- `scripts/check-openclaw.sh`

完成標準：

- 輸出 `OK`、`WARN`、`FAIL` 狀態。
- 檢查版本、程序、port、設定檔與日誌。
- 最後輸出總結與下一步建議。

### 5. 維運文件

交付：

- `docs/operations.md`
- `docs/troubleshooting.md`
- `docs/remove-openclaw-services.md`

完成標準：

- 記錄常見維護工作。
- 記錄常見錯誤與處理方式。
- 提供收集診斷資訊的指令。
- 記錄刪除 OpenClaw 服務前的盤點、備份、確認與驗證流程。

### 6. 刪除服務腳本

交付：

- `scripts/remove-openclaw-services.sh`

完成標準：

- 預設只做 dry run 或盤點，不直接刪除。
- 必須明確指定確認參數才會停止、停用或刪除服務。
- 能處理常見服務來源，例如 systemd、launchd、Docker、cron 與背景程序。
- 執行後會重新檢查服務、port 與程序殘留。

### 7. 教育文件

交付：

- `service-helper.html`

完成標準：

- 說明本專案用途、測試 VM、建議閱讀順序與日常操作。
- 說明刪除服務的 dry-run 與確認模式。
- 可直接用瀏覽器開啟，不需要建置流程。

## 不在 MVP 範圍

- 完整 UI 管理介面。
- 自動化多機部署。
- 雲端監控整合。
- 自動修復所有錯誤。
- 儲存或管理敏感憑證。

## 驗收清單

- [ ] `README.md` 能說明專案用途與快速開始。
- [ ] `AGENTS.md` 能指引代理人如何維護專案。
- [x] `docs/installation.md` 已完成。
- [x] `.env.example` 已完成。
- [x] `scripts/install-openclaw.sh` 已完成且可執行。
- [ ] `scripts/check-openclaw.sh` 已完成且可執行。
- [x] `scripts/remove-openclaw-services.sh` 已完成且可執行。
- [ ] `docs/operations.md` 已完成。
- [ ] `docs/troubleshooting.md` 已完成。
- [x] `docs/remove-openclaw-services.md` 已完成。
- [x] `service-helper.html` 已完成。
- [ ] 已在一個目標環境完成安裝驗證。
- [x] 已記錄目前 OpenClaw 版本與健康狀態。
- [x] 已在測試 VM 驗證 OpenClaw 服務刪除 dry-run 流程。
