-- ~/.config/nvim/lua/md-highlight/init.lua

local M = {}

-- Default Konfiguration
local default_config = {
  highlight_group = "MdHighlight",
  pattern = "==[^=]+==",
  filetypes = { "markdown", "text", "org" },
  auto_render = true,
  keybinds = {
    toggle_highlight = "<leader>mh",
    clear_highlights = "<leader>mc",
  }
}

local config = {}
local namespace_id = vim.api.nvim_create_namespace("md_highlight")
local autocmd_group = vim.api.nvim_create_augroup("MdHighlight", { clear = true })
local is_insert_mode = false
local render_enabled = true

-- Funktion zum Highlighten der Matches
local function highlight_matches()
  if not render_enabled then return end
  
  local bufnr = vim.api.nvim_get_current_buf()
  local lines = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)
  
  -- Bestehende Highlights löschen
  vim.api.nvim_buf_clear_namespace(bufnr, namespace_id, 0, -1)
  
  for line_num, line in ipairs(lines) do
    local start_pos = 1
    while true do
      local match_start, match_end = string.find(line, config.pattern, start_pos)
      if not match_start then break end
      
      -- Highlight nur den Text zwischen den ==, nicht die == selbst
      local text_start = match_start + 1  -- Nach dem ersten ==
      local text_end = match_end - 2      -- Vor dem letzten ==
      
      vim.api.nvim_buf_add_highlight(
        bufnr,
        namespace_id,
        config.highlight_group,
        line_num - 1,  -- 0-basierte Zeilennummerierung
        text_start,
        text_end + 1
      )
      
      start_pos = match_end + 1
    end
  end
end

-- Funktion zum Löschen aller Highlights
local function clear_highlights()
  local bufnr = vim.api.nvim_get_current_buf()
  vim.api.nvim_buf_clear_namespace(bufnr, namespace_id, 0, -1)
end

-- Funktion für Insert Mode Enter
local function on_insert_enter()
  is_insert_mode = true
  if config.auto_render then
    clear_highlights()
  end
end

-- Funktion für Insert Mode Leave
local function on_insert_leave()
  is_insert_mode = false
  if config.auto_render then
    -- Kurze Verzögerung damit der Text erst gespeichert wird
    vim.schedule(function()
      highlight_matches()
    end)
  end
end

-- Funktion für Text Changes im Normal Mode
local function on_text_changed()
  if not is_insert_mode and config.auto_render then
    highlight_matches()
  end
end

-- Toggle Funktion für manuelles Ein/Ausschalten
local function toggle_rendering()
  render_enabled = not render_enabled
  
  if render_enabled then
    if not is_insert_mode then
      highlight_matches()
    end
    print("Md-highlight rendering enabled")
  else
    clear_highlights()
    print("Md-highlight rendering disabled")
  end
end

-- Setup der Highlight-Gruppe
local function setup_highlight_group()
  -- Definiere die Highlight-Gruppe falls sie nicht existiert
  vim.api.nvim_set_hl(0, config.highlight_group, {
    bg = "#ffff00",  -- Gelber Hintergrund
    fg = "#000000",  -- Schwarzer Text
    bold = true,
  })
end

-- Auto-commands einrichten
local function setup_autocmds()
  -- Nur für spezifische Filetypes aktivieren
  vim.api.nvim_create_autocmd("FileType", {
    group = autocmd_group,
    pattern = config.filetypes,
    callback = function()
      local bufnr = vim.api.nvim_get_current_buf()
      
      -- Insert Mode tracking
      vim.api.nvim_create_autocmd("InsertEnter", {
        group = autocmd_group,
        buffer = bufnr,
        callback = on_insert_enter,
      })
      
      vim.api.nvim_create_autocmd("InsertLeave", {
        group = autocmd_group,
        buffer = bufnr,
        callback = on_insert_leave,
      })
      
      -- Text changes im Normal Mode
      vim.api.nvim_create_autocmd("TextChanged", {
        group = autocmd_group,
        buffer = bufnr,
        callback = on_text_changed,
      })
      
      -- Buffer enter/focus
      vim.api.nvim_create_autocmd("BufEnter", {
        group = autocmd_group,
        buffer = bufnr,
        callback = function()
          -- Check current mode
          local mode = vim.api.nvim_get_mode().mode
          is_insert_mode = mode == "i" or mode == "R"
          
          if not is_insert_mode and config.auto_render then
            vim.schedule(highlight_matches)
          end
        end,
      })
      
      -- Initial setup
      vim.schedule(function()
        local mode = vim.api.nvim_get_mode().mode
        is_insert_mode = mode == "i" or mode == "R"
        
        if not is_insert_mode and config.auto_render then
          highlight_matches()
        end
      end)
    end,
  })
end

-- Keybinds einrichten
local function setup_keybinds()
  if config.keybinds.toggle_highlight then
    vim.keymap.set("n", config.keybinds.toggle_highlight, toggle_rendering, {
      desc = "Toggle md-highlight rendering"
    })
  end
  
  if config.keybinds.clear_highlights then
    vim.keymap.set("n", config.keybinds.clear_highlights, clear_highlights, {
      desc = "Clear md-highlight highlights"
    })
  end
end

-- Commands einrichten
local function setup_commands()
  vim.api.nvim_create_user_command("MdHighlightToggle", toggle_rendering, {
    desc = "Toggle md-highlight rendering"
  })
  
  vim.api.nvim_create_user_command("MdHighlightClear", clear_highlights, {
    desc = "Clear all md-highlight highlights"
  })
  
  vim.api.nvim_create_user_command("MdHighlightRefresh", function()
    if not is_insert_mode then
      highlight_matches()
    end
  end, {
    desc = "Refresh md-highlight highlights"
  })
end

-- Main setup function
function M.setup(user_config)
  config = vim.tbl_deep_extend("force", default_config, user_config or {})
  
  setup_highlight_group()
  setup_autocmds()
  setup_keybinds()
  setup_commands()
end

return M
