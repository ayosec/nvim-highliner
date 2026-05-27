local M = {}

--- @class highliner.Pattern
--- @field language? string|string[] Limit the pattern to a specific language.
--- @field query? string Tree-sitter query.
--- @field groups? table<string, string> Highlight groups.

--- @param args vim.api.keyset.create_user_command.command_args
local function clear(args)
    require("highliner.bufstate").clear_buffers(args.line1, args.line2)
end

local function reset_cache()
    require("highliner.bufstate").reset_cache()
end

local function toggle()
    require("highliner.render").toggle()
end

function M.setup()
    vim.api.nvim_create_user_command("HighlinerClear", clear, {
        nargs = 0,
        range = true,
        addr = "buffers",
        desc = "Remove highlight patterns added to buffers",
    })

    vim.api.nvim_create_user_command("HighlinerResetCache", reset_cache, {
        nargs = 0,
        desc = "Reset the internal cache for Highliner",
    })

    vim.api.nvim_create_user_command("HighlinerToggle", toggle, {
        nargs = 0,
        desc = "Enable/disable line highlights",
    })

    -- Allow multiple calls to setup(), but as a no-op.
    M.setup = function() end
end

--- Add a highlight pattern to the given buffer. If `buf` is `0`, use
--- the current buffer.
---
--- @param buf integer
--- @param pattern highliner.Pattern
function M.add(buf, pattern)
    require("highliner.bufstate").add(buf, pattern)
end

return M
