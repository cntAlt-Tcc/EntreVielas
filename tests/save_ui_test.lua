-- Aba Save: o botao de lock tem que existir, refletir o estado e alternar.
-- Precisa de um config em disco ANTES do script rodar, porque a lista so
-- desenha linhas para o que ja existe.
__PRE_SEED = {
    ["Vsync/Vsync-Configs/Antigo"] = '{"__INFORMATION":{"Type":"Information","Author":"Team EntreViela$","Name":"Antigo","CreatedDate":"1/1/2025"}}'
}

local CM, FS, L = __M.Save.ConfigManager, __M.Save.FS, __M.Lib
local dir = "Vsync/Vsync-Configs"

__ok("load: script carregou", __M.__err == nil, __M.__err)
__ok("load: corrotina terminou", coroutine.status(__M.__mainCo) == "dead")
__ok("seed: config antigo no disco", FS.files[dir .. "/Antigo"] ~= nil)

local function findAll(cls)
    local found = {}
    local function walk(o, d)
        if not o or d > 60 then return end
        for _, c in pairs(o:GetChildren() or {}) do
            if c.ClassName == cls then found[#found + 1] = c end
            walk(c, d + 1)
        end
    end
    for _, s in pairs(__M.Instances) do walk(s, 0) end
    return found
end

local unlockIcon = L:CacheImage(L.Lucide["lucide-unlock"])
local lockIcon = L:CacheImage(L.Lucide["lucide-lock"])

local lockBtn
for _, b in ipairs(findAll("ImageButton")) do
    if b.Image == unlockIcon or b.Image == lockIcon then lockBtn = b break end
end

__ok("ui: botao de lock existe na linha do config", lockBtn ~= nil)
__ok("ui: lock comeca destravado", lockBtn and lockBtn.Image == unlockIcon,
     lockBtn and lockBtn.Image)

if lockBtn then
    __M.__fire(lockBtn, "MouseButton1Click")
    __M.__drain()
    __ok("ui: clique trava o config", CM:IsLocked("Antigo") == true)
    __ok("ui: icone vira cadeado fechado", lockBtn.Image == lockIcon, lockBtn.Image)

    -- Travado: Save e Delete precisam recusar.
    __ok("ui: Save recusa config travado", CM:WriteConfig({ Name = "Antigo" }) == false)
    __ok("ui: Delete recusa config travado", CM:DeleteConfig("Antigo") == false)
    __ok("ui: arquivo travado intacto", FS.files[dir .. "/Antigo"] ~= nil)

    __M.__fire(lockBtn, "MouseButton1Click")
    __M.__drain()
    __ok("ui: segundo clique destrava", CM:IsLocked("Antigo") == false)
    __ok("ui: icone volta a abrir", lockBtn.Image == unlockIcon, lockBtn.Image)
end

-- O refresh periodico so redesenha quando a contagem de arquivos muda. Travar
-- pelo ConfigManager nao mexe na contagem, entao criar outro config e o que
-- forca o redraw. Depois dele o cadeado de "Antigo" tem que continuar fechado.
CM:SetLocked("Antigo", true)
CM:WriteConfig({ Name = "Outro" })
__M.__drain(80)

local function countLocks()
    local n = 0
    for _, b in ipairs(findAll("ImageButton")) do
        if b.Image == lockIcon then n = n + 1 end
    end
    return n
end
__ok("ui: refresh redesenhou", countLocks() == 1, countLocks())
__ok("ui: lock persiste apos refresh", CM:IsLocked("Antigo") == true)
__ok("ui: outro config nao herdou o lock", CM:IsLocked("Outro") == false)

-- Clicar Save/Delete num config travado nao pode anunciar sucesso nem tocar o
-- arquivo. As notificacoes sao TextLabels criadas na UI; contamos o texto.
local function notifTexts()
    local out = {}
    for _, o in ipairs(findAll("TextLabel")) do
        local t = o.Text or ""
        if t:find("^Save config") or t:find("^Delete config") or t:find("locked$") then
            out[#out + 1] = t
        end
    end
    return out
end

local lockedPath = dir .. "/Antigo"
local lockedBefore = FS.files[lockedPath]

-- Reencontrar a linha de "Antigo" apos o refresh: o botao antigo foi destruido.
local function rowFor(name)
    for _, o in ipairs(findAll("Frame")) do
        local label
        for _, c in ipairs(o:GetChildren() or {}) do
            if c.ClassName == "TextLabel" and c.Text == name then label = c end
        end
        if label then return o end
    end
end

local row = rowFor("Antigo")
__ok("ui: linha do config encontrada apos refresh", row ~= nil)

if row then
    -- Botoes da linha: Save e Delete sao filhos da mesma LinkValues.
    local saveBtn, delBtn
    local function scan(o, d)
        if not o or d > 6 then return end
        for _, c in pairs(o:GetChildren() or {}) do
            if c.ClassName == "ImageButton" and c.Image == __M.Lib:CacheImage("rbxassetid://10747362393") then
                delBtn = c
            end
            scan(c, d + 1)
        end
    end
    scan(row, 0)
    __ok("ui: botao de delete na linha", delBtn ~= nil)

    if delBtn then
        __M.__fire(delBtn, "MouseButton1Click")
        __M.__drain()
        __ok("ui: delete travado nao apaga arquivo", FS.files[lockedPath] == lockedBefore)
        __ok("ui: delete travado nao anuncia sucesso",
             not table.find(notifTexts(), "Delete config \"Antigo\""),
             table.concat(notifTexts(), " | "))
    end
end
