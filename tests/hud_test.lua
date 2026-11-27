-- HUD: Botões, Keystrokes e Overlays.
-- Testa o que o usuario ve e aperta: a aba existe, o layout de teclado e o do
-- exemplo, a tecla certa acende (e so ela), o som toca, os quatro cantos
-- posicionam, o lock trava e o overlay pinta fundo e texto.

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

local function hasText(needle)
    for _, l in ipairs(findAll("TextLabel")) do
        if l.Text == needle then return true end
    end
    return false
end

local function keyEvent(codeName, inputType)
    return {
        UserInputType = inputType or Enum.UserInputType.Keyboard,
        KeyCode = { Name = codeName },
        Position = Vector3.new(0, 0, 0),
    }
end

__ok("hud: script carregou", __M.__err == nil, __M.__err)
__ok("hud: corrotina terminou", coroutine.status(__M.__mainCo) == "dead")

local LIB = __FIVESYNC
__ok("hud: lib exposta", type(LIB) == "table")

-- 1. As tres abas moram em Visual, como o resto do menu: nao existe
-- categoria HUD separada.
__ok("hud: aba Botões presente", hasText(" Botões "))
__ok("hud: aba Keystrokes presente", hasText(" Keystrokes "))
__ok("hud: aba Overlays presente", hasText(" Overlays "))

local KS = getgenv().Vsync_Keystrokes
__ok("hud: keystrokes exposto", type(KS) == "table")
__ok("hud: root do painel existe", KS and KS.Root ~= nil and KS.Root.Parent ~= nil)
__ok("hud: painel comeca visivel", KS and KS.Gui ~= nil and KS.Gui.Enabled == true)

