-- YHMH SPY — NPC + Object Scanner + ESP
-- Lista NPCs, objetos interativos, tools, ESP toggles
local SPY = getgenv().SPY
local lp = SPY.lp
local Players = game:GetService("Players")
local WS = game:GetService("Workspace")
local RS = game:GetService("RunService")

local pTab = SPY.tabs["Players"]

local STAT_WORDS = {"power","damage","level","strength","str","defense","def","attack","atk","speed","spd","hp","mana","energy","rank","tier","rarity","dps","crit"}
local ITEM_WORDS = {"item","collect","coin","gem","orb","shard","chest","crate","loot","drop","star","fruit","key","token","crystal","pickup","meteor","diamond","gold","reward","lucky","block","banana","sunken","potion","scroll","essence"}

-- ══════════════════════════════════
-- SCAN NPCs
-- ══════════════════════════════════
SPY.addHeader("Players", "NPC & OBJECT SCANNER")

SPY.addButton("Players", "Scan NPCs", Color3.fromRGB(180, 50, 50), function()
    SPY.clearTab("Players")
    SPY.addHeader("Players", "ALL NPCs IN GAME")

    local myPos = Vector3.zero
    pcall(function() myPos = lp.Character.HumanoidRootPart.Position end)

    local npcs = {}
    for _, d in ipairs(WS:GetDescendants()) do
        pcall(function()
            if d:IsA("Humanoid") and d.Parent and not Players:GetPlayerFromCharacter(d.Parent) then
                local model = d.Parent
                local root = model:FindFirstChild("HumanoidRootPart") or model:FindFirstChild("Head") or model:FindFirstChildWhichIsA("BasePart")
                local dist = root and math.floor((root.Position - myPos).Magnitude) or 9999
                local info = {
                    name = model.Name,
                    hp = math.floor(d.Health),
                    maxHp = math.floor(d.MaxHealth),
                    ws = math.floor(d.WalkSpeed),
                    jp = math.floor(d.JumpPower),
                    dist = dist,
                    path = model:GetFullName(),
                    stats = {},
                }
                -- Procurar stats adaptativos
                for _, v in ipairs(model:GetDescendants()) do
                    pcall(function()
                        if v:IsA("ValueBase") and type(v.Value) == "number" then
                            local n = v.Name:lower()
                            for _, sw in ipairs(STAT_WORDS) do
                                if n:find(sw, 1, true) then
                                    info.stats[v.Name] = v.Value
                                    break
                                end
                            end
                        end
                    end)
                end
                -- Attributes
                pcall(function()
                    for k, v in pairs(model:GetAttributes()) do
                        if type(v) == "number" then
                            info.stats["@" .. k] = v
                        end
                    end
                end)
                table.insert(npcs, info)
            end
        end)
    end

    -- Ordenar por distância
    table.sort(npcs, function(a, b) return a.dist < b.dist end)

    for _, npc in ipairs(npcs) do
        local statsStr = ""
        for k, v in pairs(npc.stats) do
            statsStr = statsStr .. " " .. k .. ":" .. v
        end
        local line = npc.name .. " | HP:" .. npc.hp .. "/" .. npc.maxHp .. " | WS:" .. npc.ws .. " | " .. npc.dist .. "m" .. statsStr
        SPY.addLine("Players", line, Color3.fromRGB(255, 120, 120))
        SPY.addLine("Players", "  " .. npc.path, Color3.fromRGB(80, 80, 100))
        table.insert(SPY.output, "[NPC] " .. line)
    end

    SPY.addLine("Players", "", nil)
    SPY.addLine("Players", "Total NPCs: " .. #npcs, Color3.fromRGB(100, 255, 100))
end)

-- ══════════════════════════════════
-- SCAN INTERACTIVE OBJECTS
-- ══════════════════════════════════
SPY.addButton("Players", "Scan Objects", Color3.fromRGB(50, 100, 180), function()
    SPY.clearTab("Players")
    SPY.addHeader("Players", "INTERACTIVE OBJECTS")

    local myPos = Vector3.zero
    pcall(function() myPos = lp.Character.HumanoidRootPart.Position end)

    -- ClickDetectors
    SPY.addLine("Players", "", nil)
    SPY.addLine("Players", "--- CLICK DETECTORS ---", Color3.fromRGB(100, 200, 255))
    local clickCount = 0
    for _, d in ipairs(WS:GetDescendants()) do
        pcall(function()
            if d:IsA("ClickDetector") then
                clickCount = clickCount + 1
                local parent = d.Parent
                local dist = ""
                pcall(function()
                    if parent:IsA("BasePart") then
                        dist = " [" .. math.floor((parent.Position - myPos).Magnitude) .. "m]"
                    end
                end)
                SPY.addLine("Players", "  " .. parent.Name .. dist .. " @ " .. parent:GetFullName(), Color3.fromRGB(130, 200, 255))
                table.insert(SPY.output, "[CLICK] " .. parent.Name .. " " .. parent:GetFullName())
            end
        end)
    end
    SPY.addLine("Players", "  Total: " .. clickCount, Color3.fromRGB(100, 200, 100))

    -- ProximityPrompts
    SPY.addLine("Players", "", nil)
    SPY.addLine("Players", "--- PROXIMITY PROMPTS ---", Color3.fromRGB(100, 255, 200))
    local promptCount = 0
    for _, d in ipairs(WS:GetDescendants()) do
        pcall(function()
            if d:IsA("ProximityPrompt") then
                promptCount = promptCount + 1
                local txt = d.ActionText ~= "" and d.ActionText or d.ObjectText
                local parent = d.Parent
                SPY.addLine("Players", "  " .. parent.Name .. " [" .. txt .. "] @ " .. parent:GetFullName(), Color3.fromRGB(130, 255, 200))
                table.insert(SPY.output, "[PROMPT] " .. parent.Name .. " '" .. txt .. "' " .. parent:GetFullName())
            end
        end)
    end
    SPY.addLine("Players", "  Total: " .. promptCount, Color3.fromRGB(100, 200, 100))

    -- TouchInterest (touched-based interactions)
    SPY.addLine("Players", "", nil)
    SPY.addLine("Players", "--- TOUCH INTERACTIONS ---", Color3.fromRGB(255, 200, 100))
    local touchCount = 0
    for _, d in ipairs(WS:GetDescendants()) do
        pcall(function()
            if d:IsA("TouchTransmitter") and d.Parent then
                touchCount = touchCount + 1
                if touchCount <= 30 then
                    SPY.addLine("Players", "  " .. d.Parent.Name .. " @ " .. d.Parent:GetFullName(), Color3.fromRGB(220, 180, 100))
                end
            end
        end)
    end
    if touchCount > 30 then SPY.addLine("Players", "  ...+" .. (touchCount - 30) .. " more", Color3.fromRGB(120, 120, 140)) end
    SPY.addLine("Players", "  Total: " .. touchCount, Color3.fromRGB(100, 200, 100))
end)

-- ══════════════════════════════════
-- SCAN TOOLS & ITEMS
-- ══════════════════════════════════
SPY.addButton("Players", "Scan Tools/Items", Color3.fromRGB(180, 130, 30), function()
    SPY.clearTab("Players")
    SPY.addHeader("Players", "TOOLS & ITEMS")

    -- Backpack
    SPY.addLine("Players", "", nil)
    SPY.addLine("Players", "--- YOUR BACKPACK ---", Color3.fromRGB(255, 200, 80))
    pcall(function()
        for _, t in ipairs(lp.Backpack:GetChildren()) do
            SPY.addLine("Players", "  " .. t.Name .. " [" .. t.ClassName .. "]", Color3.fromRGB(220, 200, 100))
            table.insert(SPY.output, "[BACKPACK] " .. t.Name)
        end
    end)

    -- Character equipped
    SPY.addLine("Players", "", nil)
    SPY.addLine("Players", "--- EQUIPPED ---", Color3.fromRGB(255, 200, 80))
    pcall(function()
        if lp.Character then
            for _, t in ipairs(lp.Character:GetChildren()) do
                if t:IsA("Tool") then
                    SPY.addLine("Players", "  " .. t.Name, Color3.fromRGB(255, 220, 100))
                end
            end
        end
    end)

    -- World items
    SPY.addLine("Players", "", nil)
    SPY.addLine("Players", "--- ITEMS IN WORLD ---", Color3.fromRGB(255, 220, 80))
    local myPos = Vector3.zero
    pcall(function() myPos = lp.Character.HumanoidRootPart.Position end)
    local itemCount = 0
    for _, d in ipairs(WS:GetDescendants()) do
        pcall(function()
            if d:IsA("Tool") or ((d:IsA("BasePart") or d:IsA("Model")) and d.Parent == WS) then
                local n = d.Name:lower()
                for _, iw in ipairs(ITEM_WORDS) do
                    if n:find(iw, 1, true) then
                        itemCount = itemCount + 1
                        local dist = ""
                        pcall(function()
                            local part = d:IsA("BasePart") and d or d:FindFirstChildWhichIsA("BasePart")
                            if part then dist = " [" .. math.floor((part.Position - myPos).Magnitude) .. "m]" end
                        end)
                        if itemCount <= 40 then
                            SPY.addLine("Players", "  " .. d.Name .. " [" .. d.ClassName .. "]" .. dist, Color3.fromRGB(255, 210, 80))
                            table.insert(SPY.output, "[ITEM] " .. d.Name .. " " .. d:GetFullName())
                        end
                        break
                    end
                end
            end
        end)
    end
    if itemCount > 40 then SPY.addLine("Players", "  ...+" .. (itemCount - 40) .. " more", Color3.fromRGB(120, 120, 140)) end
    SPY.addLine("Players", "  Total items: " .. itemCount, Color3.fromRGB(100, 200, 100))
end)

-- ══════════════════════════════════
-- ESP TOGGLES
-- ══════════════════════════════════
SPY.addHeader("Players", "ESP")

local espFolder = Instance.new("Folder", WS.CurrentCamera)
espFolder.Name = "YHMH_NPC_ESP"

SPY.ON._espNPC = false
SPY.ON._espItem = false
SPY.ON._espPlayer = false

SPY.addButton("Players", "ESP NPCs ON/OFF", Color3.fromRGB(180, 40, 40), function()
    SPY.ON._espNPC = not SPY.ON._espNPC
    SPY.addLine("Players", "ESP NPCs: " .. (SPY.ON._espNPC and "ON" or "OFF"), SPY.ON._espNPC and Color3.fromRGB(100, 255, 100) or Color3.fromRGB(255, 100, 100))
end)

SPY.addButton("Players", "ESP Items ON/OFF", Color3.fromRGB(180, 150, 30), function()
    SPY.ON._espItem = not SPY.ON._espItem
    SPY.addLine("Players", "ESP Items: " .. (SPY.ON._espItem and "ON" or "OFF"), SPY.ON._espItem and Color3.fromRGB(100, 255, 100) or Color3.fromRGB(255, 100, 100))
end)

SPY.addButton("Players", "ESP Players ON/OFF", Color3.fromRGB(30, 100, 180), function()
    SPY.ON._espPlayer = not SPY.ON._espPlayer
    SPY.addLine("Players", "ESP Players: " .. (SPY.ON._espPlayer and "ON" or "OFF"), SPY.ON._espPlayer and Color3.fromRGB(100, 255, 100) or Color3.fromRGB(255, 100, 100))
end)

-- ESP Loop
task.spawn(function()
    while true do
        task.wait(3)
        for _, c in ipairs(espFolder:GetChildren()) do c:Destroy() end
        local myPos = Vector3.zero
        pcall(function() myPos = lp.Character.HumanoidRootPart.Position end)

        if SPY.ON._espNPC then
            for _, d in ipairs(WS:GetDescendants()) do
                pcall(function()
                    if d:IsA("Humanoid") and d.Parent and not Players:GetPlayerFromCharacter(d.Parent) then
                        local hl = Instance.new("Highlight")
                        hl.Adornee = d.Parent
                        hl.FillColor = Color3.fromRGB(255, 60, 60)
                        hl.FillTransparency = 0.7
                        hl.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
                        hl.Parent = espFolder
                        local root = d.Parent:FindFirstChild("HumanoidRootPart") or d.Parent:FindFirstChildWhichIsA("BasePart")
                        if root then
                            local bb = Instance.new("BillboardGui")
                            bb.Adornee = root
                            bb.Size = UDim2.new(0, 220, 0, 20)
                            bb.StudsOffset = Vector3.new(0, 3, 0)
                            bb.AlwaysOnTop = true
                            bb.Parent = espFolder
                            local l = Instance.new("TextLabel", bb)
                            l.Size = UDim2.new(1, 0, 1, 0)
                            l.BackgroundTransparency = 0.4
                            l.BackgroundColor3 = Color3.new(0, 0, 0)
                            l.Text = d.Parent.Name .. " HP:" .. math.floor(d.Health) .. "/" .. math.floor(d.MaxHealth) .. " [" .. math.floor((root.Position - myPos).Magnitude) .. "m]"
                            l.TextColor3 = Color3.fromRGB(255, 100, 100)
                            l.Font = Enum.Font.SourceSansBold
                            l.TextScaled = true
                        end
                    end
                end)
            end
        end

        if SPY.ON._espItem then
            for _, d in ipairs(WS:GetDescendants()) do
                pcall(function()
                    if d:IsA("BasePart") or d:IsA("Model") then
                        local n = d.Name:lower()
                        for _, iw in ipairs(ITEM_WORDS) do
                            if n:find(iw, 1, true) then
                                local hl = Instance.new("Highlight")
                                hl.Adornee = d
                                hl.FillColor = Color3.fromRGB(255, 220, 50)
                                hl.FillTransparency = 0.5
                                hl.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
                                hl.Parent = espFolder
                                break
                            end
                        end
                    end
                end)
            end
        end

        if SPY.ON._espPlayer then
            for _, p in ipairs(Players:GetPlayers()) do
                if p ~= lp and p.Character then
                    pcall(function()
                        local hl = Instance.new("Highlight")
                        hl.Adornee = p.Character
                        hl.FillColor = Color3.fromRGB(0, 150, 255)
                        hl.FillTransparency = 0.7
                        hl.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
                        hl.Parent = espFolder
                        local r = p.Character:FindFirstChild("HumanoidRootPart")
                        if r then
                            local bb = Instance.new("BillboardGui")
                            bb.Adornee = r
                            bb.Size = UDim2.new(0, 200, 0, 20)
                            bb.StudsOffset = Vector3.new(0, 3, 0)
                            bb.AlwaysOnTop = true
                            bb.Parent = espFolder
                            local l = Instance.new("TextLabel", bb)
                            l.Size = UDim2.new(1, 0, 1, 0)
                            l.BackgroundTransparency = 0.4
                            l.BackgroundColor3 = Color3.new(0, 0, 0)
                            l.Text = p.Name .. " [" .. math.floor((r.Position - myPos).Magnitude) .. "m]"
                            l.TextColor3 = Color3.fromRGB(80, 200, 255)
                            l.Font = Enum.Font.SourceSansBold
                            l.TextScaled = true
                        end
                    end)
                end
            end
        end
    end
end)

-- ══════════════════════════════════
-- TELEPORTS
-- ══════════════════════════════════
SPY.addHeader("Players", "QUICK TP")

SPY.addButton("Players", "TP to NPC", Color3.fromRGB(120, 40, 40), function()
    local hrp = lp.Character and lp.Character:FindFirstChild("HumanoidRootPart")
    if not hrp then return end
    local best, bestD = nil, math.huge
    for _, d in ipairs(WS:GetDescendants()) do
        pcall(function()
            if d:IsA("Humanoid") and d.Parent and not Players:GetPlayerFromCharacter(d.Parent) then
                local root = d.Parent:FindFirstChild("HumanoidRootPart") or d.Parent:FindFirstChildWhichIsA("BasePart")
                if root then
                    local dist = (root.Position - hrp.Position).Magnitude
                    if dist < bestD then best = root; bestD = dist end
                end
            end
        end)
    end
    if best then
        hrp.CFrame = best.CFrame * CFrame.new(0, 0, 4)
        SPY.addLine("Players", "TP to NPC: " .. best.Parent.Name .. " (" .. math.floor(bestD) .. "m)", Color3.fromRGB(100, 255, 100))
    end
end)

SPY.addButton("Players", "TP to Item", Color3.fromRGB(150, 120, 20), function()
    local hrp = lp.Character and lp.Character:FindFirstChild("HumanoidRootPart")
    if not hrp then return end
    local best, bestD, bestN = nil, math.huge, ""
    for _, d in ipairs(WS:GetDescendants()) do
        pcall(function()
            if d:IsA("BasePart") or d:IsA("Model") then
                local n = d.Name:lower()
                for _, iw in ipairs(ITEM_WORDS) do
                    if n:find(iw, 1, true) then
                        local part = d:IsA("BasePart") and d or d:FindFirstChildWhichIsA("BasePart")
                        if part then
                            local dist = (part.Position - hrp.Position).Magnitude
                            if dist < bestD then best = part; bestD = dist; bestN = d.Name end
                        end
                        break
                    end
                end
            end
        end)
    end
    if best then
        hrp.CFrame = best.CFrame + Vector3.new(0, 3, 0)
        SPY.addLine("Players", "TP to: " .. bestN .. " (" .. math.floor(bestD) .. "m)", Color3.fromRGB(100, 255, 100))
    end
end)

print("[SPY NPC] OK")
