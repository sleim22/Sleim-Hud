
                pitchInput = 0
                rollInput = 0
                yawInput = 0
                brakeInput = 1
                unit.hide()
                newRadarContacts = {}
                printSZContacts = false --export:
                printLocationOnContact = true --export:
                showTime = true --export:
                screenHtml = "<style>html{background-color:#36393E;}</style><h1>Scanning:</h1>"
                Nav = Navigator.new(system, core, unit)
                Nav.axisCommandManager:setupCustomTargetSpeedRanges(axisCommandId.longitudinal, {1000, 5000, 10000, 20000, 30000})
                Nav.axisCommandManager:setTargetGroundAltitude(4)


                isBraking = true
                system.showHelper(0)
                if screen_1 ~= nil then
                	screen_1.setHTML(screenHtml)
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

                
                atlas = require('atlas')

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

                function getClosestPipe(wp)
                    local pipeDistance
                    nearestDistance = nil
                    local nearestPipePlanet = nil
                    local pipeOriginPlanet = nil
                    local originPlanet = getCurrentBody()

                    for k,nextPlanet in pairs(atlas[0]) do
                    	for i,originPlanet in pairs(atlas[0]) do
                    		if i~=k then
		                        local distance = getPipeDistance(vec3(originPlanet.center), vec3(nextPlanet.center),wp)
		                        if (nearestDistance == nil or distance < nearestDistance) then
		                            nearestPipePlanet = nextPlanet
		                            nearestDistance = distance
		                            pipeOriginPlanet = originPlanet
		                        end
		                    end
		                end
                    end
                    pipeDistance = getDistanceDisplayString(nearestDistance)
                    return pipeOriginPlanet.name[1],nearestPipePlanet.name[1],pipeDistance
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
                    local o,p,d = getClosestPipe(currentPos)
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
                    local fuelHeight = (40+(spacefueltank_size+atmofueltank_size)*30)
                    local fuelCSS=[[<style>
                    .fuelInfo {
                        position: fixed;
                        bottom: ]]..fuelHeight..[[px;
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
                    .bar {
                        padding: 5px;
                        border-radius: 5vh;
                        height: 95%;
                        position: center;
                        text-align: left;
                    }
                    </style>]]

                    function addFuelTank(tank,i)
                        local color = "green"
                        local percent = json.decode(tank.getData()).percentage
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
                            <div class="bar" style="width: ]]..percent..[[%;
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
                                    local accel = math.floor((json.decode(unit.getData()).acceleration/9.80665)*10)/10

                                    local c = 8333.333
                                    local m0 = core.getConstructMass()
                                    local v0 = vec3(core.getWorldVelocity())
                                    local controllerData = json.decode(unit.getData())
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
                                            h1{
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
                                            width: 33%;
                                        }          
                                        </style>
                                            <table class="speed">
                                                <tr>
                                                    <td style="text-align: right;"><h1>]]..throttle..[[</h1></td>
                                                    <td>%</td>
                                                </tr>
                                                <tr>
                                                    <td style="text-align: right;"><h1>]]..speed..[[</h1></td>
                                                    <td>km/h</td>
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

                function printNewRadarContacts()
                    if radar_size > 1 then
                    	if radar_1.isOperational()==0 then
	                        radar_1.hide()
	                        radar_2.show()
	                        radar = radar_2
                    	else
	                        radar_2.hide()
	                        radar_1.show()
	                        radar = radar_1
	                    end
                    end
                    local originPlanet,pipePlanet,pipeDist,notPvPZone,pvpDist=updatePipeInfo()
                    pvpDist = getDistanceDisplayString(pvpDist)

                    if not notPvPZone or printSZContacts then
                        local newTargetCounter = 0
                        for k,v in pairs(newRadarContacts) do
                            if newTargetCounter > 10 then
                                system.print("Didnt print all new Contacts to prevent overload!")
                            break end
                            newTargetCounter = newTargetCounter + 1
                            newTargetName = "["..radar.getConstructCoreSize(v).."]- "..radar.getConstructName(v)
                            if showTime then
                                newTargetName = newTargetName..' - Time: '..seconds_to_clock(system.getTime())
                            end
                            if radar.hasMatchingTransponder(v) == 1 then
                                newTargetName = newTargetName.." - [Ally] Owner: "..getFriendlyDetails(v)
                            elseif radar.isConstructAbandoned(v) == 1 then
                                newTargetName = newTargetName.." - Abandoned"
                            else
                                system.playSound("contact.mp3")
                            end
                            system.print("New Target: "..newTargetName)
                            if printLocationOnContact then
                                system.print(originPlanet.." - "..pipePlanet.." PvP-Border in "..pvpDist)
                                system.print(system.getWaypointFromPlayerPos())
                            end
                            if screen_1 ~= nil then
                            	screenHtml = screenHtml..[[<div><h2>]]..newTargetName..[[</h2></div><br>
                            	<div><h4>]]..originPlanet.." - "..pipePlanet.." PvP-Border in "..pvpDist..[[</h4></div><br>
                            	<div style="color:orange">]]..system.getWaypointFromPlayerPos()..[[</div><br>]]
                            	screen_1.setHTML(screenHtml)
                            end
                        end
                        newRadarContacts = {}
                    else
                        newRadarContacts = {}
                    end
                end
                
                function combineHudElements()
                    drawFuelInfo()
                    brakeHud()
                    speedInfo()
                    drawPipeInfo()
                    system.setScreen(fuelHtml..brakeHtml..speedHtml..pipeInfoHtml)
                end
                unit.setTimer("hud",0.5)
                unit.setTimer("radar",0.5)
                system.showScreen(1)
                warpdrive.show()