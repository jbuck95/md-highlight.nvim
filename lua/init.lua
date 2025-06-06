-- lua/md-highlight/init.lua
local M = {}

function M.setup(user_config)
  require("md-highlight.core").setup(user_config)
end

return M
