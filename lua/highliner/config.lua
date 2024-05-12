local M = {}

---@class highliner.Pattern
---@field language? string|string[] Limit the pattern to a specific language.
---@field query? string Tree-sitter query.
---@field groups? table<string, string> Highlight groups.

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
