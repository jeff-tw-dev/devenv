-- Mark code / files, compose them into an LLM prompt (review / debug /
-- analysis / coach / custom) with model + effort parameters, and send it:
-- headless `claude -p` by default (question + answer auto-saved as markdown,
-- browsable in the history panel), or paste into the Claude TUI tmux pane
-- for interactive discussion.
--
-- Marks panel:   <CR> jump, dd delete, e edit note, C clear all, q close
-- History panel: <CR> open exchange, dd delete, q close
local M = {}

local ns = vim.api.nvim_create_namespace("llm")

---------------------------------------------------------------------------
-- Configuration (edit freely)
---------------------------------------------------------------------------

local CLI = "claude" -- swap for another agent CLI here

local TEMPLATES = {
  {
    name = "Review",
    prompt = "Review the following code. Point out bugs, risky edge cases, and concrete improvement suggestions, ordered by severity.",
  },
  {
    name = "Debug",
    prompt = "Help me debug the following code. Identify likely root causes, explain the failure mechanism, and propose fixes.",
  },
  {
    name = "Analysis",
    prompt = "Analyze the following code: explain its structure, data flow, and design trade-offs, and note anything surprising.",
  },
  {
    name = "Coach",
    prompt = "Act as a coding coach. Walk me through the following code: what it does, the idioms and patterns it uses, and what I should learn from or improve about it.",
  },
  { name = "Custom", prompt = nil }, -- free-form input
}

local MODELS = { "default", "opus", "sonnet", "haiku" }
local EFFORTS = { "default", "low", "medium", "high" }

local FOOTER = "Answer in Traditional Chinese (繁體中文)."

local marks_path = vim.fn.stdpath("data") .. "/llm-marks.json"
local history_root = vim.fn.stdpath("data") .. "/llm-history"

---------------------------------------------------------------------------
-- Storage (marks keyed by cwd, same pattern as core/bookmarks.lua)
---------------------------------------------------------------------------

local data -- { projects = { [cwd] = { {path, s?, e?, text?, note?}, ... } } }

local function load()
  if data then
    return data
  end
  data = { projects = {} }
  if vim.fn.filereadable(marks_path) == 1 then
    local ok, decoded = pcall(vim.json.decode, table.concat(vim.fn.readfile(marks_path), "\n"))
    if ok and type(decoded) == "table" and type(decoded.projects) == "table" then
      data = decoded
    end
  end
  return data
end

local function save()
  vim.fn.writefile({ vim.json.encode(data) }, marks_path)
end

local function project_key()
  return vim.fn.getcwd()
end

local function project_marks()
  local key = project_key()
  load().projects[key] = load().projects[key] or {}
  return load().projects[key]
end

-- slug for the per-project history directory
local function history_dir()
  local slug = project_key():gsub("[/\\:]", "-"):gsub("^%-+", "")
  local dir = history_root .. "/" .. slug
  vim.fn.mkdir(dir, "p")
  return dir
end

---------------------------------------------------------------------------
-- Marking
---------------------------------------------------------------------------

local function buf_relpath()
  local path = vim.api.nvim_buf_get_name(0)
  if path == "" or vim.bo.buftype ~= "" then
    vim.notify("llm: not a file buffer", vim.log.levels.INFO)
    return nil
  end
  return vim.fn.fnamemodify(path, ":~:.")
end

