local customWaypoints = { { name = "", pos = "", color = "" } }
local words = {}
local name = ""
for word in text:gmatch("%S+") do
    table.insert(words, word)
    if #words > 2 then
        name = name .. word
    end
end
if string.find(words[2], "::pos") then
    table.insert(customWaypoints, { name = name, pos = words[2], color = "yellow" })
end
