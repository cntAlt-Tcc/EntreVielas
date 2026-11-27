-- Mock mínimo de Roblox para exercitar o bloco ESP do Script/A.
-- Só o que o ESP toca: services, Instance, Drawing, Vector2/3, Color3, Enum,
-- RunService (conexões capturadas), CoreGui.

local M = {}
__M = M

-- ===== vetores =====
local Vector2 = {}
Vector2.__index = Vector2
function Vector2.new(x, y)
    return setmetatable({ X = x or 0, Y = y or 0 }, Vector2)
end
Vector2.__add = function(a, b) return Vector2.new(a.X + b.X, a.Y + b.Y) end
Vector2.__sub = function(a, b) return Vector2.new(a.X - b.X, a.Y - b.Y) end
Vector2.__eq = function(a, b) return a.X == b.X and a.Y == b.Y end
Vector2.__mul = function(a, b)
    if type(a) == "number" then return Vector2.new(a * b.X, a * b.Y) end
    if type(b) == "number" then return Vector2.new(a.X * b, a.Y * b) end
    return Vector2.new(a.X * b.X, a.Y * b.Y)
end
Vector2.__div = function(a, b) return Vector2.new(a.X / b, a.Y / b) end
Vector2.__unm = function(a) return Vector2.new(-a.X, -a.Y) end
Vector2.__tostring = function(a) return string.format("(%.1f, %.1f)", a.X, a.Y) end

local Vector3 = {}
Vector3.__index = Vector3
function Vector3.new(x, y, z)
    return setmetatable({ X = x or 0, Y = y or 0, Z = z or 0 }, Vector3)
end
Vector3.__add = function(a, b) return Vector3.new(a.X + b.X, a.Y + b.Y, a.Z + b.Z) end
Vector3.__sub = function(a, b) return Vector3.new(a.X - b.X, a.Y - b.Y, a.Z - b.Z) end
Vector3.__eq = function(a, b) return a.X == b.X and a.Y == b.Y and a.Z == b.Z end
Vector3.__mul = function(a, b)
    if type(a) == "number" then return Vector3.new(a * b.X, a * b.Y, a * b.Z) end
    if type(b) == "number" then return Vector3.new(a.X * b, a.Y * b, a.Z * b) end
    return Vector3.new(a.X * b.X, a.Y * b.Y, a.Z * b.Z)
end
Vector3.__div = function(a, b) return Vector3.new(a.X / b, a.Y / b, a.Z / b) end
Vector3.__unm = function(a) return Vector3.new(-a.X, -a.Y, -a.Z) end
Vector3.__tostring = function(a) return string.format("(%.1f, %.1f, %.1f)", a.X, a.Y, a.Z) end
function Vector3.__index(a, k)
    if k == "Magnitude" then return math.sqrt(a.X ^ 2 + a.Y ^ 2 + a.Z ^ 2) end
    return rawget(Vector3, k)
end

-- ===== Color3 =====
local Color3 = {}
Color3.__index = Color3
local function c3(r, g, b)
    return setmetatable({ R = r or 0, G = g or 0, B = b or 0 }, Color3)
end
Color3.fromRGB = function(r, g, b) return c3(r / 255, g / 255, b / 255) end
Color3.new = function(r, g, b) return c3(r, g, b) end
Color3.fromHSV = function(h, s, v)
    local i = math.floor(h * 6)
    local f = h * 6 - i
    local p, q, t = v * (1 - s), v * (1 - f * s), v * (1 - (1 - f) * s)
    i = i % 6
    if i == 0 then return c3(v, t, p) elseif i == 1 then return c3(q, v, p)
    elseif i == 2 then return c3(p, v, t) elseif i == 3 then return c3(p, q, v)
    elseif i == 4 then return c3(t, p, v) else return c3(v, p, q) end
end
Color3.toHSV = function(c)
    local mx = math.max(c.R, c.G, c.B)
    local mn = math.min(c.R, c.G, c.B)
    local d = mx - mn
    local h = 0
    if d > 0 then
        if mx == c.R then h = ((c.G - c.B) / d) % 6
        elseif mx == c.G then h = (c.B - c.R) / d + 2
        else h = (c.R - c.G) / d + 4 end
        h = h / 6
    end
    local s = mx == 0 and 0 or d / mx
    return h, s, mx
