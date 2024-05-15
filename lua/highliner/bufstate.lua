local M = {}

local Langs = require("highliner.langs")

---@class highliner.BufState
---@field ts_parser any
---@field lang highliner.Language

---@type table<integer, highliner.BufState|false>
local BUFFERS = {}

local AC_GROUP = vim.api.nvim_create_augroup("Highliner/BufState", {})

---@param config highliner.Config
---@param bufnr integer
---@return highliner.BufState|false
function M.from_buffer(config, bufnr)
    local cached = BUFFERS[bufnr]
    if cached ~= nil then
        return cached
    end

    -- Clear cached data when the buffer is deleted.
    vim.api.nvim_create_autocmd("BufUnload", {
        group = AC_GROUP,
        buffer = bufnr,
        once = true,
        callback = function()
            BUFFERS[bufnr] = nil
        end,
    })

    -- Skip buffers without a treesitter parser.
    local ok, ts_parser = pcall(vim.treesitter.get_parser, bufnr)
    if not ok then
        BUFFERS[bufnr] = false
        return false
    end

    local lang = Langs.get(config, ts_parser:lang())

    if not lang then
        BUFFERS[bufnr] = false
        return false
    end

    ---@type highliner.BufState
    local bufstate = {
        ts_parser = ts_parser,
        lang = lang,
    }

    BUFFERS[bufnr] = bufstate

    return bufstate
end

vim.api.nvim_create_autocmd("User", {
    pattern = "HighlinerResetCaches",
    callback = function()
        BUFFERS = {}
    end,
})

return M
