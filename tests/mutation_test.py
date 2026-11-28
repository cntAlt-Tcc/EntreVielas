#!/usr/bin/env python3
"""Mutation testing: cada mutacao injeta um bug real e o teste DEVE falhar."""
import subprocess, shutil, pathlib, sys, os

ROOT = pathlib.Path(__file__).resolve().parent.parent
SRC = ROOT / 'Script' / 'A'
BAK = ROOT / 'tests' / '.A.bak'

MUTS = [
    ("DepthMode volta a 'Always' no default",
     'DepthMode = "AlwaysOnTop", RGB = true', 'DepthMode = "Always", RGB = true'),
    ("dropdown volta a 'Always'",
     'Default = "AlwaysOnTop",\n    Values = {"AlwaysOnTop", "Occluded"}',
     'Default = "Always",\n    Values = {"AlwaysOnTop", "Occluded"}'),
    ("sem fallback de nil no DepthMode",
     'SetIf(h, "DepthMode", Enum.HighlightDepthMode[Config.Chams.DepthMode]\n                    or Enum.HighlightDepthMode.AlwaysOnTop)',
     'SetIf(h, "DepthMode", Enum.HighlightDepthMode[Config.Chams.DepthMode])'),
    ("glow ignora a intensidade",
     'local layers, n = GlowLayers(intensity), count',
     'local layers, n = 1, count'),
    ("glow nao esconde sobras",
     '    for i = used + 1, #store do\n        local l = store[i]\n        if l.Visible then l.Visible = false end\n    end',
     '    for i = used + 1, #store do end'),
    ("intensidade 0 ainda desenha",
     '    if not intensity or intensity <= 0 then return 0 end',
     '    if not intensity then return 0 end'),
    ("chams nao destroi ao desligar",
     '        elseif data.Chams then\n            ChamsDestroy(data)\n        end',
     '        end'),
    ("box 3D usa store errado no glow",
     'local store = is3D and data.Glow.Box3D or data.Glow.Box',
     'local store = data.Glow.Box'),
    ("glow nao esconde o modo inativo",
     'HideList(is3D and data.Glow.Box or data.Glow.Box3D)',
     ''),
    ("self esp ignora o filtro",
     'local skip = (not Config.SelfESP and player == LocalPlayer)',
     'local skip = false'),
    ("maxdistance ignorada",
     '        if distance > maxDist then',
     '        if false then'),
    ("tracer nao desenha",
     '    if Config.Tracer.Enabled then',
     '    if false then'),
    ("skeleton nao desenha",
     '    if showSkel then',
     '    if false then'),
    ("arrow nao desenha",
     '        if Config.Arrow.Enabled then',
     '        if false then'),
    ("circle nao desenha",
     '        if Config.Circle.Enabled then',
     '        if false then'),
    ("vida barra nao desenha",
     '        if lifeBar then',
     '        if false then'),
    ("nome nao desenha",
     '        if showName then',
     '        if false then'),
    ("hideall nao esconde nada",
     'local function ESP_HideAll()',
     'local function ESP_HideAll() return'),
    # --- compatibilidade com a API da lib (nome antigo / inexistente) ---
    ("metodo FiveSync inexistente",
     'FiveSync:SetTheme(v)', 'FiveSync:SetThemeOld(v)'),
    ("elemento AddToggle inexistente",
     'VisualSection:AddToggle({', 'VisualSection:AddToggleLegacy({'),
    ("janela DrawConfig inexistente",
     'Window:DrawConfig(', 'Window:DrawConfigOld('),
    ("secao DrawSection inexistente",
     'WlcT:DrawSection({', 'WlcT:DrawSectionOld({'),
    ("AddColorPicker inexistente",
     'QuickCfgSection:AddColorPicker({', 'QuickCfgSection:AddColorPickerX({'),
    # --- regressoes de contrato da lib ---
    ("campo morto volta no AddToggle",
     '    Name = "FullBright",\n    Default = false,',
     '    Name = "FullBright",\n    Description = "x",\n    Default = false,'),
    # --- HUD: keystrokes ---
    ("tecla nao acende ao pressionar",
     '            if name then SetKey(name, true) end',
     '            if false then SetKey(name, true) end'),
    ("tecla nao apaga ao soltar",
     '            if name then SetKey(name, false) end',
     '            if false then SetKey(name, false) end'),
    ("tecla ignora a cor de pressionada",
     '            Tween(data.Frame, { BackgroundColor3 = KSState.KeyPressedColor })',
     '            Tween(data.Frame, { BackgroundColor3 = KSState.KeyColor })'),
    ("tecla ignora a cor normal ao soltar",
     '            Tween(data.Frame, { BackgroundColor3 = KSState.KeyColor })',
     '            Tween(data.Frame, { BackgroundColor3 = KSState.KeyPressedColor })'),
    ("mouse esquerdo nao acende",
     '            Tween(M.Left, { BackgroundColor3 = pressed and KSState.MousePressedColor or KSState.MouseColor })',
     '            Tween(M.Left, { BackgroundColor3 = KSState.MouseColor })'),
    ("clique do mouse nao toca som",
     '            PlayMouseSound()\n            SetMouse("LEFT", true)',
     '            SetMouse("LEFT", true)'),
    ("tecla nao toca som",
     '            PlayKeySound()\n            local name = KS_KEYMAP[input.KeyCode and input.KeyCode.Name or ""]',
     '            local name = KS_KEYMAP[input.KeyCode and input.KeyCode.Name or ""]'),
    ("som repete a variacao anterior",
     '            while index == Keystrokes.LastSound do\n                index = math.random(#KS_KEY_SOUNDS)\n            end',
     ''),
    ("volume nao chega nos sons",
     '        for _, s in pairs(Keystrokes.Sounds) do pcall(function() s.Volume = KSState.Volume end) end',
     ''),
    ("mostrar mouse nao esconde",
     '        if Keystrokes.Mouse.Area then Keystrokes.Mouse.Area.Visible = KSState.ShowMouse end',
     '        if Keystrokes.Mouse.Area then Keystrokes.Mouse.Area.Visible = true end'),
    ("tipo WASD nao troca o layout",
     '        if KSState.Layout == "WASD" then\n            BuildKeyboardWASD()',
     '        if false then\n            BuildKeyboardWASD()'),
    ("troca de layout nao limpa as teclas antigas",
     '        Keystrokes.Keys = {}\n\n        if KSState.Layout == "WASD" then',
     '\n        if KSState.Layout == "WASD" then'),
    ("posicao ignora o canto escolhido",
     '        if KSState.Anchor == "TopLeft" then',
     '        if false then'),
    ("posicao trava no canto inferior esquerdo",
     '            root.AnchorPoint = Vector2.new(1, 1)\n            root.Position = UDim2.new(1, -m, 1, -m)',
     '            root.AnchorPoint = Vector2.new(0, 1)\n            root.Position = UDim2.new(0, m, 1, -m)'),
    ("tamanho nao escala",
     '            Keystrokes.Scale.Scale = KSState.Scale * FitToViewport()',
     '            Keystrokes.Scale.Scale = 1'),
    ("escala nao se adapta a tela estreita",
     '        return math.clamp(available / KS_BASE_W, 0.65, 1)',
     '        return 1'),
    ("lock nao trava o arrasto",
     '        if not dragStart or KSState.LockPos then return end',
     '        if not dragStart then return end'),
    ("cor da tecla nao aplica",
     '                if not d.Active then d.Frame.BackgroundColor3 = c end',
     '                if false then d.Frame.BackgroundColor3 = c end'),
    ("cor do mouse nao aplica",
     '            if M.Body then M.Body.BackgroundColor3 = c end',
     '            if false then M.Body.BackgroundColor3 = c end'),
    ("toggle desligado continua acendendo",
     '        if not KSState.Enabled then return end\n        local t = input.UserInputType\n\n        if t == Enum.UserInputType.Keyboard then\n            PlayKeySound()',
     '        local t = input.UserInputType\n\n        if t == Enum.UserInputType.Keyboard then\n            PlayKeySound()'),
    ("toggle desligado nao esconde o painel",
     '            KSState.Enabled = v\n            gui.Enabled = v',
     '            KSState.Enabled = v'),
    # --- HUD: overlays ---
    ("fps fica no placeholder",
     '            fps = math.floor(frames / elapsed + 0.5)',
     '            fps = fps'),
    ("fps nao reseta a janela",
     '            frames, elapsed = 0, 0',
     '            frames = 0'),
    ("overlay ignora o toggle de FPS",
     '        if OVState.ShowFPS and OVState.ShowPing then',
     '        if true then'),
    ("overlay ignora a cor do fundo",
     '        p.BackgroundColor3 = OVState.BgColor',
     '        p.BackgroundColor3 = Color3.fromRGB(0, 0, 0)'),
    ("overlay ignora a transparencia do fundo",
     '        p.BackgroundTransparency = OVState.BgTransparency',
     '        p.BackgroundTransparency = 0.5'),
    ("overlay ignora a cor do texto",
     '        Overlays.Label.TextColor3 = OVState.TextColor',
     '        Overlays.Label.TextColor3 = Color3.new(1, 1, 1)'),
    ("overlay ignora o tamanho do texto",
     '        Overlays.Label.TextSize = OVState.TextSize',
     '        Overlays.Label.TextSize = 18'),
    ("lock do overlay nao trava",
     '        if not dragStart or OVState.LockPos then return end',
     '        if not dragStart then return end'),
    # --- HUD: botoes ---
    ("lock de posicao nao trava o arrasto",
     '            -- Posicao travada: o botao continua clicavel, so nao sai do lugar.\n            if QuickState.LockPos then return end',
     '            if false then return end'),
    # --- HUD: camadas e defaults ---
    ("keystrokes volta a nascer ligada",
     '    local KSState = {\n        Enabled = false,',
     '    local KSState = {\n        Enabled = true,'),
    ("keystrokes volta na frente do menu",
     '    gui.DisplayOrder = -1',
     '    gui.DisplayOrder = 999998'),
    ("overlays voltam na frente do menu",
     '    gui.DisplayOrder = -2',
     '    gui.DisplayOrder = 999997'),
    ("botoes voltam na frente do menu",
     '        gui.DisplayOrder = -3',
     '        gui.DisplayOrder = 9999'),
    ("borda do mouse volta a ser fixa",
     '            Color = KSState.MouseBorderColor,\n            Thickness = 1,\n            Transparency = 0.1,',
     '            Color = Color3.fromRGB(255, 100, 210),\n            Thickness = 1,\n            Transparency = 0.1,'),
    ("borda do mouse ignora o picker",
     '            if M.BorderStroke then M.BorderStroke.Color = c end',
     '            if false then end'),
    ("no recoil nao zera o recuo",
     '   if getgenv().Weapon_NoRecoil and WMatch(name, W_PAT.Recoil) then return 0 end',
     '   if getgenv().Weapon_NoRecoil and WMatch(name, W_PAT.Recoil) then return 1 end'),
    ("bala espalha nao zera o spread",
     '   if getgenv().Weapon_NoSpread and WMatch(name, W_PAT.Spread) then return 0 end',
     '   if getgenv().Weapon_NoSpread and WMatch(name, W_PAT.Spread) then return 1 end'),
    ("municao infinita nao escreve o valor",
     '   if getgenv().Weapon_InfiniteAmmo and WMatch(name, W_PAT.Ammo) then return W_AMMO_VALUE end',
     '   if getgenv().Weapon_InfiniteAmmo and WMatch(name, W_PAT.Ammo) then return nil end'),
    ("clip infinito mexe na municao",
     '   if getgenv().Weapon_InfiniteClip and WMatch(name, W_PAT.Clip) then return W_AMMO_VALUE end',
     '   if getgenv().Weapon_InfiniteClip and WMatch(name, W_PAT.Ammo) then return W_AMMO_VALUE end'),
    ("fastfire nao zera a cadencia",
     '   if getgenv().Weapon_FastFire and WMatch(name, W_PAT.Rate) then\n      return getgenv().Weapon_FireDelay\n   end',
     '   if getgenv().Weapon_FastFire and WMatch(name, W_PAT.Rate) then return nil end'),
    ("desligar nao restaura o original",
     '      WRunning = false\n      WRestoreAll()',
     '      WRunning = false'),
    ("fastfire nao aciona a arma",
     '         if gun then pcall(function() gun:Activate() end) end',
     '         if gun then end'),
    ("atributos das armas sao ignorados",
     '      local ok, attrs = pcall(function() return tool:GetAttributes() end)',
     '      local ok, attrs = pcall(function() return nil end)'),
]

