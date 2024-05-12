local M = {}

---@class highliner.Pattern
---@field filetype? string Limit the pattern to a specific filetype.
---@field query string Tree-sitter query.

---@return highliner.Config
function M.default_config()
    ---@class highliner.Config
    local opts = {
        ---@type highliner.Pattern[]
        patterns = {},
    }

    return opts
end

return M
