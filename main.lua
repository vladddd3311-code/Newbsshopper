--[[
═══════════════════════════════════════════════════════════════════════
  🐍 BSS HOPPER v1.3.43 Static 3s Rejoin & Connect Watchdog
═══════════════════════════════════════════════════════════════════════
  ЛКМ по змейке  → вкл / выкл
  ПКМ по змейке  → меню    |    F — меню    |    P — вкл/выкл
  Escape         → свернуть окно
  Настройки сохраняются в файл и переживают перезаход

  v1.3.18:
   • Перезапуск цикла фарма, если сбор токенов завершился, а росток ещё жив
   • Сброс старой точки маршрута при начале нового сбора
   • Ограничение патруля вокруг поля, если FlowerZones не найдены
v1.3.32:
   • Игнорирует Vicious вне Clover / Spider / Cactus / Mountain Top / Pepper
   • Не принимает цель, если поле нельзя уверенно определить
   • Сохраняет фильтр ложных моделей и временный noclip
v1.1:
   • Session Lock Bypass (ошибки 279 / 267 / disconnect)
   • Лутающий и Соло сами занимают улей и делают Honey
   • Сбор токенов с приоритетами встроен в оба режима
   • Ускорение x4 бега / x3 полёта
   • Автокопание Scooper/Shovel
   • Поиск свободного улья через HivePlatforms.PlayerRef и проверка назначения
   • Автоподлёт/поливалка/сбор токенов у спрута; активный бой с Vicious
═══════════════════════════════════════════════════════════════════════
]]

-- ══════════════════════════════════════════════════════════════════════
--  1. РАННИЙ СТОРОЖЕВОЙ ТАЙМЕР (WATCHDOG) ОТ ОШИБОК 279/267/DISCONNECT
-- ══════════════════════════════════════════════════════════════════════
local CoreGui = game:GetService("CoreGui")
local TeleportService = game:GetService("TeleportService")
local PlaceId = game.PlaceId > 0 and game.PlaceId or 1537690962

local Bypass = _G.ExtraHopBypass
if not Bypass then
    pcall(function()
        if isfile and isfile("session_bypass.lua") then
            Bypass = loadstring(readfile("session_bypass.lua"))()
        elseif isfile and isfile("Bss_hop/session_bypass.lua") then
            Bypass = loadstring(readfile("Bss_hop/session_bypass.lua"))()
        end
    end)
    if Bypass and Bypass.init then
        pcall(function() Bypass:init() end)
    end
    _G.ExtraHopBypass = Bypass
end

-- Внутренний bypass-слой: перехватываем ошибки телепорта до того,
-- как Roblox выкинет на экран "Disconnected".
local bypassActive = type(Bypass) == "table"

local function bypassNotify()
    if bypassActive and Bypass.Notify then
        pcall(Bypass.Notify, Bypass)
    end
end

local function bypassRecover(reason)
    if bypassActive and Bypass.Recover then
        pcall(Bypass.Recover, Bypass, reason)
    end
end

-- ══════════════════════════════════════════════════════════════════════
--  2. СТАНДАРТНЫЙ ЗАПУСК
-- ══════════════════════════════════════════════════════════════════════
local Players          = game:GetService("Players")
local HttpService      = game:GetService("HttpService")
local Workspace        = game:GetService("Workspace")
local TweenService     = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")

local player = Players.LocalPlayer

local STEP = 0
local function trace(msg)
    STEP += 1
    print(string.format("[ШАГ %02d] %s", STEP, msg))
end
trace("Скрипт стартовал")

_G.BSS_FATAL = nil
local function showFatal(msg)
    _G.BSS_FATAL = msg
    pcall(function()
        print("[ФАТАЛЬНО] " .. tostring(msg))
        local plr = game:GetService("Players").LocalPlayer
        local pg = plr:WaitForChild("PlayerGui")
        local old = pg:FindFirstChild("BssFatalGui")
        if old then old:Destroy() end
        local g = Instance.new("ScreenGui")
        g.Name = "BssFatalGui"; g.DisplayOrder = 9999999
        g.IgnoreGuiInset = true; g.Parent = pg
        local f = Instance.new("Frame")
        f.Size = UDim2.new(0, 560, 0, 150)
        f.Position = UDim2.new(0.5, -280, 0, 90)
        f.BackgroundColor3 = Color3.fromRGB(46, 18, 18)
        f.BorderSizePixel = 0; f.Active = true; f.Parent = g
        Instance.new("UICorner", f).CornerRadius = UDim.new(0, 12)
        local t = Instance.new("TextLabel", f)
        t.Size = UDim2.new(1, -24, 0, 24); t.Position = UDim2.new(0, 12, 0, 10)
        t.BackgroundTransparency = 1
        t.Text = "ОШИБКА ЗАПУСКА СКРИПТА"
        t.TextColor3 = Color3.fromRGB(255, 120, 120)
        t.Font = Enum.Font.GothamBold; t.TextSize = 14
        t.TextXAlignment = Enum.TextXAlignment.Left
        local d = Instance.new("TextLabel", f)
        d.Size = UDim2.new(1, -24, 1, -46); d.Position = UDim2.new(0, 12, 0, 38)
        d.BackgroundTransparency = 1; d.Text = tostring(msg)
        d.TextColor3 = Color3.fromRGB(230, 200, 200)
        d.Font = Enum.Font.Gotham; d.TextSize = 11
        d.TextWrapped = true; d.TextXAlignment = Enum.TextXAlignment.Left
        d.TextYAlignment = Enum.TextYAlignment.Top
    end)
end

-- ══════════════════════════════════════════════════════════════════════
--  КОНФИГУРАЦИЯ
-- ══════════════════════════════════════════════════════════════════════
local CONFIG = {
    MODE = "searcher",
    API_URL = "https://hopper-bss-production.up.railway.app",
    API_KEY = "REPLACE_WITH_YOUR_API_KEY",
    SELF_TAG = "searcher1",
    VICIOUS_CHANNEL_ID = "",
    VICIOUS_FIELD_FROM = 1, VICIOUS_FIELD_TO = 5,
    PUFFSHROOM_CHANNEL_ID = "1558633541577740318",
    CHECK_PUFFSHROOMS = true,
    PUFF_MIN_RARITY = "common",
    FIXED_LEVEL = "basic",
    MIN_RARITY = "basic",
    PLACE_ID = 1537690962,

    HOP_DELAY = 3, POLL_INTERVAL = 3, BROKEN_WAIT = 20,
    INITIAL_CHECK = 1, REPORT_DELAY = 2.5,
    CONNECT_TIMEOUT = 3, MAX_ATTEMPTS = 3, FAILED_TTL = 180,

    DEBUG_SPROUT = true, CHECK_VICIOUS = true, CHECK_SPROUTS = true,
    AUTO_START = true,

    WALK_SPEED_MULT = 5.625, FLY_SPEED = 100, JUMP_POWER = 60,

    BACKPACK_FILL_THRESHOLD = 0.95, HONEY_MAX_WAIT = 45,

    TOKEN_SCAN_INTERVAL = 0.14, TOKEN_PATROL_TIME = 20,
    FARM_REGION = "center", -- center / left / right
    ANTI_LAG = true,
    ENABLE_AUTO_SPRINKLER = true, SPRINKLER_COUNT = 3,

    SPRINKLER_KEYWORD = "sprinkler", DIG_TOOL_KEYWORD = "scooper",
    ENABLE_AUTO_DIG = true,

    EMPTY_SLOT_KEYWORD = "claim hive", MY_HIVE_KEYWORD = "make honey",
    CLAIM_TIMEOUT = 8, CLAIM_APPROACH = 6, CLAIM_PROMPT_WAIT = 6,

    -- Bypass
    ENABLE_BYPASS = true, BYPASS_RETRY = 5,

    PUFF_MIN_LEVEL_COMMON=0, PUFF_MIN_LEVEL_RARE=0,
    PUFF_MIN_LEVEL_EPIC=0, PUFF_MIN_LEVEL_LEGENDARY=0, PUFF_MIN_LEVEL_MYTHIC=0,
}

local SAVE_FILE = "bss_hopper_config.json"
local uiState = { snakePos = nil, winPos = nil }
local lastMode = "searcher"

local function packPosition(pos)
    if not pos then return nil end
    return { xScale=pos.X.Scale, xOffset=pos.X.Offset,
             yScale=pos.Y.Scale, yOffset=pos.Y.Offset }
end
local function unpackPosition(pos)
    if type(pos) ~= "table" then return nil end
    local xs, xo = tonumber(pos.xScale), tonumber(pos.xOffset)
    local ys, yo = tonumber(pos.yScale), tonumber(pos.yOffset)
    if not xs or not xo or not ys or not yo then return nil end
    return UDim2.new(xs, xo, ys, yo)
end

-- ══════════════════════════════════════════════════════════════════════
--  ЗАЩИТА ОТ ДУБЛЕЙ
-- ══════════════════════════════════════════════════════════════════════
local OLD = rawget(_G, "BSS_Hopper")
if OLD and type(OLD.Destroy) == "function" then pcall(OLD.Destroy) end

local MY_TOKEN = {}
_G.BSS_HOPPER_TOKEN = MY_TOKEN
local function alive() return rawget(_G, "BSS_HOPPER_TOKEN") == MY_TOKEN end

local myConns = {}
local function trackConn(conn)
    if conn then table.insert(myConns, conn) end
    return conn
end

-- Hold primary mouse button while the hopper is enabled. This uses the executor's
-- input bridge when available; tool:Activate() remains the fallback for harvesting.
local leftMouseHeld = false
local function setLeftMouseHeld(shouldHold)
    local vim
    pcall(function() vim = game:GetService("VirtualInputManager") end)
    local uis = game:GetService("UserInputService")
    local pos = Vector2.new(uis:GetMouseLocation().X, uis:GetMouseLocation().Y)
    if shouldHold and not leftMouseHeld then
        if vim then
            local ok = pcall(function() vim:SendMouseButtonEvent(pos.X, pos.Y, 0, true, game, 0) end)
            leftMouseHeld = ok
        end
        if not leftMouseHeld then
            local vu
            pcall(function() vu = game:GetService("VirtualUser") end)
            if vu then
                leftMouseHeld = pcall(function() vu:CaptureController(); vu:Button1Down(pos) end)
            end
        end
    elseif not shouldHold and leftMouseHeld then
        if vim then pcall(function() vim:SendMouseButtonEvent(pos.X, pos.Y, 0, false, game, 0) end) end
        local vu
        pcall(function() vu = game:GetService("VirtualUser") end)
        if vu then pcall(function() vu:Button1Up(pos) end) end
        leftMouseHeld = false
    end
end

local function stopEverything()
    pcall(function() setLeftMouseHeld(false) end)
    if type(Hopper) == "table" and Hopper.Mode then
        pcall(function() Hopper.Mode:Stop() end)
    end
    for _, c in ipairs(myConns) do pcall(function() c:Disconnect() end) end
    myConns = {}
    pcall(function() if gui then gui:Destroy() end end)
end

local function log(tag, msg)
    print(string.format("[BSS Hopper][%s][%.1f] %s", tostring(tag), os.clock(), tostring(msg)))
end

-- ══════════════════════════════════════════════════════════════════════
--  СОХРАНЕНИЕ
-- ══════════════════════════════════════════════════════════════════════
local HAS_FS = (type(writefile) == "function") and (type(readfile) == "function")
local PERSIST_ENV = _G
pcall(function() if type(getgenv) == "function" then PERSIST_ENV = getgenv() end end)

local SAVED_KEYS = {
    "MODE","API_URL","API_KEY","SELF_TAG","VICIOUS_CHANNEL_ID","VICIOUS_FIELD_FROM","VICIOUS_FIELD_TO","FIXED_LEVEL","MIN_RARITY",
    "PLACE_ID","HOP_DELAY","POLL_INTERVAL","BROKEN_WAIT","INITIAL_CHECK",
    "REPORT_DELAY","CONNECT_TIMEOUT","MAX_ATTEMPTS","FAILED_TTL",
    "DEBUG_SPROUT","AUTO_START","CHECK_VICIOUS","CHECK_SPROUTS","CHECK_PUFFSHROOMS",
    "PUFFSHROOM_CHANNEL_ID","PUFF_MIN_RARITY","PUFF_MIN_LEVEL_COMMON","PUFF_MIN_LEVEL_RARE",
    "PUFF_MIN_LEVEL_EPIC","PUFF_MIN_LEVEL_LEGENDARY","PUFF_MIN_LEVEL_MYTHIC",
    "WALK_SPEED_MULT","FLY_SPEED","JUMP_POWER","BACKPACK_FILL_THRESHOLD","HONEY_MAX_WAIT",
    "TOKEN_SCAN_INTERVAL","TOKEN_PATROL_TIME","FARM_REGION","ANTI_LAG","SPRINKLER_KEYWORD","DIG_TOOL_KEYWORD",
    "ENABLE_AUTO_SPRINKLER","SPRINKLER_COUNT",
    "ENABLE_AUTO_DIG","EMPTY_SLOT_KEYWORD","MY_HIVE_KEYWORD","CLAIM_TIMEOUT",
    "CLAIM_APPROACH","CLAIM_PROMPT_WAIT","ENABLE_BYPASS","BYPASS_RETRY",
}

local function applySavedData(data, source)
    if type(data) ~= "table" then return false end
    for _, key in ipairs(SAVED_KEYS) do
        if data[key] ~= nil then CONFIG[key] = data[key] end
    end
    local savedMode = data.LAST_ACTIVE_MODE
    local valid = { searcher=true, looter=true, solo=true }
    if not valid[savedMode] then savedMode = data.MODE end
    if valid[savedMode] then lastMode = savedMode; CONFIG.MODE = savedMode end
    uiState.snakePos = unpackPosition(data.snakePos) or uiState.snakePos
    uiState.winPos = unpackPosition(data.winPos) or uiState.winPos
    if data.winOpen ~= nil then uiState.winOpen = (data.winOpen ~= false) end
    log("CFG", "Настройки загружены: " .. tostring(source))
    return true
end

local function loadSaved()
    local envData
    pcall(function() envData = PERSIST_ENV.BSS_HOPPER_SAVED_CONFIG end)
    applySavedData(envData, "память executor")
    if not HAS_FS then return envData end
    local ok, content = pcall(readfile, SAVE_FILE)
    if not ok or not content or content == "" then return envData end
    local ok2, data = pcall(function() return HttpService:JSONDecode(content) end)
    if not ok2 or type(data) ~= "table" then return envData end
    applySavedData(data, "файл " .. SAVE_FILE)
    return data
end
loadSaved()

-- Оптимизация графики клиента. Не удаляет игровые объекты/токены и не меняет логику фарма.
local function applyAntiLag(enabled)
    CONFIG.ANTI_LAG = enabled == true
    pcall(function()
        local Lighting = game:GetService("Lighting")
        if CONFIG.ANTI_LAG then
            Lighting.GlobalShadows = false
            Lighting.FogEnd = 100000
            for _, effect in ipairs(Lighting:GetChildren()) do
                if effect:IsA("BloomEffect") or effect:IsA("BlurEffect")
                    or effect:IsA("ColorCorrectionEffect") or effect:IsA("DepthOfFieldEffect")
                    or effect:IsA("SunRaysEffect") then
                    effect.Enabled = false
                end
            end
            local terrain = Workspace:FindFirstChildOfClass("Terrain")
            if terrain then
                terrain.WaterWaveSize = 0
                terrain.WaterWaveSpeed = 0
                terrain.WaterReflectance = 0
                terrain.WaterTransparency = 1
            end
            pcall(function() settings().Rendering.QualityLevel = Enum.QualityLevel.Level01 end)
        else
            -- При выключении возвращаем базовую графику; Roblox может управлять качеством автоматически.
            Lighting.GlobalShadows = true
            pcall(function() settings().Rendering.QualityLevel = Enum.QualityLevel.Automatic end)
        end
    end)
end
if CONFIG.ANTI_LAG then applyAntiLag(true) end

local function saveNow()
    local data = {}
    for _, key in ipairs(SAVED_KEYS) do data[key] = CONFIG[key] end
    local valid = { searcher=true, looter=true, solo=true }
    data.MODE = valid[lastMode] and lastMode or (valid[CONFIG.MODE] and CONFIG.MODE or "searcher")
    data.LAST_ACTIVE_MODE = data.MODE
    data.snakePos = packPosition(uiState.snakePos)
    data.winPos = packPosition(uiState.winPos)
    data.winOpen = uiState.winOpen ~= false
    local cacheOk = pcall(function() PERSIST_ENV.BSS_HOPPER_SAVED_CONFIG = data end)
    if not HAS_FS then return cacheOk end
    local encoded, json = pcall(function() return HttpService:JSONEncode(data) end)
    if not encoded then return false end
    return pcall(writefile, SAVE_FILE, json)
end
local function flushSettings() saveNow() end

-- Периодически фиксируем конфигурацию на диск, чтобы переживала телепорт/перезаход.
task.spawn(function()
    while alive() do
        task.wait(15)
        if alive() then pcall(saveNow) end
    end
end)

-- ══════════════════════════════════════════════════════════════════════
--  ПОИСК СПРУТА / МИРА
-- ══════════════════════════════════════════════════════════════════════
local sproutFolders = {}
local freshSprout = nil
local isSprout

local function addFolder(path)
    local node = Workspace
    for piece in path:gmatch("[^%.]+") do
        node = node:FindFirstChild(piece)
        if not node then return false end
    end
    if node:IsA("Folder") or node:IsA("Model") then
        for _, existing in ipairs(sproutFolders) do
            if existing == node then return false end
        end
        table.insert(sproutFolders, node)
        pcall(function()
            trackConn(node.DescendantAdded:Connect(function(child)
                if alive() and isSprout(child) then freshSprout = child end
            end))
        end)
        return true
    end
    return false
end

isSprout = function(obj)
    if not obj then return false end
    local ok, name, parent, isPart, isModel, isFolder = pcall(function()
        return obj.Name, obj.Parent, obj:IsA("BasePart"), obj:IsA("Model"), obj:IsA("Folder")
    end)
    if not ok or type(name) ~= "string" or not parent then return false end
    if string.lower(name) ~= "sprout" then return false end
    if isPart then return true end
    if isModel or isFolder then
        local okParts, descendants = pcall(function() return obj:GetDescendants() end)
        if not okParts then return isModel end
        for _, d in ipairs(descendants) do
            if d:IsA("BasePart") then return true end
        end
        return false
    end
    return false
end

local function watchFolders()
    for _, p in ipairs({ "Particles.Folder2", "Happenings.Sprouts", "Sprouts" }) do
        addFolder(p)
    end
    for _, folder in ipairs(sproutFolders) do
        pcall(function()
            trackConn(folder.ChildAdded:Connect(function(child)
                if not alive() then return end
                if isSprout(child) then freshSprout = child end
            end))
        end)
    end
end
watchFolders()
task.spawn(function()
    for _ = 1, 30 do
        if not alive() then return end
        task.wait(2)
        if #sproutFolders < 3 then watchFolders() end
    end
end)

local function findSprout()
    if freshSprout then
        if freshSprout.Parent and isSprout(freshSprout) then return freshSprout end
        freshSprout = nil
    end
    for _, folder in ipairs(sproutFolders) do
        local ok, descendants = pcall(function() return folder:GetDescendants() end)
        if ok then
            for _, child in ipairs(descendants) do
                if isSprout(child) then return child end
            end
        end
        if isSprout(folder) then return folder end
    end
    return nil
end

local function isSproutAlive(sprout, anchorPos)
    if sprout and sprout.Parent then
        local ok, isDesc = pcall(function() return sprout:IsDescendantOf(Workspace) end)
        if ok and isDesc then return true end
    end
    if anchorPos then
        for _, folder in ipairs(sproutFolders) do
            if folder and folder.Parent then
                local ok, descendants = pcall(function() return folder:GetDescendants() end)
                if ok and descendants then
                    for _, child in ipairs(descendants) do
                        if isSprout(child) then
                            local p = worldPos(child)
                            if p and (p - anchorPos).Magnitude <= 65 then
                                return true
                            end
                        end
                    end
                end
            end
        end
    end
    return false
end

local function _rawWorldPos(obj)
    if obj:IsA("BasePart") then return obj.Position end
    if obj:IsA("Model") then return obj:GetPivot().Position end
    return nil
end

local function worldPos(obj)
    if not obj then return nil end
    local ok, p = pcall(_rawWorldPos, obj)
    if ok and p then return p end
    return nil
end

local RunService = game:GetService("RunService")

-- Flight noclip: temporarily disable collision on character body parts only.
-- Original CanCollide values are restored after each flight segment.
local flightStopRequested = false
local noclipSteppedConn = nil
local function setFlightNoclip(enabled)
    if enabled then
        if not noclipSteppedConn then
            noclipSteppedConn = RunService.Stepped:Connect(function()
                local character = player and player.Character
                if character then
                    for _, part in ipairs(character:GetDescendants()) do
                        if part:IsA("BasePart") and part.CanCollide then
                            pcall(function() part.CanCollide = false end)
                        end
                    end
                end
            end)
        end
    else
        if noclipSteppedConn then
            pcall(function() noclipSteppedConn:Disconnect() end)
            noclipSteppedConn = nil
        end
        local character = player and player.Character
        if character then
            for _, part in ipairs(character:GetDescendants()) do
                if part:IsA("BasePart") then
                    local name = part.Name
                    -- Restore collision for torso, head, etc. so character doesn't fall through the floor!
                    if name == "UpperTorso" or name == "LowerTorso" or name == "Torso" or name == "Head" or name == "HumanoidRootPart" then
                        pcall(function() part.CanCollide = true end)
                    end
                end
            end
            local hum = character:FindFirstChildOfClass("Humanoid")
            if hum then
                pcall(function()
                    hum:ChangeState(Enum.HumanoidStateType.Landed)
                    hum:ChangeState(Enum.HumanoidStateType.Running)
                end)
            end
        end
    end
end

local function stopFlightNow()
    flightStopRequested = true
    pcall(function() setFlightNoclip(false) end)
    local character = player and player.Character
    local root = character and character:FindFirstChild("HumanoidRootPart")
    local hum = character and character:FindFirstChildOfClass("Humanoid")
    if root then
        pcall(function() root.AssemblyLinearVelocity = Vector3.zero end)
        pcall(function() root.AssemblyAngularVelocity = Vector3.zero end)
    end
    if hum then pcall(function() hum:Move(Vector3.zero, false) end) end
end

-- Raycast down to find the exact top surface of the field
local function getGroundPos(pos)
    if not pos then return pos end
    local ground = pos + Vector3.new(0, 3.2, 0)
    local ok, hit = pcall(function()
        local rayParams = RaycastParams.new()
        rayParams.FilterType = RaycastFilterType.Exclude
        local filterList = {}
        if player and player.Character then table.insert(filterList, player.Character) end
        local happens = Workspace:FindFirstChild("Happenings")
        if happens then table.insert(filterList, happens) end
        rayParams.FilterDescendantsInstances = filterList
        local origin = Vector3.new(pos.X, pos.Y + 45, pos.Z)
        return Workspace:Raycast(origin, Vector3.new(0, -110, 0), rayParams)
    end)
    if ok and hit and hit.Position then
        ground = hit.Position + Vector3.new(0, 3.2, 0)
    end
    return ground
