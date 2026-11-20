-- Configs no disco que a lib nao gravou: um arquivo truncado, um da lib antiga
-- sem __INFORMATION e um normal. Todos tem que aparecer na lista e nenhum pode
-- derrubar o script -- era isso que acontecia antes: ReadInfo decodificava sem
-- pcall e o Refresh indexava Info nil, entao um unico arquivo ruim apagava a
-- lista inteira.
__PRE_SEED = {
    ["Vsync/Vsync-Configs/Novo"] =
        '{"__INFORMATION":{"Type":"Information","Author":"Team EntreViela$","Name":"Novo"}}',
    ["Vsync/Vsync-Configs/Antigo"] =
        '{"SecChams_Ativar":{"Flag":"SecChams_Ativar","Value":{"Type":"NormalElement","Value":true}}}',
    ["Vsync/Vsync-Configs/Truncado"] = "lixo invalido",
    -- JSON valido que nao e objeto: decodifica sem erro, mas indexar .__INFORMATION
    -- num numero estoura do mesmo jeito.
    ["Vsync/Vsync-Configs/Numero"] = "123",
    -- Entrada com Flag mas sem Value: ApplyConfig indexava v.Value.Type e abortava.
    ["Vsync/Vsync-Configs/SemValue"] =
        '{"__INFORMATION":{"Author":"x","Name":"SemValue"},"SecChams_Ativar":{"Flag":"SecChams_Ativar"}}',
}

local S = __M.Save
local CM, FS, L = S.ConfigManager, S.__FS or S.FS, S.Lib
local dir = "Vsync/Vsync-Configs"

__ok("robust: script carregou", __M.__err == nil, __M.__err)
__ok("robust: corrotina terminou", coroutine.status(__M.__mainCo) == "dead")

-- ReadInfo nao pode estourar em nenhum dos tres.
for _, name in ipairs({ "Novo", "Antigo", "Truncado" }) do
    local ok, info = pcall(function() return CM:ReadInfo(name) end)
    __ok("robust: ReadInfo(" .. name .. ") nao estoura", ok, tostring(info))
end
__ok("robust: ReadInfo(Novo) devolve tabela", type(CM:ReadInfo("Novo")) == "table")
__ok("robust: ReadInfo(Antigo) sem __INFORMATION vira nil", CM:ReadInfo("Antigo") == nil)
__ok("robust: ReadInfo(Truncado) vira nil", CM:ReadInfo("Truncado") == nil)
__ok("robust: ReadInfo(Numero) vira nil", CM:ReadInfo("Numero") == nil)
__ok("robust: ReadInfo(SemValue) devolve tabela", type(CM:ReadInfo("SemValue")) == "table")

-- A lista tem que conter todos.
local names = CM:GetConfigs()
__ok("robust: GetConfigs conta todos", #names == 5, table.concat(names, ","))
for _, name in ipairs({ "Novo", "Antigo", "Truncado", "Numero", "SemValue" }) do
    __ok("robust: GetConfigs inclui " .. name, table.find(names, name) ~= nil,
         table.concat(names, ","))
end

-- E a UI desenhou uma linha para cada.
local function findAll(cls)
    local found = {}
    local function walk(o, d)
        if not o or d > 60 then return end
        for _, c in pairs(o:GetChildren() or {}) do
            if c.ClassName == cls then found[#found + 1] = c end
            walk(c, d + 1)
        end
    end
    for _, s in pairs(__M.Instances) do walk(s, 0) end
    return found
end

local drawn = {}
for _, lbl in ipairs(findAll("TextLabel")) do
    local t = lbl.Text or ""
    if t == "Novo" or t == "Antigo" or t == "Truncado" then drawn[t] = true end
end
__ok("robust: linha desenhada para Novo", drawn["Novo"] == true)
__ok("robust: linha desenhada para Antigo", drawn["Antigo"] == true)
__ok("robust: linha desenhada para Truncado", drawn["Truncado"] == true)

-- Load num config corrompido tem que falhar limpo, sem matar o script.
local ok, ret = pcall(function() return CM:LoadConfig("Truncado") end)
__ok("robust: LoadConfig(Truncado) nao estoura", ok, tostring(ret))
__ok("robust: LoadConfig(Truncado) devolve false", ret == false, tostring(ret))

-- Load num config legado tambem: aplica o que der, sem abortar.
local ok2, ret2 = pcall(function() return CM:LoadConfig("Antigo") end)
__ok("robust: LoadConfig(Antigo) nao estoura", ok2, tostring(ret2))

-- Entrada sem Value: ApplyConfig tem que pular a entrada, nao abortar. O warn
-- de "aplicado parcialmente" e o sinal: se aparecer, o load parou no meio.
local warnBefore = __M.__warnings and #__M.__warnings or 0
local ok3, ret3 = pcall(function() return CM:LoadConfig("SemValue") end)
__ok("robust: LoadConfig(SemValue) nao estoura", ok3, tostring(ret3))
local warnAfter = __M.__warnings and #__M.__warnings or 0
__ok("robust: LoadConfig(SemValue) aplica inteiro, sem warn", warnAfter == warnBefore,
     tostring(__M.__warnings and __M.__warnings[warnAfter]))

-- Os botoes da linha (Load e Save) tambem tem que aguentar config legado:
-- o OnSave indexava v.Info.Author e estourava ao salvar por cima de um config
-- sem __INFORMATION.
local function rowFor(name)
    for _, o in ipairs(findAll("Frame")) do
        for _, c in ipairs(o:GetChildren() or {}) do
            if c.ClassName == "TextLabel" and c.Text == name then return o end
        end
    end
end

local row = rowFor("Antigo")
__ok("robust: linha do config legado encontrada", row ~= nil)

if row then
    local linkValues
    for _, c in ipairs(row:GetChildren()) do
        if c.ClassName == "Frame" then linkValues = c end
    end

    local buttons = {}
    for _, c in ipairs(linkValues:GetChildren()) do
        if c.ClassName == "Frame" then
            for _, b in ipairs(c:GetChildren()) do
                if b.ClassName == "TextButton" then buttons[#buttons + 1] = b end
            end
        end
    end
    __ok("robust: botoes Load e Save na linha", #buttons == 2, tostring(#buttons))

    for i, b in ipairs(buttons) do
        __M.__fire(b, "MouseButton1Click")
        __M.__drain()
        __ok("robust: clique " .. i .. " nao mata o script", __M.__err == nil, tostring(__M.__err))
    end

    -- Salvar por cima de um config legado migra o arquivo: ganha __INFORMATION.
    local raw = FS.files[dir .. "/Antigo"]
    __ok("robust: Save em config legado preserva o arquivo", raw ~= nil)
    __ok("robust: Save em config legado cria __INFORMATION",
         raw ~= nil and raw:find("__INFORMATION") ~= nil, tostring(raw and raw:sub(1, 60)))
end

-- E o script continua vivo depois de tudo isso.
__ok("robust: script segue vivo", __M.__err == nil, __M.__err)
