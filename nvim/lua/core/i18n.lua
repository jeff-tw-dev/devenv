-- i18n key navigation: gd on an i18n key string (e.g. t("common.submit"))
-- jumps to the key's definition inside the project's locale JSON files;
-- K floats every locale's translation for the key (both fall through to
-- their LSP behavior when the cursor isn't on a key).
-- Locale files are discovered from the buffer's package.json dir up to the
-- git root, plus one/two levels below the git root — so monorepo layouts
-- with translations shared above the frontend (repo/common/locales) work.
-- Nested keys resolve via the treesitter json parser (depth-accurate), with
-- a plain-text scan fallback. Multiple locales matching the same key open
-- a vim.ui.select picker showing each locale's translated value.
local M = {}

M.config = {
  -- glob patterns (relative to project root) used to find translation files
  patterns = {
    "locales/**/*.json",
    "locale/**/*.json",
    "i18n/**/*.json",
    "lang/**/*.json",
    "translations/**/*.json",
    "src/locales/**/*.json",
    "src/i18n/**/*.json",
    "src/lang/**/*.json",
    "src/translations/**/*.json",
    "public/locales/**/*.json",
    "assets/locales/**/*.json",
    "assets/i18n/**/*.json",
  },
  -- extra directories to search with the same patterns (absolute, or
  -- relative to the git root) — for layouts the auto-discovery misses
  extra_dirs = {},
  -- "nested": { a = { b = "…" } } · "flat": { ["a.b"] = "…" }
  -- "auto": try nested first, fall back to flat
  key_style = "nested",
  -- call names whose string argument is treated as an i18n key even
  -- without a dot in it (matched against the full dotted name and its
  -- last component, so "i18n.t" is covered by "t")
  func_names = { "t", "$t", "tc", "translate" },
}

---------------------------------------------------------------------------
-- Project root & locale file discovery
---------------------------------------------------------------------------

