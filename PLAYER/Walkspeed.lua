local WalkSpeedSliderModule = {}
 
-- Store global execution connections to prevent memory leaks or duplicate movement loops
local _G = _G or {}
if _G.BypassMovementHook then
    _G.BypassMovementHook:Disconnect()
    _G.BypassMovementHook = nil
end
 
_G.MovementSpeedMultiplier = 1.0 
 
function WalkSpeedSliderModule.Create(SpeedTitle, LocalPlayer, UIS)
    task.spawn(function()
        task.wait(0.3)
 
        local paragraphFrame = SpeedTitle.Frame
        if not paragraphFrame then return end
 
        -- DO NOT modify paragraphFrame.Size directly to prevent breaking UIListLayout or ScrollingFrames
        paragraphFrame.ClipsDescendants = false
 
        -- Build Track (Positioned cleanly inside default element bounds)
        local Track = Instance.new("Frame")
        Track.Name = "InstantTouchTrack"
        Track.Size = UDim2.new(1, -20, 0, 6)
        Track.Position = UDim2.new(0, 10, 1, -12) -- Anchored relative to bottom edge
        Track.BackgroundColor3 = Color3.fromRGB(45, 45, 55)
        Track.BorderSizePixel = 0
        Track.ZIndex = 10 -- Elevated ZIndex so it stays on top of parent background layers
        Track.Parent = paragraphFrame
 
        local TrackCorner = Instance.new("UICorner")
        TrackCorner.CornerRadius = UDim.new(1, 0)
        TrackCorner.Parent = Track
 
        -- Build Fill Bar
        local Fill = Instance.new("Frame")
        Fill.Name = "Fill"
        Fill.Size = UDim2.new(0, 0, 1, 0)
        Fill.BackgroundColor3 = Color3.fromRGB(0, 170, 255)
        Fill.BorderSizePixel = 0
        Fill.ZIndex = 11
        Fill.Parent = Track
 
        local FillCorner = Instance.new("UICorner")
        FillCorner.CornerRadius = UDim.new(1, 0)
        FillCorner.Parent = Fill
 
        -- Build Knob
        local Knob = Instance.new("Frame")
        Knob.Name = "Knob"
        Knob.Size = UDim2.new(0, 12, 0, 12)
        Knob.AnchorPoint = Vector2.new(0.5, 0.5)
        Knob.Position = UDim2.new(0, 0, 0.5, 0)
        Knob.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
        Knob.ZIndex = 12
        Knob.Parent = Track
 
        local KnobCorner = Instance.new("UICorner")
        KnobCorner.CornerRadius = UDim.new(1, 0)
        KnobCorner.Parent = Knob
 
        -- Touch Area
        local TouchArea = Instance.new("TextButton")
        TouchArea.Name = "TouchArea"
        TouchArea.Size = UDim2.new(1, 0, 0, 24)
        TouchArea.Position = UDim2.new(0, 0, 0.5, -12)
        TouchArea.BackgroundTransparency = 1
        TouchArea.Text = ""
        TouchArea.Active = true
        TouchArea.ZIndex = 13
        TouchArea.Parent = Track
 
        local isDragging = false
 
        local function UpdateSpeed(inputX)
            local trackX = Track.AbsolutePosition.X
            local trackWidth = Track.AbsoluteSize.X
 
            if trackWidth > 0 then
                local percent = math.clamp((inputX - trackX) / trackWidth, 0, 1)
 
                local minSpd = 16
                local maxSpd = 200
                local targetSpeed = math.clamp(math.floor(minSpd + (percent * (maxSpd - minSpd)) + 0.5), minSpd, maxSpd)
 
                Fill.Size = UDim2.new(percent, 0, 1, 0)
                Knob.Position = UDim2.new(percent, 0, 0.5, 0)
 
                -- Compact title text to prevent overflow line wrapping
                SpeedTitle:SetTitle("Speed: " .. tostring(targetSpeed))
 
                _G.MovementSpeedMultiplier = targetSpeed / 16
            end
        end
 
        local RunService = game:GetService("RunService")
        _G.BypassMovementHook = RunService.RenderStepped:Connect(function(deltaTime)
            local character = LocalPlayer.Character
            if not character then return end
 
            local humanoid = character:FindFirstChildOfClass("Humanoid")
            local rootPart = character:FindFirstChild("HumanoidRootPart")
 
            if humanoid and rootPart and humanoid.MoveDirection.Magnitude > 0 then
                local rawVelocityVector = humanoid.MoveDirection * (_G.MovementSpeedMultiplier - 1.0) * (16 * deltaTime)
                rootPart.CFrame = rootPart.CFrame + Vector3.new(rawVelocityVector.X, 0, rawVelocityVector.Z)
            end
        end)
 
        TouchArea.InputBegan:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseButton1 then
                isDragging = true
                UpdateSpeed(input.Position.X)
            end
        end)
 
        UIS.InputChanged:Connect(function(input)
            if isDragging and (input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseMovement) then
                UpdateSpeed(input.Position.X)
            end
        end)
 
        UIS.InputEnded:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseButton1 then
                isDragging = false
            end
        end)
    end)
end
 
return WalkSpeedSliderModule
