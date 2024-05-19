local M = {}

---@class highliner.Language
---@field hl_groups table<any, string> Highlight group from capture id.
---@field ts_queries any[]
---@field ts_highlight_query any

local CACHE = {}

local GENERATED_GROUP_ID = 0

local GENERATED_GROUPS = {}

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

---@param config highliner.Config
---@param lang_name string
---@return highliner.Language|nil
function M.get(config, lang_name)
    local lang = CACHE[lang_name]
    if lang then
        return lang
    end

    local hl_groups = {}
    local ts_highlight_query = nil
    local ts_queries = {}

    for _, pattern in pairs(config.patterns) do
        if match_language(pattern.language, lang_name) then
            if pattern.query then
                table.insert(ts_queries, vim.treesitter.query.parse(lang_name, pattern.query))
            end

            if pattern.groups then
                if not ts_highlight_query then
                    ts_highlight_query = vim.treesitter.query.get(lang_name, "highlights")
                end

                for source_group, target in pairs(pattern.groups) do
                    local capture_id = nil
                    for id, capture_name in pairs(ts_highlight_query.captures) do
                        if capture_name == source_group then
                            capture_id = id
                            break
                        end
                    end

                    if capture_id then
                        if type(target) == "table" then
                            GENERATED_GROUP_ID = GENERATED_GROUP_ID + 1
                            local new_group = "__HighlinerGenerated_" .. GENERATED_GROUP_ID

                            vim.api.nvim_set_hl(0, new_group, target)

                            GENERATED_GROUPS[new_group] = target

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

    lang = {
        ts_queries = ts_queries,
        hl_groups = hl_groups,
        ts_highlight_query = ts_highlight_query,
    }

    CACHE[lang_name] = lang
    return lang
end

vim.api.nvim_create_autocmd("User", {
    pattern = "HighlinerResetCaches",
    callback = function()
        CACHE = {}
    end,
})

vim.api.nvim_create_autocmd("ColorScheme", {
    callback = function()
        -- Restore generated groups after changes in the colorscheme.
        for name, hl in pairs(GENERATED_GROUPS) do
            vim.api.nvim_set_hl(0, name, hl)
        end
    end,
})

return M
