-- YHMH SPY — Game Mapper
-- Mapeamento completo: Workspace, RS, Player, Remotes
local SPY = getgenv().SPY
local lp = SPY.lp
local Players = game:GetService("Players")
local RS = game:GetService("ReplicatedStorage")
local WS = game:GetService("Workspace")
local CS = game:GetService("CollectionService")

local treeTab = SPY.tabs["Tree"]
local playTab = SPY.tabs["Players"]

-- Helper: dump instancia recursivo
local function dumpInst(inst, depth, lines)
    if depth > 4 then return end
    local indent = string.rep("  ", depth)
    local name = ""
    pcall(function() name = inst.Name end)
    local class = ""
    pcall(function() class = inst.ClassName end)
    local val = ""
    pcall(function()
        if inst:IsA("ValueBase") then
            val = " = " .. tostring(inst.Value)
        end
    end)
    local attrStr = ""
    pcall(function()
        local attrs = inst:GetAttributes()
        if attrs and next(attrs) then
            local ap = {}
            for k, v in pairs(attrs) do
                table.insert(ap, k .. "=" .. tostring(v))
            end
            attrStr = " {" .. table.concat(ap, ", ") .. "}"
        end
    end)
    local childCount = 0
    pcall(function() childCount = #inst:GetChildren() end)
    local countStr = childCount > 0 and " (" .. childCount .. ")" or ""

    table.insert(lines, indent .. name .. " [" .. class .. "]" .. countStr .. val .. attrStr)

    pcall(function()
        for _, child in ipairs(inst:GetChildren()) do
            dumpInst(child, depth + 1, lines)
        end
    end)
end

-- Helper: scan e mostrar na tab
local function scanAndShow(tabName, title, root, maxDepth)
    SPY.clearTab(tabName)
    SPY.addHeader(tabName, title)
    local lines = {}
    pcall(function()
        for _, child in ipairs(root:GetChildren()) do
            dumpInst(child, 0, lines)
        end
    end)
    for _, line in ipairs(lines) do
        SPY.addLine(tabName, line, Color3.fromRGB(180, 200, 220))
    end
    -- Salvar no output
    table.insert(SPY.output, "")
    table.insert(SPY.output, "=== " .. title .. " ===")
    for _, line in ipairs(lines) do
        table.insert(SPY.output, line)
    end
    SPY.addLine(tabName, "Total: " .. #lines .. " linhas", Color3.fromRGB(100, 200, 100))
end

-- ══════════════════════════════════
-- TAB: TREE — Botoes de scan
-- ══════════════════════════════════
SPY.addHeader("Tree", "SCAN GAME TREE")

SPY.addButton("Tree", "Scan Workspace", Color3.fromRGB(30, 80, 50), function()
    scanAndShow("Tree", "WORKSPACE", WS)
end)

SPY.addButton("Tree", "Scan RS", Color3.fromRGB(30, 50, 80), function()
    scanAndShow("Tree", "REPLICATED STORAGE", RS)
end)

SPY.addButton("Tree", "Scan Player", Color3.fromRGB(80, 50, 30), function()
    scanAndShow("Tree", "PLAYER: " .. lp.Name, lp)
end)

SPY.addButton("Tree", "Scan PlayerGui", Color3.fromRGB(80, 30, 60), function()
    SPY.clearTab("Tree")
    SPY.addHeader("Tree", "PLAYERGUI (Folders/Values only)")
    local lines = {}
    pcall(function()
        for _, d in ipairs(lp.PlayerGui:GetDescendants()) do
            pcall(function()
                if d:IsA("Folder") or d:IsA("ValueBase") or d:IsA("Configuration") then
                    local val = ""
                    if d:IsA("ValueBase") then val = " = " .. tostring(d.Value) end
                    table.insert(lines, d:GetFullName() .. " [" .. d.ClassName .. "]" .. val)
                end
            end)
        end
    end)
    for _, line in ipairs(lines) do
        SPY.addLine("Tree", line, Color3.fromRGB(180, 170, 200))
    end
    table.insert(SPY.output, "")
    table.insert(SPY.output, "=== PLAYERGUI DATA ===")
    for _, line in ipairs(lines) do table.insert(SPY.output, line) end
end)

SPY.addButton("Tree", "All Remotes", Color3.fromRGB(80, 30, 30), function()
    SPY.clearTab("Tree")
    SPY.addHeader("Tree", "ALL REMOTES IN GAME")
    local lines = {}
    local count = 0
    pcall(function()
        for _, d in ipairs(RS:GetDescendants()) do
            pcall(function()
                if d:IsA("RemoteEvent") or d:IsA("RemoteFunction") or d:IsA("BindableEvent") then
                    count = count + 1
                    local line = count .. ". " .. d.Name .. " [" .. d.ClassName .. "] " .. d:GetFullName()
                    table.insert(lines, line)
                end
            end)
        end
    end)
    for _, line in ipairs(lines) do
        local col = Color3.fromRGB(200, 150, 150)
        if line:find("RemoteFunction") then col = Color3.fromRGB(150, 150, 220) end
        if line:find("BindableEvent") then col = Color3.fromRGB(150, 200, 150) end
        SPY.addLine("Tree", line, col)
    end
    SPY.addLine("Tree", "Total: " .. count, Color3.fromRGB(100, 200, 100))
    table.insert(SPY.output, "")
    table.insert(SPY.output, "=== ALL REMOTES ===")
    for _, line in ipairs(lines) do table.insert(SPY.output, line) end
    table.insert(SPY.output, "Total: " .. count)
end)

SPY.addButton("Tree", "Keyword Search", Color3.fromRGB(60, 40, 80), function()
    SPY.clearTab("Tree")
    SPY.addHeader("Tree", "KEYWORD SEARCH")
    local kws = {"fighter","character","unit","hero","inventory","bag","storage","item","data","save",
        "profile","slot","shop","buy","sell","trade","equip","weapon","armor","pet","summon",
        "gacha","roll","spin","chest","crate","egg","star","token","coin","gem","gold","money",
        "cash","currency","quest","mission","reward","level","xp","exp","power","damage","your",
        "owned","collection","squad","team","party"}
    local lines = {}
    local function searchIn(root, rootName)
        pcall(function()
            for _, d in ipairs(root:GetDescendants()) do
                pcall(function()
                    local n = d.Name:lower()
                    for _, kw in ipairs(kws) do
                        if n:find(kw, 1, true) then
                            local childCount = 0
                            pcall(function() childCount = #d:GetChildren() end)
                            local val = ""
                            pcall(function()
                                if d:IsA("ValueBase") then val = " = " .. tostring(d.Value) end
                            end)
                            local line = "[" .. rootName .. "] " .. d.Name .. " [" .. d.ClassName .. "] (" .. childCount .. ")" .. val .. " @ " .. d:GetFullName()
                            table.insert(lines, line)
                            break
                        end
                    end
                end)
            end
        end)
    end
    searchIn(lp, "Player")
    searchIn(RS, "RS")
    searchIn(WS, "WS")
    for _, line in ipairs(lines) do
        SPY.addLine("Tree", line, Color3.fromRGB(200, 180, 140))
    end
    SPY.addLine("Tree", "Found: " .. #lines, Color3.fromRGB(100, 200, 100))
    table.insert(SPY.output, "")
    table.insert(SPY.output, "=== KEYWORD SEARCH ===")
    for _, line in ipairs(lines) do table.insert(SPY.output, line) end
end)

SPY.addButton("Tree", "All Tags", Color3.fromRGB(40, 60, 60), function()
    SPY.clearTab("Tree")
    SPY.addHeader("Tree", "COLLECTION SERVICE TAGS")
    local lines = {}
    pcall(function()
        for _, tag in ipairs(CS:GetAllTags()) do
            local tagged = CS:GetTagged(tag)
            table.insert(lines, tag .. " (" .. #tagged .. " instances)")
        end
    end)
    for _, line in ipairs(lines) do
        SPY.addLine("Tree", line, Color3.fromRGB(150, 200, 180))
    end
    table.insert(SPY.output, "")
    table.insert(SPY.output, "=== TAGS ===")
    for _, line in ipairs(lines) do table.insert(SPY.output, line) end
end)

-- ══════════════════════════════════
-- TAB: PLAYERS — Info de todos os players
-- ══════════════════════════════════
local function scanPlayers()
    SPY.clearTab("Players")
    SPY.addHeader("Players", "ALL PLAYERS (" .. #Players:GetPlayers() .. ")")

    for _, p in ipairs(Players:GetPlayers()) do
        local lines = {}
        table.insert(lines, p.Name .. " (UserId: " .. p.UserId .. ")")

        -- Leaderstats
        pcall(function()
            local ls = p:FindFirstChild("leaderstats")
            if ls then
                for _, v in ipairs(ls:GetChildren()) do
                    pcall(function()
                        if v:IsA("ValueBase") then
                            table.insert(lines, "  ls." .. v.Name .. " = " .. tostring(v.Value))
                        end
                    end)
                end
            end
        end)

        -- Data folders
        pcall(function()
            for _, child in ipairs(p:GetChildren()) do
                if child:IsA("Folder") and child.Name ~= "leaderstats" then
                    for _, v in ipairs(child:GetChildren()) do
                        pcall(function()
                            if v:IsA("ValueBase") then
                                table.insert(lines, "  " .. child.Name .. "." .. v.Name .. " = " .. tostring(v.Value))
                            end
                        end)
                    end
                end
            end
        end)

        -- Attributes
        pcall(function()
            for k, v in pairs(p:GetAttributes()) do
                table.insert(lines, "  @" .. k .. " = " .. tostring(v))
            end
        end)

        -- Humanoid stats
        pcall(function()
            if p.Character then
                local hum = p.Character:FindFirstChildOfClass("Humanoid")
                if hum then
                    table.insert(lines, "  HP: " .. math.floor(hum.Health) .. "/" .. math.floor(hum.MaxHealth))
                    table.insert(lines, "  WS: " .. math.floor(hum.WalkSpeed) .. " JP: " .. math.floor(hum.JumpPower))
                end
            end
        end)

        -- Mostrar na GUI
        local isLocal = p == lp
        local nameColor = isLocal and Color3.fromRGB(100, 255, 100) or Color3.fromRGB(100, 180, 255)
        SPY.addLine("Players", "", nil)
        SPY.addLine("Players", lines[1], nameColor)
        for i = 2, #lines do
            SPY.addLine("Players", lines[i], Color3.fromRGB(170, 170, 190))
        end

        -- Salvar no output
        table.insert(SPY.output, "")
        for _, line in ipairs(lines) do
            table.insert(SPY.output, line)
        end
    end
end

-- Auto-scan players ao carregar
task.defer(function()
    task.wait(1)
    scanPlayers()
end)

-- Botao refresh na tab Players
SPY.addButton("Players", "Refresh Players", Color3.fromRGB(30, 60, 80), function()
    scanPlayers()
end)

-- Remote counts button
SPY.addButton("Players", "Remote Counts", Color3.fromRGB(60, 30, 60), function()
    SPY.clearTab("Players")
    SPY.addHeader("Players", "REMOTE FIRE COUNTS")
    local sorted = {}
    for name, count in pairs(SPY.remoteCounts) do
        table.insert(sorted, {name = name, count = count})
    end
    table.sort(sorted, function(a, b) return a.count > b.count end)
    for _, entry in ipairs(sorted) do
        SPY.addLine("Players", entry.name .. " : " .. entry.count .. "x", Color3.fromRGB(255, 180, 100))
    end
    if #sorted == 0 then
        SPY.addLine("Players", "Nenhum remote capturado ainda", Color3.fromRGB(150, 150, 150))
    end
end)

print("[SPY MAPPER] OK")
