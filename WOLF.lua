-- Services
local CoreGui = game:GetService("CoreGui")
local Lighting = game:GetService("Lighting")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UIS = game:GetService("UserInputService")
local HttpService = game:GetService("HttpService")
local Workspace = game:GetService("Workspace")
local TweenService = game:GetService("TweenService")
local TeleportService = game:GetService("TeleportService")

local LocalPlayer = Players.LocalPlayer

----------------------------------------------------
-- HIDDEN / PROTECTED GUI CONTAINER (ANTI-DETECTION)
----------------------------------------------------
local function GetSafeGuiParent()
    if gethui then
        return gethui()
    elseif syn and syn.protect_gui then
        local folder = Instance.new("Folder")
        syn.protect_gui(folder)
        folder.Parent = CoreGui
        return folder
    else
        return CoreGui
    end
end

local SafeParent = GetSafeGuiParent()

-- Anti-Ban & Kick
if LocalPlayer and LocalPlayer.Kick then
    pcall(function()
        local oldKick
        oldKick = hookfunction(LocalPlayer.Kick, function(self, reason)
            if self == LocalPlayer then
                return nil -- Silently blocks local game scripts from kicking you (Error 267)
            end
            return oldKick(self, reason)
        end)
    end)
end

-- Safely drops background telemetry/ban report logs sent by game scripts
pcall(function()
    local mt = getrawmetatable(game)
    local oldNamecall = mt.__namecall
    setreadonly(mt, false)

    mt.__namecall = newcclosure(function(self, ...)
        local method = getnamecallmethod()
        
        if tostring(method) == "FireServer" or tostring(method) == "InvokeServer" then
            local name = tostring(self.Name):lower()
            if name:find("cheat") or name:find("detection") or name:find("report") or name:find("kick") or name:find("telemetry") or name:find("check") then
                return nil -- Drops the data report so the server never flags you
            end
        end
        
        return oldNamecall(self, ...)
    end)
    setreadonly(mt, true)
end)

-- Prevent duplicate script executions on the same place
if getgenv().AutoLoadInitialized then
    return
end
getgenv().AutoLoadInitialized = true

----------------------------------------------------
-- AUTO-EXECUTE TELEPORT QUEUE
----------------------------------------------------
local function SetupAutoExecuteOnTeleport()
    local queueFunction = queue_on_teleport or (syn and syn.queue_on_teleport) or queueonteleport
    if queueFunction then
        queueFunction([[
            repeat task.wait() until game:IsLoaded()
            task.wait(2)
            loadstring(game:HttpGet("https://raw.githubusercontent.com/Badboy45099/Tite/refs/heads/main/WOLF.lua"))()
        ]])
    end
end

SetupAutoExecuteOnTeleport()
TeleportService.TeleportInitFailed:Connect(SetupAutoExecuteOnTeleport)

----------------------------------------------------
-- CLEANUP EXISTING GUI ELEMENTS & CONNECTIONS  
----------------------------------------------------
if CoreGui:FindFirstChild("FluentUI_CustomMenu") then CoreGui:FindFirstChild("FluentUI_CustomMenu"):Destroy() end
if CoreGui:FindFirstChild("WolfMenuToggle") then CoreGui:FindFirstChild("WolfMenuToggle"):Destroy() end
 
if getgenv().WolfFreecamConns then
    for _, conn in ipairs(getgenv().WolfFreecamConns) do conn:Disconnect() end
    table.clear(getgenv().WolfFreecamConns)
else
    getgenv().WolfFreecamConns = {}
end
 
if getgenv().WolfFreecamActive then
    getgenv().WolfFreecamActive = false
    local cam = workspace.CurrentCamera
    if cam then cam.CameraType = Enum.CameraType.Custom end
    if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
        LocalPlayer.Character.HumanoidRootPart.Anchored = false
    end
    UIS.MouseBehavior = Enum.MouseBehavior.Default
end
 
if getgenv().WolfXRayConns then
    for _, conn in ipairs(getgenv().WolfXRayConns) do conn:Disconnect() end
    table.clear(getgenv().WolfXRayConns)
else
    getgenv().WolfXRayConns = {}
end
 
if getgenv().WolfInfJumpConn then getgenv().WolfInfJumpConn:Disconnect() getgenv().WolfInfJumpConn = nil end
if getgenv().WolfNoclipConn then getgenv().WolfNoclipConn:Disconnect() getgenv().WolfNoclipConn = nil end
if getgenv().WolfNoclipDescendantConn then getgenv().WolfNoclipDescendantConn:Disconnect() getgenv().WolfNoclipDescendantConn = nil end
 
if getgenv().WolfFlyActive then getgenv().WolfFlyActive = false end
if getgenv().WolfFlyKeyDownConn then getgenv().WolfFlyKeyDownConn:Disconnect() getgenv().WolfFlyKeyDownConn = nil end
if getgenv().WolfFlyKeyUpConn then getgenv().WolfFlyKeyUpConn:Disconnect() getgenv().WolfFlyKeyUpConn = nil end
 
if LocalPlayer.Character then
    local torso = LocalPlayer.Character:FindFirstChild("UpperTorso") or LocalPlayer.Character:FindFirstChild("Torso")
    if torso then
        for _, obj in ipairs(torso:GetChildren()) do
            if obj:IsA("BodyGyro") or obj:IsA("BodyVelocity") then obj:Destroy() end
        end
    end
    local hum = LocalPlayer.Character:FindFirstChildWhichIsA("Humanoid")
    if hum then hum.PlatformStand = false end
end
 
if getgenv().WolfTpGui then getgenv().WolfTpGui:Destroy() getgenv().WolfTpGui = nil end
if getgenv().WolfSeatHeartbeat then getgenv().WolfSeatHeartbeat:Disconnect() getgenv().WolfSeatHeartbeat = nil end
if CoreGui:FindFirstChild("Full_ESP_Folder") then CoreGui:FindFirstChild("Full_ESP_Folder"):Destroy() end
if getgenv().WolfESPLoop then getgenv().WolfESPLoop:Disconnect() getgenv().WolfESPLoop = nil end
 
if getgenv().WolfESPObjects then
    pcall(function()
        for plr, drawings in pairs(getgenv().WolfESPObjects) do
            for _, obj in pairs(drawings) do
                if typeof(obj) == "Instance" then obj:Destroy()
                elseif typeof(obj) == "table" and obj.Remove then obj:Remove() end
            end
        end
    end)
    table.clear(getgenv().WolfESPObjects)
end
 
for _, child in ipairs(Lighting:GetChildren()) do
    if child:IsA("DepthOfFieldEffect") or child.Name:find("Blur") or child.Name:find("Acrylic") then child:Destroy() end
end

----------------------------------------------------
-- HELPER FUNCTIONS
----------------------------------------------------
local function setCharacterTransparency(transparency)
    local char = LocalPlayer.Character
    if char then
        for _, part in ipairs(char:GetDescendants()) do
            if part:IsA("BasePart") and part.Name ~= "HumanoidRootPart" then
                part.Transparency = transparency
            end
        end
    end
