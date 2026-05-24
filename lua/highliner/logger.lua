local M = {}

--- @type integer|nil
local current_buffer = nil

local MAX_LINES = 1024

local function errors_buffer()
    if current_buffer ~= nil and vim.api.nvim_buf_is_valid(current_buffer) then
        return current_buffer
    end

    current_buffer = vim.api.nvim_create_buf(true, true)
    vim.api.nvim_buf_set_name(current_buffer, "(Highliner Errors)")
    vim.api.nvim_buf_set_lines(current_buffer, 0, 1, false, { "HIGHLINER / ERRORS", "" })

    vim.schedule(function()
        local msg = string.format("Errors in Highliner. Open the log with :b%d", current_buffer)
        vim.notify_once(msg, vim.log.levels.ERROR)
    end)

    vim.api.nvim_create_autocmd("BufDelete", {
        buffer = current_buffer,
        once = true,
        callback = function()
            current_buffer = nil
        end,
    })

    return current_buffer
end

--- Executes a function, and record its error if it fails.
---
--- The traceback is written to a scratch buffer, so the UI render is not
--- interrupted with the error messages.
---
--- @generic T
--- @param f fun():T?
--- @return T?
function M.try(f)
    local ok, res = xpcall(f, debug.traceback)
    if not ok then
        local buf = errors_buffer()

        -- Append to the end.
        vim.api.nvim_buf_set_lines(buf, -1, -1, false, vim.split(res, "\n", { plain = true }))

        -- Delete lines at the beginning to limit the buffer size.
        local delete_lines = vim.api.nvim_buf_line_count(buf) - MAX_LINES
        if delete_lines > 0 then
            vim.api.nvim_buf_set_lines(buf, 0, delete_lines, false, {})
        end

        return nil
    end

    return res
end

return M
