-- YHMH SPY GUI
-- Interface com 4 tabs: Remotes, Tree, Players, Export
local SPY = getgenv().SPY
local lp = SPY.lp
local UIS = game:GetService("UserInputService")

pcall(function()
    local old = lp.PlayerGui:FindFirstChild("YHSpy")
    if old then old:Destroy() end
end)

local sg = Instance.new("ScreenGui")
sg.Name = "YHSpy"
sg.ResetOnSpawn = false
sg.Parent = lp:WaitForChild("PlayerGui")
SPY.sg = sg

-- Toggle button
local mBtn = Instance.new("TextButton")
mBtn.Size = UDim2.new(0, 48, 0, 48)
mBtn.Position = UDim2.new(0, 8, 0.25, 0)
mBtn.BackgroundColor3 = Color3.fromRGB(220, 60, 20)
mBtn.Text = "SP"
mBtn.TextColor3 = Color3.new(1, 1, 1)
mBtn.Font = Enum.Font.SourceSansBold
mBtn.TextSize = 16
mBtn.BorderSizePixel = 0
mBtn.ZIndex = 200
mBtn.Parent = sg

-- Panel
local panel = Instance.new("Frame")
panel.Name = "SpyPanel"
panel.Size = UDim2.new(0.94, 0, 0.88, 0)
panel.Position = UDim2.new(0.03, 0, 0.06, 0)
panel.BackgroundColor3 = Color3.fromRGB(8, 8, 14)
panel.BorderSizePixel = 0
panel.Visible = false
panel.ZIndex = 50
panel.Parent = sg

-- Title bar
local tBar = Instance.new("Frame")
tBar.Size = UDim2.new(1, 0, 0, 34)
tBar.BackgroundColor3 = Color3.fromRGB(220, 60, 20)
tBar.BorderSizePixel = 0
tBar.ZIndex = 51
tBar.Parent = panel

local tLbl = Instance.new("TextLabel")
tLbl.Size = UDim2.new(0.6, 0, 1, 0)
tLbl.Position = UDim2.new(0, 10, 0, 0)
tLbl.BackgroundTransparency = 1
tLbl.Text = "YHMH SPY"
tLbl.TextColor3 = Color3.new(1, 1, 1)
tLbl.Font = Enum.Font.SourceSansBold
tLbl.TextSize = 14
tLbl.TextXAlignment = Enum.TextXAlignment.Left
tLbl.ZIndex = 52
tLbl.Parent = tBar

SPY.countLbl = Instance.new("TextLabel")
SPY.countLbl.Size = UDim2.new(0.35, 0, 1, 0)
SPY.countLbl.Position = UDim2.new(0.6, 0, 0, 0)
SPY.countLbl.BackgroundTransparency = 1
SPY.countLbl.Text = "0 captured"
SPY.countLbl.TextColor3 = Color3.fromRGB(255, 200, 150)
SPY.countLbl.Font = Enum.Font.SourceSans
SPY.countLbl.TextSize = 11
SPY.countLbl.TextXAlignment = Enum.TextXAlignment.Right
SPY.countLbl.ZIndex = 52
SPY.countLbl.Parent = tBar

local xBtn = Instance.new("TextButton")
xBtn.Size = UDim2.new(0, 34, 0, 34)
xBtn.Position = UDim2.new(1, -34, 0, 0)
xBtn.BackgroundTransparency = 1
xBtn.Text = "X"
xBtn.TextColor3 = Color3.fromRGB(255, 180, 180)
xBtn.Font = Enum.Font.SourceSansBold
xBtn.TextSize = 18
xBtn.ZIndex = 52
xBtn.Parent = tBar

SPY._open = false
local function togglePanel()
    SPY._open = not SPY._open
    panel.Visible = SPY._open
    mBtn.Text = SPY._open and "X" or "SP"
    mBtn.BackgroundColor3 = SPY._open and Color3.fromRGB(180, 30, 30) or Color3.fromRGB(220, 60, 20)
end
mBtn.MouseButton1Click:Connect(togglePanel)
xBtn.MouseButton1Click:Connect(togglePanel)

