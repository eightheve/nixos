local scroll = require("maki.scroll")

local FINE_SCROLL_LINES = 3

local function fine_scroll(delta)
  local ok, err = scroll(delta)
  if not ok then
    maki.log.debug("fine-scroll: " .. err)
  end
end

maki.keymap.set(
  "n",
  "<C-PageUp>",
  function()
    fine_scroll(-FINE_SCROLL_LINES)
  end,
  { desc = ("Scroll transcript up %d lines"):format(FINE_SCROLL_LINES) }
)

maki.keymap.set(
  "n",
  "<C-PageDown>",
  function()
    fine_scroll(FINE_SCROLL_LINES)
  end,
  { desc = ("Scroll transcript down %d lines"):format(FINE_SCROLL_LINES) }
)
