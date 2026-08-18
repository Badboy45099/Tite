local players = game:GetService("Players")
local localPlayer = players.LocalPlayer
local playerGui = localPlayer:WaitForChild("PlayerGui")
local coreGui = game:GetService("CoreGui")
local userInputService = game:GetService("UserInputService")
local httpService = game:GetService("HttpService")

local SAVE_FILE_NAME = "Global_Core_UI_Layout.json"
local trackedData = {}
local editShields = {}
local disabledConstraints = {}
local initialSessionStates = {}
local isEditModeActive = false
local selectedObject = nil
local activeHighlight = nil

-- MONOCHROME STYLING CONFIG
local STYLE = {
	MainBg = Color3.fromRGB(15, 15, 15),
	CardBg = Color3.fromRGB(25, 25, 25),
	HeaderBg = Color3.fromRGB(35, 35, 35),
	Text = Color3.fromRGB(255, 255, 255),
	SubText = Color3.fromRGB(170, 170, 170),
	Border = Color3.fromRGB(60, 60, 60),
	ButtonBg = Color3.fromRGB(40, 40, 40),
	Accent = Color3.fromRGB(255, 255, 255)
}

-- 1. JSON FILE SYSTEM: Load Saved Layout
local function loadGlobalLayout()
	if not readfile then return end
	local success, content = pcall(function() return readfile(SAVE_FILE_NAME) end)
	if success and content then
		local decodeSuccess, decodedData = pcall(function() return httpService:JSONDecode(content) end)
		if decodeSuccess and type(decodedData) == "table" then
			for name, data in pairs(decodedData) do
				trackedData[name] = {
					Position = UDim2.new(data.PosXS, data.PosXO, data.PosYS, data.PosYO),
					Size = UDim2.new(data.SizeXS, data.SizeXO, data.SizeYS, data.SizeYO),
					Transparency = data.Transparency
				}
			end
		end
	end
end

local function disableLayoutConstraints(container)
	if not container then return end
	for _, child in ipairs(container:GetChildren()) do
		if child:IsA("UIGridLayout") or child:IsA("UIListLayout") or child:IsA("UIPageLayout") then
			if child.Enabled ~= false then
				child.Enabled = false
				table.insert(disabledConstraints, child)
			end
		end
	end
end

local function restoreLayoutConstraints()
	for _, constraint in ipairs(disabledConstraints) do
		if constraint and constraint.Parent then
			constraint.Enabled = true
		end
	end
	disabledConstraints = {}
end

-- 2. FILE SYSTEM: Apply Saved Properties
local function applySavedPositions()
	local containers = {playerGui, coreGui:WaitForChild("RobloxGui", 2)}
	for _, container in ipairs(containers) do
		if container then
			for _, descendant in ipairs(container:GetDescendants()) do
				if descendant:IsA("GuiObject") and trackedData[descendant.Name] then
					local data = trackedData[descendant.Name]
					disableLayoutConstraints(descendant.Parent)
					descendant.Position = data.Position
					if data.Size then descendant.Size = data.Size end
					if data.Transparency then
						if descendant:IsA("Frame") or descendant:IsA("TextLabel") or descendant:IsA("TextButton") or descendant:IsA("ImageButton") then
							descendant.BackgroundTransparency = data.Transparency
						end
					end
				end
			end
		end
	end
end

local function isProtectedControl(gui)
	local name = gui.Name:lower()
	if gui:IsDescendantOf(playerGui:FindFirstChild("CoreLayoutStudio")) then return true end
	if name:find("joystick") or name:find("dynamicthumbpad") or name:find("dpad") or name:find("thumbpad") then return true end
	return false
end

-- 3. CORE CONTROL PANEL SETUP
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "CoreLayoutStudio"
screenGui.ResetOnSpawn = false
screenGui.DisplayOrder = 999999
screenGui.Parent = playerGui