end

----------------------------------------------------
-- CONFIGURATION & AUTO-SAVE SYSTEM
----------------------------------------------------
local ConfigFileName = "FluentUI_Settings.json"

local Settings = {
    XRay = false,
    InfiniteJump = false,
    JumpForce = 35,
    Noclip = false,
    TpMode = "Random",
    Invisible = false,
    WolfBgWhite = false,
    Theme = "Dark",
    PlayerHighlightEnabled = false,
    HighlightColor = Color3.fromRGB(136, 8, 8),
    BoxColor = Color3.fromRGB(255, 255, 255),
    TracerColor = Color3.fromRGB(255, 50, 50),
    NameTagColor = Color3.fromRGB(255, 255, 255),
    SelectedFeatures = {
        ["Highlight Player"] = false,
        ["Box"] = false,
        ["Ray Lines"] = false,
        ["Health Bar"] = false,
        ["Name Tag"] = false
    }
}

-- Convert Color3 objects to tables for JSON serialization
local function encodeSettings(tbl)
    local copy = {}
    for k, v in pairs(tbl) do
        if type(v) == "userdata" and typeof(v) == "Color3" then
            copy[k] = {R = v.R, G = v.G, B = v.B}
        elseif type(v) == "table" then
            copy[k] = encodeSettings(v)
        else
            copy[k] = v
        end
    end
    return copy
end

-- Reconstruct Color3 objects after loading from JSON
local function decodeSettings(target, loaded)
    for k, v in pairs(loaded) do
        if type(v) == "table" and v.R and v.G and v.B then
            target[k] = Color3.new(v.R, v.G, v.B)
        elseif type(v) == "table" and type(target[k]) == "table" then
            decodeSettings(target[k], v)
        else
            target[k] = v
        end
    end
end

local function saveConfig()
    if writefile then
        pcall(function()
            local data = encodeSettings(Settings)
            writefile(ConfigFileName, HttpService:JSONEncode(data))
        end)
    end
end

local function loadConfig()
    if readfile and isfile and isfile(ConfigFileName) then
        local success, result = pcall(function()
            return HttpService:JSONDecode(readfile(ConfigFileName))
        end)
        if success and type(result) == "table" then
            decodeSettings(Settings, result)
        end
    end
end

loadConfig()

----------------------------------------------------
-- LOAD FLUENT LIBRARIES
----------------------------------------------------
local Fluent = loadstring(game:HttpGet("https://github.com/dawid-scripts/Fluent/releases/latest/download/main.lua"))()

local Window = Fluent:CreateWindow({
    Title = "WOLF Tools 🐺",
    SubTitle = "by Fluent UI",
    TabWidth = 130,
    Size = UDim2.fromOffset(520, 350),
    Acrylic = false,
    Theme = Settings.Theme,
    MinimizeKey = Enum.KeyCode.LeftControl
})

task.spawn(function()
    task.wait(0.2)
    local ScreenGui = CoreGui:FindFirstChild("Fluent") or CoreGui:FindFirstChild("ScreenGui")
    if ScreenGui then
        ScreenGui.Name = "FluentUI_CustomMenu"
        
        for _, child in ipairs(ScreenGui:GetChildren()) do
            if child:IsA("Frame") and child.Size.X.Scale == 1 and child.Size.Y.Scale == 1 then
                child.BackgroundTransparency = 1
            end
        end
    end
end)

local Tabs = {
    Player = Window:AddTab({ Title = "Player", Icon = "user" }),
    Vision = Window:AddTab({ Title = "Vision", Icon = "eye" }),
    Special = Window:AddTab({ Title = "Special", Icon = "skull" }),
    Games = Window:AddTab({ Title = "Games", Icon = "gamepad-2" }),
    Settings = Window:AddTab({ Title = "Settings", Icon = "settings" })
}

getgenv().Tabs = Tabs

----------------------------------------------------
-- TOGGLE BUTTON
----------------------------------------------------
local ToggleGui = Instance.new("ScreenGui")
ToggleGui.Name = "WolfMenuToggle"
ToggleGui.ResetOnSpawn = false
ToggleGui.Parent = CoreGui

local ToggleButton = Instance.new("ImageButton")
ToggleButton.Name = "WolfIconBtn"
ToggleButton.Size = UDim2.new(0, 45, 0, 45)
ToggleButton.Position = UDim2.new(0, 20, 0.5, -22)
ToggleButton.Image = "rbxthumb://type=Asset&id=70689077582089&w=150&h=150"
ToggleButton.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
ToggleButton.BackgroundTransparency = Settings.WolfBgWhite and 0 or 1
ToggleButton.BorderSizePixel = 0
ToggleButton.Active = true
ToggleButton.Draggable = true
ToggleButton.Parent = ToggleGui

local ToggleCorner = Instance.new("UICorner")
ToggleCorner.CornerRadius = UDim.new(0, 10)
ToggleCorner.Parent = ToggleButton

ToggleButton.MouseButton1Click:Connect(function()
    if Window then
        Window:Minimize()
    end
end)

----------------------------------------------------
-- PLAYER TAB (Infinite Jump)
----------------------------------------------------
local function applyJumpPower(hum)
    if not hum then return end
    hum.UseJumpPower = true
    hum.JumpPower = Settings.JumpForce
end

local function applyInfJumpState(state)
    if getgenv().WolfInfJumpConn then
        getgenv().WolfInfJumpConn:Disconnect()
        getgenv().WolfInfJumpConn = nil
    end

    if state then
        getgenv().WolfInfJumpConn = UIS.JumpRequest:Connect(function()
            local char = LocalPlayer.Character
            if not char then return end
            local hum = char:FindFirstChildWhichIsA("Humanoid")
            if hum and hum:GetState() ~= Enum.HumanoidStateType.Dead then
                hum.UseJumpPower = true
                hum.JumpPower = Settings.JumpForce
                hum:ChangeState(Enum.HumanoidStateType.Jumping)
            end
        end)
    end
end

LocalPlayer.CharacterAdded:Connect(function(char)
    local hum = char:WaitForChild("Humanoid", 5)
    if hum then
        applyJumpPower(hum)
    end
end)

local InfJumpToggle = Tabs.Player:AddToggle("InfJumpToggle", {
    Title = "Infinite Jump",
    Default = Settings.InfiniteJump
})

InfJumpToggle:OnChanged(function(state)
    Settings.InfiniteJump = state
    applyInfJumpState(state)
    saveConfig()
end)

local JumpForceSlider = Tabs.Player:AddSlider("JumpForceSlider", {
    Title = "Jump Force",
    Default = Settings.JumpForce,
    Min = 10,
    Max = 150,
    Rounding = 0
})

JumpForceSlider:OnChanged(function(val)
    Settings.JumpForce = val
    saveConfig()
    if LocalPlayer.Character then
        local hum = LocalPlayer.Character:FindFirstChildWhichIsA("Humanoid")
        applyJumpPower(hum)
    end
end)

