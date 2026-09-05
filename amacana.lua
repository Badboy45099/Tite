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
local TweenService = game:GetService("TweenService")

local localPlayer = Players.LocalPlayer
local playerGui = localPlayer:WaitForChild("PlayerGui")
local camera = Workspace.CurrentCamera

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
CircleStroke.Color = Color3.fromRGB(150, 0, 0)
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
MainGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
MainGui.Parent = GetSafeGuiParent()

local Frame = Instance.new("Frame")
Frame.Name = "MainFrame"
Frame.Size = UDim2.new(0, 540, 0, 480)
Frame.Position = UDim2.new(0.5, -270, 0.5, -240)
Frame.BackgroundColor3 = Color3.fromRGB(10, 10, 10)
Frame.BorderSizePixel = 0
Frame.Active = true
Frame.Draggable = true
Frame.Parent = MainGui

local FrameCorner = Instance.new("UICorner")
FrameCorner.CornerRadius = UDim.new(0, 14)
FrameCorner.Parent = Frame

local FrameStroke = Instance.new("UIStroke")
FrameStroke.Color = Color3.fromRGB(70, 70, 70)
FrameStroke.Thickness = 1
FrameStroke.Transparency = 0.12
FrameStroke.Parent = Frame

local MenuScale = Instance.new("UIScale")
MenuScale.Scale = 0.94
MenuScale.Parent = Frame

local WHITE = Color3.fromRGB(245, 245, 245)
local BLACK = Color3.fromRGB(12, 12, 12)
local DARK = Color3.fromRGB(32, 32, 32)
local DARKER = Color3.fromRGB(23, 23, 23)
local MID = Color3.fromRGB(52, 52, 52)
local MUTED = Color3.fromRGB(165, 165, 165)
local RED = Color3.fromRGB(150, 12, 24)
local RED_BRIGHT = Color3.fromRGB(190, 20, 34)
local RED_DARK = Color3.fromRGB(55, 12, 17)

local FastTween = TweenInfo.new(0.12, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
local MenuTween = TweenInfo.new(0.22, Enum.EasingStyle.Quint, Enum.EasingDirection.Out)

local function addCorner(instance, radius)
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, radius or 8)
	corner.Parent = instance
	return corner
end

local function addStroke(instance, transparency)
	local stroke = Instance.new("UIStroke")
	stroke.Color = Color3.fromRGB(100, 100, 100)
	stroke.Thickness = 1
	stroke.Transparency = transparency or 0.55
	stroke.Parent = instance
	return stroke
end

local function addButtonFX(button)
	button.AutoButtonColor = false

	button.MouseEnter:Connect(function()
		TweenService:Create(button, FastTween, {
			BackgroundTransparency = 0.08
		}):Play()
	end)

	button.MouseLeave:Connect(function()
		TweenService:Create(button, FastTween, {
			BackgroundTransparency = 0
		}):Play()
	end)

	button.MouseButton1Down:Connect(function()
		TweenService:Create(button, FastTween, {
			BackgroundTransparency = 0.18
		}):Play()
	end)

	button.MouseButton1Up:Connect(function()
		TweenService:Create(button, FastTween, {
			BackgroundTransparency = 0.08
		}):Play()
	end)
end

--// TITLE
local TitleBar = Instance.new("Frame")
TitleBar.Name = "TitleBar"
TitleBar.Size = UDim2.new(1, -20, 0, 52)
TitleBar.Position = UDim2.new(0, 10, 0, 10)
TitleBar.BackgroundColor3 = Color3.fromRGB(18, 18, 18)
TitleBar.BorderSizePixel = 0
TitleBar.Parent = Frame
addCorner(TitleBar, 10)
addStroke(TitleBar, 0.65)