local mainFrame = Instance.new("Frame")
mainFrame.Size = UDim2.new(0, 240, 0, 230)
mainFrame.Position = UDim2.new(0.05, 0, 0.10, 0)
mainFrame.BackgroundColor3 = STYLE.MainBg
mainFrame.BorderSizePixel = 0
mainFrame.Active = true
mainFrame.Draggable = true
mainFrame.ZIndex = 1000000
mainFrame.Parent = screenGui

local mainCorner = Instance.new("UICorner")
mainCorner.CornerRadius = UDim.new(0, 10)
mainCorner.Parent = mainFrame

local mainStroke = Instance.new("UIStroke")
mainStroke.Color = STYLE.Border
mainStroke.Thickness = 1
mainStroke.Parent = mainFrame

local title = Instance.new("TextLabel")
title.Size = UDim2.new(1, -20, 0, 32)
title.Position = UDim2.new(0, 10, 0, 0)
title.Text = "SYSTEM UI STUDIO"
title.Font = Enum.Font.SourceSansBold
title.TextSize = 15
title.TextColor3 = STYLE.Text
title.TextXAlignment = Enum.TextXAlignment.Left
title.BackgroundTransparency = 1
title.ZIndex = 1000001
title.Parent = mainFrame

local statusLabel = Instance.new("TextLabel")
statusLabel.Size = UDim2.new(0.9, 0, 0, 18)
statusLabel.Position = UDim2.new(0.05, 0, 0.15, 0)
statusLabel.Text = "Status: UI Anchored"
statusLabel.Font = Enum.Font.SourceSansSemibold
statusLabel.TextSize = 13
statusLabel.TextColor3 = STYLE.SubText
statusLabel.BackgroundTransparency = 1
statusLabel.ZIndex = 1000001
statusLabel.Parent = mainFrame

local function createMainBtn(text, pos)
	local b = Instance.new("TextButton")
	b.Size = UDim2.new(0.9, 0, 0, 30)
	b.Position = pos
	b.Text = text
	b.Font = Enum.Font.SourceSansBold
	b.TextSize = 12
	b.TextColor3 = STYLE.Text
	b.BackgroundColor3 = STYLE.ButtonBg
	b.BorderSizePixel = 0
	b.ZIndex = 1000001
	b.Parent = mainFrame
	
	local c = Instance.new("UICorner")
	c.CornerRadius = UDim.new(0, 6)
	c.Parent = b

	local s = Instance.new("UIStroke")
	s.Color = STYLE.Border
	s.Thickness = 1
	s.Parent = b

	return b
end

local btnToggleEdit = createMainBtn("EDIT", UDim2.new(0.05, 0, 0.26, 0))
local btnSave = createMainBtn("SAVE", UDim2.new(0.05, 0, 0.43, 0))
local btnDiscard = createMainBtn("DISCARD", UDim2.new(0.05, 0, 0.60, 0))
local btnResetDefault = createMainBtn("RESET", UDim2.new(0.05, 0, 0.77, 0))

-- 4. BLACK & WHITE INSPECTOR PANEL
local inspectorFrame = Instance.new("Frame")
inspectorFrame.Size = UDim2.new(0, 240, 0, 270)
inspectorFrame.Position = UDim2.new(0.05, 0, 0.50, 0)
inspectorFrame.BackgroundColor3 = STYLE.CardBg
inspectorFrame.BorderSizePixel = 0
inspectorFrame.Visible = false
inspectorFrame.Active = true
inspectorFrame.Draggable = true
inspectorFrame.ZIndex = 1000000
inspectorFrame.Parent = screenGui

local inspCorner = Instance.new("UICorner")
inspCorner.CornerRadius = UDim.new(0, 10)
inspCorner.Parent = inspectorFrame

local inspStroke = Instance.new("UIStroke")
inspStroke.Color = STYLE.Border
inspStroke.Thickness = 1
inspStroke.Parent = inspectorFrame

