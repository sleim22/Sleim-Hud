pitchInput = 0
rollInput = 0
yawInput = 0
drift = false
pitchSpeedFactor = 0.8 --export: This factor will increase/decrease the player input along the pitch axis<br>(higher value may be unstable)<br>Valid values: Superior or equal to 0.01
yawSpeedFactor = 1 --export: This factor will increase/decrease the player input along the yaw axis<br>(higher value may be unstable)<br>Valid values: Superior or equal to 0.01
rollSpeedFactor = 1.5 --export: This factor will increase/decrease the player input along the roll axis<br>(higher value may be unstable)<br>Valid values: Superior or equal to 0.01
screenHeight = system.getScreenHeight()
screenWidth = system.getScreenWidth()
unit.hideWidget()
Nav = Navigator.new(system, core, unit)
Nav.axisCommandManager:setupCustomTargetSpeedRanges(axisCommandId.longitudinal, { 1000, 5000, 10000, 20000, 30000 })
Nav.axisCommandManager:setTargetGroundAltitude(4)


brakeToggle = true --export:

if brakeToggle then
	isBraking = true
	brakeInput = 1
else
	isBraking = false
	brakeInput = 0
end

alarm = false
system.showHelper(0)

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
				Nav.axisCommandManager:updateCommandFromActionStart(axisCommandId.longitudinal, -utils.sign(targetSpeed))
			end
		end
	end
end

function hideWarpDrive()
	if warpdrive ~= nil then
		if warpdrive.getStatus() ~= 11 or warpdrive.getStatus() ~= 7 then
			warpdrive.showWidget()
		else
			warpdrive.hideWidget()
		end
	end
end

atlas = require('atlas')

planetList = {}
for k, nextPlanet in pairs(atlas[0]) do
	if nextPlanet.type[1] == "Planet" then
		planetList[#planetList + 1] = nextPlanet
		--system.print(nextPlanet.name[1])
	end
end

function newGetClosestPipe(wp)
	local pipeDistance
	nearestDistance = nil
	local nearestPipePlanet = nil
	local pipeOriginPlanet = nil

	for i = 1, #planetList, 1 do
		for k = #planetList, i + 1, -1 do
			originPlanet = planetList[i]
			nextPlanet = planetList[k]
			local distance = getPipeDistance(vec3(originPlanet.center), vec3(nextPlanet.center), wp)
			if (nearestDistance == nil or distance < nearestDistance) then
				nearestPipePlanet = nextPlanet
				nearestDistance = distance
				pipeOriginPlanet = originPlanet
			end
			--system.print(planetList[i].name[1].."-"..planetList[k].name[1])
		end
	end
	pipeDistance = getDistanceDisplayString(nearestDistance)
	return pipeOriginPlanet.name[1], nearestPipePlanet.name[1], pipeDistance
end

function round(num, numDecimalPlaces)
	local mult = 10 ^ (numDecimalPlaces or 0)
	return math.floor(num * mult + 0.5) / mult
end

function getDistanceDisplayString(distance)
	local su = distance > 100000
	if su then
		-- Convert to SU
		return round(distance / 1000 / 200, 2) .. "SU"
	elseif distance < 1000 then
		return round(distance, 2) .. "M"
	else
		-- Convert to KM
		return round(distance / 1000, 2) .. "KM"
	end
end

function getCurrentBody()
	local coordinates = construct.getWorldPosition()
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

function getPipeDistance(origCenter, destCenter, pos)
	local pipeDistance
	local worldPos = vec3(pos)
	local pipe = (destCenter - origCenter):normalize()
	local r = (worldPos - origCenter):dot(pipe) / pipe:dot(pipe)

	if r <= 0. then
		pipeDistance = (worldPos - origCenter):len()
		return pipeDistance
	elseif r >= (destCenter - origCenter):len() then
		pipeDistance = (worldPos - destCenter):len()
		return pipeDistance
	else
		local L = origCenter + (r * pipe)
		pipeDistance = (L - worldPos):len()
		return pipeDistance
	end
end

function updatePipeInfo()
	currentPos = construct.getWorldPosition()
	local notPvPZone = construct.isInPvPZone() == 0
	local pvpDist = construct.getDistanceToSafeZone()
	if pvpDist < 0 then pvpDist = pvpDist * (-1) end

	local o, p, d = newGetClosestPipe(currentPos)
	return o, p, d, notPvPZone, pvpDist
end

function drawPipeInfo()
	local zone = ""
	local originPlanet, pipePlanet, pipeDist, notPvPZone, pvpDist = updatePipeInfo()
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
                                        <h1>]] .. originPlanet .. " - " .. pipePlanet .. [[: ]] .. pipeDist .. [[</h1>
                                        <h2>]] .. zone .. [[ Zone in: ]] .. pvpDist .. [[<h2>
                                    </div>
                                    ]]
