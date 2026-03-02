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
    indent = { enabled = true, animate = { enabled = false } },
    dashboard = { enabled = false },
    picker = {
      prompt = "/ ",
      icons = {
        files = {
          dir      = "› ",
          dir_open = "⌄ ",
        },
      },
      sources = {
        explorer = {
          formatters = {
            file = {
              filename_only = true,
              hidden = { icon = "", hl = "SnacksPickerFile" },  -- 隠しファイルを通常ファイルと同じハイライトに
            },
          },
        },
      },
    },
    explorer = {
      replace_netrw = true,
      trash = true,
    },
  },
}
