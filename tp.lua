-- ====================================================
-- STANDALONE TP BEHIND PLAYER SCRIPT
-- File: TP_Behind.lua
-- ====================================================

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local LocalPlayer = Players.LocalPlayer

----------------------------------------------------
-- DUPLICATE EXECUTION CLEANUP
----------------------------------------------------
if getgenv().WolfTpGui then
    getgenv().WolfTpGui:Destroy()
    getgenv().WolfTpGui = nil
end

if getgenv().WolfTpWindow then
    getgenv().WolfTpWindow:Destroy()
    getgenv().WolfTpWindow = nil
end

----------------------------------------------------
-- LOAD FLUENT UI LIBRARY
----------------------------------------------------
local Fluent = loadstring(game:HttpGet("https://github.com/dawid-scripts/Fluent/releases/latest/download/main.lua"))()

local Window = Fluent:CreateWindow({
    Title = "TP Behind Player",
    SubTitle = "Standalone Utility",
    TabWidth = 160,
    Size = UDim2.fromOffset(480, 360),
    Acrylic = false,
    Theme = "Dark",
    MinimizeKey = Enum.KeyCode.RightControl
})

getgenv().WolfTpWindow = Window

local Tabs = {
    Main = Window:AddTab({ Title = "Teleport", Icon = "user" })
}

----------------------------------------------------
-- VARIABLES
----------------------------------------------------
local selectedTpMode = "Random"
local selectedPlayerName = nil
local lockedPlayer = nil

----------------------------------------------------
-- DRAGGABLE FLOAT BUTTON GUI
----------------------------------------------------
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "WolfTpGui"
ScreenGui.ResetOnSpawn = false
getgenv().WolfTpGui = ScreenGui

local success, _ = pcall(function()
    ScreenGui.Parent = game:GetService("CoreGui")
end)
if not success then
    ScreenGui.Parent = LocalPlayer:WaitForChild("PlayerGui")
end

local FloatBtn = Instance.new("TextButton")
FloatBtn.Name = "TpFloatBtn"
FloatBtn.Size = UDim2.new(0, 50, 0, 50)
FloatBtn.Position = UDim2.new(0.85, 0, 0.5, 0)
FloatBtn.BackgroundColor3 = Color3.fromRGB(30, 30, 35)
FloatBtn.BorderColor3 = Color3.fromRGB(0, 170, 255)
FloatBtn.BorderSizePixel = 2
FloatBtn.Text = "TP"
FloatBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
FloatBtn.TextSize = 18
FloatBtn.Font = Enum.Font.SourceSansBold
FloatBtn.Visible = false
FloatBtn.Parent = ScreenGui

local UICorner = Instance.new("UICorner")
UICorner.CornerRadius = UDim.new(0, 25)
UICorner.Parent = FloatBtn

-- Dragging logic
local dragging, dragInput, dragStart, startPos

FloatBtn.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        dragging = true
        dragStart = input.Position
        startPos = FloatBtn.Position
        
        input.Changed:Connect(function()
            if input.UserInputState == Enum.UserInputState.End then
                dragging = false
            end
        end)
    end
end)

FloatBtn.InputChanged:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
        dragInput = input
    end
end)

UserInputService.InputChanged:Connect(function(input)
    if input == dragInput and dragging then
        local delta = input.Position - dragStart
        FloatBtn.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
    end
end)

----------------------------------------------------
-- HELPER FUNCTIONS
----------------------------------------------------
local function getNearestPlayer(excludeClosest)
    local localChar = LocalPlayer.Character
    if not localChar or not localChar:FindFirstChild("HumanoidRootPart") then return nil end

    local myPos = localChar.HumanoidRootPart.Position
    local playersList = {}

    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= LocalPlayer and p.Character and p.Character:FindFirstChild("HumanoidRootPart") then
            local dist = (p.Character.HumanoidRootPart.Position - myPos).Magnitude
            table.insert(playersList, {Player = p, Distance = dist})
        end
    end

    table.sort(playersList, function(a, b) return a.Distance < b.Distance end)

    if #playersList == 0 then return nil end

    if excludeClosest and #playersList > 1 then
        return playersList[2].Player
    end

    return playersList[1].Player
end

