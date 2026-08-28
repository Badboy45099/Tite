--// ============================================
--// ADVANCED AIMBOT
--// ============================================
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Workspace = game:GetService("Workspace")
local HttpService = game:GetService("HttpService")
local CoreGui = game:GetService("CoreGui")
local GuiService = game:GetService("GuiService")
local TeleportService = game:GetService("TeleportService")

local localPlayer = Players.LocalPlayer
local playerGui = localPlayer:WaitForChild("PlayerGui")
local camera = Workspace.CurrentCamera

-- ============================================================================
-- The btn (Hosted Script - Advanced Loop Hook & Crash Shield)
-- ============================================================================
local LoadedMenuInstance = nil
local ToggleButton = nil
local TrackingConnections = {}
local InterceptedConnections = {}
local IsLoading = false

local function StartInterception()
    local mt = getrawmetatable(game)
    if mt and setreadonly then
        setreadonly(mt, false)
        local oldIndex = mt.__index
        
        mt.__index = newcclosure(function(self, key)
            if _G.AimbotActive == false then return oldIndex(self, key) end
            
            if key == "Connect" or key == "connect" then
                return function(event, callback)
                    local connection = oldIndex(event, key)(event, callback)
                    table.insert(InterceptedConnections, connection)
                    return connection
                end
            end
            return oldIndex(self, key)
        end)
        setreadonly(mt, true)
    end
end

local function CleanOldElements()
    for _, connection in pairs(TrackingConnections) do
        if connection then pcall(function() connection:Disconnect() end) end
    end
    TrackingConnections = {}

    for _, connection in pairs(InterceptedConnections) do
        if connection and connection.Connected then 
            pcall(function() connection:Disconnect() end) 
        end
    end
    InterceptedConnections = {}

    local oldCore = CoreGui:FindFirstChild("AimbotMenuToggleGui")
    if oldCore then pcall(function() oldCore:Destroy() end) end
    
    if playerGui then
        local oldPlayer = playerGui:FindFirstChild("AimbotMenuToggleGui")
        if oldPlayer then pcall(function() oldPlayer:Destroy() end) end
    end
end

local function SendNotification(title, content, duration)
    local FluentLib = shared.Fluent or _G.Fluent or Fluent
    if FluentLib and FluentLib.Notify then
        FluentLib:Notify({ Title = title, Content = content, Duration = duration or 3 })
    else
        pcall(function()
            game:GetService("StarterGui"):SetCore("SendNotification", {
                Title = title, Text = content, Duration = duration or 3
            })
        end)
    end
end

local function DestroyScreenButton()
    CleanOldElements()
    if ToggleButton then
        pcall(function() ToggleButton:Destroy() end)
        ToggleButton = nil
    end
end

local function CreateScreenButton()
    DestroyScreenButton() 
    
    local TargetParent = CoreGui
    if not pcall(function() local x = CoreGui.Name end) then
        TargetParent = playerGui
    end
    
    local ScreenGui = Instance.new("ScreenGui")
    ScreenGui.Name = "AimbotMenuToggleGui"
    ScreenGui.ResetOnSpawn = false
    ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    
    if syn and syn.protect_gui then syn.protect_gui(ScreenGui)
    elseif getguiutils and getguiutils().protect_gui then getguiutils().protect_gui(ScreenGui) end
    
    ScreenGui.Parent = TargetParent
    ToggleButton = ScreenGui
    
    local Button = Instance.new("TextButton")
    Button.Size = UDim2.new(0, 35, 0, 35)
    Button.Position = UDim2.new(1, -60, 0, 55)
    Button.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
    Button.Text = "-" 
    Button.TextColor3 = Color3.fromRGB(255, 255, 255)
    Button.Font = Enum.Font.SourceSansBold
    Button.TextSize = 20
    Button.Parent = ScreenGui
    
    local UICorner = Instance.new("UICorner")
    UICorner.CornerRadius = UDim.new(0, 8)
    UICorner.Parent = Button
    
    local UIStroke = Instance.new("UIStroke")
    UIStroke.Color = Color3.fromRGB(60, 60, 60)
    UIStroke.Thickness = 1
    UIStroke.Parent = Button

    local MenuVisible = true

    -- Hook up Fluent UI Window to this button if Fluent is loaded
    local FluentLib = shared.Fluent or _G.Fluent or Fluent
    if FluentLib and FluentLib.Window then
        LoadedMenuInstance = FluentLib.Window
    end

    Button.MouseButton1Click:Connect(function()
        MenuVisible = not MenuVisible
        Button.Text = MenuVisible and "-" or "+"
        
        if LoadedMenuInstance then
            pcall(function()
                -- Handled Fluent window visibility toggle safely
                if LoadedMenuInstance.Minimize then
                    LoadedMenuInstance:Minimize()
                elseif typeof(LoadedMenuInstance) == "Instance" then
                    if LoadedMenuInstance:IsA("ScreenGui") then 
                        LoadedMenuInstance.Enabled = MenuVisible
                    elseif LoadedMenuInstance:IsA("GuiObject") then 
                        LoadedMenuInstance.Visible = MenuVisible 
                    end
                end
            end)
        end
    end)