-- roots to glob, innermost first: every package.json dir from the buffer
-- up to the git root, then the git root itself (monorepos keep shared
-- translations above the frontend package). Without a git repo, just the
-- nearest package.json dir (bounded walk — never up to $HOME).
local function candidate_roots()
  local git = vim.fs.root(0, ".git")
  local roots, seen = {}, {}
  local function add(dir)
    if dir and not seen[dir] then
      seen[dir] = true
      table.insert(roots, dir)
    end
  end
  if git then
    local file = vim.api.nvim_buf_get_name(0)
    local dir = file ~= "" and vim.fs.dirname(file) or vim.fn.getcwd()
    while dir and dir:sub(1, #git) == git do
      if vim.uv.fs_stat(dir .. "/package.json") then
        add(dir)
      end
      if dir == git then
        break
      end
      dir = vim.fs.dirname(dir)
    end
    add(git)
  else
    add(vim.fs.root(0, "package.json") or vim.fn.getcwd())
  end
  return roots, git
end

local file_cache = {} -- roots-key -> discovered locale file list

local function locale_files(roots, git)
  local key = table.concat(roots, ";")
  if file_cache[key] then
    return file_cache[key]
  end
  local seen, files = {}, {}
  local function sweep(dir, prefix)
    for _, pat in ipairs(M.config.patterns) do
      for _, path in ipairs(vim.fn.globpath(dir, prefix .. pat, true, true)) do
        if not seen[path] and not path:find("node_modules", 1, true) then
          seen[path] = true
          table.insert(files, path)
        end
      end
    end
  end
  for _, root in ipairs(roots) do
    sweep(root, "")
  end
  if git then
    -- shared translations one or two levels below the git root
    -- (common/locales, packages/shared/i18n, …)
    sweep(git, "*/")
    sweep(git, "*/*/")
  end
  for _, dir in ipairs(M.config.extra_dirs) do
    if not dir:match("^[/~]") then
      dir = (git or roots[#roots]) .. "/" .. dir
    end
    sweep(vim.fn.expand(dir), "")
  end
  file_cache[key] = files
  return files
end

-- forget discovered locale files (pick up newly created ones)
function M.refresh()
  file_cache = {}
end

---------------------------------------------------------------------------
-- Key extraction at cursor
---------------------------------------------------------------------------

-- returns (string content, text before the opening quote) when the cursor
-- sits inside a quoted string on the current line
local function string_under_cursor()
  local line = vim.api.nvim_get_current_line()
  local col = vim.api.nvim_win_get_cursor(0)[2] + 1
  local i = 1
  while i <= #line do
    local c = line:sub(i, i)
    if c == '"' or c == "'" or c == "`" then
      local j = line:find(c, i + 1, true)
      if not j then
        return nil
      end
      if col >= i and col <= j then
        return line:sub(i + 1, j - 1), line:sub(1, i - 1)
      end
      i = j + 1
    else
      i = i + 1
    end
  end
end

-- is the string the first argument of a configured i18n call, e.g. t("…")?
local function is_i18n_call(prefix)
  local name = prefix:match("([%w_%$][%w_%$%.]*)%s*%(%s*$")
  if not name then
    return false
  end
  local last = name:match("([^%.]+)$")
  for _, fn in ipairs(M.config.func_names) do
    if name == fn or last == fn then
      return true
    end
  end
  return false
end

local function valid_key(key, in_call)
  if key == "" or key:find("%s") or key:find("%.%.") then
    return false
  end
  if not key:match("^[%w_%$%-][%w_%$%.:%-]*$") then
    return false
  end
  return in_call or key:find("%.", 1, true) ~= nil
end

---------------------------------------------------------------------------
-- Key lookup inside a JSON file
---------------------------------------------------------------------------

-- treesitter walk: descend object → pair per segment; flat matches the
-- whole dotted key as a single top-level pair
local function ts_locate(content, segments, flat)
  local ok, parser = pcall(vim.treesitter.get_string_parser, content, "json")
  if not ok or not parser then
    return nil
  end
  local okp, trees = pcall(parser.parse, parser)
  if not okp or not trees or not trees[1] then
    return nil
  end

  local function first_object(node)
    if node:type() == "object" then
      return node
    end
    for child in node:iter_children() do
      local o = first_object(child)
      if o then
        return o
      end
    end
  end

  local function pair_key(pair)
    local kn = pair:field("key")[1]
    if not kn then
      return nil
    end
    return vim.treesitter.get_node_text(kn, content):sub(2, -2), kn
  end

  local function result(pair, kn)
    local row, col = kn:range()
    local vn = pair:field("value")[1]
    local val = vn and vim.treesitter.get_node_text(vn, content) or ""
    return row + 1, col, val
  end

  local obj = first_object(trees[1]:root())
  if not obj then
    return nil
  end

  if flat then
    local want = table.concat(segments, ".")
    for pair in obj:iter_children() do
      if pair:type() == "pair" then
        local k, kn = pair_key(pair)
        if k == want then
          return result(pair, kn)
        end
      end
    end
    return nil
  end

  for i, seg in ipairs(segments) do
    local found
    for pair in obj:iter_children() do
      if pair:type() == "pair" then
        local k, kn = pair_key(pair)
        if k == seg then
          if i == #segments then
            return result(pair, kn)
          end
          found = pair
          break
        end
      end
    end
    if not found then
      return nil
    end
    local vn = found:field("value")[1]
    if not vn or vn:type() ~= "object" then
      return nil
    end
    obj = vn
  end
end

-- fallback without a json parser: search each `"segment":` in order (not
-- depth-aware, but correct for typical locale files)
local function scan_locate(content, segments, flat)
  local lines = vim.split(content, "\n", { plain = true })
  if flat then
    segments = { table.concat(segments, ".") }
  end
  local lnum, init, col = 1, 1, nil
  for _, seg in ipairs(segments) do
    local pat = '"' .. vim.pesc(seg) .. '"%s*:'
    local found = false
    for l = lnum, #lines do
      local s = lines[l]:find(pat, l == lnum and init or 1)
      if s then
        lnum, init, col, found = l, s + 1, s - 1, true
        break
      end
    end
    if not found then
      return nil
    end
  end
  local value = lines[lnum]:match(":%s*(.-),?%s*$") or ""
  return lnum, col, value
end

local function locate(content, key)
  local segments = vim.split(key, ".", { plain = true })
  local styles = M.config.key_style == "auto" and { false, true }
    or { M.config.key_style == "flat" }
  if #segments == 1 then -- single segment: flat ≡ nested top-level pair
    styles = { false }
  end
  for _, flat in ipairs(styles) do
    local lnum, col, value = ts_locate(content, segments, flat)
    if not lnum then
      lnum, col, value = scan_locate(content, segments, flat)
    end
    if lnum then
      return lnum, col, value
    end
  end
end

---------------------------------------------------------------------------
-- Match collection & jumping
---------------------------------------------------------------------------

-- shortest path relative to any root (falls back to ~-relative)
local function rel_label(path, roots)
  local label = vim.fn.fnamemodify(path, ":~")
  for _, root in ipairs(roots) do
    if path:sub(1, #root + 1) == root .. "/" then
      local rel = path:sub(#root + 2)
      if #rel < #label then
        label = rel
      end
    end
  end
  return label
end

-- returns { {file, lnum, col, value, label}, ... } across all locale files;
-- an i18next-style "ns:key" prefers files named/foldered after the namespace
function M.find(key)
  local roots, git = candidate_roots()
  local files = locale_files(roots, git)
  local tries = { { key = key, files = files } }
  local ns, rest = key:match("^([%w_%-]+):(.+)$")
  if ns then
    local nsfiles = vim.tbl_filter(function(p)
      return p:find("/" .. ns .. ".json", 1, true) or p:find("/" .. ns .. "/", 1, true)
    end, files)
    table.insert(tries, 1, { key = rest, files = nsfiles })
  end
  for _, try in ipairs(tries) do
    local matches = {}
    for _, path in ipairs(try.files) do
      local fok, flines = pcall(vim.fn.readfile, path)
      if fok then
        local lnum, col, value = locate(table.concat(flines, "\n"), try.key)
        if lnum then
          table.insert(matches, {
            file = path,
            lnum = lnum,
            col = col,
            value = value,
            label = rel_label(path, roots),
          })
        end
      end
    end
    if #matches > 0 then
      return matches
    end
  end
  return {}
end

local function goto_match(m)
  vim.cmd.edit(vim.fn.fnameescape(m.file))
  vim.api.nvim_win_set_cursor(0, { m.lnum, m.col or 0 })
  vim.cmd("normal! zz")
end

local function short_value(v)
  v = (v or ""):gsub("%s+", " ")
  return #v > 60 and v:sub(1, 57) .. "…" or v
end

-- gd entry point: returns true when the cursor was on an i18n key and the
-- jump was handled (callers fall back to LSP definition on false)
function M.jump()
  local key, prefix = string_under_cursor()
  if not key then
    return false
  end
  local in_call = is_i18n_call(prefix)
  if not valid_key(key, in_call) then
    return false
  end
  local matches = M.find(key)
  if #matches == 0 then
    if in_call then -- definitely an i18n key: don't bounce to LSP
      vim.notify("i18n: key not found in locale files: " .. key, vim.log.levels.WARN)
      return true
    end
    return false
  end
  if #matches == 1 then
    goto_match(matches[1])
    return true
  end
  vim.ui.select(matches, {
    prompt = "i18n: " .. key,
    format_item = function(m)
      return ("%s  →  %s"):format(m.label, short_value(m.value))
    end,
  }, function(choice)
    if choice then
      goto_match(choice)
    end
  end)
  return true
end

-- float all locale values for the key under the cursor (no jump);
-- returns true when handled so K can fall back to LSP hover on false
function M.peek()
  local key, prefix = string_under_cursor()
  if not key then
    return false
  end
  local in_call = is_i18n_call(prefix)
  if not valid_key(key, in_call) then
    return false
  end
  local matches = M.find(key)
  if #matches == 0 then
    if in_call then -- definitely an i18n key: don't bounce to LSP hover
      vim.notify("i18n: key not found in locale files: " .. key, vim.log.levels.WARN)
      return true
    end
    return false
  end
  local lines, width = {}, 0
  for _, m in ipairs(matches) do
    local l = ("%s: %s"):format(m.label, short_value(m.value))
    table.insert(lines, l)
    width = math.max(width, vim.fn.strdisplaywidth(l))
  end
  local buf = vim.api.nvim_create_buf(false, true)
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
  vim.bo[buf].bufhidden = "wipe"
  vim.api.nvim_open_win(buf, false, {
    relative = "cursor",
    row = 1,
    col = 0,
    width = math.min(width + 1, vim.o.columns - 4),
    height = #lines,
    style = "minimal",
    border = "rounded",
    title = " " .. key .. " ",
    focusable = false,
  })
  vim.api.nvim_create_autocmd({ "CursorMoved", "InsertEnter", "BufLeave" }, {
    once = true,
    callback = function()
      if vim.api.nvim_buf_is_valid(buf) then
        vim.api.nvim_buf_delete(buf, { force = true })
      end
    end,
  })
  return true
end

function M.setup(opts)
  M.config = vim.tbl_deep_extend("force", M.config, opts or {})
  vim.api.nvim_create_user_command("I18nJump", function()
    if not M.jump() then
      vim.notify("i18n: no key under cursor", vim.log.levels.INFO)
    end
  end, { desc = "Jump to i18n key definition in locale files" })
  vim.api.nvim_create_user_command("I18nPeek", function()
    if not M.peek() then
      vim.notify("i18n: no key under cursor", vim.log.levels.INFO)
    end
  end, { desc = "Peek all locale values for i18n key under cursor" })
  vim.api.nvim_create_user_command("I18nRefresh", M.refresh, { desc = "Re-scan locale files (clears discovery cache)" })
end

return M
