-- Line bookmarks with JSON persistence (stdpath("data")/bookmarks.json).
-- Toggle on a line, annotate, navigate within a buffer, and manage all
-- bookmarks in a floating panel grouped by file: <CR> jump, dd delete,
-- e edit note, q close. Signs mark bookmarked lines; positions live-track
-- edits via extmarks and re-anchor by line text when a file changed on disk.
local M = {}

local ns = vim.api.nvim_create_namespace("bookmarks")
local SIGN = "◆"

vim.api.nvim_set_hl(0, "BookmarkSign", { default = true, link = "DiagnosticSignInfo" })

local db_path = vim.fn.stdpath("data") .. "/bookmarks.json"
local data -- lazy: { files = { [abspath] = { {lnum, text, note?}, ... } } }

-- live extmark ids for attached buffers: bufnr -> { {id, bm}, ... }
local live = {}

---------------------------------------------------------------------------
-- Storage
---------------------------------------------------------------------------

local function load()
  if data then
    return data
  end
  data = { files = {} }
  if vim.fn.filereadable(db_path) == 1 then
    local ok, decoded = pcall(vim.json.decode, table.concat(vim.fn.readfile(db_path), "\n"))
    if ok and type(decoded) == "table" and type(decoded.files) == "table" then
      data = decoded
    end
  end
  return data
end

local function save()
  vim.fn.writefile({ vim.json.encode(data) }, db_path)
end

---------------------------------------------------------------------------
-- Buffer attachment: signs + live position tracking
---------------------------------------------------------------------------

-- write extmark positions back into the store for an attached buffer
local function sync(buf)
  local path = vim.api.nvim_buf_get_name(buf)
  local entries = live[buf]
  if not entries or path == "" then
    return
  end
  local bms = {}
  local seen = {}
  for _, e in ipairs(entries) do
    local pos = vim.api.nvim_buf_get_extmark_by_id(buf, ns, e.id, {})
    if pos and pos[1] then
      local lnum = pos[1] + 1
      if not seen[lnum] then -- collapse bookmarks merged onto one line
        seen[lnum] = true
        e.bm.lnum = lnum
        e.bm.text = vim.api.nvim_buf_get_lines(buf, lnum - 1, lnum, false)[1] or ""
        table.insert(bms, e.bm)
      end
    end
  end
  load().files[path] = #bms > 0 and bms or nil
end

local function place_sign(buf, bm)
  local lnum = math.min(bm.lnum, vim.api.nvim_buf_line_count(buf))
  local id = vim.api.nvim_buf_set_extmark(buf, ns, lnum - 1, 0, {
    sign_text = SIGN,
    sign_hl_group = "BookmarkSign",
  })
  table.insert(live[buf], { id = id, bm = bm })
  return id
end

-- re-anchor a stored bookmark whose line text no longer matches (file
-- changed outside this nvim): prefer the closest line with identical text
local function reanchor(buf, bm)
  local total = vim.api.nvim_buf_line_count(buf)
  local at = vim.api.nvim_buf_get_lines(buf, bm.lnum - 1, bm.lnum, false)[1]
  if bm.lnum <= total and at == bm.text then
    return
  end
  local best
  for lnum, line in ipairs(vim.api.nvim_buf_get_lines(buf, 0, -1, false)) do
    if line == bm.text and (not best or math.abs(lnum - bm.lnum) < math.abs(best - bm.lnum)) then
      best = lnum
    end
  end
  bm.lnum = math.min(best or bm.lnum, total)
end

local function attach(buf)
  local path = vim.api.nvim_buf_get_name(buf)
  local bms = load().files[path]
  if live[buf] or not bms then
    return
  end
  live[buf] = {}
  for _, bm in ipairs(bms) do
    reanchor(buf, bm)
    place_sign(buf, bm)
  end
  vim.api.nvim_create_autocmd("BufWritePost", {
    buffer = buf,
    group = vim.api.nvim_create_augroup("core.bookmarks.buf" .. buf, { clear = true }),
    callback = function()
      sync(buf)
      save()
    end,
  })
  vim.api.nvim_create_autocmd("BufWipeout", {
    buffer = buf,
    once = true,
    callback = function()
      sync(buf)
      save()
      live[buf] = nil
    end,
  })
end

---------------------------------------------------------------------------
-- Core operations
---------------------------------------------------------------------------

local function current_file_buf()
  local buf = vim.api.nvim_get_current_buf()
  local path = vim.api.nvim_buf_get_name(buf)
  if path == "" or vim.bo[buf].buftype ~= "" then
    vim.notify("bookmarks: not a file buffer", vim.log.levels.INFO)
    return nil
  end
  return buf, path
end

-- find the live entry on the given line (attached buffers)
local function entry_at(buf, lnum)
  for i, e in ipairs(live[buf] or {}) do
    local pos = vim.api.nvim_buf_get_extmark_by_id(buf, ns, e.id, {})
    if pos and pos[1] == lnum - 1 then
      return e, i
    end
  end
