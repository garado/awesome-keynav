
-- █▄░█ ▄▀█ █░█ █ ▀█▀ █▀▀ █▀▄▀█ 
-- █░▀█ █▀█ ▀▄▀ █ ░█░ ██▄ █░▀░█ 

-- Base class definition for making widgets navigable
-- with the keyboard

-- █▄▄ ▄▀█ █▀ █▀▀ 
-- █▄█ █▀█ ▄█ ██▄ 
-- Only responsible for defining basic vars
-- Functions must be overridden in derived classes
local Base = {}
--function Base:new(widget, custom_obj, name)
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

return Base
