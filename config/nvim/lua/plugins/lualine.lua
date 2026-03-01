return {
  "nvim-lualine/lualine.nvim",
  event = "VeryLazy",
  opts = {
    options = {
      theme = "iceberg_dark",
      globalstatus = true,
    },
    sections = {
      lualine_c = {
        { "filename", symbols = { unnamed = "", readonly = "" } },
      },
    },
  },
}
