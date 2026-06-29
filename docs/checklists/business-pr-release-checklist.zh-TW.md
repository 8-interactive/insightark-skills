# SUPER 8 Studio InsightArk Skills 商業與 PR 發佈定調清單

這份文件提供給主管、CEO、法務與發佈負責人，用來確認是否可以對外發佈，以及要用什麼形式發佈。細部文案、素材製作與活動規劃交由行銷、PM 或平台負責人後續執行。

## 1. 發佈形式

- [ ] 確認本次發佈等級。
  - [ ] Internal only：只提供內部測試。
  - [ ] Restricted beta：提供給指定客戶或合作夥伴。
  - [ ] Public marketplace：公開上架。
  - [ ] Public announcement：公開宣傳或 PR。
- [ ] 確認本次是否要對外宣稱「正式支援」。
  - [ ] 是。
  - [ ] 否，先標示為 beta / preview / limited availability。
- [ ] 確認發佈時間點。
  - 目標日期：
  - 是否需要配合產品、銷售或合作夥伴節奏：
- [ ] 確認發佈後 owner。
  - 商業負責人：
  - 技術負責人：
  - Support / incident 負責人：

## 2. 品牌與產品名稱

- [ ] 確認正式產品名稱。
  - 目前建議：`SUPER 8 Studio InsightArk Skills`。
- [ ] 確認正式 publisher / 公司名稱。
  - 目前 repo 中出現：`Super8`、`SUPER 8 Studio`。
- [ ] 確認官網 URL。
  - 目前值：`https://www.no8.io`。
- [ ] 確認 public support contact。
  - 目前 metadata 中出現：`platform@no8.io`。
- [ ] 確認 brand color 是否可用。
  - 目前 Codex manifest 值：`#2F6FED`。
- [ ] 確認是否需要正式 icon / logo / screenshot 才能發佈。
  - [ ] 需要，公開前必須補齊。
  - [ ] 不需要，本次可先不附品牌素材。

## 3. 法務與隱私

- [ ] 確認 package license 策略。
  - 目前值：`UNLICENSED`。
  - [ ] 可用於本次發佈。
  - [ ] 發佈前需修改。
- [ ] 確認 Privacy Policy URL。
  - URL：
  - [ ] 已核准。
  - [ ] 尚未核准，不可公開上架。
- [ ] 確認 Terms of Service URL。
  - URL：
  - [ ] 已核准。
  - [ ] 尚未核准，不可公開上架。
- [ ] 確認 security reporting path 是否可公開。
  - 目前文件：`SECURITY.md`。
- [ ] 確認對外資料不可包含下列內容。
  - [ ] 真實 Developer API token。
  - [ ] Customer PII。
  - [ ] 內部 customer names。
  - [ ] 內部 organization names 或 org IDs。
  - [ ] 內部 request logs。
  - [ ] 未清理 screenshots。

## 4. 發佈渠道

- [ ] 確認本次要啟用哪些渠道。
  - [ ] Direct tarball download。
  - [ ] Codex marketplace。
  - [ ] Claude marketplace。
  - [ ] npm package。
  - [ ] Vercel `npx skills add`。
  - [ ] Blog / release note / social announcement。
- [ ] 確認 GitHub repository 是否可對外使用。
  - 目前 URL：`https://github.com/8-interactive/insightark-skills`。
- [ ] 確認 npm package visibility。
  - 目前 package：`@8-interactive/insightark-skills`。
  - 目前設定：`restricted`。
  - [ ] Restricted。
  - [ ] Public。
  - [ ] 暫不發 npm。
- [ ] 確認 download artifact host。
  - 目前 host：`https://downloads.no8.io/...`。
- [ ] 確認 Vercel `npx skills add` 是否可以對外宣稱支援。
  - [ ] 可以，已完成實測。
  - [ ] 不可以，只能寫 compatibility target 或暫不提。

## 5. 對外訊息界線

- [ ] 確認一句話定位。
  - 建議方向：讓 AI agent 透過 SUPER 8 Studio Developer API 協助處理 CRM、conversation、customer、broadcast 與 marketing automation 工作。
- [ ] 確認對外是否要提到 Developer API token。
  - [ ] 要，並清楚說明 token 由 Super 8 Console 建立。
  - [ ] 不要，交由 setup 文件說明。
- [ ] 確認對外是否要提到 write actions。
  - [ ] 要，並說明 write/outbound actions 需要使用者明確確認。
  - [ ] 不要，交由技術文件說明。
- [ ] 確認不得對外承諾的事項。
  - [ ] Marketplace install 會自動完成 credential setup。
  - [ ] Agent 可繞過 Super 8 權限或 organization scope。
  - [ ] 支援未列出的 private/internal API。
  - [ ] Vercel `npx skills add` 已正式支援，除非工程實測完成。

## 6. 發佈前必須完成的商業阻塞項目

- [ ] 正式產品名稱已核准。
- [ ] Publisher / 公司名稱已核准。
- [ ] Public support contact 已核准。
- [ ] Privacy Policy URL 已核准。
- [ ] Terms of Service URL 已核准。
- [ ] License 策略已核准。
- [ ] 發佈渠道已定案。
- [ ] 對外是否標示 beta / preview / GA 已定案。
- [ ] 是否需要 PR announcement 已定案。
- [ ] 發佈後 owner 已定案。

## 7. 主管簽核

| 項目 | 負責人 | 狀態 | 備註 |
| --- | --- | --- | --- |
| 發佈形式 |  | [ ] 已核准 |  |
| 品牌與產品名稱 |  | [ ] 已核准 |  |
| Privacy / Terms |  | [ ] 已核准 |  |
| License 策略 |  | [ ] 已核准 |  |
| 發佈渠道 |  | [ ] 已核准 |  |
| 對外訊息界線 |  | [ ] 已核准 |  |
| Public support owner |  | [ ] 已核准 |  |
| PR / announcement |  | [ ] 已核准 |  |
