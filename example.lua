--[[
	WARNING: Heads up! This script has not been verified by ScriptBlox. Use at your own risk!
]]
--[[
		FiveSync UI - Example

	Made by EntreViela$ Team

	Press Left Alt to open / close

	Otimização mobile: se o dispositivo for touch, a lib liga o modo de
	performance automaticamente. Caso contrário, segue normal.
]]


local FiveSync = loadstring(game:HttpGet("https://raw.githubusercontent.com/cntAlt-Tcc/EntreVielas/main/inject.lua"))();


-- Mobile Optimization --
-- Detecta mobile e liga o modo otimizado. Você pode ajustar o comportamento
-- passando uma config (opcional); os valores abaixo já são os padrões.
if FiveSync:IsMobile() then
	FiveSync:OptimizeMode(true , {
		DisableBlur = true,               -- desliga o acrylic/blur (mais pesado)
		DisableHover = true,              -- desliga efeitos de hover
		DisableAnimations = true,         -- aplica as propriedades sem tween
		DisableDragBlacklistListener = true, -- remove o listener global de input por elemento
		MainLoopDelay = 0.1,              -- intervalo do loop principal (maior = mais leve)
		KeybindsDelay = 0.1,
		KeybindHandlerDelay = 0.05,
		BlurDelay = 0.5,
		ColorPickerDelay = 0.03,
		CloseButtonDelay = 0.5,
		ConfigRefreshDelay = 0.5,
	});

	print("[FIVESYNC] Mobile detectado - modo otimizado ativado.");
else
	print("[FIVESYNC] Desktop detectado - modo normal.");
end;


-- Create Notification --
local Notifier = FiveSync.newNotify();


-- Create Config Mamager --
local ConfigManager = FiveSync:ConfigManager({
	Directory = "FiveSync-UI",
	Config = "Example-Configs"
});


-- Loading UI (Icon <string> , Duration <number>) --
FiveSync:Loader("rbxassetid://117056629401480" , 2.5).yield();


-- Creating Window --
local Window = FiveSync.new({
	Name = "FiveSync",
	Keybind = "LeftAlt",
	Logo = "rbxassetid://117056629401480",
	Scale = FiveSync.Scale.Window, -- Leave blank if you want automatic scale [PC, Mobile].
	TextSize = 15,
});


-- Notification --


Notifier.new({
	Title = "Notification",
	Content = "Thank you for use this script!",
	Duration = 10,
	Icon = "rbxassetid://117056629401480"
});


-- Watermark --
local Watermark = Window:Watermark();


Watermark:AddText({
	Icon = "user",
	Text = "4lpaca",
});


Watermark:AddText({
	Icon = "clock",
	Text = FiveSync:GetDate(),
});


local Time = Watermark:AddText({
	Icon = "timer",
	Text = "TIME",
});


task.spawn(function()
	while true do task.wait()
		Time:SetText(FiveSync:GetTimeNow());
	end
end)


Watermark:AddText({
	Icon = "server",
	Text = FiveSync.Version,
});


-- Creating Tab Category --
Window:DrawCategory({
	Name = "Example"
});


-- Creating Tab --
local NormalTab = Window:DrawTab({
	Name = "Example Tab",
	Icon = "apple",
	EnableScrolling = true
});


-- Creating Section --
local NormalSection = NormalTab:DrawSection({
	Name = "Section",
	Position = 'left'	
});


local Toggle = NormalSection:AddToggle({
	Name = "Toggle",
	Flag = "Toggle_Example", -- Leave it blank will not save to config
	Default = false,
	Callback = print,
});


-- Add Keybind To Toggle --
local Keybind = Toggle.Link:AddKeybind({
	Default = "E",
	Flag = "Option_Keybind",
	Callback = print
});


-- Helper --
Toggle.Link:AddHelper({
	Text = "Very cool toggle!"
})


-- Add Option To Toggle --
local Toggle2 = NormalSection:AddToggle({
	Name = "Toggle",
	Flag = "Toggle_Example2", -- Leave it blank will not save to config
	Default = false,
	Callback = print,
});


local Option = Toggle2.Link:AddOption()


Option:AddToggle({
	Name= "Example",
	Flag = "Toggle_Example3",
	Callback = print
});


do
	local Toggle2 = NormalSection:AddToggle({
		Name = "Risky Feature",
		Flag = "Toggle_Example5", -- Leave it blank will not save to config
		Default = false,
		Risky = true,
		Callback = print,
	});


	local Option = Toggle2.Link:AddOption()


	Option:AddToggle({
		Risky = true,
		Name= "Risky Feature",
		Flag = "Toggle_Example6",
		Callback = print
	});
