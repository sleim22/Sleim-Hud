aligned = false
local previousYawAmount = 0
local previousPitchAmount = 0
local pitchInput2 = 0
local yawInput2 = 0
local rollInput2 = 0
local targetRoll = 0
function AlignToWorldVector(vector) -- Aligns ship to vector with a tolerance and a damping override of user damping if needed.
    local mabs = math.abs
    local C = construct
    local tolerance = 0.01
    local damping = 0.2
    local function getMagnitudeInDirection(vector, direction)
        -- return vec3(vector):project_on(vec3(direction)):len()
        vector = vec3(vector)
        direction = vec3(direction):normalize()
        local result = vector * direction -- To preserve sign, just add them I guess

        return result.x + result.y + result.z
    end
    -- Sets inputs to attempt to point at the autopilot target
    -- Meant to be called from Update or Tick repeatedly
    local alignmentTolerance = 0.001 -- How closely it must align to a planet before accelerating to it
    local autopilotStrength = 1      -- How strongly autopilot tries to point at a target

    if damping == nil then
        damping = DampingMultiplier
    end

    if tolerance == nil then
        tolerance = alignmentTolerance
    end
    vector = vec3(vector):normalize()
    local targetVec = (vec3() - vector)
    yawAmount = -getMagnitudeInDirection(targetVec, C.getWorldOrientationRight()) * autopilotStrength
    pitchAmount = -getMagnitudeInDirection(targetVec, C.getWorldOrientationUp()) * autopilotStrength
    if previousYawAmount == 0 then previousYawAmount = yawAmount / 2 end
    if previousPitchAmount == 0 then previousPitchAmount = pitchAmount / 2 end
    -- Skip dampening at very low values, and force it to effectively overshoot so it can more accurately align back
    -- Instead of taking literal forever to converge
    if mabs(yawAmount) < 0.1 then
        yawInput2 = yawInput2 - yawAmount * 2
    else
        yawInput2 = yawInput2 - (yawAmount + (yawAmount - previousYawAmount) * damping)
    end
    if mabs(pitchAmount) < 0.1 then
        pitchInput2 = pitchInput2 + pitchAmount * 2
    else
        pitchInput2 = pitchInput2 + (pitchAmount + (pitchAmount - previousPitchAmount) * damping)
    end


    previousYawAmount = yawAmount
    previousPitchAmount = pitchAmount
    yawInput = yawAmount
    pitchInput = pitchAmount

    -- Return true or false depending on whether or not we're aligned
    if mabs(yawAmount) < tolerance and (mabs(pitchAmount) < tolerance) then
        return true
    end
    return false
end