end

-- RUN THE INTERCEPTION AND SPAWN THE BUTTON!
StartInterception()
CreateScreenButton()

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

--// ============================================
--// DEEP CLEANUP SYSTEM
--// ============================================

local function destroyExisting(parent, name)
    if parent then
        local found = parent:FindFirstChild(name)
        if found then
            pcall(function() found:Destroy() end)
        end
    end
end

destroyExisting(CoreGui, "AimbotFOVScreen")
destroyExisting(CoreGui, "AimbotNativeMenu")
destroyExisting(playerGui, "AimbotFOVScreen")
destroyExisting(playerGui, "AimbotNativeMenu")

pcall(function() RunService:UnbindFromRenderStep("HardLockAimbotStep_Pre") end)
pcall(function() RunService:UnbindFromRenderStep("HardLockAimbotStep_Post") end)

if _G.AimbotCleanup then
    pcall(_G.AimbotCleanup)
end

--// ============================================
--// CONFIG & JSON SAVE SYSTEM
--// ============================================

local CONFIG_FILE = "aimbot_config.json"

local DEFAULT_CONFIG = {
    enabled = false,
    wallCheck = false,
    targetPart = "Head",
    fov = 100,
    showFOV = true,
    teamCheckMode = "Off",
    trustedPlayers = {}
}

local CONFIG = DEFAULT_CONFIG

local function loadConfig()
    pcall(function()
        if readfile and isfile and isfile(CONFIG_FILE) then
            local decoded = HttpService:JSONDecode(readfile(CONFIG_FILE))
            if type(decoded) == "table" then
                for k, v in pairs(decoded) do
                    CONFIG[k] = v
                end
            end
        end
    end)
    CONFIG.trustedPlayers = CONFIG.trustedPlayers or {}
    CONFIG.damageDealt = {}
end

local function saveConfig()
    pcall(function()
        if writefile then
            local dataToSave = {
                enabled = CONFIG.enabled,
                wallCheck = CONFIG.wallCheck,
                targetPart = CONFIG.targetPart,
                fov = CONFIG.fov,
                showFOV = CONFIG.showFOV,
                teamCheckMode = CONFIG.teamCheckMode,
                trustedPlayers = CONFIG.trustedPlayers
            }
            writefile(CONFIG_FILE, HttpService:JSONEncode(dataToSave))
        end
    end)
end

loadConfig()

local function isUserTrusted(username)
    for _, name in ipairs(CONFIG.trustedPlayers) do
        if string.lower(name) == string.lower(username) then
            return true
        end
    end
    return false
end

local function toggleTrustUser(username)
    local foundIndex = nil
    for i, name in ipairs(CONFIG.trustedPlayers) do
        if string.lower(name) == string.lower(username) then
            foundIndex = i
            break
        end
    end
    
    if foundIndex then
        table.remove(CONFIG.trustedPlayers, foundIndex)
    else
        table.insert(CONFIG.trustedPlayers, username)
    end
    saveConfig()
end

--// ============================================
--// PERFECT CENTER FOV CIRCLE
--// ============================================

