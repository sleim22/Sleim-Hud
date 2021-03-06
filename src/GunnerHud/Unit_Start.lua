showWeapons = true --export: Shows Weapon Widgets in 3rd person
showShield = true --export: shows Shield Status
showAllies = true --export: adds info about allies
showThreats = true --export: adds info about Threats
printSZContacts = false --export: print new Contacs in Safezone, default off
printLocationOnContact = true --export: print own location on new target
showTime = true --export: Shows Time when new Targets enter radar range or leave
maxAllies = 10 --export: max Amount for detailed info about Allies, reduce if overlapping with threat info
tempRadarTime = 200 --export: temporary Radar time in seconds until it gets destroyed
probil = 0
targetSpeed = 0
oldSpeed = 0
targetDistance = 0
oldTargetDistance = 0
targetName = "TargetInfo"
speedChangeIcon = ""
distanceChangeIcon = ""
maxCoreStress = core.getMaxCoreStress()
venting = ""
stressBarHeight = "5"
newRadarContacts = {}
newRadarCounter = 0
newTargetId = 0
healthHtml = ""
alliesHtml = ""
threatsHtml = ""
html = ""
allies = {}
threats = {}
zone = construct.isInPvPZone()

radar = radar_1
if radar_size == 0 then
    system.print("Connect a space radar and run config again!")
    unit.exit()
end
if weapon_size == 0 then
    system.print("No Weapons connected")
    unit.exit()
end
local kSkipCharSet = { ["O"] = true, ["Q"] = true, ["0"] = true }
local kCharSet = {}

