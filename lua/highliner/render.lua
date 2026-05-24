local M = {}

local BufState = require("highliner.bufstate")
local Logger = require("highliner.logger")

local NAMESPACE = vim.api.nvim_create_namespace("Highliner/Render")

--- @param bufnr integer
--- @param hl_name string
--- @param node TSNode
--- @param toprow integer
--- @param botrow integer
local function set_buffer_lines(bufnr, hl_name, node, toprow, botrow)
    local row1, _, row2, col2 = node:range()

    -- In some parsers (like Markdown), blocks ends in the column 0 of the
    -- next row. In those cases, the extmark ends one line above the end.
    local row2_offset = col2 == 0 and 0 or 1

    vim.api.nvim_buf_set_extmark(bufnr, NAMESPACE, math.max(row1, toprow), 0, {
        ephemeral = true,
        hl_group = hl_name,
        hl_eol = true,
        end_col = 0,
        end_row = math.min(row2 + row2_offset, botrow),
        priority = 0,
    })
end

-- Implementation of the decoration provider events.

--- @param bufnr integer
--- @param toprow integer
--- @param botrow integer
local function dc_win(bufnr, toprow, botrow)
    local bufstate = BufState.from_buffer(bufnr)

    if not bufstate then
        return false
    end

    local lang = bufstate.lang
    local tstree = bufstate.ts_parser:parse()[1]

    -- Apply highlights from tree-sitter queries.
    for _, query in pairs(lang.ts_queries) do
        for id, node, _ in query:iter_captures(tstree:root(), bufnr, toprow, botrow) do
            local name = query.captures[id]
            set_buffer_lines(bufnr, name, node, toprow, botrow)
        end
    end

    -- Reuse highlights from the default queries.
    local hlq = bufstate.lang.ts_highlight_query
    if hlq and not vim.tbl_isempty(lang.hl_groups) then
        for id, node, _ in hlq:iter_captures(tstree:root(), bufnr, toprow, botrow) do
            local target_group = lang.hl_groups[id]
            if target_group then
                set_buffer_lines(bufnr, target_group, node, toprow, botrow)
            end
        end
    end

    return true
end

function M.setup()
    vim.api.nvim_set_decoration_provider(NAMESPACE, {
        on_win = function(_, _, bufnr, toprow, botrow)
            Logger.try(function()
                dc_win(bufnr, toprow, botrow)
            end)
            return false
        end,
    })

    -- Override setup(), so we can call it multiple times without
    -- extra state.
    M.setup = function() end
end

return M
