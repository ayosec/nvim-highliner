local M = {}

local Output = require("string.buffer").new()

local MAX_BUFFER_SIZE = 4 * 1024

local NotifySent = false

--- Executes a function, and record its error if it fails.
---
---@generic T
---@param f fun():T?
---@return T?
function M.try(f)
    local ok, res = xpcall(f, debug.traceback)
    if not ok then
        if #Output < MAX_BUFFER_SIZE then
            Output:put(res, "\n\n")
        end

        if not NotifySent then
            NotifySent = true
            vim.schedule(function()
                vim.notify("Errors in Highliner. Use :HighlinerErrors to print them.", vim.log.levels.ERROR)
                vim.api.nvim_create_user_command("HighlinerErrors", M.print, {})
            end)
        end

        return nil
    end

    return res
end

--- Print the recorded errors, and reset the buffer
function M.print()
    local msg = Output:tostring():gsub("\t", "    ")
    Output:reset()
    vim.api.nvim_err_writeln(msg)
end

return M
