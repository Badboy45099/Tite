local HttpService = game:GetService("HttpService")
local ScriptManager = {}

ScriptManager.FileName = "saved_scripts.json"
ScriptManager.RunningScripts = {}

-- Safely Load JSON
function ScriptManager.Load()
    if isfile and readfile and isfile(ScriptManager.FileName) then
        local success, result = pcall(function()
            return HttpService:JSONDecode(readfile(ScriptManager.FileName))
        end)
        if success and type(result) == "table" then
            return result
        end
    end
    return {}
end

-- Safely Save JSON
function ScriptManager.Save(data)
    if writefile then
        pcall(function()
            writefile(ScriptManager.FileName, HttpService:JSONEncode(data))
        end)
    end
end

-- Crash-Safe Debounced Executor
function ScriptManager.Execute(code, scriptName, Fluent)
    if not code or code == "" then
        if Fluent then
            Fluent:Notify({ Title = "Error", Content = "No script code provided!", Duration = 3 })
        end
        return
    end

    if ScriptManager.RunningScripts[scriptName] then
        if Fluent then
            Fluent:Notify({ Title = "Warning", Content = scriptName .. " is already executing!", Duration = 3 })
        end
        return
    end

    ScriptManager.RunningScripts[scriptName] = true

    if Fluent then
        Fluent:Notify({ Title = "Executing", Content = "Running " .. scriptName .. "...", Duration = 2 })
    end

    task.spawn(function()
        local success, result = pcall(function()
            local targetCode = code
            if code:sub(1, 4) == "http" then
                targetCode = game:HttpGet(code)
            end
            local loadedFunc, loadErr = loadstring(targetCode)
            if not loadedFunc then error(loadErr) end
            return loadedFunc()
        end)

        ScriptManager.RunningScripts[scriptName] = nil

        if not success and Fluent then
            Fluent:Notify({ Title = "Execution Error", Content = tostring(result), Duration = 5 })
        end
    end)
end

-- Complete UI Builder with Self-Cleaning Yes/No Confirm Popup
function ScriptManager.BuildUI(Tab, Fluent)
    local SavedScripts = ScriptManager.Load()
    local InputName = ""
    local InputUrl = ""
    local SelectedScript = ""

    Tab:AddSection("Script Saver & Executor")

    Tab:AddInput("ScriptNameInput", {
        Title = "Script Name",
        Default = "",
        Placeholder = "e.g., Teleport Hub",
        Callback = function(Value) InputName = Value end
    })

    Tab:AddInput("ScriptUrlInput", {
        Title = "Loadstring URL / Raw Code",
        Default = "",
        Placeholder = "https://raw.githubusercontent.com/...",
        Callback = function(Value) InputUrl = Value end
    })

    local ScriptDropdown

    local function GetScriptNames()
        local names = {}
        for name, _ in pairs(SavedScripts) do
            table.insert(names, name)
        end
        if #names == 0 then table.insert(names, "None") end
        return names
    end

    -- Save Script Handler
    Tab:AddButton({
        Title = "Save Script Entry",
        Icon = "save",
        Callback = function()
            if InputName:gsub("%s+", "") == "" or InputUrl:gsub("%s+", "") == "" then
                Fluent:Notify({ Title = "Warning", Content = "Provide both Name and URL/Code.", Duration = 3 })
                return
            end

            SavedScripts[InputName] = InputUrl
            ScriptManager.Save(SavedScripts)
            
            if ScriptDropdown then
                ScriptDropdown:SetValues(GetScriptNames())
            end

            Fluent:Notify({ Title = "Saved", Content = "'" .. InputName .. "' saved successfully!", Duration = 3 })
        end
    })

    Tab:AddSection("Saved Scripts Control")

    ScriptDropdown = Tab:AddDropdown("SavedScriptsDropdown", {
        Title = "Select Saved Script",
        Values = GetScriptNames(),
        Multi = false,
        Default = 1,
        Callback = function(Value)
            if Value ~= "None" then
                SelectedScript = Value
            else
                SelectedScript = ""
            end
        end
    })

    -- Run Selected Script
    Tab:AddButton({
        Title = "Run Selected Script",
        Icon = "play",
        Callback = function()
            if SelectedScript == "" or not SavedScripts[SelectedScript] then
                Fluent:Notify({ Title = "Error", Content = "Please select a valid script first!", Duration = 3 })
                return
            end
            ScriptManager.Execute(SavedScripts[SelectedScript], SelectedScript, Fluent)
        end
    })

    -- Popup Confirmation Mechanics
    local PopupElements = {}

    local function ClearPopup()
        for _, elem in ipairs(PopupElements) do
            if type(elem) == "table" and elem.Destroy then
                pcall(function() elem:Destroy() end)
            end
        end
        table.clear(PopupElements)
    end

    Tab:AddButton({
        Title = "Delete Selected Script",
        Icon = "trash-2",
        Callback = function()
            if SelectedScript == "" or not SavedScripts[SelectedScript] then
                Fluent:Notify({ Title = "Warning", Content = "No script selected to delete.", Duration = 3 })
                return
            end

            -- Clear any pre-existing popups first
            ClearPopup()

            Fluent:Notify({ Title = "Confirm", Content = "Are you sure you want to delete '" .. SelectedScript .. "'?", Duration = 4 })

            -- Temporary "YES" Button
            local yesBtn = Tab:AddButton({
                Title = "✅ YES, Delete: " .. SelectedScript,
                Callback = function()
                    SavedScripts[SelectedScript] = nil
                    ScriptManager.Save(SavedScripts)
                    
                    Fluent:Notify({ Title = "Deleted", Content = "'" .. SelectedScript .. "' was removed.", Duration = 3 })

                    SelectedScript = ""
                    ScriptDropdown:SetValues(GetScriptNames())
                    ClearPopup() -- Self Destructs
                end
            })
            table.insert(PopupElements, yesBtn)

            -- Temporary "NO" Button
            local noBtn = Tab:AddButton({
                Title = "❌ NO, Discard Action",
                Callback = function()
                    Fluent:Notify({ Title = "Cancelled", Content = "Deletion discarded.", Duration = 2 })
                    ClearPopup() -- Self Destructs
                end
            })
            table.insert(PopupElements, noBtn)
        end
    })
end

return ScriptManager
