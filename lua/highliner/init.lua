local M = {}

M.NAMESPACE = vim.api.nvim_create_namespace("Highliner")

---@param config? highliner.Config
function M.setup(config)
    local default_config = require("highliner.config").default_config()
    config = vim.tbl_deep_extend("force", {}, default_config, config or {})

    require("highliner.render").setup(config)
end

return M
