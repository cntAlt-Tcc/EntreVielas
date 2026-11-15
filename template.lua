--[[
	FiveSync UI - Template

	Made by EntreViela$ Team

	Ponto de partida para montar o seu painel com a FiveSync UI.
	Cada bloco abaixo mostra um tipo de elemento e como ler/escrever o valor.
	Troque os "Callback" pelos seus próprios handlers.

	Tecla padrão para abrir / fechar: Left Alt
]]


local FiveSync = loadstring(game:HttpGet("https://raw.githubusercontent.com/cntAlt-Tcc/EntreVielas/main/inject.lua"))();


-- ==============================================================
-- Otimização mobile (opcional)
-- Em aparelhos de toque a lib já liga o modo de performance sozinha.
-- Os valores abaixo são os padrões; ajuste se quiser.
-- ==============================================================
if FiveSync:IsMobile() then
	FiveSync:OptimizeMode(true, {
		DisableBlur = true,
		DisableHover = true,
		DisableAnimations = true,
		DisableDragBlacklistListener = true,
		MainLoopDelay = 0.1,
		KeybindsDelay = 0.1,
		KeybindHandlerDelay = 0.05,
		BlurDelay = 0.5,
		ColorPickerDelay = 0.03,
		CloseButtonDelay = 0.5,
		ConfigRefreshDelay = 0.5,
	});
end;


-- ==============================================================
-- Estado da aplicação
-- Guarde aqui os valores que a UI controla. É a fonte da verdade
-- que os seus handlers consultam em tempo de execução.
-- ==============================================================
local State = {
	-- Geral
	Enabled = false,
	Mode = "Padrão",
	Intensity = 50,
	Tag = "",
	AccentColor = Color3.fromRGB(255, 255, 255),
	ExtraOptions = {
		ShowHud = false,
		ShowDebug = false,
	},

	-- Interface
	KeepPanelOpen = false,
	ToolbarKey = "E",

	-- Dados
	Endpoint = "https://exemplo.com/api",
};


-- ==============================================================
-- Notificações
-- ==============================================================
local Notifier = FiveSync.newNotify();


local function Notify(Title, Content, Duration)
	Notifier.new({
		Title = Title,
		Content = Content,
		Duration = Duration or 5,
		Icon = FiveSync.Logo,
	});
end;


-- ==============================================================
-- Gerenciador de configs (salva/carrega os elementos com Flag)
-- ==============================================================
local ConfigManager = FiveSync:ConfigManager({
	Directory = "FiveSync-UI",
	Config = "Template-Configs",
});


-- ==============================================================
-- Tela de carregamento + janela
-- ==============================================================
FiveSync:Loader(FiveSync.Logo, 2.5).yield();


local Window = FiveSync.new({
	Name = "FiveSync",
	Keybind = "LeftAlt",
	Logo = FiveSync.Logo,
	Scale = FiveSync.Scale.Window, -- deixe em branco para escala automática (PC / mobile)
	TextSize = 15,
});


-- ==============================================================
-- Watermark (canto da tela)
-- ==============================================================
local Watermark = Window:Watermark();

Watermark:AddText({ Icon = "user", Text = FiveSync:GetDate() });
Watermark:AddText({ Icon = "server", Text = FiveSync.Version });

local Clock = Watermark:AddText({ Icon = "timer", Text = FiveSync:GetTimeNow() });

task.spawn(function()
	while true do
		task.wait(1);
		Clock:SetText(FiveSync:GetTimeNow());
	end
end);


-- ==============================================================
-- Categoria + abas principais
-- ==============================================================
Window:DrawCategory({ Name = "Geral" });


local MainTab = Window:DrawTab({
	Name = "Painel",
	Icon = "layout-grid",
	EnableScrolling = true,
});


-- ==============================================================
-- Seção esquerda: controles básicos
-- ==============================================================
local Controls = MainTab:DrawSection({
	Name = "Controles",
	Position = "left",
});


Controls:AddToggle({
	Name = "Ativar recurso",
	Flag = "Enabled",
	Default = State.Enabled,
	Callback = function(v)
		State.Enabled = v;
		Notify("Recurso", v and "Ligado" or "Desligado");
	end,
});


Controls:AddDropdown({
	Name = "Modo",
	Flag = "Mode",
	Default = State.Mode,
	Values = { "Padrão", "Rápido", "Preciso" },
	Callback = function(v)
		State.Mode = v;
	end,
});


Controls:AddSlider({
	Name = "Intensidade",
	Flag = "Intensity",
	Min = 0,
	Max = 100,
	Default = State.Intensity,
	Round = 0,
	Callback = function(v)
		State.Intensity = v;
	end,
});


Controls:AddColorPicker({
	Name = "Cor de destaque",
	Flag = "AccentColor",
	Default = State.AccentColor,
	Callback = function(c)
		State.AccentColor = c;
	end,
});


Controls:AddTextBox({
	Name = "Tag",
	Flag = "Tag",
	Default = State.Tag,
	Placeholder = "Digite algo...",
	Callback = function(text)
		State.Tag = text;
	end,
});


-- Botão com ação pontual
Controls:AddButton({
	Name = "Aplicar agora",
	Callback = function()
		Notify("Aplicado", "Configuração aplicada.", 4);
	end,
});


-- Texto informativo dentro da seção
Controls:AddParagraph({
	Title = "Como usar",
	Content = "Os elementos com Flag são salvos no config.\nUse a aba Config para salvar e carregar.",
});


