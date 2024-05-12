local M = {}

local BufState = require("highliner.bufstate")
local Logger = require("highliner.logger")

local NAMESPACE = require("highliner").NAMESPACE

local function set_buffer_lines(buffer_lines, hl_name, node, topline, botline_guess)
    local row1, _, row2, col2 = node:range()

    local opts = {
        ephemeral = true,
        hl_group = hl_name,
        hl_eol = true,
        end_col = 0,
    }

    for row = math.max(row1, topline), math.min(row2, botline_guess) do
        if row == row2 and col2 == 0 then
            -- Don't add the last line if it ends at column 0.
            break
        end

        buffer_lines[row] = opts
    end
end

-- Implementation of the decoration provider events.

---@param config highliner.Config
local function dc_win(config, state, bufnr, topline, botline_guess)
    local bufstate = BufState.from_buffer(config, bufnr)

    if not bufstate then
        return false
    end

    local lang = bufstate.lang
    local tstree = bufstate.ts_parser:parse()[1]

    local buffer_lines = {}
    state.buffers[bufnr] = buffer_lines

    -- Apply highlights from tree-sitter queries.
    for _, query in pairs(lang.ts_queries) do
        for id, node, _ in query:iter_captures(tstree:root(), bufnr, topline, botline_guess) do
            local name = query.captures[id]
            set_buffer_lines(buffer_lines, name, node, topline, botline_guess)
        end
    end

    -- Reuse highlights from the default queries.
    if not vim.tbl_isempty(lang.hl_groups) then
        local hlq = bufstate.lang.ts_highlight_query
        for id, node, _ in hlq:iter_captures(tstree:root(), bufnr, topline, botline_guess) do
            local target_group = lang.hl_groups[id]
            if target_group then
                set_buffer_lines(buffer_lines, target_group, node, topline, botline_guess)
            end
        end
    end

    return true
end

local function dc_line(state, bufnr, row)
    local buffer = state.buffers[bufnr]
    local opts = buffer and buffer[row]
    if opts then
        opts.end_row = row + 1
        vim.api.nvim_buf_set_extmark(bufnr, NAMESPACE, row, 0, opts)
    end
end

---@param config highliner.Config
function M.setup(config)
    local state = {
        buffers = {},
    }

    vim.api.nvim_set_decoration_provider(NAMESPACE, {
        on_win = function(_, _, bufnr, topline, botline_guess)
            return Logger.try(function()
                return dc_win(config, state, bufnr, topline, botline_guess)
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
end

return M