local function addRangeToCharSet(a, b)
    for i = a, b do
        local c = string.char(i)
        if not kSkipCharSet[c] then
            kCharSet[#kCharSet + 1] = c
        end
    end
end

-- 0 - 9
addRangeToCharSet(48, 57)
-- A - Z
addRangeToCharSet(65, 90)

local kCharSetSize = #kCharSet

local function getHash(x)
    if x == nil then
        return 0
    end
    x = ((x >> 16) ~ x) * 0x45d9f3b
    x = ((x >> 16) ~ x) * 0x45d9f3b
    x = (x >> 16) ~ x
    if x < 0 then x = ~x end
    return x
end

function getShortName(id)
    local seed = getHash(id) % 8388593
    local a = (seed * 653276) % 8388593
    local b = (a * 653276) % 8388593
    local c = (b * 653276) % 8388593
    return kCharSet[a % kCharSetSize + 1] .. kCharSet[b % kCharSetSize + 1] .. kCharSet[c % kCharSetSize + 1]
end

function seconds_to_clock(time_amount)
    local start_seconds = time_amount
    local start_minutes = math.modf(start_seconds / 60)
    local seconds = start_seconds - start_minutes * 60
    local start_hours = math.modf(start_minutes / 60)
    local minutes = start_minutes - start_hours * 60
    local start_days = math.modf(start_hours / 24)
    local hours = start_hours - start_days * 24
    local wrapped_time = { h = hours, m = minutes, s = seconds }
    if hours > 0 then
        return string.format('%02.f:%02.f:%02.f', wrapped_time.h, wrapped_time.m, wrapped_time.s)
    else
        return string.format('%02.f:%02.f', wrapped_time.m, wrapped_time.s)
    end
end

function WeaponWidgetCreate()
    if type(weapon) == 'table' and #weapon > 0 then
        local WeaponPanaelIdList = {}
        for i = 1, #weapon do
            if i % 2 ~= 0 then
                table.insert(WeaponPanaelIdList, system.createWidgetPanel(''))
            end
            local WeaponWidgetDataId = weapon[i].getWidgetDataId()
            local WeaponWidgetType = weapon[i].getWidgetType()
            system.addDataToWidget(WeaponWidgetDataId,
                system.createWidget(WeaponPanaelIdList[#WeaponPanaelIdList], WeaponWidgetType))
        end
    end
end

if showWeapons == true then
    WeaponWidgetCreate()
end

function getFriendlyDetails(id)
    owner = radar.getConstructOwnerEntity(id)
    if owner.id and owner.isOrganization then
        return system.getOrganization(owner.id).name
    end
    if owner.id and not owner.isOrganization then
        return system.getPlayerName(owner.id)
    end
    return ""
end

function printNewRadarContacts()
    if zone == 1 or printSZContacts then
        local newTargetCounter = 0
        for k, v in pairs(newRadarContacts) do
            if newTargetCounter > 10 then
                system.print("Didnt print all new Contacts to prevent overload!")
                break
            end
            newTargetCounter = newTargetCounter + 1
            newTargetName = "[" .. radar.getConstructCoreSize(v) ..
                "]-" .. getShortName(v) .. "- " .. radar.getConstructName(v)
            if showTime then
                newTargetName = newTargetName .. ' - Time: ' .. seconds_to_clock(system.getArkTime())
            end
            if radar and radar.hasMatchingTransponder(v) == 1 then
                newTargetName = newTargetName .. " - [Ally] Owner: " .. getFriendlyDetails(v)
                if not borderActive then
                    borderColor = "green"
                    borderWidth = 200
                    borderActive = true
                    unit.setTimer("cleanBorder", 1)
                end
            elseif radar.isConstructAbandoned(v) == 1 then
                newTargetName = newTargetName .. " - Abandoned"
            else
                system.playSound("contact.mp3")
                if not borderActive then
                    borderActive = true
                    borderColor = "red"
                    borderWidth = 200
                    unit.setTimer("cleanBorder", 1)
                end
            end
            system.print("New Target: " .. newTargetName)
            if printLocationOnContact then
                system.print(system.getWaypointFromPlayerPos())
            end
        end
        newRadarContacts = {}
    else
        newRadarContacts = {}
    end
end

function getMaxCorestress()
    if maxCoreStress > 1000000 then
        maxCoreStress = string.format('%0.3f', (maxCoreStress / 1000000)) .. "M"
    elseif maxCoreStress > 1000 then
        maxCoreStress = string.format('%0.2f', (maxCoreStress / 1000)) .. "k"
    end
    system.print("Max Core Stress: " .. maxCoreStress)
end

function drawShield()
    shieldHp = shield_1.getShieldHitpoints()
    shieldPercent = shieldHp / shieldMax * 100
    if shieldPercent == 100 then shieldPercent = "100"
    else
        shieldPercent = string.format('%0.2f', shieldPercent)
    end
    coreStressPercent = string.format('%0.2f', core.getCoreStressRatio() * 100)
    local shieldHealthBar = [[
                    <style>
                    .health-bar {
                        position: fixed;
                        width: 13em; 
                        padding: 1vh; 
                        bottom: 5vh;
                        left: 50%;
                        transform: translateX(-50%);
                        text-align: center;
                        background: #142027;
                        opacity: 0.8;
                        color: white;
                        font-family: "Lucida" Grande, sans-serif;
                        font-size: 1.5em;
                        border-radius: 5vh;
                        border: 0.2vh solid;
                        border-color: #098dfe;
                    }
                    .bar {
                        padding: 5px;
                        border-radius: 5vh;
                        background: #09c3fe;
                        opacity: 0.8;
                        width: ]] .. shieldPercent .. [[%;
                        height: 40px;
                        position: relative;
                    }


                    </style>
                    <html>
                        <div class="health-bar">
                            <div class="bar">]] .. venting .. shieldPercent .. [[%</div>
                        </div>
                    </html>
                    ]]
    local coreStressBar = [[
                    <style>
                    .stress-health-bar {
                        position: fixed;
                        width: 13em; 
                        padding: 1vh; 
                        bottom:]] .. stressBarHeight .. [[vh;
                        left: 50%;
                        transform: translateX(-50%);
                        text-align: center;
                        background: #142027;
                        opacity: 0.8;
                        color: white;
                        font-family: "Lucida" Grande, sans-serif;
                        font-size: 1.5em;
                        border-radius: 5vh;
                        border: 0.2vh solid;
                        border-color: #a00000;
                    }
                    .stress-bar {
                        padding: 5px;
                        border-radius: 5vh;
                        background: #ff0000;
                        opacity: 0.8;  
                        width: ]] .. coreStressPercent .. [[%;
                        height: 40px;
                        position: relative;
                    }


                    </style>
                    <html>
                        <div class="stress-health-bar">
                            <div class="stress-bar">]] .. coreStressPercent .. [[%</div>
                        </div>
                    </html>
                    ]]
    if shield_1.isVenting() == 1 then
        stressBarHeight = "15"
        venting = "Venting "
        healthHtml = coreStressBar .. shieldHealthBar
    elseif shield_1.getState() == 0 or shield_1.getShieldHitpoints() == 0 then
        stressBarHeight = "5"
        healthHtml = coreStressBar
    else
        stressBarHeight = "5"
        venting = ""
        healthHtml = shieldHealthBar
    end
end

requiredTargets = {}
function readRequiredValues()
    if autoTargets then
        requiredTargets = {}
        local targets = require("Targets")
        for _, v in pairs(targets) do
            local id = v.shortid[1]
            if id ~= targetCode then
                requiredTargets[#requiredTargets + 1] = v.shortid[1]
            end
        end
        package.loaded['Targets'] = nil

        local transponders = require("Transponder")
        local tablea = {}
        local i = 1

        for _, v in pairs(transponders) do
            local transtag = v.transponder[1]
            tablea[i] = v.transponder[1]
            i = i + 1
            transponder.setTags(tablea)
        end
        package.loaded['Transponder'] = nil
    end
end

if pcall(require, "Transponder") and pcall(require, "Targets") and transponder then
    unit.setTimer("loadRequired", 2)
end
specialRadarTargets = {}
function updateRadar(match)
    if radar_size > 1 then
        if radar_1 == radar and radar_1.getOperationalState() == -1 then radar = radar_2 end
        if radar_2 == radar and radar_2.getOperationalState() == -1 then radar = radar_1 end
    end
    allies = {}
    threats = {}
    specialRadarTargets = {}
    local data = radar.getWidgetData()
    if string.len(data) < 120000 then
        local constructList = data:gmatch('({"constructId":".-%b{}.-})')
        local list = {}
        for str in constructList do
            local id = tonumber(str:match('"constructId":"([%d]*)"'))
            local tagged = radar.hasMatchingTransponder(id) == 0 and true or false
            if radar and radar.hasMatchingTransponder(id) == 1 then
                allies[#allies + 1] = id
            end
            if radar.getThreatRateFrom(id) > 1 then
                threats[#threats + 1] = id
            end
            local ident = radar.isConstructIdentified(id) == 1
            local randomid = getShortName(id)
            str = string.gsub(str, 'name":"', 'name":"' .. randomid .. ' - ')
            if match and tagged then
                list[#list + 1] = str
            elseif not match and not tagged then
                list[#list + 1] = str
            end
            if targetCode == randomid then
                table.insert(specialRadarTargets, 1, str)
            end

            for i = 1, #requiredTargets do
                local requiredTarget = requiredTargets[i]

                if requiredTarget == randomid then
                    table.insert(specialRadarTargets, str)
                end
            end

            if not specialRadar and #specialRadarTargets > 0 then
                specialRadar = true
                specialTargetRadar()
            end

        end
        return '{"constructsList":[' .. table.concat(list, ',') .. '],' .. data:match('"elementId":".+')
    end
end

radarOnlyEnemeies = true
fm = 'Enemies'
rf = ''
FCS_locked = false
local _data = updateRadar(radarOnlyEnemeies)

local _panel = system.createWidgetPanel("RADAR")
local _widget = system.createWidget(_panel, "value")
radarFilter = system.createData('{"label":"Filter","' .. fm .. '' .. rf .. '","unit": ""}')
system.addDataToWidget(radarFilter, _widget)
local _widget = system.createWidget(_panel, "radar")
radarData = system.createData(_data)
system.addDataToWidget(radarData, _widget)

specialRadar = false
function specialTargetRadar()
    local widgetTitel = "Targets"
    if autoTargets then widgetTitel = widgetTitel .. " - AutoMode" end
    specialTimer = 0
    unit.setTimer("specialR", 0.1)
    local data = radar.getWidgetData()
    local _dataS = '{"constructsList":[' .. table.concat(specialRadarTargets, ',') .. '],' ..
        data:match('"elementId":".+')
    _panelS = system.createWidgetPanel(widgetTitel)
    local _widgetS = system.createWidget(_panelS, "radar")
    radarDataS = system.createData(_dataS)
    system.addDataToWidget(radarDataS, _widgetS)
end

allyAmount = 0
function getAlliedInfo()
    local htmlAllies = ""
    allyAmount = #allies
    local tooMany = false
    if allyAmount > maxAllies then tooMany = true end
    for i = 1, #allies do
        if i < (maxAllies + 1) then
            local id = allies[i]
            local allyShipInfo = "[" ..
                radar.getConstructCoreSize(id) .. "]-" .. getShortName(id) .. "- " .. radar.getConstructName(id)
            local owner = getFriendlyDetails(id)
            htmlAllies = htmlAllies .. [[<tr>
                                <td>]] .. allyShipInfo .. [[</td>
                                <td>]] .. owner .. [[</td>
                                </tr>]]
        end
    end
    if tooMany then
        htmlAllies = htmlAllies .. [[<tr>
                                <td colspan="2">Plus ]] .. (allyAmount - maxAllies) .. [[ more allies</td>
                                </tr>]]
    end
    return htmlAllies
end

function alliesHead()
    if allyAmount == 0 then
        return ""
    else
        local alliesHead = [[<tr>
                      <th style="width:90%">ShipInfo</th>
                      <th style="width:10%">Owner</th>
                    </tr>]]
        return alliesHead
    end
end

function drawAlliesHtml()
    alliesHtml = [[
                    <html>
                        <div class="allies">
                        <table class="customTable">
                            <thead>
                                <h2>Targets: ]] .. (#radar.getConstructIds() - allyAmount) .. [[</h2><br>
                                <h2>Allies: ]] .. allyAmount .. [[</h2><br>]] .. alliesHead() .. [[</thead>
                            <tbody>]] .. getAlliedInfo() .. [[</tbody>
                        </table></div>
                    </html>]]
end

function drawThreatsHtml()
    threatsAmount = #threats
    function threatsHead()
        if threatsAmount == 0 then
            return ""
        else
            local threatsHead = [[
                            <tr>
                                <th style="width:90%">ShipInfo</th>
                                <th style="width:10%">Threat Lvl</th>
                            </tr>]]
            return threatsHead
        end
    end

    function getThreatsInfo()
        local threatInfo = ""
        for i = 1, threatsAmount do
            local id = threats[i]
            local threatDist = radar.getConstructDistance(id)

            if threatDist < 1000 then
                threatDist = string.format('%0.2f', threatDist) .. "m"
            elseif threatDist < 100000 then
                threatDist = string.format('%0.2f', threatDist / 1000) .. "km"
            else
                threatDist = string.format('%0.2f', threatDist / 200000) .. "su"
            end
            local threatShipInfo = "[" ..
                radar.getConstructCoreSize(id) ..
                "]-" .. getShortName(id) .. "- " .. radar.getConstructName(id) .. " - " .. threatDist
            local threat = radar.getThreatRateFrom(id)
            local threatRateString = { "None", "Identified", "Stopped shooting", "Threatened", "Attacked" }
            local color = "red"
            if threat == 1 or threat == 2 then
                color = "orange"
            end
            threatInfo = threatInfo .. [[<tr style=color:]] .. color .. [[>
                                    <td>]] .. threatShipInfo .. [[</td>
                                    <td>]] .. threatRateString[threat] .. [[</td>
                                    </tr>]]
        end
        return threatInfo
    end

    threatsHtml = [[
                    <div class="locked">
                        <table class="customTable">
                            <thead>
                                <h2 style="color:red;text-align:right">Threats: ]] ..
        threatsAmount .. [[</h2><br>]] .. threatsHead() .. [[
                                <tbody>]] .. getThreatsInfo() .. [[</tbody>
                        </table>
                    </div>]]
end

cssAllyLocked = [[<style>
                    .allies {
                        position: fixed;
                        top: 25px;
                        width: 15%;
                        color: white;
                    }
                    .locked {
                        position: fixed;
                        top: 14%;
                        right: 20px;
                        width: 15%;
                        color: red;
                    }
                    table.customTable {
                        border-collapse: collapse;
                        border-width: 2px;
                        background: #142027;
                        opacity: 0.8;
                        font-family: "Lucida" Grande, sans-serif;
                        font-size: 12px;
                        border-radius: 5px;
                        border: 0.2vh solid;
                        border-color: #098dfe
                    }

                    table.customTable td, table.customTable th {
                        border-width: 2px;
                        border-color: #7EA8F8;
                        border-style: solid;
                        border-radius: 5px;
                        padding: 5px;
                    }
                    .h2{
                        font-family: "Lucida" Grande, sans-serif;
                    }

                    </style>]]

ownShipId = construct.getId()
ownShipName = construct.getName()
own3Letter = getShortName(ownShipId)
ownInfoHtml = [[
                <style>
                .ownShipInfo{
                    font-family: "Lucida" Grande, sans-serif;
                    position: fixed;
                    bottom: 10px;
                }
                </style>
                <div class="ownShipInfo">
                    <h4>]] .. ownShipId .. " [" .. own3Letter .. "] " .. ownShipName .. [[<h4>
                </div>
                ]]
if shield_1 and showShield then
    shieldMax = shield_1.getMaxShieldHitpoints()
    drawShield()
end
if showAllies then
    drawAlliesHtml()
end
borderWidth = 0
borderColor = "red"
borderActive = false
function alarmBorder()
    alarmStyles = [[<style>
                   .alarmBorder {
                    width:100%;
                    height:100%;
                    box-shadow: 0 0 ]] .. borderWidth .. [[px 0px ]] .. borderColor .. [[ inset;
                    }</style>
                    <html class='alarmBorder'></html>]]
end

function comma_value(amount)
    local formatted = amount
    while true do
        formatted, k = string.gsub(formatted, "^(-?%d+)(%d%d%d)", '%1,%2')
        if (k == 0) then
            break
        end
    end
    return formatted
end

local enemyInfoDmg = "";
dmgTable = {}
local dmgDone = 0;
local dmgDoneFormatted = "0";
local dmgPercent = 0;

function addDmgToTable(id, dmg)
    if not calculating then
        calculating = true
        unit.setTimer("DPS", 1)
    end
    local prevDmg = dmgTable[id]
    if prevDmg == nil then
        dmgTable[id] = dmg
    else
        dmgTable[id] = prevDmg + dmg
    end
end

counter = 1
dpsTable = {}
dps = "~"
ttTenMil = 0
ttTenMilString = "--:--"
calculating = false
lastDmgValue = 0
function enemyDPS()
    local incDmg = 0
    local newDmgValue = dmgTable[radar.getTargetId()] or 0
    local diff = newDmgValue - lastDmgValue
    if diff < 0 then
        unit.stopTimer("DPS")
        dpsTable = {}
        counter = 1
        dps = "~"
        ttTenMil = 0
        ttTenMilString = "--:--"
        calculating = false
        lastDmgValue = 0
    end
    dpsTable[counter] = diff
    counter = counter + 1
    lastDmgValue = newDmgValue
    local dpsTableLenght = #dpsTable
    for i = 1, dpsTableLenght do
        incDmg = incDmg + dpsTable[i]
    end

    if counter > 60 then
        counter = 1
    end
    if dpsTableLenght > 10 then
        dps = incDmg / dpsTableLenght
        if counter % 5 == 0 then
            ttTenMil = (10000000 - newDmgValue) / dps
            ttTenMilString = "~" .. seconds_to_clock(ttTenMil)
        elseif ttTenMil > 0 then
            ttTenMil = ttTenMil - 1
            ttTenMilString = "~" .. seconds_to_clock(ttTenMil)
        end
        if ttTenMil < 0 then ttTenMilString = "" end
        dps = round(dps / 1000, 2) .. "k"
    end
    if incDmg < 1 and dpsTableLenght == 60 then
        unit.stopTimer("DPS")
        dpsTable = {}
        counter = 1
        dps = "~"
        ttTenMil = 0
        ttTenMilString = "--:--"
        calculating = false
        lastDmgValue = 0
    end
end

function round(num, numDecimalPlaces)
    local mult = 10 ^ (numDecimalPlaces or 0)
    return math.floor(num * mult + 0.5) / mult
end

function drawEnemyInfoDmgBar()
    local targetId = radar.getTargetId()

    if targetId == 0 or radar.isConstructIdentified(targetId) == 0 then
        enemyInfoDmg = "";
    else

        dmgDone = dmgTable[targetId] or 0;
        dmgPercent = (dmgDone / 100000)
        if dmgPercent > 100 then dmgPercent = 100 end
        if dmgDone > 1000000 then
            dmgDoneFormatted = string.format('%0.2f', (dmgDone / 1000000)) .. "M"
        elseif dmgDone > 1000 then
            dmgDoneFormatted = string.format('%0.2f', (dmgDone / 1000)) .. "k"
        else
            dmgDoneFormatted = "0"
        end
        targetDistance = math.floor(radar.getConstructDistance(targetId))
        targetName = "[" ..
            radar.getConstructCoreSize(targetId) .. "]-" ..
            getShortName(targetId) .. "- " .. radar.getConstructName(targetId)
        targetSpeed = math.floor(radar.getConstructSpeed(targetId) * 3.6)
        if targetSpeed > oldSpeed then
            speedChangeIcon = "???"
        elseif targetSpeed < oldSpeed then
            speedChangeIcon = "???"
        else
            speedChangeIcon = ""
        end

        if targetDistance > oldTargetDistance then
            distanceChangeIcon = "???"
        elseif targetDistance < oldTargetDistance then
            distanceChangeIcon = "???"
        else
            distanceChangeIcon = ""
        end
        oldTargetDistance = targetDistance
        oldSpeed = targetSpeed

        if targetDistance < 1000 then
            distanceUnit = "m"
        elseif targetDistance < 100000 then
            targetDistance = targetDistance / 1000
            distanceUnit = "km"
        else
            targetDistance = targetDistance / 200000
            distanceUnit = "su"
        end
        probil = round(weapon_1.getHitProbability(), 4) * 100
        enemyInfoDmg = [[<style>
                        .enemyInfoCss {
                            position: fixed;
                            top: 8%;
                            left: 50%;
                            transform: translateX(-50%);
                            width: 500px;
                            color: #80ffff;
                        }
                    
                        .dmg-bar {
                            background: #142027;
                            color: white;
                            font-size: 10px;
                            border-radius: 5vh;
                            border: 1px solid;
                            border-color: #098dfe;
                        }
                    
                        .dmgBarFullness {
                            padding: 5px;
                            border-radius: 5vh;
                            height: 95%;
                        }
                    
                        table.dmgBar {
                            table-layout: fixed;
                            border-spacing: 0 0px;
                            border-collapse: separate;
                        }
                    
                        table.dmgBar td {
                            width: 110px;
                        }
                    </style>
                    <div class="enemyInfoCss">
                        <table class="dmgBar">
                            <tr>
                                <th colspan=5>*]] .. targetName .. [[*</th>
                            </tr>

                            <tr>
                                <td colspan=5 style="padding: 0px;">
                                    <div class="dmg-bar">
                                        <div class="dmgBarFullness" style="width: ]] ..
            dmgPercent .. [[%;background:darkred;text-align: right;">]] .. dmgDoneFormatted .. [[</div>
                                    </div>
                                </td>

                            </tr>
                            <tr style="font-size: 12px;padding: 0px;">
                                <td colspan="2">0</td>
                                <td style="text-align: center;">5mil</td>
                                <td colspan="2" style="text-align: right;">10mil</td>
                            </tr>
                            <tr>
                                <td colspan="2"></td>
                                <td style="text-align: center;font-size: 18px;">Hitchance</td>
                                <td colspan="2"></td>

                            </tr>
                            <tr>
                                <td></td>
                                <td colspan="3">
                                    <div class="dmg-bar">
                                        <div class="dmgBarFullness" style="width: ]] ..
            probil .. [[%;background:gray;text-align: center;">
                                            ]] .. probil .. [[%</div>
                                    </div>
                                </td>
                                <td></td>

                            </tr>
                            <tr>
                                <td style="text-align: right;">]] ..
            distanceChangeIcon .. " " .. round(targetDistance, 2) .. distanceUnit .. [[</td>
                                <td style="text-align: right;">]] ..
            speedChangeIcon .. " " .. comma_value(targetSpeed) .. [[km/h</td>
                                <td></td>
                                <td>]] .. dps .. [[ dps</td>
                                <td>]] .. ttTenMilString .. [[</td>
                            </tr>
                        </table>
                    </div>
                                        ]]
    end
end

screenHeight = system.getScreenHeight()
screenWidth = system.getScreenWidth()
function crossHair()
    local l = targetDistance
    if l < 100000 then l = 100000 end
    local pcrossHair = vec3(construct.getWorldPosition()) + l * vec3(construct.getWorldForward())
    local ocrossHair = library.getPointOnScreen({ pcrossHair['x'], pcrossHair['y'], pcrossHair['z'] })
    return [[<svg width="100%" height="100%" style="position: absolute;left:0%;top:0%;font-family: Calibri;">
    <circle cx="]] ..
        screenWidth * ocrossHair[1] ..
        [[" cy="]] ..
        screenHeight * ocrossHair[2] .. [[" r="5" stroke="gray" stroke-width="2" style="fill-opacity:0" />
    </svg> 
                    ]]
end

alliesAR = ""
function drawAlliesOnScreen()
    if lshiftPressed then
        alliesAR = [[<svg width="100%" height="100%" style="position: absolute;left:0%;top:0%;font-family: Calibri;">]]
        for _, v in ipairs(allies) do
            local point = vec3(radar.getConstructWorldPos(v))
            local allyPosOnScreen = library.getPointOnScreen({ point['x'], point['y'], point['z'] })
            local x = screenWidth * allyPosOnScreen[1]
            local y = screenHeight * allyPosOnScreen[2]
            if x > 0 and y > 0 then
                alliesAR = alliesAR ..
                    [[<circle cx="]] ..
                    x ..
                    [[" cy="]] ..
                    y ..
                    [[" r="5" stroke="green" stroke-width="2" style="fill-opacity:0" /><text x="]] ..
                    x + 10 .. [[" y="]] .. y + 10 .. [[" fill="white">]] .. getFriendlyDetails(v) .. [[</text>]]
            end
        end
        alliesAR = alliesAR .. "</svg>"
    else
        alliesAR = ""
    end
end

function drawHud()
    html = alarmStyles ..
        cssAllyLocked ..
        healthHtml .. alliesHtml .. threatsHtml .. ownInfoHtml .. enemyInfoDmg .. crossHair() ..
        alliesAR
    system.setScreen(html)
end

getMaxCorestress()
system.setScreen(html)
system.showScreen(1)
unit.setTimer("hud", 0.1)
unit.setTimer("radar", 0.4)
unit.setTimer("clean", 30)
