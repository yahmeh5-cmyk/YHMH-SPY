-- YHMH SPY — Export
-- Exporta tudo para clipboard automaticamente
local SPY = getgenv().SPY
local lp = SPY.lp
local RS = game:GetService("ReplicatedStorage")
local WS = game:GetService("Workspace")
local Players = game:GetService("Players")

local expTab = SPY.tabs["Export"]

-- Helper: copiar texto
local function copyText(text)
    local ok = false
    pcall(function() if setclipboard then setclipboard(text) ok = true end end)
    pcall(function() if not ok and toclipboard then toclipboard(text) ok = true end end)
    pcall(function() if not ok and getgenv and getgenv().setclipboard then getgenv().setclipboard(text) ok = true end end)
    return ok
end

-- Helper: montar header
local function makeHeader()
    local lines = {
        "==========================================",
        "YHMH SPY — Full Export",
        "PlaceId: " .. tostring(game.PlaceId),
        "Player: " .. lp.Name,
        "UserId: " .. tostring(lp.UserId),
    }
    pcall(function()
        local info = game:GetService("MarketplaceService"):GetProductInfo(game.PlaceId)
        table.insert(lines, "Game: " .. info.Name)
    end)
    table.insert(lines, "Time: " .. os.date("%Y-%m-%d %H:%M:%S"))
    table.insert(lines, "Remotes captured: " .. #SPY.remotes)
    table.insert(lines, "==========================================")
    table.insert(lines, "")
    return lines
end

-- Helper: montar remotes section
local function makeRemotesSection()
    local lines = {"=== CAPTURED REMOTES ==="}
    for i, r in ipairs(SPY.remotes) do
        if i > 300 then
            table.insert(lines, "... +" .. (#SPY.remotes - 300) .. " more")
            break
        end
        table.insert(lines, r.time .. " " .. r.method .. " -> " .. r.name .. "(" .. r.args .. ") PATH:" .. r.path)
    end
    table.insert(lines, "")
    return lines
end

-- Helper: montar remote counts
local function makeCountsSection()
    local lines = {"=== REMOTE FIRE COUNTS ==="}
    local sorted = {}
    for name, count in pairs(SPY.remoteCounts) do
        table.insert(sorted, {name = name, count = count})
    end
    table.sort(sorted, function(a, b) return a.count > b.count end)
    for _, e in ipairs(sorted) do
        table.insert(lines, e.name .. " : " .. e.count .. "x")
    end
    table.insert(lines, "")
    return lines
end

-- Helper: montar player data
local function makePlayerSection()
    local lines = {"=== PLAYER DATA: " .. lp.Name .. " ==="}
    pcall(function()
        for _, d in ipairs(lp:GetDescendants()) do
            pcall(function()
                if d:IsA("ValueBase") then
                    lines[#lines + 1] = d:GetFullName() .. " [" .. d.ClassName .. "] = " .. tostring(d.Value)
                end
            end)
        end
    end)
    pcall(function()
        for k, v in pairs(lp:GetAttributes()) do
            lines[#lines + 1] = "@" .. k .. " = " .. tostring(v)
        end
    end)
    table.insert(lines, "")
    return lines
end

-- Helper: montar all remotes list
local function makeAllRemotesList()
    local lines = {"=== ALL REMOTES IN GAME ==="}
    local count = 0
    pcall(function()
        for _, d in ipairs(RS:GetDescendants()) do
            pcall(function()
                if d:IsA("RemoteEvent") or d:IsA("RemoteFunction") or d:IsA("BindableEvent") then
                    count = count + 1
                    lines[#lines + 1] = count .. ". " .. d.Name .. " [" .. d.ClassName .. "] " .. d:GetFullName()
                end
            end)
        end
    end)
    table.insert(lines, "Total: " .. count)
    table.insert(lines, "")
    return lines
end

-- Helper: montar full export
local function makeFullExport()
    local all = {}
    for _, l in ipairs(makeHeader()) do table.insert(all, l) end
    for _, l in ipairs(makeRemotesSection()) do table.insert(all, l) end
    for _, l in ipairs(makeCountsSection()) do table.insert(all, l) end
    for _, l in ipairs(makePlayerSection()) do table.insert(all, l) end
    for _, l in ipairs(makeAllRemotesList()) do table.insert(all, l) end

    -- Incluir output buffer acumulado
    if #SPY.output > 0 then
        table.insert(all, "=== ACCUMULATED OUTPUT ===")
        for _, l in ipairs(SPY.output) do
            table.insert(all, l)
        end
    end

    table.insert(all, "")
    table.insert(all, "=== END OF EXPORT ===")
    return table.concat(all, "\n")
end

-- ══════════════════════════════════
-- TAB: EXPORT — Botoes
-- ══════════════════════════════════
SPY.addHeader("Export", "EXPORT DATA")

SPY.addButton("Export", "Copy ALL", Color3.fromRGB(30, 100, 40), function()
    local text = makeFullExport()
    local ok = copyText(text)
    if ok then
        SPY.addLine("Export", "Copiado! " .. #text .. " chars", Color3.fromRGB(100, 255, 100))
        print("[EXPORT] Copiado: " .. #text .. " chars")
    else
        SPY.addLine("Export", "Clipboard nao disponivel — abrindo popup", Color3.fromRGB(255, 200, 100))
        showPopup(text)
    end
end)

SPY.addButton("Export", "Copy Remotes", Color3.fromRGB(80, 40, 30), function()
    local lines = makeHeader()
    for _, l in ipairs(makeRemotesSection()) do table.insert(lines, l) end
    for _, l in ipairs(makeCountsSection()) do table.insert(lines, l) end
    local text = table.concat(lines, "\n")
    local ok = copyText(text)
    if ok then
        SPY.addLine("Export", "Remotes copiados! " .. #text .. " chars", Color3.fromRGB(100, 255, 100))
    else
        showPopup(text)
    end
end)

SPY.addButton("Export", "Copy Player Data", Color3.fromRGB(30, 40, 80), function()
    local lines = makeHeader()
    for _, l in ipairs(makePlayerSection()) do table.insert(lines, l) end
    local text = table.concat(lines, "\n")
    local ok = copyText(text)
    if ok then
        SPY.addLine("Export", "Player data copiado! " .. #text .. " chars", Color3.fromRGB(100, 255, 100))
    else
        showPopup(text)
    end
end)

SPY.addButton("Export", "Copy All Remotes List", Color3.fromRGB(60, 30, 60), function()
    local lines = makeHeader()
    for _, l in ipairs(makeAllRemotesList()) do table.insert(lines, l) end
    local text = table.concat(lines, "\n")
    local ok = copyText(text)
    if ok then
        SPY.addLine("Export", "Remote list copiada! " .. #text .. " chars", Color3.fromRGB(100, 255, 100))
    else
        showPopup(text)
    end
end)

SPY.addButton("Export", "Full Scan + Copy", Color3.fromRGB(120, 40, 20), function()
    SPY.addLine("Export", "Escaneando tudo...", Color3.fromRGB(255, 200, 100))
    task.defer(function()
        -- Scan player
        pcall(function()
            for _, d in ipairs(lp:GetDescendants()) do
                pcall(function()
                    if d:IsA("ValueBase") then
                        table.insert(SPY.output, d:GetFullName() .. " = " .. tostring(d.Value))
                    end
                end)
            end
        end)
        -- Scan all remotes
        pcall(function()
            for _, d in ipairs(RS:GetDescendants()) do
                pcall(function()
                    if d:IsA("RemoteEvent") or d:IsA("RemoteFunction") then
                        table.insert(SPY.output, "REMOTE: " .. d.Name .. " [" .. d.ClassName .. "] " .. d:GetFullName())
                    end
                end)
            end
        end)
        -- Export
        local text = makeFullExport()
        local ok = copyText(text)
        if ok then
            SPY.addLine("Export", "FULL SCAN copiado! " .. #text .. " chars", Color3.fromRGB(100, 255, 100))
        else
            showPopup(text)
        end
    end)
end)

-- ══════════════════════════════════
-- POPUP FALLBACK (iPhone sem clipboard)
-- ══════════════════════════════════
function showPopup(text)
    pcall(function()
        local old = SPY.sg:FindFirstChild("ExportPopup")
        if old then old:Destroy() end
    end)

    local popup = Instance.new("Frame")
    popup.Name = "ExportPopup"
    popup.Size = UDim2.new(0.94, 0, 0.85, 0)
    popup.Position = UDim2.new(0.03, 0, 0.075, 0)
    popup.BackgroundColor3 = Color3.fromRGB(8, 8, 16)
    popup.BorderSizePixel = 0
    popup.ZIndex = 300
    popup.Parent = SPY.sg

    local title = Instance.new("TextLabel")
    title.Size = UDim2.new(1, 0, 0, 34)
    title.BackgroundColor3 = Color3.fromRGB(200, 50, 30)
    title.Text = "  Segure texto > Selecionar Tudo > Copiar"
    title.TextColor3 = Color3.new(1, 1, 1)
    title.Font = Enum.Font.SourceSansBold
    title.TextSize = 12
    title.TextXAlignment = Enum.TextXAlignment.Left
    title.BorderSizePixel = 0
    title.ZIndex = 301
    title.Parent = popup

    local closeB = Instance.new("TextButton")
    closeB.Size = UDim2.new(0, 34, 0, 34)
    closeB.Position = UDim2.new(1, -34, 0, 0)
    closeB.BackgroundTransparency = 1
    closeB.Text = "X"
    closeB.TextColor3 = Color3.new(1, 1, 1)
    closeB.Font = Enum.Font.SourceSansBold
    closeB.TextSize = 18
    closeB.ZIndex = 302
    closeB.Parent = popup
    closeB.MouseButton1Click:Connect(function() popup:Destroy() end)

    local scroll = Instance.new("ScrollingFrame")
    scroll.Size = UDim2.new(1, -10, 1, -80)
    scroll.Position = UDim2.new(0, 5, 0, 38)
    scroll.BackgroundColor3 = Color3.fromRGB(4, 4, 10)
    scroll.BorderSizePixel = 0
    scroll.ScrollBarThickness = 4
    scroll.CanvasSize = UDim2.new(0, 0, 0, 0)
    scroll.ZIndex = 301
    scroll.Parent = popup

    local tb = Instance.new("TextBox")
    tb.Size = UDim2.new(1, -10, 0, 0)
    tb.Position = UDim2.new(0, 5, 0, 2)
    tb.AutomaticSize = Enum.AutomaticSize.Y
    tb.BackgroundTransparency = 1
    tb.TextColor3 = Color3.fromRGB(200, 220, 240)
    tb.Font = Enum.Font.Code
    tb.TextSize = 9
    tb.TextXAlignment = Enum.TextXAlignment.Left
    tb.TextYAlignment = Enum.TextYAlignment.Top
    tb.TextWrapped = true
    tb.ClearTextOnFocus = false
    tb.MultiLine = true
    tb.TextEditable = true
    tb.Text = text
    tb.ZIndex = 302
    tb.Parent = scroll

    pcall(function()
        local ts = game:GetService("TextService")
        local bounds = ts:GetTextSize(text, 9, Enum.Font.Code, Vector2.new(scroll.AbsoluteSize.X - 20, 999999))
        tb.Size = UDim2.new(1, -10, 0, bounds.Y + 30)
        scroll.CanvasSize = UDim2.new(0, 0, 0, bounds.Y + 50)
    end)

    local closeB2 = Instance.new("TextButton")
    closeB2.Size = UDim2.new(0.94, 0, 0, 36)
    closeB2.Position = UDim2.new(0.03, 0, 1, -42)
    closeB2.BackgroundColor3 = Color3.fromRGB(150, 30, 30)
    closeB2.Text = "Fechar"
    closeB2.TextColor3 = Color3.new(1, 1, 1)
    closeB2.Font = Enum.Font.SourceSansBold
    closeB2.TextSize = 14
    closeB2.BorderSizePixel = 0
    closeB2.ZIndex = 301
    closeB2.Parent = popup
    closeB2.MouseButton1Click:Connect(function() popup:Destroy() end)
end

-- ══════════════════════════════════
-- AUTO-COPY a cada 30 segundos
-- ══════════════════════════════════
task.spawn(function()
    while true do
        task.wait(30)
        if #SPY.remotes > 0 then
            local text = makeFullExport()
            local ok = copyText(text)
            if ok then
                print("[EXPORT] Auto-copy: " .. #SPY.remotes .. " remotes | " .. #text .. " chars")
            end
        end
    end
end)

-- Status
SPY.addLine("Export", "", nil)
SPY.addLine("Export", "Auto-copy: a cada 30s", Color3.fromRGB(130, 130, 160))
SPY.addLine("Export", "Jogue normalmente — tudo esta sendo gravado", Color3.fromRGB(130, 130, 160))
SPY.addLine("Export", "Toque 'Copy ALL' quando quiser exportar", Color3.fromRGB(130, 130, 160))

print("[SPY EXPORT] OK")
