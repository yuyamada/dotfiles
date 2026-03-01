return {
  "sindrets/diffview.nvim",
  cmd = { "DiffviewOpen", "DiffviewFileHistory" },
  config = function()
    local actions = require("diffview.actions")
    require("diffview").setup({
      keymaps = {
        file_panel = {
          { "n", "s", false },
          { "n", "a", actions.toggle_stage_entry },
        },
      },
    })
  end,
}
