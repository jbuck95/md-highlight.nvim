-- lua/md-highlight/core.lua
local M = {}

-- Funktion zum Lesen der Pywal Farben
local function get_pywal_colors()
  local colors = {}
  local cache_file = os.getenv("HOME") .. "/.cache/wal/colors"
  
  local file = io.open(cache_file, "r")
  if file then
    local i = 0
    for line in file:lines() do
      colors[i] = line
      i = i + 1
      if i >= 16 then break end -- Nur die ersten 16 Farben lesen
    end
    file:close()
  end
  
  return colors
end

-- Default Konfiguration
local default_config = {
  highlight_group = "MdHighlight",
  pattern = "==[^=]+==",
  filetypes = { "markdown", "text", "org" },
  auto_render = true,
  keybinds = {
    toggle_highlight = "<leader>mh",
    clear_highlights = "<leader>mc",
  },
  colors = {
    use_pywal = true,
    fallback = {
      bg = "#ffff00",
      fg = "#000000",
    },
    pywal_color_index = {
      bg = 3,  -- Pywal color3 (meist gelb/orange)
      fg = 0,  -- Pywal color0 (meist dunkel)
    },
    custom = {
      bg = nil,  -- Wenn gesetzt, überschreibt pywal/fallback
      fg = nil,  -- Wenn gesetzt, überschreibt pywal/fallback
    }
  },
  style = {
    bold = true,
    italic = false,
    underline = false,
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
  local bg_color, fg_color
  
  -- Custom colors haben höchste Priorität
  if config.colors.custom.bg and config.colors.custom.fg then
    bg_color = config.colors.custom.bg
    fg_color = config.colors.custom.fg
  -- Pywal colors wenn aktiviert
  elseif config.colors.use_pywal then
    local pywal_colors = get_pywal_colors()
    if pywal_colors and #pywal_colors > 0 then
      bg_color = pywal_colors[config.colors.pywal_color_index.bg] or config.colors.fallback.bg
      fg_color = pywal_colors[config.colors.pywal_color_index.fg] or config.colors.fallback.fg
    else
      -- Fallback wenn pywal nicht verfügbar
      bg_color = config.colors.fallback.bg
      fg_color = config.colors.fallback.fg
    end
  else
    -- Fallback colors
    bg_color = config.colors.fallback.bg
    fg_color = config.colors.fallback.fg
  end
  
  -- Highlight group definieren
  local highlight_opts = {
    bg = bg_color,
    fg = fg_color,
    bold = config.style.bold,
    italic = config.style.italic,
    underline = config.style.underline,
  }
  
  vim.api.nvim_set_hl(0, config.highlight_group, highlight_opts)
  
  -- Debug info (optional)
  if vim.g.md_highlight_debug then
    print(string.format("MdHighlight colors: bg=%s, fg=%s", bg_color, fg_color))
  end
end

-- Auto-commands einrichten
local function setup_autocmds()
  vim.api.nvim_create_autocmd("FileType", {
    group = autocmd_group,
    pattern = config.filetypes,
    callback = function()
      local bufnr = vim.api.nvim_get_current_buf()
      
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
      
      vim.api.nvim_create_autocmd("TextChanged", {
        group = autocmd_group,
        buffer = bufnr,
        callback = on_text_changed,
      })
      
      vim.api.nvim_create_autocmd("BufEnter", {
        group = autocmd_group,
        buffer = bufnr,
        callback = function()
          local mode = vim.api.nvim_get_mode().mode
          is_insert_mode = mode == "i" or mode == "R"
          
          if not is_insert_mode and config.auto_render then
            vim.schedule(highlight_matches)
          end
        end,
      })
      
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
  
  vim.api.nvim_create_user_command("MdHighlightReloadColors", function()
    setup_highlight_group()
    if not is_insert_mode then
      highlight_matches()
    end
    print("MdHighlight colors reloaded")
  end, {
    desc = "Reload md-highlight colors (useful after pywal change)"
  })
  
  vim.api.nvim_create_user_command("MdHighlightShowColors", function()
    local pywal_colors = get_pywal_colors()
    if pywal_colors and #pywal_colors > 0 then
      print("Pywal colors:")
      for i, color in pairs(pywal_colors) do
        print(string.format("  color%d: %s", i, color))
      end
    else
      print("No pywal colors found")
    end
  end, {
    desc = "Show available pywal colors"
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
