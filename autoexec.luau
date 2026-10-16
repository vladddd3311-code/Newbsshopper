-- Project Real Autoexec: BSS Hopper
-- Ожидание полной загрузки игры и 7 секунд перед инжектом
if not game:IsLoaded() then
    game.Loaded:Wait()
end
task.wait(7)

loadstring(game:HttpGet("https://raw.githubusercontent.com/vladddd3311-code/Newbsshopper/main/main.lua?t=" .. tostring(os.time())))()