end
function Color3:ToHSV() return Color3.toHSV(self) end
function Color3:ToRGB() return self.R * 255, self.G * 255, self.B * 255 end
function Color3:ToHex() return string.format("%02X%02X%02X", math.floor(self.R * 255 + 0.5), math.floor(self.G * 255 + 0.5), math.floor(self.B * 255 + 0.5)) end
function Color3:Lerp(o, a)
    return c3(self.R + (o.R - self.R) * a, self.G + (o.G - self.G) * a, self.B + (o.B - self.B) * a)
end
Color3.__eq = function(a, b)
    return math.abs(a.R - b.R) < 1e-6 and math.abs(a.G - b.G) < 1e-6 and math.abs(a.B - b.B) < 1e-6
end
Color3.__tostring = function(a) return string.format("(%.2f,%.2f,%.2f)", a.R, a.G, a.B) end


-- ===== UDim / UDim2 / TweenInfo =====
local UDim = {}
UDim.new = function(sc, off) return { Scale = sc or 0, Offset = off or 0 } end
local UDim2 = {}
UDim2.new = function(xs, xo, ys, yo) return { X = UDim.new(xs, xo), Y = UDim.new(ys, yo) } end
UDim2.fromScale = function(x, y) return { X = UDim.new(x or 0, 0), Y = UDim.new(y or 0, 0) } end
UDim2.fromOffset = function(x, y) return { X = UDim.new(0, x or 0), Y = UDim.new(0, y or 0) } end
TweenInfo = { new = function(...) return { ... } end }
NumberSequenceKeypoint = { new = function(t, v) return { Time = t, Value = v } end }
NumberSequence = { new = function(a, b)
    if type(a) == "table" then return { keypoints = a } end
    return { keypoints = { { Time = 0, Value = a or 0 }, { Time = 1, Value = b or 0 } } }
end }
ColorSequenceKeypoint = { new = function(t, c) return { Time = t, Value = c } end }
ColorSequence = { new = function(a, b) return { a = a, b = b } end }
Rect = { new = function(...) return { ... } end }

-- ===== Enum =====
-- Enums listados aqui sao ESTRITOS: chave inexistente vale nil, como no Roblox.
-- E o que pega o bug de `Enum.HighlightDepthMode["Always"]` (so existe
-- AlwaysOnTop/Occluded). Os demais ficam permissivos, mas registram a chave em
-- M.__enumKeys para auditoria.
local ENUM_ITEMS = {
    HighlightDepthMode = { "AlwaysOnTop", "Occluded" },
}
M.__enumKeys = {}
local Enum = setmetatable({}, { __index = function(t, k)
    local items = ENUM_ITEMS[k]
    if items then
        local e = {}
        for idx, name in ipairs(items) do
            e[name] = { Name = name, Value = idx, EnumType = k }
        end
        rawset(t, k, e)
        return e
    end
    -- No Roblox cada membro de Enum e um singleton: duas leituras de
    -- Enum.UserInputType.MouseButton1 devolvem a MESMA tabela. Criar uma nova
    -- a cada acesso quebra qualquer comparacao por igualdade, que e como o
    -- codigo real identifica o tipo de input.
    local cache = {}
    local e = setmetatable({}, { __index = function(_, kk)
        M.__enumKeys[k .. "." .. tostring(kk)] = true
        local item = cache[kk]
        if not item then
            item = { Name = kk, Value = 0, EnumType = k }
            cache[kk] = item
        end
        return item
    end })
    rawset(t, k, e)
    return e
end })

-- ===== Instance =====
local Instance = {}