if Settings.InfiniteJump then applyInfJumpState(true) end

----------------------------------------------------
-- WALKSPEED DISPLAY & MODULE
----------------------------------------------------
local successModule, WalkSpeedSliderModule = pcall(function()
    return loadstring(game:HttpGet("https://pastebin.com/raw/bZiCG1G9"))()
end)

local SpeedTitle = Tabs.Player:AddParagraph({
    Title = "WalkSpeed: 16",
    Content = "\n"
})

if successModule and type(WalkSpeedSliderModule) == "table" and WalkSpeedSliderModule.Create then
    WalkSpeedSliderModule.Create(SpeedTitle, LocalPlayer, UIS)
end

----------------------------------------------------
-- NOCLIP (FIXED: FORCED COLLISION RESET ON OFF)
----------------------------------------------------
local function setNoclipState(state)
    if getgenv().WolfNoclipConn then
        getgenv().WolfNoclipConn:Disconnect()
        getgenv().WolfNoclipConn = nil
    end

    if state then
        getgenv().WolfNoclipConn = RunService.Stepped:Connect(function()
            local char = LocalPlayer.Character
            if char then
                for _, part in ipairs(char:GetDescendants()) do
                    if part:IsA("BasePart") then
                        part.CanCollide = false
                    end
                end
            end
        end)
    else
        -- HARD RESET COLLISION ON EVERY PART WHEN TURNED OFF
        local char = LocalPlayer.Character
        if char then
            for _, part in ipairs(char:GetDescendants()) do
                if part:IsA("BasePart") then
                    if part.Name == "HumanoidRootPart" then
                        part.CanCollide = false
                    else
                        part.CanCollide = true
                    end
                end
            end
            local hum = char:FindFirstChildWhichIsA("Humanoid")
            if hum then
                hum:ChangeState(Enum.HumanoidStateType.GettingUp)
            end
        end
    end
end

local NoclipToggle = Tabs.Player:AddToggle("NoclipToggle", {
    Title = "Noclip",
    Default = Settings.Noclip
})

NoclipToggle:OnChanged(function(state)
    Settings.Noclip = state
    setNoclipState(state)
    saveConfig()
end)

if Settings.Noclip then setNoclipState(true) end

----------------------------------------------------
-- ANIMATED SUPERMAN FLY WITH LEVITATION HOVER
----------------------------------------------------
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local LocalPlayer = Players.LocalPlayer

local flySpeed = 50
local maxFlySpeed = 500

-- Levitation settings (adjust if you want bigger/faster float)
local hoverHeight = 2 -- How high up and down it floats
local hoverSpeed = 3    -- How fast it floats up and down

-- Lerp helper for smooth number blending
local function lerp(a, b, t)
    return a + (b - a) * t
end

-- Safe C0 setter to prevent read-only crashes in RenderStepped
local function safeSetC0(joint, cframe)
    if joint then
        pcall(function()
            joint.C0 = cframe
        end)
    end
end

local function startFlying()
    if getgenv().WolfFlyActive then return end
    getgenv().WolfFlyActive = true

    task.spawn(function()
        local char = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
        local hum = char:WaitForChild("Humanoid", 5)
        if not hum then return end

        local torso = hum.RigType == Enum.HumanoidRigType.R15 and char:WaitForChild("UpperTorso", 5) or char:WaitForChild("Torso", 5)
        if not torso then return end

        local camera = workspace.CurrentCamera
        local currentSpeed = flySpeed

        -- Create BodyGyro & BodyVelocity for rigid control
        local bg = Instance.new("BodyGyro")
        bg.Name = "WolfFlyGyro"
        bg.P = 15000
        bg.maxTorque = Vector3.new(9e9, 9e9, 9e9)
        bg.cframe = torso.CFrame
        bg.Parent = torso

        local bv = Instance.new("BodyVelocity")
        bv.Name = "WolfFlyVelocity"
        bv.velocity = Vector3.zero
        bv.maxForce = Vector3.new(9e9, 9e9, 9e9)
        bv.Parent = torso

        hum:ChangeState(Enum.HumanoidStateType.Physics)
        hum.PlatformStand = true

        -- Animation Blend States
        local flyProgress = 0

        getgenv().WolfFlyLoop = RunService.RenderStepped:Connect(function(deltaTime)
            if not getgenv().WolfFlyActive or not char or not char.Parent or not hum or hum.Health <= 0 then
                if getgenv().WolfFlyLoop then
                    getgenv().WolfFlyLoop:Disconnect()
                    getgenv().WolfFlyLoop = nil
                end
                return
            end

            local moveDir = hum.MoveDirection
            local isMoving = moveDir.Magnitude > 0

            -- Smoothly interpolate state transitions
            if isMoving then
                flyProgress = math.min(1, flyProgress + deltaTime * 6)
                currentSpeed = math.min(maxFlySpeed, currentSpeed + 0.8)
            else
                flyProgress = math.max(0, flyProgress - deltaTime * 5)
                currentSpeed = math.max(0, currentSpeed - 2)
            end

            ----------------------------------------------------
            -- SMOOTH ARM ANIMATION
            ----------------------------------------------------
            local armAngle = lerp(0, 180, flyProgress)
            
            if hum.RigType == Enum.HumanoidRigType.R15 then
                local shoulderL = char:FindFirstChild("LeftShoulder", true)
                local shoulderR = char:FindFirstChild("RightShoulder", true)
                safeSetC0(shoulderL, CFrame.new(-1, 0.5, 0) * CFrame.Angles(math.rad(armAngle), 0, 0))
                safeSetC0(shoulderR, CFrame.new(1, 0.5, 0) * CFrame.Angles(math.rad(armAngle), 0, 0))
            else
                local shoulderL = torso:FindFirstChild("Left Shoulder")
                local shoulderR = torso:FindFirstChild("Right Shoulder")
                safeSetC0(shoulderL, CFrame.new(-1.5, 0.5, 0) * CFrame.Angles(math.rad(armAngle), 0, 0))
                safeSetC0(shoulderR, CFrame.new(1.5, 0.5, 0) * CFrame.Angles(math.rad(armAngle), 0, 0))
            end

            ----------------------------------------------------
            -- MOVEMENT, ROTATION & LEVITATION (IDLE HOVER)
            ----------------------------------------------------
            local camCF = camera.CFrame
            
            if isMoving then
                local lookVec = camCF.LookVector
                local rightVec = camCF.RightVector
                
                local forwardBackward = moveDir:Dot(camCF.LookVector)
                local leftRight = moveDir:Dot(camCF.RightVector)
                
                local velocityVector = (lookVec * forwardBackward) + (rightVec * leftRight)
                bv.velocity = velocityVector * currentSpeed
            else
                -- Calculate smooth sine wave for floating effect when standing still
                local hoverOffset = math.sin(os.clock() * hoverSpeed) * hoverHeight
                bv.velocity = Vector3.new(0, hoverOffset, 0)
            end

            local pitchAngle = lerp(0, -80, flyProgress)
            bg.cframe = camCF * CFrame.Angles(math.rad(pitchAngle), 0, 0)
        end)
    end)