local inspectorTitle = Instance.new("TextLabel")
inspectorTitle.Size = UDim2.new(1, -20, 0, 28)
inspectorTitle.Position = UDim2.new(0, 10, 0, 0)
inspectorTitle.Text = "ELEMENT ADJUSTER"
inspectorTitle.Font = Enum.Font.SourceSansBold
inspectorTitle.TextSize = 14
inspectorTitle.TextColor3 = STYLE.Text
inspectorTitle.TextXAlignment = Enum.TextXAlignment.Left
inspectorTitle.BackgroundTransparency = 1
inspectorTitle.ZIndex = 1000001
inspectorTitle.Parent = inspectorFrame

-- Modern Sizing Buttons
local lblResize = Instance.new("TextLabel")
lblResize.Size = UDim2.new(1, 0, 0, 16)
lblResize.Position = UDim2.new(0, 0, 0.11, 0)
lblResize.Text = "Sizing Controls"
lblResize.Font = Enum.Font.SourceSansSemibold
lblResize.TextSize = 12
lblResize.TextColor3 = STYLE.SubText
lblResize.BackgroundTransparency = 1
lblResize.ZIndex = 1000001
lblResize.Parent = inspectorFrame

local function createResizePill(text, pos, size)
	local b = Instance.new("TextButton")
	b.Size = size
	b.Position = pos
	b.Text = text
	b.Font = Enum.Font.SourceSansBold
	b.TextSize = 12
	b.TextColor3 = STYLE.Text
	b.BackgroundColor3 = STYLE.ButtonBg
	b.BorderSizePixel = 0
	b.ZIndex = 1000001
	b.Parent = inspectorFrame
	
	local c = Instance.new("UICorner")
	c.CornerRadius = UDim.new(0, 4)
	c.Parent = b

	local s = Instance.new("UIStroke")
	s.Color = STYLE.Border
	s.Thickness = 1
	s.Parent = b

	return b
end

local btnDecX = createResizePill("W -", UDim2.new(0.05, 0, 0.18, 0), UDim2.new(0.20, 0, 0, 22))
local btnIncX = createResizePill("W +", UDim2.new(0.27, 0, 0.18, 0), UDim2.new(0.20, 0, 0, 22))
local btnDecY = createResizePill("H -", UDim2.new(0.53, 0, 0.18, 0), UDim2.new(0.20, 0, 0, 22))
local btnIncY = createResizePill("H +", UDim2.new(0.75, 0, 0.18, 0), UDim2.new(0.20, 0, 0, 22))

-- Transparency Slider Section
local lblTrans = Instance.new("TextLabel")
lblTrans.Size = UDim2.new(1, 0, 0, 16)
lblTrans.Position = UDim2.new(0, 0, 0.28, 0)
lblTrans.Text = "Transparency"
lblTrans.Font = Enum.Font.SourceSansSemibold
lblTrans.TextSize = 12
lblTrans.TextColor3 = STYLE.SubText
lblTrans.BackgroundTransparency = 1
lblTrans.ZIndex = 1000001
lblTrans.Parent = inspectorFrame

local sliderTrack = Instance.new("Frame")
sliderTrack.Size = UDim2.new(0.9, 0, 0, 4)
sliderTrack.Position = UDim2.new(0.05, 0, 0.36, 0)
sliderTrack.BackgroundColor3 = STYLE.Border
sliderTrack.BorderSizePixel = 0
sliderTrack.ZIndex = 1000001
sliderTrack.Parent = inspectorFrame

local sliderThumb = Instance.new("TextButton")
sliderThumb.Size = UDim2.new(0, 14, 0, 14)
sliderThumb.Position = UDim2.new(0, 0, -1.2, 0)
sliderThumb.BackgroundColor3 = STYLE.Accent
sliderThumb.Text = ""
sliderThumb.BorderSizePixel = 0
sliderThumb.ZIndex = 1000002
sliderThumb.Parent = sliderTrack