-- ===== sinais =====
-- Eventos (Activated, MouseButton1Click, ...) viram sinais que registram os
-- callbacks, para o harness poder disparar o clique do seletor de modo.
M.__signals = {}
local SIGNAL_NAMES = {
    Activated = true, MouseButton1Click = true, MouseButton1Down = true,
    MouseButton1Up = true, InputBegan = true, InputEnded = true,
    Changed = true, CharacterAdded = true, Died = true, Loaded = true,
    Heartbeat = true, RenderStepped = true, Stepped = true, FocusLost = true,
    MouseEnter = true, MouseLeave = true, InputChanged = true, TouchTap = true,
    ChildAdded = true, ChildRemoved = true, DescendantAdded = true, AncestryChanged = true,
    Destroying = true, SelectionChanged = true, StateChanged = true, Equipped = true,
}
local function mkSignal(owner, name)
    local key = tostring(owner) .. ":" .. name
    local rec = M.__signals[key]
    if not rec then
        rec = { owner = owner, name = name, fns = {} }
        M.__signals[key] = rec
    end
    return {
        Connect = function(_, fn) table.insert(rec.fns, fn) return { Disconnect = function() end } end,
        Wait = function() return nil end,
        Once = function(_, fn) table.insert(rec.fns, fn) return { Disconnect = function() end } end,
    }
end
M.__fire = function(owner, name, ...)
    local key = tostring(owner) .. ":" .. name
    local rec = M.__signals[key]
    if not rec then return 0 end
    for _, fn in ipairs(rec.fns) do
        local ok, err = pcall(fn, ...)
        if not ok then print("ERRO handler " .. name .. ": " .. tostring(err)) end
    end
    return #rec.fns
end

local instMeta = {}
instMeta.__index = function(self, k)
    if k == "Event" then
        -- BindableEvent.Event: Wait/Fire usados pelas notificacoes da lib.
        local ev = rawget(self, "__evt")
        if not ev then
            ev = {
                fns = {},
                Connect = function(_, fn) table.insert(ev.fns, fn) return { Disconnect = function() end } end,
                Wait = function() return nil end,
                Once = function(_, fn) table.insert(ev.fns, fn) return { Disconnect = function() end } end,
            }
            rawset(self, "__evt", ev)
        end
        return ev
    end
    local raw = rawget(self, "_props")[k]
    if raw ~= nil then return raw end
    -- Propriedades de leitura que a lib consulta sem nunca setar.
    if k == "AbsoluteContentSize" or k == "AbsoluteSize" then return Vector2.new(0, 0) end
    if k == "AbsolutePosition" then return Vector2.new(0, 0) end
    local ch = rawget(self, "_children")
    for _, c in ipairs(ch) do if c.Name == k then return c end end
    if SIGNAL_NAMES[k] then return mkSignal(self, k) end
    return instMeta.methods[k]
end
instMeta.__newindex = function(self, k, v)
    if k == "Parent" then
        local old = rawget(self, "_props").Parent
        if old then
            local oc = rawget(old, "_children")
            for i, c in ipairs(oc) do if c == self then table.remove(oc, i) break end end
        end
        rawget(self, "_props").Parent = v
        if v then table.insert(rawget(v, "_children"), self) end
        return
    end
    -- Roblox recusa nil em propriedade: "Unable to assign property X".
    -- Sem isso, `h.DepthMode = nil` passaria calado e o bug nao apareceria.
    if v == nil then
        error(string.format("Unable to assign property %s. EnumItem expected, got nil", tostring(k)), 2)
    end
    rawget(self, "_props")[k] = v
end
instMeta.methods = {}
local methods = instMeta.methods

function methods:FindFirstChild(name)
    for _, c in ipairs(rawget(self, "_children")) do if c.Name == name then return c end end
end
function methods:FindFirstChildOfClass(cls)
    for _, c in ipairs(rawget(self, "_children")) do if c.ClassName == cls then return c end end
end
function methods:FindFirstChildWhichIsA(cls)
    for _, c in ipairs(rawget(self, "_children")) do if c.ClassName == cls then return c end end
end
function methods:GetChildren() return rawget(self, "_children") end
function methods:GetDescendants()
    local out = {}
    for _, c in ipairs(rawget(self, "_children")) do
        table.insert(out, c)
        for _, d in ipairs(c:GetDescendants()) do table.insert(out, d) end
    end
    return out
end
function methods:IsA(cls) return self.ClassName == cls end
function methods:Destroy()
    self.Parent = nil
    rawget(self, "_props")._destroyed = true
end
function methods:Remove() self:Destroy() end
function methods:IsDescendantOf(root)
    local p = self.Parent
    while p do
        if p == root then return true end
        p = p.Parent
    end
    return self == root
