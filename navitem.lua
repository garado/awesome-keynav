
-- █▄░█ ▄▀█ █░█ █▀▀ █░░ █▀▀ █▀▄▀█ █▀▀ █▄░█ ▀█▀ █▀ 
-- █░▀█ █▀█ ▀▄▀ ██▄ █▄▄ ██▄ █░▀░█ ██▄ █░▀█ ░█░ ▄█ 

-- Default class definitions for keyboard-navigable widgets

local beautiful = require("beautiful")
local colorize  = require("utils.ui").colorize
local gtable    = require("gears.table")

-- █▄▄ ▄▀█ █▀ █▀▀ 
-- █▄█ █▀█ ▄█ ██▄ 

local function base(class, args)
  local ret     = args
  ret.selected  = false
  ret.type      = "navitem"

  function ret:select_on()  end
  function ret:select_off() end
  function ret:release()    end

  gtable.crush(ret, class, true)
  return ret
end

-- ▀█▀ █▀▀ ▀▄▀ ▀█▀ █▄▄ █▀█ ▀▄▀ 
-- ░█░ ██▄ █░█ ░█░ █▄█ █▄█ █░█ 

local textbox = {}
setmetatable(textbox, {
  __call  = function(cls, ...)
    return base(cls, ...)
  end,
})

function textbox:select_on()
  self.selected = true
  self.widget.markup = colorize(self.widget.text, beautiful.primary[400])
  if self.custom_on then self:custom_on() end
end

function textbox:select_off()
  self.selected = false
  self.widget.markup = colorize(self.widget.text, beautiful.fg)
  if self.custom_off then self:custom_off() end
end

function textbox:release()
  self.widget:emit_signal("button::press")
end

-- █▄▄ ▄▀█ █▀▀ █▄▀ █▀▀ █▀█ █▀█ █░█ █▄░█ █▀▄ 
-- █▄█ █▀█ █▄▄ █░█ █▄█ █▀▄ █▄█ █▄█ █░▀█ █▄▀ 

local background = {}
setmetatable(background, {
  __call  = function(cls, ...)
    return base(cls, ...)
  end,
})

function background:select_on()
  self.selected = true
  self.widget.bg = beautiful.neutral[800]
  if self.custom_on then self:custom_on() end
end

function background:select_off()
  self.selected = false
  self.widget.bg = beautiful.neutral[900]
  if self.custom_off then self:custom_off() end
end

function background:release()
end


-- █▄▄ █░█ ▀█▀ ▀█▀ █▀█ █▄░█ 
-- █▄█ █▄█ ░█░ ░█░ █▄█ █░▀█ 

local btn = {}
setmetatable(btn, {
  __call  = function(cls, ...)
    return base(cls, ...)
  end,
})

function btn:select_on()
  self.selected = true
  self.widget:emit_signal("mouse::enter")
  if self.custom_on then self:custom_on() end
end

function btn:select_off()
  self.selected = false
  self.widget:emit_signal("mouse::leave")
  if self.custom_off then self:custom_off() end
end

function btn:release()
  self.widget:emit_signal("button::press")
end

return {
  base = base,
  textbox = textbox,
  background = background,
  btn = btn,
}