end

local function stopFlying()
    getgenv().WolfFlyActive = false
    
    if getgenv().WolfFlyLoop then
        getgenv().WolfFlyLoop:Disconnect()
        getgenv().WolfFlyLoop = nil
    end

    local char = LocalPlayer.Character
    if char then
        local hum = char:FindFirstChildWhichIsA("Humanoid")
        local torso = char:FindFirstChild("UpperTorso") or char:FindFirstChild("Torso")

        -- Restore original arm joints safely
        if hum and torso then
            if hum.RigType == Enum.HumanoidRigType.R15 then
                local shoulderL = char:FindFirstChild("LeftShoulder", true)
                local shoulderR = char:FindFirstChild("RightShoulder", true)
                safeSetC0(shoulderL, CFrame.new(-1, 0.5, 0))
                safeSetC0(shoulderR, CFrame.new(1, 0.5, 0))
            else
                local shoulderL = torso:FindFirstChild("Left Shoulder")
                local shoulderR = torso:FindFirstChild("Right Shoulder")
                safeSetC0(shoulderL, CFrame.new(-1.5, 0.5, 0))
                safeSetC0(shoulderR, CFrame.new(1.5, 0.5, 0))
            end
            
            if torso:FindFirstChild("WolfFlyGyro") then torso.WolfFlyGyro:Destroy() end
            if torso:FindFirstChild("WolfFlyVelocity") then torso.WolfFlyVelocity:Destroy() end
        end

        if hum then 
            hum.PlatformStand = false
            hum:ChangeState(Enum.HumanoidStateType.GettingUp)
        end
    end
end

-- UI Controls
local FlyToggle = Tabs.Player:AddToggle("FlyToggle", {
    Title = "Superman Fly",
    Default = false
})

FlyToggle:OnChanged(function(state)
    if state then
        startFlying()
    else
        stopFlying()
    end
end)

local FlySpeedSlider = Tabs.Player:AddSlider("FlySpeedSlider", {
    Title = "Fly Speed",
    Default = 50,
    Min = 10,
    Max = 500,
    Rounding = 0
})

FlySpeedSlider:OnChanged(function(val)
    flySpeed = val
end)

LocalPlayer.CharacterAdded:Connect(function()
    if getgenv().WolfFlyActive then
        stopFlying()
        FlyToggle:SetValue(false)
    end
end)

----------------------------------------------------
-- UNIFIED TP-FLY FOLLOWER + CLEANUP
----------------------------------------------------
if getgenv().WolfFollowLoop then
    getgenv().WolfFollowLoop:Disconnect()
    getgenv().WolfFollowLoop = nil
end

local function FindTargetPlayer(targetString)
    if not targetString or targetString == "" then return nil end
    for _, plr in ipairs(Players:GetPlayers()) do
        if plr ~= LocalPlayer then
            local formattedName = plr.DisplayName .. " (@" .. plr.Name .. ")"
            if formattedName == targetString or plr.Name == targetString or plr.DisplayName == targetString then
                return plr
            end
        end
    end
    return nil
end

local function StopFollowing()
    getgenv().WolfFollowActive = false

    if getgenv().WolfFollowLoop then
        getgenv().WolfFollowLoop:Disconnect()
        getgenv().WolfFollowLoop = nil
    end

    local char = LocalPlayer.Character
    if char then
        local hrp = char:FindFirstChild("HumanoidRootPart")
        local hum = char:FindFirstChildWhichIsA("Humanoid")
        local torso = char:FindFirstChild("UpperTorso") or char:FindFirstChild("Torso")

        if torso then
            for _, child in ipairs(torso:GetChildren()) do
                if child:IsA("BodyGyro") or child:IsA("BodyVelocity") or child.Name:find("Follow") then
                    child:Destroy()
                end
            end
        end

        if hrp then
            hrp.Velocity = Vector3.zero
            hrp.RotVelocity = Vector3.zero
            hrp.AssemblyLinearVelocity = Vector3.zero
            hrp.AssemblyAngularVelocity = Vector3.zero
        end

        if hum then 
            hum.PlatformStand = false
            hum.WalkSpeed = 16
            hum.JumpPower = 50
            hum:ChangeState(Enum.HumanoidStateType.Freefall)
        end
    end
end

local function StartFollowing()
    if getgenv().WolfFollowActive then return end
    getgenv().WolfFollowActive = true

    task.spawn(function()
        local char = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
        local hum = char:WaitForChild("Humanoid", 5)
        local hrp = char:WaitForChild("HumanoidRootPart", 5)
        if not hum or not hrp then return end

        local torso = hum.RigType == Enum.HumanoidRigType.R15 and char:WaitForChild("UpperTorso", 5) or char:WaitForChild("Torso", 5)
        if not torso then return end

        for _, child in ipairs(torso:GetChildren()) do
            if child:IsA("BodyGyro") or child:IsA("BodyVelocity") then
                child:Destroy()
            end
        end

        local bg = Instance.new("BodyGyro")
        bg.Name = "FollowGyro"
        bg.P = 20000
        bg.maxTorque = Vector3.new(9e9, 9e9, 9e9)
        bg.cframe = torso.CFrame
        bg.Parent = torso

        local bv = Instance.new("BodyVelocity")
        bv.Name = "FollowVelocity"
        bv.velocity = Vector3.zero
        bv.maxForce = Vector3.new(9e9, 9e9, 9e9)
        bv.Parent = torso

        getgenv().WolfFollowLoop = RunService.RenderStepped:Connect(function()
            if not getgenv().WolfFollowActive or not char or not char.Parent or not hum or hum.Health <= 0 then
                StopFollowing()
                return
            end

            local targetPlayer = FindTargetPlayer(getgenv().FollowTargetName)
            if targetPlayer and targetPlayer.Character and targetPlayer.Character:FindFirstChild("HumanoidRootPart") then
                local targetChar = targetPlayer.Character
                local targetHrp = targetChar.HumanoidRootPart
                local targetHum = targetChar:FindFirstChildWhichIsA("Humanoid")

                if targetHum then
                    hum.WalkSpeed = targetHum.WalkSpeed
                    hum.JumpPower = targetHum.JumpPower
                end

                local targetPos = targetHrp.Position - (targetHrp.CFrame.LookVector * 3) + Vector3.new(0, 1.5, 0)
                local distance = (targetPos - hrp.Position).Magnitude

                if distance > 40 then
                    hrp.CFrame = CFrame.new(targetPos, targetHrp.Position)
                    bv.velocity = Vector3.zero
                elseif distance > 1 then
                    bv.velocity = (targetPos - hrp.Position).Unit * math.clamp(distance * 10, 15, 80)
                    bg.cframe = CFrame.lookAt(hrp.Position, targetHrp.Position)
                else
                    bv.velocity = Vector3.zero
                    bg.cframe = targetHrp.CFrame
                end
            else
                bv.velocity = Vector3.zero
            end
        end)
    end)
