-- Silent Aim: opcao "fire function check".
--
-- Historico do bug, em duas camadas:
--  1. o gate usava debug.traceback(), que inclui o frame da propria
--     SA_IsFireFunc -- nome com "fire" -- e casava consigo mesmo, liberando
--     TODA chamada. O gate nunca filtrava nada.
--  2. corrigido isso, o gate passou a olhar so o NOME do frame. Callback de
--     arma no Roblox e anonimo (nome ""), entao TODO tiro era bloqueado -- o
--     filtro matava a propria arma. O sinal que existe de verdade e o script
--     chamador (getcallingscript) e o SOURCE do frame, nao o nome.
--
-- O jogo chama o hook de outro chunk. Aqui loadstring() faz esse papel: sem
-- isso tudo roda no mesmo chunk do Script/A e o filtro de fonte propria
-- pularia todos os frames, mascarando o bug.
local SA = __M.SA
local GENV = getgenv()

__ok("SA exposto no getgenv", type(SA) == "table" and type(SA.IsFireFunc) == "function")

local function gameChunk(src, chunkname)
    local fn = assert(loadstring(src, chunkname or "@game"))
    return fn(SA)
end

local updateInv = gameChunk([[
    local SA = ...
    local function UpdateInventory() return SA.IsFireFunc() end
    return UpdateInventory
]])

-- 1. Gate desligado (default): qualquer chamada passa.
GENV.SilentAim_FireFunc = false
__ok("gate off libera chamada comum", updateInv() == true)

-- 2. Gate ligado + frame nomeado sem cara de arma -> bloqueia.
--    Sem getcallingscript no ambiente, o nome do frame e a unica evidencia.
GENV.SilentAim_FireFunc = true
__ok("gate on bloqueia chamada comum nomeada", updateInv() == false)

-- 3. Funcao nomeada de arma -> libera.
local fireNamed = gameChunk([[
    local SA = ...
    local function FireBullet() return SA.IsFireFunc() end
    return FireBullet
]])
__ok("gate on libera funcao nomeada de tiro", fireNamed() == true)

-- 4. O BUG REAL: callback anonimo dentro de um script de arma. O nome do frame
--    e "", mas o SOURCE aponta para o script da arma. Antes do fix isso era
--    bloqueado (todo tiro real morria).
local anonGun = gameChunk([[
    local SA = ...
    return function() return SA.IsFireFunc() end
]], "@/game/Workspace/Gun/Script")
__ok("arma com callback anonimo passa (bug do bloqueio total)", anonGun() == true)

local anonWeaponClient = gameChunk([[
    local SA = ...
    return function() return SA.IsFireFunc() end
]], "@/game/StarterPlayer/WeaponClient")
__ok("WeaponClient anonimo passa", anonWeaponClient() == true)

-- 5. Fail-open: executor que nao expoe frames do jogo nao pode bloquear tiro.
GENV.SilentAim_FireFunc = true
local realInfo = debug.info
debug.info = function() return nil end
__ok("pilha sem frames do jogo -> fail-open", updateInv() == true)
debug.info = realInfo
__ok("debug restaurado", debug.info == realInfo)

-- 6. getcallingscript: quando o executor expoe, o script chamador decide --
--    e um script DENTRO de um Tool conta como arma mesmo sem palavra-chave
--    no nome (AK47, Sword...).
local function fakeScript(name, parent)
    return { Name = name, Parent = parent,
             GetFullName = function() return name end }
end
local realGet = getcallingscript

-- 6a. script comum, fora de Tool -> bloqueia
getcallingscript = function() return fakeScript("InventoryHandler", nil) end
__ok("getcallingscript comum -> bloqueia", updateInv() == false)

-- 6b. script dentro de Tool, nome sem palavra-chave -> libera
local tool = { Name = "AK47", Parent = nil, ClassName = "Tool" }
getcallingscript = function() return fakeScript("LocalScript", tool) end
__ok("getcallingscript dentro de Tool -> libera", updateInv() == true)

-- 6c. script com nome de arma -> libera
getcallingscript = function() return fakeScript("GunClient", nil) end
__ok("getcallingscript com nome de arma -> libera", updateInv() == true)

getcallingscript = realGet
GENV.SilentAim_FireFunc = false

-- 7. O gate nao pode casar consigo mesmo: o nome SA_IsFireFunc tem "fire".
--    Se casasse, liberaria tudo e o filtro seria decorativo.
__ok("FrameMatchesFire ignora nome vazio", SA.FrameMatchesFire("@game", "") == false)
__ok("FrameMatchesFire pega nome de arma", SA.FrameMatchesFire("@game", "FireBullet") == true)
__ok("FrameMatchesFire pega source de arma", SA.FrameMatchesFire("@/game/Gun/Script", "") == true)

-- 8. Lista de palavras-chave continua a esperada.
local kws = {}
for _, k in ipairs(SA.FireKeywords) do kws[k] = true end
__ok("keyword 'fire' presente", kws.fire == true)
__ok("keyword 'raycast' presente", kws.raycast == true)
