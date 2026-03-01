-- インデントスタイルを自動推測
return {
  "nmac427/guess-indent.nvim",
  config = function()
    require('guess-indent').setup({
      -- デフォルト設定（推測できない場合のフォールバック）
      auto_cmd = true,        -- BufReadPost で自動実行
      filetype_exclude = {    -- 除外するファイルタイプ
        "netrw",
        "tutor",
      },
      buftype_exclude = {     -- 除外するバッファタイプ
        "help",
        "nofile",
        "terminal",
        "prompt",
      },
    })

    -- フォールバック用のデフォルト設定（2スペース）
    vim.opt.tabstop = 2
    vim.opt.shiftwidth = 2
    vim.opt.softtabstop = 2
    vim.opt.expandtab = true
  end,
}