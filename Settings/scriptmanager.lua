local HttpService = game:GetService("HttpService")
local ScriptManager = {}

ScriptManager.FileName = "saved_scripts.json"

-- Load scripts safely from JSON
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

-- Save scripts safely to JSON
function ScriptManager.Save(data)
    if writefile then
        pcall(function()
            writefile(ScriptManager.FileName, HttpService:JSONEncode(data))
        end)
    end
end

-- Safe execution using task.spawn & pcall (Prevents game freezes/crashes)
function ScriptManager.Execute(code, scriptName, Fluent)
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
            -- If user pasted an HTTP link, download raw text first
            if code:sub(1, 4) == "http" then
                targetCode = game:HttpGet(code)
            end
            local loadedFunc, loadErr = loadstring(targetCode)
            if not loadedFunc then error(loadErr) end
            return loadedFunc()
        end)

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
