-- █▄░█ ▄▀█ █░█ █ █▀▀ ▄▀█ ▀█▀ █▀█ █▀█
-- █░▀█ █▀█ ▀▄▀ █ █▄█ █▀█ ░█░ █▄█ █▀▄

-- Responsible for moving around through the navtree and
-- executing keybinds.

local awful   = require("awful")
local gobject = require("gears.object")
local path    = (...):match("(.-)[^%.]+$")
local math    = math

-- For printing stacktrace
local debug_mode = false
local spaces     = ""
local function add_space() spaces = spaces .. "  " end
local function sub_space() spaces = string.gsub(spaces, "^  ", "") end
local function dbprint(msg) if debug_mode then print(spaces .. msg) end end

local BACK  = -1
local NONE  = 0
local FORWARD = 1

local pdir = {
  [0]  = "NONE",
  [1]  = "FORWARD",
  [-1] = "BACK",
}

local mod = {
  ["Shift_L"] = true,
  ["Shift_R"] = true,
  ["Control_L"] = true,
  ["Control_R"] = true,
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
  self = setmetatable(gobject {}, navigator)

  -- This has to be a string because when checking for keybinds
  -- with multiple keys, we concat last_key with the current key
  self.last_key = "nil"

  -- Set up root area
  self.root = require(path .. "area")({
    name = "root",
    nav  = self,
  })

  if args.items then
    for i = 1, #args.items do
      self.root:append(args.items[i])
    end
  end

  self:connect_signal("area::cleared", self.handle_cleared_area)

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

--- @method handle_navkey
-- @brief Execute navigation functions for direction keys.
-- @param type  A navigation type:
--              horizontal, vertical, jump, release, ends, middle
-- @param dir   BACK, FORWARD, or NONE
function navigator:handle_navkey(type, dir)
  if not self:farea() then return end

  -- dbprint('handle_navkey('..type..', '..pdir[dir]..')')
  add_space()

  if type == "horizontal" or type == "vertical" then
    if self:farea().is_grid then
      self:iter_within_area_grid(type, dir)
    else
      if not self:fitem() then
        self.focused_area = self:parent()
        self:iter_between_areas(dir)
      else
        self:iter_within_area(dir)
      end
    end
  elseif type == "jump" then
    self:iter_between_areas(dir)
  elseif type == "ends" then
    self:jump_to_end(dir)
  elseif type == "middle" then
    self:jump_to_middle()
  elseif type == "release" then
    self:fitem():release()
  end
end

--- @method iter_between_areas
-- @brief Move to the current focused area's neighbor.
function navigator:iter_between_areas(dir)
  if not self:farea() or not self:fitem() then return end

  dbprint('iter_between_areas(' .. pdir[dir] .. ')')
  add_space()

  -- Handle wrapper area edge case
  if self:parent() and self:parent().is_wrapper then
    local index = self:farea().index
    local last_index = #self:parent().items
    if (index == 1 and dir == BACK) or (index == last_index and dir == FORWARD) then
      self.focused_area = self:parent()
      self:iter_between_areas(dir)
      return
    end
  end

  local next_area = dir == BACK and self:farea().prev or self:farea().next

  -- If there are no items in the next area, then don't go anywhere
  if #next_area.items == 0 then return end

  -- If the next area's focused item is an area, go within there
  if next_area.active_element.type == "area" then
    dbprint('next area is '..next_area.name)
    dbprint("next area's active element is an area - going in there!")
    self.focused_area = next_area
    self:iter_within_area(NONE)
    dbprint('switched to ' .. self:farea().name .. ' -------------')
    return
  end

  self.focused_area = next_area
  dbprint('switched to ' .. self:farea().name .. ' -------------')
end

--- @method iter_within_area
-- @brief Iterate within the current focused area's items.
function navigator:iter_within_area(dir)
  if not self:farea() or not self:fitem() then return end
  -- dbprint('iter_within_area('..pdir[dir]..')')

  -- If current focused item is an area, and it has items, iterate
  -- within that area
  if self:fitem().type == "area" and #self:fitem().items > 0 then
    -- dbprint('focused item is an area - traversing within')
    add_space()
    self.focused_area = self:fitem()
    return self:iter_within_area(NONE)

    -- If current focused item is a navitem or an area with no items,
    -- move to the next one like normal
  else
    -- dbprint('focused item is a navitem - iterating like normal')
    self.focused_area:iter(dir)
  end
end

--- @method iter_within_area_grid
-- @brief Iterate within a grid.
-- @param type horizontal or vertical
-- @param dir  FORWARD or BACK
function navigator:iter_within_area_grid(type, dir)
  if not self:farea() or not self:fitem() then return end

  local p = self:farea()
  local index = self:fitem().index - 1 -- temp zero-index to make math easier
  local maxindex = #p.items - 1

  -- These need to be specified for math to work; otherwise
  -- just iter like normal
  if not p.num_rows and not p.num_cols then
    self:iter_within_area(dir)
    return
  end

  -- Dir is either 1 (forward) or -1 (back)
  local newindex
  if type == "horizontal" then
    newindex = index + (1 * dir)
    local oldmod = index % p.num_cols
    local newmod = newindex % p.num_cols

    if dir == BACK then
      newindex = (newmod > oldmod and newindex + p.num_cols) or newindex

      if newindex > maxindex then
        newindex = maxindex
      end
    elseif dir == FORWARD then
      newindex = (newmod < oldmod and newindex - p.num_cols) or newindex

      if newindex > maxindex then
        newindex = math.floor(index / p.num_cols) * p.num_cols
      end
    end

  elseif type == "vertical" then
    newindex = index + (p.num_cols * dir)

    if newindex < 0 then
      newindex = (math.floor(maxindex / p.num_cols) * p.num_cols) + (index % p.num_cols)
      if newindex > maxindex then
        newindex = newindex - p.num_cols
      end
    elseif newindex > maxindex then
      newindex = index % p.num_cols
    end
  end

  self:farea():set_active_element_by_index(newindex + 1)
end

--- @method jump_to_end
-- @brief Jump to end of area
function navigator:jump_to_end(dir)
  if not self:farea() or not self:fitem() then return end

  -- dbprint('jump_to_end('..pdir[dir]..')')

  if dir == BACK then
    self:farea():set_active_element_by_index(1)
  elseif dir == FORWARD then
    local num_items = #self:farea().items
    self:farea():set_active_element_by_index(num_items)
  end
end

--- @method jump_to_middle
-- @brief Jump to middle
function navigator:jump_to_middle()
  if not self:farea() or not self:fitem() then return end
  local mid = math.floor((#self:farea().items / 2) + 0.5)
  self:farea():set_active_element_by_index(mid)
end

--- @method handle_cleared_area
-- @brief If an area gets cleared and the navigator is currently somewhere within
-- that area, reset focus to root.
function navigator:handle_cleared_area()
  if not self:farea() or not self.root:contains_area(self:farea().name) then
    self.focused_area = self.root
    self:iter_within_area(NONE)
  end
end

-- █▄▀ █▀▀ █▄█ █▀
-- █░█ ██▄ ░█░ ▄█

--- @method check_keybinds
-- @brief Checks if a key is associated with any keybinds, then
-- execute that keybind. Recurse through parent areas if not found.
function navigator:check_keybinds(key, area)
  add_space()
  if not area then
    if self:fitem() and self:fitem().type == "area" then
      area = self:fitem()
    else
      area = self:farea()
    end
  end

  -- Start from the lowest level and work your way up
  if area.keys[key] then
    area.keys[key](area)
  else
    if area.parent then
      area = area.parent
      self:check_keybinds(key, area)
    end
  end
end

--- @method check_override_keybinds
-- @brief Checks if a key is associated with any override keybinds, then
-- execute that keybind. Recurse through parent areas if not found.
function navigator:check_override_keybinds(key, area)
  add_space()
  if not area then area = self:farea() end

  -- Start from the lowest level and work your way up
  if area.override_keys[key] then
    area.override_keys[key](area)
    return true
  else
    if area.parent then
      area = area.parent
      return self:check_override_keybinds(key, area)
    end
  end
  return false
end

--- @method keypressed
-- @brief Runs every time a key is pressed
function navigator:keypressed(key)
  self.last_area = self.focused_area

  if self:farea().name == "root" then
    if #self:farea().items > 0 and self:farea().items[1].autofocus then
      self:iter_within_area(NONE)
    end
  end

  -- Debug stuff
  -- dbprint("")
  spaces = ""
  if key == "q" then
    dbprint("\nDUMP: Current pos is " .. self:farea().name .. "(" .. (self:fitem() and self:fitem().index or "-") .. ")")
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
  if key == "j" or key == "l" or key == "Tab" then dir = FORWARD end
  if key == "h" or key == "k" or key == "BackSpace" then dir = BACK end
  if type == "ends" and key == "g" then dir = BACK end
  if type == "ends" and key == "G" then dir = FORWARD end

  -- Call navigation function
  local valid_nav_types = {
    ["vertical"]   = true,
    ["horizontal"] = true,
    ["jump"]       = true, -- move between areas
    ["release"]    = true,
    ["ends"]       = true, -- like vim gg/GG
    ["middle"]     = true, -- like vim zz
  }

  -- override_keys{} take priority over navigational keybinds, and if one exists, the nav keybind is not executed.
  -- keys{} are executed alongside nav keybinds.
  -- last_key is for keybinds like zz, gg, GG
  if not self:check_override_keybinds(key) and not self:check_override_keybinds(self.last_key .. key) then
    if valid_nav_types[type] then
      self:farea():select_off()
      self:handle_navkey(type, dir)
      self:farea():select_on()
    end

    self:check_keybinds(key)
    self:check_keybinds(self.last_key .. key)
  end

  self.last_key = key

  if self.last_area ~= self.focused_area then
    self.last_area:emit_signal("area::left")
    self.focused_area:emit_signal("area::enter")
  end
end

--- @method start
-- @brief Start keygrabber to traverse through navtree and execute
-- keybound functions.
function navigator:start()
  self.focused_area = self.focused_area or self.root
  self.root:verify_nav_references()

  self.keygrabber = awful.keygrabber {
    -- TODO: The stop key should depend on whatever keyboard
    -- shortcut opened the navigator
    stop_key            = "Mod4",
    stop_event          = "press",
    autostart           = true,
    keypressed_callback = function(_, _, key, _)
      self:keypressed(key)
    end,
    stop_callback       = function()
    end
  }
end

--- @method stop
-- @brief Stop nav keygrabber.
function navigator:stop()
  if self.keygrabber then self.keygrabber:stop() end
end

return navigator