local TitleIcon = Instance.new("TextLabel")
TitleIcon.Size = UDim2.new(0, 34, 1, 0)
TitleIcon.Position = UDim2.new(0, 12, 0, 0)
TitleIcon.BackgroundTransparency = 1
TitleIcon.Text = "◎"
TitleIcon.TextColor3 = RED_BRIGHT
TitleIcon.TextSize = 24
TitleIcon.Font = Enum.Font.GothamBold
TitleIcon.Parent = TitleBar

local Title = Instance.new("TextLabel")
Title.Size = UDim2.new(1, -150, 1, 0)
Title.Position = UDim2.new(0, 44, 0, 0)
Title.BackgroundTransparency = 1
Title.Text = "EXTREME FORCE AIMBOT"
Title.TextColor3 = WHITE
Title.TextSize = 16
Title.Font = Enum.Font.GothamBold
Title.TextXAlignment = Enum.TextXAlignment.Left
Title.Parent = TitleBar

local StatusDot = Instance.new("Frame")
StatusDot.Name = "StatusDot"
StatusDot.Size = UDim2.new(0, 7, 0, 7)
StatusDot.Position = UDim2.new(0, 44, 1, -13)
StatusDot.BackgroundColor3 = RED_BRIGHT
StatusDot.BorderSizePixel = 0
StatusDot.Parent = TitleBar
addCorner(StatusDot, 99)

local StatusText = Instance.new("TextLabel")
StatusText.Size = UDim2.new(0, 90, 0, 14)
StatusText.Position = UDim2.new(0, 57, 1, -17)
StatusText.BackgroundTransparency = 1
StatusText.Text = "READY"
StatusText.TextColor3 = MUTED
StatusText.TextSize = 8
StatusText.Font = Enum.Font.GothamBold
StatusText.TextXAlignment = Enum.TextXAlignment.Left
StatusText.Parent = TitleBar

local HideHint = Instance.new("TextLabel")
HideHint.Size = UDim2.new(0, 115, 1, 0)
HideHint.Position = UDim2.new(1, -125, 0, 0)
HideHint.BackgroundTransparency = 1
HideHint.Text = "PRESS  L  TO HIDE"
HideHint.TextColor3 = MUTED
HideHint.TextSize = 10
HideHint.Font = Enum.Font.GothamMedium
HideHint.TextXAlignment = Enum.TextXAlignment.Right
HideHint.Parent = TitleBar

local AccentLine = Instance.new("Frame")
AccentLine.Size = UDim2.new(1, -24, 0, 1)
AccentLine.Position = UDim2.new(0, 12, 1, -1)
AccentLine.BackgroundColor3 = RED_BRIGHT
AccentLine.BackgroundTransparency = 0.18
AccentLine.BorderSizePixel = 0
AccentLine.Parent = TitleBar

--// LEFT PANEL
local LeftPanel = Instance.new("Frame")
LeftPanel.Name = "ControlsPanel"
LeftPanel.Size = UDim2.new(0, 250, 0, 396)
LeftPanel.Position = UDim2.new(0, 10, 0, 70)
LeftPanel.BackgroundColor3 = DARKER
LeftPanel.BorderSizePixel = 0
LeftPanel.Parent = Frame
addCorner(LeftPanel, 10)
addStroke(LeftPanel, 0.72)

local ControlsPadding = Instance.new("UIPadding")
ControlsPadding.PaddingTop = UDim.new(0, 10)
ControlsPadding.PaddingLeft = UDim.new(0, 10)
ControlsPadding.PaddingRight = UDim.new(0, 10)
ControlsPadding.Parent = LeftPanel

local ControlsLayout = Instance.new("UIListLayout")
ControlsLayout.Padding = UDim.new(0, 7)
ControlsLayout.SortOrder = Enum.SortOrder.LayoutOrder
ControlsLayout.Parent = LeftPanel

