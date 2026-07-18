-- YHMH SPY — Loader
-- Execute com:
-- loadstring(game:HttpGet("https://github.com/yahmeh5-cmyk/YHMH-SPY/new/main"))()

repeat task.wait() until game:IsLoaded() and game:GetService("Players").LocalPlayer

local BASE = "https://raw.githubusercontent.com/yahmeh5-cmyk/YHMHHUB/main/"

if not getgenv then
    getgenv = function() return _G end
end

getgenv().SPY = {
    lp = game:GetService("Players").LocalPlayer,
    remotes = {},
    remoteCounts = {},
    mapData = {},
    paused = false,
    filter = "",
    maxLog = 500,
    output = {},
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
print("[SPY] YHMH SPY v1.0")
print("[SPY] ============================")

load("spy_gui.lua")
load("spy_remotes.lua")
load("spy_mapper.lua")
load("spy_export.lua")

print("[SPY] ============================")
print("[SPY] Spy carregado! Toque SP")
print("[SPY] ============================")
