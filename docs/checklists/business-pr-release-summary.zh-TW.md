# Super 8 Studio API Skills 商業與 PR 快速確認表

這份文件是主管快速掃描版，根據目前 repo 內容先填入預設值。需要主管定調或尚未在 repo 中確認的項目，標示為「待確認」。

## 發佈形式

- 發佈等級：待確認。
  - 可選：Internal only / Restricted beta / Public marketplace / Public announcement。
- 是否對外宣稱正式支援：待確認。
  - 建議：若 marketplace discovery、install、credential setup 尚未全部完成實測，先標示為 beta / preview / limited availability。
- 目標發佈日期：待確認。
- 是否配合產品、銷售或合作夥伴節奏：待確認。
- 發佈後商業負責人：待確認。
- 發佈後技術負責人：待確認。
- Support / incident 負責人：待確認。

## 品牌與產品名稱

- 正式產品名稱：`Super 8 Studio API Skills`。
- 正式 publisher / 公司名稱：`Super8`、`Super 8 Studio`。
- 官網 URL：`https://www.no8.io`。
- Public support contact：`platform@no8.io`。
- Brand color：`#2F6FED`。
- 正式 icon / logo / screenshot：待確認。
  - 目前 repo 中尚未偵測到 image assets。
  - 若要 public marketplace release，建議發佈前補齊或由主管確認本次可不提供。

## 法務與隱私

- Package license：`UNLICENSED`。
  - 是否可用於本次發佈：待確認。
- Privacy Policy URL：待確認。
  - 目前 Codex manifest 尚未包含此欄位。
  - 若要 public marketplace release，建議列為必填。
- Terms of Service URL：待確認。
  - 目前 Codex manifest 尚未包含此欄位。
  - 若要 public marketplace release，建議列為必填。
- Security reporting path：`SECURITY.md`。
  - 是否可公開：待確認。
- 對外資料限制：不可包含真實 Developer API token、Customer PII、內部 customer names、內部 organization names 或 org IDs、內部 request logs、未清理 screenshots。

## 發佈渠道

- GitHub repository URL：`https://github.com/8-interactive/super8-studio-api-skills`。
- Direct tarball download：目前 README 使用 `https://downloads.no8.io/...`。
- Codex marketplace：待確認是否作為本次正式渠道。
- Claude marketplace：待確認是否作為本次正式渠道。
- npm package：`@super8/studio-api-skills`。
  - 目前 visibility 設定：`restricted`。
  - 本次是否發 npm：待確認。
- Vercel `npx skills add`：待確認。
  - 建議：在工程完成實測前，不對外宣稱正式支援，只寫 compatibility target 或暫不提。
- Blog / release note / social announcement：待確認。

## 對外訊息界線

- 一句話定位：讓 AI agent 透過 Super 8 Studio Developer API 協助處理 CRM、conversation、customer、broadcast 與 marketing automation 工作。
- 是否提到 Developer API token：待確認。
  - 若提到，建議明確說明 token 由 Super 8 Console 建立。
- 是否提到 write actions：待確認。
  - 若提到，建議明確說明 write / outbound actions 需要使用者明確確認。
- 不應對外承諾：
  - Marketplace install 會自動完成 credential setup。
  - Agent 可繞過 Super 8 權限或 organization scope。
  - 支援未列出的 private / internal API。
  - Vercel `npx skills add` 已正式支援，除非工程實測完成。

## 主管需定調的關鍵項目

- [ ] 發佈等級：Internal only / Restricted beta / Public marketplace / Public announcement。
- [ ] 是否對外宣稱正式支援，或標示 beta / preview / limited availability。
- [ ] 正式 publisher / 公司名稱。
- [ ] Public support contact。
- [ ] Privacy Policy URL。
- [ ] Terms of Service URL。
- [ ] `UNLICENSED` 是否可用於本次發佈。
- [ ] 是否需要 icon / logo / screenshot。
- [ ] 本次啟用哪些發佈渠道。
- [ ] 是否需要 blog、release note、social announcement 或 PR。
- [ ] 發佈後 owner。
