-- YHMH SPY - Remote Capture Stable
-- Substitua o conteudo de spy_remotes.lua por este arquivo.
-- Diagnostico local: nao bloqueia, nao reenvia e nao escuta OnClientEvent.

local env = (getgenv and getgenv()) or _G
local SPY = env.SPY
if not SPY then
    warn("[YHMH SPY] SPY nao inicializado")
    return
end

-- Evita instalar o hook duas vezes se o loader for executado novamente.
if SPY.remoteCaptureInstalled then
    warn("[YHMH SPY] capturador ja instalado")
    return
end
SPY.remoteCaptureInstalled = true

local Players = game:GetService("Players")
local player = SPY.lp or Players.LocalPlayer
local startedAt = os.clock()

SPY.remotes = SPY.remotes or {}
SPY.remoteCounts = SPY.remoteCounts or {}
SPY.output = SPY.output or {}
SPY.maxLog = math.clamp(tonumber(SPY.maxLog) or 300, 50, 1000)
SPY.paused = false
SPY.filter = tostring(SPY.filter or "")
SPY.uiQueue = SPY.uiQueue or {}

local function getType(value)
    local ok, result = pcall(typeof, value)
    return ok and result or type(value)
end

local function quote(value)
    return tostring(value)
        :gsub("\\", "\\\\")
        :gsub("\r", "\\r")
        :gsub("\n", "\\n")
        :gsub("\t", "\\t")
        :gsub("\"", "\\\"")
end

