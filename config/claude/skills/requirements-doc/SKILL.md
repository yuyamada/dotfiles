---
name: requirements-doc
description: >
  Drive a guided dialog to produce a complete Japanese 要件定義書 for a new
  service and save it as a Markdown file for team-internal sharing. Use when
  the user wants to define requirements for a new service, says things like
  "要件定義", "要件まとめて", "要件書きたい", "新サービス作る", "要件定義書つくって",
  "requirements", "PRD 書きたい", or describes a service they want to formalize
  into a spec. Make sure to use this skill whenever the user is in the early
  stage of a new service and needs to capture goals, users, features,
  non-functional requirements, and constraints — even if they don't explicitly
  say "要件定義". Output language is Japanese.
allowed-tools: Bash(date:*), Bash(git add:*), Bash(git status:*), Bash(git commit:*), Bash(mkdir:*), Read, Write, Edit
---

## Context

- Today's date: !`date +%Y-%m-%d`
- Detected git root: !`git rev-parse --show-toplevel 2>/dev/null || echo "not in a git repo"`
- Default save directory: `<git-root>/docs/requirements/` (created if missing)

## Overview

Guide the user through a section-by-section interview to produce a complete 要件定義書 for a new service. The output blends PRD-style "Why / What" sections with traditional Japanese 要件定義書 structure (機能要件, 非機能要件, 制約事項). All dialog and the produced document are in Japanese.

Four industry techniques are embedded:
- **5W1H** in the TL;DR section
- **MoSCoW** priority on every functional requirement
- **Given-When-Then** acceptance criteria per user story (recommended, not forced)
- **ISO/IEC 25010** seven categories as a non-functional checklist (no empty cells — N/A with reason if not applicable)

## Step 1: Establish service name and context

If the user already gave a service name in their initial message, use it. Otherwise ask:

> このサービスの名前（仮称でも可）を教えてください。

Derive a kebab-case ASCII slug from the name (ask the user if the romanization is ambiguous).

Then ask the **context-branching question** (multiple choice):

> 確認させてください。このサービスは:
> 1. 完全な新規（既存システムなし）
> 2. 既存システムの置き換え
> 3. 既存システムの拡張・連携

Remember the choice — it determines whether section "3. 現状システム構成" is included. For choice 1 (greenfield), drop section 3 entirely and renumber sections 4-12 as 3-11 in the output.

## Step 2: Section-by-section interview

Walk through sections in order. For each:
1. Ask the **core question** first
2. If the answer is too thin, ask up to 2 follow-up questions (3 questions max per section)
3. Show what was written and confirm before moving on

If the user says "あとで" / "TBD" / "未定" for any field, insert `<!-- TBD: <topic> -->` as a placeholder and continue. These will surface at the end as 未決事項.

### 1. 概要 (TL;DR)

Aim for 3-5 lines satisfying 5W1H. Core question:
> このサービスを 5W1H で簡潔に説明してください。誰が・いつ・どこで・何を・なぜ・どのように使いますか？

### 2. 背景・課題

Three subsections, ask in order:
- **2.1 現状 (As-Is) — ビジネス・運用視点**: 「今、ユーザーや業務はどう動いていますか？」
- **2.2 解決したい問題**: 「なぜ今これを作るのですか？」
- **2.3 やらない場合のリスク**: 「このサービスを作らなかったら何が起きますか？」

### 3. 現状システム構成 (As-Is Architecture) — conditional

Only ask this if the context choice in Step 1 was option 2 or 3.

- **3.1 システムマップ**: 「既存システムの主要コンポーネントを教えてください」
- **3.2 主要データフロー**: 「データはどこから入ってどこへ流れますか？」
- **3.3 既知の問題点**: 「現状システムで困っている点は？」
- **3.4 引き継ぐべき制約**: 「新システムでも維持しなければならない仕様は？」

### 4. スコープ

- **4.1 対象 (In-Scope)**: 「このサービスでカバーする範囲は？」
- **4.2 対象外 (Out-of-Scope)**: 「意図的にやらないことは？将来検討する項目も含めて挙げてください」

### 5. ターゲットユーザー

Start with: 「主なユーザーは何種類くらいいますか？」 Then for each persona, capture:
- 役職・属性
- 状況・コンテキスト
- 抱える課題
- 利用頻度

### 6. ユーザーストーリー & 受け入れ基準