-- Drag title bar
local dP, dS, dO = false, nil, nil
tBar.InputBegan:Connect(function(i)
    if i.UserInputType == Enum.UserInputType.Touch or i.UserInputType == Enum.UserInputType.MouseButton1 then
        dP = true; dS = i.Position; dO = panel.Position
    end
end)
tBar.InputEnded:Connect(function(i)
    if i.UserInputType == Enum.UserInputType.Touch or i.UserInputType == Enum.UserInputType.MouseButton1 then dP = false end
end)
UIS.InputChanged:Connect(function(i)
    if dP and (i.UserInputType == Enum.UserInputType.Touch or i.UserInputType == Enum.UserInputType.MouseMovement) then
        if dS then
            local d = i.Position - dS
            panel.Position = UDim2.new(dO.X.Scale, dO.X.Offset + d.X, dO.Y.Scale, dO.Y.Offset + d.Y)
        end
    end
end)

-- Tab bar
local tabNames = {"Remotes", "Tree", "Players", "Export"}
local tabBar = Instance.new("Frame")
tabBar.Size = UDim2.new(1, 0, 0, 32)
tabBar.Position = UDim2.new(0, 0, 0, 34)
tabBar.BackgroundColor3 = Color3.fromRGB(12, 12, 22)
tabBar.BorderSizePixel = 0
tabBar.ZIndex = 51
tabBar.Parent = panel

SPY.tabs = {}
SPY.tabBtns = {}