local FOVGui = Instance.new("ScreenGui")
FOVGui.Name = "AimbotFOVScreen"
FOVGui.ResetOnSpawn = false
FOVGui.DisplayOrder = 999
FOVGui.IgnoreGuiInset = true

pcall(function() FOVGui.Parent = CoreGui end)
if not FOVGui.Parent then FOVGui.Parent = playerGui end

local FOVCircle = Instance.new("Frame")
FOVCircle.Name = "FOVCircle"
FOVCircle.BackgroundTransparency = 1
FOVCircle.AnchorPoint = Vector2.new(0.5, 0.5)
FOVCircle.Position = UDim2.new(0.5, 0, 0.5, 0)
FOVCircle.Size = UDim2.new(0, CONFIG.fov * 2, 0, CONFIG.fov * 2)
FOVCircle.Visible = false
FOVCircle.Parent = FOVGui

local CircleCorner = Instance.new("UICorner")
CircleCorner.CornerRadius = UDim.new(1, 0)
CircleCorner.Parent = FOVCircle

local CircleStroke = Instance.new("UIStroke")
CircleStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
CircleStroke.Color = Color3.fromRGB(0, 255, 120)
CircleStroke.Thickness = 1.5
CircleStroke.Parent = FOVCircle

local function updateFOVCircle()
    FOVCircle.Visible = CONFIG.enabled and CONFIG.showFOV
    FOVCircle.Size = UDim2.new(0, CONFIG.fov * 2, 0, CONFIG.fov * 2)
end

--// ============================================
--// TARGETING LOGIC & SWIPE SYSTEM
--// ============================================

local lockedTarget = nil
local swipeStartPos = nil
local SWIPE_THRESHOLD = 30 -- Pixels needed to register a swipe

local function getTargetPart(character)
    if not character then return nil end
    if CONFIG.targetPart == "Head" then
        return character:FindFirstChild("Head")
    else
        return character:FindFirstChild("HumanoidRootPart") or character:FindFirstChild("UpperTorso") or character:FindFirstChild("Torso")
    end
end

local function isTeammate(targetCharacter)
    if CONFIG.teamCheckMode == "Off" then return false end
    
    local player = Players:GetPlayerFromCharacter(targetCharacter)
    if not player then return false end
    
    if CONFIG.teamCheckMode == "Roblox Team" then
        if player.Team and localPlayer.Team and player.Team == localPlayer.Team then
            return true
        end
    elseif CONFIG.teamCheckMode == "Trusted Players" then
        return isUserTrusted(player.Name)
    elseif CONFIG.teamCheckMode == "Damage Check" then
        if (CONFIG.damageDealt[player.Name] or 0) > 0 then
            return false
        end
        return true
    end
    
    return false
end

local function getScreenCenter()
    local viewportSize = camera.ViewportSize
    local inset = GuiService:GetGuiInset()
    return Vector2.new((viewportSize.X) / 2, (viewportSize.Y + inset.Y) / 2)
end

local function isTargetInFOV(targetPart)
    if not targetPart then return false end
    local screenPos, onScreen = camera:WorldToViewportPoint(targetPart.Position)
    if not onScreen or screenPos.Z <= 0 then return false end
    
    local center = getScreenCenter()
    local targetScreenPos = Vector2.new(screenPos.X, screenPos.Y)
    
    return (targetScreenPos - center).Magnitude <= CONFIG.fov
end

local function canSeeTarget(target)
    if not CONFIG.wallCheck then return true end
    local targetPart = getTargetPart(target)
    if not targetPart then return false end
    
    local myChar = localPlayer.Character
    if not myChar or not myChar:FindFirstChild("Head") then return false end
    
    local rayOrigin = myChar.Head.Position
    local rayDirection = (targetPart.Position - rayOrigin)
    
    local rayParams = RaycastParams.new()
    rayParams.FilterDescendantsInstances = {myChar, target}
    rayParams.FilterType = Enum.RaycastFilterType.Exclude
    
    local result = Workspace:Raycast(rayOrigin, rayDirection, rayParams)
    return result == nil or result.Instance:IsDescendantOf(target)
end

