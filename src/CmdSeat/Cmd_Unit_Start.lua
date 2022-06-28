
                pitchInput = 0
                rollInput = 0
                yawInput = 0
                brakeInput = 1
                unit.hide()
                Nav = Navigator.new(system, core, unit)
                Nav.axisCommandManager:setupCustomTargetSpeedRanges(axisCommandId.longitudinal, {1000, 5000, 10000, 20000, 30000})
                Nav.axisCommandManager:setTargetGroundAltitude(4)


                isBraking = true
                alarm = false
                system.showHelper(0)
                showWeapons = true --export: Shows Weapon Widgets in 3rd person
                showShield = true --export: shows Shield Status
                showAllies = true --export: adds info about allies
                showThreats = true --export: adds info about Threats
                printSZContacts = false --export: print new Contacs in Safezone, default off
                printLocationOnContact = true --export: print own location on new target
                showTime = true --export: Shows Time when new Targets enter radar range or leave
                maxAllies = 10 --export: max Amount for detailed info about Allies, reduce if overlapping with threat info
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
                        for i=a,b do
                            local c = string.char(i)
                               if not kSkipCharSet[c] then
                                   kCharSet[#kCharSet+1] = c
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
                    local seed = getHash(id)%8388593
                    local a = (seed*653276)%8388593
                    local b = (a*653276)%8388593
                    local c = (b*653276)%8388593
                    return kCharSet[a%kCharSetSize+1] .. kCharSet[b%kCharSetSize+1] .. kCharSet[c%kCharSetSize+1]
                end

                function WeaponWidgetCreate()
                        if type(weapon) == 'table' and #weapon > 0 then
                            local WeaponPanaelIdList = {}
                            for i = 1, #weapon do
                                if i%2 ~= 0 then
                                table.insert(WeaponPanaelIdList, system.createWidgetPanel(''))
                                end
                                local WeaponWidgetDataId = weapon[i].getWidgetDataId()
                                local WeaponWidgetType = weapon[i].getWidgetType()
                                system.addDataToWidget(WeaponWidgetDataId, system.createWidget(WeaponPanaelIdList[#WeaponPanaelIdList], WeaponWidgetType))
                            end
                    end
                end


                if showWeapons == true then 
                   WeaponWidgetCreate()
                end
                function createTargetInfoWidget()
                    panel = system.createWidgetPanel('Target-Info')
                    targetTitelWidget = system.createWidget(panel,"title")
                    targetHitChanceWidget = system.createWidget(panel,"gauge")
                    widgetValues = system.createWidget(panel, "value")

                    targetTitelData = system.createData('{"text": "TargetInfo"}')
                    targetHitChanceData = system.createData('{"percentage":"0"}')
                    hitChance = system.createData('{"label": "Hit Chance", "value": "0","unit":"%"}')
                    speed = system.createData('{"label": "Speed", "value": "0","unit":"km/h"}')
                    distance = system.createData('{"label": "Distance", "value": "0","unit":"km"}')

                    system.addDataToWidget(targetTitelData,targetTitelWidget)
                    system.addDataToWidget(hitChance, widgetValues)
                    system.addDataToWidget(targetHitChanceData,targetHitChanceWidget)
                    system.addDataToWidget(speed, widgetValues)
                    system.addDataToWidget(distance, widgetValues)
                end

                function getFriendlyDetails(id)
                    owner = radar.getConstructOwner(id)
                    if owner.organizationId > 0 then
                        return system.getOrganizationName(owner.organizationId)
                    end
                    if owner.playerId > 0 then
                        return system.getPlayerName(owner.playerId)
                    end
                    return ""
                end

                function printNewRadarContacts()
                    if not zone or printSZContacts then
                        local newTargetCounter = 0
                        for k,v in pairs(newRadarContacts) do
                            if newTargetCounter > 10 then
                                system.print("Didnt print all new Contacts to prevent overload!")
                            break end
                            newTargetCounter = newTargetCounter + 1
                            newTargetName = "["..radar.getConstructCoreSize(v).."]-"..getShortName(v).."- "..radar.getConstructName(v)
                            if showTime then
                                newTargetName = newTargetName..' - Time: '..seconds_to_clock(system.getArkTime())
                            end
                            if radar.hasMatchingTransponder(v) == 1 then
                                newTargetName = newTargetName.." - [Ally] Owner: "..getFriendlyDetails(v)
                                if not borderActive then
                                    borderColor = "green"
                                    borderWidth = 200
                                    borderActive = true
                                    unit.setTimer("cleanBorder",1)
                                end
                            else
                                system.playSound("contact.mp3")
                                if not borderActive then
                                    borderActive = true
                                    borderColor = "red"
                                    borderWidth = 200
                                    unit.setTimer("cleanBorder",1)
                                end
                            end
                            system.print("New Target: "..newTargetName)
                            if printLocationOnContact then
                                system.print(system.getWaypointFromPlayerPos())
                            end
                        end
                        newRadarContacts = {}
                    else
                        newRadarContacts = {}    
                    end
                end

                function updateTargetWidget()
                    targetId = radar.getTargetId()
                    if targetId == 0 then 
                        targetName = "No Target selected"
                        targetDistance = 0
                        speedChangeIcon = ""
                        distanceChangeIcon = ""
                    end
                    if radar.isConstructIdentified(targetId) == 1 then
                        targetDistance = math.floor(radar.getConstructDistance(targetId))
                        targetName = "["..radar.getConstructCoreSize(targetId).."]-"..getShortName(targetId).."- "..radar.getConstructName(targetId)
                        targetSpeed = math.floor(radar.getConstructSpeed(targetId) * 3.6)
                        if targetSpeed > oldSpeed then
                            speedChangeIcon = "↑"
                        elseif targetSpeed < oldSpeed then
                            speedChangeIcon = "↓"
                        else
                            speedChangeIcon = ""
                        end
                    
                        if targetDistance > oldTargetDistance then
                            distanceChangeIcon = "↑"
                        elseif targetDistance < oldTargetDistance then
                            distanceChangeIcon = "↓"
                        else
                            distanceChangeIcon = ""
                        end
                        oldTargetDistance = targetDistance
                        oldSpeed = targetSpeed
                    end
                    if targetDistance < 1000 then
                        distanceUnit= "m" 
                    elseif targetDistance < 100000 then
                        targetDistance = targetDistance/1000
                        distanceUnit = "km"
                    else
                        targetDistance = targetDistance/200000
                        distanceUnit= "su"
                    end
                    probil = math.floor(json.decode(weapon_1.getWidgetData()).properties.hitProbability * 100)
                    system.updateData(targetTitelData,'{"text": "'..targetName..'"}')
                    system.updateData(hitChance,'{"label": "Hit Chance", "value": "'..probil..'","unit":"%"}')
                    system.updateData(speed,'{"label": "Speed", "value": "'..speedChangeIcon..targetSpeed..'","unit":"km/h"}')
                    system.updateData(targetHitChanceData,'{"percentage":'..probil..'}')
                    system.updateData(distance,'{"label": "Distance", "value": "'..distanceChangeIcon..""..string.format('%0.2f',targetDistance)..'","unit":"'..distanceUnit..'"}')
                end

                function getMaxCorestress()
                    if maxCoreStress > 1000000 then
                         maxCoreStress = string.format('%0.3f',(maxCoreStress/1000000)).."M"
                    elseif maxCoreStress > 1000 then
                         maxCoreStress = string.format('%0.2f',(maxCoreStress/1000)).."k"    
                    end
                    system.print("Max Core Stress: "..maxCoreStress)
                end
                function updateRadar(match)
                    if radar_size > 1 and radar_1.isOperational()==0 then radar = radar_2 else radar = radar_1 end
                    allies={}
                    threats={}
                    local data = radar.getWidgetData()
                    if string.len(data) < 120000 then  
                        local constructList = data:gmatch('({"constructId":".-%b{}.-})') 
                        local list = {}
                        for str in constructList do
                            local id = tonumber(str:match('"constructId":"([%d]*)"'))
                            local tagged = radar.hasMatchingTransponder(id) == 0 and true or false
                            if radar.hasMatchingTransponder(id)==1 then
                                allies[#allies+1]=id
                            end
                            if radar.getThreatFrom(id) ~= "none" then
                                threats[#threats+1]=id
                            end 
                            local ident = radar.isConstructIdentified(id) == 1
                            local randomid = getShortName(id)
                            str = string.gsub(str, 'name":"', 'name":"'..randomid..' - ')

                            if match and tagged then
                                list[#list+1] = str
                            elseif not match and not tagged then
                                list[#list+1] = str
                            end               
                        end
                    return '{"constructsList":['..table.concat(list,',')..'],'..data:match('"elementId":".+')
                    end
                end
                radarOnlyEnemeies = true
                fm = 'Enemies'
                rf = ''
                FCS_locked = false
                local _data = updateRadar(radarOnlyEnemeies)
                    
                local _panel = system.createWidgetPanel("RADAR")
                local _widget = system.createWidget(_panel, "value")
                radarFilter = system.createData('{"label":"Filter","'..fm..''..rf..'","unit": ""}') 
                system.addDataToWidget(radarFilter, _widget)
                local _widget = system.createWidget(_panel, "radar")
                radarData = system.createData(_data) 
                system.addDataToWidget(radarData, _widget)

                allyAmount = 0
                function getAlliedInfo()
                    local htmlAllies = ""
                    allyAmount = #allies
                    local tooMany = false
                    if allyAmount > maxAllies then tooMany = true end    
                    for i=1, #allies do
                        if i < (maxAllies+1) then
                            local id = allies[i]
                            local allyShipInfo = "["..radar.getConstructCoreSize(id).."]-"..getShortName(id).."- "..radar.getConstructName(id)
                            local owner = getFriendlyDetails(id)
                            htmlAllies = htmlAllies..[[<tr>
                                <td>]]..allyShipInfo..[[</td>
                                <td>]]..owner..[[</td>
                                </tr>]]
                        end
                    end
                    if tooMany then
                        htmlAllies = htmlAllies..[[<tr>
                                <td colspan="2">Plus ]]..(allyAmount-maxAllies)..[[ more allies</td>
                                </tr>]]
                    end
                    return htmlAllies
                end
                function alliesHead()
                    if allyAmount == 0 then
                        return ""
                    else
                       local alliesHead =[[<tr>
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
                                <h2>Targets: ]]..(#radar.getConstructIds()-allyAmount)..[[</h2><br>
                                <h2>Allies: ]]..allyAmount..[[</h2><br>]]..alliesHead()..[[</thead>
                            <tbody>]]..getAlliedInfo()..[[</tbody>
                        </table></div>
                    </html>]]
                end
                function drawThreatsHtml()
                    threatsAmount = #threats
                    function threatsHead()
                        if threatsAmount == 0 then
                            return ""
                        else
                            local threatsHead =[[
                            <tr>
                                <th style="width:90%">ShipInfo</th>
                                <th style="width:10%">Threat Lvl</th>
                            </tr>]]
                            return threatsHead
                        end 
                    end
                    function getThreatsInfo()
                        local threatInfo = ""
                        for i=1,threatsAmount do
                            local id = threats[i]
                            local threatDist = radar.getConstructDistance(id)
                            
                            if threatDist < 1000 then
                                threatDist = string.format('%0.2f',threatDist).."m"
                            elseif threatDist < 100000 then
                                threatDist = string.format('%0.2f',threatDist/1000).."km"
                            else
                                threatDist = string.format('%0.2f',threatDist/200000).."su"
                            end
                            local threatShipInfo = "["..radar.getConstructCoreSize(id).."]-"..getShortName(id).."- "..radar.getConstructName(id).." - "..threatDist
                            local threat = radar.getThreatFrom(id)
                            local color = "red"
                            if threat == "identified" or threat == "threatened" then
                                color = "orange"
                            elseif threat == "threatened_identified" then
                                color = "red"
                                threat = "Stopped shooting"
                            end
                            threatInfo = threatInfo..[[<tr style=color:]]..color..[[>
                                    <td>]]..threatShipInfo..[[</td>
                                    <td>]]..threat..[[</td>
                                    </tr>]]
                        end
                        return threatInfo
                    end
                    
                    threatsHtml =[[
                    <div class="locked">
                        <table class="customTable">
                            <thead>
                                <h2 style="color:red;text-align:right">Threats: ]]..threatsAmount..[[</h2><br>]]..threatsHead()..[[
                                <tbody>]]..getThreatsInfo()..[[</tbody>
                        </table>
                    </div>]]
                end

                cssAllyLocked =[[<style>
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

                ownShipId = core.getConstructId()
                ownShipName = core.getConstructName()
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
                    <h4>]]..ownShipId.." ["..own3Letter.."] "..ownShipName..[[<h4>
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
                    box-shadow: 0 0 ]]..borderWidth..[[px 0px ]]..borderColor..[[ inset;
                    }</style>
                    <html class='alarmBorder'></html>]]
                end

                function brakeTroogle()
                    if isBraking then
                        isBraking = false
                        brakeInput = 0
                    else
                        isBraking = true
                        brakeInput = brakeInput + 1
                        local longitudinalCommandType = Nav.axisCommandManager:getAxisCommandType(axisCommandId.longitudinal)
                        if (longitudinalCommandType == axisCommandType.byTargetSpeed) then
                            local targetSpeed = Nav.axisCommandManager:getTargetSpeed(axisCommandId.longitudinal)
                            if (math.abs(targetSpeed) > constants.epsilon) then
                                Nav.axisCommandManager:updateCommandFromActionStart(axisCommandId.longitudinal, - utils.sign(targetSpeed))
                            end
                        end
                    end
                end

                function hideWarpDrive()
                    if warpdrive ~= nil then
                        if json.decode(warpdrive.getWidgetData()).destination ~= "Unknown" and json.decode(warpdrive.getWidgetData()).distance > 200000 then
                                warpdrive.show()
                        else
                                warpdrive.hide()
                        end
                    end
                end

                atlas = require('atlas')

                planetList = {}
                for k,nextPlanet in pairs(atlas[0]) do
                    if nextPlanet.type[1]=="Planet" then
                        planetList[#planetList+1]=nextPlanet
                        --system.print(nextPlanet.name[1])
                    end
                end

                function newGetClosestPipe(wp)
                    local pipeDistance
                    nearestDistance = nil
                    local nearestPipePlanet = nil
                    local pipeOriginPlanet = nil

                    for i=1,#planetList,1 do
                        for k=#planetList,i+1,-1 do
                            originPlanet = planetList[i]
                            nextPlanet = planetList[k]
                            local distance = getPipeDistance(vec3(originPlanet.center), vec3(nextPlanet.center),wp)
                            if (nearestDistance == nil or distance < nearestDistance) then
                                nearestPipePlanet = nextPlanet
                                nearestDistance = distance
                                pipeOriginPlanet = originPlanet
                            end
                            --system.print(planetList[i].name[1].."-"..planetList[k].name[1])
                        end
                    end
                    pipeDistance = getDistanceDisplayString(nearestDistance)
                    return pipeOriginPlanet.name[1],nearestPipePlanet.name[1],pipeDistance
                end

                function round(num, numDecimalPlaces)
                  local mult = 10^(numDecimalPlaces or 0)
                  return math.floor(num * mult + 0.5) / mult
                end


                function getDistanceDisplayString(distance) 
                    local su = distance > 100000       
                    if su then
                        -- Convert to SU
                        return round(distance / 1000 / 200, 2).."SU"
                    elseif distance < 1000 then
                        return round(distance, 2).."M"
                    else
                        -- Convert to KM
                        return round(distance / 1000, 2).."KM"
                    end
                end


                function getCurrentBody()
                    local coordinates = core.getConstructWorldPos()
                    local minDistance2, body
                    local coord = vec3(coordinates)
                    for i, v in pairs(atlas[0]) do
                        local distance2 = (vec3(v.center) - coord):len2()
                        if (not body or distance2 < minDistance2) then -- Never return space.  
                            body = v
                            minDistance2 = distance2
                        end
                    end
                    return body
                end


                function safeZone(WorldPos)
                    local safeWorldPos = vec3({13771471,7435803,-128971})
                    local safeRadius = 18000000
                    local szradius = 500000
                    local currentBody = getCurrentBody()
                    local distsz, distp = math.huge
                     local mabs = math.abs
                    local szsafe 
                    distsz = vec3(WorldPos):dist(safeWorldPos)
                    if distsz < safeRadius then
                        return true, mabs(distsz - safeRadius)
                    end
                    distp = vec3(WorldPos):dist(vec3(currentBody.center))
                    if distp < szradius then szsafe = true else szsafe = false end
                    if mabs(distp - szradius) < mabs(distsz - safeRadius) then 
                        return szsafe, mabs(distp - szradius)
                    else
                        return szsafe, mabs(distsz - safeRadius)
                    end
                end

                function getPipeDistance(origCenter, destCenter,pos) 
                    local pipeDistance
                    local worldPos = vec3(pos)
                    local pipe = (destCenter - origCenter):normalize()
                    local r = (worldPos -origCenter):dot(pipe) / pipe:dot(pipe)

                    if r <= 0. then
                        pipeDistance = (worldPos-origCenter):len()
                                return pipeDistance
                    elseif r >= (destCenter - origCenter):len() then
                        pipeDistance =(worldPos-destCenter):len()
                               return pipeDistance
                    else
                        local L = origCenter + (r * pipe)
                        pipeDistance =  (L - worldPos):len()
                        return pipeDistance
                    end        
                end

                function updatePipeInfo()
                    currentPos = core.getConstructWorldPos()
                    local notPvPZone, pvpDist = safeZone(currentPos)
                    local o,p,d = newGetClosestPipe(currentPos)
                    return o,p,d,notPvPZone,pvpDist
                end
                function drawPipeInfo()
                                    local zone = ""
                                    local originPlanet,pipePlanet,pipeDist,notPvPZone,pvpDist=updatePipeInfo()
                                    if notPvPZone then
                                        zone = "PvP"
                                    else
                                        zone = "Safe"
                                    end
                                    pvpDist = getDistanceDisplayString(pvpDist)
                                    pipeInfoHtml = [[
                                    <style>
                                        .pipeInfo{
                                            position: fixed;
                                            top: 10px;
                                            left: 50%;
                                            transform: translateX(-50%);
                                            text-align: center;
                                            margin-bottom: 20px;
                                        }
                                    </style>
                                    <div class="pipeInfo">
                                        <h1>]]..originPlanet.." - "..pipePlanet..[[: ]]..pipeDist..[[</h1>
                                        <h2>]]..zone..[[ Zone in: ]]..pvpDist..[[<h2>
                                    </div>
                                    ]]
                                end

                function alarmBorder()
                    local alarm = [[
                   <style>
                   .blood {
                    width:100%;
                    height:100%;
                    box-shadow: 0 0 0px 0px red inset;
                    animation:blinking 0.3s 1;
                }

                                    @keyframes blinking{
                                    0%{   box-shadow: 0 0 0px 0px red inset;  }
                                    100%{  box-shadow: 0 0 200px 10px red inset;   }
                                    }
                }
                </style>
                <html class="blood"></html>]]
                system.setScreen(alarm)
                end
                function drawFuelInfo()
                    local fuelCSS=[[<style>
                    .fuelInfo {
                        position: fixed;
                        bottom: 40px;
                        left: 28%;
                        witdh: 200px;
                    }
                    .fuel-bar {
                        text-align: center;
                        background: #142027;
                        color: white;
                        font-family: "Lucida" Grande, sans-serif;
                        font-size: 10px;
                        border-radius: 5vh;
                        border: 1px solid;
                        border-color: #098dfe;
                    }
                    .barFullness {
                        padding: 5px;
                        border-radius: 5vh;
                        height: 95%;
                        position: center;
                        text-align: left;
                    }
                    </style>]]

                    function addFuelTank(tank,i)
                        local color = "green"
                        local percent = json.decode(tank.getWidgetData()).percentage
                         if percent == nil then 
                                            percent = 0 
                                            color = "red"
                                        elseif percent < 15 then
                                            color = "red" 
                                        elseif percent < 50 then
                                            color = "orange"
                                        end
                        return [[
                       <tr><td style="width:200px"><div class="fuel-bar">
                            <div class="barFullness" style="width: ]]..percent..[[%;
                        background:]]..color..[[;">]]..percent..[[%</div>
                        </div></td></tr>
                    ]]
                    end
                    
                    fuelHtml = fuelCSS..[[<table class="fuelInfo">
                        ]]
                    if spacefueltank_size > 0 then
                            fuelHtml = fuelHtml..[[<tr>
                            <th>Space</th>
                        </tr>]]
                    end
                    for i=1,#spacefueltank do
                        
                        fuelHtml = fuelHtml..addFuelTank(spacefueltank[i],i)
                    end
                    if atmofueltank_size > 0 then
                            fuelHtml = fuelHtml..[[<tr>
                            <th>Atmo</th>
                        </tr>]]
                    end
                    
                    for i=1,#atmofueltank do
                        fuelHtml = fuelHtml..addFuelTank(atmofueltank[i],i)
                    end

                    if rocketfueltank_size > 0 then
                            fuelHtml = fuelHtml..[[<tr>
                            <th>Rocket</th>
                        </tr>]]
                    end
                    
                    for i=1,#rocketfueltank do
                        fuelHtml = fuelHtml..addFuelTank(rocketfueltank[i],i)
                    end
                    fuelHtml = fuelHtml.."</table></div>"
                end

                function brakeHud()
                    if isBraking then
                    brakeHtml = [[
                        <style>
                        .brake{
                            position: fixed;
                            left: 50%;
                            bottom: 25%;
                            transform: translateX(-50%); 
                            text-align: center;
                            color: red;
                            text-shadow: 2px 2px 2px black;
                        }
                        </style>
                        <h1><div class="brake">Brake Engaged</div></h1>
                    ]]
                    else
                        brakeHtml = ""
                    end
                end
                function speedInfo()
                                    local throttle = math.floor(unit.getThrottle())
                                    local speed = math.floor(vec3(core.getWorldVelocity()):len() * 3.6)
                                    local accel = math.floor((json.decode(unit.getWidgetData()).acceleration/9.80665)*10)/10
                                    local maxSpeed = math.floor(core.getMaxSpeed()*3.6)
                                    local c = 100000000 / 3600
                                    local m0 = core.getConstructMass()
                                    local v0 = vec3(core.getWorldVelocity())
                                    local controllerData = json.decode(unit.getWidgetData())
                                    local maxBrakeThrust = controllerData.maxBrake
                                    local time = 0.0
                                    dis = 0.0
                                    local v = v0:len()
                                    while v>1.0 do
                                      time = time + 1
                                      local m = m0 / (math.sqrt(1 - (v * v) / (c * c)))
                                      local a = maxBrakeThrust / m
                                      if v > a then
                                        v = v - a --*1 sec
                                        dis = dis + v + a / 2.0
                                      elseif a ~= 0 then
                                        local t = v/a
                                        dis = dis + v * t + a*t*t/2
                                        v = v - a
                                      end
                                    end
                                    local resString = ""
                                    if dis > 100000 then
                                      resString = resString..string.format(math.floor((dis/200000) * 10)/10)
                                      brakeText = "SU"  
                                    elseif dis > 1000 then
                                      resString = resString..string.format(math.floor((dis/1000)*10)/10)
                                      brakeText = "KM"  
                                    else
                                      resString = resString..string.format(math.floor(dis))
                                      brakeText = "M"  
                                    end

                                    speedHtml = [[
                                        <style>
                                            h1,h6{
                                            color: #80ffff;
                                            }
                                        table.speed{
                                            position: fixed;
                                            table-layout: fixed;
                                            left: 60%;
                                            bottom: 35%;
                                            border-spacing: 0 10px;
                                            border-collapse: separate;
                                            }
                                        table.speed td{
                                            width: 110px;
                                        }          
                                        </style>
                                            <table class="speed">
                                                <tr>
                                                    <td style="text-align: right;"><h1>]]..throttle..[[</h1></td>
                                                    <td>%</td>
                                                </tr>
                                                <tr>
                                                    <td style="text-align: right;"><h1>]]..speed..[[</h1></td>
                                                    <td>km/h <h6>(max ]]..maxSpeed..[[)</h6></td>
                                                </tr>
                                                <tr>
                                                    <td style="text-align: right;"><h1>]]..accel..[[</h1></td>
                                                    <td>g</td>
                                                </tr>
                                                <tr>
                                                    <td style="text-align: right;"><h1>]]..resString..[[</h1></td>
                                                    <td>]]..brakeText..[[ Brake-Dist</td>
                                                </tr>
                                            </table>

                                    ]]
                                end
                
                counter = 1
                dpmTable = {}
                dps = "Calculating"
                ttZ = 0
                ttZString = "Calculating"
                calculating = false
                lastShield = shield.getShieldHitpoints()
                adjustShield = false
                autoAdjustShield = false --export: NOT RECOMMENDED! Will audo adjust every minute based on current stress 
                shieldDownColor = ""
                function enemyDPS()
                    local incDmg = 0
                    local newShield = shield.getShieldHitpoints()
                    local diff = lastShield - newShield
                    dpmTable[counter] = diff
                    counter = counter +1
                    lastShield = newShield
                    local dpmTableLenght = #dpmTable
                    for i=1,dpmTableLenght do
                        incDmg = incDmg + dpmTable[i]
                    end
                    
                    if counter > 60 then
                        adjustShield = true
                        counter = 1
                    end
                    if autoAdjustShield then
                        autoAdjust()
                    end
                    if dpmTableLenght > 10 then
                        dps = incDmg/dpmTableLenght
                        if counter%5 == 0 then
                            ttZ = newShield/dps
                            if ttZ < 60 then
                                shieldDownColor = "red"
                            elseif ttZ < 180 then
                                shieldDownColor = "orange"
                            end
                            ttZString = "~"..seconds_to_clock(ttZ) 
                        elseif ttZ > 0 then
                            ttZ = ttZ - 1
                            ttZString = "~"..seconds_to_clock(ttZ) 
                        end
                        
                        dps = round(dps/1000,2).."k"                       
                    end
                    if incDmg < 1 and dpmTableLenght == 60 then
                        unit.stopTimer("dps")
                        dpmTable = {}
                        counter = 1
                        dps = "Calculating"
                        ttZ = 0
                        ttZString = "Calculating"
                        calculating = false
                    end
                end

                function autoAdjust()
                    if adjustShield then
                        adjustShield = false
                        local sRR = shield.getStressRatioRaw()
                        local tot = 0.5999
                        if sRR[1] == 0.0 and sRR[2] == 0.0 and sRR[3] == 0.0 and sRR[4] == 0.0 then return end
                        local setResist = shield.setResistances((tot*sRR[1]),(tot*sRR[2]),(tot*sRR[3]),(tot*sRR[4]))
                    end
                end

                function drawEnemyDPS()
                    local resistances = shield.getResistances()
                    local amRes = math.ceil(10+resistances[1]*100)
                    local elRes = math.ceil(10+resistances[2]*100)
                    local kiRes = math.ceil(10+resistances[3]*100)
                    local thRes = math.ceil(10+resistances[4]*100)
                    local resCd = math.floor(shield.getResistancesCooldown())
                    local ventCd = math.floor(shield.getVentingCooldown())

                    local sRR = shield.getStressRatioRaw()
                    function stressColor(stress)
                        if stress > 55 then
                            return "red"
                        elseif stress > 0 then
                            return "orange"
                        else
                            return ""
                        end
                    end
                    local amStress = math.floor(sRR[1]*100)
                    local elStress = math.floor(sRR[2]*100)
                    local kiStress = math.floor(sRR[3]*100)
                    local thStress = math.floor(sRR[4]*100)

                    if (calculating and shield.getState()==1) or shield.isVenting()==1 then
                    enemyDPSHtml = [[
                    <style>
                        .enemyDPS{
                            position: fixed;
                            left: 25%;
                            bottom: 35%;
                        }
                        table.cd{
                            table-layout: fixed;
                            text-align: left;
                        }
                        table.resTable{
                            table-layout: fixed;
                            text-align: center;
                        }
                        table.resTable th {
                            width: 33% ;
                        } 
                    </style>
                    <div class="enemyDPS">
                        <h3>Enemy-DPS: ]]..dps..[[</h3>
                        <h3 style="color:]]..shieldDownColor..[[">Shield Down in: ]]..ttZString..[[</h3>
                        <table class="cd">
                            <tr>
                                <th>Vent-CD: ]]..ventCd..[[s</th>
                                <th>Res-CD: ]]..resCd..[[s</th>
                            </tr>
                        </table>
                        <table class="resTable">
                            <tr>
                                <th>Type</th>
                                <th>Res</th>
                                <th>Stress</th>
                            </tr>
                            <tr style="color:]]..stressColor(amStress)..[[">
                                <td>AM</td>
                                <td>]]..amRes..[[%</td>
                                <td>]]..amStress..[[%</td>
                            </tr>
                            <tr style="color:]]..stressColor(elStress)..[[">
                                <td>EL</td>
                                <td>]]..elRes..[[%</td>
                                <td>]]..elStress..[[%</td>
                            </tr>
                            <tr style="color:]]..stressColor(kiStress)..[[">
                                <td>KI</td>
                                <td>]]..kiRes..[[%</td>
                                <td>]]..kiStress..[[%</td>
                            </tr>
                            <tr style="color:]]..stressColor(thStress)..[[">
                                <td>TH</td>
                                <td>]]..thRes..[[%</td>
                               <td>]]..thStress..[[%</td>
                            </tr>
                        </table>
                    </div>
                    ]]
                    else
                        enemyDPSHtml = ""
                    end
                end

                function seconds_to_clock(time_amount)
                    local start_seconds = time_amount
                    local start_minutes = math.modf(start_seconds/60)
                    local seconds = start_seconds - start_minutes*60
                    local start_hours = math.modf(start_minutes/60)
                    local minutes = start_minutes - start_hours*60
                    local start_days = math.modf(start_hours/24)
                    local hours = start_hours - start_days*24
                    if hours > 0 then
                    local wrapped_time = {h=hours, m=minutes, s=seconds}
                    return string.format('%02.f:%02.f:%02.f', wrapped_time.h, wrapped_time.m, wrapped_time.s)
                    else
                        local wrapped_time = {m=minutes, s=seconds}
                        return string.format('%02.f:%02.f', wrapped_time.m, wrapped_time.s)
                    end
                end
                shieldMax = shield.getMaxShieldHitpoints()
                venting = ""
                stressBarHeight = "5"
                function drawShield()
                    shieldHp = shield.getShieldHitpoints()
                    shieldPercent = shieldHp/shieldMax*100
                    if shieldPercent == 100 then shieldPercent = "100"
                    else
                    shieldPercent = string.format('%0.2f',shieldPercent)
                    end    
                    coreStressPercent = string.format('%0.2f',core.getCoreStressRatio()*100)
                    local shieldHealthBar= [[
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
                        width: ]]..shieldPercent..[[%;
                        height: 40px;
                        position: relative;
                    }


                    </style>
                    <html>
                        <div class="health-bar">
                            <div class="bar">]]..venting..shieldPercent..[[%</div>
                        </div>
                    </html>
                    ]]
                    local coreStressBar= [[
                    <style>
                    .stress-health-bar {
                        position: fixed;
                        width: 13em; 
                        padding: 1vh; 
                        bottom:]]..stressBarHeight..[[vh;
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
                        width: ]]..coreStressPercent..[[%;
                        height: 40px;
                        position: relative;
                    }


                    </style>
                    <html>
                        <div class="stress-health-bar">
                            <div class="stress-bar">]]..coreStressPercent..[[%</div>
                        </div>
                    </html>
                    ]]
                    if shield.isVenting() == 1 then
                        stressBarHeight = "15"
                        venting = "Venting "
                        healthHtml = coreStressBar..shieldHealthBar
                    elseif shield.getState() == 0 or shield.getShieldHitpoints() == 0 then
                        stressBarHeight = "5"
                        healthHtml = coreStressBar 
                    else
                        stressBarHeight = "5"
                        venting = ""
                        healthHtml = shieldHealthBar
                    end
                end

                function combineHudElements()
                    drawFuelInfo()
                    brakeHud()
                    speedInfo()
                    drawPipeInfo()
                    drawEnemyDPS()
                    drawShield()
                    if showAllies then
	                    drawAlliesHtml()
	                end
	                if showThreats then
	                    drawThreatsHtml()
	                end
	                alarmBorder()
                    system.setScreen(alarmStyles..cssAllyLocked..fuelHtml..brakeHtml..alliesHtml..threatsHtml..ownInfoHtml..speedHtml..pipeInfoHtml..enemyDPSHtml..healthHtml)
                end

                unit.setTimer("hud",0.1)
                system.showScreen(1)
                if switch_1 ~= nil then switch_1.activate() end