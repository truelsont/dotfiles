-- ============================================================
-- init.lua — Neovim config (Linux & macOS)
-- Plugin manager: lazy.nvim (auto-installs on first run)
-- ============================================================

-- ── Options ──────────────────────────────────────────────────
vim.opt.number         = true
vim.opt.relativenumber = true
vim.opt.tabstop        = 4
vim.opt.shiftwidth     = 4
vim.opt.expandtab      = true
vim.opt.smartindent    = true
vim.opt.wrap           = false
vim.opt.ignorecase     = true
vim.opt.smartcase      = true
vim.opt.hlsearch       = false
vim.opt.incsearch      = true
vim.opt.termguicolors  = true
vim.opt.scrolloff      = 8
vim.opt.signcolumn     = "yes"
vim.opt.updatetime     = 50
vim.opt.splitbelow     = true
vim.opt.splitright     = true
vim.opt.clipboard      = "unnamedplus"

vim.g.mapleader        = " "
vim.g.maplocalleader   = " "

-- ── Keymaps ──────────────────────────────────────────────────
local map = vim.keymap.set

-- Navigation
map("n", "<C-h>", "<C-w>h")
map("n", "<C-j>", "<C-w>j")
map("n", "<C-k>", "<C-w>k")
map("n", "<C-l>", "<C-w>l")

-- Move lines in visual mode
map("v", "J", ":m '>+1<CR>gv=gv")
map("v", "K", ":m '<-2<CR>gv=gv")

-- Keep cursor centered while scrolling
map("n", "<C-d>", "<C-d>zz")
map("n", "<C-u>", "<C-u>zz")
map("n", "n", "nzzzv")
map("n", "N", "Nzzzv")

-- Better paste (don't overwrite register)
map("x", "<leader>p", '"_dP')

-- Quickfix navigation
map("n", "<leader>j", "<cmd>cnext<CR>zz")
map("n", "<leader>k", "<cmd>cprev<CR>zz")

-- File explorer
map("n", "<leader>e", "<cmd>Ex<CR>")

-- ── Bootstrap lazy.nvim ──────────────────────────────────────
local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not vim.loop.fs_stat(lazypath) then
    vim.fn.system({
        "git", "clone", "--filter=blob:none",
        "https://github.com/folke/lazy.nvim.git",
        "--branch=stable", lazypath,
    })
end
vim.opt.rtp:prepend(lazypath)

-- ── Plugins ──────────────────────────────────────────────────
require("lazy").setup({

    -- Colorscheme
    {
        "catppuccin/nvim",
        name = "catppuccin",
        priority = 1000,
        config = function()
            require("catppuccin").setup({ flavour = "mocha" })
            vim.cmd.colorscheme("catppuccin")
        end,
    },

    -- Fuzzy finder
    {
        "nvim-telescope/telescope.nvim",
        dependencies = { "nvim-lua/plenary.nvim" },
        config = function()
            local builtin = require("telescope.builtin")
            map("n", "<leader>ff", builtin.find_files)
            map("n", "<leader>fg", builtin.live_grep)
            map("n", "<leader>fb", builtin.buffers)
            map("n", "<leader>fh", builtin.help_tags)
        end,
    },

    -- File tree
    {
        "nvim-tree/nvim-tree.lua",
        dependencies = { "nvim-tree/nvim-web-devicons" },
        config = function()
            require("nvim-tree").setup()
            map("n", "<leader>t", "<cmd>NvimTreeToggle<CR>")
        end,
    },

    -- Treesitter
    {
        "nvim-treesitter/nvim-treesitter",
        build = ":TSUpdate",
        config = function()
            require("nvim-treesitter.configs").setup({
                ensure_installed = {
                    "lua", "python", "c", "cpp", "rust", "go",
                    "typescript", "javascript", "json", "yaml",
                    "toml", "markdown", "bash", "dockerfile",
                },
                highlight = { enable = true },
                indent   = { enable = true },
            })
        end,
    },

    -- LSP
    {
        "neovim/nvim-lspconfig",
        dependencies = {
            "williamboman/mason.nvim",
            "williamboman/mason-lspconfig.nvim",
        },
        config = function()
            require("mason").setup()
            require("mason-lspconfig").setup({
                ensure_installed = { "lua_ls", "pyright", "clangd", "ts_ls" },
                automatic_installation = true,
            })

            local lspconfig = require("lspconfig")
            local on_attach = function(_, bufnr)
                local opts = { buffer = bufnr }
                map("n", "gd",  vim.lsp.buf.definition, opts)
                map("n", "K",   vim.lsp.buf.hover, opts)
                map("n", "<leader>rn", vim.lsp.buf.rename, opts)
                map("n", "<leader>ca", vim.lsp.buf.code_action, opts)
                map("n", "gr",  vim.lsp.buf.references, opts)
                map("n", "<leader>f", function()
                    vim.lsp.buf.format({ async = true })
                end, opts)
            end

            lspconfig.pyright.setup({ on_attach = on_attach })
            lspconfig.clangd.setup({ on_attach = on_attach })
            lspconfig.ts_ls.setup({ on_attach = on_attach })
            lspconfig.lua_ls.setup({
                on_attach = on_attach,
                settings = { Lua = { diagnostics = { globals = { "vim" } } } },
            })
        end,
    },

    -- Autocompletion
    {
        "hrsh7th/nvim-cmp",
        dependencies = {
            "hrsh7th/cmp-nvim-lsp",
            "hrsh7th/cmp-buffer",
            "hrsh7th/cmp-path",
            "L3MON4D3/LuaSnip",
            "saadparwaiz1/cmp_luasnip",
        },
        config = function()
            local cmp    = require("cmp")
            local luasnip = require("luasnip")
            cmp.setup({
                snippet = {
                    expand = function(args) luasnip.lsp_expand(args.body) end,
                },
                mapping = cmp.mapping.preset.insert({
                    ["<C-Space>"] = cmp.mapping.complete(),
                    ["<CR>"]      = cmp.mapping.confirm({ select = true }),
                    ["<Tab>"]     = cmp.mapping(function(fallback)
                        if cmp.visible() then cmp.select_next_item()
                        elseif luasnip.expand_or_jumpable() then luasnip.expand_or_jump()
                        else fallback() end
                    end, { "i", "s" }),
                }),
                sources = cmp.config.sources({
                    { name = "nvim_lsp" },
                    { name = "luasnip" },
                    { name = "buffer" },
                    { name = "path" },
                }),
            })
        end,
    },

    -- Status line
    {
        "nvim-lualine/lualine.nvim",
        dependencies = { "nvim-tree/nvim-web-devicons" },
        config = function()
            require("lualine").setup({ options = { theme = "catppuccin" } })
        end,
    },

    -- Git signs
    {
        "lewis6991/gitsigns.nvim",
        config = function()
            require("gitsigns").setup()
            map("n", "<leader>gp", "<cmd>Gitsigns preview_hunk<CR>")
            map("n", "<leader>gb", "<cmd>Gitsigns blame_line<CR>")
        end,
    },

    -- Auto pairs
    { "windwp/nvim-autopairs", event = "InsertEnter", config = true },

    -- Comment
    { "numToStr/Comment.nvim", config = true },

    -- Which-key (shows keybindings)
    { "folke/which-key.nvim",  config = true },
})
