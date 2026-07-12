-- Close buffers without closing their windows: every window showing the
-- buffer switches to the alternate / most recent listed buffer (or a fresh
-- empty one) before the buffer is deleted.
local M = {}

local function fallback_buf(closing)
  local alt = vim.fn.bufnr("#")
  if alt > 0 and alt ~= closing and vim.fn.buflisted(alt) == 1 then
    return alt
  end
  for _, buf in ipairs(vim.api.nvim_list_bufs()) do
    if buf ~= closing and vim.fn.buflisted(buf) == 1 then
      return buf
    end
  end
  return vim.api.nvim_create_buf(true, false) -- empty scratch-like listed buffer
end

function M.delete(buf)
  buf = buf or vim.api.nvim_get_current_buf()
  if vim.bo[buf].modified then
    vim.notify("bufclose: buffer has unsaved changes", vim.log.levels.WARN)
    return false
  end
  local target = fallback_buf(buf)
  for _, win in ipairs(vim.api.nvim_list_wins()) do
    if vim.api.nvim_win_get_buf(win) == buf then
      vim.api.nvim_win_set_buf(win, target)
    end
  end
  pcall(vim.api.nvim_buf_delete, buf, {})
  return true
end

-- Close all listed buffers (skipping unsaved ones), keep the window layout.
function M.delete_all()
  local skipped = 0
  for _, buf in ipairs(vim.api.nvim_list_bufs()) do
    if vim.fn.buflisted(buf) == 1 then
      if vim.bo[buf].modified then
        skipped = skipped + 1
      else
        M.delete(buf)
      end
    end
  end
  if skipped > 0 then
    vim.notify(("bufclose: skipped %d buffer(s) with unsaved changes"):format(skipped), vim.log.levels.WARN)
  end
end

return M
