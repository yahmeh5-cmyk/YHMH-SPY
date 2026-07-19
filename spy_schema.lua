-- YHMH SPY — Schema Capture v3
-- Cobre dot-notation, retornos de InvokeServer, server->client
-- e agrega assinatura+comandos por remote. Adicionar ao loader.
local SPY = getgenv().SPY
local startTime = os.clock()

SPY.schema = SPY.schema or {}   -- [name] = { methods={}, argTypes={}, cmdValues={}, returnSample, count }

-- executor compat
local hookfn   = hookfunction or replaceclosure or (getgenv and getgenv().hookfunction)
local newcc    = newcclosure or function(f) return f end
local ischecked= checkcaller or function() return false end

local function typeStr(v) return typeof(v) end

-- resumo curto de um valor pra amostra
local function sample(v, d)
 d = d or 0
 local t = typeof(v)
 if t == "string" then return #v > 40 and ('"'..v:sub(1,40)..'..."') or ('"'..v..'"')
 elseif t == "number" or t == "boolean" then return tostring(v)
 elseif t == "Instance" then return "Instance<"..v.ClassName..">"
 elseif t == "table" and d < 2 then
  local p = {} local c = 0
  for k,val in pairs(v) do c=c+1 if c>6 then p[#p+1]="..." break end
   p[#p+1]=(type(k)=="number" and ("["..k.."]") or tostring(k)).."="..sample(val,d+1) end
  return "{"..table.concat(p,", ").."}"
 else return t end
end

-- registra uma chamada no schema
local function record(name, method, args, ret)
 local s = SPY.schema[name]
 if not s then s = {methods={}, argTypes={}, cmdValues={}, count=0} SPY.schema[name]=s end
 s.count = s.count + 1
 s.methods[method] = true
 for i, a in ipairs(args) do
  s.argTypes[i] = s.argTypes[i] or {}
  s.argTypes[i][typeStr(a)] = true
 end
 -- 1º arg costuma ser o comando: coletar valores distintos
 if type(args[1]) == "string" then
  s.cmdValues[args[1]] = (s.cmdValues[args[1]] or 0) + 1
 end
 if ret ~= nil and s.returnSample == nil then s.returnSample = sample(ret) end
end

-- ── HOOK 1: __namecall (dois-pontos) + captura de retorno ──
pcall(function()
 local hookMM = hookmetamethod or (getgenv and getgenv().hookmetamethod)
 local getNCM = getnamecallmethod or (getgenv and getgenv().getnamecallmethod)
 if not (hookMM and getNCM) then return end
 local old
 old = hookMM(game, "__namecall", newcc(function(self, ...)
  local method, isRemote
  pcall(function() method = getNCM() end)
  pcall(function() isRemote = typeof(self)=="Instance" and (self:IsA("RemoteEvent") or self:IsA("RemoteFunction")) end)
  if not (isRemote and (method=="FireServer" or method=="InvokeServer")) then
   return old(self, ...)
  end
  local args = {...}
  if method == "InvokeServer" then
   local rets = {old(self, ...)}                 -- <<< captura RETORNO
   pcall(function() record(self.Name, method, args, rets[1]) end)
   return unpack(rets)
  else
   pcall(function() record(self.Name, method, args, nil) end)
   return old(self, ...)
  end
 end))
 print("[SCHEMA] namecall hook OK")
end)

-- ── HOOK 2: dot-notation (Remote.FireServer(Remote, ...)) ──
-- Cobre o caso que o namecall NAO pega (metodo em cache)
pcall(function()
 if not hookfn then print("[SCHEMA] hookfunction indisponivel, dot-notation nao coberto") return end
 local re = Instance.new("RemoteEvent")
 local rf = Instance.new("RemoteFunction")
 local realFire, realInvoke = re.FireServer, rf.InvokeServer
 local newFire, newInvoke
 newFire = hookfn(realFire, newcc(function(self, ...)
  if not ischecked() then pcall(function()
   if typeof(self)=="Instance" then record(self.Name, "FireServer", {...}, nil) end end) end
  return newFire(self, ...)
 end))
 newInvoke = hookfn(realInvoke, newcc(function(self, ...)
  local rets = {newInvoke(self, ...)}
  if not ischecked() then pcall(function()
   if typeof(self)=="Instance" then record(self.Name, "InvokeServer", {...}, rets[1]) end end) end
  return unpack(rets)
 end))
 print("[SCHEMA] dot-notation hook OK")
end)

-- ── HOOK 3: server -> client (OnClientEvent / OnClientInvoke) ──
pcall(function()
 local RS = game:GetService("ReplicatedStorage")
 for _, d in ipairs(RS:GetDescendants()) do
  pcall(function()
   if d:IsA("RemoteEvent") then
    d.OnClientEvent:Connect(function(...)
     pcall(function() record(d.Name, "OnClientEvent", {...}, nil) end)
    end)
   end
  end)
 end
 print("[SCHEMA] server->client listeners OK")
end)

-- ── EXPORT: assinatura limpa por remote ──
SPY.addHeader("Export", "SCHEMA (assinaturas)")
SPY.addButton("Export", "Copy SCHEMA", Color3.fromRGB(20, 130, 120), function()
 local L = {"=== REMOTE SCHEMA ===", "PlaceId: "..tostring(game.PlaceId), ""}
 for name, s in pairs(SPY.schema) do
  local methods = {} for m in pairs(s.methods) do methods[#methods+1]=m end
  L[#L+1] = "▶ "..name.."  ["..table.concat(methods,"/").."]  x"..s.count
  for i, set in ipairs(s.argTypes) do
   local ts = {} for t in pairs(set) do ts[#ts+1]=t end
   L[#L+1] = "   arg"..i..": "..table.concat(ts, "|")
  end
  local cmds = {} for c,n in pairs(s.cmdValues) do cmds[#cmds+1]=c.." (x"..n..")" end
  if #cmds > 0 then L[#L+1] = "   COMANDOS: "..table.concat(cmds, ", ") end
  if s.returnSample then L[#L+1] = "   RETORNO: "..s.returnSample end
  L[#L+1] = ""
 end
 local text = table.concat(L, "\n")
 local ok=false
 pcall(function() if setclipboard then setclipboard(text) ok=true end end)
 if ok then SPY.addLine("Export","SCHEMA copiado! "..#text.." chars", Color3.fromRGB(100,255,100))
 else print(text) SPY.addLine("Export","SCHEMA no console", Color3.fromRGB(255,200,100)) end
end)

print("[SPY SCHEMA] OK")