local function isValidTarget(target)
    if not target or target == localPlayer.Character then return false end
    if isTeammate(target) then return false end
    local humanoid = target:FindFirstChildOfClass("Humanoid")
    return humanoid and humanoid.Health > 0 and getTargetPart(target) ~= nil
end

local function getAllTargetsInFOV()
    local targets = {}
    local center = getScreenCenter()

    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= localPlayer and player.Character then
            local character = player.Character
            if isValidTarget(character) then
                local part = getTargetPart(character)
                if part and isTargetInFOV(part) and canSeeTarget(character) then
                    local screenPos = camera:WorldToViewportPoint(part.Position)
                    local dist = (Vector2.new(screenPos.X, screenPos.Y) - center).Magnitude
                    table.insert(targets, {
                        character = character,
                        screenX = screenPos.X,
                        distanceToCenter = dist
                    })
                end
            end
        end
    end
    return targets
end

local function getBestTarget()
    local targets = getAllTargetsInFOV()
    if #targets == 0 then
        lockedTarget = nil
        return nil
    end

    -- Keep current target if still valid in FOV
    if lockedTarget and isValidTarget(lockedTarget) then
        local part = getTargetPart(lockedTarget)
        if part and isTargetInFOV(part) and canSeeTarget(lockedTarget) then
            return lockedTarget
        end
    end

    -- Fallback to nearest player to screen center
    table.sort(targets, function(a, b)
        return a.distanceToCenter < b.distanceToCenter
    end)

    lockedTarget = targets[1].character
    return lockedTarget
end

local function cycleTarget(direction)
    local targets = getAllTargetsInFOV()
    if #targets < 2 then return end

    -- Sort targets from left to right on screen
    table.sort(targets, function(a, b)
        return a.screenX < b.screenX
    end)

    local currentIndex = 1
    for i, t in ipairs(targets) do
        if t.character == lockedTarget then
            currentIndex = i
            break
        end
    end

    local newIndex = currentIndex + direction
    if newIndex > #targets then
        newIndex = 1
    elseif newIndex < 1 then
        newIndex = #targets
    end

    lockedTarget = targets[newIndex].character
end

--// ============================================
--// EXTREME OVERRIDE HARD LOCK LOGIC
--// ============================================

local currentTarget = nil

local function hardLockToTarget(target)
    local targetPart = getTargetPart(target)
    if not targetPart then return end
    
    local targetPos = targetPart.Position
    local camPos = camera.CFrame.Position
    
    -- Force Camera LookAt
    camera.CFrame = CFrame.lookAt(camPos, targetPos)
    
    -- Force Body Mechanics (Stop recoil/sliding from twisting the character)
    local myChar = localPlayer.Character
    if myChar then
        local rootPart = myChar:FindFirstChild("HumanoidRootPart")
        if rootPart then
            local lookAtPos = Vector3.new(targetPos.X, rootPart.Position.Y, targetPos.Z)
            rootPart.CFrame = CFrame.lookAt(rootPart.Position, lookAtPos)
            rootPart.AssemblyAngularVelocity = Vector3.zero
        end
    end
end

--// ============================================
--// GUI WITH FULL TRUST SYSTEM & PLAYER LIST
--// ============================================

local MainGui = Instance.new("ScreenGui")
MainGui.Name = "AimbotNativeMenu"
MainGui.ResetOnSpawn = false

pcall(function() MainGui.Parent = CoreGui end)
if not MainGui.Parent then MainGui.Parent = playerGui end

local Frame = Instance.new("Frame")
Frame.Size = UDim2.new(0, 540, 0, 480)
Frame.Position = UDim2.new(0.05, 0, 0.12, 0)
Frame.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
Frame.BorderSizePixel = 0
Frame.Active = true
Frame.Draggable = true
Frame.Parent = MainGui

local FrameCorner = Instance.new("UICorner")
FrameCorner.CornerRadius = UDim.new(0, 8)
FrameCorner.Parent = Frame

local Title = Instance.new("TextLabel")
Title.Size = UDim2.new(1, 0, 0, 35)
Title.BackgroundColor3 = Color3.fromRGB(35, 35, 35)
Title.Text = "🎯 EXTREME FORCE AIMBOT (Press 'L' to Hide)"
Title.TextColor3 = Color3.fromRGB(255, 255, 255)
Title.TextSize = 13
Title.Font = Enum.Font.SourceSansBold
Title.Parent = Frame

