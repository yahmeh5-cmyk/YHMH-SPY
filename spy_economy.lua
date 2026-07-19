-- YHMH SPY — Economy Scanner
-- Encontra moedas, testa vulnerabilidades, monitora mudanças
local SPY = getgenv().SPY
local lp = SPY.lp
local Players = game:GetService("Players")
local RS = game:GetService("ReplicatedStorage")
local WS = game:GetService("Workspace")

local treeTab = SPY.tabs["Tree"]

-- Palavras que indicam moeda/economia
local MONEY_WORDS = {
    "money","coin","coins","cash","gold","gem","gems","diamond","diamonds",
    "crystal","crystals","token","tokens","point","points","score","credit",
    "buck","bucks","dollar","yen","star","stars","energy","mana","soul",
    "fragment","orb","orbs","ruby","emerald","currency","balance","wallet",
    "bank","xp","exp","experience","level","ticket","key","dust","essence",
    "shard","chikara","power","chi","silver","platinum","medal","badge",
}

-- Palavras que indicam remotes de economia
local ECON_WORDS = {
    "buy","sell","purchase","shop","store","trade","exchange","market",
    "give","add","reward","claim","collect","earn","gain","spend","pay",
    "upgrade","rebirth","prestige","craft","merge","fuse","open","spin",
    "roll","gacha","hatch","egg","crate","chest","donate","gift","redeem",
    "code","promo","daily","hourly","bonus","free","lucky","wheel","slot",
}

local HONEYPOT_WORDS = {
    "givemoney","givecash","givecoins","givegems","addmoney","freemoney",
    "setmoney","setcash","godmode","killplayer","giveadmin","hackpanel",
}

SPY.addHeader("Tree", "ECONOMY SCANNER")

