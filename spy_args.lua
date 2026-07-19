-- YHMH SPY — Args Capture + Code Generator
-- Gera codigo Lua copiavel para replay de cada remote
local SPY = getgenv().SPY
local lp = SPY.lp
local RS = game:GetService("ReplicatedStorage")

local expTab = SPY.tabs["Export"]

-- ══════════════════════════════════
-- CODE GENERATOR: converte arg para codigo Lua valido
-- ══════════════════════════════════
local function argToCode(v, depth)
    depth = depth or 0
    if depth > 3 then return '"..."' end
    local t = typeof(v)
    if v == nil then return "nil"
    elseif t == "string" then
        return '"' .. v:gsub('\\', '\\\\'):gsub('"', '\\"'):gsub('\n', '\\n') .. '"'
    elseif t == "number" then return tostring(v)
    elseif t == "boolean" then return tostring(v)
    elseif t == "Instance" then
        local ok, path = pcall(function() return v:GetFullName() end)
        if ok then
            -- Gerar código para encontrar a instância
            local parts = {}
            for part in path:gmatch("[^%.]+") do
                table.insert(parts, part)
            end
            if #parts > 0 and parts[1] == "Workspace" then
                return 'game:GetService("Workspace")' .. path:sub(10):gsub("([^%.]+)", function(s) return ':FindFirstChild("' .. s .. '")' end):gsub("^:FindFirstChild", "")
            elseif #parts > 0 and parts[1] == "ReplicatedStorage" then
                return 'game:GetService("ReplicatedStorage")' .. path:sub(18):gsub("([^%.]+)", function(s) return ':FindFirstChild("' .. s .. '")' end):gsub("^:FindFirstChild", "")
            else
                return 'game:FindFirstChild("' .. path .. '", true)'
            end
        end
        return "nil --[[ Instance not found ]]"
    elseif t == "Vector3" then
        return string.format("Vector3.new(%.4f, %.4f, %.4f)", v.X, v.Y, v.Z)
    elseif t == "Vector2" then
        return string.format("Vector2.new(%.4f, %.4f)", v.X, v.Y)
    elseif t == "CFrame" then
        local c = {v:GetComponents()}
        local parts = {}
        for _, comp in ipairs(c) do
            table.insert(parts, string.format("%.4f", comp))
        end
        return "CFrame.new(" .. table.concat(parts, ", ") .. ")"
    elseif t == "Color3" then
        return string.format("Color3.new(%.4f, %.4f, %.4f)", v.R, v.G, v.B)
    elseif t == "UDim2" then
        return string.format("UDim2.new(%.4f, %d, %.4f, %d)", v.X.Scale, v.X.Offset, v.Y.Scale, v.Y.Offset)
    elseif t == "EnumItem" then
        return tostring(v)
    elseif t == "table" then
        local parts = {}
        local isArray = true
        local count = 0
        for k, _ in pairs(v) do
            count = count + 1
            if type(k) ~= "number" or k ~= count then isArray = false end
        end
        if isArray then
            for i, val in ipairs(v) do
                if i > 15 then table.insert(parts, "-- ...more") break end
                table.insert(parts, argToCode(val, depth + 1))
            end
        else
            local c = 0
            for k, val in pairs(v) do
                c = c + 1
                if c > 15 then table.insert(parts, "-- ...more") break end
                local keyStr = type(k) == "string" and ("[" .. '"' .. k .. '"' .. "]") or ("[" .. tostring(k) .. "]")
                table.insert(parts, keyStr .. " = " .. argToCode(val, depth + 1))
            end
        end
        return "{" .. table.concat(parts, ", ") .. "}"
    else
        return '"' .. tostring(v) .. '" --[[ ' .. t .. ' ]]'
    end
end

