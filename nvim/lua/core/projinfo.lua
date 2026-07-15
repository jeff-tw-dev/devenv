-- Project info panel: one floating window summarizing project manifests —
-- npm scripts / dependencies (package.json), Makefile targets, Cargo.toml
-- dependencies, go.mod requires, and .env* files.
-- Panel keys: <CR> jump to the item's definition line, r run the item
-- (npm script / make target) in toggleterm, / fuzzy-search all items,
-- v reveal/mask env values, a add a variable to the env file under the
-- cursor, q close. M.search() also works standalone (<leader>ps).
local M = {}

local ns = vim.api.nvim_create_namespace("projinfo")

-- values of keys matching these are masked unless toggled with `v`
local reveal_env = false
local SENSITIVE = { "SECRET", "TOKEN", "PASS", "PWD", "KEY", "CREDENTIAL", "PRIVATE", "AUTH" }

local function is_sensitive(key)
  local up = key:upper()
  for _, pat in ipairs(SENSITIVE) do
    if up:find(pat, 1, true) then
      return true
    end
  end
  return false
end

---------------------------------------------------------------------------
-- Parsers: each returns a list of sections
-- section = { title, items = { { label, detail, path, lnum, run } } }
---------------------------------------------------------------------------

local function file_lines(path)
  if vim.fn.filereadable(path) ~= 1 then
    return nil
  end
  return vim.fn.readfile(path)
end

-- Find the line of `"name":` inside the given section (e.g. "scripts");
-- the key may sit on the section opener line itself (inline object)
local function json_key_line(lines, section, name)
  local in_section = section == nil
  local name_pat = '"' .. vim.pesc(name) .. '"%s*:'
  for i, l in ipairs(lines) do
    if not in_section then
      if l:match('"' .. vim.pesc(section) .. '"%s*:') then
        in_section = true
        if l:match(name_pat) then
          return i
        end
      end
    elseif l:match(name_pat) then
      return i
    end
  end
end

local function detect_pm(root)
  if vim.fn.filereadable(root .. "/pnpm-lock.yaml") == 1 then
    return "pnpm"
  elseif vim.fn.filereadable(root .. "/yarn.lock") == 1 then
    return "yarn"
  elseif vim.fn.filereadable(root .. "/bun.lockb") == 1 or vim.fn.filereadable(root .. "/bun.lock") == 1 then
    return "bun"
  end
  return "npm"
end

local function parse_package_json(root)
  local path = root .. "/package.json"
  local lines = file_lines(path)
  if not lines then
    return {}
  end
  local ok, data = pcall(vim.json.decode, table.concat(lines, "\n"))
  if not ok or type(data) ~= "table" then
    return {}
  end

  local pm = detect_pm(root)
  local sections = {}

  local function dep_section(title, key)
    if type(data[key]) ~= "table" or vim.tbl_isempty(data[key]) then
      return
    end
    local items = {}
    for name, ver in pairs(data[key]) do
      table.insert(items, {
        label = name,
        detail = tostring(ver),
        path = path,
        lnum = json_key_line(lines, key, name),
      })
    end
    table.sort(items, function(a, b)
      return a.label < b.label
    end)
    table.insert(sections, { title = title, items = items })
  end

  if type(data.scripts) == "table" and not vim.tbl_isempty(data.scripts) then
    local items = {}
    for name, cmd in pairs(data.scripts) do
      table.insert(items, {
        label = name,
        detail = tostring(cmd),
        path = path,
        lnum = json_key_line(lines, "scripts", name),
        run = ("%s run %s"):format(pm, name),
      })
    end
    table.sort(items, function(a, b)
      return a.label < b.label
    end)
    table.insert(sections, { title = ("npm scripts (%s)"):format(pm), items = items })
  end
  dep_section("dependencies", "dependencies")
  dep_section("devDependencies", "devDependencies")
  return sections
end

