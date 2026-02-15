-- ANSI エスケープシーケンスを色付きで表示（tmux キャプチャなど）
return {
  "0xferrous/ansi.nvim",
  lazy = true,
  ft = { "ansi", "log" },
  config = function()
    require("ansi").setup({
      -- 候補: "onedark" | "classic" | "modern" | "gruvbox" | "dracula" | "catppuccin" | "terminal"
      theme = "terminal",
      auto_enable = true,
      filetypes = { "ansi", "log" },
    })

    -- 色は fg のみ（背景色は使わない＝黒が黄緑になる不具合を避ける）
    local hl = require("ansi.highlights")
    local orig_get = hl.get_highlight_group
    local orig_create = hl.create_dynamic_highlight
    hl.get_highlight_group = function(attrs)
      local a = vim.tbl_extend("force", {}, attrs)
      a.bg = nil
      return orig_get(a)
    end
    hl.create_dynamic_highlight = function(attrs)
      local a = vim.tbl_extend("force", {}, attrs)
      a.bg = nil
      return orig_create(a)
    end

    -- ヤンク時は ANSI を除去してテキストのみレジスタに入れる
    local function strip_ansi(s)
      if type(s) ~= "string" then
        return s
      end
      -- CSI: ESC [ ... letter / OSC: ESC ] ... ESC \ / その他 ESC + 1文字
      return s
        :gsub("\27%[[%d;?]*%a", "")
        :gsub("\27%][^\27]*\27%\\", "")
        :gsub("\27[PX^_][^\27]*\27%\\", "")
        :gsub("\27.", "")
    end

    vim.api.nvim_create_autocmd("TextYankPost", {
      group = vim.api.nvim_create_augroup("ansi_plain_yank", { clear = true }),
      callback = function()
        if vim.bo.ft ~= "ansi" and vim.bo.ft ~= "log" then
          return
        end
        local regname = vim.v.event.regname
        local regtype = vim.v.event.regtype
        local contents = vim.v.event.regcontents
        if not contents or #contents == 0 then
          return
        end
        local plain = vim.tbl_map(strip_ansi, contents)
        local regs = { (regname == "" and '"') or regname }
        if regname == "" then
          if vim.o.clipboard:find("unnamedplus") then
            table.insert(regs, "+")
          end
          if vim.o.clipboard:find("unnamed") then
            table.insert(regs, "*")
          end
        end
        -- 他プラグインの後に上書きするため 1 tick 遅延
        vim.defer_fn(function()
          for _, r in ipairs(regs) do
            vim.fn.setreg(r, plain, regtype)
          end
        end, 0)
      end,
    })
  end,
}
