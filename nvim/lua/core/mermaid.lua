-- Render the ```mermaid block under the cursor as ASCII in a floating window.
-- Depends on an external binary: mermaid-ascii (~/bin/mermaid-ascii)
local M = {}

local BIN = "mermaid-ascii"

-- Extract the mermaid fenced code block under the cursor (without the ``` fences)
local function get_mermaid_block()
  local cur = vim.api.nvim_win_get_cursor(0)[1] -- 1-indexed
  local lines = vim.api.nvim_buf_get_lines(0, 0, -1, false)

  -- search upward for the opening ```mermaid
  local start_fence
  for i = cur, 1, -1 do
    local l = lines[i]
    if l:match("^%s*```%s*mermaid%s*$") then
      start_fence = i
      break
    elseif l:match("^%s*```") and i ~= cur then
      -- hit another fence: the cursor is not inside a mermaid block
      break
    end
  end
  if not start_fence then
    return nil
  end

  -- search downward for the closing ```
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

  -- the cursor must sit inside the block
  if cur < start_fence or cur > end_fence then
    return nil
  end

  return vim.list_slice(lines, start_fence + 1, end_fence - 1)
end

-- Show content in a floating window
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

  -- q / Esc to close
  for _, key in ipairs({ "q", "<Esc>" }) do
    vim.keymap.set("n", key, "<cmd>close<CR>", { buffer = buf, nowait = true, silent = true })
  end
end

function M.render()
  if vim.fn.executable(BIN) ~= 1 then
    vim.notify(BIN .. " not found — make sure it is installed and on PATH", vim.log.levels.ERROR)
    return
  end

  local block = get_mermaid_block()
  if not block then
    vim.notify("cursor is not inside a ```mermaid block", vim.log.levels.WARN)
    return
  end

  local src = table.concat(block, "\n")
  local out = vim.fn.systemlist({ BIN, "-f", "-" }, src)
  if vim.v.shell_error ~= 0 then
    vim.notify("mermaid-ascii rendering failed:\n" .. table.concat(out, "\n"), vim.log.levels.ERROR)
    return
  end

  open_float(out, " mermaid (q/Esc to close) ")
end

return M
