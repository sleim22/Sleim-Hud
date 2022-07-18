Sound = (function()
    local this = {
        base = 'my_sound_folder\\',
        fs = {
            init = 'init.mp3',
            land = 'landing.mp3'
        },
        q = {}
    }

    function this:init()
        -- KeyActions:register('tick', 'SoundCheck', 'SoundCheck', self, 'check') -- or create a unit.tick called SoundCheck
        unit.setTimer('SoundCheck', 0.25)
        return this
    end

    function this:check()
        if (system.isPlayingSound() == 1 or #self.q < 1) then return end
        local f = table.remove(self.q, 1)
        system.playSound(self.base .. self.fs[f])
    end

    function this:play(n, nomult, force)
        if nomult then
            if system.isPlayingSound() == 1 then return end
        end
        if force then
            system.stopSound()
            self.q = {}
        end
        self.q[#self.q + 1] = n
    end

    return this
end)():init()
