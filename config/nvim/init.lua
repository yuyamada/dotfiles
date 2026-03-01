-- Neovim 設定ファイル
-- Structured Setup

-- Homebrew curl を優先（avante の curl error 43 対策）
vim.env.PATH = "/opt/homebrew/opt/curl/bin:" .. vim.env.PATH

-- 設定の読み込み
require("config.general")
require("config.keymaps")
require("config.lazy")
require("config.appearance")