-- Gerar codigo completo para replay de um remote
local function genReplayCode(entry)
    local lines = {}
    table.insert(lines, "-- Replay: " .. entry.name .. " (" .. entry.method .. ")")
    table.insert(lines, "-- Captured at: " .. entry.time .. "s")
    table.insert(lines, 'local remote = game:GetService("ReplicatedStorage"):FindFirstChild("' .. entry.name .. '", true)')
    table.insert(lines, "if remote then")

    if entry.rawArgs and #entry.rawArgs > 0 then
        local argCodes = {}
        for i, arg in ipairs(entry.rawArgs) do
            argCodes[i] = argToCode(arg)
        end
        if entry.method == "FireServer" then
            table.insert(lines, "    remote:FireServer(" .. table.concat(argCodes, ", ") .. ")")
        else
            table.insert(lines, "    local result = remote:InvokeServer(" .. table.concat(argCodes, ", ") .. ")")
            table.insert(lines, "    print('Result:', result)")
        end
    else
        if entry.method == "FireServer" then
            table.insert(lines, "    remote:FireServer()")
        else
            table.insert(lines, "    local result = remote:InvokeServer()")
            table.insert(lines, "    print('Result:', result)")
        end
    end

    table.insert(lines, "else")
    table.insert(lines, '    warn("Remote not found: ' .. entry.name .. '")')
    table.insert(lines, "end")
    return table.concat(lines, "\n")
end

-- ══════════════════════════════════
-- BUTTONS
-- ══════════════════════════════════
SPY.addHeader("Export", "CODE GENERATOR")

SPY.addButton("Export", "Copy Last Remote", Color3.fromRGB(30, 120, 60), function()
    if #SPY.remotes == 0 then
        SPY.addLine("Export", "No remotes captured yet", Color3.fromRGB(255, 100, 100))
        return
    end
    local last = SPY.remotes[1]
    local code = genReplayCode(last)
    local ok = false
    pcall(function() if setclipboard then setclipboard(code) ok = true end end)
    pcall(function() if not ok and toclipboard then toclipboard(code) ok = true end end)
    if ok then
        SPY.addLine("Export", "Last remote code COPIED!", Color3.fromRGB(100, 255, 100))
        SPY.addLine("Export", "  " .. last.method .. " -> " .. last.name, Color3.fromRGB(150, 255, 150))
    else
        SPY.addLine("Export", code, Color3.fromRGB(150, 255, 150))
    end
    print("[ARGS] Last remote code:")
    print(code)
end)

