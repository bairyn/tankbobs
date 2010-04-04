---[[[[                    ]]]]---
---[[=[  dvorak key layout ]=]]---
---[[[[                    ]]]]---

local keyLayoutName = "AOEUdvorak!"
local layout =
{
	{from = 97,  to = 97},   -- a -> a
	{from = 98,  to = 120},  -- b -> x
	{from = 99,  to = 106},  -- c -> j
	{from = 100, to = 101},  -- d -> e
	{from = 101, to = 46},   -- e -> .
	{from = 102, to = 117},  -- f -> u
	{from = 103, to = 105},  -- g -> i
	{from = 104, to = 100},  -- h -> d
	{from = 105, to = 99},   -- i -> c
	{from = 106, to = 104},  -- j -> h
	{from = 107, to = 116},  -- k -> t
	{from = 108, to = 110},  -- l -> n
	{from = 109, to = 109},  -- m -> m
	{from = 110, to = 98},   -- n -> b
	{from = 111, to = 114},  -- o -> r
	{from = 112, to = 108},  -- p -> l
	{from = 113, to = 39},   -- q -> '
	{from = 114, to = 112},  -- r -> p
	{from = 115, to = 111},  -- s -> o
	{from = 116, to = 121},  -- t -> y
	{from = 117, to = 103},  -- u -> g
	{from = 118, to = 107},  -- v -> k
	{from = 119, to = 44},   -- w -> ,
	{from = 120, to = 113},  -- x -> q
	{from = 121, to = 102},  -- y -> f
	{from = 122, to = 59},   -- z -> ;
	{from = 91,  to = 47},   -- [ -> /
	{from = 93,  to = 61},   -- ] -> =
	{from = 92,  to = 92},   -- \ -> \
	{from = 47,  to = 122},  -- / -> z
	{from = 61,  to = 93},   -- = -> ]
	{from = 45,  to = 91},   -- - -> [
	{from = 39,  to = 45},   -- ' -> -
	{from = 44,  to = 119},  -- , -> w
	{from = 46,  to = 118},  -- . -> v
	{from = 59,  to = 115}   -- ; -> s
}

----- Don't change anything below here! -----

local layout_to = {}
local layout_from = {}
for _, v in pairs(layout) do
	layout_to[v.from] = v.to
	layout_from[v.to] = v.from
end
c_const_set("keyLayout_" .. keyLayoutName, layout, 1)
c_const_set("keyLayout_" .. keyLayoutName .. "To", layout_to, 1)
c_const_set("keyLayout_" .. keyLayoutName .. "From", layout_from, 1)
local layouts = c_const_get("keyLayouts")
table.insert(layouts, keyLayoutName)
c_const_set("keyLayouts", layouts)
