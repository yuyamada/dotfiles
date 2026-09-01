---
name: my-tasks
description: GitHub 上の自分のタスクをまとめて取得し、一覧表示する。Use when user says "タスク", "my tasks", "レビュー", "review", "PR一覧", "やること", or asks to check pending work.
---

# My Tasks

GitHub 上の自分のタスクをまとめて取得し、一覧表示する。

## 取得対象

1. **レビューリクエストされた PR**: 自分の最終レビュー日時つき
2. **アサインされた Issue**
3. **Project の In Review レーン**: 設定ファイルで指定された GitHub Projects から取得（ページネーション対応、`state == OPEN` のもののみ）
4. **自分がオーナーの Open PR**: レビュー状態（reviewDecision / mergeable / CI）と、他者からの最終レビュー日時つき

すべての項目が `updatedAt` を持ち、表示は「Xm/h/d ago」のような相対時刻を使う。

## アーキテクチャ: バックグラウンドキャッシュ優先

このスキルは2つのレイヤーで構成されている。

### 1. 取得（LLM トークン不使用）

`scripts/fetch-status.sh` が `gh`/`jq` だけで完結する形で上記データを取得し、`~/.cache/my-tasks/status.json` に書き出す。

- `~/Library/LaunchAgents/com.my-tasks.fetch.plist`（`./install.sh my-tasks` で登録、テンプレートは `com.my-tasks.fetch.plist.template`）が **1分ごと** に自動実行する
- 手動で即座に更新したい場合は `mtf` エイリアス（`~/.config/zsh/aliases.sh` に定義）、または `~/.claude/skills/my-tasks/scripts/fetch-status.sh` を直接実行する

### 2. 表示

`scripts/render-status.sh` が `status.json` を読み、OSC 8 のクリック可能なリンクと SGR カラー付きで整形する。`watch -c` は SGR しか解釈せず OSC 8 を握りつぶすため使わず、常駐表示には次のような単純な再描画ループを使う:

```bash
while true; do clear; ~/.claude/skills/my-tasks/scripts/render-status.sh; sleep 10; done
```

herdr 環境では、専用ワークスペースを作ってこのループを常駐させるとよい（`herdr workspace create --label my-tasks --no-focus` → `herdr pane run <pane_id> "..."`）。

### 3. Claude からの参照

ユーザーから「タスク見せて」等と言われた場合、まず `~/.cache/my-tasks/status.json` の `fetchedAt` を確認する。直近（目安5分以内）なら **gh を叩き直さず** この JSON を `Read`/`jq` して回答する。古い、またはファイルが存在しない場合は `fetch-status.sh` を実行してから読む。

## 設定

`~/.claude/skills/my-tasks/config.json` に org 名とプロジェクト番号を定義する:

```json
{
  "org": "<org_name>",
  "projects": [<project_number>, ...]
}
```

## 認証について（重要）

`gh` の生バイナリは、対話シェルの `ghtkn exec -e GH_TOKEN:readonly -- gh` ラッパーを経由しない限り、書き込み可能スコープ（`repo`, `workflow` 等）を含むフォールバック token を使ってしまう。launchd やこのスキルのスクリプトを直接実行する場合はこのラッパーを経由しない。

そのため `fetch-status.sh` と `gh-project-in-review.sh` は冒頭で次のガードを持つ:

```bash
if [[ -z "${GH_TOKEN:-}" ]]; then
  exec ghtkn exec -e GH_TOKEN:readonly -- "$0" "$@"
fi
```

呼び出し元（対話シェル / launchd / cron のどれか）に関わらず readonly token のみを使うようにするためのものなので、この仕組みを壊さないこと。

## Project ボードのページネーションについて

GitHub GraphQL の `items` connection は `first` の上限が100件（`first: 500` 等を指定すると `EXCESSIVE_PAGINATION` エラーになる）。ボードの総アイテム数が100件を超える場合、`--paginate` で全ページを回収してから外部の `jq -s` で結合・フィルタする必要がある(`gh api --paginate` は `--jq` と `--slurp` を併用できない制約があるため、生ページをまず出力し、そのあと `jq -s` に通す2段構えにする)。`gh-project-in-review.sh` はこの対応済み。

## キャッシュがない場合のフォールバック（その場で gh を叩く）

初回セットアップ前など `status.json` が存在しない場合は、以下を並列実行してその場で組み立てる:

```bash
gh search prs --review-requested=@me --state=open --owner <org> --json repository,title,number,url,author,updatedAt --limit 30
gh search issues --assignee=@me --state=open --owner <org> --json repository,title,number,url,author,updatedAt --limit 30
~/.claude/skills/my-tasks/scripts/gh-project-in-review.sh <org> <project_number>
```

## 表示フォーマット

- レビュー待ち PR / Project 別 In Review / アサイン済み Issue / 自分の Open PR（reviewDecision と mergeable から優先度付け: CHANGES REQUESTED > MERGE NOW > DRAFT > AWAITING REVIEW）の順にカテゴリ表示
- 各項目に `(updated Xm/h/d ago)` を付ける。PR にはさらに最終レビューの相対時刻 `(last review Xm/h/d ago)` を付ける
- タイトルに `[`, `]`, `(`, `)` が含まれる場合、Markdown のリンク記法と競合するため、タイトルはリンクにせず URL を別列に表示する(ターミナル表示の場合は OSC 8 でタイトル自体をハイパーリンク化する)
- 最後に合計件数を表示する