end


NormalSection:AddKeybind({
	Name = "Keybind",
	Default = "LeftAlt",
	Flag = "Keybind_Example",
	Callback = print,
});


NormalSection:AddSlider({
	Name = "Slider",
	Min = 0,
	Max = 100,
	Default = 50,
	Round = 0,
	Flag = "Slider_Example",
	Callback = print
});


NormalSection:AddColorPicker({
	Name = "ColorPicker",
	Default = Color3.fromRGB(0, 255, 140),
	Flag = "Color_Picker_Example",
	Callback = print
})


NormalSection:AddDropdown({
	Name = "Single Dropdown",
	Default = "Head",
	Flag = "Single_Dropdown",
	Values = {"Head","Body","Arms","Legs"},
	Callback = print
})


NormalSection:AddDropdown({
	Name = "Multi Dropdown",
	Default = {"Head"},
	Multi = true,
	Flag = "Multi_Dropdown",
	Values = {"Head","Body","Arms","Legs"},
	Callback = print
})


NormalSection:AddButton({
	Name = "Button",
	Callback = function()
		print('PRINT!')
	end,
})


NormalSection:AddParagraph({
	Title = "Paragraph",
	Content = "Very cool paragraph\nAll element in this scrtion\nwill be saved to the config!"
})


NormalSection:AddTextBox({
	Name = "Textbox",
	Placeholder = "Placeholder",
	Default = "Hello, World",
	Callback = print
})


local DrawElements = function(Tab,Position)
	do
		local NormalSectionRight = Tab:DrawSection({
			Name = "Section",
			Position = Position
		});


		local Toggle = NormalSectionRight:AddToggle({
			Name = "Toggle",
			Default = false,
			Callback = print,
		});


		-- Add Keybind To Toggle --
		local Keybind = Toggle.Link:AddKeybind({
			Default = "E",
			Callback = print
		});


		-- Add Option To Toggle --
		local Toggle2 = NormalSectionRight:AddToggle({
			Name = "Toggle",
			Default = false,
			Callback = print,
		});


		local Option = Toggle2.Link:AddOption()


		Option:AddToggle({
			Name= "Example",
			Callback = print
		});


		NormalSectionRight:AddKeybind({
			Name = "Keybind",
			Default = "LeftAlt",
			Callback = print,
		});


		NormalSectionRight:AddSlider({
			Name = "Slider",
			Min = 0,
			Max = 100,
			Default = 50,
			Round = 0,
			Callback = print
		});


		NormalSectionRight:AddColorPicker({
			Name = "ColorPicker",
			Default = Color3.fromRGB(0, 255, 140),
			Callback = print
		})


		NormalSectionRight:AddDropdown({
			Name = "Single Dropdown",
			Default = "Head",
			Values = {"Head","Body","Arms","Legs"},
			Callback = print
		})


		NormalSectionRight:AddDropdown({
			Name = "Multi Dropdown",
			Default = {"Head"},
			Multi = true,
			Values = {"Head","Body","Arms","Legs"},
			Callback = print
		})


		NormalSectionRight:AddButton({
			Name = "Button",
			Callback = function()
				print('PRINT!')
			end,
		})


		NormalSectionRight:AddParagraph({
			Title = "Paragraph",
			Content = "Very cool paragraph\nAll elements in this section\nwill not be save to the config"
		})
	end;
end;


DrawElements(NormalTab,'right')


-- Single Tab --
local SingleTab = Window:DrawTab({
	Name = "Single Tab",
	Icon = "banana",
	Type = "Single"
});


DrawElements(SingleTab,'left')


-- Container Tab --
local ContainerTab = Window:DrawContainerTab({
	Name = "Extract Tabs",
	Icon = "contact",
});


local ExtractTab = ContainerTab:DrawTab({
	Name = "Tab 1",
	Type = "Double"
});


local SingleExtractTab = ContainerTab:DrawTab({
	Name = "Tab 2",
	Type = "Single",
	EnableScrolling = true, -- this will make tab can scrolling (recommend)
});


DrawElements(ExtractTab,"left");
DrawElements(ExtractTab,"right");


DrawElements(SingleExtractTab,"left");
DrawElements(SingleExtractTab,"right");


Window:DrawCategory({
	Name = "Misc"
});


