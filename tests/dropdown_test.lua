-- Invariantes de dropdown que quebram config round-trip:
--  (a) Default fora de Values -> chip vazio e GetValue devolve valor inexistente
--  (b) Default nil -> GetValue nil, o flag some do config salvo
-- Dropdowns internos da lib (keybind "Mode") nao tem Flag por design, entao a
-- checagem de Flag vale so para os do Script/A (identificados por ter Flag).
local log = __DROPDOWN_LOG or {}
local badDefault, badFlag, badNil = {}, {}, {}
for _, d in ipairs(log) do
    local found = false
    for _, v in ipairs(d.Values or {}) do
        if v == d.Default then found = true break end
    end
    if d.Multi and type(d.Default) == "table" then found = true end
    if not found then
        table.insert(badDefault, string.format("%s (Default=%s) fora de [%s]",
            tostring(d.Flag or d.Name), tostring(d.Default), table.concat(d.Values or {}, ",")))
    end
    if d.Flag and d.Default == nil then
        table.insert(badNil, tostring(d.Flag))
    end
end
__ok("dropdowns: Default sempre pertence a Values", #badDefault == 0, table.concat(badDefault, " | "))
__ok("dropdowns: nenhum Default nil com Flag", #badNil == 0, table.concat(badNil, " | "))
__ok("dropdowns: registrados", #log > 100, #log)

-- O dropdown de profundidade do Chams precisa casar com Enum.HighlightDepthMode
local chams
for _, d in ipairs(log) do if d.Flag == "SecChams_Profundidade" then chams = d end end
__ok("chams: dropdown existe", chams ~= nil)
__ok("chams: Default e um valor real do enum",
     chams and Enum.HighlightDepthMode[chams.Default] ~= nil, chams and chams.Default)
__ok("chams: todos os Values existem no enum", (function()
    if not chams then return false end
    for _, v in ipairs(chams.Values) do
        if Enum.HighlightDepthMode[v] == nil then return false end
    end
    return true
end)(), chams and table.concat(chams.Values, ","))
