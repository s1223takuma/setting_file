local augroup = vim.api.nvim_create_augroup -- Create/get autocommand group
local autocmd = vim.api.nvim_create_autocmd -- Create autocommand

-- Remove whitespace on save
autocmd("BufWritePre", {
  pattern = "*",
  command = ":%s/\\s\\+$//e",
})

-- Don't auto commenting new lines
autocmd("BufEnter", {
  pattern = "*",
  command = "set fo-=c fo-=r fo-=o",
})

-- Restore cursor location when file is opened
autocmd({ "BufReadPost" }, {
  pattern = { "*" },
  callback = function()
    vim.api.nvim_exec('silent! normal! g`"zv', false)
  end,
})

-- ~/Desktop/memo/*.md を保存・終了時に自動 push
vim.api.nvim_create_autocmd("BufWinLeave", {
  pattern = "~/Desktop/memo/*",
  callback = function()
    local path = vim.fn.expand("%:p")
    local git_dir = "~/Desktop/memo"

    -- 変更があるかチェック
    local handle = io.popen("cd " .. git_dir .. " && git status --porcelain")
    local result = handle:read("*a")
    handle:close()

    if result == "" then
      print("No changes to commit for: " .. path)
      return
    end

    -- push するか確認
    local answer = vim.fn.input("変更がありました。githubにpushしますか？(y/N): ")
    if answer:lower() ~= "y" then
      print("pushしませんでした。")
      return
    end
    local msg = vim.fn.input("コミットメッセージを入力してください(空の場合Auto-update memoになります:")
    if msg:lower() == "" then
      msg = "Auto-update memo"
    end
    -- commit & push 実行
    os.execute("cd " .. git_dir .. " && git add " .. path)
    os.execute("cd " .. git_dir .. " && git commit -m '" .. msg .. "'")
    os.execute("cd " .. git_dir .. " && git push origin master")

    print("Pushed: " .. path)
  end,
})


-- ~/Desktop/daily_log/*.md(日記) を保存・終了時に自動 push
vim.api.nvim_create_autocmd("BufWinLeave", {
  pattern = "~/Desktop/daily_log/*",
  callback = function()
    local path = vim.fn.expand("%:p")
    local git_dir = "~/Desktop/daily_log"
    local date = os.date('%Y-%m-%d')
    local msg = date .. "の日記"
    -- 変更があるかチェック
    local handle = io.popen("cd " .. git_dir .. " && git status --porcelain")
    local result = handle:read("*a")
    handle:close()

    if result == "" then
      print("No changes to commit for: " .. path)
      return
    end

    -- push するか確認
    local answer = vim.fn.input("変更がありました。githubにpushしますか？(y/N): ")
    if answer:lower() ~= "y" then
      print("pushしませんでした。")
      return
    end

    -- commit & push 実行
    os.execute("cd " .. git_dir .. " && git add .")
    os.execute("cd " .. git_dir .. " && git commit -m '" .. msg .. "'")
    os.execute("cd " .. git_dir .. " && git push origin master")

    print("Pushed: " .. path)
  end,
})
