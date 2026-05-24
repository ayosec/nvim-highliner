local M = {}

local BufState = require("highliner.bufstate")
local Logger = require("highliner.logger")

local NAMESPACE = vim.api.nvim_create_namespace("Highliner")

--- @param buffer_lines { [integer]: vim.api.keyset.set_extmark }
--- @param hl_name string
--- @param node TSNode
--- @param toprow integer
--- @param botrow integer
local function set_buffer_lines(buffer_lines, hl_name, node, toprow, botrow)
    local row1, _, row2, col2 = node:range()

    --- @type vim.api.keyset.set_extmark
    local opts = {
        ephemeral = true,
        hl_group = hl_name,
        hl_eol = true,
        end_col = 0,
        priority = 0,
    }

    for row = math.max(row1, toprow), math.min(row2, botrow) do
        if row == row2 and col2 == 0 then
            -- Don't add the last line if it ends at column 0.
            break
        end

        buffer_lines[row] = opts
    end
end

-- Implementation of the decoration provider events.

--- @param state highliner.render.DecorationState
--- @param bufnr integer
--- @param toprow integer
--- @param botrow integer
local function dc_win(state, bufnr, toprow, botrow)
    local bufstate = BufState.from_buffer(bufnr)

    if not bufstate then
        return false
    end

    local lang = bufstate.lang
    local tstree = bufstate.ts_parser:parse()[1]

    local buffer_lines = {}
    state.buffers[bufnr] = buffer_lines

    -- Apply highlights from tree-sitter queries.
    for _, query in pairs(lang.ts_queries) do
        for id, node, _ in query:iter_captures(tstree:root(), bufnr, toprow, botrow) do
            local name = query.captures[id]
            set_buffer_lines(buffer_lines, name, node, toprow, botrow)
        end
    end

    -- Reuse highlights from the default queries.
    local hlq = bufstate.lang.ts_highlight_query
    if hlq and not vim.tbl_isempty(lang.hl_groups) then
        for id, node, _ in hlq:iter_captures(tstree:root(), bufnr, toprow, botrow) do
            local target_group = lang.hl_groups[id]
            if target_group then
                set_buffer_lines(buffer_lines, target_group, node, toprow, botrow)
            end
        end
    end

    return true
end

--- @param state highliner.render.DecorationState
--- @param bufnr integer
--- @param row integer
local function dc_line(state, bufnr, row)
    local buffer = state.buffers[bufnr]
    local opts = buffer and buffer[row]
    if opts then
        opts.end_row = row + 1
        vim.api.nvim_buf_set_extmark(bufnr, NAMESPACE, row, 0, opts)
    end
end

function M.setup()
    --- @class (private) highliner.render.DecorationState
    local state = {
        --- @type { [integer]: { [integer]: vim.api.keyset.set_extmark } }
        buffers = {},
    }

    vim.api.nvim_set_decoration_provider(NAMESPACE, {
        on_win = function(_, _, bufnr, toprow, botrow)
            return Logger.try(function()
                return dc_win(state, bufnr, toprow, botrow)
            end)
        end,

        on_line = function(_, _, bufnr, row)
            Logger.try(function()
                dc_line(state, bufnr, row)
            end)
        end,

        on_end = function(_, _)
            -- Clear computed extmarks when the render is done.
            state.buffers = {}
        end,
    })

    -- Override setup(), so we can call it multiple times without
    -- extra state.
    M.setup = function() end
end

return M
