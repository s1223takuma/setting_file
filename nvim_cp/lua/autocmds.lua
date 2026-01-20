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
vim.api.nvim_create_autocmd({"BufWinLeave", "BufWinLeave"}, {
  pattern = "/Users/sekitakuma/Desktop/memo/*",
  callback = function()
    local path = vim.fn.expand("%:p")
    local git_dir = "/Users/sekitakuma/Desktop/memo"
    local msg = "Auto-update memo"

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
    os.execute("cd " .. git_dir .. " && git add " .. path)
    os.execute("cd " .. git_dir .. " && git commit -m '" .. msg .. "'")
    os.execute("cd " .. git_dir .. " && git push")

    print("Pushed: " .. path)
  end,
})
