local M = {}

local BufState = require("highliner.bufstate")
local Logger = require("highliner.logger")

local NAMESPACE = require("highliner").NAMESPACE

local function reset_state(state)
    state.buffers = {}
end

-- Implementation of the decoration provider events.

---@param config highliner.Config
local function dc_win(state, config)
    return function(_, _, bufnr, topline, botline_guess)
        return Logger.try(function()
            local bufstate = BufState.from_buffer(config, bufnr)

            if not bufstate then
                return false
            end

            local queries = bufstate.queries

            if vim.tbl_isempty(queries) then
                return false
            end

            local tstree = bufstate.ts_parser:parse()[1]

            local buffer_lines = {}
            state.buffers[bufnr] = buffer_lines

            for _, query in pairs(queries) do
                for id, node, _ in query:iter_captures(tstree:root(), bufnr, topline, botline_guess) do
                    local name = query.captures[id]
                    local row1, _, row2, col2 = node:range()

                    local opts = {
                        ephemeral = true,
                        hl_group = name,
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
            end

            return true
        end)
    end
end

local function dc_line(state)
    return function(_, _, bufnr, row)
        Logger.try(function()
            local buffer = state.buffers[bufnr]
            local opts = buffer and buffer[row]
            if opts then
                opts.end_row = row + 1
                vim.api.nvim_buf_set_extmark(bufnr, NAMESPACE, row, 0, opts)
            end
        end)
    end
end

local function dc_end(state)
    return function(_, _)
        -- Clear computed extmarks when the render is done.
        state.buffers = {}
    end
end

---@param config highliner.Config
function M.setup(config)
    local state = {}
    reset_state(state)

    vim.api.nvim_set_decoration_provider(NAMESPACE, {
        on_win = dc_win(state, config),
        on_line = dc_line(state),
        on_end = dc_end(state),
    })
end

return M
