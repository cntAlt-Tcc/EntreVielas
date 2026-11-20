#!/usr/bin/env python3
"""Mutation testing das correcoes de config na lib.

Cada mutacao reintroduz um dos bugs reais que deixavam configs invisiveis.
config_robust_test.lua tem que falhar em todas.
"""
import subprocess, shutil, pathlib, sys

ROOT = pathlib.Path(__file__).resolve().parent.parent
LIB = ROOT / 'inject.lua'
BAK = ROOT / 'tests' / '.inject.bak'
TEST = 'tests/config_robust_test.lua'

MUTS = [
    ("ReadInfo decodifica sem pcall (arquivo corrompido mata o script)",
     "\t\tlocal ok, decoded = pcall(function()\n"
     "\t\t\treturn HttpService:JSONDecode(readfile(_path));\n"
     "\t\tend);\n"
     "\n"
     "\t\tif not ok or type(decoded) ~= \"table\" then return nil; end;\n",
     "\t\tlocal decoded = HttpService:JSONDecode(readfile(_path));\n"),
    ("ReadInfo nao valida o tipo do decode",
     "\t\tif not ok or type(decoded) ~= \"table\" then return nil; end;\n",
     "\t\tif not ok then return nil; end;\n"),
    ("Refresh indexa Info nil (um config legado apaga a lista toda)",
     "\t\t\t\t\tlocal Info = (type(v.Info) == \"table\") and v.Info or {};\n"
     "\n"
     "\t\t\t\t\tButton:SetInfo(Info.Author or \"Desconhecido\",v.Name);\n",
     "\t\t\t\t\tButton:SetInfo(v.Info.Author,v.Name);\n"),
    ("LoadConfig decodifica sem pcall (Load em config corrompido mata o script)",
     "\t\tlocal ok, decoded = pcall(function()\n"
     "\t\t\treturn HttpService:JSONDecode(readfile(_path));\n"
     "\t\tend);\n"
     "\n"
     "\t\tif not ok or type(decoded) ~= \"table\" then\n"
     "\t\t\tif Args.EnableNotify then\n"
     "\t\t\t\tnotify.new({\n"
     "\t\t\t\t\tTitle = \"Configs\",\n"
     "\t\t\t\t\tIcon = FiveSync:_GetIcon('alert-triangle'),\n"
     "\t\t\t\t\tContent = \"Config \\\"\"..ConfigName..\"\\\" is corrupted\"\n"
     "\t\t\t\t})\n"
     "\t\t\tend\n"
     "\n"
     "\t\t\treturn false;\n"
     "\t\tend\n",
     "\t\tlocal decoded = HttpService:JSONDecode(readfile(_path));\n"),
    ("ApplyConfig indexa Value nil (config legado aborta o load)",
     "\t\t\t\t\tif v and v.Flag and type(v.Value) == \"table\" then\n",
     "\t\t\t\t\tif v and v.Flag then\n"),
    ("OnSave indexa Info nil (salvar por cima de config legado estoura)",
     "\t\t\t\t\t\tButton:SetInfo(Info.Author or \"Desconhecido\",v.Name);\n"
     "\n"
     "\t\t\t\t\t\tConfiguration.Config:WriteConfig({\n"
     "\t\t\t\t\t\t\tName = v.Name,\n"
     "\t\t\t\t\t\t\tAuthor = Info.Author or \"Desconhecido\";\n",
     "\t\t\t\t\t\tButton:SetInfo(v.Info.Author,v.Name);\n"
     "\n"
     "\t\t\t\t\t\tConfiguration.Config:WriteConfig({\n"
     "\t\t\t\t\t\t\tName = v.Name,\n"
     "\t\t\t\t\t\t\tAuthor = v.Info.Author;\n"),
    ("GetValue de keybind volta a indexar Default nil (salvar qualquer config quebra)",
     "\t\t\tlocal default = Config.Default;\n"
     "\n"
     "\t\t\tif typeof(default) == \"string\" then\n"
     "\t\t\t\treturn default;\n"
     "\t\t\tend;\n"
     "\n"
     "\t\t\treturn default and default.Name or nil;\n",
     "\t\t\treturn (typeof(Config.Default) == \"string\" and Config.Default) or Config.Default.Name;\n",
     2),
]


def run_test():
    subprocess.run([sys.executable, 'tests/harness.py', TEST],
                   cwd=ROOT, check=True, capture_output=True)
    out = subprocess.run(['/tmp/luaubin/luau', '/tmp/setup.lua'],
                         cwd=ROOT, capture_output=True, text=True).stdout
    falhas = [l for l in out.splitlines() if l.startswith('FALHOU')]
    return falhas, out


def main():
    src = LIB.read_text()
    shutil.copy(LIB, BAK)
    try:
        falhas, out = run_test()
        print(f"baseline: {len(falhas)} falhas (esperado 0)")
        if falhas:
            for f in falhas:
                print("  " + f)
            print("BASELINE SUJO -- abortando")
            return 1

        nao_detectadas = []
        for entrada in MUTS:
            nome, alvo, mutado = entrada[:3]
            # Alguns bugs viviam em mais de um ponto (os dois AddKeybind tem o
            # mesmo GetValue); nesses casos a mutacao precisa acertar todos.
            esperado = entrada[3] if len(entrada) > 3 else 1
            achados = src.count(alvo)
            if achados != esperado:
                print(f"SKIP (padrao aparece {achados}x, esperado {esperado}x): {nome}")
                nao_detectadas.append(nome)
                continue
            LIB.write_text(src.replace(alvo, mutado, esperado))
            falhas, out = run_test()
            crash = 'ERRO corrotina' in out or 'attempt to index nil' in out
            detectada = bool(falhas) or crash
            status = "DETECTADA" if detectada else "NAO DETECTADA"
            print(f"{status}: {nome}" + (f" ({len(falhas)} falhas)" if falhas else ""))
            if not detectada:
                nao_detectadas.append(nome)
            LIB.write_text(src)

        print()
        if nao_detectadas:
            print(f"FALHA: {len(nao_detectadas)} mutacao(oes) passaram batido")
            return 1
        print(f"OK: {len(MUTS)}/{len(MUTS)} mutacoes detectadas")
        return 0
    finally:
        shutil.copy(BAK, LIB)
        BAK.unlink(missing_ok=True)


if __name__ == '__main__':
    sys.exit(main())
