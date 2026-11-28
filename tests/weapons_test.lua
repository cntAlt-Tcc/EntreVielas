-- Weapons Mod: recuo, spread, municao, clip e cadencia.
-- Cria Tools de verdade (na mochila e no personagem), liga cada mod e confere
-- o valor que a arma recebe; depois desliga e confere que o original voltou.

__ok("weapons: script carregou", __M.__err == nil, __M.__err)
__ok("weapons: corrotina terminou", coroutine.status(__M.__mainCo) == "dead")

local LIB = __FIVESYNC
__ok("weapons: lib exposta", type(LIB) == "table")

local function hasText(needle)
    local found = false
    local function walk(o, d)
        if not o or d > 80 or found then return end
        for _, c in pairs(o:GetChildren() or {}) do
            if c.ClassName == "TextLabel" and c.Text == needle then found = true end
            walk(c, d + 1)
        end
    end
    for _, s in pairs(__M.Instances) do walk(s, 0) end
    return found
end

-- 1. A aba existe e esta no container Combat.
__ok("weapons: aba presente", hasText(" Weapons Mod "))
__ok("weapons: container Combat presente", hasText("| Combat"))

-- 2. Toggles chegam ao registry com os flags esperados.
local expectFlags = {
    W_NoRecoil = "No Recoil",
    W_NoSpread = "Bala não espalha",
    W_InfiniteAmmo = "Munição infinita",
    W_InfiniteClip = "Clip infinito",
    W_FastFire = "Atirar rápido",
}
for flag, name in pairs(expectFlags) do
    local el = LIB.Flags[flag]
    __ok("weapons: flag " .. flag .. " existe", el ~= nil)
    __ok("weapons: texto de " .. flag, el ~= nil and el:GetText() == name,
        el and el:GetText())
end
__ok("weapons: slider de intervalo existe", LIB.Flags["W_FireDelay"] ~= nil)

-- 3. Arma de teste: valores nomeados como um jogo de verdade costuma expor.
local Players = game:GetService("Players")
local lp = Players.LocalPlayer
local _, char = __M.giveLocalPlayerCharacter()
__ok("weapons: personagem disponivel", char ~= nil)
local backpack = lp:FindFirstChildOfClass("Backpack")
__ok("weapons: mochila disponivel", backpack ~= nil)

local function mkTool(parent, ammo)
    local tool = Instance.new("Tool")
    tool.Name = "TestGun"
    local a = Instance.new("IntValue")
    a.Name = "Ammo"
    a.Value = ammo or 3
    a.Parent = tool
    local clip = Instance.new("IntValue")
    clip.Name = "Clip"
    clip.Value = 7
    clip.Parent = tool
    local recoil = Instance.new("NumberValue")
    recoil.Name = "Recoil"
    recoil.Value = 2.5
    recoil.Parent = tool
    local spread = Instance.new("NumberValue")
    spread.Name = "BulletSpread"
    spread.Value = 1.75
    spread.Parent = tool
    local rate = Instance.new("NumberValue")
    rate.Name = "FireRate"
    rate.Value = 0.8
    rate.Parent = tool
    local reloading = Instance.new("BoolValue")
    reloading.Name = "Reloading"
    reloading.Value = true
    reloading.Parent = tool
    tool:SetAttribute("Ammo", 3)
    tool:SetAttribute("Recoil", 2.5)
    tool.Parent = parent
    return tool
end

local tool = mkTool(backpack, 3)
__ok("weapons: arma criada na mochila", tool.Parent == backpack)

-- O loop dos mods roda em corrotina propria; __drain avanca ate o proximo
-- yield, que e o que faz o valor ser escrito de fato.
local function waitTicks(rounds)
    __M.__drain(rounds or 12)
end

-- 4. No Recoil zera so o recuo.
LIB.Flags["W_NoRecoil"]:SetValue(true)
waitTicks(4)
__ok("weapons: recuo zerado", tool.Recoil.Value == 0, tool.Recoil.Value)
__ok("weapons: recuo do attribute zerado", tool:GetAttribute("Recoil") == 0,
    tool:GetAttribute("Recoil"))
__ok("weapons: spread intacto com No Recoil", tool.BulletSpread.Value == 1.75,
    tool.BulletSpread.Value)
__ok("weapons: municao intacta com No Recoil", tool.Ammo.Value == 3, tool.Ammo.Value)

LIB.Flags["W_NoRecoil"]:SetValue(false)
waitTicks(4)
__ok("weapons: recuo restaurado", tool.Recoil.Value == 2.5, tool.Recoil.Value)
__ok("weapons: recuo do attribute restaurado", tool:GetAttribute("Recoil") == 2.5,
    tool:GetAttribute("Recoil"))

-- 5. Bala nao espalha zera so o spread.
LIB.Flags["W_NoSpread"]:SetValue(true)
waitTicks(4)
__ok("weapons: spread zerado", tool.BulletSpread.Value == 0, tool.BulletSpread.Value)
__ok("weapons: recuo intacto com No Spread", tool.Recoil.Value == 2.5,
    tool.Recoil.Value)