local function parse_makefile(root)
  local path
  for _, name in ipairs({ "Makefile", "makefile", "GNUmakefile" }) do
    if vim.fn.filereadable(root .. "/" .. name) == 1 then
      path = root .. "/" .. name
      break
    end
  end
  local lines = path and file_lines(path)
  if not lines then
    return {}
  end

  local items, seen = {}, {}
  for i, l in ipairs(lines) do
    -- a target line: starts at column 1, "name:", not an assignment (:=)
    -- and not a special target (.PHONY etc.) or pattern rule (%)
    local target = l:match("^([%w%._/%-]+)%s*:[^=]") or l:match("^([%w%._/%-]+)%s*:$")
    if target and not target:match("^%.") and not seen[target] then
      seen[target] = true
      -- use the ## comment convention as the description when present
      local desc = l:match("##%s*(.+)$") or ""
      table.insert(items, { label = target, detail = desc, path = path, lnum = i, run = "make " .. target })
    end
  end
  if #items == 0 then
    return {}
  end
  return { { title = "make targets", items = items } }
end

local function parse_cargo(root)
  local path = root .. "/Cargo.toml"
  local lines = file_lines(path)
  if not lines then
    return {}
  end
  local sections_out = {}
  local wanted = { dependencies = "cargo dependencies", ["dev-dependencies"] = "cargo dev-dependencies" }
  local current, bucket = nil, {}
  local function flush()
    if current and #bucket > 0 then
      table.insert(sections_out, { title = wanted[current], items = bucket })
    end
    bucket = {}
  end
  for i, l in ipairs(lines) do
    local sec = l:match("^%[([%w%-%.]+)%]")
    if sec then
      flush()
      current = wanted[sec] and sec or nil
    elseif current then
      local name = l:match("^([%w_%-]+)%s*=")
      if name then
        local ver = l:match('"([^"]+)"') or ""
        table.insert(bucket, { label = name, detail = ver, path = path, lnum = i })
      end
    end
  end
  flush()
  return sections_out
end

local function parse_gomod(root)
  local path = root .. "/go.mod"
  local lines = file_lines(path)
  if not lines then
    return {}
  end
  local items = {}
  local in_require = false
  for i, l in ipairs(lines) do
    if l:match("^require%s*%(") then
      in_require = true
    elseif in_require and l:match("^%)") then
      in_require = false
    elseif in_require then
      local mod, ver = l:match("^%s+(%S+)%s+(%S+)")
      if mod and not l:match("^%s*//") then
        table.insert(items, { label = mod, detail = ver .. (l:match("// indirect") and " (indirect)" or ""), path = path, lnum = i })
      end
    else
      local mod, ver = l:match("^require%s+(%S+)%s+(%S+)")
      if mod then
        table.insert(items, { label = mod, detail = ver, path = path, lnum = i })
      end
    end
  end
  if #items == 0 then
    return {}
  end
  return { { title = "go.mod require", items = items } }
end

local function parse_envfiles(root)
  local names = {}
  for name, ftype in vim.fs.dir(root) do
    if ftype == "file" and name:match("^%.env") then
      table.insert(names, name)
    end
  end
  table.sort(names)

  local sections = {}
  for _, name in ipairs(names) do
    local path = root .. "/" .. name
    local lines = file_lines(path) or {}
    local items = {}
    for i, l in ipairs(lines) do
      local key, val = l:match("^%s*export%s+([%w_%.]+)%s*=%s*(.-)%s*$")
      if not key then
        key, val = l:match("^%s*([%w_%.]+)%s*=%s*(.-)%s*$")
      end
      if key then
        val = val:gsub('^"(.*)"$', "%1"):gsub("^'(.*)'$", "%1")
        -- masking happens at render time so toggling doesn't re-read files
        table.insert(items, { label = key, detail = val, sensitive = is_sensitive(key), path = path, lnum = i, env_file = path })
      end
    end
    if #items == 0 then
      items = { { label = "(empty)", detail = "", path = path, lnum = 1, env_file = path } }
    end
    table.insert(sections, { title = "env: " .. name, items = items })
  end
  return sections
end

---------------------------------------------------------------------------
-- Panel
---------------------------------------------------------------------------