local function sectionLabel(parent, text, order)
	local label = Instance.new("TextLabel")
	label.Size = UDim2.new(1, 0, 0, 20)
	label.BackgroundTransparency = 1
	label.Text = text
	label.TextColor3 = Color3.fromRGB(185, 185, 185)
	label.TextSize = 9
	label.Font = Enum.Font.GothamBold
	label.TextXAlignment = Enum.TextXAlignment.Left
	label.LayoutOrder = order
	label.Parent = parent
	return label
end

local function makePanelButton(parent, text, height)
	local button = Instance.new("TextButton")
	button.Size = UDim2.new(1, 0, 0, height or 34)
	button.BackgroundColor3 = DARK
	button.BorderSizePixel = 0
	button.Text = text
	button.TextColor3 = WHITE
	button.TextSize = 11
	button.Font = Enum.Font.GothamMedium
	button.TextXAlignment = Enum.TextXAlignment.Left
	button.TextTruncate = Enum.TextTruncate.AtEnd
	button.Parent = parent
	addCorner(button, 8)
	addStroke(button, 0.78)
	addButtonFX(button)
	return button
end

sectionLabel(LeftPanel, "AIM CONTROL", 1)

local function createToggle(parent, text, default, callback)
	local state = default
	local button = makePanelButton(parent, "", 34)

	local function refresh()
		button.BackgroundColor3 = state and RED_DARK or DARK
		button.TextColor3 = WHITE
		button.Text = "  " .. text .. "                                      " .. (state and "ON" or "OFF")
	end

	button.MouseButton1Click:Connect(function()
		state = not state
		refresh()
		callback(state)
		saveConfig()
	end)

	refresh()
	return button
end

local EnableBtn = createToggle(LeftPanel, "Extreme Aimbot", CONFIG.enabled, function(v)
	CONFIG.enabled = v
    updateFOVCircle()
end)

local ShowFOVBtn = createToggle(LeftPanel, "Show FOV Circle", CONFIG.showFOV, function(v)
	CONFIG.showFOV = v
	FOVCircle.Visible = v
    updateFOVCircle()
end)

local WallCheckBtn = createToggle(LeftPanel, "Wall Check", CONFIG.wallCheck, function(v)
	CONFIG.wallCheck = v
end)

sectionLabel(LeftPanel, "TARGET", 5)

local TargetBtn = makePanelButton(LeftPanel, "", 34)
TargetBtn.TextXAlignment = Enum.TextXAlignment.Left

local function refreshTargetButton()
	TargetBtn.BackgroundColor3 = DARK
	TargetBtn.TextColor3 = WHITE
	TargetBtn.Text = "  Target Part     •    " .. CONFIG.targetPart
end

TargetBtn.MouseButton1Click:Connect(function()
	CONFIG.targetPart = (CONFIG.targetPart == "Head") and "Torso" or "Head"
	refreshTargetButton()
	saveConfig()
end)
refreshTargetButton()

sectionLabel(LeftPanel, "TEAM / TRUST MODE", 7)

local TeamBtn = makePanelButton(LeftPanel, "", 34)
local teamModes = {"Off", "Roblox Team", "Trusted Players", "Damage Check"}
local currentMode = 1

for i, mode in ipairs(teamModes) do
	if mode == CONFIG.teamCheckMode then
		currentMode = i
		break
	end
end

local function refreshTeamButton()
	TeamBtn.BackgroundColor3 = DARK
	TeamBtn.TextColor3 = WHITE
	TeamBtn.Text = "  Team Mode    •    " .. CONFIG.teamCheckMode
end

