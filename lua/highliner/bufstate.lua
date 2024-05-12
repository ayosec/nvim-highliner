local M = {}

---@class highliner.BufState
---@field ts_parser any
---@field queries any[]

---@type table<integer, highliner.BufState|false>
local Buffers = {}

local AC_GROUP = vim.api.nvim_create_augroup("Highliner/BufState", {})

---@param config highliner.Config
---@param bufnr integer
---@return highliner.BufState|false
function M.from_buffer(config, bufnr)
    local cached = Buffers[bufnr]
    if cached ~= nil then
        return cached
    end

    -- Clear cached data when the buffer is deleted.
    vim.api.nvim_create_autocmd("BufUnload", {
        group = AC_GROUP,
        buffer = bufnr,
        once = true,
        callback = function()
            Buffers[bufnr] = nil
        end,
    })

    -- Skip buffers without a treesitter parser.
    local ok, ts_parser = pcall(vim.treesitter.get_parser, bufnr)
    if not ok then
        Buffers[bufnr] = false
        return false
    end

    -- Collect queries for this buffer.
    local queries = {}

    local filetype = vim.bo[bufnr].filetype
    for _, pattern in pairs(config.patterns) do
        if pattern.filetype == nil or pattern.filetype == filetype then
            table.insert(queries, vim.treesitter.query.parse(filetype, pattern.query))
        end
    end

    ---@type highliner.BufState
    local bufstate = {
        ts_parser = ts_parser,
        queries = queries,
    }

    Buffers[bufnr] = bufstate

    return bufstate
end

return M