-- top = repo root to scan from (git root when available), nearest = the
-- project dir the current buffer lives in (used to sort it first)
local function repo_root()
  local buf_path = vim.api.nvim_buf_get_name(0)
  local start = buf_path ~= "" and vim.fs.dirname(buf_path) or vim.fn.getcwd()
  local markers = { "package.json", "Makefile", "makefile", "Cargo.toml", "go.mod", ".env", ".git" }
  local nearest = vim.fs.root(start, markers)
  local top = vim.fs.root(start, { ".git" }) or nearest or vim.fn.getcwd()
  return top, nearest
end

local function collect(root)
  local sections = {}
  for _, parser in ipairs({ parse_package_json, parse_makefile, parse_cargo, parse_gomod, parse_envfiles }) do
    vim.list_extend(sections, parser(root))
  end
  for _, sec in ipairs(sections) do
    for _, it in ipairs(sec.items) do
      it.cwd = root
    end
  end
  return sections
end

---------------------------------------------------------------------------
-- Monorepo discovery: walk from the repo root looking for nested projects
---------------------------------------------------------------------------

local MANIFEST_FILES = { "package.json", "Makefile", "makefile", "GNUmakefile", "Cargo.toml", "go.mod" }
local SKIP_DIRS = {
  node_modules = true,
  dist = true,
  build = true,
  out = true,
  target = true,
  vendor = true,
  deps = true,
  _build = true,
  coverage = true,
  __pycache__ = true,
}
local MAX_DEPTH = 3

local function dir_has_project_files(dir)
  for _, m in ipairs(MANIFEST_FILES) do
    if vim.fn.filereadable(dir .. "/" .. m) == 1 then
      return true
    end
  end
  return vim.fn.glob(dir .. "/.env*", true, true)[1] ~= nil
end

local function find_projects(top)
  local projects = {}
  local function walk(dir, depth)
    if dir_has_project_files(dir) then
      local sections = collect(dir)
      if #sections > 0 then
        table.insert(projects, { dir = dir, sections = sections })
      end
    end
    if depth >= MAX_DEPTH then
      return
    end
    for name, ftype in vim.fs.dir(dir) do
      if ftype == "directory" and not SKIP_DIRS[name] and not name:match("^%.") then
        walk(dir .. "/" .. name, depth + 1)
      end
    end
  end
  walk(top, 0)
  return projects
end

---------------------------------------------------------------------------
-- Folding
---------------------------------------------------------------------------

-- fold state survives re-renders and reopens within the session;
-- keys: "P:<dir>" for projects, "S:<dir>:<title>" for sections
local folds = {}

local panel -- active panel state (only one at a time)

local function is_folded(key, default)
  local v = folds[key]
  if v == nil then
    return default
  end
  return v
end

