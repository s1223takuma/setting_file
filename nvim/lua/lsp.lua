vim.lsp.enable("lua_ls")
vim.lsp.enable("pyright")
vim.lsp.enable("sourcekit")
vim.lsp.enable("html")
vim.lsp.enable("cssls")
vim.lsp.enable("emmet_ls")
vim.lsp.enable("sqls")
vim.diagnostic.config({
  virtual_text = true,
  signs = true,
  underline = true,
  float = { border = "rounded" },
})
vim.lsp.config("emmet_ls", {
  cmd = { "emmet-ls", "--stdio" },
  filetypes = {
    "html",
    "css",
    "javascriptreact",
    "typescriptreact",
    "vue",
  },
})
