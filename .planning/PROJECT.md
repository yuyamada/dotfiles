# Claude Code 自律開発設定

## What This Is

Claude Code の設定 (dotfiles) を改善し、エージェントが人間の承認なしに「タスク指示 → コード実装 → テスト → PR」まで自律実行できる環境を整備するプロジェクト。権限プロンプトの排除、サブエージェント活用ガイドラインの整備、そして自律開発ワークフローの設計が主軸。

## Core Value

タスクを指示したらPRまで自動で完結する — 人間が毎回承認ボタンを押さなくて済む。

## Requirements

### Validated

- [x] Bash/シェルコマンドの許可リスト拡充 — git, npm/yarn/pnpm, test runner等を承認不要で実行できる (Validated in Phase 01: permissions-baseline)

### Active
- [ ] 自律開発スキル — タスク指示からPR作成まで一気通貫で動くスキル (`feature-dev` 相当)
- [ ] エージェント活用ガイドライン — どのエージェントをいつ使うかを明記したドキュメント (CLAUDE.md または rules/)
- [ ] サブエージェント構成パターン — 並列実行・専門化の具体的なレシピ (orchestrator + specialist)
- [ ] コンテキスト引き継ぎ戦略 — 長いタスクでコンテキストが切れても状態を引き継げる仕組み

### Out of Scope

- GUI/Web UI の構築 — dotfiles はCLIベース
- 他のマシンへの自動展開 — install.sh の手動実行で十分
- AI モデルの切り替え自動化 — 手動でモデル選択するだけで十分

## Context

- **既存資産:** 22個のGSDエージェント、8つのスキル、5つのルールファイルがすでに存在
- **最大の摩擦:** `settings.json` の `allowedTools` に開発系コマンドが未登録のため、毎回承認プロンプトが発生
- **エージェント認識不足:** agents/ にはplanner/executor/debugger等があるが、ユーザーがいつどれを使うか把握していない
- **GSD統合済み:** `gsd:execute-phase` 等の自律実行ワークフローはすでに存在するが、権限が追いついていない
- **セキュリティ:** sandboxは維持したい — ネットワーク制限は変えず、ファイルシステム書き込み制限も保持

## Constraints

- **Tech stack:** settings.json (JSON), CLAUDE.md (Markdown), rules/ (Markdown) — 新しいランタイム不要
- **Compatibility:** 既存のスキル・エージェント・フックを壊さない
- **Security:** sandbox の network/filesystem 制限は維持する

## Key Decisions

| Decision | Rationale | Outcome |
|----------|-----------|---------|
| 権限拡充はglobal settings vs local settings | グローバルに広げるとリスク — プロジェクト別で上書き可能な構造にする | — Pending |
| 自律スキルは新規作成 vs 既存スキル拡張 | feature-dev スキルがすでにあるが不完全 — 調査して判断 | — Pending |

## Evolution

This document evolves at phase transitions and milestone boundaries.

**After each phase transition** (via `/gsd:transition`):
1. Requirements invalidated? → Move to Out of Scope with reason
2. Requirements validated? → Move to Validated with phase reference
3. New requirements emerged? → Add to Active
4. Decisions to log? → Add to Key Decisions
5. "What This Is" still accurate? → Update if drifted

**After each milestone** (via `/gsd:complete-milestone`):
1. Full review of all sections
2. Core Value check — still the right priority?
3. Audit Out of Scope — reasons still valid?
4. Update Context with current state

---
*Last updated: 2026-03-21 — Phase 01 complete (permissions baseline established)*
