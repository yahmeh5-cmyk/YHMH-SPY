-- YHMH SPY - Remote Capture (diagnostic-only)
-- Arquivo completo corrigido para substituir spy_remotes.lua.
--
-- Correcoes principais:
-- 1) Nunca interrompe uma chamada quando o filtro nao corresponde.
-- 2) Preserva o retorno original do __namecall.
-- 3) Serializador protegido contra ciclos, strings quebradas e tabelas profundas.
-- 4) Guarda args crus apenas para diagnostico local.
-- 5) Monitora RemoteEvents adicionados depois do carregamento.
-- 6) Nao possui replay nem dispara remotes automaticamente.

local SPY = getgenv().SPY
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

if not SPY then
    warn("[YHMH SPY] SPY nao inicializado")
    return
end

local localPlayer = SPY.lp or Players.LocalPlayer
local startTime = os.clock()
local connections = SPY.remoteConnections or {}
SPY.remoteConnections = connections

SPY.remotes = SPY.remotes or {}
SPY.remoteCounts = SPY.remoteCounts or {}
SPY.output = SPY.output or {}
SPY.paused = SPY.paused == true
SPY.filter = tostring(SPY.filter or "")
SPY.maxLog = tonumber(SPY.maxLog) or 500

local function safeType(value)
    local ok, result = pcall(typeof, value)
    return ok and result or type(value)
end

local function escapeString(value)
    return tostring(value)
        :gsub("\\", "\\\\")
        :gsub("\r", "\\r")
        :gsub("\n", "\\n")
        :gsub("\t", "\\t")
        :gsub("\"", "\\\"")
end