local TitleCorner = Instance.new("UICorner")
TitleCorner.CornerRadius = UDim.new(0, 8)
TitleCorner.Parent = Title

local ControlPanel = Instance.new("Frame")
ControlPanel.Size = UDim2.new(0, 250, 1, -45)
ControlPanel.Position = UDim2.new(0, 10, 0, 40)
ControlPanel.BackgroundTransparency = 1
ControlPanel.Parent = Frame

local function createToggle(text, yPos, default, callback)
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(1, 0, 0, 32)
    btn.Position = UDim2.new(0, 0, 0, yPos)
    btn.BackgroundColor3 = default and Color3.fromRGB(40, 160, 80) or Color3.fromRGB(50, 50, 50)
    btn.Text = text .. ": " .. (default and "ON" or "OFF")
    btn.TextColor3 = Color3.fromRGB(255, 255, 255)
    btn.Font = Enum.Font.SourceSansBold
    btn.TextSize = 13
    btn.Parent = ControlPanel
    
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 6)
    corner.Parent = btn
    
    local state = default
    btn.MouseButton1Click:Connect(function()
        state = not state
        btn.BackgroundColor3 = state and Color3.fromRGB(40, 160, 80) or Color3.fromRGB(50, 50, 50)
        btn.Text = text .. ": " .. (state and "ON" or "OFF")
        callback(state)
        saveConfig()
    end)
end

createToggle("Enable Extreme Aimbot", 0, CONFIG.enabled, function(val)
    CONFIG.enabled = val
    updateFOVCircle()
end)

createToggle("Show FOV Circle", 40, CONFIG.showFOV, function(val)
    CONFIG.showFOV = val
    updateFOVCircle()
end)

createToggle("Wall Check", 80, CONFIG.wallCheck, function(val)
    CONFIG.wallCheck = val
end)

local PartBtn = Instance.new("TextButton")
PartBtn.Size = UDim2.new(1, 0, 0, 32)
PartBtn.Position = UDim2.new(0, 0, 0, 120)
PartBtn.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
PartBtn.Text = "Target Part: " .. CONFIG.targetPart
PartBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
PartBtn.Font = Enum.Font.SourceSansBold
PartBtn.TextSize = 13
PartBtn.Parent = ControlPanel

local PartCorner = Instance.new("UICorner")
PartCorner.CornerRadius = UDim.new(0, 6)
PartCorner.Parent = PartBtn

PartBtn.MouseButton1Click:Connect(function()
    CONFIG.targetPart = (CONFIG.targetPart == "Head") and "Torso" or "Head"
    PartBtn.Text = "Target Part: " .. CONFIG.targetPart
    saveConfig()
end)

local TeamModes = {"Off", "Roblox Team", "Trusted Players", "Damage Check"}
local currentModeIdx = 1
for idx, mode in ipairs(TeamModes) do
    if mode == CONFIG.teamCheckMode then currentModeIdx = idx break end
end

local TeamBtn = Instance.new("TextButton")
TeamBtn.Size = UDim2.new(1, 0, 0, 32)
TeamBtn.Position = UDim2.new(0, 0, 0, 160)
TeamBtn.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
TeamBtn.Text = "Team Check: " .. CONFIG.teamCheckMode
TeamBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
TeamBtn.Font = Enum.Font.SourceSansBold
TeamBtn.TextSize = 13
TeamBtn.Parent = ControlPanel

local TeamCorner = Instance.new("UICorner")
TeamCorner.CornerRadius = UDim.new(0, 6)
TeamCorner.Parent = TeamBtn

