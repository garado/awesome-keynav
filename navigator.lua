
-- █▄░█ ▄▀█ █░█ █ █▀▀ ▄▀█ ▀█▀ █▀█ █▀█ 
-- █░▀█ █▀█ ▀▄▀ █ █▄█ █▀█ ░█░ █▄█ █▀▄ 

local awful   = require("awful")
local gobject = require("gears.object")
local path    = (...):match("(.-)[^%.]+$")
local math    = math

-- For printing stacktrace
local debug_mode = true
local spaces = ""
local function add_space()  spaces = spaces .. "  " end
local function sub_space()  spaces = string.gsub(spaces, "^  ", "")   end
local function dbprint(msg) if debug_mode then print(spaces..msg) end end

local LEFT  = -1
local NONE  = 0
local RIGHT = 1

local pdir = {
  [0]  = "NONE",
  [1]  = "RIGHT",
  [-1] = "LEFT",
}

---

local navigator = {}
navigator.__index = navigator

setmetatable(navigator, {
  __call = function(class, ...)
    return class:new(...)
  end
})

function navigator:new(args)
  args = args or {}
  self = setmetatable(gobject{}, navigator)

  -- Set up root area
  self.root  = require(path .. "area")({
    name = "root",
    nav  = self,
  })

  return self, self.root
end


-- ▄▀█ █▀▀ █▀▀ █▀▀ █▀ █▀ 
-- █▀█ █▄▄ █▄▄ ██▄ ▄█ ▄█ 

-- Syntax gets a little verbose so here's some helper functions

function navigator:parent()
  return self.focused_area.parent
end

function navigator:farea()
  return self.focused_area
end

function navigator:fitem()
  return self:farea().active_element
end


-- █▄░█ ▄▀█ █░█ █ █▀▀ ▄▀█ ▀█▀ █▀▀ 
-- █░▀█ █▀█ ▀▄▀ █ █▄█ █▀█ ░█░ ██▄ 

--- @method iter_between_areas
-- @brief Move to the current focused area's neighbors.
function navigator:iter_between_areas(dir)
  dbprint('iter_between_area('..pdir[dir]..')')
  add_space()

  if not self:farea() or not self:fitem() then
    dbprint('no focused area or no focused item; returning')
    return
  end

  -- If the current focused item is an area
  if self:fitem().type == "area" then
    self.focused_area = self:fitem()
    self:iter_within_area(NONE)
    return
  end

  if dir == LEFT then
    self.focused_area = self.focused_area.prev
  elseif dir == RIGHT then
    self.focused_area = self.focused_area.next
  end
end

--- @method iter_within_area
-- @brief Iterate within the current focused area's items.
function navigator:iter_within_area(dir)
  dbprint('iter_within_area('..pdir[dir]..')')

  if not self:farea() or not self:fitem() then
    dbprint('no focused area or no focused item; returning')
    return
  end

  -- If current focused item is an area, iterate
  -- within that area
  if self:fitem().type == "area" then
    dbprint('focused item is an area - traversing within')
    add_space()
    self.focused_area = self:fitem()
    return self:iter_within_area(NONE)

  -- If current focused item is a navitem, move to the
  -- next one like normal
  elseif self:fitem().type == "navitem" then
    dbprint('focused item is a navitem - iterating like normal')
    self.focused_area:iter(dir)
  end
end

--- @method jump_to_end
-- @brief Jump to end of area
function navigator:jump_to_end(dir)
  dbprint('jump_to_end('..pdir[dir]..')')

  if dir == LEFT then
    self:farea():set_active_element(1)
  elseif dir == RIGHT then
    local num_items = #self:farea().items
    self:farea():set_active_element(num_items)
  end
end

