local M = {}

--- @class highliner.Pattern
--- @field language? string|string[] Limit the pattern to a specific language.
--- @field query? string Tree-sitter query.
--- @field groups? table<string, string> Highlight groups.

local function toggle()
    require("highliner.render").toggle()
end

local function reset_cache()
    require("highliner.bufstate").reset_cache()
    vim.cmd.redraw { bang = true }
end

function M.setup()
    vim.api.nvim_create_user_command("HighlinerToggle", toggle, {
        nargs = 0,
        desc = "Enable/disable line highlights",
    })

    vim.api.nvim_create_user_command("HighlinerResetCache", reset_cache, {
        nargs = 0,
        desc = "Reset the internal cache for Highliner",
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
