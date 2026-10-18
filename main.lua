--[[
═══════════════════════════════════════════════════════════════════════
  🐍 BSS HOPPER v1.3.89 Standby Solo Farm for Looter
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

function bypassNotify()
    if bypassActive and Bypass.Notify then
        pcall(Bypass.Notify, Bypass)
    end
end

function bypassRecover(reason)
    if bypassActive and Bypass.Recover then
        pcall(Bypass.Recover, Bypass, reason)
    end
end

-- ──────────────────────────────────────────────────────────────────────
--  1.1 ЧИСТАЯ ПЕРСИСТЕНТНОСТЬ В ПАМЯТИ (QUEUE_ON_TELEPORT & BYPASS 267)
--  Скрипт остается заинжекченным при перезаходе БЕЗ участия autoexec!
-- ──────────────────────────────────────────────────────────────────────
local queueOnTeleport = (syn and syn.queue_on_teleport)
    or queue_on_teleport
    or (fluxus and fluxus.queue_on_teleport)
    or (identifyexecutor and queue_on_teleport)
    or queueonteleport

-- Читаем исходный код скрипта из файла (если доступен), чтобы передать его целиком в память экзекутора
local cachedScriptSource = nil
pcall(function()
    if isfile and readfile then
        local candidates = {
            "BSS_HOPPER_v1.3.33_hard_stop_toggle.lua",
            "BSS_HOPPER_v1.3.33_hard_stop_toggle (1).lua",
            "Hopper.lua",
            "bss_hopper.lua",
            "bss_hopper_autorun.lua",
            "Bss_hop/Hopper.lua",
            "Bss_hop/BSS_HOPPER_v1.3.33_hard_stop_toggle.lua",
            "BSS_HOPPER_v1.3.34_sprout_claim_loot_fix.lua"
        }
        for _, fname in ipairs(candidates) do
            if isfile(fname) then
                local ok, content = pcall(readfile, fname)
                if ok and content and #content > 5000 and string.find(content, "BSS_HOPPER", 1, true) then
                    cachedScriptSource = content
                    break
                end
            end
        end
    end
end)

local PERSIST_PAYLOAD = [==[
task.spawn(function()
    repeat task.wait(0.5) until game:IsLoaded()

    -- 1. Инициализация Session Lock Bypass Engine на новом сервере
    pcall(function()
        local Bypass = _G.ExtraHopBypass
        if not Bypass then
            if isfile and isfile("session_bypass.lua") then
                Bypass = loadstring(readfile("session_bypass.lua"))()
            elseif isfile and isfile("Bss_hop/session_bypass.lua") then
                Bypass = loadstring(readfile("Bss_hop/session_bypass.lua"))()
            end
            if Bypass and Bypass.init then pcall(function() Bypass:init() end) end
            _G.ExtraHopBypass = Bypass
        end
    end)

    -- 2. Автозапуск скрипта BSS Hopper прямо из памяти экзекутора
    local loaded = false
    if isfile and readfile then
        local candidates = {
            "BSS_HOPPER_v1.3.33_hard_stop_toggle.lua",
            "BSS_HOPPER_v1.3.33_hard_stop_toggle (1).lua",
            "Hopper.lua",
            "bss_hopper.lua",
            "bss_hopper_autorun.lua",
            "Bss_hop/Hopper.lua",
            "Bss_hop/BSS_HOPPER_v1.3.33_hard_stop_toggle.lua",
            "BSS_HOPPER_v1.3.34_sprout_claim_loot_fix.lua"
        }
        for _, fname in ipairs(candidates) do
            if isfile(fname) then
                local ok, code = pcall(readfile, fname)
                if ok and code and #code > 2000 and string.find(code, "BSS_HOPPER", 1, true) then
                    local fn, err = loadstring(code)
                    if fn then
                        task.spawn(fn)
                        loaded = true
                        break
                    end
                end
            end
        end
    end

    -- 3. Резервный вызов через Bypass Engine
    if not loaded then
        pcall(function()
            if _G.ExtraHopBypass and _G.ExtraHopBypass.Run then
                _G.ExtraHopBypass:Run()
            end
        end)
    end
end)
]==]

local saveNow, applySettings

function armTeleportPersistence()
    if applySettings then pcall(applySettings) end
    if saveNow then pcall(saveNow) end

    local cfgPrefix = ""
    pcall(function()
        if CONFIG and SAVED_KEYS and HttpService then
            local data = {}
            for _, key in ipairs(SAVED_KEYS) do data[key] = CONFIG[key] end
            if lastMode then data.LAST_ACTIVE_MODE = lastMode end
            local json = HttpService:JSONEncode(data)
            if json and json ~= "" then
                cfgPrefix = "pcall(function() _G.BSS_HOPPER_PERSIST_CONFIG = [==[" .. json .. "]==] end)\n"
            end
        end
    end)

    local payload = cfgPrefix .. (cachedScriptSource or PERSIST_PAYLOAD)
    local okQueue = false
    if type(queueOnTeleport) == "function" then
        local ok = pcall(queueOnTeleport, payload)
        if ok then okQueue = true end
    end
    if bypassActive then
        if Bypass.Queue then pcall(Bypass.Queue, Bypass, payload) end
        if Bypass.Persist then pcall(Bypass.Persist, Bypass) end
        if Bypass.ArmTeleport then pcall(Bypass.ArmTeleport, Bypass) end
    end
    return okQueue
end

-- Хуки перехвата на уровне игры (MetaMethod & Function Hooks)
-- Перехватывают вызов Kick (ошибка 267) и любые Teleport напрямую в памяти!
pcall(function()
    if hookmetamethod and typeof(game) == "Instance" then
        local oldNamecall
        oldNamecall = hookmetamethod(game, "__namecall", function(self, ...)
            local method = getnamecallmethod()
            if (method == "Kick" or method == "kick") and (self == player or self == game:GetService("Players").LocalPlayer) then
                armTeleportPersistence()
                task.spawn(function()
                    task.wait(0.5)
                    if rejoinSame then rejoinSame() end
                end)
                return nil
            end
            return oldNamecall(self, ...)
        end)
    end
end)

-- Сразу вооружаем очередь телепорта в памяти экзекутора
armTeleportPersistence()

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
function trace(msg)
    STEP += 1
    print(string.format("[ШАГ %02d] %s", STEP, msg))
end
trace("Скрипт стартовал")

_G.BSS_FATAL = nil
function showFatal(msg)
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
    ALLOWED_SPROUT_RARITIES = {
        basic = true,
        moon = true,
        rare = true,
        gummy = true,
        epic = true,
        legendary = true,
        supreme = true,
    },
    PLACE_ID = 1537690962,

    HOP_DELAY = 0.05, POLL_INTERVAL = 3, BROKEN_WAIT = 20,
    INITIAL_CHECK = 0.05, REPORT_DELAY = 0.2,
    CONNECT_TIMEOUT = 12, MAX_ATTEMPTS = 3, FAILED_TTL = 600,

    DEBUG_SPROUT = true, CHECK_VICIOUS = true, CHECK_SPROUTS = true,
    AUTO_START = true,

    WALK_SPEED_MULT = 5.625, FLY_SPEED = 100, JUMP_POWER = 60,

    BACKPACK_FILL_THRESHOLD = 0.95, HONEY_MAX_WAIT = 45,

    TOKEN_SCAN_INTERVAL = 0.14, TOKEN_PATROL_TIME = 20,
    FARM_REGION = "center", -- center / left / right
    ANTI_LAG = true,
    SUPER_OPTIMIZE = false,
    DISABLE_3D_RENDERING = false,
    AVOID_FRIENDS = true,
    ENABLE_AUTO_SPRINKLER = true, SPRINKLER_COUNT = 3,

    SPRINKLER_KEYWORD = "sprinkler", DIG_TOOL_KEYWORD = "scooper",
    ENABLE_AUTO_DIG = true,
    FALLBACK_FARM_FIELD = "None",
    IGNORE_TREAT_TOKENS = false,

    EMPTY_SLOT_KEYWORD = "claim hive", MY_HIVE_KEYWORD = "make honey",
    CLAIM_TIMEOUT = 8, CLAIM_APPROACH = 6, CLAIM_PROMPT_WAIT = 6,

    -- Bypass
    ENABLE_BYPASS = true, BYPASS_RETRY = 5,

    PUFF_MIN_LEVEL_COMMON=0, PUFF_MIN_LEVEL_RARE=0,
    PUFF_MIN_LEVEL_EPIC=0, PUFF_MIN_LEVEL_LEGENDARY=0, PUFF_MIN_LEVEL_MYTHIC=0,
    PUFF_MIN_LEVEL = 1,
    PUFF_MAX_LEVEL = 20,
    PUFF_AUTO_BOOST_EPIC = true,
    PUFF_SELECTED_BOOSTS = {
        ["Glitter"] = true,
        ["Red Extract"] = true,
        ["Blue Extract"] = true,
        ["Oil"] = true,
        ["Enzymes"] = true,
        ["Glue"] = true,
        ["Tropical Drink"] = true,
        ["Purple Potion"] = true,
        ["Super Smoothie"] = true,
    },
    CHECK_METEORS = true,
    CHECK_WINDY = true,
    WINDY_HOVER_HEIGHT = 32,
    AUTO_HARVEST_PLANTERS = true,
    SHOW_PLANTER_HUD = true,
    PLANTER_HUD_COLLAPSED = false,
    PLANTERS_CONFIG = {
        ["Paper Planter"] = { enabled = false, field = "Sunflower Field", percent = 100 },
        ["Plastic Planter"] = { enabled = false, field = "Dandelion Field", percent = 100 },
        ["Candy Planter"] = { enabled = false, field = "Stump Field", percent = 100 },
        ["Tacky Planter"] = { enabled = false, field = "Dandelion Field", percent = 100 },
        ["Pesticide Planter"] = { enabled = false, field = "Spider Field", percent = 100 },
        ["Red Clay Planter"] = { enabled = false, field = "Strawberry Field", percent = 100 },
        ["Blue Clay Planter"] = { enabled = false, field = "Pine Tree Forest", percent = 100 },
        ["Petal Planter"] = { enabled = false, field = "Coconut Field", percent = 100 },
        ["Hydroponic Planter"] = { enabled = false, field = "Pine Tree Forest", percent = 100 },
        ["Heat-Treated Planter"] = { enabled = false, field = "Pepper Patch", percent = 100 },
        ["Ticket Planter"] = { enabled = false, field = "Clover Field", percent = 100 },
        ["Sticker Planter"] = { enabled = false, field = "Dandelion Field", percent = 100 },
        ["Festive Planter"] = { enabled = false, field = "Mountain Top Field", percent = 100 },
        ["The Planter of Plenty"] = { enabled = false, field = "Pine Tree Forest", percent = 100 },
    },
    DISCORD_WEBHOOK_URL = "",
    TELEGRAM_BOT_TOKEN = "",
    TELEGRAM_CHAT_ID = "",
    SMOOTH_MOVEMENT = true,

    -- Burst-сбор, фильтрация серверов и кастомные приоритеты токенов
    BURST_LOOT_ENABLED = true,
    BURST_LOOT_TIME = 7,
    PREFER_LOW_PLAYERS = true,
    MAX_PLAYERS = 5,
    MIN_PLAYERS = 2,
    TOKEN_PRIORITIES = {},
    PERIODIC_REPORT_ENABLED = true,
    PERIODIC_REPORT_INTERVAL = 15,
}

local SAVE_FILE = "bss_hopper_config.json"
local uiState = { snakePos = nil, winPos = nil }
local lastMode = "searcher"

function packPosition(pos)
    if not pos then return nil end
    return { xScale=pos.X.Scale, xOffset=pos.X.Offset,
             yScale=pos.Y.Scale, yOffset=pos.Y.Offset }
end
function unpackPosition(pos)
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
function alive() return rawget(_G, "BSS_HOPPER_TOKEN") == MY_TOKEN end

local myConns = {}
function trackConn(conn)
    if conn then table.insert(myConns, conn) end
    return conn
end

function safeConnect(obj, signal, fn, name)
    local ok = pcall(function() trackConn(obj[signal]:Connect(fn)) end)
    if not ok and log then pcall(log, "TP", "Не удалось подписаться: " .. tostring(name or signal)) end
end

-- Hold primary mouse button while the hopper is enabled. This uses the executor's
-- input bridge when available; tool:Activate() remains the fallback for harvesting.
local leftMouseHeld = false
local isConvertingHoney = false
function setLeftMouseHeld(shouldHold)
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

function stopEverything()
    pcall(function() setLeftMouseHeld(false) end)
    if type(Hopper) == "table" and Hopper.Mode then
        pcall(function() Hopper.Mode:Stop() end)
    end
    for _, c in ipairs(myConns) do pcall(function() c:Disconnect() end) end
    myConns = {}
    pcall(function() if gui then gui:Destroy() end end)
end

function log(tag, msg)
    print(string.format("[BSS Hopper][%s][%.1f] %s", tostring(tag), os.clock(), tostring(msg)))
end

-- Защита от 20-минутного AFK-кика Roblox (Anti-AFK)
pcall(function()
    trackConn(player.Idled:Connect(function()
        pcall(function()
            local vu = game:GetService("VirtualUser")
            if vu then
                vu:CaptureController()
                vu:ClickButton2(Vector2.zero)
            end
        end)
    end))
end)

-- ══════════════════════════════════════════════════════════════════════
--  СОХРАНЕНИЕ
-- ══════════════════════════════════════════════════════════════════════
local HAS_FS = (type(writefile) == "function") and (type(readfile) == "function")
local PERSIST_ENV = _G
pcall(function() if type(getgenv) == "function" then PERSIST_ENV = getgenv() end end)

local SAVED_KEYS = {
    "MODE","API_URL","API_KEY","SELF_TAG","VICIOUS_CHANNEL_ID","VICIOUS_FIELD_FROM","VICIOUS_FIELD_TO","FIXED_LEVEL","MIN_RARITY","ALLOWED_SPROUT_RARITIES",
    "PLACE_ID","HOP_DELAY","POLL_INTERVAL","BROKEN_WAIT","INITIAL_CHECK",
    "REPORT_DELAY","CONNECT_TIMEOUT","MAX_ATTEMPTS","FAILED_TTL",
    "DEBUG_SPROUT","AUTO_START","CHECK_VICIOUS","CHECK_SPROUTS","CHECK_PUFFSHROOMS",
    "PUFFSHROOM_CHANNEL_ID","PUFF_MIN_RARITY","PUFF_MIN_LEVEL_COMMON","PUFF_MIN_LEVEL_RARE",
    "PUFF_MIN_LEVEL_EPIC","PUFF_MIN_LEVEL_LEGENDARY","PUFF_MIN_LEVEL_MYTHIC",
    "WALK_SPEED_MULT","FLY_SPEED","JUMP_POWER","BACKPACK_FILL_THRESHOLD","HONEY_MAX_WAIT",
    "TOKEN_SCAN_INTERVAL","TOKEN_PATROL_TIME","FARM_REGION","ANTI_LAG","SUPER_OPTIMIZE","DISABLE_3D_RENDERING","AVOID_FRIENDS","SPRINKLER_KEYWORD","DIG_TOOL_KEYWORD",
    "ENABLE_AUTO_SPRINKLER","SPRINKLER_COUNT",
    "ENABLE_AUTO_DIG","FALLBACK_FARM_FIELD","IGNORE_TREAT_TOKENS","EMPTY_SLOT_KEYWORD","MY_HIVE_KEYWORD","CLAIM_TIMEOUT",
    "BURST_LOOT_ENABLED","BURST_LOOT_TIME","PREFER_LOW_PLAYERS","MAX_PLAYERS","MIN_PLAYERS","TOKEN_PRIORITIES",
    "CHECK_METEORS","CHECK_WINDY","WINDY_HOVER_HEIGHT","AUTO_HARVEST_PLANTERS","SHOW_PLANTER_HUD","PLANTER_HUD_COLLAPSED",
    "PLANTERS_CONFIG","PUFF_AUTO_BOOST_EPIC","PUFF_SELECTED_BOOSTS","PUFF_MIN_LEVEL","PUFF_MAX_LEVEL",
    "DISCORD_WEBHOOK_URL","TELEGRAM_BOT_TOKEN","TELEGRAM_CHAT_ID",
    "PERIODIC_REPORT_ENABLED","PERIODIC_REPORT_INTERVAL",
}

function applySavedData(data, source)
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

function loadSaved()
    pcall(function()
        if _G.BSS_HOPPER_PERSIST_CONFIG and _G.BSS_HOPPER_PERSIST_CONFIG ~= "" then
            local okD, d = pcall(function() return HttpService:JSONDecode(_G.BSS_HOPPER_PERSIST_CONFIG) end)
            if okD and type(d) == "table" then
                applySavedData(d, "память телепорта queue_on_teleport")
            end
        end
    end)
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

-- ══════════════════════════════════════════════════════════════════════
--  СИСТЕМА КОНФИГУРАЦИЙ И ПРИВЯЗКИ К НИКАМ (PROFILE / NICK-BIND ENGINE)
-- ══════════════════════════════════════════════════════════════════════
local CFG_PREFIX = "bss_hopper_cfg_"
local BIND_FILE = "bss_hopper_nick_binds.json"
local INDEX_FILE = "bss_hopper_cfg_list.json"
local currentActiveConfig = "default"
local nickBinds = {}
local syncGuiWithConfig = nil

local function loadNickBinds()
    if not HAS_FS then return {} end
    local ok, content = pcall(readfile, BIND_FILE)
    if ok and content and content ~= "" then
        local okJ, data = pcall(function() return HttpService:JSONDecode(content) end)
        if okJ and type(data) == "table" then
            nickBinds = data
            return nickBinds
        end
    end
    nickBinds = {}
    return nickBinds
end

local function saveNickBinds()
    if not HAS_FS then return false end
    local ok, json = pcall(function() return HttpService:JSONEncode(nickBinds) end)
    if ok and json then
        return pcall(writefile, BIND_FILE, json)
    end
    return false
end

local function getSavedConfigList()
    local list = {}
    local seen = {}
    local function add(name)
        if name and name ~= "" and not seen[name] then
            seen[name] = true
            table.insert(list, name)
        end
    end

    if HAS_FS then
        local ok, content = pcall(readfile, INDEX_FILE)
        if ok and content and content ~= "" then
            local okJ, arr = pcall(function() return HttpService:JSONDecode(content) end)
            if okJ and type(arr) == "table" then
                for _, n in ipairs(arr) do add(tostring(n)) end
            end
        end
        if type(listfiles) == "function" then
            pcall(function()
                for _, file in ipairs(listfiles("")) do
                    local name = string.match(tostring(file), "bss_hopper_cfg_([%w_%-]+)%.json$")
                    if name then add(name) end
                end
            end)
        end
    end
    add("default")
    table.sort(list)
    return list
end

local function saveConfigList(list)
    if not HAS_FS then return end
    pcall(function()
        local json = HttpService:JSONEncode(list)
        writefile(INDEX_FILE, json)
    end)
end

local function saveNamedConfig(cfgName)
    cfgName = string.gsub(tostring(cfgName or ""), "[^%w_%-]", "")
    if cfgName == "" then return false, "Введите корректное имя конфига!" end

    local data = {}
    for _, key in ipairs(SAVED_KEYS) do data[key] = CONFIG[key] end
    local valid = { searcher=true, looter=true, solo=true }
    data.MODE = valid[lastMode] and lastMode or (valid[CONFIG.MODE] and CONFIG.MODE or "searcher")
    data.LAST_ACTIVE_MODE = data.MODE
    data.snakePos = packPosition(uiState.snakePos)
    data.winPos = packPosition(uiState.winPos)
    data.winOpen = uiState.winOpen ~= false
    data.CONFIG_NAME = cfgName

    if not HAS_FS then
        pcall(function() PERSIST_ENV["BSS_HOPPER_CFG_" .. cfgName] = data end)
        currentActiveConfig = cfgName
        return true, "Конфиг '" .. cfgName .. "' сохранен в память!"
    end

    local encoded, json = pcall(function() return HttpService:JSONEncode(data) end)
    if not encoded then return false, "Ошибка кодирования JSON" end

    local ok = pcall(writefile, CFG_PREFIX .. cfgName .. ".json", json)
    if not ok then return false, "Ошибка записи файла" end

    local list = getSavedConfigList()
    local found = false
    for _, n in ipairs(list) do if n == cfgName then found = true; break end end
    if not found then table.insert(list, cfgName); saveConfigList(list) end

    currentActiveConfig = cfgName
    log("CFG", "Конфиг '" .. cfgName .. "' успешно сохранен на диск!")
    return true, "Конфиг '" .. cfgName .. "' успешно сохранен!"
end

local function loadNamedConfig(cfgName)
    cfgName = string.gsub(tostring(cfgName or ""), "[^%w_%-]", "")
    if cfgName == "" then return false, "Не указано имя конфига" end

    local data = nil
    if HAS_FS then
        local ok, content = pcall(readfile, CFG_PREFIX .. cfgName .. ".json")
        if ok and content and content ~= "" then
            local okJ, decoded = pcall(function() return HttpService:JSONDecode(content) end)
            if okJ and type(decoded) == "table" then
                data = decoded
            end
        end
    end

    if not data then
        pcall(function()
            local envData = PERSIST_ENV["BSS_HOPPER_CFG_" .. cfgName]
            if type(envData) == "table" then data = envData end
        end)
    end

    if not data then
        return false, "Конфиг '" .. cfgName .. "' не найден!"
    end

    applySavedData(data, "профиль " .. cfgName)
    currentActiveConfig = cfgName
    if syncGuiWithConfig then pcall(syncGuiWithConfig) end
    if refresh then pcall(refresh) end
    log("CFG", "Конфиг '" .. cfgName .. "' успешно загружен и применен!")
    return true, "Конфиг '" .. cfgName .. "' успешно загружен!"
end

local function deleteNamedConfig(cfgName)
    cfgName = string.gsub(tostring(cfgName or ""), "[^%w_%-]", "")
    if cfgName == "" or cfgName == "default" then return false, "Нельзя удалить стандартный конфиг" end

    if HAS_FS and type(delfile) == "function" then
        pcall(delfile, CFG_PREFIX .. cfgName .. ".json")
    end

    local list = getSavedConfigList()
    local newList = {}
    for _, n in ipairs(list) do
        if n ~= cfgName then table.insert(newList, n) end
    end
    saveConfigList(newList)

    log("CFG", "Конфиг '" .. cfgName .. "' удален")
    return true, "Конфиг '" .. cfgName .. "' удален"
end

local function bindNickToConfig(nick, cfgName)
    nick = string.gsub(tostring(nick or ""), "^%s*(.-)%s*$", "%1")
    cfgName = string.gsub(tostring(cfgName or ""), "[^%w_%-]", "")
    if nick == "" then return false, "Введите никнейм!" end
    if cfgName == "" then return false, "Введите имя конфига!" end

    loadNickBinds()
    nickBinds[string.lower(nick)] = cfgName
    saveNickBinds()
    log("CFG", string.format("Привязка сохранена: ник '%s' -> конфиг '%s'", nick, cfgName))
    return true, string.format("Ник '%s' привязан к конфигу '%s'!", nick, cfgName)
end

local function unbindNick(nick)
    nick = string.gsub(tostring(nick or ""), "^%s*(.-)%s*$", "%1")
    loadNickBinds()
    nickBinds[string.lower(nick)] = nil
    saveNickBinds()
    return true, "Привязка для ника '" .. nick .. "' удалена"
end

local function checkAutoLoadNickConfig()
    loadNickBinds()
    local myName = player and player.Name
    local myDisplay = player and player.DisplayName
    local targetCfg = (myName and nickBinds[string.lower(myName)])
                   or (myDisplay and nickBinds[string.lower(myDisplay)])
                   or (myName and nickBinds[myName])
    if targetCfg and targetCfg ~= "" then
        log("CFG", string.format("🎯 Найден привязанный конфиг '%s' для игрока '%s' (%s)! Авто-загрузка...", targetCfg, tostring(myName), tostring(myDisplay)))
        local ok, msg = loadNamedConfig(targetCfg)
        if ok then
            currentActiveConfig = targetCfg
        end
        return targetCfg
    end
    return nil
end

-- Авто-загрузка конфига по нику при инжекте
checkAutoLoadNickConfig()

-- ══════════════════════════════════════════════════════════════════════
--  СВЕРХ-ОПТИМИЗАЦИЯ (FPS BOOSTER & ОЧИСТКА ПАМЯТИ)
-- ══════════════════════════════════════════════════════════════════════
function applySuperOptimization(enabled)
    CONFIG.SUPER_OPTIMIZE = (enabled == true)
    pcall(function()
        local Lighting = game:GetService("Lighting")
        local Terrain = Workspace:FindFirstChildOfClass("Terrain")

        if CONFIG.SUPER_OPTIMIZE then
            Lighting.GlobalShadows = false
            Lighting.FogEnd = 9e9
            Lighting.Brightness = 1
            for _, effect in ipairs(Lighting:GetChildren()) do
                if effect:IsA("PostEffect") or effect:IsA("BloomEffect") or effect:IsA("BlurEffect")
                    or effect:IsA("ColorCorrectionEffect") or effect:IsA("DepthOfFieldEffect")
                    or effect:IsA("SunRaysEffect") then
                    effect.Enabled = false
                end
            end
            if Terrain then
                Terrain.WaterWaveSize = 0
                Terrain.WaterWaveSpeed = 0
                Terrain.WaterReflectance = 0
                Terrain.WaterTransparency = 1
                pcall(function() Terrain.Decoration = false end)
            end
            for _, obj in ipairs(Workspace:GetDescendants()) do
                if obj:IsA("ParticleEmitter") or obj:IsA("Smoke") or obj:IsA("Fire")
                    or obj:IsA("Sparkles") or obj:IsA("Trail") or obj:IsA("Beam") then
                    obj.Enabled = false
                elseif obj:IsA("Highlight") then
                    obj.Enabled = false
                elseif obj:IsA("BasePart") then
                    obj.CastShadow = false
                end
            end
            pcall(function() settings().Network.IncomingReplicationLag = 0 end)
            if type(setfpscap) == "function" then
                pcall(setfpscap, 999)
            end
            pcall(function() collectgarbage("collect") end)
            log("Оптимизация", "⚡ Ультра-оптимизация включена: тени, частицы и тяжелые эффекты отключены, FPS разблокирован!")
        else
            Lighting.GlobalShadows = true
            if Terrain then
                pcall(function() Terrain.Decoration = true end)
            end
            log("Оптимизация", "Оптимизация отключена: возвращена стандартная графика")
        end
    end)
end

-- Фоновая периодическая очистка мусора ОЗУ каждые 60 секунд
task.spawn(function()
    while alive() do
        task.wait(60)
        pcall(function() collectgarbage("collect") end)
    end
end)

-- Оптимизация графики клиента. Не удаляет игровые объекты/токены и не меняет логику фарма.
function applyAntiLag(enabled)
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
        else
            -- При выключении возвращаем базовую графику
            Lighting.GlobalShadows = true
        end
    end)
end
if CONFIG.ANTI_LAG then applyAntiLag(true) end
if CONFIG.SUPER_OPTIMIZE then applySuperOptimization(true) end

function apply3dRendering(disabled)
    CONFIG.DISABLE_3D_RENDERING = (disabled == true)
    pcall(function()
        local rs = game:GetService("RunService")
        rs:Set3dRenderingEnabled(not disabled)
    end)
end
if CONFIG.DISABLE_3D_RENDERING then apply3dRendering(true) end

saveNow = function()
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
function flushSettings()
    if applySettings then pcall(applySettings) end
    if saveNow then pcall(saveNow) end
end

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

function addFolder(path)
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

    -- Строго отсекаем любые плантеры (Pesticide Planter, Paper Planter и т.д.)
    local cur = obj
    while cur and cur ~= Workspace do
        local n = string.lower(cur.Name or "")
        if string.find(n, "planter", 1, true) then return false end
        cur = cur.Parent
    end

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

local watchedFolders = {}
function watchFolders()
    for _, p in ipairs({ "Particles.Folder2", "Happenings.Sprouts", "Sprouts" }) do
        addFolder(p)
    end
    for _, folder in ipairs(sproutFolders) do
        if not watchedFolders[folder] then
            watchedFolders[folder] = true
            pcall(function()
                trackConn(folder.ChildAdded:Connect(function(child)
                    if not alive() then return end
                    if isSprout(child) then freshSprout = child end
                end))
            end)
        end
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

function findSprout()
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

function isSproutAlive(sprout, anchorPos)
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

function _rawWorldPos(obj)
    if not obj then return nil end
    if obj:IsA("BasePart") then return obj.Position end
    if obj:IsA("Model") then
        local prim = obj.PrimaryPart
        if prim then return prim.Position end
        local ok, piv = pcall(function() return obj:GetPivot().Position end)
        if ok and piv then return piv end
    end
    local bp = obj:FindFirstChildWhichIsA("BasePart", true)
    if bp then return bp.Position end
    return nil
end

function worldPos(obj)
    if not obj then return nil end
    local ok, p = pcall(_rawWorldPos, obj)
    if ok and p then return p end
    return nil
end

function normalizeJobId(id)
    if type(id) ~= "string" then return "" end
    return string.lower(id):gsub("[{}]", ""):gsub("%s+", "")
end

local RunService = game:GetService("RunService")

-- Flight noclip: temporarily disable collision on character body parts only.
-- Original CanCollide values are restored after each flight segment.
local flightStopRequested = false
local noclipSteppedConn = nil
function setFlightNoclip(enabled)
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
                    local n = part.Name
                    if n == "Head" or n == "Torso" or n == "UpperTorso" or n == "LowerTorso" then
                        pcall(function() part.CanCollide = true end)
                    else
                        pcall(function() part.CanCollide = false end)
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

function stopFlightNow()
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

function getFieldForPos(pos, maxExtra)
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

-- Raycast down to find the exact top surface of the field (с защитой от проваливания под поле)
function getGroundPos(pos)
    if not pos then return pos end
    local ground = pos + Vector3.new(0, 3.2, 0)
    local zName, zone = getFieldForPos(pos, 35)
    local minAllowedY = (zone and (zone.Position.Y + (zone.Size.Y * 0.5))) or (pos.Y - 1.0)

    local ok, hit = pcall(function()
        local rayParams = RaycastParams.new()
        rayParams.FilterType = RaycastFilterType.Exclude
        local filterList = {}
        if player and player.Character then table.insert(filterList, player.Character) end
        local happens = Workspace:FindFirstChild("Happenings")
        if happens then table.insert(filterList, happens) end
        rayParams.FilterDescendantsInstances = filterList
        local origin = Vector3.new(pos.X, math.max(pos.Y + 45, minAllowedY + 45), pos.Z)
        return Workspace:Raycast(origin, Vector3.new(0, -90, 0), rayParams)
    end)
    if ok and hit and hit.Position then
        -- Не позволяем приземляться под поле в пещеру/пустоту
        if hit.Position.Y >= minAllowedY - 2.5 then
            ground = hit.Position + Vector3.new(0, 3.2, 0)
        else
            ground = Vector3.new(pos.X, minAllowedY + 3.2, pos.Z)
        end
    else
        ground = Vector3.new(pos.X, minAllowedY + 3.2, pos.Z)
    end
    return ground
end

function getFieldPart(fieldName)
    if not fieldName or fieldName == "" then return nil end
    local zones = Workspace:FindFirstChild("FlowerZones")
    if not zones then return nil end
    local clean = string.lower(fieldName):gsub("%s*field%s*", ""):gsub("%s*patch%s*", ""):gsub("%s*forest%s*", "")
    for _, z in ipairs(zones:GetChildren()) do
        local zn = string.lower(z.Name)
        if zn == string.lower(fieldName) or string.find(zn, clean, 1, true) then
            return z
        end
    end
    return nil
end

local isReroutingFlight = false

local UPPER_15_BEE_FIELDS = {
    ["pine tree forest"] = true,
    ["pumpkin patch"] = true,
    ["cactus field"] = true,
}

local LOWER_10_BEE_FIELDS = {
    ["pineapple patch"] = true,
    ["stump field"] = true,
}

function isUpper15BeeField(posOrName)
    if typeof(posOrName) == "string" then
        return UPPER_15_BEE_FIELDS[string.lower(posOrName)] == true
    end
    if typeof(posOrName) == "Vector3" then
        local fName = getFieldForPos(posOrName, 45)
        if fName then
            return UPPER_15_BEE_FIELDS[string.lower(fName)] == true
        end
    end
    return false
end

function isLower10BeeField(posOrName)
    if typeof(posOrName) == "string" then
        return LOWER_10_BEE_FIELDS[string.lower(posOrName)] == true
    end
    if typeof(posOrName) == "Vector3" then
        local fName = getFieldForPos(posOrName, 45)
        if fName then
            return LOWER_10_BEE_FIELDS[string.lower(fName)] == true
        end
    end
    return false
end

function needsMountainTopReroute(startPos, endPos)
    if not startPos or not endPos then return false end
    local aToB = isUpper15BeeField(startPos) and isLower10BeeField(endPos)
    local bToA = isLower10BeeField(startPos) and isUpper15BeeField(endPos)
    return aToB or bToA
end

-- Плавный покадровый полёт через стены: без проваливания под текстуры
function moveRootToPosition(root, destination, maxDuration)
    if not root or not root.Parent or typeof(destination) ~= "Vector3" then return false end
    flightStopRequested = false

    local startPos = root.Position

    -- Безопасный облёт через Mountain Top Field (над пещерой со смертоносным пауком/оборотнем)
    if not isReroutingFlight and needsMountainTopReroute(startPos, destination) then
        local mtnPart = getFieldPart("Mountain Top Field")
        local mtnPos = mtnPart and (mtnPart.Position + Vector3.new(0, 25, 0)) or Vector3.new(76, 195, -178)
        log("Маршрут", "🏔️ Безопасный перелёт через Mountain Top Field (облёт пещеры с мобом)!")
        isReroutingFlight = true
        moveRootToPosition(root, mtnPos, (maxDuration or 12) * 0.55)
        isReroutingFlight = false
        if not alive() or flightStopRequested then return false end
        return moveRootToPosition(root, destination, (maxDuration or 12) * 0.55)
    end

    -- Защита от полета под текстуры: проверяем, не направлена ли цель под поле
    local zName, zone = getFieldForPos(destination, 35)
    if zone then
        local minSurfaceY = zone.Position.Y + (zone.Size.Y * 0.5) + 3.2
        if destination.Y < zone.Position.Y - 1.5 then
            destination = Vector3.new(destination.X, minSurfaceY, destination.Z)
        end
    end

    setFlightNoclip(true)
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

    local speed = tonumber(CONFIG.FLY_SPEED) or 55
    local duration = math.clamp(distance / speed, 0.25, maxDuration or 12)
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

function waitForGameReady(timeout, fastMode)
    local t0 = os.clock()
    timeout = timeout or 25
    local isSearcher = fastMode or (Hopper and Hopper.Mode == "searcher") or (CONFIG and CONFIG.MODE == "searcher")
    while not game:IsLoaded() and os.clock() - t0 < timeout do
        if not alive() then return end
        task.wait(0.05)
    end
    while os.clock() - t0 < timeout do
        if not alive() then return end
        local char = player.Character
        local root = char and char:FindFirstChild("HumanoidRootPart")
        local hum = char and char:FindFirstChildOfClass("Humanoid")
        if root and hum and hum.Health > 0 then
            local zones = Workspace:FindFirstChild("FlowerZones")
            if zones and #zones:GetChildren() > 5 then
                break
            end
        end
        task.wait(isSearcher and 0.05 or 0.2)
    end
    if alive() then
        if isSearcher then
            task.wait(0.05)
        else
            task.wait(1.2)
        end
    end
end

function waitForRespawn(timeout)
    timeout = timeout or 8
    local t0 = os.clock()
    while alive() and (os.clock() - t0 < timeout) do
        local c = player.Character
        local h = c and c:FindFirstChildOfClass("Humanoid")
        local r = c and c:FindFirstChild("HumanoidRootPart")
        if c and h and r and h.Health > 0 then
            return c, r, h
        end
        task.wait(0.2)
    end
    local c = player.Character
    return c, c and c:FindFirstChild("HumanoidRootPart"), c and c:FindFirstChildOfClass("Humanoid")
end


-- ПОСТОЯННАЯ ФОНОВАЯ ЗАЩИТА ОТ ПРОВАЛИВАНИЯ ПОД ПОЛЕ
task.spawn(function()
    while true do
        if not alive() then return end
        task.wait(0.5)
        pcall(function()
            local char = player.Character
            local root = char and char:FindFirstChild("HumanoidRootPart")
            if root and root.Parent and lastActiveTargetPos then
                local zName, zone = getFieldForPos(lastActiveTargetPos, 40)
                if zone then
                    local minZoneY = zone.Position.Y - 2.5
                    if root.Position.Y < minZoneY and (Vector3.new(root.Position.X, zone.Position.Y, root.Position.Z) - zone.Position).Magnitude < (zone.Size.Magnitude * 0.65) then
                        root.AssemblyLinearVelocity = Vector3.zero
                        root.AssemblyAngularVelocity = Vector3.zero
                        local surfaceY = zone.Position.Y + (zone.Size.Y * 0.5) + 3.5
                        root.CFrame = CFrame.new(root.Position.X, surfaceY, root.Position.Z)
                        setFlightNoclip(false)
                    end
                end
            end
        end)
    end
end)

function moveToSprout(sprout)
    if not sprout then return false end
    local targetPos = worldPos(sprout) or lastActiveTargetPos
    if not targetPos then return false end
    lastActiveTargetPos = targetPos

    local char, root, hum = waitForRespawn(6)
    if not root or not hum or hum.Health <= 0 then return false end

    local safeLanding = getGroundPos(targetPos)
    local ok = moveRootToPosition(root, safeLanding, 10)
    return ok or ((root.Position - safeLanding).Magnitude < 25)
end

function getFieldForPos(pos, maxExtra)
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

function detectField(sprout)
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
lastActiveTargetPos = nil

function getCalculatedWalkSpeed(boostPriority)
    local mult = tonumber(CONFIG.WALK_SPEED_MULT) or 5.625
    local base = 16 * mult
    if base < 50 then base = 90 end -- быстрая скорость бега (90 studs/s) по требованию пользователя
    if boostPriority then
        return math.max(base * 1.2, 110)
    end
    return base
end

function applyWalkSpeed(boostPriority)
    local char = player.Character
    local hum = char and char:FindFirstChildOfClass("Humanoid")
    if hum and hum.Health > 0 then
        local targetSpd = getCalculatedWalkSpeed(boostPriority)
        if math.abs(hum.WalkSpeed - targetSpd) > 0.5 then
            hum.WalkSpeed = targetSpd
        end
        hum.JumpPower = tonumber(CONFIG.JUMP_POWER) or 60
        hum.UseJumpPower = true
    end
end

task.spawn(function()
    applyWalkSpeed()
    trackConn(player.CharacterAdded:Connect(function(newChar)
        task.wait(0.35)
        applyWalkSpeed()
        local newRoot = newChar:WaitForChild("HumanoidRootPart", 6)
        local newHum = newChar:WaitForChild("Humanoid", 6)
        if newRoot and newHum and lastActiveTargetPos and typeof(lastActiveTargetPos) == "Vector3" then
            local dist = (newRoot.Position - lastActiveTargetPos).Magnitude
            if dist > 45 and alive() and Hopper.Mode and Hopper.currentKey ~= "off" then
                log("Смерть", string.format("Персонаж возродился после гибели! Лечу обратно на рабочую позицию (%.0f ст.)...", dist))
                task.spawn(function()
                    task.wait(0.2)
                    local ground = getGroundPos(lastActiveTargetPos)
                    moveRootToPosition(newRoot, ground, 10)
                end)
            end
        end
        for _ = 1, 5 do
            if not alive() then return end
            applyWalkSpeed()
            task.wait(0.5)
        end
    end))
end)

-- ══════════════════════════════════════════════════════════════════════
--  PUFFSHROOMS
-- ══════════════════════════════════════════════════════════════════════
local PUFF_RARITY_PRIORITY = { common=1, rare=2, epic=3, legendary=4, mythic=5 }
local puffReported = {}

function puffTextOf(root)
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

function isPuffshroomRoot(obj)
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

function parsePuffshroom(root)
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

function findPuffshroomTimer(root)
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

function findPuffshrooms()
    local searchRoots = {}
    local h = Workspace:FindFirstChild("Happenings")
    if h then
        local hp = h:FindFirstChild("Puffshrooms")
        if hp then table.insert(searchRoots, hp) else table.insert(searchRoots, h) end
    end
    local p = Workspace:FindFirstChild("Puffshrooms")
    if p then table.insert(searchRoots, p) end
    if #searchRoots == 0 then return {} end

    local candidates, results, seen = {}, {}, {}
    for _, rootFolder in ipairs(searchRoots) do
        local ok, descendants = pcall(function() return rootFolder:GetDescendants() end)
        if ok and descendants then
            for _, obj in ipairs(descendants) do
                if isPuffshroomRoot(obj) then
                    if obj:IsA("Model") then table.insert(candidates, 1, obj)
                    else table.insert(candidates, obj) end
                end
            end
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


-- ══════════════════════════════════════════════════════════════════════
--  ВЕБХУКИ DISCORD & TELEGRAM
-- ══════════════════════════════════════════════════════════════════════
function sendDiscordWebhook(title, description, colorHex)
    local url = CONFIG.DISCORD_WEBHOOK_URL
    if not url or url == "" then return end
    local color = tonumber(colorHex or "00f5a0", 16) or 3447003
    local body = {
        embeds = {
            {
                title = "🐝 " .. tostring(title),
                description = tostring(description),
                color = color,
                footer = { text = "BSS Hopper • " .. os.date("%X") },
                timestamp = DateTime.now():ToIsoDate(),
            }
        }
    }
    task.spawn(function()
        local raw = HttpService:JSONEncode(body)
        local req = (syn and syn.request) or (http and http.request) or http_request or request
        if req then
            pcall(function()
                req({
                    Url = url, Method = "POST",
                    Headers = { ["Content-Type"] = "application/json" },
                    Body = raw
                })
            end)
        end
    end)
end

function sendTelegramMessage(text)
    local token = CONFIG.TELEGRAM_BOT_TOKEN
    local chatId = CONFIG.TELEGRAM_CHAT_ID
    if not token or token == "" or not chatId or chatId == "" then return end
    local url = string.format("https://api.telegram.org/bot%s/sendMessage", token)
    local body = {
        chat_id = chatId,
        text = "🐝 *BSS Hopper*\n" .. tostring(text),
        parse_mode = "Markdown",
    }
    task.spawn(function()
        local raw = HttpService:JSONEncode(body)
        local req = (syn and syn.request) or (http and http.request) or http_request or request
        if req then
            pcall(function()
                req({
                    Url = url, Method = "POST",
                    Headers = { ["Content-Type"] = "application/json" },
                    Body = raw
                })
            end)
        end
    end)
end

function notifyAllWebhooks(title, text, colorHex)
    sendDiscordWebhook(title, text, colorHex)
    sendTelegramMessage("*" .. tostring(title) .. "*\n" .. tostring(text))
end

-- ══════════════════════════════════════════════════════════════════════
--  ПЕРИОДИЧЕСКИЙ ОТЧЕТ О ДОБЫТЫХ РЕСУРСАХ (DISCORD & TELEGRAM)
-- ══════════════════════════════════════════════════════════════════════
local function formatNumber(n)
    local str = tostring(math.floor(math.abs(tonumber(n) or 0)))
    local formatted = str:reverse():gsub("(%d%d%d)", "%1,"):reverse():gsub("^,", "")
    return (n < 0 and "-" or "") .. formatted
end

local function getPlayerHoney()
    local ls = player:FindFirstChild("leaderstats")
    if ls then
        local h = ls:FindFirstChild("Honey")
        if h and typeof(h.Value) == "number" then return h.Value end
    end
    local cs = player:FindFirstChild("CoreStats")
    if cs then
        local h = cs:FindFirstChild("Honey")
        if h and typeof(h.Value) == "number" then return h.Value end
    end
    return 0
end

local LOOT_REPORT_STATS = {
    startTime = os.clock(),
    lastReportTime = os.clock(),
    startHoney = 0,
    lastHoney = 0,
    sprouts = 0,
    vicious = 0,
    windy = 0,
    meteors = 0,
    planters = 0,
    items = {},
    periodItems = {},
}

function recordLootItem(name, count)
    if not name or name == "" then return end
    count = count or 1
    LOOT_REPORT_STATS.items[name] = (LOOT_REPORT_STATS.items[name] or 0) + count
    LOOT_REPORT_STATS.periodItems[name] = (LOOT_REPORT_STATS.periodItems[name] or 0) + count
end

function sendPeriodicLootReport()
    if CONFIG.PERIODIC_REPORT_ENABLED == false then return end
    local hasDiscord = CONFIG.DISCORD_WEBHOOK_URL and CONFIG.DISCORD_WEBHOOK_URL ~= ""
    local hasTg = CONFIG.TELEGRAM_BOT_TOKEN and CONFIG.TELEGRAM_BOT_TOKEN ~= "" and CONFIG.TELEGRAM_CHAT_ID and CONFIG.TELEGRAM_CHAT_ID ~= ""
    if not hasDiscord and not hasTg then return end

    local curHoney = getPlayerHoney()
    if LOOT_REPORT_STATS.startHoney == 0 and curHoney > 0 then
        LOOT_REPORT_STATS.startHoney = curHoney
        LOOT_REPORT_STATS.lastHoney = curHoney
    end
    local periodHoney = math.max(0, curHoney - LOOT_REPORT_STATS.lastHoney)
    local totalHoney = math.max(0, curHoney - LOOT_REPORT_STATS.startHoney)
    LOOT_REPORT_STATS.lastHoney = curHoney

    local intervalMins = math.max(1, tonumber(CONFIG.PERIODIC_REPORT_INTERVAL) or 15)
    local elapsedMins = math.floor((os.clock() - LOOT_REPORT_STATS.startTime) / 60)

    local itemLines = {}
    for name, cnt in pairs(LOOT_REPORT_STATS.periodItems) do
        if cnt > 0 then
            table.insert(itemLines, string.format("• %s: +%d", name, cnt))
        end
    end
    table.sort(itemLines)
    local itemsText = (#itemLines > 0) and table.concat(itemLines, "\n") or "• За этот период редких предметов не выпадало"
    LOOT_REPORT_STATS.periodItems = {}

    local desc = string.format(
        "📊 **Отчет о фарме за последние %d мин** (Всего в игре: %d мин)\n\n" ..
        "🍯 **Мёд:** +%s (Всего за сессию: +%s)\n" ..
        "🌱 **Ростки:** %d | 🐝 **Vicious:** %d | 🌪️ **Windy:** %d\n" ..
        "☄️ **Метеориты:** %d | 🪴 **Плантаторы:** %d\n\n" ..
        "💎 **Добытые ресурсы за период:**\n%s",
        intervalMins, elapsedMins,
        formatNumber(periodHoney), formatNumber(totalHoney),
        LOOT_REPORT_STATS.sprouts, LOOT_REPORT_STATS.vicious, LOOT_REPORT_STATS.windy,
        LOOT_REPORT_STATS.meteors, LOOT_REPORT_STATS.planters,
        itemsText
    )

    sendDiscordWebhook("Периодический отчет о ресурсах", desc, "00f5a0")
    sendTelegramMessage("*Периодический отчет о ресурсах*\n" .. desc)
    log("Отчет", string.format("Отправлен периодический отчет о луте за последние %d мин!", intervalMins))
end

task.spawn(function()
    while true do
        if not alive() then return end
        local intervalMins = math.max(1, tonumber(CONFIG.PERIODIC_REPORT_INTERVAL) or 15)
        local now = os.clock()
        if CONFIG.PERIODIC_REPORT_ENABLED ~= false and (now - LOOT_REPORT_STATS.lastReportTime >= intervalMins * 60) then
            LOOT_REPORT_STATS.lastReportTime = now
            pcall(sendPeriodicLootReport)
        end
        task.wait(5)
    end
end)

-- ══════════════════════════════════════════════════════════════════════
--  АВТО-БУСТЫ ИЗ ИНВЕНТАРЯ ДЛЯ EPIC+ ГРИБОВ
-- ══════════════════════════════════════════════════════════════════════
local BOOST_ITEM_NAMES = {
    "Glitter", "Red Extract", "Blue Extract", "Oil",
    "Enzymes", "Glue", "Tropical Drink", "Purple Potion", "Super Smoothie"
}
local lastBoostUsedAt = {}

function autoUseBoostItems()
    local rep = game:GetService("ReplicatedStorage")
    local ev = rep:FindFirstChild("Events")
    local act = ev and ev:FindFirstChild("PlayerActivesCommand")
    if not act then return end

    local selected = CONFIG.PUFF_SELECTED_BOOSTS or {}
    local now = os.clock()
    for _, item in ipairs(BOOST_ITEM_NAMES) do
        if selected[item] ~= false then
            if not lastBoostUsedAt[item] or (now - lastBoostUsedAt[item] > 70) then
                pcall(function()
                    act:FireServer({ Name = item })
                end)
                lastBoostUsedAt[item] = now
                log("Бусты", "⚡ Использован бафф: " .. tostring(item))
                task.wait(0.12)
            end
        end
    end
end

-- ══════════════════════════════════════════════════════════════════════
--  БОЙ С PUFFSHROOMS (ОРБИТАЛЬНАЯ АТАКА + 10 СЕК ЛУТА)
-- ══════════════════════════════════════════════════════════════════════
function fightPuffshroom(puffRoot, rarity, level)
    if not puffRoot or not puffRoot.Parent then return false end
    local pName = RARITY_LABEL[rarity] or rarity or "гриб"
    log("Puffshrooms", string.format("Начинаю бой с грибом: %s (Уровень: %d)...", pName, level or 1))

    -- Авто-использование бустов из инвентаря для Epic, Legendary, Mythic грибов
    if (rarity == "epic" or rarity == "legendary" or rarity == "mythic") and CONFIG.PUFF_AUTO_BOOST_EPIC ~= false then
        autoUseBoostItems()
        notifyAllWebhooks("Редкий гриб!", string.format("Найден гриб %s (Уровень %d)! Прожаты боевые бусты.", pName, level or 1), "ff00bb")
    end

    local anchor = worldPos(puffRoot)
    local started = os.clock()
    local orbitAngle = 0

    while alive() and puffRoot.Parent and os.clock() - started < 95 do
        local root = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
        if not root then task.wait(0.3); continue end

        anchor = worldPos(puffRoot) or anchor
        if not anchor then break end

        -- Бег по плотной орбите (радиус 6 studs) вокруг ножки гриба
        orbitAngle = orbitAngle + 0.35
        local orbitPos = anchor + Vector3.new(math.cos(orbitAngle) * 6, 2.5, math.sin(orbitAngle) * 6)
        local safePos = getGroundPos(orbitPos)

        moveRootToPosition(root, safePos, 0.25)
        pcall(swingDigTool)

        -- Микро-сбор спор и токенов вокруг гриба
        collectTokensFor(0.8, function()
            return not alive() or not puffRoot.Parent
        end, anchor)

        task.wait(0.04)
    end

    -- Фаза 2: Гриб сломан! Ровно 10 секунд турбо-сбора лута
    log("Puffshrooms", "Гриб сломан! Турбо-сбор спор и наград ровно 10 секунд...")
    local lootStart = os.clock()
    isBurstLootActive = true
    collectTokensFor(10, function()
        return not alive() or (os.clock() - lootStart >= 10)
    end, anchor)
    isBurstLootActive = false

    notifyAllWebhooks("Гриб повержен!", string.format("Гриб %s (Уровень %d) успешно сломан и залутан!", pName, level or 1), "00f5a0")
    return true
end

-- ══════════════════════════════════════════════════════════════════════
--  WINDY BEE (БЕГ ПО ПОЛЮ КАК НА РОСТКАХ, УВОРОТ ОТ ТОРНАДО, БЕЗ ПОЛЕТОВ И ПРЫЖКОВ)
-- ══════════════════════════════════════════════════════════════════════
local poppedWindyClouds = {}

local function isWindyAlreadyHatched(windy)
    if not windy or not windy.Parent then return true end
    if poppedWindyClouds[windy] then return true end

    -- 0. Метод Atlas BSS: Если модель находится в Workspace.Monsters — это 100% активный боевой моб
    local monstersFolder = Workspace:FindFirstChild("Monsters")
    if monstersFolder and (windy.Parent == monstersFolder or windy:IsDescendantOf(monstersFolder)) then
        return true
    end

    -- 1. Если на сервере уже есть торнадо — значит пчела 100% вылупилась и атакует
    local tornadoes = Workspace:FindFirstChild("Tornadoes") or (Workspace:FindFirstChild("Happenings") and Workspace.Happenings:FindFirstChild("Tornadoes"))
    if tornadoes and #tornadoes:GetChildren() > 0 then
        return true
    end

    -- 2. Если пчела перемещается в пространстве (активный полет, а не статичное облако)
    local p1 = worldPos(windy)
    if p1 then
        task.wait(0.2)
        local p2 = worldPos(windy)
        if p2 and (p1 - p2).Magnitude > 5 then
            return true
        end
    end

    -- 3. Если у модели есть боевые элементы / индикатор уровня / здоровья
    for _, child in ipairs(windy:GetChildren()) do
        local cn = string.lower(child.Name)
        if string.find(cn, "combat", 1, true) or string.find(cn, "level", 1, true) or string.find(cn, "enemy", 1, true) or string.find(cn, "health", 1, true) then
            return true
        end
    end

    return false
end

function findWindyBee()
    -- 1. Метод Atlas BSS: Сначала проверяем Workspace.Monsters (боевая модель Windy Bee с уровнем и хитбоксом)
    local monstersFolder = Workspace:FindFirstChild("Monsters")
    if monstersFolder then
        for _, mob in ipairs(monstersFolder:GetChildren()) do
            local n = string.lower(mob.Name)
            if string.find(n, "windy", 1, true) then
                return mob
            end
        end
    end

    -- 2. Метод Atlas BSS: Проверяем Workspace.NPCBees (NPC модель дикой Windy Bee)
    local npcFolder = Workspace:FindFirstChild("NPCBees")
    if npcFolder then
        for _, bee in ipairs(npcFolder:GetChildren()) do
            local n = string.lower(bee.Name)
            if string.find(n, "windy", 1, true) then
                return bee
            end
        end
    end

    -- 3. Проверяем Happenings
    local hap = Workspace:FindFirstChild("Happenings")
    if hap then
        for _, ch in ipairs(hap:GetChildren()) do
            local n = string.lower(ch.Name)
            if string.find(n, "windy", 1, true) then
                return ch
            end
        end
    end

    return nil
end

function fightWindyBee(windy)
    if not windy or not windy.Parent then return false end
    log("Windy", "🌪️ Найдена Windy Bee! Лечу на поле, подбегаю под неё по земле, затем взлетаю парить прямо над ней...")
    notifyAllWebhooks("Windy Bee!", "Обнаружена дикая Windy Bee! Лечу на поле, подбегаю под неё и взлетаю парить над ней...", "00e5ff")
    local started = os.clock()

    -- ШАГ 1: Летим на поле, где находится Windy Bee
    local wPos = worldPos(windy)
    if wPos then
        local fieldZone = getActiveFlowerZone(wPos)
        local targetGround = (fieldZone and getGroundPos(fieldZone.Position)) or getGroundPos(wPos)
        local char = player.Character
        local root = char and char:FindFirstChild("HumanoidRootPart")
        if root and targetGround then
            log("Windy", "Подлетаю к полю с Windy Bee...")
            moveRootToPosition(root, targetGround, 6)
            task.wait(0.2)
        end
    end

    -- ШАГ 2: Бежим по земле прямо ПОД Windy Bee
    setFlightNoclip(false)
    local char = player.Character
    local root = char and char:FindFirstChild("HumanoidRootPart")
    local hum = char and char:FindFirstChildOfClass("Humanoid")
    if hum then
        pcall(function()
            hum.PlatformStand = false
            hum.Sit = false
            hum:ChangeState(Enum.HumanoidStateType.Landed)
            hum:ChangeState(Enum.HumanoidStateType.Running)
        end)
        pcall(applyWalkSpeed)
    end
    if char then
        pcall(function()
            for _, part in ipairs(char:GetDescendants()) do
                if part:IsA("BasePart") then
                    local n = part.Name
                    if n == "Head" or n == "Torso" or n == "UpperTorso" or n == "LowerTorso" then
                        part.CanCollide = true
                    else
                        part.CanCollide = false
                    end
                end
            end
        end)
    end

    local runUnderStart = os.clock()
    log("Windy", "Бегу по земле прямо под Windy Bee...")
    while alive() and windy.Parent and (os.clock() - runUnderStart < 5) do
        local curPos = worldPos(windy)
        local c = player.Character
        local r = c and c:FindFirstChild("HumanoidRootPart")
        local h = c and c:FindFirstChildOfClass("Humanoid")
        if not r or not h then break end

        if curPos then
            local flatDelta = Vector3.new(curPos.X - r.Position.X, 0, curPos.Z - r.Position.Z)
            if flatDelta.Magnitude <= 8 then
                pcall(function()
                    h:Move(Vector3.zero, false)
                    r.AssemblyLinearVelocity = Vector3.new(0, r.AssemblyLinearVelocity.Y, 0)
                end)
                log("Windy", string.format("✅ Добежали под Windy Bee (расстояние %.1f studs)! Взлетаю над ней...", flatDelta.Magnitude))
                break
            end
            local moveDir = flatDelta.Unit
            local curSpd = getCalculatedWalkSpeed(true)
            h.AutoRotate = true
            h:Move(moveDir, false)
            h:MoveTo(Vector3.new(curPos.X, r.Position.Y, curPos.Z))
            pcall(function()
                r.AssemblyLinearVelocity = Vector3.new(moveDir.X * curSpd, r.AssemblyLinearVelocity.Y, moveDir.Z * curSpd)
            end)
        end
        pcall(swingDigTool)
        task.wait(0.1)
    end

    -- ШАГ 3: Теперь взлетаем и парим прямо НАД Windy Bee на безопасной высоте (32 studs)!
    setFlightNoclip(true)
    local hoverHeight = math.clamp(tonumber(CONFIG.WINDY_HOVER_HEIGHT) or 32, 15, 60) -- Повышенная безопасная высота парения над телом Windy Bee и торнадо
    local smoothedTarget = nil
    local lastFacingAt = 0
    local speed = 110

    while alive() and not flightStopRequested and (windy.Parent or findWindyBee()) and (os.clock() - started < 600) do
        if not windy or not windy.Parent then
            local nextBee = findWindyBee()
            if nextBee then
                windy = nextBee
            else
                break -- Windy Bee повержена или исчезла по таймеру
            end
        end
        local targetPos = worldPos(windy)
        if not targetPos then
            local ok, p = pcall(function()
                if windy:IsA("Attachment") then return windy.WorldPosition end
                local part = windy:FindFirstAncestorWhichIsA("BasePart") or windy:FindFirstChildWhichIsA("BasePart", true)
                if part then return part.Position end
                local model = windy:FindFirstAncestorWhichIsA("Model") or (windy:IsA("Model") and windy)
                if model then return model:GetPivot().Position end
                return nil
            end)
            if ok and p then targetPos = p end
        end

        if not targetPos then task.wait(0.1); continue end
        lastActiveTargetPos = targetPos

        local character = player.Character
        local hum = character and character:FindFirstChildOfClass("Humanoid")
        local root = character and character:FindFirstChild("HumanoidRootPart")
        if not root or not hum or hum.Health <= 0 then
            character, root, hum = waitForRespawn(6)
            if not root then break end
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

        pcall(swingDigTool)
    end

    setFlightNoclip(false)
    local root = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
    if root then
        root.AssemblyLinearVelocity = Vector3.zero
        root.AssemblyAngularVelocity = Vector3.zero
    end

    log("Windy", "Windy Bee повержена или исчезла! Сбор Cloud Vials и жетонов 8 секунд...")
    collectTokensFor(8, function() return not alive() end, lastActiveTargetPos)
    LOOT_REPORT_STATS.windy = (LOOT_REPORT_STATS.windy or 0) + 1
    notifyAllWebhooks("Windy Bee залутана!", "Фаза Windy Bee завершена, собраны Cloud Vials и жетоны.", "00f5a0")
    return true
end

-- ══════════════════════════════════════════════════════════════════════
--  METEOR SHOWER (3 РАУНДА НА 3 ПОЛЯХ)
-- ══════════════════════════════════════════════════════════════════════
function findActiveMeteors()
    local meteorsFolder = Workspace:FindFirstChild("Meteors")
    if meteorsFolder and #meteorsFolder:GetChildren() > 0 then
        return meteorsFolder
    end
    local h = Workspace:FindFirstChild("Happenings")
    if h then
        local m = h:FindFirstChild("Meteors") or h:FindFirstChild("MeteorShower")
        if m and #m:GetChildren() > 0 then return m end
    end
    local pFolder = Workspace:FindFirstChild("Particles")
    if pFolder then
        for _, c in ipairs(pFolder:GetChildren()) do
            local cn = string.lower(c.Name)
            if string.find(cn, "warning", 1, true) or string.find(cn, "disk", 1, true) or string.find(cn, "meteor", 1, true) then
                return c
            end
        end
    end
    for _, child in ipairs(Workspace:GetChildren()) do
        local cn = string.lower(child.Name)
        if (string.find(cn, "meteor", 1, true) or string.find(cn, "impact", 1, true)) and not string.find(cn, "meteorshoweritem", 1, true) then
            if #child:GetChildren() > 0 or child:IsA("BasePart") then
                return child
            end
        end
    end
    return nil
end

function getFieldPart(fieldName)
    if not fieldName or fieldName == "" then return nil end
    local zones = Workspace:FindFirstChild("FlowerZones")
    if not zones then return nil end
    local clean = string.lower(fieldName):gsub("%s*field%s*", ""):gsub("%s*patch%s*", ""):gsub("%s*forest%s*", "")
    for _, z in ipairs(zones:GetChildren()) do
        local zn = string.lower(z.Name)
        if zn == string.lower(fieldName) or string.find(zn, clean, 1, true) then
            return z
        end
    end
    return nil
end

function findMeteorFields()
    local fieldsFound = {}
    local seen = {}
    local function checkPos(pos)
        if not pos then return end
        local zones = Workspace:FindFirstChild("FlowerZones")
        if zones then
            for _, zone in ipairs(zones:GetChildren()) do
                if zone:IsA("BasePart") then
                    local lp = zone.CFrame:PointToObjectSpace(pos)
                    local half = zone.Size * 0.5
                    if math.abs(lp.X) <= half.X + 25 and math.abs(lp.Z) <= half.Z + 25 then
                        local fName = zone.Name
                        if fName and not seen[fName] then
                            seen[fName] = true
                            table.insert(fieldsFound, fName)
                        end
                        return
                    end
                end
            end
        end
        local fName = getFieldForPos(pos, 50)
        if fName and not seen[fName] then
            seen[fName] = true
            table.insert(fieldsFound, fName)
        end
    end

    local mFolder = Workspace:FindFirstChild("Meteors") or (Workspace:FindFirstChild("Happenings") and (Workspace.Happenings:FindFirstChild("Meteors") or Workspace.Happenings:FindFirstChild("MeteorShower")))
    if mFolder then
        for _, m in ipairs(mFolder:GetChildren()) do
            checkPos(worldPos(m))
        end
    end
    local pFolder = Workspace:FindFirstChild("Particles")
    if pFolder then
        for _, d in ipairs(pFolder:GetChildren()) do
            local cn = string.lower(d.Name)
            if string.find(cn, "warning", 1, true) or string.find(cn, "disk", 1, true) or string.find(cn, "meteor", 1, true) then
                checkPos(worldPos(d))
            end
        end
    end
    for _, child in ipairs(Workspace:GetChildren()) do
        local cn = string.lower(child.Name)
        if (string.find(cn, "meteor", 1, true) or string.find(cn, "impact", 1, true)) and not string.find(cn, "meteorshoweritem", 1, true) then
            checkPos(worldPos(child))
            for _, gc in ipairs(child:GetChildren()) do
                checkPos(worldPos(gc))
            end
        end
    end
    return fieldsFound
end

function lootMeteorShower(meteors)
    log("Meteor", "☄️ Обнаружен Meteor Shower! Начинаю целевой сбор метеоритов...")
    notifyAllWebhooks("Метеоритный дождь!", "На сервере идет Meteor Shower! Бот облетает поля и собирает все метеоритные награды.", "ffaa00")
    local showerStart = os.clock()
    local roundsDone = 0

    while alive() and (os.clock() - showerStart < 150) do
        local activeFields = findMeteorFields()
        if #activeFields == 0 then
            if not findActiveMeteors() and (os.clock() - showerStart > 15) then
                break
            end
            task.wait(1.5)
            activeFields = findMeteorFields()
        end

        if #activeFields > 0 then
            roundsDone = roundsDone + 1
            log("Meteor", string.format("☄️ Метеоры на полях: %s (раунд %d)", table.concat(activeFields, ", "), roundsDone))

            for idx, fName in ipairs(activeFields) do
                if not alive() then break end
                local zPart = getFieldPart(fName)
                local root = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
                if zPart and root and alive() then
                    local safeGround = getGroundPos(zPart.Position)
                    log("Meteor", string.format("⚡ Перелет на метеоритное поле: %s...", fName))
                    moveRootToPosition(root, safeGround, 25)

                    -- Собираем падающие осколки и токены
                    local t0 = os.clock()
                    while alive() and (os.clock() - t0 < 12) do
                        local pFolder = Workspace:FindFirstChild("Particles")
                        if pFolder then
                            for _, disk in ipairs(pFolder:GetChildren()) do
                                local dn = string.lower(disk.Name)
                                if (string.find(dn, "warning", 1, true) or string.find(dn, "disk", 1, true) or string.find(dn, "meteor", 1, true)) then
                                    local dPos = worldPos(disk)
                                    if dPos then
                                        local d2 = (Vector3.new(dPos.X, 0, dPos.Z) - Vector3.new(safeGround.X, 0, safeGround.Z)).Magnitude
                                        if d2 < 70 then
                                            local targetG = Vector3.new(dPos.X, safeGround.Y, dPos.Z)
                                            moveRootToPosition(root, targetG, 4)
                                            task.wait(0.1)
                                        end
                                    end
                                end
                            end
                        end
                        collectTokensFor(2.5, function() return not alive() end, safeGround)
                    end
                end
            end
        else
            collectTokensFor(5, function() return not alive() end)
        end

        task.wait(1)
        if not findActiveMeteors() and (os.clock() - showerStart > 25) then
            break
        end
    end

    log("Meteor", "Метеоритный дождь завершен! Финальный сбор токенов 12 секунд...")
    collectTokensFor(12, function() return not alive() end)
    notifyAllWebhooks("Метеориты собраны!", "Метеоритный дождь успешно залутан!", "00f5a0")
    return true
end

-- ══════════════════════════════════════════════════════════════════════
--  ПЛАНТАТОРЫ (14 ТИПОВ: СБОР ПО % И АВТО-ПОСАДКА НА ПОЛЕ)
-- ══════════════════════════════════════════════════════════════════════
local ALL_PLANTER_TYPES = {
    "Paper Planter",
    "Plastic Planter",
    "Candy Planter",
    "Tacky Planter",
    "Pesticide Planter",
    "Red Clay Planter",
    "Blue Clay Planter",
    "Petal Planter",
    "Hydroponic Planter",
    "Heat-Treated Planter",
    "Ticket Planter",
    "Sticker Planter",
    "Festive Planter",
    "The Planter of Plenty",
}

local ALL_BSS_FIELDS = {
    "Sunflower Field", "Dandelion Field", "Mushroom Field", "Blue Flower Field",
    "Clover Field", "Strawberry Field", "Spider Field", "Bamboo Field",
    "Pineapple Patch", "Stump Field", "Cactus Field", "Pumpkin Patch",
    "Pine Tree Forest", "Rose Field", "Mountain Top Field", "Coconut Field", "Pepper Patch"
}

-- Вспомогательные функции Atlas BSS для работы с плантаторами
local function getLocalPlantersTable()
    local ok, res = pcall(function()
        local rep = game:GetService("ReplicatedStorage")
        local lpMod = rep:FindFirstChild("LocalPlanters")
        if not lpMod then return nil end
        local required = require(lpMod)
        if not required then return nil end
        local checkFn = required.CheckForNearbyHarvestablePlanters
        if not checkFn then return nil end

        local getUpv = (debug and debug.getupvalue) or getupvalue
        if type(getUpv) == "function" then
            local upv = getUpv(checkFn, 1)
            if type(upv) == "table" then return upv end
            local getUpvs = (debug and debug.getupvalues) or getupvalues
            if type(getUpvs) == "function" then
                local allUpvs = getUpvs(checkFn)
                if type(allUpvs) == "table" then
                    for _, v in pairs(allUpvs) do
                        if type(v) == "table" then
                            for _, entry in pairs(v) do
                                if type(entry) == "table" and (entry.IsMine ~= nil or entry.ActorID ~= nil) then
                                    return v
                                end
                            end
                        end
                    end
                end
            end
        end
        return nil
    end)
    if ok and res then return res end
    return nil
end

local function getPlanterDisplayNames()
    local ok, res = pcall(function()
        local rep = game:GetService("ReplicatedStorage")
        local ptMod = rep:FindFirstChild("PlanterTypes")
        if ptMod then
            local pt = require(ptMod)
            if pt and type(pt.GetTypes) == "function" then
                return pt.GetTypes()
            end
        end
        return nil
    end)
    if ok and res then return res end
    return nil
end

function getPlanterType(model)
    if not model then return "Unknown Planter" end

    -- 0. Метод Atlas BSS: считывание названия из Gui Attach -> Planter Gui -> Bar -> TextLabel
    -- Формат текста в игре: "Paper Planter (100%)" или "Red Clay Planter (55%)"
    local guiAttach = model:FindFirstChild("Gui Attach")
    if guiAttach then
        local pGui = guiAttach:FindFirstChild("Planter Gui")
        local bar = pGui and pGui:FindFirstChild("Bar")
        local txtLbl = bar and bar:FindFirstChild("TextLabel")
        if txtLbl and txtLbl.Text and txtLbl.Text ~= "" then
            local matched = string.match(txtLbl.Text, "(.+)%s*%(")
            if matched then
                local clean = matched:gsub("^%s*(.-)%s*$", "%1")
                for _, pType in ipairs(ALL_PLANTER_TYPES) do
                    if string.lower(pType) == string.lower(clean)
                       or string.find(string.lower(clean), string.lower(pType), 1, true)
                       or string.find(string.lower(pType), string.lower(clean), 1, true) then
                        return pType
                    end
                end
                if clean ~= "" then return clean end
            end
        end
    end

    -- 1. Метод Atlas BSS: сопоставление через LocalPlanters upvalue
    local lpTable = getLocalPlantersTable()
    if lpTable then
        local pTypes = getPlanterDisplayNames()
        for _, lp in pairs(lpTable) do
            if lp.Model == model or (lp.Position and model:IsA("BasePart") and (lp.Position - model.Position).Magnitude < 4) then
                if pTypes and lp.Type and pTypes[lp.Type] and pTypes[lp.Type].DisplayName then
                    return pTypes[lp.Type].DisplayName
                end
                if lp.DisplayName then return lp.DisplayName end
                if lp.Type then return tostring(lp.Type) end
            end
        end
    end

    -- 2. Проверка атрибутов и имени модели
    local raw = model:GetAttribute("Type") or model:GetAttribute("PlanterType") or model.Name
    local low = string.lower(tostring(raw))
    for _, pType in ipairs(ALL_PLANTER_TYPES) do
        local pLow = string.lower(pType)
        local short = pLow:gsub("%s*planter%s*", ""):gsub("the%s*", ""):gsub("%s*of%s*", "")
        if string.find(low, short, 1, true) then
            return pType
        end
    end

    -- 3. Резервный поиск по всем TextLabel внутри модели
    for _, desc in ipairs(model:GetDescendants()) do
        if desc:IsA("TextLabel") then
            local tLow = string.lower(desc.Text or "")
            local matched = string.match(desc.Text or "", "(.+)%s*%(")
            if matched then
                local clean = matched:gsub("^%s*(.-)%s*$", "%1")
                for _, pType in ipairs(ALL_PLANTER_TYPES) do
                    if string.lower(pType) == string.lower(clean) then
                        return pType
                    end
                end
            end
            for _, pType in ipairs(ALL_PLANTER_TYPES) do
                local pLow = string.lower(pType)
                local short = pLow:gsub("%s*planter%s*", ""):gsub("the%s*", ""):gsub("%s*of%s*", "")
                if string.find(tLow, short, 1, true) then
                    return pType
                end
            end
        end
    end
    return model.Name
end

function getPlanterProgress(model)
    if not model then return 0, "0%" end
    local percent = nil
    local timeLeftStr = nil
    local isFullyReady = false

    -- 0. Метод Atlas BSS: ValueObject "GrowthPercent" (1.0 = 100%)
    local growthVal = model:FindFirstChild("GrowthPercent")
    if growthVal then
        local rawVal = nil
        if growthVal:IsA("ValueObject") or growthVal:IsA("NumberValue") or growthVal:IsA("IntValue") or growthVal:IsA("DoubleConstrainedValue") then
            rawVal = growthVal.Value
        elseif type(growthVal.Value) == "number" then
            rawVal = growthVal.Value
        end
        if type(rawVal) == "number" then
            local p = (rawVal <= 1.0001 and rawVal >= 0) and (rawVal * 100) or rawVal
            percent = p
            if p >= 99.9 or rawVal >= 1 then
                isFullyReady = true
                percent = 100
                timeLeftStr = "Ready!"
            end
        end
    end

    -- 1. Метод Atlas BSS: Gui Attach -> Planter Gui -> Bar -> TextLabel
    local guiAttach = model:FindFirstChild("Gui Attach")
    local pGui = guiAttach and guiAttach:FindFirstChild("Planter Gui")
    local bar = pGui and pGui:FindFirstChild("Bar")
    local txtLbl = bar and bar:FindFirstChild("TextLabel")
    if txtLbl and txtLbl.Text and txtLbl.Text ~= "" then
        local txt = txtLbl.Text
        local low = string.lower(txt)
        local pMatch = string.match(txt, "%((%d+%.?%d*)%%%s*%)") or string.match(txt, "(%d+%.?%d*)%%")
        if pMatch then
            local num = tonumber(pMatch)
            if num then
                percent = num
                if num >= 100 then
                    isFullyReady = true
                    percent = 100
                    timeLeftStr = "Ready!"
                else
                    isFullyReady = false
                end
            end
        end

        if string.find(low, "ready to harvest", 1, true) or string.find(low, "harvest!", 1, true)
           or (string.find(low, "ready", 1, true) and not string.find(low, "ready in", 1, true) and not string.find(low, "not ready", 1, true) and not string.find(low, "grow", 1, true)) then
            isFullyReady = true
            percent = 100
            timeLeftStr = "Ready!"
        elseif string.find(low, "left", 1, true) or string.find(txt, ":", 1, true) or string.find(low, "ready in", 1, true) then
            timeLeftStr = timeLeftStr or txt
        end
    end

    -- 2. Проверка атрибутов модели
    if percent == nil then
        local attrPct = model:GetAttribute("Progress") or model:GetAttribute("Growth") or model:GetAttribute("Percent")
        if type(attrPct) == "number" then
            local p = (attrPct <= 1.05 and attrPct > 0) and (attrPct * 100) or attrPct
            percent = p
            if p >= 99.9 then
                isFullyReady = true
                percent = 100
                timeLeftStr = "Ready!"
            end
        end
    end
    local attrTime = model:GetAttribute("TimeLeft") or model:GetAttribute("Remaining") or model:GetAttribute("Duration")
    if attrTime and not timeLeftStr then timeLeftStr = tostring(attrTime) end

    -- 3. Резервный поиск по потомкам (ТОЛЬКО парсинг явных процентов и надписей, БЕЗ ошибочного детекта по размеру контейнера Bar)
    if percent == nil then
        for _, desc in ipairs(model:GetDescendants()) do
            if desc:IsA("TextLabel") then
                local txt = desc.Text or ""
                local low = string.lower(txt)
                local pMatch = string.match(txt, "(%d+%.?%d*)%%")
                if pMatch then
                    local num = tonumber(pMatch)
                    if num then
                        percent = num
                        if num >= 100 then
                            isFullyReady = true
                            percent = 100
                            timeLeftStr = "Ready!"
                        end
                        break
                    end
                end
                if string.find(low, "ready to harvest", 1, true) or string.find(low, "harvest!", 1, true) then
                    isFullyReady = true
                    percent = 100
                    timeLeftStr = "Ready!"
                    break
                end
            end
        end
    end

    -- Если процент так и не определен или меньше 100 — плантатор НЕ готов!
    percent = percent or 0
    if percent < 100 then
        isFullyReady = false
    end

    local statusStr
    if isFullyReady then
        statusStr = "Ready!"
    elseif timeLeftStr and timeLeftStr ~= "" then
        statusStr = string.format("%.1f%% (%s)", percent, timeLeftStr)
    else
        statusStr = string.format("%.1f%%", percent)
    end
    return percent, statusStr
end

local cachedPlantersFolder = nil

local function getAllPlanterCandidates()
    local candidates = {}
    local seen = {}

    local function addCandidate(model)
        if model and not seen[model] and (model:IsA("Model") or model:IsA("BasePart")) then
            seen[model] = true
            table.insert(candidates, model)
        end
    end

    local function checkAndAdd(item)
        if not item then return end
        if item:IsA("Model") or item:IsA("BasePart") then
            addCandidate(item)
        elseif item:IsA("Folder") or item:IsA("Configuration") then
            for _, sub in ipairs(item:GetChildren()) do
                if sub:IsA("Model") or sub:IsA("BasePart") or sub:FindFirstChildWhichIsA("BasePart", true) then
                    addCandidate(sub)
                end
            end
        end
    end

    -- 1. Сначала проверяем кэшированную папку
    if cachedPlantersFolder and cachedPlantersFolder.Parent then
        for _, ch in ipairs(cachedPlantersFolder:GetChildren()) do
            checkAndAdd(ch)
        end
    end

    -- 2. Проверяем Workspace.Planters и LocalPlanters (основное хранилище плантаторов BSS из Atlas)
    local plantersFolder = Workspace:FindFirstChild("Planters")
    if plantersFolder then
        cachedPlantersFolder = plantersFolder
        for _, ch in ipairs(plantersFolder:GetChildren()) do
            checkAndAdd(ch)
            if ch.Name == "LocalPlanters" then
                for _, sub in ipairs(ch:GetChildren()) do
                    checkAndAdd(sub)
                end
            end
        end
    end

    -- 3. Известные контейнеры плантаторов в Workspace
    local folders = {
        Workspace:FindFirstChild("LocalPlanters"),
        Workspace:FindFirstChild("ActivePlanters"),
        Workspace:FindFirstChild("PlanterModels"),
        Workspace:FindFirstChild("Core") and Workspace.Core:FindFirstChild("Planters"),
        Workspace:FindFirstChild("Happenings") and Workspace.Happenings:FindFirstChild("Planters"),
        Workspace:FindFirstChild("FlowerZones"),
        Workspace:FindFirstChild("Fields"),
        Workspace:FindFirstChild("Models"),
        Workspace:FindFirstChild("Debris"),
    }
    for _, f in ipairs(folders) do
        if f then
            for _, ch in ipairs(f:GetChildren()) do
                local nLow = string.lower(ch.Name)
                if string.find(nLow, "planter", 1, true) or ch.Name == "PlanterBulb" or f.Name == "Planters" or f.Name == "LocalPlanters" or f.Name == "ActivePlanters" or f.Name == "PlanterModels" then
                    checkAndAdd(ch)
                    cachedPlantersFolder = f
                end
            end
        end
    end

    -- 4. Прямые потомки Workspace
    for _, ch in ipairs(Workspace:GetChildren()) do
        local nLow = string.lower(ch.Name)
        if string.find(nLow, "planter", 1, true) or ch.Name == "PlanterBulb" then
            checkAndAdd(ch)
        end
    end

    -- 5. Быстрый поиск по потомкам Workspace по ProximityPrompt и BillboardGui (если кандидатов нет)
    if #candidates == 0 then
        for _, desc in ipairs(Workspace:GetDescendants()) do
            if desc:IsA("ProximityPrompt") then
                local act = string.lower(desc.ActionText or "")
                local obj = string.lower(desc.ObjectText or "")
                if string.find(act, "harvest", 1, true) or string.find(act, "planter", 1, true)
                   or string.find(obj, "planter", 1, true) then
                    local m = desc:FindFirstAncestorWhichIsA("Model") or desc.Parent
                    if m then
                        addCandidate(m)
                        if m.Parent then cachedPlantersFolder = m.Parent end
                    end
                end
            elseif desc:IsA("BillboardGui") then
                local isPlanter = false
                for _, lbl in ipairs(desc:GetChildren()) do
                    if lbl:IsA("TextLabel") and string.find(string.lower(lbl.Text or ""), "planter", 1, true) then
                        isPlanter = true; break
                    end
                end
                if isPlanter then
                    local m = desc:FindFirstAncestorWhichIsA("Model") or desc.Parent
                    if m then
                        addCandidate(m)
                        if m.Parent then cachedPlantersFolder = m.Parent end
                    end
                end
            end
        end
    end

    return candidates
end

function isPlanterMine(pModel)
    if not pModel then return false end
    local myName = string.lower(player.Name)
    local myId = tostring(player.UserId)

    -- 0. Метод Atlas BSS: проверка через upvalue ReplicatedStorage.LocalPlanters (IsMine == true)
    local lpTable = getLocalPlantersTable()
    if lpTable then
        for _, lp in pairs(lpTable) do
            if lp.IsMine then
                if lp.Model == pModel or (pModel:IsA("BasePart") and lp.Model and lp.Model:IsAncestorOf(pModel)) then
                    return true
                end
                local pPos = worldPos(pModel)
                if pPos and lp.Position and (lp.Position - pPos).Magnitude < 5 then
                    return true
                end
            end
        end
    end

    -- 0.1. Если модель находится внутри "LocalPlanters" - это гарантированно НАШ плантатор!
    if pModel:FindFirstAncestor("LocalPlanters") then
        return true
    end
    local parent = pModel.Parent
    if parent and (string.lower(parent.Name) == "localplanters" or string.find(string.lower(parent.Name), "local", 1, true)) then
        return true
    end

    -- 1. ProximityPrompt (В BSS у чужих плантаторов НЕТ промпта сбора для локального игрока!)
    for _, prompt in ipairs(pModel:GetDescendants()) do
        if prompt:IsA("ProximityPrompt") then
            local act = string.lower(prompt.ActionText or "")
            local obj = string.lower(prompt.ObjectText or "")
            if string.find(act, "harvest", 1, true) or string.find(act, "planter", 1, true)
               or string.find(obj, "planter", 1, true) or prompt.Enabled then
                return true
            end
        end
    end

    -- 2. Имя модели совпадает с именем или UserId
    local mName = string.lower(pModel.Name)
    if mName == myName or mName == myId or string.find(mName, myId, 1, true) or string.find(mName, myName, 1, true) then
        return true
    end

    -- 3. Атрибуты (Owner, UserId, Player, OwnerId, Placer, Account)
    for _, attrName in ipairs({ "Owner", "UserId", "Player", "OwnerId", "Placer", "Account", "Creator" }) do
        local val = pModel:GetAttribute(attrName)
        if val then
            local s = string.lower(tostring(val))
            if s == myName or s == myId or string.find(s, myId, 1, true) or string.find(s, myName, 1, true) then
                return true
            end
        end
    end

    -- 4. ValueObject объекты
    for _, valName in ipairs({ "Owner", "Player", "UserId", "PlayerRef", "OwnerRef", "Placer" }) do
        local obj = pModel:FindFirstChild(valName)
        if obj then
            if obj:IsA("ObjectValue") and obj.Value == player then
                return true
            elseif obj.Value then
                local s = string.lower(tostring(obj.Value))
                if s == myName or s == myId or string.find(s, myId, 1, true) or string.find(s, myName, 1, true) then
                    return true
                end
            end
        end
    end

    -- 5. Текстовые метки с UserId или ником (например: "4039616847(81%)")
    for _, desc in ipairs(pModel:GetDescendants()) do
        if desc:IsA("TextLabel") then
            local txt = string.lower(desc.Text or "")
            if string.find(txt, myId, 1, true) or string.find(txt, myName, 1, true) then
                return true
            end
        end
    end

    -- 6. Если один на сервере - все плантаторы на сервере принадлежат нам
    if #Players:GetPlayers() <= 1 then
        return true
    end

    return false
end

function findMyActivePlanters()
    local rawPlanters = {}
    local candidates = getAllPlanterCandidates()

    for _, pModel in ipairs(candidates) do
        if isPlanterMine(pModel) then
            local pType = getPlanterType(pModel)
            local percent, statusStr = getPlanterProgress(pModel)
            local fieldName = detectField(pModel) or "Unknown Field"
            local ready = (percent >= 100) or (statusStr == "Ready!")

            table.insert(rawPlanters, {
                type = pType,
                model = pModel,
                field = fieldName,
                percent = percent,
                statusStr = statusStr,
                ready = ready,
            })
        end
    end

    -- Дедупликация: ровно 1 строка на каждый тип плантатора в HUD и в задачах
    local myPlanters = {}
    local byType = {}
    for _, info in ipairs(rawPlanters) do
        local key = info.type
        if not byType[key] then
            byType[key] = info
            table.insert(myPlanters, info)
        else
            local existing = byType[key]
            -- Предпочитаем запись с большим прогрессом и известным полем
            if info.percent and info.percent > (existing.percent or 0) then
                existing.percent = info.percent
                existing.statusStr = info.statusStr
                existing.ready = info.ready
            end
            if (existing.field == "Unknown Field" or not existing.field) and info.field and info.field ~= "Unknown Field" then
                existing.field = info.field
            end
            if info.model and info.model:FindFirstChild("Gui Attach") then
                existing.model = info.model
            end
        end
    end

    return myPlanters
end

function confirmPlanterHarvestModal()
    local pg = player:FindFirstChild("PlayerGui")
    if not pg then return false end

    -- 0. Метод Atlas BSS: Канонический путь ScreenGui.QuestionBox.Box.YesButton
    local screenGui = pg:FindFirstChild("ScreenGui")
    if screenGui then
        local qBox = screenGui:FindFirstChild("QuestionBox")
        if qBox and qBox.Visible then
            local box = qBox:FindFirstChild("Box")
            local descLbl = box and (box:FindFirstChildWhichIsA("TextLabel") or qBox:FindFirstChildWhichIsA("TextLabel"))
            local dText = string.lower(descLbl and descLbl.Text or "")
            local isEarlyWarning = string.find(dText, "still growing", 1, true)
                or string.find(dText, "before it", 1, true)
                or string.find(dText, "not ready", 1, true)
            if isEarlyWarning then
                log("Плантатор", "⚠️ Плантатор ещё не созрел! Закрываю диалог (нажимаю No)...")
                local noBtn = box and (box:FindFirstChild("NoButton") or box:FindFirstChild("No") or box:FindFirstChild("Cancel"))
                if noBtn then
                    pcall(function()
                        if type(firesignal) == "function" then firesignal(noBtn.MouseButton1Click); firesignal(noBtn.Activated) end
                    end)
                end
                return false
            end

            local yesBtn = box and (box:FindFirstChild("YesButton") or box:FindFirstChild("Yes"))
            if yesBtn then
                log("Плантатор", "🟢 [Atlas] Нажата каноническая кнопка QuestionBox.Box.YesButton!")
                pcall(function()
                    if type(firesignal) == "function" then
                        firesignal(yesBtn.MouseButton1Click)
                        firesignal(yesBtn.Activated)
                    end
                end)
                pcall(function()
                    if type(getconnections) == "function" then
                        for _, c in ipairs(getconnections(yesBtn.MouseButton1Click)) do c:Fire() end
                        for _, c in ipairs(getconnections(yesBtn.Activated)) do c:Fire() end
                    end
                end)
                pcall(function()
                    local vim = game:GetService("VirtualInputManager")
                    if vim then
                        local center = yesBtn.AbsolutePosition + (yesBtn.AbsoluteSize * 0.5)
                        local inset = game:GetService("GuiService"):GetGuiInset()
                        vim:SendMouseMoveEvent(center.X, center.Y, game)
                        vim:SendMouseButtonEvent(center.X, center.Y, 0, true, game, 1)
                        task.wait(0.04)
                        vim:SendMouseButtonEvent(center.X, center.Y, 0, false, game, 1)
                        vim:SendMouseMoveEvent(center.X + inset.X, center.Y + inset.Y, game)
                        vim:SendMouseButtonEvent(center.X + inset.X, center.Y + inset.Y, 0, true, game, 1)
                        task.wait(0.04)
                        vim:SendMouseButtonEvent(center.X + inset.X, center.Y + inset.Y, 0, false, game, 1)
                    end
                end)
                pcall(function()
                    local vu = game:GetService("VirtualUser")
                    if vu then
                        local center = yesBtn.AbsolutePosition + (yesBtn.AbsoluteSize * 0.5)
                        vu:CaptureController()
                        vu:ClickButton1(Vector2.new(center.X, center.Y))
                    end
                end)
                return true
            end
        end
    end

    -- 1. Резервный поиск диалогового окна подтверждения сбора плантатора по всему PlayerGui
    for _, desc in ipairs(pg:GetDescendants()) do
        if desc:IsA("TextLabel") or desc:IsA("TextButton") then
            local t = string.lower(desc.Text or "")
            local isEarlyWarning = string.find(t, "still growing", 1, true)
                or string.find(t, "before it", 1, true)
                or string.find(t, "not ready", 1, true)
            if isEarlyWarning then
                log("Плантатор", "⚠️ Плантатор ещё растёт! Закрываю диалог сбора...")
                local dialogContainer = desc.Parent
                if dialogContainer then
                    for _, elem in ipairs(dialogContainer:GetDescendants()) do
                        if elem:IsA("TextButton") or elem:IsA("ImageButton") then
                            local eTxt = string.lower(elem.Text or "")
                            local eName = string.lower(elem.Name or "")
                            if eTxt == "no" or eName == "no" or string.find(eTxt, "no", 1, true) or string.find(eTxt, "cancel", 1, true) then
                                pcall(function() if type(firesignal) == "function" then firesignal(elem.MouseButton1Click); firesignal(elem.Activated) end end)
                                break
                            end
                        end
                    end
                end
                return false
            end

            local isPlanterModal = (
                (string.find(t, "harvest", 1, true) and (string.find(t, "planter", 1, true) or string.find(t, "done", 1, true)))
                or string.find(t, "done growing", 1, true)
                or (string.find(t, "harvest the", 1, true) and string.find(t, "planter", 1, true))
                or (string.find(t, "claim", 1, true) and string.find(t, "planter", 1, true))
            )

            if isPlanterModal then
                local dialogContainer = desc.Parent
                if dialogContainer then
                    local searchScopes = { dialogContainer, dialogContainer.Parent, dialogContainer.Parent and dialogContainer.Parent.Parent, dialogContainer.Parent and dialogContainer.Parent.Parent and dialogContainer.Parent.Parent.Parent }
                    for _, container in ipairs(searchScopes) do
                        if container then
                            for _, elem in ipairs(container:GetDescendants()) do
                                if elem:IsA("TextButton") or elem:IsA("ImageButton") or elem:IsA("GuiObject") then
                                    local eTxt = (elem:IsA("TextButton") or elem:IsA("TextLabel")) and string.lower(elem.Text or "") or ""
                                    local eName = string.lower(elem.Name or "")
                                    local childTxt = ""
                                    local lbl = elem:FindFirstChildWhichIsA("TextLabel", true)
                                    if lbl then childTxt = string.lower(lbl.Text or "") end

                                    -- Определяем кнопку "Yes" / "Confirm"
                                    local isYes = (eTxt == "yes" or childTxt == "yes" or eName == "yes"
                                        or string.find(eName, "yes", 1, true)
                                        or string.find(eTxt, "yes", 1, true)
                                        or string.find(childTxt, "yes", 1, true)
                                        or string.find(eTxt, "confirm", 1, true)
                                        or string.find(eName, "confirm", 1, true))

                                    if isYes then
                                        log("Плантатор", "🟢 Нажата кнопка [ Yes ] в диалоге сбора плантатора!")

                                        -- 1. firesignal
                                        pcall(function()
                                            if type(firesignal) == "function" then
                                                if elem:IsA("GuiButton") then
                                                    firesignal(elem.MouseButton1Click)
                                                    firesignal(elem.MouseButton1Down)
                                                    firesignal(elem.MouseButton1Up)
                                                    firesignal(elem.Activated)
                                                end
                                                if elem.Parent and elem.Parent:IsA("GuiButton") then
                                                    firesignal(elem.Parent.MouseButton1Click)
                                                    firesignal(elem.Parent.MouseButton1Down)
                                                    firesignal(elem.Parent.MouseButton1Up)
                                                    firesignal(elem.Parent.Activated)
                                                end
                                            end
                                        end)

                                        -- 2. getconnections
                                        pcall(function()
                                            if type(getconnections) == "function" then
                                                local btn = elem:IsA("GuiButton") and elem or (elem.Parent and elem.Parent:IsA("GuiButton") and elem.Parent)
                                                if btn then
                                                    for _, c in ipairs(getconnections(btn.MouseButton1Click)) do c:Fire() end
                                                    for _, c in ipairs(getconnections(btn.MouseButton1Down)) do c:Fire() end
                                                    for _, c in ipairs(getconnections(btn.MouseButton1Up)) do c:Fire() end
                                                    for _, c in ipairs(getconnections(btn.Activated)) do c:Fire() end
                                                end
                                            end
                                        end)

                                        -- 3. VirtualInputManager (по обоим координатам: с Inset и без, с предварительным Move)
                                        pcall(function()
                                            local vim = game:GetService("VirtualInputManager")
                                            if vim then
                                                local targetElem = elem:IsA("GuiObject") and elem or elem.Parent
                                                local center = targetElem.AbsolutePosition + (targetElem.AbsoluteSize * 0.5)
                                                local inset = game:GetService("GuiService"):GetGuiInset()

                                                vim:SendMouseMoveEvent(center.X, center.Y, game)
                                                vim:SendMouseButtonEvent(center.X, center.Y, 0, true, game, 1)
                                                task.wait(0.04)
                                                vim:SendMouseButtonEvent(center.X, center.Y, 0, false, game, 1)

                                                vim:SendMouseMoveEvent(center.X + inset.X, center.Y + inset.Y, game)
                                                vim:SendMouseButtonEvent(center.X + inset.X, center.Y + inset.Y, 0, true, game, 1)
                                                task.wait(0.04)
                                                vim:SendMouseButtonEvent(center.X + inset.X, center.Y + inset.Y, 0, false, game, 1)
                                            end
                                        end)

                                        -- 4. VirtualUser
                                        pcall(function()
                                            local vu = game:GetService("VirtualUser")
                                            if vu then
                                                local targetElem = elem:IsA("GuiObject") and elem or elem.Parent
                                                local center = targetElem.AbsolutePosition + (targetElem.AbsoluteSize * 0.5)
                                                vu:CaptureController()
                                                vu:ClickButton1(Vector2.new(center.X, center.Y))
                                            end
                                        end)

                                        -- 5. Прямой вызов Remote подтверждения
                                        pcall(function()
                                            local rep = game:GetService("ReplicatedStorage")
                                            local events = rep:FindFirstChild("Events")
                                            if events then
                                                local pCmd = events:FindFirstChild("PlanterCommand")
                                                if pCmd then
                                                    pCmd:FireServer({ Type = "ConfirmHarvest" })
                                                    pCmd:FireServer({ Type = "Harvest", Confirm = true })
                                                    pCmd:FireServer({ Type = "HarvestPlanter", Confirm = true })
                                                end
                                            end
                                        end)

                                        return true
                                    end
                                end
                            end
                        end
                    end
                end
            end
        end
    end
    return false
end

-- Фоновый наблюдатель за диалогом сбора плантатора (подтверждает Yes если окно появилось на экране)
task.spawn(function()
    while true do
        if not alive() then return end
        if CONFIG.AUTO_HARVEST_PLANTERS ~= false then
            pcall(confirmPlanterHarvestModal)
        end
        task.wait(0.5)
    end
end)

function managePlanters()
    if CONFIG.AUTO_HARVEST_PLANTERS == false then return false end
    local rep = game:GetService("ReplicatedStorage")
    local pCmd = rep:FindFirstChild("Events") and rep.Events:FindFirstChild("PlanterCommand")
    local repPkg = rep:FindFirstChild("Events") and rep.Events:FindFirstChild("PlanterPackage")
    local activePlanters = findMyActivePlanters()
    local activeTypes = {}
    local harvestedAny = false

    -- 1. Сбор созревших плантаторов
    for _, info in ipairs(activePlanters) do
        activeTypes[info.type] = true
        local pCfg = CONFIG.PLANTERS_CONFIG and CONFIG.PLANTERS_CONFIG[info.type]
        local isEnabled = pCfg and (pCfg.enabled == true)
        local targetPct = (pCfg and tonumber(pCfg.percent)) or 100

        local shouldHarvest = isEnabled and (info.percent >= targetPct and info.percent > 0)

        if shouldHarvest then
            harvestedAny = true
            local pPos = worldPos(info.model)
            local fieldName = info.field
            if not fieldName or fieldName == "Unknown Field" then
                if pPos then
                    fieldName = getFieldForPos(pPos, 45) or detectField(info.model) or "Unknown Field"
                end
            end
            info.field = fieldName
            log("Плантатор", string.format("🪴 Плантатор %s на поле %s готов к сбору (%.1f%%, порог %d%%)! Собираю урожай...", info.type, info.field, info.percent, targetPct))
            notifyAllWebhooks("Сбор плантатора!", string.format("Плантатор %s на поле %s собран!", info.type, info.field), "00f5a0")

            -- ШАГ 0: Летим в упор к плантатору
            local root = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
            if root and pPos then
                local targetG = getGroundPos(pPos)
                moveRootToPosition(root, targetG, 6)
                setFlightNoclip(false)
                if (root.Position - pPos).Magnitude > 6 then
                    root.CFrame = CFrame.new(targetG)
                end
                task.wait(0.2)
            end

            -- ШАГ 1: Нажимаем E (VirtualInputManager + ProximityPrompt)
            for _, prompt in ipairs(info.model:GetDescendants()) do
                if prompt:IsA("ProximityPrompt") then
                    pcall(function()
                        prompt.HoldDuration = 0
                        prompt.RequiresLineOfSight = false
                        prompt.MaxActivationDistance = 999
                    end)
                    -- fireproximityprompt (самый надежный)
                    if type(fireproximityprompt) == "function" then
                        pcall(fireproximityprompt, prompt, 0, true)
                        pcall(fireproximityprompt, prompt)
                    end
                    -- getconnections
                    pcall(function()
                        if type(getconnections) == "function" then
                            for _, conn in ipairs(getconnections(prompt.Triggered)) do
                                conn:Fire()
                            end
                            for _, conn in ipairs(getconnections(prompt.TriggerEnded)) do
                                conn:Fire()
                            end
                        end
                    end)
                    -- InputHoldBegin/End
                    pcall(function()
                        prompt:InputHoldBegin()
                        task.wait(0.06)
                        prompt:InputHoldEnd()
                    end)
                end
            end

            -- Метод Atlas BSS: нажатие наэкранной кнопки ActivateButton
            local pg = player:FindFirstChild("PlayerGui")
            local scrGui = pg and pg:FindFirstChild("ScreenGui")
            local actBtn = scrGui and scrGui:FindFirstChild("ActivateButton")
            if actBtn and actBtn.Visible and actBtn.Position.Y.Offset >= 0 then
                pcall(function()
                    if type(firesignal) == "function" then
                        firesignal(actBtn.MouseButton1Click)
                        firesignal(actBtn.Activated)
                    end
                end)
            end

            -- VIM E key (имитация нажатия E рядом с плантатором)
            pcall(function()
                local vim = game:GetService("VirtualInputManager")
                if vim then
                    vim:SendKeyEvent(true, Enum.KeyCode.E, false, game)
                    task.wait(0.1)
                    vim:SendKeyEvent(false, Enum.KeyCode.E, false, game)
                end
            end)
            task.wait(0.1)

            -- Метод Atlas BSS: прямой вызов RemoteEvent PlanterModelCollect с ActorID
            local actorID = nil
            local lpTable = getLocalPlantersTable()
            if lpTable then
                local pTypes = getPlanterDisplayNames()
                for _, lp in pairs(lpTable) do
                    if lp.IsMine then
                        local dName = (pTypes and lp.Type and pTypes[lp.Type] and pTypes[lp.Type].DisplayName) or lp.DisplayName or lp.Type
                        if (dName and string.lower(tostring(dName)) == string.lower(tostring(info.type)))
                           or lp.Model == info.model
                           or (lp.Position and pPos and (lp.Position - pPos).Magnitude < 6) then
                            actorID = lp.ActorID
                            break
                        end
                    end
                end
                if not actorID then
                    for _, lp in pairs(lpTable) do
                        if lp.IsMine and lp.ActorID then
                            if lp.Model == info.model or (lp.Position and pPos and (lp.Position - pPos).Magnitude < 10) then
                                actorID = lp.ActorID
                                break
                            end
                        end
                    end
                end
            end

            local repEvents = rep:FindFirstChild("Events")
            if repEvents then
                local collectRemote = repEvents:FindFirstChild("PlanterModelCollect")
                if collectRemote then
                    if actorID then
                        log("Плантатор", string.format("⚡ [Atlas] Вызов PlanterModelCollect с ActorID: %s", tostring(actorID)))
                        pcall(function() collectRemote:FireServer(actorID) end)
                    end
                    pcall(function() collectRemote:FireServer(info.model) end)
                end
            end

            -- FireServer (на случай если промпт активировал серверное событие)
            if pCmd then
                pcall(function()
                    pCmd:FireServer({ Type = "Harvest", Planter = info.model, Confirm = true })
                    pCmd:FireServer({ Type = "Harvest", PlanterBox = info.model, Confirm = true })
                    pCmd:FireServer({ Type = "HarvestPlanter", Planter = info.model, Confirm = true })
                end)
            end
            if repPkg then
                pcall(function()
                    repPkg:FireServer({ Type = "Harvest", Planter = info.model, Confirm = true })
                    repPkg:FireServer({ Type = "HarvestPlanter", Planter = info.model, Confirm = true })
                end)
            end

            -- ШАГ 2: Ждём и подтверждаем "Yes" в диалоге сбора плантатора
            for attempt = 1, 25 do
                task.wait(0.1)
                if confirmPlanterHarvestModal() then
                    log("Плантатор", "✅ Нажали [Yes] в диалоге сбора плантатора!")
                    break
                end
                -- Повторно жмем E / ActivateButton / PlanterModelCollect если диалог не появился
                if attempt % 5 == 0 then
                    if actBtn and actBtn.Visible and actBtn.Position.Y.Offset >= 0 and type(firesignal) == "function" then
                        pcall(firesignal, actBtn.MouseButton1Click)
                        pcall(firesignal, actBtn.Activated)
                    end
                    if actorID and repEvents and repEvents:FindFirstChild("PlanterModelCollect") then
                        pcall(function() repEvents.PlanterModelCollect:FireServer(actorID) end)
                    end
                    pcall(function()
                        local vim = game:GetService("VirtualInputManager")
                        if vim then
                            vim:SendKeyEvent(true, Enum.KeyCode.E, false, game)
                            task.wait(0.08)
                            vim:SendKeyEvent(false, Enum.KeyCode.E, false, game)
                        end
                    end)
                    for _, prompt in ipairs(info.model:GetDescendants()) do
                        if prompt:IsA("ProximityPrompt") and type(fireproximityprompt) == "function" then
                            pcall(fireproximityprompt, prompt, 0, true)
                        end
                    end
                end
            end
            task.wait(0.3)

            -- ШАГ 3: Определяем поле, на котором стоял плантатор, и БЕГАЕМ по нему 10 секунд!
            LOOT_REPORT_STATS.planters = (LOOT_REPORT_STATS.planters or 0) + 1

            -- Определяем центр поля для сбора токенов
            local fieldZone = getActiveFlowerZone(pPos)
            if not fieldZone and info.field and info.field ~= "Unknown Field" then
                fieldZone = getFieldPart(info.field)
            end
            local fieldAnchorPos = (fieldZone and fieldZone.Position) or pPos

            log("Плантатор", string.format("🏃 Бегаю по полю %s 10 секунд, собираю выпавшие токены!", info.field or "?"))
            collectTokensFor(10, function() return not alive() end, fieldAnchorPos)
            activeTypes[info.type] = false
            task.wait(0.5)
        end
    end

    -- 2. Авто-посадка: ТОЛЬКО если был произведен сбор плантатора (harvestedAny == true)!
    -- НЕ летаем по полям сажать плантаторы при обычной проверке!
    if harvestedAny and CONFIG.PLANTERS_CONFIG then
        for pType, pCfg in pairs(CONFIG.PLANTERS_CONFIG) do
            if pCfg and pCfg.enabled == true and not activeTypes[pType] and pCfg.field and pCfg.field ~= "" then
                local fieldPart = getFieldPart(pCfg.field)
                local root = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
                if fieldPart and root and alive() then
                    local targetPos = getGroundPos(fieldPart.Position)
                    log("Плантатор", string.format("🌱 Плантатор %s только что собран! Сажаю заново на поле %s...", pType, pCfg.field))
                    moveRootToPosition(root, targetPos, 4)
                    task.wait(0.5)

                    if pCmd then
                        pcall(function()
                            pCmd:FireServer({ Type = "Plant", Planter = pType, Field = pCfg.field })
                            pCmd:FireServer({ Type = "Plant", Name = pType, Field = pCfg.field })
                        end)
                    end
                    if repPkg then
                        pcall(function()
                            repPkg:FireServer({ Type = "Plant", PlanterType = pType, Field = pCfg.field })
                        end)
                    end
                    local actCmd = rep:FindFirstChild("Events") and rep.Events:FindFirstChild("PlayerActivesCommand")
                    if actCmd then
                        pcall(function() actCmd:FireServer({ Name = pType }) end)
                    end
                    task.wait(0.8)
                    activeTypes[pType] = true
                end
            end
        end
    end
    return harvestedAny
end
harvestMaturePlanters = managePlanters

function findEligiblePuffshrooms()
    local results = {}
    local minR = PUFF_RARITY_PRIORITY[CONFIG.PUFF_MIN_RARITY] or 1
    local minLvl = tonumber(CONFIG.PUFF_MIN_LEVEL) or 1
    local maxLvl = tonumber(CONFIG.PUFF_MAX_LEVEL) or 25

    for _, entry in ipairs(findPuffshrooms()) do
        local lk = "PUFF_MIN_LEVEL_" .. string.upper(entry.rarity)
        local minL = math.clamp(tonumber(CONFIG[lk]) or 0, 0, 30)
        if (PUFF_RARITY_PRIORITY[entry.rarity] or 0) >= minR 
            and entry.level >= minL 
            and entry.level >= minLvl 
            and entry.level <= maxLvl then
            table.insert(results, entry)
        end
    end
    return results
end

function findPuffshroom()
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

function isPlayerBee(obj)
    if not obj then return false end
    local ok, res = pcall(function()
        -- 1. Быстрые атрибуты и маркеры
        if obj:FindFirstChild("Owner") or obj:FindFirstChild("Player") or obj:FindFirstChild("Bot") then
            return true
        end
        if obj:GetAttribute("Owner") or obj:GetAttribute("Player") then
            return true
        end
        -- 2. Быстрая проверка предков (ульи, персонажи, пчелы)
        local cur = obj
        while cur and cur ~= Workspace do
            local n = string.lower(cur.Name)
            if n == "bees" or n == "characters" or n == "hiveplatforms" or n == "hives" or n == "honeycombs" then
                return true
            end
            cur = cur.Parent
        end
        -- 3. Descendant of any player's Character
        for _, plr in ipairs(game:GetService("Players"):GetPlayers()) do
            if plr.Character and obj:IsDescendantOf(plr.Character) then return true end
        end
        -- 4. Descendant of Workspace.Bees
        local beesFolder = Workspace:FindFirstChild("Bees")
        if beesFolder and obj:IsDescendantOf(beesFolder) then return true end
        return false
    end)
    return ok and res
end

function isViciousFieldAllowed(obj)
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

function isViciousPart(obj)
    if not obj or isPlayerBee(obj) then return false end
    local ok, name = pcall(function() return obj.Name end)
    return ok and type(name) == "string"
        and string.find(string.lower(name), "vicious", 1, true) ~= nil
end

function getViciousTargetRoot(obj)
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
function findViciousSpikeInAllowedFields()
    local searchRoots = {}
    local p = Workspace:FindFirstChild("Particles")
    if p then
        local f2 = p:FindFirstChild("Folder2")
        if f2 then table.insert(searchRoots, f2) end
    end
    local m = Workspace:FindFirstChild("Monsters")
    if m then table.insert(searchRoots, m) end
    local h = Workspace:FindFirstChild("Happenings")
    if h then table.insert(searchRoots, h) end

    for _, root in ipairs(searchRoots) do
        local ok, children = pcall(function() return root:GetDescendants() end)
        if ok and children then
            for _, obj in ipairs(children) do
                local name = string.lower(tostring(obj.Name or ""))
                local isSpike = (name == "spike") or string.find(name, "vicious", 1, true)
                if isSpike and not isPlayerBee(obj) then
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
    return nil
end

function findVicious()
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
            if obj:IsA("Model") then
                local n = string.lower(tostring(obj.Name or ""))
                if string.find(n, "vicious", 1, true) and not isPlayerBee(obj) then
                    table.insert(candidates, obj)
                end
            end
        end
    end

    for _, cand in ipairs(candidates) do
        local n = string.lower(tostring(cand.Name or ""))
        if string.find(n, "vicious", 1, true) and not isPlayerBee(cand) then
            local root = getViciousTargetRoot(cand) or cand
            if root and root.Parent and isViciousFieldAllowed(root) then
                freshVicious = root
                return root
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
        local f2 = particles and particles:FindFirstChild("Folder2")
        if f2 then
            local function onAdded(obj)
                if not alive() then return end
                local name = string.lower(tostring(obj.Name or ""))
                if (name == "spike" or string.find(name, "vicious", 1, true)) and not isPlayerBee(obj) then
                    freshVicious = obj
                end
            end
            local function onRemoving(obj)
                if freshVicious == obj then freshVicious = nil end
            end
            trackConn(f2.ChildAdded:Connect(onAdded))
            trackConn(f2.ChildRemoved:Connect(onRemoving))
            findVicious(); return
        end
        task.wait(1)
    end
end)

function viciousDefeatedMessageVisible()
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

function fightVicious(vicious)
    if not vicious or not vicious.Parent then return false end
    vicious = getViciousTargetRoot(vicious) or vicious
    if not vicious or not vicious.Parent then return false end

    if not hasOwnHive() then
        pcall(ensureHiveClaimed)
    end

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

        lastActiveTargetPos = targetPos
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

function detectViciousKind(obj)
    if string.find(string.lower(obj.Name or ""), "rogue", 1, true) then return "rogue" end
    return "wild"
end

-- ══════════════════════════════════════════════════════════════════════
--  ЗАЩИТА ОТ СЕРВЕРОВ ДРУЗЕЙ (АНТИ-ПАЛЕВО)
-- ══════════════════════════════════════════════════════════════════════
local friendJobIds = {}
local friendUserIds = {}
local lastFriendsCheckAt = 0

function updateFriendsList()
    if os.clock() - lastFriendsCheckAt < 20 and next(friendUserIds) ~= nil then
        return friendJobIds, friendUserIds
    end
    lastFriendsCheckAt = os.clock()
    friendJobIds = {}
    friendUserIds = {}

    -- 1. Получение списка друзей онлайн через Roblox Player API
    pcall(function()
        local online = player:GetFriendsOnline(200)
        if type(online) == "table" then
            for _, f in ipairs(online) do
                if f.VisitorId then
                    friendUserIds[tonumber(f.VisitorId)] = true
                end
                if f.GameId and f.GameId ~= "" then
                    friendJobIds[tostring(f.GameId)] = true
                end
            end
        end
    end)

    -- 2. Получение списка друзей через HTTP API (Roblox Presence)
    pcall(function()
        local url = "https://friends.roblox.com/v1/users/" .. tostring(player.UserId) .. "/friends/online"
        local res = game:HttpGet(url)
        local d = HttpService:JSONDecode(res)
        if d and d.data then
            for _, f in ipairs(d.data) do
                if f.id then
                    friendUserIds[tonumber(f.id)] = true
                end
                if f.userPresence and f.userPresence.gameId and f.userPresence.gameId ~= "" then
                    friendJobIds[tostring(f.userPresence.gameId)] = true
                end
            end
        end
    end)

    return friendJobIds, friendUserIds
end

function checkFriendInServer()
    if CONFIG.AVOID_FRIENDS == false then return false end
    updateFriendsList()
    for _, plr in ipairs(Players:GetPlayers()) do
        if plr ~= player then
            local isFriend = false
            if friendUserIds[plr.UserId] then
                isFriend = true
            else
                local ok, res = pcall(function() return player:IsFriendsWith(plr.UserId) end)
                if ok and res then
                    isFriend = true
                    friendUserIds[plr.UserId] = true
                end
            end
            if isFriend then
                return true, plr.Name
            end
        end
    end
    return false
end

-- Автоматическая экстренная эвакуация, если друг подключился на сервер во время работы
safeConnect(Players, "PlayerAdded", function(newPlr)
    if CONFIG.AVOID_FRIENDS == false or newPlr == player then return end
    task.wait(0.5)
    local isFriend = false
    if friendUserIds[newPlr.UserId] then
        isFriend = true
    else
        local ok, res = pcall(function() return player:IsFriendsWith(newPlr.UserId) end)
        if ok and res then isFriend = true end
    end
    if isFriend then
        log("Защита", string.format("Друг '%s' зашел на сервер! Немедленно меняю сервер ради приватности...", newPlr.Name))
        task.spawn(function()
            if hopRandom then hopRandom() end
        end)
    end
end, "friend_evacuate")

local SERVER_CACHE_FILE = "bss_known_servers.json"
local serverPoolCache = {}
local lastServerFetchAt = 0

local function loadKnownServersFromDisk()
    pcall(function()
        if _G.BSS_KNOWN_SERVERS and type(_G.BSS_KNOWN_SERVERS) == "table" and #_G.BSS_KNOWN_SERVERS > 0 then
            serverPoolCache = _G.BSS_KNOWN_SERVERS
        elseif HAS_FS and isfile and isfile(SERVER_CACHE_FILE) then
            local raw = readfile(SERVER_CACHE_FILE)
            local decoded = HttpService:JSONDecode(raw)
            if type(decoded) == "table" and #decoded > 0 then
                serverPoolCache = decoded
            end
        end
    end)
end
loadKnownServersFromDisk()

local function saveKnownServersToDisk()
    pcall(function()
        _G.BSS_KNOWN_SERVERS = serverPoolCache
        if HAS_FS and writefile and #serverPoolCache > 0 then
            writefile(SERVER_CACHE_FILE, HttpService:JSONEncode(serverPoolCache))
        end
    end)
end

local function robustHttpGet(url)
    local req = (syn and syn.request) or (http and http.request) or http_request or request
    if type(req) == "function" then
        local ok, res = pcall(function()
            return req({
                Url = url,
                Method = "GET",
                Headers = {
                    ["User-Agent"] = "Mozilla/5.0 (Windows NT 10.0; Win64; x64) Roblox/WinInet",
                    ["Accept"] = "application/json",
                },
            })
        end)
        if ok and res then
            local status = tonumber(res.StatusCode or res.Status or res.status_code) or 0
            local body = tostring(res.Body or res.body or res.data or "")
            if status >= 200 and status < 300 and body ~= "" then
                return body, status
            elseif body ~= "" then
                return body, status
            end
        end
    end
    local ok, res = pcall(function() return game:HttpGet(url) end)
    if ok and res and res ~= "" then
        return tostring(res), 200
    end
    return nil, 0
end

function getServerList(cursor)
    local pid = tonumber(CONFIG.PLACE_ID) or (game and game.PlaceId) or 1537690962
    local now = os.clock()

    -- Если есть недавний кэш и нет курсора, отдаем кэш
    if (not cursor or cursor == "") and #serverPoolCache > 10 and (now - lastServerFetchAt < 20) then
        return serverPoolCache, nil
    end

    local urls = {
        "https://games.roblox.com/v1/games/" .. tostring(pid) .. "/servers/Public?sortOrder=Asc&limit=100",
        "https://games.roblox.com/v1/games/" .. tostring(pid) .. "/servers/Public?limit=100",
    }
    if cursor and cursor ~= "" then
        urls = {
            "https://games.roblox.com/v1/games/" .. tostring(pid) .. "/servers/Public?sortOrder=Asc&limit=100&cursor=" .. tostring(cursor),
            "https://games.roblox.com/v1/games/" .. tostring(pid) .. "/servers/Public?limit=100&cursor=" .. tostring(cursor),
        }
    end

    local data = nil
    for _, url in ipairs(urls) do
        local raw = robustHttpGet(url)
        if raw and raw ~= "" then
            local okDec, decoded = pcall(function() return HttpService:JSONDecode(raw) end)
            if okDec and decoded and decoded.data and type(decoded.data) == "table" and #decoded.data > 0 then
                data = decoded
                break
            end
        end
        task.wait(0.2)
    end

    if data and data.data then
        lastServerFetchAt = now
        -- Пополняем persistent serverPoolCache
        for _, s in ipairs(data.data) do
            if s and s.id then
                local exists = false
                for _, ex in ipairs(serverPoolCache) do
                    if ex.id == s.id then
                        ex.playing = s.playing or ex.playing
                        ex.maxPlayers = s.maxPlayers or ex.maxPlayers
                        exists = true
                        break
                    end
                end
                if not exists then
                    table.insert(serverPoolCache, s)
                end
            end
        end
        while #serverPoolCache > 150 do
            table.remove(serverPoolCache, 1)
        end
        saveKnownServersToDisk()
        return data.data, data.nextPageCursor
    end

    -- Если запрос к API заблокирован 429 или дал ошибку, возвращаем серверы из пула!
    if #serverPoolCache > 0 then
        return serverPoolCache, nil
    end

    return nil, nil
end

-- ══════════════════════════════════════════════════════════════════════
--  ТЕЛЕПОРТЫ + BYPASS
-- ══════════════════════════════════════════════════════════════════════
local failedServers = {}
local attemptCounter = 0
local lastTeleportAt = 0
local lastAttemptId = 0

function rememberFailure(jobId)
    if jobId then failedServers[jobId] = os.clock() end
    attemptCounter += 1
end
function clearFailures() failedServers = {}; attemptCounter = 0 end
function isFailed(jobId) return jobId ~= nil and failedServers[jobId] ~= nil end
function pruneFailures()
    local now = os.clock()
    local ttl = tonumber(CONFIG.FAILED_TTL) or 90
    for id, t in pairs(failedServers) do
        if now - t > ttl then failedServers[id] = nil end
    end
end

-- Черный список последних посещенных серверов (Blacklist до 1000 серверов, изолирован для каждого аккаунта)
local visitedGlobalKey = "BSS_VISITED_" .. tostring(player and player.UserId or "local")
local VISITED_SERVERS_FILE = "bss_visited_" .. tostring(player and player.UserId or "local") .. ".json"
local recentVisitedServers = {}
local visitedServersSet = {}

function loadRecentVisited()
    pcall(function()
        if _G[visitedGlobalKey] and type(_G[visitedGlobalKey]) == "table" then
            recentVisitedServers = _G[visitedGlobalKey]
        elseif HAS_FS and isfile and isfile(VISITED_SERVERS_FILE) then
            local raw = readfile(VISITED_SERVERS_FILE)
            local decoded = HttpService:JSONDecode(raw)
            if type(decoded) == "table" then recentVisitedServers = decoded end
        end
        visitedServersSet = {}
        for _, id in ipairs(recentVisitedServers) do
            local norm = normalizeJobId(id)
            if norm ~= "" then visitedServersSet[norm] = true end
        end
    end)
end
loadRecentVisited()

function addVisitedServer(jobId)
    if not jobId or jobId == "" then return end
    local norm = normalizeJobId(jobId)
    if norm == "" then return end
    visitedServersSet[norm] = true
    for i, id in ipairs(recentVisitedServers) do
        if normalizeJobId(id) == norm then table.remove(recentVisitedServers, i); break end
    end
    table.insert(recentVisitedServers, 1, jobId)
    while #recentVisitedServers > 1000 do
        local removed = table.remove(recentVisitedServers)
        if removed then visitedServersSet[normalizeJobId(removed)] = nil end
    end
    _G[visitedGlobalKey] = recentVisitedServers
    pcall(function()
        if HAS_FS and writefile then
            writefile(VISITED_SERVERS_FILE, HttpService:JSONEncode(recentVisitedServers))
        end
    end)
end

function isVisitedServer(jobId)
    if not jobId or jobId == "" then return true end
    local norm = normalizeJobId(jobId)
    if norm == "" then return true end
    if norm == normalizeJobId(game.JobId) then return true end
    return visitedServersSet[norm] == true
end

-- Добавляем текущий сервер в список посещенных навсегда
pcall(function() addVisitedServer(game.JobId) end)

function getCandidateServers()
    pruneFailures()
    updateFriendsList()

    local servers, nextCursor = getServerList()
    if not servers then return nil end

    -- Если на 1 странице мало серверов, догружаем 2 страницу для богатого выбора
    if nextCursor and #servers < 120 then
        local p2 = getServerList(nextCursor)
        if p2 and type(p2) == "table" then
            for _, s in ipairs(p2) do table.insert(servers, s) end
        end
    end

    local preferLow = CONFIG.PREFER_LOW_PLAYERS ~= false
    local minP = math.max(1, tonumber(CONFIG.MIN_PLAYERS) or 1)
    local maxP = math.max(minP, tonumber(CONFIG.MAX_PLAYERS) or 5)

    local out = {}
    local fallback = {}

    for _, s in ipairs(servers) do
        local sid = tostring(s.id or "")

        -- 1. СТРОГИЙ ЗАПРЕТ: Серверы друзей
        if CONFIG.AVOID_FRIENDS ~= false and friendJobIds[sid] then
            continue
        end

        -- 2. СТРОГИЙ ЗАПРЕТ: Текущий сервер, посещенные и сбойные (НИ ПРИ КАКИХ УСЛОВИЯХ НЕ ЗАХОДИТЬ)
        if sid == game.JobId or normalizeJobId(sid) == normalizeJobId(game.JobId) or isFailed(sid) or isVisitedServer(sid) then
            continue
        end

        -- 3. Разрешаем живые серверы (от 1 до maxPlayers - 1)
        local playing = tonumber(s.playing) or 0
        local maxPlr = tonumber(s.maxPlayers) or 6
        if playing < 1 or playing >= maxPlr then
            continue
        end

        -- 4. Проверка качества: пинг и fps (если переданы API)
        local ping = tonumber(s.ping) or 0
        local fps = tonumber(s.fps) or 60
        if (ping > 0 and ping > 300) or fps < 15 then
            continue
        end

        local entry = { id = sid, ping = ping, playing = playing }
        table.insert(fallback, entry)
        if preferLow then
            if playing >= minP and playing <= maxP then
                table.insert(out, entry)
            end
        else
            table.insert(out, entry)
        end
    end

    local pool = (#out > 0) and out or fallback
    if #pool == 0 then return {} end

    -- Перемешиваем пул для равномерного распределения, чтобы не долбиться всем ботам в один сервер
    for i = #pool, 2, -1 do
        local j = math.random(1, i)
        pool[i], pool[j] = pool[j], pool[i]
    end

    if preferLow then
        table.sort(pool, function(a, b)
            if a.playing ~= b.playing then
                return a.playing < b.playing
            end
            return (a.ping > 0 and b.ping > 0) and (a.ping < b.ping) or false
        end)
    end

    local limit = math.max(1, math.min(8, #pool))
    local best = {}
    for i = 1, limit do table.insert(best, pool[i].id) end
    return best
end

local pendingTarget, pendingAt, rejoinTries = nil, 0, 0
function resetRejoinTries() if rejoinTries > 0 then rejoinTries = 0 end end
function markTeleport(j) pendingTarget = j; pendingAt = os.clock(); resetRejoinTries() end
function clearTeleport() pendingTarget = nil; pendingAt = 0 end

function hopTo(jobId, placeId, isTaskHop)
    -- Защита от блокировки прыжка: если рюкзак пуст, флаг конвертации сбрасывается
    if isConvertingHoney then
        local bp = getBackpackPollen()
        if not bp or not bp.current or bp.current <= 0 then
            isConvertingHoney = false
        else
            log("Телепорт", "Отмена прыжка: идет конвертация меда в улье!")
            return false
        end
    end

    local normTarget = normalizeJobId(jobId)
    local normCurrent = normalizeJobId(game.JobId)
    if not jobId or jobId == "" or normTarget == "" or normTarget == normCurrent then
        log("Телепорт", "Отмена: попытка прыжка на текущий же сервер!")
        return false
    end
    if not isTaskHop and isVisitedServer(jobId) then
        log("Телепорт", string.format("СТРОГИЙ ЗАПРЕТ: Сервер %s уже посещался! Отмена телепорта.", tostring(jobId):sub(1, 12)))
        return false
    end
    lastAttemptId += 1
    lastTeleportAt = os.clock()
    markTeleport(jobId)
    flushSettings()
    armTeleportPersistence()
    if CONFIG.ENABLE_BYPASS then bypassNotify() end

    local pid = tonumber(placeId) or tonumber(CONFIG.PLACE_ID) or (game and game.PlaceId) or 1537690962
    log("Телепорт", string.format("Телепортируюсь на сервер %s (PlaceId: %d)...", tostring(jobId):sub(1, 12), pid))

    local ok, err = pcall(function()
        TeleportService:TeleportToPlaceInstance(pid, jobId, player)
    end)
    if not ok then
        rememberFailure(jobId)
        log("Телепорт", "Сбой вызова TeleportToPlaceInstance: " .. tostring(err))
        if CONFIG.ENABLE_BYPASS then bypassRecover("teleport_fail") end
        return false
    end
    addVisitedServer(jobId)
    return true
end

function hopRandom()
    -- Защита от зависшего флага конвертации
    if isConvertingHoney then
        local bp = getBackpackPollen()
        if not bp or not bp.current or bp.current <= 0 then
            isConvertingHoney = false
        else
            log("Телепорт", "Отмена прыжка: идет конвертация меда в улье!")
            return false
        end
    end
    armTeleportPersistence()

    -- 1. Поиск среди лучших кандидатов
    local candidates = getCandidateServers()
    if candidates and #candidates > 0 then
        for i = 1, math.min(6, #candidates) do
            local target = candidates[i]
            if target and target ~= game.JobId and hopTo(target) then return true end
            task.wait(0.3)
        end
    end

    -- 2. Если кандидаты в списке временных сбоев — сбрасываем список сбоев и пробуем снова
    clearFailures()
    candidates = getCandidateServers()
    if candidates and #candidates > 0 then
        for i = 1, math.min(6, #candidates) do
            local target = candidates[i]
            if target and target ~= game.JobId and hopTo(target) then return true end
            task.wait(0.3)
        end
    end

    -- 3. Резервный перебор ВСЕХ доступных серверов из кэша и API (СТРОГО sid ~= game.JobId)
    log("Телепорт", "Резервный перебор живых серверов...")
    local pool = {}
    if serverPoolCache and #serverPoolCache > 0 then
        for _, s in ipairs(serverPoolCache) do table.insert(pool, s) end
    end
    local fresh = getServerList()
    if fresh and type(fresh) == "table" then
        for _, s in ipairs(fresh) do table.insert(pool, s) end
    end

    if #pool > 0 then
        updateFriendsList()
        -- Перемешиваем пул для разнообразия
        for i = #pool, 2, -1 do
            local j = math.random(1, i)
            pool[i], pool[j] = pool[j], pool[i]
        end
        for _, s in ipairs(pool) do
            local sid = tostring(s.id or "")
            local p = tonumber(s.playing) or 0
            local maxP = tonumber(s.maxPlayers) or 6
            if sid ~= "" and sid ~= game.JobId and not isVisitedServer(sid)
                and (CONFIG.AVOID_FRIENDS == false or not friendJobIds[sid]) then
                if hopTo(sid) then return true end
                task.wait(0.25)
            end
        end
    end

    -- СТРОГИЙ ЗАПРЕТ: НИ В КОЕМ СЛУЧАЕ НЕ ВЫЗЫВАЕМ TeleportService:Teleport(placeId)!
    -- Именно он перезаходит на ТОТ ЖЕ САМЫЙ сервер!
    log("Телепорт", "Ожидаю появления новых серверов в пуле (без перезахода на старый)...")
    return false
end

-- СТОРОЖЕВОЙ ТАЙМЕР ЗАВИСШЕГО ПОДКЛЮЧЕНИЯ (ЗАЩИТА ОТ БЕСКОНЕЧНОЙ ЗАГРУЗКИ)
task.spawn(function()
    while true do
        if not alive() then return end
        task.wait(1)
        if pendingAt > 0 then
            if isConvertingHoney then
                clearTeleport()
            else
                local timeout = math.clamp(tonumber(CONFIG.CONNECT_TIMEOUT) or 10, 6, 14)
                if os.clock() - pendingAt >= timeout then
                    local target = pendingTarget
                    clearTeleport()
                    if target then
                        rememberFailure(target)
                        log("TP", string.format("Таймаут подключения (%dс) к серверу %s! Сервер завис на загрузке. Заношу в черный список и подключаюсь к новому серверу...", timeout, tostring(target)))
                    end

                    pcall(function()
                        if type(TeleportService.TeleportCancel) == "function" then
                            TeleportService:TeleportCancel()
                        end
                    end)

                    task.wait(0.5)
                    armTeleportPersistence()

                    -- Подключаемся к другому проверенному живому серверу
                    local newCandidates = getCandidateServers()
                    if newCandidates and #newCandidates > 0 then
                        local nextTarget = newCandidates[math.random(1, #newCandidates)]
                        hopTo(nextTarget)
                    else
                        rejoinSame()
                    end
                end
            end
        end
    end
end)

function rejoinSame()
    armTeleportPersistence()
    hopRandom()
end

local RETRYABLE_TELEPORT_CODES = { [2]=true, [3]=true, [279]=true, [267]=true }
local MAX_REJOIN_TRIES = 5
function rejoinRetry(code)
    rejoinTries += 1
    local attempt = rejoinTries
    task.wait(3) -- Таймаут перезахода: статично 3 секунды
    armTeleportPersistence()
    if CONFIG.ENABLE_BYPASS then bypassRecover("code_" .. tostring(code)) end
    clearTeleport()
    hopRandom()
end

local teleportLock = false
function handleTeleportFailure(reason)
    if teleportLock then return end
    teleportLock = true
    clearTeleport()
    task.wait(3) -- Таймаут перезахода: статично 3 секунды
    armTeleportPersistence()
    if CONFIG.ENABLE_BYPASS then bypassRecover(tostring(reason)) end
    if attemptCounter >= (tonumber(CONFIG.MAX_ATTEMPTS) or 3) then clearFailures() end
    hopRandom()
    teleportLock = false
end

-- Автоматический обход Ошибки 2 (Connection Failed / Reconnect) и дисконнектов
local lastErrorBypass = 0
function checkAndBypassError()
    if os.clock() - lastErrorBypass < 2 then return end

    local promptGui = nil
    pcall(function()
        promptGui = CoreGui:FindFirstChild("RobloxPromptGui") or (gethui and gethui():FindFirstChild("RobloxPromptGui"))
    end)
    if not promptGui then return end

    local overlay = promptGui:FindFirstChild("promptOverlay")
    if not overlay then return end

    local errorPrompt = overlay:FindFirstChild("ErrorPrompt")
    if not errorPrompt then return end

    local fullText = ""
    for _, d in ipairs(errorPrompt:GetDescendants()) do
        if d:IsA("TextLabel") and d.Text and d.Text ~= "" then
            fullText = fullText .. " " .. d.Text
        end
    end

    local isError2 = string.find(fullText, "Error Code: 2")
        or string.find(fullText, "Error Code: 279")
        or string.find(fullText, "Error Code: 277")
        or string.find(fullText, "Error Code: 268")
        or string.find(fullText, "Error Code: 273")
        or string.find(fullText, "Error Code: 267")
        or string.find(fullText, "Error Code: 260")
        or string.find(fullText, "Error Code: 261")
        or string.find(fullText, "Error Code: 262")
        or string.find(fullText, "Connection Failed")
        or string.find(fullText, "Failed to connect")
        or string.find(fullText, "Disconnected")
        or string.find(fullText, "Lost connection")
        or string.find(fullText, "kicked")
        or string.find(fullText, "unexpected client")
        or string.find(fullText, "shut down")

    if isError2 then
        lastErrorBypass = os.clock()
        log("TP", "[ОБХОД 267/279/DISCONNECT] Найдено окно сбоя подключения: " .. fullText:sub(1, 80))

        -- Вооружаем персистентность (queue_on_teleport) перед перезаходом
        armTeleportPersistence()
        if CONFIG.ENABLE_BYPASS then bypassRecover("error_kick_267") end
        if bypassActive and Bypass.Recover then pcall(Bypass.Recover, Bypass, "error_kick_267") end
        if bypassActive and Bypass.Bypass267 then pcall(Bypass.Bypass267, Bypass) end

        -- НИ В КОЕМ СЛУЧАЕ НЕ НАЖИМАЕМ Retry / Reconnect (так как это возвращает на тот же сервер!)
        log("TP", "[ОБХОД СБОЯ] Ухожу на новый сервер (не текущий!)...")
        pcall(function() errorPrompt.Visible = false end)
        task.wait(1.5)
        clearTeleport()
        armTeleportPersistence()
        hopRandom()
    end
end

pcall(function()
    local GuiService = game:GetService("GuiService")
    GuiService.ErrorMessageChanged:Connect(function()
        task.wait(0.5)
        pcall(checkAndBypassError)
    end)
end)

task.spawn(function()
    while true do
        pcall(checkAndBypassError)
        task.wait(1)
    end
end)

-- safeConnect уже объявлен в начале файла (для ранних подписок)

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
local RARITY_PRIORITY = {
    supreme   = 8,
    mythic    = 7,
    festive   = 7,
    legendary = 6,
    epic      = 5,
    gummy     = 4,
    rare      = 3,
    moon      = 2,
    basic     = 1,
    common    = 1,
    normal    = 1,
    unknown   = 1,
}
local RARITY_LABEL = {
    supreme   = "👑 Supreme",
    mythic    = "🌟 Mythic",
    festive   = "🎄 Festive",
    legendary = "💠 Legendary",
    epic      = "🥇 Epic",
    gummy     = "🍬 Gummy",
    rare      = "🥈 Rare",
    moon      = "🌙 Moon",
    basic     = "🌱 Basic",
    common    = "⚪ Common",
}

function hueOf(color)
    local h, s, v = Color3.toHSV(color); return h or 0, s or 0, v or 0
end

local RARITY_WORDS = {
    { level="supreme",   words={"supreme"} },
    { level="mythic",    words={"mythic"} },
    { level="festive",   words={"festive"} },
    { level="gummy",     words={"gummy"} },
    { level="legendary", words={"legendary"} },
    { level="epic",      words={"epic"} },
    { level="rare",      words={"uncommon","rare"} },
    { level="moon",      words={"moon","lunar"} },
    { level="basic",     words={"common","normal","basic"} },
}
function matchWords(text)
    if not text or text == "" then return nil end
    local low = string.lower(text)
    for _, entry in ipairs(RARITY_WORDS) do
        for _, w in ipairs(entry.words) do
            if string.find(low, w, 1, true) then return entry.level end
        end
    end
    return nil
end

function normalizeRarity(str)
    if not str then return "basic" end
    local s = string.lower(tostring(str))
    if string.find(s, "supreme", 1, true) then return "supreme" end
    if string.find(s, "mythic", 1, true) then return "mythic" end
    if string.find(s, "festive", 1, true) then return "festive" end
    if string.find(s, "legend", 1, true) then return "legendary" end
    if string.find(s, "epic", 1, true) then return "epic" end
    if string.find(s, "gummy", 1, true) then return "gummy" end
    if string.find(s, "rare", 1, true) or string.find(s, "uncommon", 1, true) then return "rare" end
    if string.find(s, "moon", 1, true) or string.find(s, "lunar", 1, true) then return "moon" end
    if string.find(s, "common", 1, true) or string.find(s, "normal", 1, true) or string.find(s, "basic", 1, true) then return "basic" end
    return "basic"
end

function sproutSparklesRate(sprout)
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

function sproutHasGlow(sprout)
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

function detectRarity(sprout)
    if not sprout then return nil, "no-object" end

    -- 1. Проверка по имени самого объекта
    local ownName = string.lower(tostring(sprout.Name or ""))
    local own = matchWords(ownName)
    if own then return own, "own-name" end

    -- 2. Проверка по тексту внутри TextLabel / GUI
    local okGui, descendants = pcall(function() return sprout:GetDescendants() end)
    local maxPollenNum = 0
    if okGui and descendants then
        for _, d in ipairs(descendants) do
            if d:IsA("TextLabel") or d:IsA("TextButton") then
                local txt = string.lower(tostring(d.Text or ""))
                local found = matchWords(txt)
                if found and (string.find(txt, "sprout", 1, true) or string.find(txt, "supreme", 1, true)
                    or string.find(txt, "legendary", 1, true) or string.find(txt, "common", 1, true)
                    or string.find(txt, "rare", 1, true) or string.find(txt, "epic", 1, true)
                    or string.find(txt, "gummy", 1, true) or string.find(txt, "moon", 1, true)) then
                    return found, "gui-explicit"
                end
                local cleanDigits = string.gsub(txt, "[^%d]", "")
                local pVal = tonumber(cleanDigits)
                if pVal and pVal > maxPollenNum and pVal >= 50000 then
                    maxPollenNum = pVal
                end
            end
        end
    end

    -- 3. Проверка по атрибутам модели
    local okAttr, attrs = pcall(function() return sprout:GetAttributes() end)
    if okAttr and attrs then
        for k, v in pairs(attrs) do
            local key = string.lower(tostring(k))
            if key == "rarity" or key == "sprouttype" or key == "sproutrarity" or key == "type" then
                local found = matchWords(tostring(v))
                if found then return found, "attribute:" .. key end
            end
        end
    end

    -- Собираем все BasePart детали ростка
    local parts = {}
    if sprout:IsA("BasePart") then table.insert(parts, sprout) end
    if okGui and descendants then
        for _, d in ipairs(descendants) do
            if d:IsA("BasePart") then table.insert(parts, d) end
        end
    end

    local hasGlow = sproutHasGlow(sprout)

    -- 4. ВЫСШИЙ ПРИОРИТЕТ: СВЕТЯЩИЕСЯ NEON РОСТКИ (В BSS СВЕТЯТСЯ ТОЛЬКО ДВА: SUPREME И MOON!)
    -- Supreme = Люминесцентный зеленый Neon.
    -- Moon = Люминесцентный синий/голубой Neon.
    for _, part in ipairs(parts) do
        local isNeon = (part.Material == Enum.Material.Neon)
        if isNeon or hasGlow then
            local h, sat, val = hueOf(part.Color)
            local deg = h * 360

            -- 👑 Supreme Sprout: яркий неоновый зеленый (80° - 155°)
            if deg >= 80 and deg <= 155 and sat >= 0.28 and val >= 0.40 then
                return "supreme", "sig:supreme-neon"
            end

            -- 🌙 Moon Sprout: яркий неоновый синий/голубой (180° - 245°)
            if isNeon and deg >= 180 and deg <= 245 and sat >= 0.28 and val >= 0.40 then
                return "moon", "sig:moon-neon"
            end
        end
    end

    -- 5. ЦВЕТНЫЕ РОСТКИ БЕЗ НЕОНА (GUMMY, LEGENDARY, EPIC, RARE)
    for _, part in ipairs(parts) do
        local h, sat, val = hueOf(part.Color)
        local deg = h * 360
        local r, g, b = part.Color.R, part.Color.G, part.Color.B
        local isGrey = math.abs(r - g) < 0.04 and math.abs(g - b) < 0.04 and math.abs(r - b) < 0.04

        -- 🍬 Gummy Sprout: прозрачный/полупрозрачный розовый/маджента (280° - 350°)
        if (part.Material == Enum.Material.Glass or part.Transparency > 0)
            and deg >= 280 and deg <= 350 and sat >= 0.42 and val >= 0.35 then
            return "gummy", "sig:gummy"
        end

        -- 💠 Legendary Sprout: бирюзовый/циан (160° - 198°), SmoothPlastic / Glass, СТРОГО НЕ NEON!
        if part.Material ~= Enum.Material.Neon and deg >= 160 and deg <= 198 and sat >= 0.25 and val >= 0.25 then
            return "legendary", "sig:legendary-teal"
        end

        -- 🥇 Epic Sprout: золотой/желтый (25° - 68°)
        if deg >= 25 and deg <= 68 and sat >= 0.35 and val >= 0.25 and not isGrey then
            return "epic", "sig:epic"
        end

        -- 🥈 Rare Sprout: СТРОГО серебристый/металлический/серый без зеленого оттенка
        -- У Common зеленоватый оттенок (g > r и g > b). У Rare - чистый серый/серебристый или металл!
        local isGreenish = (g > r and g > b and (g - r) >= 0.01) or (deg >= 70 and deg <= 155)
        if not isGreenish and (part.Material == Enum.Material.Metal or part.Material == Enum.Material.Glass or part.Reflectance > 0.05 or isGrey)
            and sat < 0.15 and val >= 0.45 and val <= 0.95 then
            return "rare", "sig:rare"
        end
    end

    -- 6. ПРОВЕРКА ПО ПЫЛЬЦЕ (ЕСЛИ ЦВЕТ ЕЩЁ НЕ ПОДГРУЗИЛСЯ)
    if maxPollenNum >= 14000000 then
        -- 14M+ бывает ТОЛЬКО у Supreme (15M-750M) и Legendary (10M-500M)
        for _, part in ipairs(parts) do
            local h = hueOf(part.Color)
            local deg = h * 360
            if deg >= 75 and deg <= 155 then
                return "supreme", "sig:supreme-pollen"
            end
            if deg >= 160 and deg <= 200 then
                return "legendary", "sig:legendary-pollen"
            end
        end
    end

    -- 7. ЕСЛИ РЕДКОСТЬ НЕ ОПРЕДЕЛЕНА — ЭТО 100% COMMON (BASIC) РОСТОК!
    -- В BSS у Common ростка нет специальной метки редкости.
    return "basic", "default:common"
end

function isRarityAtLeast(rarity, minimum)
    local got = rarity and RARITY_PRIORITY[rarity]
    local minValue = RARITY_PRIORITY[string.lower(tostring(minimum or "basic"))] or RARITY_PRIORITY.basic
    return got ~= nil and got >= minValue
end

function isSproutEligible(sprout)
    local rarity, source = detectRarity(sprout)
    if not rarity then return false, nil, source end
    local rLow = string.lower(tostring(rarity))
    if rLow == "common" or rLow == "normal" then rLow = "basic" end

    -- Проверяем индивидуальный переключатель редкостей (ВКЛ / ВЫКЛ)
    if CONFIG.ALLOWED_SPROUT_RARITIES and type(CONFIG.ALLOWED_SPROUT_RARITIES) == "table" then
        if CONFIG.ALLOWED_SPROUT_RARITIES[rLow] ~= nil then
            return (CONFIG.ALLOWED_SPROUT_RARITIES[rLow] == true), rarity, source
        end
    end

    return isRarityAtLeast(rarity, CONFIG.MIN_RARITY), rarity, source
end

function findLootableSprout()
    local best, bestPriority = nil, -1
    local function consider(obj)
        if not obj or not isSprout(obj) then return end
        local eligible, rarity = isSproutEligible(obj)
        local priority = rarity and RARITY_PRIORITY[rarity] or 0
        if eligible and priority > bestPriority then best, bestPriority = obj, priority end
    end
    if freshSprout and freshSprout.Parent then consider(freshSprout) end
    for _, folder in ipairs(sproutFolders) do
        if folder and folder.Parent then
            consider(folder)
            local ok, descendants = pcall(function() return folder:GetDescendants() end)
            if ok and descendants then
                for _, child in ipairs(descendants) do consider(child) end
            end
        end
    end
    -- Прямой fallback по Workspace
    local h = Workspace:FindFirstChild("Happenings")
    if h then
        local hs = h:FindFirstChild("Sprouts")
        if hs then
            local okH, hDesc = pcall(function() return hs:GetDescendants() end)
            if okH and hDesc then
                for _, child in ipairs(hDesc) do consider(child) end
            end
        end
    end
    local ws = Workspace:FindFirstChild("Sprouts")
    if ws then
        local okW, wDesc = pcall(function() return ws:GetDescendants() end)
        if okW and wDesc then
            for _, child in ipairs(wDesc) do consider(child) end
        end
    end
    local part = Workspace:FindFirstChild("Particles") and Workspace.Particles:FindFirstChild("Folder2")
    if part then
        local okP, pDesc = pcall(function() return part:GetDescendants() end)
        if okP and pDesc then
            for _, child in ipairs(pDesc) do consider(child) end
        end
    end
    if not best then
        best = findSprout()
    end
    return best
end

function findAnySprout()
    -- 1. Сначала проверяем лучший подходящий росток
    local s = findLootableSprout()
    if s and isSproutAlive(s) then return s end

    -- 2. Затем общий поиск findSprout
    s = findSprout()
    if s and isSproutAlive(s) then return s end

    -- 3. Прямой поиск в Happenings.Sprouts
    local h = Workspace:FindFirstChild("Happenings")
    if h then
        local hs = h:FindFirstChild("Sprouts")
        if hs then
            local okH, hDesc = pcall(function() return hs:GetDescendants() end)
            if okH and hDesc then
                for _, child in ipairs(hDesc) do
                    if isSprout(child) and isSproutAlive(child) then return child end
                end
            end
        end
    end

    -- 4. Прямой поиск в Workspace.Sprouts
    local ws = Workspace:FindFirstChild("Sprouts")
    if ws then
        local okW, wDesc = pcall(function() return ws:GetDescendants() end)
        if okW and wDesc then
            for _, child in ipairs(wDesc) do
                if isSprout(child) and isSproutAlive(child) then return child end
            end
        end
    end

    -- 5. Прямой поиск в Workspace.Particles.Folder2
    local part = Workspace:FindFirstChild("Particles") and Workspace.Particles:FindFirstChild("Folder2")
    if part then
        local okP, pDesc = pcall(function() return part:GetDescendants() end)
        if okP and pDesc then
            for _, child in ipairs(pDesc) do
                if isSprout(child) and isSproutAlive(child) then return child end
            end
        end
    end

    -- 6. Прямой поиск по прямым потомкам Workspace
    local okCh, chList = pcall(function() return Workspace:GetChildren() end)
    if okCh and chList then
        for _, child in ipairs(chList) do
            if isSprout(child) and isSproutAlive(child) then return child end
        end
    end

    return nil
end

-- ══════════════════════════════════════════════════════════════════════
--  УЛЕЙ / HONEY / РЮКЗАК / ТОКЕНЫ
-- ══════════════════════════════════════════════════════════════════════

function promptWorldPos(prompt)
    if not prompt or not prompt.Parent then return nil end
    local parent = prompt.Parent
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
    return worldPos(parent)
end

function findPromptByKeyword(keyword)
    local needle = string.lower(tostring(keyword or ""))
    local results = {}
    local searchRoots = {}
    local hp = Workspace:FindFirstChild("HivePlatforms")
    if hp then table.insert(searchRoots, hp) end
    local npc = Workspace:FindFirstChild("NPCs")
    if npc then table.insert(searchRoots, npc) end
    local hap = Workspace:FindFirstChild("Happenings")
    if hap then table.insert(searchRoots, hap) end

    local descendants = {}
    for _, root in ipairs(searchRoots) do
        local ok, desc = pcall(function() return root:GetDescendants() end)
        if ok and desc then
            for _, d in ipairs(desc) do table.insert(descendants, d) end
        end
    end
    if #descendants == 0 then
        local ok, d = pcall(function() return Workspace:GetChildren() end)
        if ok and d then descendants = d end
    end
    local words = {}
    for word in string.gmatch(needle, "%S+") do table.insert(words, word) end
    local isLookingForClaim = string.find(needle, "claim", 1, true) or string.find(needle, "занять", 1, true)
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
            local matched = false
            if needle == "" then
                matched = true
            elseif isLookingForClaim then
                matched = string.find(haystack, "claim", 1, true) or string.find(haystack, "занять", 1, true)
            else
                matched = string.find(haystack, needle, 1, true) ~= nil
                if not matched and #words > 0 then
                    matched = true
                    for _, word in ipairs(words) do
                        if not string.find(haystack, word, 1, true) then matched = false; break end
                    end
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

function findPromptNearPosition(keyword, position, maxDistance)
    if not position then return nil end
    local best, bestD = nil, maxDistance or 25
    local prompts = findPromptByKeyword(keyword)
    for _, entry in ipairs(prompts) do
        local d = (entry.pos - position).Magnitude
        if d < bestD then
            best, bestD = entry, d
        end
    end
    return best
end

function findYellowHivePads()
    local results = {}
    local hp = Workspace:FindFirstChild("HivePlatforms")
    if not hp then return results end
    local ok, descendants = pcall(function() return hp:GetDescendants() end)
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

-- Точный улей, занятый на ТЕКУЩЕМ сервере (сбрасывается на каждом новом сервере)
myClaimedHiveSlot = nil
myClaimedHivePos = nil
local cachedHiveSlot = nil
local cachedHivePos = nil
_G.BSS_CLAIMED_HIVE_POS = nil

function saveMyHivePos(pos)
    if not pos or typeof(pos) ~= "Vector3" then return end
    cachedHivePos = pos
    myClaimedHivePos = pos
    _G.BSS_CLAIMED_HIVE_POS = pos
    log("Улей", string.format("Свой улей закреплен: %.1f, %.1f, %.1f", pos.X, pos.Y, pos.Z))
end

function loadSavedHivePos()
    if myClaimedHivePos and typeof(myClaimedHivePos) == "Vector3" then return myClaimedHivePos end
    if cachedHivePos and typeof(cachedHivePos) == "Vector3" then return cachedHivePos end
    if _G.BSS_CLAIMED_HIVE_POS and typeof(_G.BSS_CLAIMED_HIVE_POS) == "Vector3" then
        return _G.BSS_CLAIMED_HIVE_POS
    end
    return nil
end

-- Прямой поиск промпта Make Honey своего улья в Workspace
function findMyHivePromptAndPos()
    local roots = {}
    local hp = Workspace:FindFirstChild("HivePlatforms")
    if hp then table.insert(roots, hp) end
    local hc = Workspace:FindFirstChild("Honeycombs")
    if hc then table.insert(roots, hc) end

    for _, root in ipairs(roots) do
        local ok, children = pcall(function() return root:GetDescendants() end)
        if ok and children then
            for _, obj in ipairs(children) do
                if obj:IsA("ProximityPrompt") then
                    local act = string.lower(tostring(obj.ActionText or ""))
                    local objTxt = string.lower(tostring(obj.ObjectText or ""))
                    if string.find(act, "make", 1, true) or string.find(act, "honey", 1, true)
                        or string.find(objTxt, "make", 1, true) or string.find(objTxt, "honey", 1, true) then
                        local p = promptWorldPos(obj)
                        if p then return obj, p end
                    end
                end
            end
        end
    end

    -- Fallback: смотрим все модели в Workspace с именем hive
    local okW, wChildren = pcall(function() return Workspace:GetChildren() end)
    if okW and wChildren then
        for _, obj in ipairs(wChildren) do
            local n = string.lower(obj.Name)
            if string.find(n, "hive", 1, true) or string.find(n, "honey", 1, true) then
                local okD, d = pcall(function() return obj:GetDescendants() end)
                if okD and d then
                    for _, x in ipairs(d) do
                        if x:IsA("ProximityPrompt") then
                            local act = string.lower(tostring(x.ActionText or ""))
                            if string.find(act, "make", 1, true) or string.find(act, "honey", 1, true) then
                                local p = promptWorldPos(x)
                                if p then return x, p end
                            end
                        end
                    end
                end
            end
        end
    end
    return nil, nil
end

function getHivePlatformRecords()
    local records = {}
    local folder = Workspace:FindFirstChild("HivePlatforms") or Workspace:FindFirstChild("Hives")
    if not folder then return records end
    for _, model in ipairs(folder:GetChildren()) do
        if model:IsA("Model") or model:IsA("Folder") then
            local hiveRef = model:FindFirstChild("Hive")
            local playerRef = model:FindFirstChild("PlayerRef")
                or model:FindFirstChild("Player")
                or model:FindFirstChild("Owner")
                or model:FindFirstChildWhichIsA("ObjectValue")
                or model:FindFirstChildWhichIsA("StringValue")
            local platform = model:FindFirstChild("Circle")
                or model:FindFirstChild("Circle2")
                or model:FindFirstChild("Platform")
                or model:FindFirstChild("Pad")
                or model:FindFirstChildWhichIsA("BasePart")
            if not platform then
                for _, desc in ipairs(model:GetDescendants()) do
                    if desc:IsA("BasePart") and (desc.Name == "Circle" or desc.Name == "Pad" or desc.Name == "Platform") then
                        platform = desc
                        break
                    end
                end
            end
            if platform and platform:IsA("BasePart") then
                table.insert(records, {
                    model = model,
                    hiveRef = hiveRef,
                    playerRef = playerRef,
                    platform = platform,
                    pos = platform.Position,
                })
            end
        end
    end
    return records
end

function findAssignedHiveSlot()
    -- 0. Если улей уже был занят нами на этом сервере
    if myClaimedHiveSlot and myClaimedHiveSlot.pos then
        return myClaimedHiveSlot
    end
    if cachedHiveSlot and cachedHiveSlot.pos then
        return cachedHiveSlot
    end

    -- 1. Проверяем records в HivePlatforms СТРОГО по имени, DisplayName или UserId нашего аккаунта!
    local ok, records = pcall(getHivePlatformRecords)
    if ok and records then
        local myName = string.lower(player.Name)
        local myDisplay = player.DisplayName and string.lower(player.DisplayName) or nil
        local myId = tostring(player.UserId)

        for _, slot in ipairs(records) do
            local isMe = false
            if slot.playerRef then
                local val = slot.playerRef.Value
                if val == player or (player.Character and val == player.Character) then
                    isMe = true
                elseif type(val) == "string" and (string.lower(val) == myName or (myDisplay and string.lower(val) == myDisplay)) then
                    isMe = true
                elseif tostring(val) == player.Name or (myDisplay and tostring(val) == player.DisplayName) then
                    isMe = true
                end
            end

            if not isMe and slot.model then
                local ownerAttr = slot.model:GetAttribute("Owner") or slot.model:GetAttribute("Player") or slot.model:GetAttribute("UserId")
                if ownerAttr then
                    local sAttr = string.lower(tostring(ownerAttr))
                    if sAttr == myName or (myDisplay and sAttr == myDisplay) or tostring(ownerAttr) == myId then
                        isMe = true
                    end
                end
            end

            -- Проверяем табличку улья (TextLabel)
            if not isMe and slot.model then
                for _, d in ipairs(slot.model:GetDescendants()) do
                    if d:IsA("TextLabel") then
                        local txt = string.lower(tostring(d.Text or ""))
                        if txt == myName or (myDisplay and txt == myDisplay) then
                            isMe = true
                            break
                        end
                    end
                end
            end

            if isMe then
                myClaimedHiveSlot = slot
                myClaimedHivePos = slot.pos
                cachedHiveSlot = slot
                cachedHivePos = slot.pos
                _G.BSS_CLAIMED_HIVE_POS = slot.pos
                return slot
            end
        end
    end

    -- 3. Проверяем Workspace.Honeycombs (ульи игроков с табличками имени)
    local hc = Workspace:FindFirstChild("Honeycombs")
    if hc then
        local myName = string.lower(player.Name)
        local myDisplay = player.DisplayName and string.lower(player.DisplayName) or nil
        for _, hModel in ipairs(hc:GetChildren()) do
            local isHcMe = false
            local o = hModel:FindFirstChild("Owner") or hModel:FindFirstChild("Player")
            if o and (o.Value == player or string.lower(tostring(o.Value)) == myName) then
                isHcMe = true
            end
            if not isHcMe then
                local oAttr = hModel:GetAttribute("Owner") or hModel:GetAttribute("Player")
                if oAttr and (oAttr == player.UserId or string.lower(tostring(oAttr)) == myName) then
                    isHcMe = true
                end
            end
            if not isHcMe then
                for _, d in ipairs(hModel:GetDescendants()) do
                    if d:IsA("TextLabel") then
                        local txt = string.lower(tostring(d.Text or ""))
                        if txt == myName or (myDisplay and txt == myDisplay)
                            or string.find(txt, myName, 1, true)
                            or (myDisplay and string.find(txt, myDisplay, 1, true)) then
                            isHcMe = true
                            break
                        end
                    end
                end
            end
            if isHcMe then
                local hcPos = hModel:GetPivot().Position
                local records = getHivePlatformRecords()
                local bestSlot, bestDist = nil, math.huge
                for _, s in ipairs(records) do
                    local d = (s.pos - hcPos).Magnitude
                    if d < bestDist then
                        bestDist = d
                        bestSlot = s
                    end
                end
                if bestSlot then
                    cachedHiveSlot = bestSlot
                    cachedHivePos = bestSlot.pos
                    _G.BSS_CLAIMED_HIVE_POS = bestSlot.pos
                    return bestSlot
                else
                    local fallbackSlot = { pos = hcPos, model = hModel, platform = hModel, prompt = nil }
                    cachedHiveSlot = fallbackSlot
                    cachedHivePos = hcPos
                    _G.BSS_CLAIMED_HIVE_POS = hcPos
                    return fallbackSlot
                end
            end
        end
    end

    return nil
end

function slotIsFree(slot)
    if not slot then return false end
    if slot.playerRef and slot.playerRef.Value == nil then return true end
    if slot.model then
        for _, d in ipairs(slot.model:GetDescendants()) do
            if d:IsA("ProximityPrompt") then
                local txt = string.lower(tostring(d.ActionText or ""))
                if string.find(txt, "claim", 1, true) or string.find(txt, "занять", 1, true) then
                    return true
                end
            end
        end
    end
    return false
end

function claimHive()
    local root = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
    local hum = player.Character and player.Character:FindFirstChildOfClass("Humanoid")
    if not root or not hum or hum.Health <= 0 then return false end

    -- Если улей уже РЕАЛЬНО занят нами на текущем сервере
    local assigned = findAssignedHiveSlot()
    if assigned and assigned.pos then
        cachedHiveSlot = assigned
        saveMyHivePos(assigned.pos)
        log("Улей", "Свой улей уже занят на этом сервере")
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
                local pref = m:FindFirstChild("PlayerRef") or m:FindFirstChild("Player") or m:FindFirstChild("Owner")
                local plat = m:FindFirstChild("Circle") or m:FindFirstChild("Platform") or m:FindFirstChild("Pad") or m:FindFirstChildWhichIsA("BasePart")
                if plat and plat:IsA("BasePart") then
                    if not pref or pref.Value == nil then
                        table.insert(freeSlots, { model = m, playerRef = pref, platform = plat, pos = plat.Position })
                    end
                end
            end
        end
    end

    if #freeSlots == 0 then
        for _, entry in ipairs(findPromptByKeyword("claim")) do
            table.insert(freeSlots, { model = entry.slot, platform = entry.slot, pos = entry.pos, prompt = entry.prompt })
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

        log("Улей", "Встаю на платформу улья: " .. tostring(slot.model and slot.model.Name or "Pad"))
        local standPos = slot.pos + Vector3.new(0, 3.2, 0)
        saveMyHivePos(slot.pos) -- Запоминаем позицию сразу при попытке занять!

        moveRootToPosition(root, standPos, 4)
        task.wait(0.15)

        root = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
        hum = player.Character and player.Character:FindFirstChildOfClass("Humanoid")
        if not root or not hum or hum.Health <= 0 then return false end

        setFlightNoclip(false)
        pcall(function()
            root.CFrame = CFrame.new(standPos)
            root.AssemblyLinearVelocity = Vector3.zero
            root.AssemblyAngularVelocity = Vector3.zero
            hum:ChangeState(Enum.HumanoidStateType.Landed)
            hum:ChangeState(Enum.HumanoidStateType.Running)
        end)
        task.wait(0.2)

        local prompt = slot.prompt or (slot.platform and slot.platform:FindFirstChildWhichIsA("ProximityPrompt"))
        if not prompt and slot.model then
            prompt = slot.model:FindFirstChildWhichIsA("ProximityPrompt", true)
        end

        log("Улей", prompt and "ProximityPrompt найден — активирую..." or "Активирую захват стойки...")

        local tryStart = os.clock()
        while alive() and os.clock() - tryStart < 2.0 do
            local found = findAssignedHiveSlot()
            if found then
                log("Улей", "Улей успешно занят!")
                cachedHiveSlot = found
                saveMyHivePos(found.pos)
                return true
            end

            if prompt and prompt.Parent then
                pcall(function()
                    prompt.Enabled = true
                    prompt.RequiresLineOfSight = false
                    prompt.HoldDuration = 0
                end)
                if type(fireproximityprompt) == "function" then
                    pcall(fireproximityprompt, prompt, 0, true)
                end
            end

            pcall(function()
                local vim = game:GetService("VirtualInputManager")
                if vim then
                    vim:SendKeyEvent(true, Enum.KeyCode.E, false, game)
                    task.wait(0.08)
                    vim:SendKeyEvent(false, Enum.KeyCode.E, false, game)
                end
            end)

            pcall(function()
                local rep = game:GetService("ReplicatedStorage")
                local ev = rep:FindFirstChild("Events")
                if ev then
                    local claimEv = ev:FindFirstChild("ClaimHive") or ev:FindFirstChild("PlayerHiveCommand")
                    if claimEv and claimEv:IsA("RemoteEvent") then
                        claimEv:FireServer(slot.model)
                    end
                end
            end)

            task.wait(0.25)
        end

        -- Мы завершили захват этой свободной платформы!
        myClaimedHiveSlot = slot
        myClaimedHivePos = slot.pos
        cachedHiveSlot = slot
        cachedHivePos = slot.pos
        _G.BSS_CLAIMED_HIVE_POS = slot.pos
        log("Улей", string.format("Свой улей успешно занят на платформе: %.1f, %.1f, %.1f!", slot.pos.X, slot.pos.Y, slot.pos.Z))
        return true
    end

    local finalCheck = findAssignedHiveSlot()
    if finalCheck then
        myClaimedHiveSlot = finalCheck
        myClaimedHivePos = finalCheck.pos
        cachedHiveSlot = finalCheck
        cachedHivePos = finalCheck.pos
        return true
    end
    return false
end

function findMyHive()
    local owned = findAssignedHiveSlot()
    if not owned then
        local p, pos = findMyHivePromptAndPos()
        if p and pos then
            return { pos = pos, slot = nil, prompt = p }
        end
        return nil
    end
    if owned.prompt then
        return { pos = owned.pos, slot = owned, prompt = owned.prompt }
    end
    if owned.model then
        for _, desc in ipairs(owned.model:GetDescendants()) do
            if desc:IsA("ProximityPrompt") then
                return { pos=owned.pos, slot=owned, prompt=desc }
            end
        end
    end
    if owned.hiveRef and owned.hiveRef.Value then
        for _, desc in ipairs(owned.hiveRef.Value:GetDescendants()) do
            if desc:IsA("ProximityPrompt") then
                return { pos=owned.pos, slot=owned, prompt=desc }
            end
        end
    end
    local p, pos = findMyHivePromptAndPos()
    if p then
        return { pos = pos or owned.pos, slot = owned, prompt = p }
    end
    return { pos=owned.pos, slot=owned, prompt=nil }
end

function stripCommas(s) return (tostring(s):gsub(",", "")) end

function getBackpackPollen()
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

function isBackpackFull()
    local info = getBackpackPollen()
    if not info or not info.max or info.max <= 0 then return false end
    if not info.current or info.current <= 0 then return false end
    local threshold = tonumber(CONFIG.BACKPACK_FILL_THRESHOLD) or 0.95
    return info.current >= info.max or info.ratio >= threshold
end

local useSprinklerBuilder
local collectTokensFor

function triggerMakeHoneyAction(prompt)
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

function makeHoney()
    local char = player.Character
    local root = char and char:FindFirstChild("HumanoidRootPart")
    local hum = char and char:FindFirstChildOfClass("Humanoid")
    if not root or not hum or hum.Health <= 0 then return false end

    -- Если пыльцы нет вообще (0), не разгружаемся
    local info = getBackpackPollen()
    if not info or not info.current or info.current <= 0 then
        return true
    end

    -- Если улей еще не был занят на этом сервере — сначала занимаем СВОЙ улей!
    if not hasOwnHive() then
        log("Honey", "Свой улей еще не занят. Сначала занимаю свободный улей...")
        claimHive()
    end

    local mySlot = myClaimedHiveSlot or findAssignedHiveSlot()
    local hivePos = (mySlot and mySlot.pos) or myClaimedHivePos

    if not hivePos then
        log("Honey", "Свой улей не найден, повторная попытка захвата...")
        if claimHive() then
            mySlot = myClaimedHiveSlot or findAssignedHiveSlot()
            hivePos = (mySlot and mySlot.pos) or myClaimedHivePos
        end
    end

    if not hivePos then
        log("Honey", "Ошибка: не удалось определить свой улей на этом сервере")
        return false
    end

    isConvertingHoney = true

    -- Немедленно останавливаем копание и сбор токенов, чтобы не перебивали полет
    stopAutoDig()
    tokenCollectorBusy = false
    patrolTarget = nil

    log("Honey", string.format("Рюкзак полон! Лечу строго в СВОЙ улей (%.1f, %.1f, %.1f)...", hivePos.X, hivePos.Y, hivePos.Z))
    -- Подлетаем прямо к платформе СВОЕГО улья
    moveRootToPosition(root, hivePos + Vector3.new(0, 3.5, 0), 10)

    -- Отключаем ноклип и встаем ровно на платформу СВОЕГО улья
    setFlightNoclip(false)
    pcall(function()
        root.CFrame = CFrame.new(hivePos + Vector3.new(0, 3.2, 0))
        root.AssemblyLinearVelocity = Vector3.zero
        root.AssemblyAngularVelocity = Vector3.zero
        hum:ChangeState(Enum.HumanoidStateType.Landed)
        hum:ChangeState(Enum.HumanoidStateType.Running)
    end)
    task.wait(0.2)

    -- Ищем Prompt "Make Honey" СТРОГО на модели СВОЕГО улья или в пределах 14 стадс от нашей платформы
    local function findNearbyMakeHoneyPrompt()
        local myModel = mySlot and mySlot.model
        if myModel then
            for _, d in ipairs(myModel:GetDescendants()) do
                if d:IsA("ProximityPrompt") then
                    local act = string.lower(tostring(d.ActionText or ""))
                    local objT = string.lower(tostring(d.ObjectText or ""))
                    if string.find(act, "make", 1, true) or string.find(act, "honey", 1, true)
                        or string.find(objT, "make", 1, true) or string.find(objT, "honey", 1, true) then
                        return d
                    end
                end
            end
        end
        for _, p in ipairs(Workspace:GetDescendants()) do
            if p:IsA("ProximityPrompt") then
                local pPos = promptWorldPos(p)
                if pPos and (pPos - hivePos).Magnitude <= 14 then
                    local act = string.lower(tostring(p.ActionText or ""))
                    local objT = string.lower(tostring(p.ObjectText or ""))
                    if string.find(act, "make", 1, true) or string.find(act, "honey", 1, true)
                        or string.find(objT, "make", 1, true) or string.find(objT, "honey", 1, true) then
                        return p
                    end
                end
            end
        end
        return nil
    end

    local activePrompt = findNearbyMakeHoneyPrompt()

    -- Постоянное включение и удержание Make Honey без отжатия до полной расконвертации
    log("Honey", "Включаю Make Honey (постоянное удержание до 0 пыльцы)...")

    local function engageMakeHoney()
        activePrompt = activePrompt or findNearbyMakeHoneyPrompt()
        if activePrompt and activePrompt.Parent then
            pcall(function()
                activePrompt.Enabled = true
                activePrompt.RequiresLineOfSight = false
                activePrompt.MaxActivationDistance = 9999
                activePrompt.HoldDuration = 0
            end)
            if type(fireproximityprompt) == "function" then
                pcall(fireproximityprompt, activePrompt, 0, true)
                pcall(fireproximityprompt, activePrompt)
            end
            pcall(function()
                activePrompt:InputHoldBegin()
            end)
        end
        pcall(function()
            local vim = game:GetService("VirtualInputManager")
            if vim then
                vim:SendKeyEvent(true, Enum.KeyCode.E, false, game)
            end
        end)
        pcall(function()
            local vu = game:GetService("VirtualUser")
            if vu then
                vu:CaptureController()
                vu:SetKeyDown("0x65")
            end
        end)
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

    local function releaseMakeHoney()
        pcall(function()
            local vim = game:GetService("VirtualInputManager")
            if vim then
                vim:SendKeyEvent(false, Enum.KeyCode.E, false, game)
            end
        end)
        pcall(function()
            local vu = game:GetService("VirtualUser")
            if vu then
                vu:SetKeyUp("0x65")
            end
        end)
        if activePrompt and activePrompt.Parent then
            pcall(function()
                activePrompt:InputHoldEnd()
            end)
        end
    end

    -- Первичная активация Make Honey
    engageMakeHoney()

    -- Ждём ПОЛНОЙ разгрузки рюкзака (пыльца -> 0), НЕ отжимая Make Honey!
    local maxWait = tonumber(CONFIG.HONEY_MAX_WAIT) or 120
    local t0 = os.clock()
    local lastEngageAt = os.clock()

    while alive() and (os.clock() - t0 < maxWait) do
        -- Плавное удержание персонажа на улье (БЕЗ дерганья и постоянного CFrame-телепорта)
        pcall(function()
            local curPos = root.Position
            local dist = (curPos - hivePos).Magnitude
            if dist > 8 then
                hum:MoveTo(hivePos + Vector3.new(0, 3.2, 0))
            else
                root.AssemblyLinearVelocity = Vector3.new(0, root.AssemblyLinearVelocity.Y, 0)
            end
        end)

        -- Каждые 0.4 сек повторно укрепляем удержание (InputHoldBegin + KeyDown)
        if os.clock() - lastEngageAt >= 0.4 then
            lastEngageAt = os.clock()
            engageMakeHoney()
        end

        local currentInfo = getBackpackPollen()
        if currentInfo then
            -- Полная разгрузка: пыльцы 0 (или менее 1% от объема)
            if currentInfo.current <= 0 or currentInfo.ratio <= 0.01 then
                releaseMakeHoney()
                isConvertingHoney = false
                log("Honey", string.format("Рюкзак ПОЛНОСТЬЮ разгружен (0 / %d)! Отжимаю Make Honey и возвращаюсь к фарму.", currentInfo.max))
                task.wait(0.3)
                return true
            end
        else
            if os.clock() - t0 > 15 then
                releaseMakeHoney()
                isConvertingHoney = false
                log("Honey", "Индикатор пыльцы пуст, разгрузка завершена")
                return true
            end
        end

        task.wait(0.1)
    end

    -- В случае таймаута отпускаем
    releaseMakeHoney()
    isConvertingHoney = false
    log("Honey", "Разгрузка завершена по таймауту")
    return true
end

local TOKEN_P1 = {
    "ticket", "glitter", "glue", "extract", "star jelly", "magic bean", "bean",
    "royal jelly", "atomic treat", "star treat", "neonberry",
    "moon charm", "whirligig", "egg", "dice", "smoothie",
    "converter", "micro-converter", "oil", "enzymes", "tropical drink",
    "gumdrop", "gumdrops", "gingerbread", "snowflake", "festive",
    "box frog", "night bell"
}
local TOKEN_P2 = {
    "strawberry", "blueberry", "pineapple", "sunflower", "seed",
    "coconut", "bitterberry", "treat", "ant pass", "pollen"
}

-- Реестр всех токенов со спрутов в Bee Swarm Simulator
TOKEN_REGISTRY = {
    { id = "token_link", name = "Token Link (🔗)", icon = "🔗", keywords = { "token link", "tokenlink", "link" }, defaultPrio = 0 },
    { id = "star_treat", name = "Star Treat", icon = "⭐", keywords = { "star treat" }, defaultPrio = 1 },
    { id = "eggs", name = "Mythic / Diamond Eggs", icon = "🥚", keywords = { "egg", "diamond egg", "gold egg", "silver egg", "mythic egg" }, defaultPrio = 1 },
    { id = "star_jelly", name = "Star Jelly", icon = "🌟", keywords = { "star jelly" }, defaultPrio = 1 },
    { id = "night_bell", name = "Night Bell", icon = "🔔", keywords = { "night bell" }, defaultPrio = 1 },
    { id = "atomic_treat", name = "Atomic Treat", icon = "☢️", keywords = { "atomic treat" }, defaultPrio = 1 },
    { id = "magic_bean", name = "Magic Bean", icon = "🌱", keywords = { "magic bean", "bean" }, defaultPrio = 1 },
    { id = "glitter", name = "Glitter", icon = "✨", keywords = { "glitter" }, defaultPrio = 1 },
    { id = "glue", name = "Glue", icon = "🧴", keywords = { "glue" }, defaultPrio = 1 },
    { id = "enzymes", name = "Enzymes", icon = "🧪", keywords = { "enzymes", "enzyme" }, defaultPrio = 1 },
    { id = "oil", name = "Oil", icon = "🛢️", keywords = { "oil" }, defaultPrio = 1 },
    { id = "tropical_drink", name = "Tropical Drink", icon = "🍹", keywords = { "tropical drink", "tropical" }, defaultPrio = 1 },
    { id = "micro_converter", name = "Micro-Converter", icon = "⚡", keywords = { "micro-converter", "converter" }, defaultPrio = 1 },
    { id = "tickets", name = "Tickets", icon = "🎟️", keywords = { "ticket" }, defaultPrio = 1 },
    { id = "stinger", name = "Stinger", icon = "🗡️", keywords = { "stinger" }, defaultPrio = 1 },
    { id = "gumdrops", name = "Gumdrops", icon = "🍬", keywords = { "gumdrop", "gumdrops" }, defaultPrio = 2 },
    { id = "moon_charm", name = "Moon Charm", icon = "🌙", keywords = { "moon charm" }, defaultPrio = 2 },
    { id = "royal_jelly", name = "Royal Jelly", icon = "👑", keywords = { "royal jelly" }, defaultPrio = 2 },
    { id = "dice_smoothie", name = "Field Dice / Smoothie", icon = "🎲", keywords = { "dice", "smoothie", "whirligig" }, defaultPrio = 2 },
    { id = "berries", name = "Berries (Blue/Straw/Pine/Seed)", icon = "🍓", keywords = { "strawberry", "blueberry", "pineapple", "sunflower", "seed" }, defaultPrio = 2 },
    { id = "bitter_neon", name = "Bitterberry & Neonberry", icon = "🫐", keywords = { "bitterberry", "neonberry" }, defaultPrio = 2 },
    { id = "coconut", name = "Coconut", icon = "🥥", keywords = { "coconut" }, defaultPrio = 2 },
    { id = "treats", name = "Treats (Печенья)", icon = "🍪", keywords = { "treat" }, defaultPrio = 3 },
    { id = "festive", name = "Gingerbread / Snowflake", icon = "❄️", keywords = { "gingerbread", "snowflake", "festive" }, defaultPrio = 2 },
    { id = "honey_tokens", name = "Honey Tokens (Жетоны мёда)", icon = "🍯", keywords = { "honey", "honeydrop", "honeytoken" }, defaultPrio = 0 },
}

local ATLAS_PRIORITY_SPROUT_IDS = {
    ["1471848094"] = true, ["1471849394"] = true, ["1471850677"] = true, ["4520739302"] = true,
    ["1987253833"] = true, ["1987257040"] = true, ["1987255318"] = true, ["6134473023"] = true,
    ["8277780065"] = true, ["8277781666"] = true, ["8277783113"] = true, ["8310376128"] = true,
    ["2319943273"] = true, ["2495935291"] = true, ["2495936060"] = true, ["4483267595"] = true,
    ["4483236276"] = true, ["3030569073"] = true, ["2028603146"] = true, ["2545746569"] = true,
    ["2529092020"] = true, ["2504978518"] = true, ["2584584968"] = true, ["2542899798"] = true,
    ["8054996680"] = true, ["3027672238"] = true, ["6299503651"] = true, ["2306224708"] = true,
    ["1674871631"] = true, ["2319083910"] = true, ["5877939956"] = true, ["2000457501"] = true,
    ["1104415222"] = true, ["1472425802"] = true, ["1472580249"] = true, ["1472532912"] = true,
    ["2032949183"] = true, ["1472491940"] = true, ["1489734171"] = true, ["1837410537"] = true,
    ["2652364563"] = true, ["2652424740"] = true, ["6077288982"] = true,
}

-- Известные текстуры предметов BSS (ID -> имя предмета)
local TOKEN_TEXTURE_MAP = {
    ["1471850677"] = "diamond egg",
    ["1471849394"] = "gold egg",
    ["1471844391"] = "silver egg",
    ["1472135114"] = "star jelly",
    ["2028607990"] = "magic bean",
    ["1674871631"] = "ticket",
    ["2007780065"] = "ticket",
    ["1629547638"] = "honey",
    ["2314120108"] = "glitter",
    ["2314120302"] = "glue",
    ["2314120489"] = "enzymes",
    ["2314120658"] = "oil",
    ["2314120800"] = "tropical drink",
    ["2529094220"] = "star treat",
    ["2007780188"] = "stinger",
    ["2007780300"] = "moon charm",
    ["2007780411"] = "micro-converter",
    ["1471850800"] = "mythic egg",
}
for spId, _ in pairs(ATLAS_PRIORITY_SPROUT_IDS) do
    if not TOKEN_TEXTURE_MAP[spId] then
        TOKEN_TEXTURE_MAP[spId] = "sprout_item"
    end
end

-- Динамическое сканирование UI инвентаря и ReplicatedStorage для сопоставления текстур предметов
function buildTokenTextureMap()
    pcall(function()
        local pg = player:FindFirstChild("PlayerGui")
        if pg then
            for _, d in ipairs(pg:GetDescendants()) do
                if d:IsA("ImageLabel") or d:IsA("ImageButton") then
                    local img = tostring(d.Image or "")
                    local id = string.match(img, "%d+")
                    if id and #id >= 6 then
                        local n = string.lower(tostring(d.Name))
                        local p = d.Parent and string.lower(tostring(d.Parent.Name)) or ""
                        local gp = d.Parent and d.Parent.Parent and string.lower(tostring(d.Parent.Parent.Name)) or ""
                        for _, reg in ipairs(TOKEN_REGISTRY) do
                            for _, kw in ipairs(reg.keywords) do
                                if string.find(n, kw, 1, true) or string.find(p, kw, 1, true) or string.find(gp, kw, 1, true) then
                                    TOKEN_TEXTURE_MAP[id] = kw
                                    TOKEN_TEXTURE_MAP[string.lower(img)] = kw
                                    break
                                end
                            end
                        end
                    end
                end
            end
        end
    end)
    pcall(function()
        local rep = game:GetService("ReplicatedStorage")
        for _, d in ipairs(rep:GetDescendants()) do
            if d:IsA("Decal") or d:IsA("Texture") or d:IsA("ImageLabel") or d:IsA("ImageButton") then
                local tex = tostring(d.Texture or d.Image or "")
                local id = string.match(tex, "%d+")
                if id and #id >= 6 then
                    local n = string.lower(tostring(d.Name))
                    local p = d.Parent and string.lower(tostring(d.Parent.Name)) or ""
                    for _, reg in ipairs(TOKEN_REGISTRY) do
                        for _, kw in ipairs(reg.keywords) do
                            if string.find(n, kw, 1, true) or string.find(p, kw, 1, true) then
                                TOKEN_TEXTURE_MAP[id] = kw
                                TOKEN_TEXTURE_MAP[string.lower(tex)] = kw
                                break
                            end
                        end
                    end
                end
            end
        end
    end)
end
pcall(buildTokenTextureMap)

function isHoneyToken(low)
    local n = string.lower(tostring(low or ""))
    if string.find(n, "honey", 1, true) or string.find(n, "honeydrop", 1, true) or string.find(n, "honeytoken", 1, true) then
        return true
    end
    if string.find(n, "1629547638", 1, true) then
        return true
    end
    return false
end

local TOKEN_NAME_CACHE = setmetatable({}, { __mode = "k" })
local TOKEN_PRIO_CACHE = setmetatable({}, { __mode = "k" })

-- Быстрое получение декалей без тяжёлого обхода дерева (O(1) для обычных токенов)
local function getObjDecals(obj)
    local decals = {}
    if not obj then return decals end
    local ok, children = pcall(function() return obj:GetChildren() end)
    if not ok or not children then return decals end
    for _, c in ipairs(children) do
        if c:IsA("Decal") or c:IsA("Texture") then
            decals[#decals + 1] = c
        elseif c:IsA("BasePart") or c:IsA("Model") then
            local okSub, subChildren = pcall(function() return c:GetChildren() end)
            if okSub and subChildren then
                for _, gc in ipairs(subChildren) do
                    if gc:IsA("Decal") or gc:IsA("Texture") then
                        decals[#decals + 1] = gc
                    end
                end
            end
        end
    end
    if #decals == 0 then
        local okDesc, descs = pcall(function() return obj:GetDescendants() end)
        if okDesc and descs then
            for _, d in ipairs(descs) do
                if d:IsA("Decal") or d:IsA("Texture") then
                    decals[#decals + 1] = d
                end
            end
        end
    end
    return decals
end

isBurstLootActive = false

local TOKEN_LINK_CACHE = setmetatable({}, { __mode = "k" })
local tokenLinkScanned = false
local tokenLinkTextureId = nil
function findTokenLinkTextureId()
    if tokenLinkScanned then return tokenLinkTextureId end
    tokenLinkScanned = true
    pcall(function()
        local rep = game:GetService("ReplicatedStorage")
        for _, d in ipairs(rep:GetDescendants()) do
            local low = string.lower(d.Name)
            if string.find(low, "token link", 1, true) or string.find(low, "tokenlink", 1, true) or (string.find(low, "link", 1, true) and not string.find(low, "blink", 1, true)) then
                if d:IsA("Decal") or d:IsA("Texture") or d:IsA("ImageLabel") or d:IsA("ImageButton") then
                    local id = string.match(tostring(d.Texture or d.Image or ""), "%d+")
                    if id and #id >= 6 then
                        tokenLinkTextureId = id
                        TOKEN_TEXTURE_MAP[id] = "token_link"
                        return
                    end
                end
            end
        end
    end)
    return tokenLinkTextureId
end

function isTokenLink(obj)
    if not obj then return false end
    local cached = TOKEN_LINK_CACHE[obj]
    if cached ~= nil then return cached end

    local oName = string.lower(tostring(obj.Name or ""))
    if string.find(oName, "token link", 1, true) or string.find(oName, "tokenlink", 1, true) or (string.find(oName, "link", 1, true) and not string.find(oName, "blink", 1, true)) then
        TOKEN_LINK_CACHE[obj] = true
        return true
    end

    local linkId = findTokenLinkTextureId()
    local decals = getObjDecals(obj)
    for _, d in ipairs(decals) do
        local dn = string.lower(tostring(d.Name or ""))
        if string.find(dn, "token link", 1, true) or string.find(dn, "tokenlink", 1, true) or (string.find(dn, "link", 1, true) and not string.find(dn, "blink", 1, true)) then
            TOKEN_LINK_CACHE[obj] = true
            return true
        end
        local tex = tostring(d.Texture or "")
        local lowTex = string.lower(tex)
        if string.find(lowTex, "link", 1, true) and not string.find(lowTex, "blink", 1, true) then
            TOKEN_LINK_CACHE[obj] = true
            return true
        end
        local id = string.match(tex, "%d+")
        if id then
            if linkId and id == linkId then
                TOKEN_LINK_CACHE[obj] = true
                return true
            end
            if TOKEN_TEXTURE_MAP[id] == "token_link" or TOKEN_TEXTURE_MAP[id] == "token link" then
                TOKEN_LINK_CACHE[obj] = true
                return true
            end
        end
    end

    local okAttr, attrs = pcall(function() return obj:GetAttributes() end)
    if okAttr and attrs then
        for k, v in pairs(attrs) do
            local lowVal = string.lower(tostring(v or ""))
            local lowKey = string.lower(tostring(k or ""))
            if string.find(lowVal, "token link", 1, true) or string.find(lowVal, "tokenlink", 1, true) or (string.find(lowVal, "link", 1, true) and not string.find(lowVal, "blink", 1, true)) or string.find(lowKey, "token link", 1, true) or string.find(lowKey, "tokenlink", 1, true) then
                TOKEN_LINK_CACHE[obj] = true
                return true
            end
        end
    end

    TOKEN_LINK_CACHE[obj] = false
    return false
end

function isAbilityToken(low)
    local n = string.lower(tostring(low or ""))
    return string.find(n, "focus", 1, true)
        or string.find(n, "melody", 1, true)
        or string.find(n, "bomb", 1, true)
        or string.find(n, "boost", 1, true)
        or string.find(n, "mark", 1, true)
        or string.find(n, "scratch", 1, true)
        or string.find(n, "haste", 1, true)
        or string.find(n, "rage", 1, true)
        or string.find(n, "beam", 1, true)
        or string.find(n, "combo", 1, true)
end

function tokenPriority(name)
    local low = string.lower(tostring(name or ""))
    -- Token Link (🔗) — СВЕРХПРИОРИТЕТ 0 (мгновенно пылесосит всё поле!)
    if string.find(low, "token link", 1, true) or string.find(low, "tokenlink", 1, true) or (string.find(low, "link", 1, true) and not string.find(low, "blink", 1, true)) then
        return 0
    end

    -- Игнорирование Treat токенов (печенья)
    if CONFIG.IGNORE_TREAT_TOKENS and string.find(low, "treat", 1, true)
        and not string.find(low, "star", 1, true)
        and not string.find(low, "atomic", 1, true)
        and not string.find(low, "heat", 1, true) then
        return 999
    end

    local pMap = CONFIG.TOKEN_PRIORITIES

    -- 1. Пользовательские приоритеты из настроек
    if pMap and type(pMap) == "table" then
        for _, def in ipairs(TOKEN_REGISTRY) do
            local userPrio = pMap[def.id]
            local prio = (userPrio ~= nil) and userPrio or def.defaultPrio
            for _, kw in ipairs(def.keywords) do
                if string.find(low, kw, 1, true) then
                    if prio == 0 then return (def.id == "token_link" and 0 or 999) end
                    return prio -- 1, 2 или 3
                end
            end
        end
    end

    -- 2. Стандартный fallback
    if isHoneyToken(low) then return 99 end
    for _, w in ipairs(TOKEN_P1) do
        if string.find(low, w, 1, true) then return 1 end
    end
    for _, w in ipairs(TOKEN_P2) do
        if string.find(low, w, 1, true) then return 2 end
    end
    if isAbilityToken(low) then return 3 end

    -- Если токен со спрута не распознан точно, но это не мед и не абилка — считаем его редким лутом (P1)!
    if low ~= "token" and low ~= "cframe" and low ~= "part" and low ~= "" then
        return 1
    end
    return 3
end

function resolveTokenName(obj)
    if not obj then return "token" end
    local cached = TOKEN_NAME_CACHE[obj]
    if cached ~= nil then
        return cached
    end

    if isTokenLink(obj) then
        TOKEN_NAME_CACHE[obj] = "token_link"
        return "token_link"
    end

    local name = tostring(obj.Name or "")
    local detectedName = nil

    -- 1. Проверяем декали внутри токена по базе текстур BSS (через быстрый getObjDecals)
    local decals = getObjDecals(obj)
    for _, child in ipairs(decals) do
        local tex = tostring(child.Texture or "")
        local lowTex = string.lower(tex)
        local id = string.match(tex, "%d+")
        if TOKEN_TEXTURE_MAP[lowTex] then
            detectedName = TOKEN_TEXTURE_MAP[lowTex]
            break
        elseif id and TOKEN_TEXTURE_MAP[id] then
            detectedName = TOKEN_TEXTURE_MAP[id]
            break
        elseif id and ATLAS_PRIORITY_SPROUT_IDS[id] then
            detectedName = "sprout_item"
            break
        end
        local cName = string.lower(tostring(child.Name or ""))
        if cName ~= "frontdecal" and cName ~= "backdecal" and cName ~= "decal" and cName ~= "" then
            for _, w in ipairs(TOKEN_P1) do
                if string.find(cName, w, 1, true) then detectedName = w; break end
            end
            if not detectedName then
                for _, w in ipairs(TOKEN_P2) do
                    if string.find(cName, w, 1, true) then detectedName = w; break end
                end
            end
            if detectedName then break end
        end
    end

    -- 2. Проверяем атрибуты объекта
    if not detectedName then
        local okAttr, attrs = pcall(function() return obj:GetAttributes() end)
        if okAttr and attrs then
            for k, v in pairs(attrs) do
                local val = string.lower(tostring(v))
                for _, w in ipairs(TOKEN_P1) do
                    if string.find(val, w, 1, true) then detectedName = w; break end
                end
                if detectedName then break end
                for _, w in ipairs(TOKEN_P2) do
                    if string.find(val, w, 1, true) then detectedName = w; break end
                end
                if detectedName then break end
            end
        end
    end

    -- 3. Проверяем имя объекта
    if not detectedName and name ~= "CFrame" and name ~= "" and name ~= "Part" then
        local lowName = string.lower(name)
        for _, w in ipairs(TOKEN_P1) do
            if string.find(lowName, w, 1, true) then detectedName = w; break end
        end
        if not detectedName then
            for _, w in ipairs(TOKEN_P2) do
                if string.find(lowName, w, 1, true) then detectedName = w; break end
            end
        end
    end

    -- 4. Если токен имеет декаль, которая не мед и не абилка — это предмет!
    if not detectedName and #decals > 0 then
        for _, child in ipairs(decals) do
            local tex = tostring(child.Texture or "")
            if tex ~= "" and not isHoneyToken(tex) and not isAbilityToken(tex) then
                detectedName = "sprout_item"
                break
            end
        end
    end

    local result = detectedName or (name ~= "" and name or "token")
    TOKEN_NAME_CACHE[obj] = result
    return result
end

function getTokenPriorityForObj(obj)
    if not obj then return 3 end
    local cached = TOKEN_PRIO_CACHE[obj]
    if cached ~= nil then return cached end

    if isTokenLink(obj) then
        TOKEN_PRIO_CACHE[obj] = 0
        return 0
    end

    local name = resolveTokenName(obj)
    local lowName = string.lower(tostring(name or ""))
    if CONFIG.IGNORE_TREAT_TOKENS and string.find(lowName, "treat", 1, true)
        and not string.find(lowName, "star", 1, true)
        and not string.find(lowName, "atomic", 1, true)
        and not string.find(lowName, "heat", 1, true) then
        TOKEN_PRIO_CACHE[obj] = 999
        return 999
    end

    -- 1. Метод Atlas BSS: проверка спец-эффектов редкости (Spots, Rainbow, Sparkles)
    if obj:FindFirstChild("Spots") or obj:FindFirstChild("Rainbow") or obj:FindFirstChild("Sparkles")
        or obj:FindFirstChildWhichIsA("Sparkles")
        or (obj:IsA("Model") and (obj:FindFirstChild("Spots", true) or obj:FindFirstChild("Rainbow", true) or obj:FindFirstChild("Sparkles", true))) then
        TOKEN_PRIO_CACHE[obj] = 1
        return 1
    end

    -- 2. Метод Atlas BSS: проверка декалей токена по ID базы редких предметов
    local decals = getObjDecals(obj)
    for _, d in ipairs(decals) do
        local tex = tostring(d.Texture or "")
        local id = string.match(tex, "%d+")
        if id and ATLAS_PRIORITY_SPROUT_IDS[id] then
            TOKEN_PRIO_CACHE[obj] = 1
            return 1
        end
    end

    local name = resolveTokenName(obj)
    local prio = tokenPriority(name)
    TOKEN_PRIO_CACHE[obj] = prio
    return prio
end

local TOKEN_FOLDERS = { "Collectibles", "Tokens", "Drops" }
local TOKEN_CACHE, TOKEN_CACHE_AT = {}, 0
local TOKEN_CACHE_TTL = 0.5
function findToolByKeyword(keyword)
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

function equipTool(tool)
    if not tool then return false end
    local char = player.Character
    local hum = char and char:FindFirstChildOfClass("Humanoid")
    if not hum then return false end
    pcall(function() hum:EquipTool(tool) end)
    return tool.Parent == char
end

local cachedHarvestTool = nil
local lastToolCheckAt = 0

function ensureHarvestToolEquipped()
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
                cachedHarvestTool = item
                return item
            end
        end
    end
    return nil
end

function findHarvestTool()
    return ensureHarvestToolEquipped()
end

local toolCollectRemote = nil
local lastRemoteCheckAt = 0
function getToolCollectRemote()
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
function swingDigTool()
    local now = os.clock()
    if now - lastSwingAt < 0.12 then return end
    lastSwingAt = now

    local char = player.Character
    if not char then return end
    local tool = ensureHarvestToolEquipped()
    if tool and tool.Parent == char then
        tool.Enabled = true
        pcall(function() tool:Activate() end)
        if type(firesignal) == "function" and tool:FindFirstChild("Activated") then
            pcall(firesignal, tool.Activated)
        end
    end

    -- Чистая активация инструмента сбора без кликов мыши в экран
    local ev = getToolCollectRemote()
    if ev then
        pcall(function() ev:FireServer() end)
    end
end

local TOKEN_CACHE, TOKEN_CACHE_AT = {}, 0
local collectedTokens = setmetatable({}, { __mode = "k" })
function findFieldTokens(anchorZone, limitX, limitZ, fieldAnchor)
    local now = os.clock()
    if now - TOKEN_CACHE_AT < 0.15 then
        return TOKEN_CACHE
    end
    TOKEN_CACHE_AT = now

    local out = {}
    local zonePos = anchorZone and anchorZone.Position
    local maxRadius = (anchorZone and math.max(anchorZone.Size.X, anchorZone.Size.Z) * 0.5 + 30) or 65
    local maxRadiusSq = maxRadius * maxRadius

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
                                    local half = anchorZone.Size * 0.5
                                    -- Строго внутри цветков поля (с запасом 2 стадса от края) — не убегаем за пределы поля!
                                    if math.abs(lp.X) <= (half.X - 2.0) and math.abs(lp.Z) <= (half.Z - 2.0) then
                                        inField = true
                                    end
                                end
                            elseif fieldAnchor then
                                local dx = pos.X - fieldAnchor.X
                                local dz = pos.Z - fieldAnchor.Z
                                inField = (dx * dx + dz * dz) <= (38 * 38)
                            else
                                inField = true
                            end

                            if inField then
                                local prio = getTokenPriorityForObj(obj)
                                if prio <= 3 then
                                    local isLink = (prio == 0) or (TOKEN_LINK_CACHE[obj] == true)
                                    out[#out+1] = {
                                        obj = obj,
                                        pos = pos,
                                        priority = isLink and 0 or prio,
                                        isLink = isLink,
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

function getActiveFlowerZone(anchorPos)
    local zones = Workspace:FindFirstChild("FlowerZones")
    if not zones then return nil end
    local pos = anchorPos or (player.Character and player.Character:FindFirstChild("HumanoidRootPart") and player.Character.HumanoidRootPart.Position)
    if not pos then return nil end
    local bestZone, bestDist = nil, math.huge
    for _, zone in ipairs(zones:GetChildren()) do
        if zone:IsA("BasePart") then
            local lp = zone.CFrame:PointToObjectSpace(pos)
            local half = zone.Size * 0.5
            local yDiff = math.abs(zone.Position.Y - pos.Y)
            if yDiff <= 45 and math.abs(lp.X) <= half.X + 25 and math.abs(lp.Z) <= half.Z + 25 then
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

function disableSprinklerCollision()
    pcall(function()
        local g = Workspace:FindFirstChild("Gadgets")
        if g then
            for _, d in ipairs(g:GetDescendants()) do
                if d:IsA("BasePart") and d.CanCollide then
                    d.CanCollide = false
                end
            end
        end
        for _, obj in ipairs(Workspace:GetChildren()) do
            if obj:IsA("Model") then
                local n = string.lower(obj.Name)
                if string.find(n, "sprinkler", 1, true) or string.find(n, "saturator", 1, true) or string.find(n, "drencher", 1, true) or string.find(n, "gusher", 1, true) or string.find(n, "soaker", 1, true) then
                    for _, p in ipairs(obj:GetDescendants()) do
                        if p:IsA("BasePart") and p.CanCollide then
                            p.CanCollide = false
                        end
                    end
                end
            end
        end
    end)
end

local function getObstacleAvoidanceTarget(rootPos, targetPos, character)
    return targetPos
end

local ONETT_EASTER_EGGS = {}
local BLACKLISTED_STATIC_EASTER_EGGS = {}

pcall(function()
    local coll = Workspace:FindFirstChild("Collectibles")
    if coll then
        for _, t in ipairs(coll:GetChildren()) do
            ONETT_EASTER_EGGS[t] = true
        end
    end
end)

local function isNearAnyFlowerZone(pos, maxDist)
    maxDist = maxDist or 85
    local fz = Workspace:FindFirstChild("FlowerZones")
    if not fz then return true end
    for _, z in ipairs(fz:GetChildren()) do
        if z:IsA("BasePart") then
            local delta = pos - z.Position
            local halfX = z.Size.X * 0.5 + maxDist
            local halfZ = z.Size.Z * 0.5 + maxDist
            if math.abs(delta.X) <= halfX and math.abs(delta.Z) <= halfZ and math.abs(delta.Y) <= 40 then
                return true
            end
        end
    end
    return false
end

local function isOnettEasterEgg(token)
    if not token or not token.Parent then return true end
    if ONETT_EASTER_EGGS[token] or BLACKLISTED_STATIC_EASTER_EGGS[token] then return true end
    local p = worldPos(token)
    if not p then return true end

    -- Черный список статичных пасхалок Онетта:
    -- 1. Под рампой/в тени 30 пчел (Diamond Egg)
    if p.Y < 65 and p.Z < -350 then return true end
    -- 2. Внутри пещер Паука и Оборотня
    if p.Y < 45 and p.X < -220 and p.Z < -50 then return true end
    -- 3. На верхушке блендера 15 пчел (Star Jelly)
    if (p - Vector3.new(-425, 72, 0)).Magnitude < 20 then return true end
    -- 4. В секретных комнатах/лабиринтах (компьютерная комната, gummy lair)
    if p.Y < 6 or p.Y > 360 then return true end
    -- 5. Если токен вне цветущих полей (> 85 studs) — это 100% статичная пасхалка (карамельная трость, стены, секреты)
    if not isNearAnyFlowerZone(p, 85) then
        BLACKLISTED_STATIC_EASTER_EGGS[token] = true
        return true
    end

    return false
end

collectTokensFor = function(maxSeconds, stopFn, fieldAnchor)
    collectorTokenGen = collectorTokenGen + 1
    local myGen = collectorTokenGen
    tokenCollectorBusy = true
    if fieldAnchor then lastActiveTargetPos = fieldAnchor end

    local function runLoop()
        local started = os.clock()
        patrolTarget, activeTokenObj = nil, nil
        lastPatrolPickAt = 0
        local lastMoveToTarget = nil
        local lastMoveToCall = 0
        local lastRecordedPos = nil
        local stuckStartTime = nil
        local lastJumpTime = 0

        -- Включаем полный Noclip персонажа как в полете (пробегать насквозь сквозь заборы, поливалки, плантаторы, ростки)
        setFlightNoclip(true)
        pcall(disableSprinklerCollision)
        local initialChar = player.Character
        local initialRoot = initialChar and initialChar:FindFirstChild("HumanoidRootPart")
        local initialHum = initialChar and initialChar:FindFirstChildOfClass("Humanoid")
        if initialRoot then
            pcall(function()
                initialRoot.AssemblyLinearVelocity = Vector3.zero
                initialRoot.AssemblyAngularVelocity = Vector3.zero
            end)
        end
        if initialHum then
            pcall(function()
                initialHum.PlatformStand = false
                initialHum.Sit = false
                initialHum:ChangeState(Enum.HumanoidStateType.Landed)
                initialHum:ChangeState(Enum.HumanoidStateType.Running)
            end)
        end
        -- Принудительно выставляем скорость бега, чтобы персонаж БЕЖАЛ а не стоял
        pcall(applyWalkSpeed)

        -- Находим физическую зону текущего поля
        local anchorZone = getActiveFlowerZone(fieldAnchor)
        local limitX, limitZ = 40, 40
        local function refreshZoneLimits()
            if anchorZone then
                local half = anchorZone.Size * 0.5
                limitX = math.max(6, half.X * 0.99)
                limitZ = math.max(6, half.Z * 0.99)
            end
        end
        refreshZoneLimits()

        while alive() and os.clock() - started < maxSeconds do
            if collectorTokenGen ~= myGen then break end
            if stopFn and stopFn() then break end

            local char, root, humanoid = waitForRespawn(5)
            if not root or not humanoid or humanoid.Health <= 0 then
                break
            end
            if humanoid.PlatformStand or humanoid.Sit then
                pcall(function()
                    humanoid.PlatformStand = false
                    humanoid.Sit = false
                    humanoid:ChangeState(Enum.HumanoidStateType.Running)
                end)
            end

            -- Защита от реальной потери поля (только если возродился в улье или упал далеко за пределы)
            local targetFieldPos = fieldAnchor or (anchorZone and anchorZone.Position)
            local maxAllowedFieldDist = (anchorZone and (math.sqrt((anchorZone.Size.X * 0.5)^2 + (anchorZone.Size.Z * 0.5)^2) + 38)) or 120
            if targetFieldPos and (root.Position - targetFieldPos).Magnitude > maxAllowedFieldDist then
                log("Возврат", string.format("Персонаж реально улетел/возродился вдали от поля (%.0f studs). Возвращаюсь на поле...", (root.Position - targetFieldPos).Magnitude))
                moveRootToPosition(root, getGroundPos(targetFieldPos), 10)
                task.wait(0.3)
            end

            -- АКТИВНАЯ ЗАЩИТА: Защита от реального проваливания в бездну
            if anchorZone and root then
                local minFieldY = anchorZone.Position.Y - 18.0
                if root.Position.Y < minFieldY then
                    log("Защита", "Персонаж провалился под поле! Мгновенный подъем на поверхность поля...")
                    local safeY = anchorZone.Position.Y + (anchorZone.Size.Y * 0.5) + 3.5
                    root.AssemblyLinearVelocity = Vector3.zero
                    root.AssemblyAngularVelocity = Vector3.zero
                    root.CFrame = CFrame.new(root.Position.X, safeY, root.Position.Z)
                    setFlightNoclip(true)
                end
            end



            if not anchorZone then
                anchorZone = getActiveFlowerZone(root.Position)
                refreshZoneLimits()
            end

            -- Во время Burst-сбора отключаем копание, чтобы не тормозить бег!
            if not isBurstLootActive then
                pcall(swingDigTool)
            end

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
                            pcall(function()
                                local tName = resolveTokenName(activeTokenObj)
                                if tName and tName ~= "token" and recordLootItem then
                                    recordLootItem(tName, 1)
                                end
                            end)
                            activeTokenObj = nil
                        end
                    else
                        activeTokenObj = nil
                    end
                end
            end

            -- Поиск токенов внутри и вокруг поля
            local tokens = findFieldTokens(anchorZone, limitX, limitZ, fieldAnchor)
            local bestToken = nil
            local bestPrio = math.huge
            local bestDistSq = math.huge

            for _, token in ipairs(tokens) do
                local tobj = token.obj
                if tobj and tobj.Parent and not collectedTokens[tobj] then
                    local dx = token.pos.X - rootPos.X
                    local dz = token.pos.Z - rootPos.Z
                    local distSq = dx * dx + dz * dz
                    if distSq <= 6.25 then
                        collectedTokens[tobj] = true
                        pcall(function()
                            local tName = resolveTokenName(tobj)
                            if tName and tName ~= "token" and recordLootItem then
                                recordLootItem(tName, 1)
                            end
                        end)
                    else
                        local isLink = (token.priority == 0) or (token.isLink == true)
                        local p = isLink and 0 or token.priority
                        if p < 999 then
                            -- Atlas BSS строгая приоритезация:
                            -- Меньший приоритет (P0 > P1 > P2 > P3) ВСЕГДА имеет абсолютное преимущество!
                            -- При равном приоритете побеждает ближайший токен.
                            if p < bestPrio then
                                bestPrio = p
                                bestDistSq = distSq
                                bestToken = token
                            elseif p == bestPrio and distSq < bestDistSq then
                                bestDistSq = distSq
                                bestToken = token
                            end
                        end
                    end
                end
            end

            -- Target lock: если уже бежим к активному токену ТОГО ЖЕ приоритета, не дергаемся между одинаковыми
            if bestToken and activeTokenObj and activeTokenObj.Parent and not collectedTokens[activeTokenObj] and activeTokenObj ~= bestToken.obj then
                local activePrio = getTokenPriorityForObj(activeTokenObj)
                if activePrio == bestPrio then
                    local p = worldPos(activeTokenObj)
                    if p then
                        local dx = p.X - rootPos.X
                        local dz = p.Z - rootPos.Z
                        local distSq = dx * dx + dz * dz
                        if distSq < (bestDistSq + 144.0) then
                            bestToken = { obj = activeTokenObj, pos = p, priority = activePrio, isLink = (activePrio == 0) }
                        end
                    end
                end
            end

            local best = bestToken

            -- Приоритетная скорость бега (без резких скачков и перезаписи Heartbeat)
            local isP1 = best and (best.priority == 1 or best.priority == 0)
            applyWalkSpeed(isP1 or isBurstLootActive)

            -- Не копаем во время охоты за P1 / Token Link токеном, чтобы не сбивать спринт!
            if not isP1 and not isBurstLootActive then
                pcall(swingDigTool)
            end

            if best then
                if activeTokenObj ~= best.obj then
                    local tName = resolveTokenName(best.obj)
                    if best.priority == 0 then
                        log("Token", string.format("🔗 НАЙДЕН TOKEN LINK! Бегу собрать его в первую очередь (дистанция %.1f studs)!", math.sqrt(bestDistSq)))
                    elseif isP1 then
                        log("Token", string.format("⚡ Бегу за приоритетным токеном: %s (P1) на расстоянии %.1f studs!", tName, math.sqrt(bestDistSq)))
                    end
                end
                activeTokenObj = best.obj
                patrolTarget = Vector3.new(best.pos.X, (anchorZone and (anchorZone.Position.Y + 3.2)) or root.Position.Y, best.pos.Z)
            else
                activeTokenObj = nil
                local needNewPatrol = not patrolTarget 
                    or (root.Position - patrolTarget).Magnitude < 3.2
                    or (os.clock() - lastPatrolPickAt > 2.2)

                if needNewPatrol then
                    lastPatrolPickAt = os.clock()
                    if fieldAnchor then
                        -- При наличии активного центра (росток / плантатор) бегаем вокруг него кругами (8-22 studs)
                        local angle = math.random() * math.pi * 2
                        local dist = math.random(8, 22)
                        patrolTarget = Vector3.new(
                            fieldAnchor.X + math.cos(angle) * dist,
                            (anchorZone and (anchorZone.Position.Y + 3.2)) or root.Position.Y,
                            fieldAnchor.Z + math.sin(angle) * dist
                        )
                    elseif anchorZone then
                        local half = anchorZone.Size * 0.5
                        local xSpan = half.X * 0.85
                        local zSpan = half.Z * 0.85
                        local localTarget = Vector3.new(
                            (math.random() * 2 - 1) * xSpan,
                            0,
                            (math.random() * 2 - 1) * zSpan
                        )
                        local worldPoint = anchorZone.CFrame:PointToWorldSpace(localTarget)
                        patrolTarget = Vector3.new(worldPoint.X, (anchorZone and (anchorZone.Position.Y + 3.2)) or root.Position.Y, worldPoint.Z)
                    else
                        patrolTarget = root.Position
                    end
                end

            end

            -- Ограничение цели СТРОГО в границы поля (персонаж доходит до 99% поля!)
            if anchorZone and patrolTarget then
                local lp = anchorZone.CFrame:PointToObjectSpace(patrolTarget)
                local safeX = math.clamp(lp.X, -limitX, limitX)
                local safeZ = math.clamp(lp.Z, -limitZ, limitZ)
                local safeWorld = anchorZone.CFrame:PointToWorldSpace(Vector3.new(safeX, lp.Y, safeZ))
                patrolTarget = Vector3.new(safeWorld.X, (anchorZone and (anchorZone.Position.Y + 3.2)) or root.Position.Y, safeWorld.Z)
            end

            -- Плавное и безотказное прямое перемещение: активный бег через humanoid:Move() + MoveTo() + AssemblyLinearVelocity
            if patrolTarget and humanoid and root then
                local currentPos = root.Position
                local flatTarget = Vector3.new(patrolTarget.X, currentPos.Y, patrolTarget.Z)
                local flatDelta = flatTarget - currentPos
                local dist = flatDelta.Magnitude

                local currentSpd = getCalculatedWalkSpeed(isP1 or isBurstLootActive)
                if dist > 1.2 then
                    local moveDir = flatDelta.Unit
                    humanoid.AutoRotate = true
                    humanoid:Move(moveDir, false)
                    humanoid:MoveTo(flatTarget)
                    -- Физический толчок скорости (гарантирует что персонаж БЕЖИТ даже если PlayerModule сбрасывает Move):
                    local currentY = root.AssemblyLinearVelocity.Y
                    root.AssemblyLinearVelocity = Vector3.new(moveDir.X * currentSpd, currentY, moveDir.Z * currentSpd)
                else
                    humanoid:Move(Vector3.zero, false)
                    root.AssemblyLinearVelocity = Vector3.new(0, root.AssemblyLinearVelocity.Y, 0)
                    if not activeTokenObj then
                        patrolTarget = nil
                    end
                end

                -- Защита от застревания в преградах (прыжок при остановке):
                local now = os.clock()
                if not lastRecordedPos then lastRecordedPos = currentPos end
                if (currentPos - lastRecordedPos).Magnitude < 0.6 then
                    if not stuckStartTime then stuckStartTime = now end
                    if (now - stuckStartTime > 0.6) then
                        pcall(function() humanoid.Jump = true end)
                        pcall(disableSprinklerCollision)
                        patrolTarget = nil
                        stuckStartTime = nil
                        lastRecordedPos = currentPos
                    end
                else
                    lastRecordedPos = currentPos
                    stuckStartTime = nil
                end
            end

            RunService.Heartbeat:Wait()
        end

        pcall(function()
            setFlightNoclip(false)
            local c = player.Character
            local h = c and c:FindFirstChildOfClass("Humanoid")
            local r = c and c:FindFirstChild("HumanoidRootPart")
            if h then h:Move(Vector3.zero, false) end
            if r then r.AssemblyLinearVelocity = Vector3.new(0, r.AssemblyLinearVelocity.Y, 0) end
        end)
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
    local halfX = zone and (zone.Size.X * 0.5) or 35
    local halfZ = zone and (zone.Size.Z * 0.5) or 35

    -- Формируем целевые точки размещения поливалок с широкой расстановкой (не ближе 22-28 стадс)
    local targetOffsets = {}
    if count == 1 then
        table.insert(targetOffsets, Vector3.new(0, 0, 0))
    elseif count == 2 then
        local spanX = math.clamp(halfX * 0.65, 22, math.max(22, halfX - 6))
        table.insert(targetOffsets, Vector3.new(-spanX, 0, 0))
        table.insert(targetOffsets, Vector3.new(spanX, 0, 0))
    elseif count == 3 then
        local spanX = math.clamp(halfX * 0.65, 22, math.max(22, halfX - 6))
        local spanZ = math.clamp(halfZ * 0.60, 20, math.max(20, halfZ - 6))
        table.insert(targetOffsets, Vector3.new(0, 0, spanZ))
        table.insert(targetOffsets, Vector3.new(-spanX, 0, -spanZ * 0.70))
        table.insert(targetOffsets, Vector3.new(spanX, 0, -spanZ * 0.70))
    elseif count == 4 then
        local spanX = math.clamp(halfX * 0.65, 22, math.max(22, halfX - 6))
        local spanZ = math.clamp(halfZ * 0.65, 22, math.max(22, halfZ - 6))
        table.insert(targetOffsets, Vector3.new(-spanX, 0, spanZ))
        table.insert(targetOffsets, Vector3.new(spanX, 0, spanZ))
        table.insert(targetOffsets, Vector3.new(-spanX, 0, -spanZ))
        table.insert(targetOffsets, Vector3.new(spanX, 0, -spanZ))
    end

    -- 1. Экипируем Sprinkler Builder в руки ДО начала расстановки (минимальная задержка экипировки)
    if tool and tool.Parent ~= char then
        equipTool(tool)
        task.wait(0.15)
    end

    local placed = 0
    local lastSprinklerPlacedAt = 0

    for i, offset in ipairs(targetOffsets) do
        if not alive() or not root.Parent then break end

        local worldTarget
        if zone then
            worldTarget = zone.CFrame:PointToWorldSpace(offset)
        else
            worldTarget = center + offset
        end

        local safeGround = getGroundPos(worldTarget)
        local goal = Vector3.new(safeGround.X, safeGround.Y, safeGround.Z)

        -- Летим на нужную точку расстановки (время полета засчитывается в 1.5 сек кд!)
        moveRootToPosition(root, goal, 2.5)

        -- Убеждаемся что инструмент все еще в руках
        if tool and tool.Parent ~= char then
            equipTool(tool)
            task.wait(0.1)
        end

        -- ЭКОНОМИЯ ВРЕМЕНИ: ровно 1.5 секунды с момента установки предыдущей поливалки!
        -- Если полет занял 0.8 сек, ждем только оставшиеся 0.7 сек.
        -- Для первой поливалки (i == 1) задержки нет вообще!
        if i > 1 and lastSprinklerPlacedAt > 0 then
            local elapsed = os.clock() - lastSprinklerPlacedAt
            if elapsed < 1.5 then
                task.wait(1.5 - elapsed)
            end
        end

        -- 1. Вызов серверного RemoteEvent размещения поливалки
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

        -- 3. Активация без мыши (чистый firesignal)
        if tool and type(firesignal) == "function" and tool:FindFirstChild("Activated") then
            pcall(firesignal, tool.Activated)
        end

        placed += 1
        lastSprinklerPlacedAt = os.clock()
    end

    log("Инструмент", string.format("Sprinkler Builder: размещено %d/%d (режим: %d поливалки)", placed, count, count))

    -- Синхронное снятие лейки и немедленное вооружение палкой
    pcall(function() hum:UnequipTools() end)
    task.wait(0.1)
    ensureHarvestToolEquipped()
    pcall(disableSprinklerCollision)

    -- Если есть anchor ростка — отходим на 5 стадсов от последней поливалки к ростку
    if fieldAnchor and root then
        local delta = fieldAnchor - root.Position
        local flatD = Vector3.new(delta.X, 0, delta.Z)
        if flatD.Magnitude > 3 then
            root.CFrame = CFrame.new(root.Position + flatD.Unit * 5 + Vector3.new(0, 0.5, 0))
        end
    end
    return placed > 0
end

local autoDigThread = nil
function startAutoDig()
    if autoDigThread or not CONFIG.ENABLE_AUTO_DIG then return end
    autoDigThread = task.spawn(function()
        while alive() do
            local tool = findHarvestTool()
            if tool then
                local char = player.Character
                if tool.Parent ~= char and char then equipTool(tool) end
                tool.Enabled = true
                pcall(function() tool:Activate() end)
                if type(firesignal) == "function" and tool:FindFirstChild("Activated") then
                    pcall(firesignal, tool.Activated)
                end
                local ev = getToolCollectRemote()
                if ev then pcall(function() ev:FireServer() end) end
            end
            task.wait(0.18)
        end
    end)
end
function stopAutoDig()
    if autoDigThread then
        pcall(task.cancel, autoDigThread)
        autoDigThread = nil
    end
end

function hasOwnHive()
    if cachedHiveSlot and cachedHiveSlot.pos then return true end
    local slot = findAssignedHiveSlot()
    if slot and slot.pos then
        cachedHiveSlot = slot
        saveMyHivePos(slot.pos)
        return true
    end
    return false
end

function ensureHiveClaimed()
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

function postJson(path, body)
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

function responseRejected(resp)
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
    local maxAttempts = math.min(3, math.max(2, tonumber(CONFIG.MAX_ATTEMPTS) or 2))
    for attempt = 1, maxAttempts do
        local ok, resp = pcall(function() return postJson("/report", body) end)
        if ok and not responseRejected(resp) then
            self.stats.reportsSent += 1
            self.stats.lastSprout = { fieldName = "отправлено" }
            return true
        end
        if attempt < maxAttempts then task.wait(0.2) end
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
    for attempt = 1, 2 do
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
        if attempt < 2 then task.wait(0.2) end
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
    for attempt = 1, 2 do
        local ok, resp = pcall(function() return postJson("/puffshroom", body) end)
        if ok and not responseRejected(resp) then self.stats.reportsSent += 1; return true end
        if attempt < 2 then task.wait(0.2) end
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
        s.currentStatus = "Ожидание загрузки игры..."
        waitForGameReady(12, true)
        s.currentStatus = "Быстрое сканирование..."
        task.wait(0.05)
        while alive() do
            -- После смерти ждём новый персонаж и продолжаем тот же цикл.
            if not player.Character or not player.Character:FindFirstChild("HumanoidRootPart") then
                s.currentStatus = "Персонаж погиб — жду возрождения..."
                task.wait(0.2)
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
                            if tm then
                                task.spawn(function()
                                    self:reportPuffshroom(game.JobId, puffRarity, puffLevel, f, tm)
                                end)
                            end
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
                        task.wait(0.2)
                        hopRandom(); return
                    end
                end

                if sprout then
                    local rarity = detectRarity(sprout)
                    if not rarity then
                        task.wait(0.15)
                        rarity = detectRarity(sprout)
                    end
                    local fieldName = detectField(sprout)
                    local repRarity = rarity or "basic"
                    s.currentStatus = "Репортую " .. (RARITY_LABEL[repRarity] or repRarity)
                    if self:report(game.JobId, repRarity, fieldName) then
                        s.lastSprout = { fieldName = (RARITY_LABEL[repRarity] or repRarity).." @ "..tostring(fieldName or "?") }
                    end
                    task.wait(0.2)
                    hopRandom()
                else
                    s.currentStatus = "Сервер #" .. tostring(s.serversChecked) .. " — пусто"
                    task.wait(0.1)
                    hopRandom()
                end
            end)
            if not ok then
                log("Ищущий", "Ошибка: " .. tostring(err))
                task.wait(0.4); hopRandom()
            end
            task.wait(0.15)
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

local lastSproutBrokenTime = 0
local lastSproutHarvestAnchor = nil
local localVisitedTasks = {}

local function isTaskVisited(jobId)
    if not jobId or jobId == "" then return true end
    local norm = normalizeJobId(jobId)
    if norm == "" or norm == normalizeJobId(game.JobId) then return true end
    if failedServers[jobId] and (os.clock() - failedServers[jobId] < 30) then return true end
    if localVisitedTasks[norm] and (os.clock() - localVisitedTasks[norm] < 300) then return true end
    return false
end

local function markTaskVisited(jobId)
    if jobId and jobId ~= "" then
        local norm = normalizeJobId(jobId)
        localVisitedTasks[norm] = os.clock()
        pcall(function() addVisitedServer(jobId) end)
    end
end

local function isSproutLootProtected()
    -- 1. На сервере прямо сейчас есть активный росток для сбора
    if CONFIG.CHECK_SPROUTS and findAnySprout() then
        return true, "на сервере активный росток"
    end
    -- 2. Росток сломан, но ещё не прошло 15 секунд обязательного сбора лута
    if lastSproutBrokenTime > 0 then
        local elapsed = os.clock() - lastSproutBrokenTime
        if elapsed < 15 then
            return true, string.format("долутывание ростка (осталось %dс)", math.ceil(15 - elapsed))
        end
    end
    -- 3. На сервере идет метеоритный дождь
    if (CONFIG.CHECK_METEORS ~= false) and findActiveMeteors() then
        return true, "на сервере идет метеоритный дождь"
    end
    return false, nil
end

function Looter:harvest(sproutObj)
    local s = self.stats
    local sprout = sproutObj or findAnySprout() or findLootableSprout()
    if not sprout then return false end

    local sproutAnchor = worldPos(sprout)
    currentSproutFieldZone = getActiveFlowerZone(sproutAnchor)
    if not moveToSprout(sprout) then
        currentSproutFieldZone = nil
        return false
    end
    sproutAnchor = worldPos(sprout) or sproutAnchor or (player.Character and player.Character:FindFirstChild("HumanoidRootPart") and player.Character.HumanoidRootPart.Position)
    currentSproutFieldZone = getActiveFlowerZone(sproutAnchor)
    lastSproutHarvestAnchor = sproutAnchor

    local rar = detectRarity(sprout)
    s.lastSprout = { fieldName = RARITY_LABEL[rar] or "спрут" }
    s.sproutsHarvested += 1
    s.currentStatus = "Лечу к ростку: " .. (RARITY_LABEL[rar] or "спрут")

    -- Занимаем улей ТОЛЬКО когда реально подлетели к подтвержденному ростку
    if not hasOwnHive() then
        s.currentStatus = "Росток подтвержден — занимаю улей"
        local claimOk, claimed = pcall(ensureHiveClaimed)
        if claimOk and claimed then s.hivesClaimed += 1 end
        moveToSprout(sprout)
    end

    s.currentStatus = "Росток: ставлю поливалку"
    task.wait(0.15)
    if useSprinklerBuilder then pcall(useSprinklerBuilder, sproutAnchor) end
    ensureHarvestToolEquipped()

    -- Фаза 1: Росток жив. Бегаем постоянно, машем инструментом, собираем токены
    while alive() and isSproutAlive(sprout, sproutAnchor) do
        local char = player.Character
        local root = char and char:FindFirstChild("HumanoidRootPart")
        local hum = char and char:FindFirstChildOfClass("Humanoid")
        if not root or not hum or hum.Health <= 0 then
            s.currentStatus = "Персонаж погиб — жду возрождения..."
            local newChar = player.CharacterAdded:Wait()
            local newRoot = newChar:WaitForChild("HumanoidRootPart", 6)
            task.wait(0.3)
            if newRoot and sprout and isSproutAlive(sprout, sproutAnchor) then
                s.currentStatus = "Возвращаюсь к ростку после смерти..."
                moveToSprout(sprout)
            end

        end

        s.currentStatus = CONFIG.ENABLE_AUTO_DIG and "Росток: копаю и бегаю по полю" or "Росток: собираю токены"
        collectTokensFor(6, function()
            return not alive() or not isSproutAlive(sprout, sproutAnchor)
        end, sproutAnchor)
        task.wait(0.05)
    end

    -- Фаза 2: Росток сломан! Засекаем точное время поломки
    lastSproutBrokenTime = os.clock()
    lastSproutHarvestAnchor = sproutAnchor
    log("Спрут", "Росток сломан! Запущен 15-секундный таймер обязательного лутания.")

    if alive() and sproutAnchor then
        local char = player.Character
        local root = char and char:FindFirstChild("HumanoidRootPart")
        local hum = char and char:FindFirstChildOfClass("Humanoid")
        if not root or not hum or hum.Health <= 0 then
            local newChar = player.CharacterAdded:Wait()
            local newRoot = newChar:WaitForChild("HumanoidRootPart", 6)
            task.wait(0.3)
            if newRoot and sproutAnchor then
                moveRootToPosition(newRoot, getGroundPos(sproutAnchor), 10)
            end
        end

        stopAutoDig()
        tokenCollectorBusy = false
        patrolTarget = nil

        -- BURST-РЕЖИМ СБОРА
        if CONFIG.BURST_LOOT_ENABLED ~= false then
            s.currentStatus = "⚡ BURST-СБОР: Сверхбыстрый сбор редкого лута!"
            isBurstLootActive = true
            local burstTime = tonumber(CONFIG.BURST_LOOT_TIME) or 7
            local burstStart = os.clock()
            collectTokensFor(burstTime, function()
                return not alive() or (os.clock() - burstStart >= burstTime)
            end, sproutAnchor)
            isBurstLootActive = false
        end

        -- Обязательный сбор оставшихся токенов (минимум 15 секунд с момента поломки)
        local totalLootDuration = math.max(15, tonumber(CONFIG.BROKEN_WAIT) or 20)
        while alive() and (os.clock() - lastSproutBrokenTime < totalLootDuration) do
            local elapsed = os.clock() - lastSproutBrokenTime
            local remaining = math.ceil(totalLootDuration - elapsed)
            s.currentStatus = string.format("Росток сломан — сбор лута (ещё %dс)...", remaining)
            collectTokensFor(math.min(remaining, 5), function()
                return not alive() or (os.clock() - lastSproutBrokenTime >= totalLootDuration)
            end, sproutAnchor)
            task.wait(0.05)
        end
    end

    if isBackpackFull() then
        stopAutoDig()
        tokenCollectorBusy = false
        patrolTarget = nil
        while isBackpackFull() and alive() do
            s.currentStatus = "Рюкзак полный — делаю Honey"
            makeHoney()
            task.wait(1)
        end
    end
    currentSproutFieldZone = nil
    return true
end

local function makeApiUrl(path)
    local base = string.gsub(CONFIG.API_URL or "https://hopper-bss-production.up.railway.app", "/+$", "")
    local key = CONFIG.API_KEY or ""
    local sep = string.find(path, "?", 1, true) and "&" or "?"
    return string.format("%s%s%sapiKey=%s", base, path, sep, key)
end

local function apiGet(path)
    local url = makeApiUrl(path)
    local raw, status = robustHttpGet(url)
    if not raw or raw == "" then
        return nil, "нет связи с сервером"
    end
    local okDec, data = pcall(function() return HttpService:JSONDecode(raw) end)
    if not okDec or type(data) ~= "table" then
        return nil, "некорректный ответ"
    end
    if data.status == "error" or data.error then
        return nil, tostring(data.message or data.error or "ошибка API")
    end
    return data, nil
end

function Looter:fetchNextVicious()
    local lastErr = nil

    -- 1. Сканируем всю очередь /vicious-queue за последние 2 минуты (120 секунд)
    local qData, qErr = apiGet("/vicious-queue")
    if qData then
        local qList = (type(qData) == "table" and (qData.queue or (qData[1] and qData))) or nil
        if qList and type(qList) == "table" and #qList > 0 then
            for _, t in ipairs(qList) do
                local jid = tostring(t.jobId or "")
                local age = tonumber(t.age) or 0
                if jid ~= "" and age <= 120 and not isTaskVisited(jid) then
                    return {
                        jobId = jid,
                        kind = t.kind or "wild",
                        placeId = t.placeId or CONFIG.PLACE_ID,
                        fieldName = t.fieldName or "unknown",
                        age = age,
                        searcherTag = t.searcherTag or "vicious_queue_history",
                        isVicious = true,
                    }, nil
                end
            end
        end
    else
        lastErr = qErr
    end

    -- 2. Опрашиваем /vicious-next
    local nData, nErr = apiGet("/vicious-next")
    if nData and not nData.empty and nData.jobId then
        local jid = tostring(nData.jobId)
        local age = tonumber(nData.age) or 0
        if age <= 120 and not isTaskVisited(jid) then
            nData.isVicious = true
            return nData, nil
        end
    elseif not lastErr then
        lastErr = nErr
    end

    return nil, lastErr
end

function Looter:fetchNext()
    local lastErr = nil

    -- 1. Сначала сканируем всю очередь /queue за последние 4 минуты (240 секунд)
    local qData, qErr = apiGet("/queue")
    if qData then
        local qList = (type(qData) == "table" and (qData.queue or (qData[1] and qData))) or nil
        local candidates = {}
        if qList and type(qList) == "table" and #qList > 0 then
            for _, t in ipairs(qList) do
                local jid = tostring(t.jobId or "")
                local age = tonumber(t.age) or 0
                if jid ~= "" and age <= 240 and not isTaskVisited(jid) then
                    local taskRarity = normalizeRarity(t.level)
                    if not CONFIG.ALLOWED_SPROUT_RARITIES or CONFIG.ALLOWED_SPROUT_RARITIES[taskRarity] ~= false then
                        local prio = RARITY_PRIORITY[taskRarity] or 1
                        table.insert(candidates, {
                            jobId = jid,
                            level = taskRarity,
                            placeId = t.placeId or CONFIG.PLACE_ID,
                            fieldName = t.fieldName or "unknown",
                            age = age,
                            priority = prio,
                            searcherTag = t.searcherTag or "queue_history",
                        })
                    end
                end
            end
        end
        if #candidates > 0 then
            table.sort(candidates, function(a, b)
                if a.priority ~= b.priority then
                    return a.priority > b.priority
                end
                return a.age < b.age
            end)
            return candidates[1], nil
        end
    else
        lastErr = qErr
    end

    -- 2. Если в /queue ничего не подошло — опрашиваем /next
    local nData, nErr = apiGet("/next")
    if nData and not nData.empty and nData.jobId then
        local jid = tostring(nData.jobId)
        local age = tonumber(nData.age) or 0
        local taskRarity = normalizeRarity(nData.level)
        local isRarityAllowed = not CONFIG.ALLOWED_SPROUT_RARITIES or (CONFIG.ALLOWED_SPROUT_RARITIES[taskRarity] ~= false)
        if age <= 240 and not isTaskVisited(jid) and isRarityAllowed then
            nData.level = taskRarity
            return nData, nil
        end
    elseif not lastErr then
        lastErr = nErr
    end

    return nil, lastErr
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
    pcall(function() return postJson(endpoint, body) end)
    return true
end

function Looter:Start()
    self:Stop()
    local s = self.stats
    s.tasksReceived, s.teleports, s.lastTask = 0, 0, nil
    s.sproutsHarvested, s.hivesClaimed, s.tokensCollected = 0, 0, 0

    stopAutoDig()
    self.thread = task.spawn(function()
        s.currentStatus = "Ожидание загрузки игры..."
        waitForGameReady(25)

        -- Включаем наблюдатели за папками ростков
        watchFolders()

        -- Сброс данных улья прошлого сервера
        myClaimedHiveSlot = nil
        myClaimedHivePos = nil
        cachedHiveSlot = nil
        cachedHivePos = nil

        -- 1. Быстрая проверка сервера на росток (ровно 1.0 - 1.2 секунды)
        s.currentStatus = "Проверяю сервер на росток (1с)..."
        local sprout = nil
        local tStart = os.clock()
        while (os.clock() - tStart) < 1.2 do
            if not alive() then return end
            if CONFIG.CHECK_SPROUTS then
                sprout = findAnySprout()
                if sprout then break end
            end
            task.wait(0.1)
        end

        local meteors = (not sprout and CONFIG.CHECK_METEORS ~= false) and findActiveMeteors() or nil
        local vicious = (not sprout and not meteors and CONFIG.CHECK_VICIOUS) and findVicious() or nil

        -- ЕСЛИ РОСТОК ЕСТЬ — ЗАБЫВАЕТ ПРО ОЧЕРЕДЬ И ИДЕТ ЕГО ЛУТАТЬ!
        if sprout then
            s.currentStatus = "Росток на сервере — забываю про очередь, иду лутать!"
            log("Лутающий", "Росток обнаружен на сервере при входе! Блокирую очередь и иду лутать.")

            -- ШАГ 1: Занимаем свой улей
            if not hasOwnHive() then
                s.currentStatus = "Росток есть! Занимаю свой улей..."
                local claimOk, claimed = pcall(ensureHiveClaimed)
                if claimOk and claimed then s.hivesClaimed += 1 end
            end

            -- ШАГ 2: Если рюкзак полон — конвертируем
            if isBackpackFull() then
                s.currentStatus = "Рюкзак полон — конвертирую в своем улье..."
                pcall(makeHoney)
            end

            -- ШАГ 3: Полный сбор ростка (удар, слом, burst-лут, 15с сбор токенов)
            s.currentStatus = "Лечу лутать росток!"
            pcall(function() return self:harvest(sprout) end)

            -- ШАГ 4: Если рюкзак заполнился после ростка — конвертируем
            if isBackpackFull() then
                s.currentStatus = "Рюкзак полный — делаю Honey"
                pcall(makeHoney)
            end

            -- ШАГ 5: Долутывание ростка (гарантия 15 секунд сбора лута)
            while alive() and (os.clock() - lastSproutBrokenTime < 15) do
                local rem = math.ceil(15 - (os.clock() - lastSproutBrokenTime))
                s.currentStatus = string.format("Долутывание ростка (%dс)...", rem)
                collectTokensFor(math.min(rem, 3), function()
                    return not alive() or (os.clock() - lastSproutBrokenTime >= 15)
                end, lastSproutHarvestAnchor)
                task.wait(0.1)
            end
        elseif meteors then
            s.currentStatus = "☄️ Метеоритный дождь на сервере — лутаю!"
            log("Лутающий", "Метеоритный дождь обнаружен на сервере при входе! Блокирую очередь и лутаю.")
            if not hasOwnHive() then
                s.currentStatus = "Метеоры есть! Занимаю свой улей..."
                local claimOk, claimed = pcall(ensureHiveClaimed)
                if claimOk and claimed then s.hivesClaimed += 1 end
            end
            if isBackpackFull() then
                s.currentStatus = "Рюкзак полон — конвертирую в своем улье..."
                pcall(makeHoney)
            end
            s.currentStatus = "Лечу собирать метеоры!"
            pcall(function() lootMeteorShower(meteors) end)
            if isBackpackFull() then
                s.currentStatus = "Рюкзак полный — делаю Honey"
                pcall(makeHoney)
            end
        elseif vicious then
            if not hasOwnHive() then pcall(ensureHiveClaimed) end
            s.currentStatus = "Лечу бить Вициуса!"
            pcall(function() fightVicious(vicious) end)
        elseif CONFIG.CHECK_PUFFSHROOMS then
            local okPuff, puffList = pcall(findEligiblePuffshrooms)
            if okPuff and puffList and #puffList > 0 then
                s.currentStatus = "Puffshroom найден — начинаю сбор!"
                pcall(function() self:harvestPuffshrooms() end)
            end
        end

        -- Авто-сбор созревших плантаторов (только после проверки ростка, чтобы не отвлекать от него)
        if CONFIG.AUTO_HARVEST_PLANTERS ~= false and not findAnySprout() then
            pcall(managePlanters)
        end

        if isBackpackFull() then
            s.currentStatus = "Рюкзак полный — делаю Honey"
            pcall(makeHoney)
        end

        local taskAttempts = {}
        local looterLastSprinklerField = nil
        local looterLastSprinklerTime = 0

        -- А ПОСЛЕ ВСПОМИНАЕТ ПРО ОЧЕРЕДЬ:
        while true do
            if not alive() then return end
            local ok, err = pcall(function()
                s.serversChecked += 1

                -- 1. Если на сервере есть росток — ЛУТАЕМ ЕГО, ЗАБЫВАЯ ПРО ОЧЕРЕДЬ!
                local activeSprout = CONFIG.CHECK_SPROUTS and findAnySprout() or nil
                if activeSprout then
                    stopAutoDig()
                    tokenCollectorBusy = false
                    s.currentStatus = "Росток на сервере — лутаю!"
                    if not hasOwnHive() then pcall(ensureHiveClaimed) end
                    pcall(function() self:harvest(activeSprout) end)
                    if isBackpackFull() then pcall(makeHoney) end
                    return
                end

                -- 2. Если росток сломан, но ещё не прошло 15 секунд — долутываем, очередь НЕ трогаем!
                if lastSproutBrokenTime > 0 and (os.clock() - lastSproutBrokenTime < 15) then
                    local rem = math.ceil(15 - (os.clock() - lastSproutBrokenTime))
                    s.currentStatus = string.format("Долутывание ростка (%dс)...", rem)
                    collectTokensFor(math.min(rem, 3), function()
                        return not alive() or (os.clock() - lastSproutBrokenTime >= 15)
                    end, lastSproutHarvestAnchor)
                    return
                end

                -- 3. Если на сервере Вициус — бьем его
                if CONFIG.CHECK_VICIOUS then
                    local v = findVicious()
                    if v then
                        stopAutoDig()
                        tokenCollectorBusy = false
                        s.currentStatus = "Vicious на сервере — лечу!"
                        pcall(function() fightVicious(v) end)
                        return
                    end
                end

                -- 3.5 Если на сервере метеоритный дождь — лутаем его!
                if CONFIG.CHECK_METEORS ~= false then
                    local activeMeteors = findActiveMeteors()
                    if activeMeteors then
                        stopAutoDig()
                        tokenCollectorBusy = false
                        s.currentStatus = "☄️ Метеоритный дождь на сервере — лутаю!"
                        if not hasOwnHive() then pcall(ensureHiveClaimed) end
                        pcall(function() lootMeteorShower(activeMeteors) end)
                        if isBackpackFull() then pcall(makeHoney) end
                        return
                    end
                end

                -- 4. Если рюкзак полон — разгружаем в мед на улье
                while isBackpackFull() and alive() do
                    stopAutoDig()
                    tokenCollectorBusy = false
                    if not hasOwnHive() then
                        s.currentStatus = "Рюкзак полон — занимаю свободный улей..."
                        ensureHiveClaimed()
                        task.wait(1)
                    else
                        s.currentStatus = "Рюкзак полный — делаю Honey на улье..."
                        makeHoney()
                        task.wait(1)
                    end
                end

                -- 5. ТЕПЕРЬ ВСПОМИНАЕМ ПРО ОЧЕРЕДЬ (ростков на этом сервере нет, лут собран):
                local taskData, skipReason = nil, nil
                if CONFIG.CHECK_VICIOUS then
                    taskData, skipReason = self:fetchNextVicious()
                end
                if not taskData and CONFIG.CHECK_SPROUTS then
                    local sData, sReason = self:fetchNext()
                    if sData then
                        local taskRarity = normalizeRarity(sData.level)
                        if CONFIG.ALLOWED_SPROUT_RARITIES and CONFIG.ALLOWED_SPROUT_RARITIES[taskRarity] == false then
                            self:returnTask(sData, "rarity_disabled")
                            sData = nil
                        end
                        taskData = sData
                    elseif not skipReason then
                        skipReason = sReason
                    end
                end

                if taskData and taskData.jobId then
                    -- Дополнительная финальная проверка: вдруг росток или метеор появились прямо сейчас
                    local localSproutCheck = CONFIG.CHECK_SPROUTS and findAnySprout() or nil
                    if localSproutCheck then
                        self:returnTask(taskData, "farming_local_sprout")
                        pcall(function() self:harvest(localSproutCheck) end)
                        return
                    end

                    local localMeteorCheck = (CONFIG.CHECK_METEORS ~= false) and findActiveMeteors() or nil
                    if localMeteorCheck then
                        self:returnTask(taskData, "farming_local_meteor")
                        pcall(function() lootMeteorShower(localMeteorCheck) end)
                        return
                    end

                    -- Проверка защиты от перехода
                    local isProtected, protectReason = isSproutLootProtected()
                    if isProtected then
                        log("Лутающий", "Переход на сервер задачи отложен: " .. tostring(protectReason))
                        if lastSproutBrokenTime > 0 and (os.clock() - lastSproutBrokenTime < 15) then
                            while alive() and (os.clock() - lastSproutBrokenTime < 15) do
                                local rem = math.ceil(15 - (os.clock() - lastSproutBrokenTime))
                                s.currentStatus = string.format("Долутывание ростка перед переходом (%dс)...", rem)
                                collectTokensFor(math.min(rem, 3), function()
                                    return not alive() or (os.clock() - lastSproutBrokenTime >= 15)
                                end, lastSproutHarvestAnchor)
                                task.wait(0.1)
                            end
                        end
                        return
                    end

                    local targetJob = normalizeJobId(taskData.jobId)
                    local currentJob = normalizeJobId(game.JobId)

                    -- Если бот выдал сервер, на котором мы УЖЕ находимся
                    if targetJob ~= "" and targetJob == currentJob then
                        stopAutoDig()
                        tokenCollectorBusy = false
                        s.currentStatus = "Сервер задачи — ищу цель..."
                        local found = false
                        for _ = 1, 8 do
                            if not alive() then return end
                            local sObj = CONFIG.CHECK_SPROUTS and findAnySprout() or nil
                            if sObj then
                                pcall(function() self:harvest(sObj) end)
                                found = true
                                break
                            end
                            if CONFIG.CHECK_VICIOUS and findVicious() then
                                pcall(function() fightVicious(findVicious()) end)
                                found = true
                                break
                            end
                            task.wait(0.5)
                        end
                        if not found then
                            self:returnTask(taskData, "not_found")
                            task.wait(1)
                        end
                        return
                    end

                    -- Ограничение повторов недоступных серверов
                    local attempts = (taskAttempts[taskData.jobId] or 0) + 1
                    taskAttempts[taskData.jobId] = attempts
                    if attempts > 2 then
                        log("Лутающий", "Сервер задачи недоступен (попыток: " .. tostring(attempts) .. "), пропускаю")
                        rememberFailure(taskData.jobId)
                        self:returnTask(taskData, "unreachable")
                        task.wait(1)
                        return
                    end

                    -- Ищущие нашли задачу! Телепортируемся на сервер
                    stopAutoDig()
                    tokenCollectorBusy = false
                    s.tasksReceived += 1
                    s.lastTask = {
                        fieldName = taskData.isVicious and ("Vicious @ "..tostring(taskData.fieldName or "?"))
                            or (RARITY_LABEL[taskData.level] or taskData.level or "спрут"),
                        jobId = taskData.jobId, age = taskData.age,
                    }
                    s.currentStatus = "Переход на сервер задачи (" .. tostring(taskData.level or "росток") .. ")..."
                    s.teleports += 1
                    log("Лутающий", string.format("Переход на сервер задачи %s [%s]...", tostring(taskData.jobId), tostring(taskData.level or "?")))
                    if not hopTo(taskData.jobId, taskData.placeId, true) then
                        self:returnTask(taskData, "teleport failed")
                        task.wait(tonumber(CONFIG.POLL_INTERVAL) or 3)
                        return
                    end
                    markTaskVisited(taskData.jobId)
                    task.wait(25)
                    self:returnTask(taskData, "timeout")
                    return
                end

                -- Ожидание задач от ищущих (опрос очереди) или фарм на выбранном поле
                local fallbackField = CONFIG.FALLBACK_FARM_FIELD
                local canFallbackFarm = fallbackField and fallbackField ~= "" and fallbackField ~= "None"

                if canFallbackFarm then
                    local fPart = getFieldPart(fallbackField)
                    if fPart and alive() then
                        if not hasOwnHive() then
                            s.currentStatus = "Claiming hive before idle farming..."
                            pcall(ensureHiveClaimed)
                        end
                        if isBackpackFull() then
                            s.currentStatus = "Backpack full — converting honey..."
                            stopAutoDig()
                            pcall(makeHoney)
                        else
                            s.currentStatus = string.format("Idle farming @ %s...", tostring(fallbackField))
                            local safeGround = getGroundPos(fPart.Position)
                            local root = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
                            if root and safeGround then
                                local dist = (Vector3.new(root.Position.X, 0, root.Position.Z) - Vector3.new(safeGround.X, 0, safeGround.Z)).Magnitude
                                if dist > 35 then
                                    moveRootToPosition(root, safeGround, 10)
                                end
                            end

                            -- Автоматическая установка поливалок на поле
                            if (CONFIG.ENABLE_AUTO_SPRINKLER ~= false) and ((looterLastSprinklerField ~= fallbackField) or (os.clock() - looterLastSprinklerTime > 300)) then
                                s.currentStatus = string.format("Placing sprinklers on %s...", tostring(fallbackField))
                                if useSprinklerBuilder then
                                    pcall(useSprinklerBuilder, safeGround)
                                end
                                ensureHarvestToolEquipped()
                                looterLastSprinklerField = fallbackField
                                looterLastSprinklerTime = os.clock()
                            end

                            startAutoDig()
                            collectTokensFor(1.8, function()
                                if not alive() then return true end
                                if CONFIG.CHECK_SPROUTS and findAnySprout() then return true end
                                if (CONFIG.CHECK_METEORS ~= false) and findActiveMeteors() then return true end
                                if CONFIG.CHECK_VICIOUS and findVicious() then return true end
                                if isBackpackFull() then return true end
                                return false
                            end, safeGround)
                        end
                    else
                        stopAutoDig()
                        if skipReason and skipReason ~= "" then
                            s.currentStatus = "Waiting for tasks (" .. tostring(skipReason) .. ")..."
                        else
                            s.currentStatus = "Waiting for searcher tasks..."
                        end
                        task.wait(1)
                    end
                else
                    stopAutoDig()
                    if skipReason and skipReason ~= "" then
                        s.currentStatus = "Waiting for tasks (" .. tostring(skipReason) .. ")..."
                    else
                        s.currentStatus = "Waiting for searcher tasks..."
                    end
                    task.wait(1)
                end
            end)
            if not ok then
                log("Лутающий", "Ошибка: " .. tostring(err))
                task.wait(2)
            end
        end
    end)
end

function Looter:Stop()
    if self.thread then pcall(task.cancel, self.thread); self.thread = nil end
    tokenCollectorBusy = false
    patrolTarget = nil
    activeTokenObj = nil
    currentSproutFieldZone = nil
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
        s.currentStatus = "Ожидание загрузки игры..."
        waitForGameReady(25)
        s.currentStatus = "Соло активно — проверяю сервер на ростки..."
        task.wait(tonumber(CONFIG.INITIAL_CHECK) or 1.5)
        watchFolders()

        while true do
            if not alive() then return end
            local ok, err = pcall(function()
                s.serversChecked += 1

                -- Сброс данных улья прошлого сервера
                myClaimedHiveSlot = nil
                myClaimedHivePos = nil
                cachedHiveSlot = nil
                cachedHivePos = nil

                -- Проверка на наличие друзей на сервере (Анти-Палево)
                if CONFIG.AVOID_FRIENDS ~= false then
                    local hasFriend, friendName = checkFriendInServer()
                    if hasFriend then
                        log("Защита", string.format("На сервере обнаружен друг '%s'! Немедленно покидаю сервер...", tostring(friendName)))
                        s.currentStatus = "Обнаружен друг " .. tostring(friendName) .. " — меняю сервер..."
                        task.wait(1.5)
                        hopRandom()
                        task.wait(6)
                        return
                    end
                end

                -- Авто-сбор созревших плантаторов на сервере
                if CONFIG.AUTO_HARVEST_PLANTERS ~= false then
                    pcall(harvestMaturePlanters)
                end

                -- Комплексная проверка целей: Vicious, Росток, Грибы, Windy Bee, Метеоры
                s.currentStatus = "Сканирую сервер на цели (ростки, грибы, вициус, windy, метеоры)..."
                local vicious = CONFIG.CHECK_VICIOUS and findVicious() or nil
                local sprout = CONFIG.CHECK_SPROUTS and findSprout() or nil
                local puffRoot, puffRarity, puffLevel = nil, nil, nil
                if CONFIG.CHECK_PUFFSHROOMS then
                    puffRoot, puffRarity, puffLevel = findPuffshroom()
                end
                local windy = CONFIG.CHECK_WINDY and findWindyBee() or nil
                local meteors = CONFIG.CHECK_METEORS and findActiveMeteors() or nil

                -- Если целей нет — улей не ставим, переходим на другой сервер мгновенно!
                if not vicious and not sprout and not puffRoot and not windy and not meteors then
                    s.hops += 1
                    s.currentStatus = "Телепортируюсь на новый сервер..."
                    task.wait(0.02)
                    hopRandom()
                    return
                end

                -- ЦЕЛЬ ЕСТЬ (росток или вициус)!
                -- ШАГ 1: ПОСТАВИЛ УЛЕЙ!
                if not hasOwnHive() then
                    s.currentStatus = "Цель найдена! Занимаю свой улей..."
                    local claimOk, claimed = pcall(ensureHiveClaimed)
                    if claimOk and claimed then s.hivesClaimed += 1 end
                end

                -- ШАГ 2: ЕСЛИ РЮКЗАК ПОЛОН — КОНВЕРТИРУЕТ В СВОЕМ УЛЬЕ!
                if isBackpackFull() then
                    stopAutoDig()
                    tokenCollectorBusy = false
                    patrolTarget = nil
                    while isBackpackFull() and alive() do
                        s.currentStatus = "Рюкзак полный — делаю Honey в своем улье..."
                        makeHoney()
                        task.wait(0.5)
                    end
                end

                -- ШАГ 3: ЛЕТИТ ЛУТАТЬ!
                if windy then
                    s.currentStatus = "🌪️ Найдена Windy Bee — бегу на поле для боя!"
                    pcall(function() fightWindyBee(windy) end)
                    task.wait(1)
                    return
                end

                if meteors then
                    s.currentStatus = "☄️ На сервере метеоритный дождь — собираю метеоры!"
                    pcall(function() lootMeteorShower(meteors) end)
                    task.wait(1)
                    return
                end

                if puffRoot then
                    s.currentStatus = string.format("🍄 Найден гриб %s (лвл %d) — атакую!", RARITY_LABEL[puffRarity] or puffRarity, puffLevel or 1)
                    pcall(function() fightPuffshroom(puffRoot, puffRarity, puffLevel) end)
                    task.wait(1)
                    return
                end

                if vicious then
                    s.currentStatus = "Vicious найден — лечу к нему"
                    local searcher = Hopper.instances.searcher
                    if searcher then
                        searcher:reportVicious(game.JobId, detectViciousKind(vicious), detectField(vicious))
                    end
                    pcall(function() fightVicious(vicious) end)
                    task.wait(1)
                    return
                end

                if sprout then
                    s.sproutsFound += 1
                    local rar = detectRarity(sprout)
                    s.lastSprout = { fieldName = RARITY_LABEL[rar] or "спрут" }
                    s.currentStatus = "Лечу лутать росток: " .. (RARITY_LABEL[rar] or "спрут")
                    local sproutAnchor = worldPos(sprout)
                    currentSproutFieldZone = getActiveFlowerZone(sproutAnchor)
                    if moveToSprout(sprout) then
                        sproutAnchor = worldPos(sprout) or sproutAnchor or (player.Character and player.Character:FindFirstChild("HumanoidRootPart") and player.Character.HumanoidRootPart.Position)
                        currentSproutFieldZone = getActiveFlowerZone(sproutAnchor)
                        s.currentStatus = "Росток: ставлю поливалку"
                        task.wait(0.15)
                        if useSprinklerBuilder then pcall(useSprinklerBuilder, sproutAnchor) end
                        ensureHarvestToolEquipped()

                        -- Фаза 1: Росток жив. Бегает всегда, машет палкой 100%, собирает токены
                        while alive() and isSproutAlive(sprout, sproutAnchor) do
                            local char = player.Character
                            local root = char and char:FindFirstChild("HumanoidRootPart")
                            local hum = char and char:FindFirstChildOfClass("Humanoid")
                            if not root or not hum or hum.Health <= 0 or (sproutAnchor and (root.Position - sproutAnchor).Magnitude > 135) then
                                if not root or not hum or hum.Health <= 0 then
                                    s.currentStatus = "Персонаж погиб — жду возрождения..."
                                    char, root, hum = waitForRespawn(8)
                                end
                                task.wait(0.3)
                                if root and (sprout or sproutAnchor) then
                                    s.currentStatus = "Возвращаюсь к ростку после смерти..."
                                    if sprout and isSproutAlive(sprout, sproutAnchor) then
                                        moveToSprout(sprout)
                                    elseif sproutAnchor then
                                        moveRootToPosition(root, getGroundPos(sproutAnchor), 10)
                                    end
                                end
                            end

                            if CONFIG.CHECK_VICIOUS and findVicious() then break end
                            s.currentStatus = CONFIG.ENABLE_AUTO_DIG and "Росток: копаю и бегаю по полю" or "Росток: бегаю и собираю токены"
                            collectTokensFor(6, function()
                                return not alive() or not isSproutAlive(sprout, sproutAnchor)
                                    or (CONFIG.CHECK_VICIOUS and findVicious() ~= nil)
                            end, sproutAnchor)
                            task.wait(0.05)
                        end

                        -- Фаза 2: Росток сломан! Засекаем точное время поломки
                        lastSproutBrokenTime = os.clock()
                        lastSproutHarvestAnchor = sproutAnchor
                        log("Спрут", "Росток сломан! Запущен 15-секундный таймер обязательного лутания.")

                        if alive() and sproutAnchor and not (CONFIG.CHECK_VICIOUS and findVicious()) then
                            local char = player.Character
                            local root = char and char:FindFirstChild("HumanoidRootPart")
                            local hum = char and char:FindFirstChildOfClass("Humanoid")
                            if not root or not hum or hum.Health <= 0 or (root.Position - sproutAnchor).Magnitude > 135 then
                                if not root or not hum or hum.Health <= 0 then
                                    char, root, hum = waitForRespawn(8)
                                end
                                task.wait(0.3)
                                if root and sproutAnchor then
                                    log("Возврат", "Возврат к сломанному ростку после смерти...")
                                    moveRootToPosition(root, getGroundPos(sproutAnchor), 10)
                                end
                            end

                            stopAutoDig()
                            tokenCollectorBusy = false
                            patrolTarget = nil

                            -- BURST-РЕЖИМ СБОРА
                            if CONFIG.BURST_LOOT_ENABLED ~= false then
                                s.currentStatus = "⚡ BURST-СБОР: Сверхбыстрый сбор редкого лута!"
                                isBurstLootActive = true
                                local burstTime = tonumber(CONFIG.BURST_LOOT_TIME) or 7
                                local burstStart = os.clock()
                                collectTokensFor(burstTime, function()
                                    return not alive()
                                        or (CONFIG.CHECK_VICIOUS and findVicious() ~= nil)
                                        or (os.clock() - burstStart >= burstTime)
                                end, sproutAnchor)
                                isBurstLootActive = false
                            end

                            -- Обязательный сбор оставшихся токенов (не менее 15 секунд с момента поломки)
                            local totalLootDuration = math.max(15, tonumber(CONFIG.BROKEN_WAIT) or 20)
                            while alive() and not (CONFIG.CHECK_VICIOUS and findVicious()) and (os.clock() - lastSproutBrokenTime < totalLootDuration) do
                                local elapsed = os.clock() - lastSproutBrokenTime
                                local remaining = math.ceil(totalLootDuration - elapsed)
                                s.currentStatus = string.format("Росток сломан — сбор лута (ещё %dс)...", remaining)
                                collectTokensFor(math.min(remaining, 5), function()
                                    return not alive()
                                        or (CONFIG.CHECK_VICIOUS and findVicious() ~= nil)
                                        or (os.clock() - lastSproutBrokenTime >= totalLootDuration)
                                end, sproutAnchor)
                                task.wait(0.05)
                            end
                        end
                    end

                    -- Разгрузка перед переходом на следующий сервер
                    if isBackpackFull() then
                        stopAutoDig()
                        tokenCollectorBusy = false
                        patrolTarget = nil
                        while isBackpackFull() and alive() do
                            s.currentStatus = "Рюкзак полный — делаю Honey перед переходом"
                            makeHoney()
                            task.wait(0.5)
                        end
                    end

                    -- Фаза 3: Росток залутан! Переход на следующий сервер
                    currentSproutFieldZone = nil
                    s.hops += 1
                    s.currentStatus = "Телепортируюсь на новый сервер..."
                    task.wait(0.02)
                    hopRandom()
                    return
                end

                -- Если ростка нет на сервере — быстрый переход (с защитой от ухода до завершения сбора и 15с)
                local isProtected, protectReason = isSproutLootProtected()
                if isProtected then
                    if CONFIG.CHECK_SPROUTS and findSprout() then
                        -- росток есть на сервере
                    elseif lastSproutBrokenTime > 0 and (os.clock() - lastSproutBrokenTime < 15) then
                        local rem = math.ceil(15 - (os.clock() - lastSproutBrokenTime))
                        collectTokensFor(math.min(rem, 3), function()
                            return not alive() or (os.clock() - lastSproutBrokenTime >= 15)
                        end, lastSproutHarvestAnchor)
                    end
                    return
                end

                currentSproutFieldZone = nil
                s.hops += 1
                s.currentStatus = "Телепортируюсь на новый сервер..."
                task.wait(0.02)
                hopRandom()
                return
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
    currentSproutFieldZone = nil
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
--  GUI (MODERN CLICK GUI - 100% ENGLISH)
-- ══════════════════════════════════════════════════════════════════════
local modeButtons = {}
local readyPill
local isOpen = true
local refresh
local showPage
local setWindow
local C
local gui
local farmFieldText
local updateFieldPickerUI

local guiOk, guiErr = pcall(function()

local PlayerGui = player:WaitForChild("PlayerGui")
trace("PlayerGui acquired")
local old = PlayerGui:FindFirstChild("BssHopperGui")
if old then old:Destroy() end

C = {
    bg = Color3.fromRGB(13, 16, 23),
    panel = Color3.fromRGB(18, 22, 32),
    sidebar = Color3.fromRGB(15, 18, 27),
    card = Color3.fromRGB(24, 29, 42),
    cardHover = Color3.fromRGB(30, 36, 52),
    cardHi = Color3.fromRGB(20, 52, 40),
    field = Color3.fromRGB(14, 17, 25),
    border = Color3.fromRGB(36, 44, 64),
    borderActive = Color3.fromRGB(34, 197, 94),
    text = Color3.fromRGB(243, 244, 246),
    dim = Color3.fromRGB(138, 148, 168),
    accent = Color3.fromRGB(34, 197, 94),     -- #22c55e Emerald
    accent2 = Color3.fromRGB(16, 185, 129),   -- #10b981 Emerald dark
    danger = Color3.fromRGB(239, 68, 68),     -- #ef4444 Red
    warn = Color3.fromRGB(245, 158, 11),      -- #f59e0b Amber
}

local function new(class, props)
    local o = Instance.new(class)
    for k, v in pairs(props or {}) do o[k] = v end
    return o
end

local function round(o, r)
    new("UICorner", { CornerRadius = UDim.new(0, r or 10), Parent = o })
end

local function stroke(o, c, t)
    return new("UIStroke", {
        Color = c or C.border,
        Thickness = t or 1,
        Transparency = 0.2,
        Parent = o,
    })
end

gui = new("ScreenGui", {
    Name = "BssHopperGui",
    ResetOnSpawn = false,
    IgnoreGuiInset = true,
    DisplayOrder = 999999,
    ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
    Parent = PlayerGui,
})

-- ══════════════════════════════════════════════════════════════════════
--  FLOATING TOGGLE WIDGET
-- ══════════════════════════════════════════════════════════════════════
local SNAKE_SIZE = 46
local snake = new("TextButton", {
    Name = "FloatingWidget",
    Size = UDim2.new(0, SNAKE_SIZE, 0, SNAKE_SIZE),
    Position = uiState.snakePos or UDim2.new(0.5, -SNAKE_SIZE/2, 0, 45),
    BackgroundColor3 = C.panel,
    Text = "⚡",
    Font = Enum.Font.GothamBold,
    TextSize = 22,
    TextColor3 = C.accent,
    BorderSizePixel = 0,
    Draggable = true,
    Active = true,
    Parent = gui,
})
round(snake, SNAKE_SIZE/2)
stroke(snake, C.border, 1.5)

local dot = new("Frame", {
    Size = UDim2.new(0, 10, 0, 10),
    Position = UDim2.new(1, -12, 1, -12),
    BackgroundColor3 = C.danger,
    BorderSizePixel = 0,
    Parent = snake,
})
round(dot, 5)
stroke(dot, C.bg, 1.5)

local hint = new("TextLabel", {
    Size = UDim2.new(0, 320, 0, 14),
    Position = UDim2.new(0.5, -160, 0, 45 + SNAKE_SIZE + 4),
    BackgroundTransparency = 1,
    Text = "LMB: Toggle Bot  •  RMB / F: Menu  •  P: Pause",
    TextColor3 = C.dim,
    Font = Enum.Font.GothamMedium,
    TextSize = 10,
    TextTransparency = 0.3,
    Parent = gui,
})

-- ══════════════════════════════════════════════════════════════════════
--  ON-SCREEN PLANTER TIMERS HUD
-- ══════════════════════════════════════════════════════════════════════
local planterHudFrame = new("Frame", {
    Name = "PlanterTimersHUD",
    Size = UDim2.new(0, 240, 0, 0),
    AutomaticSize = Enum.AutomaticSize.Y,
    Position = UDim2.new(1, -255, 0, 65),
    BackgroundColor3 = C.panel,
    BorderSizePixel = 0,
    Active = true,
    Draggable = true,
    Visible = (CONFIG.SHOW_PLANTER_HUD ~= false),
    Parent = gui,
})
round(planterHudFrame, 10)
stroke(planterHudFrame, C.border, 1)

local planterHudHeader = new("Frame", {
    Size = UDim2.new(1, 0, 0, 28),
    BackgroundTransparency = 1,
    Parent = planterHudFrame,
})
new("TextLabel", {
    Size = UDim2.new(1, -36, 1, 0),
    Position = UDim2.new(0, 10, 0, 0),
    BackgroundTransparency = 1,
    Text = "Planter Timers",
    Font = Enum.Font.GothamBold,
    TextSize = 11,
    TextColor3 = C.text,
    TextXAlignment = Enum.TextXAlignment.Left,
    Parent = planterHudHeader,
})
local planterHudArrow = new("TextButton", {
    Size = UDim2.new(0, 26, 0, 26),
    Position = UDim2.new(1, -28, 0, 1),
    BackgroundTransparency = 1,
    Text = CONFIG.PLANTER_HUD_COLLAPSED and "▲" or "▼",
    Font = Enum.Font.GothamBold,
    TextSize = 11,
    TextColor3 = C.dim,
    Parent = planterHudHeader,
})
local planterHudContent = new("Frame", {
    Size = UDim2.new(1, 0, 0, 0),
    AutomaticSize = Enum.AutomaticSize.Y,
    Position = UDim2.new(0, 0, 0, 28),
    BackgroundTransparency = 1,
    Visible = not CONFIG.PLANTER_HUD_COLLAPSED,
    Parent = planterHudFrame,
})
new("UIListLayout", { SortOrder = Enum.SortOrder.LayoutOrder, Padding = UDim.new(0, 4), Parent = planterHudContent })
new("UIPadding", { PaddingTop = UDim.new(0, 2), PaddingBottom = UDim.new(0, 8), PaddingLeft = UDim.new(0, 10), PaddingRight = UDim.new(0, 10), Parent = planterHudContent })

planterHudArrow.MouseButton1Click:Connect(function()
    CONFIG.PLANTER_HUD_COLLAPSED = not CONFIG.PLANTER_HUD_COLLAPSED
    planterHudContent.Visible = not CONFIG.PLANTER_HUD_COLLAPSED
    planterHudArrow.Text = CONFIG.PLANTER_HUD_COLLAPSED and "▲" or "▼"
    saveNow()
end)

local function refreshPlanterHud(activeList)
    if not planterHudContent then return end
    planterHudContent:ClearAllChildren()
    new("UIListLayout", { SortOrder = Enum.SortOrder.LayoutOrder, Padding = UDim.new(0, 4), Parent = planterHudContent })
    new("UIPadding", { PaddingTop = UDim.new(0, 2), PaddingBottom = UDim.new(0, 8), PaddingLeft = UDim.new(0, 10), PaddingRight = UDim.new(0, 10), Parent = planterHudContent })

    if not activeList or #activeList == 0 then
        new("TextLabel", {
            Size = UDim2.new(1, 0, 0, 18),
            BackgroundTransparency = 1,
            Text = "No active planters",
            TextColor3 = C.dim,
            Font = Enum.Font.Gotham,
            TextSize = 11,
            TextXAlignment = Enum.TextXAlignment.Left,
            Parent = planterHudContent,
        })
        return
    end

    for idx, info in ipairs(activeList) do
        local isReady = info.ready or (info.percent >= 100) or string.find(string.lower(info.statusStr or ""), "0s", 1, true)
        local lineText = string.format("%s: %s (%s)", info.type or "Planter", info.statusStr or "?", info.field or "?")
        new("TextLabel", {
            Size = UDim2.new(1, 0, 0, 18),
            BackgroundTransparency = 1,
            Text = lineText,
            TextColor3 = isReady and C.accent or C.text,
            Font = isReady and Enum.Font.GothamBold or Enum.Font.GothamMedium,
            TextSize = 11,
            TextXAlignment = Enum.TextXAlignment.Left,
            LayoutOrder = idx,
            Parent = planterHudContent,
        })
    end
end

-- ══════════════════════════════════════════════════════════════════════
--  MAIN CLICK GUI WINDOW
-- ══════════════════════════════════════════════════════════════════════
local WIN_W, WIN_H = 760, 480
local HEADER_H = 48
local SIDEBAR_W = 150

local win = new("Frame", {
    Name = "MainWindow",
    Size = UDim2.new(0, WIN_W, 0, WIN_H),
    Position = uiState.winPos or UDim2.new(0.5, -WIN_W/2, 0.5, -WIN_H/2),
    BackgroundColor3 = C.bg,
    BorderSizePixel = 0,
    Visible = true,
    Active = true,
    ClipsDescendants = true,
    Parent = gui,
})
round(win, 12)
stroke(win, C.border, 1.2)

-- HEADER
local head = new("Frame", {
    Size = UDim2.new(1, 0, 0, HEADER_H),
    BackgroundColor3 = C.panel,
    BorderSizePixel = 0,
    Parent = win,
})
round(head, 12)
new("Frame", {
    Size = UDim2.new(1, 0, 0, 1),
    Position = UDim2.new(0, 0, 1, -1),
    BackgroundColor3 = C.border,
    BorderSizePixel = 0,
    Parent = head,
})

-- Header Title & Badges
new("TextLabel", {
    Size = UDim2.new(0, 24, 1, 0),
    Position = UDim2.new(0, 14, 0, 0),
    BackgroundTransparency = 1,
    Text = "⚡",
    Font = Enum.Font.GothamBold,
    TextSize = 16,
    TextColor3 = C.accent,
    Parent = head,
})
new("TextLabel", {
    Size = UDim2.new(0, 120, 1, 0),
    Position = UDim2.new(0, 40, 0, 0),
    BackgroundTransparency = 1,
    Text = "BSS Hopper",
    TextColor3 = C.text,
    Font = Enum.Font.GothamBold,
    TextSize = 15,
    TextXAlignment = Enum.TextXAlignment.Left,
    Parent = head,
})
local verBadge = new("Frame", {
    Size = UDim2.new(0, 42, 0, 20),
    Position = UDim2.new(0, 150, 0.5, -10),
    BackgroundColor3 = C.card,
    BorderSizePixel = 0,
    Parent = head,
})
round(verBadge, 6)
new("TextLabel", {
    Size = UDim2.new(1, 0, 1, 0),
    BackgroundTransparency = 1,
    Text = "v2.0",
    TextColor3 = C.dim,
    Font = Enum.Font.GothamBold,
    TextSize = 10,
    Parent = verBadge,
})

-- Status Pill in Header
readyPill = new("Frame", {
    Name = "SystemReadyPill",
    Size = UDim2.new(0, 95, 0, 24),
    Position = UDim2.new(0, 202, 0.5, -12),
    BackgroundColor3 = C.card,
    BorderSizePixel = 0,
    Parent = head,
})
round(readyPill, 6)
local pillDot = new("Frame", {
    Size = UDim2.new(0, 6, 0, 6),
    Position = UDim2.new(0, 8, 0.5, -3),
    BackgroundColor3 = C.danger,
    BorderSizePixel = 0,
    Parent = readyPill,
})
round(pillDot, 3)
local pillLabel = new("TextLabel", {
    Size = UDim2.new(1, -20, 1, 0),
    Position = UDim2.new(0, 18, 0, 0),
    BackgroundTransparency = 1,
    Text = "IDLE",
    TextColor3 = C.dim,
    Font = Enum.Font.GothamBold,
    TextSize = 10,
    TextXAlignment = Enum.TextXAlignment.Left,
    Parent = readyPill,
})

-- Header Buttons (Discord, Close)
local DISCORD_URL = "https://discord.gg/2YmPh2wExu"
local function openUrl(url)
    local attempts = {
        function() if type(loadurl) == "function" then return loadurl(url) end end,
        function() if type(open_url) == "function" then return open_url(url) end end,
    }
    for _, fn in ipairs(attempts) do
        local ok, result = pcall(fn)
        if ok and result ~= false then return true end
    end
    if type(setclipboard) == "function" then pcall(setclipboard, url) end
    return false
end

local discordBtn = new("TextButton", {
    Size = UDim2.new(0, 30, 0, 30),
    Position = UDim2.new(1, -72, 0.5, -15),
    BackgroundColor3 = C.card,
    Text = "💬",
    Font = Enum.Font.GothamBold,
    TextSize = 13,
    TextColor3 = Color3.fromRGB(88, 101, 242),
    BorderSizePixel = 0,
    Parent = head,
})
round(discordBtn, 6)
discordBtn.MouseButton1Click:Connect(function() openUrl(DISCORD_URL) end)

local menuToggleBtn = new("TextButton", {
    Size = UDim2.new(0, 110, 0, 28),
    Position = UDim2.new(1, -190, 0.5, -14),
    BackgroundColor3 = C.cardHi,
    Text = "OPEN MENU ▼",
    TextColor3 = C.accent,
    Font = Enum.Font.GothamBold,
    TextSize = 10,
    BorderSizePixel = 0,
    Visible = not isOpen,
    Parent = head,
})
round(menuToggleBtn, 6)
stroke(menuToggleBtn, C.accent, 1)
menuToggleBtn.MouseButton1Click:Connect(function()
    if setWindow then setWindow(true) end
end)

local closeBtn = new("TextButton", {
    Size = UDim2.new(0, 30, 0, 30),
    Position = UDim2.new(1, -38, 0.5, -15),
    BackgroundColor3 = C.card,
    Text = isOpen and "✕" or "▼",
    TextColor3 = isOpen and C.dim or C.accent,
    Font = Enum.Font.GothamBold,
    TextSize = 12,
    BorderSizePixel = 0,
    Parent = head,
})
round(closeBtn, 6)
closeBtn.MouseButton1Click:Connect(function()
    if setWindow then setWindow(not isOpen) end
end)

head.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 and not isOpen then
        if setWindow then setWindow(true) end
    end
end)

-- ══════════════════════════════════════════════════════════════════════
--  SIDEBAR NAVIGATION
-- ══════════════════════════════════════════════════════════════════════
local sidebar = new("Frame", {
    Name = "Sidebar",
    Size = UDim2.new(0, SIDEBAR_W, 1, -HEADER_H),
    Position = UDim2.new(0, 0, 0, HEADER_H),
    BackgroundColor3 = C.sidebar,
    BorderSizePixel = 0,
    Parent = win,
})
new("Frame", {
    Name = "SidebarDivider",
    Size = UDim2.new(0, 1, 1, -HEADER_H),
    Position = UDim2.new(0, SIDEBAR_W, 0, HEADER_H),
    BackgroundColor3 = C.border,
    BorderSizePixel = 0,
    Parent = win,
})
new("UIListLayout", {
    SortOrder = Enum.SortOrder.LayoutOrder,
    Padding = UDim.new(0, 4),
    Parent = sidebar,
})
new("UIPadding", {
    PaddingTop = UDim.new(0, 10),
    PaddingBottom = UDim.new(0, 10),
    PaddingLeft = UDim.new(0, 8),
    PaddingRight = UDim.new(0, 8),
    Parent = sidebar,
})

new("TextLabel", {
    Size = UDim2.new(1, 0, 0, 16),
    BackgroundTransparency = 1,
    Text = "NAVIGATION",
    TextColor3 = C.dim,
    Font = Enum.Font.GothamBold,
    TextSize = 9,
    TextXAlignment = Enum.TextXAlignment.Left,
    LayoutOrder = 0,
    Parent = sidebar,
})

local tabButtons = {}
local tabOrder = 1
local function makeTab(icon, label, key)
    local b = new("TextButton", {
        Size = UDim2.new(1, 0, 0, 36),
        BackgroundColor3 = C.sidebar,
        Text = "",
        BorderSizePixel = 0,
        AutoButtonColor = false,
        LayoutOrder = tabOrder,
        Active = true,
        Parent = sidebar,
    })
    tabOrder = tabOrder + 1
    round(b, 8)

    local bar = new("Frame", {
        Size = UDim2.new(0, 3, 1, -12),
        Position = UDim2.new(0, 0, 0, 6),
        BackgroundColor3 = C.accent,
        BorderSizePixel = 0,
        Visible = false,
        Parent = b,
    })
    round(bar, 2)

    local ico = new("TextLabel", {
        Size = UDim2.new(0, 22, 1, 0),
        Position = UDim2.new(0, 8, 0, 0),
        BackgroundTransparency = 1,
        Text = icon,
        Font = Enum.Font.GothamBold,
        TextSize = 13,
        TextColor3 = C.dim,
        Active = false,
        Parent = b,
    })
    local lbl = new("TextLabel", {
        Size = UDim2.new(1, -34, 1, 0),
        Position = UDim2.new(0, 34, 0, 0),
        BackgroundTransparency = 1,
        Text = label,
        TextColor3 = C.dim,
        Font = Enum.Font.GothamBold,
        TextSize = 11,
        TextXAlignment = Enum.TextXAlignment.Left,
        Active = false,
        Parent = b,
    })
    tabButtons[key] = { btn=b, bar=bar, icon=ico, label=lbl }
    return b
end

makeTab("⌂", "Dashboard", "main")
makeTab("🌱", "Sprouts", "sprouts")
makeTab("🪴", "Planters & Mobs", "planters_mobs")
makeTab("📁", "Configs", "configs")
makeTab("⚙", "Settings", "settings")

-- ══════════════════════════════════════════════════════════════════════
--  CONTENT CONTAINER
-- ══════════════════════════════════════════════════════════════════════
local content = new("ScrollingFrame", {
    Name = "Content",
    Size = UDim2.new(1, -SIDEBAR_W - 16, 1, -HEADER_H - 12),
    Position = UDim2.new(0, SIDEBAR_W + 8, 0, HEADER_H + 6),
    BackgroundTransparency = 1,
    BorderSizePixel = 0,
    ScrollBarThickness = 4,
    ScrollBarImageColor3 = C.border,
    AutomaticCanvasSize = Enum.AutomaticSize.Y,
    CanvasSize = UDim2.new(),
    ScrollingDirection = Enum.ScrollingDirection.Y,
    Parent = win,
})
new("UIListLayout", { SortOrder = Enum.SortOrder.LayoutOrder, Padding = UDim.new(0, 8), Parent = content })
new("UIPadding", { PaddingTop = UDim.new(0, 4), PaddingBottom = UDim.new(0, 14), PaddingRight = UDim.new(0, 6), Parent = content })

local function section(parent, title, order)
    local sec = new("Frame", {
        Size = UDim2.new(1, 0, 0, 22),
        BackgroundTransparency = 1,
        LayoutOrder = order,
        Parent = parent,
    })
    new("TextLabel", {
        Size = UDim2.new(1, 0, 1, 0),
        BackgroundTransparency = 1,
        Text = string.upper(title),
        TextColor3 = C.dim,
        Font = Enum.Font.GothamBold,
        TextSize = 9,
        TextXAlignment = Enum.TextXAlignment.Left,
        Parent = sec,
    })
    return sec
end

local function makeToggle(parent, label, desc, value, order, onChanged)
    local card = new("Frame", {
        Size = UDim2.new(1, 0, 0, desc and 44 or 36),
        BackgroundColor3 = C.card,
        BorderSizePixel = 0,
        LayoutOrder = order,
        Parent = parent,
    })
    round(card, 8)
    stroke(card, C.border, 1)

    new("TextLabel", {
        Size = UDim2.new(1, -65, 0, desc and 18 or 36),
        Position = UDim2.new(0, 12, 0, desc and 5 or 0),
        BackgroundTransparency = 1,
        Text = label,
        TextColor3 = C.text,
        Font = Enum.Font.GothamBold,
        TextSize = 11,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextYAlignment = Enum.TextYAlignment.Center,
        Parent = card,
    })
    if desc then
        new("TextLabel", {
            Size = UDim2.new(1, -65, 0, 15),
            Position = UDim2.new(0, 12, 0, 22),
            BackgroundTransparency = 1,
            Text = desc,
            TextColor3 = C.dim,
            Font = Enum.Font.Gotham,
            TextSize = 9,
            TextXAlignment = Enum.TextXAlignment.Left,
            Parent = card,
        })
    end

    local state = (value == true)
    local switch = new("TextButton", {
        Size = UDim2.new(0, 42, 0, 20),
        Position = UDim2.new(1, -52, 0.5, -10),
        BackgroundColor3 = state and C.accent or Color3.fromRGB(30, 36, 50),
        Text = "",
        AutoButtonColor = false,
        BorderSizePixel = 0,
        Parent = card,
    })
    round(switch, 10)
    local switchStroke = stroke(switch, state and C.accent2 or C.border, 1)

    local circle = new("Frame", {
        Size = UDim2.new(0, 14, 0, 14),
        Position = state and UDim2.new(1, -17, 0.5, -7) or UDim2.new(0, 3, 0.5, -7),
        BackgroundColor3 = Color3.fromRGB(255, 255, 255),
        BorderSizePixel = 0,
        Parent = switch,
    })
    round(circle, 7)

    local function updateSwitch(s)
        state = s
        local targetColor = state and C.accent or Color3.fromRGB(30, 36, 50)
        local targetPos = state and UDim2.new(1, -17, 0.5, -7) or UDim2.new(0, 3, 0.5, -7)
        local tw = TweenInfo.new(0.18, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
        TweenService:Create(switch, tw, { BackgroundColor3 = targetColor }):Play()
        TweenService:Create(circle, tw, { Position = targetPos }):Play()
        if switchStroke then switchStroke.Color = state and C.accent2 or C.border end
    end

    switch.MouseButton1Click:Connect(function()
        updateSwitch(not state)
        if onChanged then pcall(onChanged, state) end
    end)

    return function(v)
        if v ~= nil then updateSwitch(v) end
        return state
    end
end

local function makeField(parent, label, value, placeholder, order, onSubmitted)
    local card = new("Frame", {
        Size = UDim2.new(1, 0, 0, 46),
        BackgroundColor3 = C.card,
        BorderSizePixel = 0,
        LayoutOrder = order,
        Parent = parent,
    })
    round(card, 8)
    stroke(card, C.border, 1)

    new("TextLabel", {
        Size = UDim2.new(1, -20, 0, 13),
        Position = UDim2.new(0, 12, 0, 5),
        BackgroundTransparency = 1,
        Text = string.upper(label),
        TextColor3 = C.dim,
        Font = Enum.Font.GothamBold,
        TextSize = 8,
        TextXAlignment = Enum.TextXAlignment.Left,
        Parent = card,
    })

    local tb = new("TextBox", {
        Size = UDim2.new(1, -24, 0, 20),
        Position = UDim2.new(0, 12, 0, 20),
        BackgroundColor3 = C.field,
        Text = tostring(value or ""),
        PlaceholderText = placeholder or "",
        PlaceholderColor3 = Color3.fromRGB(90, 100, 120),
        TextColor3 = C.text,
        Font = Enum.Font.GothamMedium,
        TextSize = 11,
        ClearTextOnFocus = false,
        TextXAlignment = Enum.TextXAlignment.Left,
        BorderSizePixel = 0,
        Parent = card,
    })
    round(tb, 5)
    new("UIPadding", { PaddingLeft = UDim.new(0, 6), PaddingRight = UDim.new(0, 6), Parent = tb })

    tb.FocusLost:Connect(function()
        if onSubmitted then pcall(onSubmitted, tb.Text) end
        if applySettings then pcall(applySettings) end
    end)
    return tb
end

local function makeBtn(parent, text, icon, col, order, onClick)
    local b = new("TextButton", {
        Size = UDim2.new(1, 0, 0, 34),
        BackgroundColor3 = col or C.card,
        Text = "",
        BorderSizePixel = 0,
        AutoButtonColor = false,
        LayoutOrder = order,
        Parent = parent,
    })
    round(b, 8)
    stroke(b, C.border, 1)

    local row = new("Frame", {
        Size = UDim2.new(1, 0, 1, 0),
        BackgroundTransparency = 1,
        Parent = b,
    })
    new("UIListLayout", {
        FillDirection = Enum.FillDirection.Horizontal,
        HorizontalAlignment = Enum.HorizontalAlignment.Center,
        VerticalAlignment = Enum.VerticalAlignment.Center,
        Padding = UDim.new(0, 6),
        Parent = row,
    })
    if icon and icon ~= "" then
        new("TextLabel", {
            Size = UDim2.new(0, 16, 1, 0),
            BackgroundTransparency = 1,
            Text = icon,
            TextColor3 = C.text,
            Font = Enum.Font.GothamBold,
            TextSize = 12,
            Parent = row,
        })
    end
    new("TextLabel", {
        Size = UDim2.new(0, 0, 1, 0),
        AutomaticSize = Enum.AutomaticSize.X,
        BackgroundTransparency = 1,
        Text = text,
        TextColor3 = C.text,
        Font = Enum.Font.GothamBold,
        TextSize = 11,
        Parent = row,
    })

    b.MouseEnter:Connect(function()
        TweenService:Create(b, TweenInfo.new(0.12), { BackgroundColor3 = col and col:Lerp(Color3.new(1,1,1), 0.1) or C.cardHover }):Play()
    end)
    b.MouseLeave:Connect(function()
        TweenService:Create(b, TweenInfo.new(0.12), { BackgroundColor3 = col or C.card }):Play()
    end)
    b.MouseButton1Click:Connect(function() if onClick then pcall(onClick) end end)
    return b
end

-- ══════════════════════════════════════════════════════════════════════
--  TAB 1: DASHBOARD (MAIN)
-- ══════════════════════════════════════════════════════════════════════
local PAGE_HOME = new("Frame", {
    Size = UDim2.new(1, 0, 0, 0),
    AutomaticSize = Enum.AutomaticSize.Y,
    BackgroundTransparency = 1,
    Visible = true,
    Parent = content,
})
new("UIListLayout", { SortOrder = Enum.SortOrder.LayoutOrder, Padding = UDim.new(0, 8), Parent = PAGE_HOME })

-- 1. Mode Cards
section(PAGE_HOME, "Select Mode", 1)
local modeRow = new("Frame", {
    Size = UDim2.new(1, 0, 0, 78),
    BackgroundTransparency = 1,
    LayoutOrder = 2,
    Parent = PAGE_HOME,
})
new("UIListLayout", { FillDirection = Enum.FillDirection.Horizontal, Padding = UDim.new(0, 8), Parent = modeRow })

local MODE_META = {
    searcher = { icon="🔍", name="Searcher", desc="Fast hops & scans servers" },
    looter   = { icon="💰", name="Looter",   desc="Claims hive & loots queue tasks" },
    solo     = { icon="🎮", name="Solo",     desc="Autonomous farming & hopper" },
}

local mIdx = 1
for _, key in ipairs({ "searcher", "looter", "solo" }) do
    local m = MODE_META[key]
    local b = new("TextButton", {
        Size = UDim2.new(1/3, -6, 1, 0),
        BackgroundColor3 = C.card,
        Text = "",
        BorderSizePixel = 0,
        AutoButtonColor = false,
        LayoutOrder = mIdx,
        Parent = modeRow,
    })
    mIdx = mIdx + 1
    round(b, 10)
    local mStroke = stroke(b, C.border, 1)

    new("TextLabel", {
        Size = UDim2.new(0, 24, 0, 24),
        Position = UDim2.new(0, 12, 0, 8),
        BackgroundTransparency = 1,
        Text = m.icon,
        Font = Enum.Font.GothamBold,
        TextSize = 16,
        Parent = b,
    })
    local tl = new("TextLabel", {
        Size = UDim2.new(1, -44, 0, 20),
        Position = UDim2.new(0, 40, 0, 10),
        BackgroundTransparency = 1,
        Text = m.name,
        TextColor3 = C.text,
        Font = Enum.Font.GothamBold,
        TextSize = 13,
        TextXAlignment = Enum.TextXAlignment.Left,
        Parent = b,
    })
    new("TextLabel", {
        Size = UDim2.new(1, -24, 0, 32),
        Position = UDim2.new(0, 12, 0, 36),
        BackgroundTransparency = 1,
        Text = m.desc,
        TextWrapped = true,
        TextColor3 = C.dim,
        Font = Enum.Font.Gotham,
        TextSize = 9,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextYAlignment = Enum.TextYAlignment.Top,
        Parent = b,
    })
    local bar = new("Frame", {
        Size = UDim2.new(1, -20, 0, 2),
        Position = UDim2.new(0, 10, 1, -5),
        BackgroundColor3 = C.accent,
        BorderSizePixel = 0,
        Visible = false,
        Parent = b,
    })
    round(bar, 1)

    b.MouseEnter:Connect(function()
        if Hopper.Mode ~= Hopper.instances[key] then
            TweenService:Create(b, TweenInfo.new(0.12), { BackgroundColor3 = C.cardHover }):Play()
        end
    end)
    b.MouseLeave:Connect(function()
        if Hopper.Mode ~= Hopper.instances[key] then
            TweenService:Create(b, TweenInfo.new(0.12), { BackgroundColor3 = C.card }):Play()
        end
    end)
    b.MouseButton1Click:Connect(function()
        if Hopper.Mode == Hopper.instances[key] then Hopper.SwitchMode("off")
        else Hopper.SwitchMode(key) end
    end)
    modeButtons[key] = { btn=b, title=tl, bar=bar, outline=mStroke }
end

-- 2. Status & Activity Cards
section(PAGE_HOME, "Live Activity", 10)
local statusRow = new("Frame", {
    Size = UDim2.new(1, 0, 0, 52),
    BackgroundTransparency = 1,
    LayoutOrder = 11,
    Parent = PAGE_HOME,
})
new("UIListLayout", { FillDirection = Enum.FillDirection.Horizontal, Padding = UDim.new(0, 8), Parent = statusRow })

local statusCard = new("Frame", {
    Size = UDim2.new(0.55, -4, 1, 0),
    BackgroundColor3 = C.card,
    BorderSizePixel = 0,
    Parent = statusRow,
})
round(statusCard, 8)
stroke(statusCard, C.border, 1)
new("TextLabel", {
    Size = UDim2.new(1, -20, 0, 12),
    Position = UDim2.new(0, 10, 0, 6),
    BackgroundTransparency = 1,
    Text = "STATUS",
    TextColor3 = C.dim,
    Font = Enum.Font.GothamBold,
    TextSize = 8,
    TextXAlignment = Enum.TextXAlignment.Left,
    Parent = statusCard,
})
local statusVal = new("TextLabel", {
    Size = UDim2.new(1, -20, 0, 26),
    Position = UDim2.new(0, 10, 0, 20),
    BackgroundTransparency = 1,
    Text = "Ready to work",
    TextWrapped = true,
    TextColor3 = C.accent,
    Font = Enum.Font.GothamBold,
    TextSize = 11,
    TextXAlignment = Enum.TextXAlignment.Left,
    TextTruncate = Enum.TextTruncate.AtEnd,
    Parent = statusCard,
})

local lastCard = new("Frame", {
    Size = UDim2.new(0.45, -4, 1, 0),
    BackgroundColor3 = C.card,
    BorderSizePixel = 0,
    Parent = statusRow,
})
round(lastCard, 8)
stroke(lastCard, C.border, 1)
new("TextLabel", {
    Size = UDim2.new(1, -20, 0, 12),
    Position = UDim2.new(0, 10, 0, 6),
    BackgroundTransparency = 1,
    Text = "LAST TARGET",
    TextColor3 = C.dim,
    Font = Enum.Font.GothamBold,
    TextSize = 8,
    TextXAlignment = Enum.TextXAlignment.Left,
    Parent = lastCard,
})
local lastVal = new("TextLabel", {
    Size = UDim2.new(1, -20, 0, 26),
    Position = UDim2.new(0, 10, 0, 20),
    BackgroundTransparency = 1,
    Text = "None",
    TextWrapped = true,
    TextColor3 = C.text,
    Font = Enum.Font.GothamMedium,
    TextSize = 11,
    TextXAlignment = Enum.TextXAlignment.Left,
    TextTruncate = Enum.TextTruncate.AtEnd,
    Parent = lastCard,
})

-- 3. Looter Idle Farming Field Selector
section(PAGE_HOME, "Looter Idle Farming (When No Sprouts)", 20)
local farmBox = new("Frame", {
    Size = UDim2.new(1, 0, 0, 60),
    BackgroundColor3 = C.card,
    BorderSizePixel = 0,
    LayoutOrder = 21,
    Parent = PAGE_HOME,
})
round(farmBox, 10)
stroke(farmBox, C.border, 1)

new("TextLabel", {
    Size = UDim2.new(1, -24, 0, 14),
    Position = UDim2.new(0, 12, 0, 6),
    BackgroundTransparency = 1,
    Text = "FALLBACK FARM FIELD (LOOTER ONLY)",
    TextColor3 = C.dim,
    Font = Enum.Font.GothamBold,
    TextSize = 8,
    TextXAlignment = Enum.TextXAlignment.Left,
    Parent = farmBox,
})

local farmFieldBtn = new("TextButton", {
    Size = UDim2.new(1, -24, 0, 28),
    Position = UDim2.new(0, 12, 0, 24),
    BackgroundColor3 = C.field,
    Text = "",
    BorderSizePixel = 0,
    AutoButtonColor = false,
    Parent = farmBox,
})
round(farmFieldBtn, 6)
stroke(farmFieldBtn, C.border, 1)

new("TextLabel", {
    Size = UDim2.new(0, 22, 1, 0),
    Position = UDim2.new(0, 8, 0, 0),
    BackgroundTransparency = 1,
    Text = "📍",
    Font = Enum.Font.GothamBold,
    TextSize = 13,
    Parent = farmFieldBtn,
})

farmFieldText = new("TextLabel", {
    Size = UDim2.new(1, -130, 1, 0),
    Position = UDim2.new(0, 32, 0, 0),
    BackgroundTransparency = 1,
    Text = tostring(CONFIG.FALLBACK_FARM_FIELD or "None"),
    TextColor3 = C.text,
    Font = Enum.Font.GothamBold,
    TextSize = 11,
    TextXAlignment = Enum.TextXAlignment.Left,
    Parent = farmFieldBtn,
})

new("TextLabel", {
    Size = UDim2.new(0, 110, 1, 0),
    Position = UDim2.new(1, -118, 0, 0),
    BackgroundTransparency = 1,
    Text = "Change Field  ▼",
    TextColor3 = C.accent,
    Font = Enum.Font.GothamBold,
    TextSize = 10,
    TextXAlignment = Enum.TextXAlignment.Right,
    Parent = farmFieldBtn,
})

-- 4. Quick Targets
section(PAGE_HOME, "Quick Targets", 30)
makeToggle(PAGE_HOME, "Loot Sprouts", "Automatically locate and harvest sprouts", CONFIG.CHECK_SPROUTS, 31, function(v)
    CONFIG.CHECK_SPROUTS = v; saveNow()
end)
makeToggle(PAGE_HOME, "Hunt Vicious Bee", "Attack wild Vicious Bees on fields", CONFIG.CHECK_VICIOUS, 32, function(v)
    CONFIG.CHECK_VICIOUS = v; saveNow()
end)
makeToggle(PAGE_HOME, "Loot Meteor Shower", "Collect all falling mythic meteor tokens", CONFIG.CHECK_METEORS, 33, function(v)
    CONFIG.CHECK_METEORS = v; saveNow()
end)
makeToggle(PAGE_HOME, "Hunt Windy Bee", "Fight wild Windy Bee in cloud", CONFIG.CHECK_WINDY, 34, function(v)
    CONFIG.CHECK_WINDY = v; saveNow()
end)
makeToggle(PAGE_HOME, "Farm Puffshrooms", "Pop and collect puffshroom spores", CONFIG.CHECK_PUFFSHROOMS, 35, function(v)
    CONFIG.CHECK_PUFFSHROOMS = v; saveNow()
end)
makeToggle(PAGE_HOME, "Auto Harvest Planters", "Harvest full planters & auto replant", CONFIG.AUTO_HARVEST_PLANTERS, 36, function(v)
    CONFIG.AUTO_HARVEST_PLANTERS = v; saveNow()
end)

-- ══════════════════════════════════════════════════════════════════════
--  TAB 2: SPROUTS
-- ══════════════════════════════════════════════════════════════════════
local PAGE_SPROUTS = new("Frame", {
    Size = UDim2.new(1, 0, 0, 0),
    AutomaticSize = Enum.AutomaticSize.Y,
    BackgroundTransparency = 1,
    Visible = false,
    Parent = content,
})
new("UIListLayout", { SortOrder = Enum.SortOrder.LayoutOrder, Padding = UDim.new(0, 8), Parent = PAGE_SPROUTS })

section(PAGE_SPROUTS, "Sprout Harvesting", 1)
makeToggle(PAGE_SPROUTS, "Burst Loot Mode", "Prioritize rare tokens immediately when sprout pops", CONFIG.BURST_LOOT_ENABLED ~= false, 2, function(v)
    CONFIG.BURST_LOOT_ENABLED = v; saveNow()
end)
local fBurstTime = makeField(PAGE_SPROUTS, "Burst Loot Duration (seconds)", CONFIG.BURST_LOOT_TIME or 7, "7", 3, function(val)
    local n = tonumber(val)
    if n and n >= 2 and n <= 30 then CONFIG.BURST_LOOT_TIME = n; saveNow() end
end)
makeToggle(PAGE_SPROUTS, "Ignore Treat Tokens", "Skip normal treats to focus on high value sprout loot", CONFIG.IGNORE_TREAT_TOKENS, 4, function(v)
    CONFIG.IGNORE_TREAT_TOKENS = v; saveNow()
end)

section(PAGE_SPROUTS, "Allowed Sprout Rarities", 10)
local sproutRarities = {
    { key = "basic", label = "Basic Sprout" },
    { key = "moon", label = "Moon Sprout" },
    { key = "rare", label = "Rare Sprout" },
    { key = "gummy", label = "Gummy Sprout" },
    { key = "epic", label = "Epic Sprout" },
    { key = "legendary", label = "Legendary Sprout" },
    { key = "supreme", label = "Supreme Sprout" },
}
for rIdx, rInfo in ipairs(sproutRarities) do
    local isAllowed = not CONFIG.ALLOWED_SPROUT_RARITIES or (CONFIG.ALLOWED_SPROUT_RARITIES[rInfo.key] ~= false)
    makeToggle(PAGE_SPROUTS, rInfo.label, nil, isAllowed, 10 + rIdx, function(v)
        CONFIG.ALLOWED_SPROUT_RARITIES = CONFIG.ALLOWED_SPROUT_RARITIES or {}
        CONFIG.ALLOWED_SPROUT_RARITIES[rInfo.key] = v
        saveNow()
    end)
end

section(PAGE_SPROUTS, "Sprout Token Priorities", 20)
new("TextLabel", {
    Size = UDim2.new(1, 0, 0, 26),
    BackgroundTransparency = 1,
    Text = "Cycle priority: [ P1: Top ] -> [ P2: Mid ] -> [ P3: Low ] -> [ OFF ].\nP1 = Top loot (burst collected), P2 = Medium, P3 = Low, OFF = Ignored.",
    TextColor3 = C.dim,
    Font = Enum.Font.Gotham,
    TextSize = 9,
    TextWrapped = true,
    TextXAlignment = Enum.TextXAlignment.Left,
    LayoutOrder = 21,
    Parent = PAGE_SPROUTS,
})

local tokensContainer = new("Frame", {
    Size = UDim2.new(1, 0, 0, 0),
    AutomaticSize = Enum.AutomaticSize.Y,
    BackgroundTransparency = 1,
    LayoutOrder = 22,
    Parent = PAGE_SPROUTS,
})
new("UIListLayout", {
    SortOrder = Enum.SortOrder.LayoutOrder,
    Padding = UDim.new(0, 4),
    Parent = tokensContainer,
})

local prioLabels = {
    [1] = "[ P1: Top ]",
    [2] = "[ P2: Mid ]",
    [3] = "[ P3: Low ]",
    [0] = "[ OFF ]",
}
local prioColors = {
    [1] = Color3.fromRGB(255, 215, 0),
    [2] = Color3.fromRGB(105, 190, 255),
    [3] = Color3.fromRGB(175, 180, 195),
    [0] = Color3.fromRGB(255, 85, 85),
}
local prioBgColors = {
    [1] = Color3.fromRGB(48, 42, 24),
    [2] = Color3.fromRGB(24, 38, 52),
    [3] = Color3.fromRGB(28, 30, 40),
    [0] = Color3.fromRGB(45, 20, 25),
}

CONFIG.TOKEN_PRIORITIES = CONFIG.TOKEN_PRIORITIES or {}

for idx, item in ipairs(TOKEN_REGISTRY) do
    local curPrio = CONFIG.TOKEN_PRIORITIES[item.id]
    if curPrio == nil then curPrio = item.defaultPrio end

    local row = new("Frame", {
        Size = UDim2.new(1, 0, 0, 30),
        BackgroundColor3 = C.card,
        BorderSizePixel = 0,
        LayoutOrder = idx,
        Parent = tokensContainer,
    })
    round(row, 6)
    stroke(row, C.border, 1)

    new("TextLabel", {
        Size = UDim2.new(1, -95, 1, 0),
        Position = UDim2.new(0, 10, 0, 0),
        BackgroundTransparency = 1,
        Text = (item.icon or "✨") .. "  " .. item.name,
        TextColor3 = C.text,
        Font = Enum.Font.GothamMedium,
        TextSize = 10,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextYAlignment = Enum.TextYAlignment.Center,
        TextTruncate = Enum.TextTruncate.AtEnd,
        Parent = row,
    })

    local pBtn = new("TextButton", {
        Size = UDim2.new(0, 80, 0, 20),
        Position = UDim2.new(1, -88, 0.5, -10),
        BackgroundColor3 = prioBgColors[curPrio] or C.field,
        Text = prioLabels[curPrio] or ("[ P" .. tostring(curPrio) .. " ]"),
        TextColor3 = prioColors[curPrio] or C.text,
        Font = Enum.Font.GothamBold,
        TextSize = 9,
        BorderSizePixel = 0,
        AutoButtonColor = false,
        Parent = row,
    })
    round(pBtn, 4)
    local pBtnStroke = stroke(pBtn, prioColors[curPrio] or C.dim, 1)

    pBtn.MouseButton1Click:Connect(function()
        local nowP = CONFIG.TOKEN_PRIORITIES[item.id]
        if nowP == nil then nowP = item.defaultPrio end
        local nextP = (nowP == 1 and 2) or (nowP == 2 and 3) or (nowP == 3 and 0) or 1
        CONFIG.TOKEN_PRIORITIES[item.id] = nextP
        saveNow()
        pBtn.Text = prioLabels[nextP] or ("[ P" .. tostring(nextP) .. " ]")
        pBtn.TextColor3 = prioColors[nextP] or C.text
        pBtn.BackgroundColor3 = prioBgColors[nextP] or C.field
        pBtnStroke.Color = prioColors[nextP] or C.dim
    end)
end

section(PAGE_SPROUTS, "Excavation & Tool", 40)
makeToggle(PAGE_SPROUTS, "Auto Dig Tool", "Automatically swing collector tool on fields", CONFIG.ENABLE_AUTO_DIG ~= false, 41, function(v)
    CONFIG.ENABLE_AUTO_DIG = v; saveNow()
end)
local fDigTool = makeField(PAGE_SPROUTS, "Dig Tool Keyword", CONFIG.DIG_TOOL_KEYWORD or "scooper", "scooper", 42, function(val)
    if val and val ~= "" then CONFIG.DIG_TOOL_KEYWORD = val; saveNow() end
end)

-- ══════════════════════════════════════════════════════════════════════
--  TAB 3: PLANTERS & MOBS
-- ══════════════════════════════════════════════════════════════════════
local PAGE_PLANTERS_MOBS = new("Frame", {
    Size = UDim2.new(1, 0, 0, 0),
    AutomaticSize = Enum.AutomaticSize.Y,
    BackgroundTransparency = 1,
    Visible = false,
    Parent = content,
})
new("UIListLayout", { SortOrder = Enum.SortOrder.LayoutOrder, Padding = UDim.new(0, 8), Parent = PAGE_PLANTERS_MOBS })

section(PAGE_PLANTERS_MOBS, "Planters", 1)
makeToggle(PAGE_PLANTERS_MOBS, "Auto Harvest Planters", "Harvest ripe planters & auto replant seeds", CONFIG.AUTO_HARVEST_PLANTERS ~= false, 2, function(v)
    CONFIG.AUTO_HARVEST_PLANTERS = v; saveNow()
end)
makeToggle(PAGE_PLANTERS_MOBS, "Show Planter Timers HUD", "Display floating planter timers on screen", CONFIG.SHOW_PLANTER_HUD ~= false, 3, function(v)
    CONFIG.SHOW_PLANTER_HUD = v
    if planterHudFrame then planterHudFrame.Visible = v end
    saveNow()
end)

section(PAGE_PLANTERS_MOBS, "Bosses & Events", 10)
makeToggle(PAGE_PLANTERS_MOBS, "Hunt Vicious Bee", "Defeat Vicious Bee whenever spawned", CONFIG.CHECK_VICIOUS ~= false, 11, function(v)
    CONFIG.CHECK_VICIOUS = v; saveNow()
end)

local VICIOUS_FIELD_NAMES = { "Clover", "Spider", "Cactus", "Mountain Top", "Pepper Patch" }
local vicFrom = math.clamp(math.floor(tonumber(CONFIG.VICIOUS_FIELD_FROM) or 1), 1, 5)
local vicTo = math.clamp(math.floor(tonumber(CONFIG.VICIOUS_FIELD_TO) or 5), 1, 5)
if vicFrom > vicTo then vicFrom, vicTo = vicTo, vicFrom end
CONFIG.VICIOUS_FIELD_FROM, CONFIG.VICIOUS_FIELD_TO = vicFrom, vicTo

local vicCard = new("Frame", {
    Size = UDim2.new(1, 0, 0, 142),
    BackgroundColor3 = C.card,
    BorderSizePixel = 0,
    LayoutOrder = 12,
    Parent = PAGE_PLANTERS_MOBS,
})
round(vicCard, 8)
stroke(vicCard, C.border, 1)

new("TextLabel", {
    Size = UDim2.new(1, -20, 0, 16),
    Position = UDim2.new(0, 12, 0, 8),
    BackgroundTransparency = 1,
    Text = "VICIOUS BEE FIELD RANGE",
    TextColor3 = C.dim,
    Font = Enum.Font.GothamBold,
    TextSize = 9,
    TextXAlignment = Enum.TextXAlignment.Left,
    Parent = vicCard,
})

local vicSummary = new("TextLabel", {
    Size = UDim2.new(1, -20, 0, 16),
    Position = UDim2.new(0, 12, 0, 24),
    BackgroundTransparency = 1,
    Text = "Allowed: " .. vicFrom .. "★ - " .. vicTo .. "★ (" .. VICIOUS_FIELD_NAMES[vicFrom] .. " to " .. VICIOUS_FIELD_NAMES[vicTo] .. ")",
    TextColor3 = C.accent,
    Font = Enum.Font.GothamBold,
    TextSize = 10,
    TextXAlignment = Enum.TextXAlignment.Left,
    Parent = vicCard,
})

local function updateVicSummary()
    vicSummary.Text = "Allowed: " .. vicFrom .. "★ - " .. vicTo .. "★ (" .. VICIOUS_FIELD_NAMES[vicFrom] .. " to " .. VICIOUS_FIELD_NAMES[vicTo] .. ")"
end

local function makeVicStarSelector(parentLabel, yPos, curVal, onSelect)
    new("TextLabel", {
        Size = UDim2.new(0, 100, 0, 24),
        Position = UDim2.new(0, 12, 0, yPos),
        BackgroundTransparency = 1,
        Text = parentLabel,
        TextColor3 = C.text,
        Font = Enum.Font.GothamMedium,
        TextSize = 10,
        TextXAlignment = Enum.TextXAlignment.Left,
        Parent = vicCard,
    })
    local starBtns = {}
    for i = 1, 5 do
        local isSel = (i == curVal)
        local sb = new("TextButton", {
            Size = UDim2.new(0, 44, 0, 24),
            Position = UDim2.new(0, 115 + (i - 1) * 48, 0, yPos),
            BackgroundColor3 = isSel and C.accent or C.field,
            Text = string.rep("★", i),
            TextColor3 = isSel and Color3.fromRGB(20, 25, 35) or C.dim,
            Font = Enum.Font.GothamBold,
            TextSize = 9,
            BorderSizePixel = 0,
            AutoButtonColor = false,
            Parent = vicCard,
        })
        round(sb, 5)
        local sbStroke = stroke(sb, isSel and C.accent or C.border, 1)
        sb.MouseButton1Click:Connect(function()
            for sIdx, bData in ipairs(starBtns) do
                local active = (sIdx == i)
                bData.btn.BackgroundColor3 = active and C.accent or C.field
                bData.btn.TextColor3 = active and Color3.fromRGB(20, 25, 35) or C.dim
                bData.stroke.Color = active and C.accent or C.border
            end
            onSelect(i)
        end)
        starBtns[i] = { btn = sb, stroke = sbStroke }
    end
end

makeVicStarSelector("Min Field (From):", 46, vicFrom, function(val)
    vicFrom = val
    if vicFrom > vicTo then vicTo = vicFrom end
    CONFIG.VICIOUS_FIELD_FROM = vicFrom
    CONFIG.VICIOUS_FIELD_TO = vicTo
    saveNow()
    updateVicSummary()
end)

makeVicStarSelector("Max Field (To):", 76, vicTo, function(val)
    vicTo = val
    if vicTo < vicFrom then vicFrom = vicTo end
    CONFIG.VICIOUS_FIELD_FROM = vicFrom
    CONFIG.VICIOUS_FIELD_TO = vicTo
    saveNow()
    updateVicSummary()
end)

new("TextLabel", {
    Size = UDim2.new(1, -20, 0, 20),
    Position = UDim2.new(0, 12, 0, 110),
    BackgroundTransparency = 1,
    Text = "1★ Clover  |  2★ Spider  |  3★ Cactus  |  4★ Mountain Top  |  5★ Pepper",
    TextColor3 = C.dim,
    Font = Enum.Font.Gotham,
    TextSize = 9,
    TextXAlignment = Enum.TextXAlignment.Left,
    Parent = vicCard,
})

local fVicH = makeField(PAGE_PLANTERS_MOBS, "Vicious Bee Hover Height (studs)", CONFIG.VICIOUS_HOVER_HEIGHT or 6, "6", 13, function(val)
    local n = tonumber(val)
    if n and n >= 3 and n <= 15 then CONFIG.VICIOUS_HOVER_HEIGHT = n; saveNow() end
end)

local fVicChannel = makeField(PAGE_PLANTERS_MOBS, "Discord Channel ID (Vicious Alerts)", CONFIG.VICIOUS_CHANNEL_ID or "", "Channel ID", 14, function(val)
    CONFIG.VICIOUS_CHANNEL_ID = val
    saveNow()
end)

makeToggle(PAGE_PLANTERS_MOBS, "Loot Meteor Shower", "Collect falling meteor tokens on target fields", CONFIG.CHECK_METEORS ~= false, 15, function(v)
    CONFIG.CHECK_METEORS = v; saveNow()
end)
makeToggle(PAGE_PLANTERS_MOBS, "Hunt Windy Bee in Cloud", "Fly up and battle wild Windy Bee", CONFIG.CHECK_WINDY ~= false, 16, function(v)
    CONFIG.CHECK_WINDY = v; saveNow()
end)
local fWindyH = makeField(PAGE_PLANTERS_MOBS, "Windy Bee Hover Height (studs)", CONFIG.WINDY_HOVER_HEIGHT or 32, "32", 17, function(val)
    local n = tonumber(val)
    if n and n >= 15 and n <= 60 then CONFIG.WINDY_HOVER_HEIGHT = n; saveNow() end
end)
makeToggle(PAGE_PLANTERS_MOBS, "Farm Puffshrooms", "Pop puffshrooms and gather rare spores", CONFIG.CHECK_PUFFSHROOMS ~= false, 18, function(v)
    CONFIG.CHECK_PUFFSHROOMS = v; saveNow()
end)

-- ══════════════════════════════════════════════════════════════════════
--  TAB 4: SETTINGS & WEBHOOKS
-- ══════════════════════════════════════════════════════════════════════
local PAGE_SETTINGS = new("Frame", {
    Size = UDim2.new(1, 0, 0, 0),
    AutomaticSize = Enum.AutomaticSize.Y,
    BackgroundTransparency = 1,
    Visible = false,
    Parent = content,
})
new("UIListLayout", { SortOrder = Enum.SortOrder.LayoutOrder, Padding = UDim.new(0, 8), Parent = PAGE_SETTINGS })

section(PAGE_SETTINGS, "Webhooks & Notifications", 1)
local fDisc = makeField(PAGE_SETTINGS, "Discord Webhook URL", CONFIG.DISCORD_WEBHOOK_URL or "", "https://discord.com/api/webhooks/...", 2, function(v)
    CONFIG.DISCORD_WEBHOOK_URL = v; saveNow()
end)
local fTgToken = makeField(PAGE_SETTINGS, "Telegram Bot Token", CONFIG.TELEGRAM_BOT_TOKEN or "", "123456789:ABCdef...", 3, function(v)
    CONFIG.TELEGRAM_BOT_TOKEN = v; saveNow()
end)
local fTgChat = makeField(PAGE_SETTINGS, "Telegram Chat ID", CONFIG.TELEGRAM_CHAT_ID or "", "123456789", 4, function(v)
    CONFIG.TELEGRAM_CHAT_ID = v; saveNow()
end)

makeBtn(PAGE_SETTINGS, "Send Test Webhook Notification", "📡", C.card, 5, function()
    notifyAllWebhooks("Test Notification", "BSS Hopper Webhook is working correctly!", "00f5a0")
end)

makeToggle(PAGE_SETTINGS, "Periodic Loot Reports", "Send hourly resource summary reports", CONFIG.PERIODIC_REPORT_ENABLED ~= false, 6, function(v)
    CONFIG.PERIODIC_REPORT_ENABLED = v; saveNow()
end)
local fRepInterval = makeField(PAGE_SETTINGS, "Report Interval (minutes)", CONFIG.PERIODIC_REPORT_INTERVAL or 15, "15", 7, function(val)
    local n = tonumber(val)
    if n and n >= 1 and n <= 120 then CONFIG.PERIODIC_REPORT_INTERVAL = n; saveNow() end
end)

section(PAGE_SETTINGS, "Performance & Safety", 10)
makeToggle(PAGE_SETTINGS, "Anti-Lag (Reduce token visuals)", "Optimizes memory and reduces client lag", CONFIG.ANTI_LAG ~= false, 11, function(v)
    CONFIG.ANTI_LAG = v; saveNow()
end)
makeToggle(PAGE_SETTINGS, "Super Optimizer (Boost FPS)", "Drastically reduces CPU & GPU load", CONFIG.SUPER_OPTIMIZE == true, 12, function(v)
    CONFIG.SUPER_OPTIMIZE = v; saveNow()
end)
makeToggle(PAGE_SETTINGS, "Avoid Friends (Anti-Detection)", "Leaves server immediately if a friend is spotted", CONFIG.AVOID_FRIENDS ~= false, 13, function(v)
    CONFIG.AVOID_FRIENDS = v; saveNow()
end)
makeToggle(PAGE_SETTINGS, "Prefer Low Player Count Servers", "Targets emptier servers with fewer competitors", CONFIG.PREFER_LOW_PLAYERS ~= false, 14, function(v)
    CONFIG.PREFER_LOW_PLAYERS = v; saveNow()
end)
local fMaxP = makeField(PAGE_SETTINGS, "Max Server Players (1-6)", CONFIG.MAX_PLAYERS or 5, "5", 15, function(val)
    local n = tonumber(val)
    if n and n >= 1 and n <= 6 then CONFIG.MAX_PLAYERS = n; saveNow() end
end)

section(PAGE_SETTINGS, "Searcher & Server Connection", 20)
local fTag = makeField(PAGE_SETTINGS, "Account Tag (Searcher ID)", CONFIG.SELF_TAG or "searcher1", "searcher1", 21, function(v)
    CONFIG.SELF_TAG = v; saveNow()
end)
local fUrl = makeField(PAGE_SETTINGS, "Searcher Server API URL", CONFIG.API_URL or "", "http://...", 22, function(v)
    CONFIG.API_URL = v; saveNow()
end)
local fKey = makeField(PAGE_SETTINGS, "Searcher Server API Key", CONFIG.API_KEY or "", "api key", 23, function(v)
    CONFIG.API_KEY = v; saveNow()
end)
local fHop = makeField(PAGE_SETTINGS, "Server Hop Delay (seconds)", CONFIG.HOP_DELAY or 1.5, "1.5", 24, function(v)
    local n = tonumber(v)
    if n and n >= 0.5 and n <= 10 then CONFIG.HOP_DELAY = n; saveNow() end
end)
local fPoll = makeField(PAGE_SETTINGS, "Queue Poll Interval (seconds)", CONFIG.POLL_INTERVAL or 3, "3", 25, function(v)
    local n = tonumber(v)
    if n and n >= 1 and n <= 15 then CONFIG.POLL_INTERVAL = n; saveNow() end
end)
local fWait = makeField(PAGE_SETTINGS, "Broken Sprout Loot Wait (seconds)", CONFIG.BROKEN_WAIT or 20, "20", 26, function(v)
    local n = tonumber(v)
    if n and n >= 10 and n <= 60 then CONFIG.BROKEN_WAIT = n; saveNow() end
end)
local fConn = makeField(PAGE_SETTINGS, "Connection Timeout (seconds)", CONFIG.CONNECT_TIMEOUT or 20, "20", 27, function(v)
    local n = tonumber(v)
    if n and n >= 5 and n <= 60 then CONFIG.CONNECT_TIMEOUT = n; saveNow() end
end)

section(PAGE_SETTINGS, "Tools & Prompts", 30)
local fSprinkler = makeField(PAGE_SETTINGS, "Sprinkler Tool Keyword", CONFIG.SPRINKLER_KEYWORD or "sprinkler", "sprinkler", 31, function(v)
    if v and v ~= "" then CONFIG.SPRINKLER_KEYWORD = v; saveNow() end
end)
local fSprinklerCount = makeField(PAGE_SETTINGS, "Sprinklers to Place (1-4)", CONFIG.SPRINKLER_COUNT or 3, "3", 32, function(v)
    local n = tonumber(v)
    if n and n >= 1 and n <= 4 then CONFIG.SPRINKLER_COUNT = n; saveNow() end
end)
local fSlotKeyword = makeField(PAGE_SETTINGS, "Claim Hive Prompt Keyword", CONFIG.EMPTY_SLOT_KEYWORD or "claim hive", "claim hive", 33, function(v)
    if v and v ~= "" then CONFIG.EMPTY_SLOT_KEYWORD = v; saveNow() end
end)
local fHoneyKeyword = makeField(PAGE_SETTINGS, "Make Honey Prompt Keyword", CONFIG.MY_HIVE_KEYWORD or "make honey", "make honey", 34, function(v)
    if v and v ~= "" then CONFIG.MY_HIVE_KEYWORD = v; saveNow() end
end)

section(PAGE_SETTINGS, "Movement & Flight", 40)
local fWalk = makeField(PAGE_SETTINGS, "Walkspeed Multiplier", CONFIG.WALK_SPEED_MULT or 1, "1", 41, function(v)
    local n = tonumber(v)
    if n and n >= 0.5 and n <= 3 then CONFIG.WALK_SPEED_MULT = n; saveNow() end
end)
local fFly = makeField(PAGE_SETTINGS, "Flight / Tween Speed", CONFIG.FLY_SPEED or 55, "55", 42, function(v)
    local n = tonumber(v)
    if n and n >= 20 and n <= 120 then CONFIG.FLY_SPEED = n; saveNow() end
end)

-- ══════════════════════════════════════════════════════════════════════
--  TAB 5: CONFIGS & PROFILES
-- ══════════════════════════════════════════════════════════════════════
local PAGE_CONFIGS = new("Frame", {
    Size = UDim2.new(1, 0, 0, 0),
    AutomaticSize = Enum.AutomaticSize.Y,
    BackgroundTransparency = 1,
    Visible = false,
    Parent = content,
})
new("UIListLayout", { SortOrder = Enum.SortOrder.LayoutOrder, Padding = UDim.new(0, 8), Parent = PAGE_CONFIGS })

-- Header banner
local cfgHeaderBox = new("Frame", {
    Size = UDim2.new(1, 0, 0, 56),
    BackgroundColor3 = C.card,
    BorderSizePixel = 0,
    LayoutOrder = 1,
    Parent = PAGE_CONFIGS,
})
round(cfgHeaderBox, 10)
stroke(cfgHeaderBox, C.border, 1)

new("TextLabel", {
    Size = UDim2.new(0, 36, 1, 0),
    Position = UDim2.new(0, 12, 0, 0),
    BackgroundTransparency = 1,
    Text = "📁",
    Font = Enum.Font.GothamBold,
    TextSize = 22,
    TextColor3 = C.accent,
    Parent = cfgHeaderBox,
})
new("TextLabel", {
    Size = UDim2.new(1, -60, 0, 22),
    Position = UDim2.new(0, 52, 0, 8),
    BackgroundTransparency = 1,
    Text = "Profile Manager & Username Auto-Binds",
    TextColor3 = C.text,
    Font = Enum.Font.GothamBold,
    TextSize = 13,
    TextXAlignment = Enum.TextXAlignment.Left,
    Parent = cfgHeaderBox,
})
local cfgHeaderSub = new("TextLabel", {
    Size = UDim2.new(1, -60, 0, 18),
    Position = UDim2.new(0, 52, 0, 30),
    BackgroundTransparency = 1,
    Text = "Account: " .. tostring(player.Name) .. "  |  Active Profile: " .. tostring(currentActiveConfig or "default"),
    TextColor3 = C.dim,
    Font = Enum.Font.Gotham,
    TextSize = 10,
    TextXAlignment = Enum.TextXAlignment.Left,
    Parent = cfgHeaderBox,
})

-- Actions
section(PAGE_CONFIGS, "Profile Actions", 10)
local fCfgName = makeField(PAGE_CONFIGS, "Profile Name", currentActiveConfig or "default", "e.g. default or solo_macro", 11)

local cfgBtnRow = new("Frame", {
    Size = UDim2.new(1, 0, 0, 34),
    BackgroundTransparency = 1,
    LayoutOrder = 12,
    Parent = PAGE_CONFIGS,
})
new("UIListLayout", { FillDirection = Enum.FillDirection.Horizontal, Padding = UDim.new(0, 8), Parent = cfgBtnRow })

local cfgStatusLabel = new("TextLabel", {
    Size = UDim2.new(1, 0, 0, 22),
    BackgroundTransparency = 1,
    Text = "Ready to manage configurations",
    TextColor3 = C.dim,
    Font = Enum.Font.Gotham,
    TextSize = 10,
    TextXAlignment = Enum.TextXAlignment.Left,
    LayoutOrder = 13,
    Parent = PAGE_CONFIGS,
})

section(PAGE_CONFIGS, "Saved Profiles", 14)
local cfgListContainer = new("Frame", {
    Size = UDim2.new(1, 0, 0, 0),
    AutomaticSize = Enum.AutomaticSize.Y,
    BackgroundTransparency = 1,
    LayoutOrder = 15,
    Parent = PAGE_CONFIGS,
})
new("UIListLayout", {
    FillDirection = Enum.FillDirection.Horizontal,
    Padding = UDim.new(0, 6),
    SortOrder = Enum.SortOrder.LayoutOrder,
    Parent = cfgListContainer,
})

local refreshConfigButtons
refreshConfigButtons = function()
    for _, child in ipairs(cfgListContainer:GetChildren()) do
        if child:IsA("TextButton") then child:Destroy() end
    end
    local list = getSavedConfigList()
    for _, cfg in ipairs(list) do
        local isCur = (cfg == currentActiveConfig)
        local b = new("TextButton", {
            Size = UDim2.new(0, math.max(70, #cfg * 8 + 24), 0, 28),
            BackgroundColor3 = isCur and C.cardHi or C.field,
            Text = "📁 " .. cfg,
            TextColor3 = isCur and C.accent or C.text,
            Font = Enum.Font.GothamBold,
            TextSize = 10,
            BorderSizePixel = 0,
            Parent = cfgListContainer,
        })
        round(b, 6)
        stroke(b, isCur and C.accent or C.border, 1)
        b.MouseButton1Click:Connect(function()
            fCfgName.Text = cfg
            local ok, msg = loadNamedConfig(cfg)
            cfgStatusLabel.Text = msg or ("Loaded: " .. cfg)
            cfgStatusLabel.TextColor3 = ok and C.accent or C.danger
            refreshConfigButtons()
        end)
    end
    cfgHeaderSub.Text = "Account: " .. tostring(player.Name) .. "  |  Active Profile: " .. tostring(currentActiveConfig or "default")
end

local saveCfgBtn = new("TextButton", {
    Size = UDim2.new(0.33, -5, 1, 0),
    BackgroundColor3 = C.accent2,
    Text = "💾 Save Profile",
    TextColor3 = C.text,
    Font = Enum.Font.GothamBold,
    TextSize = 10,
    BorderSizePixel = 0,
    LayoutOrder = 1,
    Parent = cfgBtnRow,
})
round(saveCfgBtn, 6)
saveCfgBtn.MouseButton1Click:Connect(function()
    local name = (fCfgName.Text ~= "" and fCfgName.Text) or "default"
    local ok, msg = saveNamedConfig(name)
    cfgStatusLabel.Text = msg
    cfgStatusLabel.TextColor3 = ok and C.accent or C.danger
    refreshConfigButtons()
end)

local loadCfgBtn = new("TextButton", {
    Size = UDim2.new(0.33, -5, 1, 0),
    BackgroundColor3 = C.card,
    Text = "📂 Load Profile",
    TextColor3 = C.text,
    Font = Enum.Font.GothamBold,
    TextSize = 10,
    BorderSizePixel = 0,
    LayoutOrder = 2,
    Parent = cfgBtnRow,
})
round(loadCfgBtn, 6)
stroke(loadCfgBtn, C.border, 1)
loadCfgBtn.MouseButton1Click:Connect(function()
    local name = (fCfgName.Text ~= "" and fCfgName.Text) or "default"
    local ok, msg = loadNamedConfig(name)
    cfgStatusLabel.Text = msg
    cfgStatusLabel.TextColor3 = ok and C.accent or C.danger
    refreshConfigButtons()
end)

local delCfgBtn = new("TextButton", {
    Size = UDim2.new(0.33, -5, 1, 0),
    BackgroundColor3 = Color3.fromRGB(80, 25, 30),
    Text = "🗑️ Delete Profile",
    TextColor3 = Color3.fromRGB(255, 150, 150),
    Font = Enum.Font.GothamBold,
    TextSize = 10,
    BorderSizePixel = 0,
    LayoutOrder = 3,
    Parent = cfgBtnRow,
})
round(delCfgBtn, 6)
delCfgBtn.MouseButton1Click:Connect(function()
    local name = fCfgName.Text
    if name and name ~= "" and name ~= "default" then
        local ok, msg = deleteNamedConfig(name)
        cfgStatusLabel.Text = msg
        cfgStatusLabel.TextColor3 = ok and C.accent or C.danger
        refreshConfigButtons()
    else
        cfgStatusLabel.Text = "Cannot delete default profile!"
        cfgStatusLabel.TextColor3 = C.warn
    end
end)

-- Nickname Binds
section(PAGE_CONFIGS, "Auto-Load Profile by Username", 20)
new("TextLabel", {
    Size = UDim2.new(1, 0, 0, 24),
    BackgroundTransparency = 1,
    Text = "Automatically loads a profile whenever an account with this username runs BSS Hopper.",
    TextColor3 = C.dim,
    Font = Enum.Font.Gotham,
    TextSize = 9,
    TextWrapped = true,
    TextXAlignment = Enum.TextXAlignment.Left,
    LayoutOrder = 21,
    Parent = PAGE_CONFIGS,
})

local bindRow = new("Frame", {
    Size = UDim2.new(1, 0, 0, 48),
    BackgroundTransparency = 1,
    LayoutOrder = 22,
    Parent = PAGE_CONFIGS,
})
new("UIListLayout", { FillDirection = Enum.FillDirection.Horizontal, Padding = UDim.new(0, 8), Parent = bindRow })

local colNick = new("Frame", { Size = UDim2.new(0.5, -4, 1, 0), BackgroundTransparency = 1, Parent = bindRow })
local colCfg = new("Frame", { Size = UDim2.new(0.5, -4, 1, 0), BackgroundTransparency = 1, Parent = bindRow })
local fBindNick = makeField(colNick, "Roblox Username", player.Name, "Account Name", 1)
local fBindCfg = makeField(colCfg, "Profile Name", currentActiveConfig or "default", "e.g. default", 1)

makeBtn(PAGE_CONFIGS, "Bind Username to Profile", "🔗", C.accent2, 23, function()
    local n = fBindNick.Text
    local c = fBindCfg.Text
    local ok, msg = bindNickToConfig(n, c)
    cfgStatusLabel.Text = msg
    cfgStatusLabel.TextColor3 = ok and C.accent or C.danger
    if refreshBindsList then refreshBindsList() end
end)

section(PAGE_CONFIGS, "Active Username Binds", 24)
local bindsContainer = new("Frame", {
    Size = UDim2.new(1, 0, 0, 0),
    AutomaticSize = Enum.AutomaticSize.Y,
    BackgroundTransparency = 1,
    LayoutOrder = 25,
    Parent = PAGE_CONFIGS,
})
new("UIListLayout", {
    SortOrder = Enum.SortOrder.LayoutOrder,
    Padding = UDim.new(0, 4),
    Parent = bindsContainer,
})

local refreshBindsList
refreshBindsList = function()
    for _, child in ipairs(bindsContainer:GetChildren()) do
        if child:IsA("Frame") then child:Destroy() end
    end
    local binds = loadNickBinds()
    local count = 0
    for nick, cfg in pairs(binds) do
        count += 1
        local item = new("Frame", {
            Size = UDim2.new(1, 0, 0, 32),
            BackgroundColor3 = C.card,
            BorderSizePixel = 0,
            LayoutOrder = count,
            Parent = bindsContainer,
        })
        round(item, 6)
        stroke(item, C.border, 1)

        local isMyNick = (string.lower(nick) == string.lower(player.Name))
        new("TextLabel", {
            Size = UDim2.new(1, -75, 1, 0),
            Position = UDim2.new(0, 10, 0, 0),
            BackgroundTransparency = 1,
            Text = string.format("👤 %s  ➔  📁 %s", nick, cfg),
            TextColor3 = isMyNick and C.accent or C.text,
            Font = Enum.Font.GothamMedium,
            TextSize = 10,
            TextXAlignment = Enum.TextXAlignment.Left,
            Parent = item,
        })
        local unbindBtn = new("TextButton", {
            Size = UDim2.new(0, 60, 0, 20),
            Position = UDim2.new(1, -66, 0.5, -10),
            BackgroundColor3 = Color3.fromRGB(80, 25, 30),
            Text = "Unbind",
            TextColor3 = Color3.fromRGB(255, 160, 160),
            Font = Enum.Font.GothamBold,
            TextSize = 9,
            BorderSizePixel = 0,
            Parent = item,
        })
        round(unbindBtn, 4)
        unbindBtn.MouseButton1Click:Connect(function()
            unbindNick(nick)
            refreshBindsList()
        end)
    end
    if count == 0 then
        local empty = new("Frame", {
            Size = UDim2.new(1, 0, 0, 24),
            BackgroundTransparency = 1,
            LayoutOrder = 1,
            Parent = bindsContainer,
        })
        new("TextLabel", {
            Size = UDim2.new(1, 0, 1, 0),
            BackgroundTransparency = 1,
            Text = "No active username binds configured",
            TextColor3 = C.dim,
            Font = Enum.Font.Gotham,
            TextSize = 10,
            TextXAlignment = Enum.TextXAlignment.Left,
            Parent = empty,
        })
    end
end

refreshConfigButtons()
refreshBindsList()

-- ══════════════════════════════════════════════════════════════════════
--  FIELD PICKER MODAL OVERLAY (GUI OVER MAIN)
-- ══════════════════════════════════════════════════════════════════════
local pickerOverlay = new("TextButton", {
    Name = "FieldPickerOverlay",
    Size = UDim2.new(1, 0, 1, 0),
    Position = UDim2.new(0, 0, 0, 0),
    BackgroundColor3 = Color3.fromRGB(5, 7, 12),
    BackgroundTransparency = 0.45,
    BorderSizePixel = 0,
    AutoButtonColor = false,
    Text = "",
    Visible = false,
    ZIndex = 100,
    Parent = win,
})
round(pickerOverlay, 12)

local pickerCard = new("Frame", {
    Name = "PickerModal",
    Size = UDim2.new(0, 480, 0, 380),
    Position = UDim2.new(0.5, -240, 0.5, -190),
    BackgroundColor3 = C.panel,
    BorderSizePixel = 0,
    ZIndex = 101,
    Parent = pickerOverlay,
})
round(pickerCard, 12)
stroke(pickerCard, C.borderActive, 1.5)

local pickerHead = new("Frame", {
    Size = UDim2.new(1, 0, 0, 48),
    BackgroundTransparency = 1,
    ZIndex = 102,
    Parent = pickerCard,
})
new("TextLabel", {
    Size = UDim2.new(1, -50, 0, 20),
    Position = UDim2.new(0, 16, 0, 8),
    BackgroundTransparency = 1,
    Text = "SELECT IDLE FARM FIELD",
    TextColor3 = C.text,
    Font = Enum.Font.GothamBold,
    TextSize = 13,
    TextXAlignment = Enum.TextXAlignment.Left,
    ZIndex = 103,
    Parent = pickerHead,
})
new("TextLabel", {
    Size = UDim2.new(1, -50, 0, 14),
    Position = UDim2.new(0, 16, 0, 28),
    BackgroundTransparency = 1,
    Text = "Looter will farm here whenever searchers have no sprout tasks",
    TextColor3 = C.dim,
    Font = Enum.Font.Gotham,
    TextSize = 10,
    TextXAlignment = Enum.TextXAlignment.Left,
    ZIndex = 103,
    Parent = pickerHead,
})
local pickerCloseBtn = new("TextButton", {
    Size = UDim2.new(0, 26, 0, 26),
    Position = UDim2.new(1, -36, 0, 11),
    BackgroundColor3 = C.card,
    Text = "✕",
    TextColor3 = C.dim,
    Font = Enum.Font.GothamBold,
    TextSize = 11,
    BorderSizePixel = 0,
    ZIndex = 103,
    Parent = pickerHead,
})
round(pickerCloseBtn, 6)

local pickerList = new("ScrollingFrame", {
    Size = UDim2.new(1, -24, 1, -58),
    Position = UDim2.new(0, 12, 0, 50),
    BackgroundTransparency = 1,
    BorderSizePixel = 0,
    ScrollBarThickness = 4,
    ScrollBarImageColor3 = C.accent,
    CanvasSize = UDim2.new(0, 0, 0, 0),
    AutomaticCanvasSize = Enum.AutomaticSize.Y,
    ZIndex = 102,
    Parent = pickerCard,
})
new("UIGridLayout", {
    CellSize = UDim2.new(0.5, -6, 0, 36),
    CellPadding = UDim2.new(0, 8, 0, 8),
    SortOrder = Enum.SortOrder.LayoutOrder,
    Parent = pickerList,
})

local ALL_PICKER_FIELDS = {
    { name = "None", icon = "🚫", label = "None (Wait at spawn)" },
    { name = "Sunflower Field", icon = "🌻" },
    { name = "Dandelion Field", icon = "🌼" },
    { name = "Mushroom Field", icon = "🍄" },
    { name = "Blue Flower Field", icon = "🌸" },
    { name = "Clover Field", icon = "🍀" },
    { name = "Strawberry Field", icon = "🍓" },
    { name = "Spider Field", icon = "🕷️" },
    { name = "Bamboo Field", icon = "🎋" },
    { name = "Pineapple Patch", icon = "🍍" },
    { name = "Stump Field", icon = "🪵" },
    { name = "Cactus Field", icon = "🌵" },
    { name = "Pumpkin Patch", icon = "🎃" },
    { name = "Pine Tree Forest", icon = "🌲" },
    { name = "Rose Field", icon = "🌹" },
    { name = "Mountain Top Field", icon = "🏔️" },
    { name = "Coconut Field", icon = "🥥" },
    { name = "Pepper Patch", icon = "🌶️" },
}

local fieldCardButtons = {}
updateFieldPickerUI = function()
    local cur = CONFIG.FALLBACK_FARM_FIELD or "None"
    farmFieldText.Text = (cur == "None") and "None (Wait at spawn)" or cur
    for _, item in ipairs(ALL_PICKER_FIELDS) do
        local btnInfo = fieldCardButtons[item.name]
        if btnInfo then
            local isSel = (item.name == cur)
            btnInfo.btn.BackgroundColor3 = isSel and C.cardHi or C.card
            btnInfo.stroke.Color = isSel and C.accent or C.border
            btnInfo.check.Visible = isSel
            btnInfo.nameLabel.TextColor3 = isSel and C.accent or C.text
        end
    end
end

for idx, fData in ipairs(ALL_PICKER_FIELDS) do
    local fBtn = new("TextButton", {
        BackgroundColor3 = C.card,
        Text = "",
        BorderSizePixel = 0,
        AutoButtonColor = false,
        LayoutOrder = idx,
        ZIndex = 103,
        Parent = pickerList,
    })
    round(fBtn, 8)
    local fStroke = stroke(fBtn, C.border, 1)

    new("TextLabel", {
        Size = UDim2.new(0, 22, 1, 0),
        Position = UDim2.new(0, 8, 0, 0),
        BackgroundTransparency = 1,
        Text = fData.icon,
        Font = Enum.Font.GothamBold,
        TextSize = 13,
        ZIndex = 104,
        Parent = fBtn,
    })
    local fLbl = new("TextLabel", {
        Size = UDim2.new(1, -54, 1, 0),
        Position = UDim2.new(0, 32, 0, 0),
        BackgroundTransparency = 1,
        Text = fData.label or fData.name,
        TextColor3 = C.text,
        Font = Enum.Font.GothamBold,
        TextSize = 10,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextTruncate = Enum.TextTruncate.AtEnd,
        ZIndex = 104,
        Parent = fBtn,
    })
    local fChk = new("TextLabel", {
        Size = UDim2.new(0, 18, 1, 0),
        Position = UDim2.new(1, -22, 0, 0),
        BackgroundTransparency = 1,
        Text = "✓",
        TextColor3 = C.accent,
        Font = Enum.Font.GothamBold,
        TextSize = 12,
        Visible = false,
        ZIndex = 104,
        Parent = fBtn,
    })

    fBtn.MouseButton1Click:Connect(function()
        CONFIG.FALLBACK_FARM_FIELD = fData.name
        saveNow()
        updateFieldPickerUI()
        pickerOverlay.Visible = false
    end)

    fieldCardButtons[fData.name] = { btn = fBtn, stroke = fStroke, nameLabel = fLbl, check = fChk }
end

local function openFieldPicker()
    updateFieldPickerUI()
    pickerOverlay.Visible = true
end
farmFieldBtn.MouseButton1Click:Connect(openFieldPicker)
pickerCloseBtn.MouseButton1Click:Connect(function() pickerOverlay.Visible = false end)
pickerOverlay.MouseButton1Click:Connect(function() pickerOverlay.Visible = false end)

-- ══════════════════════════════════════════════════════════════════════
--  TAB NAVIGATION LOGIC
-- ══════════════════════════════════════════════════════════════════════
local pages = {
    main = PAGE_HOME,
    sprouts = PAGE_SPROUTS,
    planters_mobs = PAGE_PLANTERS_MOBS,
    configs = PAGE_CONFIGS,
    settings = PAGE_SETTINGS,
}

showPage = function(which)
    if not pages[which] then which = "main" end
    for key, pg in pairs(pages) do pg.Visible = (key == which) end
    for key, t in pairs(tabButtons) do
        local on = (key == which)
        t.bar.Visible = on
        t.btn.BackgroundColor3 = on and C.cardHover or C.sidebar
        t.icon.TextColor3 = on and C.accent or C.dim
        t.label.TextColor3 = on and C.text or C.dim
    end
    content.CanvasPosition = Vector2.new(0, 0)
    if refresh then pcall(refresh) end
end

for key, t in pairs(tabButtons) do
    t.btn.MouseButton1Click:Connect(function()
        if not isOpen then setWindow(true) end
        showPage(key)
    end)
end
showPage("main")

-- ══════════════════════════════════════════════════════════════════════
--  INPUTS & WINDOW CONTROLS
-- ══════════════════════════════════════════════════════════════════════
snake.MouseButton1Click:Connect(function() Hopper.Toggle() end)

local function openMenu()
    if not isOpen then setWindow(true) end
    showPage("main")
end
snake.MouseButton2Click:Connect(openMenu)

UserInputService.InputBegan:Connect(function(input, processed)
    if processed then return end
    if input.UserInputType == Enum.UserInputType.MouseButton2 then
        local ok, center = pcall(function() return snake.AbsolutePosition + snake.AbsoluteSize/2 end)
        if ok and center then
            local radius = math.max(snake.AbsoluteSize.X, snake.AbsoluteSize.Y)/2 + 8
            if (Vector2.new(input.Position.X, input.Position.Y) - center).Magnitude <= radius then openMenu() end
        end
    end
end)

UserInputService.InputBegan:Connect(function(inp, gpe)
    if gpe then return end
    if inp.KeyCode == Enum.KeyCode.Escape and isOpen then setWindow(false) end
    if inp.KeyCode == Enum.KeyCode.F then openMenu() end
    if inp.KeyCode == Enum.KeyCode.P then Hopper.Toggle() end
end)

setWindow = function(show)
    isOpen = show
    TweenService:Create(win,
        TweenInfo.new(0.25, Enum.EasingStyle.Quart,
            show and Enum.EasingDirection.Out or Enum.EasingDirection.In),
        { Size = UDim2.new(0, WIN_W, 0, show and WIN_H or HEADER_H) }):Play()
    sidebar.Visible = show
    content.Visible = show
    if closeBtn then
        closeBtn.Text = show and "✕" or "▼"
        closeBtn.TextColor3 = show and C.dim or C.accent
    end
    if menuToggleBtn then menuToggleBtn.Visible = not show end
    hint.Text = show and "LMB: Toggle Bot  •  RMB / F: Menu  •  P: Pause"
        or "Click header or floating icon to expand menu"
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

-- ══════════════════════════════════════════════════════════════════════
--  SYNC GUI WITH CONFIG & REFRESH
-- ══════════════════════════════════════════════════════════════════════
syncGuiWithConfig = function()
    pcall(function()
        if fDigTool and CONFIG.DIG_TOOL_KEYWORD ~= nil then fDigTool.Text = tostring(CONFIG.DIG_TOOL_KEYWORD) end
        if fBurstTime and CONFIG.BURST_LOOT_TIME ~= nil then fBurstTime.Text = tostring(CONFIG.BURST_LOOT_TIME) end
        if fWindyH and CONFIG.WINDY_HOVER_HEIGHT ~= nil then fWindyH.Text = tostring(CONFIG.WINDY_HOVER_HEIGHT) end
        if fVicH and CONFIG.VICIOUS_HOVER_HEIGHT ~= nil then fVicH.Text = tostring(CONFIG.VICIOUS_HOVER_HEIGHT) end
        if fVicChannel and CONFIG.VICIOUS_CHANNEL_ID ~= nil then fVicChannel.Text = tostring(CONFIG.VICIOUS_CHANNEL_ID) end
        if fDisc and CONFIG.DISCORD_WEBHOOK_URL ~= nil then fDisc.Text = tostring(CONFIG.DISCORD_WEBHOOK_URL) end
        if fTgToken and CONFIG.TELEGRAM_BOT_TOKEN ~= nil then fTgToken.Text = tostring(CONFIG.TELEGRAM_BOT_TOKEN) end
        if fTgChat and CONFIG.TELEGRAM_CHAT_ID ~= nil then fTgChat.Text = tostring(CONFIG.TELEGRAM_CHAT_ID) end
        if fRepInterval and CONFIG.PERIODIC_REPORT_INTERVAL ~= nil then fRepInterval.Text = tostring(CONFIG.PERIODIC_REPORT_INTERVAL) end
        if fMaxP and CONFIG.MAX_PLAYERS ~= nil then fMaxP.Text = tostring(CONFIG.MAX_PLAYERS) end
        if fTag and CONFIG.SELF_TAG ~= nil then fTag.Text = tostring(CONFIG.SELF_TAG) end
        if fUrl and CONFIG.API_URL ~= nil then fUrl.Text = tostring(CONFIG.API_URL) end
        if fKey and CONFIG.API_KEY ~= nil then fKey.Text = tostring(CONFIG.API_KEY) end
        if fHop and CONFIG.HOP_DELAY ~= nil then fHop.Text = tostring(CONFIG.HOP_DELAY) end
        if fPoll and CONFIG.POLL_INTERVAL ~= nil then fPoll.Text = tostring(CONFIG.POLL_INTERVAL) end
        if fWait and CONFIG.BROKEN_WAIT ~= nil then fWait.Text = tostring(CONFIG.BROKEN_WAIT) end
        if fConn and CONFIG.CONNECT_TIMEOUT ~= nil then fConn.Text = tostring(CONFIG.CONNECT_TIMEOUT) end
        if fSprinkler and CONFIG.SPRINKLER_KEYWORD ~= nil then fSprinkler.Text = tostring(CONFIG.SPRINKLER_KEYWORD) end
        if fSprinklerCount and CONFIG.SPRINKLER_COUNT ~= nil then fSprinklerCount.Text = tostring(CONFIG.SPRINKLER_COUNT) end
        if fSlotKeyword and CONFIG.EMPTY_SLOT_KEYWORD ~= nil then fSlotKeyword.Text = tostring(CONFIG.EMPTY_SLOT_KEYWORD) end
        if fHoneyKeyword and CONFIG.MY_HIVE_KEYWORD ~= nil then fHoneyKeyword.Text = tostring(CONFIG.MY_HIVE_KEYWORD) end
        if fWalk and CONFIG.WALK_SPEED_MULT ~= nil then fWalk.Text = tostring(CONFIG.WALK_SPEED_MULT) end
        if fFly and CONFIG.FLY_SPEED ~= nil then fFly.Text = tostring(CONFIG.FLY_SPEED) end
        if fCfgName then fCfgName.Text = tostring(currentActiveConfig or "default") end
        if updateFieldPickerUI then updateFieldPickerUI() end
        if refreshConfigButtons then refreshConfigButtons() end
        if refreshBindsList then refreshBindsList() end
    end)
end

refresh = function()
    for k, v in pairs(modeButtons) do
        local on = (k == lastMode and Hopper.Mode ~= nil)
        v.bar.Visible = on
        v.btn.BackgroundColor3 = on and C.cardHi or C.card
        v.title.TextColor3 = on and C.accent or C.text
        if v.outline then
            v.outline.Color = on and C.accent or C.border
            v.outline.Thickness = on and 1.5 or 1
            v.outline.Transparency = on and 0.05 or 0.2
        end
    end

    dot.BackgroundColor3 = Hopper.Mode and C.accent or C.danger
    if readyPill then
        local isActive = (Hopper.Mode ~= nil)
        pillLabel.Text = isActive and "ACTIVE" or "IDLE"
        pillLabel.TextColor3 = isActive and C.accent or C.dim
        pillDot.BackgroundColor3 = isActive and C.accent or C.danger
    end

    if not Hopper.Mode then
        statusVal.Text = "Stopped"
        statusVal.TextColor3 = C.dim
        lastVal.Text = "None"
        lastVal.TextColor3 = C.dim
        return
    end

    local s = Hopper.Mode:GetStats()
    local st = s.currentStatus or ""

    statusVal.Text = st
    statusVal.TextColor3 = (string.find(st,"Error",1,true) or string.find(st,"failed",1,true)) and C.danger or C.accent

    if s.lastTask then
        lastVal.Text = string.format("%s • %ds ago", tostring(s.lastTask.fieldName or "?"), s.lastTask.age or 0)
        lastVal.TextColor3 = C.warn
    elseif s.lastSprout then
        lastVal.Text = tostring(s.lastSprout.fieldName or "Sprout")
        lastVal.TextColor3 = C.accent
    else
        lastVal.Text = "Searching..."
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

do
    local okBoot, errBoot = pcall(boot)
    if not okBoot then
        log("ERR", "Ошибка запуска: " .. tostring(errBoot))
        if Hopper.OnModeChanged then pcall(function() Hopper.OnModeChanged("off") end) end
    end
end

trace("Запуск завершён")

print("=====================================================")
print("  BSS HOPPER v1.1 ЗАГРУЖЕН")
print("  Bypass  : " .. (_G.BSS_BYPASS_ACTIVE and "session_bypass.lua" or "встроенный"))
print("  Тег     : " .. tostring(CONFIG.SELF_TAG))
print("  Бот     : " .. tostring(CONFIG.API_URL))
print("  ЛКМ змейка — вкл/выкл | ПКМ/F — меню | P — вкл/выкл")
print("=====================================================")

_G.BSS_Hopper = {
    Switch = Hopper.SwitchMode,
    Toggle = Hopper.Toggle,
    Open = function() setWindow(true); showPage("main") end,
    Close = function() setWindow(false) end,
    Save = saveNow,
    Mode = function() return lastMode end,
    Destroy = stopEverything,
    Config = CONFIG,
    Bypass = _G.ExtraHopBypass,
}