end

local function GetPlayerNamesList()
    local nameList = {}
    for _, plr in ipairs(Players:GetPlayers()) do
        if plr ~= LocalPlayer then
            table.insert(nameList, plr.DisplayName .. " (@" .. plr.Name .. ")")
        end
    end
    if #nameList == 0 then
        table.insert(nameList, "No Players In Server")
    end
    return nameList
end

----------------------------------------------------
-- SAFELY ATTACH UI CONTROLS
----------------------------------------------------
task.spawn(function()
    repeat task.wait() until Tabs.Player ~= nil

    local PlayerSection = Tabs.Player:AddSection("Target Controls")

    local PlayerDropdown = PlayerSection:AddDropdown("PlayerSelectDropdown", {
        Title = "Select Target Player",
        Values = GetPlayerNamesList(),
        Multi = false,
        Default = 1,
        Callback = function(selected)
            getgenv().FollowTargetName = selected
        end
    })

    Players.PlayerAdded:Connect(function()
        PlayerDropdown:SetValues(GetPlayerNamesList())
    end)
    Players.PlayerRemoving:Connect(function()
        PlayerDropdown:SetValues(GetPlayerNamesList())
    end)

    PlayerSection:AddToggle("FollowToggle", {
        Title = "Enable Sync TP-Fly Follow",
        Default = false,
        Callback = function(state)
            if state then 
                StartFollowing() 
            else 
                StopFollowing() 
            end
        end
    })
end)

----------------------------------------------------
-- TP
----------------------------------------------------
local successModule, TeleportModule = pcall(function()
    return loadstring(game:HttpGet("https://raw.githubusercontent.com/Badboy45099/Tite/refs/heads/main/TP.lua"))()
end)

if successModule and type(TeleportModule) == "table" and TeleportModule.Create then
    TeleportModule.Create(Tabs.Player, Fluent)
end

----------------------------------------------------
-- ESP SYSTEM
----------------------------------------------------
local Camera = workspace.CurrentCamera
local espGuiContainer = CoreGui:FindFirstChild("Full_ESP_Container")
if not espGuiContainer then
    local success, _ = pcall(function()
        espGuiContainer = Instance.new("ScreenGui")
        espGuiContainer.Name = "Full_ESP_Container"
        espGuiContainer.ResetOnSpawn = false
        espGuiContainer.IgnoreGuiInset = true -- THIS FIXES THE DOWNWARD OFFSET
        espGuiContainer.Parent = CoreGui
    end)
    if not success then
        espGuiContainer = Instance.new("ScreenGui")
        espGuiContainer.Name = "Full_ESP_Container"
        espGuiContainer.ResetOnSpawn = false
        espGuiContainer.IgnoreGuiInset = true -- THIS FIXES THE DOWNWARD OFFSET
        espGuiContainer.Parent = LocalPlayer:WaitForChild("PlayerGui")
    end
end

local espFolder = CoreGui:FindFirstChild("Full_ESP_Folder") or Instance.new("Folder")
espFolder.Name = "Full_ESP_Folder"
espFolder.Parent = CoreGui

getgenv().WolfESPObjects = getgenv().WolfESPObjects or {}
local activeESPObjects = getgenv().WolfESPObjects
local renderConnection = nil

local function removePlayerESP(plr)
    if activeESPObjects[plr] then
        for _, obj in pairs(activeESPObjects[plr]) do
            pcall(function()
                if typeof(obj) == "Instance" then
                    obj:Destroy()
                end
            end)
        end
        activeESPObjects[plr] = nil
    end
end

local function createPlayerESP(plr)
    if plr == LocalPlayer then return end
    removePlayerESP(plr)

    local drawings = {}

    -- 1. Highlight (Roblox Native)
    local highlight = Instance.new("Highlight")
    highlight.Name = plr.Name .. "_Highlight"
    highlight.FillColor = Settings.HighlightColor
    highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
    highlight.FillTransparency = 0.5
    highlight.OutlineColor = Color3.fromRGB(255, 255, 255)
    highlight.Enabled = false
    highlight.Parent = espFolder
    drawings.Highlight = highlight

    -- 2. Box (Gui Frame with UIStroke)
    local box = Instance.new("Frame")
    box.BackgroundTransparency = 1
    box.Visible = false
    box.Parent = espGuiContainer

    local boxStroke = Instance.new("UIStroke")
    boxStroke.Thickness = 1.5
    boxStroke.Color = Settings.BoxColor
    boxStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    boxStroke.Parent = box
    drawings.Box = box
    drawings.BoxStroke = boxStroke

    -- 3. Line/Tracer (Gui Frame acting as line)
    local line = Instance.new("Frame")
    line.AnchorPoint = Vector2.new(0.5, 0.5)
    line.BorderSizePixel = 0
    line.BackgroundColor3 = Settings.TracerColor
    line.Visible = false
    line.Parent = espGuiContainer
    drawings.Line = line

    -- 4. Health Bar Background
    local healthBg = Instance.new("Frame")
    healthBg.BorderSizePixel = 0
    healthBg.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
    healthBg.Visible = false
    healthBg.Parent = espGuiContainer
    drawings.HealthBg = healthBg

    -- 5. Health Bar Main
    local healthMain = Instance.new("Frame")
    healthMain.BorderSizePixel = 0
    healthMain.BackgroundColor3 = Color3.fromRGB(0, 255, 0)
    healthMain.Visible = false
    healthMain.Parent = espGuiContainer
    drawings.HealthMain = healthMain

    -- 6. Name Text Label
    local nameText = Instance.new("TextLabel")
    nameText.BackgroundTransparency = 1
    nameText.TextSize = 14
    nameText.Font = Enum.Font.SourceSansBold
    nameText.TextColor3 = Settings.NameTagColor
    nameText.TextStrokeTransparency = 0
    nameText.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
    nameText.Visible = false
    nameText.Parent = espGuiContainer
    drawings.NameText = nameText

    activeESPObjects[plr] = drawings
end

