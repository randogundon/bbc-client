--[[

	AirHub by Exunys © CC0 1.0 Universal (2023)

	https://github.com/Exunys

]]

--// Cache

local loadstring, getgenv, setclipboard, tablefind, UserInputService = loadstring, getgenv, setclipboard, table.find, game:GetService("UserInputService")

--// Loaded check

if AirHub or AirHubV2Loaded then
    return
end

--// Environment

getgenv().AirHub = {}

--// Load Modules

--[[

	Aimbot Module [AirHub] by Exunys © CC0 1.0 Universal (2023)

	https://github.com/Exunys

]]

--// Cache

local pcall, getgenv, next, setmetatable, Vector2new, CFramenew, Color3fromRGB, Drawingnew, TweenInfonew, stringupper, mousemoverel = pcall, getgenv, next, setmetatable, Vector2.new, CFrame.new, Color3.fromRGB, Drawing.new, TweenInfo.new, string.upper, mousemoverel or (Input and Input.MouseMove)

--// Launching checks

if not getgenv().AirHub or getgenv().AirHub.Aimbot then return end

--// Services

local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local Camera = workspace.CurrentCamera

--// Variables

local RequiredDistance, Typing, Running, ServiceConnections, Animation, OriginalSensitivity = 2000, false, false, {}

--// Environment

getgenv().AirHub.Aimbot = {
	Settings = {
		Enabled = false,
		TeamCheck = false,
		AliveCheck = true,
		WallCheck = false,
		Sensitivity = 0, -- Animation length (in seconds) before fully locking onto target
		ThirdPerson = false, -- Uses mousemoverel instead of CFrame to support locking in third person (could be choppy)
		ThirdPersonSensitivity = 3,
		TriggerKey = "MouseButton2",
		Toggle = false,
		LockPart = "Head" -- Body part to lock on
	},

	FOVSettings = {
		Enabled = true,
		Visible = true,
		Amount = 90,
		Color = Color3fromRGB(255, 255, 255),
		LockedColor = Color3fromRGB(255, 70, 70),
		Transparency = 0.5,
		Sides = 60,
		Thickness = 1,
		Filled = false
	},

	FOVCircle = Drawingnew("Circle")
}

local Environment = getgenv().AirHub.Aimbot

--// Core Functions

local function ConvertVector(Vector)
	return Vector2new(Vector.X, Vector.Y)
end

local function CancelLock()
	Environment.Locked = nil
	Environment.FOVCircle.Color = Environment.FOVSettings.Color
	UserInputService.MouseDeltaSensitivity = OriginalSensitivity

	if Animation then
		Animation:Cancel()
	end
end

local function GetClosestPlayer()
	if not Environment.Locked then
		RequiredDistance = (Environment.FOVSettings.Enabled and Environment.FOVSettings.Amount or 2000)

		for _, v in next, Players:GetPlayers() do
			if v ~= LocalPlayer and v.Character and v.Character:FindFirstChild(Environment.Settings.LockPart) and v.Character:FindFirstChildOfClass("Humanoid") then
				if Environment.Settings.TeamCheck and v.TeamColor == LocalPlayer.TeamColor then continue end
				if Environment.Settings.AliveCheck and v.Character:FindFirstChildOfClass("Humanoid").Health <= 0 then continue end
				if Environment.Settings.WallCheck and #(Camera:GetPartsObscuringTarget({v.Character[Environment.Settings.LockPart].Position}, v.Character:GetDescendants())) > 0 then continue end

				local Vector, OnScreen = Camera:WorldToViewportPoint(v.Character[Environment.Settings.LockPart].Position); Vector = ConvertVector(Vector)
				local Distance = (UserInputService:GetMouseLocation() - Vector).Magnitude

				if Distance < RequiredDistance and OnScreen then
					RequiredDistance = Distance
					Environment.Locked = v
				end
			end
		end
	elseif (UserInputService:GetMouseLocation() - ConvertVector(Camera:WorldToViewportPoint(Environment.Locked.Character[Environment.Settings.LockPart].Position))).Magnitude > RequiredDistance then
		CancelLock()
	end
end