-- normal mode: mark the whole file; visual mode: mark the selection
function M.mark()
  local path = buf_relpath()
  if not path then
    return
  end
  local mode = vim.fn.mode()
  local marks = project_marks()
  if mode == "v" or mode == "V" or mode == "\22" then
    -- leave visual mode so '< and '> are set to the current selection
    vim.cmd([[execute "normal! \<Esc>"]])
    local s = vim.api.nvim_buf_get_mark(0, "<")[1]
    local e = vim.api.nvim_buf_get_mark(0, ">")[1]
    if s > e then
      s, e = e, s
    end
    local text = table.concat(vim.api.nvim_buf_get_lines(0, s - 1, e, false), "\n")
    table.insert(marks, { path = path, s = s, e = e, text = text })
    vim.notify(("llm: marked %s:%d-%d (%d total)"):format(path, s, e, #marks))
  else
    table.insert(marks, { path = path })
    vim.notify(("llm: marked file %s (%d total)"):format(path, #marks))
  end
  save()
end

-- add/edit a note on the most recent mark for the current file (or the
-- mark covering the cursor line)
function M.annotate()
  local path = buf_relpath()
  if not path then
    return
  end
  local row = vim.api.nvim_win_get_cursor(0)[1]
  local marks = project_marks()
  local target
  for i = #marks, 1, -1 do
    local m = marks[i]
    if m.path == path then
      if m.s and row >= m.s and row <= m.e then
        target = m
        break
      end
      target = target or m
    end
  end
  if not target then
    vim.notify("llm: no mark for this file yet", vim.log.levels.INFO)
    return
  end
  vim.ui.input({ prompt = "Mark note: ", default = target.note or "" }, function(input)
    if input == nil then
      return
    end
    target.note = input ~= "" and input or nil
    save()
  end)
end

---------------------------------------------------------------------------
-- Prompt composition
---------------------------------------------------------------------------

local function compose(intent_prompt)
  local marks = project_marks()
  local parts = { intent_prompt, "" }
  for _, m in ipairs(marks) do
    if m.s then
      table.insert(parts, ("[%s:%d-%d]%s"):format(m.path, m.s, m.e, m.note and (" — " .. m.note) or ""))
      table.insert(parts, "```")
      table.insert(parts, m.text)
      table.insert(parts, "```")
    else
      table.insert(parts, ("[%s] (whole file — read it yourself)%s"):format(m.path, m.note and (" — " .. m.note) or ""))
    end
    table.insert(parts, "")
  end
  table.insert(parts, FOOTER)
  return table.concat(parts, "\n")
end

---------------------------------------------------------------------------
-- Send: headless claude -p
---------------------------------------------------------------------------

local function timestamp()
  return os.date("%Y%m%d-%H%M%S")
end

local running = 0

local function headless_send(prompt, intent, model, effort)
  local argv = { CLI, "-p", prompt }
  if model ~= "default" then
    vim.list_extend(argv, { "--model", model })
  end
  if effort ~= "default" then
    vim.list_extend(argv, { "--effort", effort })
  end

  local out_file = ("%s/%s-%s.md"):format(history_dir(), timestamp(), intent:lower())
  running = running + 1
  vim.notify(("llm: %s running headless (%s/%s)… answer -> history"):format(intent, model, effort))

  vim.system(argv, { cwd = project_key(), text = true }, function(res)
    running = running - 1
    vim.schedule(function()
      local answer = res.code == 0 and vim.trim(res.stdout or "") or ("(claude exited %d)\n%s"):format(res.code, res.stderr or "")
      local lines = { "# " .. intent .. " — " .. os.date("%Y-%m-%d %H:%M"), "", ("model: %s · effort: %s"):format(model, effort), "", "## Prompt", "" }
      vim.list_extend(lines, vim.split(prompt, "\n"))
      vim.list_extend(lines, { "", "## Answer", "" })
      vim.list_extend(lines, vim.split(answer, "\n"))
      vim.fn.writefile(lines, out_file)
      if res.code == 0 then
        vim.cmd("vsplit " .. vim.fn.fnameescape(out_file))
        vim.notify("llm: " .. intent .. " done")
      else
        vim.notify("llm: claude failed — " .. (res.stderr or ""), vim.log.levels.ERROR)
      end
    end)
  end)
  M._last_history_file = out_file
end

-- follow-up on the most recent headless conversation in this project
function M.followup()
  vim.ui.input({ prompt = "Follow-up: " }, function(input)
    if not input or input == "" then
      return
    end
    local prompt = input .. "\n\n" .. FOOTER
    local argv = { CLI, "-p", "-c", prompt }
    vim.notify("llm: follow-up running…")
    vim.system(argv, { cwd = project_key(), text = true }, function(res)
      vim.schedule(function()
        local answer = res.code == 0 and vim.trim(res.stdout or "") or ("(claude exited %d)\n%s"):format(res.code, res.stderr or "")
        local target = M._last_history_file
        if target and vim.fn.filereadable(target) == 1 then
          local lines = vim.fn.readfile(target)
          vim.list_extend(lines, { "", "## Follow-up", "", input, "", "## Answer", "" })
          vim.list_extend(lines, vim.split(answer, "\n"))
          vim.fn.writefile(lines, target)
          vim.cmd("vsplit " .. vim.fn.fnameescape(target))
          vim.cmd("normal! G")
        else
          vim.notify(answer, vim.log.levels.INFO)
        end
      end)
    end)
  end)
end

---------------------------------------------------------------------------
-- Send: paste into the Claude TUI tmux pane (ported from cx-paste)
---------------------------------------------------------------------------

local function tui_paste(prompt)
  if vim.env.TMUX == nil then
    vim.fn.setreg("+", prompt)
    vim.notify("llm: not inside tmux — prompt copied to clipboard", vim.log.levels.WARN)
    return
  end
  -- find a pane in the current window that is not an editor/sidebar
  local panes = vim.fn.systemlist({ "tmux", "list-panes", "-F", "#{pane_id} #{pane_title} #{pane_current_command}" })
  local target
  for _, p in ipairs(panes) do
    local id, title, cmd = p:match("^(%S+)%s+(%S*)%s*(%S*)$")
    if id and title ~= "cx-sidebar" and title ~= "cx-edit" and cmd ~= "nvim" and cmd ~= "vim" then
      target = id
      break
    end
  end
  if not target then
    vim.fn.setreg("+", prompt)
    vim.notify("llm: no TUI pane found — prompt copied to clipboard", vim.log.levels.WARN)
    return
  end
  local tmp = vim.fn.tempname()
  vim.fn.writefile(vim.split(prompt, "\n"), tmp)
  vim.fn.system({ "tmux", "load-buffer", tmp })
  vim.fn.system({ "tmux", "paste-buffer", "-t", target })
  vim.fn.delete(tmp)
  vim.fn.system({ "tmux", "select-pane", "-t", target })
  vim.notify("llm: prompt pasted into TUI pane (review, then press Enter)")
end

---------------------------------------------------------------------------
-- Ask: intent -> model -> effort -> action
---------------------------------------------------------------------------

function M.ask()
  if #project_marks() == 0 then
    vim.notify("llm: no marks yet — <leader>am to mark code or files", vim.log.levels.INFO)
    return
  end
  local names = {}
  for _, t in ipairs(TEMPLATES) do
    table.insert(names, t.name)
  end
  vim.ui.select(names, { prompt = "Intent" }, function(intent)
    if not intent then
      return
    end
    local tmpl
    for _, t in ipairs(TEMPLATES) do
      if t.name == intent then
        tmpl = t
      end
    end

    local function with_prompt(intent_prompt)
      vim.ui.select(MODELS, { prompt = "Model" }, function(model)
        if not model then
          return
        end
        vim.ui.select(EFFORTS, { prompt = "Effort" }, function(effort)
          if not effort then
            return
          end
          local prompt = compose(intent_prompt)
          vim.ui.select(
            { "headless (save Q&A to history)", "paste into TUI pane", "copy to clipboard" },
            { prompt = "Send via" },
            function(action)
              if not action then
                return
              end
              if action:match("^headless") then
                headless_send(prompt, intent, model, effort)
              elseif action:match("^paste") then
                tui_paste(prompt)
              else
                vim.fn.setreg("+", prompt)
                vim.notify("llm: prompt copied to clipboard")
              end
            end
          )
        end)
      end)
    end

    if tmpl.prompt then
      with_prompt(tmpl.prompt)
    else
      vim.ui.input({ prompt = "Custom instruction: " }, function(input)
        if input and input ~= "" then
          with_prompt(input)
        end
      end)
    end
  end)
end

---------------------------------------------------------------------------
-- Marks panel
---------------------------------------------------------------------------

local panel

local function close_panel()
  if panel and vim.api.nvim_win_is_valid(panel.win) then
    vim.api.nvim_win_close(panel.win, true)
  end
  panel = nil
end

local function open_float(title, ft)
  local prev_win = vim.api.nvim_get_current_win()
  local buf = vim.api.nvim_create_buf(false, true)
  vim.bo[buf].bufhidden = "wipe"
  vim.bo[buf].filetype = ft
  local win = vim.api.nvim_open_win(buf, true, {
    relative = "editor",
    row = 5,
    col = 10,
    width = 60,
    height = 12,
    style = "minimal",
    border = "rounded",
    title = title,
  })
  vim.wo[win].cursorline = true
  vim.api.nvim_create_autocmd("BufWipeout", {
    buffer = buf,
    once = true,
    callback = function()
      panel = nil
    end,
  })
  return { buf = buf, win = win, prev_win = prev_win, line_items = {} }
end

local function set_panel_lines(lines, marks)
  local st = panel
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

local function render_marks_panel()
  local st = panel
  local lines, hl = {}, {}
  st.line_items = {}
  lines[1] = " LLM marks"
  lines[2] = " <CR>:jump  dd:delete  e:note  C:clear all  q:quit"
  hl[#hl + 1] = { 0, 0, #lines[1], "Title" }
  hl[#hl + 1] = { 1, 0, #lines[2], "Comment" }

  local marks = project_marks()
  if #marks == 0 then
    table.insert(lines, "")
    table.insert(lines, "   (no marks)")
  end
  for _, m in ipairs(marks) do
    local loc = m.s and ("%s:%d-%d"):format(m.path, m.s, m.e) or (m.path .. "  (file)")
    local snippet = m.s and vim.trim((m.text or ""):match("^[^\n]*") or "") or ""
    local line = ("   %s  %s%s"):format(loc, m.note and ("[" .. m.note .. "] ") or "", snippet)
    table.insert(lines, line)
    st.line_items[#lines] = m
    hl[#hl + 1] = { #lines - 1, 3, 3 + #loc, "Identifier" }
    if m.note then
      hl[#hl + 1] = { #lines - 1, 5 + #loc, 5 + #loc + #m.note + 2, "Function" }
    end
  end
  set_panel_lines(lines, hl)
end

function M.list()
  if panel then
    close_panel()
  end
  panel = open_float(" LLM marks ", "llmmarks")
  render_marks_panel()

  local function cur_item()
    return panel.line_items[vim.api.nvim_win_get_cursor(panel.win)[1]]
  end
  local opts = { buffer = panel.buf, nowait = true, silent = true }
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
    if it.s then
      vim.api.nvim_win_set_cursor(0, { math.min(it.s, vim.api.nvim_buf_line_count(0)), 0 })
      vim.cmd("normal! zz")
    end
  end, opts)
  vim.keymap.set("n", "dd", function()
    local it = cur_item()
    if not it then
      return
    end
    local marks = project_marks()
    for i, m in ipairs(marks) do
      if m == it then
        table.remove(marks, i)
        break
      end
    end
    save()
    render_marks_panel()
  end, opts)
  vim.keymap.set("n", "e", function()
    local it = cur_item()
    if not it then
      return
    end
    vim.ui.input({ prompt = "Mark note: ", default = it.note or "" }, function(input)
      if input == nil then
        return
      end
      it.note = input ~= "" and input or nil
      save()
      render_marks_panel()
    end)
  end, opts)
  vim.keymap.set("n", "C", function()
    load().projects[project_key()] = {}
    save()
    render_marks_panel()
  end, opts)
end

---------------------------------------------------------------------------
-- History panel
---------------------------------------------------------------------------

function M.history()
  if panel then
    close_panel()
  end
  panel = open_float(" LLM history ", "llmhistory")

  local function render()
    local st = panel
    local lines, hl = {}, {}
    st.line_items = {}
    lines[1] = " LLM history"
    lines[2] = " <CR>:open  dd:delete  q:quit"
    hl[#hl + 1] = { 0, 0, #lines[1], "Title" }
    hl[#hl + 1] = { 1, 0, #lines[2], "Comment" }
    local files = vim.fn.glob(history_dir() .. "/*.md", true, true)
    table.sort(files, function(a, b)
      return a > b
    end)
    if #files == 0 then
      table.insert(lines, "")
      table.insert(lines, "   (no history)")
    end
    table.insert(lines, "")
    for _, f in ipairs(files) do
      local name = vim.fn.fnamemodify(f, ":t:r")
      local date, time, intent = name:match("^(%d+)-(%d+)-(.*)$")
      local label = date
          and ("   %s-%s-%s %s:%s  %s"):format(
            date:sub(1, 4),
            date:sub(5, 6),
            date:sub(7, 8),
            time:sub(1, 2),
            time:sub(3, 4),
            intent
          )
        or ("   " .. name)
      table.insert(lines, label)
      st.line_items[#lines] = f
      hl[#hl + 1] = { #lines - 1, 3, #label, "Identifier" }
    end
    set_panel_lines(lines, hl)
  end
  render()

  local function cur_file()
    return panel.line_items[vim.api.nvim_win_get_cursor(panel.win)[1]]
  end
  local opts = { buffer = panel.buf, nowait = true, silent = true }
  vim.keymap.set("n", "q", close_panel, opts)
  vim.keymap.set("n", "<Esc>", close_panel, opts)
  vim.keymap.set("n", "<CR>", function()
    local f = cur_file()
    if not f then
      return
    end
    local target = panel.prev_win
    close_panel()
    if target and vim.api.nvim_win_is_valid(target) then
      vim.api.nvim_set_current_win(target)
    end
    vim.cmd("vsplit " .. vim.fn.fnameescape(f))
  end, opts)
  vim.keymap.set("n", "dd", function()
    local f = cur_file()
    if not f then
      return
    end
    vim.fn.delete(f)
    render()
  end, opts)
end

-- exposed for testing
M._compose = compose
M._project_marks = project_marks

return M
