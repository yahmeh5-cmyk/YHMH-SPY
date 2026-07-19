-- YHMH SPY — Remote Capture
-- Captura todos FireServer/InvokeServer com args completos
local SPY = getgenv().SPY
local lp = SPY.lp
local startTime = os.clock()

-- Serializer robusto
local function ser(v, depth)
    depth = depth or 0
    if depth > 4 then return "..." end
    local t = typeof(v)
    if v == nil then return "nil"
    elseif t == "string" then
        local s = v
        if #s > 80 then s = s:sub(1, 80) .. "..." end
        return '"' .. s .. '"'
    elseif t == "number" then return tostring(v)
    elseif t == "boolean" then return tostring(v)
    elseif t == "Instance" then
        local ok, path = pcall(function() return v:GetFullName() end)
        local ok2, cls = pcall(function() return v.ClassName end)
        return "Instance<" .. (ok2 and cls or "?") .. ": " .. (ok and path or "?") .. ">"
    elseif t == "Vector3" then
        return "Vector3(" .. string.format("%.1f, %.1f, %.1f", v.X, v.Y, v.Z) .. ")"
    elseif t == "Vector2" then
        return "Vector2(" .. string.format("%.1f, %.1f", v.X, v.Y) .. ")"
    elseif t == "CFrame" then
        return "CFrame(" .. string.format("%.1f, %.1f, %.1f", v.X, v.Y, v.Z) .. ")"
    elseif t == "Color3" then
        return "Color3(" .. string.format("%.2f, %.2f, %.2f", v.R, v.G, v.B) .. ")"
    elseif t == "UDim2" then
        return "UDim2(" .. tostring(v) .. ")"
    elseif t == "EnumItem" then
        return tostring(v)
    elseif t == "table" then
        local parts = {}
        local count = 0
        for k, val in pairs(v) do
            count = count + 1
            if count > 10 then
                table.insert(parts, "...+" .. count)
                break
            end
            local ks = type(k) == "number" and ("[" .. k .. "]") or tostring(k)
            table.insert(parts, ks .. "=" .. ser(val, depth + 1))
        end
        return "{ " .. table.concat(parts, ", ") .. " }"
    else
        return t .. "(" .. tostring(v) .. ")"
    end
end

local function serArgs(args)
    local parts = {}
    for i, a in ipairs(args) do
        table.insert(parts, ser(a))
    end
    return table.concat(parts, ", ")
end

-- Controles na tab Remotes
local rTab = SPY.tabs["Remotes"]

-- Botoes de controle
local ctrlFrame = Instance.new("Frame")
ctrlFrame.Size = UDim2.new(1, 0, 0, 38)
ctrlFrame.BackgroundTransparency = 1
ctrlFrame.ZIndex = 53
ctrlFrame.Parent = rTab

local pauseBtn = Instance.new("TextButton")
pauseBtn.Size = UDim2.new(0.3, -2, 0, 32)
pauseBtn.Position = UDim2.new(0, 0, 0, 3)
pauseBtn.BackgroundColor3 = Color3.fromRGB(30, 80, 30)
pauseBtn.Text = "Pause"
pauseBtn.TextColor3 = Color3.new(1, 1, 1)
pauseBtn.Font = Enum.Font.SourceSansBold
pauseBtn.TextSize = 12
pauseBtn.BorderSizePixel = 0
pauseBtn.ZIndex = 54
pauseBtn.Parent = ctrlFrame
pauseBtn.MouseButton1Click:Connect(function()
    SPY.paused = not SPY.paused
    pauseBtn.Text = SPY.paused and "Resume" or "Pause"
    pauseBtn.BackgroundColor3 = SPY.paused and Color3.fromRGB(180, 120, 20) or Color3.fromRGB(30, 80, 30)
end)

local clearBtn = Instance.new("TextButton")
clearBtn.Size = UDim2.new(0.3, -2, 0, 32)
clearBtn.Position = UDim2.new(0.32, 0, 0, 3)
clearBtn.BackgroundColor3 = Color3.fromRGB(120, 25, 25)
clearBtn.Text = "Clear"
clearBtn.TextColor3 = Color3.new(1, 1, 1)
clearBtn.Font = Enum.Font.SourceSansBold
clearBtn.TextSize = 12
clearBtn.BorderSizePixel = 0
clearBtn.ZIndex = 54
clearBtn.Parent = ctrlFrame
clearBtn.MouseButton1Click:Connect(function()
    SPY.remotes = {}
    SPY.remoteCounts = {}
    for _, c in ipairs(rTab:GetChildren()) do
        if c:IsA("Frame") and c ~= ctrlFrame then c:Destroy() end
    end
    pcall(function() SPY.countLbl.Text = "0 captured" end)
end)

