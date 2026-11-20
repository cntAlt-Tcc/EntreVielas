#!/usr/bin/env python3
"""Roda Script/A de ponta a ponta: mock + inject.lua + Script/A + driver opcional.

Top-level chunks rodam em corrotina e sao drenados, porque task.wait cede.
"""
import re, sys, pathlib, os, tempfile

ROOT = pathlib.Path(__file__).resolve().parent.parent
TESTS = ROOT / 'tests'
mock = (TESTS / 'roblox_mock.lua').read_text()
lib  = (ROOT / 'inject.lua').read_text()
# MOCK_SCRIPT permite exercitar outro consumidor da lib (ex.: example.lua) com
# o mesmo mock, em vez de so o Script/A. Sem isso, a API que os scripts de
# exemplo usam nunca e executada de verdade -- so compilada.
SCRIPT_NAME = os.environ.get('MOCK_SCRIPT', 'Script/A')
main = (ROOT / SCRIPT_NAME).read_text()

mock = mock.replace('return M\n', '').rstrip()
if mock.endswith('return M'):
    mock = mock[:-len('return M')]

_lb = lib.rstrip()
if _lb.endswith('return FiveSync;'):
    lib_body = _lb[:-len('return FiveSync;')]
elif _lb.endswith('return FiveSync'):
    lib_body = _lb[:-len('return FiveSync')]
else:
    lib_body = lib

main = re.sub(r'loadstring\(game:HttpGet\([^)]*\)\)\s*\(\)', '__LIB_LOADED()', main)

# Instrumenta AddDropdown para registrar Values/Default de cada instancia.
# Sem isso o registry de Flags nao expoe esses campos e a invariante
# "Default pertence a Values" nao pode ser checada.
import re as _re
_pat = _re.compile(r'(function Args:AddDropdown\(Config : Dropdown\)\s*\n)')
lib_body = _pat.sub(
    lambda m: m.group(1) +
        "__DROPDOWN_LOG = __DROPDOWN_LOG or {}\n"
        "table.insert(__DROPDOWN_LOG, { Flag = Config.Flag, Name = Config.Name,"
        " Default = Config.Default, Values = Config.Values, Multi = Config.Multi })\n",
    lib_body, count=1)

# Registra quais Add* a lib realmente define, para o teste de compatibilidade
# provar que a API usada pelo Script/A existe (e nao so compila).
lib_body = _re.sub(r'function Args:(Add[A-Za-z]+)\(',
                   lambda m: ("__ELEMENT_TYPES = __ELEMENT_TYPES or {}\n"
                              "__ELEMENT_TYPES[\"%s\"] = true\n" % m.group(1)
                              + "function Args:" + m.group(1) + "("),
                   lib_body)

lib_body = _re.sub(r'function (TabArgs|WindowArgs):(Draw[A-Za-z]+)\(',
                   lambda m: ("__DRAW_TYPES = __DRAW_TYPES or {}\n"
                              "__DRAW_TYPES[\"%s\"] = true\n" % m.group(2)
                              + "function " + m.group(1) + ":" + m.group(2) + "("),
                   lib_body)

if SCRIPT_NAME == 'Script/A':
    # Exporta so o que o script realmente define: citar um simbolo ausente
    # aqui quebra o harness inteiro com "attempt to index nil", escondendo o
    # resultado real dos testes.
    esp_syms = ['Config', 'ESP_Render', 'InitPlayerESP', 'ESP_UpdateLoop',
                'ESP_SetEnabled', 'ChamsGet', 'ChamsDestroy', 'ESP_HideAll',
                'DrawGlow', 'CollectGlowSegs', 'HideList', 'GlowSegs',
                'ChamsNeon', 'ESP_TeamColor', 'ESP_SafeColor', 'ESP_SafeAlpha',
                'ESP_Cache']
    present = [x for x in esp_syms
               if _re.search(r'(^|\n)(local\s+)?function\s+%s\s*\(|\b%s\s*=' % (x, x), main)]
    main += '\n__M.ESP = {\n' + ''.join(
        '    %s = %s,\n' % (x, x) for x in present) + '}\n'
    save_syms = ['ConfigManager', 'Config', '__FS']
    save_present = [x for x in save_syms
                    if _re.search(r'(^|\n)(local\s+)?function\s+%s\s*\(|\b%s\s*=' % (x, x), main)]
    main += '__M.Save = {\n' + ''.join(
        '    %s = %s,\n' % (x, x) for x in save_present) + '}\n'
    main += '__M.Lib = FiveSync\n'

driver = ''
if len(sys.argv) > 1:
    driver = pathlib.Path(sys.argv[1]).read_text()