local function updateESPLoop()
    if renderConnection then return end

    renderConnection = RunService.RenderStepped:Connect(function()
        local selected = Settings.SelectedFeatures or {}

        for plr, drawings in pairs(activeESPObjects) do
            local char = plr.Character
            local hrp = char and char:FindFirstChild("HumanoidRootPart")
            local head = char and char:FindFirstChild("Head")
            local hum = char and char:FindFirstChildWhichIsA("Humanoid")

            if char and hrp and head and hum and hum.Health > 0 then
                -- Define Top (just above head) and Bottom (at feet) in 3D space
                local topWorld = head.Position + Vector3.new(0, 0.5, 0)
                local bottomWorld = hrp.Position - Vector3.new(0, 3.5, 0)

                -- Convert to 2D Screen Space
                local topPos, onScreenTop = Camera:WorldToViewportPoint(topWorld)
                local bottomPos, onScreenBottom = Camera:WorldToViewportPoint(bottomWorld)

                if onScreenTop or onScreenBottom then
                    -- Calculate precise Height and Width for the 2D Box
                    local height = math.abs(topPos.Y - bottomPos.Y)
                    local width = height / 1.8 -- 1.8 is the standard Roblox avatar ratio
                    
                    local boxX = topPos.X - (width / 2)
                    local boxY = topPos.Y

                    -- 1. Highlight
                    if selected["Highlight Player"] then
                        drawings.Highlight.Adornee = char
                        drawings.Highlight.FillColor = Settings.HighlightColor
                        drawings.Highlight.Enabled = true
                    else
                        drawings.Highlight.Enabled = false
                    end

                    -- 2. Box
                    if selected["Box"] then
                        drawings.Box.Size = UDim2.new(0, width, 0, height)
                        drawings.Box.Position = UDim2.new(0, boxX, 0, boxY)
                        drawings.BoxStroke.Color = Settings.BoxColor
                        drawings.Box.Visible = true
                    else
                        drawings.Box.Visible = false
                    end

                    -- 3. Ray Lines / Tracing
                    if selected["Ray Lines"] then
                        local startPos = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y)
                        local targetPos = Vector2.new(bottomPos.X, bottomPos.Y) -- Tracers point to feet
                        local distance = (targetPos - startPos).Magnitude
                        local angle = math.atan2(targetPos.Y - startPos.Y, targetPos.X - startPos.X)

                        drawings.Line.Size = UDim2.new(0, distance, 0, 1.5)
                        drawings.Line.Position = UDim2.new(0, (startPos.X + targetPos.X) / 2, 0, (startPos.Y + targetPos.Y) / 2)
                        drawings.Line.Rotation = math.deg(angle)
                        drawings.Line.BackgroundColor3 = Settings.TracerColor
                        drawings.Line.Visible = true
                    else
                        drawings.Line.Visible = false
                    end

                    -- 4. Health Bar
                    if selected["Health Bar"] then
                        local barWidth = 3
                        local healthPercent = math.clamp(hum.Health / hum.MaxHealth, 0, 1)
                        local barHeight = height * healthPercent

                        drawings.HealthBg.Size = UDim2.new(0, barWidth + 2, 0, height + 2)
                        drawings.HealthBg.Position = UDim2.new(0, boxX - (barWidth + 4), 0, boxY - 1)
                        drawings.HealthBg.Visible = true

                        drawings.HealthMain.Size = UDim2.new(0, barWidth, 0, barHeight)
                        drawings.HealthMain.Position = UDim2.new(0, boxX - (barWidth + 3), 0, boxY + (height - barHeight))
                        drawings.HealthMain.BackgroundColor3 = Color3.fromRGB(
                            math.floor(255 * (1 - healthPercent)),
                            math.floor(255 * healthPercent),
                            0
                        )
                        drawings.HealthMain.Visible = true
                    else
                        drawings.HealthBg.Visible = false
                        drawings.HealthMain.Visible = false
                    end

                    -- 5. Name Tag
                    if selected["Name Tag"] then
                        drawings.NameText.Text = plr.DisplayName .. " (@" .. plr.Name .. ")"
                        drawings.NameText.Size = UDim2.new(0, 200, 0, 18)
                        drawings.NameText.Position = UDim2.new(0, topPos.X - 100, 0, boxY - 20)
                        drawings.NameText.TextColor3 = Settings.NameTagColor
                        drawings.NameText.Visible = true
                    else
                        drawings.NameText.Visible = false
                    end
                else
                    for name, drawObj in pairs(drawings) do
                        if name == "Highlight" then
                            drawObj.Enabled = false
                        elseif drawObj:IsA("GuiObject") then
                            drawObj.Visible = false
                        end
                    end
                end
            else
                for name, drawObj in pairs(drawings) do
                    if name == "Highlight" then
                        drawObj.Enabled = false
                    elseif drawObj:IsA("GuiObject") then
                        drawObj.Visible = false
                    end
                end
            end
        end
    end)

    getgenv().WolfESPLoop = renderConnection
end

local function setupESP()
    local function trackPlayer(plr)
        if plr == LocalPlayer then return end

        if plr.Character then
            createPlayerESP(plr)
        end

        plr.CharacterAdded:Connect(function()
            task.wait(0.2)
            createPlayerESP(plr)
        end)
    end

    for _, p in ipairs(Players:GetPlayers()) do
        trackPlayer(p)
    end

    Players.PlayerAdded:Connect(trackPlayer)
    Players.PlayerRemoving:Connect(removePlayerESP)

    updateESPLoop()
end

setupESP()

----------------------------------------------------
-- VISION TAB UI
----------------------------------------------------
local MultiSelect = Tabs.Vision:AddDropdown("ESP", {
    Title = "Select ESP Features",
    Values = {"Highlight Player", "Box", "Ray Lines", "Health Bar", "Name Tag"},
    Multi = true,
    Default = Settings.SelectedFeatures
})

MultiSelect:OnChanged(function(Value)
    Settings.SelectedFeatures = Value
    saveConfig()
end)

local HighlightColorPicker = Tabs.Vision:AddColorpicker("HighlightColorPicker", {
    Title = "Highlight Color",
    Default = Settings.HighlightColor
})

HighlightColorPicker:OnChanged(function(Value)
    Settings.HighlightColor = Value
    saveConfig()
end)

local BoxColorPicker = Tabs.Vision:AddColorpicker("BoxColorPicker", {
    Title = "Box & Line Color",
    Default = Settings.BoxColor
})

BoxColorPicker:OnChanged(function(Value)
    Settings.BoxColor = Value
    Settings.TracerColor = Value
    saveConfig()
end)

----------------------------------------------------
-- BRIGHTNESS SLIDER
----------------------------------------------------

local successBrightness, BrightnessSliderModule = pcall(function()
    return loadstring(game:HttpGet("https://raw.githubusercontent.com/Badboy45099/Tite/refs/heads/main/brightness.lua"))()
end)

local BrightnessTitle = Tabs.Vision:AddParagraph({
    Title = "Brightness: 2.0",
    Content = "\n"
})

if successBrightness and type(BrightnessSliderModule) == "table" and BrightnessSliderModule.Create then
    BrightnessSliderModule.Create(BrightnessTitle, UIS)
end

----------------------------------------------------
-- X-RAY
----------------------------------------------------
local function applyXRayPart(v)
	local char = LocalPlayer.Character
	if v:IsA("BasePart") and (not char or not v:IsDescendantOf(char)) then
		if not v:FindFirstChild("OriginalTransparency") then
			local saved = Instance.new("NumberValue")
			saved.Name = "OriginalTransparency"
			saved.Value = v.Transparency
			saved.Parent = v
		end
		v.Transparency = 0.5
	end
end

local function restoreXRayPart(v)
	if v:IsA("BasePart") then
		local saved = v:FindFirstChild("OriginalTransparency")
		if saved then
			v.Transparency = saved.Value
			saved:Destroy()
		end
	end
end

