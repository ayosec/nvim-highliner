local M = {}

M.NAMESPACE = vim.api.nvim_create_namespace("Highliner")

---@param config? highliner.Config
function M.setup(config)
    local default_config = require("highliner.config").default_config()
    config = vim.tbl_deep_extend("force", {}, default_config, config or {})

    require("highliner.render").setup(config)
end

local function reset_cache()
    vim.api.nvim_exec_autocmds("User", { pattern = "HighlinerResetCaches" })

    vim.schedule(function()
        vim.cmd.redraw { bang = true }
    end)
end

-- User command to reset the internal caches.
vim.api.nvim_create_user_command("HighlinerResetCaches", reset_cache, { nargs = 0 })

return M