Iterate: for each user story (US-1, US-2, ...):
> US-N の概要を聞かせてください。形式: 「<ペルソナ> として、<アクション> したい。<理由> のため。」

Then ask:
> このストーリーの受け入れ基準を Given-When-Then で書いておきますか？（推奨ですが必須ではありません）

If yes, fill at least one Given-When-Then triple. If no, leave the criteria empty for now.

After each US, ask: 「次のユーザーストーリーを追加しますか？」

### 7. 機能要件

Iterate: for each function:
1. 機能名
2. 説明（1-2 行）
3. 優先度 (MoSCoW) — ask with this 4-option choice:
   - **Must** — 必須
   - **Should** — 重要だが代替手段あり
   - **Could** — あれば嬉しい
   - **Won't** — 今期は対象外
4. 関連 US があれば紐付け（任意）

After each, ask: 「次の機能を追加しますか？」

### 8. 非機能要件 (ISO/IEC 25010)

Walk through all 7 categories in this order. For each, ask:
> <カテゴリ> についての要件はありますか？該当しない場合は「N/A」と理由を教えてください。

Categories: 性能効率性 / 信頼性 / セキュリティ / 使用性 / 保守性 / 互換性 / 移植性

For each non-N/A item, also ask: 「この要件をどう測定しますか？」 (測定方法 column)

Empty cells are not allowed — N/A with a reason is fine, but every row must have content.

### 9. 制約事項

Four subsections, ask in order:
- **9.1 前提条件**: 「成立を前提とする条件（既存システム稼働、SSO 認証済みなど）は？」
- **9.2 技術制約**: 「使用言語・フレームワーク・インフラの制約は？」
- **9.3 法令・社内規程**: 「個人情報保護法 / GDPR / 社内セキュリティポリシーなど守るべきものは？」
- **9.4 リソース・スケジュール制約**: 「人員・期日・予算の制約は？」

### 10. 成功指標 (KPI)

Ask first: 「このサービスの北極星指標 (NSM) は何ですか？」

Then for补助指標 (1-2 つ):
- 指標名
- 種別
- 目標値
- 計測タイミング

### 11. マイルストーン

Default to MVP / v1.0 / v1.1 unless the user has different phasing. For each phase:
- 内容
- 含む機能（F-N IDs を参照）
- 目標時期

### 12. 未決事項

Scan for any `<!-- TBD: ... -->` markers inserted during the interview. List each as a checklist:
- [ ] Q-N: <未決事項の内容>

If no TBD markers were inserted, leave the section with: `（現時点で未決事項なし）`

## Step 3: Preview and save

Show the user the full assembled document and confirm:
> 以下が要件定義書のドラフトです。`<save-path>` に保存してよいですか？

The save path is:
```
<git-root>/docs/requirements/<YYYY-MM-DD>-<service-slug>.md
```

Where `<YYYY-MM-DD>` is today's date (already in the Context section above) and `<service-slug>` is the kebab-case ASCII slug from Step 1.

If the directory doesn't exist, create it:
```bash
mkdir -p <git-root>/docs/requirements
```

If a file with that name already exists, ask:
> `<path>` は既に存在します。どうしますか？
> 1. 上書きする
> 2. 別名で保存 (`<service-slug>-v2.md`, `-v3.md`, ...)
> 3. キャンセル

Then write the file with the `Write` tool.

After saving:
1. Run `git add <path>`
2. Suggest the commit message: `docs(requirements): add <service-slug> requirements`
3. Ask: 「コミットしますか？」 — only run `git commit` if the user explicitly says yes.

## Step 4: Post-save guidance

After saving (and committing if requested):

1. Surface any 未決事項 as a numbered list
2. For each TBD, suggest a concrete next action (例: 「ステークホルダー X に確認」「技術調査タスクを issue 化」)
3. Note that the document is at version 0.1 — when significant changes happen, the user should bump the version in the metadata table and add a row to Appendix B (改訂履歴)

## Output Template

The output document uses this exact structure. Section numbers shift up by one if section 3 is dropped (greenfield case).

