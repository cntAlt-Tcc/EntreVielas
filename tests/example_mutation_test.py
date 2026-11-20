#!/usr/bin/env python3
"""Mutation testing do example.lua: cada bug injetado DEVE fazer o teste falhar.

O example.lua e o script de exemplo herdado da lib antiga. Ele compilar nao
prova nada: um campo que a lib nao le (ou uma cor que nao existe) deixa o
controle na tela sem efeito. Este teste injeta esses defeitos e exige que
example_script_test.lua acuse cada um.
"""
import os
import pathlib
import shutil
import subprocess
import sys

ROOT = pathlib.Path(__file__).resolve().parent.parent
EXAMPLE = ROOT / 'example.lua'
DRIVER = ROOT / 'tests' / 'example_script_test.lua'
LUAU = '/tmp/luaubin/luau'

MUTS = [
    ("campo morto Description volta no toggle",
     '\tFlag = "Toggle_Example", -- Leave it blank will not save to config',
     '\tDescription = "x",\n\tFlag = "Toggle_Example", -- Leave it blank will not save to config'),
    ("campo morto Color volta no slider",
     '\tFlag = "Slider_Example",',
     '\tColor = 5,\n\tFlag = "Slider_Example",'),
    ("cor inexistente volta no colorpicker",
     'Default = FiveSync.Colors.Risky,',
     'Default = FiveSync.Colors.RiskyOld,'),
]


def run():
    env = {**os.environ, 'MOCK_SCRIPT': 'example.lua'}
    subprocess.run(['python3', str(ROOT / 'tests' / 'harness.py'), str(DRIVER)],
                   capture_output=True, text=True, env=env)
    r = subprocess.run([LUAU, '/tmp/setup.lua'],
                       capture_output=True, text=True, timeout=180)
    out = r.stdout + r.stderr
    return r.returncode == 0 and 'FALHOU' not in out, out


orig = EXAMPLE.read_text()
bak = ROOT / 'tests' / '.example.bak'
shutil.copy(EXAMPLE, bak)

try:
    ok, out = run()
    print(f"baseline: {'OK' if ok else 'FALHOU'}")
    if not ok:
        print(out[-1500:])
        sys.exit(1)

    detected = 0
    survived = []
    for name, old, new in MUTS:
        if old not in orig:
            print(f"  [SKIP] {name} (ancora nao encontrada)")
            survived.append(name + " (ancora)")
            continue
        EXAMPLE.write_text(orig.replace(old, new, 1))
        ok, _ = run()
        if ok:
            print(f"  [SOBREVIVEU] {name}")
            survived.append(name)
        else:
            detected += 1
            print(f"  [detectado] {name}")
finally:
    EXAMPLE.write_text(orig)
    bak.unlink(missing_ok=True)

print(f"\n{detected}/{len(MUTS)} mutacoes detectadas")
if survived:
    print("SOBREVIVENTES:")
    for s in survived:
        print("  -", s)
    sys.exit(1)
