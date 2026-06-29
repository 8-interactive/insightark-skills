# Super 8 Studio API Skills 技術發佈檢查清單

這份文件提供給負責開發、維運、CI/CD、package 與 release 的工程師，在發佈前做最後技術檢查。目標是確認 repo、package、安裝流程、API 環境與安全邊界都已達到可發佈狀態。

## 發佈狀態

- [ ] 確認本次發佈類型。
  - [ ] Internal test。
  - [ ] Restricted beta。
  - [ ] Public marketplace release。
- [ ] 確認目標 release channel。
  - [ ] Staging release，來源 branch 為 `staging`。
  - [ ] Production release，來源 branch 為 `main`。
- [ ] 確認 git working tree 乾淨。
  - [ ] 沒有 modified files。
  - [ ] 沒有 untracked release files。
  - [ ] 沒有 local-only generated files 被誤包。
- [ ] 確認 release branch 與 CI/CD 設定一致。
  - 目前 release script 預期 `DRONE_BRANCH=staging` 或 `DRONE_BRANCH=main`。

## 版本與 Manifest 一致性

- [ ] 確認版本號一致。
  - 目前預期版本：`1.0.0`。
  - 檢查檔案：
    - `package.json`
    - `.codex-plugin/plugin.json`
    - `.claude-plugin/plugin.json`
    - `.claude-plugin/marketplace.json`
    - `skills/_super8-studio-api-shared/VERSION`
- [ ] 確認 `.codex-plugin/plugin.json` 的 `skills` 指向 `../skills/`。
- [ ] 確認 `.claude-plugin/plugin.json` 的 `skills` 指向 `../skills/`。
- [ ] 確認 `.agents/plugins/marketplace.json` 的 source path 指向 repo root。
- [ ] 確認 `.claude-plugin/marketplace.json` 的 source 指向 repo root。
- [ ] 確認 `package.json` 的 `bin.super8-studio-api-skills` 指向存在的 CLI adapter。
- [ ] 確認 package `files` 欄位包含必要內容：
  - [ ] `.codex-plugin/`
  - [ ] `.claude-plugin/`
  - [ ] `skills/`
  - [ ] `docs/`
  - [ ] `installer/`
  - [ ] `scripts/`
  - [ ] `install.sh`
  - [ ] `setup-env.sh`
  - [ ] `uninstall.sh`
  - [ ] `README.md`
  - [ ] `SECURITY.md`
  - [ ] `CHANGELOG.md`

## 技能 Bundle 與 Shared Runtime

- [ ] 確認 `skills/` 是唯一 canonical skills payload。
- [ ] 確認每個 `skills/super8-studio-*/SKILL.md` 都有 frontmatter。
- [ ] 確認每個 skill folder name 與 frontmatter `name` 相同。
- [ ] 確認每個 skill 都有足夠清楚的 `description`。
- [ ] 確認 `_super8-studio-api-shared/` 是 shared runtime，不應被當成可觸發 skill。
- [ ] 確認 shared scripts 的 executable permissions 在 package 後仍保留。
- [ ] 確認 read-only skills 沒有引導 mutation。
- [ ] 確認 write-action skills 都要求明確使用者確認。
- [ ] 確認 skill examples 沒有真實 customer ID、org ID、token 或內部資料。

## 安裝流程驗證

- [ ] 確認 direct tarball install 仍為支援通路。
  - 預期流程：下載 tarball、解壓縮、執行 `./install.sh`，再執行 `./setup-env.sh`。
- [ ] 確認 `install.sh` 會複製完整 `skills/`。
- [ ] 確認 `install.sh` 會寫入 install registry。
  - Registry path：`~/.super8-studio.config`。
- [ ] 確認 `setup-env.sh` 可設定 credentials。
- [ ] 確認 `uninstall.sh` 可依 registry 或指定 target 移除技能。
- [ ] 確認 marketplace installs 不被文件描述成會執行 `install.sh`。
- [ ] 確認 credential setup 在 marketplace installs 中仍是 follow-up step。
- [ ] 確認 Windows 文件指示使用 Git Bash 或 WSL。

## 發佈通路技術狀態

- [ ] Codex marketplace metadata 可被解析。
  - 檢查 `.codex-plugin/plugin.json`。
  - 檢查 `.agents/plugins/marketplace.json`。
- [ ] Claude marketplace metadata 可被解析。
  - 檢查 `.claude-plugin/plugin.json`。
  - 檢查 `.claude-plugin/marketplace.json`。
- [ ] npm package 可 dry run。
  - 目前 package name：`@8-interactive/insightark-skills`。
  - 目前 `publishConfig.access`：`restricted`。
- [ ] Vercel `npx skills add` 仍標示為 compatibility target。
  - 在 `docs/implementation/vercel-skills-add.md` open questions 解完前，不應宣稱正式支援。
- [ ] 確認 download URLs 與發佈 channel 對應。
  - Staging：`https://downloads.no8.io/staging/releases/skills/super8-studio-api-skills-latest.tar.gz`
  - Production：`https://downloads.no8.io/main/releases/skills/super8-studio-api-skills-latest.tar.gz`

## 必跑驗證命令

- [ ] 執行 static validation：

```bash
bash scripts/validate-skills.sh
```

- [ ] 確認 validation 沒有任何 failure。
- [ ] 執行 package CLI help：

```bash
node scripts/super8-skills-cli.js --help
```

