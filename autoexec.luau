-- Project Real Autoexec: BSS Hopper
-- Автоматический запуск BSS Hopper и отправка Heartbeat в Watchdog

local Players = game:GetService("Players")
local HttpService = game:GetService("HttpService")

local localPlayer = Players.LocalPlayer or Players.PlayerAdded:Wait()
local myName = localPlayer.Name
local saveFileName = "rejoin_" .. myName .. ".json"

-- 1. Фоновое обновление статуса и отправка Heartbeat в Watchdog
task.spawn(function()
    while true do
        task.wait(5)
        pcall(function()
            if game.JobId and #game.JobId > 0 then
                if writefile then
                    writefile(saveFileName, HttpService:JSONEncode({
                        jobId = game.JobId,
                        placeId = game.PlaceId,
                        time = os.time(),
                        account = myName
                    }))
                end

                local req = (syn and syn.request) or (http and http.request) or http_request or (fluxus and fluxus.request) or request
                if req then
                    req({
                        Url = "http://127.0.0.1:18888/heartbeat",
                        Method = "POST",
                        Headers = { ["Content-Type"] = "application/json" },
                        Body = HttpService:JSONEncode({
                            account = myName,
                            placeId = game.PlaceId,
                            jobId = game.JobId
                        })
                    })
                end
            end
        end)
    end
end)

-- 2. Безопасный запуск BSS Hopper
task.spawn(function()
    if not game:IsLoaded() then
        game.Loaded:Wait()
    end
    task.wait(3)
    local url = "https://raw.githubusercontent.com/vladddd3311-code/Newbsshopper/main/main.lua?t=" .. tostring(os.time())
    local s, code = pcall(function() return game:HttpGet(url) end)
    if s and code and #code > 0 then
        local fn, err = loadstring(code)
        if fn then
            fn()
        else
            warn("[BSS AutoExec] Compile Error: ", tostring(err))
        end
    else
        warn("[BSS AutoExec] HttpGet failed: ", tostring(code))
    end
end)
