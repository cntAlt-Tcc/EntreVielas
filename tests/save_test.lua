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

-- 4. Autoload: marca no proprio arquivo, exclusivo entre configs.
CM:WriteConfig({ Name = "AutoA" })
CM:WriteConfig({ Name = "AutoB" })

__ok("autoload: nasce desligado", CM:IsAutoload("AutoA") == false)
__ok("autoload: nenhum marcado no inicio", CM:GetAutoloadConfig() == nil,
     tostring(CM:GetAutoloadConfig()))

__ok("autoload: SetAutoload grava", CM:SetAutoloadExclusive("AutoA", true) == true)
__ok("autoload: AutoA marcado", CM:IsAutoload("AutoA") == true)
__ok("autoload: GetAutoloadConfig devolve AutoA", CM:GetAutoloadConfig() == "AutoA",
     tostring(CM:GetAutoloadConfig()))

-- Marcar outro tem que desmarcar o primeiro: dois autoloads disputariam os
-- mesmos Flags na inicializacao.
CM:SetAutoloadExclusive("AutoB", true)
__ok("autoload: exclusivo desmarca AutoA", CM:IsAutoload("AutoA") == false)
__ok("autoload: exclusivo marca AutoB", CM:IsAutoload("AutoB") == true)
__ok("autoload: so um marcado", CM:GetAutoloadConfig() == "AutoB",
     tostring(CM:GetAutoloadConfig()))

-- O autoload vive no __INFORMATION, junto do lock: nao pode derrubar o lock.
CM:SetLocked("AutoB", true)
CM:SetAutoloadExclusive("AutoB", true)
__ok("autoload: lock sobrevive ao autoload", CM:IsLocked("AutoB") == true)
__ok("autoload: autoload sobrevive ao lock", CM:IsAutoload("AutoB") == true)

-- Desmarcar volta a nao carregar nada.
CM:SetAutoloadExclusive("AutoB", false)
__ok("autoload: desmarcado", CM:IsAutoload("AutoB") == false)
__ok("autoload: nenhum marcado no fim", CM:GetAutoloadConfig() == nil)

-- Config inexistente nao pode explodir.
__ok("autoload: config inexistente devolve false", CM:SetAutoload("NaoExiste", true) == false)
__ok("autoload: IsAutoload de inexistente e false", CM:IsAutoload("NaoExiste") == false)
