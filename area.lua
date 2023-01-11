
-- ▄▀█ █▀█ █▀▀ ▄▀█ 
-- █▀█ █▀▄ ██▄ █▀█ 

-- Basic unit for the nav tree. Can contain navitems or child areas.
-- Very messy right now and needs more documentation (but it works!)

local Area = {}
Area.__index = Area

setmetatable(Area, {
  __call = function(class, ...)
    return class:new(...)
  end
})

function Area:new(args)
  self = setmetatable({}, Area)

  self.name      = args.name or "unnamed_area"
  self.parent    = args.parent or nil
  self.items     = args.items or {}
  self.widget    = args.widget or nil
  self.index     = 1
  self.is_area   = true
  self.is_navitem = false
  self.is_row    = args.is_row or false
  self.is_column = args.is_column or false
  self.selected  = false
  self.visited   = false
  self.nav       = args.nav or nil
  self.confine   = args.confine or false
  self.circular  = args.circular or false
  self.keys      = args.keys or nil

  self.is_grid   = args.is_grid or nil
  self.grid_rows = args.grid_rows or nil
  self.grid_cols = args.grid_cols or nil

  -- If the area contains a grid of navitems. Needed because grid navigation has a very
  -- specific algorithm.
  -- TODO fix the dumbass algorithm
  self.is_grid_container = args.is_grid_container or false

  -- If the current item highlight should persist when switching to another area.
  self.hl_persist_on_area_switch = args.hl_persist_on_area_switch or false

  args.children = args.children or {}
  for i = 1, #args.children do
    self:append(args.children[i])
  end

  return self
end

-- ▄▀█ █▀▀ █▀▀ █▀▀ █▀ █▀    █▀▀ █░█ █▄░█ █▀▀ ▀█▀ █ █▀█ █▄░█ █▀ 
-- █▀█ █▄▄ █▄▄ ██▄ ▄█ ▄█    █▀░ █▄█ █░▀█ █▄▄ ░█░ █ █▄█ █░▀█ ▄█ 

--- Override equality operator to check if 2 areas are equal.
-- @param b The area to check equality against.
function Area:__eq(b)
  return self.name == b.name
end

function Area:is_empty() return #self.items == 0 end

-- Append item to area's item table.
function Area:append(item)
  if item.is_area then
    item.parent = self
    if self.nav then
      item.nav = self.nav
    end
  end
  table.insert(self.items, item)
end

-- Returns if current area contains a given area.
function Area:contains(item)
  if not item.is_area then return end
  for i = 1, #self.items do
    if self.items[i].is_area then
      if self.items[i] == item then
        return true
      end
    end
  end
  return false
end

-- Return the currently selected item within the item table.
-- TODO: Replace with get_focused_item
function Area:get_curr_item()
  return self.items[self.index]
end

function Area:get_focused_item()
  return self.items[self.index]
end

-- TODO: Replace with set_curr_item
--- Set focused item to the item at the given index.
-- @param idx Index to set
function Area:set_curr_item(idx)
  if idx > 0 and idx <= #self.items then
    if self.items[self.index] then
      self.items[self.index]:select_off()
    end
    self.index = idx
    self.items[self.index]:select_on()
  end
end

-- function Area:set_focused_item(idx)
--   if idx > 0 and idx <= #self.items then
--     if self.items[self.index] then
--       self.items[self.index]:select_off()
--     end
--     self.index = idx
--     self.items[self.index]:select_on()
--   end
-- end

--- Remove an item from a given index in the item table.
-- @index Index of item to remove.
function Area:remove_index(index)
  local item = self.items[index]
  if item then
    -- Turn off highlight
    if item.is_area then
      item:select_off_recursive()
    else
      item:select_off()
    end
    table.remove(self.items, index)
  end
end


-- Remove an area with a specific name from area's item table.
function Area:remove_item(item)
  if self.nav then
    self.nav:emit_signal("nav::area_removed", self, item)
  end
  item:select_off_recursive()
  item:reset_visited_recursive()
  --if self.items[self.index] == item then
  --  self.index = 1
  --end
  for i = 1, #self.items do
    if item == self.items[i] then
      if i <= self.index then
        self.index = self.index - 1
      end
      table.remove(self.items, i)
      return
    end
  end
end

-- Remove all items from area.
function Area:remove_all_items()
  for i = 1, #self.items do
    table.remove(self.items, i)
  end
  self.items = {} -- why does the loop not work but this does???
  self.index = 1
end

