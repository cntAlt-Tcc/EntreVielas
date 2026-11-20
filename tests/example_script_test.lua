-- Exercita example.lua (o script de exemplo que veio da lib antiga) contra a
-- lib real, rodando com MOCK_SCRIPT=example.lua. O port so compilar nao prova
-- nada: a lib descarta chave desconhecida em silencio, entao um elemento
-- herdado da API antiga aparece na tela e nao faz nada. Aqui cada tipo de
-- elemento e instanciado e o valor e lido de volta pela API nova.
local FS = __FIVESYNC

-- Sem MOCK_SCRIPT o harness roda o Script/A e este teste passaria verificando
-- outro consumidor -- verde falso. Exige o alvo certo.
__ok("example: rodando contra example.lua", __SCRIPT_NAME == "example.lua", __SCRIPT_NAME)
__ok("example: lib carregou", type(FS) == "table")
__ok("example: script rodou ate o fim", coroutine.status(__M.__mainCo) == "dead",
     coroutine.status(__M.__mainCo))

-- 1. Dropdowns instrumentados: o example monta 5 (single, multi e o de tema).
__ok("example: dropdowns registrados", #(__DROPDOWN_LOG or {}) >= 5, #(__DROPDOWN_LOG or {}))

-- 2. Nenhum campo morto. A lib so le `Config.<campo>`; __CONFIG descarta o
--    resto sem erro, entao um campo herdado da API antiga (Description no
--    toggle, Color no slider) vira texto inerte e o controle nao faz nada.
--    Os dois lados vem de fontes diferentes: os campos do example, os campos
--    lidos pela lib. Comparar os dois pega essa classe de bug.
local known = {}
for _, f in ipairs(__LIB_CONFIG_FIELDS or {}) do known[f] = true end
local dead = {}
for _, pair in ipairs(__ELEMENT_FIELDS or {}) do
    if not known[pair[2]] then dead[#dead + 1] = pair[1] .. "." .. pair[2] end
end
__ok("example: campos do example extraidos", #(__ELEMENT_FIELDS or {}) > 50,
     #(__ELEMENT_FIELDS or {}))
__ok("example: nenhum campo morto nos elementos", #dead == 0, table.concat(dead, ", "))

__ok("example: registry de flags existe", type(FS.Flags) == "table")

-- 3. O dropdown multi precisa guardar tabela, nao string.
for _, d in ipairs(__DROPDOWN_LOG or {}) do
    if d.Name == "Multi Dropdown" then
        __ok("example: multi dropdown marcado Multi", d.Multi == true, d.Multi)
        __ok("example: multi default e tabela", type(d.Default) == "table", type(d.Default))
    end
    if d.Name == "Single Dropdown" then
        __ok("example: single dropdown nao e Multi", d.Multi ~= true, d.Multi)
        __ok("example: single default e string", type(d.Default) == "string", type(d.Default))
    end
end

-- 4. Tema: o example monta o dropdown de temas a partir de SetTheme; todo valor
--    precisa ter ramo, senao o usuario escolhe e nada muda.
local themeValues
for _, d in ipairs(__DROPDOWN_LOG or {}) do
    if d.Name == "Select Theme" then themeValues = d.Values end
end
__ok("example: dropdown de tema existe", themeValues ~= nil)
for _, t in ipairs(themeValues or {}) do
    local ok, err = pcall(function() FS:SetTheme(t) end)
    __ok("example: SetTheme('" .. t .. "')", ok, err)
end

-- 5. Cores: o painel de Settings escreve em FiveSync.Colors.<campo> e chama
--    RefreshCurrentColor. A lista vem do fonte do example; nome que a lib nao
--    define chega nil no ColorPicker sem erro nenhum.
--    O mock representa Color3 como tabela com R/G/B, entao checa a forma.
__ok("example: cores extraidas do example", #(__API_COLORS or {}) > 0, #(__API_COLORS or {}))
for _, c in ipairs(__API_COLORS or {}) do
    local col = FS.Colors[c]
    __ok("example: Colors." .. c,
         type(col) == "table" and tonumber(col.R) and tonumber(col.G) and tonumber(col.B),
         type(col))
end
__ok("example: RefreshCurrentColor responde",
     pcall(function() FS:RefreshCurrentColor(FS.Colors.Highlight) end))

-- 6. GetTheme precisa devolver algo serializavel; o botao "Get Theme" imprime
--    o retorno direto.
local okTheme, theme = pcall(function() return FS:GetTheme() end)
__ok("example: GetTheme funciona", okTheme, theme)
__ok("example: GetTheme devolve tabela", type(theme) == "table", type(theme))

-- 7. Watermark e janela precisam existir para o cabecalho desenhar.
__ok("example: janela registrada", next(FS.Windows or {}) ~= nil)
