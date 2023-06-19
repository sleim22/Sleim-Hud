local ShieldDisplay = {}

ShieldDisplay.startX = screenWidth * 0.3
ShieldDisplay.startY = screenHeight * 0.5
ShieldDisplay.resFactorX = screenWidth / 1920
ShieldDisplay.resFactorY = screenHeight / 1080

ShieldDisplay.totalWidth = 300 * ShieldDisplay.resFactorX
ShieldDisplay.totalHeight = 200 * ShieldDisplay.resFactorY
if (calculating and shield.isActive()) or shield.isVenting() or ventCd > 0 then
ShieldDisplay.HTML = [[
  <svg width="100%" height="100%" style="position: absolute;left:0%;top:0%;font-family: Calibri;fill:white;stroke:#80ffff;font-weight:bold">

	<rect x="]] .. ShieldDisplay.startX .. [[" y="]] .. ShieldDisplay.startY .. [[" rx="20" ry="20" width="]] .. ShieldDisplay.totalWidth .. [[" height="]] .. ShieldDisplay.totalHeight .. [[" style="stroke-width:2;fill-opacity:0"/>

	<text x="]] .. ShieldDisplay.startX + 30 ..  [[" y="]] ..  ShieldDisplay.startY + ShieldDisplay.textMargin .. [[">Enemy DPS: 30k</text>
	<text x="]] .. ShieldDisplay.startX + 30 .. [[" y="]] .. ShieldDisplay.startY + ShieldDisplay.textMargin * 2.. [[">Time till shield down:</text>
	<line x1="]] .. ShieldDisplay.startX + 10 ..  [[" y1="]] .. ShieldDisplay.startY + ShieldDisplay.barMargin * 2 .. [[" x2="]] ..ShieldDisplay.startY + ShieldDisplay.totalWidth - 10 ..  [[" y2="]] .. ShieldDisplay.startY + ShieldDisplay.barMargin * 2 .. [[" style="stroke-width:2" />
	
	<text x="]] .. ShieldDisplay.startX + 30 .. [[" y="]] .. ShieldDisplay.startY + ShieldDisplay.barMargin * 3 .. [[">Points left: ]]..math.floor(shield.getResistancesRemaining()*100) .."/".. math.floor(ShieldRes.maxPool*100) ..[[</text>

	<text x="]] .. ShieldDisplay.startX + 20 ..  [[" y="]] ..  ShieldDisplay.startY + ShieldDisplay.barMargin * 4 - 5 .. [[" font-weight:"lighter" font-size="10">Antimatter</text>
    <rect x="]] .. ShieldDisplay.startX + 20 ..  [[" y="]] ..  ShieldDisplay.startY + ShieldDisplay.barMargin * 4 .. [[" rx="2" ry="2" width="]].. ShieldDisplay.resBarWidth*ShieldRes.amRes/ShieldRes.maxPool ..[[" height="10" style="stroke-width:2;fill-opacity:0.8;fill:white" />
	<rect x="]] .. ShieldDisplay.startX + 20 ..  [[" y="]] ..  ShieldDisplay.startY + ShieldDisplay.barMargin * 4 .. [[" rx="2" ry="2" width="]]..ShieldDisplay.resBarWidth..[[" height="10" style="stroke-width:2;fill-opacity:0" />
	
	
	<text x="]] .. ShieldDisplay.startX + 20 ..  [[" y="]] ..  ShieldDisplay.startY + ShieldDisplay.barMargin * 5 - 5 .. [[" font-weight:"lighter" font-size="10">Electromagnetic</text>
    <rect x="]] .. ShieldDisplay.startX + 20 ..  [[" y="]] ..  ShieldDisplay.startY + ShieldDisplay.barMargin * 5 .. [[" rx="2" ry="2" width="]].. ShieldDisplay.resBarWidth*ShieldRes.emRes/ShieldRes.maxPool  ..[[" height="10" style="stroke-width:2;fill-opacity:0.8;fill:white" />
	<rect x="]] .. ShieldDisplay.startX + 20 ..  [[" y="]] ..  ShieldDisplay.startY + ShieldDisplay.barMargin * 5 .. [[" rx="2" ry="2" width="]]..ShieldDisplay.resBarWidth..[[" height="10" style="stroke-width:2;fill-opacity:0" />
	
	<text x="]] .. ShieldDisplay.startX + 20 ..  [[" y="]] ..  ShieldDisplay.startY + ShieldDisplay.barMargin * 6 - 5 .. [[" font-weight:"lighter" font-size="10">Kinetic</text>
	<rect x="]] .. ShieldDisplay.startX + 20 ..  [[" y="]] ..  ShieldDisplay.startY + ShieldDisplay.barMargin * 6 .. [[" rx="2" ry="2" width="]].. ShieldDisplay.resBarWidth*ShieldRes.kiRes/ShieldRes.maxPool  ..[[" height="10" style="stroke-width:2;fill-opacity:0.8;fill:white" />
	<rect x="]] .. ShieldDisplay.startX + 20 ..  [[" y="]] ..  ShieldDisplay.startY + ShieldDisplay.barMargin * 6 .. [[" rx="2" ry="2" width="]]..ShieldDisplay.resBarWidth..[[" height="10" style="stroke-width:2;fill-opacity:0" />
	
	<text x="]] .. ShieldDisplay.startX + 20 ..  [[" y="]] ..  ShieldDisplay.startY + ShieldDisplay.barMargin * 7 - 5 .. [[" font-weight:"lighter" font-size="10">Thermal</text>
	<rect x="]] .. ShieldDisplay.startX + 20 ..  [[" y="]] ..  ShieldDisplay.startY + ShieldDisplay.barMargin * 7 .. [[" rx="2" ry="2" width="]].. ShieldDisplay.resBarWidth*ShieldRes.thRes/ShieldRes.maxPool ..[[" height="10" style="stroke-width:2;fill-opacity:0.8;fill:white" />
	<rect x="]] .. ShieldDisplay.startX + 20 ..  [[" y="]] ..  ShieldDisplay.startY + ShieldDisplay.barMargin * 7 .. [[" rx="2" ry="2" width="]]..ShieldDisplay.resBarWidth..[[" height="10" style="stroke-width:2;fill-opacity:0" />
	
	<rect x="390" y="140" rx="2" ry="2" width="100" height="20" style="fill:red;stroke:black;stroke-width:5;fill-opacity:0" />
	<rect x="390" y="180" rx="2" ry="2" width="100" height="20" style="fill:red;stroke:black;stroke-width:5;fill-opacity:0" />
	<rect x="390" y="220" rx="2" ry="2" width="100" height="20" style="fill:red;stroke:black;stroke-width:5;fill-opacity:0" />
	<rect x="390" y="260" rx="2" ry="2" width="100" height="20" style="fill:red;stroke:black;stroke-width:5;fill-opacity:0" />
	
	<rect x="70" y="310" rx="2" ry="2" width="150" height="40" style="fill:red;stroke:black;stroke-width:5;fill-opacity:0" />
	<text x="80" y="335" style="fill:black;font-weight:bold">Change Resistances</text>
	
	<rect x="400" y="310" rx="2" ry="2" width="100" height="40" style="fill:red;stroke:black;stroke-width:5;fill-opacity:0" />
	<text x="410" y="335" style="fill:black;font-weight:bold">Vent Shield</text>
	</svg>]]
