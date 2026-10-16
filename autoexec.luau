-- Project Real Autoexec: BSS Hopper
-- Ожидание полной загрузки игры и 5 секунд перед инжектом
task.spawn(function()
    if not game:IsLoaded() then
        game.Loaded:Wait()
    end
    task.wait(5)
    local url = "https://raw.githubusercontent.com/vladddd3311-code/Newbsshopper/main/main.lua?t=" .. tostring(os.time())
    local s, code = pcall(function() return game:HttpGet(url) end)
    if s and code then
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
