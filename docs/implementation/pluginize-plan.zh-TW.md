# Pluginize 計劃與差異分析（Claude Code / OpenAI Codex）

> 參考規格：
> - Claude Code Plugins Reference — https://code.claude.com/docs/zh-TW/plugins-reference
> - Claude Code Plugin Marketplaces — https://code.claude.com/docs/zh-TW/plugin-marketplaces
> - OpenAI Codex Build Plugins — https://developers.openai.com/codex/plugins/build

## 0. 結論（TL;DR）

**目前架構已約 90% 完成 pluginize，且兩個生態系的 manifest 都已驗證通過**
（`claude plugin validate .` → ✔ Validation passed）。

差異**不在「能不能載入」，而在「安裝體驗、發佈韌性、與品牌完整度」**：

- ✅ 結構合規：Claude / Codex 雙 manifest + 雙 marketplace 皆存在且 schema 正確。
- ✅ 執行正確：19 個 skill 透過 `../_super8-studio-api-shared/scripts/*` 共用腳本；腳本以 `$(dirname "$0")` / `BASH_SOURCE` 自我定位、憑證從 `$HOME` 與 cwd 載入，**複製到 plugin cache 後仍可運作**。
- ⚠️ 主要落差：**憑證安裝仍是手動流程**（`install.sh` + `setup-env.sh` + `~/.super8-studio.env`），未使用 plugin 原生的 `userConfig` / SessionStart hook。
- ⚠️ 次要落差：版本雙寫陷阱、相對路徑來源的發佈限制、Codex 品牌/法務欄位未填、無 MCP/hooks（屬設計選擇）。

---

## 1. 現況盤點

| 元件 | 路徑 | 狀態 |
| :-- | :-- | :-- |
| Claude plugin manifest | `.claude-plugin/plugin.json` | ✅ name/version/skills 齊全 |
| Claude marketplace | `.claude-plugin/marketplace.json` | ✅ 單一 plugin，`source: "./"` |
| Codex plugin manifest | `.codex-plugin/plugin.json` | ✅ 含 `interface` 物件 |
| Codex repo marketplace | `.agents/plugins/marketplace.json` | ✅ `source.local + path:"./"` |
| Skills | `skills/super8-studio-*/SKILL.md` ×19 | ✅ frontmatter name 對齊資料夾 |
| 共用腳本 | `skills/_super8-studio-api-shared/scripts/` | ✅ 底線前綴不被當 skill |
| 安裝 | `install.sh` / `setup-env.sh` / npm CLI | ⚠️ 手動憑證流程 |

整個 repo 同時扮演 **plugin 本體**與 **marketplace 根目錄**（`source: "./"`），是合法的 marketplace-root 模式。

---

## 2. 與規格的逐項差異

### A. 已符合（無需動作）
- Claude：`plugin.json` 唯一必填 `name` ✓；`skills:"./skills/"` 指向預設目錄，不觸發警告。
- Claude marketplace：`name`/`owner`/`plugins` 必填皆有 ✓。
- Codex：唯一必填 `.codex-plugin/plugin.json` ✓；`interface` 欄位齊全（displayName/shortDescription/longDescription/developerName/category/capabilities/websiteURL/brandColor/defaultPrompt）。
- 路徑規則：所有元件路徑以 `./` 開頭、位於 plugin root 內 ✓。

### B. 建議強化（提升安裝體驗，價值最高）
1. **以 `userConfig` 取代手動 env 檔（Claude）**
   - 宣告 `S8_API_URL`（string）與 `S8_SESSION_TOKEN`（string, `sensitive:true`）。
   - 啟用時自動提示；敏感值進系統 keychain；腳本可用 `${user_config.*}` 或 `CLAUDE_PLUGIN_OPTION_*` 取得。
   - 移除使用者手動編輯 `~/.super8-studio.env` 的負擔（保留為 fallback）。
2. **SessionStart hook 做就緒檢查**
   - `hooks/hooks.json` 在 SessionStart 跑 `doctor.sh --soft-fail`，提早提示憑證缺失。
3. **Codex 對應**：以 `interface` + `channels/userConfig`（或既有 `setup-env.sh`）提供等價提示流程。

### C. 維護陷阱（低成本修掉）
1. **版本雙寫**：`version` 同時寫在 `plugin.json` 與 marketplace entry。規格警告 plugin.json 會靜默勝出，易造成 marketplace 版本被遮蔽。
   - 建議：保留 `plugin.json` 為單一真實來源，marketplace entry 移除 `version`（或維持 `validate-skills.sh` 強制相等的現狀並加註解）。
2. **單一 plugin 綁定全部 skill 的限制**：共用腳本靠相對路徑 `../_super8-studio-api-shared`。
   - 只要維持「一個 plugin 包全部 skill」就安全；**若未來拆成一 skill 一 plugin，相對路徑會因各自複製到 cache 而斷裂**，需改用 symlink 或共用 MCP。需在文件明列此約束。

### D. 發佈韌性（distribution）
1. **相對路徑來源 `"./"` 僅在 Git 方式新增 marketplace 時有效**；以直接 URL 提供 `marketplace.json` 會失敗。
   - 建議官方安裝指令統一為 GitHub 簡寫：`/plugin marketplace add 8-interactive/insightark-skills`。
2. **私有 repo 自動更新**：需設定 `GITHUB_TOKEN`；於 README/文件補充。
3. **`defaultEnabled`**：因連外部 API，可評估設 `false` 讓使用者明確 opt-in（需 CC v2.1.154+）。

### E. 品牌與法務（Codex marketplace 上架完整度）
- `interface` 可補：`privacyPolicyURL`、`termsOfServiceURL`、`logo`、`composerIcon`、`screenshots`，並將資產置於 `./assets/`。

---

## 3. 分階段計劃

> 原則：可逆 commit、每階段後跑 `npm run validate` 與 `claude plugin validate .`。

**Phase 1 — 憑證原生化（影響最大）**
- [ ] Claude `plugin.json` 加 `userConfig`（`S8_API_URL`、`S8_SESSION_TOKEN sensitive`）。
- [ ] 共用腳本 `lib/env.sh` 在讀檔 fallback 前，優先採用 `CLAUDE_PLUGIN_OPTION_*` / 環境變數。
- [ ] 新增 `hooks/hooks.json`：SessionStart → `doctor.sh --soft-fail`。
- [ ] Codex `interface` 補對應提示（或文件指向 `setup-env.sh`）。

**Phase 2 — 維護陷阱**
- [ ] 統一版本單一來源；更新 `validate-skills.sh` 規則與註解。
- [ ] 在 `skill-authoring-guide.md` 明列「相對路徑共用腳本」約束與未來拆分指引。

**Phase 3 — 發佈與品牌**
- [ ] README/文件：統一 Git 安裝指令、私有 repo token 說明。
- [ ] 評估 `defaultEnabled:false`。
- [ ] 補 Codex 品牌/法務欄位與 `./assets/`。

**Phase 4（選配）— MCP 路線評估**
- [ ] 評估將 SUPER 8 Studio Developer API 包成 plugin 內建 MCP server（取代 bash 腳本的長期路線），可同時供 Claude 與 Codex 使用，並解除相對路徑共用限制。

---

## 4. 驗證方式
- `npm run validate`（既有 `scripts/validate-skills.sh`）。
- `claude plugin validate .`（marketplace）與 `claude plugin validate ./`（plugin 本體 + skill/agent/hook frontmatter）。
- 本機端對端：`/plugin marketplace add ./` → `/plugin install insightark-skills@super8-studio` → 跑 `super8-studio-session` 驗證憑證提示流程。
