Print("WOLF activated")
getgenv().SAR = getgenv().SAR or {Loaded = false}
if getgenv().SAR.Loaded then return end
getgenv().SAR.Loaded = true

-- 1. PERSISTENT TELEPORTATION MANAGER (FIXED)
-- Update URL here↓
local SELF_URL = "https://raw.githubusercontent.com/Badboy45099/Tite/main/main.lua"

local function hookTeleport()
    if queueonteleport then
        queueonteleport([[
            repeat task.wait() until game:IsLoaded()
            loadstring(game:HttpGet("https://raw.githubusercontent.com/Badboy45099/Tite/main/main.lua"))()
        ]])
    end
end
game:GetService("Players").LocalPlayer.OnTeleport:Connect(hookTeleport)

-- 2. INITIALIZE THE UI LIBRARY (Fluent Modded for Compatibility)
local Fluent = loadstring(game:HttpGet("https://github.com/StyearX/Fluent-Modded/releases/download/Fluent/FluentPro"))()
local SaveManager = loadstring(game:HttpGet("https://githubusercontent.com"))()
local InterfaceManager = loadstring(game:HttpGet("https://githubusercontent.com"))()

-- Create the main window overlay
local Window = Fluent:CreateWindow({
    Title = "WOLF",
    SubTitle = "by Badboy",
    TabWidth = 160,
    Size = UDim2.fromOffset(580, 460),
    Acrylic = true,
    Theme = "Dark",
    MinimizeKey = Enum.KeyCode.LeftControl -- Press Left Ctrl to hide/unhide menu
})

-- Roblox inspect player overlay
local GuiService = game:GetService("GuiService")
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer

local function viewPlayerProfile(targetPlayer)
    if targetPlayer then
        pcall(function()
            GuiService:InspectPlayerFromUserId(targetPlayer.UserId)
        end)
    end
end

LocalPlayer.Chatted:Connect(function(message)
    if message == "/inspect" then
        viewPlayerProfile(LocalPlayer)
    end
end)

-- 3. DIVIDE INTO CATEGORIES (TABS)
local Tabs = {
    Main = Window:AddTab({ Title = "Main", Icon = "home" }),
    Character = Window:AddTab({ Title = "Character", Icon = "user" }),
    Vision = Window:AddTab({ Title = "Vision", Icon = "eye" }),
    Games = Window:AddTab({ Title = "Games", Icon = "gamepad" }),
    Settings = Window:AddTab({ Title = "Settings", Icon = "settings" })
}

-- Theme selection menu
local function ApplyTheme(ThemeName)
    local themeMap = {
        White = "Light",
        Black = "Dark",
        Grey = "Dark"
    }

    local selectedTheme = themeMap[ThemeName] or "Dark"
    local ok, err = pcall(function()
        if Window.ChangeTheme then
            Window:ChangeTheme(selectedTheme)
        elseif Window.SetTheme then
            Window:SetTheme(selectedTheme)
        elseif Window.Theme ~= nil then
            Window.Theme = selectedTheme
        end
    end)

    if not ok then
        warn("Unable to apply theme:", err)
    end
end

local function AddThemeToggle(ThemeName, DisplayName)
    local toggle = Tabs.Settings:AddToggle("Theme_" .. ThemeName, {
        Title = DisplayName,
        Default = ThemeName == "Black"
    })

    toggle:OnChanged(function(Value)
        if Value then
            ApplyTheme(ThemeName)
        end
    end)
end

AddThemeToggle("White", "White Theme")
AddThemeToggle("Black", "Black Theme")
AddThemeToggle("Grey", "Grey Theme")

local InspectButton = Tabs.Settings:AddButton("InspectPlayerButton", {
    Title = "Inspect Player",
    Callback = function()
        viewPlayerProfile(LocalPlayer)
    end
})

-- 4. ADD UNIVERSAL TOGGLES WITH PERSISTENCE (SAVE ON LOGOUT)
-- Example 1: Main Category Toggle
local MainToggle = Tabs.Main:AddToggle("WolfFeature", {
    Title = "Activate Wolf Protocol 🐺", 
    Default = false
})

MainToggle:OnChanged(function(Value)
    print("Wolf Feature state changed to: ", Value)
    if Value then
        -- Insert your active code here
    else
        -- Insert your stop code here
    end
end)

-- Example 2: Character Category Toggle
local SpeedToggle = Tabs.Character:AddToggle("SuperSpeed", {
    Title = "Enable Universal Speed", 
    Default = false
})

SpeedToggle:OnChanged(function(Value)
    if Value then
        game:GetService("Players").LocalPlayer.Character.Humanoid.WalkSpeed = 50
    else
        game:GetService("Players").LocalPlayer.Character.Humanoid.WalkSpeed = 16
    end
end)

-- 5. AUTOMATIC SYSTEM FOR SAVING CONFIGURATION
SaveManager:SetLibrary(Fluent)
InterfaceManager:SetLibrary(Fluent)

SaveManager:IgnoreThemeSettings()
SaveManager:SetIgnoreIndexes({})

InterfaceManager:SetFolder("SAR_Universal_Configs")
SaveManager:SetFolder("SAR_Universal_Configs")

InterfaceManager:BuildInterfaceSection(Tabs.Settings)
SaveManager:BuildConfigSection(Tabs.Settings)

-- Auto-load saved settings when the player joins/logins
SaveManager:LoadAutoloadConfig()