local function Load()
	OriginalSensitivity = UserInputService.MouseDeltaSensitivity

	ServiceConnections.RenderSteppedConnection = RunService.RenderStepped:Connect(function()
		if Environment.FOVSettings.Enabled and Environment.Settings.Enabled then
			Environment.FOVCircle.Radius = Environment.FOVSettings.Amount
			Environment.FOVCircle.Thickness = Environment.FOVSettings.Thickness
			Environment.FOVCircle.Filled = Environment.FOVSettings.Filled
			Environment.FOVCircle.NumSides = Environment.FOVSettings.Sides
			Environment.FOVCircle.Color = Environment.FOVSettings.Color
			Environment.FOVCircle.Transparency = Environment.FOVSettings.Transparency
			Environment.FOVCircle.Visible = Environment.FOVSettings.Visible
			Environment.FOVCircle.Position = Vector2new(UserInputService:GetMouseLocation().X, UserInputService:GetMouseLocation().Y)
		else
			Environment.FOVCircle.Visible = false
		end

		if Running and Environment.Settings.Enabled then
			GetClosestPlayer()

			if Environment.Locked then
				if Environment.Settings.ThirdPerson then
					local Vector = Camera:WorldToViewportPoint(Environment.Locked.Character[Environment.Settings.LockPart].Position)

					mousemoverel((Vector.X - UserInputService:GetMouseLocation().X) * Environment.Settings.ThirdPersonSensitivity, (Vector.Y - UserInputService:GetMouseLocation().Y) * Environment.Settings.ThirdPersonSensitivity)
				else
					if Environment.Settings.Sensitivity > 0 then
						Animation = TweenService:Create(Camera, TweenInfonew(Environment.Settings.Sensitivity, Enum.EasingStyle.Sine, Enum.EasingDirection.Out), {CFrame = CFramenew(Camera.CFrame.Position, Environment.Locked.Character[Environment.Settings.LockPart].Position)})
						Animation:Play()
					else
						Camera.CFrame = CFramenew(Camera.CFrame.Position, Environment.Locked.Character[Environment.Settings.LockPart].Position)
					end

					UserInputService.MouseDeltaSensitivity = 0
				end

				Environment.FOVCircle.Color = Environment.FOVSettings.LockedColor
			end
		end
	end)

	ServiceConnections.InputBeganConnection = UserInputService.InputBegan:Connect(function(Input)
		if not Typing then
			pcall(function()
				if Input.UserInputType == Enum.UserInputType.Keyboard and Input.KeyCode == Enum.KeyCode[#Environment.Settings.TriggerKey == 1 and stringupper(Environment.Settings.TriggerKey) or Environment.Settings.TriggerKey] or Input.UserInputType == Enum.UserInputType[Environment.Settings.TriggerKey] then
					if Environment.Settings.Toggle then
						Running = not Running

						if not Running then
							CancelLock()
						end
					else
						Running = true
					end
				end
			end)
		end
	end)

	ServiceConnections.InputEndedConnection = UserInputService.InputEnded:Connect(function(Input)
		if not Typing then
			if not Environment.Settings.Toggle then
				pcall(function()
					if Input.UserInputType == Enum.UserInputType.Keyboard and Input.KeyCode == Enum.KeyCode[#Environment.Settings.TriggerKey == 1 and stringupper(Environment.Settings.TriggerKey) or Environment.Settings.TriggerKey] or Input.UserInputType == Enum.UserInputType[Environment.Settings.TriggerKey] then
						Running = false; CancelLock()
					end
				end)
			end
		end
	end)
end

--// Typing Check

ServiceConnections.TypingStartedConnection = UserInputService.TextBoxFocused:Connect(function()
	Typing = true
end)

ServiceConnections.TypingEndedConnection = UserInputService.TextBoxFocusReleased:Connect(function()
	Typing = false
end)

--// Functions

Environment.Functions = {}

function Environment.Functions:Exit()
	for _, v in next, ServiceConnections do
		v:Disconnect()
	end

	Environment.FOVCircle:Remove()

	getgenv().AirHub.Aimbot.Functions = nil
	getgenv().AirHub.Aimbot = nil

	Load = nil; ConvertVector = nil; CancelLock = nil; GetClosestPlayer = nil;
end

function Environment.Functions:Restart()
	for _, v in next, ServiceConnections do
		v:Disconnect()
	end

	Load()
end

function Environment.Functions:ResetSettings()
	Environment.Settings = {
		Enabled = false,
		TeamCheck = false,
		AliveCheck = true,
		WallCheck = false,
		Sensitivity = 0, -- Animation length (in seconds) before fully locking onto target
		ThirdPerson = false, -- Uses mousemoverel instead of CFrame to support locking in third person (could be choppy)
		ThirdPersonSensitivity = 3,
		TriggerKey = "MouseButton2",
		Toggle = false,
		LockPart = "Head" -- Body part to lock on
	}

	Environment.FOVSettings = {
		Enabled = true,
		Visible = true,
		Amount = 90,
		Color = Color3fromRGB(255, 255, 255),
		LockedColor = Color3fromRGB(255, 70, 70),
		Transparency = 0.5,
		Sides = 60,
		Thickness = 1,
		Filled = false
	}
end

setmetatable(Environment.Functions, {
	__newindex = warn
})

--// Load

Load()
loadstring(game:HttpGet("https://raw.githubusercontent.com/Exunys/AirHub/main/Modules/Wall%20Hack.lua"))()

--// Variables

local Library = loadstring(game:GetObjects("rbxassetid://7657867786")[1].Source)() -- Pepsi's UI Library
local Aimbot, WallHack = getgenv().AirHub.Aimbot, getgenv().AirHub.WallHack
local Parts, Fonts, TracersType = {"Head", "HumanoidRootPart", "Torso", "Left Arm", "Right Arm", "Left Leg", "Right Leg", "LeftHand", "RightHand", "LeftLowerArm", "RightLowerArm", "LeftUpperArm", "RightUpperArm", "LeftFoot", "LeftLowerLeg", "UpperTorso", "LeftUpperLeg", "RightFoot", "RightLowerLeg", "LowerTorso", "RightUpperLeg"}, {"UI", "System", "Plex", "Monospace"}, {"Bottom", "Center", "Mouse"}

--// Frame

Library.UnloadCallback = function()
	Aimbot.Functions:Exit()
	WallHack.Functions:Exit()
	getgenv().AirHub = nil
end

local MainFrame = Library:CreateWindow({
	Name = "bbc client",
	Themeable = {
		Image = "7059346386",
		Info = "Created by brazzers co.",
		Credit = true
	},
	Background = "",
	Theme = [[{"__Designer.Colors.topGradient":"C2DFFF","__Designer.Colors.section":"A6D8FF","__Designer.Colors.hoveredOptionBottom":"93E0FF","__Designer.Background.ImageAssetID":"rbxassetid://4427304036","__Designer.Colors.selectedOption":"8CB3FF","__Designer.Colors.unselectedOption":"BEDAFF","__Designer.Files.WorkspaceFile":"AirHub","__Designer.Colors.unhoveredOptionTop":"B3E6FF","__Designer.Colors.outerBorder":"BFE3FF","__Designer.Background.ImageColor":"D6EFFF","__Designer.Colors.tabText":"000000","__Designer.Colors.elementBorder":"C2DFFF","__Designer.Background.ImageTransparency":100,"__Designer.Colors.background":"E6

})

--// Tabs

local AimbotTab = MainFrame:CreateTab({
	Name = "Aimbot"
})

local VisualsTab = MainFrame:CreateTab({
	Name = "Visuals"
})

local CrosshairTab = MainFrame:CreateTab({
	Name = "Crosshair"
})

local FunctionsTab = MainFrame:CreateTab({
	Name = "Functions"
})

--// Aimbot Sections

local Values = AimbotTab:CreateSection({
	Name = "Values"
})

local Checks = AimbotTab:CreateSection({
	Name = "Checks"
})

local ThirdPerson = AimbotTab:CreateSection({
	Name = "Third Person"
})

local FOV_Values = AimbotTab:CreateSection({
	Name = "Field Of View",
	Side = "Right"
})

local FOV_Appearance = AimbotTab:CreateSection({
	Name = "FOV Circle Appearance",
	Side = "Right"
})

--// Visuals Sections

local WallHackChecks = VisualsTab:CreateSection({
	Name = "Checks"
})

local ESPSettings = VisualsTab:CreateSection({
	Name = "ESP Settings"
})

local BoxesSettings = VisualsTab:CreateSection({
	Name = "Boxes Settings"
})

local ChamsSettings = VisualsTab:CreateSection({
	Name = "Chams Settings"
})

local TracersSettings = VisualsTab:CreateSection({
	Name = "Tracers Settings",
	Side = "Right"
})

local HeadDotsSettings = VisualsTab:CreateSection({
	Name = "Head Dots Settings",
	Side = "Right"
})

local HealthBarSettings = VisualsTab:CreateSection({
	Name = "Health Bar Settings",
	Side = "Right"
})

--// Crosshair Sections

local CrosshairSettings = CrosshairTab:CreateSection({
	Name = "Settings"
})

local CrosshairSettings_CenterDot = CrosshairTab:CreateSection({
	Name = "Center Dot Settings",
	Side = "Right"
})

--// Functions Sections

local FunctionsSection = FunctionsTab:CreateSection({
	Name = "Functions"
})

--// Aimbot Values

Values:AddToggle({
	Name = "Enabled",
	Value = Aimbot.Settings.Enabled,
	Callback = function(New, Old)
		Aimbot.Settings.Enabled = New
	end
}).Default = Aimbot.Settings.Enabled

Values:AddToggle({
	Name = "Toggle",
	Value = Aimbot.Settings.Toggle,
	Callback = function(New, Old)
		Aimbot.Settings.Toggle = New
	end
}).Default = Aimbot.Settings.Toggle

Aimbot.Settings.LockPart = Parts[1]; Values:AddDropdown({
	Name = "Lock Part",
	Value = Parts[1],
	Callback = function(New, Old)
		Aimbot.Settings.LockPart = New
	end,
	List = Parts,
	Nothing = "Head"
}).Default = Parts[1]

Values:AddTextbox({ -- Using a Textbox instead of a Keybind because the UI Library doesn't support Mouse inputs like Left Click / Right Click...
	Name = "Hotkey",
	Value = Aimbot.Settings.TriggerKey,
	Callback = function(New, Old)
		Aimbot.Settings.TriggerKey = New
	end
}).Default = Aimbot.Settings.TriggerKey

--[[
Values:AddKeybind({
	Name = "Hotkey",
	Value = Aimbot.Settings.TriggerKey,
	Callback = function(New, Old)
		Aimbot.Settings.TriggerKey = stringmatch(tostring(New), "Enum%.[UserInputType]*[KeyCode]*%.(.+)")
	end,
}).Default = Aimbot.Settings.TriggerKey
]]

Values:AddSlider({
	Name = "Sensitivity",
	Value = Aimbot.Settings.Sensitivity,
	Callback = function(New, Old)
		Aimbot.Settings.Sensitivity = New
	end,
	Min = 0,
	Max = 1,
	Decimals = 2
}).Default = Aimbot.Settings.Sensitivity

--// Aimbot Checks

Checks:AddToggle({
	Name = "Team Check",
	Value = Aimbot.Settings.TeamCheck,
	Callback = function(New, Old)
		Aimbot.Settings.TeamCheck = New
	end
}).Default = Aimbot.Settings.TeamCheck

Checks:AddToggle({
	Name = "Wall Check",
	Value = Aimbot.Settings.WallCheck,
	Callback = function(New, Old)
		Aimbot.Settings.WallCheck = New
	end
}).Default = Aimbot.Settings.WallCheck

Checks:AddToggle({
	Name = "Alive Check",
	Value = Aimbot.Settings.AliveCheck,
	Callback = function(New, Old)
		Aimbot.Settings.AliveCheck = New
	end
}).Default = Aimbot.Settings.AliveCheck

--// Aimbot ThirdPerson

ThirdPerson:AddToggle({
	Name = "Enable Third Person",
	Value = Aimbot.Settings.ThirdPerson,
	Callback = function(New, Old)
		Aimbot.Settings.ThirdPerson = New
	end
}).Default = Aimbot.Settings.ThirdPerson

ThirdPerson:AddSlider({
	Name = "Sensitivity",
	Value = Aimbot.Settings.ThirdPersonSensitivity,
	Callback = function(New, Old)
		Aimbot.Settings.ThirdPersonSensitivity = New
	end,
	Min = 0.1,
	Max = 5,
	Decimals = 1
}).Default = Aimbot.Settings.ThirdPersonSensitivity

--// FOV Settings Values

FOV_Values:AddToggle({
	Name = "Enabled",
	Value = Aimbot.FOVSettings.Enabled,
	Callback = function(New, Old)
		Aimbot.FOVSettings.Enabled = New
	end
}).Default = Aimbot.FOVSettings.Enabled

FOV_Values:AddToggle({
	Name = "Visible",
	Value = Aimbot.FOVSettings.Visible,
	Callback = function(New, Old)
		Aimbot.FOVSettings.Visible = New
	end
}).Default = Aimbot.FOVSettings.Visible

FOV_Values:AddSlider({
	Name = "Amount",
	Value = Aimbot.FOVSettings.Amount,
	Callback = function(New, Old)
		Aimbot.FOVSettings.Amount = New
	end,
	Min = 10,
	Max = 300
}).Default = Aimbot.FOVSettings.Amount

--// FOV Settings Appearance

FOV_Appearance:AddToggle({
	Name = "Filled",
	Value = Aimbot.FOVSettings.Filled,
	Callback = function(New, Old)
		Aimbot.FOVSettings.Filled = New
	end
}).Default = Aimbot.FOVSettings.Filled

FOV_Appearance:AddSlider({
	Name = "Transparency",
	Value = Aimbot.FOVSettings.Transparency,
	Callback = function(New, Old)
		Aimbot.FOVSettings.Transparency = New
	end,
	Min = 0,
	Max = 1,
	Decimal = 1
}).Default = Aimbot.FOVSettings.Transparency

FOV_Appearance:AddSlider({
	Name = "Sides",
	Value = Aimbot.FOVSettings.Sides,
	Callback = function(New, Old)
		Aimbot.FOVSettings.Sides = New
	end,
	Min = 3,
	Max = 60
}).Default = Aimbot.FOVSettings.Sides

FOV_Appearance:AddSlider({
	Name = "Thickness",
	Value = Aimbot.FOVSettings.Thickness,
	Callback = function(New, Old)
		Aimbot.FOVSettings.Thickness = New
	end,
	Min = 1,
	Max = 50
}).Default = Aimbot.FOVSettings.Thickness

FOV_Appearance:AddColorpicker({
	Name = "Color",
	Value = Aimbot.FOVSettings.Color,
	Callback = function(New, Old)
		Aimbot.FOVSettings.Color = New
	end
}).Default = Aimbot.FOVSettings.Color

FOV_Appearance:AddColorpicker({
	Name = "Locked Color",
	Value = Aimbot.FOVSettings.LockedColor,
	Callback = function(New, Old)
		Aimbot.FOVSettings.LockedColor = New
	end
}).Default = Aimbot.FOVSettings.LockedColor

--// Wall Hack Settings

WallHackChecks:AddToggle({
	Name = "Enabled",
	Value = WallHack.Settings.Enabled,
	Callback = function(New, Old)
		WallHack.Settings.Enabled = New
	end
}).Default = WallHack.Settings.Enabled

WallHackChecks:AddToggle({
	Name = "Team Check",
	Value = WallHack.Settings.TeamCheck,
	Callback = function(New, Old)
		WallHack.Settings.TeamCheck = New
	end
}).Default = WallHack.Settings.TeamCheck

WallHackChecks:AddToggle({
	Name = "Alive Check",
	Value = WallHack.Settings.AliveCheck,
	Callback = function(New, Old)
		WallHack.Settings.AliveCheck = New
	end
}).Default = WallHack.Settings.AliveCheck

--// Visuals Settings

ESPSettings:AddToggle({
	Name = "Enabled",
	Value = WallHack.Visuals.ESPSettings.Enabled,
	Callback = function(New, Old)
		WallHack.Visuals.ESPSettings.Enabled = New
	end
}).Default = WallHack.Visuals.ESPSettings.Enabled

ESPSettings:AddToggle({
	Name = "Outline",
	Value = WallHack.Visuals.ESPSettings.Outline,
	Callback = function(New, Old)
		WallHack.Visuals.ESPSettings.Outline = New
	end
}).Default = WallHack.Visuals.ESPSettings.Outline

ESPSettings:AddToggle({
	Name = "Display Distance",
	Value = WallHack.Visuals.ESPSettings.DisplayDistance,
	Callback = function(New, Old)
		WallHack.Visuals.ESPSettings.DisplayDistance = New
	end
}).Default = WallHack.Visuals.ESPSettings.DisplayDistance

ESPSettings:AddToggle({
	Name = "Display Health",
	Value = WallHack.Visuals.ESPSettings.DisplayHealth,
	Callback = function(New, Old)
		WallHack.Visuals.ESPSettings.DisplayHealth = New
	end
}).Default = WallHack.Visuals.ESPSettings.DisplayHealth

ESPSettings:AddToggle({
	Name = "Display Name",
	Value = WallHack.Visuals.ESPSettings.DisplayName,
	Callback = function(New, Old)
		WallHack.Visuals.ESPSettings.DisplayName = New
	end
}).Default = WallHack.Visuals.ESPSettings.DisplayName

ESPSettings:AddSlider({
	Name = "Offset",
	Value = WallHack.Visuals.ESPSettings.Offset,
	Callback = function(New, Old)
		WallHack.Visuals.ESPSettings.Offset = New
	end,
	Min = -30,
	Max = 30
}).Default = WallHack.Visuals.ESPSettings.Offset

ESPSettings:AddColorpicker({
	Name = "Text Color",
	Value = WallHack.Visuals.ESPSettings.TextColor,
	Callback = function(New, Old)
		WallHack.Visuals.ESPSettings.TextColor = New
	end
}).Default = WallHack.Visuals.ESPSettings.TextColor

ESPSettings:AddColorpicker({
	Name = "Outline Color",
	Value = WallHack.Visuals.ESPSettings.OutlineColor,
	Callback = function(New, Old)
		WallHack.Visuals.ESPSettings.OutlineColor = New
	end
}).Default = WallHack.Visuals.ESPSettings.OutlineColor

ESPSettings:AddSlider({
	Name = "Text Transparency",
	Value = WallHack.Visuals.ESPSettings.TextTransparency,
	Callback = function(New, Old)
		WallHack.Visuals.ESPSettings.TextTransparency = New
	end,
	Min = 0,
	Max = 1,
	Decimals = 2
}).Default = WallHack.Visuals.ESPSettings.TextTransparency

ESPSettings:AddSlider({
	Name = "Text Size",
	Value = WallHack.Visuals.ESPSettings.TextSize,
	Callback = function(New, Old)
		WallHack.Visuals.ESPSettings.TextSize = New
	end,
	Min = 8,
	Max = 24
}).Default = WallHack.Visuals.ESPSettings.TextSize

ESPSettings:AddDropdown({
	Name = "Text Font",
	Value = Fonts[WallHack.Visuals.ESPSettings.TextFont + 1],
	Callback = function(New, Old)
		WallHack.Visuals.ESPSettings.TextFont = Drawing.Fonts[New]
	end,
	List = Fonts,
	Nothing = "UI"
}).Default = Fonts[WallHack.Visuals.ESPSettings.TextFont + 1]

BoxesSettings:AddToggle({
	Name = "Enabled",
	Value = WallHack.Visuals.BoxSettings.Enabled,
	Callback = function(New, Old)
		WallHack.Visuals.BoxSettings.Enabled = New
	end
}).Default = WallHack.Visuals.BoxSettings.Enabled

BoxesSettings:AddSlider({
	Name = "Transparency",
	Value = WallHack.Visuals.BoxSettings.Transparency,
	Callback = function(New, Old)
		WallHack.Visuals.BoxSettings.Transparency = New
	end,
	Min = 0,
	Max = 1,
	Decimals = 2
}).Default = WallHack.Visuals.BoxSettings.Transparency

BoxesSettings:AddSlider({
	Name = "Thickness",
	Value = WallHack.Visuals.BoxSettings.Thickness,
	Callback = function(New, Old)
		WallHack.Visuals.BoxSettings.Thickness = New
	end,
	Min = 1,
	Max = 5
}).Default = WallHack.Visuals.BoxSettings.Thickness

BoxesSettings:AddSlider({
	Name = "Scale Increase (For 3D)",
	Value = WallHack.Visuals.BoxSettings.Increase,
	Callback = function(New, Old)
		WallHack.Visuals.BoxSettings.Increase = New
	end,
	Min = 1,
	Max = 5
}).Default = WallHack.Visuals.BoxSettings.Increase

BoxesSettings:AddColorpicker({
	Name = "Color",
	Value = WallHack.Visuals.BoxSettings.Color,
	Callback = function(New, Old)
		WallHack.Visuals.BoxSettings.Color = New
	end
}).Default = WallHack.Visuals.BoxSettings.Color

BoxesSettings:AddDropdown({
	Name = "Type",
	Value = WallHack.Visuals.BoxSettings.Type == 1 and "3D" or "2D",
	Callback = function(New, Old)
		WallHack.Visuals.BoxSettings.Type = New == "3D" and 1 or 2
	end,
	List = {"3D", "2D"},
	Nothing = "3D"
}).Default = WallHack.Visuals.BoxSettings.Type == 1 and "3D" or "2D"

BoxesSettings:AddToggle({
	Name = "Filled (2D Square)",
	Value = WallHack.Visuals.BoxSettings.Filled,
	Callback = function(New, Old)
		WallHack.Visuals.BoxSettings.Filled = New
	end
}).Default = WallHack.Visuals.BoxSettings.Filled

ChamsSettings:AddToggle({
	Name = "Enabled",
	Value = WallHack.Visuals.ChamsSettings.Enabled,
	Callback = function(New, Old)
		WallHack.Visuals.ChamsSettings.Enabled = New
	end
}).Default = WallHack.Visuals.ChamsSettings.Enabled

ChamsSettings:AddToggle({
	Name = "Filled",
	Value = WallHack.Visuals.ChamsSettings.Filled,
	Callback = function(New, Old)
		WallHack.Visuals.ChamsSettings.Filled = New
	end
}).Default = WallHack.Visuals.ChamsSettings.Filled

ChamsSettings:AddToggle({
	Name = "Entire Body (For R15 Rigs)",
	Value = WallHack.Visuals.ChamsSettings.EntireBody,
	Callback = function(New, Old)
		WallHack.Visuals.ChamsSettings.EntireBody = New
	end
}).Default = WallHack.Visuals.ChamsSettings.EntireBody

ChamsSettings:AddSlider({
	Name = "Transparency",
	Value = WallHack.Visuals.ChamsSettings.Transparency,
	Callback = function(New, Old)
		WallHack.Visuals.ChamsSettings.Transparency = New
	end,
	Min = 0,
	Max = 1,
	Decimals = 2
}).Default = WallHack.Visuals.ChamsSettings.Transparency

ChamsSettings:AddSlider({
	Name = "Thickness",
	Value = WallHack.Visuals.ChamsSettings.Thickness,
	Callback = function(New, Old)
		WallHack.Visuals.ChamsSettings.Thickness = New
	end,
	Min = 0,
	Max = 3
}).Default = WallHack.Visuals.ChamsSettings.Thickness

ChamsSettings:AddColorpicker({
	Name = "Color",
	Value = WallHack.Visuals.ChamsSettings.Color,
	Callback = function(New, Old)
		WallHack.Visuals.ChamsSettings.Color = New
	end
}).Default = WallHack.Visuals.ChamsSettings.Color

TracersSettings:AddToggle({
	Name = "Enabled",
	Value = WallHack.Visuals.TracersSettings.Enabled,
	Callback = function(New, Old)
		WallHack.Visuals.TracersSettings.Enabled = New
	end
}).Default = WallHack.Visuals.TracersSettings.Enabled

TracersSettings:AddSlider({
	Name = "Transparency",
	Value = WallHack.Visuals.TracersSettings.Transparency,
	Callback = function(New, Old)
		WallHack.Visuals.TracersSettings.Transparency = New
	end,
	Min = 0,
	Max = 1,
	Decimals = 2
}).Default = WallHack.Visuals.TracersSettings.Transparency

TracersSettings:AddSlider({
	Name = "Thickness",
	Value = WallHack.Visuals.TracersSettings.Thickness,
	Callback = function(New, Old)
		WallHack.Visuals.TracersSettings.Thickness = New
	end,
	Min = 1,
	Max = 5
}).Default = WallHack.Visuals.TracersSettings.Thickness

TracersSettings:AddColorpicker({
	Name = "Color",
	Value = WallHack.Visuals.TracersSettings.Color,
	Callback = function(New, Old)
		WallHack.Visuals.TracersSettings.Color = New
	end
}).Default = WallHack.Visuals.TracersSettings.Color

TracersSettings:AddDropdown({
	Name = "Start From",
	Value = TracersType[WallHack.Visuals.TracersSettings.Type],
	Callback = function(New, Old)
		WallHack.Visuals.TracersSettings.Type = tablefind(TracersType, New)
	end,
	List = TracersType,
	Nothing = "Bottom"
}).Default = Fonts[WallHack.Visuals.TracersSettings.Type + 1]

HeadDotsSettings:AddToggle({
	Name = "Enabled",
	Value = WallHack.Visuals.HeadDotSettings.Enabled,
	Callback = function(New, Old)
		WallHack.Visuals.HeadDotSettings.Enabled = New
	end
}).Default = WallHack.Visuals.HeadDotSettings.Enabled

HeadDotsSettings:AddToggle({
	Name = "Filled",
	Value = WallHack.Visuals.HeadDotSettings.Filled,
	Callback = function(New, Old)
		WallHack.Visuals.HeadDotSettings.Filled = New
	end
}).Default = WallHack.Visuals.HeadDotSettings.Filled

HeadDotsSettings:AddSlider({
	Name = "Transparency",
	Value = WallHack.Visuals.HeadDotSettings.Transparency,
	Callback = function(New, Old)
		WallHack.Visuals.HeadDotSettings.Transparency = New
	end,
	Min = 0,
	Max = 1,
	Decimals = 2
}).Default = WallHack.Visuals.HeadDotSettings.Transparency

HeadDotsSettings:AddSlider({
	Name = "Thickness",
	Value = WallHack.Visuals.HeadDotSettings.Thickness,
	Callback = function(New, Old)
		WallHack.Visuals.HeadDotSettings.Thickness = New
	end,
	Min = 1,
	Max = 5
}).Default = WallHack.Visuals.HeadDotSettings.Thickness

HeadDotsSettings:AddSlider({
	Name = "Sides",
	Value = WallHack.Visuals.HeadDotSettings.Sides,
	Callback = function(New, Old)
		WallHack.Visuals.HeadDotSettings.Sides = New
	end,
	Min = 3,
	Max = 60
}).Default = WallHack.Visuals.HeadDotSettings.Sides

HeadDotsSettings:AddColorpicker({
	Name = "Color",
	Value = WallHack.Visuals.HeadDotSettings.Color,
	Callback = function(New, Old)
		WallHack.Visuals.HeadDotSettings.Color = New
	end
}).Default = WallHack.Visuals.HeadDotSettings.Color

HealthBarSettings:AddToggle({
	Name = "Enabled",
	Value = WallHack.Visuals.HealthBarSettings.Enabled,
	Callback = function(New, Old)
		WallHack.Visuals.HealthBarSettings.Enabled = New
	end
}).Default = WallHack.Visuals.HealthBarSettings.Enabled

HealthBarSettings:AddDropdown({
	Name = "Position",
	Value = WallHack.Visuals.HealthBarSettings.Type == 1 and "Top" or WallHack.Visuals.HealthBarSettings.Type == 2 and "Bottom" or WallHack.Visuals.HealthBarSettings.Type == 3 and "Left" or "Right",
	Callback = function(New, Old)
		WallHack.Visuals.HealthBarSettings.Type = New == "Top" and 1 or New == "Bottom" and 2 or New == "Left" and 3 or 4
	end,
	List = {"Top", "Bottom", "Left", "Right"},
	Nothing = "Left"
}).Default = WallHack.Visuals.HealthBarSettings.Type == 1 and "Top" or WallHack.Visuals.HealthBarSettings.Type == 2 and "Bottom" or WallHack.Visuals.HealthBarSettings.Type == 3 and "Left" or "Right"

HealthBarSettings:AddSlider({
	Name = "Transparency",
	Value = WallHack.Visuals.HealthBarSettings.Transparency,
	Callback = function(New, Old)
		WallHack.Visuals.HealthBarSettings.Transparency = New
	end,
	Min = 0,
	Max = 1,
	Decimals = 2
}).Default = WallHack.Visuals.HealthBarSettings.Transparency

HealthBarSettings:AddSlider({
	Name = "Size",
	Value = WallHack.Visuals.HealthBarSettings.Size,
	Callback = function(New, Old)
		WallHack.Visuals.HealthBarSettings.Size = New
	end,
	Min = 2,
	Max = 10
}).Default = WallHack.Visuals.HealthBarSettings.Size

HealthBarSettings:AddSlider({
	Name = "Blue",
	Value = WallHack.Visuals.HealthBarSettings.Blue,
	Callback = function(New, Old)
		WallHack.Visuals.HealthBarSettings.Blue = New
	end,
	Min = 0,
	Max = 255
}).Default = WallHack.Visuals.HealthBarSettings.Blue

HealthBarSettings:AddSlider({
	Name = "Offset",
	Value = WallHack.Visuals.HealthBarSettings.Offset,
	Callback = function(New, Old)
		WallHack.Visuals.HealthBarSettings.Offset = New
	end,
	Min = -30,
	Max = 30
}).Default = WallHack.Visuals.HealthBarSettings.Offset

HealthBarSettings:AddColorpicker({
	Name = "Outline Color",
	Value = WallHack.Visuals.HealthBarSettings.OutlineColor,
	Callback = function(New, Old)
		WallHack.Visuals.HealthBarSettings.OutlineColor = New
	end
}).Default = WallHack.Visuals.HealthBarSettings.OutlineColor

--// Crosshair Settings

CrosshairSettings:AddToggle({
	Name = "Mouse Cursor",
	Value = UserInputService.MouseIconEnabled,
	Callback = function(New, Old)
		UserInputService.MouseIconEnabled = New
	end
}).Default = UserInputService.MouseIconEnabled

CrosshairSettings:AddToggle({
	Name = "Enabled",
	Value = WallHack.Crosshair.Settings.Enabled,
	Callback = function(New, Old)
		WallHack.Crosshair.Settings.Enabled = New
	end
}).Default = WallHack.Crosshair.Settings.Enabled

CrosshairSettings:AddColorpicker({
	Name = "Color",
	Value = WallHack.Crosshair.Settings.Color,
	Callback = function(New, Old)
		WallHack.Crosshair.Settings.Color = New
	end
}).Default = WallHack.Crosshair.Settings.Color

CrosshairSettings:AddSlider({
	Name = "Transparency",
	Value = WallHack.Crosshair.Settings.Transparency,
	Callback = function(New, Old)
		WallHack.Crosshair.Settings.Transparency = New
	end,
	Min = 0,
	Max = 1,
	Decimals = 2
}).Default = WallHack.Crosshair.Settings.Transparency

CrosshairSettings:AddSlider({
	Name = "Size",
	Value = WallHack.Crosshair.Settings.Size,
	Callback = function(New, Old)
		WallHack.Crosshair.Settings.Size = New
	end,
	Min = 8,
	Max = 24
}).Default = WallHack.Crosshair.Settings.Size

CrosshairSettings:AddSlider({
	Name = "Thickness",
	Value = WallHack.Crosshair.Settings.Thickness,
	Callback = function(New, Old)
		WallHack.Crosshair.Settings.Thickness = New
	end,
	Min = 1,
	Max = 5
}).Default = WallHack.Crosshair.Settings.Thickness

CrosshairSettings:AddSlider({
	Name = "Gap Size",
	Value = WallHack.Crosshair.Settings.GapSize,
	Callback = function(New, Old)
		WallHack.Crosshair.Settings.GapSize = New
	end,
	Min = 0,
	Max = 20
}).Default = WallHack.Crosshair.Settings.GapSize

CrosshairSettings:AddSlider({
	Name = "Rotation (Degrees)",
	Value = WallHack.Crosshair.Settings.Rotation,
	Callback = function(New, Old)
		WallHack.Crosshair.Settings.Rotation = New
	end,
	Min = -180,
	Max = 180
}).Default = WallHack.Crosshair.Settings.Rotation

CrosshairSettings:AddDropdown({
	Name = "Position",
	Value = WallHack.Crosshair.Settings.Type == 1 and "Mouse" or "Center",
	Callback = function(New, Old)
		WallHack.Crosshair.Settings.Type = New == "Mouse" and 1 or 2
	end,
	List = {"Mouse", "Center"},
	Nothing = "Mouse"
}).Default = WallHack.Crosshair.Settings.Type == 1 and "Mouse" or "Center"

CrosshairSettings_CenterDot:AddToggle({
	Name = "Center Dot",
	Value = WallHack.Crosshair.Settings.CenterDot,
	Callback = function(New, Old)
		WallHack.Crosshair.Settings.CenterDot = New
	end
}).Default = WallHack.Crosshair.Settings.CenterDot

CrosshairSettings_CenterDot:AddColorpicker({
	Name = "Center Dot Color",
	Value = WallHack.Crosshair.Settings.CenterDotColor,
	Callback = function(New, Old)
		WallHack.Crosshair.Settings.CenterDotColor = New
	end
}).Default = WallHack.Crosshair.Settings.CenterDotColor

CrosshairSettings_CenterDot:AddSlider({
	Name = "Center Dot Size",
	Value = WallHack.Crosshair.Settings.CenterDotSize,
	Callback = function(New, Old)
		WallHack.Crosshair.Settings.CenterDotSize = New
	end,
	Min = 1,
	Max = 6
}).Default = WallHack.Crosshair.Settings.CenterDotSize

CrosshairSettings_CenterDot:AddSlider({
	Name = "Center Dot Transparency",
	Value = WallHack.Crosshair.Settings.CenterDotTransparency,
	Callback = function(New, Old)
		WallHack.Crosshair.Settings.CenterDotTransparency = New
	end,
	Min = 0,
	Max = 1,
	Decimals = 2
}).Default = WallHack.Crosshair.Settings.CenterDotTransparency

CrosshairSettings_CenterDot:AddToggle({
	Name = "Center Dot Filled",
	Value = WallHack.Crosshair.Settings.CenterDotFilled,
	Callback = function(New, Old)
		WallHack.Crosshair.Settings.CenterDotFilled = New
	end
}).Default = WallHack.Crosshair.Settings.CenterDotFilled

--// Functions / Functions

FunctionsSection:AddButton({
	Name = "Reset Settings",
	Callback = function()
		Aimbot.Functions:ResetSettings()
		WallHack.Functions:ResetSettings()
		Library.ResetAll()
	end
})

FunctionsSection:AddButton({
	Name = "Restart",
	Callback = function()
		Aimbot.Functions:Restart()
		WallHack.Functions:Restart()
	end
})

FunctionsSection:AddButton({
	Name = "Exit",
	Callback = Library.Unload,
})

FunctionsSection:AddButton({
	Name = "Copy Script Page",
	Callback = function()
		setclipboard("https://github.com/Exunys/AirHub")
	end
})

--// AirHub V2 Prompt

do
	local Aux = Instance.new("BindableFunction")
    
	Aux.OnInvoke = function(Answer)
		if Answer == "No" then
			return
		end

		Library.Unload()
		loadstring(game:HttpGet("https://raw.githubusercontent.com/Exunys/AirHub-V2/main/src/Main.lua"))()
	end

	game.StarterGui:SetCore("SendNotification", {
		Title = "🎆  AirHub V2  🎆",
		Text = "Would you like to use the new AirHub V2 script?",
		Button1 = "Yes",
		Button2 = "No",
		Duration = 1 / 0,
		Icon = "rbxassetid://6238537240",
		Callback = Aux
	})
end
