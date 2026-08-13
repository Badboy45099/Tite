local BrightnessSliderModule = {}

function BrightnessSliderModule.Create(BrightnessTitle, UIS)
    task.spawn(function()
        task.wait(0.3) -- Wait for Fluent to construct BrightnessTitle.Frame

        local Lighting = game:GetService("Lighting")

        -- 1. Get the host Paragraph Frame
        local paragraphFrame = BrightnessTitle.Frame
        if not paragraphFrame then return end

        -- Expand paragraph frame height
        paragraphFrame.Size = UDim2.new(paragraphFrame.Size.X.Scale, paragraphFrame.Size.X.Offset, 0, 20)

        -- 2. Build Track
        local Track = Instance.new("Frame")
        Track.Name = "InstantTouchTrack"
        Track.Size = UDim2.new(1, -20, 0, 8)
        Track.Position = UDim2.new(0, 10, 1, -12)
        Track.BackgroundColor3 = Color3.fromRGB(45, 45, 55)
        Track.BorderSizePixel = 0
        Track.Parent = paragraphFrame

        local TrackCorner = Instance.new("UICorner")
        TrackCorner.CornerRadius = UDim.new(1, 0)
        TrackCorner.Parent = Track

        -- 3. Build Fill Bar
        local Fill = Instance.new("Frame")
        Fill.Name = "Fill"
        Fill.Size = UDim2.new(0, 0, 1, 0)
        Fill.BackgroundColor3 = Color3.fromRGB(255, 200, 0) -- Warm yellow accent for brightness
        Fill.BorderSizePixel = 0
        Fill.Parent = Track

        local FillCorner = Instance.new("UICorner")
        FillCorner.CornerRadius = UDim.new(1, 0)
        FillCorner.Parent = Fill

        -- 4. Build Knob
        local Knob = Instance.new("Frame")
        Knob.Name = "Knob"
        Knob.Size = UDim2.new(0, 14, 0, 14)
        Knob.AnchorPoint = Vector2.new(0.5, 0.5)
        Knob.Position = UDim2.new(0, 0, 0.5, 0)
        Knob.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
        Knob.Parent = Track

        local KnobCorner = Instance.new("UICorner")
        KnobCorner.CornerRadius = UDim.new(1, 0)
        KnobCorner.Parent = Knob

        -- 5. Touch Area
        local TouchArea = Instance.new("TextButton")
        TouchArea.Name = "TouchArea"
        TouchArea.Size = UDim2.new(1, 0, 0, 28)
        TouchArea.Position = UDim2.new(0, 0, 0.5, -14)
        TouchArea.BackgroundTransparency = 1
        TouchArea.Text = ""
        TouchArea.Active = true
        TouchArea.Parent = Track

        -- 6. Drag Logic
        local isDragging = false

        local function UpdateBrightness(inputX)
            local trackX = Track.AbsolutePosition.X
            local trackWidth = Track.AbsoluteSize.X

            if trackWidth > 0 then
                local percent = math.clamp((inputX - trackX) / trackWidth, 0, 1)
                local minVal = 0
                local maxVal = 10 -- Range from 0 to 10
                
                -- Calculate brightness rounded to 1 decimal place
                local newBrightness = math.floor((minVal + (percent * (maxVal - minVal))) * 10 + 0.5) / 10

                Fill.Size = UDim2.new(percent, 0, 1, 0)
                Knob.Position = UDim2.new(percent, 0, 0.5, 0)
                BrightnessTitle:SetTitle("Brightness: " .. string.format("%.1f", newBrightness))

                -- Apply to Roblox Lighting
                Lighting.Brightness = newBrightness
            end
        end

        -- Connections
        TouchArea.InputBegan:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseButton1 then
                isDragging = true
                UpdateBrightness(input.Position.X)
            end
        end)

        UIS.InputChanged:Connect(function(input)
            if isDragging and (input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseMovement) then
                UpdateBrightness(input.Position.X)
            end
        end)

        UIS.InputEnded:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseButton1 then
                isDragging = false
            end
        end)
    end)
end

return BrightnessSliderModule