local function getRandomPlayer()
    local validPlayers = {}
    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= LocalPlayer and p.Character and p.Character:FindFirstChild("HumanoidRootPart") then
            table.insert(validPlayers, p)
        end
    end
    if #validPlayers > 0 then
        return validPlayers[math.random(1, #validPlayers)]
    end
    return nil
end

local function teleportBehind(targetPlayer)
    if not targetPlayer or not targetPlayer.Character then return end
    local targetHRP = targetPlayer.Character:FindFirstChild("HumanoidRootPart")
    local myChar = LocalPlayer.Character
    local myHRP = myChar and myChar:FindFirstChild("HumanoidRootPart")

    if targetHRP and myHRP then
        ----------------------------------------------------
        -- ADJUST POSITION BEHIND PLAYER HERE:
        -- CFrame.new(0, 0, 3) = 3 studs directly BEHIND the target
        -- Change '3' to larger/smaller number for distance
        -- Change '0, 0' to adjust X (Left/Right) or Y (Up/Down)
        ----------------------------------------------------
        local offset = CFrame.new(0, 0, 3)
        myHRP.CFrame = targetHRP.CFrame * offset
    end
end

local function executeTeleport()
    local target = nil

    if lockedPlayer and lockedPlayer.Parent and lockedPlayer.Character then
        target = lockedPlayer
    else
        if selectedTpMode == "Random" then
            target = getRandomPlayer()
        elseif selectedTpMode == "Nearest" then
            target = getNearestPlayer(false)
        elseif selectedTpMode == "Specific" then
            if selectedPlayerName then
                target = Players:FindFirstChild(selectedPlayerName)
            end
        end
    end

    if target then
        teleportBehind(target)
    end
end

FloatBtn.MouseButton1Click:Connect(executeTeleport)

----------------------------------------------------
-- UI CONTROLS
----------------------------------------------------

Tabs.Main:AddToggle("ShowTpFloatBtn", {
    Title = "Show On-Screen TP Button",
    Default = false,
    Callback = function(state)
        FloatBtn.Visible = state
    end
})

Tabs.Main:AddDropdown("TpCategory", {
    Title = "TP Target Mode",
    Values = {"Random", "Nearest", "Specific"},
    Default = "Random",
    Callback = function(val)
        selectedTpMode = val
    end
})

Tabs.Main:AddButton({
    Title = "TP to Nearest (Skip Closest)",
    Callback = function()
        local target = getNearestPlayer(true)
        if target then
            teleportBehind(target)
        end
    end
})

Tabs.Main:AddButton({
    Title = "Lock Nearest Player for TP",
    Callback = function()
        local target = getNearestPlayer(false)
        if target then
            lockedPlayer = target
            Fluent:Notify({ Title = "TP Lock", Content = "Locked onto: " .. target.Name, Duration = 3 })
        end
    end
})

Tabs.Main:AddButton({
    Title = "Unlock Target Player",
    Callback = function()
        lockedPlayer = nil
        Fluent:Notify({ Title = "TP Lock", Content = "Player Unlocked", Duration = 3 })
    end
})

local function getPlayerList()
    local names = {}
    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= LocalPlayer then
            table.insert(names, p.Name)
        end
    end
    return names
end

local SpecificPlayerDropdown = Tabs.Main:AddDropdown("SpecificPlayerSelect", {
    Title = "Select Specific Player",
    Values = getPlayerList(),
    Default = nil,
    Callback = function(val)
        selectedPlayerName = val
    end
})

Tabs.Main:AddInput("PlayerSearchInput", {
    Title = "Search Player Name",
    Default = "",
    Placeholder = "Type player name...",
    Numeric = false,
    Finished = false,
    Callback = function(text)
        if text == "" then return end
        for _, p in ipairs(Players:GetPlayers()) do
            if p ~= LocalPlayer and p.Name:lower():find(text:lower()) then
                selectedPlayerName = p.Name
                SpecificPlayerDropdown:SetValue(p.Name)
                break
            end
        end
    end
})

Tabs.Main:AddButton({
    Title = "Refresh Player List",
    Callback = function()
        SpecificPlayerDropdown:SetValues(getPlayerList())
    end
})

Window:SelectTab(1)