local SettingTab = Window:DrawTab({
	Icon = "settings-3",
	Name = "Settings",
	Type = "Single",
	EnableScrolling = true
});


local ThemeTab = Window:DrawTab({
	Icon = "paintbrush",
	Name = "Themes",
	Type = "Single"
});


local Settings = SettingTab:DrawSection({
	Name = "UI Settings",
});


Settings:AddToggle({
	Name = "Alway Show Frame",
	Default = false,
	Callback = function(v)
		Window.AlwayShowTab = v;
	end,
});


Settings:AddColorPicker({
	Name = "Highlight",
	Default = FiveSync.Colors.Highlight,
	Callback = function(v)
		FiveSync.Colors.Highlight = v;
		FiveSync:RefreshCurrentColor();
	end,
});


Settings:AddColorPicker({
	Name = "Toggle Color",
	Default = FiveSync.Colors.Toggle,
	Callback = function(v)
		FiveSync.Colors.Toggle = v;
		
		FiveSync:RefreshCurrentColor(v);
	end,
});


Settings:AddColorPicker({
	Name = "Drop Color",
	Default = FiveSync.Colors.DropColor,
	Callback = function(v)
		FiveSync.Colors.DropColor = v;


		FiveSync:RefreshCurrentColor(v);
	end,
});


Settings:AddColorPicker({
	Name = "Risky",
	Default = FiveSync.Colors.Risky,
	Callback = function(v)
		FiveSync.Colors.Risky = v;


		FiveSync:RefreshCurrentColor(v);
	end,
});


Settings:AddColorPicker({
	Name = "Mouse Enter",
	Default = FiveSync.Colors.MouseEnter,
	Callback = function(v)
		FiveSync.Colors.MouseEnter = v;


		FiveSync:RefreshCurrentColor(v);
	end,
});


Settings:AddColorPicker({
	Name = "Block Color",
	Default = FiveSync.Colors.BlockColor,
	Callback = function(v)
		FiveSync.Colors.BlockColor = v;


		FiveSync:RefreshCurrentColor(v);
	end,
});


Settings:AddColorPicker({
	Name = "Background Color",
	Default = FiveSync.Colors.BGDBColor,
	Callback = function(v)
		FiveSync.Colors.BGDBColor = v;


		FiveSync:RefreshCurrentColor(v);
	end,
});


Settings:AddColorPicker({
	Name = "Block Background Color",
	Default = FiveSync.Colors.BlockBackground,
	Callback = function(v)
		FiveSync.Colors.BlockBackground = v;


		FiveSync:RefreshCurrentColor(v);
	end,
});


Settings:AddColorPicker({
	Name = "Stroke Color",
	Default = FiveSync.Colors.StrokeColor,
	Callback = function(v)
		FiveSync.Colors.StrokeColor = v;


		FiveSync:RefreshCurrentColor(v);
	end,
});


Settings:AddColorPicker({
	Name = "High Stroke Color",
	Default = FiveSync.Colors.HighStrokeColor,
	Callback = function(v)
		FiveSync.Colors.HighStrokeColor = v;


		FiveSync:RefreshCurrentColor(v);
	end,
});


Settings:AddColorPicker({
	Name = "Switch Color",
	Default = FiveSync.Colors.SwitchColor,
	Callback = function(v)
		FiveSync.Colors.SwitchColor = v;


		FiveSync:RefreshCurrentColor(v);
	end,
});


Settings:AddColorPicker({
	Name = "Line Color",
	Default = FiveSync.Colors.LineColor,
	Callback = function(v)
		FiveSync.Colors.LineColor = v;


		FiveSync:RefreshCurrentColor(v);
	end,
});


Settings:AddButton({
	Name = "Get Theme",
	Callback = function()
		print(FiveSync:GetTheme())
		
		Notifier.new({
			Title = "Notification",
			Content = "Copied Them Color to your clipboard",
			Duration = 5,
			Icon = "rbxassetid://117056629401480"
		});
	end,
});


ThemeTab:DrawSection({
	Name = "UI Themes"
}):AddDropdown({
	Name = "Select Theme",
	Default = "Default",
	Values = {
		"Default",
		"Dark Green",
		"Dark Blue",
		"Purple Rose",
		"Skeet"
	},
	Callback = function(v)
		FiveSync:SetTheme(v)
	end,
})


-- Creating Config Tab --
local ConfigUI = Window:DrawConfig({
	Name = "Config",
	Icon = "folder",
	Config = ConfigManager
});


ConfigUI:Init();