local filterBtn = Instance.new("TextBox")
filterBtn.Size = UDim2.new(0.36, -2, 0, 32)
filterBtn.Position = UDim2.new(0.64, 0, 0, 3)
filterBtn.BackgroundColor3 = Color3.fromRGB(15, 15, 30)
filterBtn.PlaceholderText = "Filter..."
filterBtn.PlaceholderColor3 = Color3.fromRGB(80, 80, 110)
filterBtn.Text = ""
filterBtn.TextColor3 = Color3.fromRGB(255, 200, 100)
filterBtn.Font = Enum.Font.Code
filterBtn.TextSize = 11
filterBtn.ClearTextOnFocus = false
filterBtn.BorderSizePixel = 0
filterBtn.ZIndex = 54
filterBtn.Parent = ctrlFrame
filterBtn.FocusLost:Connect(function()
    SPY.filter = filterBtn.Text:lower()
end)

-- Hook
local hooked = false

pcall(function()
    local hookMM = hookmetamethod or (getgenv and getgenv().hookmetamethod)
    local getNCM = getnamecallmethod or (getgenv and getgenv().getnamecallmethod)

    if hookMM and getNCM then
        local old
        old = hookMM(game, "__namecall", function(self, ...)
            pcall(function()
                local method = getNCM()
                if (method == "FireServer" or method == "InvokeServer") and typeof(self) == "Instance" then
                    local isRemote = self:IsA("RemoteEvent") or self:IsA("RemoteFunction")
                    if not isRemote then return end
                    if SPY.paused then return end

                    local remoteName = self.Name
                    local remotePath = ""
                    pcall(function() remotePath = self:GetFullName() end)

                    -- Filter
                    if SPY.filter ~= "" and not remoteName:lower():find(SPY.filter, 1, true) then
                        return
                    end

                    local args = {...}
                    local argsStr = serArgs(args)
                    local timeStr = string.format("%.2f", os.clock() - startTime)

                    local entry = {
                        time = timeStr,
                        method = method,
                        name = remoteName,
                        path = remotePath,
                        args = argsStr,
                        rawArgs = args,
                    }

                    -- Armazenar
                    table.insert(SPY.remotes, 1, entry)
                    if #SPY.remotes > SPY.maxLog then
                        table.remove(SPY.remotes)
                    end

                    -- Contagem
                    SPY.remoteCounts[remoteName] = (SPY.remoteCounts[remoteName] or 0) + 1

                    -- Output buffer
                    table.insert(SPY.output, timeStr .. " " .. method .. " -> " .. remoteName .. "(" .. argsStr .. ") PATH:" .. remotePath)

                    -- GUI
                    SPY.addRemoteEntry(entry)
                end
            end)
            return old(self, ...)
        end)
        hooked = true
        print("[SPY REMOTES] hookmetamethod OK")
    end
end)

if not hooked then
    -- Fallback: monitorar OnClientEvent em todos os remotes
    print("[SPY REMOTES] hookmetamethod NAO disponivel")
    print("[SPY REMOTES] Usando fallback: OnClientEvent listener")
    pcall(function()
        local RS = game:GetService("ReplicatedStorage")
        for _, d in ipairs(RS:GetDescendants()) do
            pcall(function()
                if d:IsA("RemoteEvent") then
                    d.OnClientEvent:Connect(function(...)
                        if SPY.paused then return end
                        local args = {...}
                        local argsStr = serArgs(args)
                        local timeStr = string.format("%.2f", os.clock() - startTime)
                        local entry = {
                            time = timeStr,
                            method = "OnClient",
                            name = d.Name,
                            path = d:GetFullName(),
                            args = argsStr,
                        }
                        table.insert(SPY.remotes, 1, entry)
                        if #SPY.remotes > SPY.maxLog then table.remove(SPY.remotes) end
                        SPY.remoteCounts[d.Name] = (SPY.remoteCounts[d.Name] or 0) + 1
                        table.insert(SPY.output, timeStr .. " OnClient <- " .. d.Name .. "(" .. argsStr .. ")")
                        SPY.addRemoteEntry(entry)
                    end)
                end
            end)
        end
    end)
end

print("[SPY REMOTES] Captura ativa")
