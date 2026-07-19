-- YHMH SPY GUI v2
-- 7 tabs: Remotes, Tree, Econ, NPCs, Players, Args, Export
local SPY = getgenv().SPY
local lp = SPY.lp
local UIS = game:GetService("UserInputService")
local RS = game:GetService("RunService")

-- Cleanup
pcall(function()
    local old = lp.PlayerGui:FindFirstChild("YHSpy")
    if old then old:Destroy() end
end)

local sg = Instance.new("ScreenGui")
sg.Name = "YHSpy"
sg.ResetOnSpawn = false
sg.Parent = lp:WaitForChild("PlayerGui")
SPY.sg = sg

-- ══════════════════════════════════
-- COLORS
-- ══════════════════════════════════
local C = {
    accent = Color3.fromRGB(220, 60, 20),
    bg = Color3.fromRGB(8, 8, 14),
    card = Color3.fromRGB(14, 14, 26),
    cardLight = Color3.fromRGB(20, 20, 34),
    tabOff = Color3.fromRGB(18, 18, 30),
    text = Color3.fromRGB(210, 210, 225),
    textDim = Color3.fromRGB(130, 130, 155),
    green = Color3.fromRGB(30, 150, 60),
    red = Color3.fromRGB(180, 40, 40),
    yellow = Color3.fromRGB(220, 180, 40),
    blue = Color3.fromRGB(40, 120, 220),
}

-- ══════════════════════════════════
-- TOGGLE BUTTON (arrastavel)
-- ══════════════════════════════════
local mBtn = Instance.new("TextButton")
mBtn.Size = UDim2.new(0, 50, 0, 50)
mBtn.Position = UDim2.new(0, 6, 0.25, 0)
mBtn.BackgroundColor3 = C.accent
mBtn.Text = "SPY"
mBtn.TextColor3 = Color3.new(1, 1, 1)
mBtn.Font = Enum.Font.SourceSansBold
mBtn.TextSize = 14
mBtn.BorderSizePixel = 0
mBtn.ZIndex = 200
mBtn.Parent = sg

local dragM, dragMS, dragMP, wasDragM = false, nil, nil, false
mBtn.InputBegan:Connect(function(i)
    if i.UserInputType == Enum.UserInputType.Touch or i.UserInputType == Enum.UserInputType.MouseButton1 then
        dragM = true
        wasDragM = false
        dragMS = i.Position
        dragMP = mBtn.Position
    end
end)
UIS.InputChanged:Connect(function(i)
    if dragM and (i.UserInputType == Enum.UserInputType.Touch or i.UserInputType == Enum.UserInputType.MouseMovement) then
        if dragMS then
            local d = i.Position - dragMS
            if d.Magnitude > 8 then wasDragM = true end
            mBtn.Position = UDim2.new(dragMP.X.Scale, dragMP.X.Offset + d.X, dragMP.Y.Scale, dragMP.Y.Offset + d.Y)
        end
    end
end)
mBtn.InputEnded:Connect(function(i)
    if i.UserInputType == Enum.UserInputType.Touch or i.UserInputType == Enum.UserInputType.MouseButton1 then
        if dragM and not wasDragM then
            SPY._open = not SPY._open
            sg:FindFirstChild("Panel").Visible = SPY._open
            mBtn.Text = SPY._open and "X" or "SPY"
            mBtn.BackgroundColor3 = SPY._open and C.red or C.accent
        end
        dragM = false
    end
end)

-- ══════════════════════════════════
-- PANEL
-- ══════════════════════════════════
local panel = Instance.new("Frame")
panel.Name = "Panel"
panel.Size = UDim2.new(0.94, 0, 0.88, 0)
panel.Position = UDim2.new(0.03, 0, 0.06, 0)
panel.BackgroundColor3 = C.bg
panel.BorderSizePixel = 0
panel.Visible = false
panel.ZIndex = 50
panel.Parent = sg