local function describe(value, depth, seen)
    depth = depth or 0
    seen = seen or {}
    if depth > 3 then return "..." end
    if value == nil then return "nil" end

    local kind = getType(value)
    if kind == "string" then
        local text = quote(value)
        if #text > 100 then text = text:sub(1, 100) .. "..." end
        return '"' .. text .. '"'
    elseif kind == "number" or kind == "boolean" then
        return tostring(value)
    elseif kind == "Vector3" then
        return string.format("Vector3(%.2f, %.2f, %.2f)", value.X, value.Y, value.Z)
    elseif kind == "Vector2" then
        return string.format("Vector2(%.2f, %.2f)", value.X, value.Y)
    elseif kind == "CFrame" then
        return string.format("CFrame(%.2f, %.2f, %.2f)", value.X, value.Y, value.Z)
    elseif kind == "Color3" then
        return string.format("Color3(%.2f, %.2f, %.2f)", value.R, value.G, value.B)
    elseif kind == "EnumItem" or kind == "UDim2" then
        return tostring(value)
    elseif kind == "Instance" then
        local className, path = "?", "?"
        pcall(function() className = value.ClassName end)
        pcall(function() path = value:GetFullName() end)
        return "Instance<" .. className .. ": " .. path .. ">"
    elseif kind == "table" then
        if seen[value] then return "<cycle>" end
        seen[value] = true
        local parts, count = {}, 0
        for key, item in pairs(value) do
            count = count + 1
            if count > 12 then
                parts[#parts + 1] = "..."
                break
            end
            local keyText = type(key) == "string" and '["' .. quote(key) .. '"]' or "[" .. tostring(key) .. "]"
            parts[#parts + 1] = keyText .. "=" .. describe(item, depth + 1, seen)
        end
        seen[value] = nil
        return "{" .. table.concat(parts, ", ") .. "}"
    end
    return kind .. "(" .. tostring(value) .. ")"
end

local function serializeArgs(args)
    local parts = {}
    for index, value in ipairs(args) do
        parts[index] = describe(value)
    end
    return table.concat(parts, ", ")
end

local function remoteInfo(remote)
    local name, path = "?", "?"
    pcall(function() name = remote.Name end)
    pcall(function() path = remote:GetFullName() end)
    return name, path
end

local function matchesFilter(name, path)
    local filter = tostring(SPY.filter or ""):lower()
    if filter == "" then return true end
    return name:lower():find(filter, 1, true) ~= nil
        or path:lower():find(filter, 1, true) ~= nil
end

local function trim(list, limit)
    while #list > limit do
        table.remove(list, 1)
    end
end

local function record(remote, method, args, result, hasResult)
    if SPY.paused then return end

    local name, path = remoteInfo(remote)
    if not matchesFilter(name, path) then return end

    local argsText = serializeArgs(args)
    local timestamp = string.format("%.2f", os.clock() - startedAt)
    local entry = {
        time = timestamp,
        method = method,
        name = name,
        path = path,
        args = argsText,
        rawArgs = table.pack(table.unpack(args)),
    }

    if hasResult then
        entry.result = result
        entry.resultText = describe(result)
    end

    table.insert(SPY.remotes, 1, entry)
    trim(SPY.remotes, SPY.maxLog)
    SPY.remoteCounts[name] = (SPY.remoteCounts[name] or 0) + 1

    local line = timestamp .. " " .. method .. " -> " .. name .. "(" .. argsText .. ") PATH:" .. path
    if entry.resultText then line = line .. " RETURN:" .. entry.resultText end
    table.insert(SPY.output, line)
    trim(SPY.output, SPY.maxLog * 2)

    -- A GUI nao e atualizada a cada chamada. Isso evita congelamentos em remotes de alta frequencia.
    SPY.uiQueue[#SPY.uiQueue + 1] = entry
    if #SPY.uiQueue > 20 then table.remove(SPY.uiQueue, 1) end
end

-- Hook unico e protegido. A chamada original sempre continua.
pcall(function()
    local hookMeta = hookmetamethod
    local getMethod = getnamecallmethod
    local wrap = newcclosure or function(fn) return fn end

    if not hookMeta or not getMethod then
        warn("[YHMH SPY] executor sem hookmetamethod/getnamecallmethod")
        SPY.remoteCaptureInstalled = false
        return
    end

    local previous
    previous = hookMeta(game, "__namecall", wrap(function(self, ...)
        local method = getMethod()
        local isRemote = false

        pcall(function()
            isRemote = typeof(self) == "Instance"
                and (self:IsA("RemoteEvent") or self:IsA("RemoteFunction"))
        end)

        if not isRemote or (method ~= "FireServer" and method ~= "InvokeServer") then
            return previous(self, ...)
        end

        local args = {...}

        if method == "InvokeServer" then
            -- O retorno e preservado exatamente como veio do servidor.
            local results = table.pack(previous(self, ...))
            task.defer(function()
                pcall(function() record(self, method, args, results[1], true) end)
            end)
            return table.unpack(results, 1, results.n)
        end

        task.defer(function()
            pcall(function() record(self, method, args, nil, false) end)
        end)
        return previous(self, ...)
    end))

    print("[YHMH SPY] hook de saida ativo")
end)

-- Atualiza a GUI no maximo 8 vezes por segundo, em lotes pequenos.
task.spawn(function()
    while SPY.remoteCaptureInstalled do
        task.wait(0.125)
        local batch = SPY.uiQueue
        SPY.uiQueue = {}

        if SPY.addRemoteEntry then
            for index = 1, math.min(#batch, 8) do
                pcall(function() SPY.addRemoteEntry(batch[index]) end)
            end
        end
    end
end)

-- Controles simples, sem listeners de OnClientEvent.
local tab = SPY.tabs and SPY.tabs["Remotes"]
if tab then
    local controls = Instance.new("Frame")
    controls.Name = "StableRemoteControls"
    controls.Size = UDim2.new(1, 0, 0, 38)
    controls.BackgroundTransparency = 1
    controls.Parent = tab

    local pause = Instance.new("TextButton")
    pause.Size = UDim2.new(0.3, -2, 0, 32)
    pause.BackgroundColor3 = Color3.fromRGB(30, 80, 30)
    pause.Text = "Pause"
    pause.TextColor3 = Color3.new(1, 1, 1)
    pause.Font = Enum.Font.SourceSansBold
    pause.TextSize = 12
    pause.BorderSizePixel = 0
    pause.Parent = controls
    pause.MouseButton1Click:Connect(function()
        SPY.paused = not SPY.paused
        pause.Text = SPY.paused and "Resume" or "Pause"
    end)

    local clear = Instance.new("TextButton")
    clear.Size = UDim2.new(0.3, -2, 0, 32)
    clear.Position = UDim2.new(0.32, 0, 0, 0)
    clear.BackgroundColor3 = Color3.fromRGB(120, 25, 25)
    clear.Text = "Clear"
    clear.TextColor3 = Color3.new(1, 1, 1)
    clear.Font = Enum.Font.SourceSansBold
    clear.TextSize = 12
    clear.BorderSizePixel = 0
    clear.Parent = controls
    clear.MouseButton1Click:Connect(function()
        SPY.remotes = {}
        SPY.remoteCounts = {}
        SPY.output = {}
        SPY.uiQueue = {}
    end)

    local filter = Instance.new("TextBox")
    filter.Size = UDim2.new(0.36, -2, 0, 32)
    filter.Position = UDim2.new(0.64, 0, 0, 0)
    filter.BackgroundColor3 = Color3.fromRGB(15, 15, 30)
    filter.PlaceholderText = "Filter name/path..."
    filter.Text = SPY.filter
    filter.TextColor3 = Color3.fromRGB(255, 200, 100)
    filter.Font = Enum.Font.Code
    filter.TextSize = 11
    filter.ClearTextOnFocus = false
    filter.BorderSizePixel = 0
    filter.Parent = controls
    filter.FocusLost:Connect(function()
        SPY.filter = filter.Text or ""
    end)
end

print("[YHMH SPY] capturador estavel pronto")
