local transponders = require("Transponder")
local tablea = {}
local i = 1
local i2 = 1

for _, v in pairs(transponders) do
    local transtag = v.transponder[1]
    tablea[i] = v.transponder[1]
    i = i + 1
    transponder.setTags(tablea)
end



local targets = require("Targets")
for k = 1, 5, 1 do databank.clearValue(k) end
for _, v in pairs(targets) do
    databank.setStringValue(i2, v.shortid[1])
    --system.print(v.shortid[1])
    --system.print(i2)
    i2 = i2 + 1
end
unit.hideWidget()
unit.exit()
