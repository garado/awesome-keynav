
-- █▄░█ ▄▀█ █░█ █ ▀█▀ █▀▀ █▀▄▀█ █▀ 
-- █░▀█ █▀█ ▀▄▀ █ ░█░ ██▄ █░▀░█ ▄█ 

-- Default class definitions for keyboard-navigable widgets

local beautiful     = require("beautiful")
local colorize      = require("helpers.ui").colorize_text
local remove_pango  = require("helpers.dash").remove_pango
local gtable = require("gears.table")

-- █▄▄ ▄▀█ █▀ █▀▀ 
-- █▄█ █▀█ ▄█ ██▄ 

local function base(class, args)
  local ret = args
  ret.selected    = false
  ret.is_area     = false
  ret.is_navitem  = true
  ret.visited     = false
  gtable.crush(ret, class, true)
  return ret
end

local Base = {}
setmetatable(Base, {
  __index = Base,
  __call = function (cls, ...)
    return base(cls, ...)
  end,
})

-- ▀█▀ █▀▀ ▀▄▀ ▀█▀ █▄▄ █▀█ ▀▄▀ 
-- ░█░ ██▄ █░█ ░█░ █▄█ █▄█ █░█ 

local Textbox = {}
setmetatable(Textbox, {
  __call = function (cls, ...)
    return base(cls, ...)
  end,
})

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

-- █▄▄ ▄▀█ █▀▀ █▄▀ █▀▀ █▀█ █▀█ █░█ █▄░█ █▀▄ 
-- █▄█ █▀█ █▄▄ █░█ █▄█ █▀▄ █▄█ █▄█ █░▀█ █▄▀ 

local Background = {}

function Background:select_on()
  self.selected = true
  self.widget.bg = self.bg_on or beautiful.dash_widget_sel
  if self.custom_on then self:custom_on() end
end

function Background:select_off()
  self.selected = false
  self.widget.bg = self.bg_off or beautiful.dash_widget_bg
  if self.custom_off then self:custom_off() end
end

setmetatable(Background, {
  __call  = function (cls, ...)
    return base(cls, ...)
  end,
})

-- █▀▀ █░█ █▀▀ █▀▀ █▄▀ █▄▄ █▀█ ▀▄▀ 
-- █▄▄ █▀█ ██▄ █▄▄ █░█ █▄█ █▄█ █░█ 

local Checkbox = {}
setmetatable(Checkbox, {
  __call  = function (class, ...)
    return base(class, ...)
  end,
})

function Checkbox:select_on()
  self.selected = true
  local box = self.widget.children[1]
  box.check_color = beautiful.hab_selected_bg
  box.bg = beautiful.hab_selected_bg
end

function Checkbox:select_off()
  self.selected = false
  local box = self.widget.children[1]
  box.bg = not box.checked and beautiful.hab_uncheck_bg
  box.check_color = beautiful.hab_check_bg
end

function Checkbox:release()
  self.widget:emit_signal("button::press")
end


-- █▀ █ █▀▄▀█ █▀█ █░░ █▀▀    █▄▄ █░█ ▀█▀ ▀█▀ █▀█ █▄░█ 
-- ▄█ █ █░▀░█ █▀▀ █▄▄ ██▄    █▄█ █▄█ ░█░ ░█░ █▄█ █░▀█ 

local SimpleButton = {}
setmetatable(SimpleButton, {
  __call = function (cls, ...)
    return base(cls, ...)
  end,
})

function SimpleButton:select_on()
  self.selected = true
  self.widget.bg = self.bg_off or beautiful.dash_widget_bg

  local textbox = self.widget:get_children_by_id("textbox")[1]
  local text = remove_pango(textbox.markup or "")
  local color = self.fg_on or beautiful.main_accent or "#bf616a"
  textbox:set_markup_silently(colorize(text, color))
  if self.custom_on then self:custom_on() end
end

function SimpleButton:select_off()
  self.selected = false
  self.widget.bg = self.bg_off or beautiful.dash_widget_bg

  local textbox = self.widget:get_children_by_id("textbox")[1]
  local text = remove_pango(textbox.markup or "")
  local color = self.fg_off or beautiful.fg or "#eceff4"
  textbox:set_markup_silently(colorize(text, color))

  if self.custom_off then self:custom_off() end
end

function SimpleButton:release()
  self.widget:nav_release()
end


-- █▀▀ █▄▄ █░█ ▀█▀ ▀█▀ █▀█ █▄░█ 
-- ██▄ █▄█ █▄█ ░█░ ░█░ █▄█ █░▀█ 

local Elevated = {}
setmetatable(Elevated, {
  __call = function (cls, ...)
    return base(cls, ...)
  end,
})

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

return {
  Base        = Base,
  Textbox     = Textbox,
  Background  = Background,
  Checkbox    = Checkbox,
  Elevated    = Elevated,
  SimpleButton = SimpleButton,
  ------
  base        = Base,
  textbox     = Textbox,
  background  = Background,
  checkbox    = Checkbox,
  elevated    = Elevated,
  simplebutton = SimpleButton,
}
