# AGENTS.md

本專案用來安裝、維護、設定與檢查 OpenClaw 的狀態。代理人進入此專案時，請優先遵守本文件。

## 專案目標

- 建立可重複執行的 OpenClaw 安裝流程。
- 保存 OpenClaw 的設定、部署步驟與檢查指令。
- 提供狀態檢查、故障排除與維護紀錄。
- 讓人與 AI 代理人都能快速判斷目前系統是否健康。

## 工作原則

- 修改前先理解現有文件與腳本，不要覆蓋未知用途的檔案。
- 優先將人工操作整理成可重複執行的腳本。
- 任何涉及憑證、token、private key、內網 IP 的資訊都不要提交到 Git。
- 新增設定範例時使用 `.example` 或清楚標示 placeholder。
- 維護文件要保持可操作，避免只寫概念。
- 執行具破壞性的操作前，必須先向使用者確認。

## 建議目錄

```text
.
├── AGENTS.md
├── README.md
├── MVP.md
├── TODO.md
├── scripts/
│   ├── install-openclaw.sh
│   ├── check-openclaw.sh
│   ├── maintain-openclaw.sh
│   └── remove-openclaw-services.sh
├── config/
│   └── .env.example
├── docs/
│   ├── installation.md
│   ├── operations.md
│   ├── remove-openclaw-services.md
│   └── troubleshooting.md
└── logs/
    └── .gitkeep
```

## 測試環境

目前可用的測試 VM：

```sh
source .env
ssh "$OPENCLAW_TEST_VM_SSH_TARGET"
```

測試 VM 位址與帳號必須放在本地 `.env`，不可提交。使用測試 VM 前，請先確認連線目標正確。任何刪除服務、移除套件、清資料、重啟系統的操作，都必須先回報將執行的動作並取得使用者確認。

## 常用任務

### 安裝 OpenClaw

1. 確認目標作業系統、硬體與網路條件。
2. 建立或更新 `.env.example`，真實值放在本地 `.env`。
3. 將安裝步驟整理到 `scripts/install-openclaw.sh`。
4. 在 `docs/installation.md` 記錄手動安裝與驗證方式。

### 檢查 OpenClaw 狀態

1. 優先使用 `scripts/check-openclaw.sh`。
2. 檢查服務程序、port、設定檔、版本、日誌與必要依賴。
3. 輸出要能讓使用者快速判斷 `OK`、`WARN`、`FAIL`。
4. 若發現問題，將修復建議寫入輸出或文件。

### 維護 OpenClaw

1. 更新前先記錄目前版本與設定。
2. 備份重要設定與資料。
3. 執行更新或修復後，重新跑狀態檢查。
4. 將維護結果補到 `docs/operations.md` 或 TODO。

### 刪除 OpenClaw 所有服務

1. 先閱讀 `docs/remove-openclaw-services.md`。
2. 盤點 OpenClaw 相關 systemd、launchd、Docker、cron、背景程序與 port。
3. 備份服務定義、設定檔與必要資料。
4. 向使用者列出將停止、停用、刪除的項目並取得確認。
5. 刪除後執行狀態檢查，確認沒有殘留服務或監聽 port。

## 回報格式

完成任務時，請簡短說明：

- 改了哪些檔案。
- 如何驗證。
- 還有哪些風險或待辦。
