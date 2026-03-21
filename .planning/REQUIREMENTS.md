# Requirements: Claude Code 自律開発設定

**Defined:** 2026-03-21
**Core Value:** タスクを指示したらPRまで自動で完結する — 人間が毎回承認ボタンを押さなくて済む

## v1 Requirements

### Permissions

- [ ] **PERM-01**: `git add`, `git commit`, `git push`, `git checkout`, `git worktree` が承認なしで実行できる
- [ ] **PERM-02**: `gh pr create`, `gh pr edit`, `gh run watch`, `gh run view` が承認なしで実行できる
- [ ] **PERM-03**: `npm`, `npx`, `node`, `yarn`, `pnpm`, `bun` が承認なしで実行できる
- [ ] **PERM-04**: `deny` ブロックに `git push --force`, `rm -rf`, `sudo`, `curl|bash` が明示登録されている
- [x] **PERM-05**: 既存の11個の `:*` 非推奨構文が `space *` 形式に移行されている
- [ ] **PERM-06**: `.planning/**` がサブエージェントからも書き込み可能 (sandbox allowWrite 拡張)

### Skills

- [ ] **SKIL-01**: `commit` スキルが `--auto` フラグ対応 — ブランチ確認・メッセージ確認・push確認をスキップ
- [ ] **SKIL-02**: `pr` スキルが `--auto` フラグ対応 — push確認・内容確認をスキップし自動でdraft PR作成

### Discoverability

- [ ] **DISC-01**: `rules/agents.md` にエージェント選択ガイドを追加 — シナリオ別に「どのエージェントを使うか」を明記
- [ ] **DISC-02**: `CLAUDE.md` から `@rules/agents.md` を import している

## v2 Requirements

### Resilience

- **RESI-01**: コンテキスト切れ時の状態引き継ぎ — JSON チェックポイントで `claude --continue` 再開
- **RESI-02**: CI ポーリングループ — PR 作成後に `gh run view` でグリーン待機

### Automation

- **AUTO-01**: テストゲート — コミット前にテストを実行し、3回失敗でブロック
- **AUTO-02**: レビューゲート — PR前に `parallel-review` を自動実行

## Out of Scope

| Feature | Reason |
|---------|--------|
| 独自の一気通貫スキル (feature-dev-auto 等) | `feature-dev@claude-plugins-official` と競合する — Phase 1-2 完了後に既存プラグインで評価 |
| main への自動マージ | CI・レビューゲートが安定するまでリスクが高い |
| Docker コマンドの許可 | 現時点で使用なし — 必要になってから追加 |
| グローバル settings への write 権限追加 | プロジェクトスコープで十分 — blast radius を限定する |

## Traceability

| Requirement | Phase | Status |
|-------------|-------|--------|
| PERM-01 | Phase 1 | Pending |
| PERM-02 | Phase 1 | Pending |
| PERM-03 | Phase 1 | Pending |
| PERM-04 | Phase 1 | Pending |
| PERM-05 | Phase 1 | Complete |
| PERM-06 | Phase 1 | Pending |
| SKIL-01 | Phase 2 | Pending |
| SKIL-02 | Phase 2 | Pending |
| DISC-01 | Phase 3 | Pending |
| DISC-02 | Phase 3 | Pending |

**Coverage:**
- v1 requirements: 10 total
- Mapped to phases: 10
- Unmapped: 0 ✓

---
*Requirements defined: 2026-03-21*