--- @method jump_to_middle
-- @brief Jump to middle
function navigator:jump_to_middle()
  local mid = math.floor((#self:farea().items / 2) + 0.5)
  self:farea():set_active_element(mid)
end

-- █▄▀ █▀▀ █▄█ █▀ 
-- █░█ ██▄ ░█░ ▄█ 

--- @method check_keybinds
-- @brief Checks if a key is associated with any keybinds, then
-- execute that keybind.
function navigator:check_keybinds(key, area)
  dbprint('check_keybinds('..key..')')
  add_space()
  if not area then area = self:farea() end

  -- Start from the lowest level and work your way up
  if area.keys[key] then
    dbprint('keybind found')
    area.keys[key]()
  else
    if area.parent then
      area = area.parent
      dbprint('no keybind found - recursing up')
      add_space()
      self:check_keybinds(key, area)
    end
  end
end

--- @method handle_key
-- @brief Execute functions for direction keys
-- @param type  A navigation type:
--              horizontal, vertical, jump, release, ends
-- @param dir   LEFT, RIGHT, or NONE
function navigator:handle_key(type, dir)
  if not self:farea() or not self:fitem() then
    dbprint('no focused area or no focused item; returning')
    return
  end

  dbprint('handle_key('..type..', '..pdir[dir]..')')
  add_space()

  if type == "horizontal" or type == "vertical" then
    self:iter_within_area(dir)
  elseif type == "jump" then
    self:iter_between_areas(dir)
  elseif type == "ends" then
    self:jump_to_end(dir)
  elseif type == "middle" then
    self:jump_to_middle()
  end
end

--- @method keypressed
-- @brief Runs every time a key is pressed
function navigator:keypressed(key)
  self:farea():select_off()

  -- Debug stuff
  print("")
  spaces = ""
  if key == "q" then
    dbprint("\nDUMP: Current pos is "..self:farea().name.."("..(self:fitem() and self:fitem().index or "-")..")")
    self.root:dump()
  end

  -- Determine navigation type
  local type = ""
  if key == "j" or key == "k" then type = "vertical" end
  if key == "h" or key == "l" then type = "horizontal" end

  if key == "Tab" or key == "BackSpace" then type = "jump" end

  if key == "Return" then type = "release" end

  if key == "z" and self.last_key == "z" then type = "middle" end
  if key == "g" and self.last_key == "g" then type = "ends" end
  if key == "G" then type = "ends" end

  -- Determine if navigating left or right through tree
  local dir = NONE
  if key == "j" or key == "l" or key == "Tab" then dir = RIGHT end
  if key == "h" or key == "k" or key == "BackSpace" then dir = LEFT end
  if type == "ends" and key == "g" then dir = LEFT end
  if type == "ends" and key == "G" then dir = RIGHT end

  -- Call navigation function
  local valid_nav_types = {
    ["vertical"]   = true,
    ["horizontal"] = true,
    ["jump"]       = true, -- move between areas
    ["release"]    = true,
    ["ends"]       = true, -- like vim gg/GG
    ["middle"]     = true, -- like vim zz
  }

  if valid_nav_types[type] then
    self:handle_key(type, dir)
  else
    self:check_keybinds(key)
  end

  self.last_key = key
  self:farea():select_on()
end

--- @method keypressed
-- @brief Runs every time a key is released
function navigator:keyreleased(key)
end

--- @method start
-- @brief Start keygrabber to traverse through navtree and execute
-- keybound functions.
function navigator:start()
  self.focused_area = self.focused_area or self.root

  self.keygrabber = awful.keygrabber {
    -- TODO: The stop key should depend on whatever keyboard
    -- shortcut opened the navigator
    stop_key   = "Alt_L",
    stop_event = "press",
    autostart  = true,
    keypressed_callback  = function(_, _, key, _)
      self:keypressed(key)
    end,
    keyreleased = function(_, _, key, _)
      self:keyreleased(key)
    end,
    stop_callback = function()
    end
  }
end

--- @method stop
-- @brief Stop nav keygrabber.
function navigator:stop()
  if self.keygrabber then self.keygrabber:stop() end
end

return navigator
