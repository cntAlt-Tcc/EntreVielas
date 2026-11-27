-- Regressoes dos dois bugs reportados:
--  1. ligar o Chams parava o ESP inteiro;
--  2. salvar/carregar config nao funcionava.
local E, C, L = __M.ESP, __M.ESP.Config, __M.Lib
local S = __M.Save

local function chamsDefaults()
    C.Enabled = true; C.Chams.Enabled = true
    C.Chams.Fill = true; C.Chams.Outline = true
    C.Chams.FillColor = Color3.fromRGB(255, 255, 255)
    C.Chams.OutlineColor = Color3.fromRGB(255, 255, 255)
    C.Chams.FillTransparency = 0.5; C.Chams.OutlineTransparency = 0
    C.Chams.DepthMode = "AlwaysOnTop"
    C.Chams.RGB = true; C.Chams.Team = true; C.Chams.Glow = false
end

local function freshPlayer(name)
    local p = __M.addPlayer(name, Color3.fromRGB(255, 0, 0), 100)
    E.InitPlayerESP(p)
    return p, E.ESP_Cache[p]
end

-- ===== 1. Chams nao pode derrubar o resto do frame =====
-- O erro acontecia no meio do ESP_Render: o chams estourava e box/tracer/texto
-- nunca chegavam a desenhar. Cada caso abaixo e um estado que ja estourou.
local badStates = {
    { "cor de preenchimento nil", function() C.Chams.FillColor = nil end },
    { "cor de contorno nil", function() C.Chams.OutlineColor = nil end },
    { "cor como tabela {R,G,B} (config antigo)",
      function() C.Chams.FillColor = { R = 1, G = 0, B = 0 } end },
    { "glow com cor nil", function() C.Chams.Glow = true; C.Chams.FillColor = nil end },
    { "glow com cor tabela",
      function() C.Chams.Glow = true; C.Chams.FillColor = { R = 1, G = 0, B = 0 } end },
    { "DepthMode tabela", function() C.Chams.DepthMode = { x = 1 } end },
    { "DepthMode nil", function() C.Chams.DepthMode = nil end },
    { "transparencia string", function() C.Chams.FillTransparency = "0.5" end },
    { "transparencia tabela", function() C.Chams.FillTransparency = {} end },
    { "transparencia fora da faixa", function() C.Chams.FillTransparency = 7 end },
}

for _, case in ipairs(badStates) do
    chamsDefaults()
    C.Box.Enabled = true
    case[2]()
    local _, d = freshPlayer("Chams_" .. case[1])
    local ok, err = pcall(E.ESP_Render)
    __ok("chams: " .. case[1] .. " nao estoura", ok, err)

    -- O ponto do bug: o box precisa desenhar mesmo quando o chams falha.
    local boxVisible = false
    for _, line in pairs(d.Box or {}) do
        if line.Visible then boxVisible = true end
    end
    __ok("chams: " .. case[1] .. " nao impede o box", boxVisible)
end

-- CoreGui negado pelo executor: era a causa de "tudo para de funcionar".
chamsDefaults()
C.Box.Enabled = true

-- O folder do chams fica em cache. Sem soltar esse cache o codigo nunca toca
-- no gethui bloqueado e o teste passaria sem exercitar nada.
local function dropChamsFolder()
    local function walk(o)
        for _, c in pairs(o:GetChildren() or {}) do
            if c.Name == "EntreVielas_Chams" then
                c.Parent = nil
            else
                walk(c)
            end
        end
    end
    walk(__M.Instances.CoreGui)
end
dropChamsFolder()

local realCoreGui = __M.Instances.CoreGui
local realGethui = gethui
local blocked = setmetatable({}, {
    __index = realCoreGui,
    __newindex = function() error("cannot write CoreGui (permission 4)", 2) end,
})
gethui = function() return blocked end
__M.Instances.CoreGui = blocked
local _, dBlocked = freshPlayer("Chams_Blocked")
local okBlocked, errBlocked = pcall(E.ESP_Render)
gethui = realGethui
__M.Instances.CoreGui = realCoreGui
__ok("chams: CoreGui negado nao estoura", okBlocked, errBlocked)
local boxBlocked = false
for _, line in pairs(dBlocked.Box or {}) do
    if line.Visible then boxBlocked = true end
end
__ok("chams: CoreGui negado nao impede o box", boxBlocked)

-- Caminho feliz continua funcionando.
chamsDefaults()
local pOk, dOk = freshPlayer("Chams_Ok")
__ok("chams: render normal ok", (pcall(E.ESP_Render)))
__ok("chams: Highlight criado", dOk.Chams ~= nil)
__ok("chams: Adornee e o personagem", dOk.Chams and dOk.Chams.Adornee == pOk.Character)

-- ===== 2. Salvar/carregar config =====
local CM, FS = S.ConfigManager, S.FS
local dir = "Vsync/Vsync-Configs"

