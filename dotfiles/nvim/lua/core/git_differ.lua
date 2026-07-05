-- Git differ: commit-browsing layer on top of diffview.nvim.
-- Back/forth through history (each commit diffed against its parent),
-- fuzzy commit search by message/date, arbitrary two-commit compare,
-- a commit-message float, and a keymap cheatsheet.

local M = {}

-- git's well-known empty tree object, used as the parent of the root commit
local EMPTY_TREE = "4b825dc642cb6eb9a060e54bf8d69288fbee4904"

local state = {
  commits = {}, -- newest first: { hash, date, subject }
  index = -1, -- -1 = working tree, 0 = HEAD, 1 = HEAD~1, ...
  navigating = false, -- guards the view_closed hook during close+reopen
  msg = { win = nil, buf = nil },
  help = { win = nil },
}

local function git(args)
  local cmd = { "git" }
  vim.list_extend(cmd, args)
  local out = vim.fn.systemlist(cmd)
  if vim.v.shell_error ~= 0 then
    return nil
  end
  return out
end

local function load_commits()
  local lines = git({ "log", "--format=%h\t%ad\t%s", "--date=format:%Y-%m-%d" })
  if not lines then
    vim.notify("Git differ: 這裡不是 git repo（或還沒有任何 commit）", vim.log.levels.WARN)
    return false
  end
  state.commits = {}
  for _, l in ipairs(lines) do
    local hash, date, subject = l:match("^(%S+)\t(%S+)\t(.*)$")
    if hash then
      state.commits[#state.commits + 1] = { hash = hash, date = date, subject = subject }
    end
  end
  return #state.commits > 0
end

local function ensure_commits(force)
  if force or #state.commits == 0 then
    return load_commits()
  end
  return true
end

local function index_of(hash)
  for i, c in ipairs(state.commits) do
    if c.hash == hash then
      return i - 1
    end
  end
  return -1
end

local function view_is_open()
  local ok, lib = pcall(require, "diffview.lib")
  return ok and lib.get_current_view() ~= nil
end

local function label(index)
  if index < 0 then
    return "working tree"
  elseif index == 0 then
    return "HEAD"
  end
  return ("HEAD~%d"):format(index)
end

local function announce()
  if state.index < 0 then
    vim.notify("Git differ: working tree（尚未 commit 的變更）", vim.log.levels.INFO)
  else
    local c = state.commits[state.index + 1]
    vim.notify(
      ("Git differ: [%s] %s %s · %s"):format(label(state.index), c.hash, c.date, c.subject),
      vim.log.levels.INFO
    )
  end
end

---------------------------------------------------------------------------
-- Commit message float
---------------------------------------------------------------------------

local function msg_float_valid()
  return state.msg.win and vim.api.nvim_win_is_valid(state.msg.win)
end

local function close_msg_float()
  if msg_float_valid() then
    vim.api.nvim_win_close(state.msg.win, true)
  end
  state.msg.win = nil
end

local function render_msg_float()
  local c = state.commits[state.index + 1]
  if not c then
    return
  end
  local lines = git({ "show", "-s", "--format=medium", "--date=format:%Y-%m-%d %H:%M", c.hash })
    or { "(無法讀取 commit message)" }

  if not (state.msg.buf and vim.api.nvim_buf_is_valid(state.msg.buf)) then
    state.msg.buf = vim.api.nvim_create_buf(false, true)
    vim.bo[state.msg.buf].bufhidden = "hide"
    vim.bo[state.msg.buf].filetype = "git"
  end
  vim.bo[state.msg.buf].modifiable = true
  vim.api.nvim_buf_set_lines(state.msg.buf, 0, -1, false, lines)
  vim.bo[state.msg.buf].modifiable = false

  local width = 40
  for _, l in ipairs(lines) do
    width = math.max(width, vim.fn.strdisplaywidth(l))
  end
  width = math.min(width + 2, math.floor(vim.o.columns * 0.5))
  local win_opts = {
    relative = "editor",
    anchor = "NE",
    row = 1,
    col = vim.o.columns - 1,
    width = width,
    height = math.min(#lines, 20),
    style = "minimal",
    border = "rounded",
    title = (" %s (%s) "):format(c.hash, label(state.index)),
    title_pos = "center",
    focusable = false,
    zindex = 60,
  }
  if msg_float_valid() then
    vim.api.nvim_win_set_config(state.msg.win, win_opts)
  else
    state.msg.win = vim.api.nvim_open_win(state.msg.buf, false, win_opts)
  end
  vim.wo[state.msg.win].wrap = true
end

---------------------------------------------------------------------------
-- Opening views
---------------------------------------------------------------------------

-- Close the current view (if any) and open the diff for the given index.
-- index >= 0 shows what that commit changed (parent..commit);
-- index == -1 shows uncommitted working tree changes.
local function open_at(index)
  state.index = index
  state.navigating = true
  if view_is_open() then
    vim.cmd("DiffviewClose")
  end
  if index < 0 then
    vim.cmd("DiffviewOpen")
  else
    local c = state.commits[index + 1]
    local parent = (index + 2 <= #state.commits) and (c.hash .. "^") or EMPTY_TREE
    vim.cmd(("DiffviewOpen %s..%s"):format(parent, c.hash))
  end
  state.navigating = false

  if msg_float_valid() then
    if state.index >= 0 then
      render_msg_float()
    else
      close_msg_float()
    end
  end
  announce()
end

function M.toggle()
  if view_is_open() then
    vim.cmd("DiffviewClose") -- view_closed hook resets state
    return
  end
  if not load_commits() then
    return
  end
  open_at(-1)
end

function M.older()
  if not ensure_commits() then
    return
  end
  if not view_is_open() then
    state.index = -1
  end
  if state.index + 1 >= #state.commits then
    vim.notify("Git differ: 已經是最舊的 commit", vim.log.levels.INFO)
    return
  end
  open_at(state.index + 1)
end

function M.newer()
  if not ensure_commits() then
    return
  end
  if not view_is_open() then
    open_at(-1)
    return
  end
  if state.index <= -1 then
    vim.notify("Git differ: 已經在最新的 working tree", vim.log.levels.INFO)
    return
  end
  open_at(state.index - 1)
end

function M.toggle_message()
  if msg_float_valid() then
    close_msg_float()
    return
  end
  if not view_is_open() or state.index < 0 then
    vim.notify("Git differ: 目前是尚未 commit 的變更，沒有 commit message", vim.log.levels.INFO)
    return
  end
  render_msg_float()
end

-- Called from diffview's view_closed hook.
function M.on_view_closed()
  if state.navigating then
    return
  end
  state.index = -1
  close_msg_float()
end

---------------------------------------------------------------------------
-- Telescope pickers
---------------------------------------------------------------------------

local function commit_picker(opts)
  local pickers = require("telescope.pickers")
  local finders = require("telescope.finders")
  local conf = require("telescope.config").values
  local previewers = require("telescope.previewers")
  local t_actions = require("telescope.actions")
  local action_state = require("telescope.actions.state")

  pickers
    .new({}, {
      prompt_title = opts.title,
      finder = finders.new_table({
        results = state.commits,
        entry_maker = function(c)
          return {
            value = c,
            display = ("%s  %s  %s"):format(c.hash, c.date, c.subject),
            ordinal = ("%s %s %s"):format(c.date, c.subject, c.hash),
          }
        end,
      }),
      sorter = conf.generic_sorter({}),
      previewer = previewers.new_termopen_previewer({
        get_command = function(entry)
          return { "git", "show", "--color=always", "--stat", "--patch", entry.value.hash }
        end,
      }),
      attach_mappings = function(prompt_bufnr)
        t_actions.select_default:replace(function()
          local entry = action_state.get_selected_entry()
          t_actions.close(prompt_bufnr)
          if entry then
            opts.on_select(entry.value)
          end
        end)
        return true
      end,
    })
    :find()
end

-- Fuzzy-search commits by message or date (e.g. "fix", "2026-07"),
-- then open that commit's diff against its parent.
function M.find_commit()
  if not ensure_commits(true) then
    return
  end
  commit_picker({
    title = "搜尋 commit（訊息或日期，如 fix / 2026-07）",
    on_select = function(c)
      open_at(index_of(c.hash))
    end,
  })
end

-- Pick two arbitrary commits and diff them (base → target).
function M.compare_commits()
  if not ensure_commits(true) then
    return
  end
  commit_picker({
    title = "① 選擇基準 commit（較舊的 base）",
    on_select = function(base)
      vim.schedule(function()
        commit_picker({
          title = ("② 選擇目標 commit（與 %s 比較）"):format(base.hash),
          on_select = function(target)
            state.navigating = true
            if view_is_open() then
              vim.cmd("DiffviewClose")
            end
            vim.cmd(("DiffviewOpen %s..%s"):format(base.hash, target.hash))
            state.navigating = false
            state.index = index_of(target.hash)
            if msg_float_valid() then
              render_msg_float()
            end
            vim.notify(
              ("Git differ: 比較 %s..%s（%s → %s）"):format(base.hash, target.hash, base.subject, target.subject),
              vim.log.levels.INFO
            )
          end,
        })
      end)
    end,
  })
end

---------------------------------------------------------------------------
-- Keymap cheatsheet
---------------------------------------------------------------------------

function M.help()
  if state.help.win and vim.api.nvim_win_is_valid(state.help.win) then
    vim.api.nvim_win_close(state.help.win, true)
    state.help.win = nil
    return
  end

  local lines = {
    "",
    "  全域",
    "    <leader>gd    開關 git diff 瀏覽器（working tree 未 commit 的變更）",
    "    <leader>gp    ← 上一個（較舊）commit：該 commit 相對其父層改了什麼",
    "    <leader>gn    → 下一個（較新）commit，走到底回到 working tree",
    "    <leader>gf    搜尋 commit（fuzzy 比對訊息或日期），選中直接開 diff",
    "    <leader>gc    自選兩個 commit 互相比較（先選 base 再選 target）",
    "    <leader>gm    開關右上角 commit message 浮窗（隨瀏覽自動更新）",
    "    <leader>g?    本說明",
    "    <leader>gh    目前檔案的 commit 歷史",
    "    <leader>gH    整個 branch 的 commit 歷史",
    "    <leader>gb    切換 git branch（Telescope）",
    "",
    "  Diffview 面板內",
    "    <C-j>/<C-k>   下一個 / 上一個 檔案（歷史面板則是 commit entry）",
    "    <Tab>/<S-Tab> 切換檔案並開啟 diff（diffview 內建）",
    "    [c / ]c       跳到上一個 / 下一個變更區塊（vim diff 內建）",
    "    g?            diffview 內建完整說明",
    "",
    "  提示：gp/gn 以「commit n 對 n-1」瀏覽每個 commit 的變更；",
    "        用 gc 自選比較後，gp/gn 會從 target commit 繼續接著走。",
    "",
    "  按 q 或 <Esc> 關閉本視窗",
    "",
  }

  local buf = vim.api.nvim_create_buf(false, true)
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
  vim.bo[buf].modifiable = false
  vim.bo[buf].bufhidden = "wipe"

  local width = 0
  for _, l in ipairs(lines) do
    width = math.max(width, vim.fn.strdisplaywidth(l))
  end
  width = math.min(width + 2, vim.o.columns - 4)
  local height = math.min(#lines, vim.o.lines - 4)
  state.help.win = vim.api.nvim_open_win(buf, true, {
    relative = "editor",
    row = math.floor((vim.o.lines - height) / 2),
    col = math.floor((vim.o.columns - width) / 2),
    width = width,
    height = height,
    style = "minimal",
    border = "rounded",
    title = " Git differ 快捷鍵 ",
    title_pos = "center",
  })

  local function close()
    if state.help.win and vim.api.nvim_win_is_valid(state.help.win) then
      vim.api.nvim_win_close(state.help.win, true)
    end
    state.help.win = nil
  end
  for _, key in ipairs({ "q", "<Esc>" }) do
    vim.keymap.set("n", key, close, { buffer = buf, nowait = true })
  end
end

return M