TeamBtn.MouseButton1Click:Connect(function()
    currentModeIdx = (currentModeIdx % #TeamModes) + 1
    CONFIG.teamCheckMode = TeamModes[currentModeIdx]
    TeamBtn.Text = "Team Check: " .. CONFIG.teamCheckMode
    saveConfig()
end)

local FOVLabel = Instance.new("TextLabel")
FOVLabel.Size = UDim2.new(1, 0, 0, 20)
FOVLabel.Position = UDim2.new(0, 0, 0, 200)
FOVLabel.BackgroundTransparency = 1
FOVLabel.Text = "FOV Radius: " .. CONFIG.fov
FOVLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
FOVLabel.Font = Enum.Font.SourceSans
FOVLabel.TextSize = 13
FOVLabel.Parent = ControlPanel

local MinusBtn = Instance.new("TextButton")
MinusBtn.Size = UDim2.new(0, 118, 0, 30)
MinusBtn.Position = UDim2.new(0, 0, 0, 225)
MinusBtn.BackgroundColor3 = Color3.fromRGB(70, 70, 70)
MinusBtn.Text = "- 10 FOV"
MinusBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
MinusBtn.Font = Enum.Font.SourceSansBold
MinusBtn.Parent = ControlPanel

local PlusBtn = Instance.new("TextButton")
PlusBtn.Size = UDim2.new(0, 118, 0, 30)
PlusBtn.Position = UDim2.new(0, 132, 0, 225)
PlusBtn.BackgroundColor3 = Color3.fromRGB(70, 70, 70)
PlusBtn.Text = "+ 10 FOV"
PlusBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
PlusBtn.Font = Enum.Font.SourceSansBold
PlusBtn.Parent = ControlPanel

MinusBtn.MouseButton1Click:Connect(function()
    CONFIG.fov = math.max(5, CONFIG.fov - 10)
    FOVLabel.Text = "FOV Radius: " .. CONFIG.fov
    updateFOVCircle()
    saveConfig()
end)

PlusBtn.MouseButton1Click:Connect(function()
    CONFIG.fov = math.min(500, CONFIG.fov + 10)
    FOVLabel.Text = "FOV Radius: " .. CONFIG.fov
    updateFOVCircle()
    saveConfig()
end)

local ManualInput = Instance.new("TextBox")
ManualInput.Size = UDim2.new(0, 170, 0, 30)
ManualInput.Position = UDim2.new(0, 0, 0, 265)
ManualInput.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
ManualInput.PlaceholderText = "Type Username..."
ManualInput.Text = ""
ManualInput.TextColor3 = Color3.fromRGB(255, 255, 255)
ManualInput.Font = Enum.Font.SourceSans
ManualInput.TextSize = 13
ManualInput.Parent = ControlPanel

local ManualInputCorner = Instance.new("UICorner")
ManualInputCorner.CornerRadius = UDim.new(0, 6)
ManualInputCorner.Parent = ManualInput

local ManualAddBtn = Instance.new("TextButton")
ManualAddBtn.Size = UDim2.new(0, 75, 0, 30)
ManualAddBtn.Position = UDim2.new(0, 175, 0, 265)
ManualAddBtn.BackgroundColor3 = Color3.fromRGB(40, 120, 200)
ManualAddBtn.Text = "+ Trust"
ManualAddBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
ManualAddBtn.Font = Enum.Font.SourceSansBold
ManualAddBtn.TextSize = 13
ManualAddBtn.Parent = ControlPanel

local ManualAddCorner = Instance.new("UICorner")
ManualAddCorner.CornerRadius = UDim.new(0, 6)
ManualAddCorner.Parent = ManualAddBtn

local ClearBtn = Instance.new("TextButton")
ClearBtn.Size = UDim2.new(1, 0, 0, 30)
ClearBtn.Position = UDim2.new(0, 0, 0, 305)
ClearBtn.BackgroundColor3 = Color3.fromRGB(150, 50, 50)
ClearBtn.Text = "Clear All Trusted"
ClearBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
ClearBtn.Font = Enum.Font.SourceSansBold
ClearBtn.TextSize = 13
ClearBtn.Parent = ControlPanel

local ClearCorner = Instance.new("UICorner")
ClearCorner.CornerRadius = UDim.new(0, 6)
ClearCorner.Parent = ClearBtn

local RightPanel = Instance.new("Frame")
RightPanel.Size = UDim2.new(0, 260, 1, -50)
RightPanel.Position = UDim2.new(0, 270, 0, 40)
RightPanel.BackgroundTransparency = 1
RightPanel.Parent = Frame

local RefreshBtn = Instance.new("TextButton")
RefreshBtn.Size = UDim2.new(1, 0, 0, 26)
RefreshBtn.Position = UDim2.new(0, 0, 0, 0)
RefreshBtn.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
RefreshBtn.Text = "🔄 Refresh Players List"
RefreshBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
RefreshBtn.Font = Enum.Font.SourceSansBold
RefreshBtn.TextSize = 12
RefreshBtn.Parent = RightPanel

local RefreshCorner = Instance.new("UICorner")
RefreshCorner.CornerRadius = UDim.new(0, 6)
RefreshCorner.Parent = RefreshBtn

local ServerListLabel = Instance.new("TextLabel")
ServerListLabel.Size = UDim2.new(1, 0, 0, 20)
ServerListLabel.Position = UDim2.new(0, 0, 0, 30)
ServerListLabel.BackgroundTransparency = 1
ServerListLabel.Text = "👥 Server Players (Click to Toggle)"
ServerListLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
ServerListLabel.Font = Enum.Font.SourceSansBold
ServerListLabel.TextSize = 12
ServerListLabel.Parent = RightPanel

local ServerScroll = Instance.new("ScrollingFrame")
ServerScroll.Size = UDim2.new(1, 0, 0, 180)
ServerScroll.Position = UDim2.new(0, 0, 0, 52)
ServerScroll.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
ServerScroll.BorderSizePixel = 0
ServerScroll.ScrollBarThickness = 4
ServerScroll.Parent = RightPanel

local ServerLayout = Instance.new("UIListLayout")
ServerLayout.SortOrder = Enum.SortOrder.Name
ServerLayout.Padding = UDim.new(0, 3)
ServerLayout.Parent = ServerScroll

local TrustedHeaderLabel = Instance.new("TextLabel")
TrustedHeaderLabel.Size = UDim2.new(1, 0, 0, 20)
TrustedHeaderLabel.Position = UDim2.new(0, 0, 0, 238)
TrustedHeaderLabel.BackgroundTransparency = 1
TrustedHeaderLabel.Text = "🛡️ Active Trusted List (0 Saved)"
TrustedHeaderLabel.TextColor3 = Color3.fromRGB(0, 255, 120)
TrustedHeaderLabel.Font = Enum.Font.SourceSansBold
TrustedHeaderLabel.TextSize = 12
TrustedHeaderLabel.Parent = RightPanel

local TrustedScroll = Instance.new("ScrollingFrame")
TrustedScroll.Size = UDim2.new(1, 0, 0, 165)
TrustedScroll.Position = UDim2.new(0, 0, 0, 260)
TrustedScroll.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
TrustedScroll.BorderSizePixel = 0
TrustedScroll.ScrollBarThickness = 4
TrustedScroll.Parent = RightPanel

local TrustedLayout = Instance.new("UIListLayout")
TrustedLayout.SortOrder = Enum.SortOrder.Name
TrustedLayout.Padding = UDim.new(0, 3)
TrustedLayout.Parent = TrustedScroll

local function updateLists()
    for _, child in ipairs(ServerScroll:GetChildren()) do
        if child:IsA("TextButton") then child:Destroy() end
    end
    
    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= localPlayer then
            local trusted = isUserTrusted(player.Name)
            
            local btn = Instance.new("TextButton")
            btn.Size = UDim2.new(1, -6, 0, 26)
            btn.BackgroundColor3 = trusted and Color3.fromRGB(40, 140, 70) or Color3.fromRGB(45, 45, 45)
            btn.Text = (trusted and "🛡️ " or "👤 ") .. player.Name
            btn.TextColor3 = Color3.fromRGB(255, 255, 255)
            btn.Font = Enum.Font.SourceSans
            btn.TextSize = 13
            btn.Parent = ServerScroll
            
            local btnCorner = Instance.new("UICorner")
            btnCorner.CornerRadius = UDim.new(0, 4)
            btnCorner.Parent = btn
            
            btn.MouseButton1Click:Connect(function()
                toggleTrustUser(player.Name)
                updateLists()
            end)
        end
    end
    
    ServerScroll.CanvasSize = UDim2.new(0, 0, 0, ServerLayout.AbsoluteContentSize.Y)
    
    for _, child in ipairs(TrustedScroll:GetChildren()) do
        if child:IsA("TextButton") or child:IsA("TextLabel") then child:Destroy() end
    end
    
    TrustedHeaderLabel.Text = "🛡️ Active Trusted List (" .. #CONFIG.trustedPlayers .. " Saved)"
    
    for _, trustedName in ipairs(CONFIG.trustedPlayers) do
        local btn = Instance.new("TextButton")
        btn.Size = UDim2.new(1, -6, 0, 24)
        btn.BackgroundColor3 = Color3.fromRGB(35, 90, 50)
        btn.Text = "🛡️ " .. trustedName .. " (Click to remove)"
        btn.TextColor3 = Color3.fromRGB(255, 255, 255)
        btn.Font = Enum.Font.SourceSans
        btn.TextSize = 12
        btn.Parent = TrustedScroll
        
        local btnCorner = Instance.new("UICorner")
        btnCorner.CornerRadius = UDim.new(0, 4)
        btnCorner.Parent = btn
        
        btn.MouseButton1Click:Connect(function()
            toggleTrustUser(trustedName)
            updateLists()
        end)
    end
    
    TrustedScroll.CanvasSize = UDim2.new(0, 0, 0, TrustedLayout.AbsoluteContentSize.Y)
end

RefreshBtn.MouseButton1Click:Connect(updateLists)

ManualAddBtn.MouseButton1Click:Connect(function()
    if ManualInput.Text ~= "" then
        if not isUserTrusted(ManualInput.Text) then
            toggleTrustUser(ManualInput.Text)
        end
        ManualInput.Text = ""
        updateLists()
    end
end)

ClearBtn.MouseButton1Click:Connect(function()
    CONFIG.trustedPlayers = {}
    saveConfig()
    updateLists()
end)

Players.PlayerAdded:Connect(updateLists)
Players.PlayerRemoving:Connect(updateLists)

updateLists()

_G.AimbotCleanup = function()
    if FOVGui then pcall(function() FOVGui:Destroy() end) end
    if MainGui then pcall(function() MainGui:Destroy() end) end
    RunService:UnbindFromRenderStep("HardLockAimbotStep_Pre")
    RunService:UnbindFromRenderStep("HardLockAimbotStep_Post")
end

updateFOVCircle()

--// ============================================
--// DUAL STAGE LOCKING & INPUT LISTENERS
--// ============================================

RunService:BindToRenderStep("HardLockAimbotStep_Pre", Enum.RenderPriority.Camera.Value - 1, function()
    if CONFIG.enabled then
        currentTarget = getBestTarget()
        if currentTarget and isValidTarget(currentTarget) then
            hardLockToTarget(currentTarget)
        end
    end
end)

RunService:BindToRenderStep("HardLockAimbotStep_Post", Enum.RenderPriority.Last.Value, function()
    if CONFIG.enabled and currentTarget and isValidTarget(currentTarget) then
        hardLockToTarget(currentTarget)
    end
end)

UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then return end
    
    if input.KeyCode == Enum.KeyCode.L then
        Frame.Visible = not Frame.Visible
    end

    -- Capture touch or mouse drag start inside FOV
    if CONFIG.enabled and (input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch) then
        local startPos = Vector2.new(input.Position.X, input.Position.Y)
        local center = getScreenCenter()

        if (startPos - center).Magnitude <= CONFIG.fov then
            swipeStartPos = startPos
        end
    end
end)

UserInputService.InputEnded:Connect(function(input, gameProcessed)
    if not CONFIG.enabled or not swipeStartPos then return end

    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        local endPos = Vector2.new(input.Position.X, input.Position.Y)
        local delta = endPos - swipeStartPos
        swipeStartPos = nil

        -- Trigger target swap if horizontal swipe distance is met
        if math.abs(delta.X) >= SWIPE_THRESHOLD and math.abs(delta.X) > math.abs(delta.Y) then
            if delta.X > 0 then
                cycleTarget(1)  -- Swipe Right -> Next player on right
            else
                cycleTarget(-1) -- Swipe Left -> Next player on left
            end
        end
    end
end)
