local TeleportModule = {}

function TeleportModule.Create(PlayerTab, FluentLibrary)
    -- Anti-Duplication Check
    if getgenv().TeleportScriptLoaded then
        for _, gui in ipairs(game:GetService("CoreGui"):GetChildren()) do
            if gui.Name == "TpDraggableGui" then
                gui:Destroy()
            end
        end
        for _, beacon in ipairs(workspace:GetChildren()) do
            if beacon.Name:sub(1, 7) == "Beacon_" then
                beacon:Destroy()
            end
        end
    end
    getgenv().TeleportScriptLoaded = true

    local Players = game:GetService("Players")
    local LocalPlayer = Players.LocalPlayer
    local HttpService = game:GetService("HttpService")

    local ConfigFileName = "FluentUI_SavedPositions.json"

    -- Master Data Storage
    local SavedPositions = {}
    local CurrentCategoryMode = "Saved position"
    local SelectedSaveName = ""
    local SelectedSpecificPlayer = nil
    local LockedPlayer = nil
    local LockModeEnabled = false

    -- Helper: Load JSON File
    local function LoadSavedPositionsFile()
        if isfile and isfile(ConfigFileName) then
            local success, content = pcall(readfile, ConfigFileName)
            if success and content then
                local decodedOk, decodedData = pcall(function() return HttpService:JSONDecode(content) end)
                if decodedOk and type(decodedData) == "table" then
                    SavedPositions = decodedData
                end
            end
        end
    end

    -- Helper: Save JSON File
    local function WritePositionsToFile()
        if writefile then
            local encodedData = HttpService:JSONEncode(SavedPositions)
            writefile(ConfigFileName, encodedData)
        end
    end

    LoadSavedPositionsFile()

    -- Helper: Reset Saved Positions File
    local function ResetAllSavedPositions()
        SavedPositions = {}
        if writefile then
            writefile(ConfigFileName, HttpService:JSONEncode(SavedPositions))
        end
    end

    -- Helper: Get Local HumanoidRootPart
    local function GetHRP(player)
        player = player or LocalPlayer
        if player and player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
            return player.Character.HumanoidRootPart
        end
        return nil
    end

    ----------------------------------------------------
    -- FLOATING TP BUTTON
    ----------------------------------------------------
    local DraggableIcon = Instance.new("ScreenGui")
    local IconBtn = Instance.new("ImageButton")
    local UICorner = Instance.new("UICorner")

    DraggableIcon.Name = "TpDraggableGui"
    DraggableIcon.Parent = game:GetService("CoreGui")
    DraggableIcon.Enabled = false

    IconBtn.Name = "TpBtn"
    IconBtn.Parent = DraggableIcon
    IconBtn.BackgroundTransparency = 1 
    IconBtn.BorderSizePixel = 0
    IconBtn.Position = UDim2.new(0.98, 0, 0.02, 0)
    IconBtn.Size = UDim2.new(0, 50, 0, 50)
    IconBtn.Image = "rbxthumb://type=Asset&id=111311201582764&w=150&h=150"
    IconBtn.Active = true
    IconBtn.Draggable = true

    UICorner.CornerRadius = UDim.new(0, 12)
    UICorner.Parent = IconBtn

    IconBtn.MouseButton1Click:Connect(function()
        local myHRP = GetHRP(LocalPlayer)
        if not myHRP then return end

        if CurrentCategoryMode == "Saved position" then
            if SelectedSaveName ~= "" and SavedPositions[SelectedSaveName] then
                local pos = SavedPositions[SelectedSaveName]
                myHRP.CFrame = CFrame.new(pos.X, pos.Y, pos.Z)
            end
        elseif CurrentCategoryMode == "Specific" then
            if SelectedSpecificPlayer and GetHRP(SelectedSpecificPlayer) then
                local targetHRP = GetHRP(SelectedSpecificPlayer)
                myHRP.CFrame = targetHRP.CFrame * CFrame.new(0, 0, 4)
            end
        elseif CurrentCategoryMode == "Random" then
            local target = nil
            if LockModeEnabled and LockedPlayer then
                target = LockedPlayer
            else
                local validPlayers = {}
                for _, p in ipairs(Players:GetPlayers()) do
                    if p ~= LocalPlayer and GetHRP(p) then table.insert(validPlayers, p) end
                end
                if #validPlayers > 0 then target = validPlayers[math.random(1, #validPlayers)] end
            end

            if target and GetHRP(target) then
                local targetHRP = GetHRP(target)
                myHRP.CFrame = targetHRP.CFrame * CFrame.new(0, 0, 4)
            end
        end
    end)

    ----------------------------------------------------
    -- ATTACH TO PLAYER TAB
    ----------------------------------------------------
    PlayerTab:AddButton({
        Title = "Toggle Floating TP Button",
        Icon = "rbxassetid://4520179063",
        Callback = function()
            DraggableIcon.Enabled = not DraggableIcon.Enabled
        end
    })

    local CategoryDropdown = PlayerTab:AddDropdown("CategoryDropdown", {
        Title = "Drop Down Box (Select Mode)",
        Values = {"Saved position", "Random", "Specific"},
        Multi = false,
        Default = 1,
    })

    local SavedSection = PlayerTab:AddSection("Saved Positions")
    local RandomSection = PlayerTab:AddSection("Random Player Teleport")
    local SpecificSection = PlayerTab:AddSection("Specific Player Teleport")

    ----------------------------------------------------
    -- SAVED POSITION SECTION
    ----------------------------------------------------
    local SaveInputText = ""

    SavedSection:AddInput("SaveNameInput", {
        Title = "Position Name",
        Default = "",
        Placeholder = "Enter name (e.g. Base, Bank)...",
        Callback = function(Value)
            SaveInputText = Value
            if Value ~= "" then SelectedSaveName = Value end
        end
    })

    local function GetSavedListKeys()
        local keys = {}
        for name, _ in pairs(SavedPositions) do table.insert(keys, name) end
        if #keys == 0 then table.insert(keys, "No saved positions") end
        return keys
    end

    local savedFilesDropdown = SavedSection:AddDropdown("SavedFilesDropdown", {
        Title = "Your Saved File Here",
        Values = GetSavedListKeys(),
        Multi = false,
        Default = 1,
    })

    savedFilesDropdown:OnChanged(function(Value)
        if Value ~= "No saved positions" and Value ~= "" then SelectedSaveName = Value end
    end)

    SavedSection:AddButton({
        Title = "Save Current Position",
        Callback = function()
            if SaveInputText == "" then
                return
            end

            local myHRP = GetHRP(LocalPlayer)
            if myHRP then
                local pos = myHRP.Position
                SavedPositions[SaveInputText] = {X = pos.X, Y = pos.Y, Z = pos.Z}
                WritePositionsToFile()
                SelectedSaveName = SaveInputText
                savedFilesDropdown:SetValues(GetSavedListKeys())
            end
        end
    })

    SavedSection:AddButton({
        Title = "Refresh Saved File List",
        Callback = function()
            LoadSavedPositionsFile()
            savedFilesDropdown:SetValues(GetSavedListKeys())
        end
    })

    SavedSection:AddButton({
        Title = "Reset All Saved Positions",
        Callback = function()
            ResetAllSavedPositions()
            SelectedSaveName = ""
            savedFilesDropdown:SetValues(GetSavedListKeys())
        end
    })

    -- 3D World Beacon Visualizer
    local ActiveBeacons = {}

    SavedSection:AddButton({
        Title = "Pin Selected Position in 3D World",
        Callback = function()
            if SelectedSaveName == "" or not SavedPositions[SelectedSaveName] then
                return
            end

            local pos = SavedPositions[SelectedSaveName]
            if ActiveBeacons[SelectedSaveName] then
                ActiveBeacons[SelectedSaveName]:Destroy()
            end

            local beaconPart = Instance.new("Part")
            beaconPart.Name = "Beacon_" .. SelectedSaveName
            beaconPart.Size = Vector3.new(3, 200, 3)
            beaconPart.Position = Vector3.new(pos.X, pos.Y + 100, pos.Z)
            beaconPart.Anchored = true
            beaconPart.CanCollide = false
            beaconPart.Material = Enum.Material.Neon
            beaconPart.Color = Color3.fromRGB(0, 255, 150)
            beaconPart.Transparency = 0.5
            beaconPart.Parent = workspace

            local billboard = Instance.new("BillboardGui")
            billboard.AlwaysOnTop = true
            billboard.Size = UDim2.new(0, 140, 0, 35)
            billboard.StudsOffset = Vector3.new(0, -95, 0)
            billboard.Adornee = beaconPart
            billboard.Parent = game:GetService("CoreGui")

            local label = Instance.new("TextLabel")
            label.Parent = billboard
            label.Size = UDim2.new(1, 0, 1, 0)
            label.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
            label.BackgroundTransparency = 0.2
            label.TextColor3 = Color3.fromRGB(0, 255, 150)
            label.Text = "📌 " .. SelectedSaveName
            label.TextScaled = true

            ActiveBeacons[SelectedSaveName] = beaconPart
        end
    })

    SavedSection:AddButton({
        Title = "Clear All World Pins",
        Callback = function()
            for _, beacon in pairs(ActiveBeacons) do
                if beacon then beacon:Destroy() end
            end
            ActiveBeacons = {}
        end
    })

    ----------------------------------------------------
    -- RANDOM SECTION
    ----------------------------------------------------
    RandomSection:AddButton({
        Title = "Search Nearest Player",
        Callback = function()
            local nearest = nil
            local shortestDist = math.huge
            local myHRP = GetHRP(LocalPlayer)
            if not myHRP then return end

            for _, p in ipairs(Players:GetPlayers()) do
                if p ~= LocalPlayer and GetHRP(p) then
                    local dist = (GetHRP(p).Position - myHRP.Position).Magnitude
                    if dist < shortestDist then
                        shortestDist = dist
                        nearest = p
                    end
                end
            end

            if nearest then
                LockedPlayer = nearest
            end
        end
    })

    RandomSection:AddToggle("PlayerLockToggle", {
        Title = "Lock Target Mode (On/Off)",
        Default = false,
        Callback = function(Value)
            LockModeEnabled = Value
            if not Value then LockedPlayer = nil end
        end
    })

    RandomSection:AddButton({
        Title = "TP Random Player (Safe Distance Click)",
        Callback = function()
            local validPlayers = {}
            for _, p in ipairs(Players:GetPlayers()) do
                if p ~= LocalPlayer and GetHRP(p) then table.insert(validPlayers, p) end
            end

            if #validPlayers > 0 then
                local target = validPlayers[math.random(1, #validPlayers)]
                local targetHRP = GetHRP(target)
                local myHRP = GetHRP(LocalPlayer)
                if myHRP and targetHRP then
                    myHRP.CFrame = targetHRP.CFrame * CFrame.new(3, 0, 3)
                end
            end
        end
    })

    ----------------------------------------------------
    -- SPECIFIC SECTION
    ----------------------------------------------------
    local function GetFilteredPlayers(filter)
        filter = string.lower(filter or "")
        local list = {}
        for _, p in ipairs(Players:GetPlayers()) do
            if p ~= LocalPlayer then
                if filter == "" or string.find(string.lower(p.Name), filter) or string.find(string.lower(p.DisplayName), filter) then
                    table.insert(list, p.Name)
                end
            end
        end
        if #list == 0 then table.insert(list, "No match found") end
        return list
    end

    local searchPlayerInput = SpecificSection:AddInput("SearchPlayerInput", {
        Title = "Search Player Name",
        Default = "",
        Placeholder = "Type player name to filter...",
        Callback = function() end
    })

    local specificDropdown = SpecificSection:AddDropdown("SpecificPlayerDropdown", {
        Title = "List of Players Drop Down Box",
        Values = GetFilteredPlayers(""),
        Multi = false,
        Default = 1,
    })

    searchPlayerInput:OnChanged(function(Value)
        specificDropdown:SetValues(GetFilteredPlayers(Value))
    end)

    specificDropdown:OnChanged(function(Value)
        if Value ~= "No match found" then SelectedSpecificPlayer = Players:FindFirstChild(Value) end
    end)

    SpecificSection:AddButton({
        Title = "Refresh Player Name",
        Callback = function()
            specificDropdown:SetValues(GetFilteredPlayers(searchPlayerInput.Value))
        end
    })

    -- Category Switch Tracker
    CategoryDropdown:OnChanged(function(Value)
        CurrentCategoryMode = Value
    end)
end

return TeleportModule