-- ══════════════════════════════════
-- SCAN ECONOMY
-- ══════════════════════════════════
SPY.addButton("Tree", "Scan Economy", Color3.fromRGB(180, 150, 30), function()
    SPY.clearTab("Tree")
    SPY.addHeader("Tree", "ECONOMY SCAN RESULTS")

    local currencies = {}
    local econRemotes = {}

    -- 1. LEADERSTATS
    SPY.addLine("Tree", "", nil)
    SPY.addLine("Tree", "--- LEADERSTATS ---", Color3.fromRGB(255, 200, 80))
    pcall(function()
        local ls = lp:FindFirstChild("leaderstats")
        if ls then
            for _, v in ipairs(ls:GetChildren()) do
                pcall(function()
                    if v:IsA("ValueBase") then
                        local line = v.Name .. " = " .. tostring(v.Value) .. " [" .. v.ClassName .. "]"
                        SPY.addLine("Tree", "  " .. line, Color3.fromRGB(255, 220, 100))
                        table.insert(currencies, {name = v.Name, value = v.Value, inst = v, source = "leaderstats"})
                        table.insert(SPY.output, "[ECON] leaderstats." .. line)
                    end
                end)
            end
        else
            SPY.addLine("Tree", "  (nenhum leaderstats)", Color3.fromRGB(120, 120, 140))
        end
    end)

    -- 2. PLAYER VALUES (moedas em Data folders)
    SPY.addLine("Tree", "", nil)
    SPY.addLine("Tree", "--- PLAYER VALUES ---", Color3.fromRGB(255, 200, 80))
    pcall(function()
        for _, d in ipairs(lp:GetDescendants()) do
            pcall(function()
                if d:IsA("ValueBase") and type(d.Value) == "number" then
                    local n = d.Name:lower()
                    for _, mw in ipairs(MONEY_WORDS) do
                        if n:find(mw, 1, true) then
                            local line = d.Name .. " = " .. tostring(d.Value) .. " @ " .. d:GetFullName()
                            SPY.addLine("Tree", "  " .. line, Color3.fromRGB(220, 200, 130))
                            table.insert(currencies, {name = d.Name, value = d.Value, inst = d, source = "PlayerValue"})
                            table.insert(SPY.output, "[ECON] " .. line)
                            break
                        end
                    end
                end
            end)
        end
    end)

    -- 3. PLAYER ATTRIBUTES
    SPY.addLine("Tree", "", nil)
    SPY.addLine("Tree", "--- PLAYER ATTRIBUTES ---", Color3.fromRGB(255, 200, 80))
    pcall(function()
        for k, v in pairs(lp:GetAttributes()) do
            if type(v) == "number" then
                local low = k:lower()
                for _, mw in ipairs(MONEY_WORDS) do
                    if low:find(mw, 1, true) then
                        local line = "@" .. k .. " = " .. tostring(v)
                        SPY.addLine("Tree", "  " .. line, Color3.fromRGB(200, 180, 130))
                        table.insert(currencies, {name = k, value = v, source = "Attribute", attrKey = k})
                        table.insert(SPY.output, "[ECON] " .. line)
                        break
                    end
                end
            end
        end
    end)

    -- 4. ALL NUMERIC VALUES (mostra tudo que é número no player)
    SPY.addLine("Tree", "", nil)
    SPY.addLine("Tree", "--- ALL NUMERIC VALUES ---", Color3.fromRGB(200, 180, 100))
    local numCount = 0
    pcall(function()
        for _, d in ipairs(lp:GetDescendants()) do
            pcall(function()
                if d:IsA("IntValue") or d:IsA("NumberValue") then
                    numCount = numCount + 1
                    if numCount <= 50 then
                        SPY.addLine("Tree", "  " .. d.Name .. " = " .. tostring(d.Value) .. " @ " .. d:GetFullName(), Color3.fromRGB(160, 160, 180))
                    end
                end
            end)
        end
    end)
    if numCount > 50 then
        SPY.addLine("Tree", "  ...+" .. (numCount - 50) .. " more", Color3.fromRGB(100, 100, 120))
    end
    SPY.addLine("Tree", "  Total numeric values: " .. numCount, Color3.fromRGB(100, 200, 100))

    -- 5. ECONOMY REMOTES
    SPY.addLine("Tree", "", nil)
    SPY.addLine("Tree", "--- ECONOMY REMOTES ---", Color3.fromRGB(255, 150, 100))
    pcall(function()
        for _, d in ipairs(RS:GetDescendants()) do
            pcall(function()
                if d:IsA("RemoteEvent") or d:IsA("RemoteFunction") then
                    local n = d.Name:lower()
                    for _, ew in ipairs(ECON_WORDS) do
                        if n:find(ew, 1, true) then
                            local line = d.Name .. " [" .. d.ClassName .. "] " .. d:GetFullName()
                            SPY.addLine("Tree", "  " .. line, Color3.fromRGB(255, 160, 120))
                            table.insert(econRemotes, {inst = d, name = d.Name, keyword = ew})
                            table.insert(SPY.output, "[ECON REMOTE] " .. line)
                            break
                        end
                    end
                end
            end)
        end
    end)
    SPY.addLine("Tree", "  Economy remotes: " .. #econRemotes, Color3.fromRGB(100, 200, 100))

    -- 6. HONEYPOTS
    SPY.addLine("Tree", "", nil)
    SPY.addLine("Tree", "--- HONEYPOTS (DANGER!) ---", Color3.fromRGB(255, 80, 80))
    local hpCount = 0
    pcall(function()
        for _, d in ipairs(RS:GetDescendants()) do
            pcall(function()
                if d:IsA("RemoteEvent") or d:IsA("RemoteFunction") then
                    local n = d.Name:lower():gsub("[%s_%-]", "")
                    for _, hp in ipairs(HONEYPOT_WORDS) do
                        if n:find(hp, 1, true) then
                            SPY.addLine("Tree", "  HONEYPOT: " .. d.Name .. " — NAO DISPARE!", Color3.fromRGB(255, 60, 60))
                            table.insert(SPY.output, "[HONEYPOT] " .. d.Name .. " " .. d:GetFullName())
                            hpCount = hpCount + 1
                            break
                        end
                    end
                end
            end)
        end
    end)
    if hpCount == 0 then
        SPY.addLine("Tree", "  Nenhum honeypot detectado", Color3.fromRGB(100, 200, 100))
    end

    -- SUMMARY
    SPY.addLine("Tree", "", nil)
    SPY.addLine("Tree", "--- SUMMARY ---", Color3.fromRGB(100, 255, 150))
    SPY.addLine("Tree", "  Currencies: " .. #currencies, Color3.fromRGB(200, 200, 220))
    SPY.addLine("Tree", "  Econ remotes: " .. #econRemotes, Color3.fromRGB(200, 200, 220))
    SPY.addLine("Tree", "  Honeypots: " .. hpCount, Color3.fromRGB(200, 200, 220))
    SPY.addLine("Tree", "  Numeric values: " .. numCount, Color3.fromRGB(200, 200, 220))

    -- Salvar para uso por outros modulos
    SPY.currencies = currencies
    SPY.econRemotes = econRemotes
end)

-- ══════════════════════════════════
-- TEST VULNERABILITIES
-- ══════════════════════════════════
SPY.addButton("Tree", "Test Vulns", Color3.fromRGB(200, 50, 30), function()
    SPY.clearTab("Tree")
    SPY.addHeader("Tree", "VULNERABILITY TEST")
    SPY.addLine("Tree", "Testing...", Color3.fromRGB(255, 200, 100))

    local vulns = 0

    -- Test 1: leaderstats editable?
    SPY.addLine("Tree", "", nil)
    SPY.addLine("Tree", "--- TEST 1: Client-side edit ---", Color3.fromRGB(255, 180, 80))
    pcall(function()
        local ls = lp:FindFirstChild("leaderstats")
        if ls then
            for _, v in ipairs(ls:GetChildren()) do
                pcall(function()
                    if v:IsA("ValueBase") and type(v.Value) == "number" then
                        local orig = v.Value
                        v.Value = orig + 1
                        task.wait(0.5)
                        local after = v.Value
                        if after == orig + 1 then
                            SPY.addLine("Tree", "  VULN: " .. v.Name .. " editavel!", Color3.fromRGB(255, 80, 80))
                            table.insert(SPY.output, "[VULN] " .. v.Name .. " client-side editable")
                            vulns = vulns + 1
                        else
                            SPY.addLine("Tree", "  OK: " .. v.Name .. " protegido", Color3.fromRGB(100, 200, 100))
                        end
                        v.Value = orig
                    end
                end)
            end
        end
    end)

    -- Test 2: rate limiting
    SPY.addLine("Tree", "", nil)
    SPY.addLine("Tree", "--- TEST 2: Rate limiting ---", Color3.fromRGB(255, 180, 80))
    pcall(function()
        local tested = 0
        for _, d in ipairs(RS:GetDescendants()) do
            if tested >= 3 then break end
            pcall(function()
                if d:IsA("RemoteEvent") then
                    local n = d.Name:lower()
                    for _, ew in ipairs(ECON_WORDS) do
                        if n:find(ew, 1, true) then
                            local fires = 0
                            for _ = 1, 20 do
                                local ok = pcall(function() d:FireServer() end)
                                if ok then fires = fires + 1 end
                            end
                            if fires >= 18 then
                                SPY.addLine("Tree", "  NO LIMIT: " .. d.Name .. " (" .. fires .. "/20)", Color3.fromRGB(255, 200, 80))
                                table.insert(SPY.output, "[VULN] No rate limit: " .. d.Name)
                                vulns = vulns + 1
                            else
                                SPY.addLine("Tree", "  LIMITED: " .. d.Name .. " (" .. fires .. "/20)", Color3.fromRGB(100, 200, 100))
                            end
                            tested = tested + 1
                            break
                        end
                    end
                end
            end)
        end
    end)

    SPY.addLine("Tree", "", nil)
    SPY.addLine("Tree", "Vulnerabilities found: " .. vulns, vulns > 0 and Color3.fromRGB(255, 80, 80) or Color3.fromRGB(100, 255, 100))
end)

-- ══════════════════════════════════
-- MONITOR CURRENCY CHANGES
-- ══════════════════════════════════
SPY.addButton("Tree", "Watch Currency", Color3.fromRGB(30, 100, 80), function()
    SPY.addLine("Tree", "Currency monitor ACTIVE", Color3.fromRGB(100, 255, 150))
    SPY.addLine("Tree", "Changes will appear here + console", Color3.fromRGB(130, 130, 160))

    -- Watch leaderstats
    pcall(function()
        local ls = lp:FindFirstChild("leaderstats")
        if ls then
            for _, v in ipairs(ls:GetChildren()) do
                pcall(function()
                    if v:IsA("ValueBase") then
                        v.Changed:Connect(function(newVal)
                            local line = "CHANGED: " .. v.Name .. " = " .. tostring(newVal)
                            SPY.addLine("Tree", "  " .. line, Color3.fromRGB(255, 255, 100))
                            table.insert(SPY.output, "[CURRENCY] " .. line)
                            print("[CURRENCY] " .. line)
                        end)
                    end
                end)
            end
        end
    end)

    -- Watch Data folders
    pcall(function()
        for _, child in ipairs(lp:GetChildren()) do
            if child:IsA("Folder") then
                for _, v in ipairs(child:GetDescendants()) do
                    pcall(function()
                        if v:IsA("ValueBase") and type(v.Value) == "number" then
                            v.Changed:Connect(function(newVal)
                                local line = "CHANGED: " .. child.Name .. "." .. v.Name .. " = " .. tostring(newVal)
                                SPY.addLine("Tree", "  " .. line, Color3.fromRGB(255, 220, 80))
                                table.insert(SPY.output, "[CURRENCY] " .. line)
                                print("[CURRENCY] " .. line)
                            end)
                        end
                    end)
                end
            end
        end
    end)
end)

print("[SPY ECONOMY] OK")
