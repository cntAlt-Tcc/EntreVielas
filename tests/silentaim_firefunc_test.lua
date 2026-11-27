-- Silent Aim: opcao "fire function check".
--
-- O gate antigo usava debug.traceback(), que inclui o frame da propria
-- SA_IsFireFunc -- e o nome dela contem "fire". O gate casava consigo mesmo,
-- liberava TODA chamada e a opcao nunca filtrava nada.
--
-- O jogo real chama o hook de outro chunk. Aqui loadstring() faz esse papel:
-- sem isso tudo roda no mesmo chunk do Script/A e o filtro de fonte propria
-- pularia todos os frames, mascarando o bug.
local SA = __M.SA
local GENV = getgenv()

__ok("SA exposto no getgenv", type(SA) == "table" and type(SA.IsFireFunc) == "function")

local function gameChunk(src)
    local fn = assert(loadstring(src, "@game"))
    return fn(SA)
end

local plainCall  = gameChunk("local SA = ... return function() return SA.IsFireFunc() end")
local fireCall   = gameChunk("local SA = ... return function() return SA.IsFireFunc() end")
local fireBullet = gameChunk([[
    local SA = ...
    local function FireBullet() return SA.IsFireFunc() end
    return FireBullet
]])
local updateInv = gameChunk([[
    local SA = ...
    local function UpdateInventory() return SA.IsFireFunc() end
    return UpdateInventory
]])

-- 1. Gate desligado (default): qualquer chamada passa -- inclusive uma sem
--    nenhuma palavra-chave de arma. Usar uma chamada armada aqui deixaria o
--    teste passar mesmo sem o shortcircuit.
GENV.SilentAim_FireFunc = false
__ok("gate off libera chamada comum", updateInv() == true)

-- 2. Gate ligado: chamada comum e bloqueada...
GENV.SilentAim_FireFunc = true
__ok("gate on bloqueia chamada comum", updateInv() == false)

-- 3. ...e o tiro continua passando.
__ok("gate on libera funcao de tiro", fireBullet() == true)

-- 4. Funcao anonima (sem nome armado) tambem e bloqueada: o gate olha o
--    nome do frame, nao o conteudo.
__ok("gate on bloqueia funcao anonima", plainCall() == false)

-- 5. Fail-open: executor que nao expoe frames do jogo nao pode bloquear tiro.
--    O gate precisa estar LIGADO aqui: desligado, o shortcircuit retorna antes
--    de olhar a pilha e o teste passaria sem exercitar o fail-open.
GENV.SilentAim_FireFunc = true
local realInfo = debug.info
debug.info = function() return nil end
__ok("pilha sem frames do jogo -> fail-open", updateInv() == true)
debug.info = realInfo
__ok("debug restaurado", debug.info == realInfo)
GENV.SilentAim_FireFunc = false

-- 6. Frame nativo ([C]) com nome armado nao pode ser confundido com frame do
--    jogo: o proprio hook roda em [C] via newcclosure. Se [C] fosse inspecionado,
--    "FireBullet" liberaria uma chamada comum. Aqui a pilha e simulada porque o
--    Luau nao produz [C] com nome custom.
GENV.SilentAim_FireFunc = true
local stackInfo = debug.info
debug.info = function(level)
    if level == 1 then return "[C]", "FireBullet" end
    if level == 2 then return "/game/Inventory.lua", "UpdateInventory" end
    return nil
end
__ok("[C] armado nao mascara frame do jogo", updateInv() == false)
debug.info = stackInfo
GENV.SilentAim_FireFunc = false

-- 7. Lista de palavras-chave continua a esperada.
local kws = {}
for _, k in ipairs(SA.FireKeywords) do kws[k] = true end
__ok("keyword 'fire' presente", kws.fire == true)
__ok("keyword 'raycast' presente", kws.raycast == true)
