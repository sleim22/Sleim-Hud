atlas = require('atlas')
targetVektorPoints = {}

function zeroConvertToWorldCoordinates(cl)
    local q = ' *([+-]?%d+%.?%d*e?[+-]?%d*)'
    local cm = '::pos{' .. q .. ',' .. q .. ',' .. q .. ',' .. q .. ',' .. q .. '}'
    local cn, co, ci, cj, ch = string.match(cl, cm)
    if cn == '0' and co == '0' then
        return vec3(tonumber(ci), tonumber(cj), tonumber(ch))
    end
    cj = math.rad(cj)
    ci = math.rad(ci)

    local planet = atlas[tonumber(cn)][tonumber(co)]
    system.print(planet.name[1])
    local cp = math.cos(ci)
    local cq = vec3(cp * math.cos(cj), cp * math.sin(cj), math.sin(ci))
    return (vec3(planet.center) + (planet.radius + ch) * cq)
end

function setCalculatedWaypoint(waypoint)
    system.setWaypoint("::pos{0,0," .. waypoint.x .. "," .. waypoint.y .. "," .. waypoint.z .. "}")
end

function calculateVektor()
    local P = targetVektorFromTarget[1]
    local Q = targetVektorFromTarget[2]
    local abstand = P:dist(Q)
    --system.print(abstand)
    local meter = 200000 * 50
    local lambda = meter / abstand
    local richtungsVerktor = Q - P
    local R = P + lambda * richtungsVerktor
    setCalculatedWaypoint(R)
end

if text:sub(1, 5) == "::pos" then
    table.insert(targetVektorPoints, text)
    if (#targetVektorPoints == 2) then
        system.print("Target Vektor Point 2 added")
        calculateVektor()
        targetVektorPoints = {}
    else
        system.print("Target Vektor Point 1 added")
    end
elseif text == "clear" then
    targetVektorPoints = {}
else
    system.print("Searching for: " .. string.upper(text))
    targetCode = string.upper(text)
end
function addPoint()

end

targetVektorFromTarget = {}
function getPointFromTarget()
    local targetId = radar.getTargetId()

    if targetId == 0 or radar.isConstructIdentified(targetId) == 0 then
        system.print("No target")
        return
    end
    local l = targetDistance
    local pcrossHair = vec3(construct.getWorldPosition()) + l * vec3(construct.getWorldForward())
    table.insert(targetVektorFromTarget, pcrossHair)
    if (#targetVektorFromTarget == 2) then
        system.print("Target Vektor Point 2 added")
        calculateVektor()
        targetVektorFromTarget = {}
    else
        system.print("Target Vektor Point 1 added")
    end
end
