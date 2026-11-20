local E = __M.ESP
local C = E.Config

-- helpers
local function countVis(t)
    if type(t) ~= "table" then return 0 end
    local n = 0
    for _, d in pairs(t) do
        if type(d) == "table" and d.Visible then n = n + 1 end
    end
    return n
end
local function resetAll()
    for _, k in ipairs({"Box","Tracer","Info","Skeleton","Arrow","Circle","Chams","Life"}) do
        C[k].Enabled = false
        C[k].Glow = false
    end
    C.Info.Name, C.Info.Distance, C.Info.Item = false, false, false
    C.Box.Fill = false
    C.Circle.Filled = false
    C.TeamColor.Enabled = false
    C.Rainbow.Enabled = false
    C.MaxDistance = 1000
    C.TeamCheck = false
    C.SelfESP = false
    C.Box.Type = "Full"
    C.Life.Type = "Bar"
end
local function newPlayer(name)
    local p = __M.addPlayer(name or "Alvo", Color3.fromRGB(255,0,0), 100)
    E.InitPlayerESP(p)
    return p, E.ESP_Cache[p]
end

-- ============ 1. CARREGAMENTO ============
__ok("script carrega inteiro", coroutine.status(__M.__mainCo) == "dead" and __M.__err == nil,
     __M.__err)
__ok("UI montada (>1000 instancias)", (__M.__instCount or 0) > 1000, __M.__instCount)

-- ============ 2. CHAMS / DepthMode (bug do nil) ============
resetAll(); C.Enabled = true; C.Chams.Enabled = true
local p1, d1 = newPlayer("ChamsAlvo")
local ok, err = pcall(E.ESP_Render)
__ok("chams: render nao estoura", ok, err)
__ok("chams: Highlight criado", d1.Chams ~= nil)
__ok("chams: default do Config e AlwaysOnTop", C.Chams.DepthMode == "AlwaysOnTop", C.Chams.DepthMode)
__ok("chams: DepthMode valido", d1.Chams and d1.Chams.DepthMode ~= nil
     and d1.Chams.DepthMode.Name == "AlwaysOnTop",
     d1.Chams and tostring(d1.Chams.DepthMode and d1.Chams.DepthMode.Name))
__ok("chams: Adornee e o personagem", d1.Chams and d1.Chams.Adornee == p1.Character)

-- config antigo com o nome invalido "Always" nao pode derrubar o frame
C.Chams.DepthMode = "Always"
ok, err = pcall(E.ESP_Render)
__ok("chams: DepthMode 'Always' legado nao estoura", ok, err)
__ok("chams: legado cai em AlwaysOnTop", d1.Chams.DepthMode.Name == "AlwaysOnTop",
     d1.Chams.DepthMode and d1.Chams.DepthMode.Name)

C.Chams.DepthMode = "Occluded"
ok, err = pcall(E.ESP_Render)
__ok("chams: DepthMode Occluded aplica", ok and d1.Chams.DepthMode.Name == "Occluded",
     d1.Chams.DepthMode and d1.Chams.DepthMode.Name)
C.Chams.DepthMode = "AlwaysOnTop"

-- desligar destrói o Highlight (nao fica parado no CoreGui)
C.Chams.Enabled = false
E.ESP_Render()
__ok("chams: desligar remove Highlight", d1.Chams == nil)

-- ============ 3. BOX nos 3 modos ============
resetAll(); C.Enabled = true
for _, mode in ipairs({"Full", "Corner", "3D"}) do
    C.Box.Enabled = true
    C.Box.Type = mode
    local p, d = newPlayer("Box" .. mode)
    ok, err = pcall(E.ESP_Render)
    local drawn = countVis(d.Box) + countVis(d.Box3D)
    __ok("box " .. mode .. ": desenha", ok and drawn > 0, string.format("ok=%s vis=%d err=%s", tostring(ok), drawn, tostring(err)))
end

-- ============ 4. BRILHO (glow) por elemento ============
resetAll(); C.Enabled = true; C.Box.Enabled = true; C.Box.Type = "Full"
C.Box.Glow = true
local pg, dg = newPlayer("GlowAlvo")
E.ESP_Render()
__ok("glow box: camadas desenhadas", countVis(dg.Glow.Box) > 0, countVis(dg.Glow.Box))
local layerCount = countVis(dg.Glow.Box)
local boxCount = countVis(dg.Box)
__ok("glow box: 1 camada por segmento", layerCount == boxCount,
     string.format("glow=%d box=%d", layerCount, boxCount))

C.Box.GlowIntensity = 3
E.ESP_Render()
__ok("glow: intensidade 3 usa 2 camadas", countVis(dg.Glow.Box) == boxCount * 2,
     string.format("glow=%d esperado=%d", countVis(dg.Glow.Box), boxCount * 2))

-- sobras: com 2 camadas desenhadas, baixar para 1 tem que esconder a 2a
C.Box.GlowIntensity = 1
E.ESP_Render()
__ok("glow: baixar intensidade esconde as sobras",
     countVis(dg.Glow.Box) == boxCount,
     string.format("glow=%d esperado=%d", countVis(dg.Glow.Box), boxCount))