-- Remove all child items except for the given area
-- Returns true if successful, false otherwise
function Area:remove_all_except_item(item)
  -- Item must be an area
  if item and not item.is_area then
    return false
  end

  -- Must contain item to begin with
  if not self:contains(item) then
    return false
  end

  -- Execute
  for i = 1, #self.items do
    local curr = self.items[i]
    if curr.is_area and not (curr == item) then
      table.remove(self.items, i)
      if i < self.index then
        self.index = self.index - 1
        if self.index < 0 then self.index = 1 end
      end
    end
  end

  return #self.items == 1 and self.items[1] == item
end

-- Reset area to defaults.
-- Deselect any children and set the index back to 1.
function Area:reset()
  self:select_off_recursive()
  self:reset_visited_recursive()
  self:reset_index_recursive()
  self.index = 1
end

-- ▄▀█ █▀▀ ▀█▀ █ █▀█ █▄░█    █▀▀ █░█ █▄░█ █▀▀ ▀█▀ █ █▀█ █▄░█ █▀ 
-- █▀█ █▄▄ ░█░ █ █▄█ █░▀█    █▀░ █▄█ █░▀█ █▄▄ ░█░ █ █▄█ █░▀█ ▄█ 
-- Actions for area's attached widget

-- You should not be able to directly interact with the area widget
function Area:release() end

function Area:select_on_recurse_up()
  -- Set self and current item
  self.selected = not self.selected
  if self.items[self.index] and self.items[self.index].is_navitem then
    self.items[self.index]:select_on()
  end

  -- Toggle area widgets
  if self.widget then self.widget:select_on() end

  -- Recurse up through the navtree
  if self.parent then
    self.parent:select_on_recurse_up()
  end
end

-- Toggle selection for the current item and also all areas within
-- the branch.
function Area:select_toggle_recurse_up()
  -- Toggle self and current item
  self.selected = not self.selected
  if self.items[self.index] and self.items[self.index].is_navitem then
    self.items[self.index]:select_toggle()
  end

  -- Toggle area widgets
  if self.widget then self.widget:select_toggle() end

  -- Recurse up through the navtree
  if self.parent then
    self.parent:select_toggle_recurse_up()
  end
end

-- Turn off highlight for associated widget
function Area:select_off()
  if self.widget then
    self.widget:select_off()
  end
end

-- Turn off highlight for all child items
function Area:select_off_recursive()
  if self.widget then self.widget:select_off() end
  self.selected = false
  for i = 1, #self.items do
    if self.items[i].is_area then
      self.items[i]:select_off_recursive()
    else
      self.items[i]:select_off()
    end
  end
end

function Area:iter_force_circular(amount)
  local new_index = self.index + amount
  self.index = new_index % #self.items
  if self.index == 0 then
    self.index = #self.items
  end
  return self.items[self.index]
end

-- Iterate through an area's item table by a given amount.
-- Returns the item that it iterated to.
function Area:iter(amount)
  local new_index = self.index + amount

  -- If iterating went out of item table's bounds and the area isn't
  -- circular, then return nil.
  local overflow = new_index > #self.items or new_index <= 0
  if not self.circular and overflow then
    return
  end

  -- Otherwise, iterate like normal.
  self.index = new_index % #self.items
  if self.index == 0 then
    self.index = #self.items
  end
  return self.items[self.index]
end

-- only max if it has child areas?
function Area:max_index_recursive()
  for i = 1, #self.items do
    if self.items[i].is_area then
      self.index = #self.items
      self.items[i]:max_index_recursive()
    end
  end
end

function Area:reset_index_recursive()
  self.index = 1
  for i = 1, #self.items do
    if self.items[i].is_area then
      self.items[i]:reset_index_recursive()
    end
  end
end

-- Sets visited = false for area and all child areas
function Area:reset_visited_recursive()
  self.visited = false
  for i = 1, #self.items do
    if self.items[i].is_area then
      self.items[i]:reset_visited_recursive()
    elseif self.items[i].is_navitem then
      self.items[i].visited = false
    end
  end
end

function Area:foreach(func)
  for i = 1, #self.items do
    func(self.items[i])
  end
end

-- Ensure that every child has a reference to the nav
-- Should be called on root area.
function Area:verify_nav_references()
  if self.parent and not self.nav then
    self.nav = self.parent.nav
  end

  for i = 1, #self.items do
    if self.items[i].is_area then
      self.items[i]:verify_nav_references()
    end
  end
end

-- Print area contents.
function Area:dump()
  --print("\nDUMP: Current pos is "..self.name.."("..self.index..")")
  self:_dump()
end

function Area:_dump(space)
  space = space or ""
  print(space.."'"..self.name.."["..tostring(self.index).."]': "..#self.items.." items")
  space = space .. "  "
  for i = 1, #self.items do
    if self.items[i].is_area then
      self.items[i]:_dump(space .. "  ")
    end
  end
end

return Area

