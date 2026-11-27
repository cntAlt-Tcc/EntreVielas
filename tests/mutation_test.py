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
]

def run():
    outs = []
    tests_dir = ROOT / 'tests'
    for driver in ['esp_test.lua', 'dropdown_test.lua', 'api_compat_test.lua']:
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
