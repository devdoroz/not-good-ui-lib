local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")

local IS_STUDIO = RunService:IsStudio()
local Player = Players.LocalPlayer

local Lib = {}; Lib.__index = Lib
local Objects = game:GetObjects("rbxassetid://18437241213")[1]

local Category = {}; do
	Category.__index = Category
	
	function Category.new()
		local self = setmetatable({}, Category)
		self.Frame = Objects.Contents:Clone()
		return self
	end
	
	function Category:CreateToggle(name, default, callback)
		local object = Objects.Toggle:Clone()
		object.Text = name.." ["..(default and "X" or " ").."]"
		object.Parent = self.Frame
		
		local dataTable = {
			Value = default,
		}
		
		dataTable.Update = function(v)
			dataTable.Value = v
			object.Text = name.." ["..(v and "X" or " ").."]"
			(callback or function() end)(v)
		end
		
		object.MouseButton1Click:Connect(function()
			dataTable.Update(not dataTable.Value)
		end)
		
		return dataTable
	end
	
	function Category:CreateDropdown(name, default, range, callback)
		local object = Objects.Dropdown:Clone()
		object.Title.Text = name
		object.Parent = self.Frame
		
		local dataTable = {
			Value = default
		}
		
		dataTable.Update = function(v)
			local index = table.find(range, v)
			dataTable.Value = v
			object.Arrow.Position = UDim2.new(0, -24 + (77 * index), 0, 40);
			(callback or function() end)(v)
		end
		
		for index, value in ipairs(range) do
			local dropdownObj = Objects.DropdownButton:Clone()
			dropdownObj.Text = value
			dropdownObj.Parent = object.Frame
			dropdownObj.MouseButton1Click:Connect(function()
				dataTable.Update(value)
			end)
		end
		
		return dataTable
	end
	
	function Category:CreateSlider(name, default, min, max, callback)
		local object = Objects.Slider:Clone()
		object.Text = name.." ("..default..")"
		object.Parent = self.Frame
		
		local dataTable = {
			Value = default
		}
		
		local range = {min, max}
		local rangeMin = range[1]
		local rangeMax = range[2]
		
		dataTable.Update = function(v)
			local percentage = (v - range[1]) / (range[2] - range[1])
			dataTable.Value = v
			object.Text = name.." ("..(math.round(v * 10) / 10)..")"
			object.Frame.Bar.Size = UDim2.new(percentage, 0, 1, 0)
		end
		
		local dragging = false
		
		UserInputService.InputChanged:Connect(function(input)
			if dragging then
				local mousePos = UserInputService:GetMouseLocation()
				local mouseX, mouseY = mousePos.X, mousePos.Y
				local boundaries0 = object.Frame.AbsolutePosition.X 
				local boundaries1 = object.Frame.AbsolutePosition.X + object.Frame.AbsoluteSize.X
				local at = mouseX - boundaries0
				local goal = boundaries1 - boundaries0
				local percentage = math.clamp(at / goal, 0, 1)
				dataTable.Update(rangeMin + ((rangeMax - rangeMin) * percentage))	
			end
		end)

		object.Frame.InputBegan:Connect(function(input)
			if input.UserInputType == Enum.UserInputType.MouseButton1 then
				dragging = true
				local e; e = input.Changed:Connect(function()
					if input.UserInputState == Enum.UserInputState.End then
						dragging = false
						e:Disconnect()
					end
				end)
			end
		end)
		
		return dataTable
	end
end

function Lib:CreateCategory(name)
	local nwCategory = Category.new(name)
	self.Categories[name] = nwCategory.Frame
	
	local button = Objects.CategoryButton:Clone()
	button.Text = " "..name
	button.Parent = self.UI.Frame.Categories
	button.MouseButton1Click:Connect(function()
		if self.UI.Frame.Contents:FindFirstChildWhichIsA("Frame") then
			self.UI.Frame.Contents:FindFirstChildWhichIsA("Frame").Parent = nil
		end
		
		self.Categories[name].Parent = self.UI.Frame.Contents
	end)
	
	return nwCategory
end

function Lib:Create(name)
	local self = setmetatable({}, Lib)
	self.UI = Objects.HHWare:Clone()
	self.Categories = {}
	self.UI.Frame.Title.Text = name
	return self
end

function Lib:Init()
	self.UI.Parent = (gethui and gethui()) or (IS_STUDIO and Player.PlayerGui or game:GetService("CoreGui"))
	
	do
		local gui = self.UI.Frame

		local dragging
		local dragInput
		local dragStart
		local startPos

		local function update(input)
			local delta = input.Position - dragStart
			gui.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
		end

		gui.InputBegan:Connect(function(input)
			if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
				dragging = true
				dragStart = input.Position
				startPos = gui.Position

				input.Changed:Connect(function()
					if input.UserInputState == Enum.UserInputState.End then
						dragging = false
					end
				end)
			end
		end)

		gui.InputChanged:Connect(function(input)
			if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
				dragInput = input
			end
		end)

		UserInputService.InputChanged:Connect(function(input)
			if input == dragInput and dragging then
				update(input)
			end
		end)
	end
end

return Lib
