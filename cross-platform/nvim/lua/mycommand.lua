-- :Memoでメモファイルを開く
vim.api.nvim_create_user_command('Memo', function()
  vim.cmd('edit ~/Desktop/memo/memo.md')
end, {})

-- :Memoでメモファイルを開く
vim.api.nvim_create_user_command('Smemo', function()
  vim.cmd('edit ~/Desktop/memo/secretmemo.md')
end, {})

-- :Dmemoで日毎に別れたメモを開く
vim.api.nvim_create_user_command('Dmemo', function()
  local date = os.date('%Y-%m-%d')
  vim.cmd('edit ~/Desktop/memo/' .. date .. '.md')
end, {})

-- :Dlogで日記を開く(1日1回書けたらいいな)
vim.api.nvim_create_user_command('Dlog', function()
  local date = os.date('%Y-%m-%d')
  vim.cmd('edit ~/Desktop/daily_log/' .. date .. '.md')
end, {})

-- :PmemoでPythonファイルを開く
vim.api.nvim_create_user_command('P', function()
  vim.cmd('edit ~/Desktop/memo/test.py')
end, {})

-- :SmemoでSwiftファイルを開く
vim.api.nvim_create_user_command('S', function()
  vim.cmd('edit ~/Desktop/memo/test.swift')
end, {})

local python = vim.fn.has('win32') == 1 and 'python' or 'python3'

local function run_in_terminal(program)
  vim.cmd('write')
  local file = vim.api.nvim_buf_get_name(0)
  vim.cmd('new')
  -- シェル文字列に連結せず、空白や記号を含むファイル名もそのまま渡す。
  vim.fn.jobstart({ program, file }, { term = true })
end

local function run_with_input(program)
  vim.cmd('write')
  local file = vim.fn.shellescape(vim.api.nvim_buf_get_name(0), true)
  local input = vim.fn.shellescape(vim.fn.getcwd() .. '/test.txt', true)
  vim.cmd('!' .. program .. ' ' .. file .. ' < ' .. input)
end

-- :PyでPythonファイルを実行
vim.api.nvim_create_user_command('Py', function()
  run_in_terminal(python)
  vim.cmd('startinsert')
end, {})

-- :SwでSwiftファイルを実行
vim.api.nvim_create_user_command('Sw', function()
  run_in_terminal('swift')
end, {})
-- :W や :Wq で保存
vim.api.nvim_create_user_command('W', function()
  vim.cmd('write')
end, {})

vim.api.nvim_create_user_command('Wq', function()
  vim.cmd('wq')
end, {})

-- :As で Swift プログラムを実行 (AtCoder用)
vim.api.nvim_create_user_command('As', function()
  run_with_input('swift')
end, {})

-- :Ap で Python プログラムを実行 (AtCoder用)
vim.api.nvim_create_user_command('Ap', function()
  run_with_input(python)
end, {})
