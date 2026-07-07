local opts = { noremap = true, silent = true }
local term_opts = { silent = true }

--local keymap = vim.keymap
local keymap = vim.api.nvim_set_keymap
local builtin = require('telescope.builtin')

--telescope
vim.keymap.set('n', 'ff', builtin.find_files, { desc = 'Telescope find files' })
vim.keymap.set('n', 'F', builtin.live_grep, { desc = 'Telescope live grep' })
vim.keymap.set('n', 'fb', builtin.buffers, { desc = 'Telescope buffers' })
vim.keymap.set('n', 'fh', builtin.help_tags, { desc = 'Telescope help tags' })
--Remap space as leader key
keymap("", "<Space>", "<Nop>", opts)
vim.g.mapleader = " "
vim.g.maplocalleader = " "

-- Modes
--   normal_mode = 'n',
--   insert_mode = 'i',
--   visual_mode = 'v',
--   visual_block_mode = 'x',
--   term_mode = 't',
--   command_mode = 'c',

-- 縦方向矢印キーを5行飛ぶようにする
vim.keymap.set("n", "<Up>", "5k")
vim.keymap.set("n", "<Down>", "5j")

-- Brtter window navigation (smart-splits.nvimに移行、plugins.luaで定義)

-- Flutter tools
vim.keymap.set("n", "<leader>0", require("telescope").extensions.flutter.commands, { desc = "Open command Flutter" })
vim.keymap.set("n", "<leader>r", ":FlutterReload<CR>", { silent = true, desc = "Flutter Reload" })
vim.keymap.set("n", "<leader>R", ":FlutterRestart<CR>", { silent = true, desc = "Flutter Restart" })
-- New tab
keymap("n", "te", ":tabedit", opts)

-- 新しいタブを一番右に作る
keymap("n", "gn", ":tabnew<Return>", opts)

-- move tab
keymap("n", "<Tab>", ":bnext<CR>", { silent = true })
keymap("n", "<S-Tab>", ":bprev<CR>", { silent = true })
-- Vimのタブを閉じる
keymap("n", "<leader>bt", ":tabclose<CR>", opts)
-- バッファ（上に並ぶタブ)を閉じる
keymap("n", "<leader>bd", ":bdelete<CR>", opts)
-- Do not yank with x
keymap("n", "x", '"_x', opts)

-- Delete a word backwards
keymap("n", "dw", 'vb"_d', opts)

keymap("n", "<Space>l", "$", opts)

-- ;でコマンド入力( ;と:を入れ替)
keymap("n", ";", ":", opts)

-- 行末までのヤンクにする
keymap("n", "Y", "y$", opts)

-- <Space>q で強制終了
keymap("n", "<Space>q", ":<C-u>q!<Return>", opts)

-- ESC でハイライトやめる
keymap("n", "<Esc>", ":<C-u>set nohlsearch<Return>", opts)

-- Insert --
-- Press jk fast to exit insert mode
keymap("i", "jk", "<ESC>", opts)

-- コンマの後に自動的にスペースを挿入
keymap("i", ",", ",<Space>", opts)

-- Visual --
-- Stay in indent mode
keymap("v", "<", "<gv", opts)
keymap("v", ">", ">gv", opts)

-- ビジュアルモード時vで行末まで選択
keymap("v", "v", "$h", opts)

-- 0番レジスタを使いやすくした
keymap("v", "<C-p>", '"0p', opts)

-- Neotreeを使いやすくした
keymap("n", "<leader>e", ":Neotree toggle<Return>", opts)

-- Molten
local nn = require("notebook-navigator")

vim.keymap.set("n", "<leader>mi", ":MoltenInit python3<CR>")

-- セル実行(カーソル位置の # %% セルをまるごと実行)
vim.keymap.set("n", "<leader>r", function() nn.run_cell() end, { desc = "Run cell" })

-- セル実行して次のセルへ移動
vim.keymap.set("n", "<leader>x", function() nn.run_and_move() end, { desc = "Run cell and move" })

-- セル間移動
vim.keymap.set("n", "]h", function() nn.move_cell("d") end, { desc = "Next cell" })
vim.keymap.set("n", "[h", function() nn.move_cell("u") end, { desc = "Prev cell" })

-- 行・選択範囲はそのままMoltenでOK
vim.keymap.set("n", "<leader>rl", ":MoltenEvaluateLine<CR>")
vim.keymap.set("v", "<leader>rv", ":<C-u>MoltenEvaluateVisual<CR>")

-- 再実行
vim.keymap.set("n", "<leader>rr", ":MoltenReevaluateCell<CR>")

-- エラーの確認
vim.keymap.set("n", "<leader>er", vim.diagnostic.open_float, { desc = "Show diagnostic" })

-- GitHub系
vim.keymap.set("n", "<leader>gd", function()
  vim.cmd("Neogit")
  vim.cmd("vsplit")
  vim.cmd("Octo pr list")
end, { desc = "Git Dashboard (Neogit + Octo)" })
