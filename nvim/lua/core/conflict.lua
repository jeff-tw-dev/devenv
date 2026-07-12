-- Merge-conflict resolver: detects <<<<<<< / ======= / >>>>>>> markers
-- (diff3 ||||||| base sections too), highlights each side, and adds
-- buffer-local keys while conflicts exist — co keep ours, ct keep theirs,
-- cb keep both, c0 keep none, ]x / [x next / previous conflict.
-- M.qf() collects every conflict in the repo into the quickfix list.
local M = {}

local ns = vim.api.nvim_create_namespace("conflict")

vim.api.nvim_set_hl(0, "ConflictOurs", { default = true, link = "DiffAdd" })
vim.api.nvim_set_hl(0, "ConflictTheirs", { default = true, link = "DiffChange" })
vim.api.nvim_set_hl(0, "ConflictBase", { default = true, link = "Folded" })
vim.api.nvim_set_hl(0, "ConflictMarker", { default = true, link = "NonText" })

local blocks_by_buf = {} -- bufnr -> { {ours, base?, sep, theirs}, ... } (1-indexed lnums)
local notified = {} -- bufnr -> true once the "N conflicts" hint was shown

local MAX_LINES = 50000 -- skip conflict scanning on huge files

---------------------------------------------------------------------------
-- Parsing and rendering
---------------------------------------------------------------------------

local function parse(buf)
  if vim.api.nvim_buf_line_count(buf) > MAX_LINES then
    return {}
  end
  local lines = vim.api.nvim_buf_get_lines(buf, 0, -1, false)
  local blocks = {}
  local i = 1
  while i <= #lines do
    if lines[i]:match("^<<<<<<<") then
      local b = { ours = i }
      local j = i + 1
      while j <= #lines do
        local l = lines[j]
        if l:match("^|||||||") and not b.sep then
          b.base = j
        elseif l:match("^=======%s*$") and not b.sep then
          b.sep = j
        elseif l:match("^>>>>>>>") then
          b.theirs = j
          break
        elseif l:match("^<<<<<<<") then
          break -- malformed block: restart from the inner marker
        end
        j = j + 1
      end
      if b.sep and b.theirs then
        table.insert(blocks, b)
        i = b.theirs + 1
      else
        i = i + 1
      end
    else
      i = i + 1
    end
  end
  return blocks
end

local function render(buf)
  vim.api.nvim_buf_clear_namespace(buf, ns, 0, -1)
  local function mark_line(lnum, group)
    vim.api.nvim_buf_set_extmark(buf, ns, lnum - 1, 0, { line_hl_group = group, priority = 150 })
  end
  for _, b in ipairs(blocks_by_buf[buf] or {}) do
    mark_line(b.ours, "ConflictMarker")
    mark_line(b.sep, "ConflictMarker")
    mark_line(b.theirs, "ConflictMarker")
    if b.base then
      mark_line(b.base, "ConflictMarker")
    end
    for l = b.ours + 1, (b.base or b.sep) - 1 do
      mark_line(l, "ConflictOurs")
    end
    if b.base then
      for l = b.base + 1, b.sep - 1 do
        mark_line(l, "ConflictBase")
      end
    end
    for l = b.sep + 1, b.theirs - 1 do
      mark_line(l, "ConflictTheirs")
    end
  end
end

local function refresh(buf)
  blocks_by_buf[buf] = parse(buf)
  render(buf)
  return #blocks_by_buf[buf]
end

---------------------------------------------------------------------------
-- Resolution
---------------------------------------------------------------------------

local function block_at_cursor()
  local buf = vim.api.nvim_get_current_buf()
  local row = vim.api.nvim_win_get_cursor(0)[1]
  for _, b in ipairs(blocks_by_buf[buf] or {}) do
    if row >= b.ours and row <= b.theirs then
      return b, buf
    end
  end
end

-- which: "ours" | "theirs" | "both" | "none"
function M.choose(which)
  local b, buf = block_at_cursor()
  if not b then
    vim.notify("conflict: cursor is not inside a conflict block", vim.log.levels.INFO)
    return
  end
  local lines = vim.api.nvim_buf_get_lines(buf, 0, -1, false)
  local ours = vim.list_slice(lines, b.ours + 1, (b.base or b.sep) - 1)
  local theirs = vim.list_slice(lines, b.sep + 1, b.theirs - 1)
  local keep
  if which == "ours" then
    keep = ours
  elseif which == "theirs" then
    keep = theirs
  elseif which == "both" then
    keep = vim.list_extend(ours, theirs)
  else
    keep = {}
  end
  vim.api.nvim_buf_set_lines(buf, b.ours - 1, b.theirs, false, keep)
  local remaining = refresh(buf)
  if remaining == 0 then
    vim.notify("conflict: all conflicts in this buffer resolved", vim.log.levels.INFO)
  end
end

function M.next()
  local buf = vim.api.nvim_get_current_buf()
  local row = vim.api.nvim_win_get_cursor(0)[1]
  local blocks = blocks_by_buf[buf] or {}
  for _, b in ipairs(blocks) do
    if b.ours > row then
      vim.api.nvim_win_set_cursor(0, { b.ours, 0 })
      return
    end
  end
  if blocks[1] then -- wrap around
    vim.api.nvim_win_set_cursor(0, { blocks[1].ours, 0 })
  end
end

function M.prev()
  local buf = vim.api.nvim_get_current_buf()
  local row = vim.api.nvim_win_get_cursor(0)[1]
  local blocks = blocks_by_buf[buf] or {}
  for i = #blocks, 1, -1 do
    if blocks[i].theirs < row then
      vim.api.nvim_win_set_cursor(0, { blocks[i].ours, 0 })
      return
    end
  end
  if blocks[#blocks] then
    vim.api.nvim_win_set_cursor(0, { blocks[#blocks].ours, 0 })
  end
end

---------------------------------------------------------------------------
-- Quickfix: every conflict in the repo
---------------------------------------------------------------------------

function M.qf()
  local root = (vim.fn.systemlist({ "git", "rev-parse", "--show-toplevel" }) or {})[1]
  if vim.v.shell_error ~= 0 or not root then
    vim.notify("conflict: not inside a git repo", vim.log.levels.WARN)
    return
  end
  local files = vim.fn.systemlist({ "git", "-C", root, "diff", "--name-only", "--diff-filter=U" })
  local items = {}
  for _, rel in ipairs(files) do
    local path = root .. "/" .. rel
    for lnum, line in ipairs(vim.fn.readfile(path)) do
      if line:match("^<<<<<<<") then
        table.insert(items, { filename = path, lnum = lnum, text = line })
      end
    end
  end
  if #items == 0 then
    vim.notify("conflict: no merge conflicts in the repo", vim.log.levels.INFO)
    return
  end
  vim.fn.setqflist({}, " ", { title = "Merge conflicts", items = items })
  vim.cmd("copen")
end

---------------------------------------------------------------------------
-- Attach / detect
---------------------------------------------------------------------------

local function attach(buf)
  if vim.b[buf].conflict_attached then
    return
  end
  vim.b[buf].conflict_attached = true

  local opts = { buffer = buf, nowait = true, silent = true }
  vim.keymap.set("n", "co", function()
    M.choose("ours")
  end, vim.tbl_extend("force", opts, { desc = "Conflict: keep ours" }))
  vim.keymap.set("n", "ct", function()
    M.choose("theirs")
  end, vim.tbl_extend("force", opts, { desc = "Conflict: keep theirs" }))
  vim.keymap.set("n", "cb", function()
    M.choose("both")
  end, vim.tbl_extend("force", opts, { desc = "Conflict: keep both" }))
  vim.keymap.set("n", "c0", function()
    M.choose("none")
  end, vim.tbl_extend("force", opts, { desc = "Conflict: keep none" }))
  vim.keymap.set("n", "]x", M.next, vim.tbl_extend("force", opts, { desc = "Next conflict" }))
  vim.keymap.set("n", "[x", M.prev, vim.tbl_extend("force", opts, { desc = "Previous conflict" }))

  vim.api.nvim_create_autocmd({ "TextChanged", "InsertLeave" }, {
    buffer = buf,
    group = vim.api.nvim_create_augroup("core.conflict.buf" .. buf, { clear = true }),
    callback = function()
      refresh(buf)
    end,
  })
  vim.api.nvim_create_autocmd("BufWipeout", {
    buffer = buf,
    once = true,
    callback = function()
      blocks_by_buf[buf] = nil
      notified[buf] = nil
    end,
  })
end

function M.setup()
  vim.api.nvim_create_autocmd({ "BufReadPost", "BufWritePost" }, {
    group = vim.api.nvim_create_augroup("core.conflict", { clear = true }),
    callback = function(args)
      local n = refresh(args.buf)
      if n > 0 then
        attach(args.buf)
        if not notified[args.buf] then
          notified[args.buf] = true
          vim.notify(
            ("conflict: %d conflict%s — co/ct/cb/c0 resolve, ]x/[x navigate"):format(n, n > 1 and "s" or ""),
            vim.log.levels.WARN
          )
        end
      end
    end,
  })
end

return M
