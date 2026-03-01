vim.opt.clipboard = "unnamedplus"

-- :Q で全バッファを保存せずに終了
vim.api.nvim_create_user_command("Q", "qa!", {})

-- 行番号を表示
vim.opt.number = true
vim.opt.relativenumber = true
vim.opt.numberwidth = 1

-- サインカラムを常に表示（gitsigns などで幅が変化しないよう固定）
vim.opt.signcolumn = "yes"
