#!/bin/bash
# cycle_pane.sh - 隣ペインに移動、端でサイズをサイクル
# サイズサイクル: 2/3 → 1/2 → 1/3 → 2/3
# Usage: cycle_pane.sh left|right

DIRECTION=${1:-left}

WINDOW_PANES=$(tmux display-message -p "#{window_panes}")
[ "$WINDOW_PANES" -lt 2 ] && exit 0

PANE_ID=$(tmux display-message -p "#{pane_id}")
BASE=$(tmux show-options -gv pane-base-index 2>/dev/null || echo 0)
LAST=$(( BASE + WINDOW_PANES - 1 ))
CURRENT_IDX=$(tmux display-message -p -t "$PANE_ID" '#{pane_index}')

# 端かどうか判定
at_edge=false
[ "$DIRECTION" = "left"  ] && [ "$CURRENT_IDX" -le "$BASE" ] && at_edge=true
[ "$DIRECTION" = "right" ] && [ "$CURRENT_IDX" -ge "$LAST" ] && at_edge=true

if [ "$at_edge" = "false" ]; then
    # 端でなければ隣に移動するだけ
    if [ "$DIRECTION" = "left" ]; then
        tmux swap-pane -dU -t "$PANE_ID"
    else
        tmux swap-pane -dD -t "$PANE_ID"
    fi
    tmux select-pane -t "$PANE_ID"
else
    # 端でサイズをサイクル: 2/3(67%) → 1/2(50%) → 1/3(33%) → 2/3(67%)
    WINDOW_WIDTH=$(tmux display-message -p "#{window_width}")
    PANE_WIDTH=$(tmux display-message -p -t "$PANE_ID" "#{pane_width}")
    RATIO=$(( PANE_WIDTH * 100 / WINDOW_WIDTH ))

    if   [ "$RATIO" -gt 58 ]; then NEXT=33
    elif [ "$RATIO" -gt 40 ]; then NEXT=67
    else                            NEXT=50
    fi

    # セパレータ (N-1) を除いた実使用幅でピクセル計算
    USABLE=$(( WINDOW_WIDTH - WINDOW_PANES + 1 ))
    ACTIVE_PX=$(( USABLE * NEXT / 100 ))
    tmux resize-pane -t "$PANE_ID" -x "${ACTIVE_PX}"

    # 残りのペインを均等分配（最後のペインはtmuxが自動調整）
    if [ "$WINDOW_PANES" -gt 2 ]; then
        OTHER_COUNT=$(( WINDOW_PANES - 1 ))
        EACH_PX=$(( (USABLE - ACTIVE_PX) / OTHER_COUNT ))
        OTHER_IDS=$(tmux list-panes -F "#{pane_id}" | grep -v "^${PANE_ID}$")
        I=0
        for PID in $OTHER_IDS; do
            I=$(( I + 1 ))
            [ "$I" -lt "$OTHER_COUNT" ] && tmux resize-pane -t "$PID" -x "${EACH_PX}"
        done
    fi
fi