local function render()
  local st = panel
  if not st or not vim.api.nvim_buf_is_valid(st.buf) then
    return
  end

  local lines, marks = {}, {}
  st.line_items, st.line_fold, st.header_line, st.fold_default = {}, {}, {}, {}

  lines[1] = " " .. vim.fn.fnamemodify(st.top, ":~")
  lines[2] = " <CR>:jump  <Tab>:fold  zM/zR:fold all  /:search  r:run  v:reveal env  a:add env  q:quit"
  marks[#marks + 1] = { 0, 0, #lines[1], "Title" }
  marks[#marks + 1] = { 1, 0, #lines[2], "Comment" }

  local label_w = 0
  for _, proj in ipairs(st.projects) do
    for _, sec in ipairs(proj.sections) do
      for _, it in ipairs(sec.items) do
        label_w = math.max(label_w, #it.label)
      end
    end
  end
  label_w = math.min(label_w, 40)

  local multi = #st.projects > 1
  for _, proj in ipairs(st.projects) do
    local pkey = "P:" .. proj.dir
    -- projects other than the one you're in start folded
    local pdefault = multi and proj.dir ~= st.nearest
    local pfolded = multi and is_folded(pkey, pdefault) or false
    if multi then
      st.fold_default[pkey] = pdefault
      local rel = proj.dir == st.top and "(root)" or (proj.dir:sub(#st.top + 2) .. "/")
      local count = 0
      for _, sec in ipairs(proj.sections) do
        count = count + #sec.items
      end
      local header = ("%s %s%s%s"):format(
        pfolded and "▸" or "▾",
        rel,
        pfolded and (" (%d)"):format(count) or "",
        proj.dir == st.nearest and "  ← current" or ""
      )
      table.insert(lines, "")
      table.insert(lines, header)
      marks[#marks + 1] = { #lines - 1, 0, #header, "Title" }
      st.line_fold[#lines] = pkey
      st.header_line[pkey] = #lines
    end
    if not pfolded then
      for _, sec in ipairs(proj.sections) do
        local skey = "S:" .. proj.dir .. ":" .. sec.title
        st.fold_default[skey] = false
        local sfolded = is_folded(skey, false)
        local sheader = ("%s %s%s"):format(sfolded and "▸" or "▾", sec.title, sfolded and (" (%d)"):format(#sec.items) or "")
        table.insert(lines, "")
        table.insert(lines, sheader)
        marks[#marks + 1] = { #lines - 1, 0, #sheader, "Statement" }
        st.line_fold[#lines] = skey
        st.header_line[skey] = #lines
        if not sfolded then
          for _, it in ipairs(sec.items) do
            local detail = it.detail or ""
            if it.sensitive and not reveal_env then
              detail = "••••••"
            end
            local label = #it.label > label_w and (it.label:sub(1, label_w - 1) .. "…") or it.label
            local line = ("   %-" .. label_w .. "s  %s"):format(label, detail)
            table.insert(lines, line)
            st.line_items[#lines] = it
            st.line_fold[#lines] = skey
            marks[#marks + 1] = { #lines - 1, 3, 3 + #label, it.run and "Function" or "Identifier" }
            marks[#marks + 1] = { #lines - 1, 3 + label_w, #line, "Comment" }
          end
        end
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

  -- resize/recenter; width only grows so the window doesn't jiggle
  local width = 0
  for _, l in ipairs(lines) do
    width = math.max(width, vim.fn.strdisplaywidth(l))
  end
  width = math.min(math.max(width + 2, st.width or 0), vim.o.columns - 8)
  st.width = width
  local height = math.min(#lines, vim.o.lines - 6)
  if vim.api.nvim_win_is_valid(st.win) then
    vim.api.nvim_win_set_config(st.win, {
      relative = "editor",
      row = math.floor((vim.o.lines - height) / 2) - 1,
      col = math.floor((vim.o.columns - width) / 2),
      width = width,
      height = height,
    })
  end
end

local function cur_item()
  return panel and panel.line_items[vim.api.nvim_win_get_cursor(panel.win)[1]]
end

local function close()
  if panel and vim.api.nvim_win_is_valid(panel.win) then
    vim.api.nvim_win_close(panel.win, true)
  end
  panel = nil
end

local function toggle_fold()
  local st = panel
  local lnum = vim.api.nvim_win_get_cursor(st.win)[1]
  local key = st.line_fold[lnum]
  if not key then
    return
  end
  folds[key] = not is_folded(key, st.fold_default[key])
  render()
  local hl = st.header_line[key]
  if hl then
    pcall(vim.api.nvim_win_set_cursor, st.win, { hl, 0 })
  end
end

local function set_all_folds(val)
  local st = panel
  local cursor_key = st.line_fold[vim.api.nvim_win_get_cursor(st.win)[1]]
  for _, proj in ipairs(st.projects) do
    if #st.projects > 1 then
      folds["P:" .. proj.dir] = val
    end
    for _, sec in ipairs(proj.sections) do
      folds["S:" .. proj.dir .. ":" .. sec.title] = val
    end
  end
  render()
  local hl = cursor_key and st.header_line[cursor_key]
  pcall(vim.api.nvim_win_set_cursor, st.win, { hl or 1, 0 })
end

-- projects sorted so the one the current buffer belongs to comes first
local function sorted_projects(top, nearest)
  local projects = find_projects(top)
  table.sort(projects, function(a, b)
    if (a.dir == nearest) ~= (b.dir == nearest) then
      return a.dir == nearest
    end
    return a.dir < b.dir
  end)
  return projects
end

-- re-scan manifests (after `a` writes a file) without losing fold state
local function refresh()
  local st = panel
  local cur = vim.api.nvim_win_get_cursor(st.win)[1]
  st.projects = sorted_projects(st.top, st.nearest)
  render()
  pcall(vim.api.nvim_win_set_cursor, st.win, { math.min(cur, vim.api.nvim_buf_line_count(st.buf)), 0 })
end

---------------------------------------------------------------------------
-- Full-text fuzzy search (Telescope) over every item of every project
---------------------------------------------------------------------------

-- Fuzzy-search across projects, sections, labels AND full detail text
-- (script bodies, versions, env values). <CR> jumps to the definition
-- line, <C-r> runs the item in toggleterm. Reuses the open panel's data
-- when called from it; collects fresh otherwise.
function M.search()
  local top, nearest, projects, target_win
  if panel then
    top, nearest, projects = panel.top, panel.nearest, panel.projects
    target_win = panel.prev_win
    close()
    if target_win and vim.api.nvim_win_is_valid(target_win) then
      vim.api.nvim_set_current_win(target_win)
    end
  else
    top, nearest = repo_root()
    projects = sorted_projects(top, nearest)
  end
  if #projects == 0 then
    vim.notify("projinfo: no package.json / Makefile / Cargo.toml / go.mod / .env found under " .. top, vim.log.levels.INFO)
    return
  end

  local multi = #projects > 1
  local entries = {}
  for _, proj in ipairs(projects) do
    local rel = proj.dir == top and "(root)" or proj.dir:sub(#top + 2)
    for _, sec in ipairs(proj.sections) do
      for _, it in ipairs(sec.items) do
        local detail = it.detail or ""
        if it.sensitive and not reveal_env then
          detail = "••••••"
        end
        table.insert(entries, {
          project = multi and rel or "",
          section = sec.title,
          label = it.label,
          detail = detail,
          item = it,
        })
      end
    end
  end

  local pickers = require("telescope.pickers")
  local finders = require("telescope.finders")
  local conf = require("telescope.config").values
  local entry_display = require("telescope.pickers.entry_display")
  local actions = require("telescope.actions")
  local action_state = require("telescope.actions.state")

  local displayer = entry_display.create({
    separator = "  ",
    items = {
      { width = multi and 18 or 1 },
      { width = 24 },
      { width = 28 },
      { remaining = true },
    },
  })

  pickers
    .new({}, {
      prompt_title = "Project info (fuzzy: name / detail / section)",
      finder = finders.new_table({
        results = entries,
        entry_maker = function(e)
          return {
            value = e,
            display = function(entry)
              local v = entry.value
              return displayer({
                { v.project, "Comment" },
                { v.section, "Statement" },
                { v.label, v.item.run and "Function" or "Identifier" },
                { v.detail, "Comment" },
              })
            end,
            -- full-text: project + section + label + detail are all matchable
            ordinal = ("%s %s %s %s"):format(e.project, e.section, e.label, e.detail),
          }
        end,
      }),
      sorter = conf.generic_sorter({}),
      attach_mappings = function(prompt_bufnr, map)
        actions.select_default:replace(function()
          local entry = action_state.get_selected_entry()
          actions.close(prompt_bufnr)
          local it = entry and entry.value.item
          if not it or not it.lnum then
            return
          end
          vim.cmd.edit(vim.fn.fnameescape(it.path))
          vim.api.nvim_win_set_cursor(0, { it.lnum, 0 })
          vim.cmd("normal! zz")
        end)
        map({ "i", "n" }, "<C-r>", function()
          local entry = action_state.get_selected_entry()
          local it = entry and entry.value.item
          if not it or not it.run then
            vim.notify("projinfo: not a runnable item (only scripts / make targets)", vim.log.levels.INFO)
            return
          end
          actions.close(prompt_bufnr)
          local ok = pcall(function()
            require("toggleterm").exec(it.run, nil, nil, it.cwd or top)
          end)
          if not ok then
            vim.notify("projinfo: toggleterm unavailable, command: " .. it.run, vim.log.levels.WARN)
          end
        end)
        return true
      end,
    })
    :find()
end

function M.show()
  local top, nearest = repo_root()
  local projects = sorted_projects(top, nearest)
  if #projects == 0 then
    vim.notify("projinfo: no package.json / Makefile / Cargo.toml / go.mod / .env found under " .. top, vim.log.levels.INFO)
    return
  end

  if panel then
    close()
  end
  local prev_win = vim.api.nvim_get_current_win()
  local buf = vim.api.nvim_create_buf(false, true)
  vim.bo[buf].bufhidden = "wipe"
  vim.bo[buf].filetype = "projinfo"

  local win = vim.api.nvim_open_win(buf, true, {
    relative = "editor",
    row = math.floor(vim.o.lines / 4),
    col = math.floor(vim.o.columns / 4),
    width = 40,
    height = 10,
    style = "minimal",
    border = "rounded",
    title = " Project Info ",
  })
  vim.wo[win].cursorline = true

  panel = {
    buf = buf,
    win = win,
    top = top,
    nearest = nearest,
    projects = projects,
    prev_win = prev_win,
  }
  render()

  vim.api.nvim_create_autocmd("BufWipeout", {
    buffer = buf,
    once = true,
    callback = function()
      panel = nil
    end,
  })

  local opts = { buffer = buf, nowait = true, silent = true }
  vim.keymap.set("n", "q", close, opts)
  vim.keymap.set("n", "<Esc>", close, opts)
  vim.keymap.set("n", "<Tab>", toggle_fold, opts)
  vim.keymap.set("n", "za", toggle_fold, opts)
  vim.keymap.set("n", "/", M.search, opts)
  vim.keymap.set("n", "zM", function()
    set_all_folds(true)
  end, opts)
  vim.keymap.set("n", "zR", function()
    set_all_folds(false)
  end, opts)
  vim.keymap.set("n", "v", function()
    reveal_env = not reveal_env
    local cur = vim.api.nvim_win_get_cursor(win)[1]
    render()
    pcall(vim.api.nvim_win_set_cursor, win, { math.min(cur, vim.api.nvim_buf_line_count(buf)), 0 })
  end, opts)
  vim.keymap.set("n", "a", function()
    local it = cur_item()
    if not it or not it.env_file then
      vim.notify("projinfo: put the cursor on an env entry to add to that file", vim.log.levels.INFO)
      return
    end
    vim.ui.input({ prompt = ("Add to %s (KEY=VALUE): "):format(vim.fn.fnamemodify(it.env_file, ":t")) }, function(input)
      if not input or input == "" then
        return
      end
      if not input:match("^[%w_%.]+=") then
        vim.notify("projinfo: expected KEY=VALUE format", vim.log.levels.WARN)
        return
      end
      vim.fn.writefile({ input }, it.env_file, "a")
      refresh()
    end)
  end, opts)
  vim.keymap.set("n", "<CR>", function()
    local it = cur_item()
    if not it or not it.lnum then
      return
    end
    local target = panel.prev_win
    close()
    if target and vim.api.nvim_win_is_valid(target) then
      vim.api.nvim_set_current_win(target)
    end
    vim.cmd.edit(vim.fn.fnameescape(it.path))
    vim.api.nvim_win_set_cursor(0, { it.lnum, 0 })
    vim.cmd("normal! zz")
  end, opts)
  vim.keymap.set("n", "r", function()
    local it = cur_item()
    if not it then
      return
    end
    if not it.run then
      vim.notify("projinfo: not a runnable item (only scripts / make targets)", vim.log.levels.INFO)
      return
    end
    close()
    local ok = pcall(function()
      require("toggleterm").exec(it.run, nil, nil, it.cwd or top)
    end)
    if not ok then
      vim.notify("projinfo: toggleterm unavailable, command: " .. it.run, vim.log.levels.WARN)
    end
  end, opts)
end

return M