__ok("save: ConfigManager existe", CM ~= nil and CM.WriteConfig ~= nil)

-- O bug: um keybind sem tecla tinha Default nil e GetValue estourava,
-- abortando o save inteiro.
local saved = false
local okSave, errSave = pcall(function()
    CM:WriteConfig({ Name = "Regressao" })
    saved = true
end)
__ok("save: WriteConfig funciona", saved and okSave, errSave)
__ok("save: arquivo criado", FS.files[dir .. "/Regressao"] ~= nil)
__ok("save: aparece em GetConfigs",
     table.find(CM:GetConfigs(), "Regressao") ~= nil,
     table.concat(CM:GetConfigs(), ","))
__ok("save: metadata legivel", type(CM:ReadInfo("Regressao")) == "table")

-- Round-trip pelo caminho do usuario: clicar nos elementos da UI. Setar
-- Config direto nao serve, porque o save serializa o estado dos elementos.
local chamsToggle = L.Flags["SecChams_Ativar"]
local boxToggle = L.Flags["SecBox_AtivarBox"]
__ok("save: toggles de chams/box existem", chamsToggle ~= nil and boxToggle ~= nil)

C.Enabled = true
chamsToggle:SetValue(false)
boxToggle:SetValue(true)
CM:WriteConfig({ Name = "RoundTrip" })

chamsToggle:SetValue(true)
boxToggle:SetValue(false)
__ok("save: estado mudou antes do load",
     C.Chams.Enabled == true and C.Box.Enabled == false)
CM:LoadConfig("RoundTrip")
__ok("load: Chams.Enabled restaurado", C.Chams.Enabled == false, tostring(C.Chams.Enabled))
__ok("load: Box.Enabled restaurado", C.Box.Enabled == true, tostring(C.Box.Enabled))

-- O config salvo precisa conter os elementos de chams.
local raw = FS.files[dir .. "/RoundTrip"]
__ok("save: config inclui flag de chams",
     raw ~= nil and raw:find("SecChams_Ativar", 1, true) ~= nil)

-- Keybind sem tecla e o que quebrava o save; confirma que serializa.
local keybindFlag = nil
for flag, el in pairs(L.Flags) do
    local okv, v = pcall(function() return el:GetValue() end)
    if not okv then
        keybindFlag = flag
        break
    end
end
__ok("save: nenhum elemento estoura no GetValue", keybindFlag == nil, keybindFlag)

CM:DeleteConfig("Regressao")
CM:DeleteConfig("RoundTrip")
__ok("delete: arquivo removido", FS.files[dir .. "/Regressao"] == nil)

-- ===== 3. Lock/unlock por config =====
CM:WriteConfig({ Name = "Travavel" })
local lockPath = dir .. "/Travavel"

__ok("lock: config novo nasce destravado", CM:IsLocked("Travavel") == false)

__ok("lock: SetLocked(true) aplica", CM:SetLocked("Travavel", true) == true)
__ok("lock: IsLocked reflete o lock", CM:IsLocked("Travavel") == true)

-- O ponto da feature: um config travado nao pode ser sobrescrito.
local beforeLock = FS.files[lockPath]
chamsToggle:SetValue(true)
__ok("lock: WriteConfig em travado recusa", CM:WriteConfig({ Name = "Travavel" }) == false)
__ok("lock: conteudo do travado intacto", FS.files[lockPath] == beforeLock)

-- Nem apagado.
__ok("lock: DeleteConfig em travado recusa", CM:DeleteConfig("Travavel") == false)
__ok("lock: arquivo travado ainda existe", FS.files[lockPath] ~= nil)

-- Destravar devolve as duas operacoes.
CM:SetLocked("Travavel", false)
__ok("lock: SetLocked(false) remove", CM:IsLocked("Travavel") == false)
__ok("lock: WriteConfig destravado grava", CM:WriteConfig({ Name = "Travavel" }) == true)
__ok("lock: DeleteConfig destravado apaga", CM:DeleteConfig("Travavel") == true)
__ok("lock: arquivo destravado removido", FS.files[lockPath] == nil)

-- O lock vive dentro do arquivo, entao precisa sobreviver a releitura.
CM:WriteConfig({ Name = "Persistente" })
CM:SetLocked("Persistente", true)
local persisted = CM:ReadInfo("Persistente") or {}
__ok("lock: persiste no arquivo", persisted.Locked == true, tostring(persisted.Locked))
__ok("lock: sobrevive a releitura", CM:IsLocked("Persistente") == true)

-- Config inexistente nao pode virar lock fantasma.
__ok("lock: SetLocked em inexistente falha", CM:SetLocked("NaoExiste", true) == false)
__ok("lock: inexistente nao fica travado", CM:IsLocked("NaoExiste") == false)

CM:SetLocked("Persistente", false)
CM:DeleteConfig("Persistente")
