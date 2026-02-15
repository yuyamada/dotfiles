-- iceberg カラースキーム
return {
  "cocopon/iceberg.vim",
  lazy = false,
  priority = 1000,
  config = function()
    vim.cmd.colorscheme("iceberg")
    -- ansi.nvim の theme="terminal" が参照する Terminal0-15 を Iceberg の色で定義
    -- （iceberg.vim は g:terminal_color_* のみ設定し、ハイライトは別なので明示する）
    local iceberg_terminal = {
      "#1e2132", "#e27878", "#b4be82", "#e2a478", "#84a0c6", "#a093c7", "#89b8c2", "#c6c8d1",
      "#6b7089", "#e98989", "#c0ca8e", "#e9b189", "#91acd1", "#ada0d3", "#95c4ce", "#d2d4de",
    }
    for i, hex in ipairs(iceberg_terminal) do
      vim.api.nvim_set_hl(0, ("Terminal%d"):format(i - 1), { fg = hex })
    end
  end,
}
