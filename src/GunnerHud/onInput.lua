local function isFilterCommand(inputString)

    return inputString:match("^/filter") ~= nil
end

local function parseFilterString(filterString)
    local distance, area, rarity
    local distance_match = filterString:match("-d (%d+)")
    if distance_match then distance = tonumber(distance_match) end
    local area_match = filterString:match("-a (%w+)")
    if area_match then area = area_match end
    local rarity_match = filterString:match("-r (%w+)")
    if rarity_match then rarity = rarity_match end
    return { distance = tonumber(distance) or 400 * 200000, area = area or nil, rarity = rarity or nil }
end

local function filterWaypoints(waypoints, filter)
    local filteredWaypoints = {}
    for _, waypoint in pairs(waypoints) do
        local waypointCoordinates = zeroConvertToWorldCoordinates(waypoint.pos)
        local distance = (waypointCoordinates - vec3(construct.getWorldPosition())):len()
        if (not filter.area or waypoint.area == filter.area) and
            (not filter.rarity or waypoint.rarity == filter.rarity) and
            (not filter.distance or distance < filter.distance * 200000) then
            table.insert(filteredWaypoints, waypoint)
        end
    end
    return filteredWaypoints
end

local beginning = text:sub(1, 5)
if beginning == "::pos" then
    addPoint(zeroConvertToWorldCoordinates(text))
elseif text == "clear" then
    system.print("Vektor points cleared")
    targetVektorPoints = {}
elseif beginning == "/add " then
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
elseif isFilterCommand(text) then
    local filter = parseFilterString(text)
    filteredWaypoints = filterWaypoints(customWaypoints, filter)
else
    system.print("Searching for: " .. string.upper(text))
    targetCode = string.upper(text)
end