end

function drawFuelInfo()
	local fuelCSS = [[<style>
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

	function addFuelTank(tank, i)
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
                            <div class="barFullness" style="width: ]] .. percent .. [[%;
                        background:]] .. color .. [[;">]] .. percent .. [[%</div>
                        </div></td></tr>
                    ]]
	end

	fuelHtml = fuelCSS .. [[<table class="fuelInfo">
                        ]]
	if spacefueltank_size > 0 then
		fuelHtml = fuelHtml .. [[<tr>
                            <th>Space</th>
                        </tr>]]
	end
	for i = 1, #spacefueltank do

		fuelHtml = fuelHtml .. addFuelTank(spacefueltank[i], i)
	end
	if atmofueltank_size > 0 then
		fuelHtml = fuelHtml .. [[<tr>
                            <th>Atmo</th>
                        </tr>]]
	end

	for i = 1, #atmofueltank do
		fuelHtml = fuelHtml .. addFuelTank(atmofueltank[i], i)
	end

	if rocketfueltank_size > 0 then
		fuelHtml = fuelHtml .. [[<tr>
                            <th>Rocket</th>
                        </tr>]]
	end

	for i = 1, #rocketfueltank do
		fuelHtml = fuelHtml .. addFuelTank(rocketfueltank[i], i)
	end
	fuelHtml = fuelHtml .. "</table></div>"
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
	local speed = math.floor(vec3(construct.getWorldVelocity()):len() * 3.6)
	local accel = math.floor((vec3(construct.getWorldAcceleration()):len() / 9.80665) * 10) / 10
	local maxSpeed = math.floor(construct.getMaxSpeed() * 3.6)
	local c = 100000000 / 3600
	local m0 = construct.getMass()
	local v0 = vec3(construct.getWorldVelocity())
	local maxBrakeThrust = construct.getMaxBrake()
	local time = 0.0
	dis = 0.0
	local v = v0:len()
	if maxBrakeThrust > 0 then
		while v > 1.0 do
			time = time + 1
			local m = m0 / (math.sqrt(1 - (v * v) / (c * c)))
			local a = maxBrakeThrust / m
			if v > a then
				v = v - a --*1 sec
				dis = dis + v + a / 2.0
			elseif a ~= 0 then
				local t = v / a
				dis = dis + v * t + a * t * t / 2
				v = v - a
			end
		end
	end
	local resString = ""
	if dis > 100000 then
		resString = resString .. string.format(math.floor((dis / 200000) * 10) / 10)
		brakeText = "SU"
	elseif dis > 1000 then
		resString = resString .. string.format(math.floor((dis / 1000) * 10) / 10)
		brakeText = "KM"
	else
		resString = resString .. string.format(math.floor(dis))
		brakeText = "M"
	end
	driftInfo = ""
	if drift then
		driftInfo = [[<tr>
		<td style="text-align: center;" colspan="2"><h6>Inertia-Dampening: Off</h6></td>
	</tr>]]
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
                                                    <td style="text-align: right;"><h1>]] .. throttle .. [[</h1></td>
                                                    <td>%</td>
                                                </tr>
                                                <tr>
                                                    <td style="text-align: right;"><h1>]] .. speed .. [[</h1></td>
                                                    <td>km/h <h6>(max ]] .. maxSpeed .. [[)</h6></td>
                                                </tr>
                                                <tr>
                                                    <td style="text-align: right;"><h1>]] .. accel .. [[</h1></td>
                                                    <td>g</td>
                                                </tr>
                                                <tr>
                                                    <td style="text-align: right;"><h1>]] .. resString .. [[</h1></td>
                                                    <td>]] .. brakeText .. [[ Brake-Dist</td>
                                                </tr>]] .. driftInfo .. [[
                                            </table>]]
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
ShieldRes = {}
ShieldDisplay = {}
function enemyDPS()
	local incDmg = 0
	local newShield = shield.getShieldHitpoints()
	local diff = lastShield - newShield
	dpmTable[counter] = diff
	counter = counter + 1
	lastShield = newShield
	local dpmTableLenght = #dpmTable
	for i = 1, dpmTableLenght do
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
		dps = incDmg / dpmTableLenght
		if counter % 5 == 0 then
			ttZ = newShield / dps
			if ttZ < 60 then
				shieldDownColor = "red"
			elseif ttZ < 180 then
				shieldDownColor = "orange"
			end
			ttZString = "~" .. seconds_to_clock(ttZ)
		elseif ttZ > 0 then
			ttZ = ttZ - 1
			ttZString = "~" .. seconds_to_clock(ttZ)
		end

		dps = round(dps / 1000, 2) .. "k"
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
		local setResist = shield.setResistances((tot * sRR[1]), (tot * sRR[2]), (tot * sRR[3]), (tot * sRR[4]))
	end