end

function M.toggle()
  local buf, path = current_file_buf()
  if not buf then
    return
  end
  live[buf] = live[buf] or {}
  local lnum = vim.api.nvim_win_get_cursor(0)[1]
  local e, i = entry_at(buf, lnum)
  if e then
    vim.api.nvim_buf_del_extmark(buf, ns, e.id)
    table.remove(live[buf], i)
  else
    local bm = { lnum = lnum, text = vim.api.nvim_get_current_line() }
    load().files[path] = load().files[path] or {}
    place_sign(buf, bm)
  end
  sync(buf)
  save()
  attach(buf) -- ensures write/wipeout autocmds exist for first-time buffers
end

function M.annotate()
  local buf, path = current_file_buf()
  if not buf then
    return
  end
  live[buf] = live[buf] or {}
  local lnum = vim.api.nvim_win_get_cursor(0)[1]
  local e = entry_at(buf, lnum)
  vim.ui.input({ prompt = "Bookmark note: ", default = e and e.bm.note or "" }, function(input)
    if input == nil then
      return
    end
    if not e then
      local bm = { lnum = lnum, text = vim.api.nvim_get_current_line(), note = input ~= "" and input or nil }
      load().files[path] = load().files[path] or {}
      place_sign(buf, bm)
      attach(buf)
    else
      e.bm.note = input ~= "" and input or nil
    end
    sync(buf)
    save()
  end)
end

local function buffer_bookmark_lines(buf)
  local lnums = {}
  for _, e in ipairs(live[buf] or {}) do
    local pos = vim.api.nvim_buf_get_extmark_by_id(buf, ns, e.id, {})
    if pos and pos[1] then
      table.insert(lnums, pos[1] + 1)
    end
  end
  table.sort(lnums)
  return lnums
end

function M.next()
  local buf = vim.api.nvim_get_current_buf()
  local row = vim.api.nvim_win_get_cursor(0)[1]
  local lnums = buffer_bookmark_lines(buf)
  for _, l in ipairs(lnums) do
    if l > row then
      vim.api.nvim_win_set_cursor(0, { l, 0 })
      return
    end
  end
  if lnums[1] then
    vim.api.nvim_win_set_cursor(0, { lnums[1], 0 })
  end
end