-- ==============================================================
-- Seção direita: toggle com keybind e opções extras
-- ==============================================================
local Extra = MainTab:DrawSection({
	Name = "Avançado",
	Position = "right",
});


local MasterToggle = Extra:AddToggle({
	Name = "Mestre",
	Flag = "Master",
	Default = false,
	Callback = function(v)
		State.Enabled = v;
	end,
});


-- Keybind ligada ao toggle (o callback roda quando a tecla é rebindada)
MasterToggle.Link:AddKeybind({
	Name = "Alternar mestre",
	Flag = "MasterKey",
	Default = "E",
	Callback = function(key)
		Notify("Atalho", "Tecla definida para " .. tostring(key));
	end,
});


MasterToggle.Link:AddHelper({
	Text = "Atalho rápido para o interruptor principal.",
});


-- Sub-opções aninhadas dentro do toggle
local Options = MasterToggle.Link:AddOption();

Options:AddToggle({
	Name = "Mostrar HUD",
	Flag = "ExtraOptions_ShowHud",
	Default = State.ExtraOptions.ShowHud,
	Callback = function(v)
		State.ExtraOptions.ShowHud = v;
	end,
});

Options:AddToggle({
	Name = "Mostrar debug",
	Flag = "ExtraOptions_ShowDebug",
	Default = State.ExtraOptions.ShowDebug,
	Risky = true,
	Callback = function(v)
		State.ExtraOptions.ShowDebug = v;
	end,
});


-- Keybind independente
Extra:AddKeybind({
	Name = "Tecla da barra",
	Flag = "ToolbarKey",
	Default = State.ToolbarKey,
	Callback = function(key)
		State.ToolbarKey = key;
		Notify("Tecla", "Barra vinculada a " .. tostring(key));
	end,
});


Extra:AddDropdown({
	Name = "Módulos",
	Flag = "Modules",
	Default = { "HUD" },
	Multi = true,
	Values = { "HUD", "Log", "Métricas", "Avisos" },
	Callback = function(selected)
		-- selected é uma tabela { [nome] = true }
		local list = {};
		for name in next, selected do
			table.insert(list, name);
		end
		State.Modules = list;
	end,
});


-- ==============================================================
-- Aba de dados (texto multilinha, etc.)
-- ==============================================================
local DataTab = Window:DrawTab({
	Name = "Dados",
	Icon = "database",
	Type = "Single",
	EnableScrolling = true,
});

local DataSection = DataTab:DrawSection({ Name = "Entrada" });

DataSection:AddTextBox({
	Name = "Endpoint",
	Flag = "Endpoint",
	Default = State.Endpoint,
	Placeholder = "https://...",
	Callback = function(text)
		State.Endpoint = text;
	end,
});

DataSection:AddParagraph({
	Title = "Observação",
	Content = "Use esta aba para entradas de texto longas ou dados de configuração.",
});


-- ==============================================================
-- Aba de interface (tema + cores)
-- ==============================================================
Window:DrawCategory({ Name = "Sistema" });

local SettingsTab = Window:DrawTab({
	Name = "Interface",
	Icon = "settings-3",
	Type = "Single",
	EnableScrolling = true,
});

local UISection = SettingsTab:DrawSection({ Name = "Janela" });

UISection:AddToggle({
	Name = "Manter abas visíveis",
	Default = false,
	Callback = function(v)
		Window.AlwayShowTab = v;
	end,
});

local ColorSection = SettingsTab:DrawSection({ Name = "Cores" });

-- Cada picker reescreve uma cor da paleta e repinta a UI na hora.
local ColorKeys = {
	{ "Highlight", "Destaque" },
	{ "Toggle", "Toggle" },
	{ "DropColor", "Dropdown" },
	{ "Risky", "Ação de risco" },
	{ "MouseEnter", "Hover" },
	{ "BlockColor", "Bloco" },
	{ "BlockBackground", "Fundo do bloco" },
	{ "BGDBColor", "Fundo" },
	{ "StrokeColor", "Contorno" },
	{ "HighStrokeColor", "Contorno destacado" },
	{ "SwitchColor", "Texto" },
	{ "LineColor", "Linha" },
};

for _, entry in next, ColorKeys do
	local key, label = entry[1], entry[2];

	ColorSection:AddColorPicker({
		Name = label,
		Default = FiveSync.Colors[key],
		Callback = function(c)
			FiveSync.Colors[key] = c;
			FiveSync:RefreshCurrentColor(c);
		end,
	});
end


ColorSection:AddButton({
	Name = "Copiar tema atual",
	Callback = function()
		print(FiveSync:GetTheme());
		Notify("Tema", "Tema atual copiado para o console.", 4);
	end,
});


-- ==============================================================
-- Aba de temas
-- ==============================================================
local ThemeTab = Window:DrawTab({
	Name = "Temas",
	Icon = "paintbrush",
	Type = "Single",
});

ThemeTab:DrawSection({ Name = "Paleta" }):AddDropdown({
	Name = "Tema",
	Default = "Default",
	Values = { "Default", "Dark Green", "Dark Blue", "Purple Rose", "Skeet" },
	Callback = function(name)
		FiveSync:SetTheme(name);
	end,
});


-- ==============================================================
-- Aba de configs
-- ==============================================================
local ConfigTab = Window:DrawConfig({
	Name = "Config",
	Icon = "folder",
	Config = ConfigManager,
});

ConfigTab:Init();


-- ==============================================================
-- Início
-- ==============================================================
Notify("FiveSync UI", "Template carregado com sucesso!", 6);
