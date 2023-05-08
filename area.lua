
-- ▄▀█ █▀█ █▀▀ ▄▀█ 
-- █▀█ █▀▄ ██▄ █▀█ 

-- Basic unit for the nav hierarchy. An area's items can be
-- navelements or other areas.

local LEFT  = -1
local NONE  = 0
local RIGHT = 1

local pdir = {
  [0]  = "NONE",
  [1]  = "RIGHT",
  [-1] = "LEFT",
}

local area = {}
area.__index = area

setmetatable(area, {
  __call = function(class, ...)
    return class:new(...)
  end
})

function area:new(args)
  args = args or {}
  self = setmetatable({}, area)

  self.widget = args.widget
  self.name = args.name or "unnamed_area"
  self.type = "area"

  -- Index within parent (areas can be items within another area)
  self.index = 1

  -- TODO: Unused
  self.circular = args.circular or true

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

  return self
end

function area:__eq(b)
  return self.name == b.name
end


-- █ █▄░█ █▀ █▀▀ █▀█ ▀█▀ ░░▄▀ █▀▄ █▀▀ █░░ █▀▀ ▀█▀ █▀▀ 
-- █ █░▀█ ▄█ ██▄ █▀▄ ░█░ ▄▀░░ █▄▀ ██▄ █▄▄ ██▄ ░█░ ██▄ 

function area:insert_at(index, item)
end

function area:prepend(item) end

--- @method append
-- @brief Append new item to end of list
function area:append(item)
  print()
  print('Appending item to '..self.name)

  item.index = #self.items + 1
  item.parent = self

  local last  = self.items[#self.items]
  local first = self.items[1]

  -- Update item references
  print('  There are '..#self.items..' items in this area')
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

  print('  Inserted at position '..item.index)
  self:dump()
end


-- █▄░█ ▄▀█ █░█ 
-- █░▀█ █▀█ ▀▄▀ 

--- @method iter
-- @param dir
function area:iter(dir)
  print('area::iter('..pdir[dir]..')')
  if dir == LEFT then
    self.active_element = self.active_element.prev
  elseif dir == RIGHT then
    self.active_element = self.active_element.next
  end
  return self.active_element
end

function area:set_active_element(index)
  self.active_element = self.items[index]
end

-- █▀▄▀█ █ █▀ █▀▀ 
-- █░▀░█ █ ▄█ █▄▄ 

--- @method dump
-- @brief Print area contents
function area:dump(space)
  space = space or ""
  local actelm = self.active_element
  print(space.."'"..self.name.."["..(actelm and actelm.index or 0).."] "..
        '(P:'..(actelm and self.active_element.prev.index or "-")..
        ', N:'..(actelm and self.active_element.next.index or "-")..')'.. ": "..#self.items.." items")
  space = space .. "  "
  for i = 1, #self.items do
    if self.items[i].type == "area" then
      self.items[i]:dump(space .. "  ")
    else
      print(space..'['..i..'] P:'..self.items[i].prev.index..' N:'..self.items[i].next.index)
    end
  end
end

--- @method contains_area
-- Check if this area contains a given area.
-- For this to work properly, the area's names must be set.
-- @param target (string) The name of the area to look for
function area:contains_area(target)
  for i = 1, #self.items do
    if self.items[i].type == "area" then
      if self.items[i].name == target then
        return true
      else
        return self.items[i]:contains_area(target)
      end
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
    if self.items[i].type == area then
      self.items[i].nav = self.nav
      self.items[i]:verify_nav_references()
    end
  end
end

-- ▄▀█ █▀▀ ▀█▀ █ █▀█ █▄░█ █▀ 
-- █▀█ █▄▄ ░█░ █ █▄█ █░▀█ ▄█ 

function area:select_on()
  if self.active_element then self.active_element:select_on() end
  if self.widget then self.widget:select_on() end
end

function area:select_off()
  if self.active_element then self.active_element:select_off() end
  if self.widget then self.widget:select_off() end
end

function area:release() end

return area
