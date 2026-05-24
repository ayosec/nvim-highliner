local M = {}

---@class highliner.Language
---@field ts_queries vim.treesitter.Query[]
---@field hl_groups table<integer, string> Highlight group from capture id.
---@field ts_highlight_query vim.treesitter.Query?

--- Compute a hash from the items of a table.
---
--- The implementation ignores the fact that `pairs` can return items in any
--- order, but for our use-case this is not important: most tables will have
--- only one element, and for tables with more than one, it is not an issue
--- to create multiple highlight groups with the same arguments.
---
--- @param tbl table
--- @return string
local function compute_hash(tbl)
    local plain = ""

    for k, v in pairs(tbl) do
        plain = plain .. k .. "\1" .. v .. "\2"
    end

    return string.sub(vim.fn.sha256(plain), 0, 12)
end

---@param lang_pattern string|string[]|nil
---@param lang_name string
---@return boolean
local function match_language(lang_pattern, lang_name)
    if lang_pattern == nil then
        return true
    end

    if type(lang_pattern) == "string" then
        return lang_name == lang_pattern
    end

    for _, ln in pairs(lang_pattern) do
        if ln == lang_name then
            return true
        end
    end

    return false
end

---@param patterns highliner.Pattern[]
---@param lang_name string
---@return highliner.Language|nil
function M.get(patterns, lang_name)
    local hl_groups = {}
    local ts_highlight_query = nil
    local ts_queries = {}

    for _, pattern in pairs(patterns) do
        if match_language(pattern.language, lang_name) then
            if pattern.query then
                table.insert(ts_queries, vim.treesitter.query.parse(lang_name, pattern.query))
            end

            if not ts_highlight_query then
                ts_highlight_query = vim.treesitter.query.get(lang_name, "highlights")
            end

            if pattern.groups and ts_highlight_query then
                for source_group, target in pairs(pattern.groups) do
                    local capture_id = nil --- @type integer?
                    for id, capture_name in pairs(ts_highlight_query.captures) do
                        if capture_name == source_group then
                            capture_id = id
                            break
                        end
                    end

                    if capture_id then
                        if type(target) == "table" then
                            local hash = compute_hash(target)
                            local new_group = "HighlinerGenerated_" .. hash

                            vim.api.nvim_set_hl(0, new_group, target)

                            target = new_group
                        end

                        hl_groups[capture_id] = target
                    end
                end
            end
        end
    end

    -- Don't create the instance if there are no patterns.
    if vim.tbl_isempty(ts_queries) and vim.tbl_isempty(hl_groups) then
        return nil
    end

    --- @type highliner.Language
    local lang = {
        ts_queries = ts_queries,
        hl_groups = hl_groups,
        ts_highlight_query = ts_highlight_query,
    }

    return lang
end

vim.api.nvim_create_autocmd("ColorScheme", {
    group = vim.api.nvim_create_augroup("highliner.langs", {}),
    callback = function()
        -- Reset cache, so the highlight groups are regenerated on next render.
        require("highliner.bufstate").reset_cache()
    end,
})

return M