-- 2. Layout FULL do exemplo: numeros, QWERT, ASDFG, ZXCV, CTRL/ALT/SPACE.
if KS then
    local expected = { "1", "2", "3", "4", "5", "TAB", "Q", "W", "E", "R", "T",
                       "CAPS\nLOCK", "A", "S", "D", "F", "G", "SHIFT",
                       "Z", "X", "C", "V", "CTRL", "ALT", "SPACE" }
    local missing = {}
    for _, name in ipairs(expected) do
        if not KS.Keys[name] then missing[#missing + 1] = name end
    end
    __ok("hud: layout FULL completo", #missing == 0, table.concat(missing, ", "))
    __ok("hud: FULL tem 25 teclas", (function()
        local n = 0
        for _ in pairs(KS.Keys) do n = n + 1 end
        return n == 25
    end)())
end

-- 3. Teclado: a tecla fisica acende so o bloco dela.
if KS then
    __M.__fire(__M.services.UserInputService, "InputBegan", keyEvent("W"))
    __M.__drain(5)
    __ok("hud: W acende ao pressionar", KS.Keys["W"].Active == true)
    __ok("hud: A continua apagado", KS.Keys["A"].Active == false)

    -- Sem drain: o handler de InputEnded e sincrono. Checar depois do drain
    -- deixaria a rede de seguranca (poll) apagar a tecla e esconderia um
    -- InputEnded quebrado.
    __M.__fire(__M.services.UserInputService, "InputEnded", keyEvent("W"))
    __ok("hud: W apaga ao soltar", KS.Keys["W"].Active == false)
    __M.__drain(5)

    -- Os dois Shift e os dois Ctrl apontam para a mesma tecla.
    __M.__fire(__M.services.UserInputService, "InputBegan", keyEvent("RightShift"))
    __M.__drain(5)
    __ok("hud: RightShift acende SHIFT", KS.Keys["SHIFT"].Active == true)
    __M.__fire(__M.services.UserInputService, "InputEnded", keyEvent("RightShift"))
    __ok("hud: RightShift apaga SHIFT", KS.Keys["SHIFT"].Active == false)
    __M.__drain(5)

    __M.__fire(__M.services.UserInputService, "InputBegan", keyEvent("RightControl"))
    __M.__drain(5)
    __ok("hud: RightControl acende CTRL", KS.Keys["CTRL"].Active == true)
    __M.__fire(__M.services.UserInputService, "InputEnded", keyEvent("RightControl"))
    __M.__drain(5)

    -- Tecla fora do mapa nao pode acender nada.
    __M.__fire(__M.services.UserInputService, "InputBegan", keyEvent("F9"))
    __M.__drain(5)
    local lit = 0
    for _, d in pairs(KS.Keys) do if d.Active then lit = lit + 1 end end
    __ok("hud: tecla fora do mapa nao acende", lit == 0, lit)

    -- A cor pressionada e a normal sao diferentes, senao o efeito some.
    local keyColor = KS.Keys["W"].Frame.BackgroundColor3
    __M.__fire(__M.services.UserInputService, "InputBegan", keyEvent("W"))
    __M.__drain(5)
    local pressedColor = KS.Keys["W"].Frame.BackgroundColor3
    __ok("hud: cor muda ao pressionar", keyColor ~= pressedColor)
    __M.__fire(__M.services.UserInputService, "InputEnded", keyEvent("W"))
    __M.__drain(5)
    __ok("hud: cor volta ao soltar", KS.Keys["W"].Frame.BackgroundColor3 == keyColor)
end

-- 4. Mouse: esquerdo e direito acendem lados diferentes do desenho.
if KS then
    __ok("hud: mouse desenhado", KS.Mouse.Left ~= nil and KS.Mouse.Right ~= nil)
    local before = KS.Mouse.Left.BackgroundColor3
    __M.__fire(__M.services.UserInputService, "InputBegan",
        { UserInputType = Enum.UserInputType.MouseButton1, Position = Vector3.new(0, 0, 0) })
    __M.__drain(5)
    __ok("hud: LMB acende o esquerdo", KS.Mouse.Left.BackgroundColor3 ~= before)
    __ok("hud: LMB nao acende o direito", KS.Mouse.Right.BackgroundColor3 == before)

    __M.__fire(__M.services.UserInputService, "InputEnded",
        { UserInputType = Enum.UserInputType.MouseButton1, Position = Vector3.new(0, 0, 0) })
    __M.__drain(5)
    __ok("hud: LMB apaga ao soltar", KS.Mouse.Left.BackgroundColor3 == before)

    -- Mostrar Mouse desliga o grupo inteiro.
    local showMouse = LIB.Flags["KS_MostrarMouse"]
    __ok("hud: toggle Mostrar Mouse existe", showMouse ~= nil)
    if showMouse then
        showMouse:SetValue(false)
        __M.__drain(5)
        __ok("hud: mouse escondido", KS.Mouse.Area.Visible == false)
        showMouse:SetValue(true)
        __M.__drain(5)
        __ok("hud: mouse volta", KS.Mouse.Area.Visible == true)
    end
end

-- 5. Som: cada tecla toca um som, e sem repetir o anterior.
if KS then
    __ok("hud: sons criados", KS.Sounds ~= nil and KS.Sounds[1] ~= nil)
    __ok("hud: som do mouse criado", KS.MouseSound ~= nil)

    -- math.random e readonly no Luau, entao o invariante e verificado por
    -- repeticao: em 40 teclas seguidas nenhum som pode repetir o anterior.
    -- Com o re-sorteio quebrado, a chance de passar por sorte e (5/6)^39.
    local before = #__M.__soundsPlayed
    __M.__fire(__M.services.UserInputService, "InputBegan", keyEvent("A"))
    __M.__drain(5)
    __ok("hud: tecla toca som", #__M.__soundsPlayed == before + 1, #__M.__soundsPlayed - before)

    local firstSound = __M.__soundsPlayed[#__M.__soundsPlayed]
    __M.__fire(__M.services.UserInputService, "InputEnded", keyEvent("A"))
    __M.__drain(5)
    __M.__fire(__M.services.UserInputService, "InputBegan", keyEvent("S"))
    __M.__drain(5)
    __ok("hud: som nao repete o anterior", __M.__soundsPlayed[#__M.__soundsPlayed] ~= firstSound)
    __M.__fire(__M.services.UserInputService, "InputEnded", keyEvent("S"))
    __M.__drain(5)

    local repeats = 0
    for _ = 1, 40 do
        __M.__fire(__M.services.UserInputService, "InputBegan", keyEvent("Q"))
        __M.__drain(2)
        __M.__fire(__M.services.UserInputService, "InputEnded", keyEvent("Q"))
        __M.__drain(2)
    end
    for i = 2, #__M.__soundsPlayed do
        if __M.__soundsPlayed[i] == __M.__soundsPlayed[i - 1] then
            repeats = repeats + 1
        end
    end
    __ok("hud: nunca repete som em sequencia", repeats == 0, repeats .. " repeticoes")

    local beforeMouse = #__M.__soundsPlayed
    __M.__fire(__M.services.UserInputService, "InputBegan",
        { UserInputType = Enum.UserInputType.MouseButton1, Position = Vector3.new(0, 0, 0) })
    __M.__drain(5)
    __ok("hud: clique toca som do mouse", #__M.__soundsPlayed == beforeMouse + 1)
    __ok("hud: som do clique e o do mouse",
         __M.__soundsPlayed[#__M.__soundsPlayed] == KS.MouseSound)
    __M.__fire(__M.services.UserInputService, "InputEnded",
        { UserInputType = Enum.UserInputType.MouseButton1, Position = Vector3.new(0, 0, 0) })
    __M.__drain(5)

    -- Volume chega nos sons.
    local vol = LIB.Flags["KS_Volume"]
    __ok("hud: slider de volume existe", vol ~= nil)
    if vol then
        vol:SetValue(0.25)
        __M.__drain(5)
        __ok("hud: volume aplicado na tecla", KS.Sounds[1].Volume == 0.25, KS.Sounds[1].Volume)
        __ok("hud: volume aplicado no mouse", KS.MouseSound.Volume == 0.25)
        vol:SetValue(0.7)
        __M.__drain(5)
    end
end

-- 6. Tipo WASD troca o layout; FULL volta.
if KS then
    local tipo = LIB.Flags["KS_Tipo"]
    __ok("hud: dropdown Tipo existe", tipo ~= nil)
    if tipo then
        tipo:SetValue("WASD")
        __M.__drain(5)
        __ok("hud: WASD tem W", KS.Keys["W"] ~= nil)
        __ok("hud: WASD nao tem numeros", KS.Keys["1"] == nil)
        __ok("hud: WASD nao acumula TAB", KS.Keys["TAB"] == nil)
        local n = 0
        for _ in pairs(KS.Keys) do n = n + 1 end
        __ok("hud: WASD tem 6 teclas", n == 6, n)

        tipo:SetValue("FULL")
        __M.__drain(5)
        __ok("hud: FULL volta com numeros", KS.Keys["1"] ~= nil)
        __ok("hud: FULL volta sem sobras", KS.Keys["W"] ~= nil and KS.Keys["SPACE"] ~= nil)
    end
end

-- 7. Posicao: os quatro cantos mudam o anchor do painel.
if KS then
    local pos = LIB.Flags["KS_Posicao"]
    __ok("hud: dropdown Posição existe", pos ~= nil)
    if pos then
        local cases = {
            BottomLeft  = { 0, 1 },
            BottomRight = { 1, 1 },
            TopLeft     = { 0, 0 },
            TopRight    = { 1, 0 },
        }
        local bad = {}
        for name, ap in pairs(cases) do
            pos:SetValue(name)
            __M.__drain(5)
            if KS.Root.AnchorPoint.X ~= ap[1] or KS.Root.AnchorPoint.Y ~= ap[2] then
                bad[#bad + 1] = name
            end
        end
        __ok("hud: os quatro cantos posicionam", #bad == 0, table.concat(bad, ", "))
        pos:SetValue("BottomLeft")
        __M.__drain(5)
    end

    -- Tamanho escala o painel inteiro.
    local size = LIB.Flags["KS_Tamanho"]
    __ok("hud: slider Tamanho existe", size ~= nil)
    if size then
        size:SetValue(1.25)
        __M.__drain(5)
        __ok("hud: tamanho aplicado no UIScale", KS.Scale.Scale == 1.25, KS.Scale.Scale)
        size:SetValue(1)
        __M.__drain(5)
    end
end

-- 8. Cores das teclas e do mouse chegam no desenho.
if KS then
    local corTecla = LIB.Flags["KS_CorTecla"]
    __ok("hud: color picker da tecla existe", corTecla ~= nil)
    if corTecla then
        corTecla:SetValue(Color3.fromRGB(10, 20, 30))
        __M.__drain(5)
        __ok("hud: cor da tecla aplicada",
             KS.Keys["W"].Frame.BackgroundColor3 == Color3.fromRGB(10, 20, 30))
    end

    local corMouse = LIB.Flags["KS_CorMouse"]
    __ok("hud: color picker do mouse existe", corMouse ~= nil)
    if corMouse then
        corMouse:SetValue(Color3.fromRGB(40, 50, 60))
        __M.__drain(5)
        __ok("hud: cor do mouse aplicada",
             KS.Mouse.Body.BackgroundColor3 == Color3.fromRGB(40, 50, 60))
    end
end

-- 9. Toggle principal e lock de arrasto.
if KS then
    local ativar = LIB.Flags["KS_Ativar"]
    __ok("hud: toggle Keystrokes existe", ativar ~= nil)
    if ativar then
        ativar:SetValue(false)
        __M.__drain(5)
        __ok("hud: keystrokes desligado esconde", KS.Gui.Enabled == false)
        -- Desligado nao pode acender nem tocar som.
        local before = #__M.__soundsPlayed
        __M.__fire(__M.services.UserInputService, "InputBegan", keyEvent("D"))
        __M.__drain(5)
        __ok("hud: desligado nao acende", KS.Keys["D"].Active == false)
        __ok("hud: desligado nao toca som", #__M.__soundsPlayed == before)
        __M.__fire(__M.services.UserInputService, "InputEnded", keyEvent("D"))
        __M.__drain(5)
        ativar:SetValue(true)
        __M.__drain(5)
        __ok("hud: keystrokes volta", KS.Gui.Enabled == true)
    end

    local lock = LIB.Flags["KS_LockPos"]
    __ok("hud: toggle Lock Posição existe", lock ~= nil)
    if lock then
        local function drag()
            __M.__fire(KS.DragArea, "InputBegan", {
                UserInputType = Enum.UserInputType.MouseButton1,
                Position = Vector3.new(0, 0, 0),
            })
            __M.__fire(__M.services.UserInputService, "InputChanged", {
                UserInputType = Enum.UserInputType.MouseMovement,
                Position = Vector3.new(90, 90, 0),
            })
        end

        lock:SetValue(true)
        __M.__drain(5)
        local before = KS.Root.Position
        drag()
        __ok("hud: travado nao arrasta", KS.Root.Position == before)

        lock:SetValue(false)
        __M.__drain(5)
        local before2 = KS.Root.Position
        drag()
        __ok("hud: destravado arrasta", KS.Root.Position ~= before2)
    end
end

-- 10. Overlays: FPS, fundo e texto.
local OV = getgenv().Vsync_Overlays
__ok("hud: overlay exposto", type(OV) == "table")
__ok("hud: label do overlay existe", OV and OV.Label ~= nil)

if OV then
    __M.__drain(5)
    __ok("hud: FPS comeca com placeholder", OV.Label.Text:find("FPS:") ~= nil, OV.Label.Text)

    for _ = 1, 60 do __M.__step("RenderStepped", 1 / 60) end
    __ok("hud: FPS calculado depois de 1s", OV.Label.Text == "FPS: 60", OV.Label.Text)

    -- 31 frames: 30*(1/30) da 0.9999... e nao cruza a fronteira do segundo.
    for _ = 1, 31 do __M.__step("RenderStepped", 1 / 30) end
    __ok("hud: FPS acompanha a queda", OV.Label.Text == "FPS: 30", OV.Label.Text)

    local fps = LIB.Flags["OV_FPS"]
    if fps then
        fps:SetValue(false)
        __M.__drain(5)
        __ok("hud: texto do FPS sai", OV.Label.Text == "", OV.Label.Text)
        fps:SetValue(true)
        __M.__drain(5)
    end

    -- Fundo: cor e transparencia proprios, independentes do texto.
    local bgColor = LIB.Flags["OV_CorFundo"]
    __ok("hud: color picker do fundo existe", bgColor ~= nil)
    if bgColor then
        bgColor:SetValue(Color3.fromRGB(12, 34, 56))
        __M.__drain(5)
        __ok("hud: cor do fundo aplicada",
             OV.Panel.BackgroundColor3 == Color3.fromRGB(12, 34, 56))
    end

    local bgTransp = LIB.Flags["OV_TransparenciaFundo"]
    __ok("hud: slider de transparencia do fundo existe", bgTransp ~= nil)
    if bgTransp then
        bgTransp:SetValue(0.8)
        __M.__drain(5)
        __ok("hud: transparencia do fundo aplicada", OV.Panel.BackgroundTransparency == 0.8)
    end

    local cor = LIB.Flags["OV_Cor"]
    __ok("hud: color picker do texto existe", cor ~= nil)
    if cor then
        cor:SetValue(Color3.fromRGB(200, 100, 50))
        __M.__drain(5)
        __ok("hud: cor do texto aplicada",
             OV.Label.TextColor3 == Color3.fromRGB(200, 100, 50))
    end

    local size = LIB.Flags["OV_Tamanho"]
    __ok("hud: slider de tamanho do overlay existe", size ~= nil)
    if size then
        size:SetValue(30)
        __M.__drain(5)
        __ok("hud: tamanho do texto aplicado", OV.Label.TextSize == 30, OV.Label.TextSize)
        size:SetValue(18)
        __M.__drain(5)
    end

    -- Lock do overlay: travado nao arrasta, destravado arrasta.
    local lock = LIB.Flags["OV_LockPos"]
    __ok("hud: toggle Lock do overlay existe", lock ~= nil)
    if lock then
        local dragArea
        for _, c in ipairs(OV.Panel:GetChildren()) do
            if c.ClassName == "TextButton" then dragArea = c end
        end
        __ok("hud: area de arrasto do overlay existe", dragArea ~= nil)

        local function drag()
            __M.__fire(dragArea, "InputBegan", {
                UserInputType = Enum.UserInputType.MouseButton1,
                Position = Vector3.new(0, 0, 0),
            })
            __M.__fire(__M.services.UserInputService, "InputChanged", {
                UserInputType = Enum.UserInputType.MouseMovement,
                Position = Vector3.new(70, 70, 0),
            })
        end

        lock:SetValue(true)
        __M.__drain(5)
        local before = OV.Panel.Position
        drag()
        __ok("hud: overlay travado nao arrasta", OV.Panel.Position == before)

        lock:SetValue(false)
        __M.__drain(5)
        local before2 = OV.Panel.Position
        drag()
        __ok("hud: overlay destravado arrasta", OV.Panel.Position ~= before2)
    end

    local mostrar = LIB.Flags["OV_Mostrar"]
    if mostrar then
        mostrar:SetValue(false)
        __M.__drain(5)
        __ok("hud: overlay escondido", OV.Panel.Parent.Enabled == false)
        mostrar:SetValue(true)
        __M.__drain(5)
    end
end

-- 11. Botoes rapidos: todo Flag aponta para algo real.
local QB = getgenv().Vsync_QuickButtons
__ok("hud: quick buttons exposto", type(QB) == "table")
if QB then
    local broken, total = {}, 0
    for id, entry in pairs(QB.Registry) do
        total = total + 1
        local flag = entry.Def.Flag
        if flag and not LIB.Flags[flag] then broken[#broken + 1] = id .. "->" .. flag end
    end
    __ok("hud: todo botao aponta para Flag real", #broken == 0, table.concat(broken, ", "))
    __ok("hud: registro com 23 botoes", total == 23, total)
end

-- 12. Mobile: em tela estreita o painel encolhe para caber.
if KS then
    local camera = workspace.CurrentCamera
    local before = KS.Scale.Scale
    camera.ViewportSize = Vector2.new(300, 800)
    __M.__fire(camera, "ViewportSize", Vector2.new(300, 800))
    __M.__drain(5)
    local narrow = KS.Scale.Scale
    __ok("hud: encolhe em tela estreita", narrow < before, tostring(narrow))

    camera.ViewportSize = Vector2.new(1920, 1080)
    __M.__fire(camera, "ViewportSize", Vector2.new(1920, 1080))
    __M.__drain(5)
    __ok("hud: volta ao tamanho em tela larga", KS.Scale.Scale == before, tostring(KS.Scale.Scale))
end

-- 13. Lock dos botoes rapidos: travado nao arrasta, destravado arrasta.
if QB then
    local lockFlag = LIB.Flags["QuickBtn_LockPos"]
    __ok("hud: toggle Lock dos botoes existe", lockFlag ~= nil)
    if lockFlag then
        local entry
        for _, e in pairs(QB.Registry) do entry = e break end
        __ok("hud: entrada de botao encontrada", entry ~= nil)

        if entry then
            local click
            for _, c in ipairs(entry.Frame:GetChildren()) do
                if c.ClassName == "TextButton" then click = c end
            end
            __ok("hud: area de clique do botao existe", click ~= nil)

            if click then
                -- O botao exige HOLD de 3s ou movimento > 6px para armar o
                -- arraste; mover direto e o caminho que o usuario faz.
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

                lockFlag:SetValue(true)
                __M.__drain(5)
                local before = entry.Frame.Position
                drag()
                __ok("hud: botao travado nao arrasta", entry.Frame.Position == before)

                lockFlag:SetValue(false)
                __M.__drain(5)
                local before2 = entry.Frame.Position
                drag()
                __ok("hud: botao destravado arrasta", entry.Frame.Position ~= before2)
            end
        end
    end
end