# O driver pode declarar __PRE_SEED para criar arquivos antes do script rodar
# (a aba Save so desenha linhas para configs que ja existem no disco). O bloco
# e retirado do driver e injetado antes do load, senao rodaria tarde demais.
pre_seed_src = ''
_seed_at = driver.find('__PRE_SEED')
if _seed_at != -1:
    _brace = driver.find('{', _seed_at)
    _depth, _i = 0, _brace
    while _i < len(driver):
        if driver[_i] == '{':
            _depth += 1
        elif driver[_i] == '}':
            _depth -= 1
            if _depth == 0:
                break
        _i += 1
    _end = driver.find('\n', _i)
    pre_seed_src = '__PRE_SEED = ' + driver[_brace:_i + 1]
    driver = driver[:_seed_at] + driver[_end + 1:]

mode = os.environ.get('MOCK_MODE', 'Performance')
has_numeric = 'Config.Numeric' in lib_body
# Grafia errada e codigo morto: nada le Config.Numberic. Se voltar, o default
# do AddTextBox deixa de registrar a chave que o parse consulta.
has_typo_key = _re.search(r'\bNumberic\b', lib_body) is not None

# A lista de API tem que sair do Script/A, nao de uma constante no teste:
# com lista fixa, renomear uma chamada para um metodo que nao existe passa
# despercebido (o teste continua checando o nome antigo).
api_methods = sorted(set(_re.findall(r'FiveSync:([A-Za-z_][A-Za-z0-9_]*)\s*\(', main)))
api_elements = sorted(set(_re.findall(r':(Add[A-Za-z]+)\s*\(\s*\{', main)))
# Metodos de janela/aba (Draw*) chamados em qualquer objeto da lib: nao sao
# "FiveSync:" entao a varredura acima nao os ve, e um DrawConfig renomeado
# passava despercebido.
api_draws = sorted(set(_re.findall(r':(Draw[A-Za-z]+)\s*\(', main)))

# Cores que o script consumidor referencia (FiveSync.Colors.X). Um nome que a
# lib nao define vira nil e o ColorPicker recebe default invalido sem erro, entao
# a lista precisa sair do fonte do script, nao de uma constante no teste.
api_colors = sorted(set(_re.findall(r'(?:FiveSync|__FIVESYNC)\.Colors\.([A-Za-z_]\w*)', main)))

# Campos de nivel 1 que o Script/A passa a cada elemento. A lib so le um campo
# se aparecer como `Config.<campo>`; __CONFIG descarta o resto em silencio,
# entao um campo herdado da API antiga (ex.: Description no toggle) vira texto
# morto sem nenhum erro. Comparar os dois lados pega essa classe de bug.
def _top_level_keys(text, start):
    depth, keys, buf, quote = 0, [], '', None
    i = start
    while i < len(text):
        ch = text[i]
        if quote:
            if ch == quote and text[i - 1] != '\\':
                quote = None
            buf += ch
        elif ch in '"\'':
            quote = ch
            buf += ch
        elif ch == '{':
            depth += 1
            buf += ch
        elif ch == '}':
            depth -= 1
            if depth == 0:
                m = _re.match(r'\s*([A-Za-z_]\w*)\s*=', buf)
                if m:
                    keys.append(m.group(1))
                return keys
            buf += ch
        elif depth == 1 and ch == ',':
            m = _re.match(r'\s*([A-Za-z_]\w*)\s*=', buf)
            if m:
                keys.append(m.group(1))
            buf = ''
        elif depth >= 1:
            buf += ch
        i += 1
    return keys

element_fields = []
for _m in _re.finditer(r':(Add[A-Za-z]+)\s*\(\s*\{', main):
    for _k in _top_level_keys(main, _m.end() - 1):
        element_fields.append([_m.group(1), _k])

lib_config_fields = sorted(set(_re.findall(r'Config\.([A-Za-z_]\w*)', lib_body)))

# O filtro numerico do AddTextBox vive numa closure sobre Config; extrair o
# corpo real permite exercitar a filtragem sem depender do sinal de Text do
# mock (que nao dispara). Assim o teste valida o codigo da lib, nao uma copia.
_parse_m = _re.search(r'local parse = (function\(text\).*?)\n\n\t\tUpdate\(\);', lib_body, _re.S)
if not _parse_m or 'Config.Numeric' not in _parse_m.group(1):
    raise SystemExit('harness: nao achei o parse() do AddTextBox em inject.lua; '
                     'o teste de Numeric ficaria vazio')
lib_parse_src = _parse_m.group(1)

