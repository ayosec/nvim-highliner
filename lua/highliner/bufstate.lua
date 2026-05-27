local M = {}

local Langs = require("highliner.langs")

---@class highliner.BufState
---@field ts_parser vim.treesitter.LanguageTree
---@field lang highliner.Language

--- @type table<integer, highliner.Pattern[]>
local BuffersPatterns = {}

--- @type table<integer, highliner.BufState|false>
local BuffersState = {}

local AC_GROUP = vim.api.nvim_create_augroup("Highliner/BufState", {})

---@param bufnr integer
---@return highliner.BufState|false
function M.from_buffer(bufnr)
    local cached = BuffersState[bufnr]
    if cached ~= nil then
        return cached
    end

    local patterns = BuffersPatterns[bufnr]
    if patterns == nil then
        -- Skip buffers without patterns.
        return false
    end

    local ok, ts_parser = pcall(vim.treesitter.get_parser, bufnr)
    if not ok or not ts_parser then
        -- Skip buffers without a treesitter parser.
        BuffersState[bufnr] = false
        return false
    end

    local lang = Langs.get(patterns, ts_parser:lang())
    if not lang then
        BuffersState[bufnr] = false
        return false
    end

    ---@type highliner.BufState
    local bufstate = {
        ts_parser = ts_parser,
        lang = lang,
    }

    BuffersState[bufnr] = bufstate

    return bufstate
end

function M.reset_cache()
    BuffersState = {}
    vim.cmd.redraw { bang = true }
end

--- @param first integer
--- @param last integer
function M.clear_buffers(first, last)
    for buf = first, last do
        BuffersPatterns[buf] = nil
        BuffersState[buf] = nil
    end

    vim.cmd.redraw { bang = true }
end

--- @param buf integer
--- @param pattern highliner.Pattern
function M.add(buf, pattern)
    if buf == 0 then
        buf = vim.api.nvim_get_current_buf()
    end

    assert(vim.api.nvim_buf_is_valid(buf))

    local entry = BuffersPatterns[buf]
    if entry == nil then
        entry = {}
        BuffersPatterns[buf] = entry

        vim.api.nvim_create_autocmd("BufDelete", {
            group = AC_GROUP,
            buffer = buf,
            once = true,
            callback = function()
                BuffersPatterns[buf] = nil
                BuffersState[buf] = nil
            end,
        })
    end

    table.insert(entry, pattern)

    -- Reset cache, if any.
    BuffersState[buf] = nil

    require("highliner.render").setup()

    vim.cmd.redraw { bang = true }
end

return M