local thumbCorner = Instance.new("UICorner")
thumbCorner.CornerRadius = UDim.new(1, 0)
thumbCorner.Parent = sliderThumb

-- CIRCLE REMOTE D-PAD
local remotePad = Instance.new("Frame")
remotePad.Size = UDim2.new(0, 110, 0, 110)
remotePad.Position = UDim2.new(0.5, -55, 0.54, 0)
remotePad.BackgroundColor3 = STYLE.HeaderBg
remotePad.BorderSizePixel = 0
remotePad.ZIndex = 1000001
remotePad.Parent = inspectorFrame

local remoteCorner = Instance.new("UICorner")
remoteCorner.CornerRadius = UDim.new(1, 0)
remoteCorner.Parent = remotePad

local remoteStroke = Instance.new("UIStroke")
remoteStroke.Color = STYLE.Border
remoteStroke.Thickness = 1
remoteStroke.Parent = remotePad

local function createRemoteBtn(text, pos, size)
	local b = Instance.new("TextButton")
	b.Size = size
	b.Position = pos
	b.Text = text
	b.Font = Enum.Font.SourceSansBold
	b.TextSize = 13
	b.TextColor3 = STYLE.Text
	b.BackgroundColor3 = STYLE.ButtonBg
	b.BorderSizePixel = 0
	b.ZIndex = 1000002
	b.Parent = remotePad
	
	local c = Instance.new("UICorner")
	c.CornerRadius = UDim.new(0, 4)
	c.Parent = b
	return b
end

local btnUp = createRemoteBtn("▲", UDim2.new(0.35, 0, 0.05, 0), UDim2.new(0.3, 0, 0.28, 0))
local btnDown = createRemoteBtn("▼", UDim2.new(0.35, 0, 0.67, 0), UDim2.new(0.3, 0, 0.28, 0))
local btnLeft = createRemoteBtn("◀", UDim2.new(0.05, 0, 0.35, 0), UDim2.new(0.28, 0, 0.3, 0))
local btnRight = createRemoteBtn("▶", UDim2.new(0.67, 0, 0.35, 0), UDim2.new(0.28, 0, 0.3, 0))

local centerIndicator = Instance.new("Frame")
centerIndicator.Size = UDim2.new(0, 14, 0, 14)
centerIndicator.Position = UDim2.new(0.5, -7, 0.5, -7)
centerIndicator.BackgroundColor3 = STYLE.Accent
centerIndicator.BorderSizePixel = 0
centerIndicator.ZIndex = 1000002
centerIndicator.Parent = remotePad

local centerCorner = Instance.new("UICorner")
centerCorner.CornerRadius = UDim.new(1, 0)
centerCorner.Parent = centerIndicator

local function saveState(obj)
	if not obj then return end
	local trans = 0
	if obj:IsA("GuiObject") then trans = obj.BackgroundTransparency end
	trackedData[obj.Name] = {
		Position = obj.Position,
		Size = obj.Size,
		Transparency = trans
	}
end

-- 5. INSPECTOR EVENT LOGIC
local STEP = 5

btnIncX.MouseButton1Click:Connect(function()
	if selectedObject then
		selectedObject.Size = selectedObject.Size + UDim2.new(0, STEP, 0, 0)
		saveState(selectedObject)
	end
end)

btnDecX.MouseButton1Click:Connect(function()
	if selectedObject then
		selectedObject.Size = selectedObject.Size - UDim2.new(0, STEP, 0, 0)
		saveState(selectedObject)
	end
end)

btnIncY.MouseButton1Click:Connect(function()
	if selectedObject then
		selectedObject.Size = selectedObject.Size + UDim2.new(0, 0, 0, STEP)
		saveState(selectedObject)
	end
end)

btnDecY.MouseButton1Click:Connect(function()
	if selectedObject then
		selectedObject.Size = selectedObject.Size - UDim2.new(0, 0, 0, STEP)
		saveState(selectedObject)
	end
end)