LIB.Flags["W_NoSpread"]:SetValue(false)
waitTicks(4)
__ok("weapons: spread restaurado", tool.BulletSpread.Value == 1.75,
    tool.BulletSpread.Value)

-- 6. Municao infinita: valor, attribute e reloading.
LIB.Flags["W_InfiniteAmmo"]:SetValue(true)
waitTicks(4)
__ok("weapons: municao infinita", tool.Ammo.Value == 9999, tool.Ammo.Value)
__ok("weapons: attribute de municao infinito", tool:GetAttribute("Ammo") == 9999,
    tool:GetAttribute("Ammo"))
__ok("weapons: reloading desligado", tool.Reloading.Value == false, tool.Reloading.Value)
__ok("weapons: clip intacto com municao infinita", tool.Clip.Value == 7, tool.Clip.Value)
LIB.Flags["W_InfiniteAmmo"]:SetValue(false)
waitTicks(4)
__ok("weapons: municao restaurada", tool.Ammo.Value == 3, tool.Ammo.Value)
__ok("weapons: reloading restaurado", tool.Reloading.Value == true, tool.Reloading.Value)

-- 7. Clip infinito mexe no clip, nao na municao.
LIB.Flags["W_InfiniteClip"]:SetValue(true)
waitTicks(4)
__ok("weapons: clip infinito", tool.Clip.Value == 9999, tool.Clip.Value)
__ok("weapons: municao intacta com clip infinito", tool.Ammo.Value == 3, tool.Ammo.Value)
LIB.Flags["W_InfiniteClip"]:SetValue(false)
waitTicks(4)
__ok("weapons: clip restaurado", tool.Clip.Value == 7, tool.Clip.Value)

-- 8. Atirar rapido leva o FireRate ao intervalo configurado.
LIB.Flags["W_FireDelay"]:SetValue(0.05)
LIB.Flags["W_FastFire"]:SetValue(true)
waitTicks(4)
__ok("weapons: firerate no intervalo", math.abs(tool.FireRate.Value - 0.05) < 0.001,
    tool.FireRate.Value)
LIB.Flags["W_FastFire"]:SetValue(false)
waitTicks(4)
__ok("weapons: firerate restaurado", tool.FireRate.Value == 0.8, tool.FireRate.Value)

-- 9. Atirar rapido aciona a arma ao segurar o botao esquerdo.
LIB.Flags["W_FastFire"]:SetValue(true)
local UIS = game:GetService("UserInputService")
-- O HUD de keystrokes tambem escuta InputBegan, entao disparar so o fns[1]
-- acertaria o handler errado. Todos recebem o mesmo evento.
local function fireInput(kind)
    local rec = __M.__signals[tostring(UIS) .. ":" .. kind]
    for _, fn in ipairs(rec.fns) do
        fn({
            UserInputType = Enum.UserInputType.MouseButton1,
            KeyCode = { Name = "Unknown" },
            Position = Vector3.new(0, 0, 0),
        })
    end
end
__M.__activations = {}
fireInput("InputBegan")
__M.__drain(12)
__ok("weapons: fastfire aciona a arma", #__M.__activations > 0, #__M.__activations)
fireInput("InputEnded")
__M.__drain(8)
local afterRelease = #__M.__activations
__M.__drain(12)
__ok("weapons: fastfire para ao soltar", #__M.__activations == afterRelease,
    tostring(afterRelease) .. " -> " .. tostring(#__M.__activations))

-- Com o mod desligado, o clique nao aciona nada.
LIB.Flags["W_FastFire"]:SetValue(false)
__M.__activations = {}
fireInput("InputBegan")
__M.__drain(12)
__ok("weapons: sem fastfire nao aciona", #__M.__activations == 0, #__M.__activations)

-- 10. Arma que entra depois (outra arma comprada) tambem e pega.
local late = mkTool(backpack, 5)
LIB.Flags["W_InfiniteAmmo"]:SetValue(true)
waitTicks(4)
__ok("weapons: arma nova pega o mod", late.Ammo.Value == 9999, late.Ammo.Value)
LIB.Flags["W_InfiniteAmmo"]:SetValue(false)
waitTicks(4)

-- 10. Todos desligados: nada mais e reescrito (valores param de mudar).
waitTicks(4)
local before = tool.Ammo.Value
tool.Ammo.Value = 42
waitTicks(4)
__ok("weapons: nada reescreve com tudo desligado", tool.Ammo.Value == 42,
    tool.Ammo.Value)
tool.Ammo.Value = before

-- 11. Arma equipada (no personagem) tambem e alvo.
tool.Parent = char
LIB.Flags["W_NoRecoil"]:SetValue(true)
waitTicks(4)
__ok("weapons: arma equipada pega o mod", tool.Recoil.Value == 0, tool.Recoil.Value)
LIB.Flags["W_NoRecoil"]:SetValue(false)
waitTicks(4)
tool.Parent = backpack

print(__PASS .. " passaram, " .. __FAIL .. " falharam")