TeamBtn.MouseButton1Click:Connect(function()
	currentMode = (currentMode % #teamModes) + 1
	CONFIG.teamCheckMode = teamModes[currentMode]
	refreshTeamButton()
	saveConfig()
end)
refreshTeamButton()

sectionLabel(LeftPanel, "FOV", 9)

local FOVRow = Instance.new("Frame")
FOVRow.Size = UDim2.new(1, 0, 0, 34)
FOVRow.BackgroundTransparency = 1
FOVRow.LayoutOrder = 10
FOVRow.Parent = LeftPanel

local FOVLabel = Instance.new("TextLabel")
FOVLabel.Size = UDim2.new(1, -78, 1, 0)
FOVLabel.BackgroundColor3 = DARK
FOVLabel.BorderSizePixel = 0
FOVLabel.Text = "  FOV    •    " .. CONFIG.fov
FOVLabel.TextColor3 = WHITE
FOVLabel.TextSize = 11
FOVLabel.Font = Enum.Font.GothamMedium
FOVLabel.TextXAlignment = Enum.TextXAlignment.Left
FOVLabel.Parent = FOVRow
addCorner(FOVLabel, 8)
addStroke(FOVLabel, 0.78)

local MinusBtn = Instance.new("TextButton")
MinusBtn.Size = UDim2.new(0, 34, 1, 0)
MinusBtn.Position = UDim2.new(1, -72, 0, 0)
MinusBtn.BackgroundColor3 = DARK
MinusBtn.BorderSizePixel = 0
MinusBtn.Text = "−"
MinusBtn.TextColor3 = WHITE
MinusBtn.TextSize = 16
MinusBtn.Font = Enum.Font.GothamBold
MinusBtn.Parent = FOVRow
addCorner(MinusBtn, 8)
addButtonFX(MinusBtn)

local PlusBtn = MinusBtn:Clone()
PlusBtn.Name = "PlusButton"
PlusBtn.Position = UDim2.new(1, -34, 0, 0)
PlusBtn.Text = "+"
PlusBtn.Parent = FOVRow
addButtonFX(PlusBtn)

local function refreshFOVLabel()
	FOVLabel.Text = "  FOV    •    " .. CONFIG.fov
end

MinusBtn.MouseButton1Click:Connect(function()
	CONFIG.fov = math.max(50, CONFIG.fov - 25)
	refreshFOVLabel()
	updateFOVCircle()
	saveConfig()
end)

PlusBtn.MouseButton1Click:Connect(function()
	CONFIG.fov = math.min(400, CONFIG.fov + 25)
	refreshFOVLabel()
	updateFOVCircle()
	saveConfig()
end)

sectionLabel(LeftPanel, "TRUSTED PLAYERS", 11)

local ManualInput = Instance.new("TextBox")
ManualInput.Size = UDim2.new(1, 0, 0, 34)
ManualInput.BackgroundColor3 = DARK
ManualInput.BorderSizePixel = 0
ManualInput.PlaceholderText = "  Enter player name..."
ManualInput.PlaceholderColor3 = Color3.fromRGB(125, 125, 125)
ManualInput.Text = ""
ManualInput.TextColor3 = WHITE
ManualInput.TextSize = 11
ManualInput.Font = Enum.Font.Gotham
ManualInput.ClearTextOnFocus = false
ManualInput.LayoutOrder = 12
ManualInput.Parent = LeftPanel
addCorner(ManualInput, 8)
addStroke(ManualInput, 0.78)

local ManualAddBtn = makePanelButton(LeftPanel, "  +   Add Trusted Player", 32)
ManualAddBtn.BackgroundColor3 = RED
ManualAddBtn.TextColor3 = WHITE
ManualAddBtn.LayoutOrder = 13

ManualAddBtn.MouseButton1Click:Connect(function()
	local name = ManualInput.Text
	if name and name ~= "" then
		toggleTrustUser(name)
		ManualInput.Text = ""
		updateLists()
		saveConfig()
	end
end)

local ClearBtn = makePanelButton(LeftPanel, "  ×   Clear Trusted Players", 32)
ClearBtn.LayoutOrder = 14

ClearBtn.MouseButton1Click:Connect(function()
	CONFIG.trustedPlayers = {}
	updateLists()
	saveConfig()
end)

--// RIGHT PANEL
local RightPanel = Instance.new("Frame")
RightPanel.Name = "PlayersPanel"
RightPanel.Size = UDim2.new(0, 260, 0, 396)
RightPanel.Position = UDim2.new(0, 270, 0, 70)
RightPanel.BackgroundColor3 = DARKER
RightPanel.BorderSizePixel = 0
RightPanel.Parent = Frame
addCorner(RightPanel, 10)
addStroke(RightPanel, 0.72)

local RefreshBtn = Instance.new("TextButton")
RefreshBtn.Size = UDim2.new(1, -20, 0, 34)
RefreshBtn.Position = UDim2.new(0, 10, 0, 10)
RefreshBtn.BackgroundColor3 = DARK
RefreshBtn.BorderSizePixel = 0
RefreshBtn.Text = "  ↻   Refresh Players List"
RefreshBtn.TextColor3 = WHITE
RefreshBtn.TextSize = 11
RefreshBtn.Font = Enum.Font.GothamMedium
RefreshBtn.TextXAlignment = Enum.TextXAlignment.Left
RefreshBtn.Parent = RightPanel
addCorner(RefreshBtn, 8)
addStroke(RefreshBtn, 0.78)
addButtonFX(RefreshBtn)

local ServerLabel = Instance.new("TextLabel")
ServerLabel.Size = UDim2.new(1, -20, 0, 25)
ServerLabel.Position = UDim2.new(0, 10, 0, 49)
ServerLabel.BackgroundTransparency = 1
ServerLabel.Text = "  SERVER PLAYERS  /  CLICK TO TRUST"
ServerLabel.TextColor3 = MUTED
ServerLabel.TextSize = 9
ServerLabel.Font = Enum.Font.GothamBold
ServerLabel.TextXAlignment = Enum.TextXAlignment.Left
ServerLabel.Parent = RightPanel

local ServerScroll = Instance.new("ScrollingFrame")
ServerScroll.Size = UDim2.new(1, -20, 0, 145)
ServerScroll.Position = UDim2.new(0, 10, 0, 72)
ServerScroll.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
ServerScroll.BorderSizePixel = 0
ServerScroll.ScrollBarThickness = 3
ServerScroll.ScrollBarImageColor3 = RED_BRIGHT
ServerScroll.ScrollBarImageTransparency = 0.45
ServerScroll.CanvasSize = UDim2.new(0, 0, 0, 0)
ServerScroll.Parent = RightPanel
addCorner(ServerScroll, 8)
addStroke(ServerScroll, 0.82)

local ServerLayout = Instance.new("UIListLayout")
ServerLayout.Padding = UDim.new(0, 5)
ServerLayout.SortOrder = Enum.SortOrder.LayoutOrder
ServerLayout.Parent = ServerScroll

local TrustedHeaderLabel = Instance.new("TextLabel")
TrustedHeaderLabel.Size = UDim2.new(1, -20, 0, 25)
TrustedHeaderLabel.Position = UDim2.new(0, 10, 0, 225)
TrustedHeaderLabel.BackgroundTransparency = 1
TrustedHeaderLabel.Text = "  TRUSTED PLAYERS  /  " .. #CONFIG.trustedPlayers .. " SAVED"
TrustedHeaderLabel.TextColor3 = MUTED
TrustedHeaderLabel.TextSize = 9
TrustedHeaderLabel.Font = Enum.Font.GothamBold
TrustedHeaderLabel.TextXAlignment = Enum.TextXAlignment.Left
TrustedHeaderLabel.Parent = RightPanel

local TrustedScroll = Instance.new("ScrollingFrame")
TrustedScroll.Size = UDim2.new(1, -20, 0, 135)
TrustedScroll.Position = UDim2.new(0, 10, 0, 250)
TrustedScroll.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
TrustedScroll.BorderSizePixel = 0
TrustedScroll.ScrollBarThickness = 3
TrustedScroll.ScrollBarImageColor3 = RED_BRIGHT
TrustedScroll.ScrollBarImageTransparency = 0.45
TrustedScroll.CanvasSize = UDim2.new(0, 0, 0, 0)
TrustedScroll.Parent = RightPanel
addCorner(TrustedScroll, 8)
addStroke(TrustedScroll, 0.82)

local TrustedLayout = Instance.new("UIListLayout")
TrustedLayout.Padding = UDim.new(0, 5)
TrustedLayout.SortOrder = Enum.SortOrder.LayoutOrder
TrustedLayout.Parent = TrustedScroll

local function createListButton(parent, text, active)
	local btn = Instance.new("TextButton")
	btn.Size = UDim2.new(1, -10, 0, 30)
	btn.BackgroundColor3 = active and RED_DARK or MID
	btn.BorderSizePixel = 0
	btn.TextColor3 = WHITE
	btn.TextSize = 10
	btn.Font = Enum.Font.GothamMedium
	btn.TextXAlignment = Enum.TextXAlignment.Left
	btn.TextTruncate = Enum.TextTruncate.AtEnd
	btn.Text = active and ("  ●   " .. text) or ("  ○   " .. text)
	btn.Parent = parent
	addCorner(btn, 7)
	addStroke(btn, 0.82)
	addButtonFX(btn)
	return btn
end

local function updateLists()
	for _, child in ipairs(ServerScroll:GetChildren()) do
		if child:IsA("TextButton") then
			child:Destroy()
		end
	end

	for _, child in ipairs(TrustedScroll:GetChildren()) do
		if child:IsA("TextButton") then
			child:Destroy()
		end
	end

	local players = Players:GetPlayers()
	table.sort(players, function(a, b)
		return a.Name:lower() < b.Name:lower()
	end)

	for _, player in ipairs(players) do
		if player ~= localPlayer then
			local isTrusted = isUserTrusted(player.Name)
			local btn = createListButton(ServerScroll, player.Name, isTrusted)

			btn.MouseButton1Click:Connect(function()
				toggleTrustUser(player.Name)
				updateLists()
				saveConfig()
			end)
		end
	end

	for _, name in ipairs(CONFIG.trustedPlayers) do
		local btn = createListButton(TrustedScroll, name, true)

		btn.MouseButton1Click:Connect(function()
			toggleTrustUser(name)
			updateLists()
			saveConfig()
		end)
	end

	task.defer(function()
		ServerScroll.CanvasSize = UDim2.new(0, 0, 0, ServerLayout.AbsoluteContentSize.Y + 8)
		TrustedScroll.CanvasSize = UDim2.new(0, 0, 0, TrustedLayout.AbsoluteContentSize.Y + 8)
		TrustedHeaderLabel.Text = "  TRUSTED PLAYERS  /  " .. #CONFIG.trustedPlayers .. " SAVED"
	end)
end

RefreshBtn.MouseButton1Click:Connect(function()
	updateLists()
end)

Players.PlayerAdded:Connect(function()
	task.wait(0.15)
	updateLists()
end)

Players.PlayerRemoving:Connect(function()
	task.wait(0.15)
	updateLists()
end)

--// MENU ANIMATION
local menuVisible = true
local menuTween

local function setMenuVisible(visible)
	if menuTween then
		pcall(function()
			menuTween:Cancel()
		end)
	end

	menuVisible = visible

	if visible then
		Frame.Visible = true
		MenuScale.Scale = 0.94
		menuTween = TweenService:Create(MenuScale, MenuTween, {Scale = 1})
		menuTween:Play()
	else
		menuTween = TweenService:Create(MenuScale, MenuTween, {Scale = 0.94})
		menuTween:Play()
		menuTween.Completed:Connect(function()
			if not menuVisible then
				Frame.Visible = false
			end
		end)
	end
end

updateLists()

--// ============================================

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
		setMenuVisible(not menuVisible)
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
