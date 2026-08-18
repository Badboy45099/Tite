local HttpService = game:GetService("HttpService")
local ScriptManager = {}

ScriptManager.FileName = "saved_scripts.json"
ScriptManager.RunningScripts = {}

-- Load saved scripts safely
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

-- Save scripts safely
function ScriptManager.Save(data)
    if writefile then
        pcall(function()
            writefile(ScriptManager.FileName, HttpService:JSONEncode(data))
        end)
    end
end

-- Safe execution with debounce protection (Prevents multi-execution crash)
function ScriptManager.Execute(code, scriptName, Fluent)
    if ScriptManager.RunningScripts[scriptName] then
        if Fluent then
            Fluent:Notify({
                Title = "Already Running",
                Content = scriptName .. " is already executing!",
                Duration = 3
            })
        end
        return
    end

    ScriptManager.RunningScripts[scriptName] = true

    if Fluent then
        Fluent:Notify({
            Title = "Executing",
            Content = "Running " .. scriptName .. "...",
            Duration = 2
        })
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
            Fluent:Notify({
                Title = "Execution Error",
                Content = tostring(result),
                Duration = 5
            })
        end
    end)
end

return ScriptManager
