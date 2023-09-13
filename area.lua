
-- ▄▀█ █▀█ █▀▀ ▄▀█ 
-- █▀█ █▀▄ ██▄ █▀█ 

-- Basic unit for the nav hierarchy. An area's items can be
-- nav elements or other areas.

local gobject = require("gears.object")

local LEFT  = -1
local NONE  = 0
local RIGHT = 1

local debug = true
local function dbprint(...)
  if debug then print(...) end
end

local area = {}
area.__index = area

setmetatable(area, {
  __call = function(class, ...)
    return class:new(...)
  end
})

function area:new(args)
  args = args or {}
  self = setmetatable(gobject{}, area)

  self.widget = args.widget
  self.name = args.name or "unnamed_area"
  self.type = "area"

  -- Index within parent (areas can be items within another area)
  self.index = 1

  -- TODO: Don't remember what this does lol
  self.autofocus = args.autofocus or false

  self.is_wrapper = args.is_wrapper or false

  -- Grid stuff
  self.is_grid  = args.is_grid or false
  self.num_rows = args.num_rows
  self.num_cols = args.num_cols

  -- Doubly linked list stuff
  self.parent = nil
  self.next = self
  self.prev = self

  self.items = {}
  if args.items then
    for i = 1, #args.items do
      self:append(args.items[i])
    end
  end

  -- Keybound functions
  self.keys = args.keys or {}
  self.override_keys = args.override_keys or {}

  -- Reference to navigator
  self.nav = args.nav

  if args.parent_area then
    args.parent_area:append(self)
  end

  return self
end

function area:__concat()
  return self.name
end

function area:__eq(b)
  return self.name == b.name
end

-- █ █▄░█ █▀ █▀▀ █▀█ ▀█▀ ░░▄▀ █▀▄ █▀▀ █░░ █▀▀ ▀█▀ █▀▀ 
-- █ █░▀█ ▄█ ██▄ █▀▄ ░█░ ▄▀░░ █▄▀ ██▄ █▄▄ ██▄ ░█░ ██▄ 

function area:insert_at(index, item)
  print('INSERT AT UNIMPLEMENTED')
end

function area:prepend(item) end

--- @method append
-- @brief Append new item to end of list
function area:append(item)
  item.index = #self.items + 1
  item.parent = self

  if item.type == "area" then
    item.nav = self.nav
  end

  local first = self.items[1]
  local last  = self.items[#self.items]

  if #self.items > 0 then
    last.next  = item
    first.prev = item
    item.prev  = last
    item.next  = first
  else
    self.active_element = item
    item.prev = item
    item.next = item
  end

  self.items[#self.items+1] = item
end

--- @method remove
-- @brief Remove an element from this area by index.
-- TODO: Needs serious testing
function area:remove(index)
  print('Area: Removing by index')
  -- Get index of currently active element
  local active_idx = 1
  for i = 1, #self.items do
    if self.items[i] == self.active_element then
      active_idx = i
    end
  end

  -- TODO: What if it's the last remaining element?
  if index == active_idx then
    self:iter()
  else
    -- Fix doubly linked list references
    local target_prev = self.items[index].prev
    local target_next = self.items[index].next
    target_prev.next = target_next
    target_next.prev = target_prev
    table.remove(self.items, index)
    self:update_indices()
    return
  end
end

--- @method remove_area
-- @brief Remove a subarea from this area.
-- @param target (string) The name of the area to remove.
function area:remove_area(target)
  for i = 1, #self.items do
    if self.items[i].type == "area" then
      if self.items[i].name == target then

        -- Fix doubly linked list references
        local target_prev = self.items[i].prev
        local target_next = self.items[i].next
        target_prev.next = target_next
        target_next.prev = target_prev

        table.remove(self.items, i)

        self:update_indices()
        self.nav:emit_signal("area::removed", target)
        return
      else
        self.items[i]:remove_area(target)
      end
    end
  end
end

--- @method clear
-- @brief Remove all items from this area.
function area:clear()
  self.items = {}
  self.active_element = nil
  if self.nav then self.nav:emit_signal("area::cleared") end
end


-- █▄░█ ▄▀█ █░█ 
-- █░▀█ █▀█ ▀▄▀ 

--- @method iter
-- @param dir
function area:iter(dir)
  if dir == LEFT then
    self.active_element = self.active_element.prev
  elseif dir == RIGHT then
    self.active_element = self.active_element.next
  end
  return self.active_element
end

function area:set_active_element(element)
  self.active_element = element
end

function area:set_active_element_by_index(index)
  self.active_element = self.items[index]
end

function area:force_active()
  if self.nav then self.nav:set_focused_area(self) end
end

-- █▀▄▀█ █ █▀ █▀▀ 
-- █░▀░█ █ ▄█ █▄▄ 

--- @method dump
-- @brief Print area contents for debugging
function area:dump(space)
  space = space or ""
  local actelm = self.active_element
  dbprint(space.."'"..self.name.."["..(actelm and actelm.index or 0).."] "..
    '(P:'..(self.prev.name or "-")..
    ', N:'..(self.next.name or "-")..')'.. ": "..#self.items.." items")
  space = space .. "  "
  for i = 1, #self.items do
    if self.items[i].type == "area" then
      self.items[i]:dump(space .. "  ")
    else
      dbprint(space..'['..i..'] P:'..self.items[i].prev.index..' N:'..self.items[i].next.index)
    end
  end
end

--- @method contains_area
-- Check if this area contains a given area.
-- For this to work properly, the area's names must be set.
-- @param target (string) The name of the area to look for
function area:contains_area(target)
  if self.name == target then return true end
  for i = 1, #self.items do
    if self.items[i].type == "area" then
      if self.items[i]:contains_area(target) then return true end
    end
  end
  return false
end

--- @method verify_nav_references
-- @brief Make sure every sub-area contained within this one has
-- a reference to the main navigator. This is so an area can send signals
-- to the navigator. This function is only called on the nav_root area.
function area:verify_nav_references()
  for i = 1, #self.items do
    if self.items[i].type == "area" then
      self.items[i].nav = self.nav
      self.items[i]:verify_nav_references()
    end
  end
end

--- @method update_indices
-- @brief Update item indices. Usually called after something has been
-- removed.
function area:update_indices()
  for i = 1, #self.items do
    self.items[i].index = i
  end
end

-- ▄▀█ █▀▀ ▀█▀ █ █▀█ █▄░█ █▀ 
-- █▀█ █▄▄ ░█░ █ █▄█ █░▀█ ▄█ 

function area:select_on()
  if self.active_element and self.active_element.emit_signal then
    self.active_element:emit_signal("mouse::enter")
  end

  if self.widget and self.widget.emit_signal then
    self.widget:emit_signal("mouse::enter")
  end
end

function area:select_off()
  if self.active_element and self.active_element.emit_signal then
    self.active_element:emit_signal("mouse::leave")
  end

  if self.widget and self.widget.emit_signal then
    self.widget:emit_signal("mouse::leave")
  end
end

function area:release() end

return area
