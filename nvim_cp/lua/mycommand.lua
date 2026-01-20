-- :Memoでメモファイルを開く
vim.api.nvim_create_user_command('Memo', function()
  vim.cmd('edit ~/Desktop/memo/memo.md')
end, {})

-- :Dmemoで日毎に別れたメモを開く
vim.api.nvim_create_user_command('Dmemo', function()
  local date = os.date('%Y-%m-%d')
  vim.cmd('edit ~/Desktop/memo/' .. date .. '.md')
end, {})

-- :PmemoでPythonファイルを開く
vim.api.nvim_create_user_command('Pmemo', function()
  vim.cmd('edit ~/Desktop/memo/test.py')
end, {})

-- :PyでPythonファイルを実行
vim.api.nvim_create_user_command('Py', function()
  vim.cmd('write')
  vim.cmd('!python3 %')
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
  vim.cmd('write')
  vim.cmd('!swift < test.txt')
end, {})

-- :Ap で Python プログラムを実行 (AtCoder用)
vim.api.nvim_create_user_command('Ap', function()
  vim.cmd('write')
  vim.cmd('!python3 < test.txt')
end, {})
