#!/usr/bin/env python3
"""Claude Code Stop hook: 会話ターンを Langfuse に送信する。

- TRACE_TO_LANGFUSE=true のときだけ動作する (未設定時はサイレントに no-op)
- Langfuse の公開 ingestion API (stdlib urllib のみ) を使うため追加依存なし
- セッション単位で last_processed_uuid を ~/.claude/langfuse-state/ に保存し、
  新しいアシスタント応答ぶんだけを 1 トレースとして送信する
- ネットワーク失敗時は state を更新せず次回再送を試みる (簡易リトライ)
- 例外で Claude Code を止めないよう最外で握り潰す

参考: https://langfuse.com/integrations/other/claude-code
"""
from __future__ import annotations

import base64
import json
import os
import sys
import urllib.error
import urllib.request
import uuid
from datetime import datetime, timezone
from pathlib import Path
from typing import Any, Iterable

STATE_DIR = Path.home() / ".claude" / "langfuse-state"
TIMEOUT_SEC = 5


def _now_iso() -> str:
    return datetime.now(timezone.utc).isoformat()


def _stringify(content: Any) -> str:
    """Claude Code transcript の content は string か block list になりうる。"""
    if isinstance(content, str):
        return content
    if isinstance(content, list):
        parts: list[str] = []
        for block in content:
            if not isinstance(block, dict):
                continue
            btype = block.get("type")
            if btype == "text":
                parts.append(block.get("text", ""))
            elif btype == "tool_use":
                name = block.get("name", "")
                tool_input = block.get("input", {})
                parts.append(f"[tool_use: {name}]\n{json.dumps(tool_input, ensure_ascii=False)}")
            elif btype == "tool_result":
                parts.append(f"[tool_result]\n{_stringify(block.get('content', ''))}")
        return "\n\n".join(p for p in parts if p)
    return json.dumps(content, ensure_ascii=False)


def _read_transcript(path: Path) -> list[dict[str, Any]]:
    entries: list[dict[str, Any]] = []
    with path.open("r", encoding="utf-8") as f:
        for line in f:
            line = line.strip()
            if not line:
                continue
            try:
                entries.append(json.loads(line))
            except json.JSONDecodeError:
                continue
    return entries


def _state_path(session_id: str) -> Path:
    safe = "".join(c for c in session_id if c.isalnum() or c in "-_") or "default"
    return STATE_DIR / f"{safe}.json"


def _load_state(session_id: str) -> dict[str, Any]:
    p = _state_path(session_id)
    if not p.exists():
        return {}
    try:
        return json.loads(p.read_text(encoding="utf-8"))
    except (OSError, json.JSONDecodeError):
        return {}


def _save_state(session_id: str, state: dict[str, Any]) -> None:
    STATE_DIR.mkdir(parents=True, exist_ok=True)
    _state_path(session_id).write_text(
        json.dumps(state, ensure_ascii=False), encoding="utf-8"
    )


def _new_entries(
    entries: list[dict[str, Any]], last_uuid: str | None
) -> list[dict[str, Any]]:
    if last_uuid is None:
        return entries
    for i, entry in enumerate(entries):
        if entry.get("uuid") == last_uuid:
            return entries[i + 1 :]
    # 過去の uuid が見当たらない (transcript が剪定された等) → 全件扱い
    return entries


def _extract_turn(new_entries: Iterable[dict[str, Any]]) -> tuple[str, str]:
    """新しく追加された entries から user 入力 / assistant 出力を抽出。"""
    user_parts: list[str] = []
    assistant_parts: list[str] = []
    for entry in new_entries:
        etype = entry.get("type")
        msg = entry.get("message") or {}
        content = msg.get("content")
        text = _stringify(content) if content is not None else ""
        if not text:
            continue
        if etype == "user":
            user_parts.append(text)
        elif etype == "assistant":
            assistant_parts.append(text)
    return "\n\n".join(user_parts), "\n\n".join(assistant_parts)


def _post_ingestion(host: str, public_key: str, secret_key: str, events: list[dict[str, Any]]) -> None:
    url = host.rstrip("/") + "/api/public/ingestion"
    body = json.dumps({"batch": events}).encode("utf-8")
    auth = base64.b64encode(f"{public_key}:{secret_key}".encode()).decode()
    req = urllib.request.Request(
        url,
        data=body,
        headers={
            "Content-Type": "application/json",
            "Authorization": f"Basic {auth}",
        },
        method="POST",
    )
    with urllib.request.urlopen(req, timeout=TIMEOUT_SEC) as resp:
        # 2xx 以外は例外にする
        if resp.status >= 300:
            raise urllib.error.HTTPError(url, resp.status, resp.reason, resp.headers, None)


def main() -> int:
    if os.environ.get("TRACE_TO_LANGFUSE", "").lower() != "true":
        return 0

    host = os.environ.get("LANGFUSE_HOST", "").strip()
    public_key = os.environ.get("LANGFUSE_PUBLIC_KEY", "").strip()
    secret_key = os.environ.get("LANGFUSE_SECRET_KEY", "").strip()
    if not (host and public_key and secret_key):
        return 0

    try:
        payload = json.load(sys.stdin)
    except (json.JSONDecodeError, ValueError):
        return 0

    transcript_path = payload.get("transcript_path")
    session_id = payload.get("session_id") or "unknown"
    if not transcript_path:
        return 0
    tpath = Path(transcript_path)
    if not tpath.exists():
        return 0

    entries = _read_transcript(tpath)
    if not entries:
        return 0

    state = _load_state(session_id)
    last_uuid = state.get("last_uuid")
    new = _new_entries(entries, last_uuid)
    if not new:
        return 0

    user_input, assistant_output = _extract_turn(new)
    if not (user_input or assistant_output):
        # 新しい entry はあるが文字列化できる content が無い (メタ情報のみ等)
        state["last_uuid"] = entries[-1].get("uuid") or last_uuid
        _save_state(session_id, state)
        return 0

    trace_id = uuid.uuid4().hex
    now = _now_iso()
    event = {
        "id": uuid.uuid4().hex,
        "timestamp": now,
        "type": "trace-create",
        "body": {
            "id": trace_id,
            "timestamp": now,
            "name": "claude-code-turn",
            "sessionId": session_id,
            "input": user_input or None,
            "output": assistant_output or None,
            "metadata": {
                "cwd": payload.get("cwd"),
                "hook_event_name": payload.get("hook_event_name"),
                "turn_count": state.get("turn_count", 0) + 1,
            },
        },
    }

    try:
        _post_ingestion(host, public_key, secret_key, [event])
    except (urllib.error.URLError, urllib.error.HTTPError, TimeoutError, OSError):
        # ネットワーク失敗: state を更新せず次回に再送
        return 0

    state["last_uuid"] = entries[-1].get("uuid") or last_uuid
    state["turn_count"] = state.get("turn_count", 0) + 1
    _save_state(session_id, state)
    return 0


if __name__ == "__main__":
    try:
        sys.exit(main())
    except Exception:
        # Stop hook は Claude Code を止めてはいけないので例外を握り潰す
        sys.exit(0)
