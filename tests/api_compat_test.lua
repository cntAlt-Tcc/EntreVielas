-- Compatibilidade Script/A <-> lib. A API antiga (Compkiller) tinha nomes que
-- a lib atual nao implementa; uma chave desconhecida e descartada em silencio
-- por __CONFIG, entao o sintoma e "o controle aparece mas nao faz nada".
local FS = __FIVESYNC
local R = {}

-- 1. Todo metodo FiveSync: usado no Script/A existe na lib. A lista vem do
-- fonte (__API_METHODS), nao de uma constante: renomear uma chamada para um
-- nome que a lib nao tem precisa reprovar.
__ok("api: metodos extraidos do Script/A", #__API_METHODS > 0, #__API_METHODS)
for _, n in ipairs(__API_METHODS) do
    __ok("api: FiveSync." .. n, type(FS[n]) == "function", type(FS[n]))
end

-- 2. Elementos usados precisam existir como metodo em Args.
local types = __ELEMENT_TYPES or {}
__ok("api: elementos extraidos do Script/A", #__API_ELEMENTS > 0, #__API_ELEMENTS)
for _, n in ipairs(__API_ELEMENTS) do
    __ok("api: Args." .. n, types[n] == true)
end

-- 2b. Metodos Draw* (janela/aba) precisam existir na lib.
local draws = __DRAW_TYPES or {}
__ok("api: Draw* extraidos do Script/A", #__API_DRAWS > 0, #__API_DRAWS)
for _, n in ipairs(__API_DRAWS) do
    __ok("api: " .. n, draws[n] == true)
end

-- 2c. Todo campo passado a um elemento precisa ser lido pela lib. A lib so
-- le `Config.<campo>`; __CONFIG descarta o resto sem erro, entao um campo
-- herdado da API antiga (Description no toggle) vira texto morto.
local known = {}
for _, f in ipairs(__LIB_CONFIG_FIELDS) do known[f] = true end
local dead = {}
for _, pair in ipairs(__ELEMENT_FIELDS) do
    local el, field = pair[1], pair[2]
    if not known[field] then dead[#dead + 1] = el .. "." .. field end
end
__ok("api: nenhum campo morto nos elementos", #dead == 0, table.concat(dead, ", "))
__ok("api: campos extraidos", #__ELEMENT_FIELDS > 50, #__ELEMENT_FIELDS)

-- 3. Tema: todo valor do dropdown precisa de um ramo em SetTheme, senao
-- SetTheme cai no default e o usuario ve o tema nao mudar.
local themes = {}
for _, d in ipairs(__DROPDOWN_LOG or {}) do
    if d.Flag == "ConfigTheme" or d.Name == "Select Theme" then
        for _, v in ipairs(d.Values or {}) do themes[#themes+1] = v end
    end
end
__ok("theme: dropdown encontrado", #themes > 0, #themes)
for _, t in ipairs(themes) do
    local ok = pcall(function() FS:SetTheme(t) end)
    __ok("theme: SetTheme('" .. t .. "')", ok)
end

-- 4. AddTextBox le Config.Numeric mas registra o default como "Numberic".
-- Se algum dia o typo virar default real, Numeric=true deixaria de filtrar.
-- Exercita o filtro real: Numeric=true precisa remover letras e devolver
-- numero; Numeric=false precisa devolver o texto intacto.
__ok("textbox: Numeric=true filtra letras", __LIB_PARSE("abc12.5x", true) == 12.5,
     __LIB_PARSE("abc12.5x", true))
__ok("textbox: Numeric=true sem digito devolve nil", __LIB_PARSE("abc", true) == nil,
     __LIB_PARSE("abc", true))
__ok("textbox: sem a grafia errada Numberic", __LIB_HAS_TYPO_KEY == false)
__ok("textbox: lib le Config.Numeric", __LIB_HAS_NUMERIC == true)
__ok("textbox: Numeric=false preserva texto", __LIB_PARSE("abc12.5x", false) == "abc12.5x",
     __LIB_PARSE("abc12.5x", false))
