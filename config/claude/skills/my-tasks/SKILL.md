---
name: my-tasks
description: GitHub 上の自分のタスクをまとめて取得し、一覧表示する。Use when user says "タスク", "my tasks", "レビュー", "review", "PR一覧", "やること", or asks to check pending work.
---

# My Tasks

GitHub 上の自分のタスクをまとめて取得し、一覧表示する。

## 取得対象

1. **レビューリクエストされた PR**: `gh search prs --review-requested=@me --state=open`
2. **アサインされた Issue**: `gh search issues --assignee=@me --state=open`
3. **Project の In Review レーン**: 設定ファイルで指定された GitHub Projects から取得

## 設定

`~/.claude/skills/my-tasks/config.json` に org 名とプロジェクト番号を定義する:

```json
{
  "org": "<org_name>",
  "projects": [<project_number>, ...]
}
```

## 手順

1. まず `~/.claude/skills/my-tasks/config.json` を読み取り、org 名とプロジェクト番号を取得する
2. 以下のコマンドを**並列実行**する:

```bash
# レビューリクエストされた PR
gh search prs --review-requested=@me --state=open --json repository,title,number,url,author,updatedAt --limit 30

# アサインされた Issue
gh search issues --assignee=@me --state=open --json repository,title,number,url,author,updatedAt --limit 30

# 各プロジェクトの In Review アイテム（config.json の projects ごとに実行）
~/.claude/skills/my-tasks/scripts/gh-project-in-review.sh <org> <project_number>
```

3. 結果を以下のフォーマットでカテゴリ別にテーブル表示する:
   - レビュー待ち PR
   - Project 別の In Review アイテム
   - アサイン済み Issue
   - **注意**: タイトルに `[`, `]`, `(`, `)` が含まれる場合、Markdown のリンク記法と競合するため、タイトルはリンクにせず URL を別列に表示する
4. 最後に合計件数を表示する