SPY.addButton("Export", "Copy All as Script", Color3.fromRGB(30, 60, 120), function()
    if #SPY.remotes == 0 then
        SPY.addLine("Export", "No remotes captured", Color3.fromRGB(255, 100, 100))
        return
    end
    local lines = {
        "-- YHMH SPY — Generated Script",
        "-- All captured remotes as replayable code",
        '-- Game: ' .. tostring(game.PlaceId),
        '-- Generated: ' .. os.date("%Y-%m-%d %H:%M:%S"),
        "",
        'local RS = game:GetService("ReplicatedStorage")',
        "",
    }
    -- Coletar remotes unicos
    local seen = {}
    for _, entry in ipairs(SPY.remotes) do
        local key = entry.name .. "_" .. entry.args
        if not seen[key] then
            seen[key] = true
            table.insert(lines, "-- " .. entry.time .. "s | " .. entry.method .. " -> " .. entry.name)
            table.insert(lines, genReplayCode(entry))
            table.insert(lines, "")
        end
    end
    local script = table.concat(lines, "\n")
    local ok = false
    pcall(function() if setclipboard then setclipboard(script) ok = true end end)
    pcall(function() if not ok and toclipboard then toclipboard(script) ok = true end end)
    if ok then
        SPY.addLine("Export", "Full script COPIED! (" .. #script .. " chars, " .. #seen .. " unique remotes)", Color3.fromRGB(100, 255, 100))
    else
        print(script)
        SPY.addLine("Export", "Printed to console (clipboard unavailable)", Color3.fromRGB(255, 200, 100))
    end
end)

SPY.addButton("Export", "Replay Last", Color3.fromRGB(180, 80, 20), function()
    if #SPY.remotes == 0 then
        SPY.addLine("Export", "No remotes to replay", Color3.fromRGB(255, 100, 100))
        return
    end
    local last = SPY.remotes[1]
    local ok = pcall(function()
        local remote = last.remote or RS:FindFirstChild(last.name, true)
        if remote then
            if last.rawArgs and #last.rawArgs > 0 then
                if last.method == "FireServer" then
                    remote:FireServer(unpack(last.rawArgs))
                else
                    local result = remote:InvokeServer(unpack(last.rawArgs))
                    SPY.addLine("Export", "  Result: " .. tostring(result), Color3.fromRGB(200, 200, 255))
                end
            else
                if last.method == "FireServer" then
                    remote:FireServer()
                else
                    local result = remote:InvokeServer()
                    SPY.addLine("Export", "  Result: " .. tostring(result), Color3.fromRGB(200, 200, 255))
                end
            end
            SPY.addLine("Export", "Replayed: " .. last.name, Color3.fromRGB(100, 255, 100))
        else
            SPY.addLine("Export", "Remote not found: " .. last.name, Color3.fromRGB(255, 100, 100))
        end
    end)
    if not ok then
        SPY.addLine("Export", "Replay failed", Color3.fromRGB(255, 80, 80))
    end
end)

SPY.addButton("Export", "Replay ALL (x1)", Color3.fromRGB(200, 40, 20), function()
    if #SPY.remotes == 0 then
        SPY.addLine("Export", "No remotes to replay", Color3.fromRGB(255, 100, 100))
        return
    end
    SPY.addLine("Export", "Replaying " .. #SPY.remotes .. " remotes...", Color3.fromRGB(255, 200, 100))
    task.spawn(function()
        local ok, fail = 0, 0
        for i = #SPY.remotes, 1, -1 do
            local entry = SPY.remotes[i]
            local success = pcall(function()
                local remote = entry.remote or RS:FindFirstChild(entry.name, true)
                if remote then
                    if entry.rawArgs and #entry.rawArgs > 0 then
                        if entry.method == "FireServer" then
                            remote:FireServer(unpack(entry.rawArgs))
                        else
                            remote:InvokeServer(unpack(entry.rawArgs))
                        end
                    else
                        if entry.method == "FireServer" then
                            remote:FireServer()
                        else
                            remote:InvokeServer()
                        end
                    end
                end
            end)
            if success then ok = ok + 1 else fail = fail + 1 end
            task.wait(0.1)
        end
        SPY.addLine("Export", "Replay done: " .. ok .. " OK, " .. fail .. " failed", Color3.fromRGB(100, 255, 100))
    end)
end)

-- ══════════════════════════════════
-- REMOTE HISTORY (mostra ultimos com codigo)
-- ══════════════════════════════════
SPY.addHeader("Export", "REMOTE HISTORY")

SPY.addButton("Export", "Show History", Color3.fromRGB(60, 40, 80), function()
    SPY.addLine("Export", "", nil)
    SPY.addLine("Export", "--- LAST 20 REMOTES ---", Color3.fromRGB(200, 180, 255))
    for i = 1, math.min(20, #SPY.remotes) do
        local e = SPY.remotes[i]
        local col = e.method == "FireServer" and Color3.fromRGB(80, 220, 120) or Color3.fromRGB(120, 160, 255)
        SPY.addLine("Export", e.time .. " " .. e.method .. " " .. e.name .. "(" .. e.args:sub(1, 80) .. ")", col)
    end
    if #SPY.remotes == 0 then
        SPY.addLine("Export", "No remotes captured. Play the game!", Color3.fromRGB(150, 150, 150))
    end
end)

SPY.addButton("Export", "Remote Stats", Color3.fromRGB(40, 60, 80), function()
    SPY.addLine("Export", "", nil)
    SPY.addLine("Export", "--- REMOTE FIRE COUNTS ---", Color3.fromRGB(200, 180, 255))
    local sorted = {}
    for name, count in pairs(SPY.remoteCounts) do
        table.insert(sorted, {name = name, count = count})
    end
    table.sort(sorted, function(a, b) return a.count > b.count end)
    for _, e in ipairs(sorted) do
        SPY.addLine("Export", "  " .. e.name .. " : " .. e.count .. "x", Color3.fromRGB(255, 180, 100))
    end
    if #sorted == 0 then
        SPY.addLine("Export", "  No data yet", Color3.fromRGB(150, 150, 150))
    end
end)

print("[SPY ARGS] OK")
