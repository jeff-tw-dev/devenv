-- Central external-dependency checks: on a machine missing node/go/cc/etc.
-- the related features degrade quietly instead of erroring at startup.
-- One compact INFO notification summarizes what was disabled; :DepsCheck
-- shows the full status anytime.

local M = {}

M.missing = {} -- bin -> list of features disabled because of it

function M.has(bin)
  return vim.fn.executable(bin) == 1
end

-- Record that `feature` was disabled for lack of `bin`.
function M.note(bin, feature)
  M.missing[bin] = M.missing[bin] or {}
  table.insert(M.missing[bin], feature)
end

-- True when `bin` exists; otherwise records the disabled feature and
-- returns false. Use as the gate in plugin configs / cond.
function M.need(bin, feature)
  if M.has(bin) then
    return true
  end
  M.note(bin, feature)
  return false
end

function M.has_cc()
  for _, cc in ipairs({ "cc", "gcc", "clang", "zig" }) do
    if M.has(cc) then
      return true
    end
  end
  return false
end

function M.need_cc(feature)
  if M.has_cc() then
    return true
  end
  M.note("cc/gcc/clang", feature)
  return false
end

---------------------------------------------------------------------------
-- One-shot startup summary (INFO, not an error wall)
---------------------------------------------------------------------------

local reported = false

function M.report()
  if reported or next(M.missing) == nil then
    return
  end
  reported = true
  local bins = vim.tbl_keys(M.missing)
  table.sort(bins)
  vim.notify(
    ("缺少 %s — 相關功能已自動停用，:DepsCheck 看詳情"):format(table.concat(bins, "、")),
    vim.log.levels.INFO,
    { title = "外部依賴" }
  )
end

if vim.v.vim_did_enter == 1 then
  vim.defer_fn(M.report, 500)
else
  vim.api.nvim_create_autocmd("User", {
    pattern = "VeryLazy",
    once = true,
    callback = function()
      vim.defer_fn(M.report, 500)
    end,
  })
end

---------------------------------------------------------------------------
-- :DepsCheck
---------------------------------------------------------------------------

local KNOWN = {
  { bin = "node", feat = "JS/TS/Web/Python LSP（ts_ls、tailwindcss、svelte、pyright、jsonls、yamlls）、jest/vitest 測試" },
  { bin = "go", feat = "gopls、go.nvim" },
  { bin = "elixir", feat = "elixir-tools、elixirls、neotest-elixir" },
  { bin = "python3", feat = "neotest-python" },
  { bin = "cargo", feat = "Rust 專案開發（rust-analyzer 由 mason 提供）" },
  { bin = "make", feat = "telescope-fzf-native 編譯" },
  { bin = "cc", feat = "treesitter parser 編譯（cc/gcc/clang 任一即可）" },
  { bin = "rg", feat = "Telescope live_grep" },
}

vim.api.nvim_create_user_command("DepsCheck", function()
  local lines = {}
  for _, d in ipairs(KNOWN) do
    local ok
    if d.bin == "cc" then
      ok = M.has_cc()
    else
      ok = M.has(d.bin)
    end
    lines[#lines + 1] = ("%s %-8s %s"):format(ok and "✓" or "✗", d.bin, d.feat)
  end
  if next(M.missing) then
    lines[#lines + 1] = ""
    lines[#lines + 1] = "本次啟動已停用："
    local bins = vim.tbl_keys(M.missing)
    table.sort(bins)
    for _, bin in ipairs(bins) do
      lines[#lines + 1] = ("  %s → %s"):format(bin, table.concat(M.missing[bin], "、"))
    end
  end
  vim.notify(table.concat(lines, "\n"), vim.log.levels.INFO, { title = "DepsCheck" })
end, { desc = "檢查外部依賴與被停用的功能" })

return M
