░█▀▄░█▀▀░█▀█░█▀▄░█▄█░█▀▀
░█▀▄░█▀▀░█▀█░█░█░█░█░█▀▀
░▀░▀░▀▀▀░▀░▀░▀▀░░▀░▀░▀▀▀

# ⌨️ Keynav
I like AwesomeWM a lot and spend a lot of time making widgets. I also like Vim a lot and prefer to control everything with the keyboard. I was annoyed with having to use my mouse to use my widgets so I wrote this library to enable keyboard navigation within widgets.

Documentation is a little sparse right now but I'll update when I can and as best as I can.

The code is not very clean at the moment (which is why it has not been posted anywhere) but the library works perfectly for my needs.

# Usage
UI elements that you can interact with are called navitems
  - You need to define a class for every navitem that you want
  - This class includes `release`, `select_on`, and `select_off` functions that determine how the navitem should behave when interacting with it

Navitems are grouped into areas

The navigator controls moving through areas

Every widget must have a root area
  - You don't interact with the root area; it just acts as a container for other areas
  - Other areas must be appended to root (`nav_root:append(your_area_name)`)

```
-- Initializing the navigator
local navigator = require("modules.keynav").navigator
local navigator, nav_root = navigator:new()
```

To start/stop the navigator, call `navigator:start()` and `navigator:stop()`
  - This usually goes within a widget opened/closed signal

```
awesome.connect_signal("dash::open", function()
  dash.visible = true
  navigator:start()
end)

awesome.connect_signal("dash::close", function()
  dash.visible = false
  navigator:stop()
end)
```

# Examples
## Dashboard
(put picture of dashboard here)

The underlying keynav structure here looks like this

┌────────────────────────────────────────────────────┐
│                     NAV_ROOT                       │
│                                                    │
│ ┌────────────────────┐   ┌───────────────────────┐ │
│ │  NAV_TIMEWARRIOR   │   │      NAV_HABITS       │ │
│ │                    │   │ ┌───────────────────┐ │ │
│ │   - stop button    │   │ │     EXERCISE      │ │ │
│ └────────────────────┘   │ │- saturday button  │ │ │
│                          │ │- sunday button    │ │ │
│                          │ │- monday button    │ │ │
│                          │ │- tuesday button   │ │ │
│                          │ └───────────────────┘ │ │
│                          │ ┌───────────────────┐ │ │
│                          │ │       READ        │ │ │
│                          │ │- saturday button  │ │ │
│                          │ │- sunday button    │ │ │
│                          │ │- monday button    │ │ │
│                          │ │- tuesday button   │ │ │
│                          │ └───────────────────┘ │ │
│                          │  and so on for the    │ │
│                          │     other habits      │ │
│                          └───────────────────────┘ │
└────────────────────────────────────────────────────┘

- Pressing hjkl moves between navitems in an area
- Pressing enter "clicks" the button
- Pressing (shift+)tab cycles between areas

- Areas can be laid out in a grid
  - The habit widget is laid out in a grid formation with each habit having its own area
  - There, I prefer hjkl to move up, down, left, right through items in the grid
  - I also prefer that tab ignores subareas in the grid (exercise, read, etc) so it doesn't cycle between them

To replicate this, just set a few flags when initializing the areas:
```
-- Init the area containing all of the habit sub-areas
local nav_dash_habits = Area:new({
  name = "nav_dash_habits",
  circular = true,
  is_grid_container = true,
})

...

for i = 1, #habit_list do
  local nav_habit = Area:new({
    name = habit_list[i],
    circular = true,
    is_row = true,
    row_wrap_vertical = true,
  })
  nav_dash_habits:append(nav_habit)
end
```

## Task manager
The underlying keynav structure here looks like this

┌─────────────────────────────────────────────────────────────┐
│                        NAV_ROOT                             │
│    ┌────────────┐  ┌─────────────────┐   ┌───────────────┐  │
│    │  NAV_TAGS  │  │   NAV_PROJECTS  │   │ NAV_TASKLIST  │  │
│    │  - tag 1   │  │  - project 1    │   │  - task 1     │  │
│    │  - tag 2   │  │  - project 2    │   │  - task 2     │  │
│    │  - tag 3   │  │  - etc          │   │  - etc        │  │
│    │  - etc     │  │                 │   │               │  │
│    └────────────┘  └─────────────────┘   └───────────────┘  │
└─────────────────────────────────────────────────────────────┘

- Areas can have "container" widgets attached to them
  - These widgets only have the `select_on` and `select_off` functions defined
  - Example: the tags, projects, and tasklist areas have the wibox_background widget set as the container widget
    - When navigating within the area, you can see the container widget highlights
    - When outside the area, the container widget unhighlights
  
- Pressing G/gg jumps to top/bottom

## Control center
(todo)

## Theme switcher
(todo)

# Debugging
- Use Xephyr to test your config in a sandbox
- Open whatever widget you're testing
- Press `q` to print the keynav hierarchy