def run():
    outs = []
    tests_dir = ROOT / 'tests'
    for driver in ['esp_test.lua', 'dropdown_test.lua', 'api_compat_test.lua',
                   'hud_test.lua', 'weapons_test.lua']:
        if not (tests_dir / driver).exists():
            continue
        subprocess.run(['python3', str(tests_dir / 'harness.py'),
                        str(tests_dir / driver)], capture_output=True, text=True)
        r2 = subprocess.run(['/tmp/luaubin/luau', '/tmp/setup.lua'],
                            capture_output=True, text=True, timeout=180)
        o = r2.stdout + r2.stderr
        if r2.returncode != 0 or 'FALHOU' in o:
            return False, o
        outs.append(o)
    return True, ''.join(outs)

shutil.copy(SRC, BAK)
orig = BAK.read_text()

base_ok, base_out = run()
print(f"baseline: {'OK' if base_ok else 'FALHOU'}")
if not base_ok:
    print(base_out[-1500:]); sys.exit(1)

detected = 0
survived = []
for name, old, new in MUTS:
    if old not in orig:
        print(f"  [SKIP] {name} (ancora nao encontrada)")
        survived.append(name + " (ancora)")
        continue
    SRC.write_text(orig.replace(old, new, 1))
    ok, out = run()
    if ok:
        print(f"  [SOBREVIVEU] {name}")
        survived.append(name)
    else:
        detected += 1
        print(f"  [detectado] {name}")

SRC.write_text(orig)
BAK.unlink(missing_ok=True)
print(f"\n{detected}/{len(MUTS)} mutacoes detectadas")
if survived:
    print("SOBREVIVENTES:")
    for s in survived: print("  -", s)
