--// Invisible LocalScript (Up 500 - Zero Flicker & Smooth)

if _G.InvisConnections then
	for _,v in pairs(_G.InvisConnections) do
		if v then
			v:Disconnect()
		end
	end
end

pcall(function()
	game:GetService("RunService"):UnbindFromRenderStep("InvisSnapDown")
end)

_G.InvisConnections = {}

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UIS = game:GetService("UserInputService")

local Player = Players.LocalPlayer
local Character
local Humanoid
local RootPart

local Invisible = false
local isUp = false
local BodyParts = {}

--// Чистый сброс старых оффсетов камеры
if Player.Character and Player.Character:FindFirstChild("Humanoid") then
	Player.Character.Humanoid.CameraOffset = Vector3.new(0, 0, 0)
end

--// Возврат полной видимости
local function ResetTransparency()
	for _,v in pairs(BodyParts) do
		if v and v.Parent then
			v.LocalTransparencyModifier = 0
		end
	end
end

--// Получение персонажа
local function SetupCharacter()
	Character = Player.Character or Player.CharacterAdded:Wait()
	Humanoid = Character:WaitForChild("Humanoid")
	RootPart = Character:WaitForChild("HumanoidRootPart")

	Humanoid.CameraOffset = Vector3.new(0, 0, 0)

	table.clear(BodyParts)

	for _,v in pairs(Character:GetDescendants()) do
		if v:IsA("BasePart") and v.Name ~= "HumanoidRootPart" then
			table.insert(BodyParts, v)
			v.LocalTransparencyModifier = 0
		end
	end

	Character.DescendantAdded:Connect(function(v)
		if v:IsA("BasePart") and v.Name ~= "HumanoidRootPart" then
			table.insert(BodyParts, v)
			if not Invisible then
				v.LocalTransparencyModifier = 0
			end
		end
	end)

	-- Сброс при смерти
	Humanoid.Died:Connect(function()
		Invisible = false
		if isUp and RootPart and RootPart.Parent then
			RootPart.CFrame = RootPart.CFrame - Vector3.new(0, 500, 0)
			isUp = false
		end
		ResetTransparency()
	end)
end

--// Инвиз
local function ToggleInvisible()
	Invisible = not Invisible

	if not Invisible then
		if isUp and RootPart and RootPart.Parent then
			RootPart.CFrame = RootPart.CFrame - Vector3.new(0, 500, 0)
			isUp = false
		end
		ResetTransparency()
	end
end

--// GUI
local function CreateGui()

	local gui = Instance.new("ScreenGui")
	gui.Name = "InvisibleGui"
	gui.ResetOnSpawn = false

	local button = Instance.new("TextButton")
	button.Size = UDim2.new(0,100,0,50)
	button.Position = UDim2.new(0.5,-50,0.1,0)

	button.Text = "Invisible"
	button.BackgroundColor3 = Color3.fromRGB(255,0,0)
	button.TextColor3 = Color3.new(1,1,1)

	button.Parent = gui
	gui.Parent = Player:WaitForChild("PlayerGui")

	-- Drag с защитой от случайных свайпов и мультитача
	local dragging = false
	local activeTouch = nil
	local dragStart
	local startPos
	local dragged = false

	button.InputBegan:Connect(function(input)
		if (input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch) and not dragging then
			dragging = true
			dragged = false
			activeTouch = input
			dragStart = input.Position
			startPos = button.Position
		end
	end)

	UIS.InputChanged:Connect(function(input)
		if dragging and input == activeTouch then
			local delta = input.Position - dragStart

			if delta.Magnitude > 7 then
				dragged = true
			end

			button.Position = UDim2.new(
				startPos.X.Scale,
				startPos.X.Offset + delta.X,
				startPos.Y.Scale,
				startPos.Y.Offset + delta.Y
			)
		end
	end)

	UIS.InputEnded:Connect(function(input)
		if input == activeTouch then
			dragging = false
			activeTouch = nil
		end
	end)

	button.MouseButton1Click:Connect(function()
		if not dragged then
			ToggleInvisible()
		end
	end)
end

--// Инициализация
SetupCharacter()
CreateGui()

--// Клавиша G для ПК
table.insert(_G.InvisConnections,
	UIS.InputBegan:Connect(function(input, gp)
		if gp then return end
		if input.KeyCode == Enum.KeyCode.G then
			ToggleInvisible()
		end
	end)
)

--// 1. Возврат на землю ДО того, как камера и экран начнут рисовать кадр (нет вспышек неба)
RunService:BindToRenderStep("InvisSnapDown", Enum.RenderPriority.Camera.Value - 1, function()
	if isUp and RootPart and RootPart.Parent then
		RootPart.CFrame = RootPart.CFrame - Vector3.new(0, 500, 0)
		isUp = false
	end

	if Invisible and Humanoid and Humanoid.Health > 0 then
		for _,v in pairs(BodyParts) do
			if v and v.Parent then
				v.LocalTransparencyModifier = 0.5
			end
		end
	end
end)

--// 2. Поднятие на 500 для сервера сразу после расчета физики
table.insert(_G.InvisConnections,
	RunService.Heartbeat:Connect(function()
		if Invisible and RootPart and RootPart.Parent and Humanoid and Humanoid.Health > 0 then
			if not isUp then
				RootPart.CFrame = RootPart.CFrame + Vector3.new(0, 500, 0)
				isUp = true
			end
		end
	end)
)

--// Респавн
table.insert(_G.InvisConnections,
	Player.CharacterAdded:Connect(function()
		Invisible = false
		isUp = false
		task.wait(0.5)
		SetupCharacter()
		ResetTransparency()
	end)
)