for i, name in ipairs(tabNames) do
    local b = Instance.new("TextButton")
    b.Size = UDim2.new(1 / #tabNames, -1, 0, 26)
    b.Position = UDim2.new((i - 1) / #tabNames, 0, 0.5, -13)
    b.BackgroundColor3 = i == 1 and Color3.fromRGB(220, 60, 20) or Color3.fromRGB(20, 20, 34)
    b.Text = name
    b.TextColor3 = Color3.new(1, 1, 1)
    b.Font = Enum.Font.SourceSansBold
    b.TextSize = 11
    b.BorderSizePixel = 0
    b.ZIndex = 52
    b.Parent = tabBar
    SPY.tabBtns[name] = b

    local f = Instance.new("ScrollingFrame")
    f.Size = UDim2.new(1, -6, 1, -72)
    f.Position = UDim2.new(0, 3, 0, 69)
    f.BackgroundTransparency = 1
    f.BorderSizePixel = 0
    f.ScrollBarThickness = 3
    f.ScrollBarImageColor3 = Color3.fromRGB(220, 60, 20)
    f.CanvasSize = UDim2.new(0, 0, 0, 0)
    f.AutomaticCanvasSize = Enum.AutomaticSize.Y
    f.Visible = i == 1
    f.ZIndex = 51
    f.Parent = panel
    Instance.new("UIListLayout", f).Padding = UDim.new(0, 2)
    local p = Instance.new("UIPadding", f)
    p.PaddingLeft = UDim.new(0, 3)
    p.PaddingRight = UDim.new(0, 3)
    p.PaddingTop = UDim.new(0, 3)
    SPY.tabs[name] = f

    b.MouseButton1Click:Connect(function()
        for n, tb in pairs(SPY.tabBtns) do
            tb.BackgroundColor3 = n == name and Color3.fromRGB(220, 60, 20) or Color3.fromRGB(20, 20, 34)
        end
        for n, tf in pairs(SPY.tabs) do
            tf.Visible = n == name
        end
    end)
end

-- Builder: add text line to a tab
function SPY.addLine(tabName, text, color)
    local parent = SPY.tabs[tabName]
    if not parent then return end
    local l = Instance.new("TextLabel")
    l.Size = UDim2.new(1, 0, 0, 0)
    l.AutomaticSize = Enum.AutomaticSize.Y
    l.BackgroundTransparency = 1
    l.Text = text
    l.TextColor3 = color or Color3.fromRGB(200, 200, 215)
    l.Font = Enum.Font.Code
    l.TextSize = 10
    l.TextXAlignment = Enum.TextXAlignment.Left
    l.TextWrapped = true
    l.ZIndex = 53
    l.Parent = parent
end

-- Builder: add header line
function SPY.addHeader(tabName, text)
    local parent = SPY.tabs[tabName]
    if not parent then return end
    local l = Instance.new("TextLabel")
    l.Size = UDim2.new(1, 0, 0, 20)
    l.BackgroundColor3 = Color3.fromRGB(220, 60, 20)
    l.BackgroundTransparency = 0.8
    l.Text = "  " .. text
    l.TextColor3 = Color3.fromRGB(255, 180, 130)
    l.Font = Enum.Font.SourceSansBold
    l.TextSize = 11
    l.TextXAlignment = Enum.TextXAlignment.Left
    l.ZIndex = 53
    l.Parent = parent
end

-- Builder: add button
function SPY.addButton(tabName, text, color, cb)
    local parent = SPY.tabs[tabName]
    if not parent then return end
    local b = Instance.new("TextButton")
    b.Size = UDim2.new(0.48, 0, 0, 36)
    b.BackgroundColor3 = color or Color3.fromRGB(25, 25, 40)
    b.Text = text
    b.TextColor3 = Color3.new(1, 1, 1)
    b.Font = Enum.Font.SourceSansBold
    b.TextSize = 12
    b.BorderSizePixel = 0
    b.ZIndex = 53
    b.Parent = parent
    b.MouseButton1Click:Connect(function() pcall(cb) end)
    return b
end

-- Builder: clear tab
function SPY.clearTab(tabName)
    local parent = SPY.tabs[tabName]
    if not parent then return end
    for _, c in ipairs(parent:GetChildren()) do
        if c:IsA("TextLabel") or c:IsA("TextButton") then
            c:Destroy()
        end
    end
end

-- Remote entry builder (used by spy_remotes)
function SPY.addRemoteEntry(data)
    local parent = SPY.tabs["Remotes"]
    if not parent then return end

    -- Limitar entradas visuais
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
    f.BackgroundColor3 = data.method == "FireServer" and Color3.fromRGB(12, 16, 12) or Color3.fromRGB(12, 12, 18)
    f.BorderSizePixel = 0
    f.ZIndex = 53
    f.Parent = parent

    local fp = Instance.new("UIPadding", f)
    fp.PaddingLeft = UDim.new(0, 6)
    fp.PaddingTop = UDim.new(0, 3)
    fp.PaddingBottom = UDim.new(0, 3)

    local headerColor = data.method == "FireServer" and Color3.fromRGB(80, 220, 120) or Color3.fromRGB(120, 160, 255)

    local h = Instance.new("TextLabel")
    h.Size = UDim2.new(1, -6, 0, 14)
    h.BackgroundTransparency = 1
    h.Text = data.time .. " " .. data.method .. " -> " .. data.name
    h.TextColor3 = headerColor
    h.Font = Enum.Font.SourceSansBold
    h.TextSize = 10
    h.TextXAlignment = Enum.TextXAlignment.Left
    h.ZIndex = 54
    h.Parent = f

    local a = Instance.new("TextLabel")
    a.Size = UDim2.new(1, -6, 0, 0)
    a.Position = UDim2.new(0, 0, 0, 14)
    a.AutomaticSize = Enum.AutomaticSize.Y
    a.BackgroundTransparency = 1
    a.Text = "  " .. data.args
    a.TextColor3 = Color3.fromRGB(150, 150, 170)
    a.Font = Enum.Font.Code
    a.TextSize = 9
    a.TextXAlignment = Enum.TextXAlignment.Left
    a.TextWrapped = true
    a.ZIndex = 54
    a.Parent = f

    if data.path then
        local p = Instance.new("TextLabel")
        p.Size = UDim2.new(1, -6, 0, 10)
        p.Position = UDim2.new(0, 0, 1, 0)
        p.BackgroundTransparency = 1
        p.Text = "  " .. data.path
        p.TextColor3 = Color3.fromRGB(80, 80, 100)
        p.Font = Enum.Font.Code
        p.TextSize = 8
        p.TextXAlignment = Enum.TextXAlignment.Left
        p.ZIndex = 54
        p.Parent = f
    end

    -- Update counter
    pcall(function()
        SPY.countLbl.Text = #SPY.remotes .. " captured"
    end)
end

print("[SPY GUI] OK")