-- ══════════════════════════════════
-- TITLE BAR (arrastavel)
-- ══════════════════════════════════
local tBar = Instance.new("Frame")
tBar.Size = UDim2.new(1, 0, 0, 36)
tBar.BackgroundColor3 = C.accent
tBar.BorderSizePixel = 0
tBar.ZIndex = 51
tBar.Parent = panel

-- Logo + Title
local tLbl = Instance.new("TextLabel")
tLbl.Size = UDim2.new(0.45, 0, 1, 0)
tLbl.Position = UDim2.new(0, 10, 0, 0)
tLbl.BackgroundTransparency = 1
tLbl.Text = "YHMH SPY v2"
tLbl.TextColor3 = Color3.new(1, 1, 1)
tLbl.Font = Enum.Font.SourceSansBold
tLbl.TextSize = 15
tLbl.TextXAlignment = Enum.TextXAlignment.Left
tLbl.ZIndex = 52
tLbl.Parent = tBar

-- Game info (right side)
local gInfo = Instance.new("TextLabel")
gInfo.Size = UDim2.new(0.45, 0, 0.5, 0)
gInfo.Position = UDim2.new(0.45, 0, 0, 0)
gInfo.BackgroundTransparency = 1
gInfo.Text = "PlaceId: " .. game.PlaceId
gInfo.TextColor3 = Color3.fromRGB(255, 200, 170)
gInfo.Font = Enum.Font.SourceSans
gInfo.TextSize = 9
gInfo.TextXAlignment = Enum.TextXAlignment.Right
gInfo.ZIndex = 52
gInfo.Parent = tBar

-- Remote counter
SPY.countLbl = Instance.new("TextLabel")
SPY.countLbl.Size = UDim2.new(0.45, 0, 0.5, 0)
SPY.countLbl.Position = UDim2.new(0.45, 0, 0.5, 0)
SPY.countLbl.BackgroundTransparency = 1
SPY.countLbl.Text = "0 remotes captured"
SPY.countLbl.TextColor3 = Color3.fromRGB(255, 220, 180)
SPY.countLbl.Font = Enum.Font.SourceSansBold
SPY.countLbl.TextSize = 9
SPY.countLbl.TextXAlignment = Enum.TextXAlignment.Right
SPY.countLbl.ZIndex = 52
SPY.countLbl.Parent = tBar

-- Game name (async)
task.spawn(function()
    pcall(function()
        local info = game:GetService("MarketplaceService"):GetProductInfo(game.PlaceId)
        gInfo.Text = info.Name
    end)
end)

-- Close button
local xBtn = Instance.new("TextButton")
xBtn.Size = UDim2.new(0, 36, 0, 36)
xBtn.Position = UDim2.new(1, -36, 0, 0)
xBtn.BackgroundTransparency = 1
xBtn.Text = "X"
xBtn.TextColor3 = Color3.fromRGB(255, 200, 200)
xBtn.Font = Enum.Font.SourceSansBold
xBtn.TextSize = 18
xBtn.ZIndex = 52
xBtn.Parent = tBar
xBtn.MouseButton1Click:Connect(function()
    SPY._open = false
    panel.Visible = false
    mBtn.Text = "SPY"
    mBtn.BackgroundColor3 = C.accent
end)

-- Drag panel by title
local dragP, dragPS, dragPP = false, nil, nil
tBar.InputBegan:Connect(function(i)
    if i.UserInputType == Enum.UserInputType.Touch or i.UserInputType == Enum.UserInputType.MouseButton1 then
        dragP = true
        dragPS = i.Position
        dragPP = panel.Position
    end
end)
tBar.InputEnded:Connect(function(i)
    if i.UserInputType == Enum.UserInputType.Touch or i.UserInputType == Enum.UserInputType.MouseButton1 then
        dragP = false
    end
end)
UIS.InputChanged:Connect(function(i)
    if dragP and (i.UserInputType == Enum.UserInputType.Touch or i.UserInputType == Enum.UserInputType.MouseMovement) then
        if dragPS then
            local d = i.Position - dragPS
            panel.Position = UDim2.new(dragPP.X.Scale, dragPP.X.Offset + d.X, dragPP.Y.Scale, dragPP.Y.Offset + d.Y)
        end
    end
end)

