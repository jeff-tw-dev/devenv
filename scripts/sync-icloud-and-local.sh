#!/bin/zsh

ICLOUD_VAULT="/Users/luca/Library/Mobile Documents/iCloud~md~obsidian/Documents/SecondBrain/"
MAX_WAIT=300  # 最多等 5 分鐘
INTERVAL=5

# 1. 觸發下載
brctl download "$ICLOUD_VAULT"

# 2. 等待所有檔案下載完成
#    iCloud placeholder 檔案會有 com.apple.ubiquity 的 extended attribute
#    或者檔名帶有 .icloud 前綴
elapsed=0
while [ $elapsed -lt $MAX_WAIT ]; do
    # 找還沒下載的 placeholder 檔（.icloud 檔）
    pending=$(find "$ICLOUD_VAULT" -name ".*.icloud" 2>/dev/null | wc -l | tr -d ' ')

    if [ "$pending" -eq 0 ]; then
        echo "所有檔案已下載完成"
        break
    fi

    echo "還有 $pending 個檔案下載中，已等待 ${elapsed}s..."
    sleep $INTERVAL
    elapsed=$((elapsed + INTERVAL))
done

if [ $elapsed -ge $MAX_WAIT ]; then
    echo "警告：等待超時，仍有檔案未下載，跳過本次同步"
    exit 1
fi

# 3. 執行 unison 同步
unison obsidian -batch