- [ ] 執行 npm package dry run：

```bash
npm_config_cache=/tmp/super8-npm-cache npm pack --dry-run
```

- [ ] 確認 package contents 沒有 local-only files 或 credentials。
- [ ] 使用暫存 `HOME` 執行 direct install smoke test：

```bash
mkdir -p /tmp/super8-publish-home
HOME=/tmp/super8-publish-home ./install.sh --target /tmp/super8-skills-publish-check
```

- [ ] 確認暫存 install target 的 top-level bundle 目錄與 `skills/` 一致。
- [ ] 確認 registry file 有寫入暫存 home：

```bash
cat /tmp/super8-publish-home/.super8-studio.config
```

## API 環境與 Org 驗證

- [ ] 確認 production API URL。
  - 目前值：`https://api-next.no8.io`。
- [ ] 確認 production Console URL。
  - 目前值：`https://console.no8.io`。
- [ ] 確認 staging API URL。
  - 目前值：`https://stage-api-next.no8.io`。
- [ ] 確認 staging Console URL。
  - 目前值：`https://stage-console.no8.io`。
- [ ] 確認 `installer/write-release.sh` 產生的 channel 與 API URL 正確。
- [ ] 確認可從 Super 8 Console 建立測試用 Developer API token。
  - README 文件中的 Console path：Account Settings -> Developer API。
- [ ] 確認 setup flow 可列出 Developer API enabled organizations。
  - 可使用 `./setup-env.sh` 或 `super8-studio-org-scope` skill 驗證。
- [ ] 確認 `S8_ORG_ID` 行為正確。
  - `S8_ORG_ID` 是 optional。
  - Org-scoped routes 仍需要明確 org context。
- [ ] 確認 token expiration policy 與文件一致。
  - 目前文件寫明 token 六個月後到期。

## 安全與敏感資料檢查

- [ ] 確認 repo 中沒有 `.super8-studio.env`。
- [ ] 確認 repo 中沒有真實 `_SessionToken` 或 `S8_SESSION_TOKEN`。
- [ ] 確認 package 內容沒有：
  - [ ] 真實 Developer API token。
  - [ ] Customer PII。
  - [ ] 內部 customer names。
  - [ ] 內部 request logs。
  - [ ] 包含 token、org ID、customer ID 或私有資料的 screenshots。
- [ ] 確認 `setup-env.sh` 寫出的 credential files 權限為 `600`。
- [ ] 確認 API 回應內容在 skill 指示中被視為 data，不會覆蓋 system/developer/repo/skill instructions。
- [ ] 確認 outbound 或 destructive actions 都需要使用者明確確認。
- [ ] 確認沒有把真實 `skills/_super8-studio-api-shared/RELEASE` commit 進 repo。
  - `RELEASE` 應只在 release packaging 時產生。
  - `RELEASE.example` 可以保留在 repo。

## 文件技術審查

- [ ] 審查 `README.md`。
  - [ ] Install flow 正確。
  - [ ] Download URLs 正確。
  - [ ] Supported agents 正確。
  - [ ] Setup 與 security notes 正確。
- [ ] 審查 `Introduction.html`。
  - [ ] Repository URL 正確。
  - [ ] Download URLs 正確。
  - [ ] 沒有過期產品文案。
  - [ ] 沒有 internal-only instructions。
- [ ] 審查 `docs/implementation/install-flow-contract.md`。
  - [ ] Install registry behavior 正確。
  - [ ] Marketplace install assumptions 正確。
- [ ] 審查 `docs/implementation/distribution-implementation-guide.md`。
  - [ ] Distribution matrix 正確。
  - [ ] Known open questions 對本次 release type 可接受。
- [ ] 審查 `docs/implementation/plugin-release-process.md`。
  - [ ] Release checklist 符合實際 CI/CD。
- [ ] 審查 `docs/implementation/vercel-skills-add.md`。
  - [ ] 在完成驗證前，仍標示為 compatibility target。
- [ ] 審查 `CHANGELOG.md`。
  - [ ] Version notes 與本次 release 相符。
- [ ] 審查 `SECURITY.md`。
  - [ ] Security policy 適合本次 release audience。

## 技術阻塞項目

- [ ] 修正 `Introduction.html` 與 package/manifest metadata 之間的 repository URL 不一致。
- [ ] 驗證實際 Codex marketplace discovery flow。
- [ ] 驗證實際 Claude marketplace discovery flow。
- [ ] 驗證 Vercel `npx skills add` 行為後，才能對外宣稱支援此通路。
- [ ] 新增或確認 CI workflow 會執行 release smoke tests。
- [ ] 確認 package 後 shell scripts executable permissions 未遺失。
- [ ] 確認 production/staging release artifact 產生流程可重現。

## 工程簽核表

| 項目 | 負責人 | 狀態 | 備註 |
| --- | --- | --- | --- |
| Git working tree clean |  | [ ] 已確認 |  |
| Version sync |  | [ ] 已確認 |  |
| Manifest validation |  | [ ] 已確認 |  |
| Skill bundle validation |  | [ ] 已確認 |  |
| npm package dry run |  | [ ] 已確認 |  |
| Direct install smoke test |  | [ ] 已確認 |  |
| API environment check |  | [ ] 已確認 |  |
| Credential setup check |  | [ ] 已確認 |  |
| Sensitive data scan |  | [ ] 已確認 |  |
| Release artifact check |  | [ ] 已確認 |  |
