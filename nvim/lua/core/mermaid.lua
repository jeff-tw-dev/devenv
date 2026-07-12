-- 把游標所在的 ```mermaid 區塊渲染成 ASCII，顯示在浮動視窗
-- 依賴外部 binary: mermaid-ascii (~/bin/mermaid-ascii)
local M = {}

local BIN = "mermaid-ascii"

-- 找出游標所在的 mermaid fenced code block 內容 (不含 ``` 圍欄)
local function get_mermaid_block()
  local cur = vim.api.nvim_win_get_cursor(0)[1] -- 1-indexed
  local lines = vim.api.nvim_buf_get_lines(0, 0, -1, false)

  -- 往上找開頭 ```mermaid
  local start_fence
  for i = cur, 1, -1 do
    local l = lines[i]
    if l:match("^%s*```%s*mermaid%s*$") then
      start_fence = i
      break
    elseif l:match("^%s*```") and i ~= cur then
      -- 撞到別的圍欄，代表游標不在 mermaid 區塊裡
      break
    end
  end
  if not start_fence then
    return nil
  end

  -- 往下找結尾 ```
  local end_fence
  for i = start_fence + 1, #lines do
    if lines[i]:match("^%s*```%s*$") then
      end_fence = i
      break
    end
  end
  if not end_fence then
    return nil
  end

  -- 游標必須落在區塊範圍內
  if cur < start_fence or cur > end_fence then
    return nil
  end

  return vim.list_slice(lines, start_fence + 1, end_fence - 1)
end

-- 開浮動視窗顯示內容
local function open_float(content_lines, title)
  local width = 0
  for _, l in ipairs(content_lines) do
    width = math.max(width, vim.fn.strdisplaywidth(l))
  end
  width = math.min(width + 2, vim.o.columns - 4)
  local height = math.min(#content_lines, vim.o.lines - 4)

  local buf = vim.api.nvim_create_buf(false, true)
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, content_lines)
  vim.bo[buf].modifiable = false
  vim.bo[buf].bufhidden = "wipe"

  local win = vim.api.nvim_open_win(buf, true, {
    relative = "editor",
    row = math.floor((vim.o.lines - height) / 2),
    col = math.floor((vim.o.columns - width) / 2),
    width = width,
    height = height,
    style = "minimal",
    border = "rounded",
    title = title or " mermaid ",
    title_pos = "center",
  })
  vim.wo[win].wrap = false

  -- q / Esc 關閉
  for _, key in ipairs({ "q", "<Esc>" }) do
    vim.keymap.set("n", key, "<cmd>close<CR>", { buffer = buf, nowait = true, silent = true })
  end
end

function M.render()
  if vim.fn.executable(BIN) ~= 1 then
    vim.notify("找不到 " .. BIN .. "，請確認已安裝到 PATH", vim.log.levels.ERROR)
    return
  end

  local block = get_mermaid_block()
  if not block then
    vim.notify("游標不在 ```mermaid 區塊內", vim.log.levels.WARN)
    return
  end

  local src = table.concat(block, "\n")
  local out = vim.fn.systemlist({ BIN, "-f", "-" }, src)
  if vim.v.shell_error ~= 0 then
    vim.notify("mermaid-ascii 渲染失敗:\n" .. table.concat(out, "\n"), vim.log.levels.ERROR)
    return
  end

  open_float(out, " mermaid (q/Esc 關閉) ")
end

return M
