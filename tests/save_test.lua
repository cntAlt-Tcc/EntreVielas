-- Ciclo real de salvar/carregar config, contra o ConfigManager da lib.
local S = __M.Save
local CM, C, FS = S.ConfigManager, S.Config, S.FS
local L = S.Lib or __M.Lib

__ok("save: ConfigManager exposto", CM ~= nil and CM.WriteConfig ~= nil)

-- O estado que o save captura vem das flags, nao do Config: quem muda o Config
-- direto deixa a flag dessincronizada e o save grava o valor antigo. O usuario
-- so muda pela UI, entao o teste tambem tem que passar por SetValue.
local flags = L:GetConfig("KV")
local function setFlag(name, value)
    local f = flags[name]
    if f then f.Functions:SetValue(value) end
    return f ~= nil
end

__ok("save: flag do Chams encontrada", flags["SecChams_Ativar"] ~= nil)
__ok("save: flag do Box encontrada", flags["SecBox_AtivarBox"] ~= nil)

-- 1. Save cria arquivo no diretorio de configs
CM:WriteConfig({ Name = "TesteCiclo" })
local dir = "Vsync/Vsync-Configs"
local path = dir .. "/TesteCiclo"
__ok("save: arquivo criado", FS.files[path] ~= nil, path)
__ok("save: listado em GetConfigs", table.find(CM:GetConfigs(), "TesteCiclo") ~= nil,
     table.concat(CM:GetConfigs(), ","))
__ok("save: ReadInfo devolve metadata", type(CM:ReadInfo("TesteCiclo")) == "table")

-- 2. Mudar valores e ver se o load restaura
setFlag("SecChams_Ativar", false)
setFlag("SecBox_AtivarBox", true)
CM:WriteConfig({ Name = "Snapshot" })

setFlag("SecChams_Ativar", true)
setFlag("SecBox_AtivarBox", false)
__ok("save: estado mudou antes do load", C.Chams.Enabled == true and C.Box.Enabled == false)

CM:LoadConfig("Snapshot")
__ok("load: Chams.Enabled restaurado", C.Chams.Enabled == false, tostring(C.Chams.Enabled))
__ok("load: Box.Enabled restaurado", C.Box.Enabled == true, tostring(C.Box.Enabled))

-- 3. Delete
CM:DeleteConfig("TesteCiclo")
__ok("delete: arquivo removido", FS.files[path] == nil)
__ok("delete: some de GetConfigs", table.find(CM:GetConfigs(), "TesteCiclo") == nil)