out = f'''
-- ===== harness =====
local __PASS, __FAIL = 0, 0
function __ok(name, cond, extra)
    if cond then __PASS = __PASS + 1
    else
        __FAIL = __FAIL + 1
        print("FALHOU: " .. tostring(name) .. (extra and (" | " .. tostring(extra)) or ""))
    end
end

__SCRIPT_NAME = {SCRIPT_NAME!r}
__LIB_HAS_NUMERIC = {str(has_numeric).lower()}
__LIB_HAS_TYPO_KEY = {str(has_typo_key).lower()}
__API_METHODS = {{{', '.join(repr(x) for x in api_methods)}}}
__API_ELEMENTS = {{{', '.join(repr(x) for x in api_elements)}}}
__API_DRAWS = {{{', '.join(repr(x) for x in api_draws)}}}
__API_COLORS = {{{', '.join(repr(x) for x in api_colors)}}}
__ELEMENT_FIELDS = {{{', '.join('{%r, %r}' % (a, b) for a, b in element_fields)}}}
__LIB_CONFIG_FIELDS = {{{', '.join(repr(x) for x in lib_config_fields)}}}
__LIB_PARSE = function(text, numeric)
    local Config = {{ Numeric = numeric }}
    local parse = {lib_parse_src}
    return parse(text)
end

-- ===== mock =====
{mock}

-- Pre-seed do filesystem: o driver pode pedir arquivos que precisam existir
-- ANTES do script rodar (ex.: configs para a aba Save desenhar suas linhas).
-- Deve vir depois do mock (FS existe) e antes de carregar o script.
{pre_seed_src}
if __PRE_SEED then
    for pth, data in pairs(__PRE_SEED) do
        local dir = pth:match("^(.*)/[^/]+$")
        if dir and not isfolder(dir) then makefolder(dir) end
        writefile(pth, data)
    end
end

-- ===== inject.lua =====
local function __LIB_LOADED()
local FiveSync
{lib_body}
__FIVESYNC = FiveSync
return FiveSync
end

-- ===== Script/A =====
local __main_co = coroutine.create(function()
{main}
end)

-- Auto-escolhe FULL no seletor, senao o script bloqueia esperando o clique.
-- Dispara o clique do seletor de modo: procura o sinal Activated registrado
-- e chama o primeiro (o botao FULL e o primeiro criado).
task.defer(function()
    task.wait(0.2)
    -- MOCK_MODE=Full|Performance escolhe qual botao do seletor clicar.
    -- Sem isso o driver sempre pega o primeiro (Performance) e o modo Full,
    -- que e o que o usuario normalmente usa, nunca seria exercitado.
    local want = "{mode}"
    local fired = 0
    for _, rec in pairs(__M.__signals) do
        if rec.name == "Activated" then
            -- O rotulo do botao fica em Name ("FULL"/"PERFORMANCE"); Text e "".
            local label = rec.owner and rec.owner.Name
            if label == string.upper(want) then
                fired = fired + 1
                __M.__fire(rec.owner, "Activated")
                break
            end
        end
    end
    __M.__modeFired = fired
end)

__M.__mainCo = __main_co
local __drive = {{ __main_co }}
if __M.__spawned then
    for _, co in ipairs(__M.__spawned) do table.insert(__drive, co) end
end

-- O driver roda depois deste drain, mas handlers de clique usam task.spawn.
-- __drain permite avancar essas corrotinas sob demanda.
__M.__drain = function(rounds)
    for _ = 1, (rounds or 50) do
        local alive = false
        for _, co in ipairs(__M.__spawned) do
            if coroutine.status(co) == "suspended" then
                alive = true
                local ok, err = coroutine.resume(co)
                if not ok then print("ERRO corrotina: " .. tostring(err)) end
            end
        end
        if not alive then break end
    end
end

-- Drena as corrotinas: cada resume avanca ate o proximo yield (task.wait).
local __rounds = 0
while __rounds < 400 do
    __rounds = __rounds + 1
    local alive = false
    local snapshot = {{}}
    for _, co in ipairs(__drive) do table.insert(snapshot, co) end
    for _, co in ipairs(snapshot) do
        if coroutine.status(co) == "suspended" then
            alive = true
            local ok, err = coroutine.resume(co)
            if not ok then print("ERRO corrotina: " .. tostring(err)) __M.__err = tostring(err) end
        end
    end
    if __M.__spawned then
        for _, co in ipairs(__M.__spawned) do
            local known = false
            for _, k in ipairs(__drive) do if k == co then known = true break end end
            if not known then table.insert(__drive, co) end
        end
    end
    if not alive then break end
end

-- ===== driver =====
{driver}

print(string.format("\\n%d passaram, %d falharam", __PASS, __FAIL))
if __FAIL > 0 then error("falhas: " .. __FAIL) end
'''

OUT = pathlib.Path(os.environ.get('SETUP_OUT', tempfile.gettempdir())) / 'setup.lua'
OUT.write_text(out)
print(f'{OUT} gerado: {len(out)} bytes')
