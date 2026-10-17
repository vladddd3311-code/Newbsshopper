--[[
═══════════════════════════════════════════════════════════════════════
  🐍 BSS HOPPER v1.1 Standby Solo Farm for Looter
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
    PLACE_ID = 1537690962,

    HOP_DELAY = 0.8, POLL_INTERVAL = 3, BROKEN_WAIT = 20,
    INITIAL_CHECK = 1, REPORT_DELAY = 2.5,
    CONNECT_TIMEOUT = 12, MAX_ATTEMPTS = 3, FAILED_TTL = 600,

    DEBUG_SPROUT = true, CHECK_VICIOUS = true, CHECK_SPROUTS = true,
    AUTO_START = true,

    WALK_SPEED_MULT = 5.625, FLY_SPEED = 100, JUMP_POWER = 60,

    BACKPACK_FILL_THRESHOLD = 0.95, HONEY_MAX_WAIT = 45,

    TOKEN_SCAN_INTERVAL = 0.14, TOKEN_PATROL_TIME = 20,
    FARM_REGION = "center", -- center / left / right
    ANTI_LAG = true,
    SUPER_OPTIMIZE = false,
    AVOID_FRIENDS = true,
    ENABLE_AUTO_SPRINKLER = true, SPRINKLER_COUNT = 3,

    SPRINKLER_KEYWORD = "sprinkler", DIG_TOOL_KEYWORD = "scooper",
    ENABLE_AUTO_DIG = true,

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
    "MODE","API_URL","API_KEY","SELF_TAG","VICIOUS_CHANNEL_ID","VICIOUS_FIELD_FROM","VICIOUS_FIELD_TO","FIXED_LEVEL","MIN_RARITY",
    "PLACE_ID","HOP_DELAY","POLL_INTERVAL","BROKEN_WAIT","INITIAL_CHECK",
    "REPORT_DELAY","CONNECT_TIMEOUT","MAX_ATTEMPTS","FAILED_TTL",
    "DEBUG_SPROUT","AUTO_START","CHECK_VICIOUS","CHECK_SPROUTS","CHECK_PUFFSHROOMS",
    "PUFFSHROOM_CHANNEL_ID","PUFF_MIN_RARITY","PUFF_MIN_LEVEL_COMMON","PUFF_MIN_LEVEL_RARE",
    "PUFF_MIN_LEVEL_EPIC","PUFF_MIN_LEVEL_LEGENDARY","PUFF_MIN_LEVEL_MYTHIC",
    "WALK_SPEED_MULT","FLY_SPEED","JUMP_POWER","BACKPACK_FILL_THRESHOLD","HONEY_MAX_WAIT",
    "TOKEN_SCAN_INTERVAL","TOKEN_PATROL_TIME","FARM_REGION","ANTI_LAG","SUPER_OPTIMIZE","AVOID_FRIENDS","SPRINKLER_KEYWORD","DIG_TOOL_KEYWORD",
    "ENABLE_AUTO_SPRINKLER","SPRINKLER_COUNT",
    "ENABLE_AUTO_DIG","EMPTY_SLOT_KEYWORD","MY_HIVE_KEYWORD","CLAIM_TIMEOUT",
    "BURST_LOOT_ENABLED","BURST_LOOT_TIME","PREFER_LOW_PLAYERS","MAX_PLAYERS","MIN_PLAYERS","TOKEN_PRIORITIES",
    "CHECK_METEORS","CHECK_WINDY","AUTO_HARVEST_PLANTERS","SHOW_PLANTER_HUD","PLANTER_HUD_COLLAPSED",
    "PLANTERS_CONFIG","PUFF_AUTO_BOOST_EPIC","PUFF_SELECTED_BOOSTS","PUFF_MIN_LEVEL","PUFF_MAX_LEVEL",
    "DISCORD_WEBHOOK_URL","TELEGRAM_BOT_TOKEN","TELEGRAM_CHAT_ID",
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
            pcall(function() settings().Rendering.QualityLevel = Enum.QualityLevel.Level01 end)
            pcall(function() settings().Network.IncomingReplicationLag = 0 end)
            if type(setfpscap) == "function" then
                pcall(setfpscap, 999)
            end
            pcall(function() collectgarbage("collect") end)
            log("Оптимизация", "⚡ Ультра-оптимизация включена: тени, частицы и тяжелые эффекты отключены, FPS разблокирован!")
        else
            Lighting.GlobalShadows = true
            pcall(function() settings().Rendering.QualityLevel = Enum.QualityLevel.Automatic end)
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
            pcall(function() settings().Rendering.QualityLevel = Enum.QualityLevel.Level01 end)
        else
            -- При выключении возвращаем базовую графику; Roblox может управлять качеством автоматически.
            Lighting.GlobalShadows = true
            pcall(function() settings().Rendering.QualityLevel = Enum.QualityLevel.Automatic end)
        end
    end)
end
if CONFIG.ANTI_LAG then applyAntiLag(true) end
if CONFIG.SUPER_OPTIMIZE then applySuperOptimization(true) end

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
    if obj:IsA("BasePart") then return obj.Position end
    if obj:IsA("Model") then return obj:GetPivot().Position end
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

function waitForGameReady(timeout)
    local t0 = os.clock()
    timeout = timeout or 25
    while not game:IsLoaded() and os.clock() - t0 < timeout do
        if not alive() then return end
        task.wait(0.3)
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
        task.wait(0.5)
    end
    if alive() then task.wait(2.0) end
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
--  WINDY BEE (БОЙ В ОБЛАКЕ С УВОРОТОМ ОТ ТОРНАДО)
-- ══════════════════════════════════════════════════════════════════════
function findWindyBee()
    local npcFolder = Workspace:FindFirstChild("NPCBees")
    if not npcFolder then return nil end
    for _, bee in ipairs(npcFolder:GetChildren()) do
        local n = string.lower(bee.Name)
        if string.find(n, "windy", 1, true) then
            return bee
        end
    end
    return nil
end

function fightWindyBee(windy)
    if not windy or not windy.Parent then return false end
    log("Windy", "🌪️ Найдена дикая Windy Bee! Начинаю бой...")
    notifyAllWebhooks("Windy Bee!", "Обнаружена дикая Windy Bee! Лечу на поле для боя...", "00e5ff")
    local started = os.clock()

    local initialPos = worldPos(windy)
    if not initialPos then return false end
    local fieldName, fieldZone = getFieldForPos(initialPos, 50)
    local groundTarget = getGroundPos(initialPos)

    -- ПОДЛЕТАЕМ ТОЛЬКО 1 РАЗ к полю / к земле под Windy Bee!
    local root = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
    if root then
        log("Windy", string.format("Подлетаю 1 раз на поле к Windy Bee (%s)...", tostring(fieldName or "Поле")))
        moveRootToPosition(root, groundTarget, 6)
        setFlightNoclip(false)
    end

    local lastBeePos = initialPos
    local lastWindyJump = 0

    -- 1 раз подбегаем под облако Windy Bee и делаем 1 прыжок
    local char = player.Character
    local curRoot = char and char:FindFirstChild("HumanoidRootPart")
    local hum = char and char:FindFirstChildOfClass("Humanoid")
    if curRoot and hum and alive() then
        local underBee = Vector3.new(initialPos.X, curRoot.Position.Y, initialPos.Z)
        hum:MoveTo(underBee)
        local t0 = os.clock()
        while alive() and (os.clock() - t0 < 3.0) and (curRoot.Position - underBee).Magnitude > 8 do
            task.wait(0.08)
        end
        if hum.FloorMaterial ~= Enum.Material.Air then
            hum.Jump = true
            log("Windy", "☁️ Подбежал под облако Windy Bee и прыгнул 1 раз!")
            task.wait(0.4)
        end
    end

    -- ДАЛЬШЕ БЕГАЕМ ПО ПОЛЮ КАК НА РОСТКАХ, УВОРАЧИВАЯСЬ ОТ ТОРНАДО!
    while alive() and windy.Parent and (os.clock() - started < 360) do
        local curChar = player.Character
        local rootPart = curChar and curChar:FindFirstChild("HumanoidRootPart")
        local humanoid = curChar and curChar:FindFirstChildOfClass("Humanoid")
        if not rootPart or not humanoid or humanoid.Health <= 0 then
            curChar, rootPart, humanoid = waitForRespawn(6)
            if not rootPart then break end
        end

        local beePos = worldPos(windy)
        if not beePos then break end

        -- Если Windy Bee перелетела на ДРУГОЕ поле (дистанция > 90 studs) - только тогда перелетаем 1 раз!
        if (beePos - lastBeePos).Magnitude > 90 then
            log("Windy", "Windy Bee сменила поле! Перелетаю 1 раз на новое поле...")
            lastBeePos = beePos
            local newGround = getGroundPos(beePos)
            moveRootToPosition(rootPart, newGround, 6)
            setFlightNoclip(false)
            task.wait(0.3)

            -- На новом поле снова подбегаем 1 раз под облако и прыгаем
            local underBee = Vector3.new(beePos.X, rootPart.Position.Y, beePos.Z)
            humanoid:MoveTo(underBee)
            local t0 = os.clock()
            while alive() and (os.clock() - t0 < 3.0) and (rootPart.Position - underBee).Magnitude > 8 do
                task.wait(0.08)
            end
            if humanoid.FloorMaterial ~= Enum.Material.Air then
                humanoid.Jump = true
                task.wait(0.4)
            end
        end

        applyWalkSpeed()
        pcall(swingDigTool)

        -- Сканируем торнадо для уворота на земле
        local tornadoDodgeDir = nil
        local tornadoes = Workspace:FindFirstChild("Tornadoes") or (Workspace:FindFirstChild("Happenings") and Workspace.Happenings:FindFirstChild("Tornadoes"))
        if tornadoes then
            for _, torn in ipairs(tornadoes:GetChildren()) do
                if string.find(string.lower(torn.Name), "tornado", 1, true) then
                    local tpos = worldPos(torn)
                    if tpos and (rootPart.Position - tpos).Magnitude < 25 then
                        local away = (rootPart.Position - tpos)
                        tornadoDodgeDir = Vector3.new(away.X, 0, away.Z).Unit
                        break
                    end
                end
            end
        end

        if tornadoDodgeDir then
            local runTarget = rootPart.Position + tornadoDodgeDir * 28
            log("Windy", "Уворот по земле от торнадо Windy Bee!")
            if humanoid.FloorMaterial ~= Enum.Material.Air and (os.clock() - lastWindyJump > 1.8) then
                humanoid.Jump = true
                lastWindyJump = os.clock()
            end
            humanoid:MoveTo(runTarget)
            task.wait(0.4)
        else
            -- Бегаем по полю точно так же, как будто лутаем ростки!
            collectTokensFor(3.0, function()
                if not alive() or not windy.Parent then return true end
                local curBee = worldPos(windy)
                if curBee and (curBee - lastBeePos).Magnitude > 90 then return true end
                if tornadoes then
                    for _, torn in ipairs(tornadoes:GetChildren()) do
                        if string.find(string.lower(torn.Name), "tornado", 1, true) then
                            local tpos = worldPos(torn)
                            if tpos and (rootPart.Position - tpos).Magnitude < 25 then
                                return true
                            end
                        end
                    end
                end
                return false
            end, beePos)
        end

        task.wait(0.05)
    end

    setFlightNoclip(false)
    log("Windy", "Windy Bee повержена или исчезла! Сбор оставшихся Cloud Vials 8 секунд...")
    collectTokensFor(8, function() return not alive() end, lastBeePos)
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
    for _, child in ipairs(Workspace:GetChildren()) do
        local cn = string.lower(child.Name)
        if string.find(cn, "meteor", 1, true) or string.find(cn, "impact", 1, true) then
            return child
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
        local fName = getFieldForPos(pos, 40)
        if fName and not seen[fName] then
            seen[fName] = true
            table.insert(fieldsFound, fName)
        end
    end

    local mFolder = Workspace:FindFirstChild("Meteors") or (Workspace:FindFirstChild("Happenings") and Workspace.Happenings:FindFirstChild("Meteors"))
    if mFolder then
        for _, m in ipairs(mFolder:GetChildren()) do
            checkPos(worldPos(m))
        end
    end
    for _, child in ipairs(Workspace:GetChildren()) do
        local cn = string.lower(child.Name)
        if string.find(cn, "meteor", 1, true) or string.find(cn, "impact", 1, true) then
            checkPos(worldPos(child))
        end
    end
    return fieldsFound
end

function lootMeteorShower(meteors)
    log("Meteor", "☄️ Обнаружен Meteor Shower (3 раунда на 3 полях)! Начинаю целевой сбор...")
    notifyAllWebhooks("Метеоритный дождь!", "На сервере идет Meteor Shower (3 раунда на 3 полях)! Бот облетает поля и собирает все награды.", "ffaa00")
    local showerStart = os.clock()
    local roundsDone = 0

    while alive() and (os.clock() - showerStart < 140) and (roundsDone < 3) do
        local activeFields = findMeteorFields()
        if #activeFields == 0 then
            task.wait(2.5)
            activeFields = findMeteorFields()
            if #activeFields == 0 then
                break
            end
        end

        roundsDone = roundsDone + 1
        log("Meteor", string.format("☄️ Раунд %d/3! Метеоры падают на полях: %s", roundsDone, table.concat(activeFields, ", ")))

        for idx, fName in ipairs(activeFields) do
            if idx > 3 then break end
            local zPart = getFieldPart(fName)
            local root = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
            if zPart and root and alive() then
                local safeGround = getGroundPos(zPart.Position)
                log("Meteor", string.format("Перелет на метеоритное поле [%d/3]: %s...", idx, fName))
                moveRootToPosition(root, safeGround, 3.5)
                collectTokensFor(7, function() return not alive() end, safeGround)
            end
        end

        task.wait(1.5)
    end

    log("Meteor", "Все 3 раунда метеоритного дождя завершены! Финальный сбор токенов 10 секунд...")
    collectTokensFor(10, function() return not alive() end)
    notifyAllWebhooks("Метеориты собраны!", "Все 3 раунда метеоритного дождя успешно залутаны!", "00f5a0")
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

function getPlanterType(model)
    if not model then return "Unknown Planter" end
    local raw = model:GetAttribute("Type") or model:GetAttribute("PlanterType") or model.Name
    local low = string.lower(tostring(raw))
    for _, pType in ipairs(ALL_PLANTER_TYPES) do
        local pLow = string.lower(pType)
        local short = pLow:gsub("%s*planter%s*", ""):gsub("the%s*", ""):gsub("%s*of%s*", "")
        if string.find(low, short, 1, true) then
            return pType
        end
    end
    for _, desc in ipairs(model:GetDescendants()) do
        if desc:IsA("TextLabel") then
            local tLow = string.lower(desc.Text or "")
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

    local attrPct = model:GetAttribute("Progress") or model:GetAttribute("Growth") or model:GetAttribute("Percent")
    if type(attrPct) == "number" then
        percent = (attrPct <= 1.05 and attrPct > 0) and (attrPct * 100) or attrPct
    end
    local attrTime = model:GetAttribute("TimeLeft") or model:GetAttribute("Remaining") or model:GetAttribute("Duration")
    if attrTime then timeLeftStr = tostring(attrTime) end

    for _, desc in ipairs(model:GetDescendants()) do
        if desc:IsA("TextLabel") then
            local txt = desc.Text or ""
            local low = string.lower(txt)

            -- Парсинг процентов "XX.X%"
            local pMatch = string.match(txt, "(%d+%.?%d*)%%")
            if pMatch then
                local num = tonumber(pMatch)
                if num then
                    percent = num
                    if num >= 100 then
                        isFullyReady = true
                    end
                end
            end

            -- Оставшееся время (например: "Ready in: 25:10", "15m left")
            if string.find(low, "left", 1, true) or string.find(txt, ":", 1, true) or string.find(low, "ready in", 1, true) then
                timeLeftStr = txt
            end

            -- Явная готовность к сбору (НЕ должна срабатывать на "ready in" или "not ready"!)
            if string.find(low, "ready to harvest", 1, true)
               or string.find(low, "harvest!", 1, true)
               or low == "harvest"
               or (string.find(low, "ready", 1, true) and not string.find(low, "ready in", 1, true) and not string.find(low, "not ready", 1, true))
               or string.find(low, "claim", 1, true)
               or string.find(low, "0s left", 1, true) then
                isFullyReady = true
            end
        elseif desc:IsA("Frame") and (desc.Name == "Bar" or desc.Name == "Progress" or desc.Name == "Fill") then
            if desc.Size.X.Scale > 0 and desc.Size.X.Scale <= 1 then
                if not percent then percent = desc.Size.X.Scale * 100 end
                if desc.Size.X.Scale >= 1 then isFullyReady = true end
            end
        end
    end

    if isFullyReady then
        percent = math.max(percent or 100, 100)
        timeLeftStr = "Ready!"
    end

    percent = percent or 0
    local statusStr
    if timeLeftStr and timeLeftStr ~= "" then
        statusStr = timeLeftStr
    else
        statusStr = string.format("%.1f%%", percent)
    end
    return percent, statusStr
end

function findMyActivePlanters()
    local myPlanters = {}
    local plantersFolder = Workspace:FindFirstChild("Planters") 
        or (Workspace:FindFirstChild("Core") and Workspace.Core:FindFirstChild("Planters"))
        or (Workspace:FindFirstChild("Happenings") and Workspace.Happenings:FindFirstChild("Planters"))
    if not plantersFolder then return myPlanters end

    local myName = string.lower(player.Name)
    local myId = tostring(player.UserId)

    for _, pModel in ipairs(plantersFolder:GetChildren()) do
        if pModel:IsA("Model") or pModel:IsA("Folder") or pModel:IsA("BasePart") then
            local isMine = false
            local ownerAttr = pModel:GetAttribute("Owner") or pModel:GetAttribute("UserId") or pModel:GetAttribute("Player")
            if ownerAttr and (string.lower(tostring(ownerAttr)) == myName or tostring(ownerAttr) == myId) then
                isMine = true
            end
            if not isMine then
                local oVal = pModel:FindFirstChild("Owner") or pModel:FindFirstChild("Player") or pModel:FindFirstChild("PlayerRef")
                if oVal and (oVal.Value == player or string.lower(tostring(oVal.Value)) == myName or tostring(oVal.Value) == myId) then
                    isMine = true
                end
            end
            if not isMine then
                for _, desc in ipairs(pModel:GetDescendants()) do
                    if desc:IsA("TextLabel") and string.find(string.lower(desc.Text or ""), myName, 1, true) then
                        isMine = true
                        break
                    end
                end
            end
            if not isMine and #Players:GetPlayers() <= 1 then
                isMine = true
            end

            if isMine then
                local pType = getPlanterType(pModel)
                local percent, statusStr = getPlanterProgress(pModel)
                local fieldName = detectField(pModel) or "Unknown Field"
                local ready = (percent >= 100) or (statusStr == "Ready!")
                table.insert(myPlanters, {
                    type = pType,
                    model = pModel,
                    field = fieldName,
                    percent = percent,
                    statusStr = statusStr,
                    ready = ready,
                })
            end
        end
    end
    return myPlanters
end

function confirmPlanterHarvestModal()
    local pg = player:FindFirstChild("PlayerGui")
    if not pg then return false end
    for _, desc in ipairs(pg:GetDescendants()) do
        if desc:IsA("TextLabel") then
            local t = string.lower(desc.Text or "")
            if string.find(t, "harvest the planter", 1, true)
               or string.find(t, "done growing", 1, true) then
                local dialog = desc.Parent
                for _ = 1, 4 do
                    if dialog and dialog:IsA("GuiObject") then
                        for _, btn in ipairs(dialog:GetDescendants()) do
                            if btn:IsA("TextButton") or btn:IsA("ImageButton") then
                                local bText = string.lower(btn.Text or "")
                                local bName = string.lower(btn.Name)
                                local innerTxt = ""
                                local innerLabel = btn:FindFirstChildWhichIsA("TextLabel")
                                if innerLabel then innerTxt = string.lower(innerLabel.Text or "") end

                                if bText == "yes" or innerTxt == "yes" or bName == "yes" or string.find(bName, "yes", 1, true) then
                                    pcall(function()
                                        if type(firesignal) == "function" then
                                            firesignal(btn.MouseButton1Click)
                                            firesignal(btn.Activated)
                                        end
                                    end)
                                    pcall(function()
                                        local vim = game:GetService("VirtualInputManager")
                                        if vim then
                                            local pos = btn.AbsolutePosition + (btn.AbsoluteSize * 0.5)
                                            vim:SendMouseButtonEvent(pos.X, pos.Y, 0, true, game, 1)
                                            task.wait(0.04)
                                            vim:SendMouseButtonEvent(pos.X, pos.Y, 0, false, game, 1)
                                        end
                                    end)
                                    log("Плантатор", "✅ Нажата кнопка [ Yes ] в диалоге сбора плантатора!")
                                    return true
                                end
                            end
                        end
                        dialog = dialog.Parent
                    end
                end
            end
        end
    end
    return false
end

function managePlanters()
    if CONFIG.AUTO_HARVEST_PLANTERS == false then return end
    local rep = game:GetService("ReplicatedStorage")
    local pCmd = rep:FindFirstChild("Events") and rep.Events:FindFirstChild("PlanterCommand")
    local repPkg = rep:FindFirstChild("Events") and rep.Events:FindFirstChild("PlanterPackage")
    local activePlanters = findMyActivePlanters()
    local activeTypes = {}

    -- 1. Сбор созревших плантаторов (ТОЛЬКО если достигли порога % или готовы)
    for _, info in ipairs(activePlanters) do
        activeTypes[info.type] = true
        local pCfg = CONFIG.PLANTERS_CONFIG and CONFIG.PLANTERS_CONFIG[info.type]
        local isEnabled = pCfg and (pCfg.enabled == true)
        local targetPct = (pCfg and tonumber(pCfg.percent)) or 100

        -- Собираем ТОЛЬКО если плантатор созрел (Ready/100%) ИЛИ включен пользователем и достиг targetPct
        local shouldHarvest = (info.ready == true) or (isEnabled and info.percent >= targetPct and info.percent > 0)

        if shouldHarvest then
            log("Плантатор", string.format("🪴 Плантатор %s на поле %s достиг %.1f%% (порог %d%%)! Собираю урожай...", info.type, info.field, info.percent, targetPct))
            notifyAllWebhooks("Сбор плантатора!", string.format("Плантатор %s на поле %s достиг %.1f%% и был собран!", info.type, info.field, info.percent), "00f5a0")

            local root = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
            local pPos = worldPos(info.model)
            if root and pPos then
                moveRootToPosition(root, getGroundPos(pPos), 3.5)
            end

            -- Шаг 1: Активируем ProximityPrompt ("Harvest the ... Planter")
            for _, prompt in ipairs(info.model:GetDescendants()) do
                if prompt:IsA("ProximityPrompt") then
                    pcall(function() prompt.HoldDuration = 0 end)
                    if type(fireproximityprompt) == "function" then
                        pcall(fireproximityprompt, prompt, 0, true)
                        pcall(fireproximityprompt, prompt)
                    end
                    pcall(function()
                        prompt:InputHoldBegin()
                        task.wait(0.06)
                        prompt:InputHoldEnd()
                    end)
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

            if pCmd then
                pcall(function()
                    pCmd:FireServer({ Type = "Harvest", Planter = info.model, Confirm = true })
                    pCmd:FireServer({ Type = "Harvest", PlanterBox = info.model, Confirm = true })
                end)
            end
            if repPkg then
                pcall(function() repPkg:FireServer({ Type = "Harvest", Planter = info.model, Confirm = true }) end)
            end

            -- Шаг 2: Подтверждаем всплывающий диалог "Harvest the Planter before it's done growing? [Yes]"
            for _ = 1, 8 do
                task.wait(0.15)
                if confirmPlanterHarvestModal() then
                    break
                end
            end

            collectTokensFor(6, function() return not alive() end, pPos)
            activeTypes[info.type] = false
            task.wait(0.5)
        end
    end

    -- 2. Авто-посадка: ТОЛЬКО если плантатор включен пользователем (enabled == true),
    -- и его НЕТ на полях (not activeTypes[pType])!
    if CONFIG.PLANTERS_CONFIG then
        for pType, pCfg in pairs(CONFIG.PLANTERS_CONFIG) do
            if pCfg and pCfg.enabled == true and not activeTypes[pType] and pCfg.field and pCfg.field ~= "" then
                local fieldPart = getFieldPart(pCfg.field)
                local root = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
                if fieldPart and root and alive() then
                    local targetPos = getGroundPos(fieldPart.Position)
                    log("Плантатор", string.format("🌱 Плантатора %s нет на полях! Сажаю на поле %s...", pType, pCfg.field))
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
    if req then
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
        if ok and res and (res.StatusCode == 200 or res.Status == 200) and res.Body and res.Body ~= "" then
            return res.Body
        end
    end
    local ok, res = pcall(function() return game:HttpGet(url) end)
    if ok and res and res ~= "" then
        return res
    end
    return nil
end

function getServerList(cursor)
    local pid = tonumber(CONFIG.PLACE_ID) or (game and game.PlaceId) or 1537690962
    local now = os.clock()

    -- Если есть недавний кэш и нет курсора, отдаем кэш
    if (not cursor or cursor == "") and #serverPoolCache > 10 and (now - lastServerFetchAt < 20) then
        return serverPoolCache, nil
    end

    local urls = {
        "https://games.roblox.com/v1/games/" .. tostring(pid) .. "/servers/Public?sortOrder=Asc&limit=25",
        "https://games.roblox.com/v1/games/" .. tostring(pid) .. "/servers/Public?limit=25",
        "https://games.roblox.com/v1/games/" .. tostring(pid) .. "/servers/Public?sortOrder=Asc&limit=50",
    }
    if cursor and cursor ~= "" then
        urls = {
            "https://games.roblox.com/v1/games/" .. tostring(pid) .. "/servers/Public?sortOrder=Asc&limit=25&cursor=" .. tostring(cursor),
            "https://games.roblox.com/v1/games/" .. tostring(pid) .. "/servers/Public?limit=25&cursor=" .. tostring(cursor),
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

-- Черный список последних посещенных серверов (Blacklist последних 20 серверов)
local VISITED_SERVERS_FILE = "bss_recent_servers.json"
local recentVisitedServers = {}

function loadRecentVisited()
    pcall(function()
        if _G.BSS_VISITED_SERVERS and type(_G.BSS_VISITED_SERVERS) == "table" then
            recentVisitedServers = _G.BSS_VISITED_SERVERS
        elseif HAS_FS and isfile and isfile(VISITED_SERVERS_FILE) then
            local raw = readfile(VISITED_SERVERS_FILE)
            local decoded = HttpService:JSONDecode(raw)
            if type(decoded) == "table" then recentVisitedServers = decoded end
        end
    end)
end
loadRecentVisited()

function addVisitedServer(jobId)
    if not jobId or jobId == "" then return end
    for i, id in ipairs(recentVisitedServers) do
        if id == jobId then table.remove(recentVisitedServers, i); break end
    end
    table.insert(recentVisitedServers, 1, jobId)
    while #recentVisitedServers > 25 do
        table.remove(recentVisitedServers)
    end
    _G.BSS_VISITED_SERVERS = recentVisitedServers
    pcall(function()
        if HAS_FS and writefile then
            writefile(VISITED_SERVERS_FILE, HttpService:JSONEncode(recentVisitedServers))
        end
    end)
end

function isVisitedServer(jobId)
    if not jobId then return false end
    for _, id in ipairs(recentVisitedServers) do
        if id == jobId then return true end
    end
    return false
end

-- Добавляем текущий сервер в список посещенных
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

        -- 2. СТРОГИЙ ЗАПРЕТ: Текущий сервер, посещенные и сбойные
        if sid == game.JobId or isFailed(sid) or isVisitedServer(sid) then
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

    -- Резервный пул (если все подходящие уже были посещены)
    if #out == 0 and #fallback == 0 then
        for _, s in ipairs(servers) do
            local sid = tostring(s.id or "")
            local playing = tonumber(s.playing) or 0
            local maxPlr = tonumber(s.maxPlayers) or 6
            local ping = tonumber(s.ping) or 0
            local fps = tonumber(s.fps) or 60
            if sid ~= game.JobId and not isFailed(sid)
                and (CONFIG.AVOID_FRIENDS == false or not friendJobIds[sid])
                and playing >= 1 and playing < maxPlr
                and (ping == 0 or ping < 300) and fps >= 15 then
                table.insert(fallback, { id = sid, ping = ping, playing = playing })
            end
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

function hopTo(jobId, placeId)
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

    if not jobId or jobId == "" or jobId == game.JobId then
        log("Телепорт", "Отмена: попытка прыжка на текущий же сервер!")
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
        -- Если все посещены — пробуем любой сервер кроме текущего
        for _, s in ipairs(pool) do
            local sid = tostring(s.id or "")
            if sid ~= "" and sid ~= game.JobId
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
    local servers = getServerList()
    if servers then
        pruneFailures()
        updateFriendsList()
        for _, s in ipairs(servers) do
            local sid = tostring(s.id or "")
            local p = tonumber(s.playing) or 0
            local maxP = tonumber(s.maxPlayers) or 6
            if sid ~= game.JobId and p >= 2 and p < maxP
                and not isFailed(sid)
                and (CONFIG.AVOID_FRIENDS == false or not friendJobIds[sid]) then
                hopTo(sid); return
            end
        end
    end
end

local RETRYABLE_TELEPORT_CODES = { [2]=true, [3]=true, [279]=true, [267]=true }
local MAX_REJOIN_TRIES = 5
function rejoinRetry(code)
    rejoinTries += 1
    local attempt = rejoinTries
    task.wait(3) -- Таймаут перезахода: статично 3 секунды
    armTeleportPersistence()
    if CONFIG.ENABLE_BYPASS then bypassRecover("code_" .. tostring(code)) end
    if attempt >= MAX_REJOIN_TRIES then
        rejoinTries = 0; clearTeleport(); hopRandom(); return
    end
    clearTeleport(); rejoinSame()
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
    rejoinSame()
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
    local retryBtn = nil
    for _, d in ipairs(errorPrompt:GetDescendants()) do
        if d:IsA("TextLabel") and d.Text and d.Text ~= "" then
            fullText = fullText .. " " .. d.Text
        elseif (d:IsA("TextButton") or d:IsA("ImageButton")) and d.Visible then
            local bText = string.lower(tostring(d.Text or ""))
            if string.find(bText, "retry") or string.find(bText, "reconnect") or string.find(bText, "повтор") or string.find(bText, "переподключ") then
                retryBtn = d
            end
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

        -- Вооружаем персистентность (queue_on_teleport) перед перезаходом,
        -- чтобы скрипт автоматически оставался и выполнялся на новом сервере без повторного инжекта!
        armTeleportPersistence()
        if CONFIG.ENABLE_BYPASS then bypassRecover("error_kick_267") end
        if bypassActive and Bypass.Recover then pcall(Bypass.Recover, Bypass, "error_kick_267") end
        if bypassActive and Bypass.Bypass267 then pcall(Bypass.Bypass267, Bypass) end

        if retryBtn then
            log("TP", "[ОБХОД 267/279] Нажимаю Reconnect / Retry (скрипт сохранен в queue_on_teleport)...")
            pcall(function()
                if type(firesignal) == "function" then
                    firesignal(retryBtn.MouseButton1Click)
                end
                retryBtn.MouseButton1Click:Fire()
            end)
            task.wait(1.5)
        end

        if overlay:FindFirstChild("ErrorPrompt") then
            log("TP", "[ОБХОД 267/279] Перезапускаю подключение к серверу (скрипт сохранен в queue_on_teleport)...")
            pcall(function() errorPrompt.Visible = false end)
            task.wait(2.5)
            clearTeleport()
            armTeleportPersistence()
            rejoinSame()
        end
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
local RARITY_PRIORITY = { mythic=7, legendary=6, epic=5, gummy=4, rare=3, moon=2, basic=1, common=1, normal=1, unknown=1 }
local RARITY_LABEL = {
    gummy="🍬 Gummy", legendary="💠 Legendary", epic="🥇 Epic",
    rare="🥈 Rare", basic="🌱 Basic", moon="🌙 Moon", common="⚪ Common",
}

function hueOf(color)
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

function isRarityAtLeast(rarity, minimum)
    local got = rarity and RARITY_PRIORITY[rarity]
    local minValue = RARITY_PRIORITY[string.lower(tostring(minimum or "basic"))] or RARITY_PRIORITY.basic
    return got ~= nil and got >= minValue
end

function isSproutEligible(sprout)
    local rarity, source = detectRarity(sprout)
    return isRarityAtLeast(rarity, CONFIG.MIN_RARITY), rarity, source
end

function findLootableSprout()
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
    return best
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

-- Реестр всех токенов со спрутов в Bee Swarm Simulator
TOKEN_REGISTRY = {
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

isBurstLootActive = false

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
        or string.find(n, "link", 1, true)
end

function tokenPriority(name)
    local low = string.lower(tostring(name or ""))
    local pMap = CONFIG.TOKEN_PRIORITIES

    -- 1. Пользовательские приоритеты из настроек
    if pMap and type(pMap) == "table" then
        for _, def in ipairs(TOKEN_REGISTRY) do
            local userPrio = pMap[def.id]
            local prio = (userPrio ~= nil) and userPrio or def.defaultPrio
            for _, kw in ipairs(def.keywords) do
                if string.find(low, kw, 1, true) then
                    if prio == 0 then return 999 end -- Полный пропуск токена
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
    if cached and cached ~= "token" and cached ~= "cframe" and cached ~= "part" then
        return cached
    end

    local name = tostring(obj.Name or "")
    local detectedName = nil

    -- 1. Проверяем декали внутри токена по базе текстур BSS (через GetDescendants)
    local okC, descendants = pcall(function() return obj:GetDescendants() end)
    if okC and descendants then
        for _, child in ipairs(descendants) do
            if child:IsA("Decal") or child:IsA("Texture") then
                local tex = tostring(child.Texture or "")
                local lowTex = string.lower(tex)
                local id = string.match(tex, "%d+")
                if TOKEN_TEXTURE_MAP[lowTex] then
                    detectedName = TOKEN_TEXTURE_MAP[lowTex]
                    break
                elseif id and TOKEN_TEXTURE_MAP[id] then
                    detectedName = TOKEN_TEXTURE_MAP[id]
                    break
                elseif id and #id >= 6 then
                    -- Мгновенно обновляем базу если попался неизвестный ID
                    pcall(buildTokenTextureMap)
                    if TOKEN_TEXTURE_MAP[id] then
                        detectedName = TOKEN_TEXTURE_MAP[id]
                        break
                    end
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
                end
            end
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
    if not detectedName and okC and descendants then
        for _, child in ipairs(descendants) do
            if child:IsA("Decal") or child:IsA("Texture") then
                local tex = tostring(child.Texture or "")
                if tex ~= "" and not isHoneyToken(tex) and not isAbilityToken(tex) then
                    detectedName = "sprout_item"
                    break
                end
            end
        end
    end

    local result = detectedName or (name ~= "" and name or "token")
    if result ~= "token" and result ~= "cframe" and result ~= "part" then
        TOKEN_NAME_CACHE[obj] = result
    end
    return result
end

function getTokenPriorityForObj(obj)
    if not obj then return 3 end
    local cached = TOKEN_PRIO_CACHE[obj]
    if cached and cached ~= 3 then return cached end
    local name = resolveTokenName(obj)
    local prio = tokenPriority(name)
    if prio ~= 3 or name ~= "token" then
        TOKEN_PRIO_CACHE[obj] = prio
    end
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
                if item.Parent ~= char then pcall(function() item.Parent = char end) end
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
    if now - TOKEN_CACHE_AT < 0.08 then
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

            local char, root, humanoid = waitForRespawn(5)
            if not root or not humanoid or humanoid.Health <= 0 then
                break
            end

            -- Защита от потери поля: если персонаж возродился на улье после смерти (> 70 studs от поля)
            local targetFieldPos = fieldAnchor or (anchorZone and anchorZone.Position)
            if targetFieldPos and (root.Position - targetFieldPos).Magnitude > 70 then
                log("Возврат", string.format("Персонаж вдали от поля (%.0f studs). Немедленно лечу обратно на поле...", (root.Position - targetFieldPos).Magnitude))
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
                    setFlightNoclip(false)
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
                            activeTokenObj = nil
                        end
                    else
                        activeTokenObj = nil
                    end
                end
            end

            -- Поиск токенов внутри и вокруг поля (с Target Lock от тряски)
            local tokens = findFieldTokens(anchorZone, limitX, limitZ, fieldAnchor)
            local best, bestKey = nil, math.huge
            if activeTokenObj and activeTokenObj.Parent and not collectedTokens[activeTokenObj] then
                local p = worldPos(activeTokenObj)
                if p then
                    local dx = p.X - rootPos.X
                    local dz = p.Z - rootPos.Z
                    if (dx * dx + dz * dz) > 4.0 then
                        best = { obj = activeTokenObj, pos = p, priority = 1 }
                        bestKey = 0
                    end
                end
            end
            for _, token in ipairs(tokens) do
                local tobj = token.obj
                if tobj and tobj.Parent and not collectedTokens[tobj] then
                    local dx = token.pos.X - rootPos.X
                    local dz = token.pos.Z - rootPos.Z
                    local distSq = dx * dx + dz * dz
                    if distSq <= 6.25 then
                        collectedTokens[tobj] = true
                    else
                        local p = token.priority
                        if p < 999 then
                            local score
                            if isBurstLootActive then
                                score = (p == 1 and 0) or 5000000
                            else
                                score = (p == 1 and 0) or (p == 2 and 100000) or 200000
                            end
                            local key = score + distSq
                            if key < bestKey then
                                best = token
                                bestKey = key
                            end
                        end
                    end
                end
            end

            -- Приоритетная скорость бега (без резких скачков и перезаписи Heartbeat)
            local isP1 = best and best.priority == 1
            applyWalkSpeed(isP1 or isBurstLootActive)

            -- Не копаем во время охоты за P1 токеном, чтобы не сбивать спринт!
            if not isP1 and not isBurstLootActive then
                pcall(swingDigTool)
            end

            if best then
                if activeTokenObj ~= best.obj and isP1 then
                    local tName = resolveTokenName(best.obj)
                    log("Token", string.format("⚡ Бегу за приоритетным токеном: %s (P1) на расстоянии %.1f studs!", tName, math.sqrt(bestKey)))
                end
                activeTokenObj = best.obj
                patrolTarget = Vector3.new(best.pos.X, (anchorZone and (anchorZone.Position.Y + 3.2)) or root.Position.Y, best.pos.Z)
            else
                activeTokenObj = nil
                local needNewPatrol = not patrolTarget 
                    or (root.Position - patrolTarget).Magnitude < 3.2
                    or (os.clock() - lastPatrolPickAt > 2.8)

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
                        patrolTarget = Vector3.new(worldPoint.X, (anchorZone and (anchorZone.Position.Y + 3.2)) or root.Position.Y, worldPoint.Z)
                    elseif fieldAnchor then
                        local angle = math.random() * math.pi * 2
                        local dist = math.random(5, 18)
                        patrolTarget = Vector3.new(fieldAnchor.X + math.cos(angle) * dist, (anchorZone and (anchorZone.Position.Y + 3.2)) or root.Position.Y, fieldAnchor.Z + math.sin(angle) * dist)
                    else
                        patrolTarget = root.Position
                    end
                end

            end

            -- Ограничение цели СТРОГО в границы поля (персонаж никогда не убегает с поля!)
            if anchorZone and patrolTarget then
                local lp = anchorZone.CFrame:PointToObjectSpace(patrolTarget)
                local safeX = math.clamp(lp.X, -limitX, limitX)
                local safeZ = math.clamp(lp.Z, -limitZ, limitZ)
                local safeWorld = anchorZone.CFrame:PointToWorldSpace(Vector3.new(safeX, lp.Y, safeZ))
                patrolTarget = Vector3.new(safeWorld.X, (anchorZone and (anchorZone.Position.Y + 3.2)) or root.Position.Y, safeWorld.Z)
            end

            -- Плавное и безотказное перемещение через нативный MoveTo с защитой от тряски
            if patrolTarget and humanoid and root then
                local currentPos = root.Position
                local flatTarget = Vector3.new(patrolTarget.X, currentPos.Y, patrolTarget.Z)
                local offset = flatTarget - currentPos
                local dist = offset.Magnitude

                if dist > 3.0 then
                    local now = os.clock()
                    if not lastMoveToTarget or (lastMoveToTarget - flatTarget).Magnitude > 2.0 or (now - lastMoveToCall > 0.35) then
                        lastMoveToTarget = flatTarget
                        lastMoveToCall = now
                        humanoid:MoveTo(flatTarget)
                    end
                else
                    lastMoveToTarget = nil
                end

                -- Защита от реального застревания в объектах (ростки, заборы):
                -- Прыгаем ТОЛЬКО если персонаж физически не сдвинулся с места более 1.2 сек!
                local now = os.clock()
                if not lastRecordedPos then lastRecordedPos = currentPos end
                if (currentPos - lastRecordedPos).Magnitude < 0.6 then
                    if not stuckStartTime then stuckStartTime = now end
                    if (now - stuckStartTime > 1.2) and (now - lastJumpTime > 2.5) then
                        if humanoid.FloorMaterial ~= Enum.Material.Air then
                            humanoid.Jump = true
                            lastJumpTime = now
                        end
                        -- Сбрасываем цель, чтобы персонаж обошел росток или забор, а не прыгал по нему
                        patrolTarget = nil
                        stuckStartTime = nil
                    end
                else
                    lastRecordedPos = currentPos
                    stuckStartTime = nil
                end
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
    local bp = player:FindFirstChildOfClass("Backpack")
    if bp and tool and tool.Parent == char then
        pcall(function() tool.Parent = bp end)
    end
    task.wait(0.05)
    ensureHarvestToolEquipped()
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
        s.currentStatus = "Ожидание загрузки игры..."
        waitForGameReady(25)
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
                    local hopWait = math.max(0.2, tonumber(CONFIG.HOP_DELAY) or 0.8)
                    task.wait(hopWait)
                    hopRandom()
                end
            end)
            if not ok then
                log("Ищущий", "Ошибка: " .. tostring(err))
                task.wait(2); hopRandom()
            end
            task.wait(math.max(0.5, tonumber(CONFIG.HOP_DELAY) or 0.8))
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
    if not sprout then return false end

    local sproutAnchor = worldPos(sprout)
    if not moveToSprout(sprout) then
        return false
    end
    sproutAnchor = worldPos(sprout) or sproutAnchor or (player.Character and player.Character:FindFirstChild("HumanoidRootPart") and player.Character.HumanoidRootPart.Position)

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

        if isBackpackFull() then
            stopAutoDig()
            tokenCollectorBusy = false
            patrolTarget = nil
            while isBackpackFull() and alive() do
                s.currentStatus = "Рюкзак полный — делаю Honey на улье..."
                makeHoney()
                task.wait(1)
            end
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
        if alive() and not isBackpackFull() then
            -- BURST-РЕЖИМ СБОРА
            if CONFIG.BURST_LOOT_ENABLED ~= false then
                s.currentStatus = "⚡ BURST-СБОР: Сверхбыстрый сбор редкого лута!"
                stopAutoDig()
                tokenCollectorBusy = false
                patrolTarget = nil
                isBurstLootActive = true
                local burstTime = tonumber(CONFIG.BURST_LOOT_TIME) or 7
                local burstStart = os.clock()
                collectTokensFor(burstTime, function()
                    return not alive() or isBackpackFull() or (os.clock() - burstStart >= burstTime)
                end, sproutAnchor)
                isBurstLootActive = false
            end

            if alive() and not isBackpackFull() then
                s.currentStatus = "Росток сломан — собираю оставшиеся токены..."
                collectTokensFor(tonumber(CONFIG.BROKEN_WAIT) or 20, function()
                    return not alive() or isBackpackFull()
                end, sproutAnchor)
            end
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
    return true
end

function Looter:fetchNextVicious()
    local ok, res = pcall(function()
        return game:HttpGet(CONFIG.API_URL .. "/vicious-next?apiKey=" .. CONFIG.API_KEY)
    end)
    if not ok then return nil, "HTTP Vicious" end
    local ok2, data = pcall(function() return HttpService:JSONDecode(res) end)
    if not ok2 or not data then return nil, "плохой JSON" end
    if data.empty or not data.jobId then return nil, nil end
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
        s.currentStatus = "Ожидание загрузки игры..."
        waitForGameReady(25)

        -- Сброс данных улья прошлого сервера
        myClaimedHiveSlot = nil
        myClaimedHivePos = nil
        cachedHiveSlot = nil
        cachedHivePos = nil

        -- 1. Сначала при заходе на сервер ищем росток/вициус ровно 5 секунд
        local initialTargetFound = false
        for checkSec = 1, 5 do
            if not alive() then return end
            s.currentStatus = string.format("Проверяю сервер на росток / вициус (%dc)...", 6 - checkSec)

            local sprout = CONFIG.CHECK_SPROUTS and findLootableSprout() or nil
            local vicious = CONFIG.CHECK_VICIOUS and findVicious() or nil

            if sprout or vicious then
                initialTargetFound = true

                -- ШАГ 1: Поставил улей если есть росток/вициус!
                if not hasOwnHive() then
                    s.currentStatus = "Цель есть! Занимаю свой улей..."
                    local claimOk, claimed = pcall(ensureHiveClaimed)
                    if claimOk and claimed then s.hivesClaimed += 1 end
                end

                -- ШАГ 2: Если рюкзак полон — конвертирует в своем улье!
                if isBackpackFull() then
                    s.currentStatus = "Рюкзак полон — конвертирую в своем улье..."
                    pcall(makeHoney)
                end

                -- ШАГ 3: Летит лутать!
                if sprout then
                    s.currentStatus = "Лечу лутать росток!"
                    local okHarvest, harvestRes = pcall(function() return self:harvest() end)
                    if okHarvest and harvestRes == true then
                        break
                    end
                elseif vicious then
                    s.currentStatus = "Лечу бить Вициуса!"
                    pcall(function() fightVicious(vicious) end)
                    break
                end
            end

            if CONFIG.CHECK_PUFFSHROOMS then
                local okPuff, puffList = pcall(findEligiblePuffshrooms)
                if okPuff and puffList and #puffList > 0 then
                    s.currentStatus = "Puffshroom найден — начинаю сбор!"
                    pcall(function() self:harvestPuffshrooms() end)
                    initialTargetFound = true
                    break
                end
            end

            task.wait(1)
        end

        -- Если рюкзак заполнился во время сбора начального ростка — разгружаем на улье
        if isBackpackFull() then
            s.currentStatus = "Рюкзак полный — делаю Honey"
            pcall(makeHoney)
        end

        local taskAttempts = {}

        if not initialTargetFound then
            s.currentStatus = "Целей на сервере нет — опрашиваю ищущих..."
            log("Лутающий", "Нет целей за 5с. Проверяю очередь задач от ищущих.")
        else
            s.currentStatus = "Цель залутана — подключаюсь к боту..."
        end

        while true do
            if not alive() then return end
            local ok, err = pcall(function()
                s.serversChecked += 1

                -- Проверка локальных целей (если новый росток или вициус вырос прямо на этом сервере)
                if CONFIG.CHECK_SPROUTS and findLootableSprout() then
                    stopAutoDig()
                    tokenCollectorBusy = false
                    s.currentStatus = "Новый росток на сервере — лутаю!"
                    pcall(function() self:harvest() end)
                    if isBackpackFull() then pcall(makeHoney) end
                    return
                end

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

                -- Если рюкзак полон — разгружаем в мед на улье
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

                -- Опрашиваем бота о новых задачах от Ищущего
                local taskData, skipReason = nil, nil
                if CONFIG.CHECK_VICIOUS then
                    taskData, skipReason = self:fetchNextVicious()
                end
                if not taskData and CONFIG.CHECK_SPROUTS then
                    local sData, sReason = self:fetchNext()
                    if sData then
                        taskData = sData
                    elseif not skipReason then
                        skipReason = sReason
                    end
                end

                if taskData and taskData.jobId then
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
                            if CONFIG.CHECK_SPROUTS and findLootableSprout() then
                                pcall(function() self:harvest() end)
                                found = true
                                break
                            end
                            if CONFIG.CHECK_VICIOUS and findVicious() then
                                pcall(function() fightVicious(findVicious()) end)
                                found = true
                                break
                            end
                            task.wait(1)
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

                    -- Ищущие нашли задачу! Моментально прекращаем соло-фарм и телепортируемся
                    stopAutoDig()
                    tokenCollectorBusy = false
                    s.tasksReceived += 1
                    s.lastTask = {
                        fieldName = taskData.isVicious and ("Vicious @ "..tostring(taskData.fieldName or "?"))
                            or (RARITY_LABEL[taskData.level] or taskData.level or "спрут"),
                        jobId = taskData.jobId, age = taskData.age,
                    }
                    s.currentStatus = "Ищущие нашли задачу! Телепортируюсь..."
                    s.teleports += 1
                    log("Лутающий", "Ищущие нашли задачу! Немедленный переход на сервер: " .. tostring(taskData.jobId))
                    if not hopTo(taskData.jobId, taskData.placeId) then
                        self:returnTask(taskData, "teleport failed")
                        task.wait(tonumber(CONFIG.POLL_INTERVAL) or 3)
                        return
                    end
                    task.wait(25)
                    self:returnTask(taskData, "timeout")
                    return
                end

                -- ЗАДАЧ НЕТ И ЦЕЛЕЙ НА СЕРВЕРЕ НЕТ:
                -- Лутающий работает автономно в соло-режиме: прыгает по серверам,
                -- параллельно на каждом сервере проверяя задания от ищущих!
                while isBackpackFull() and alive() do
                    stopAutoDig()
                    tokenCollectorBusy = false
                    s.currentStatus = "Рюкзак полный — делаю Honey перед прыжком..."
                    makeHoney()
                    task.wait(1)
                end

                s.currentStatus = "Целей нет — прыгаю на случайный сервер (соло-поиск)..."
                log("Лутающий", "Нет задач от ищущих и целей на сервере. Прыгаю на случайный сервер...")
                local hopWait = math.max(0.2, tonumber(CONFIG.HOP_DELAY) or 0.8)
                task.wait(hopWait)
                if alive() then
                    s.teleports += 1
                    s.currentStatus = "Телепортируюсь на новый сервер..."
                    hopRandom()
                    task.wait(6)
                    return
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

                -- Если целей нет — улей не ставим, переходим на другой сервер!
                if not vicious and not sprout and not puffRoot and not windy and not meteors then
                    s.currentStatus = "Целей нет — перехожу на другой сервер..."
                    local hopWait = math.max(0.2, tonumber(CONFIG.HOP_DELAY) or 0.8)
                    task.wait(hopWait)
                    if alive() then
                        s.hops += 1
                        s.currentStatus = "Телепортируюсь на новый сервер..."
                        local hopped = hopRandom()
                        if not hopped then
                            s.currentStatus = "Ожидание свободного сервера..."
                            task.wait(6)
                        else
                            task.wait(8)
                        end
                        return
                    end
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
                    s.currentStatus = "🌪️ Найдена Windy Bee — взлетаю в облако!"
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
                    if moveToSprout(sprout) then
                        sproutAnchor = worldPos(sprout) or sproutAnchor or (player.Character and player.Character:FindFirstChild("HumanoidRootPart") and player.Character.HumanoidRootPart.Position)
                        s.currentStatus = "Росток: ставлю поливалку"
                        task.wait(0.15)
                        if useSprinklerBuilder then pcall(useSprinklerBuilder, sproutAnchor) end
                        ensureHarvestToolEquipped()

                        -- Фаза 1: Росток жив. Бегает всегда, машет палкой 100%, собирает токены
                        while alive() and isSproutAlive(sprout, sproutAnchor) do
                            local char = player.Character
                            local root = char and char:FindFirstChild("HumanoidRootPart")
                            local hum = char and char:FindFirstChildOfClass("Humanoid")
                            if not root or not hum or hum.Health <= 0 or (sproutAnchor and (root.Position - sproutAnchor).Magnitude > 70) then
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

                            if isBackpackFull() then
                                stopAutoDig()
                                tokenCollectorBusy = false
                                patrolTarget = nil
                                while isBackpackFull() and alive() do
                                    s.currentStatus = "Рюкзак полный — делаю Honey на улье..."
                                    makeHoney()
                                    task.wait(0.5)
                                end
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
                            local char = player.Character
                            local root = char and char:FindFirstChild("HumanoidRootPart")
                            local hum = char and char:FindFirstChildOfClass("Humanoid")
                            if not root or not hum or hum.Health <= 0 or (root.Position - sproutAnchor).Magnitude > 70 then
                                if not root or not hum or hum.Health <= 0 then
                                    char, root, hum = waitForRespawn(8)
                                end
                                task.wait(0.3)
                                if root and sproutAnchor then
                                    log("Возврат", "Возврат к сломанному ростку после смерти...")
                                    moveRootToPosition(root, getGroundPos(sproutAnchor), 10)
                                end
                            end

                            if isBackpackFull() then
                                stopAutoDig()
                                tokenCollectorBusy = false
                                patrolTarget = nil
                                while isBackpackFull() and alive() do
                                    s.currentStatus = "Рюкзак полный — делаю Honey"
                                    makeHoney()
                                    task.wait(0.5)
                                end
                            end
                            if alive() and not isBackpackFull() then
                                -- BURST-РЕЖИМ СБОРА
                                if CONFIG.BURST_LOOT_ENABLED ~= false then
                                    s.currentStatus = "⚡ BURST-СБОР: Сверхбыстрый сбор редкого лута!"
                                    stopAutoDig()
                                    tokenCollectorBusy = false
                                    patrolTarget = nil
                                    isBurstLootActive = true
                                    local burstTime = tonumber(CONFIG.BURST_LOOT_TIME) or 7
                                    local burstStart = os.clock()
                                    collectTokensFor(burstTime, function()
                                        return not alive() or isBackpackFull()
                                            or (CONFIG.CHECK_VICIOUS and findVicious() ~= nil)
                                            or (os.clock() - burstStart >= burstTime)
                                    end, sproutAnchor)
                                    isBurstLootActive = false
                                end

                                if alive() and not isBackpackFull() and not (CONFIG.CHECK_VICIOUS and findVicious()) then
                                    s.currentStatus = "Росток сломан — собираю оставшиеся токены..."
                                    collectTokensFor(tonumber(CONFIG.BROKEN_WAIT) or 20, function()
                                        return not alive() or isBackpackFull() or (CONFIG.CHECK_VICIOUS and findVicious() ~= nil)
                                    end, sproutAnchor)
                                end
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
                    s.currentStatus = "Росток залутан — перехожу на другой сервер..."
                    local hopWait = math.max(0.2, tonumber(CONFIG.HOP_DELAY) or 0.8)
                    task.wait(hopWait)
                    if alive() then
                        s.hops += 1
                        s.currentStatus = "Телепортируюсь на новый сервер..."
                        hopRandom()
                        task.wait(6)
                        return
                    end
                end

                -- Если ростка нет на сервере — переходим на другой
                s.currentStatus = "Целей нет — перехожу на другой сервер..."
                local hopWait = math.max(0.2, tonumber(CONFIG.HOP_DELAY) or 0.8)
                task.wait(hopWait)
                if alive() then
                    s.hops += 1
                    s.currentStatus = "Телепортируюсь на новый сервер..."
                    local hopped = hopRandom()
                    if not hopped then
                        s.currentStatus = "Ожидание свободного сервера..."
                        task.wait(6)
                    else
                        task.wait(8)
                    end
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

-- ══════════════════════════════════════════════════════════════════════
--  ON-SCREEN HUD: PLANTER TIMERS (ТОЧНО КАК НА СКРИНШОТЕ)
-- ══════════════════════════════════════════════════════════════════════
local planterHudFrame = new("Frame", {
    Name = "PlanterTimersHUD",
    Size = UDim2.new(0, 260, 0, 0),
    AutomaticSize = Enum.AutomaticSize.Y,
    Position = UDim2.new(1, -275, 0, 75),
    BackgroundColor3 = Color3.fromRGB(18, 18, 22),
    BorderSizePixel = 0, Active = true, Draggable = true,
    Visible = (CONFIG.SHOW_PLANTER_HUD ~= false),
    Parent = gui,
})
round(planterHudFrame, 8)
stroke(planterHudFrame, Color3.fromRGB(48, 50, 62), 1)

local planterHudHeader = new("Frame", {
    Size = UDim2.new(1, 0, 0, 28),
    BackgroundTransparency = 1,
    Parent = planterHudFrame,
})

local planterHudTitle = new("TextLabel", {
    Size = UDim2.new(1, -36, 1, 0),
    Position = UDim2.new(0, 10, 0, 0),
    BackgroundTransparency = 1,
    Text = "Planter Timers",
    Font = Enum.Font.GothamBold,
    TextSize = 13,
    TextColor3 = Color3.fromRGB(240, 240, 245),
    TextXAlignment = Enum.TextXAlignment.Left,
    Parent = planterHudHeader,
})

local planterHudArrow = new("TextButton", {
    Size = UDim2.new(0, 26, 0, 26),
    Position = UDim2.new(1, -28, 0, 1),
    BackgroundTransparency = 1,
    Text = CONFIG.PLANTER_HUD_COLLAPSED and "▲" or "▼",
    Font = Enum.Font.GothamBold,
    TextSize = 12,
    TextColor3 = Color3.fromRGB(200, 200, 210),
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
new("UIListLayout", {
    SortOrder = Enum.SortOrder.LayoutOrder,
    Padding = UDim.new(0, 4),
    Parent = planterHudContent,
})
new("UIPadding", {
    PaddingTop = UDim.new(0, 2),
    PaddingBottom = UDim.new(0, 8),
    PaddingLeft = UDim.new(0, 10),
    PaddingRight = UDim.new(0, 10),
    Parent = planterHudContent,
})

planterHudArrow.MouseButton1Click:Connect(function()
    CONFIG.PLANTER_HUD_COLLAPSED = not CONFIG.PLANTER_HUD_COLLAPSED
    planterHudContent.Visible = not CONFIG.PLANTER_HUD_COLLAPSED
    planterHudArrow.Text = CONFIG.PLANTER_HUD_COLLAPSED and "▲" or "▼"
    saveNow()
end)

local function refreshPlanterHud(activeList)
    if not planterHudContent then return end
    planterHudContent:ClearAllChildren()
    new("UIListLayout", {
        SortOrder = Enum.SortOrder.LayoutOrder,
        Padding = UDim.new(0, 4),
        Parent = planterHudContent,
    })
    new("UIPadding", {
        PaddingTop = UDim.new(0, 2),
        PaddingBottom = UDim.new(0, 8),
        PaddingLeft = UDim.new(0, 10),
        PaddingRight = UDim.new(0, 10),
        Parent = planterHudContent,
    })

    if not activeList or #activeList == 0 then
        new("TextLabel", {
            Size = UDim2.new(1, 0, 0, 18),
            BackgroundTransparency = 1,
            Text = "Нет активных плантаторов",
            TextColor3 = Color3.fromRGB(140, 140, 150),
            Font = Enum.Font.Gotham,
            TextSize = 11,
            TextXAlignment = Enum.TextXAlignment.Left,
            Parent = planterHudContent,
        })
        return
    end

    for idx, info in ipairs(activeList) do
        local isReady = info.ready or (info.percent >= 100) or string.find(string.lower(info.statusStr), "0s", 1, true)
        local lineText = string.format("%s: %s (%s)", info.type, info.statusStr, info.field)
        new("TextLabel", {
            Size = UDim2.new(1, 0, 0, 18),
            BackgroundTransparency = 1,
            Text = lineText,
            TextColor3 = isReady and Color3.fromRGB(80, 240, 120) or Color3.fromRGB(230, 230, 235),
            Font = isReady and Enum.Font.GothamBold or Enum.Font.GothamMedium,
            TextSize = 11,
            TextXAlignment = Enum.TextXAlignment.Left,
            LayoutOrder = idx,
            Parent = planterHudContent,
        })
    end
end

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
    BackgroundTransparency = 1, Text = "BSS Hopper v1.3.76",
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
makeTab("🍄", "Грибы", "puffshrooms")
makeTab("🪴", "Плантаторы", "planters")
makeTab("🌪️", "Windy & Meteors", "windy_meteors")
makeTab("📡", "Вебхуки", "webhooks")
makeTab("⚙", "Настройки", "settings")
makeTab("📁", "Конфиги", "configs")
makeTab("🐝", "Vicious Bee", "vicious")

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
    tb.FocusLost:Connect(function()
        if applySettings then pcall(applySettings) end
    end)
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
    local TweenService = game:GetService("TweenService")

    -- Стильный анимированный переключатель (Cyber Switch) с гладким сдвигом таблетки
    local switch = new("TextButton", {
        Size = UDim2.new(0, 48, 0, 24),
        Position = UDim2.new(1, -56, 0.5, -12),
        BackgroundColor3 = state and Color3.fromRGB(0, 230, 150) or Color3.fromRGB(32, 38, 52),
        Text = "", AutoButtonColor = false,
        BorderSizePixel = 0, Parent = box,
    })
    round(switch, 12)
    stroke(switch, state and Color3.fromRGB(0, 255, 180) or Color3.fromRGB(48, 56, 76), 1)

    local circle = new("Frame", {
        Size = UDim2.new(0, 18, 0, 18),
        Position = state and UDim2.new(1, -21, 0.5, -9) or UDim2.new(0, 3, 0.5, -9),
        BackgroundColor3 = Color3.fromRGB(255, 255, 255),
        BorderSizePixel = 0, Parent = switch,
    })
    round(circle, 9)

    switch.MouseButton1Click:Connect(function()
        state = not state
        local targetColor = state and Color3.fromRGB(0, 230, 150) or Color3.fromRGB(32, 38, 52)
        local targetPos = state and UDim2.new(1, -21, 0.5, -9) or UDim2.new(0, 3, 0.5, -9)
        local twInfo = TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
        pcall(function()
            TweenService:Create(switch, twInfo, { BackgroundColor3 = targetColor }):Play()
            TweenService:Create(circle, twInfo, { Position = targetPos }):Play()
        end)
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
makeToggle(PAGE_HOME, "Лутать ростки (Sprouts)", CONFIG.CHECK_SPROUTS, 2, function(v)
    CONFIG.CHECK_SPROUTS = v; saveNow()
end)
makeToggle(PAGE_HOME, "Лутать грибы (Puffshrooms)", CONFIG.CHECK_PUFFSHROOMS, 3, function(v)
    CONFIG.CHECK_PUFFSHROOMS = v; saveNow()
end)
makeToggle(PAGE_HOME, "Охота на Windy Bee (бой на поле)", CONFIG.CHECK_WINDY, 4, function(v)
    CONFIG.CHECK_WINDY = v; saveNow()
end)
makeToggle(PAGE_HOME, "Лутать метеориты (Meteor Shower)", CONFIG.CHECK_METEORS, 5, function(v)
    CONFIG.CHECK_METEORS = v; saveNow()
end)
makeToggle(PAGE_HOME, "Лутать Vicious Bee", CONFIG.CHECK_VICIOUS, 6, function(v)
    CONFIG.CHECK_VICIOUS = v; saveNow()
end)
makeToggle(PAGE_HOME, "Авто-плантаторы (Сбор и Посадка)", CONFIG.AUTO_HARVEST_PLANTERS, 7, function(v)
    CONFIG.AUTO_HARVEST_PLANTERS = v; saveNow()
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

-- ══════════════════════════════════════════════════════════════════════
--  ВКЛАДКА: 🌪️ WINDY BEE & METEORS
-- ══════════════════════════════════════════════════════════════════════
local PAGE_WINDY = new("Frame", {
    Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y,
    BackgroundTransparency = 1, Visible = false, Parent = content,
})
new("UIListLayout", { SortOrder = Enum.SortOrder.LayoutOrder, Padding = UDim.new(0, 8), Parent = PAGE_WINDY })

section("🌪️ WINDY BEE & METEOR SHOWER", 1).Parent = PAGE_WINDY
makeToggle(PAGE_WINDY, "Атаковать дикую Windy Bee в облаке", CONFIG.CHECK_WINDY, 2, function(v)
    CONFIG.CHECK_WINDY = v; saveNow()
end)
makeToggle(PAGE_WINDY, "Лутать метеоритный дождь (Meteors)", CONFIG.CHECK_METEORS, 3, function(v)
    CONFIG.CHECK_METEORS = v; saveNow()
end)
makeToggle(PAGE_WINDY, "Автоматический сбор спелых плантаторов", CONFIG.AUTO_HARVEST_PLANTERS, 4, function(v)
    CONFIG.AUTO_HARVEST_PLANTERS = v; saveNow()
end)

-- ══════════════════════════════════════════════════════════════════════
--  ВКЛАДКА: 📡 ВЕБХУКИ DISCORD & TELEGRAM
-- ══════════════════════════════════════════════════════════════════════
local PAGE_WEBHOOKS = new("Frame", {
    Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y,
    BackgroundTransparency = 1, Visible = false, Parent = content,
})
new("UIListLayout", { SortOrder = Enum.SortOrder.LayoutOrder, Padding = UDim.new(0, 8), Parent = PAGE_WEBHOOKS })

section("📡 УВЕДОМЛЕНИЯ В DISCORD & TELEGRAM", 1).Parent = PAGE_WEBHOOKS
local fDisc = makeField(PAGE_WEBHOOKS, "DISCORD WEBHOOK URL", CONFIG.DISCORD_WEBHOOK_URL or "", "https://discord.com/api/webhooks/...", 2)
local fTgToken = makeField(PAGE_WEBHOOKS, "TELEGRAM BOT TOKEN", CONFIG.TELEGRAM_BOT_TOKEN or "", "123456789:ABCdef...", 3)
local fTgChat = makeField(PAGE_WEBHOOKS, "TELEGRAM CHAT ID", CONFIG.TELEGRAM_CHAT_ID or "", "123456789", 4)

makeBtn(PAGE_WEBHOOKS, "💾 Сохранить и проверить вебхуки", function()
    CONFIG.DISCORD_WEBHOOK_URL = fDisc.Text
    CONFIG.TELEGRAM_BOT_TOKEN = fTgToken.Text
    CONFIG.TELEGRAM_CHAT_ID = fTgChat.Text
    saveNow()
    notifyAllWebhooks("Тестовое уведомление!", "Вебхуки BSS Hopper успешно подключены и работают!", "00f5a0")
    log("Вебхуки", "Настройки сохранены! Отправлено тестовое уведомление.")
end, C.accent2, 5)

-- ══════════════════════════════════════════════════════════════════════
--  ВКЛАДКА: 🪴 ПЛАНТАТОРЫ (14 ТИПОВ: СБОР ПО % И ПОСАДКА НА ПОЛЕ)
-- ══════════════════════════════════════════════════════════════════════
local PAGE_PLANTERS = new("Frame", {
    Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y,
    BackgroundTransparency = 1, Visible = false, Parent = content,
})
new("UIListLayout", { SortOrder = Enum.SortOrder.LayoutOrder, Padding = UDim.new(0, 8), Parent = PAGE_PLANTERS })

section("🪴 УПРАВЛЕНИЕ ПЛАНТАТОРАМИ (14 ТИПОВ)", 1).Parent = PAGE_PLANTERS
makeToggle(PAGE_PLANTERS, "Включить авто-плантаторы (Сбор и Посадка)", CONFIG.AUTO_HARVEST_PLANTERS ~= false, 2, function(v)
    CONFIG.AUTO_HARVEST_PLANTERS = v; saveNow()
end)
makeToggle(PAGE_PLANTERS, "Показывать виджет 'Planter Timers' на экране", CONFIG.SHOW_PLANTER_HUD ~= false, 3, function(v)
    CONFIG.SHOW_PLANTER_HUD = v
    if planterHudFrame then planterHudFrame.Visible = v end
    saveNow()
end)

section("📊 АКТИВНЫЕ ПЛАНТАТОРЫ НА КАРТЕ (ЖИВОЙ СТАТУС)", 4).Parent = PAGE_PLANTERS
local livePlantersCard = new("Frame", {
    Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y,
    BackgroundColor3 = C.card, BorderSizePixel = 0, LayoutOrder = 5,
    Parent = PAGE_PLANTERS,
})
round(livePlantersCard, 10)
stroke(livePlantersCard)
local livePlantersList = new("Frame", {
    Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y,
    BackgroundTransparency = 1, Parent = livePlantersCard,
})
new("UIListLayout", { SortOrder = Enum.SortOrder.LayoutOrder, Padding = UDim.new(0, 4), Parent = livePlantersList })
new("UIPadding", { PaddingTop = UDim.new(0, 8), PaddingBottom = UDim.new(0, 8), PaddingLeft = UDim.new(0, 10), PaddingRight = UDim.new(0, 10), Parent = livePlantersList })

local function updateLivePlantersGui(activeList)
    if not livePlantersList then return end
    livePlantersList:ClearAllChildren()
    new("UIListLayout", { SortOrder = Enum.SortOrder.LayoutOrder, Padding = UDim.new(0, 4), Parent = livePlantersList })
    new("UIPadding", { PaddingTop = UDim.new(0, 8), PaddingBottom = UDim.new(0, 8), PaddingLeft = UDim.new(0, 10), PaddingRight = UDim.new(0, 10), Parent = livePlantersList })

    if not activeList or #activeList == 0 then
        new("TextLabel", {
            Size = UDim2.new(1, 0, 0, 20), BackgroundTransparency = 1,
            Text = "Нет активных плантаторов на карте", TextColor3 = C.dim,
            Font = Enum.Font.Gotham, TextSize = 11, TextXAlignment = Enum.TextXAlignment.Left,
            Parent = livePlantersList,
        })
        return
    end

    for idx, info in ipairs(activeList) do
        local isReady = info.ready or (info.percent >= 100) or string.find(string.lower(info.statusStr), "0s", 1, true)
        local row = new("Frame", {
            Size = UDim2.new(1, 0, 0, 24), BackgroundTransparency = 1,
            LayoutOrder = idx, Parent = livePlantersList,
        })
        new("TextLabel", {
            Size = UDim2.new(1, 0, 1, 0), BackgroundTransparency = 1,
            Text = string.format("🪴 %s:  %s  ➔  %s", info.type, info.statusStr, info.field),
            TextColor3 = isReady and Color3.fromRGB(80, 240, 120) or C.text,
            Font = isReady and Enum.Font.GothamBold or Enum.Font.GothamMedium, TextSize = 11,
            TextXAlignment = Enum.TextXAlignment.Left, Parent = row,
        })
    end
end

section("⚙️ НАСТРОЙКИ ПОСАДКИ И СБОРА (14 ПЛАНТАТОРОВ)", 6).Parent = PAGE_PLANTERS

local planterInputFields = {}

for pIdx, pName in ipairs(ALL_PLANTER_TYPES) do
    if not CONFIG.PLANTERS_CONFIG then CONFIG.PLANTERS_CONFIG = {} end
    if not CONFIG.PLANTERS_CONFIG[pName] then
        CONFIG.PLANTERS_CONFIG[pName] = { enabled = false, field = "Sunflower Field", percent = 100 }
    end
    local cfg = CONFIG.PLANTERS_CONFIG[pName]

    local pCard = new("Frame", {
        Size = UDim2.new(1, 0, 0, 80), BackgroundColor3 = C.card,
        BorderSizePixel = 0, LayoutOrder = 10 + pIdx, Parent = PAGE_PLANTERS,
    })
    round(pCard, 10)
    stroke(pCard)

    local pTopRow = new("Frame", {
        Size = UDim2.new(1, 0, 0, 32), BackgroundTransparency = 1,
        Parent = pCard,
    })
    new("TextLabel", {
        Size = UDim2.new(1, -70, 1, 0), Position = UDim2.new(0, 12, 0, 0),
        BackgroundTransparency = 1, Text = "🪴 " .. pName,
        TextColor3 = C.accent, Font = Enum.Font.GothamBold, TextSize = 12,
        TextXAlignment = Enum.TextXAlignment.Left, Parent = pTopRow,
    })

    local swBack = new("Frame", {
        Size = UDim2.new(0, 44, 0, 22), Position = UDim2.new(1, -56, 0.5, -11),
        BackgroundColor3 = cfg.enabled and C.accent or C.field, BorderSizePixel = 0,
        Parent = pTopRow,
    })
    round(swBack, 11)
    local swKnob = new("Frame", {
        Size = UDim2.new(0, 18, 0, 18),
        Position = cfg.enabled and UDim2.new(1, -20, 0.5, -9) or UDim2.new(0, 2, 0.5, -9),
        BackgroundColor3 = Color3.fromRGB(255, 255, 255), BorderSizePixel = 0,
        Parent = swBack,
    })
    round(swKnob, 9)
    local swHit = new("TextButton", {
        Size = UDim2.new(1, 0, 1, 0), BackgroundTransparency = 1, Text = "",
        Parent = swBack,
    })
    swHit.MouseButton1Click:Connect(function()
        cfg.enabled = not cfg.enabled
        swBack.BackgroundColor3 = cfg.enabled and C.accent or C.field
        swKnob.Position = cfg.enabled and UDim2.new(1, -20, 0.5, -9) or UDim2.new(0, 2, 0.5, -9)
        saveNow()
    end)

    local pBottomRow = new("Frame", {
        Size = UDim2.new(1, -24, 0, 38), Position = UDim2.new(0, 12, 0, 34),
        BackgroundTransparency = 1, Parent = pCard,
    })
    new("UIListLayout", {
        FillDirection = Enum.FillDirection.Horizontal,
        Padding = UDim.new(0, 10), Parent = pBottomRow,
    })

    local fFieldBox = new("TextBox", {
        Size = UDim2.new(0.65, -5, 1, 0), BackgroundColor3 = C.field,
        Text = tostring(cfg.field or "Sunflower Field"),
        TextColor3 = C.text, Font = Enum.Font.GothamMedium, TextSize = 11,
        ClearTextOnFocus = false, BorderSizePixel = 0, Parent = pBottomRow,
    })
    round(fFieldBox, 6)
    stroke(fFieldBox)
    fFieldBox.FocusLost:Connect(function()
        cfg.field = fFieldBox.Text
        saveNow()
    end)

    local fPctBox = new("TextBox", {
        Size = UDim2.new(0.35, -5, 1, 0), BackgroundColor3 = C.field,
        Text = tostring(cfg.percent or 100),
        PlaceholderText = "% сбора (1-100)",
        TextColor3 = C.accent, Font = Enum.Font.GothamBold, TextSize = 11,
        ClearTextOnFocus = false, BorderSizePixel = 0, Parent = pBottomRow,
    })
    round(fPctBox, 6)
    stroke(fPctBox)
    fPctBox.FocusLost:Connect(function()
        local n = tonumber(fPctBox.Text)
        if n then
            cfg.percent = math.clamp(n, 1, 100)
            fPctBox.Text = tostring(cfg.percent)
        else
            cfg.percent = 100
            fPctBox.Text = "100"
        end
        saveNow()
    end)

    planterInputFields[pName] = { field = fFieldBox, pct = fPctBox, swBack = swBack, swKnob = swKnob }
end

makeBtn(PAGE_PLANTERS, "💾 Сохранить настройки плантаторов", function()
    saveNow()
    log("Плантаторы", "Настройки 14 плантаторов успешно сохранены!")
end, C.accent2, 35)

task.spawn(function()
    while true do
        if not alive() then return end
        pcall(function()
            local active = findMyActivePlanters()
            refreshPlanterHud(active)
            updateLivePlantersGui(active)
        end)
        task.wait(1.5)
    end
end)

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

do
    section("⚡ BURST-СБОР (ПРИ ВЗРЫВЕ РОСТКА)", 10).Parent = PAGE_SPROUTS

    makeToggle(PAGE_SPROUTS, "⚡ Включить Burst-сбор редкого лута", CONFIG.BURST_LOOT_ENABLED ~= false, 11, function(v)
        CONFIG.BURST_LOOT_ENABLED = v
        saveNow()
    end)

    local fBurstTime = makeField(PAGE_SPROUTS, "ДЛИТЕЛЬНОСТЬ BURST-СБОРА (СЕК)", CONFIG.BURST_LOOT_TIME or 7, "7", 12)
    fBurstTime.FocusLost:Connect(function()
        local n = tonumber(string.gsub(tostring(fBurstTime.Text), ",", "."))
        CONFIG.BURST_LOOT_TIME = (n and n > 0) and n or 7
        saveNow()
    end)

    section("🌐 ФИЛЬТР СЕРВЕРОВ (LOW PLAYER COUNT & BLACKLIST)", 20).Parent = PAGE_SPROUTS

    makeToggle(PAGE_SPROUTS, "👥 Искать серверы с малым числом игроков", CONFIG.PREFER_LOW_PLAYERS ~= false, 21, function(v)
        CONFIG.PREFER_LOW_PLAYERS = v
        saveNow()
    end)

    local fMaxP = makeField(PAGE_SPROUTS, "МАКС. ИГРОКОВ НА СЕРВЕРЕ (1-6)", CONFIG.MAX_PLAYERS or 5, "5", 22)
    fMaxP.FocusLost:Connect(function()
        local n = tonumber(fMaxP.Text)
        CONFIG.MAX_PLAYERS = (n and n >= 1 and n <= 10) and n or 5
        saveNow()
    end)

    section("🎯 ПРИОРИТЕТЫ ТОКЕНОВ СО СПРУТОВ", 30).Parent = PAGE_SPROUTS

    new("TextLabel", {
        Size = UDim2.new(1, 0, 0, 28), BackgroundTransparency = 1,
        Text = "Нажимайте на кнопку приоритета [P1 / P2 / P3 / ВЫКЛ] для каждого предмета.\nP1 = Топ лут (Burst), P2 = Средний, P3 = Низкий, ВЫКЛ = Пропуск. Автосохранение.",
        TextColor3 = C.dim, Font = Enum.Font.Gotham, TextSize = 9,
        TextWrapped = true, TextXAlignment = Enum.TextXAlignment.Left,
        LayoutOrder = 31, Parent = PAGE_SPROUTS,
    })

    local tokensContainer = new("Frame", {
        Size = UDim2.new(1, 0, 0, 0),
        AutomaticSize = Enum.AutomaticSize.Y,
        BackgroundTransparency = 1,
        LayoutOrder = 32,
        Parent = PAGE_SPROUTS,
    })
    new("UIListLayout", {
        SortOrder = Enum.SortOrder.LayoutOrder,
        Padding = UDim.new(0, 4),
        Parent = tokensContainer,
    })

    local prioLabels = {
        [1] = "[ P1: Топ ]",
        [2] = "[ P2: Средн ]",
        [3] = "[ P3: Низк ]",
        [0] = "[ ВЫКЛ ]",
    }
    local prioColors = {
        [1] = Color3.fromRGB(255, 215, 0),   -- Gold
        [2] = Color3.fromRGB(105, 190, 255), -- Cyan
        [3] = Color3.fromRGB(175, 180, 195), -- Dim
        [0] = Color3.fromRGB(255, 85, 85),   -- Red
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
            Size = UDim2.new(1, 0, 0, 28),
            BackgroundColor3 = C.card,
            BorderSizePixel = 0,
            LayoutOrder = idx,
            Parent = tokensContainer,
        })
        round(row, 6)

        new("TextLabel", {
            Size = UDim2.new(1, -95, 1, 0),
            Position = UDim2.new(0, 8, 0, 0),
            BackgroundTransparency = 1,
            Text = item.icon .. "  " .. item.name,
            TextColor3 = C.text,
            Font = Enum.Font.GothamSemibold,
            TextSize = 10,
            TextXAlignment = Enum.TextXAlignment.Left,
            TextYAlignment = Enum.TextYAlignment.Center,
            TextTruncate = Enum.TextTruncate.AtEnd,
            Parent = row,
        })

        local btn = new("TextButton", {
            Size = UDim2.new(0, 80, 0, 20),
            Position = UDim2.new(1, -85, 0.5, -10),
            BackgroundColor3 = prioBgColors[curPrio] or C.field,
            Text = prioLabels[curPrio] or "[ P" .. tostring(curPrio) .. " ]",
            TextColor3 = prioColors[curPrio] or C.text,
            Font = Enum.Font.GothamBold,
            TextSize = 9,
            BorderSizePixel = 0,
            AutoButtonColor = false,
            Parent = row,
        })
        round(btn, 4)
        stroke(btn, prioColors[curPrio] or C.dim, 1)

        btn.MouseButton1Click:Connect(function()
            local nowP = CONFIG.TOKEN_PRIORITIES[item.id]
            if nowP == nil then nowP = item.defaultPrio end
            local nextP
            if nowP == 1 then nextP = 2
            elseif nowP == 2 then nextP = 3
            elseif nowP == 3 then nextP = 0
            else nextP = 1 end

            CONFIG.TOKEN_PRIORITIES[item.id] = nextP
            btn.Text = prioLabels[nextP] or "[ P" .. tostring(nextP) .. " ]"
            btn.TextColor3 = prioColors[nextP] or C.text
            btn.BackgroundColor3 = prioBgColors[nextP] or C.field
            local st = btn:FindFirstChildOfClass("UIStroke")
            if st then st.Color = prioColors[nextP] or C.dim end
            saveNow()
        end)
    end
end

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
local fHop = makeField(pageSettings, "ЗАДЕРЖКА ХОПА (сек)", CONFIG.HOP_DELAY, "1.5", 21)
local fPoll = makeField(pageSettings, "ОПРОС БОТА (сек)", CONFIG.POLL_INTERVAL, "3", 22)
local fWait = makeField(pageSettings, "ЖДАТЬ СЛОМАННОГО СПРУТА (сек)", CONFIG.BROKEN_WAIT, "20", 23)
local fConn = makeField(pageSettings, "ТАЙМАУТ ПОДКЛЮЧЕНИЯ (сек)", CONFIG.CONNECT_TIMEOUT, "20", 24)
local fPlace = makeField(pageSettings, "PLACE ID", CONFIG.PLACE_ID, "1537690962", 25)

section("СКОРОСТЬ", 30).Parent = pageSettings
local fWalk = makeField(pageSettings, "МНОЖИТЕЛЬ БЕГА (x от 16)", CONFIG.WALK_SPEED_MULT, "2.4", 31)
local fFly = makeField(pageSettings, "СКОРОСТЬ ПОЛЁТА (studs/s)", CONFIG.FLY_SPEED, "100", 32)

section("ИНСТРУМЕНТЫ И УЛЕЙ", 40).Parent = pageSettings
local fSprinkler = makeField(pageSettings, "SPRINKLER KEYWORD", CONFIG.SPRINKLER_KEYWORD, "sprinkler", 41)
local fSprinklerCount = makeField(pageSettings, "КОЛИЧЕСТВО ПОЛИВАЛОК (1–4)", CONFIG.SPRINKLER_COUNT, "3", 42)
local getSprinkler = makeToggle(pageSettings, "Автоматически ставить поливалки", CONFIG.ENABLE_AUTO_SPRINKLER, 43, function(v)
    CONFIG.ENABLE_AUTO_SPRINKLER = v; if saveNow then pcall(saveNow) end
end)
local fRegion = makeField(pageSettings, "ЗОНА ФАРМА (center / left / right)", CONFIG.FARM_REGION, "center", 44)
local fDigTool = makeField(pageSettings, "DIG TOOL KEYWORD", CONFIG.DIG_TOOL_KEYWORD, "scooper", 45)
local fSlotKeyword = makeField(pageSettings, "EMPTY SLOT KEYWORD", CONFIG.EMPTY_SLOT_KEYWORD, "claim hive", 46)
local fHoneyKeyword = makeField(pageSettings, "MY HIVE KEYWORD", CONFIG.MY_HIVE_KEYWORD, "make honey", 47)

section("ОПЦИИ", 50).Parent = pageSettings
local getDebug = makeToggle(pageSettings, "Диагностика спрута в консоли",
    CONFIG.DEBUG_SPROUT, 52, function(v) CONFIG.DEBUG_SPROUT = v; if saveNow then pcall(saveNow) end end)
local getAuto = makeToggle(pageSettings, "Автозапуск после перезахода",
    CONFIG.AUTO_START, 53, function(v) CONFIG.AUTO_START = v; if saveNow then pcall(saveNow) end end)
local getAntiLag = makeToggle(pageSettings, "ANTI-LAG: снизить графику", CONFIG.ANTI_LAG, 54, function(v)
    applyAntiLag(v); if saveNow then pcall(saveNow) end
end)
local getSuperOpt = makeToggle(pageSettings, "⚡ УЛЬТРА-ОПТИМИЗАЦИЯ (FPS Boost & ОЗУ)", CONFIG.SUPER_OPTIMIZE, 55, function(v)
    CONFIG.SUPER_OPTIMIZE = v
    applySuperOptimization(v)
    if saveNow then pcall(saveNow) end
end)
local getAvoidFriends = makeToggle(pageSettings, "🛡️ АНТИ-ПАЛЕВО: избегать друзей", CONFIG.AVOID_FRIENDS, 56, function(v)
    CONFIG.AVOID_FRIENDS = v
    if saveNow then pcall(saveNow) end
end)

applySettings = function()
    local function num(v, def)
        if v == nil then return def end
        local str = string.gsub(tostring(v), ",", ".")
        local n = tonumber(str)
        return (n and n > 0) and n or def
    end
    CONFIG.SELF_TAG = (fTag.Text ~= "" and fTag.Text) or CONFIG.SELF_TAG
    CONFIG.API_URL = (fUrl.Text ~= "" and fUrl.Text) or CONFIG.API_URL
    if fKey.Text ~= "" then CONFIG.API_KEY = fKey.Text end
    CONFIG.VICIOUS_CHANNEL_ID = (fViciousChannel.Text ~= "" and fViciousChannel.Text) or CONFIG.VICIOUS_CHANNEL_ID
    CONFIG.HOP_DELAY = num(fHop.Text, CONFIG.HOP_DELAY or 1.5)
    CONFIG.POLL_INTERVAL = num(fPoll.Text, CONFIG.POLL_INTERVAL or 3)
    CONFIG.BROKEN_WAIT = num(fWait.Text, CONFIG.BROKEN_WAIT or 20)
    CONFIG.CONNECT_TIMEOUT = num(fConn.Text, CONFIG.CONNECT_TIMEOUT or 20)
    CONFIG.PLACE_ID = (fPlace.Text ~= "" and fPlace.Text) or CONFIG.PLACE_ID
    CONFIG.WALK_SPEED_MULT = num(fWalk.Text, CONFIG.WALK_SPEED_MULT or 2.4)
    CONFIG.FLY_SPEED = math.clamp(num(fFly.Text, CONFIG.FLY_SPEED or 100), 50, 150)
    CONFIG.SPRINKLER_KEYWORD = (fSprinkler.Text ~= "" and fSprinkler.Text) or CONFIG.SPRINKLER_KEYWORD
    CONFIG.SPRINKLER_COUNT = math.clamp(math.floor(num(fSprinklerCount.Text, CONFIG.SPRINKLER_COUNT or 3)), 1, 4)
    if getSprinkler then CONFIG.ENABLE_AUTO_SPRINKLER = getSprinkler() end
    local region = string.lower((fRegion.Text ~= "" and fRegion.Text) or CONFIG.FARM_REGION or "center")
    CONFIG.FARM_REGION = (region == "left" or region == "right") and region or "center"
    CONFIG.DIG_TOOL_KEYWORD = (fDigTool.Text ~= "" and fDigTool.Text) or CONFIG.DIG_TOOL_KEYWORD
    CONFIG.EMPTY_SLOT_KEYWORD = (fSlotKeyword.Text ~= "" and fSlotKeyword.Text) or CONFIG.EMPTY_SLOT_KEYWORD
    CONFIG.MY_HIVE_KEYWORD = (fHoneyKeyword.Text ~= "" and fHoneyKeyword.Text) or CONFIG.MY_HIVE_KEYWORD
    if getDebug then CONFIG.DEBUG_SPROUT = getDebug() end
    if getAuto then CONFIG.AUTO_START = getAuto() end
    if getAntiLag then
        CONFIG.ANTI_LAG = getAntiLag()
        applyAntiLag(CONFIG.ANTI_LAG)
    end
    if getSuperOpt then
        CONFIG.SUPER_OPTIMIZE = getSuperOpt()
        applySuperOptimization(CONFIG.SUPER_OPTIMIZE)
    end
    if getAvoidFriends then
        CONFIG.AVOID_FRIENDS = getAvoidFriends()
    end
    applyWalkSpeed()
    if saveNow then pcall(saveNow) end
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

section("ДИАПАЗОН УРОВНЕЙ ГРИБОВ ДЛЯ ФАРМА", 6).Parent = PAGE_PUFF
local puffLevelRow = new("Frame", {
    Size = UDim2.new(1, 0, 0, 48), BackgroundTransparency = 1,
    LayoutOrder = 7, Parent = PAGE_PUFF,
})
new("UIListLayout", {
    FillDirection = Enum.FillDirection.Horizontal,
    Padding = UDim.new(0, 10), Parent = puffLevelRow,
})
local fPuffMin = makeField(puffLevelRow, "ОТ УРОВНЯ (MIN)", CONFIG.PUFF_MIN_LEVEL or 1, "1", 1)
fPuffMin.Parent.Size = UDim2.new(0.5, -5, 1, 0)
fPuffMin.FocusLost:Connect(function()
    CONFIG.PUFF_MIN_LEVEL = tonumber(fPuffMin.Text) or 1
    saveNow()
end)
local fPuffMax = makeField(puffLevelRow, "ДО УРОВНЯ (MAX)", CONFIG.PUFF_MAX_LEVEL or 20, "20", 2)
fPuffMax.Parent.Size = UDim2.new(0.5, -5, 1, 0)
fPuffMax.FocusLost:Connect(function()
    CONFIG.PUFF_MAX_LEVEL = tonumber(fPuffMax.Text) or 20
    saveNow()
end)

section("⚡ ВЫБОР БУСТОВ ДЛЯ EPIC+ ГРИБОВ", 8).Parent = PAGE_PUFF
makeToggle(PAGE_PUFF, "Использовать бусты при спавне Epic/Legendary/Mythic", CONFIG.PUFF_AUTO_BOOST_EPIC ~= false, 9, function(v)
    CONFIG.PUFF_AUTO_BOOST_EPIC = v; saveNow()
end)

local boostDisplayNames = {
    ["Glitter"] = "✨ Glitter",
    ["Red Extract"] = "🔴 Red Extract",
    ["Blue Extract"] = "🔵 Blue Extract",
    ["Oil"] = "🛢️ Oil",
    ["Enzymes"] = "🧪 Enzymes",
    ["Glue"] = "🍯 Glue",
    ["Tropical Drink"] = "🍹 Tropical Drink",
    ["Purple Potion"] = "🟣 Purple Potion",
    ["Super Smoothie"] = "🥤 Super Smoothie",
}

for bIndex, bName in ipairs(BOOST_ITEM_NAMES) do
    local isChecked = (CONFIG.PUFF_SELECTED_BOOSTS and CONFIG.PUFF_SELECTED_BOOSTS[bName] ~= false)
    makeToggle(PAGE_PUFF, boostDisplayNames[bName] or bName, isChecked, 10 + bIndex, function(v)
        if not CONFIG.PUFF_SELECTED_BOOSTS then CONFIG.PUFF_SELECTED_BOOSTS = {} end
        CONFIG.PUFF_SELECTED_BOOSTS[bName] = v
        saveNow()
    end)
end

-- ══════════════════════════════════════════════════════════════════════
--  ПЕРЕКЛЮЧЕНИЕ РАЗДЕЛОВ
-- ══════════════════════════════════════════════════════════════════════
-- ══════════════════════════════════════════════════════════════════════
--  ВКЛАДКА КОНФИГУРАЦИЙ (PAGE_CONFIGS)
-- ══════════════════════════════════════════════════════════════════════
local PAGE_CONFIGS = new("Frame", {
    Size = UDim2.new(1, 0, 0, 0),
    AutomaticSize = Enum.AutomaticSize.Y,
    BackgroundTransparency = 1, Visible = false, Parent = content,
})
new("UIListLayout", {
    SortOrder = Enum.SortOrder.LayoutOrder, Padding = UDim.new(0, 8),
    Parent = PAGE_CONFIGS,
})

-- Баннер текущего состояния
local cfgHeaderBox = new("Frame", {
    Size = UDim2.new(1, 0, 0, 56), BackgroundColor3 = C.card,
    BorderSizePixel = 0, LayoutOrder = 1, Parent = PAGE_CONFIGS,
})
round(cfgHeaderBox, 12)
stroke(cfgHeaderBox)
new("TextLabel", {
    Size = UDim2.new(0, 36, 1, 0), Position = UDim2.new(0, 12, 0, 0),
    BackgroundTransparency = 1, Text = "📁", Font = Enum.Font.GothamBold,
    TextSize = 22, TextColor3 = C.accent, Parent = cfgHeaderBox,
})
local cfgHeaderTitle = new("TextLabel", {
    Size = UDim2.new(1, -60, 0, 22), Position = UDim2.new(0, 52, 0, 8),
    BackgroundTransparency = 1, Text = "Менеджер конфигураций и авто-профилей",
    TextColor3 = C.text, Font = Enum.Font.GothamBold, TextSize = 13,
    TextXAlignment = Enum.TextXAlignment.Left, Parent = cfgHeaderBox,
})
local cfgHeaderSub = new("TextLabel", {
    Size = UDim2.new(1, -60, 0, 18), Position = UDim2.new(0, 52, 0, 30),
    BackgroundTransparency = 1,
    Text = "Аккаунт: " .. tostring(player.Name) .. "  |  Активный конфиг: " .. tostring(currentActiveConfig or "default"),
    TextColor3 = C.dim, Font = Enum.Font.Gotham, TextSize = 11,
    TextXAlignment = Enum.TextXAlignment.Left, Parent = cfgHeaderBox,
})

-- Раздел 1: Сохранение и загрузка конфигов
section("СОХРАНЕНИЕ / ЗАГРУЗКА КОНФИГА", 10).Parent = PAGE_CONFIGS

local fCfgName = makeField(PAGE_CONFIGS, "ИМЯ КОНФИГА", currentActiveConfig or "gg", "например: gg или solo_farm", 11)

local cfgBtnRow = new("Frame", {
    Size = UDim2.new(1, 0, 0, 36), BackgroundTransparency = 1,
    LayoutOrder = 12, Parent = PAGE_CONFIGS,
})
new("UIListLayout", {
    FillDirection = Enum.FillDirection.Horizontal,
    Padding = UDim.new(0, 8), Parent = cfgBtnRow,
})

local cfgStatusLabel = new("TextLabel", {
    Size = UDim2.new(1, 0, 0, 24), BackgroundTransparency = 1,
    Text = "Готов к работе с конфигурациями", TextColor3 = C.dim,
    Font = Enum.Font.Gotham, TextSize = 11, TextXAlignment = Enum.TextXAlignment.Left,
    LayoutOrder = 13, Parent = PAGE_CONFIGS,
})

local cfgListContainer = new("Frame", {
    Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y,
    BackgroundTransparency = 1, LayoutOrder = 15, Parent = PAGE_CONFIGS,
})
new("UIListLayout", {
    FillDirection = Enum.FillDirection.Horizontal,
    Padding = UDim.new(0, 6), Parent = cfgListContainer,
})

local function refreshConfigButtons()
    for _, child in ipairs(cfgListContainer:GetChildren()) do
        if child:IsA("TextButton") then child:Destroy() end
    end
    local list = getSavedConfigList()
    for _, cfg in ipairs(list) do
        local b = new("TextButton", {
            Size = UDim2.new(0, math.max(65, #cfg * 9 + 20), 0, 28),
            BackgroundColor3 = (cfg == currentActiveConfig) and C.cardHi or C.field,
            Text = "📁 " .. cfg, TextColor3 = (cfg == currentActiveConfig) and C.accent or C.text,
            Font = Enum.Font.GothamBold, TextSize = 11,
            BorderSizePixel = 0, Parent = cfgListContainer,
        })
        round(b, 6)
        stroke(b, (cfg == currentActiveConfig) and C.accent2 or Color3.fromRGB(48,62,72))
        b.MouseButton1Click:Connect(function()
            fCfgName.Text = cfg
            cfgStatusLabel.Text = "Выбран конфиг: " .. cfg .. ". Нажмите 'Загрузить' или 'Сохранить'."
            cfgStatusLabel.TextColor3 = C.text
        end)
    end
    cfgHeaderSub.Text = "Аккаунт: " .. tostring(player.Name) .. "  |  Активный конфиг: " .. tostring(currentActiveConfig or "default")
end

makeBtn(cfgBtnRow, "💾 Сохранить", function()
    local name = (fCfgName.Text ~= "" and fCfgName.Text) or "default"
    applySettings()
    local ok, msg = saveNamedConfig(name)
    cfgStatusLabel.Text = msg
    cfgStatusLabel.TextColor3 = ok and C.accent or C.danger
    refreshConfigButtons()
end, C.accent2)

makeBtn(cfgBtnRow, "📂 Загрузить", function()
    local name = (fCfgName.Text ~= "" and fCfgName.Text) or "default"
    local ok, msg = loadNamedConfig(name)
    cfgStatusLabel.Text = msg
    cfgStatusLabel.TextColor3 = ok and C.accent or C.danger
    refreshConfigButtons()
end, Color3.fromRGB(45, 110, 200))

makeBtn(cfgBtnRow, "🗑️ Удалить", function()
    local name = (fCfgName.Text ~= "" and fCfgName.Text) or ""
    local ok, msg = deleteNamedConfig(name)
    cfgStatusLabel.Text = msg
    cfgStatusLabel.TextColor3 = ok and C.warn or C.danger
    refreshConfigButtons()
end, Color3.fromRGB(120, 45, 45))

section("СОХРАНЕННЫЕ КОНФИГИ (КЛИК ДЛЯ ВЫБОРА)", 14).Parent = PAGE_CONFIGS
refreshConfigButtons()

-- Раздел 2: Привязка ника к конфигу (Авто-инжект по нику)
section("ПРИВЯЗКА К НИКУ (АВТО-ИНЖЕКТ КОНФИГА)", 20).Parent = PAGE_CONFIGS

local nickInfoLabel = new("TextLabel", {
    Size = UDim2.new(1, 0, 0, 36), BackgroundColor3 = C.card,
    Text = "  Укажите ник игрока и конфиг (например 'gg'). При входе с этого аккаунта бот автоматически активирует именно этот конфиг!",
    TextColor3 = C.dim, Font = Enum.Font.Gotham, TextSize = 10,
    TextWrapped = true, TextXAlignment = Enum.TextXAlignment.Left,
    BorderSizePixel = 0, LayoutOrder = 21, Parent = PAGE_CONFIGS,
})
round(nickInfoLabel, 8)
stroke(nickInfoLabel)

local bindRow = new("Frame", {
    Size = UDim2.new(1, 0, 0, 60), BackgroundTransparency = 1,
    LayoutOrder = 22, Parent = PAGE_CONFIGS,
})
new("UIListLayout", {
    FillDirection = Enum.FillDirection.Horizontal,
    Padding = UDim.new(0, 8), Parent = bindRow,
})

local colNick = new("Frame", { Size = UDim2.new(0.5, -4, 1, 0), BackgroundTransparency = 1, Parent = bindRow })
local colCfg = new("Frame", { Size = UDim2.new(0.5, -4, 1, 0), BackgroundTransparency = 1, Parent = bindRow })

local fBindNick = makeField(colNick, "НИКНЕЙМ АККАУНТА", player.Name, "Имя аккаунта")
local fBindCfg = makeField(colCfg, "ИМЯ КОНФИГА", currentActiveConfig or "gg", "например: gg")

local bindBtnRow = new("Frame", {
    Size = UDim2.new(1, 0, 0, 34), BackgroundTransparency = 1,
    LayoutOrder = 23, Parent = PAGE_CONFIGS,
})
new("UIListLayout", { FillDirection = Enum.FillDirection.Horizontal, Padding = UDim.new(0, 8), Parent = bindBtnRow })

local bindsContainer = new("Frame", {
    Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y,
    BackgroundTransparency = 1, LayoutOrder = 25, Parent = PAGE_CONFIGS,
})
new("UIListLayout", {
    SortOrder = Enum.SortOrder.LayoutOrder, Padding = UDim.new(0, 4),
    Parent = bindsContainer,
})

local function refreshBindsList()
    for _, child in ipairs(bindsContainer:GetChildren()) do
        if child:IsA("Frame") then child:Destroy() end
    end
    local binds = loadNickBinds()
    local count = 0
    for nick, cfg in pairs(binds) do
        count += 1
        local item = new("Frame", {
            Size = UDim2.new(1, 0, 0, 32), BackgroundColor3 = C.card,
            BorderSizePixel = 0, Parent = bindsContainer,
        })
        round(item, 6)
        stroke(item)
        new("TextLabel", {
            Size = UDim2.new(1, -70, 1, 0), Position = UDim2.new(0, 10, 0, 0),
            BackgroundTransparency = 1,
            Text = string.format("👤 %s  ➔  📁 %s", nick, cfg),
            TextColor3 = (string.lower(nick) == string.lower(player.Name)) and C.accent or C.text,
            Font = Enum.Font.GothamMedium, TextSize = 11,
            TextXAlignment = Enum.TextXAlignment.Left, Parent = item,
        })
        local unbindBtn = new("TextButton", {
            Size = UDim2.new(0, 56, 0, 22), Position = UDim2.new(1, -62, 0.5, -11),
            BackgroundColor3 = Color3.fromRGB(100, 40, 40), Text = "Отвязать",
            TextColor3 = C.text, Font = Enum.Font.GothamBold, TextSize = 9,
            BorderSizePixel = 0, Parent = item,
        })
        round(unbindBtn, 4)
        unbindBtn.MouseButton1Click:Connect(function()
            unbindNick(nick)
            refreshBindsList()
        end)
    end
    if count == 0 then
        local empty = new("Frame", {
            Size = UDim2.new(1, 0, 0, 26), BackgroundTransparency = 1,
            Parent = bindsContainer,
        })
        new("TextLabel", {
            Size = UDim2.new(1, 0, 1, 0), BackgroundTransparency = 1,
            Text = "Нет активных привязок к никам", TextColor3 = C.dim,
            Font = Enum.Font.Gotham, TextSize = 10, Parent = empty,
        })
    end
end

makeBtn(bindBtnRow, "🔗 Привязать ник к конфигу", function()
    local n = fBindNick.Text
    local c = fBindCfg.Text
    local ok, msg = bindNickToConfig(n, c)
    cfgStatusLabel.Text = msg
    cfgStatusLabel.TextColor3 = ok and C.accent or C.danger
    refreshBindsList()
end, C.accent2)

section("АКТИВНЫЕ ПРИВЯЗКИ НИКОВ", 24).Parent = PAGE_CONFIGS
refreshBindsList()

syncGuiWithConfig = function()
    pcall(function()
        if fTag and CONFIG.SELF_TAG ~= nil then fTag.Text = tostring(CONFIG.SELF_TAG) end
        if fUrl and CONFIG.API_URL ~= nil then fUrl.Text = tostring(CONFIG.API_URL) end
        if fKey and CONFIG.API_KEY ~= nil then fKey.Text = tostring(CONFIG.API_KEY) end
        if fViciousChannel and CONFIG.VICIOUS_CHANNEL_ID ~= nil then fViciousChannel.Text = tostring(CONFIG.VICIOUS_CHANNEL_ID) end
        if fHop and CONFIG.HOP_DELAY ~= nil then fHop.Text = tostring(CONFIG.HOP_DELAY) end
        if fPoll and CONFIG.POLL_INTERVAL ~= nil then fPoll.Text = tostring(CONFIG.POLL_INTERVAL) end
        if fWait and CONFIG.BROKEN_WAIT ~= nil then fWait.Text = tostring(CONFIG.BROKEN_WAIT) end
        if fConn and CONFIG.CONNECT_TIMEOUT ~= nil then fConn.Text = tostring(CONFIG.CONNECT_TIMEOUT) end
        if fPlace and CONFIG.PLACE_ID ~= nil then fPlace.Text = tostring(CONFIG.PLACE_ID) end
        if fWalk and CONFIG.WALK_SPEED_MULT ~= nil then fWalk.Text = tostring(CONFIG.WALK_SPEED_MULT) end
        if fFly and CONFIG.FLY_SPEED ~= nil then fFly.Text = tostring(CONFIG.FLY_SPEED) end
        if fSprinkler and CONFIG.SPRINKLER_KEYWORD ~= nil then fSprinkler.Text = tostring(CONFIG.SPRINKLER_KEYWORD) end
        if fSprinklerCount and CONFIG.SPRINKLER_COUNT ~= nil then fSprinklerCount.Text = tostring(CONFIG.SPRINKLER_COUNT) end
        if fRegion and CONFIG.FARM_REGION ~= nil then fRegion.Text = tostring(CONFIG.FARM_REGION) end
        if fDigTool and CONFIG.DIG_TOOL_KEYWORD ~= nil then fDigTool.Text = tostring(CONFIG.DIG_TOOL_KEYWORD) end
        if fSlotKeyword and CONFIG.EMPTY_SLOT_KEYWORD ~= nil then fSlotKeyword.Text = tostring(CONFIG.EMPTY_SLOT_KEYWORD) end
        if fHoneyKeyword and CONFIG.MY_HIVE_KEYWORD ~= nil then fHoneyKeyword.Text = tostring(CONFIG.MY_HIVE_KEYWORD) end
        if fCfgName then fCfgName.Text = tostring(currentActiveConfig or "default") end
        if paintSproutRarity then paintSproutRarity() end
        if paintPuffRarity then paintPuffRarity() end
        if saveViciousRange then saveViciousRange() end
        if applyWalkSpeed then applyWalkSpeed() end
        if applyAntiLag then applyAntiLag(CONFIG.ANTI_LAG) end
        if applySuperOptimization then applySuperOptimization(CONFIG.SUPER_OPTIMIZE) end
        if fDisc and CONFIG.DISCORD_WEBHOOK_URL ~= nil then fDisc.Text = tostring(CONFIG.DISCORD_WEBHOOK_URL) end
        if fTgToken and CONFIG.TELEGRAM_BOT_TOKEN ~= nil then fTgToken.Text = tostring(CONFIG.TELEGRAM_BOT_TOKEN) end
        if fTgChat and CONFIG.TELEGRAM_CHAT_ID ~= nil then fTgChat.Text = tostring(CONFIG.TELEGRAM_CHAT_ID) end
        if fPuffMin and CONFIG.PUFF_MIN_LEVEL ~= nil then fPuffMin.Text = tostring(CONFIG.PUFF_MIN_LEVEL) end
        if fPuffMax and CONFIG.PUFF_MAX_LEVEL ~= nil then fPuffMax.Text = tostring(CONFIG.PUFF_MAX_LEVEL) end
        if planterInputFields and CONFIG.PLANTERS_CONFIG then
            for pName, pInputs in pairs(planterInputFields) do
                local pCfg = CONFIG.PLANTERS_CONFIG[pName]
                if pCfg then
                    if pInputs.field then pInputs.field.Text = tostring(pCfg.field or "Sunflower Field") end
                    if pInputs.pct then pInputs.pct.Text = tostring(pCfg.percent or 100) end
                    if pInputs.swBack and pInputs.swKnob then
                        pInputs.swBack.BackgroundColor3 = pCfg.enabled and C.accent or C.field
                        pInputs.swKnob.Position = pCfg.enabled and UDim2.new(1, -20, 0.5, -9) or UDim2.new(0, 2, 0.5, -9)
                    end
                end
            end
        end
        if refreshConfigButtons then refreshConfigButtons() end
        if refreshBindsList then refreshBindsList() end
    end)
end

local pages = {
    main = PAGE_HOME,
    sprouts = PAGE_SPROUTS,
    settings = pageSettings,
    configs = PAGE_CONFIGS,
    vicious = PAGE_VICIOUS,
    puffshrooms = PAGE_PUFF,
    windy_meteors = PAGE_WINDY,
    webhooks = PAGE_WEBHOOKS,
    planters = PAGE_PLANTERS,
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
    if (Vector2.new(input.Position.X, input.Position.Y) - center).Magnitude <= radius then openMenu() end
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