local function serialize(value, depth, seen)
    depth = depth or 0
    seen = seen or {}

    if depth > 4 then
        return "..."
    end

    if value == nil then
        return "nil"
    end

    local valueType = safeType(value)

    if valueType == "string" then
        local text = escapeString(value)
        if #text > 160 then
            text = text:sub(1, 160) .. "..."
        end
        return "\"" .. text .. "\""
    elseif valueType == "number" or valueType == "boolean" then
        return tostring(value)
    elseif valueType == "Vector3" then
        return string.format("Vector3(%.3f, %.3f, %.3f)", value.X, value.Y, value.Z)
    elseif valueType == "Vector2" then
        return string.format("Vector2(%.3f, %.3f)", value.X, value.Y)
    elseif valueType == "CFrame" then
        return string.format("CFrame(%.3f, %.3f, %.3f)", value.X, value.Y, value.Z)
    elseif valueType == "Color3" then
        return string.format("Color3(%.3f, %.3f, %.3f)", value.R, value.G, value.B)
    elseif valueType == "UDim2" or valueType == "EnumItem" then
        return tostring(value)
    elseif valueType == "Instance" then
        local className = "?"
        local fullName = "?"
        pcall(function() className = value.ClassName end)
        pcall(function() fullName = value:GetFullName() end)
        return "Instance<" .. className .. ": " .. fullName .. ">"
    elseif valueType == "table" then
        if seen[value] then
            return "<cycle>"
        end
        seen[value] = true

        local parts = {}
        local count = 0
        for key, item in pairs(value) do
            count = count + 1
            if count > 20 then
                parts[#parts + 1] = "..."
                break
            end

            local keyText
            if type(key) == "string" then
                keyText = "[\"" .. escapeString(key) .. "\"]"
            else
                keyText = "[" .. tostring(key) .. "]"
            end

            parts[#parts + 1] = keyText .. "=" .. serialize(item, depth + 1, seen)
        end

        seen[value] = nil
        return "{" .. table.concat(parts, ", ") .. "}"
    end

    return valueType .. "(" .. tostring(value) .. ")"
end

local function serializeArgs(args)
    local parts = {}
    for index, value in ipairs(args) do
        parts[index] = serialize(value)
    end
    return table.concat(parts, ", ")
end

local function matchesFilter(remoteName, remotePath)
    local filter = tostring(SPY.filter or ""):lower()
    if filter == "" then
        return true
    end

    return tostring(remoteName):lower():find(filter, 1, true) ~= nil
        or tostring(remotePath):lower():find(filter, 1, true) ~= nil
end

local function getRemoteInfo(remote)
    local name = "?"
    local path = "?"
    pcall(function() name = remote.Name end)
    pcall(function() path = remote:GetFullName() end)
    return name, path
end

local function addEntry(remote, method, args, direction, result)
    if SPY.paused then
        return
    end

    local name, path = getRemoteInfo(remote)
    if not matchesFilter(name, path) then
        return
    end

    local argsCopy = table.pack(table.unpack(args))
    local argsText = serializeArgs(argsCopy)
    local timeText = string.format("%.2f", os.clock() - startTime)

    local entry = {
        time = timeText,
        method = method,
        direction = direction or "out",
        name = name,
        path = path,
        args = argsText,
        rawArgs = argsCopy,
    }

    if result ~= nil then
        entry.result = result
        entry.resultText = serialize(result)
    end

    table.insert(SPY.remotes, 1, entry)
    while #SPY.remotes > SPY.maxLog do
        table.remove(SPY.remotes)
    end

    SPY.remoteCounts[name] = (SPY.remoteCounts[name] or 0) + 1

    local line = timeText .. " " .. direction .. " " .. method .. " -> " .. name .. "(" .. argsText .. ") PATH:" .. path
    if entry.resultText then
        line = line .. " RETURN:" .. entry.resultText
    end
    table.insert(SPY.output, line)
    while #SPY.output > SPY.maxLog * 2 do
        table.remove(SPY.output, 1)
    end

    pcall(function()
        if SPY.addRemoteEntry then
            SPY.addRemoteEntry(entry)
        end
    end)
end

local function connectRemote(remote)
    if not remote or not remote:IsA("RemoteEvent") or connections[remote] then
        return
    end

    local ok, connection = pcall(function()
        return remote.OnClientEvent:Connect(function(...)
            addEntry(remote, "OnClientEvent", {...}, "in")
        end)
    end)

    if ok and connection then
        connections[remote] = connection
    end
end

local function disconnectAll()
    for remote, connection in pairs(connections) do
        pcall(function() connection:Disconnect() end)
        connections[remote] = nil
    end
end

-- Controles da aba Remotes.
local remoteTab = SPY.tabs and SPY.tabs["Remotes"]
if remoteTab then
    local controlFrame = Instance.new("Frame")
    controlFrame.Name = "RemoteControls"
    controlFrame.Size = UDim2.new(1, 0, 0, 38)
    controlFrame.BackgroundTransparency = 1
    controlFrame.ZIndex = 53
    controlFrame.Parent = remoteTab

    local pauseButton = Instance.new("TextButton")
    pauseButton.Size = UDim2.new(0.3, -2, 0, 32)
    pauseButton.Position = UDim2.new(0, 0, 0, 3)
    pauseButton.BackgroundColor3 = Color3.fromRGB(30, 80, 30)
    pauseButton.Text = SPY.paused and "Resume" or "Pause"
    pauseButton.TextColor3 = Color3.new(1, 1, 1)
    pauseButton.Font = Enum.Font.SourceSansBold
    pauseButton.TextSize = 12
    pauseButton.BorderSizePixel = 0
    pauseButton.ZIndex = 54
    pauseButton.Parent = controlFrame
    pauseButton.MouseButton1Click:Connect(function()
        SPY.paused = not SPY.paused
        pauseButton.Text = SPY.paused and "Resume" or "Pause"
        pauseButton.BackgroundColor3 = SPY.paused and Color3.fromRGB(180, 120, 20) or Color3.fromRGB(30, 80, 30)
    end)

    local clearButton = Instance.new("TextButton")
    clearButton.Size = UDim2.new(0.3, -2, 0, 32)
    clearButton.Position = UDim2.new(0.32, 0, 0, 3)
    clearButton.BackgroundColor3 = Color3.fromRGB(120, 25, 25)
    clearButton.Text = "Clear"
    clearButton.TextColor3 = Color3.new(1, 1, 1)
    clearButton.Font = Enum.Font.SourceSansBold
    clearButton.TextSize = 12
    clearButton.BorderSizePixel = 0
    clearButton.ZIndex = 54
    clearButton.Parent = controlFrame
    clearButton.MouseButton1Click:Connect(function()
        SPY.remotes = {}
        SPY.remoteCounts = {}
        SPY.output = {}
        pcall(function()
            if SPY.countLbl then SPY.countLbl.Text = "0 captured" end
        end)
        for _, child in ipairs(remoteTab:GetChildren()) do
            if child:IsA("Frame") and child ~= controlFrame then
                child:Destroy()
            end
        end
    end)

    local filterBox = Instance.new("TextBox")
    filterBox.Size = UDim2.new(0.36, -2, 0, 32)
    filterBox.Position = UDim2.new(0.64, 0, 0, 3)
    filterBox.BackgroundColor3 = Color3.fromRGB(15, 15, 30)
    filterBox.PlaceholderText = "Filter name/path..."
    filterBox.PlaceholderColor3 = Color3.fromRGB(80, 80, 110)
    filterBox.Text = SPY.filter
    filterBox.TextColor3 = Color3.fromRGB(255, 200, 100)
    filterBox.Font = Enum.Font.Code
    filterBox.TextSize = 11
    filterBox.ClearTextOnFocus = false
    filterBox.BorderSizePixel = 0
    filterBox.ZIndex = 54
    filterBox.Parent = controlFrame
    filterBox.FocusLost:Connect(function()
        SPY.filter = filterBox.Text or ""
    end)
end

-- Um unico hook de __namecall. Ele registra a chamada, mas sempre chama a funcao original.
pcall(function()
    local hookMeta = hookmetamethod
    local getNamecallMethod = getnamecallmethod
    local wrap = newcclosure or function(callback) return callback end

    if not hookMeta or not getNamecallMethod then
        warn("[YHMH SPY] hookmetamethod indisponivel")
        return
    end

    local previous
    previous = hookMeta(game, "__namecall", wrap(function(self, ...)
        local method = getNamecallMethod()
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
            local results = table.pack(previous(self, ...))
            pcall(function()
                addEntry(self, method, args, "out", results[1])
            end)
            return table.unpack(results, 1, results.n)
        end

        pcall(function()
            addEntry(self, method, args, "out")
        end)

        -- Correcao critica: a chamada original nunca e bloqueada.
        return previous(self, ...)
    end))

    SPY.remoteHookInstalled = true
    print("[YHMH SPY] __namecall capture active")
end)

-- Escuta eventos recebidos e remotes criados dinamicamente.
for _, descendant in ipairs(ReplicatedStorage:GetDescendants()) do
    if descendant:IsA("RemoteEvent") then
        connectRemote(descendant)
    end
end

if not SPY.remoteDescendantConnection then
    SPY.remoteDescendantConnection = ReplicatedStorage.DescendantAdded:Connect(function(descendant)
        if descendant:IsA("RemoteEvent") then
            connectRemote(descendant)
        end
    end)
end

SPY.disconnectRemoteCapture = disconnectAll

print("[YHMH SPY] Remote capture active")
