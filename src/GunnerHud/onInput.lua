local function isFilterCommand(inputString)
    return inputString:match("^/filter") ~= nil
end

local function parseFilterString(filterString)
    local distance, area, rarity
    local distance_match = filterString:match("-d (%d+)")
    if distance_match then distance = tonumber(distance_match) end
    local area_match = filterString:match("-a ([%w, ]+)")
    if area_match then area = area_match end
    local rarity_match = filterString:match("-r ([%w, ]+)")
    if rarity_match then rarity = rarity_match end
    return { distance = tonumber(distance) or nil, area = area or nil, rarity = rarity or nil }
end

function filterWaypoints(waypoints, filter)
    local filteredWaypoints = {}
    for _, waypoint in pairs(waypoints) do
        local waypointCoordinates = waypoint.pos
        local distance = (waypointCoordinates - vec3(construct.getWorldPosition())):len()
        if (not filter.area or (waypoint.area and string.find(filter.area, waypoint.area))) and
            (not filter.rarity or (waypoint.rarity and string.find(filter.rarity, waypoint.rarity))) and
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
    system.print("Custom waypoints filtered!")
    if filter.area then activeFilter = system.print("Area: " .. filter.area) end
    if filter.rarity then activeFilter = system.print("Rarity: " .. filter.rarity) end
    if filter.distance then activeFilter = system.print("Distance: " .. filter.distance) end
    filteredWaypoints = filterWaypoints(customWaypoints, filter)
elseif beginning == "/spee" then
    local speed = text:match("%d+")
    if TargetVektorInfo.isTracking and speed then
        TargetVektorInfo.manualSpeed = speed / 3.6
        TargetVektorInfo.displaySpeed = comma_value(math.floor(speed))
    end
elseif text == "/import" then
    importTargetVector()
elseif text == "/export" then
    exportTargetVector()
else
    system.print("Searching for: " .. string.upper(text))
    targetCode = string.upper(text)
end
