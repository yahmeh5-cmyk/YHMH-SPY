-- YHMH SPY v2.0 — Loader
-- 8 modulos: gui, remotes, mapper, export, economy, npc, args
-- loadstring(game:HttpGet("https://raw.githubusercontent.com/yahmeh5-cmyk/YHMH-SPY/main/spy_loader.lua"))()

repeat task.wait() until game:IsLoaded() and game:GetService("Players").LocalPlayer

local BASE = "https://raw.githubusercontent.com/yahmeh5-cmyk/YHMH-SPY/main/"

if not getgenv then
    getgenv = function() return _G end
end

getgenv().SPY = {
    lp = game:GetService("Players").LocalPlayer,
    remotes = {},
    remoteCounts = {},
    mapData = {},
    currencies = {},
    econRemotes = {},
    paused = false,
    filter = "",
    maxLog = 500,
    output = {},
    ON = {},
}

local function load(name)
    local url = BASE .. name
    print("[SPY] Baixando: " .. name)
    local ok, err = pcall(function()
        local code = game:HttpGet(url)
        local dashPos = code:find("%-%-")
        if dashPos and dashPos > 1 then
            code = code:sub(dashPos)
        end
        local fn, compileErr = loadstring(code)
        if fn then
            fn()
            print("[SPY] OK: " .. name)
        else
            warn("[SPY] COMPILE ERROR " .. name .. ": " .. tostring(compileErr))
        end
    end)
    if not ok then
        warn("[SPY] DOWNLOAD ERROR " .. name .. ": " .. tostring(err))
    end
    task.wait(0.3)
end

print("[SPY] ============================")
print("[SPY] YHMH SPY v2.0")
print("[SPY] 8 modules loading...")
print("[SPY] ============================")

-- Modulos originais
load("spy_gui.lua")
load("spy_remotes.lua")
load("spy_mapper.lua")
load("spy_export.lua")

-- Novos modulos v2
load("spy_economy.lua")
load("spy_npc.lua")
load("spy_args.lua")

print("[SPY] ============================")
print("[SPY] YHMH SPY v2.0 LOADED!")
print("[SPY] 8 modules | Toque SP")
print("[SPY] ============================")
