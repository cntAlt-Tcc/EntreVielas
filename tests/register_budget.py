#!/usr/bin/env python3
"""Checa o orcamento de locais por funcao (limite do Roblox/Luau: 200).

Estourar esse limite nao aparece no `luau-compile` local, que aceita mais. So
aparece em execucao, no Roblox:

    Out of local registers when trying to allocate ApplyVolume: exceeded limit 200

O limite vale por funcao e conta quantos `local` estao em escopo ao mesmo
tempo. Um bloco `do ... end` devolve seus locais no `end`, mas enquanto esta
aberto eles dividem o orcamento da funcao que o contem. Foi assim que o bloco
do Keystrokes estourou: dezenas de locais vivos junto com os do chunk.

Envolver o bloco em `(function() ... end)()` da a ele uma funcao propria, com
orcamento zerado, que e o que resolve.

A contagem usa a AST real (`luau-ast`), nao heuristica de texto.
"""

import json
import subprocess
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
LIMIT = 200
LUAU_AST = Path('/tmp/luaubin/luau-ast')


def parse(path):
    result = subprocess.run([str(LUAU_AST), str(path)], capture_output=True, text=True)
    if result.returncode != 0:
        raise RuntimeError(result.stderr.strip() or 'falha ao gerar AST')
    return json.loads(result.stdout)['root']


class Budget:
    """Conta locais em escopo, por funcao."""

    def __init__(self):
        self.scopes = [0]      # locais declarados em cada escopo aberto
        self.fn_start = 0      # indice do escopo mais externo da funcao atual
        self.fn_stack = []
        self.peak = {'value': 0, 'at': None}

    def declare(self, count, location):
        self.scopes[-1] += count
        current = sum(self.scopes[self.fn_start:])
        if current > self.peak['value']:
            self.peak = {'value': current, 'at': location}

    def enter_block(self):
        self.scopes.append(0)

    def leave_block(self):
        if len(self.scopes) > 1:
            self.scopes.pop()

    def enter_function(self):
        self.fn_stack.append(self.fn_start)
        self.scopes.append(0)
        self.fn_start = len(self.scopes) - 1

    def leave_function(self):
        self.scopes.pop()
        self.fn_start = self.fn_stack.pop()


DECLARATIONS = {
    'AstStatLocal': lambda node: len(node.get('vars') or []),
    'AstStatLocalFunction': lambda node: 1,
}

# A variavel de um `for` vive so no corpo do loop: entra e sai com ele.
LOOP_DECLARATIONS = {
    'AstStatFor': lambda node: 1,
    'AstStatForIn': lambda node: len(node.get('vars') or []),
}


def walk(node, budget):
    if isinstance(node, list):
        for item in node:
            walk(item, budget)
        return
    if not isinstance(node, dict):
        return

    kind = node.get('type')
    location = node.get('location', '')

    if kind == 'AstExprFunction':
        budget.enter_function()
        params = len(node.get('args') or []) + (1 if node.get('vararg') else 0)
        budget.declare(params, location)
        walk(node.get('body'), budget)
        budget.leave_function()
        return

    if kind in LOOP_DECLARATIONS:
        budget.enter_block()
        budget.declare(LOOP_DECLARATIONS[kind](node), location)
        for key in ('from', 'to', 'step', 'iter', 'exprs'):
            if key in node:
                walk(node[key], budget)
        walk(node.get('body'), budget)
        budget.leave_block()
        return

    if kind in DECLARATIONS:
        budget.declare(DECLARATIONS[kind](node), location)

    if kind == 'AstStatBlock':
        budget.enter_block()
        walk(node.get('body'), budget)
        budget.leave_block()
        return

    for value in node.values():
        if isinstance(value, (dict, list)):
            walk(value, budget)


def scan(path):
    budget = Budget()
    walk(parse(path), budget)
    return budget.peak['value'], budget.peak['at']


def main():
    targets = sys.argv[1:] or ['Script/A', 'inject.lua']
    failures = 0

    for rel in targets:
        path = ROOT / rel
        if not path.exists():
            print(f"  [pulado] {rel} nao existe")
            continue
        try:
            peak, location = scan(path)
        except RuntimeError as error:
            print(f"  [ERRO] {rel}: {error}")
            failures += 1
            continue

        status = 'OK  ' if peak < LIMIT else 'ESTOURA'
        print(f"  [{status}] {rel}: pico {peak}/{LIMIT} locais em escopo, em {location}")
        if peak >= LIMIT:
            failures += 1

    if failures:
        print(f"\n{failures} arquivo(s) acima de {LIMIT} locais em escopo.")
        print("Envolva o bloco em (function() ... end)() para abrir orcamento novo.")
        return 1
    return 0


if __name__ == '__main__':
    sys.exit(main())