C.Box.GlowIntensity = 0
E.ESP_Render()
__ok("glow: intensidade 0 esconde tudo", countVis(dg.Glow.Box) == 0, countVis(dg.Glow.Box))

C.Box.Glow = false
C.Box.GlowIntensity = 1
E.ESP_Render()
__ok("glow: desligar esconde camadas", countVis(dg.Glow.Box) == 0, countVis(dg.Glow.Box))

-- troca Full -> 3D com o glow ligado: o halo do Full tem que sumir
C.Box.Type = "Full"; C.Box.Glow = true; C.Box.GlowIntensity = 1
E.ESP_Render()
local fullGlow = countVis(dg.Glow.Box)
__ok("glow: Full desenha halo", fullGlow > 0, fullGlow)
C.Box.Type = "3D"
E.ESP_Render()
__ok("glow 3D: halo do Full foi escondido", countVis(dg.Glow.Box) == 0,
     string.format("fullGlow=%d restante=%d", fullGlow, countVis(dg.Glow.Box)))
__ok("glow 3D: halo 3D desenhado", countVis(dg.Glow.Box3D) > 0, countVis(dg.Glow.Box3D))

-- ============ 5. TRACER / SKELETON / ARROW / CIRCLE ============
resetAll(); C.Enabled = true
C.Tracer.Enabled = true
C.Skeleton.Enabled = true
C.Arrow.Enabled = true
C.Circle.Enabled = true
local pt, dt = newPlayer("TodosAlvo")
ok, err = pcall(E.ESP_Render)
__ok("todos: render ok", ok, err)
__ok("tracer: visivel", dt.Tracer.Visible)
__ok("skeleton: linhas visiveis", countVis(dt.Skeleton) > 0, countVis(dt.Skeleton))
__ok("arrow: visivel", dt.Arrow.Visible)
__ok("circle: desenha", countVis(dt.Circle3D) > 0, countVis(dt.Circle3D))

C.Circle.Filled = true
E.ESP_Render()
__ok("circle preenchido: faces desenhadas", countVis(dt.Circle3DFill) > 0, countVis(dt.Circle3DFill))

-- ============ 6. INFO (nome/distancia) ============
resetAll(); C.Enabled = true
C.Info.Name = true
C.Info.Distance = true
local pi, di = newPlayer("InfoAlvo")
E.ESP_Render()
__ok("info: nome visivel", di.Name.Visible)
__ok("info: nome tem texto", di.Name.Text ~= "", di.Name.Text)
__ok("info: distancia visivel", di.Distance.Visible)
__ok("info: distancia tem texto", di.Distance.Text ~= "", di.Distance.Text)

-- ============ 7. VIDA (barra e texto) ============
resetAll(); C.Enabled = true
C.Life.Enabled = true; C.Life.Type = "Bar"
local pl, dl = newPlayer("VidaAlvo")
ok, err = pcall(E.ESP_Render)
__ok("vida barra: render ok", ok, err)
__ok("vida barra: barra visivel", dl.HealthBar.Visible)
C.Life.Type = "Text"
E.ESP_Render()
__ok("vida texto: texto visivel", dl.HealthText.Visible)

-- ============ 8. TEAM COLOR ============
resetAll(); C.Enabled = true; C.Box.Enabled = true
C.TeamColor.Enabled = true
C.Box.Team = true
local ptm, dtm = newPlayer("TimeAlvo")
E.ESP_Render()
__ok("team: render ok", true)
local line1 = dtm.Box.Line1
__ok("team: cor aplicada ao box", line1.Color ~= nil)

-- ============ 9. FILTROS ============
resetAll(); C.Enabled = true; C.Box.Enabled = true
local lp = __M.giveLocalPlayerCharacter()
E.InitPlayerESP(lp)
local dself = E.ESP_Cache[lp]
E.ESP_Render()
__ok("self esp: LocalPlayer escondido por padrao", countVis(dself.Box) == 0, countVis(dself.Box))
C.SelfESP = true
E.ESP_Render()
__ok("self esp: ligado mostra o LocalPlayer", countVis(dself.Box) > 0, countVis(dself.Box))
C.SelfESP = false

-- distancia maxima
resetAll(); C.Enabled = true; C.Box.Enabled = true
C.MaxDistance = 1
local pfar, dfar = newPlayer("LongeAlvo")
pfar.Character.HumanoidRootPart.Position = Vector3.new(5000, 0, 0)
E.ESP_Render()
__ok("maxdistance: fora do alcance escondido", countVis(dfar.Box) == 0, countVis(dfar.Box))

-- ============ 10. TOGGLE GERAL ============
resetAll(); C.Enabled = false
local pz, dz = newPlayer("DesligadoAlvo")
E.ESP_Render()
__ok("esp desligado: nada desenhado", countVis(dz.Box) == 0 and not dz.Tracer.Visible)

-- ============ 11. ESP_HideAll ============
resetAll(); C.Enabled = true; C.Box.Enabled = true
local ph, dh = newPlayer("HideAlvo")
E.ESP_Render()
local before = countVis(dh.Box)
E.ESP_HideAll()
__ok("hideall: esconde o que estava visivel", before > 0 and countVis(dh.Box) == 0,
     string.format("antes=%d depois=%d", before, countVis(dh.Box)))
