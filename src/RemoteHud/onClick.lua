local x = system.getMousePosX()
local y = system.getMousePosY()
if x > ShieldDisplay.startX and x < ShieldDisplay.startX + ShieldDisplay.totalWidth and leftAltPressed then
    local xClicked = round((x - ShieldDisplay.startX - 30) / (ShieldDisplay.resBarWidth) * ShieldRes.maxPool, 2)
    if xClicked < 0 then xClicked = 0 end

    -- AM bar
    if y > ShieldDisplay.startY + ShieldDisplay.barStart + ShieldDisplay.barMargin and
        y < ShieldDisplay.startY + ShieldDisplay.barStart + ShieldDisplay.barMargin + 10 then
        local remaining = ShieldRes.maxPool - (ShieldRes[2][1] + ShieldRes[3][1] + ShieldRes[4][1])
        if xClicked <= remaining then
            ShieldRes[1][1] = xClicked
        else
            ShieldRes[1][1] = remaining
        end
    end

    -- EM bar
    if y > ShieldDisplay.startY + ShieldDisplay.barStart + ShieldDisplay.barMargin * 2 and
        y < ShieldDisplay.startY + ShieldDisplay.barStart + ShieldDisplay.barMargin * 2 + 10 then
        local remaining = ShieldRes.maxPool - (ShieldRes[1][1] + ShieldRes[3][1] + ShieldRes[4][1])
        if xClicked <= remaining then
            ShieldRes[2][1] = xClicked
        else
            ShieldRes[2][1] = remaining
        end
    end

    -- KI bar
    if y > ShieldDisplay.startY + ShieldDisplay.barStart + ShieldDisplay.barMargin * 3 and
        y < ShieldDisplay.startY + ShieldDisplay.barStart + ShieldDisplay.barMargin * 3 + 10 then
        local remaining = ShieldRes.maxPool - (ShieldRes[1][1] + ShieldRes[2][1] + ShieldRes[4][1])
        if xClicked <= remaining then
            ShieldRes[3][1] = xClicked
        else
            ShieldRes[3][1] = remaining
        end
    end

    -- TH bar
    if y > ShieldDisplay.startY + ShieldDisplay.barStart + ShieldDisplay.barMargin * 4 and
        y < ShieldDisplay.startY + ShieldDisplay.barStart + ShieldDisplay.barMargin * 4 + 10 then
        local remaining = ShieldRes.maxPool - (ShieldRes[1][1] + ShieldRes[2][1] + ShieldRes[3][1])
        if xClicked <= remaining then
            ShieldRes[4][1] = xClicked
        else
            ShieldRes[4][1] = remaining
        end
    end

    -- buttons
    if y > ShieldDisplay.startY + ShieldDisplay.barStart + ShieldDisplay.barMargin * 5 and
        y < ShieldDisplay.startY + ShieldDisplay.barStart + ShieldDisplay.barMargin * 5 + 40 then
        -- Set Button
        if x > ShieldDisplay.startX + 30 * ShieldDisplay.resFactorX and
            x < ShieldDisplay.startX + 30 * ShieldDisplay.resFactorX + 50 * ShieldDisplay.resFactorX then
            local currentRes = shield.getResistances()
            if not
                (
                    currentRes[1] == ShieldRes[1][1] and currentRes[2] == ShieldRes[2][1] and
                    currentRes[3] == ShieldRes[3][1] and
                    currentRes[4] == ShieldRes[4][1]) then
                local setWorked = shield.setResistances(ShieldRes[1][1], ShieldRes[2][1], ShieldRes[3][1],
                    ShieldRes[4][1])
                if setWorked == 0 then system.print("Failed to set Resistances") end
            end
        end

        -- Reset
        if x > ShieldDisplay.startX + 90 * ShieldDisplay.resFactorX and
            x < ShieldDisplay.startX + 90 * ShieldDisplay.resFactorX + 50 * ShieldDisplay.resFactorX then
            for i = 1, 4, 1 do
                ShieldRes[i][1] = 0
            end
        end

        -- autoadjust
        if x > ShieldDisplay.startX + 150 * ShieldDisplay.resFactorX and
            x < ShieldDisplay.startX + 150 * ShieldDisplay.resFactorX + 65 * ShieldDisplay.resFactorX then
            autoAdjustShield = not autoAdjustShield
        end

        -- Vent
        if x > ShieldDisplay.startX + ShieldDisplay.resBarWidth + ShieldDisplay.textMargin * 2 and
            x <
            ShieldDisplay.startX + ShieldDisplay.resBarWidth + ShieldDisplay.textMargin * 2 +
            80 * ShieldDisplay.resFactorX then
            if not shield.isVenting() and shield.getShieldHitpoints() < shield.getMaxShieldHitpoints() then
                local started = shield.startVenting()
                if started then
                    unit.stopTimer("dps")
                    dpmTable = {}
                    counter = 1
                    dps = "Calculating"
                    ttZ = 0
                    ttZString = "Calculating"
                    calculating = false
                end
            else
                shield.stopVenting()
            end
        end
    end

    local used = ShieldRes[1][1] + ShieldRes[2][1] + ShieldRes[3][1] + ShieldRes[4][1]

    if math.floor(ShieldRes.maxPool * 100) == math.floor(used * 100) then
        ShieldRes.currentPool = 0
    else
        ShieldRes.currentPool = ShieldRes.maxPool - used
    end
end