```markdown
# <サービス名> 要件定義書

| 項目 | 内容 |
|---|---|
| 作成日 | YYYY-MM-DD |
| 作成者 | <name or "未記入"> |
| ステータス | Draft |
| バージョン | 0.1 |

---

## 1. 概要 (TL;DR)

<3-5 行で 5W1H をカバー>

## 2. 背景・課題

### 2.1 現状 (As-Is) — ビジネス・運用視点
<...>

### 2.2 解決したい問題
<...>

### 2.3 やらない場合のリスク
<...>

## 3. 現状システム構成 (As-Is Architecture)

<※既存システム置換 / 拡張のときのみ含める>

### 3.1 システムマップ
<...>

### 3.2 主要データフロー
<...>

### 3.3 既知の問題点
<...>

### 3.4 引き継ぐべき制約
<...>

## 4. スコープ

### 4.1 対象 (In-Scope)
- <...>

### 4.2 対象外 (Out-of-Scope)
- <...>

## 5. ターゲットユーザー

### ペルソナ A: <役職・属性>
- 状況・コンテキスト: <...>
- 抱える課題: <...>
- 利用頻度: <...>

## 6. ユーザーストーリー & 受け入れ基準

### US-1: <タイトル>
**ストーリー**: <ペルソナ> として、<アクション> したい。<理由> のため。

**受け入れ基準** (Given-When-Then):
- Given <前提>
  When <操作>
  Then <結果>

## 7. 機能要件

| ID | 機能名 | 優先度 | 説明 | 関連 US |
|---|---|---|---|---|
| F-1 | <名前> | **Must** | <説明> | US-1 |

> 優先度 (MoSCoW): **Must**=必須 / **Should**=重要だが代替手段あり / **Could**=あれば嬉しい / **Won't**=今期は対象外

## 8. 非機能要件 (ISO/IEC 25010 ベース)

| カテゴリ | 要件 | 測定方法 |
|---|---|---|
| **性能効率性** | <...> | <...> |
| **信頼性** | <...> | <...> |
| **セキュリティ** | <...> | <...> |
| **使用性** | <...> | <...> |
| **保守性** | <...> | <...> |
| **互換性** | <...> | <...> |
| **移植性** | <...> | <...> |

> 該当しない項目は「N/A（理由：...）」で明示する。空欄禁止。

## 9. 制約事項

### 9.1 前提条件
- <...>

### 9.2 技術制約
- <...>

### 9.3 法令・社内規程
- <...>

### 9.4 リソース・スケジュール制約
- <...>

## 10. 成功指標 (KPI)

| 指標 | 種別 | 目標値 | 計測タイミング |
|---|---|---|---|
| <北極星指標> | NSM | <...> | 月次 |

## 11. マイルストーン

| フェーズ | 内容 | 含む機能 | 目標時期 |
|---|---|---|---|
| MVP (M0) | <最小実装> | F-1, F-2 | YYYY-MM |

## 12. 未決事項

- [ ] Q-1: <未決事項>

---

## Appendix

### A. 参考資料
- <設計の元になった調査・既存資料へのリンク>

### B. 改訂履歴
| 日付 | 版 | 変更内容 | 作成者 |
|---|---|---|---|
| YYYY-MM-DD | 0.1 | 初版 | <name> |
```

## Why this structure works

- **5W1H in TL;DR** forces a complete elevator pitch upfront — anyone reading the doc gets the gist from section 1 alone.
- **Conditional section 3** lets greenfield projects skip As-Is architecture without leaving an awkward empty chapter, while replacement / extension projects get a dedicated space for it.
- **MoSCoW priority embedded in the 機能要件 table** prevents priority discussions from getting stuck in the abstract — every function has a concrete bucket.
- **Given-When-Then per user story** creates testable acceptance criteria that map cleanly to QA work later, but it's recommended rather than forced so the doc doesn't bog down for simple stories.
- **Full ISO 25010 list with "N/A + reason" required** forces deliberate decisions about each quality attribute — empty space is not allowed, which catches commonly-forgotten requirements like 移植性 / 互換性.
- **Splitting 制約事項 into 4 subsections** (前提 / 技術 / 法令 / リソース) catches the constraint types that get forgotten in pure PRD-style docs.

## Edge cases

- **Many TBD answers**: don't pressure the user to complete every section in one sitting. Each TBD becomes a future task in 未決事項.
- **Very long answers**: summarize the answer back to the user before writing it to the doc.
- **Features without a clear US mapping**: leave the "関連 US" column empty rather than fabricating a story.
- **Non-Japanese mixed input**: keep technical terms in English (API names, framework names) but write surrounding prose in Japanese.
- **User wants to add a section not in the template**: append it as a new top-level `## <N>. <章名>` after section 11 and before 未決事項. Note in 改訂履歴.
