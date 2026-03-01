return {
  "yetone/avante.nvim",
  build = "make",
  event = "VeryLazy",
  version = false,
  opts = {
    provider = "claude",
    input = { provider = "snacks" },
    providers = {
      claude = {
        model = "claude-sonnet-4-6",
      },
    },
  },
  dependencies = {
    "nvim-lua/plenary.nvim",
    "MunifTanjim/nui.nvim",
  },
}