btnUp.MouseButton1Click:Connect(function()
	if selectedObject then
		selectedObject.Position = selectedObject.Position - UDim2.new(0, 0, 0, STEP)
		saveState(selectedObject)
	end
end)

btnDown.MouseButton1Click:Connect(function()
	if selectedObject then
		selectedObject.Position = selectedObject.Position + UDim2.new(0, 0, 0, STEP)
		saveState(selectedObject)
	end
end)

btnLeft.MouseButton1Click:Connect(function()
	if selectedObject then
		selectedObject.Position = selectedObject.Position - UDim2.new(0, STEP, 0, 0)
		saveState(selectedObject)
	end
end)

btnRight.MouseButton1Click:Connect(function()
	if selectedObject then
		selectedObject.Position = selectedObject.Position + UDim2.new(0, STEP, 0, 0)
		saveState(selectedObject)
	end
end)

local draggingSlider = false
sliderThumb.MouseButton1Down:Connect(function() draggingSlider = true end)
userInputService.InputEnded:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
		draggingSlider = false
	end
end)

userInputService.InputChanged:Connect(function(input)
	if draggingSlider and selectedObject and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
		local relX = math.clamp(input.Position.X - sliderTrack.AbsolutePosition.X, 0, sliderTrack.AbsoluteSize.X)
		local scale = relX / sliderTrack.AbsoluteSize.X
		sliderThumb.Position = UDim2.new(scale, -7, -1.2, 0)
		
		selectedObject.BackgroundTransparency = scale
		saveState(selectedObject)
	end
end)

local function highlightSelected(shield)
	if activeHighlight then
		activeHighlight.Border.Color = Color3.fromRGB(100, 100, 100)
		activeHighlight.Border.Thickness = 1
		activeHighlight.Shield.BackgroundTransparency = 1
	end
	
	if shield then
		local stroke = shield:FindFirstChildOfClass("UIStroke")
		if stroke then
			stroke.Color = Color3.fromRGB(255, 255, 255)
			stroke.Thickness = 2
		end
		shield.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
		shield.BackgroundTransparency = 0.88
		activeHighlight = {Shield = shield, Border = stroke}
	end
end

-- 6. SHIELD & DRAG SYSTEM OVERRIDE
local function setupShieldAndDrag(targetGui)
	if isProtectedControl(targetGui) then return end

	if not initialSessionStates[targetGui] then
		initialSessionStates[targetGui] = {
			Position = targetGui.Position,
			Size = targetGui.Size,
			Transparency = targetGui.BackgroundTransparency
		}
	end

	local shield = Instance.new("TextButton")
	shield.Size = UDim2.new(1, 0, 1, 0)
	shield.Position = UDim2.new(0, 0, 0, 0)
	shield.BackgroundTransparency = 1
	shield.Text = ""
	shield.ZIndex = 9999
	shield.Parent = targetGui

	local border = Instance.new("UIStroke")
	border.Color = Color3.fromRGB(100, 100, 100)
	border.Thickness = 1
	border.Parent = shield
	
	table.insert(editShields, shield)

	local dragging = false
	local dragInput, dragStart, startPosition

	shield.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			selectedObject = targetGui
			highlightSelected(shield)
			
			inspectorTitle.Text = "TARGET: " .. string.upper(targetGui.Name)
			inspectorFrame.Visible = true
			
			local currentTrans = targetGui.BackgroundTransparency or 0
			sliderThumb.Position = UDim2.new(currentTrans, -7, -1.2, 0)

			dragging = true
			dragStart = input.Position
			startPosition = targetGui.Position

			input.Changed:Connect(function()
				if input.UserInputState == Enum.UserInputState.End then
					dragging = false
					saveState(targetGui)
				end
			end)
		end
	end)

	shield.InputChanged:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
			dragInput = input
		end
	end)

	userInputService.InputChanged:Connect(function(input)
		if input == dragInput and dragging then
			disableLayoutConstraints(targetGui.Parent)
			local delta = input.Position - dragStart
			targetGui.Position = UDim2.new(
				startPosition.X.Scale, 
				startPosition.X.Offset + delta.X, 
				startPosition.Y.Scale, 
				startPosition.Y.Offset + delta.Y
			)
		end
	end)
