-- Categoria HUD: Botões, Keystrokes e Overlays.
-- O que se testa aqui e o que o usuario percebe na tela: a categoria existe,
-- as abas moram nela, o painel de keystrokes acende a tecla certa e o FPS
-- mostra um numero plausivel.
__ok("hud: script carregou", __M.__err == nil, __M.__err)
__ok("hud: corrotina terminou", coroutine.status(__M.__mainCo) == "dead")

local function findAll(cls)
    local found = {}
    local function walk(o, d)
        if not o or d > 80 then return end
        for _, c in pairs(o:GetChildren() or {}) do
            if c.ClassName == cls then found[#found + 1] = c end
            walk(c, d + 1)
        end
    end
    for _, s in pairs(__M.Instances) do walk(s, 0) end
    return found
end

local function textLabels()
    local out = {}
    for _, l in ipairs(findAll("TextLabel")) do
        if l.Text and l.Text ~= "" then out[#out + 1] = l.Text end
    end
    return out
end

local function hasText(needle)
    for _, t in ipairs(textLabels()) do
        if t == needle then return true end
    end
    return false
end

-- 1. As tres abas existem com o nome que o usuario ve no menu.
__ok("hud: aba Botões presente", hasText(" Botões "))
__ok("hud: aba Keystrokes presente", hasText(" Keystrokes "))
__ok("hud: aba Overlays presente", hasText(" Overlays "))

-- 2. Keystrokes: o painel nasce com uma celula por tecla, todas visiveis.
local LIB = __FIVESYNC
__ok("hud: lib exposta", type(LIB) == "table")

local KS = getgenv().Vsync_Keystrokes
__ok("hud: painel de keystrokes exposto", type(KS) == "table")
__ok("hud: celulas criadas", KS and #KS.Cells == 9, KS and #KS.Cells)
__ok("hud: painel na tela", KS and KS.Panel ~= nil and KS.Panel.Parent ~= nil)
__ok("hud: painel comeca visivel", KS and KS.Panel.Parent.Enabled == true)

if KS then
    local function cellFor(id)
        for _, c in ipairs(KS.Cells) do
            if c.Def.Id == id then return c end
        end
    end

    __ok("hud: celula do W existe", cellFor("W") ~= nil)
    __ok("hud: celula do LMB existe", cellFor("LMB") ~= nil)

    -- Nada pressionado: tudo apagado.
    local w = cellFor("W")
    __ok("hud: W comeca apagado", w and w.Painted == false, w and tostring(w.Painted))

    -- Pressionar W acende so o W.
    __M.__keysDown["W"] = true
    __M.__drain(10)
    __ok("hud: W acende ao pressionar", w and w.Painted == true, w and tostring(w.Painted))
    __ok("hud: A continua apagado", cellFor("A").Painted == false)

    -- Soltar apaga.
    __M.__keysDown["W"] = false
    __M.__drain(10)
    __ok("hud: W apaga ao soltar", w and w.Painted == false, w and tostring(w.Painted))

    -- Mouse: o painel le os botoes pressionados, nao o teclado.
    __M.__mouseDown = { 1 }
    __M.__drain(10)
    __ok("hud: LMB acende com botao esquerdo", cellFor("LMB").Painted == true)
    __ok("hud: RMB nao acende com botao esquerdo", cellFor("RMB").Painted == false)

    __M.__mouseDown = { 2 }
    __M.__drain(10)
    __ok("hud: RMB acende com botao direito", cellFor("RMB").Painted == true)
    __ok("hud: LMB apaga ao soltar", cellFor("LMB").Painted == false)
    __M.__mouseDown = {}
    __M.__drain(10)

    -- Desligar uma tecla na UI esconde a celula e nao deixa ela acesa.
    local keyToggle = LIB.Flags["KS_Key_Space"]
    __ok("hud: toggle da tecla Space existe", keyToggle ~= nil)
    if keyToggle then
        keyToggle:SetValue(false)
        __M.__drain(5)
        local space
        for _, c in ipairs(KS.Cells) do if c.Def.Id == "Space" then space = c end end
        __ok("hud: celula Space escondida", space.Frame.Visible == false)

        keyToggle:SetValue(true)
        __M.__drain(5)
        __ok("hud: celula Space volta", space.Frame.Visible == true)
    end

    -- O slider de espacamento tem que chegar no UIListLayout: definir o
    -- padding so na criacao deixava o slider sem efeito visivel.
    local gapFlag = LIB.Flags["KS_Espacamento"]
    __ok("hud: slider de espacamento existe", gapFlag ~= nil)
    if gapFlag then
        gapFlag:SetValue(12)
        __M.__drain(5)
        __ok("hud: espacamento aplicado no layout",
             KS.Layout ~= nil and KS.Layout.Padding.Offset == 12,
             KS.Layout and tostring(KS.Layout.Padding.Offset))
        gapFlag:SetValue(4)
        __M.__drain(5)
    end

    -- Esconder o painel inteiro desliga o ScreenGui.
    local showKS = LIB.Flags["KS_Mostrar"]
    __ok("hud: toggle Mostrar Keystrokes existe", showKS ~= nil)
    if showKS then
        showKS:SetValue(false)
        __M.__drain(5)
        __ok("hud: painel escondido", KS.Panel.Parent.Enabled == false)
        showKS:SetValue(true)
        __M.__drain(5)
        __ok("hud: painel volta", KS.Panel.Parent.Enabled == true)
    end
end

-- 3. Overlays: o FPS sai de uma contagem real de frames, nao de um numero fixo.
local OV = getgenv().Vsync_Overlays
__ok("hud: overlay exposto", type(OV) == "table")
__ok("hud: label do overlay existe", OV and OV.Label ~= nil)

if OV then
    __M.__drain(5)
    -- Antes de qualquer frame o texto e o placeholder.
    __ok("hud: FPS comeca sem numero", OV.Label.Text:find("FPS:") ~= nil, OV.Label.Text)

    -- Simula um segundo a 60 fps.
    for _ = 1, 60 do __M.__step("RenderStepped", 1 / 60) end
    __ok("hud: FPS calculado depois de 1s", OV.Label.Text == "FPS: 60", OV.Label.Text)

    -- Um segundo a 30 fps tem que mudar o numero. 31 frames porque 30*(1/30)
    -- da 0.9999... em ponto flutuante e nao cruza a fronteira do segundo.
    for _ = 1, 31 do __M.__step("RenderStepped", 1 / 30) end
    __ok("hud: FPS acompanha a queda", OV.Label.Text == "FPS: 30", OV.Label.Text)

    -- Desligar o FPS some com o texto.
    local fpsToggle = LIB.Flags["OV_FPS"]
    __ok("hud: toggle Mostrar FPS existe", fpsToggle ~= nil)
    if fpsToggle then
        fpsToggle:SetValue(false)
        __M.__drain(5)
        __ok("hud: texto do FPS sai", OV.Label.Text == "", OV.Label.Text)
        fpsToggle:SetValue(true)
        __M.__drain(5)
        __ok("hud: texto do FPS volta", OV.Label.Text:find("FPS:") ~= nil, OV.Label.Text)
    end

    -- Esconder o overlay desliga o ScreenGui inteiro.
    local showOV = LIB.Flags["OV_Mostrar"]
    if showOV then
        showOV:SetValue(false)
        __M.__drain(5)
        __ok("hud: overlay escondido", OV.Panel.Parent.Enabled == false)
        showOV:SetValue(true)
        __M.__drain(5)
    end
end

-- 4. Botões: os novos entraram no registro e refletem o Flag certo.
local QB = getgenv().Vsync_QuickButtons
__ok("hud: quick buttons exposto", type(QB) == "table")
__ok("hud: registro tem 23 botoes", QB and (function()
    local n = 0
    for _ in pairs(QB.Registry) do n = n + 1 end
    return n == 23
end)(), QB and (function()
    local n = 0
    for _ in pairs(QB.Registry) do n = n + 1 end
    return n
end)())

-- Todo botao de Flag aponta para um Flag que existe: um id errado vira um
-- botao que nunca acende e nunca alterna.
if QB then
    local broken = {}
    for id, entry in pairs(QB.Registry) do
        local flag = entry.Def.Flag
        if flag and not LIB.Flags[flag] then broken[#broken + 1] = id .. "->" .. flag end
    end
    __ok("hud: todo botao aponta para Flag real", #broken == 0, table.concat(broken, ", "))
end

-- 5. Lock Posição dos botoes: travado, o arrasto nao move.
if QB then
    -- Registry e indexado por id, nao array: ipairs nao itera nada aqui.
    local entry
    for _, e in pairs(QB.Registry) do entry = e break end
    __ok("hud: entrada de botao encontrada", entry ~= nil)
    local lockFlag = LIB.Flags["QuickBtn_LockPos"]
    __ok("hud: toggle Lock Posição existe", lockFlag ~= nil)
    if entry and lockFlag then
        entry.Frame.Visible = true
        lockFlag:SetValue(true)
        __M.__drain(5)
        local click
        for _, c in ipairs(entry.Frame:GetChildren()) do
            if c.ClassName == "TextButton" then click = c end
        end
        __ok("hud: area de clique do botao existe", click ~= nil)

        local function drag()
            __M.__fire(click, "InputBegan", {
                UserInputType = Enum.UserInputType.MouseButton1,
                Position = Vector3.new(0, 0, 0),
            })
            __M.__fire(__M.services.UserInputService, "InputChanged", {
                UserInputType = Enum.UserInputType.MouseMovement,
                Position = Vector3.new(80, 80, 0),
            })
        end

        local before = entry.Frame.Position
        drag()
        __ok("hud: travado nao arrasta", entry.Frame.Position == before,
             tostring(entry.Frame.Position.X.Offset) .. "," .. tostring(entry.Frame.Position.Y.Offset))

        -- Destravado o mesmo gesto tem que mover: sem isso o teste passaria
        -- mesmo se o arrasto nunca funcionasse.
        lockFlag:SetValue(false)
        __M.__drain(5)
        local before2 = entry.Frame.Position
        drag()
        __ok("hud: destravado arrasta", entry.Frame.Position ~= before2,
             tostring(entry.Frame.Position.X.Offset) .. "," .. tostring(entry.Frame.Position.Y.Offset))
        lockFlag:SetValue(false)
        __M.__drain(5)
    end
end
