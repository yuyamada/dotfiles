-- snacks.nvim - 品質向上プラグイン集（picker と explorer を含む）
return {
  "folke/snacks.nvim",
  dependencies = {
    "nvim-treesitter/nvim-treesitter",
    {
      "nvim-tree/nvim-web-devicons",
      opts = { color_icons = false },
    },
  },
  opts = {
    indent = { enabled = true },
    picker = {
      prompt = "/ ",
      icons = {
        files = {
          dir      = "› ",
          dir_open = "⌄ ",
        },
      },
    },
  },
}
