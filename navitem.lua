
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
  self.widget.markup = colorize("Selected", beautiful.fg)
  if self.custom_on then self:custom_on() end
end

function textbox:select_off()
  self.selected = false
  self.widget.markup = colorize("Not selected", beautiful.fg)
  if self.custom_off then self:custom_off() end
end

function textbox:release()
end

return {
  base = base,
  textbox = textbox,
}