-- ══════════════════════════════════
-- TAB BAR (scrollable horizontal)
-- ══════════════════════════════════
local tabNames = {"Remotes", "Tree", "Econ", "NPCs", "Players", "Args", "Export"}

local tabScroll = Instance.new("ScrollingFrame")
tabScroll.Size = UDim2.new(1, 0, 0, 34)
tabScroll.Position = UDim2.new(0, 0, 0, 36)
tabScroll.BackgroundColor3 = Color3.fromRGB(10, 10, 20)
tabScroll.BorderSizePixel = 0
tabScroll.ScrollBarThickness = 0
tabScroll.CanvasSize = UDim2.new(0, #tabNames * 72, 0, 0)
tabScroll.ScrollingDirection = Enum.ScrollingDirection.X
tabScroll.ZIndex = 51
tabScroll.Parent = panel

SPY.tabs = {}
SPY.tabBtns = {}

for i, name in ipairs(tabNames) do
    local b = Instance.new("TextButton")
    b.Size = UDim2.new(0, 70, 0, 28)
    b.Position = UDim2.new(0, (i - 1) * 72 + 2, 0.5, -14)
    b.BackgroundColor3 = i == 1 and C.accent or C.tabOff
    b.Text = name
    b.TextColor3 = i == 1 and Color3.new(1, 1, 1) or C.textDim
    b.Font = Enum.Font.SourceSansBold
    b.TextSize = 11
    b.BorderSizePixel = 0
    b.ZIndex = 52
    b.Parent = tabScroll
    SPY.tabBtns[name] = b

    local f = Instance.new("ScrollingFrame")
    f.Name = "Tab_" .. name
    f.Size = UDim2.new(1, -6, 1, -92)
    f.Position = UDim2.new(0, 3, 0, 74)
    f.BackgroundTransparency = 1
    f.BorderSizePixel = 0
    f.ScrollBarThickness = 3
    f.ScrollBarImageColor3 = C.accent
    f.CanvasSize = UDim2.new(0, 0, 0, 0)
    f.AutomaticCanvasSize = Enum.AutomaticSize.Y
    f.Visible = i == 1
    f.ZIndex = 51
    f.Parent = panel

    Instance.new("UIListLayout", f).Padding = UDim.new(0, 3)
    local pad = Instance.new("UIPadding", f)
    pad.PaddingLeft = UDim.new(0, 4)
    pad.PaddingRight = UDim.new(0, 4)
    pad.PaddingTop = UDim.new(0, 4)
    pad.PaddingBottom = UDim.new(0, 8)

    SPY.tabs[name] = f

    b.MouseButton1Click:Connect(function()
        for n, tb in pairs(SPY.tabBtns) do
            tb.BackgroundColor3 = n == name and C.accent or C.tabOff
            tb.TextColor3 = n == name and Color3.new(1, 1, 1) or C.textDim
        end
        for n, tf in pairs(SPY.tabs) do
            tf.Visible = n == name
        end
    end)
end

-- ══════════════════════════════════
-- STATUS BAR
-- ══════════════════════════════════
local statusBar = Instance.new("TextLabel")
statusBar.Size = UDim2.new(1, 0, 0, 18)
statusBar.Position = UDim2.new(0, 0, 1, -18)
statusBar.BackgroundColor3 = Color3.fromRGB(6, 6, 12)
statusBar.Text = "  " .. lp.Name .. " | " .. game.PlaceId .. " | YHMH SPY v2"
statusBar.TextColor3 = Color3.fromRGB(70, 70, 100)
statusBar.Font = Enum.Font.SourceSans
statusBar.TextSize = 9
statusBar.TextXAlignment = Enum.TextXAlignment.Left
statusBar.BorderSizePixel = 0
statusBar.ZIndex = 51
statusBar.Parent = panel

-- ══════════════════════════════════
-- NOTIFICATION SYSTEM
-- ══════════════════════════════════
function SPY.notify(text, duration)
    pcall(function()
        local old = sg:FindFirstChild("Notif")
        if old then old:Destroy() end

        local n = Instance.new("TextLabel")
        n.Name = "Notif"
        n.Size = UDim2.new(0.8, 0, 0, 36)
        n.Position = UDim2.new(0.1, 0, 0, 4)
        n.BackgroundColor3 = C.accent
        n.Text = "  " .. text
        n.TextColor3 = Color3.new(1, 1, 1)
        n.Font = Enum.Font.SourceSansBold
        n.TextSize = 13
        n.TextXAlignment = Enum.TextXAlignment.Left
        n.BorderSizePixel = 0
        n.ZIndex = 300
        n.Parent = sg

        task.delay(duration or 3, function()
            pcall(function() n:Destroy() end)
        end)
    end)
end

-- ══════════════════════════════════
-- BUILDER FUNCTIONS
-- ══════════════════════════════════

function SPY.addLine(tabName, text, color)
    local parent = SPY.tabs[tabName]
    if not parent then return end
    local l = Instance.new("TextLabel")
    l.Size = UDim2.new(1, 0, 0, 0)
    l.AutomaticSize = Enum.AutomaticSize.Y
    l.BackgroundTransparency = 1
    l.Text = text
    l.TextColor3 = color or C.text
    l.Font = Enum.Font.Code
    l.TextSize = 10
    l.TextXAlignment = Enum.TextXAlignment.Left
    l.TextWrapped = true
    l.ZIndex = 53
    l.Parent = parent
end

function SPY.addHeader(tabName, text)
    local parent = SPY.tabs[tabName]
    if not parent then return end
    local l = Instance.new("TextLabel")
    l.Size = UDim2.new(1, 0, 0, 22)
    l.BackgroundColor3 = C.accent
    l.BackgroundTransparency = 0.75
    l.Text = "  " .. text
    l.TextColor3 = Color3.fromRGB(255, 190, 140)
    l.Font = Enum.Font.SourceSansBold
    l.TextSize = 11
    l.TextXAlignment = Enum.TextXAlignment.Left
    l.ZIndex = 53
    l.Parent = parent
end

function SPY.addButton(tabName, text, color, cb)
    local parent = SPY.tabs[tabName]
    if not parent then return end
    local b = Instance.new("TextButton")
    b.Size = UDim2.new(1, 0, 0, 38)
    b.BackgroundColor3 = color or C.cardLight
    b.Text = "  " .. text
    b.TextColor3 = Color3.new(1, 1, 1)
    b.Font = Enum.Font.SourceSansBold
    b.TextSize = 12
    b.TextXAlignment = Enum.TextXAlignment.Left
    b.BorderSizePixel = 0
    b.ZIndex = 53
    b.Parent = parent
    b.MouseButton1Click:Connect(function()
        local orig = b.BackgroundColor3
        b.BackgroundColor3 = Color3.fromRGB(60, 60, 90)
        b.Text = "  ..."
        pcall(cb)
        task.delay(0.4, function()
            pcall(function()
                b.BackgroundColor3 = orig
                b.Text = "  " .. text
            end)
        end)
    end)
    return b
end

function SPY.addToggle(tabName, text, key, onCB, offCB)
    SPY.ON[key] = SPY.ON[key] or false
    local parent = SPY.tabs[tabName]
    if not parent then return end

    local f = Instance.new("Frame")
    f.Size = UDim2.new(1, 0, 0, 40)
    f.BackgroundColor3 = C.card
    f.BorderSizePixel = 0
    f.ZIndex = 53
    f.Parent = parent

    local l = Instance.new("TextLabel")
    l.Size = UDim2.new(0.64, 0, 1, 0)
    l.Position = UDim2.new(0, 10, 0, 0)
    l.BackgroundTransparency = 1
    l.Text = text
    l.TextColor3 = C.text
    l.Font = Enum.Font.SourceSansBold
    l.TextSize = 12
    l.TextXAlignment = Enum.TextXAlignment.Left
    l.ZIndex = 54
    l.Parent = f

    local b = Instance.new("TextButton")
    b.Size = UDim2.new(0, 54, 0, 26)
    b.Position = UDim2.new(1, -60, 0.5, -13)
    b.BackgroundColor3 = SPY.ON[key] and C.green or Color3.fromRGB(50, 20, 20)
    b.Text = SPY.ON[key] and "ON" or "OFF"
    b.TextColor3 = Color3.new(1, 1, 1)
    b.Font = Enum.Font.SourceSansBold
    b.TextSize = 12
    b.BorderSizePixel = 0
    b.ZIndex = 54
    b.Parent = f

    b.MouseButton1Click:Connect(function()
        SPY.ON[key] = not SPY.ON[key]
        b.Text = SPY.ON[key] and "ON" or "OFF"
        b.BackgroundColor3 = SPY.ON[key] and C.green or Color3.fromRGB(50, 20, 20)
        f.BackgroundColor3 = SPY.ON[key] and Color3.fromRGB(14, 20, 14) or C.card
        if SPY.ON[key] and onCB then pcall(onCB) end
        if not SPY.ON[key] and offCB then pcall(offCB) end
    end)
end

function SPY.addSlider(tabName, text, key, min, max, step)
    SPY.V = SPY.V or {}
    SPY.V[key] = SPY.V[key] or min
    local parent = SPY.tabs[tabName]
    if not parent then return end

    local f = Instance.new("Frame")
    f.Size = UDim2.new(1, 0, 0, 34)
    f.BackgroundColor3 = Color3.fromRGB(10, 10, 22)
    f.BorderSizePixel = 0
    f.ZIndex = 53
    f.Parent = parent

    local l = Instance.new("TextLabel")
    l.Size = UDim2.new(0.42, 0, 1, 0)
    l.Position = UDim2.new(0, 10, 0, 0)
    l.BackgroundTransparency = 1
    l.Text = text .. ": " .. SPY.V[key]
    l.TextColor3 = C.textDim
    l.Font = Enum.Font.SourceSans
    l.TextSize = 11
    l.TextXAlignment = Enum.TextXAlignment.Left
    l.ZIndex = 54
    l.Parent = f

    local mb = Instance.new("TextButton")
    mb.Size = UDim2.new(0, 34, 0, 24)
    mb.Position = UDim2.new(0.46, 0, 0.5, -12)
    mb.BackgroundColor3 = Color3.fromRGB(55, 18, 18)
    mb.Text = "-"
    mb.TextColor3 = Color3.new(1, 1, 1)
    mb.Font = Enum.Font.SourceSansBold
    mb.TextSize = 16
    mb.BorderSizePixel = 0
    mb.ZIndex = 54
    mb.Parent = f

    local vl = Instance.new("TextLabel")
    vl.Size = UDim2.new(0, 44, 0, 24)
    vl.Position = UDim2.new(0.46, 38, 0.5, -12)
    vl.BackgroundTransparency = 1
    vl.Text = tostring(SPY.V[key])
    vl.TextColor3 = Color3.fromRGB(255, 200, 60)
    vl.Font = Enum.Font.SourceSansBold
    vl.TextSize = 13
    vl.ZIndex = 54
    vl.Parent = f

    local pb = Instance.new("TextButton")
    pb.Size = UDim2.new(0, 34, 0, 24)
    pb.Position = UDim2.new(0.46, 86, 0.5, -12)
    pb.BackgroundColor3 = Color3.fromRGB(18, 55, 18)
    pb.Text = "+"
    pb.TextColor3 = Color3.new(1, 1, 1)
    pb.Font = Enum.Font.SourceSansBold
    pb.TextSize = 16
    pb.BorderSizePixel = 0
    pb.ZIndex = 54
    pb.Parent = f

    mb.MouseButton1Click:Connect(function()
        SPY.V[key] = math.max(min, SPY.V[key] - step)
        vl.Text = tostring(SPY.V[key])
        l.Text = text .. ": " .. SPY.V[key]
    end)
    pb.MouseButton1Click:Connect(function()
        SPY.V[key] = math.min(max, SPY.V[key] + step)
        vl.Text = tostring(SPY.V[key])
        l.Text = text .. ": " .. SPY.V[key]
    end)
end

function SPY.clearTab(tabName)
    local parent = SPY.tabs[tabName]
    if not parent then return end
    for _, c in ipairs(parent:GetChildren()) do
        if c:IsA("TextLabel") or c:IsA("TextButton") or c:IsA("Frame") then
            c:Destroy()
        end
    end
end

-- Remote entry builder
function SPY.addRemoteEntry(data)
    local parent = SPY.tabs["Remotes"]
    if not parent then return end

    local count = 0
    for _, c in ipairs(parent:GetChildren()) do
        if c:IsA("Frame") then count = count + 1 end
    end
    if count > 80 then
        for _, c in ipairs(parent:GetChildren()) do
            if c:IsA("Frame") then c:Destroy() break end
        end
    end

    local f = Instance.new("Frame")
    f.Size = UDim2.new(1, 0, 0, 0)
    f.AutomaticSize = Enum.AutomaticSize.Y
    f.BackgroundColor3 = data.method == "FireServer" and Color3.fromRGB(10, 16, 10) or Color3.fromRGB(10, 10, 18)
    f.BorderSizePixel = 0
    f.ZIndex = 53
    f.Parent = parent

    local fp = Instance.new("UIPadding", f)
    fp.PaddingLeft = UDim.new(0, 6)
    fp.PaddingTop = UDim.new(0, 3)
    fp.PaddingBottom = UDim.new(0, 3)
    fp.PaddingRight = UDim.new(0, 4)

    local headerCol = data.method == "FireServer" and Color3.fromRGB(80, 230, 120) or Color3.fromRGB(100, 150, 255)

    local h = Instance.new("TextLabel")
    h.Size = UDim2.new(1, 0, 0, 14)
    h.BackgroundTransparency = 1
    h.Text = data.time .. "s  " .. data.method .. " -> " .. data.name
    h.TextColor3 = headerCol
    h.Font = Enum.Font.SourceSansBold
    h.TextSize = 10
    h.TextXAlignment = Enum.TextXAlignment.Left
    h.ZIndex = 54
    h.Parent = f

    local a = Instance.new("TextLabel")
    a.Size = UDim2.new(1, 0, 0, 0)
    a.Position = UDim2.new(0, 0, 0, 14)
    a.AutomaticSize = Enum.AutomaticSize.Y
    a.BackgroundTransparency = 1
    a.Text = "  " .. data.args
    a.TextColor3 = Color3.fromRGB(160, 160, 180)
    a.Font = Enum.Font.Code
    a.TextSize = 9
    a.TextXAlignment = Enum.TextXAlignment.Left
    a.TextWrapped = true
    a.ZIndex = 54
    a.Parent = f

    pcall(function()
        SPY.countLbl.Text = #SPY.remotes .. " remotes"
    end)
end

-- ══════════════════════════════════
-- FPS COUNTER (status bar)
-- ══════════════════════════════════
task.spawn(function()
    while true do
        task.wait(2)
        pcall(function()
            local fps = math.floor(1 / RS.Heartbeat:Wait())
            statusBar.Text = "  " .. lp.Name .. " | " .. game.PlaceId .. " | " .. fps .. " FPS | YHMH SPY v2"
        end)
    end
end)

SPY._open = false

print("[SPY GUI v2] 7 tabs | OK")
