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
    addPoint(zeroConvertToWorldCoordinates(text))
elseif text == "clear" then
    targetVektorFromTarget = {}
else
    system.print("Searching for: " .. string.upper(text))
    targetCode = string.upper(text)
end

function addPoint(point)
    table.insert(targetVektorFromTarget, point)
    if (#targetVektorFromTarget == 2) then
        system.print("Target Vektor Point 2 added")
        calculateVektor()
        targetVektorFromTarget = {}
    else
        system.print("Target Vektor Point 1 added")
    end
end

targetVektorFromTarget = {}
function getPointFromTarget()
    local targetId = radar.getTargetId()

    if targetId == 0 or not radar.isConstructIdentified(targetId) then
        system.print("No target")
        return
    end
    local l = targetDistance
    local targetPos = vec3(construct.getWorldPosition()) + l * vec3(construct.getWorldForward())
    addPoint(targetPos)
end