end

-- Плавный покадровый полёт через стены: без проваливания под текстуры
local function moveRootToPosition(root, destination, maxDuration)
    if not root or not root.Parent or typeof(destination) ~= "Vector3" then return false end
    flightStopRequested = false
    setFlightNoclip(true)
    local startPos = root.Position
    local offset = destination - startPos
    local distance = offset.Magnitude
    if distance < 2.5 then
        setFlightNoclip(false)
        pcall(function()
            root.AssemblyLinearVelocity = Vector3.zero
            root.AssemblyAngularVelocity = Vector3.zero
        end)
        return true
    end

    local speed = 100 -- Статичная скорость полета: 100 studs/s
    local duration = math.clamp(distance / speed, 0.25, maxDuration or 10)
    local direction = offset.Unit
    local targetCFrame = CFrame.new(destination, destination + direction)
    local started = os.clock()

    while alive() and not flightStopRequested and root.Parent do
        local elapsed = os.clock() - started
        local alpha = math.clamp(elapsed / duration, 0, 1)
        local pos = startPos:Lerp(destination, alpha)
        local look = (destination - pos)
        local cf = CFrame.new(pos, pos + (look.Magnitude > 0.05 and look.Unit or direction))
        local ok = pcall(function()
            root.CFrame = cf
            root.AssemblyLinearVelocity = Vector3.zero
            root.AssemblyAngularVelocity = Vector3.zero
        end)
        if not ok then
            setFlightNoclip(false)
            return false
        end
        if alpha >= 1 then break end
        RunService.Heartbeat:Wait()
    end

    if not flightStopRequested and root.Parent then
        pcall(function()
            root.CFrame = targetCFrame
            root.AssemblyLinearVelocity = Vector3.zero
            root.AssemblyAngularVelocity = Vector3.zero
        end)
    end
    setFlightNoclip(false)
    pcall(function()
        root.AssemblyLinearVelocity = Vector3.zero
        root.AssemblyAngularVelocity = Vector3.zero
    end)
    return not flightStopRequested and root.Parent ~= nil and (root.Position - destination).Magnitude < 18
end

local function moveToSprout(sprout)
    if not sprout then return false end
    local targetPos = worldPos(sprout)
    if not targetPos then return false end
    local root = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
    if not root then return false end
    local safeLanding = getGroundPos(targetPos)
    local ok = moveRootToPosition(root, safeLanding, 8)
    return ok or ((root.Position - safeLanding).Magnitude < 25)
end

local function getFieldForPos(pos, maxExtra)
    if not pos then return nil end
    local zones = Workspace:FindFirstChild("FlowerZones")
    if not zones then return nil end
    maxExtra = maxExtra or 18
    local ok, children = pcall(function() return zones:GetChildren() end)
    if not ok or not children then return nil end
    for _, zone in ipairs(children) do
        if zone:IsA("BasePart") then
            local lp = zone.CFrame:PointToObjectSpace(pos)
            local half = zone.Size * 0.5
            if math.abs(lp.X) <= half.X + maxExtra
                and math.abs(lp.Z) <= half.Z + maxExtra
                and math.abs(lp.Y) <= 80 then
                return zone.Name, zone
            end
        end
    end
    return nil
end

local function detectField(sprout)
    local pos = worldPos(sprout)
    if not pos then return nil end
    local fName = getFieldForPos(pos, 25)
    if fName then return fName end
    local zones = Workspace:FindFirstChild("FlowerZones")
    if not zones then return nil end
    local okC, children = pcall(function() return zones:GetChildren() end)
    if not okC then return nil end
    local bestName, bestDist = nil, math.huge
    for _, zone in ipairs(children) do
        local zpos = worldPos(zone)
        if zpos then
            local d = (zpos - pos).Magnitude
            if d < bestDist then bestDist = d; bestName = zone.Name end
        end
    end
    return bestName
end

-- ══════════════════════════════════════════════════════════════════════
--  СКОРОСТЬ
-- ══════════════════════════════════════════════════════════════════════
local STATIC_SPEED = 90
local function applyWalkSpeed()
    local char = player.Character
    local hum = char and char:FindFirstChildOfClass("Humanoid")
    if hum then
        hum.WalkSpeed = STATIC_SPEED
        hum.JumpPower = tonumber(CONFIG.JUMP_POWER) or 60
        hum.UseJumpPower = true
    end
end

task.spawn(function()
    applyWalkSpeed()
    trackConn(player.CharacterAdded:Connect(function()
        task.wait(0.3)
        for _ = 1, 12 do
            if not alive() then return end
            applyWalkSpeed(); task.wait(0.4)
        end
    end))
    -- Фиксируем скорость статично на 90 каждый кадр
    while alive() do
        RunService.Heartbeat:Wait()
        local hum = player.Character and player.Character:FindFirstChildOfClass("Humanoid")
        if hum and hum.Health > 0 then
            if math.abs(hum.WalkSpeed - STATIC_SPEED) > 0.05 then hum.WalkSpeed = STATIC_SPEED end
        end
    end
end)

-- ══════════════════════════════════════════════════════════════════════
--  PUFFSHROOMS
-- ══════════════════════════════════════════════════════════════════════
local PUFF_RARITY_PRIORITY = { common=1, rare=2, epic=3, legendary=4, mythic=5 }
local puffReported = {}

local function puffTextOf(root)
    local chunks = { tostring(root.Name or "") }
    local function addAttrs(obj)
        local ok, attrs = pcall(function() return obj:GetAttributes() end)
        if ok and type(attrs) == "table" then
            for k, v in pairs(attrs) do
                local key = string.lower(tostring(k))
                if string.find(key,"rarity",1,true) or string.find(key,"level",1,true)
                    or string.find(key,"type",1,true) or string.find(key,"puff",1,true) then
                    table.insert(chunks, tostring(k) .. " " .. tostring(v))
                end
            end
        end
    end
    addAttrs(root)
    local ok, descendants = pcall(function() return root:GetDescendants() end)
    if ok then
        for _, d in ipairs(descendants) do
            if #chunks > 180 then break end
            local n = string.lower(tostring(d.Name or ""))
            if string.find(n,"puff",1,true) or string.find(n,"rarity",1,true)
                or string.find(n,"level",1,true) then table.insert(chunks, tostring(d.Name)) end
            addAttrs(d)
            if d:IsA("TextLabel") or d:IsA("TextButton") or d:IsA("TextBox") then
                pcall(function() table.insert(chunks, d.Text) end)
            end
        end
    end
    return table.concat(chunks, " | ")
end

local function isPuffshroomRoot(obj)
    local name = string.lower(tostring(obj and obj.Name or ""))
    if string.find(name,"puffshroom",1,true) or string.find(name,"puff shroom",1,true) then return true end
    if name ~= "sprout" then return false end
    local ok, descendants = pcall(function() return obj:GetDescendants() end)
    if not ok then return false end
    for _, d in ipairs(descendants) do
        local n = string.lower(tostring(d.Name or ""))
        if string.find(n,"puffshroom",1,true) or string.find(n,"puff shroom",1,true) then return true end
        if d:IsA("TextLabel") or d:IsA("TextButton") or d:IsA("TextBox") then
            local v = string.lower(tostring(d.Text or ""))
            if string.find(v,"puffshroom",1,true) or string.find(v,"puff shroom",1,true) then return true end
        end
    end
    return false
end

local function parsePuffshroom(root)
    local text = string.lower(puffTextOf(root))
    local rootName = string.lower(tostring(root and root.Name or ""))
    if not string.find(text,"puff",1,true)
        and not string.find(rootName,"puffshroom",1,true)
        and not string.find(rootName,"puff shroom",1,true)
        and rootName ~= "sprout" then return nil end
    local rarity
    for _, r in ipairs({"mythic","legendary","epic","rare","common"}) do
        if string.find(text, r, 1, true) then rarity = r; break end
    end
    local level
    for _, pattern in ipairs({"level%s*[:=]?%s*(%d+)","lvl%s*[:=]?%s*(%d+)","puffshroomlevel%s*[:=]?%s*(%d+)"}) do
        local v = string.match(text, pattern)
        if v then level = tonumber(v); break end
    end
    if not level then
        pcall(function()
            for _, key in ipairs({"Level","Lvl","PuffshroomLevel"}) do
                local v = root:GetAttribute(key)
                if tonumber(v) then level = tonumber(v); break end
            end
        end)
    end
    if (not level or level < 1 or level > 30) and rootName == "sprout" then
        rarity = "common"; level = 1
    end
    if not level or level < 1 or level > 30 then level = 1 end
    rarity = rarity or "common"
    return rarity, math.floor(level)
end

local function findPuffshroomTimer(root)
    local ok, descendants = pcall(function() return root:GetDescendants() end)
    if ok then
        for _, obj in ipairs(descendants) do
            if obj:IsA("TextLabel") or obj:IsA("TextButton") or obj:IsA("TextBox") then
                local v = tostring(obj.Text or "")
                local m, s = string.match(v, "(%d+):(%d%d)")
                if m and s and tonumber(s) < 60 then
                    return tostring(tonumber(m)) .. ":" .. tostring(s)
                end
            end
        end
    end
    return nil
end

local function findPuffshrooms()
    local ok, descendants = pcall(function() return Workspace:GetDescendants() end)
    if not ok then return {} end
    local candidates, results, seen = {}, {}, {}
    for _, obj in ipairs(descendants) do
        if isPuffshroomRoot(obj) then
            if obj:IsA("Model") then table.insert(candidates, 1, obj)
            else table.insert(candidates, obj) end
        end
    end
    for _, root in ipairs(candidates) do
        local ancestor, nested = root.Parent, false
        while ancestor and ancestor ~= Workspace do
            if isPuffshroomRoot(ancestor) then nested = true; break end
            ancestor = ancestor.Parent
        end
        if not nested and not seen[root] then
            local rarity, level = parsePuffshroom(root)
            local timer = findPuffshroomTimer(root)
            if rarity and level and timer then
                seen[root] = true
                table.insert(results, { root=root, rarity=rarity, level=level, timer=timer })
            end
        end
    end
    return results
end

local function findEligiblePuffshrooms()
    local results = {}
    local minR = PUFF_RARITY_PRIORITY[CONFIG.PUFF_MIN_RARITY] or 1
    for _, entry in ipairs(findPuffshrooms()) do
        local lk = "PUFF_MIN_LEVEL_" .. string.upper(entry.rarity)
        local minL = math.clamp(tonumber(CONFIG[lk]) or 0, 0, 30)
        if (PUFF_RARITY_PRIORITY[entry.rarity] or 0) >= minR and entry.level >= minL then
            table.insert(results, entry)
        end
    end
    return results
end

local function findPuffshroom()
    local ok, entries = pcall(findEligiblePuffshrooms)
    if not ok then return nil end
    if #entries > 0 then return entries[1].root, entries[1].rarity, entries[1].level end
    return nil
end

-- ══════════════════════════════════════════════════════════════════════
--  VICIOUS BEE (ШИП + РОУГ/ДИКИЙ ВИЦИУС, БЕЗ АТАКИ ПЧЕЛ ИГРОКОВ)
-- ══════════════════════════════════════════════════════════════════════
local VICIOUS_FIELD_ORDER = {
    ["clover field"] = 1, ["spider field"] = 2, ["cactus field"] = 3,
    ["mountain top field"] = 4, ["pepper patch"] = 5,
}

local function isPlayerBee(obj)
    if not obj then return false end
    local ok, res = pcall(function()
        -- 1. Descendant of any player's Character
        for _, plr in ipairs(game:GetService("Players"):GetPlayers()) do
            if plr.Character and obj:IsDescendantOf(plr.Character) then return true end
        end
        -- 2. Descendant of Workspace.Bees
        local beesFolder = Workspace:FindFirstChild("Bees")
        if beesFolder and obj:IsDescendantOf(beesFolder) then return true end
        -- 3. Ancestors check
        local cur = obj
        while cur and cur ~= Workspace do
            local n = string.lower(cur.Name)
            if n == "bees" or n == "characters" or n == "hiveplatforms" or n == "hives" then
                return true
            end
            cur = cur.Parent
        end
        -- 4. Attributes / child values
        if obj:FindFirstChild("Owner") or obj:FindFirstChild("Player") or obj:FindFirstChild("Bot") then
            return true
        end
        if obj:GetAttribute("Owner") or obj:GetAttribute("Player") then
            return true
        end
        return false
    end)
    return ok and res
end

local function isViciousFieldAllowed(obj)
    local pos = worldPos(obj)
    if not pos then return false end
    local field = getFieldForPos(pos, 25)
    if not field then
        local dField = detectField(obj)
        if dField then
            local zones = Workspace:FindFirstChild("FlowerZones")
            local zPart = zones and zones:FindFirstChild(dField)
            if zPart and zPart:IsA("BasePart") then
                if (zPart.Position - pos).Magnitude <= 85 then
                    field = dField
                end
            end
        end
    end
    if type(field) ~= "string" or field == "" then return false end
    local normalized = string.lower(field):gsub("%s+", " "):gsub("^%s+", ""):gsub("%s+$", "")
    local idx = VICIOUS_FIELD_ORDER[normalized]
    if not idx then return false end
    local first = math.clamp(math.floor(tonumber(CONFIG.VICIOUS_FIELD_FROM) or 1), 1, 5)
    local last = math.clamp(math.floor(tonumber(CONFIG.VICIOUS_FIELD_TO) or 5), 1, 5)
    if first > last then first, last = last, first end
    return idx >= first and idx <= last, normalized
end

local freshVicious = nil

local function isViciousPart(obj)
    if not obj or isPlayerBee(obj) then return false end
    local ok, name = pcall(function() return obj.Name end)
    return ok and type(name) == "string"
        and string.find(string.lower(name), "vicious", 1, true) ~= nil
end

local function getViciousTargetRoot(obj)
    if not obj or isPlayerBee(obj) then return nil end
    local current = obj
    local bestModel = nil
    while current and current ~= Workspace do
        if current:IsA("Model") and not isPlayerBee(current) then
            local n = string.lower(tostring(current.Name or ""))
            if string.find(n, "vicious", 1, true) then
                bestModel = current
            end
        end
        current = current.Parent
    end
    if bestModel then return bestModel end
    if obj:IsA("BasePart") and string.find(string.lower(tostring(obj.Name)), "vicious", 1, true) then
        return obj
    end
    local parentPart = obj:FindFirstAncestorWhichIsA("BasePart")
    if parentPart and not isPlayerBee(parentPart) and string.find(string.lower(tostring(parentPart.Name)), "vicious", 1, true) then
        return parentPart
    end
    return nil
end

-- Поиск шипа (Spike) дикого Вициуса строго в разрешенных полях
local function findViciousSpikeInAllowedFields()
    local searchRoots = {}
    local p = Workspace:FindFirstChild("Particles")
    if p then table.insert(searchRoots, p) end
    local m = Workspace:FindFirstChild("Monsters")
    if m then table.insert(searchRoots, m) end
    table.insert(searchRoots, Workspace)

    for _, root in ipairs(searchRoots) do
        local ok, children = pcall(function()
            if root == Workspace then
                return root:GetChildren()
            else
                return root:GetDescendants()
            end
        end)
        if ok and children then
            for _, obj in ipairs(children) do
                if not isPlayerBee(obj) then
                    local name = string.lower(tostring(obj.Name or ""))
                    local isSpike = string.find(name, "spike", 1, true)
                        or string.find(name, "stinger", 1, true)
                        or string.find(name, "thorn", 1, true)
                    if isSpike then
                        local pos = worldPos(obj)
                        if pos then
                            local allowed, fieldName = isViciousFieldAllowed(obj)
                            if allowed then
                                return obj, pos, fieldName
                            end
                        end
                    end
                end
            end
        end
    end
    return nil
end

local function findVicious()
    -- 1. СТРОГАЯ ПРОВЕРКА: летим на Вициуса ТОЛЬКО если на нужном поле есть реальный шип!
    -- Это на 100% исключает атаку пчёл других игроков.
    local spikeObj, spikePos, fieldName = findViciousSpikeInAllowedFields()
    if not spikeObj then
        freshVicious = nil
        return nil
    end

    -- 2. Если шип есть, проверяем, не вылезла ли уже сама дикая пчела (модель монстра)
    local monstersFolder = Workspace:FindFirstChild("Monsters")
    local candidates = {}
    if monstersFolder then
        local okM, mDesc = pcall(function() return monstersFolder:GetDescendants() end)
        if okM and mDesc then
            for _, obj in ipairs(mDesc) do
                table.insert(candidates, obj)
            end
        end
    end
    local okW, wChildren = pcall(function() return Workspace:GetChildren() end)
    if okW and wChildren then
        for _, obj in ipairs(wChildren) do
            if obj:IsA("Model") and not isPlayerBee(obj) then
                table.insert(candidates, obj)
            end
        end
    end

    for _, cand in ipairs(candidates) do
        if not isPlayerBee(cand) then
            local n = string.lower(tostring(cand.Name or ""))
            if string.find(n, "vicious", 1, true) then
                local root = getViciousTargetRoot(cand) or cand
                if root and root.Parent and isViciousFieldAllowed(root) then
                    freshVicious = root
                    return root
                end
            end
        end
    end

    -- 3. Если пчела ещё под землёй — летим прямо на шип (касание шипа активирует её появление)
    freshVicious = spikeObj
    return spikeObj
end

task.spawn(function()
    for _ = 1, 60 do
        if not alive() then return end
        local particles = Workspace:FindFirstChild("Particles")
        if particles then
            local function onAdded(obj)
                if not alive() or isPlayerBee(obj) then return end
                local name = string.lower(tostring(obj.Name or ""))
                if string.find(name, "spike", 1, true) or string.find(name, "vicious", 1, true) then
                    freshVicious = obj
                end
            end
            local function onRemoving(obj)
                if freshVicious == obj then freshVicious = nil end
            end
            trackConn(particles.ChildAdded:Connect(onAdded))
            trackConn(particles.DescendantAdded:Connect(onAdded))
            trackConn(particles.ChildRemoved:Connect(onRemoving))
            trackConn(particles.DescendantRemoving:Connect(onRemoving))
            findVicious(); return
        end
        task.wait(1)
    end
end)

local function viciousDefeatedMessageVisible()
    local needles = { "vicious bee has been defeated", "vicious bee defeated", "defeated vicious bee" }
    local pgui = player:FindFirstChildOfClass("PlayerGui")
    if not pgui then return false end
    local ok, descendants = pcall(function() return pgui:GetDescendants() end)
    if not ok then return false end
    for _, obj in ipairs(descendants) do
        if obj:IsA("TextLabel") and obj.Visible then
            local txt = string.lower(tostring(obj.Text or ""))
            for _, needle in ipairs(needles) do
                if string.find(txt, needle, 1, true) then return true end
            end
        end
    end
    return false
end

local function fightVicious(vicious)
    if not vicious or not vicious.Parent then return false end
    vicious = getViciousTargetRoot(vicious) or vicious
    if not vicious or not vicious.Parent then return false end
    local started = os.clock()
    setFlightNoclip(true)
    log("Vicious", "Шип/Вициус подтверждён; полёт сквозь стены на скорости 50-150")
    local hoverHeight = math.clamp(tonumber(CONFIG.VICIOUS_HOVER_HEIGHT) or 6, 3, 9)
    local lastDistance = math.huge
    local lastProgressAt = os.clock()
    local smoothedTarget = nil
    local lastFacingAt = 0

    while alive() and not flightStopRequested and vicious.Parent and os.clock() - started < 900 do
        if viciousDefeatedMessageVisible() then
            setFlightNoclip(false)
            return true
        end

        -- Если атаковали шип и появилась сама пчела — переключаемся на пчелу
        if vicious:IsA("BasePart") or not string.find(string.lower(tostring(vicious.Name or "")), "bee", 1, true) then
            local currentTarget = findVicious()
            if currentTarget and currentTarget ~= vicious and currentTarget.Parent then
                vicious = currentTarget
            end
        end

        local targetPos = worldPos(vicious)
        if not targetPos then
            local ok, p = pcall(function()
                if vicious:IsA("Attachment") then return vicious.WorldPosition end
                local part = vicious:FindFirstAncestorWhichIsA("BasePart")
                if part then return part.Position end
                local model = vicious:FindFirstAncestorWhichIsA("Model")
                if model then return model:GetPivot().Position end
                return nil
            end)
            if ok then targetPos = p end
        end
        if not targetPos then task.wait(0.1); continue end

        local character = player.Character
        local hum = character and character:FindFirstChildOfClass("Humanoid")
        local root = character and character:FindFirstChild("HumanoidRootPart")
        if not root or not hum or hum.Health <= 0 then
            task.wait(0.25)
            continue
        end

        local dt = RunService.Heartbeat:Wait()
        dt = math.clamp(dt, 1/240, 1/20)
        if not smoothedTarget then smoothedTarget = targetPos
        else
            local blend = 1 - math.exp(-dt * 14)
            smoothedTarget = smoothedTarget:Lerp(targetPos, blend)
        end

        local goal = smoothedTarget + Vector3.new(0, hoverHeight, 0)
        local delta = goal - root.Position
        local distance = delta.Magnitude
        local speed = 100 -- Статичная скорость полета: 100 studs/s

        local desiredVelocity = Vector3.zero
        if distance > 1.8 then
            local desiredSpeed = math.min(speed, math.max(25, distance * 3.0))
            desiredVelocity = delta.Unit * desiredSpeed
        end
        local currentVelocity = root.AssemblyLinearVelocity
        local response = 1 - math.exp(-dt * 8)
        local nextVelocity = currentVelocity:Lerp(desiredVelocity, response)
        pcall(function()
            hum:ChangeState(Enum.HumanoidStateType.Freefall)
            local gravityCompensation = Vector3.new(0, Workspace.Gravity * dt, 0)
            root.AssemblyLinearVelocity = nextVelocity + gravityCompensation
            root.AssemblyAngularVelocity = root.AssemblyAngularVelocity:Lerp(Vector3.zero, response)
            if os.clock() - lastFacingAt > 0.35 then
                lastFacingAt = os.clock()
                local flatDelta = Vector3.new(delta.X, 0, delta.Z)
                if flatDelta.Magnitude > 1 then
                    hum:Move(flatDelta.Unit, false)
                else
                    hum:Move(Vector3.zero, false)
                end
            end
        end)

        if distance < lastDistance - 0.5 then
            lastDistance = distance
            lastProgressAt = os.clock()
        elseif os.clock() - lastProgressAt > 4 and distance > 25 then
            pcall(function() root.AssemblyLinearVelocity = delta.Unit * math.min(speed, 95) + Vector3.new(0, Workspace.Gravity * dt, 0) end)
            lastProgressAt = os.clock()
            lastDistance = distance
        end
    end
    setFlightNoclip(false)
    return viciousDefeatedMessageVisible() or not vicious.Parent
end

local function detectViciousKind(obj)
    if string.find(string.lower(obj.Name or ""), "rogue", 1, true) then return "rogue" end
    return "wild"