function M.prev()
  local buf = vim.api.nvim_get_current_buf()
  local row = vim.api.nvim_win_get_cursor(0)[1]
  local lnums = buffer_bookmark_lines(buf)
  for i = #lnums, 1, -1 do
    if lnums[i] < row then
      vim.api.nvim_win_set_cursor(0, { lnums[i], 0 })
      return
    end
  end
  if lnums[#lnums] then
    vim.api.nvim_win_set_cursor(0, { lnums[#lnums], 0 })
  end
end

---------------------------------------------------------------------------
-- List panel
---------------------------------------------------------------------------

local panel

local function close_panel()
  if panel and vim.api.nvim_win_is_valid(panel.win) then
    vim.api.nvim_win_close(panel.win, true)
  end
  panel = nil
end

local function panel_items()
  -- flush attached buffers so the panel reflects live positions
  for buf in pairs(live) do
    if vim.api.nvim_buf_is_valid(buf) then
      sync(buf)
    end
  end
  local files = {}
  for path, bms in pairs(load().files) do
    table.insert(files, { path = path, bms = bms })
  end
  table.sort(files, function(a, b)
    return a.path < b.path
  end)
  return files
end

local function render_panel()
  local st = panel
  local lines, marks = {}, {}
  st.line_items = {}

  lines[1] = " Bookmarks"
  lines[2] = " <CR>:jump  dd:delete  e:note  q:quit"
  marks[#marks + 1] = { 0, 0, #lines[1], "Title" }
  marks[#marks + 1] = { 1, 0, #lines[2], "Comment" }

  local files = panel_items()
  if #files == 0 then
    table.insert(lines, "")
    table.insert(lines, "   (no bookmarks)")
  end
  for _, f in ipairs(files) do
    local rel = vim.fn.fnamemodify(f.path, ":~:.")
    table.insert(lines, "")
    table.insert(lines, ("▸ %s"):format(rel))
    marks[#marks + 1] = { #lines - 1, 0, #lines[#lines], "Statement" }
    table.sort(f.bms, function(a, b)
      return a.lnum < b.lnum
    end)
    for _, bm in ipairs(f.bms) do
      local label = bm.note and (bm.note .. "  ·  " .. vim.trim(bm.text)) or vim.trim(bm.text)
      local line = ("   %4d  %s"):format(bm.lnum, label)
      table.insert(lines, line)
      st.line_items[#lines] = { path = f.path, bm = bm }
      marks[#marks + 1] = { #lines - 1, 3, 7, "Number" }
      if bm.note then
        marks[#marks + 1] = { #lines - 1, 9, 9 + #bm.note, "Function" }
      end
    end
  end

  vim.bo[st.buf].modifiable = true
  vim.api.nvim_buf_set_lines(st.buf, 0, -1, false, lines)
  vim.bo[st.buf].modifiable = false
  vim.api.nvim_buf_clear_namespace(st.buf, ns, 0, -1)
  for _, m in ipairs(marks) do
    vim.api.nvim_buf_set_extmark(st.buf, ns, m[1], m[2], { end_col = m[3], hl_group = m[4] })
  end

  local width = 0
  for _, l in ipairs(lines) do
    width = math.max(width, vim.fn.strdisplaywidth(l))
  end
  width = math.min(width + 2, vim.o.columns - 8)
  local height = math.min(math.max(#lines, 6), vim.o.lines - 6)
  vim.api.nvim_win_set_config(st.win, {
    relative = "editor",
    row = math.floor((vim.o.lines - height) / 2) - 1,
    col = math.floor((vim.o.columns - width) / 2),
    width = width,
    height = height,
  })
end

-- remove a bookmark from the store AND from any attached buffer's extmarks
local function remove_bookmark(path, bm)
  local bms = load().files[path]
  if bms then
    for i, x in ipairs(bms) do
      if x == bm then
        table.remove(bms, i)
        break
      end
    end
    if #bms == 0 then
      load().files[path] = nil
    end
  end
  for buf, entries in pairs(live) do
    if vim.api.nvim_buf_get_name(buf) == path then
      for i, e in ipairs(entries) do
        if e.bm == bm then
          vim.api.nvim_buf_del_extmark(buf, ns, e.id)
          table.remove(entries, i)
          break
        end
      end
    end
  end
  save()
end

function M.list()
  if panel then
    close_panel()
  end
  local prev_win = vim.api.nvim_get_current_win()
  local buf = vim.api.nvim_create_buf(false, true)
  vim.bo[buf].bufhidden = "wipe"
  vim.bo[buf].filetype = "bookmarklist"
  local win = vim.api.nvim_open_win(buf, true, {
    relative = "editor",
    row = 5,
    col = 10,
    width = 40,
    height = 10,
    style = "minimal",
    border = "rounded",
    title = " Bookmarks ",
  })
  vim.wo[win].cursorline = true
  panel = { buf = buf, win = win, prev_win = prev_win, line_items = {} }
  render_panel()

  local function cur_item()
    return panel.line_items[vim.api.nvim_win_get_cursor(win)[1]]
  end

  local opts = { buffer = buf, nowait = true, silent = true }
  vim.keymap.set("n", "q", close_panel, opts)
  vim.keymap.set("n", "<Esc>", close_panel, opts)
  vim.keymap.set("n", "<CR>", function()
    local it = cur_item()
    if not it then
      return
    end
    local target = panel.prev_win
    close_panel()
    if target and vim.api.nvim_win_is_valid(target) then
      vim.api.nvim_set_current_win(target)
    end
    vim.cmd.edit(vim.fn.fnameescape(it.path))
    vim.api.nvim_win_set_cursor(0, { math.min(it.bm.lnum, vim.api.nvim_buf_line_count(0)), 0 })
    vim.cmd("normal! zz")
  end, opts)
  vim.keymap.set("n", "dd", function()
    local it = cur_item()
    if not it then
      return
    end
    local cur = vim.api.nvim_win_get_cursor(win)[1]
    remove_bookmark(it.path, it.bm)
    render_panel()
    pcall(vim.api.nvim_win_set_cursor, win, { math.min(cur, vim.api.nvim_buf_line_count(buf)), 0 })
  end, opts)
  vim.keymap.set("n", "e", function()
    local it = cur_item()
    if not it then
      return
    end
    vim.ui.input({ prompt = "Bookmark note: ", default = it.bm.note or "" }, function(input)
      if input == nil then
        return
      end
      it.bm.note = input ~= "" and input or nil
      save()
      render_panel()
    end)
  end, opts)
  vim.api.nvim_create_autocmd("BufWipeout", {
    buffer = buf,
    once = true,
    callback = function()
      panel = nil
    end,
  })
end

function M.setup()
  vim.api.nvim_create_autocmd("BufReadPost", {
    group = vim.api.nvim_create_augroup("core.bookmarks", { clear = true }),
    callback = function(args)
      attach(args.buf)
    end,
  })
  vim.api.nvim_create_autocmd("VimLeavePre", {
    group = vim.api.nvim_create_augroup("core.bookmarks.exit", { clear = true }),
    callback = function()
      for buf in pairs(live) do
        if vim.api.nvim_buf_is_valid(buf) then
          sync(buf)
        end
      end
      if data then
        save()
      end
    end,
  })
end

return M
