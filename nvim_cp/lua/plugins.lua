-- =========================
-- OS判定（Windowsではimage.nvim/diagram.nvimを無効化）
-- =========================
local is_windows = vim.loop.os_uname().sysname:match("Windows") ~= nil

return {
  -- =========================
  -- Utility
  -- =========================
  {
    "nvim-lua/plenary.nvim",
  },

  -- =========================
  -- Colorscheme
  -- =========================
  {
    "EdenEast/nightfox.nvim",
    priority = 1000,
  },

  -- =========================
  -- UI
  -- =========================
  { "nvim-tree/nvim-web-devicons" },
  { "akinsho/bufferline.nvim" },

  -- =========================
  -- Telescope
  -- =========================
  {
    'nvim-telescope/telescope.nvim',
    version = '*',
    dependencies = {
      'nvim-lua/plenary.nvim',
      -- optional but recommended
      { 'nvim-telescope/telescope-fzf-native.nvim', build = 'make' },
    }
  },
  {
    "nvim-telescope/telescope-file-browser.nvim",
    dependencies = { "nvim-telescope/telescope.nvim" },
  },

  -- =========================
  -- Treesitter
  -- =========================
  {
    "nvim-treesitter/nvim-treesitter",
    build = ":TSUpdate",
  },
  { "windwp/nvim-ts-autotag" },

  -- =========================
  -- Auto pairs
  -- =========================
  {
    "windwp/nvim-autopairs",
    config = true,
  },

  -- =========================
  -- Completion (nvim-cmp)
  -- =========================
  { "hrsh7th/nvim-cmp" },
  { "hrsh7th/cmp-buffer" },
  { "hrsh7th/cmp-path" },
  { "hrsh7th/cmp-cmdline" },
  { "hrsh7th/cmp-nvim-lsp" },
  { "saadparwaiz1/cmp_luasnip" },
  { "L3MON4D3/LuaSnip" },

  -- =========================
  -- LSP core
  -- =========================
  {
    "neovim/nvim-lspconfig",
    config = function()
      vim.lsp.config("marksman", {
        cmd = { "marksman" },
        filetypes = { "markdown" },
      })
      vim.lsp.enable("marksman")

      vim.lsp.config("pyright", {
        settings = {
          python = {
            analysis = {
              diagnosticSeverityOverrides = {
                reportAttributeAccessIssue = "none",
              },
            },
          },
        },
      })
      vim.lsp.enable("pyright")

      -- JS/TS (GASもこれでOK)
      vim.lsp.enable("ts_ls")

      -- Dart
      -- vim.lsp.enable("dartls")
    end,
  },

  -- =========================
  -- Mason (installer)
  -- =========================
  {
    "williamboman/mason.nvim",
    config = true,
  },
  {
    "HiPhish/rainbow-delimiters.nvim",
  },


  -- =========================
  -- Markdown preview
  -- =========================
  {
    "ellisonleao/glow.nvim",
    config = true,
  },

  -- =========================
  -- Color highlight
  -- =========================
  {
    "NvChad/nvim-colorizer.lua",
    opts = {},
  },

  -- =========================
  -- File tree
  -- =========================
  {
    "nvim-neo-tree/neo-tree.nvim",
    branch = "v3.x",
    dependencies = {
      "nvim-lua/plenary.nvim",
      "nvim-tree/nvim-web-devicons",
      "MunifTanjim/nui.nvim",
    },
  },
  -- ========================
  -- format
  -- ========================
  {
    "stevearc/conform.nvim",
    config = function()
      require("conform").setup({
        format_on_save = {
          timeout_ms = 500,
          lsp_fallback = true,
        },
        formatters_by_ft = {
          lua = { "stylua" },
          python = { "ruff_format" },
          javascript = { "prettier" },
          typescript = { "prettier" },
          markdown = { "prettier" },
          swift = { "swiftformat" },
        },
      })
    end,
  },
  {
    'romgrk/barbar.nvim',
    dependencies = {
      'lewis6991/gitsigns.nvim',     -- OPTIONAL: for git status
      'nvim-tree/nvim-web-devicons', -- OPTIONAL: for file icons
    },
    init = function() vim.g.barbar_auto_setup = false end,
    opts = {
      -- lazy.nvim will automatically call setup for you. put your options here, anything missing will use the default:
      -- animation = true,
      -- insert_at_start = true,
      -- …etc.
    },
    version = '^1.0.0', -- optional: only update when a new 1.x version is released
  },
  {
    "nvim-lualine/lualine.nvim",
    dependencies = { "nvim-tree/nvim-web-devicons" },
    config = function()
      require("lualine").setup({
        options = {
          theme = "auto",
          section_separators = "",
          component_separators = "",
        },
        sections = {
          lualine_c = { "filename" },
          lualine_x = { "encoding", "fileformat", "filetype" },
        },
      })
    end,
  },
  {
    "Wansmer/treesj",
    keys = {
      { "J", "<cmd>TSJToggle<CR>", desc = "Toggle split/join" },
    },
    dependencies = { "nvim-treesitter/nvim-treesitter" },
    config = function()
      require("treesj").setup({
        use_default_keymaps = false,
        check_syntax_error = false,
      })
    end,
  },
  {
    "akinsho/toggleterm.nvim",
    version = "*",
    opts = {
      direction = "float",
      open_mapping = [[<c-\>]],
      start_in_insert = true,
      shade_terminals = true,

      float_opts = {
        border = "curved",
      },
    },
  },
  {
    "folke/which-key.nvim",
    event = "VeryLazy",
    config = function()
      local wk = require("which-key")

      wk.add({
        { "<leader>f", group = "検索" },
        { "<leader>g", group = "Git" },
        { "<leader>t", group = "ターミナル" },
        { "<leader>m", group = "Markdown" },
        { "<leader>h", group = "Git Hunk" },
        { "<leader>x", group = "診断" },
        { "<leader>s", group = "検索・置換" },
        { "<leader>o", group = "Octo (GitHub)" },
        { "<leader>d", group = "デバッグ (DAP)" },
      })
    end,
  },

  -- =========================
  -- 画像・図表表示 (Windowsでは無効化: MSVC/hererocks問題を回避)
  -- =========================
  {
    "3rd/image.nvim",
    cond = not is_windows,
    opts = {},
  },
  {
    "benlubas/molten-nvim",
    build = ":UpdateRemotePlugins",
    init = function()
      vim.g.molten_auto_open_output = false
      -- Windowsではimage.nvimを使わない（未ロードのため）
      if not is_windows then
        vim.g.molten_image_provider = "image.nvim"
      end
    end,
  },
  {
    "GCBallesteros/NotebookNavigator.nvim",
    dependencies = { "benlubas/molten-nvim" },
    config = function()
      require("notebook-navigator").setup({ repl_provider = "molten" })
    end,
  },
  {
    "mfussenegger/nvim-jdtls",
    ft = { "java" },
    config = function()
      local jdtls = require("jdtls")
      local home = os.getenv("HOME")
      local workspace = home .. "/.cache/jdtls/workspace"
      local root_dir = require("jdtls.setup").find_root({
        ".git",
        "mvnw",
        "gradlew",
      })
      if not root_dir then
        return
      end

      -- Masonのjdtlsパスを取得
      local mason_registry = require("mason-registry")
      local jdtls_path = mason_registry.get_package("jdtls"):get_install_path()
      local launcher_jar = jdtls_path .. "/plugins/org.eclipse.equinox.launcher_*.jar"

      jdtls.start_or_attach({
        cmd = {
          "java",
          "-Declipse.application=org.eclipse.jdt.ls.core.id1",
          "-Dosgi.bundles.defaultStartLevel=4",
          "-Declipse.product=org.eclipse.jdt.ls.core.product",
          "-Dlog.protocol=true",
          "-Dlog.level=OFF",
          "-noverify",
          "-Xmx1G",
          "-jar",
          launcher_jar,
          "-configuration",
          jdtls_path .. (is_windows and "/config_win" or "/config_mac"),
          "-data",
          workspace,
        },
        root_dir = root_dir,
        workspace_folders = { {
          uri = "file://" .. workspace,
          name = "workspace",
        } },
      })
    end,
  },
  {
    "sindrets/diffview.nvim",
    cmd = {
      "DiffviewOpen",
      "DiffviewClose",
      "DiffviewFileHistory",
    },
  },
  {
    "MeanderingProgrammer/render-markdown.nvim",
    dependencies = {
      "nvim-treesitter/nvim-treesitter",
    },
    opts = {
      render_modes = { "n", "v", "c", "t" },
      code = {
        disable = { "mermaid" },
      },
      image = {
        enabled = false,
      },
    },
  },
  {
    "shellRaining/hlchunk.nvim",
    event = { "BufReadPre", "BufNewFile" },
    opts = {
      chunk = {
        enable = true,
      },
      indent = {
        enable = true,
      },
      line_num = {
        enable = true,
      },
      blank = {
        enable = false,
      },
    },
  },
  {
    "stevearc/oil.nvim",
    lazy = false,

    dependencies = {
      "nvim-mini/mini.icons",
    },

    opts = {
      default_file_explorer = true,
      view_options = {
        show_hidden = true,
      },
    },

    keys = {
      { "-", "<cmd>Oil<CR>", desc = "Open parent directory" },
    },
  },
  {
    'Bekaboo/dropbar.nvim',
    -- optional, but required for fuzzy finder support
    dependencies = {
      'nvim-telescope/telescope-fzf-native.nvim',
      build = 'make'
    },
    config = function()
      local dropbar_api = require('dropbar.api')
      vim.keymap.set('n', '<Leader>;', dropbar_api.pick, { desc = 'Pick symbols in winbar' })
      vim.keymap.set('n', '[;', dropbar_api.goto_context_start, { desc = 'Go to start of current context' })
      vim.keymap.set('n', '];', dropbar_api.select_next_context, { desc = 'Select next context' })
    end
  },
  {
    'nvimdev/dashboard-nvim',
    event = 'VimEnter',
    config = function()
      require('dashboard').setup {
        -- config
      }
    end,
    dependencies = { { 'nvim-tree/nvim-web-devicons' } }
  },
  {
    "lewis6991/gitsigns.nvim",
    config = function()
      require("gitsigns").setup({
        signs = {
          add = { text = "│" },
          change = { text = "│" },
          delete = { text = "_" },
          topdelete = { text = "‾" },
          changedelete = { text = "~" },
        },
        on_attach = function(bufnr)
          local gs = package.loaded.gitsigns
          local function map(mode, l, r, opts)
            opts = opts or {}
            opts.buffer = bufnr
            vim.keymap.set(mode, l, r, opts)
          end
          map("n", "]c", gs.next_hunk, { desc = "Next hunk" })
          map("n", "[c", gs.prev_hunk, { desc = "Prev hunk" })
          map("n", "<leader>hs", gs.stage_hunk, { desc = "Stage hunk" })
          map("n", "<leader>hr", gs.reset_hunk, { desc = "Reset hunk" })
          map("n", "<leader>hp", gs.preview_hunk, { desc = "Preview hunk" })
        end,
      })
    end,
  },
  {
    "folke/trouble.nvim",
    dependencies = { "nvim-tree/nvim-web-devicons" },
    cmd = "Trouble",
    keys = {
      { "<leader>xx", "<cmd>Trouble diagnostics toggle<CR>",              desc = "Diagnostics" },
      { "<leader>xX", "<cmd>Trouble diagnostics toggle filter.buf=0<CR>", desc = "Buffer Diagnostics" },
    },
    opts = {},
  },
  {
    "akinsho/flutter-tools.nvim",
    dependencies = {
      "nvim-lua/plenary.nvim",
      "stevearc/dressing.nvim", -- 任意。UIが綺麗になる
    },
    config = function()
      require("flutter-tools").setup({})
    end,
  },
  {
    "kylechui/nvim-surround",
    version = "*",
    event = "VeryLazy",
    config = function()
      require("nvim-surround").setup({})
    end,
  },
  {
    "folke/flash.nvim",
    event = "VeryLazy",
    opts = {
      modes = {
        -- f/F/t/T のデフォルトフックを無効化（Fをlive_grepで使うため競合回避）
        char = {
          enabled = false,
        },
      },
    },
    keys = {
      { "s", mode = { "n", "x", "o" }, function() require("flash").jump() end,       desc = "Flash" },
      { "S", mode = { "n", "x", "o" }, function() require("flash").treesitter() end, desc = "Flash Treesitter" },
      { "r", mode = "o",               function() require("flash").remote() end,     desc = "Remote Flash" },
    },
  },
  {
    "folke/todo-comments.nvim",
    dependencies = { "nvim-lua/plenary.nvim" },
    event = { "BufReadPost", "BufNewFile" },
    opts = {
      keywords = {
        IDEA = {
          icon = "💡",
          color = "hint",
          alt = { "IDEAS" },
        },
        QUESTION = {
          icon = "?",
          color = "warning",
          alt = { "Q" },
        },
        DEBUG = {
          icon = "",
          color = "error",
        },
        PERF = {
          icon = "⚡",
          color = "info",
        },
        MEMO = {
          icon = "📝",
          color = "hint"
        },
      },
    },
    keys = {
      {
        "]t",
        function() require("todo-comments").jump_next() end,
        desc = "Next todo comment",
      },
      {
        "[t",
        function() require("todo-comments").jump_prev() end,
        desc = "Prev todo comment",
      },
      {
        "<leader>ft",
        "<cmd>TodoTelescope<CR>",
        desc = "Todo (Telescope)",
      },
    },
  },
  {
    "nvim-mini/mini.ai",
    version = "*",
    config = function()
      require("mini.ai").setup({})
    end,
  },
  {
    "numToStr/Comment.nvim",
    config = function()
      require("Comment").setup()
    end,
  },
  {
    "gbprod/substitute.nvim",
    config = function()
      require("substitute").setup()
    end,
  },
  {
    "yorickpeterse/nvim-pqf",
    opts = {},
  },
  {
    "chrisgrieser/nvim-spider",
    keys = {
      { "w", "<cmd>lua require('spider').motion('w')<CR>", mode = { "n", "o", "x" } },
      { "e", "<cmd>lua require('spider').motion('e')<CR>", mode = { "n", "o", "x" } },
      { "b", "<cmd>lua require('spider').motion('b')<CR>", mode = { "n", "o", "x" } },
    },
  },
  {
    "mrjones2014/smart-splits.nvim",
    config = function()
      local sm = require("smart-splits")
      -- リサイズ (Alt+hjkl)
      vim.keymap.set("n", "<A-h>", sm.resize_left)
      vim.keymap.set("n", "<A-j>", sm.resize_down)
      vim.keymap.set("n", "<A-k>", sm.resize_up)
      vim.keymap.set("n", "<A-l>", sm.resize_right)
      -- 移動 (tmuxペインとシームレスに連携)
      vim.keymap.set("n", "<C-h>", sm.move_cursor_left)
      vim.keymap.set("n", "<C-j>", sm.move_cursor_down)
      vim.keymap.set("n", "<C-k>", sm.move_cursor_up)
      vim.keymap.set("n", "<C-l>", sm.move_cursor_right)
    end,
  },
  {
    "MagicDuck/grug-far.nvim",
    cmd = "GrugFar",
    opts = {},
    keys = {
      { "<leader>sr", "<cmd>GrugFar<CR>", desc = "Search and Replace" },
    },
  },
  {
    "pwntester/octo.nvim",
    dependencies = {
      "nvim-lua/plenary.nvim",
      "nvim-telescope/telescope.nvim",
      "nvim-tree/nvim-web-devicons",
    },
    config = function()
      require("octo").setup()
    end,
    cmd = "Octo",
    keys = {
      { "<leader>op", "<cmd>Octo pr list<CR>", desc = "PR一覧" },
      { "<leader>oc", "<cmd>Octo pr create<CR>", desc = "PR作成" },
      { "<leader>oi", "<cmd>Octo issue list<CR>", desc = "Issue一覧" },
      { "<leader>oI", "<cmd>Octo issue create<CR>", desc = "Issue作成" },
      { "<leader>or", "<cmd>Octo review start<CR>", desc = "レビュー開始" },
      { "<leader>os", "<cmd>Octo search<CR>", desc = "検索" },
    },
  },
  {
    "3rd/diagram.nvim",
    cond = not is_windows,
    dependencies = {
      "3rd/image.nvim",
    },
    config = function()
      require("diagram").setup({
        integrations = {
          require("diagram.integrations.markdown"),
        },
        events = {
          render_buffer = { "InsertLeave", "BufWinEnter" }, -- インサートを抜けたら画像表示
          clear_buffer = { "InsertEnter", "BufLeave" },     -- インサートに入ったら画像を消す
        },
        renderer_options = {
          mermaid = {
            theme = "dark",
            scale = 2,
          },
        },
      })
    end,
  },

  -- =========================
  -- タスクランナー
  -- =========================
  {
    "is0n/jaq-nvim",
    cmd = { "Jaq" },
    keys = {
      { "<leader>j", "<cmd>Jaq<CR>", desc = "コードを即実行 (jaq)" },
    },
    config = function()
      require("jaq-nvim").setup({
        cmds = {
          internal = {
            lua = "luafile %",
            vim = "source %",
          },
          external = {
            python = "python3 %",
            javascript = "node %",
            sh = "sh %",
          },
        },
        behavior = {
          default = "float",
          startinsert = false,
          wincmd = false,
          autosave = false,
        },
        ui = {
          float = {
            border = "rounded", -- 他のfloat(診断等)と統一
            winhl = "Normal",
            borderhl = "FloatBorder",
            winblend = 0,
            height = 0.8,
            width = 0.8,
            x = 0.5,
            y = 0.5,
          },
          terminal = { position = "bot", size = 10, line_no = false },
          quickfix = { position = "bot", size = 10 },
        },
      })
    end,
  },

  -- =========================
  -- デバッガ (DAP)
  -- =========================
  {
    "mfussenegger/nvim-dap",
    dependencies = {
      "rcarriga/nvim-dap-ui",
      "nvim-neotest/nvim-nio", -- dap-uiの依存
      "mfussenegger/nvim-dap-python",
    },
    keys = {
      { "<leader>dc", function() require("dap").continue() end,          desc = "Continue" },
      { "<leader>do", function() require("dap").step_over() end,         desc = "Step Over" },
      { "<leader>di", function() require("dap").step_into() end,         desc = "Step Into" },
      { "<leader>dO", function() require("dap").step_out() end,          desc = "Step Out" },
      { "<leader>db", function() require("dap").toggle_breakpoint() end, desc = "Breakpoint Toggle" },
      {
        "<leader>dB",
        function() require("dap").set_breakpoint(vim.fn.input("Breakpoint condition: ")) end,
        desc = "Conditional Breakpoint",
      },
      {
        "<leader>dl",
        function() require("dap").set_breakpoint(nil, nil, vim.fn.input("Log point message: ")) end,
        desc = "Log Point",
      },
      { "<leader>du", function() require("dapui").toggle() end, desc = "DAP UI Toggle" },
      { "<leader>de", function() require("dapui").eval() end,   desc = "DAP Eval",     mode = { "n", "v" } },
    },
    config = function()
      require("mydap")
    end,
  },
  {
    "theHamsta/nvim-dap-virtual-text",
    dependencies = {
      "mfussenegger/nvim-dap",
      "nvim-treesitter/nvim-treesitter",
    },
    opts = {
      enabled = true,

      -- 変更された値だけ表示
      highlight_changed_variables = true,

      -- 新しい値を強調
      highlight_new_as_changed = false,

      -- 停止中だけ表示
      all_references = false,

      -- コメント風の表示
      commented = true,

      -- 実行位置だけ表示
      virt_text_pos = "eol",
    },
  },

  -- =========================
  -- LSP UI強化
  -- =========================
  {
    "nvimdev/lspsaga.nvim",
    event = "LspAttach",
    dependencies = {
      "nvim-tree/nvim-web-devicons",
      "nvim-treesitter/nvim-treesitter",
    },
    opts = {
      symbol_in_winbar = { enable = false },
      ui = { border = "rounded", title = false }, -- 他のfloatと統一
      lightbulb = { enable = false },
    },
    keys = {
      { "K",         "<cmd>Lspsaga hover_doc<CR>",             desc = "Hover Doc" },
      { "<leader>1", "<cmd>Lspsaga finder<CR>",                desc = "LSP Finder" },
      { "<leader>2", "<cmd>Lspsaga rename<CR>",                desc = "Rename" },
      { "<leader>3", "<cmd>Lspsaga code_action<CR>",           desc = "Code Action" },
      { "<leader>4", "<cmd>Lspsaga show_line_diagnostics<CR>", desc = "Line Diagnostics" },
      { "<leader>5", "<cmd>Lspsaga peek_definition<CR>",       desc = "Peek Definition" },
      { "<leader>[", "<cmd>Lspsaga diagnostic_jump_prev<CR>",  desc = "Prev Diagnostic" },
      { "<leader>]", "<cmd>Lspsaga diagnostic_jump_next<CR>",  desc = "Next Diagnostic" },
    },
  },
}
