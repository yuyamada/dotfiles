---
name: github-upload-image
description: ローカルの画像ファイルを GitHub CDN にアップロードして URL を取得する。Issue/PR コメントに画像を埋め込みたいときに使う。
---

# GitHub 画像アップロード

ローカルの画像ファイルを GitHub にアップロードして CDN URL を取得し、Issue や PR のコメントに埋め込む。

## 使用ツール

Playwright MCP（`mcp__plugin_playwright_playwright__*`）を使用する。

## 手順

### 1. 対象 Issue/PR ページを開く

```
browser_navigate: https://github.com/{org}/{repo}/issues/{number}
```

### 2. ファイルアップロードボタンをクリック

コメント欄の「Paste, drop, or click to add files」ボタンを JavaScript でクリックする:

```js
// browser_evaluate
() => {
  const btn = Array.from(document.querySelectorAll('button')).find(b => b.textContent.includes('Paste, drop'));
  btn?.click();
  return !!btn;
}
```

File chooser が開いたら `browser_file_upload` で画像をアップロードする:

```
browser_file_upload: ["/absolute/path/to/image.png"]
```

複数ファイルをアップロードする場合は手順 2〜3 を繰り返す（1ファイルずつ）。

### 3. テキストエリアから URL を取得

アップロード後、テキストエリアに GitHub CDN の img タグが挿入される:

```js
// browser_evaluate
() => {
  const textarea = document.querySelector('textarea[placeholder*="Markdown"]') || document.querySelector('textarea');
  return textarea?.value || '';
}
```

結果例:
```
<img width="2560" height="968" alt="Image" src="https://github.com/user-attachments/assets/xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx" />
```

取得した URL: `https://github.com/user-attachments/assets/xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx`

### 4. URL をコメントに埋め込む

取得した URL を使って `gh api` でコメントを投稿・編集する:

```bash
# 新規コメント
gh api --method POST repos/{org}/{repo}/issues/{number}/comments \
  -f body="![説明](https://github.com/user-attachments/assets/xxxxxxxx-...)"

# 既存コメントを編集
gh api --method PATCH repos/{org}/{repo}/issues/comments/{comment_id} \
  -f body="更新後の本文（画像URL埋め込み済み）"
```

## 注意事項

- アップロード後にテキストエリアをクリアしないと次回アップロード時に内容が蓄積される
- GitHub にログイン済みのブラウザセッションが必要
