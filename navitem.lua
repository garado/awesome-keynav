
-- █▄░█ ▄▀█ █░█ █ ▀█▀ █▀▀ █▀▄▀█ █▀ 
-- █░▀█ █▀█ ▀▄▀ █ ░█░ ██▄ █░▀░█ ▄█ 

-- Default class definitions for keyboard-navigable widgets

local gtable        = require("gears.table")
local beautiful     = require("beautiful")
local colorize      = require("helpers.ui").colorize_text
local remove_pango  = require("helpers.dash").remove_pango

-- █▄▄ ▄▀█ █▀ █▀▀ 
-- █▄█ █▀█ ▄█ ██▄ 
-- Only responsible for defining basic vars
-- Functions must be overridden in derived classes
-- TODO: remove custom_obj!
local Base = {}
function Base:new(widget, custom_obj, name)
  local o = {}
  o.widget      = widget
  o.selected    = false
  o.is_area     = false
  o.is_navitem  = true
  o.visited     = false
  o.custom_obj  = custom_obj or nil
  o.name        = name or "noname"
  setmetatable(o, self)
  self.__index = self
  return o
end

-- Override these 3 functions in your custom definition.
function Base:select_on()   end
function Base:select_off()  end
function Base:release()     end

function Base:select_toggle()
  if self.selected then
    self:select_off()
  else
    self:select_on()
  end
end

-- █▀▀ █░░ █▀▀ █░█ ▄▀█ ▀█▀ █▀▀ █▀▄ 
-- ██▄ █▄▄ ██▄ ▀▄▀ █▀█ ░█░ ██▄ █▄▀ 

local Elevated = Base:new(...)

function Elevated:select_on()
  self.selected = true
  self.widget:nav_hl_on()
end

function Elevated:select_off()
  self.selected = false
  self.widget:nav_hl_off()
end

function Elevated:release()
  self.widget:nav_release()
end


-- ▀█▀ █▀▀ ▀▄▀ ▀█▀ █▄▄ █▀█ ▀▄▀ 
-- ░█░ ██▄ █░█ ░█░ █▄█ █▄█ █░█ 

local Textbox = Base:new(...)

function Textbox:select_on()
  self.selected = true
  local text = remove_pango(self.widget.markup)
  local markup = colorize(text, self.fg_on or beautiful.main_accent)
  self.widget:set_markup_silently(markup)
  if self.custom_on then self:custom_on() end
end

function Textbox:select_off()
  self.selected = false
  local text = remove_pango(self.widget.markup)
  local markup = colorize(text, self.fg_off or beautiful.fg)
  self.widget:set_markup_silently(markup)
  if self.custom_off then self:custom_off() end
end

function Textbox:release() end


-- █▄▄ ▄▀█ █▀▀ █▄▀ █▀▀ █▀█ █▀█ █░█ █▄░█ █▀▄ 
-- █▄█ █▀█ █▄▄ █░█ █▄█ █▀▄ █▄█ █▄█ █░▀█ █▄▀ 

local Background = Base:new(...)

function Background:select_on()
  self.selected = true
  self.widget.bg = self.bg_on or beautiful.dash_widget_sel
end

function Background:select_off()
  self.selected = false
  self.widget.bg = self.bg_off or beautiful.dash_widget_bg
end

function Background:release() end

-- EVERYTHING BELOW HERE NEEDS TO BE REFACTORED/REMOVED
---------------------

-- █▀█ ▄▀█ █▀▀ ▀█▀ █ █▀█ █▄░█ 
-- ▀▀█ █▀█ █▄▄ ░█░ █ █▄█ █░▀█ 
local Qaction = Base:new(...)

function Qaction:select_on()
  self.selected = true
  self.widget:nav_hover()
  self.widget:nav_hl_on()
end

function Qaction:select_off()
  self.selected = false
  self.widget:nav_hl_off()
end

function Qaction:release()
  self.widget:nav_release()
end


-- █░█ ▄▀█ █▄▄ █ ▀█▀ █▀ 
-- █▀█ █▀█ █▄█ █ ░█░ ▄█ 
local Habit = Base:new(...)

function Habit:select_on()
  self.selected = true
  local box = self.widget.children[1]
  box.check_color = beautiful.hab_selected_bg
  box.bg = beautiful.hab_selected_bg
end

function Habit:select_off()
  self.selected = false
  local box = self.widget.children[1]
  box.bg = not box.checked and beautiful.hab_uncheck_bg
  box.check_color = beautiful.hab_check_bg
end

function Habit:release()
  self.widget:emit_signal("button::press")
end

