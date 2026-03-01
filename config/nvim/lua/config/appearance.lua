-- カラースキームのカスタムハイライト設定
local function apply()
  -- NormalFloat / FloatBorder を iceberg に合わせる
  vim.api.nvim_set_hl(0, "NormalFloat",  { bg = "#161821", fg = "#c6c8d1" })
  vim.api.nvim_set_hl(0, "FloatBorder",  { bg = "#161821", fg = "#1e2132" })
  vim.api.nvim_set_hl(0, "WinSeparator", { fg = "#1e2132", bg = "#161821" })
  vim.api.nvim_set_hl(0, "FloatTitle",   { fg = "#3d425b", bg = "#161821" })
  -- snacks picker のプレビューだけ少し暗く
  vim.api.nvim_set_hl(0, "SnacksPickerPreview", { bg = "#0f1117", fg = "#c6c8d1" })
  vim.api.nvim_set_hl(0, "SnacksPickerPrompt", { fg = "#2a3158", bg = "#161821" })
  -- picker / explorer のファイル名・ディレクトリ名・ツリー枝を同じ色に
  vim.api.nvim_set_hl(0, "SnacksPickerDir",  { fg = "#6b7089" })
  vim.api.nvim_set_hl(0, "SnacksPickerFile", { fg = "#6b7089" })
  vim.api.nvim_set_hl(0, "SnacksPickerTree", { fg = "#1e2132" })
  vim.api.nvim_set_hl(0, "Directory",        { fg = "#6b7089" })
  -- DevIcon* を同じ明るさに統一
  for _, hl in ipairs(vim.fn.getcompletion("DevIcon", "highlight")) do
    vim.api.nvim_set_hl(0, hl, { fg = "#6b7089" })
  end
end

apply()

vim.api.nvim_create_autocmd("ColorScheme", {
  callback = apply,
})
