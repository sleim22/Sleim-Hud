floatyText = {}
floatyHtml = ""
showFloatyText = true
table.insert(floatyText, { timer = 0, text = "10k", hit = true })
function floatyTextF()
    floatyHtml = ""
    if showFloatyText then
        for k, v in pairs(floatyText) do
            local color = "#80ffff"
            local factor = 1
            v.timer = v.timer + 0.02
            if (v.timer >= 2) then table.remove(floatyText, k) end
            if not v.hit then
                color = "red"
                factor = -1
            end
            local x = screenWidth * (0.5 - factor * 0.05) - factor * v.timer * 30
            local y = screenHeight * 0.47 - v.timer * 30
            floatyHtml = floatyHtml .. [[
            <style>
            .floatyText]] .. k .. [[{
            position: fixed;
            top: ]] .. y .. [[px;
            right: ]] .. x .. [[px;
             color: ]] .. color .. [[;
            font-family: "Lucida" Grande, sans-serif;
            font-size:]] .. 40 - v.timer * 10 .. [[px;
            transform: translateX(50%);
            
            opacity: ]] .. 1 - v.timer / 2 .. [[

        }
           
            </style>
            
            <div  class="floatyText]] .. k .. [[">
            ]] .. v.text .. [[
            </div>
            ]]

        end
    end

end