-- █▀▄ ▄▀█ █▀ █░█    █░█░█ █ █▀▄ █▀▀ █▀▀ ▀█▀ 
-- █▄▀ █▀█ ▄█ █▀█    ▀▄▀▄▀ █ █▄▀ █▄█ ██▄ ░█░ 
local Dashwidget = Base:new(...)

function Dashwidget:select_on()
  self.selected = true
  self.widget.children[1].bg = beautiful.dash_widget_sel
end

function Dashwidget:select_off()
  self.selected = false
  self.widget.children[1].bg = beautiful.dash_widget_bg
end

-- █▀▄ ▄▀█ █▀ █░█    ▀█▀ ▄▀█ █▄▄ █▀ 
-- █▄▀ █▀█ ▄█ █▀█    ░█░ █▀█ █▄█ ▄█ 
local Dashtab = Base:new(...)

function Dashtab:select_on()
  self.selected = true
  self.widget:set_color(beautiful.main_accent)
  self.widget:nav_release()
  self.widget:nav_hl_on()
end

function Dashtab:select_off()
  self.selected = false
  self.widget:nav_hl_off()
  self.widget:set_color(beautiful.dash_tab_fg)
end

function Dashtab:release()
  self.widget:nav_release()
end

-- █▀█ █▀█ █▀█ ░░█ █▀▀ █▀▀ ▀█▀ █▀ 
-- █▀▀ █▀▄ █▄█ █▄█ ██▄ █▄▄ ░█░ ▄█ 
-- Project overview
local Project = Base:new(...)

function Project:select_on()
  self.selected = true
  self.widget.bg = beautiful.dash_widget_sel
end

function Project:select_off()
  self.selected = false
  self.widget.bg = beautiful.dash_widget_bg
end

function Project:release()
  self.custom_obj.current_project = self.name
  self.custom_obj:emit_signal("tasks::project_selected")
end

-- ▀█▀ ▄▀█ █▀ █▄▀ 
-- ░█░ █▀█ ▄█ █░█ 
local Task = Base:new(...)

function Task:select_on()
  local text = self.widget.children[1]
  self.selected = true
  text.font = beautiful.font_name .. "Bold 12"
end

function Task:select_off()
  self.selected = false
  local text = self.widget.children[1]
  text.font = beautiful.font_name .. "12"
end

function Task:release() end

-- ▀█▀ ▄▀█ █▀ █▄▀ █▄▄ █▀█ ▀▄▀ 
-- ░█░ █▀█ ▄█ █░█ █▄█ █▄█ █░█ 
local Taskbox = Base:new(...)

function Taskbox:select_on()
  self.selected = true
  self.widget.bg = beautiful.dash_widget_sel
end

function Taskbox:select_off()
  self.selected = false
  self.widget.bg = beautiful.dash_widget_bg
end

local OverviewBox = Base:new(...)

function OverviewBox:select_on()
  self.selected = true
  self.widget.bg = beautiful.dash_widget_sel
  self.custom_obj:emit_signal("tasks::overview_selected")
end

function OverviewBox:select_off()
  self.selected = false
  self.widget.bg = beautiful.dash_widget_bg
  self.custom_obj:emit_signal("tasks::overview_deselected")
end

-- ▀█▀ ▄▀█ █▀▀    ▀█▀ █▀▀ ▀▄▀ ▀█▀ █▄▄ █▀█ ▀▄▀ 
-- ░█░ █▀█ █▄█    ░█░ ██▄ █░█ ░█░ █▄█ █▄█ █░█ 
local Tasks_Textbox = Base:new(...)

function Tasks_Textbox:select_on()
  self.selected = true
  self.widget.font = beautiful.font_name .. "Bold 11"

  local text = remove_pango(self.widget.text)
  local markup = colorize(text, beautiful.main_accent)
  self.widget:set_markup_silently(markup)
end

function Tasks_Textbox:select_off()
  self.selected = false
  self.widget.font = beautiful.font_name .. "11"

  local text = remove_pango(self.widget.text)
  local markup = colorize(text, beautiful.fg)
  self.widget:set_markup_silently(markup)
end

function Tasks_Textbox:release() end

-- TODO: possibly Rename to Nav_everything
return {
  Base        = Base,
  Elevated    = Elevated,
  Textbox     = Textbox,
  Background  = Background,
  --- 
  Qaction = Qaction,
  Habit = Habit,
  Dashtab = Dashtab,
  Dashwidget = Dashwidget,
  Project = Project,
  Task = Task,
  -- Taskbox = Taskbox,
  -- Tasks_Textbox = Tasks_Textbox,
  OverviewBox = OverviewBox,
}