local function setXRayState(enabled)
	Settings.XRay = enabled
	saveConfig()

	-- Clean up existing connections
	for _, conn in ipairs(getgenv().WolfXRayConns) do
		conn:Disconnect()
	end
	table.clear(getgenv().WolfXRayConns)

	if enabled then
		-- Apply to current map parts
		for _, v in ipairs(workspace:GetDescendants()) do
			applyXRayPart(v)
		end

		-- Auto-apply to streamed / newly added parts
		table.insert(getgenv().WolfXRayConns, workspace.DescendantAdded:Connect(function(v)
			applyXRayPart(v)
		end))

		-- Auto-reapply on character respawn / map reload
		table.insert(getgenv().WolfXRayConns, LocalPlayer.CharacterAdded:Connect(function()
			task.wait(0.5)
			if Settings.XRay then
				for _, v in ipairs(workspace:GetDescendants()) do
					applyXRayPart(v)
				end
			end
		end))
	else
		-- Restore original transparency
		for _, v in ipairs(workspace:GetDescendants()) do
			restoreXRayPart(v)
		end
	end
end

local XRayToggle = Tabs.Vision:AddToggle("XRayToggle", {
    Title = "X-Ray",
    Default = Settings.XRay or false
})

XRayToggle:OnChanged(function(Value)
    setXRayState(Value)
end)

if Settings.XRay then
    setXRayState(true)
end

----------------------------------------------------
-- FREECAM MODULE (Logic & Input Handlers)
----------------------------------------------------
local cam = workspace.CurrentCamera
local freecamEnabled = false
local keysDown = {}
local rotating = false
local touchPos = nil
local yaw = 0
local pitch = 0
local speed = 0.5
local onMobile = UIS.TouchEnabled and not UIS.KeyboardEnabled
local sens = onMobile and 0.6 or 0.3

local function setPlayerFrozen(freeze)
	local char = LocalPlayer.Character
	if char and char:FindFirstChild("HumanoidRootPart") then
		char.HumanoidRootPart.Anchored = freeze
	end
end

local function setFreecamState(enabled)
	freecamEnabled = enabled
	getgenv().WolfFreecamActive = enabled
	
	setPlayerFrozen(enabled)
	
	if enabled then
		-- Sync current camera rotation angles on enable
		local _, currentYaw, _ = cam.CFrame:ToOrientation()
		yaw = math.deg(currentYaw)
		pitch = 0
		cam.CameraType = Enum.CameraType.Scriptable
	else
		keysDown = {}
		rotating = false
		touchPos = nil
		cam.CameraType = Enum.CameraType.Custom
		UIS.MouseBehavior = Enum.MouseBehavior.Default
	end
end

-- Render loop for Movement and Rotation
table.insert(getgenv().WolfFreecamConns, RunService.RenderStepped:Connect(function()
	if not freecamEnabled then return end
	
	if rotating then
		local delta = UIS:GetMouseDelta()
		yaw = yaw - delta.X * sens
		pitch = math.clamp(pitch - delta.Y * sens, -65, 65)
		local rot = CFrame.Angles(0, math.rad(yaw), 0) * CFrame.Angles(math.rad(pitch), 0, 0)
		cam.CFrame = CFrame.new(cam.CFrame.Position) * rot
		UIS.MouseBehavior = Enum.MouseBehavior.LockCurrentPosition
	else
		UIS.MouseBehavior = Enum.MouseBehavior.Default
	end
	
	if keysDown["Enum.KeyCode.W"] then cam.CFrame *= CFrame.new(0, 0, -speed) end
	if keysDown["Enum.KeyCode.A"] then cam.CFrame *= CFrame.new(-speed, 0, 0) end
	if keysDown["Enum.KeyCode.S"] then cam.CFrame *= CFrame.new(0, 0, speed) end
	if keysDown["Enum.KeyCode.D"] then cam.CFrame *= CFrame.new(speed, 0, 0) end
end))

-- Input Begin Listeners
table.insert(getgenv().WolfFreecamConns, UIS.InputBegan:Connect(function(input, gameProcessed)
	if not freecamEnabled or gameProcessed then return end
	
	if table.find({Enum.KeyCode.W, Enum.KeyCode.A, Enum.KeyCode.S, Enum.KeyCode.D}, input.KeyCode) then
		keysDown[tostring(input.KeyCode)] = true
	end
	
	if input.UserInputType == Enum.UserInputType.MouseButton2 or
	   (input.UserInputType == Enum.UserInputType.Touch and UIS:GetMouseLocation().X > (cam.ViewportSize.X / 2)) then
		rotating = true
	end
	
	if input.UserInputType == Enum.UserInputType.Touch and input.Position.X < cam.ViewportSize.X / 2 then
		touchPos = input.Position
	end
end))

-- Input Ended Listeners
table.insert(getgenv().WolfFreecamConns, UIS.InputEnded:Connect(function(input)
	if not freecamEnabled then return end
	
	if keysDown[tostring(input.KeyCode)] then
		keysDown[tostring(input.KeyCode)] = false
	end
	
	if input.UserInputType == Enum.UserInputType.MouseButton2 or
	   (input.UserInputType == Enum.UserInputType.Touch and UIS:GetMouseLocation().X > (cam.ViewportSize.X / 2)) then
		rotating = false
	end
	
	if input.UserInputType == Enum.UserInputType.Touch and touchPos and input.Position.X < cam.ViewportSize.X / 2 then
		touchPos = nil
		keysDown = {}
	end
end))

-- Touch Movement Handler
table.insert(getgenv().WolfFreecamConns, UIS.TouchMoved:Connect(function(input)
	if not freecamEnabled then return end
	
	if touchPos and input.Position.X < cam.ViewportSize.X / 2 then
		keysDown["Enum.KeyCode.W"] = input.Position.Y < touchPos.Y
		keysDown["Enum.KeyCode.S"] = input.Position.Y >= touchPos.Y
		if input.Position.X < (touchPos.X - 15) then
			keysDown["Enum.KeyCode.A"] = true
			keysDown["Enum.KeyCode.D"] = false
		elseif input.Position.X > (touchPos.X + 15) then
			keysDown["Enum.KeyCode.A"] = false
			keysDown["Enum.KeyCode.D"] = true
		else
			keysDown["Enum.KeyCode.A"] = false
			keysDown["Enum.KeyCode.D"] = false
		end
	end
end))

local FreecamToggle = Tabs.Vision:AddToggle("FreecamToggle", {
	Title = "Freecam",
	Default = false
})

FreecamToggle:OnChanged(function(Value)
	setFreecamState(Value)
end)

----------------------------------------------------
-- SPECIAL TAB (INSTANT SEAT WELD INVISIBILITY)
----------------------------------------------------
local seatTeleportPosition = Vector3.new(-25.95, 400, 3537.55)

