----------------------------------------------------
-- 🛡️ GLOBAL CONFIGURATION & SERVICES
----------------------------------------------------
local Players = game:GetService("Players") -- FIXED: Added missing Players service
local NetworkClient = game:GetService("NetworkClient")
local immunePlayers = {} 

----------------------------------------------------
-- 🛡️ CLIENT PROTECTION & AUTO-IMMUNITY
----------------------------------------------------
local LocalPlayer = Players.LocalPlayer

if LocalPlayer then
    -- AUTO-IMMUNITY: Automatically add the executing player's ID
    table.insert(immunePlayers, LocalPlayer.UserId)
    print("Successfully granted automatic immunity to: " .. LocalPlayer.Name .. " (" .. LocalPlayer.UserId .. ")")

    local function kickPlayerSafely(player, reason)
        if table.find(immunePlayers, player.UserId) then
            print(player.Name .. " is immune to automated kicks.")
            return 
        end
        player:Kick(reason)
    end

    -- Anti-Kick Hook
    pcall(function()
        if LocalPlayer.Kick then
            local oldKick
            oldKick = hookfunction(LocalPlayer.Kick, function(self, reason)
                if self == LocalPlayer then
                    print("Blocked a local Kick attempt.")
                    return nil 
                end
                return oldKick(self, reason)
            end)
        end
    end)

    -- Telemetry / Detection Drop Hook
    pcall(function()
        local mt = getrawmetatable(game)
        local oldNamecall = mt.__namecall
        setreadonly(mt, false)

        mt.__namecall = newcclosure(function(self, ...)
            local method = getnamecallmethod()
            
            if tostring(method) == "FireServer" or tostring(method) == "InvokeServer" then
                local name = tostring(self.Name):lower()
                if name:find("cheat") or name:find("detection") or name:find("report") or name:find("kick") or name:find("telemetry") or name:find("check") then
                    print("Blocked telemetry/detection traffic: " .. tostring(self.Name))
                    return nil 
                end
            end
            
            return oldNamecall(self, ...)
        end)
        setreadonly(mt, true)
    end)

    -- Anti-Ban Hook (Credit: StepBroFurious)
    pcall(function()
        local X
        X = hookmetamethod(game, "__namecall", function(self, ...)
            local method = getnamecallmethod()
            
            if method == "Ban" then
                local eval1 = {false}
                local eval2 = {false}
                local args = {...}

                if debug.validlevel and debug.validlevel(3) and self.Parent == nil then
                    local stack = debug.getstack(3)
                    local counter = 0
                    local expected
                    
                    for i, v in pairs(stack) do
                        if v == LocalPlayer.Name or v == "Ban" or v == "Packet" or v == "Network" then
                            counter = counter + 1
                        elseif type(v) == "number" then
                            if type(expected) == "number" then
                                expected = expected + v
                            else
                                expected = v
                            end
                        end
                    end

                    if counter == expected then
                        eval1 = {true, counter + 5}
                    end
                end

                if eval1[1] then
                    if #args == eval1[2] then
                        local counter = 0
                        local outgoingkey
                        for i, v in pairs(args) do
                            if v == LocalPlayer.Name or v == "Ban" or v == "Packet" or v == "Network" then
                                counter = counter + 1
                            elseif tostring(i):find("userdata") then
                                outgoingkey = v
                            end
                        end
                        if counter >= eval1[2] then
                            eval2 = {true, outgoingkey}
                        end
                    end
                end

                if eval2[1] then
                    pcall(function()
                        NetworkClient:SetOutgoingKBPSLimit(0)
                    end)
                    LocalPlayer:Kick("Game attempted to ban you but was blocked")
                    return task.wait(9e9) 
                end
            end

            return X(self, ...)
        end)
    end)
end

----------------------------------------------------
-- 🎨 LOAD THE VISUAL MENU GUI (ADDED HERE)
----------------------------------------------------
task.spawn(function()
    local success, err = pcall(function()
        -- REPLACE THIS URL with your actual Raw script link:
        loadstring(game:HttpGet("https://raw.githubusercontent.com/Badboy45099/Tite/refs/heads/main/WOLF.lua"))()
    end)
    
    if success then
        print("Menu script loaded successfully!")
    else
        warn("Failed to load the menu UI: " .. tostring(err))
    end
end)