end
function methods:GetBoundingBox()
    local cf = rawget(self, "_props").CFrame
    local size = rawget(self, "_props").Size
    return cf, size
end
function methods:GetPivot() return rawget(self, "_props").CFrame end
-- Player:GetMouse() existe no Roblox; a lib chama no LocalPlayer.
function methods:GetMouse() return M.mouse end
function methods:GetTextSize(txt) return Vector2.new(#tostring(txt or "") * 7, 14) end
function methods:GetTextSize_() end
-- Remote/Eventos: a lib usa Fire/FireServer/FireClient em notificacoes.
function methods:Fire() end
function methods:FireServer() end
function methods:FireClient() end
function methods:InvokeServer() return nil end
-- Filhos moram em _children; buscar em _props devolvia nil e o render
-- tratava o personagem como morto. Recursivo como o Roblox.
local function findChild(self, name, recursive)
    for _, c in ipairs(rawget(self, "_children")) do
        if c.Name == name then return c end
    end
    if recursive then
        for _, c in ipairs(rawget(self, "_children")) do
            local f = findChild(c, name, true)
            if f then return f end
        end
    end
end
function methods:FindFirstChild(name, recursive) return findChild(self, name, recursive) end
function methods:WaitForChild(name) return findChild(self, name, false) end
function methods:FindFirstChildOfClass(cls)
    for _, c in ipairs(rawget(self, "_children")) do
        if c.ClassName == cls then return c end
    end
end
function methods:FindFirstAncestor() return nil end
function methods:IsA(cls) return rawget(self, "ClassName") == cls end
function methods:GetChildren() return rawget(self, "_children") end
function methods:GetDescendants() return rawget(self, "_children") end
function methods:Destroy() rawget(self, "_props").Parent = nil end
function methods:ClearAllChildren() rawset(self, "_children", {}) end
function methods:GetAttribute() return nil end
function methods:SetAttribute() end
function methods:GetPropertyChangedSignal()
    return { Connect = function() return { Disconnect = function() end } end }
end

function Instance.new(cls, parent)
    M.__instCount = (M.__instCount or 0) + 1
    local o = setmetatable({
        ClassName = cls,
        _props = { ZIndex = 1, Transparency = 0, Visible = true },
        _children = {},
    }, instMeta)
    o._props.Name = cls
    if parent ~= nil then o.Parent = parent end
    if cls == "Highlight" then
        o._props.Enabled = true
        -- No Roblox o DepthMode nasce AlwaysOnTop. E por isso que atribuir
        -- nil nele (enum inexistente) estoura em vez de passar calado.
        o._props.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
    end
    return o
end

-- ===== CFrame =====
local CFrame = {}
CFrame.__index = CFrame
function CFrame.new(x, y, z)
    if type(x) == "table" then
        return setmetatable({ Position = x }, CFrame)
    end
    return setmetatable({ Position = Vector3.new(x or 0, y or 0, z or 0) }, CFrame)
end
CFrame.__mul = function(a, b)
    return CFrame.new(a.Position + b.Position)
end

-- ===== Drawing =====
-- Registra cada Drawing criado em M.drawings para o teste inspecionar.
M.drawings = {}
local Drawing = {}
function Drawing.new(kind)
    local d = setmetatable({
        __kind = kind, Visible = false, Transparency = 1, Color = Color3.fromRGB(255, 255, 255),
        Thickness = 1, Filled = false, From = Vector2.new(0, 0), To = Vector2.new(0, 0),
        Position = Vector2.new(0, 0), Size = Vector2.new(0, 0), Text = "", Center = false,
        Outline = false, PointA = Vector2.new(0, 0), PointB = Vector2.new(0, 0),
        PointC = Vector2.new(0, 0), PointD = Vector2.new(0, 0),
    }, { __index = Drawing, __newindex = function(t, k, v) rawset(t, k, v) end })
    table.insert(M.drawings, d)
    return d
end
function Drawing:Remove() self.Visible = false; self.__removed = true end

-- ===== services =====
local services = {}
local function mkService(name)
    local s = Instance.new(name)
    s.Name = name
    services[name] = s
    return s
end

local Players = mkService("Players")
local RunService = mkService("RunService")
local UserInputService = mkService("UserInputService")
local CoreGui = mkService("CoreGui")
local HttpService = mkService("HttpService")

-- JSON minimo mas real (encode/decode simetricos) para exercitar o ciclo de
-- config: numeros, strings, booleanos, arrays e objetos aninhados.
local function jsonEncode(v)
    local t = type(v)
    if t == "nil" then return "null"
    elseif t == "boolean" then return tostring(v)
    elseif t == "number" then return tostring(v)
    elseif t == "string" then
        return '"' .. v:gsub('[%c"\\]', function(c)
            if c == '"' then return '\\"' elseif c == "\\" then return "\\\\"
            elseif c == "\n" then return "\\n" elseif c == "\t" then return "\\t"
            else return string.format("\\u%04x", c:byte()) end
        end) .. '"'
    elseif t == "table" then
        local isArray = #v > 0
        if isArray then
            local parts = {}
            for i = 1, #v do parts[i] = jsonEncode(v[i]) end
            return "[" .. table.concat(parts, ",") .. "]"
        end
        local keys = {}
        for k in pairs(v) do keys[#keys + 1] = k end
        table.sort(keys)
        local parts = {}
        for _, k in ipairs(keys) do
            parts[#parts + 1] = jsonEncode(tostring(k)) .. ":" .. jsonEncode(v[k])
        end
        return "{" .. table.concat(parts, ",") .. "}"
    end
    error("jsonEncode: tipo nao suportado " .. t)
end

local function jsonDecode(str)
    local pos = 1
    local function skip()
        while pos <= #str and str:sub(pos, pos):match("[%s]") do pos = pos + 1 end
    end
    local parseValue
    local function parseString()
        pos = pos + 1
        local out = {}
        while true do
            local c = str:sub(pos, pos)
            if c == "" then error("jsonDecode: string sem fim") end
            if c == '"' then pos = pos + 1; break end
            if c == "\\" then
                local n = str:sub(pos + 1, pos + 1)
                if n == "n" then out[#out+1] = "\n"; pos = pos + 2
                elseif n == "t" then out[#out+1] = "\t"; pos = pos + 2
                elseif n == "u" then
                    out[#out+1] = string.char(tonumber(str:sub(pos+2, pos+5), 16) % 256)
                    pos = pos + 6
                else out[#out+1] = n; pos = pos + 2 end
            else out[#out+1] = c; pos = pos + 1 end
        end
        return table.concat(out)
    end
    parseValue = function()
        skip()
        local c = str:sub(pos, pos)
        if c == "{" then
            pos = pos + 1
            local obj = {}
            skip()
            if str:sub(pos, pos) == "}" then pos = pos + 1; return obj end
            while true do
                skip()
                local k = parseString()
                skip()
                pos = pos + 1 -- ':'
                obj[k] = parseValue()
                skip()
                local sep = str:sub(pos, pos); pos = pos + 1
                if sep == "}" then return obj end
            end
        elseif c == "[" then
            pos = pos + 1
            local arr = {}
            skip()
            if str:sub(pos, pos) == "]" then pos = pos + 1; return arr end
            while true do
                arr[#arr + 1] = parseValue()
                skip()
                local sep = str:sub(pos, pos); pos = pos + 1
                if sep == "]" then return arr end
            end
        elseif c == '"' then
            return parseString()
        elseif str:sub(pos, pos + 3) == "true" then pos = pos + 4; return true
        elseif str:sub(pos, pos + 4) == "false" then pos = pos + 5; return false
        elseif str:sub(pos, pos + 3) == "null" then pos = pos + 4; return nil
        else
            local num = str:match("^-?%d+%.?%d*[eE]?[-+]?%d*", pos)
            if not num or num == "" then error("jsonDecode: valor invalido em " .. pos) end
            pos = pos + #num
            return tonumber(num)
        end
    end
    local v = parseValue()
    return v
end

HttpService.JSONEncode = function(_, v) return jsonEncode(v) end
HttpService.JSONDecode = function(_, v) return jsonDecode(v) end
local TweenService = mkService("TweenService")
-- Create aplica o alvo na hora: o harness nao tem tempo real.
TweenService.Create = function(_, obj, info, goal)
    return { Play = function()
        for k, v in pairs(goal) do pcall(function() obj[k] = v end) end
    end, Cancel = function() end }
end

-- metodos de servico que a lib chama
RunService.IsStudio = function() return false end
RunService.IsClient = function() return true end
RunService.IsServer = function() return false end
RunService.IsRunning = function() return true end
RunService.Heartbeat = {
    Connect = function(_, fn)
        table.insert(M.connections, { name = "Heartbeat", fn = fn })
        return { Disconnect = function() end, Connected = true }
    end,
}
RunService.Stepped = {
    Connect = function(_, fn)
        table.insert(M.connections, { name = "Stepped", fn = fn })
        return { Disconnect = function() end, Connected = true }
    end,
}

-- conexões: guarda o callback para o teste chamar manualmente
M.connections = {}
-- Dispara as conexoes de um loop do RunService. Sem isso um teste de FPS nao
-- tem como avancar o tempo: RenderStepped nao passa por __drain.
M.__step = function(name, dt)
    for _, c in ipairs(M.connections) do
        if c.name == name then
            local ok, err = pcall(c.fn, dt)
            if not ok then print("ERRO " .. name .. ": " .. tostring(err)) end
        end
    end
end
RunService.RenderStepped = {
    Connect = function(_, fn)
        table.insert(M.connections, { name = "RenderStepped", fn = fn })
        return { Disconnect = function() end, Connected = true }
    end,
}

-- camera
local camera = Instance.new("Camera")
camera.Name = "Camera"
camera.ViewportSize = Vector2.new(1920, 1080)
camera.CFrame = CFrame.new(0, 0, 0)
-- projeta: mundo -> viewport. Simples: identidade com Z como profundidade.
camera.WorldToViewportPoint = function(_, wp)
    return Vector3.new(wp.X + 960, 540 - wp.Y, wp.Z + 10), true
end
camera.ViewportPointToRay = function(_, x, y)
    return { Origin = Vector3.new(x, y, 0), Direction = Vector3.new(0, 0, -1), Unit = { Origin = Vector3.new(x,y,0), Direction = Vector3.new(0,0,-1) } }
end
camera.ScreenPointToRay = camera.ViewportPointToRay
camera.GetPartsObscuringTarget = function() return {} end

local PlayersSvc = services["Players"]

local workspace = Instance.new("Workspace")
workspace.Name = "Workspace"
workspace.CurrentCamera = camera

local game = Instance.new("Game")
game.Name = "Game"
game.Workspace = workspace
game.GetService = function(_, n)
    if n == "Workspace" then return workspace end
    if services[n] then return services[n] end
    return mkService(n)
end
workspace.Parent = game
for _, sv in pairs(services) do sv.Parent = game end
game.IsLoaded = function() return true end
game.IsDescendantOf = function() return true end

-- jogadores
M.players = {}
function M.addPlayer(name, teamColor, health)
    local plr = Instance.new("Player")
    plr.Name = name
    plr.DisplayName = name
    plr.TeamColor = { Color = teamColor or Color3.fromRGB(0, 255, 0) }
    plr.Team = { TeamColor = { Color = teamColor or Color3.fromRGB(0, 255, 0) } }
    plr.Backpack = Instance.new("Backpack")

    local char = Instance.new("Model")
    char.Name = name
    local hum = Instance.new("Humanoid")
    hum.Health = health or 100
    hum.MaxHealth = 100
    hum.HipHeight = 2
    hum.RigType = { Name = "R15" }
    hum.Parent = char

    local hrp = Instance.new("Part")
    hrp.Name = "HumanoidRootPart"
    hrp.Position = Vector3.new(0, 0, 0)
    hrp.Size = Vector3.new(2, 2, 1)
    hrp.CFrame = CFrame.new(0, 0, 0)
    hrp.Parent = char

    local head = Instance.new("Part")
    head.Name = "Head"
    head.Position = Vector3.new(0, 2, 0)
    head.Size = Vector3.new(1, 1, 1)
    head.Parent = char

    for _, n in ipairs({"UpperTorso","LowerTorso","LeftUpperLeg","LeftLowerLeg","LeftFoot",
                        "RightUpperLeg","RightLowerLeg","RightFoot","LeftUpperArm","LeftLowerArm",
                        "LeftHand","RightUpperArm","RightLowerArm","RightHand"}) do
        local p = Instance.new("Part")
        p.Name = n
        p.Position = Vector3.new(0, 0, 0)
        p.Size = Vector3.new(1, 1, 1)
        p.Parent = char
    end

    char.CFrame = CFrame.new(0, 0, 0)
    char.Size = Vector3.new(2, 5, 1)
    char.Parent = workspace
    plr.Character = char
    plr.Parent = Players
    table.insert(M.players, plr)
    return plr, char, hum, hrp, head
end

-- Da um personagem completo ao LocalPlayer do mock, reaproveitando a mesma
-- estrutura de addPlayer (Position/CFrame/skeleton), para exercitar o SelfESP.
function M.giveLocalPlayerCharacter()
    local plr = M.localPlayer
    local char = Instance.new("Model")
    char.Name = "LocalPlayer"
    local hum = Instance.new("Humanoid"); hum.Health = 100; hum.MaxHealth = 100
    hum.HipHeight = 2; hum.RigType = { Name = "R15" }; hum.Parent = char
    local hrp = Instance.new("Part"); hrp.Name = "HumanoidRootPart"
    hrp.Position = Vector3.new(0, 0, 0); hrp.Size = Vector3.new(2, 2, 1)
    hrp.CFrame = CFrame.new(0, 0, 0); hrp.Parent = char
    local head = Instance.new("Part"); head.Name = "Head"
    head.Position = Vector3.new(0, 2, 0); head.Size = Vector3.new(1, 1, 1); head.Parent = char
    for _, n in ipairs({"UpperTorso","LowerTorso","LeftUpperLeg","LeftLowerLeg","LeftFoot",
                        "RightUpperLeg","RightLowerLeg","RightFoot","LeftUpperArm","LeftLowerArm",
                        "LeftHand","RightUpperArm","RightLowerArm","RightHand"}) do
        local p = Instance.new("Part"); p.Name = n; p.Position = Vector3.new(0, 0, 0)
        p.Size = Vector3.new(1, 1, 1); p.Parent = char
    end
    char.CFrame = CFrame.new(0, 0, 0); char.Size = Vector3.new(2, 5, 1)
    char.Parent = workspace
    plr.Character = char
    return plr, char
end
Players.GetPlayers = function()
    local out = {}
    for _, p in ipairs(M.players) do
        if p.Parent == Players then table.insert(out, p) end
    end
    return out
end
Players.GetPlayerFromCharacter = function(_, char)
    for _, p in ipairs(M.players) do
        if p.Character == char then return p end
    end
end
-- LocalPlayer precisa existir: o Script/A espera por ele antes de tudo.
local __lp = Instance.new("Player")
__lp.Name = "LocalPlayer"
__lp.DisplayName = "LocalPlayer"
__lp.TeamColor = { Color = Color3.fromRGB(255, 255, 255) }
__lp.Team = { TeamColor = { Color = Color3.fromRGB(255, 255, 255) } }
__lp.Backpack = Instance.new("Backpack")
__lp.Parent = Players
Players.LocalPlayer = __lp
M.localPlayer = __lp
-- Entra na lista: o render itera GetPlayers(), nao LocalPlayer.
if not M.players then M.players = {} end
table.insert(M.players, __lp)

local __mouse = {
    Hit = CFrame.new(0,0,0), Target = nil, UnitRay = { Origin = Vector3.new(0,0,0), Direction = Vector3.new(0,0,-1) },
    X = 960, Y = 540,
}
__mouse.Button1Down = { Connect = function() return { Disconnect = function() end } end }
__mouse.Button1Up = { Connect = function() return { Disconnect = function() end } end }
__mouse.Move = { Connect = function() return { Disconnect = function() end } end }
__mouse.Button1Down = __mouse.Button1Down
local Players = services["Players"]
Players.GetMouse = function() return __mouse end
Players.GetPlayerByUserId = function() return nil end
Players.GetNameFromUserIdAsync = function() return "user" end
local UIS = services["UserInputService"]
UIS.GetMouseLocation = function() return Vector2.new(960, 540) end
-- Estado de input controlavel pelo teste: o painel Keystrokes le daqui.
M.__keysDown = {}
M.__mouseDown = {}
UIS.IsKeyDown = function(_, key)
    local name = (type(key) == "table" and key.Name) or tostring(key)
    return M.__keysDown[name] == true
end
UIS.GetMouseButtonsPressed = function()
    local out = {}
    for _, idx in ipairs(M.__mouseDown) do
        out[#out + 1] = { UserInputType = (idx == 1) and Enum.UserInputType.MouseButton1
                                                   or Enum.UserInputType.MouseButton2 }
    end
    return out
end
UIS.GetFocusedTextBox = function() return nil end
-- InputBegan/InputEnded/InputChanged/TouchTap NAO sao sobrescritos: o __index
-- de instancia ja devolve sinais registraveis (mkSignal), e um stub que
-- descarta o handler faz o teste passar sem exercitar o codigo de verdade.
M.mouse = __mouse

M.services = services
M.Instances = { Players = Players, RunService = RunService, UserInputService = UserInputService, CoreGui = CoreGui }

-- globais que o bloco usa
game = game
workspace = workspace
Instance = Instance
Drawing = Drawing
Vector2 = Vector2
Vector3 = Vector3
Color3 = Color3
CFrame = CFrame
Enum = Enum
UDim = UDim
UDim2 = UDim2
tick = function() return os.clock() end
gethui = function() return CoreGui end
-- getgenv: tabela compartilhada; o bloco le/escreve varias chaves nela.
local GENV = {}
getgenv = function() return GENV end

-- Executores reais deixam `debug` gravavel (hooks trocam debug.info, e o
-- fail-open depende de detectar debug ausente). A tabela debug do Luau CLI e
-- readonly, entao o mock expoe uma copia gravavel com os mesmos campos.
local RealDebug = debug
debug = setmetatable({}, {
    __index = RealDebug,
    __newindex = function(t, k, v) rawset(t, k, v) end,
})
pcall = pcall

-- ===== filesystem do executor =====
local FS = { folders = { [""] = true }, files = {} }
isfolder = function(pth) return FS.folders[pth] ~= nil end
makefolder = function(pth) FS.folders[pth] = true end
isfile = function(pth) return FS.files[pth] ~= nil end
writefile = function(pth, data) FS.files[pth] = data end
readfile = function(pth) return FS.files[pth] end
delfile = function(pth) FS.files[pth] = nil end
-- listfiles devolve caminhos completos, como os executores reais: a lib faz
-- string.sub(v, #dir + 2) para extrair o nome, entao devolver so o nome
-- quebraria GetConfigs/GetConfigCount silenciosamente.
listfiles = function(pth)
    local out = {}
    local prefix = (pth == "" or pth == nil) and "" or (pth .. "/")
    for path in pairs(FS.files) do
        if pth == "" or pth == nil or path:sub(1, #prefix) == prefix then
            out[#out + 1] = path
        end
    end
    table.sort(out)
    return out
end
getcustomasset = function(pth) return "rbxassetid://0" end
setclipboard = function() end
setfpscap = function() end
cloneref = function(o) return o end
UserSettings = function()
    return { GetService = function(_, n)
        return { GetPropertyChangedSignal = function() return { Connect = function() return { Disconnect = function() end } end } end }
    end }
end
gethui = gethui
__FS = FS

-- ===== task =====
-- `wait` cede de verdade: sem isso, `while not X do task.wait() end` gira
-- para sempre dentro de um unico resume e o harness nunca drena.
M.__spawned = M.__spawned or {}
task = {
    wait = function(t) coroutine.yield(t or 0) return t or 0 end,
    spawn = function(fn, ...)
        local co = coroutine.create(fn)
        table.insert(M.__spawned, co)
        return co
    end,
    defer = function(fn, ...) return task.spawn(fn, ...) end,
    delay = function(_, fn, ...) return task.spawn(fn, ...) end,
    cancel = function() end,
}

-- warn existe no Roblox e no Luau padrao; a lib usa para reportar falhas nao
-- fatais. Sem ele o mock estoura exatamente nos caminhos de erro que os testes
-- querem exercitar.
warn = function(...)
    local parts = {}
    for i = 1, select('#', ...) do parts[i] = tostring((select(i, ...))) end
    M.__warnings = M.__warnings or {}
    table.insert(M.__warnings, table.concat(parts, ' '))
end

return M