end

local function getServerList()
    local ok, res = pcall(function()
        return game:HttpGet("https://games.roblox.com/v1/games/" ..
            tostring(CONFIG.PLACE_ID) .. "/servers/Public?sortOrder=Asc&limit=100")
    end)
    if not ok then return nil end
    local ok2, data = pcall(function() return HttpService:JSONDecode(res) end)
    if not ok2 or not data or not data.data then return nil end
    return data.data
end

-- ══════════════════════════════════════════════════════════════════════
--  ТЕЛЕПОРТЫ + BYPASS
-- ══════════════════════════════════════════════════════════════════════
local failedServers = {}
local attemptCounter = 0
local lastTeleportAt = 0
local lastAttemptId = 0

local function rememberFailure(jobId)
    if jobId then failedServers[jobId] = os.clock() end
    attemptCounter += 1
end
local function clearFailures() failedServers = {}; attemptCounter = 0 end
local function isFailed(jobId) return jobId ~= nil and failedServers[jobId] ~= nil end
local function pruneFailures()
    local now = os.clock()
    local ttl = tonumber(CONFIG.FAILED_TTL) or 90
    for id, t in pairs(failedServers) do
        if now - t > ttl then failedServers[id] = nil end
    end
end

local function getCandidateServers()
    pruneFailures()
    local servers = getServerList()
    if not servers then return nil end
    local out = {}
    for _, s in ipairs(servers) do
        if s.id ~= game.JobId and not isFailed(s.id)
            and s.playing < s.maxPlayers and s.playing > 0 then
            table.insert(out, { id = s.id, ping = s.ping or 999 })
        end
    end
    if #out == 0 then return out end
    table.sort(out, function(a, b) return a.ping < b.ping end)
    local limit = math.max(1, math.floor(#out / 2))
    local best = {}
    for i = 1, limit do table.insert(best, out[i].id) end
    return best
end

local pendingTarget, pendingAt, rejoinTries = nil, 0, 0
local function resetRejoinTries() if rejoinTries > 0 then rejoinTries = 0 end end
local function markTeleport(j) pendingTarget = j; pendingAt = os.clock(); resetRejoinTries() end
local function clearTeleport() pendingTarget = nil; pendingAt = 0 end

local function hopTo(jobId, placeId)
    if not jobId or isFailed(jobId) then return false end
    lastAttemptId += 1
    lastTeleportAt = os.clock()
    markTeleport(jobId)
    flushSettings()
    if CONFIG.ENABLE_BYPASS then bypassNotify() end
    local ok = pcall(function()
        TeleportService:TeleportToPlaceInstance(placeId or CONFIG.PLACE_ID, jobId, player)
    end)
    if not ok then
        rememberFailure(jobId)
        if CONFIG.ENABLE_BYPASS then bypassRecover("teleport_fail") end
        return false
    end
    return true
end

function hopRandom()
    local candidates = getCandidateServers()
    if candidates and #candidates > 0 then
        local target = candidates[math.random(1, #candidates)]
        if hopTo(target) then return end
    end
    if attemptCounter >= (tonumber(CONFIG.MAX_ATTEMPTS) or 3) then clearFailures() end
    lastAttemptId += 1
    lastTeleportAt = os.clock()
    markTeleport(nil)
    flushSettings()
    if CONFIG.ENABLE_BYPASS then bypassNotify() end
    pcall(function() TeleportService:Teleport(CONFIG.PLACE_ID, player) end)
end

task.spawn(function()
    while true do
        if not alive() then return end
        task.wait(0.5)
        if pendingAt > 0 then
            local timeout = 3 -- Таймаут перезахода/подключения: статично 3 секунды
            if os.clock() - pendingAt >= timeout then
                local target = pendingTarget
                clearTeleport()
                if target then rememberFailure(target) end
                if CONFIG.ENABLE_BYPASS then bypassRecover("connect_timeout") end
                hopRandom()
            end
        end
    end
end)

local function rejoinSame()
    local servers = getServerList()
    if servers then
        pruneFailures()
        for _, s in ipairs(servers) do
            if s.playing < s.maxPlayers and not isFailed(s.id) then
                hopTo(s.id); return
            end
        end
    end
    pcall(function() TeleportService:Teleport(CONFIG.PLACE_ID, player) end)
end

local RETRYABLE_TELEPORT_CODES = { [2]=true, [3]=true, [279]=true, [267]=true }
local MAX_REJOIN_TRIES = 5
local function rejoinRetry(code)
    rejoinTries += 1
    local attempt = rejoinTries
    task.wait(3) -- Таймаут перезахода: статично 3 секунды
    if CONFIG.ENABLE_BYPASS then bypassRecover("code_" .. tostring(code)) end
    if attempt >= MAX_REJOIN_TRIES then
        rejoinTries = 0; clearTeleport(); hopRandom(); return
    end
    clearTeleport(); rejoinSame()
end

local teleportLock = false
local function handleTeleportFailure(reason)
    if teleportLock then return end
    teleportLock = true
    clearTeleport()
    task.wait(3) -- Таймаут перезахода: статично 3 секунды
    if CONFIG.ENABLE_BYPASS then bypassRecover(tostring(reason)) end
    if attemptCounter >= (tonumber(CONFIG.MAX_ATTEMPTS) or 3) then clearFailures() end
    rejoinSame()
    teleportLock = false
end

-- Автоматический перезаход при дисконнекте (ErrorPrompt) ровно через 3 секунды
task.spawn(function()
    pcall(function()
        local robloxPromptGui = CoreGui:WaitForChild("RobloxPromptGui", 5)
        if robloxPromptGui then
            local promptOverlay = robloxPromptGui:WaitForChild("promptOverlay", 5)
            if promptOverlay then
                promptOverlay.ChildAdded:Connect(function(child)
                    if child.Name == "ErrorPrompt" then
                        log("Watchdog", "Обнаружен экран ошибки/дисконнекта. Перезаход через 3 секунды...")
                        task.wait(3)
                        clearTeleport()
                        rejoinSame()
                    end
                end)
                local existing = promptOverlay:FindFirstChild("ErrorPrompt")
                if existing then
                    log("Watchdog", "Обнаружен экран ошибки. Перезаход через 3 секунды...")
                    task.wait(3)
                    clearTeleport()
                    rejoinSame()
                end
            end
        end
    end)
end)

local function safeConnect(obj, signal, fn, name)
    local ok = pcall(function() trackConn(obj[signal]:Connect(fn)) end)
    if not ok then log("TP", "Не удалось подписаться: " .. name) end
end

safeConnect(TeleportService, "TeleportInitFailed", function(plr, result, msg)
    if plr ~= player then return end
    local code = tonumber(result)
    log("TP", "TeleportInitFailed: " .. tostring(result) .. " (" .. tostring(msg) .. ")")
    if code and RETRYABLE_TELEPORT_CODES[code] then
        task.spawn(rejoinRetry, code); return
    end
    rememberFailure(nil)
    task.spawn(handleTeleportFailure, "TeleportInitFailed")
end, "TeleportInitFailed")

safeConnect(player, "OnTeleport", function(state)
    if state == Enum.TeleportState.Failed then
        rememberFailure(nil)
        task.spawn(handleTeleportFailure, "OnTeleport Failed")
    end
end, "OnTeleport")

safeConnect(game, "Close", function()
    flushSettings(); markTeleport(nil)
    if CONFIG.ENABLE_BYPASS then bypassNotify() end
    pcall(function() TeleportService:Teleport(CONFIG.PLACE_ID, player) end)
end, "game.Close")

-- ══════════════════════════════════════════════════════════════════════
--  РАЗНОВИДНОСТИ СПРУТОВ
-- ══════════════════════════════════════════════════════════════════════
local RARITY_PRIORITY = { legendary=6, epic=5, gummy=4, rare=3, moon=2, basic=1, common=0 }
local RARITY_LABEL = {
    gummy="🍬 Gummy", legendary="💠 Legendary", epic="🥇 Epic",
    rare="🥈 Rare", basic="🌱 Basic", moon="🌙 Moon", common="⚪ Common",
}

local function hueOf(color)
    local h, s, v = Color3.toHSV(color); return h or 0, s or 0, v or 0
end

local RARITY_WORDS = {
    { level="gummy",     words={"gummy"} },
    { level="legendary", words={"legendary"} },
    { level="epic",      words={"epic"} },
    { level="rare",      words={"uncommon","rare"} },
    { level="moon",      words={"moon","lunar"} },
    { level="basic",     words={"common","normal","basic"} },
}
local function matchWords(text)
    if not text or text == "" then return nil end
    local low = string.lower(text)
    for _, entry in ipairs(RARITY_WORDS) do
        for _, w in ipairs(entry.words) do
            if string.find(low, w, 1, true) then return entry.level end
        end
    end
    return nil
end

local function sproutSparklesRate(sprout)
    local bestRate = nil
    local ok, descendants = pcall(function() return sprout:GetDescendants() end)
    if ok then
        for _, d in ipairs(descendants) do
            if d:IsA("ParticleEmitter") and string.lower(tostring(d.Name)) == "sparkles" then
                local rate = tonumber(d.Rate)
                if rate and (bestRate == nil or rate > bestRate) then bestRate = rate end
            end
        end
    end
    return bestRate
end

local function sproutHasGlow(sprout)
    local function partGlows(obj)
        if obj:IsA("BasePart") and obj.Material == Enum.Material.Neon then return true end
        return false
    end
    if partGlows(sprout) then return true end
    local ok, descendants = pcall(function() return sprout:GetDescendants() end)
    if not ok then return false end
    for _, d in ipairs(descendants) do
        if partGlows(d) or d:IsA("PointLight") or d:IsA("SpotLight")
            or d:IsA("SurfaceLight") or d:IsA("Highlight") then return true end
    end
    return false
end

local function detectRarity(sprout)
    if not sprout then return nil, "no-object" end
    local ownName = string.lower(tostring(sprout.Name or ""))
    local own = matchWords(ownName)
    if own then return own, "own-name" end

    local okGui, descendants = pcall(function() return sprout:GetDescendants() end)
    if okGui then
        for _, d in ipairs(descendants) do
            if d:IsA("TextLabel") or d:IsA("TextButton") then
                local txt = string.lower(tostring(d.Text or ""))
                local found = matchWords(txt)
                if found and (string.find(txt,"sprout",1,true) or string.find(txt,"legendary",1,true)
                    or string.find(txt,"common",1,true) or string.find(txt,"rare",1,true)
                    or string.find(txt,"epic",1,true) or string.find(txt,"gummy",1,true)
                    or string.find(txt,"moon",1,true)) then return found, "gui-explicit" end
            end
        end
    end

    local okAttr, attrs = pcall(function() return sprout:GetAttributes() end)
    if okAttr then
        for k, v in pairs(attrs) do
            local key = string.lower(tostring(k))
            if key=="rarity" or key=="sprouttype" or key=="sproutrarity" then
                local found = matchWords(tostring(v))
                if found then return found, "attribute:"..key end
            end
        end
    end

    local parts = {}
    if sprout:IsA("BasePart") then table.insert(parts, sprout) end
    if okGui then
        for _, d in ipairs(descendants) do
            if d:IsA("BasePart") then table.insert(parts, d) end
        end
    end

    local rate = sproutSparklesRate(sprout)
    local hasGlow = sproutHasGlow(sprout)

    for _, part in ipairs(parts) do
        local h = hueOf(part.Color); local deg = h * 360
        if part.Material == Enum.Material.Neon and deg >= 190 and deg <= 230 and rate then
            if rate <= 20 then return "moon", "sig:moon" end
            if rate >= 80 then return "legendary", "sig:legendary" end
        end
    end

    for _, part in ipairs(parts) do
        local h, sat, val = hueOf(part.Color); local deg = h * 360
        local r, g, b = part.Color.R, part.Color.G, part.Color.B
        local isGrey = math.abs(r-g)<0.06 and math.abs(g-b)<0.06
        if part.Material == Enum.Material.Glass and deg >= 285 and deg <= 350
            and sat >= 0.48 and val >= 0.35 then return "gummy", "sig:gummy" end
        if part.Material == Enum.Material.Glass and deg >= 28 and deg <= 62
            and sat > 0.40 and val >= 0.25 then return "epic", "sig:epic" end
        if isGrey and sat < 0.18 and val >= 0.55 and val <= 0.92
            and part.Material == Enum.Material.Glass then return "rare", "sig:rare" end
    end

    for _, part in ipairs(parts) do
        local _, _, val = hueOf(part.Color)
        local r, g, b = part.Color.R, part.Color.G, part.Color.B
        local knownCommon = math.abs(r-0.706)<=0.055 and math.abs(g-0.745)<=0.055 and math.abs(b-0.729)<=0.055
        local paleGreen = part.Material == Enum.Material.Plastic
            and g >= r and g >= b and (g-r) >= 0.015
            and (g-b) >= 0.005 and val >= 0.55 and val <= 0.90
        if part.Material == Enum.Material.Plastic and knownCommon and not hasGlow then return "basic", "sig:common-rgb" end
        if paleGreen and not hasGlow then return "basic", "sig:common-pale" end
    end

    return nil, "unconfirmed"
end

local function isRarityAtLeast(rarity, minimum)
    local got = rarity and RARITY_PRIORITY[rarity]
    local minValue = RARITY_PRIORITY[string.lower(tostring(minimum or "basic"))] or RARITY_PRIORITY.basic
    return got ~= nil and got >= minValue
end

local function isSproutEligible(sprout)
    local rarity, source = detectRarity(sprout)
    return isRarityAtLeast(rarity, CONFIG.MIN_RARITY), rarity, source
end

local function findLootableSprout()
    local best, bestPriority = nil, -1
    local function consider(obj)
        if not obj or not isSprout(obj) then return end
        local eligible, rarity = isSproutEligible(obj)
        local priority = rarity and RARITY_PRIORITY[rarity] or -1
        if eligible and priority > bestPriority then best, bestPriority = obj, priority end
    end
    if freshSprout and freshSprout.Parent then consider(freshSprout) end
    for _, folder in ipairs(sproutFolders) do
        if folder and folder.Parent then
            consider(folder)
            local ok, descendants = pcall(function() return folder:GetDescendants() end)
            if ok then
                for _, child in ipairs(descendants) do consider(child) end
            end
        end
    end
    return best
end

-- ══════════════════════════════════════════════════════════════════════
--  УЛЕЙ / HONEY / РЮКЗАК / ТОКЕНЫ
-- ══════════════════════════════════════════════════════════════════════

local function promptWorldPos(prompt)
    if not prompt then return nil end
    local parent = prompt.Parent
    if parent then
        local ok, pos = pcall(function()
            if parent:IsA("Attachment") then return parent.WorldPosition end
            if parent:IsA("BasePart") then return parent.Position end
            if parent:IsA("Model") then return parent:GetPivot().Position end
            local part = parent:FindFirstAncestorWhichIsA("BasePart")
            if part then return part.Position end
            local model = parent:FindFirstAncestorWhichIsA("Model")
            if model then return model:GetPivot().Position end
            return nil
        end)
        if ok and pos then return pos end
    end
    return worldPos(parent)
end

local function promptWorldPos(prompt)
    if not prompt or not prompt.Parent then return nil end
    local parent = prompt.Parent
    if parent:IsA("BasePart") then return parent.Position end
    if parent:IsA("Attachment") then return parent.WorldPosition end
    return worldPos(parent)
end

local function findPromptByKeyword(keyword)
    local needle = string.lower(tostring(keyword or ""))
    local results = {}
    local ok, descendants = pcall(function() return Workspace:GetDescendants() end)
    if not ok then return results end
    local words = {}
    for word in string.gmatch(needle, "%S+") do table.insert(words, word) end
    for _, obj in ipairs(descendants) do
        if obj:IsA("ProximityPrompt") then
            local parts = {
                tostring(obj.ActionText or ""), tostring(obj.ObjectText or ""), tostring(obj.Name or "")
            }
            local ancestor = obj.Parent
            for _ = 1, 4 do
                if not ancestor then break end
                table.insert(parts, tostring(ancestor.Name or ""))
                ancestor = ancestor.Parent
            end
            local haystack = string.lower(table.concat(parts, " "))
            local isClaimPrompt = string.find(haystack, "claim", 1, true)
                or string.find(haystack, "hive", 1, true)
                or string.find(haystack, "занять", 1, true)
                or string.find(haystack, "улей", 1, true)
                or string.find(haystack, "стойк", 1, true)
            local matched = isClaimPrompt or needle == "" or string.find(haystack, needle, 1, true) ~= nil
            if not matched and #words > 0 then
                matched = true
                for _, word in ipairs(words) do
                    if not string.find(haystack, word, 1, true) then matched = false; break end
                end
            end
            if matched then
                local slot = obj.Parent
                local pos = promptWorldPos(obj)
                if pos then table.insert(results, { prompt=obj, slot=slot, pos=pos }) end
            end
        end
    end
    return results
end

local function findYellowHivePads()
    local results = {}
    local ok, descendants = pcall(function() return Workspace:GetDescendants() end)
    if not ok then return results end
    for _, obj in ipairs(descendants) do
        if obj:IsA("BasePart")
            and (obj.Shape == Enum.PartType.Cylinder or obj.Shape == Enum.PartType.Ball) then
            local c = obj.Color
            local r, g, b = c.R, c.G, c.B
            if r > 0.85 and g > 0.75 and b < 0.5 and obj.Position.Y < 100 then
                table.insert(results, { part=obj, pos=obj.Position })
            end
        end
    end
    return results
end

local function getHivePlatformRecords()
    local records = {}
    local folder = Workspace:FindFirstChild("HivePlatforms")
    if not folder then return records end
    for _, model in ipairs(folder:GetChildren()) do
        if model:IsA("Model") then
            local hiveRef = model:FindFirstChild("Hive")
            local playerRef = model:FindFirstChild("PlayerRef")
            local platform = model:FindFirstChild("Platform") or model:FindFirstChildWhichIsA("BasePart")
            if playerRef and playerRef:IsA("ObjectValue") and platform and platform:IsA("BasePart") then
                table.insert(records, {
                    model=model, hiveRef=hiveRef, playerRef=playerRef,
                    platform=platform, pos=platform.Position,
                })
            end
        end
    end
    return records
end

local function findAssignedHiveSlot()
    local ok, records = pcall(getHivePlatformRecords)
    if ok and records then
        for _, slot in ipairs(records) do
            local val = slot.playerRef and slot.playerRef.Value
            if val == player or (typeof(val) == "Instance" and val == player) or tostring(val) == player.Name then
                return slot
            end
        end
    end
    return nil
end

local function slotIsFree(slot)
    return slot and slot.playerRef and slot.playerRef.Value == nil
end

local function claimHive()
    local root = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
    local hum = player.Character and player.Character:FindFirstChildOfClass("Humanoid")
    if not root or not hum or hum.Health <= 0 then return false end
    if findAssignedHiveSlot() then
        log("Улей", "Свой улей уже назначен")
        return true
    end

    local slots = getHivePlatformRecords()
    local freeSlots = {}
    for _, slot in ipairs(slots) do
        if slotIsFree(slot) then
            table.insert(freeSlots, slot)
        end
    end

    if #freeSlots == 0 then
        local hp = Workspace:FindFirstChild("HivePlatforms")
        if hp then
            for _, m in ipairs(hp:GetChildren()) do
                local pref = m:FindFirstChild("PlayerRef")
                local plat = m:FindFirstChild("Platform") or m:FindFirstChildWhichIsA("BasePart")
                if pref and pref:IsA("ObjectValue") and pref.Value == nil and plat then
                    table.insert(freeSlots, { model = m, playerRef = pref, platform = plat, pos = plat.Position })
                end
            end
        end
    end

    if #freeSlots == 0 then
        log("Улей", "Все ульи заняты на сервере")
        return false
    end

    table.sort(freeSlots, function(a, b)
        return (a.pos - root.Position).Magnitude < (b.pos - root.Position).Magnitude
    end)

    for _, slot in ipairs(freeSlots) do
        if not alive() then return false end
        if findAssignedHiveSlot() then return true end

        log("Улей", "Встаю на платформу улья: " .. tostring(slot.model.Name))
        local standPos = slot.pos + Vector3.new(0, 3.2, 0)

        -- Летим прямо на платформу
        moveRootToPosition(root, standPos, 4)
        task.wait(0.2)

        root = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
        hum = player.Character and player.Character:FindFirstChildOfClass("Humanoid")
        if not root or not hum or hum.Health <= 0 then return false end

        -- Отключаем ноклип, восстанавливаем коллизию и физически встаем на платформу
        setFlightNoclip(false)
        pcall(function()
            root.CFrame = CFrame.new(standPos)
            root.AssemblyLinearVelocity = Vector3.zero
            root.AssemblyAngularVelocity = Vector3.zero
            hum:ChangeState(Enum.HumanoidStateType.Landed)
            hum:ChangeState(Enum.HumanoidStateType.Running)
        end)
        task.wait(0.25)

        -- Ищем ProximityPrompt для захвата улья
        local prompt = nil
        -- А. Внутри модели слота
        for _, desc in ipairs(slot.model:GetDescendants()) do
            if desc:IsA("ProximityPrompt") then
                prompt = desc
                break
            end
        end
        -- Б. В радиусе 25 студов от платформы в Workspace
        if not prompt then
            local okD, allDesc = pcall(function() return Workspace:GetDescendants() end)
            if okD then
                local bestD = 25
                for _, desc in ipairs(allDesc) do
                    if desc:IsA("ProximityPrompt") then
                        local pPos = promptWorldPos(desc)
                        if pPos then
                            local d = (pPos - slot.pos).Magnitude
                            if d < bestD then
                                prompt = desc
                                bestD = d
                            end
                        end
                    end
                end
            end
        end

        log("Улей", prompt and "ProximityPrompt найден — активирую..." or "Активирую захват стойки всеми методами...")

        -- Пробуем захватить этот улей в течение 3.5 секунд
        local tryStart = os.clock()
        while alive() and os.clock() - tryStart < 3.5 do
            if findAssignedHiveSlot() then
                log("Улей", "Улей успешно занят!")
                return true
            end

            -- 1. ProximityPrompt методы
            if prompt and prompt.Parent then
                pcall(function()
                    prompt.Enabled = true
                    prompt.RequiresLineOfSight = false
                    prompt.MaxActivationDistance = 9999
                    prompt.HoldDuration = 0
                end)
                if type(fireproximityprompt) == "function" then
                    pcall(fireproximityprompt, prompt, 0, true)
                    pcall(fireproximityprompt, prompt, 1, true)
                    pcall(fireproximityprompt, prompt)
                end
                pcall(function()
                    prompt:InputHoldBegin()
                    task.wait(0.12)
                    prompt:InputHoldEnd()
                end)
            end

            -- 2. Нажатие клавиши 'E' через VirtualInputManager
            pcall(function()
                local vim = game:GetService("VirtualInputManager")
                if vim then
                    vim:SendKeyEvent(true, Enum.KeyCode.E, false, game)
                    task.wait(0.15)
                    vim:SendKeyEvent(false, Enum.KeyCode.E, false, game)
                end
            end)

            -- 3. VirtualUser клавиша 'E'
            pcall(function()
                local vu = game:GetService("VirtualUser")
                if vu then
                    vu:CaptureController()
                    vu:SetKeyDown("0x65")
                    task.wait(0.15)
                    vu:SetKeyUp("0x65")
                end
            end)

            -- 4. ClickDetector fallback
            if type(fireclickdetector) == "function" then
                for _, cd in ipairs(slot.model:GetDescendants()) do
                    if cd:IsA("ClickDetector") then
                        pcall(fireclickdetector, cd)
                    end
                end
            end

            -- 5. TouchInterest на платформе и всех частях модели
            if type(firetouchinterest) == "function" and root then
                for _, part in ipairs(slot.model:GetDescendants()) do
                    if part:IsA("BasePart") then
                        pcall(firetouchinterest, root, part, 0)
                        pcall(firetouchinterest, root, part, 1)
                    end
                end
            end

            -- 6. RemoteEvents в ReplicatedStorage
            pcall(function()
                local rep = game:GetService("ReplicatedStorage")
                local evFolder = rep:FindFirstChild("Events") or rep
                for _, ev in ipairs(evFolder:GetDescendants()) do
                    if ev:IsA("RemoteEvent") or ev:IsA("RemoteFunction") then
                        local n = string.lower(ev.Name)
                        if string.find(n, "claimhive", 1, true) 
                           or string.find(n, "playerhivecommand", 1, true)
                           or string.find(n, "claim", 1, true) then
                            if ev:IsA("RemoteEvent") then
                                pcall(function() ev:FireServer(slot.model) end)
                                pcall(function() ev:FireServer(slot.platform) end)
                            elseif ev:IsA("RemoteFunction") then
                                pcall(function() ev:InvokeServer(slot.model) end)
                                pcall(function() ev:InvokeServer(slot.platform) end)
                            end
                        end
                    end
                end
            end)

            task.wait(0.3)
        end

        if findAssignedHiveSlot() then
            log("Улей", "Улей успешно занят!")
            return true
        end
    end

    return findAssignedHiveSlot() ~= nil
end

local function findMyHive()
    local owned = findAssignedHiveSlot()
    if not owned then return nil end
    local prompts = findPromptByKeyword(CONFIG.MY_HIVE_KEYWORD or "make honey")
    local scoped = {}
    for _, entry in ipairs(prompts) do
        if entry.prompt:IsDescendantOf(owned.model) or (owned.hiveRef and owned.hiveRef.Value and entry.prompt:IsDescendantOf(owned.hiveRef.Value)) then
            table.insert(scoped, entry)
        end
    end
    if #scoped > 0 then return scoped[1] end
    return { pos=owned.pos, slot=owned, prompt=nil }
end

local function stripCommas(s) return (tostring(s):gsub(",", "")) end

local function getBackpackPollen()
    -- 1. Самый точный метод: CoreStats игрока в BSS (напрямую от сервера)
    local okCore, info = pcall(function()
        local cs = player:FindFirstChild("CoreStats")
        if cs then
            local pol = cs:FindFirstChild("Pollen")
            local cap = cs:FindFirstChild("Capacity")
            if pol and cap and tonumber(cap.Value) and cap.Value > 0 then
                local c = tonumber(pol.Value) or 0
                local m = tonumber(cap.Value)
                return { current = c, max = m, ratio = c / m }
            end
        end
        return nil
    end)
    if okCore and info then return info end

    -- 2. Второй метод: прямое чтение Pollen Meter (Meter2) в PlayerGui
    local pg = player:FindFirstChildOfClass("PlayerGui")
    if not pg then return nil end

    local sg = pg:FindFirstChild("ScreenGui")
    if sg then
        local meter2 = sg:FindFirstChild("Meter2") or sg:FindFirstChild("PollenMeter")
        if meter2 then
            for _, d in ipairs(meter2:GetDescendants()) do
                if d:IsA("TextLabel") then
                    local a, b = string.match(d.Text or "", "([%d,]+)%s*/%s*([%d,]+)")
                    if a and b then
                        local c = tonumber(stripCommas(a))
                        local m = tonumber(stripCommas(b))
                        if c and m and m > 0 then
                            return { current = c, max = m, ratio = c / m }
                        end
                    end
                end
            end
        end
    end

    -- 3. Fallback: поиск по всем TextLabel в PlayerGui с фильтром по Pollen/Meter2
    local best = nil
    local okDesc, descendants = pcall(function() return pg:GetDescendants() end)
    if okDesc and descendants then
        for _, d in ipairs(descendants) do
            if d:IsA("TextLabel") then
                local txt = tostring(d.Text or "")
                local a, b = string.match(txt, "([%d,]+)%s*/%s*([%d,]+)")
                if a and b then
                    local c = tonumber(stripCommas(a))
                    local m = tonumber(stripCommas(b))
                    if c and m and m > 0 then
                        local pName = string.lower(d.Name)
                        local parentName = d.Parent and string.lower(d.Parent.Name) or ""
                        local gparentName = d.Parent and d.Parent.Parent and string.lower(d.Parent.Parent.Name) or ""
                        local isPollen = string.find(pName, "pollen", 1, true) or string.find(pName, "meter2", 1, true)
                            or string.find(parentName, "pollen", 1, true) or string.find(parentName, "meter2", 1, true)
                            or string.find(gparentName, "pollen", 1, true) or string.find(gparentName, "meter2", 1, true)
                        if not isPollen and d.Parent then
                            for _, sib in ipairs(d.Parent:GetChildren()) do
                                if sib:IsA("TextLabel") and string.find(string.lower(sib.Text or ""), "pollen", 1, true) then
                                    isPollen = true
                                    break
                                end
                            end
                        end
                        if isPollen then
                            return { current = c, max = m, ratio = c / m }
                        end
                        if not best and m <= 100000000 then
                            best = { current = c, max = m, ratio = c / m }
                        end
                    end
                end
            end
        end
    end
    return best
end

local function isBackpackFull()
    local info = getBackpackPollen()
    if not info then return false end
    local threshold = tonumber(CONFIG.BACKPACK_FILL_THRESHOLD) or 0.95
    return info.current >= info.max or info.ratio >= threshold
end

local useSprinklerBuilder
local collectTokensFor

local function triggerMakeHoneyAction(prompt)
    if prompt and prompt.Parent then
        pcall(function()
            prompt.Enabled = true
            prompt.RequiresLineOfSight = false
            prompt.MaxActivationDistance = 9999
            prompt.HoldDuration = 0
        end)
        if type(fireproximityprompt) == "function" then
            pcall(fireproximityprompt, prompt, 0, true)
            pcall(fireproximityprompt, prompt, 1, true)
            pcall(fireproximityprompt, prompt)
        end
        pcall(function()
            prompt:InputHoldBegin()
            task.wait(0.12)
            prompt:InputHoldEnd()
        end)
    end

    -- Нажатие клавиши 'E' (Make Honey) через VirtualInputManager
    pcall(function()
        local vim = game:GetService("VirtualInputManager")
        if vim then
            vim:SendKeyEvent(true, Enum.KeyCode.E, false, game)
            task.wait(0.15)
            vim:SendKeyEvent(false, Enum.KeyCode.E, false, game)
        end
    end)

    -- VirtualUser 'E'
    pcall(function()
        local vu = game:GetService("VirtualUser")
        if vu then
            vu:CaptureController()
            vu:SetKeyDown("0x65")
            task.wait(0.15)
            vu:SetKeyUp("0x65")
        end
    end)

    -- RemoteEvent в ReplicatedStorage
    pcall(function()
        local rep = game:GetService("ReplicatedStorage")
        local ev = rep:FindFirstChild("Events")
        if ev then
            local cmd = ev:FindFirstChild("PlayerHiveCommand") or ev:FindFirstChild("MakeHoney")
            if cmd and cmd:IsA("RemoteEvent") then
                cmd:FireServer("MakeHoney")
            end
        end
    end)
end

local function makeHoney()
    local char = player.Character
    local root = char and char:FindFirstChild("HumanoidRootPart")
    local hum = char and char:FindFirstChildOfClass("Humanoid")
    if not root or not hum or hum.Health <= 0 then return false end

    -- Проверяем наличие своего улья
    if not hasOwnHive() then
        log("Honey", "Улей не назначен — занимаю свободный улей...")
        pcall(ensureHiveClaimed)
    end

    local hive = findMyHive()
    local slot = findAssignedHiveSlot()
    local hivePos = (hive and hive.pos) or (slot and slot.pos)
    if not hivePos then
        log("Honey", "Позиция своего улья не найдена")
        return false
    end

    log("Honey", "Рюкзак полон! Лечу к улью на разгрузку...")
    -- Подлетаем к платформе улья
    moveRootToPosition(root, hivePos + Vector3.new(0, 3.5, 0), 10)

    -- Отключаем ноклип и встаем ровно на платформу
    setFlightNoclip(false)
    pcall(function()
        root.CFrame = CFrame.new(hivePos + Vector3.new(0, 3.2, 0))
        root.AssemblyLinearVelocity = Vector3.zero
        root.AssemblyAngularVelocity = Vector3.zero
        hum:ChangeState(Enum.HumanoidStateType.Landed)
        hum:ChangeState(Enum.HumanoidStateType.Running)
    end)
    task.wait(0.3)

    -- Ищем Prompt "Make Honey"
    local prompt = (hive and hive.prompt)
    if not prompt then
        local near = findPromptNearPosition(CONFIG.MY_HIVE_KEYWORD or "make honey", hivePos, 30)
        if near then prompt = near.prompt end
    end
    if not prompt and slot and slot.model then
        for _, desc in ipairs(slot.model:GetDescendants()) do
            if desc:IsA("ProximityPrompt") then
                prompt = desc
                break
            end
        end
    end

    -- Нажимаем Make Honey
    log("Honey", "Активирую Make Honey (клавиша E)...")
    triggerMakeHoneyAction(prompt)

    -- Ждём ПОЛНОЙ разгрузки рюкзака (пыльца -> 0)
    local maxWait = tonumber(CONFIG.HONEY_MAX_WAIT) or 120
    local t0 = os.clock()
    local lastActionAt = 0

    while alive() and (os.clock() - t0 < maxWait) do
        -- Периодически удерживаем персонажа на платформе и обновляем активацию Make Honey
        if os.clock() - lastActionAt > 2.0 then
            lastActionAt = os.clock()
            pcall(function()
                root.CFrame = CFrame.new(hivePos + Vector3.new(0, 3.2, 0))
                root.AssemblyLinearVelocity = Vector3.zero
            end)
            if not prompt then
                local near = findPromptNearPosition(CONFIG.MY_HIVE_KEYWORD or "make honey", hivePos, 30)
                if near then prompt = near.prompt end
            end
            triggerMakeHoneyAction(prompt)
        end

        local info = getBackpackPollen()
        if info then
            -- Полная разгрузка: пыльцы 0 (или менее 0.5% от объема)
            if info.current <= 0 or info.ratio <= 0.005 then
                log("Honey", string.format("Рюкзак ПОЛНОСТЬЮ разгружен (0 / %d)! Возвращаюсь к фарму.", info.max))
                task.wait(0.5)
                return true
            end
        else
            -- Если индикатор стал недоступен через 15 сек после начала, считаем разгрузку успешной
            if os.clock() - t0 > 15 then
                log("Honey", "Индикатор пыльцы пуст, разгрузка завершена")
                return true
            end
        end

        task.wait(0.4)
    end

    log("Honey", "Разгрузка завершена по истечению времени")
    return true
end

local TOKEN_P1 = {
    "glitter", "glue", "extract", "star jelly", "magic bean", "bean",
    "royal jelly", "atomic treat", "star treat", "neonberry",
    "moon charm", "whirligig", "egg", "dice", "smoothie",
    "converter", "micro-converter", "oil", "enzymes", "tropical drink",
    "gumdrop", "gumdrops", "gingerbread", "snowflake", "festive",
    "box frog", "night bell"
}
local TOKEN_P2 = {
    "strawberry", "blueberry", "pineapple", "sunflower", "seed",
    "coconut", "bitterberry", "treat", "ticket", "ant pass", "pollen"
}

local function isHoneyToken(low)
    if string.find(low, "honey", 1, true) then return true end
    -- Все известные ID текстур медовых монет BSS
    if string.find(low, "1629547638", 1, true) or string.find(low, "2028607990", 1, true)
       or string.find(low, "1471850677", 1, true) or string.find(low, "1471849394", 1, true)
       or string.find(low, "1471844391", 1, true) or string.find(low, "1472135114", 1, true)
       or string.find(low, "honeytoken", 1, true) or string.find(low, "honeydrop", 1, true) then
        return true
    end
    return false
end

local TOKEN_NAME_CACHE = setmetatable({}, { __mode = "k" })
local TOKEN_PRIO_CACHE = setmetatable({}, { __mode = "k" })

local function tokenPriority(name)
    local low = string.lower(tostring(name or ""))
    -- Медовые токены: приоритет 99 (игнорируются от целенаправленного бега, собираются только наступая)
    if isHoneyToken(low) then return 99 end
    -- N1: Супер редкие предметы (Glue, Blue Extract, Glitter, Star Jelly, Magic Beans и т.д.)
    for _, w in ipairs(TOKEN_P1) do
        if string.find(low, w, 1, true) then return 1 end
    end
    -- N2: Фрукты, семена, билеты (Blueberry, Strawberry, Seeds, Treats, Tickets)
    for _, w in ipairs(TOKEN_P2) do
        if string.find(low, w, 1, true) then return 2 end
    end
    -- N3: Все остальные токены на поле (способности пчёл, бомбы, бусты, баффы)
    return 3
end

local function resolveTokenName(obj)
    if not obj then return "token" end
    local cached = TOKEN_NAME_CACHE[obj]
    if cached then return cached end

    local parts = {}
    local name = tostring(obj.Name or "")
    table.insert(parts, name)
    local okC, children = pcall(function() return obj:GetChildren() end)
    if okC and children then
        for _, child in ipairs(children) do
            if child:IsA("Decal") or child:IsA("Texture") then
                table.insert(parts, tostring(child.Name or ""))
                local tex = tostring(child.Texture or "")
                if tex ~= "" then table.insert(parts, tex) end
            end
        end
    end
    local okAttr, attrs = pcall(function() return obj:GetAttributes() end)
    if okAttr and attrs then
        for k, v in pairs(attrs) do
            table.insert(parts, tostring(k) .. " " .. tostring(v))
        end
    end
    local combined = string.lower(table.concat(parts, " "))

    local result = name ~= "" and name or "token"
    for _, w in ipairs(TOKEN_P1) do
        if string.find(combined, w, 1, true) then result = w; break end
    end
    if result == name or result == "token" then
        for _, w in ipairs(TOKEN_P2) do
            if string.find(combined, w, 1, true) then result = w; break end
        end
    end
    if isHoneyToken(combined) then result = "honey" end

    TOKEN_NAME_CACHE[obj] = result
    return result
end

local function getTokenPriorityForObj(obj)
    if not obj then return 3 end
    local cached = TOKEN_PRIO_CACHE[obj]
    if cached then return cached end
    local name = resolveTokenName(obj)
    local prio = tokenPriority(name)
    TOKEN_PRIO_CACHE[obj] = prio
    return prio
end

local TOKEN_FOLDERS = { "Collectibles", "Tokens", "Drops" }
local TOKEN_CACHE, TOKEN_CACHE_AT = {}, 0
local TOKEN_CACHE_TTL = 0.5
local function findToolByKeyword(keyword)
    local needle = string.lower(tostring(keyword or ""))
    local backpack = player:FindFirstChildOfClass("Backpack")
    if backpack then
        for _, tool in ipairs(backpack:GetChildren()) do
            if tool:IsA("Tool") and string.find(string.lower(tool.Name), needle, 1, true) then return tool end
        end
    end
    local char = player.Character
    if char then
        for _, tool in ipairs(char:GetChildren()) do
            if tool:IsA("Tool") and string.find(string.lower(tool.Name), needle, 1, true) then return tool end
        end
    end
    return nil
end

local function equipTool(tool)
    if not tool then return false end
    local char = player.Character
    local hum = char and char:FindFirstChildOfClass("Humanoid")
    if not hum then return false end
    pcall(function() hum:EquipTool(tool) end)
    return tool.Parent == char
end

local cachedHarvestTool = nil
local lastToolCheckAt = 0

local function ensureHarvestToolEquipped()
    local char = player.Character
    if not char then return nil end
    local hum = char:FindFirstChildOfClass("Humanoid")
    if not hum then return nil end

    local now = os.clock()
    if cachedHarvestTool and cachedHarvestTool.Parent == char and (now - lastToolCheckAt < 0.8) then
        return cachedHarvestTool
    end
    lastToolCheckAt = now

    -- 1. Если в руках осталась лейка/поливалка — СНИМАЕМ ЕЁ!
    for _, item in ipairs(char:GetChildren()) do
        if item:IsA("Tool") and string.find(string.lower(item.Name), "sprinkler", 1, true) then
            pcall(function() hum:UnequipTools() end)
            local bp = player:FindFirstChildOfClass("Backpack")
            if bp then pcall(function() item.Parent = bp end) end
            break
        end
    end

    -- 2. Если в руках уже палка/инструмент сбора — возвращаем её
    for _, item in ipairs(char:GetChildren()) do
        if item:IsA("Tool") and not string.find(string.lower(item.Name), "sprinkler", 1, true) then
            cachedHarvestTool = item
            return item
        end
    end

    -- 3. Если инструмент в рюкзаке — экипируем моментально без задержек
    local bp = player:FindFirstChildOfClass("Backpack")
    if bp then
        for _, item in ipairs(bp:GetChildren()) do
            if item:IsA("Tool") and not string.find(string.lower(item.Name), "sprinkler", 1, true) then
                pcall(function() hum:EquipTool(item) end)
                if item.Parent ~= char then pcall(function() item.Parent = char end) end
                cachedHarvestTool = item
                return item
            end
        end
    end
    return nil
end

local function findHarvestTool()
    return ensureHarvestToolEquipped()
end

local toolCollectRemote = nil
local lastRemoteCheckAt = 0
local function getToolCollectRemote()
    if toolCollectRemote and toolCollectRemote.Parent then return toolCollectRemote end
    local now = os.clock()
    if now - lastRemoteCheckAt < 1.0 then return nil end
    lastRemoteCheckAt = now
    local ok, ev = pcall(function() return game:GetService("ReplicatedStorage"):FindFirstChild("Events") end)
    if ok and ev then
        toolCollectRemote = ev:FindFirstChild("ToolCollect")
    end
    return toolCollectRemote
end

local lastSwingAt = 0
local function swingDigTool()
    local now = os.clock()
    if now - lastSwingAt < 0.15 then return end
    lastSwingAt = now

    local char = player.Character
    if not char then return end
    local tool = ensureHarvestToolEquipped()
    if tool then
        pcall(function() tool:Activate() end)
    end
    if type(mouse1click) == "function" then
        pcall(mouse1click)
    elseif type(mouse1press) == "function" and type(mouse1release) == "function" then
        pcall(function()
            mouse1press()
            mouse1release()
        end)
    end
    local ev = getToolCollectRemote()
    if ev then
        pcall(function() ev:FireServer() end)
    end
end

local TOKEN_CACHE, TOKEN_CACHE_AT = {}, 0
local collectedTokens = setmetatable({}, { __mode = "k" })
local function findFieldTokens(anchorZone, limitX, limitZ, fieldAnchor)
    local now = os.clock()
    if now - TOKEN_CACHE_AT < 0.08 then
        return TOKEN_CACHE
    end
    TOKEN_CACHE_AT = now

    local out = {}
    local zonePos = anchorZone and anchorZone.Position
    local maxRadiusSq = 55 * 55
    if anchorZone then
        local maxR = math.max(anchorZone.Size.X, anchorZone.Size.Z) * 0.5 + 2
        maxRadiusSq = maxR * maxR
    end

    for _, folderName in ipairs(TOKEN_FOLDERS) do
        local folder = Workspace:FindFirstChild(folderName)
        if folder then
            local ok, items = pcall(function() return folder:GetChildren() end)
            if ok and items then
                for _, obj in ipairs(items) do
                    if not collectedTokens[obj] then
                        local pos = worldPos(obj)
                        if pos then
                            local inField = false
                            if anchorZone and zonePos then
                                local dx = pos.X - zonePos.X
                                local dz = pos.Z - zonePos.Z
                                if (dx * dx + dz * dz) <= maxRadiusSq then
                                    local lp = anchorZone.CFrame:PointToObjectSpace(pos)
                                    if math.abs(lp.X) <= limitX and math.abs(lp.Z) <= limitZ then
                                        inField = true
                                    end
                                end
                            elseif fieldAnchor then
                                local dx = pos.X - fieldAnchor.X
                                local dz = pos.Z - fieldAnchor.Z
                                inField = (dx * dx + dz * dz) <= 1764
                            end

                            if inField then
                                local prio = getTokenPriorityForObj(obj)
                                if prio <= 3 then
                                    out[#out+1] = {
                                        obj = obj,
                                        pos = pos,
                                        priority = prio,
                                    }
                                end
                            end
                        end
                    end
                end
            end
        end
    end
    TOKEN_CACHE = out
    return out
end

local tokenCollectorBusy = false
local collectorTokenGen = 0
local patrolTarget = nil
local activeTokenObj = nil
local lastPatrolPickAt = 0

local function getActiveFlowerZone(anchorPos)
    local zones = Workspace:FindFirstChild("FlowerZones")
    if not zones then return nil end
    local pos = anchorPos or (player.Character and player.Character:FindFirstChild("HumanoidRootPart") and player.Character.HumanoidRootPart.Position)
    if not pos then return nil end
    local bestZone, bestDist = nil, math.huge
    for _, zone in ipairs(zones:GetChildren()) do
        if zone:IsA("BasePart") then
            local lp = zone.CFrame:PointToObjectSpace(pos)
            local half = zone.Size * 0.5
            if math.abs(lp.X) <= half.X + 25 and math.abs(lp.Z) <= half.Z + 25 then
                return zone
            end
            local d = (zone.Position - pos).Magnitude
            if d < bestDist then
                bestDist = d
                bestZone = zone
            end
        end
    end
    return bestZone
end

collectTokensFor = function(maxSeconds, stopFn, fieldAnchor)
    collectorTokenGen = collectorTokenGen + 1
    local myGen = collectorTokenGen
    tokenCollectorBusy = true

    local function runLoop()
        local started = os.clock()
        patrolTarget, activeTokenObj = nil, nil
        lastPatrolPickAt = 0

        -- Находим физическую зону текущего поля
        local anchorZone = getActiveFlowerZone(fieldAnchor)
        local limitX, limitZ = 40, 40
        local function refreshZoneLimits()
            if anchorZone then
                local half = anchorZone.Size * 0.5
                limitX = math.max(6, half.X - 5.0)
                limitZ = math.max(6, half.Z - 5.0)
            end
        end
        refreshZoneLimits()

        while alive() and os.clock() - started < maxSeconds do
            if collectorTokenGen ~= myGen then break end
            if stopFn and stopFn() then break end

            local char = player.Character
            local root = char and char:FindFirstChild("HumanoidRootPart")
            local humanoid = char and char:FindFirstChildOfClass("Humanoid")

            -- Персонаж умер: немедленный выход
            if not root or not humanoid or humanoid.Health <= 0 then
                patrolTarget, activeTokenObj = nil, nil
                break
            end

            if not anchorZone then
                anchorZone = getActiveFlowerZone(root.Position)
                refreshZoneLimits()
            end

            -- Автосвинг палкой (с лимитом вызовов)
            pcall(swingDigTool)

            local rootPos = root.Position
            -- Мгновенно исключаем только что взятый токен, не дожидаясь пока BSS его удалит
            if activeTokenObj then
                if not activeTokenObj.Parent or collectedTokens[activeTokenObj] then
                    activeTokenObj = nil
                else
                    local p = worldPos(activeTokenObj)
                    if p then
                        local dx = p.X - rootPos.X
                        local dz = p.Z - rootPos.Z
                        if (dx * dx + dz * dz) <= 18.0 then
                            collectedTokens[activeTokenObj] = true
                            activeTokenObj = nil
                        end
                    else
                        activeTokenObj = nil
                    end
                end
            end

            -- Поиск токенов СТРОГО внутри границ поля (токены за полем ПОЛНОСТЬЮ отсеяны в findFieldTokens)
            local tokens = findFieldTokens(anchorZone, limitX, limitZ, fieldAnchor)
            local best, bestKey = nil, math.huge
            for _, token in ipairs(tokens) do
                local tobj = token.obj
                if tobj and tobj.Parent and not collectedTokens[tobj] then
                    local dx = token.pos.X - rootPos.X
                    local dz = token.pos.Z - rootPos.Z
                    local distSq = dx * dx + dz * dz
                    if distSq <= 14.44 then
                        -- Персонаж уже коснулся токена: помечаем собранным, не ждем пока BSS его удалит!
                        collectedTokens[tobj] = true
                    else
                        local score = (token.priority == 1 and 0) or (token.priority == 2 and 100000) or 200000
                        local key = score + distSq
                        if key < bestKey then
                            best = token
                            bestKey = key
                        end
                    end
                end
            end

            -- Скорость бега: статично 90
            local targetSpeed = 90
            if math.abs(humanoid.WalkSpeed - targetSpeed) > 0.05 then
                humanoid.WalkSpeed = targetSpeed
            end

            if best then
                activeTokenObj = best.obj
                patrolTarget = Vector3.new(best.pos.X, root.Position.Y, best.pos.Z)
            else
                activeTokenObj = nil
                local needNewPatrol = not patrolTarget 
                    or (root.Position - patrolTarget).Magnitude < 3
                    or (os.clock() - lastPatrolPickAt > 0.8)

                if needNewPatrol then
                    lastPatrolPickAt = os.clock()
                    if anchorZone then
                        local half = anchorZone.Size * 0.5
                        local xSpan = (half.X - 8) * 0.60
                        local zSpan = (half.Z - 8) * 0.60
                        local localTarget = Vector3.new(
                            (math.random() * 2 - 1) * xSpan,
                            0,
                            (math.random() * 2 - 1) * zSpan
                        )
                        local worldPoint = anchorZone.CFrame:PointToWorldSpace(localTarget)
                        patrolTarget = Vector3.new(worldPoint.X, root.Position.Y, worldPoint.Z)
                    elseif fieldAnchor then
                        local angle = math.random() * math.pi * 2
                        local dist = math.random(5, 18)
                        patrolTarget = Vector3.new(fieldAnchor.X + math.cos(angle) * dist, root.Position.Y, fieldAnchor.Z + math.sin(angle) * dist)
                    else
                        patrolTarget = root.Position
                    end
                end
            end

            -- Ограничение цели СТРОГО в границы поля
            if anchorZone and patrolTarget then
                local lp = anchorZone.CFrame:PointToObjectSpace(patrolTarget)
                local safeX = math.clamp(lp.X, -limitX, limitX)
                local safeZ = math.clamp(lp.Z, -limitZ, limitZ)
                local safeWorld = anchorZone.CFrame:PointToWorldSpace(Vector3.new(safeX, lp.Y, safeZ))
                patrolTarget = Vector3.new(safeWorld.X, root.Position.Y, safeWorld.Z)
            end

            -- Бег строго через MoveTo (без конфликтующих вызовов Move, которые отменяли ходьбу)
            if patrolTarget then
                humanoid:MoveTo(patrolTarget)
            end

            RunService.Heartbeat:Wait()
        end
    end

    pcall(runLoop)
    if collectorTokenGen == myGen then
        tokenCollectorBusy = false
    end
end

useSprinklerBuilder = function(fieldAnchor)
    if not CONFIG.ENABLE_AUTO_SPRINKLER then return false end
    local count = math.clamp(math.floor(tonumber(CONFIG.SPRINKLER_COUNT) or 3), 1, 4)

    local char = player.Character
    local root = char and char:FindFirstChild("HumanoidRootPart")
    local hum = char and char:FindFirstChildOfClass("Humanoid")
    if not root or not hum or hum.Health <= 0 then return false end

    -- Поиск инструмента Sprinkler Builder
    local tool = findToolByKeyword(CONFIG.SPRINKLER_KEYWORD or "sprinkler")
    if not tool then
        local bp = player:FindFirstChildOfClass("Backpack")
        if bp then
            tool = bp:FindFirstChild("Sprinkler Builder") or bp:FindFirstChild("Sprinkler")
        end
        if not tool and char then
            tool = char:FindFirstChild("Sprinkler Builder") or char:FindFirstChild("Sprinkler")
        end
    end

    -- Находим зону текущего поля для точного позиционирования поливалок
    local anchorPos = fieldAnchor or root.Position
    local zone = getActiveFlowerZone(anchorPos)
    local center = zone and zone.Position or anchorPos
    local halfX = zone and (zone.Size.X * 0.5) or 32
    local halfZ = zone and (zone.Size.Z * 0.5) or 32

    -- Формируем целевые точки размещения поливалок по правилам:
    -- 1: по середине поля
    -- 2: слева и справа с достаточным расстоянием друг от друга
    -- 3: сверху 1, и 2 снизу слева и справа
    -- 4: в 4 углах поля, но не под самый корень (с безопасным отступом)
    local targetOffsets = {}
    if count == 1 then
        table.insert(targetOffsets, Vector3.new(0, 0, 0))
    elseif count == 2 then
        local spanX = math.clamp(halfX * 0.44, 12, 22)
        table.insert(targetOffsets, Vector3.new(-spanX, 0, 0))
        table.insert(targetOffsets, Vector3.new(spanX, 0, 0))
    elseif count == 3 then
        local spanX = math.clamp(halfX * 0.44, 12, 22)
        local spanZ = math.clamp(halfZ * 0.40, 10, 20)
        table.insert(targetOffsets, Vector3.new(0, 0, spanZ))
        table.insert(targetOffsets, Vector3.new(-spanX, 0, -spanZ * 0.75))
        table.insert(targetOffsets, Vector3.new(spanX, 0, -spanZ * 0.75))
    elseif count == 4 then
        local spanX = math.clamp(halfX * 0.52, 14, 25)
        local spanZ = math.clamp(halfZ * 0.52, 14, 25)
        table.insert(targetOffsets, Vector3.new(-spanX, 0, spanZ))
        table.insert(targetOffsets, Vector3.new(spanX, 0, spanZ))
        table.insert(targetOffsets, Vector3.new(-spanX, 0, -spanZ))
        table.insert(targetOffsets, Vector3.new(spanX, 0, -spanZ))
    end

    local placed = 0
    for i, offset in ipairs(targetOffsets) do
        if not alive() or not root.Parent then break end

        local worldTarget
        if zone then
            worldTarget = zone.CFrame:PointToWorldSpace(offset)
        else
            worldTarget = center + offset
        end
        local goal = Vector3.new(worldTarget.X, root.Position.Y, worldTarget.Z)

        pcall(function() hum:MoveTo(goal) end)
        local deadline = os.clock() + 0.45
        while alive() and os.clock() < deadline and (root.Position - goal).Magnitude > 3.2 do
            RunService.Heartbeat:Wait()
        end

        -- Экипировка Sprinkler Builder
        if tool and tool.Parent ~= char then
            equipTool(tool)
        end

        -- 1. Вызов серверного RemoteEvent размещения поливалки из инвентаря
        pcall(function()
            local rep = game:GetService("ReplicatedStorage")
            local ev = rep:FindFirstChild("Events")
            if ev then
                local act = ev:FindFirstChild("PlayerActivesCommand")
                if act and act:IsA("RemoteEvent") then
                    act:FireServer({ Name = "Sprinkler Builder" })
                end
            end
        end)

        -- 2. Активация инструмента в руках
        if tool and tool.Parent == char then
            pcall(function() tool:Activate() end)
        end

        -- 3. Клик мыши
        if type(mouse1click) == "function" then
            pcall(mouse1click)
        end

        task.wait(0.12)
        placed += 1
    end

    log("Инструмент", string.format("Sprinkler Builder: размещено %d/%d (режим: %d поливалки)", placed, count, count))

    -- Синхронное снятие лейки и немедленное вооружение палкой
    pcall(function() hum:UnequipTools() end)
    local bp = player:FindFirstChildOfClass("Backpack")
    if bp and tool and tool.Parent == char then
        pcall(function() tool.Parent = bp end)
    end
    task.wait(0.05)
    ensureHarvestToolEquipped()
    return placed > 0
end

local autoDigThread = nil
local function startAutoDig()
    if autoDigThread or not CONFIG.ENABLE_AUTO_DIG then return end
    autoDigThread = task.spawn(function()
        while alive() do
            local tool = findHarvestTool()
            if tool then
                if tool.Parent ~= player.Character then equipTool(tool) end
                pcall(function() tool:Activate() end)
            end
            task.wait(0.28)
        end
    end)
end
local function stopAutoDig()
    if autoDigThread then
        pcall(task.cancel, autoDigThread)
        autoDigThread = nil
    end
end

local function hasOwnHive()
    return findAssignedHiveSlot() ~= nil
end

local function ensureHiveClaimed()
    if hasOwnHive() then
        log("Улей", "Свой улей уже есть")
        return true
    end
    log("Улей", "Ищу свободный улей")
    return claimHive()
end

-- ══════════════════════════════════════════════════════════════════════
--  РЕЖИМ: 🔍 ИЩУЩИЙ
-- ══════════════════════════════════════════════════════════════════════
local Searcher = {}
Searcher.__index = Searcher
local Hopper

function Searcher.New()
    return setmetatable({
        thread = nil,
        stats = { serversChecked=0, reportsSent=0, viciousFound=0,
                  lastSprout=nil, lastVicious=nil, currentStatus="Готов к работе" },
    }, Searcher)
end

local function postJson(path, body)
    local url = CONFIG.API_URL:gsub("/+$", "") .. path
    local req = (syn and syn.request) or http_request or request
    if type(req) == "function" then
        local response = req({
            Url = url, Method = "POST",
            Headers = { ["Content-Type"]="application/json", ["Accept"]="application/json" },
            Body = body,
        })
        local status = tonumber(response and (response.StatusCode or response.Status)) or 0
        local responseBody = tostring(response and (response.Body or response.body) or "")
        if status < 200 or status >= 300 then
            error("HTTP " .. tostring(status) .. ": " .. responseBody)
        end
        return responseBody, status
    end
    local responseBody = game:HttpPost(url, body, "application/json")
    return tostring(responseBody or ""), 200
end

local function responseRejected(resp)
    local raw = tostring(resp or "")
    local ok, value = pcall(function() return HttpService:JSONDecode(raw) end)
    if ok and type(value) == "table" then
        if value.status=="ok" or value.ok==true or value.success==true then return false end
        if value.status=="error" or value.ok==false or value.success==false then return true end
    end
    local lower = string.lower(raw)
    return string.find(lower,"unauthorized",1,true) ~= nil
        or string.find(lower,"invalid api key",1,true) ~= nil
        or string.find(lower,"internal server error",1,true) ~= nil
end

function Searcher:report(jobId, rarity, fieldName)
    local body = HttpService:JSONEncode({
        apiKey=CONFIG.API_KEY, jobId=jobId, level=rarity or "unknown",
        placeId=CONFIG.PLACE_ID, fieldName=fieldName or "unknown",
        searcherTag=CONFIG.SELF_TAG,
    })
    local maxAttempts = math.max(5, tonumber(CONFIG.MAX_ATTEMPTS) or 3)
    for attempt = 1, maxAttempts do
        local ok, resp = pcall(function() return postJson("/report", body) end)
        if ok and not responseRejected(resp) then
            self.stats.reportsSent += 1
            self.stats.lastSprout = { fieldName = "отправлено" }
            return true
        end
        if attempt < maxAttempts then task.wait(math.min(attempt * 1.5, 6)) end
    end
    return false
end

function Searcher:reportVicious(jobId, kind, fieldName)
    local body = HttpService:JSONEncode({
        apiKey=CONFIG.API_KEY, jobId=jobId, kind=kind or "wild",
        placeId=CONFIG.PLACE_ID, fieldName=fieldName or "unknown",
        searcherTag=CONFIG.SELF_TAG,
        viciousChannelId=(CONFIG.VICIOUS_CHANNEL_ID ~= "" and CONFIG.VICIOUS_CHANNEL_ID) or nil,
    })
    for attempt = 1, 3 do
        local ok, resp = pcall(function() return postJson("/vicious", body) end)
        if ok then
            local lower = string.lower(tostring(resp))
            local failure = string.find(lower,'"error"',1,true)
                or string.find(lower,'"success":false',1,true)
                or string.find(lower,'"ok":false',1,true)
            if not failure then
                self.stats.viciousFound += 1
                self.stats.lastVicious = { fieldName=fieldName, kind=kind }
                return true
            end
        end
        if attempt < 3 then task.wait(attempt * 1.5) end
    end
    return false
end

function Searcher:reportPuffshroom(jobId, rarity, level, fieldName, timeRemaining)
    if not PUFF_RARITY_PRIORITY[rarity] then return false end
    local body = HttpService:JSONEncode({
        apiKey=CONFIG.API_KEY, jobId=jobId, placeId=CONFIG.PLACE_ID,
        fieldName=fieldName or "unknown", rarity=rarity, level=level,
        timeRemaining=timeRemaining, searcherTag=CONFIG.SELF_TAG,
        puffshroomChannelId=CONFIG.PUFFSHROOM_CHANNEL_ID,
    })
    for attempt = 1, 3 do
        local ok, resp = pcall(function() return postJson("/puffshroom", body) end)
        if ok and not responseRejected(resp) then self.stats.reportsSent += 1; return true end
        if attempt < 3 then task.wait(attempt * 0.75) end
    end
    return false
end

function Searcher:Start()
    self:Stop()
    local s = self.stats
    s.serversChecked, s.reportsSent = 0, 0
    s.viciousFound = 0
    s.lastSprout, s.lastVicious = nil, nil

    self.thread = task.spawn(function()
        s.currentStatus = "Запуск сканирования..."
        task.wait(tonumber(CONFIG.INITIAL_CHECK) or 1)
        while alive() do
            -- После смерти ждём новый персонаж и продолжаем тот же цикл.
            if not player.Character or not player.Character:FindFirstChild("HumanoidRootPart") then
                s.currentStatus = "Персонаж погиб — жду возрождения..."
                task.wait(0.5)
                continue
            end
            local ok, err = pcall(function()
                s.serversChecked += 1
                local sprout = CONFIG.CHECK_SPROUTS and findSprout() or nil

                if CONFIG.CHECK_PUFFSHROOMS then
                    local puff, puffRarity, puffLevel = findPuffshroom()
                    local minPuff = PUFF_RARITY_PRIORITY[CONFIG.PUFF_MIN_RARITY] or 1
                    if puff and puffRarity and (PUFF_RARITY_PRIORITY[puffRarity] or 0) >= minPuff and puffLevel then
                        local key = tostring(game.JobId).."|"..tostring(puff:GetFullName()).."|"..puffRarity.."|"..tostring(puffLevel)
                        if not puffReported[key] then
                            puffReported[key] = os.clock()
                            local f = detectField(puff)
                            local tm = findPuffshroomTimer(puff)
                            if tm then self:reportPuffshroom(game.JobId, puffRarity, puffLevel, f, tm) end
                        end
                    end
                end

                if CONFIG.CHECK_VICIOUS then
                    local vic = findVicious()
                    if vic then
                        local kind = detectViciousKind(vic)
                        s.currentStatus = "🐝 Vicious " .. kind .. " — остаюсь"
                        self:reportVicious(game.JobId, kind, detectField(vic))
                        if sprout then
                            local rarity = detectRarity(sprout)
                            if rarity then self:report(game.JobId, rarity, detectField(sprout)) end
                        end
                        task.wait(tonumber(CONFIG.REPORT_DELAY) or 2.5)
                        hopRandom(); return
                    end
                end

                if sprout then
                    local rarity = detectRarity(sprout)
                    local fieldName = detectField(sprout)
                    if rarity then
                        s.currentStatus = "Репортую " .. (RARITY_LABEL[rarity] or rarity)
                        if self:report(game.JobId, rarity, fieldName) then
                            s.lastSprout = { fieldName = (RARITY_LABEL[rarity] or rarity).." @ "..tostring(fieldName or "?") }
                        end
                    else
                        s.currentStatus = "Репортую Common"
                        self:report(game.JobId, "common", fieldName)
                    end
                    task.wait(tonumber(CONFIG.REPORT_DELAY) or 2.5)
                    hopRandom()
                else
                    s.currentStatus = "Сервер #" .. tostring(s.serversChecked) .. " — пусто"
                    hopRandom()
                end
            end)
            if not ok then
                log("Ищущий", "Ошибка: " .. tostring(err))
                task.wait(3); hopRandom()
            end
            task.wait(math.max(3, tonumber(CONFIG.HOP_DELAY) or 3))
        end
    end)
end

function Searcher:Stop()
    if self.thread then pcall(task.cancel, self.thread); self.thread = nil end
    self.stats.currentStatus = "Остановлен"
end
function Searcher:GetStats() return self.stats end

-- ══════════════════════════════════════════════════════════════════════
--  РЕЖИМ: 💰 ЛУТАЮЩИЙ
-- ══════════════════════════════════════════════════════════════════════
local Looter = {}
Looter.__index = Looter

function Looter.New()
    return setmetatable({
        thread = nil,
        stats = {
            tasksReceived=0, teleports=0, serversChecked=0,
            sproutsHarvested=0, hivesClaimed=0, tokensCollected=0,
            lastTask=nil, currentStatus="Готов к работе",
        },
    }, Looter)
end

function Looter:harvestPuffshrooms()
    local targets = findEligiblePuffshrooms()
    if #targets == 0 then return false end
    local s = self.stats
    s.currentStatus = "Puffshrooms — обработка"
    local stableMissing = 0
    while alive() do
        local remaining = findEligiblePuffshrooms()
        if #remaining > 0 then stableMissing = 0
        else
            stableMissing += 2
            if stableMissing >= 6 then break end
        end
        task.wait(2)
    end
    for i = 10, 1, -1 do
        if not alive() then return true end
        s.currentStatus = "Грибы собраны — " .. tostring(i) .. "с"
        task.wait(1)
    end
    return true
end

function Looter:harvest()
    local s = self.stats
    local sprout = findLootableSprout()
    if not sprout then return end

    if not hasOwnHive() then
        s.currentStatus = "Росток найден — занимаю улей"
        local claimOk, claimed = pcall(ensureHiveClaimed)
        if claimOk and claimed then s.hivesClaimed += 1 end
    end

    local rar = detectRarity(sprout)
    s.lastSprout = { fieldName = RARITY_LABEL[rar] or "спрут" }
    s.sproutsHarvested += 1
    s.currentStatus = "Лечу к ростку: " .. (RARITY_LABEL[rar] or "спрут")

    local sproutAnchor = worldPos(sprout)
    if moveToSprout(sprout) then
        sproutAnchor = worldPos(sprout) or sproutAnchor or (player.Character and player.Character:FindFirstChild("HumanoidRootPart") and player.Character.HumanoidRootPart.Position)
        s.currentStatus = "Росток: ставлю поливалку"
        task.wait(0.15)
        if useSprinklerBuilder then pcall(useSprinklerBuilder, sproutAnchor) end
        ensureHarvestToolEquipped()

        -- Фаза 1: Росток жив. Бегаем постоянно, машем инструментом, собираем токены
        while alive() and isSproutAlive(sprout, sproutAnchor) do
            if isBackpackFull() then
                s.currentStatus = "Рюкзак полный — делаю Honey"
                pcall(makeHoney)
                if not alive() or not isSproutAlive(sprout, sproutAnchor) then break end
                s.currentStatus = "Возвращаюсь к ростку"
                moveToSprout(sprout)
            end
            s.currentStatus = CONFIG.ENABLE_AUTO_DIG and "Росток: копаю и бегаю по полю" or "Росток: собираю токены"
            collectTokensFor(6, function()
                return not alive() or not isSproutAlive(sprout, sproutAnchor) or isBackpackFull()
            end, sproutAnchor)
            task.wait(0.05)
        end

        -- Фаза 2: Росток сломан! Лутаем оставшиеся ценные токены (игнорируя honey tokens)
        if alive() and sproutAnchor then
            if isBackpackFull() then
                s.currentStatus = "Рюкзак полный — делаю Honey"
                pcall(makeHoney)
            end
            if alive() and not isBackpackFull() then
                s.currentStatus = "Росток сломан — собираю ценные токены..."
                collectTokensFor(tonumber(CONFIG.BROKEN_WAIT) or 20, function()
                    return not alive() or isBackpackFull()
                end, sproutAnchor)
            end
        end
    end

    if isBackpackFull() then
        s.currentStatus = "Рюкзак полный — делаю Honey"
        pcall(makeHoney)
    end
end

function Looter:fetchNextVicious()
    local ok, res = pcall(function()
        return game:HttpGet(CONFIG.API_URL .. "/vicious-next?apiKey=" .. CONFIG.API_KEY)
    end)
    if not ok then return nil, "HTTP Vicious" end
    local ok2, data = pcall(function() return HttpService:JSONDecode(res) end)
    if not ok2 or not data then return nil, "плохой JSON" end
    if data.empty or not data.jobId then return nil, nil end
    if data.jobId == game.JobId then return nil, nil end
    data.isVicious = true
    return data, nil
end

function Looter:fetchNext()
    local ok, res = pcall(function()
        return game:HttpGet(CONFIG.API_URL .. "/next?apiKey=" .. CONFIG.API_KEY)
    end)
    if not ok then return nil, "HTTP" end
    local ok2, data = pcall(function() return HttpService:JSONDecode(res) end)
    if not ok2 or not data then return nil, "плохой JSON" end
    if data.empty or not data.jobId then return nil, nil end
    if data.jobId == game.JobId then return nil, "уже здесь" end
    return data, nil
end

function Looter:returnTask(taskData, reason)
    if not taskData or not taskData.jobId then return false end
    local endpoint, body
    if taskData.isVicious then
        endpoint = "/vicious"
        body = HttpService:JSONEncode({
            apiKey=CONFIG.API_KEY, jobId=taskData.jobId,
            kind=taskData.kind or "wild",
            placeId=taskData.placeId or CONFIG.PLACE_ID,
            fieldName=taskData.fieldName or "unknown",
            searcherTag=CONFIG.SELF_TAG,
        })
    else
        endpoint = "/return"
        body = HttpService:JSONEncode({
            apiKey=CONFIG.API_KEY, jobId=taskData.jobId,
            level=taskData.level, placeId=taskData.placeId or CONFIG.PLACE_ID,
            fieldName=taskData.fieldName or "unknown",
            searcherTag=CONFIG.SELF_TAG,
        })
    end
    pcall(function() return game:HttpPost(CONFIG.API_URL .. endpoint, body, "application/json") end)
    return true
end

function Looter:Start()
    self:Stop()
    local s = self.stats
    s.tasksReceived, s.teleports, s.lastTask = 0, 0, nil
    s.sproutsHarvested, s.hivesClaimed, s.tokensCollected = 0, 0, 0

    stopAutoDig()
    self.thread = task.spawn(function()
        task.wait(2)
        if ensureHiveClaimed() then s.hivesClaimed += 1 end

        if CONFIG.CHECK_VICIOUS then
            local v = findVicious()
            if v then
                s.currentStatus = "Vicious — лечу"
                pcall(function() fightVicious(v) end)
            end
        end
        if CONFIG.CHECK_PUFFSHROOMS and #findEligiblePuffshrooms() > 0 then
            pcall(function() self:harvestPuffshrooms() end)
        end
        if CONFIG.CHECK_SPROUTS and findLootableSprout() then
            pcall(function() self:harvest() end)
        end

        s.currentStatus = "Подключаюсь к боту..."

        while true do
            if not alive() then return end
            local ok, err = pcall(function()
                s.serversChecked += 1

                if CONFIG.CHECK_VICIOUS then
                    local v = findVicious()
                    if v then
                        s.currentStatus = "Vicious — лечу"
                        pcall(function() fightVicious(v) end)
                        return
                    end
                end

                if CONFIG.CHECK_PUFFSHROOMS and #findEligiblePuffshrooms() > 0 then
                    pcall(function() self:harvestPuffshrooms() end)
                    return
                end

                if CONFIG.CHECK_SPROUTS and findLootableSprout() then
                    pcall(function() self:harvest() end)
                    return
                end

                if isBackpackFull() then
                    s.currentStatus = "Рюкзак полный — делаю Honey"
                    pcall(makeHoney)
                    return
                end

                local taskData, skipReason = self:fetchNextVicious()
                if not taskData and not skipReason and CONFIG.CHECK_SPROUTS then
                    taskData, skipReason = self:fetchNext()
                end
                if skipReason then
                    s.currentStatus = skipReason
                    task.wait(tonumber(CONFIG.POLL_INTERVAL) or 3)
                    return
                end
                if taskData and not isFailed(taskData.jobId) then
                    s.tasksReceived += 1
                    s.lastTask = {
                        fieldName = taskData.isVicious and ("Vicious @ "..tostring(taskData.fieldName or "?"))
                            or (RARITY_LABEL[taskData.level] or taskData.level or "спрут"),
                        jobId = taskData.jobId, age = taskData.age,
                    }
                    s.currentStatus = "Телепорт к задаче..."
                    s.teleports += 1
                    if not hopTo(taskData.jobId, taskData.placeId) then
                        self:returnTask(taskData, "teleport failed")
                        task.wait(tonumber(CONFIG.POLL_INTERVAL) or 3)
                        return
                    end
                    task.wait(15)
                    self:returnTask(taskData, "timeout")
                    return
                end

                -- Лутающий НЕ ищет случайные сервера и НЕ собирает токены без задачи.
                -- Переходит только по задачам, опубликованным Ищущим.
                s.currentStatus = "Жду задачу от Ищущего — без цели ничего не собираю"
                task.wait(math.max(2, tonumber(CONFIG.POLL_INTERVAL) or 3))
            end)
            if not ok then
                log("Лутающий", "Ошибка: " .. tostring(err))
                task.wait(5)
            end
        end
    end)
end

function Looter:Stop()
    if self.thread then pcall(task.cancel, self.thread); self.thread = nil end
    tokenCollectorBusy = false
    patrolTarget = nil
    activeTokenObj = nil
    stopAutoDig()
    self.stats.currentStatus = "Остановлен"
end
function Looter:GetStats() return self.stats end

-- ══════════════════════════════════════════════════════════════════════
--  РЕЖИМ: 🎮 СОЛО
-- ══════════════════════════════════════════════════════════════════════
local Solo = {}
Solo.__index = Solo

function Solo.New()
    return setmetatable({
        thread = nil,
        stats = {
            serversChecked=0, sproutsFound=0, hops=0,
            hivesClaimed=0, tokensCollected=0,
            lastSprout=nil, currentStatus="Готов к работе",
        },
    }, Solo)
end

function Solo:Start()
    self:Stop()
    local s = self.stats
    s.serversChecked, s.sproutsFound, s.hops = 0, 0, 0
    s.hivesClaimed, s.tokensCollected = 0, 0
    s.lastSprout = nil
    s.currentStatus = "Запускаю Соло..."

    stopAutoDig()

    self.thread = task.spawn(function()
        s.currentStatus = "Соло активно — проверяю сервер на ростки..."
        task.wait(tonumber(CONFIG.INITIAL_CHECK) or 1.5)
        watchFolders()

        while true do
            if not alive() then return end
            local ok, err = pcall(function()
                s.serversChecked += 1

                local vicious = CONFIG.CHECK_VICIOUS and findVicious() or nil
                if vicious then
                    if not hasOwnHive() then
                        s.currentStatus = "Цель найдена — занимаю улей"
                        local claimOk, claimed = pcall(ensureHiveClaimed)
                        if claimOk and claimed then s.hivesClaimed += 1 end
                    end
                    s.currentStatus = "Vicious найден — лечу к нему"
                    local searcher = Hopper.instances.searcher
                    if searcher then
                        searcher:reportVicious(game.JobId, detectViciousKind(vicious), detectField(vicious))
                    end
                    pcall(function() fightVicious(vicious) end)
                    task.wait(1)
                    return
                end

                -- Проверка рюкзака перед поиском целей
                if isBackpackFull() then
                    s.currentStatus = "Рюкзак полный — делаю Honey"
                    pcall(makeHoney)
                end

                local sprout = CONFIG.CHECK_SPROUTS and findSprout() or nil
                if sprout then
                    s.sproutsFound += 1
                    local rar = detectRarity(sprout)
                    s.lastSprout = { fieldName = RARITY_LABEL[rar] or "спрут" }
                    s.currentStatus = "Росток найден — занимаю улей"

                    if not hasOwnHive() then
                        local claimOk, claimed = pcall(ensureHiveClaimed)
                        if claimOk and claimed then s.hivesClaimed += 1 end
                    end

                    s.currentStatus = "Лечу к ростку: " .. (RARITY_LABEL[rar] or "спрут")
                    local sproutAnchor = worldPos(sprout)
                    if moveToSprout(sprout) then
                        sproutAnchor = worldPos(sprout) or sproutAnchor or (player.Character and player.Character:FindFirstChild("HumanoidRootPart") and player.Character.HumanoidRootPart.Position)
                        s.currentStatus = "Росток: ставлю поливалку"
                        task.wait(0.15)
                        if useSprinklerBuilder then pcall(useSprinklerBuilder, sproutAnchor) end
                        ensureHarvestToolEquipped()

                        -- Фаза 1: Росток жив. Бегает всегда, машет палкой 100%, собирает токены
                        while alive() and isSproutAlive(sprout, sproutAnchor) do
                            if isBackpackFull() then
                                s.currentStatus = "Рюкзак полный — делаю Honey"
                                pcall(makeHoney)
                                if not alive() or not isSproutAlive(sprout, sproutAnchor) then break end
                                s.currentStatus = "Возвращаюсь к ростку"
                                moveToSprout(sprout)
                            end
                            if CONFIG.CHECK_VICIOUS and findVicious() then break end
                            s.currentStatus = CONFIG.ENABLE_AUTO_DIG and "Росток: копаю и бегаю по полю" or "Росток: бегаю и собираю токены"
                            collectTokensFor(6, function()
                                return not alive() or not isSproutAlive(sprout, sproutAnchor)
                                    or isBackpackFull()
                                    or (CONFIG.CHECK_VICIOUS and findVicious() ~= nil)
                            end, sproutAnchor)
                            task.wait(0.05)
                        end

                        -- Фаза 2: Росток сломан! Лутаем оставшиеся ценные токены (игнорируя honey tokens)
                        if alive() and sproutAnchor and not (CONFIG.CHECK_VICIOUS and findVicious()) then
                            if isBackpackFull() then
                                s.currentStatus = "Рюкзак полный — делаю Honey"
                                pcall(makeHoney)
                            end
                            if alive() and not isBackpackFull() then
                                s.currentStatus = "Росток сломан — собираю ценные токены..."
                                collectTokensFor(tonumber(CONFIG.BROKEN_WAIT) or 20, function()
                                    return not alive() or isBackpackFull() or (CONFIG.CHECK_VICIOUS and findVicious() ~= nil)
                                end, sproutAnchor)
                            end
                        end
                    end

                    -- Разгрузка перед переходом на следующий сервер
                    if isBackpackFull() then
                        s.currentStatus = "Рюкзак полный — делаю Honey перед переходом"
                        pcall(makeHoney)
                    end

                    -- Фаза 3: Росток залутан! Переход на следующий сервер
                    s.currentStatus = "Росток залутан — перехожу на другой сервер..."
                    task.wait(1)
                    if alive() then
                        s.hops += 1
                        hopRandom()
                        return
                    end
                end

                -- Если ростка нет на сервере — переходим на другой
                s.currentStatus = "Целей нет — перехожу на другой сервер..."
                task.wait(1)
                if alive() then
                    s.hops += 1
                    hopRandom()
                    return
                end
            end)
            if not ok then
                log("Соло", "Ошибка: " .. tostring(err))
                task.wait(2)
            end
            task.wait(0.3)
        end
    end)
end

function Solo:Stop()
    if self.thread then pcall(task.cancel, self.thread); self.thread = nil end
    tokenCollectorBusy = false
    patrolTarget = nil
    activeTokenObj = nil
    stopAutoDig()
    self.stats.currentStatus = "Остановлен"
end
function Solo:GetStats() return self.stats end

-- ══════════════════════════════════════════════════════════════════════
--  МЕНЕДЖЕР РЕЖИМОВ
-- ══════════════════════════════════════════════════════════════════════
Hopper = { Mode = nil, currentKey = nil }

Hopper.instances = {
    searcher = Searcher.New(),
    looter   = Looter.New(),
    solo     = Solo.New(),
}

local VALID_MODES = { searcher=true, looter=true, solo=true }

function Hopper.SwitchMode(mode, skipSave)
    flightStopRequested = true
    pcall(stopFlightNow)
    tokenCollectorBusy = false
    patrolTarget = nil
    activeTokenObj = nil
    if mode ~= "off" and Hopper.instances[mode] then
        lastMode = mode; CONFIG.MODE = mode
        pcall(saveNow)
    end
    if Hopper.Mode then pcall(function() Hopper.Mode:Stop() end) end
    if mode == "off" or not Hopper.instances[mode] then
        pcall(function() setLeftMouseHeld(false) end)
        Hopper.Mode = nil; Hopper.currentKey = nil
        if Hopper.OnModeChanged then Hopper.OnModeChanged("off") end
        if not skipSave then saveNow() end
        return
    end
    flightStopRequested = false
    Hopper.Mode = Hopper.instances[mode]
    Hopper.currentKey = mode
    pcall(function() setLeftMouseHeld(true) end)
    Hopper.Mode:Start()
    if Hopper.OnModeChanged then Hopper.OnModeChanged(mode) end
    saveNow()
end

local supervisorLog = false
function Hopper.Supervise()
    if not Hopper.Mode or not Hopper.currentKey then return end
    local thread = Hopper.Mode.thread
    local isAlive = false
    if thread then
        local ok, status = pcall(coroutine.status, thread)
        isAlive = ok and status ~= "dead"
    end
    if not isAlive then
        if not supervisorLog then supervisorLog = true end
        Hopper.SwitchMode(Hopper.currentKey, true)
    end
end

function Hopper.Toggle()
    if Hopper.Mode then Hopper.SwitchMode("off")
    else Hopper.SwitchMode(VALID_MODES[lastMode] and lastMode or "searcher") end
end

-- ══════════════════════════════════════════════════════════════════════
--  GUI
-- ══════════════════════════════════════════════════════════════════════
local modeButtons = {}
local readyPill
local isOpen = true
local refresh
local showPage
local setWindow
local C
local gui

local guiOk, guiErr = pcall(function()

local PlayerGui = player:WaitForChild("PlayerGui")
trace("PlayerGui получен")
local old = PlayerGui:FindFirstChild("BssHopperGui")
if old then old:Destroy() end

C = {
    bg=Color3.fromRGB(7,11,18), panel=Color3.fromRGB(10,16,25),
    sidebar=Color3.fromRGB(8,14,23), card=Color3.fromRGB(16,25,37),
    cardHi=Color3.fromRGB(13,43,34), field=Color3.fromRGB(11,18,29),
    text=Color3.fromRGB(239,243,248), dim=Color3.fromRGB(148,160,178),
    accent=Color3.fromRGB(105,235,145), accent2=Color3.fromRGB(54,184,105),
    danger=Color3.fromRGB(255,105,112), warn=Color3.fromRGB(255,198,100),
}

local function new(class, props)
    local o = Instance.new(class)
    for k, v in pairs(props or {}) do o[k] = v end
    return o
end
local function round(o, r)
    new("UICorner", { CornerRadius = UDim.new(0, r or 12), Parent = o })
end
local function stroke(o, c, t)
    new("UIStroke", {
        Color = c or Color3.fromRGB(48,62,72),
        Thickness = t or 1, Transparency = 0.22, Parent = o,
    })
end

gui = new("ScreenGui", {
    Name = "BssHopperGui", ResetOnSpawn = false, IgnoreGuiInset = true,
    DisplayOrder = 999999, ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
    Parent = PlayerGui,
})

local SNAKE_SIZE = 54
local snake = new("TextButton", {
    Name = "Snake",
    Size = UDim2.new(0, SNAKE_SIZE, 0, SNAKE_SIZE),
    Position = uiState.snakePos or UDim2.new(0.5, -SNAKE_SIZE/2, 0, 56),
    BackgroundColor3 = C.bg,
    Text = "🐍", Font = Enum.Font.GothamBold, TextSize = 27,
    TextColor3 = C.text, BorderSizePixel = 0,
    Draggable = true, Active = true, Parent = gui,
})
round(snake, SNAKE_SIZE/2)
stroke(snake, C.accent2, 2)

local dot = new("Frame", {
    Size = UDim2.new(0, 13, 0, 13),
    Position = UDim2.new(1, -15, 1, -15),
    BackgroundColor3 = C.danger, BorderSizePixel = 0, Parent = snake,
})
round(dot, 7)
new("UIStroke", { Color = C.bg, Thickness = 2, Parent = dot })

local hint = new("TextLabel", {
    Size = UDim2.new(0, 320, 0, 14),
    Position = UDim2.new(0.5, -160, 0, 56 + SNAKE_SIZE),
    BackgroundTransparency = 1,
    Text = "ЛКМ — вкл/выкл   •   ПКМ/F — меню",
    TextColor3 = C.dim, Font = Enum.Font.Gotham, TextSize = 11,
    TextTransparency = 0.35, Parent = gui,
})

trace("ScreenGui создан")

local WIN_W, WIN_H = 880, 500
local HEADER_H = 58
local SIDEBAR_W = 154

local win = new("Frame", {
    Name = "Win",
    Size = UDim2.new(0, WIN_W, 0, WIN_H),
    Position = uiState.winPos or UDim2.new(0.5, -WIN_W/2, 0.5, -WIN_H/2),
    BackgroundColor3 = C.bg,
    BorderSizePixel = 0, Visible = true, Active = true,
    ClipsDescendants = true, Parent = gui,
})
round(win, 16)
stroke(win, Color3.fromRGB(38,40,52))

local head = new("Frame", {
    Size = UDim2.new(1, 0, 0, HEADER_H),
    BackgroundColor3 = C.panel, BorderSizePixel = 0, Parent = win,
})
head.ClipsDescendants = true
round(head, 16)
new("UIGradient", {
    Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0, Color3.fromRGB(20,29,35)),
        ColorSequenceKeypoint.new(0.55, C.panel),
        ColorSequenceKeypoint.new(1, Color3.fromRGB(17,23,34)),
    }),
    Rotation = 0, Parent = head,
})
new("Frame", {
    Size = UDim2.new(1, 0, 0, 18), Position = UDim2.new(0, 0, 1, -18),
    BackgroundColor3 = C.panel, BorderSizePixel = 0, Parent = head,
})
new("Frame", {
    Size = UDim2.new(1, 0, 0, 1), Position = UDim2.new(0, 0, 1, -1),
    BackgroundColor3 = C.accent2, BorderSizePixel = 0,
    BackgroundTransparency = 0.55, Parent = head,
})

new("TextLabel", {
    Size = UDim2.new(0, 42, 1, 0), Position = UDim2.new(0, 16, 0, 0),
    BackgroundTransparency = 1, Text = "🐍",
    Font = Enum.Font.GothamBold, TextSize = 25,
    TextColor3 = C.accent, Parent = head,
})
new("TextLabel", {
    Size = UDim2.new(0, 220, 0, 25), Position = UDim2.new(0, 58, 0, 10),
    BackgroundTransparency = 1, Text = "🐍 BSS Hopper v1.3.43",
    TextColor3 = C.text, Font = Enum.Font.GothamBold, TextSize = 22,
    TextXAlignment = Enum.TextXAlignment.Left, Parent = head,
})
local subTitle = new("TextLabel", {
    Size = UDim2.new(0, 380, 0, 18), Position = UDim2.new(0, 58, 0, 36),
    BackgroundTransparency = 1, Text = "",
    TextColor3 = C.dim, Font = Enum.Font.Gotham, TextSize = 11,
    TextXAlignment = Enum.TextXAlignment.Left,
    TextTruncate = Enum.TextTruncate.AtEnd, Parent = head,
})

readyPill = new("Frame", {
    Name = "SystemReadyPill", Size = UDim2.new(0, 142, 0, 34),
    Position = UDim2.new(1, -286, 0, 16),
    BackgroundColor3 = Color3.fromRGB(12,35,29),
    BorderSizePixel = 0, Parent = head,
})
round(readyPill, 17)
stroke(readyPill, Color3.fromRGB(36,111,76), 1)
new("Frame", {
    Size = UDim2.new(0, 8, 0, 8), Position = UDim2.new(0, 12, 0.5, -4),
    BackgroundColor3 = C.accent, BorderSizePixel = 0, Parent = readyPill,
})
round(readyPill:FindFirstChildOfClass("Frame"), 4)
new("TextLabel", {
    Size = UDim2.new(1, -30, 1, 0), Position = UDim2.new(0, 26, 0, 0),
    BackgroundTransparency = 1, Text = "Система готова", TextColor3 = C.accent,
    Font = Enum.Font.GothamMedium, TextSize = 11,
    TextXAlignment = Enum.TextXAlignment.Left, Parent = readyPill,
})

local gearBtn = new("TextButton", {
    Size = UDim2.new(0, 38, 0, 38), Position = UDim2.new(1, -82, 0, 14),
    BackgroundColor3 = C.card, Text = "⚙", TextColor3 = C.dim,
    Font = Enum.Font.GothamBold, TextSize = 15,
    BorderSizePixel = 0, Parent = head,
})
round(gearBtn, 9)

local DISCORD_URL = "https://discord.gg/2YmPh2wExu"

local function openUrl(url)
    local attempts = {}
    if type(loadurl) == "function" then table.insert(attempts, function() return loadurl(url) end) end
    if type(open_url) == "function" then table.insert(attempts, function() return open_url(url) end) end
    for _, fn in ipairs(attempts) do
        local ok, result = pcall(fn)
        if ok and result ~= false then return true end
    end
    if type(setclipboard) == "function" then pcall(setclipboard, url) end
    return false
end

local discordBtn = new("TextButton", {
    Name = "DiscordBtn", Size = UDim2.new(0, 38, 0, 38),
    Position = UDim2.new(1, -130, 0, 14),
    BackgroundColor3 = Color3.fromRGB(88,101,242),
    Text = "", BorderSizePixel = 0, Parent = head,
})
round(discordBtn, 9)
new("TextLabel", {
    Size = UDim2.new(1, 0, 1, 0), BackgroundTransparency = 1,
    Text = "💬", Font = Enum.Font.GothamBold, TextSize = 15,
    TextColor3 = Color3.fromRGB(255,255,255), Parent = discordBtn,
})
discordBtn.MouseButton1Click:Connect(function() openUrl(DISCORD_URL) end)

local closeBtn = new("TextButton", {
    Size = UDim2.new(0, 38, 0, 38), Position = UDim2.new(1, -46, 0, 14),
    BackgroundColor3 = C.card, Text = "✕", TextColor3 = C.dim,
    Font = Enum.Font.GothamBold, TextSize = 13,
    BorderSizePixel = 0, Parent = head,
})
round(closeBtn, 9)

local sidebar = new("Frame", {
    Size = UDim2.new(0, SIDEBAR_W, 1, -HEADER_H),
    Position = UDim2.new(0, 0, 0, HEADER_H),
    BackgroundColor3 = C.sidebar, BorderSizePixel = 0, Parent = win,
})
new("UIListLayout", {
    SortOrder = Enum.SortOrder.LayoutOrder,
    Padding = UDim.new(0, 4), Parent = sidebar,
})
new("UIPadding", {
    PaddingTop = UDim.new(0, 10), PaddingBottom = UDim.new(0, 10),
    PaddingLeft = UDim.new(0, 8), PaddingRight = UDim.new(0, 8), Parent = sidebar,
})
new("TextLabel", {
    Size = UDim2.new(1, 0, 0, 16), BackgroundTransparency = 1,
    Text = "РАЗДЕЛЫ", TextColor3 = C.dim, Font = Enum.Font.GothamBold,
    TextSize = 10, TextXAlignment = Enum.TextXAlignment.Left,
    LayoutOrder = 0, Parent = sidebar,
})

local tabButtons = {}
local tabOrder = 10

local function makeTab(icon, label, key, locked)
    local b = new("TextButton", {
        Size = UDim2.new(1, 0, 0, 42), BackgroundColor3 = C.panel, Text = "",
        BorderSizePixel = 0, LayoutOrder = tabOrder,
        AutoButtonColor = not locked, Parent = sidebar,
    })
    tabOrder += 1
    round(b, 10)
    local bar = new("Frame", {
        Size = UDim2.new(0, 3, 1, -16), Position = UDim2.new(0, 0, 0, 8),
        BackgroundColor3 = C.accent, BorderSizePixel = 0,
        Visible = false, Parent = b,
    })
    round(bar, 2)
    local ico = new("TextLabel", {
        Size = UDim2.new(0, 26, 1, 0), Position = UDim2.new(0, 6, 0, 0),
        BackgroundTransparency = 1, Text = icon,
        Font = Enum.Font.GothamBold, TextSize = 14,
        TextColor3 = C.dim, Parent = b,
    })
    local lbl = new("TextLabel", {
        Size = UDim2.new(1, -34, 1, 0), Position = UDim2.new(0, 32, 0, 0),
        BackgroundTransparency = 1, Text = label,
        TextColor3 = C.dim, Font = Enum.Font.Gotham, TextSize = 12,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextYAlignment = Enum.TextYAlignment.Center,
        TextTruncate = Enum.TextTruncate.AtEnd, Parent = b,
    })
    tabButtons[key] = { btn=b, bar=bar, icon=ico, label=lbl, locked=locked }
    return b
end

makeTab("⌂", "Главная", "main")
makeTab("🌱", "Спруты", "sprouts")
makeTab("⚙", "Настройки", "settings")
makeTab("🐝", "Vicious Bee", "vicious")
makeTab("🍄", "Puffshrooms", "puffshrooms")

trace("Боковая панель готова")

local content = new("ScrollingFrame", {
    Name = "Content",
    Size = UDim2.new(1, -SIDEBAR_W - 12, 1, -HEADER_H - 8),
    Position = UDim2.new(0, SIDEBAR_W + 6, 0, HEADER_H + 4),
    BackgroundTransparency = 1, BorderSizePixel = 0,
    ScrollBarThickness = 4, ScrollBarImageColor3 = C.accent2,
    AutomaticCanvasSize = Enum.AutomaticSize.Y,
    CanvasSize = UDim2.new(),
    ScrollingDirection = Enum.ScrollingDirection.Y,
    Parent = win,
})
new("UIListLayout", {
    SortOrder = Enum.SortOrder.LayoutOrder, Padding = UDim.new(0, 8),
    Parent = content,
})
new("UIPadding", {
    PaddingTop = UDim.new(0, 2), PaddingBottom = UDim.new(0, 10),
    PaddingRight = UDim.new(0, 6), Parent = content,
})
new("Frame", {
    Size = UDim2.new(0, 1, 1, -HEADER_H - 10),
    Position = UDim2.new(0, SIDEBAR_W, 0, HEADER_H + 5),
    BackgroundColor3 = Color3.fromRGB(38,40,52),
    BorderSizePixel = 0, Parent = win,
})

local function section(txt, order)
    return new("TextLabel", {
        Size = UDim2.new(1, 0, 0, 16), BackgroundTransparency = 1,
        Text = txt, TextColor3 = C.dim, Font = Enum.Font.GothamBold,
        TextSize = 9, TextXAlignment = Enum.TextXAlignment.Left,
        LayoutOrder = order, Parent = content,
    })
end

local PAGE_HOME = new("Frame", {
    Size = UDim2.new(1, 0, 0, 0),
    AutomaticSize = Enum.AutomaticSize.Y,
    BackgroundTransparency = 1, Visible = true, Parent = content,
})
new("UIListLayout", {
    SortOrder = Enum.SortOrder.LayoutOrder, Padding = UDim.new(0, 8),
    Parent = PAGE_HOME,
})

local secModes = section("РЕЖИМ РАБОТЫ", 10)
secModes.Parent = PAGE_HOME

local MODE_META = {
    searcher = { icon="🔍", name="Ищущий",  desc="Сканирует серверы и репортит находки" },
    looter   = { icon="💰", name="Лутающий", desc="Задачи + улей + токены + Honey" },
    solo     = { icon="🎮", name="Соло",     desc="Сам ищет, лутает, фармит и делает Honey" },
}

local modeRow = new("Frame", {
    Size = UDim2.new(1, 0, 0, 120), BackgroundTransparency = 1,
    LayoutOrder = 11, Parent = PAGE_HOME,
})
new("UIListLayout", {
    FillDirection = Enum.FillDirection.Horizontal,
    Padding = UDim.new(0, 8), Parent = modeRow,
})

local modeOrder = 10
for _, key in ipairs({ "searcher", "looter", "solo" }) do
    local m = MODE_META[key]
    local b = new("TextButton", {
        Size = UDim2.new(1/3, -6, 1, 0),
        BackgroundColor3 = C.card, Text = "", BorderSizePixel = 0,
        AutoButtonColor = false, LayoutOrder = modeOrder, Parent = modeRow,
    })
    modeOrder += 1
    round(b, 12)
    local modeStroke = new("UIStroke", {
        Color = Color3.fromRGB(39,57,75), Thickness = 1,
        Transparency = 0.12, Parent = b,
    })
    new("TextLabel", {
        Size = UDim2.new(0, 40, 0, 34), Position = UDim2.new(0, 16, 0, 14),
        BackgroundTransparency = 1, Text = m.icon,
        Font = Enum.Font.GothamBold, TextSize = 23,
        TextColor3 = C.text, Parent = b,
    })
    local tl = new("TextLabel", {
        Size = UDim2.new(1, -32, 0, 24), Position = UDim2.new(0, 16, 0, 54),
        BackgroundTransparency = 1, Text = m.name,
        TextColor3 = C.text, Font = Enum.Font.GothamBold, TextSize = 16,
        TextXAlignment = Enum.TextXAlignment.Left, Parent = b,
    })
    new("TextLabel", {
        Size = UDim2.new(1, -32, 0, 42), Position = UDim2.new(0, 16, 0, 82),
        BackgroundTransparency = 1, Text = m.desc, TextWrapped = true,
        TextColor3 = C.dim, Font = Enum.Font.Gotham, TextSize = 10,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextYAlignment = Enum.TextYAlignment.Top, Parent = b,
    })
    local bar = new("Frame", {
        Size = UDim2.new(1, -24, 0, 3), Position = UDim2.new(0, 12, 1, -8),
        BackgroundColor3 = C.accent, BorderSizePixel = 0,
        Visible = false, Parent = b,
    })
    round(bar, 2)

    b.MouseEnter:Connect(function()
        if Hopper.Mode ~= Hopper.instances[key] then
            TweenService:Create(b, TweenInfo.new(0.14), { BackgroundColor3 = C.cardHi }):Play()
        end
    end)
    b.MouseLeave:Connect(function()
        if Hopper.Mode ~= Hopper.instances[key] then
            TweenService:Create(b, TweenInfo.new(0.14), { BackgroundColor3 = C.card }):Play()
        end
    end)
    b.MouseButton1Click:Connect(function()
        if Hopper.Mode == Hopper.instances[key] then Hopper.SwitchMode("off")
        else Hopper.SwitchMode(key) end
    end)
    modeButtons[key] = { btn=b, title=tl, bar=bar, outline=modeStroke }
end

local secStatus = section("СТАТУС", 20)
secStatus.Parent = PAGE_HOME

local statusBox = new("Frame", {
    Size = UDim2.new(1, 0, 0, 64), BackgroundColor3 = C.card,
    BorderSizePixel = 0, LayoutOrder = 21, Parent = PAGE_HOME,
})
round(statusBox, 12)
stroke(statusBox)
new("TextLabel", {
    Size = UDim2.new(0, 90, 0, 64), Position = UDim2.new(0, 16, 0, 0),
    BackgroundTransparency = 1, Text = "СТАТУС",
    TextColor3 = C.dim, Font = Enum.Font.GothamBold, TextSize = 9,
    TextXAlignment = Enum.TextXAlignment.Left,
    TextYAlignment = Enum.TextYAlignment.Center, Parent = statusBox,
})
local statusVal = new("TextLabel", {
    Size = UDim2.new(1, -130, 0, 64), Position = UDim2.new(0, 110, 0, 0),
    BackgroundTransparency = 1, Text = "-", TextWrapped = true,
    TextColor3 = C.accent, Font = Enum.Font.GothamBold, TextSize = 12,
    TextXAlignment = Enum.TextXAlignment.Left,
    TextYAlignment = Enum.TextYAlignment.Center, Parent = statusBox,
})

local secLast = section("ПОСЛЕДНЯЯ ЗАДАЧА", 40)
secLast.Parent = PAGE_HOME
local lastBox = new("Frame", {
    Size = UDim2.new(1, 0, 0, 66), BackgroundColor3 = C.card,
    BorderSizePixel = 0, LayoutOrder = 41, Parent = PAGE_HOME,
})
round(lastBox, 12)
stroke(lastBox)
local lastVal = new("TextLabel", {
    Size = UDim2.new(1, -24, 1, 0), Position = UDim2.new(0, 12, 0, 0),
    BackgroundTransparency = 1, Text = "—", TextWrapped = true,
    TextColor3 = C.dim, Font = Enum.Font.Gotham, TextSize = 12,
    TextXAlignment = Enum.TextXAlignment.Left,
    TextYAlignment = Enum.TextYAlignment.Center, Parent = lastBox,
})

local function makeField(parent, label, value, placeholder, order, secret)
    local box = new("Frame", {
        Size = UDim2.new(1, 0, 0, 48), BackgroundColor3 = C.card,
        BorderSizePixel = 0, LayoutOrder = order, Parent = parent,
    })
    round(box, 12)
    stroke(box)
    new("TextLabel", {
        Size = UDim2.new(1, -20, 0, 13), Position = UDim2.new(0, 10, 0, 6),
        BackgroundTransparency = 1, Text = label,
        TextColor3 = C.dim, Font = Enum.Font.GothamBold, TextSize = 8,
        TextXAlignment = Enum.TextXAlignment.Left, Parent = box,
    })
    local tb = new("TextBox", {
        Size = UDim2.new(1, -20, 0, 22), Position = UDim2.new(0, 10, 0, 21),
        BackgroundColor3 = C.field, Text = tostring(value or ""),
        PlaceholderText = placeholder or "",
        PlaceholderColor3 = Color3.fromRGB(85,88,102),
        TextColor3 = C.text, Font = Enum.Font.Gotham, TextSize = 11,
        ClearTextOnFocus = false, TextXAlignment = Enum.TextXAlignment.Left,
        BorderSizePixel = 0, Parent = box,
    })
    round(tb, 6)
    return tb
end

local function makeToggle(parent, label, value, order, onChanged)
    local box = new("Frame", {
        Size = UDim2.new(1, 0, 0, 34), BackgroundColor3 = C.card,
        BorderSizePixel = 0, LayoutOrder = order, Parent = parent,
    })
    round(box, 12)
    stroke(box)
    new("TextLabel", {
        Size = UDim2.new(1, -70, 1, 0), Position = UDim2.new(0, 12, 0, 0),
        BackgroundTransparency = 1, Text = label, TextColor3 = C.text,
        Font = Enum.Font.Gotham, TextSize = 11,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextYAlignment = Enum.TextYAlignment.Center, Parent = box,
    })
    local state = value and true or false
    local knob = new("TextButton", {
        Size = UDim2.new(0, 44, 0, 20),
        Position = UDim2.new(1, -52, 0.5, -10),
        BackgroundColor3 = state and C.accent2 or C.cardHi,
        Text = state and "ВКЛ" or "ВЫКЛ",
        TextColor3 = C.text, Font = Enum.Font.GothamBold, TextSize = 9,
        BorderSizePixel = 0, Parent = box,
    })
    round(knob, 10)
    knob.MouseButton1Click:Connect(function()
        state = not state
        knob.BackgroundColor3 = state and C.accent2 or C.cardHi
        knob.Text = state and "ВКЛ" or "ВЫКЛ"
        if onChanged then pcall(onChanged, state) end
    end)
    return function() return state end
end

local function makeBtn(parent, txt, cb, col, order)
    local b = new("TextButton", {
        Size = UDim2.new(0.5, -4, 1, 0),
        BackgroundColor3 = col or C.card, Text = txt,
        TextColor3 = C.text, Font = Enum.Font.GothamBold, TextSize = 11,
        BorderSizePixel = 0, LayoutOrder = order, Parent = parent,
    })
    round(b, 10)
    stroke(b)
    b.MouseButton1Click:Connect(cb)
    return b
end

section("ОСНОВНЫЕ ФУНКЦИИ", 1).Parent = PAGE_HOME
makeToggle(PAGE_HOME, "Лутать Vicious Bee", CONFIG.CHECK_VICIOUS, 2, function(v)
    CONFIG.CHECK_VICIOUS = v; saveNow()
end)
makeToggle(PAGE_HOME, "Лутать ростки", CONFIG.CHECK_SPROUTS, 4, function(v)
    CONFIG.CHECK_SPROUTS = v; saveNow()
end)
-- Автокопание работает пассивно
-- Bypass работает пассивно

local homeInfo = new("TextLabel", {
    Size = UDim2.new(1, 0, 0, 48), BackgroundColor3 = C.card,
    Text = "Включи нужные цели и выбери режим. В Лутающем и Соло автоматически занимается улей, фармятся токены и делается Honey при полном рюкзаке.",
    TextColor3 = C.dim, Font = Enum.Font.Gotham, TextSize = 11,
    TextWrapped = true, TextXAlignment = Enum.TextXAlignment.Left,
    TextYAlignment = Enum.TextYAlignment.Center, BorderSizePixel = 0,
    LayoutOrder = 7, Parent = PAGE_HOME,
})
round(homeInfo, 12)
new("UIPadding", { PaddingLeft = UDim.new(0, 12), PaddingRight = UDim.new(0, 12), Parent = homeInfo })

-- ══════════════════════════════════════════════════════════════════════
--  СПРУТЫ
-- ══════════════════════════════════════════════════════════════════════
local PAGE_SPROUTS = new("Frame", {
    Size = UDim2.new(1, 0, 0, 0),
    AutomaticSize = Enum.AutomaticSize.Y,
    BackgroundTransparency = 1, Visible = false, Parent = content,
})
new("UIListLayout", {
    SortOrder = Enum.SortOrder.LayoutOrder, Padding = UDim.new(0, 8),
    Parent = PAGE_SPROUTS,
})

section("МИНИМАЛЬНАЯ РЕДКОСТЬ ДЛЯ ЛУТА", 1).Parent = PAGE_SPROUTS

local sproutRarityOrder = { "basic", "moon", "rare", "gummy", "epic", "legendary" }
local sproutRarityLabels = {
    moon="Moon", basic="Common", rare="Rare", epic="Epic",
    legendary="Legendary", gummy="Gummy",
}
local sproutRarityColors = {
    moon=Color3.fromRGB(105,190,255), basic=Color3.fromRGB(130,220,135),
    rare=Color3.fromRGB(190,200,210), epic=Color3.fromRGB(255,195,70),
    legendary=Color3.fromRGB(75,220,205), gummy=Color3.fromRGB(255,115,220),
}
if not RARITY_PRIORITY[CONFIG.MIN_RARITY] then CONFIG.MIN_RARITY = "basic" end

local sproutRarityRow = new("Frame", {
    Size = UDim2.new(1, 0, 0, 70), BackgroundTransparency = 1,
    LayoutOrder = 2, Parent = PAGE_SPROUTS,
})
new("UIGridLayout", {
    CellSize = UDim2.new(0.25, -5, 0, 30),
    CellPadding = UDim2.new(0, 6, 0, 6),
    FillDirectionMaxCells = 4,
    SortOrder = Enum.SortOrder.LayoutOrder,
    Parent = sproutRarityRow,
})
local sproutRarityButtons = {}
local function paintSproutRarity()
    for _, rarityName in ipairs(sproutRarityOrder) do
        local button = sproutRarityButtons[rarityName]
        if button then
            local selected = CONFIG.MIN_RARITY == rarityName
            button.BackgroundColor3 = selected and C.cardHi or C.field
            button.TextColor3 = sproutRarityColors[rarityName]
            local outline = button:FindFirstChildOfClass("UIStroke")
            if outline then outline.Thickness = selected and 2 or 1 end
        end
    end
end

for index, rarityName in ipairs(sproutRarityOrder) do
    local button = new("TextButton", {
        Size = UDim2.new(0.25, -5, 0, 30),
        BackgroundColor3 = C.field,
        Text = sproutRarityLabels[rarityName],
        TextColor3 = sproutRarityColors[rarityName],
        Font = Enum.Font.GothamBold, TextSize = 10,
        AutoButtonColor = false, BorderSizePixel = 0,
        LayoutOrder = index, Parent = sproutRarityRow,
    })
    round(button, 8)
    stroke(button, sproutRarityColors[rarityName], 1)
    sproutRarityButtons[rarityName] = button
    button.MouseButton1Click:Connect(function()
        CONFIG.MIN_RARITY = rarityName
        paintSproutRarity(); saveNow()
        statusVal.Text = "Минимальная редкость: " .. sproutRarityLabels[rarityName] .. "+"
        statusVal.TextColor3 = C.accent
    end)
end
paintSproutRarity()

new("TextLabel", {
    Size = UDim2.new(1, 0, 0, 20), BackgroundTransparency = 1,
    Text = "Минимальная редкость",
    TextColor3 = C.dim, Font = Enum.Font.Gotham, TextSize = 10,
    TextWrapped = true, TextXAlignment = Enum.TextXAlignment.Left,
    LayoutOrder = 3, Parent = PAGE_SPROUTS,
})

-- ══════════════════════════════════════════════════════════════════════
--  НАСТРОЙКИ
-- ══════════════════════════════════════════════════════════════════════
local pageSettings = new("Frame", {
    Size = UDim2.new(1, 0, 0, 0),
    AutomaticSize = Enum.AutomaticSize.Y,
    BackgroundTransparency = 1, Visible = false, Parent = content,
})
new("UIListLayout", {
    SortOrder = Enum.SortOrder.LayoutOrder, Padding = UDim.new(0, 8),
    Parent = pageSettings,
})

section("АККАУНТ И БОТ", 1).Parent = pageSettings
local fTag = makeField(pageSettings, "ТЕГ АККАУНТА", CONFIG.SELF_TAG, "searcher1", 10)
local fUrl = makeField(pageSettings, "URL БОТА", CONFIG.API_URL, "https://...", 11)
local fKey = makeField(pageSettings, "API KEY", CONFIG.API_KEY, "ключ", 12, true)
local fViciousChannel = makeField(pageSettings, "DISCORD CHANNEL ID — VICIOUS", CONFIG.VICIOUS_CHANNEL_ID, "ID канала", 13, true)

local acctRow = new("Frame", {
    Size = UDim2.new(1, 0, 0, 160), BackgroundTransparency = 1,
    LayoutOrder = 14, Parent = pageSettings,
})
new("UIListLayout", { FillDirection = Enum.FillDirection.Horizontal,
    Padding = UDim.new(0, 8), Parent = acctRow })
local colA = new("Frame", { Size = UDim2.new(0.5, -4, 1, 0), BackgroundTransparency = 1, Parent = acctRow })
local colB = new("Frame", { Size = UDim2.new(0.5, -4, 1, 0), BackgroundTransparency = 1, Parent = acctRow })
new("UIListLayout", { SortOrder = Enum.SortOrder.LayoutOrder, Padding = UDim.new(0, 8), Parent = colA })
new("UIListLayout", { SortOrder = Enum.SortOrder.LayoutOrder, Padding = UDim.new(0, 8), Parent = colB })

fTag.Parent = colA
fUrl.Parent = colB
fKey.Parent = colA
fViciousChannel.Parent = colB

section("ТАЙМИНГИ", 20).Parent = pageSettings
local fHop = makeField(pageSettings, "ЗАДЕРЖКА ХОПА (сек)", CONFIG.HOP_DELAY, "3", 21)
local fPoll = makeField(pageSettings, "ОПРОС БОТА (сек)", CONFIG.POLL_INTERVAL, "3", 22)
local fWait = makeField(pageSettings, "ЖДАТЬ СЛОМАННОГО СПРУТА (сек)", CONFIG.BROKEN_WAIT, "20", 23)
local fConn = makeField(pageSettings, "ТАЙМАУТ ПОДКЛЮЧЕНИЯ (сек)", CONFIG.CONNECT_TIMEOUT, "3", 24)
local fPlace = makeField(pageSettings, "PLACE ID", CONFIG.PLACE_ID, "1537690962", 25)

section("СКОРОСТЬ", 30).Parent = pageSettings
local fWalk = makeField(pageSettings, "МНОЖИТЕЛЬ БЕГА (x от 16)", CONFIG.WALK_SPEED_MULT, "2.4", 31)
local fFly = makeField(pageSettings, "СКОРОСТЬ ПОЛЁТА (studs/s)", CONFIG.FLY_SPEED, "100", 32)

section("ИНСТРУМЕНТЫ И УЛЕЙ", 40).Parent = pageSettings
local fSprinkler = makeField(pageSettings, "SPRINKLER KEYWORD", CONFIG.SPRINKLER_KEYWORD, "sprinkler", 41)
local fSprinklerCount = makeField(pageSettings, "КОЛИЧЕСТВО ПОЛИВАЛОК (1–4)", CONFIG.SPRINKLER_COUNT, "3", 42)
local getSprinkler = makeToggle(pageSettings, "Автоматически ставить поливалки", CONFIG.ENABLE_AUTO_SPRINKLER, 43, function(v)
    CONFIG.ENABLE_AUTO_SPRINKLER = v; saveNow()
end)
local fRegion = makeField(pageSettings, "ЗОНА ФАРМА (center / left / right)", CONFIG.FARM_REGION, "center", 44)
local fDigTool = makeField(pageSettings, "DIG TOOL KEYWORD", CONFIG.DIG_TOOL_KEYWORD, "scooper", 45)
local fSlotKeyword = makeField(pageSettings, "EMPTY SLOT KEYWORD", CONFIG.EMPTY_SLOT_KEYWORD, "claim hive", 46)
local fHoneyKeyword = makeField(pageSettings, "MY HIVE KEYWORD", CONFIG.MY_HIVE_KEYWORD, "make honey", 47)

section("ОПЦИИ", 50).Parent = pageSettings
local getDebug = makeToggle(pageSettings, "Диагностика спрута в консоли",
    CONFIG.DEBUG_SPROUT, 52, function(v) CONFIG.DEBUG_SPROUT = v; saveNow() end)
local getAuto = makeToggle(pageSettings, "Автозапуск после перезахода",
    CONFIG.AUTO_START, 53, function(v) CONFIG.AUTO_START = v; saveNow() end)
local getAntiLag = makeToggle(pageSettings, "ANTI-LAG: снизить графику", CONFIG.ANTI_LAG, 54, function(v)
    applyAntiLag(v); saveNow()
end)

local function applySettings()
    local function num(v, def)
        local n = tonumber(v); return n and n > 0 and n or def
    end
    CONFIG.SELF_TAG = (fTag.Text ~= "" and fTag.Text) or CONFIG.SELF_TAG
    CONFIG.API_URL = (fUrl.Text ~= "" and fUrl.Text) or CONFIG.API_URL
    if fKey.Text ~= "" then CONFIG.API_KEY = fKey.Text end
    CONFIG.VICIOUS_CHANNEL_ID = (fViciousChannel.Text ~= "" and fViciousChannel.Text) or CONFIG.VICIOUS_CHANNEL_ID
    CONFIG.HOP_DELAY = num(fHop.Text, 3)
    CONFIG.POLL_INTERVAL = num(fPoll.Text, 3)
    CONFIG.BROKEN_WAIT = num(fWait.Text, 20)
    CONFIG.CONNECT_TIMEOUT = num(fConn.Text, 3)
    CONFIG.PLACE_ID = (fPlace.Text ~= "" and fPlace.Text) or CONFIG.PLACE_ID
    CONFIG.WALK_SPEED_MULT = num(fWalk.Text, 2.4)
    CONFIG.FLY_SPEED = math.clamp(num(fFly.Text, 100), 50, 150)
    CONFIG.SPRINKLER_KEYWORD = (fSprinkler.Text ~= "" and fSprinkler.Text) or CONFIG.SPRINKLER_KEYWORD
    CONFIG.SPRINKLER_COUNT = math.clamp(math.floor(num(fSprinklerCount.Text, 3)), 1, 4)
    CONFIG.ENABLE_AUTO_SPRINKLER = getSprinkler()
    local region = string.lower((fRegion.Text ~= "" and fRegion.Text) or CONFIG.FARM_REGION or "center")
    CONFIG.FARM_REGION = (region == "left" or region == "right") and region or "center"
    CONFIG.DIG_TOOL_KEYWORD = (fDigTool.Text ~= "" and fDigTool.Text) or CONFIG.DIG_TOOL_KEYWORD
    CONFIG.EMPTY_SLOT_KEYWORD = (fSlotKeyword.Text ~= "" and fSlotKeyword.Text) or CONFIG.EMPTY_SLOT_KEYWORD
    CONFIG.MY_HIVE_KEYWORD = (fHoneyKeyword.Text ~= "" and fHoneyKeyword.Text) or CONFIG.MY_HIVE_KEYWORD
    CONFIG.DEBUG_SPROUT = getDebug()
    CONFIG.AUTO_START = getAuto()
    CONFIG.ANTI_LAG = getAntiLag()
    applyAntiLag(CONFIG.ANTI_LAG)
    applyWalkSpeed()
    saveNow()
end

local btnRow = new("Frame", {
    Size = UDim2.new(1, 0, 0, 34), BackgroundTransparency = 1,
    LayoutOrder = 60, Parent = pageSettings,
})
new("UIListLayout", { FillDirection = Enum.FillDirection.Horizontal,
    Padding = UDim.new(0, 8), Parent = btnRow })

makeBtn(btnRow, "💾 Сохранить", function()
    applySettings()
    if saveNow() then
        statusVal.Text = "Настройки сохранены"
        statusVal.TextColor3 = C.accent
    else
        statusVal.Text = "Не удалось сохранить"
        statusVal.TextColor3 = C.warn
    end
end, C.accent2)

makeBtn(btnRow, "↺ Сбросить", function()
    pcall(function()
        if type(delfile) == "function" then delfile(SAVE_FILE) end
    end)
    statusVal.Text = "Файл настроек удалён"
    statusVal.TextColor3 = C.warn
end, Color3.fromRGB(80,40,40))

-- ══════════════════════════════════════════════════════════════════════
--  VICIOUS BEE
-- ══════════════════════════════════════════════════════════════════════
local PAGE_VICIOUS = new("Frame", {
    Size = UDim2.new(1, 0, 0, 0),
    AutomaticSize = Enum.AutomaticSize.Y,
    BackgroundTransparency = 1, Visible = false, Parent = content,
})
new("UIListLayout", {
    SortOrder = Enum.SortOrder.LayoutOrder, Padding = UDim.new(0, 8),
    Parent = PAGE_VICIOUS,
})
section("ПОИСК VICIOUS BEE", 1).Parent = PAGE_VICIOUS
local vicRangeInfo = new("TextLabel", {
    Size = UDim2.new(1, 0, 0, 34), BackgroundTransparency = 1,
    Text = "Диапазон полей для Vicious: 1 Clover, 2 Spider, 3 Cactus, 4 Mountain Top, 5 Pepper Patch. Сохрани диапазон в настройках ниже.",
    TextColor3 = C.dim, Font = Enum.Font.Gotham, TextSize = 10,
    TextWrapped = true, TextXAlignment = Enum.TextXAlignment.Left,
    LayoutOrder = 2, Parent = PAGE_VICIOUS,
})
-- Компактный выбор диапазона звёздами вместо огромной кнопки и текстовых полей.
local VICIOUS_FIELD_NAMES = { "Clover", "Spider", "Cactus", "Mountain Top", "Pepper Patch" }
local vicFrom = math.clamp(math.floor(tonumber(CONFIG.VICIOUS_FIELD_FROM) or 1), 1, 5)
local vicTo = math.clamp(math.floor(tonumber(CONFIG.VICIOUS_FIELD_TO) or 5), 1, 5)
if vicFrom > vicTo then vicFrom, vicTo = vicTo, vicFrom end
CONFIG.VICIOUS_FIELD_FROM, CONFIG.VICIOUS_FIELD_TO = vicFrom, vicTo

local function makeStarRangeRow(titleText, order, selectedValue, callback)
    local wrap = new("Frame", {
        Size = UDim2.new(1, 0, 0, 56), BackgroundTransparency = 1,
        LayoutOrder = order, Parent = PAGE_VICIOUS,
    })
    new("TextLabel", {
        Size = UDim2.new(1, 0, 0, 16), BackgroundTransparency = 1,
        Text = titleText, TextColor3 = C.dim, Font = Enum.Font.Gotham,
        TextSize = 10, TextXAlignment = Enum.TextXAlignment.Left,
        Parent = wrap,
    })
    local row = new("Frame", {
        Position = UDim2.new(0, 0, 0, 19), Size = UDim2.new(1, 0, 0, 34),
        BackgroundTransparency = 1, Parent = wrap,
    })
    new("UIListLayout", {
        FillDirection = Enum.FillDirection.Horizontal,
        Padding = UDim.new(0, 6), SortOrder = Enum.SortOrder.LayoutOrder,
        Parent = row,
    })
    local buttons = {}
    local function paint(value)
        for i, button in ipairs(buttons) do
            local active = i == value
            button.BackgroundColor3 = active and C.accent2 or C.field
            button.TextColor3 = active and Color3.fromRGB(255,255,255) or C.text
            local outline = button:FindFirstChildOfClass("UIStroke")
            if outline then outline.Thickness = active and 2 or 1 end
        end
    end
    for i = 1, 5 do
        local b = new("TextButton", {
            Size = UDim2.new(0.2, -5, 1, 0), BackgroundColor3 = C.field,
            Text = string.rep("★", i), TextColor3 = C.text,
            Font = Enum.Font.GothamBold, TextSize = 10, AutoButtonColor = false,
            BorderSizePixel = 0, LayoutOrder = i, Parent = row,
        })
        round(b, 8); stroke(b, C.cardHi, 1)
        buttons[i] = b
        b.MouseButton1Click:Connect(function()
            paint(i)
            callback(i)
        end)
    end
    paint(selectedValue)
    return paint
end

local vicRangeSummary = new("TextLabel", {
    Size = UDim2.new(1, 0, 0, 24), BackgroundTransparency = 1,
    Text = "Диапазон: 1–5 звёзд", TextColor3 = C.dim,
    Font = Enum.Font.Gotham, TextSize = 10, TextXAlignment = Enum.TextXAlignment.Left,
    LayoutOrder = 5, Parent = PAGE_VICIOUS,
})
local function saveViciousRange()
    if vicFrom > vicTo then vicFrom, vicTo = vicTo, vicFrom end
    CONFIG.VICIOUS_FIELD_FROM, CONFIG.VICIOUS_FIELD_TO = vicFrom, vicTo
    freshVicious = nil
    saveNow()
    vicRangeSummary.Text = "Диапазон: " .. vicFrom .. "–" .. vicTo .. " звёзд (" .. VICIOUS_FIELD_NAMES[vicFrom] .. " — " .. VICIOUS_FIELD_NAMES[vicTo] .. ")"
end
makeStarRangeRow("ОТ ЗВЕЗДЫ", 3, vicFrom, function(value)
    vicFrom = value
    saveViciousRange()
end)
makeStarRangeRow("ДО ЗВЕЗДЫ", 4, vicTo, function(value)
    vicTo = value
    saveViciousRange()
end)
saveViciousRange()
local vicInfo = new("TextLabel", {
    Size = UDim2.new(1, 0, 0, 58), BackgroundColor3 = C.card,
    Text = "🐝  Дикий шип торчит из земли ночью. Даёт Стинжеры.",
    TextColor3 = C.dim, Font = Enum.Font.Gotham, TextSize = 11,
    TextWrapped = true, TextXAlignment = Enum.TextXAlignment.Left,
    TextYAlignment = Enum.TextYAlignment.Center,
    BorderSizePixel = 0, LayoutOrder = 2, Parent = PAGE_VICIOUS,
})
round(vicInfo, 12)
stroke(vicInfo)
new("UIPadding", { PaddingLeft = UDim.new(0, 12), PaddingRight = UDim.new(0, 12), Parent = vicInfo })

section("НАЙДЕНО", 10).Parent = PAGE_VICIOUS
local vicStats = new("Frame", {
    Size = UDim2.new(1, 0, 0, 50), BackgroundColor3 = C.card,
    BorderSizePixel = 0, LayoutOrder = 11, Parent = PAGE_VICIOUS,
})
round(vicStats, 12)
stroke(vicStats)
local vicMetric = new("TextLabel", {
    Size = UDim2.new(1, -24, 1, 0), Position = UDim2.new(0, 12, 0, 0),
    BackgroundTransparency = 1, Text = "Vicious ещё не найдено",
    TextColor3 = C.dim, Font = Enum.Font.GothamBold, TextSize = 12,
    TextXAlignment = Enum.TextXAlignment.Left,
    TextYAlignment = Enum.TextYAlignment.Center, Parent = vicStats,
})

-- ══════════════════════════════════════════════════════════════════════
--  PUFFSHROOMS
-- ══════════════════════════════════════════════════════════════════════
local PAGE_PUFF = new("Frame", {
    Size = UDim2.new(1, 0, 0, 0),
    AutomaticSize = Enum.AutomaticSize.Y,
    BackgroundTransparency = 1, Visible = false, Parent = content,
})
new("UIListLayout", {
    SortOrder = Enum.SortOrder.LayoutOrder, Padding = UDim.new(0, 8),
    Parent = PAGE_PUFF,
})
section("ПОИСК PUFFSHROOMS", 1).Parent = PAGE_PUFF
makeToggle(PAGE_PUFF, "Искать Puffshrooms", CONFIG.CHECK_PUFFSHROOMS, 3, function(v)
    CONFIG.CHECK_PUFFSHROOMS = v; saveNow()
end)

section("МИНИМАЛЬНАЯ РЕДКОСТЬ PUFFSHROOM", 4).Parent = PAGE_PUFF
local puffRarityOrder = { "common","rare","epic","legendary","mythic" }
local puffRarityLabels = { common="Common", rare="Rare", epic="Epic", legendary="Legendary", mythic="Mythic" }
local puffRarityColors = {
    common=Color3.fromRGB(130,220,135), rare=Color3.fromRGB(90,180,255),
    epic=Color3.fromRGB(180,115,255), legendary=Color3.fromRGB(255,190,75),
    mythic=Color3.fromRGB(255,95,180),
}
local puffRarityRow = new("Frame", {
    Size = UDim2.new(1, 0, 0, 36), BackgroundTransparency = 1,
    LayoutOrder = 5, Parent = PAGE_PUFF,
})
new("UIListLayout", {
    FillDirection = Enum.FillDirection.Horizontal,
    Padding = UDim.new(0, 6), Parent = puffRarityRow,
})
local puffRarityButtons = {}
local function paintPuffRarity()
    for _, rarityName in ipairs(puffRarityOrder) do
        local button = puffRarityButtons[rarityName]
        local selected = CONFIG.PUFF_MIN_RARITY == rarityName
        button.BackgroundColor3 = selected and C.cardHi or C.field
        button.TextColor3 = puffRarityColors[rarityName]
        local outline = button:FindFirstChildOfClass("UIStroke")
        if outline then outline.Thickness = selected and 2 or 1 end
    end
end
for index, rarityName in ipairs(puffRarityOrder) do
    local button = new("TextButton", {
        Size = UDim2.new(0.2, -5, 1, 0),
        BackgroundColor3 = C.field, Text = puffRarityLabels[rarityName],
        TextColor3 = puffRarityColors[rarityName], Font = Enum.Font.GothamBold,
        TextSize = 10, AutoButtonColor = false, BorderSizePixel = 0,
        LayoutOrder = index, Parent = puffRarityRow,
    })
    round(button, 8)
    stroke(button, puffRarityColors[rarityName], 1)
    puffRarityButtons[rarityName] = button
    button.MouseButton1Click:Connect(function()
        CONFIG.PUFF_MIN_RARITY = rarityName
        paintPuffRarity(); saveNow()
    end)
end
if not PUFF_RARITY_PRIORITY[CONFIG.PUFF_MIN_RARITY] then CONFIG.PUFF_MIN_RARITY = "common" end
paintPuffRarity()

-- ══════════════════════════════════════════════════════════════════════
--  ПЕРЕКЛЮЧЕНИЕ РАЗДЕЛОВ
-- ══════════════════════════════════════════════════════════════════════
local pages = {
    main = PAGE_HOME,
    sprouts = PAGE_SPROUTS,
    settings = pageSettings,
    vicious = PAGE_VICIOUS,
    puffshrooms = PAGE_PUFF,
}

local settingsOpen = false

showPage = function(which)
    if not pages[which] then which = "main" end
    for key, pg in pairs(pages) do pg.Visible = (key == which) end
    settingsOpen = (which == "settings")
    for key, t in pairs(tabButtons) do
        local on = (key == which)
        t.bar.Visible = on
        t.btn.BackgroundColor3 = on and C.cardHi or C.panel
        t.icon.TextColor3 = on and C.accent or C.dim
        t.label.TextColor3 = on and C.text or C.dim
    end
    content.CanvasPosition = Vector2.new(0, 0)
    refresh()
end

for key, t in pairs(tabButtons) do
    if not t.locked then
        t.btn.MouseButton1Click:Connect(function()
            if not isOpen then setWindow(true) end
            showPage(key)
        end)
    end
end

gearBtn.MouseButton1Click:Connect(function()
    if not isOpen then setWindow(true) end
    showPage("settings")
end)

snake.MouseButton1Click:Connect(function() Hopper.Toggle() end)

local function openMenu()
    if not isOpen then setWindow(true) end
    showPage("main")
end

snake.MouseButton2Click:Connect(openMenu)

UserInputService.InputBegan:Connect(function(input, processed)
    if processed then return end
    if input.UserInputType ~= Enum.UserInputType.MouseButton2 then return end
    local ok, center = pcall(function()
        return snake.AbsolutePosition + snake.AbsoluteSize/2
    end)
    if not ok or not center then return end
    local radius = math.max(snake.AbsoluteSize.X, snake.AbsoluteSize.Y)/2 + 8
    if (input.Position - center).Magnitude <= radius then openMenu() end
end)

UserInputService.InputBegan:Connect(function(inp, gpe)
    if gpe then return end
    if inp.KeyCode == Enum.KeyCode.Escape and isOpen then setWindow(false) end
    if inp.KeyCode == Enum.KeyCode.F then openMenu() end
    if inp.KeyCode == Enum.KeyCode.P then Hopper.Toggle() end
end)

closeBtn.MouseButton1Click:Connect(function() setWindow(false) end)

setWindow = function(show)
    isOpen = show
    TweenService:Create(win,
        TweenInfo.new(0.3, Enum.EasingStyle.Quart,
            show and Enum.EasingDirection.Out or Enum.EasingDirection.In),
        { Size = UDim2.new(0, WIN_W, 0, show and WIN_H or HEADER_H) }):Play()
    sidebar.Visible = show
    content.Visible = show
    hint.Text = show and "ЛКМ — вкл/выкл   •   ПКМ/F — меню"
        or "Нажми на заголовок чтобы развернуть"
    uiState.winOpen = show
    saveNow()
end

snake:GetPropertyChangedSignal("Position"):Connect(function()
    uiState.snakePos = snake.Position
    saveNow()
end)

local function rememberWinPos()
    local cam = workspace.CurrentCamera
    local viewX = cam and cam.ViewportSize.X or 1920
    local viewY = cam and cam.ViewportSize.Y or 1080
    uiState.winPos = UDim2.new(
        win.Position.X.Scale,
        math.max(0, math.min(win.Position.X.Offset, viewX - WIN_W)),
        win.Position.Y.Scale,
        math.max(0, math.min(win.Position.Y.Offset, viewY - 60))
    )
    saveNow()
end

do
    local dragging, dragInput, dragStart, startPos
    head.InputBegan:Connect(function(inp)
        if inp.UserInputType == Enum.UserInputType.MouseButton1
            or inp.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            dragStart = inp.Position
            startPos = win.Position
            inp.Changed:Connect(function()
                if inp.UserInputState == Enum.UserInputState.End then
                    dragging = false
                    rememberWinPos()
                end
            end)
        end
    end)
    head.InputChanged:Connect(function(inp)
        if inp.UserInputType == Enum.UserInputType.MouseMovement
            or inp.UserInputType == Enum.UserInputType.Touch then
            dragInput = inp
        end
    end)
    UserInputService.InputChanged:Connect(function(inp)
        if dragging and inp == dragInput then
            local d = inp.Position - dragStart
            win.Position = UDim2.new(
                startPos.X.Scale, startPos.X.Offset + d.X,
                startPos.Y.Scale, startPos.Y.Offset + d.Y)
        end
    end)
end

refresh = function()
    for k, v in pairs(modeButtons) do
        local on = (k == lastMode and Hopper.Mode ~= nil)
        v.bar.Visible = on
        v.btn.BackgroundColor3 = on and C.cardHi or C.card
        v.title.TextColor3 = on and C.accent or C.text
        if v.outline then
            v.outline.Color = on and C.accent2 or Color3.fromRGB(55,72,79)
            v.outline.Thickness = on and 1.5 or 1
            v.outline.Transparency = on and 0.05 or 0.22
        end
    end

    dot.BackgroundColor3 = Hopper.Mode and C.accent or C.danger
    if readyPill then
        local pillLabel = readyPill:FindFirstChildWhichIsA("TextLabel")
        if pillLabel then
            local text = Hopper.Mode and "Система активна" or "Система готова"
            if _G.BSS_BYPASS_ACTIVE and text == "Система готова" then
                text = "Bypass активен"
            end
            pillLabel.Text = text
            pillLabel.TextColor3 = Hopper.Mode and C.accent or C.dim
        end
    end

    local meta = MODE_META[lastMode]
    if Hopper.Mode and meta then
        subTitle.Text = meta.icon .. "  " .. meta.name .. " — " .. meta.desc
        subTitle.TextColor3 = C.accent
    else
        subTitle.Text = "Выключено — ЛКМ по змейке чтобы включить"
        subTitle.TextColor3 = C.dim
    end

    if not Hopper.Mode then
        statusVal.Text = "Остановлено"
        statusVal.TextColor3 = C.dim
        lastVal.Text = "—"
        lastVal.TextColor3 = C.dim
        return
    end

    local s = Hopper.Mode:GetStats()
    local st = s.currentStatus or ""

    if vicMetric then
        local vf = s.viciousFound or 0
        if vf > 0 then
            local lv = s.lastVicious
            vicMetric.Text = string.format("Найдено Vicious: %d   •   последнее: %s (%s)",
                vf, tostring(lv and lv.fieldName or "?"),
                tostring(lv and lv.kind or "?"))
            vicMetric.TextColor3 = C.accent
        else
            vicMetric.Text = "Vicious ещё не найдено"
            vicMetric.TextColor3 = C.dim
        end
    end

    if settingsOpen then return end

    statusVal.Text = st
    statusVal.TextColor3 = (string.find(st,"Ошибка",1,true)
        or string.find(st,"не дошёл",1,true)) and C.danger or C.accent

    if s.lastTask then
        lastVal.Text = string.format("%s   •   %s   •   %ds назад",
            tostring(s.lastTask.fieldName or "?"),
            tostring(s.lastTask.jobId or ""):sub(1, 14),
            s.lastTask.age or 0)
        lastVal.TextColor3 = C.warn
    elseif s.lastSprout then
        lastVal.Text = tostring(s.lastSprout.fieldName or "спрут")
        lastVal.TextColor3 = C.accent
    else
        lastVal.Text = "Пока нет данных"
        lastVal.TextColor3 = C.dim
    end
end

task.spawn(function()
    local lastWatch = 0
    while gui and gui.Parent do
        if not alive() then return end
        refresh()
        if Hopper.Mode and os.clock() - lastWatch >= 3 then
            lastWatch = os.clock()
            pcall(Hopper.Supervise)
        end
        task.wait(0.5)
    end
end)
end)

if not guiOk then showFatal(guiErr) end

-- ══════════════════════════════════════════════════════════════════════
--  СТАРТ
-- ══════════════════════════════════════════════════════════════════════
local function boot()
    Hopper.OnModeChanged = function(mode)
        if VALID_MODES[mode] then
            lastMode = mode
            CONFIG.MODE = mode
        end
        showPage("main")
        local accentColor = (C and C.accent) or Color3.fromRGB(70,220,145)
        local normalTextColor = (C and C.text) or Color3.fromRGB(210,218,230)
        for k, v in pairs(modeButtons or {}) do
            if v then
                if v.bar then v.bar.Visible = (k == mode) end
                if v.title then
                    v.title.TextColor3 = (k == mode) and accentColor or normalTextColor
                end
            end
        end
        refresh()
    end

    CONFIG.AUTO_START = true
    local startMode = lastMode
    if not Hopper.instances[startMode] then startMode = CONFIG.MODE end
    if not Hopper.instances[startMode] then startMode = "searcher" end
    Hopper.SwitchMode(startMode, true)
    saveNow()

    isOpen = true
    setWindow(true)
end

local okBoot, errBoot = pcall(boot)
if not okBoot then
    log("ERR", "Ошибка запуска: " .. tostring(errBoot))
    if Hopper.OnModeChanged then pcall(function() Hopper.OnModeChanged("off") end) end
end

trace("Запуск завершён")

print("=====================================================")
print("  BSS HOPPER v1.3.43 ЗАГРУЖЕН")
print("  Bypass  : " .. (_G.BSS_BYPASS_ACTIVE and "session_bypass.lua" or "встроенный"))
print("  Тег     : " .. tostring(CONFIG.SELF_TAG))
print("  Бот     : " .. tostring(CONFIG.API_URL))
print("  ЛКМ змейка — вкл/выкл | ПКМ/F — меню | P — вкл/выкл")
print("=====================================================")

_G.BSS_Hopper = {
    Switch = Hopper.SwitchMode,
    Toggle = Hopper.Toggle,
    Open = function() setWindow(true) showPage("main") end,
    Close = function() setWindow(false) end,
    Save = saveNow,
    Mode = function() return lastMode end,
    Destroy = stopEverything,
    Config = CONFIG,
    Bypass = _G.ExtraHopBypass,
}