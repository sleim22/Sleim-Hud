Sound = {}
function play(path)
    system.playSound("SleimHud/" .. path .. ".mp3")
end

unit.setTimer("sound", 1)

-- timer
if system.isPlayingSound() == 0 and #Sound > 0 then
    play(table.remove(Sound, 1))
end


-- remote triggers
fuelLow = false
fuelCritical = false
shieldLow = false
shieldCritical = false
