# maintain-openclaw

這個專案用來安裝、設定、維護與檢查 OpenClaw 的狀態。

目前先建立維護文件骨架，後續會逐步加入安裝腳本、設定範例、健康檢查與故障排除流程。

也提供 [service-helper.html](./service-helper.html) 作為教育文件，說明本專案的使用方式、操作順序與刪除服務的安全流程。

## 目標

- 快速安裝 OpenClaw。
- 保存 OpenClaw 的設定與部署流程。
- 一鍵檢查 OpenClaw 是否正常運作。
- 將維護經驗文件化，降低下次排查成本。

## 預計內容

```text
scripts/
  install-openclaw.sh      # 安裝 OpenClaw
  check-openclaw.sh        # 檢查 OpenClaw 狀態
  maintain-openclaw.sh     # 常見維護工作
  remove-openclaw-services.sh
                            # 刪除 OpenClaw 相關服務

config/
  .env.example             # 私密環境設定範例

docs/
  installation.md          # 安裝文件
  operations.md            # 維運文件
  remove-openclaw-services.md
                            # 刪除 OpenClaw 服務流程
  troubleshooting.md       # 故障排除
```

## 測試環境

可使用下列 VM 作為安裝、維護與狀態檢查測試環境：

```sh
cp .env.example .env
$EDITOR .env
source .env
ssh "$OPENCLAW_TEST_VM_SSH_TARGET"
```

注意：測試 VM 的 IP、帳號與可用狀態屬於私密設定，請放在 `.env`，不要寫入 Git 追蹤的文件。執行刪除、停止服務、移除套件等破壞性操作前，請先確認目標主機與影響範圍。

## 快速開始

第一階段建議依序完成：

1. 確認 OpenClaw 的安裝方式與官方來源。
2. 建立本地 `.env`，並以 `.env.example` 作為範例。
3. 建立 `scripts/install-openclaw.sh`。
4. 建立 `scripts/check-openclaw.sh`。
5. 使用 `scripts/remove-openclaw-services.sh --dry-run` 盤點 OpenClaw 服務。
6. 將實際安裝、檢查與移除服務結果補到 `docs/`。

## 刪除 OpenClaw 服務

本專案已建立安全預設的刪除服務腳本：

```sh
./scripts/remove-openclaw-services.sh --dry-run
```

dry-run 只會盤點 OpenClaw 相關服務、程序、Docker 資源、cron、port、npm global package 與常見設定路徑，不會刪除任何東西。

若要真正刪除，必須明確使用：

```sh
./scripts/remove-openclaw-services.sh --confirm --yes-i-understand-this-removes-openclaw-services
```

執行確認模式前，請先閱讀 [docs/remove-openclaw-services.md](./docs/remove-openclaw-services.md)。

已在測試 VM `$OPENCLAW_TEST_VM_SSH_TARGET` 執行 dry-run，確認偵測到 OpenClaw gateway 程序與設定的 gateway port。之後已依使用者要求真正移除 VM 上的 OpenClaw，並確認程序、port、npm global package、user systemd service、`~/.openclaw`、`~/openclaw` 與 `/tmp/openclaw*` 都已清除。

## 狀態檢查預期

未來 `scripts/check-openclaw.sh` 應至少檢查：

- OpenClaw 是否已安裝。
- OpenClaw 版本。
- 主要服務是否正在執行。
- 必要 port 是否有監聽。
- 設定檔是否存在且格式正確。
- 最近日誌是否有錯誤。
- 必要依賴是否可用。

## 文件

- [AGENTS.md](./AGENTS.md): 代理人工作規範。
- [MVP.md](./MVP.md): 第一版可交付範圍。
- [TODO.md](./TODO.md): 待辦清單。
- [service-helper.html](./service-helper.html): 專案使用與操作教育文件。
- [docs/remove-openclaw-services.md](./docs/remove-openclaw-services.md): 刪除 OpenClaw 所有服務的安全流程。
- [.env.example](./.env.example): 私密環境設定範例。

## 安全注意

- 不要提交 `.env`、token、private key、密碼或內網敏感資訊。
- 設定範例請使用 placeholder，例如 `OPENCLAW_TEST_VM_HOST=192.0.2.10`。
- 執行更新、刪除、重啟服務等操作前，先確認影響範圍。