end

function drawEnemyDPS()
	local resCd = math.floor(shield.getResistancesCooldown())
	local ventCd = math.floor(shield.getVentingCooldown())

	local sRR = shield.getStressRatioRaw()



	screenHeight = system.getScreenHeight()
	screenWidth = system.getScreenWidth()
	ShieldDisplay.startX = screenWidth * 0.17
	ShieldDisplay.startY = screenHeight * 25 / 1080
	ShieldDisplay.resFactorX = screenWidth / 1920
	ShieldDisplay.resFactorY = screenHeight / 1080
	--system.print(ShieldDisplay.resFactorX)

	ShieldDisplay.totalWidth = 350 * ShieldDisplay.resFactorX
	ShieldDisplay.totalHeight = 250 * ShieldDisplay.resFactorY
	ShieldDisplay.resBarWidth = ShieldDisplay.totalWidth * 3 / 5
	ShieldDisplay.barMargin = 25 * ShieldDisplay.resFactorY
	ShieldDisplay.textMargin = 20 * ShieldDisplay.resFactorY
	ShieldDisplay.barStart = 60 * ShieldDisplay.resFactorY
	local resistances = shield.getResistances()


	ShieldRes.maxPool = shield.getResistancesPool()

	if not leftAltPressed then
		ShieldRes.currentPool = shield.getResistancesRemaining()
		ShieldRes[1] = { resistances[1], "AM", sRR[1] }
		ShieldRes[2] = { resistances[2], "EM", sRR[2] }
		ShieldRes[3] = { resistances[3], "KI", sRR[3] }
		ShieldRes[4] = { resistances[4], "TH", sRR[4] }

	end
	ShieldDisplay.setString = "Set"
	if resCd > 0 then
		ShieldDisplay.setString = resCd .. " s"
	end
	ShieldDisplay.ventString = "Vent"
	if ventCd > 0 then
		ShieldDisplay.ventString = ventCd .. " sec"
	end
	if (calculating and shield.isActive() == 1) or shield.isVenting() == 1 or ventCd > 0 or leftAltPressed or resCd > 0 then
		ShieldDisplay.HTML = [[

 <svg width="100%" height="100%" style="position: absolute;left:0%;top:0%;font-family: Calibri;fill:white;stroke:#80ffff;font-weight:bold">

	<rect x="]] ..
			ShieldDisplay.startX ..
			[[" y="]] ..
			ShieldDisplay.startY ..
			[[" rx="20" ry="20" width="]] ..
			ShieldDisplay.totalWidth ..
			[[" height="]] .. ShieldDisplay.totalHeight .. [[" style="stroke-width:2;fill-opacity:0"/>

	<text x="]] ..
			ShieldDisplay.startX + 30 ..
			[[" y="]] .. ShieldDisplay.startY + ShieldDisplay.textMargin .. [[">Enemy DPS: ]] .. dps .. [[</text>
	<text x="]] ..
			ShieldDisplay.startX + 30 ..
			[[" y="]] ..
			ShieldDisplay.startY + ShieldDisplay.textMargin * 2 ..
			[[" fill="]] .. shieldDownColor .. [[">Time till shield down: ]] .. ttZString .. [[</text>
        <line x1="]] ..
			ShieldDisplay.startX + 10 ..
			[[" y1="]] ..
			ShieldDisplay.startY + ShieldDisplay.barMargin * 2 ..
			[[" x2="]] ..
			ShieldDisplay.startX + ShieldDisplay.totalWidth - 10 ..
			[[" y2="]] .. ShieldDisplay.startY + ShieldDisplay.barMargin * 2 .. [[" style="stroke-width:2" />
	
	<text x="]] ..
			ShieldDisplay.startX + 30 ..
			[[" y="]] ..
			ShieldDisplay.startY + ShieldDisplay.barMargin * 3 ..
			[[">Points left: ]] .. math.floor(ShieldRes.currentPool * 100) ..
			"/" .. math.floor(ShieldRes.maxPool * 100) .. [[</text>

	]]

		for i = 1, 4, 1 do
			ShieldDisplay.HTML = ShieldDisplay.HTML ..
				[[<text x="]] ..
				ShieldDisplay.startX + 12 ..
				[[" y="]] ..
				ShieldDisplay.startY + ShieldDisplay.barStart + ShieldDisplay.barMargin * i + 8 ..
				[[" font-weight:"lighter" font-size="10">]] .. ShieldRes[i][2] .. [[</text>
		<rect x="]] ..
				ShieldDisplay.startX + 30 ..
				[[" y="]] ..
				ShieldDisplay.startY + ShieldDisplay.barStart + ShieldDisplay.barMargin * i ..
				[[" rx="2" ry="2" width="]] ..
				ShieldDisplay.resBarWidth * ShieldRes[i][1] / ShieldRes.maxPool ..
				[[" height="10" style="stroke-width:0;fill-opacity:0.8;fill:white" />
		<rect x="]] ..
				ShieldDisplay.startX + 30 ..
				[[" y="]] ..
				ShieldDisplay.startY + ShieldDisplay.barStart + ShieldDisplay.barMargin * i ..
				[[" rx="2" ry="2" width="]] .. ShieldDisplay.resBarWidth ..
				[[" height="10" style="stroke-width:2;fill-opacity:0" />
		
		<rect x="]] ..
				ShieldDisplay.startX + ShieldDisplay.resBarWidth + 40 ..
				[[" y="]] ..
				ShieldDisplay.startY + ShieldDisplay.barStart + ShieldDisplay.barMargin * i ..
				[[" rx="2" ry="2" width="]] ..
				(ShieldDisplay.totalWidth - ShieldDisplay.resBarWidth - 60) * ShieldRes[i][3] ..
				[[" height="10" style="stroke-width:0;fill-opacity:0.8;fill:red" />
		<rect x="]] ..
				ShieldDisplay.startX + ShieldDisplay.resBarWidth + 40 ..
				[[" y="]] ..
				ShieldDisplay.startY + ShieldDisplay.barStart + ShieldDisplay.barMargin * i ..
				[[" rx="2" ry="2" width="]] ..
				(ShieldDisplay.totalWidth - ShieldDisplay.resBarWidth - 60) ..
				[[" height="10" style="stroke-width:2;fill-opacity:0" />
		
		]]
		end
		ShieldDisplay.HTML = ShieldDisplay.HTML .. [[
	
	<rect x="]] ..
			ShieldDisplay.startX + 30 * ShieldDisplay.resFactorX ..
			[[" y="]] ..
			ShieldDisplay.startY + ShieldDisplay.barStart + ShieldDisplay.barMargin * 5 ..
			[[" rx="4" ry="4" width="]] ..
			50 * ShieldDisplay.resFactorX .. [[" height="40" style="fill:yellow;stroke-width:2;fill-opacity:0" />
	<text x="]] ..
			ShieldDisplay.startX + 45 * ShieldDisplay.resFactorX ..
			[[" y="]] ..
			ShieldDisplay.startY + ShieldDisplay.barStart + ShieldDisplay.barMargin * 6 ..
			[[" style="font-weight:bold">]] .. ShieldDisplay.setString .. [[</text>
	
        <rect x="]] ..
			ShieldDisplay.startX + 90 * ShieldDisplay.resFactorX ..
			[[" y="]] ..
			ShieldDisplay.startY + ShieldDisplay.barStart + ShieldDisplay.barMargin * 5 ..
			[[" rx="4" ry="4" width="]] ..
			50 * ShieldDisplay.resFactorX .. [[" height="40" style="fill:yellow;stroke-width:2;fill-opacity:0" />
	    <text x="]] ..
			ShieldDisplay.startX + 98 * ShieldDisplay.resFactorX ..
			[[" y="]] ..
			ShieldDisplay.startY + ShieldDisplay.barStart + ShieldDisplay.barMargin * 6 ..
			[[" style="font-weight:bold">Reset</text>
	
     <rect x="]] ..
			ShieldDisplay.startX + ShieldDisplay.resBarWidth + ShieldDisplay.textMargin * 2 ..
			[[" y="]] ..
			ShieldDisplay.startY + ShieldDisplay.barStart + ShieldDisplay.barMargin * 5 ..
			[[" rx="4" ry="4" width="]] ..
			(ShieldDisplay.totalWidth - ShieldDisplay.resBarWidth - 60) ..
			[[" height="40" style="fill:yellow;stroke-width:2;fill-opacity:0" />
	<text x="]] ..
			ShieldDisplay.startX + ShieldDisplay.resBarWidth + ShieldDisplay.textMargin * 3 ..
			[[" y="]] ..
			ShieldDisplay.startY + ShieldDisplay.barStart + ShieldDisplay.barMargin * 6 ..
			[[" style="font-weight:bold">]] .. ShieldDisplay.ventString .. [[</text>
	
	</svg>]]

	else
		ShieldDisplay.HTML = ""
	end
end

function seconds_to_clock(time_amount)
	local start_seconds = time_amount
	local start_minutes = math.modf(start_seconds / 60)
	local seconds = start_seconds - start_minutes * 60
	local start_hours = math.modf(start_minutes / 60)
	local minutes = start_minutes - start_hours * 60
	local start_days = math.modf(start_hours / 24)
	local hours = start_hours - start_days * 24
	if hours > 0 then
		local wrapped_time = { h = hours, m = minutes, s = seconds }
		return string.format('%02.f:%02.f:%02.f', wrapped_time.h, wrapped_time.m, wrapped_time.s)
	else
		local wrapped_time = { m = minutes, s = seconds }
		return string.format('%02.f:%02.f', wrapped_time.m, wrapped_time.s)
	end
end

shieldMax = shield.getMaxShieldHitpoints()
venting = ""
stressBarHeight = "5"
function drawShield()
	shieldHp = shield.getShieldHitpoints()
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
	if shield.isVenting() == 1 then
		stressBarHeight = "15"
		venting = "Venting "
		healthHtml = coreStressBar .. shieldHealthBar
	elseif shield.isActive() == 0 or shield.getShieldHitpoints() == 0 then
		stressBarHeight = "5"
		healthHtml = coreStressBar
	else
		stressBarHeight = "5"
		venting = ""
		healthHtml = shieldHealthBar
	end
end

mouseHtml = ""
leftAltPressed = false
function drawMouse()
	if leftAltPressed then
		local x = system.getMousePosX()
		local y = system.getMousePosY()
		mouseHtml = [[<svg  width="100%" height="100%" style="position: absolute;left:0%;top:0%;"><circle cx=]] ..
			x .. [[ cy=]] .. y .. [[ r=2 stroke="red" stroke-width="3" fill="red"></svg>]]
	else
		mouseHtml = ""
	end
end

function combineHudElements()
	drawFuelInfo()
	brakeHud()
	speedInfo()
	drawPipeInfo()
	drawEnemyDPS()
	drawShield()
	drawMouse()
	system.setScreen(alienAR ..
		planetAR .. fuelHtml .. brakeHtml .. speedHtml .. pipeInfoHtml .. ShieldDisplay.HTML .. healthHtml .. mouseHtml)
end

unit.setTimer("hud", 0.1)
system.showScreen(1)
if switch_1 ~= nil then switch_1.activate() end