local function toggleSeatInvisibility(state)
    if getgenv().WolfSeatHeartbeat then
        getgenv().WolfSeatHeartbeat:Disconnect()
        getgenv().WolfSeatHeartbeat = nil
    end

    local char = LocalPlayer.Character
    if not char then return end

    if state then
        setCharacterTransparency(0.75)

        local hrp = char:FindFirstChild("HumanoidRootPart")
        local torso = char:FindFirstChild("Torso") or char:FindFirstChild("UpperTorso")
        
        if hrp and torso then
            local savedpos = hrp.CFrame

            -- Instantly spawn seat and attach without long delays
            local Seat = Instance.new("Seat")
            Seat.Name = "invischair"
            Seat.Transparency = 1
            Seat.CanCollide = false
            Seat.Anchored = false
            Seat.CFrame = CFrame.new(seatTeleportPosition)
            Seat.Parent = workspace

            local Weld = Instance.new("Weld")
            Weld.Part0 = Seat
            Weld.Part1 = torso
            Weld.Parent = Seat

            -- Instantly reposition back
            Seat.CFrame = savedpos

            getgenv().WolfSeatHeartbeat = RunService.Heartbeat:Connect(function()
                if not workspace:FindFirstChild("invischair") or not LocalPlayer.Character then
                    if getgenv().WolfSeatHeartbeat then
                        getgenv().WolfSeatHeartbeat:Disconnect()
                        getgenv().WolfSeatHeartbeat = nil
                    end
                end
            end)
        end
    else
        setCharacterTransparency(0)
        local inv = workspace:FindFirstChild("invischair")
        if inv then
            inv:Destroy()
        end
    end
end

LocalPlayer.CharacterAdded:Connect(function()
    if getgenv().WolfSeatHeartbeat then
        getgenv().WolfSeatHeartbeat:Disconnect()
        getgenv().WolfSeatHeartbeat = nil
    end
    Settings.Invisible = false
end)

local InvisToggle = Tabs.Special:AddToggle("TrueInvisToggle", {
    Title = "Invisibility",
    Default = Settings.Invisible or false
})

InvisToggle:OnChanged(function(state)
    Settings.Invisible = state
    toggleSeatInvisibility(state)
    saveConfig()
end)

----------------------------------------------------
-- USER PROFILE CARD
----------------------------------------------------
task.spawn(function()
    task.wait(0.2)

    local MainFrame = Window.Root or (Window.UIElements and Window.UIElements.Main)
    if not MainFrame then return end

    if MainFrame:FindFirstChild("UserProfileCard") then
        MainFrame:FindFirstChild("UserProfileCard"):Destroy()
    end

    local ProfileFrame = Instance.new("Frame")
    ProfileFrame.Name = "UserProfileCard"
    ProfileFrame.Size = UDim2.new(0, 118, 0, 40)
    ProfileFrame.Position = UDim2.new(0, 6, 1, -46)
    ProfileFrame.BackgroundColor3 = Color3.fromRGB(20, 20, 25)
    ProfileFrame.BackgroundTransparency = 0.2
    ProfileFrame.BorderSizePixel = 0
    ProfileFrame.ZIndex = 100
    ProfileFrame.Parent = MainFrame

    local UICorner = Instance.new("UICorner")
    UICorner.CornerRadius = UDim.new(0, 6)
    UICorner.Parent = ProfileFrame

    local ProfileImage = Instance.new("ImageLabel")
    ProfileImage.Name = "Avatar"
    ProfileImage.Size = UDim2.new(0, 28, 0, 28)
    ProfileImage.Position = UDim2.new(0, 5, 0.5, -14)
    ProfileImage.BackgroundTransparency = 1
    ProfileImage.ZIndex = 101
    ProfileImage.Image = "rbxthumb://type=AvatarHeadShot&id=" .. LocalPlayer.UserId .. "&w=150&h=150"
    ProfileImage.Parent = ProfileFrame

    local ImageCorner = Instance.new("UICorner")
    ImageCorner.CornerRadius = UDim.new(1, 0)
    ImageCorner.Parent = ProfileImage

    local DisplayNameLabel = Instance.new("TextLabel")
    DisplayNameLabel.Size = UDim2.new(1, -38, 0, 14)
    DisplayNameLabel.Position = UDim2.new(0, 36, 0, 5)
    DisplayNameLabel.BackgroundTransparency = 1
    DisplayNameLabel.Text = LocalPlayer.DisplayName
    DisplayNameLabel.TextColor3 = Color3.fromRGB(240, 240, 240)
    DisplayNameLabel.TextSize = 10
    DisplayNameLabel.Font = Enum.Font.SourceSansBold
    DisplayNameLabel.TextXAlignment = Enum.TextXAlignment.Left
    DisplayNameLabel.TextTruncate = Enum.TextTruncate.AtEnd
    DisplayNameLabel.ZIndex = 101
    DisplayNameLabel.Parent = ProfileFrame

    local UsernameLabel = Instance.new("TextLabel")
    UsernameLabel.Size = UDim2.new(1, -38, 0, 12)
    UsernameLabel.Position = UDim2.new(0, 36, 0, 20)
    UsernameLabel.BackgroundTransparency = 1
    UsernameLabel.Text = "@" .. LocalPlayer.Name
    UsernameLabel.TextColor3 = Color3.fromRGB(150, 150, 150)
    UsernameLabel.TextSize = 9
    UsernameLabel.Font = Enum.Font.SourceSans
    UsernameLabel.TextXAlignment = Enum.TextXAlignment.Left
    UsernameLabel.TextTruncate = Enum.TextTruncate.AtEnd
    UsernameLabel.ZIndex = 101
    UsernameLabel.Parent = ProfileFrame
end)

----------------------------------------------------
-- OTHER TABS & SETTINGS
----------------------------------------------------
Tabs.Games:AddParagraph({ Title = "Games", Content = "Game features go here." })

local WolfBgToggle = Tabs.Settings:AddToggle("WolfBgToggle", {
    Title = "Wolf Icon Background (White)",
    Default = Settings.WolfBgWhite
})

WolfBgToggle:OnChanged(function(state)
    Settings.WolfBgWhite = state
    ToggleButton.BackgroundTransparency = state and 0 or 1
    saveConfig()
end)

local ThemeDropdown = Tabs.Settings:AddDropdown("ThemeDropdown", {
    Title = "Menu Theme",
    Values = {"Dark", "Light", "Darker", "Aqua", "Amethyst", "Rose"},
    Default = Settings.Theme
})

ThemeDropdown:OnChanged(function(val)
    Settings.Theme = val
    Fluent:SetTheme(val)
    saveConfig()
end)

Tabs.Settings:AddButton({
    Title = "Restart Game",
    Description = "Rejoins the current server instance.",
    Callback = function()
        local TeleportService = game:GetService("TeleportService")
        local Players = game:GetService("Players")
        local LocalPlayer = Players.LocalPlayer
        
        if #Players:GetPlayers() <= 1 then
            TeleportService:Teleport(game.PlaceId, LocalPlayer)
        else
            TeleportService:TeleportToPlaceInstance(game.PlaceId, game.JobId, LocalPlayer)
        end
    end
})

Tabs.Player:Select()
