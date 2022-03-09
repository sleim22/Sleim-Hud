
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
                
                function seconds_to_clock(time_amount)
                    local start_seconds = time_amount
                    local start_minutes = math.modf(start_seconds/60)
                    local seconds = start_seconds - start_minutes*60
                    local start_hours = math.modf(start_minutes/60)
                    local minutes = start_minutes - start_hours*60
                    local start_days = math.modf(start_hours/24)
                    local hours = start_hours - start_days*24
                    local wrapped_time = {h=hours, m=minutes, s=seconds}
                    return string.format('%02.f:%02.f:%02.f', wrapped_time.h, wrapped_time.m, wrapped_time.s)
                end

                function WeaponWidgetCreate()
                        if type(weapon) == 'table' and #weapon > 0 then
                            local WeaponPanaelIdList = {}
                            for i = 1, #weapon do
                                if i%2 ~= 0 then
                                table.insert(WeaponPanaelIdList, system.createWidgetPanel(''))
                                end
                                local WeaponWidgetDataId = weapon[i].getDataId()
                                local WeaponWidgetType = weapon[i].getWidgetType()
                                system.addDataToWidget(WeaponWidgetDataId, system.createWidget(WeaponPanaelIdList[#WeaponPanaelIdList], WeaponWidgetType))
                            end
                    end
                end
                if showWeapons == true then 
                   WeaponWidgetCreate()
                end

                function createTargetInfoWidget()
                    panel = system.createWidgetPanel('')
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
                                newTargetName = newTargetName..' - Time: '..seconds_to_clock(system.getTime())
                            end
                            if radar.hasMatchingTransponder(v) == 1 then
                                newTargetName = newTargetName.." - [Ally] Owner: "..getFriendlyDetails(v)
                            else
                                system.playSound("contact.mp3")
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
                    probil = math.floor(json.decode(weapon_1.getData()).properties.hitProbability * 100)
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

                function drawShield()
                    shieldHp = shield_1.getShieldHitpoints()
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
                    if shield_1.isVenting() == 1 then
                        stressBarHeight = "15"
                        venting = "Venting "
                        healthHtml = coreStressBar..shieldHealthBar
                    elseif shield_1.getState() == 0 or shield_1.getShieldHitpoints() == 0 then
                        stressBarHeight = "5"
                        healthHtml = coreStressBar 
                    else
                        stressBarHeight = "5"
                        venting = ""
                        healthHtml = shieldHealthBar
                    end
                end

                function updateRadar(match)
                    if radar_size > 1 and radar_1.isOperational()==0 then radar = radar_2 else radar = radar_1 end
                    allies={}
                    threats={}
                    local data = radar.getData()
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
                                threats[#threats]=id
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
                function drawHud()
                    html = cssAllyLocked..healthHtml..alliesHtml..threatsHtml..ownInfoHtml
                    system.setScreen(html)
                end
                radar = radar_1
                createTargetInfoWidget()
                getMaxCorestress()
                system.setScreen(html)
                system.showScreen(1)
                unit.setTimer("hud",0.1)
                unit.setTimer("data", 0.2)
                unit.setTimer("radar", 0.4)
                unit.setTimer("clean", 30)