end

local function cleanEditShields()
	highlightSelected(nil)
	for _, shield in ipairs(editShields) do
		if shield then shield:Destroy() end
	end
	editShields = {}
end

-- 7. RUNTIME CONTROLS
btnToggleEdit.MouseButton1Click:Connect(function()
	if isEditModeActive then return end
	isEditModeActive = true
	
	statusLabel.Text = "Status: Overriding Layouts..."
	statusLabel.TextColor3 = STYLE.Text
	
	local targets = {playerGui, coreGui:WaitForChild("RobloxGui", 2)}
	for _, container in ipairs(targets) do
		if container then
			for _, descendant in ipairs(container:GetDescendants()) do
				if descendant:IsA("GuiObject") and descendant.Visible and not isProtectedControl(descendant) then
					if descendant:IsA("TextButton") or descendant:IsA("ImageButton") or descendant:IsA("TextBox") or descendant.Name:find("Button") or descendant.Name:find("Chat") or descendant.Name:find("Jump") then
						setupShieldAndDrag(descendant)
					end
				end
			end
		end
	end
end)

btnSave.MouseButton1Click:Connect(function()
	if not isEditModeActive then return end
	isEditModeActive = false
	inspectorFrame.Visible = false
	selectedObject = nil
	cleanEditShields()
	
	if writefile then
		local exportTable = {}
		for name, data in pairs(trackedData) do
			local pos = data.Position
			local sz = data.Size
			exportTable[name] = {
				PosXS = pos.X.Scale, PosXO = pos.X.Offset,
				PosYS = pos.Y.Scale, PosYO = pos.Y.Offset,
				SizeXS = sz.X.Scale, SizeXO = sz.X.Offset,
				SizeYS = sz.Y.Scale, SizeYO = sz.Y.Offset,
				Transparency = data.Transparency or 0
			}
		end
		pcall(function() 
			writefile(SAVE_FILE_NAME, httpService:JSONEncode(exportTable)) 
		end)
	end
	
	statusLabel.Text = "Status: JSON Layout Saved!"
	statusLabel.TextColor3 = STYLE.SubText
end)

btnDiscard.MouseButton1Click:Connect(function()
	if not isEditModeActive then return end
	isEditModeActive = false
	inspectorFrame.Visible = false
	selectedObject = nil
	cleanEditShields()
	
	for obj, state in pairs(initialSessionStates) do
		if obj and obj.Parent then
			obj.Position = state.Position
			obj.Size = state.Size
			obj.BackgroundTransparency = state.Transparency
		end
	end
	
	statusLabel.Text = "Status: Changes Discarded"
	statusLabel.TextColor3 = STYLE.SubText
end)

btnResetDefault.MouseButton1Click:Connect(function()
	isEditModeActive = false
	inspectorFrame.Visible = false
	selectedObject = nil
	cleanEditShields()
	trackedData = {}
	
	if delfile then
		pcall(function() delfile(SAVE_FILE_NAME) end)
	end
	
	for obj, state in pairs(initialSessionStates) do
		if obj and obj.Parent then
			obj.Position = state.Position
			obj.Size = state.Size
			obj.BackgroundTransparency = state.Transparency
		end
	end
	restoreLayoutConstraints()
	
	statusLabel.Text = "Status: Reset To Defaults!"
	statusLabel.TextColor3 = STYLE.SubText
end)

-- Initialize
loadGlobalLayout()
task.wait(3)
applySavedPositions()
