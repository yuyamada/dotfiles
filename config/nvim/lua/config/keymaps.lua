-- キーマップ設定

-- leader キーの設定
vim.g.mapleader = " "
vim.g.maplocalleader = " "

-- jj で normal mode
vim.keymap.set("i", "jj", "<ESC>", { silent = true })

-- 行が折り返し表示されていた場合、行単位ではなく表示行単位でカーソルを移動する
vim.keymap.set("n", "j", "gj")
vim.keymap.set("n", "k", "gk")
vim.keymap.set("n", "<down>", "gj")
vim.keymap.set("n", "<up>", "gk")

-- バッファ移動
vim.keymap.set("", "<C-n>", ":bnext<CR>")
vim.keymap.set("", "<C-p>", ":bprev<CR>")
vim.keymap.set("", "]b", ":bnext<CR>")
vim.keymap.set("", "[b", ":bprev<CR>")

-- insert mode 中 Ctrl+hjkl で移動
vim.keymap.set("i", "<C-h>", "<Left>")
vim.keymap.set("i", "<C-k>", "<Up>")
vim.keymap.set("i", "<C-j>", "<Down>")
vim.keymap.set("i", "<C-l>", "<Right>")

-- 行頭・行末移動
vim.keymap.set("", "<C-a>", "^")
vim.keymap.set("", "<C-e>", "$<Right>")
vim.keymap.set("i", "<C-a>", "<C-o>^")
vim.keymap.set("i", "<C-e>", "<C-o>$")

-- return と backspace
vim.keymap.set("", "<C-d>", "i<BS>")
vim.keymap.set("i", "<C-d>", "<BS>")
vim.keymap.set("", "<C-m>", "i<CR>")
vim.keymap.set("i", "<C-m>", "<CR>")
vim.keymap.set("", "<BS>", "i<BS>")

-- タブ移動（s プレフィックス）
vim.keymap.set("n", "s", "<Nop>")
vim.keymap.set("n", "sj", "<C-w>j")
vim.keymap.set("n", "sk", "<C-w>k")
vim.keymap.set("n", "sl", "<C-w>l")
vim.keymap.set("n", "sh", "<C-w>h")
vim.keymap.set("n", "sJ", "<C-w>J")
vim.keymap.set("n", "sK", "<C-w>K")
vim.keymap.set("n", "sL", "<C-w>L")
vim.keymap.set("n", "sH", "<C-w>H")
vim.keymap.set("n", "sn", "gt")
vim.keymap.set("n", "sp", "gT")
vim.keymap.set("n", "sr", "<C-w>r")
vim.keymap.set("n", "s=", "<C-w>=")
vim.keymap.set("n", "sw", "<C-w>w")
vim.keymap.set("n", "so", "<C-w>_<C-w>|")
vim.keymap.set("n", "sO", "<C-w>=")
vim.keymap.set("n", "sN", ":<C-u>bn<CR>")
vim.keymap.set("n", "sP", ":<C-u>bp<CR>")
vim.keymap.set("n", "st", ":<C-u>tabnew<CR>")
vim.keymap.set("n", "ss", ":<C-u>sp<CR>")
vim.keymap.set("n", "sv", ":<C-u>vs<CR>")
vim.keymap.set("n", "sq", ":q<CR>")
vim.keymap.set("n", "sQ", ":<C-u>bd<CR>")

-- 文字列検索（ESC 2回でハイライトの切り替え）
vim.keymap.set("n", "<esc><esc>", ":<C-u>set nohlsearch!<CR>", { silent = true })

-- delete without cut
vim.keymap.set("n", "x", '"_x')
vim.keymap.set("n", "d", '"_d')

-- snacks.nvim picker
vim.keymap.set("n", "<leader><space>", function()
  Snacks.picker.smart()
end, { desc = "Smart Find Files" })
vim.keymap.set("n", "<leader>/", function()
  Snacks.picker.grep()
end, { desc = "Grep" })
vim.keymap.set("n", "<leader>e", function()
  Snacks.explorer()
end, { desc = "File Explorer" })
vim.keymap.set("n", "<leader>p", function()
  Snacks.picker.pickers()
end, { desc = "Pickers picker" })
