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

-- UI Builder with Interactive Window Dialog Buttons
function ScriptManager.BuildUI(Tab, Fluent, Window)
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

    -- Save Button
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

    -- Interactive Dialog Delete Button
    Tab:AddButton({
    Title = "Delete Selected Script",
    Icon = "trash-2",
    Callback = function()
        if SelectedScript == "" or SelectedScript == "None" or not SavedScripts[SelectedScript] then
            Fluent:Notify({ Title = "Warning", Content = "No script selected to delete.", Duration = 3 })
            return
        end

        local scriptToDelete = SelectedScript

        -- Opens Interactive Dialog Window with YES and NO Buttons
        Window:Dialog({
            Title = "Confirm Deletion",
            Content = "Are you sure you want to delete '" .. scriptToDelete .. "'?",
            Buttons = {
                {
                    Title = "Yes, Delete",
                    Callback = function()
                        -- 1. Remove from local memory and save file
                        SavedScripts[scriptToDelete] = nil
                        ScriptManager.Save(SavedScripts)

                        -- 2. Clear selected variable state
                        SelectedScript = ""

                        -- 3. Update Dropdown choices and force set active selection
                        local updatedNames = GetScriptNames()
                        ScriptDropdown:SetValues(updatedNames)
                        ScriptDropdown:SetValue(updatedNames[1] or "None")

                        Fluent:Notify({ Title = "Deleted", Content = "Script successfully removed.", Duration = 3 })
                    end
                },
                {
                    Title = "No, Discard",
                    Callback = function()
                        Fluent:Notify({ Title = "Cancelled", Content = "Deletion cancelled.", Duration = 2 })
                    end
                }
            }
        })
    end
})
end

return ScriptManager
