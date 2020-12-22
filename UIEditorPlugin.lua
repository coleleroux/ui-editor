assert(plugin)

local RunService = game:GetService("RunService")
local InsertService = game:GetService("InsertService")
local Selection = game:GetService("Selection")
local toolbar = plugin:CreateToolbar("UI Editor")

local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local mouse = plugin:GetMouse()

-- Create new 'DockWidgetPluginGuiInfo' object
local widgetInfo = DockWidgetPluginGuiInfo.new(
	Enum.InitialDockState.Top,  -- Widget will be initialized in floating panel
	true,   -- Widget will be initially enabled
	false,  -- Don't override the previous enabled state
	200,    -- Default width of the floating window
	300,    -- Default height of the floating window
	150,    -- Minimum width of the floating window (optional)
	110     -- Minimum height of the floating window (optional)
)
--
local pluginButton = toolbar:CreateButton("Enable", "Enable this plugin", "rbxassetid://963300406")
pluginButton.ClickableWhenViewportHidden = true
--
local main = {}

function main.new(self)
	self.uiObjects = {}
	self.interface = self:createInterface()
	
	self.selection = nil
	self.assetID = nil
	
	self.canZoom = true
	self.minZoom,self.maxZoom = 50, 150
	self.defaultZoom = 100
	
	return self
end

function main:updateInterfaceTitle(selectionName, interface)
	interface = interface and interface or self.interface
	if (interface) then
		interface.Title = string.format("UIEditor - Selection %s", (selectionName and string.format("\"%s\"",selectionName)) or "None")
	end
end

function main:createInterface()
	local interface = plugin:CreateDockWidgetPluginGui("UIEditor", widgetInfo)
	self:updateInterfaceTitle(nil,interface)
	
	return interface
end

function main:objectsExist()
	return self.uiObjects
end

function main:addToObjects(instance)
	if (self:objectsExist()) then
		table.insert(self.uiObjects,instance)
	else
		warn("not added")
	end
end

function main:createInstance(instanceType, ...)
	local r = Instance.new(instanceType)
	for key,value in pairs(unpack{...})do
		if key == "Parent" then
			r.Parent = value
		elseif r[key] and value then
			r[key] = value
		end
	end
	--
	self:addToObjects(r)
	--
	return r
end

function main:createFromStarterGui()
	for _,uiScreen in pairs(game:GetService("StarterGui"):GetChildren())do
		if uiScreen:IsA("ScreenGui")then
			uiScreen = uiScreen:Clone()
			--uiScreen.Parent = self.interface
			local last
			local function recurseMake(element: Instance): Instance
				last = element
				for i,v in pairs(element:GetChildren())do
					v.Parent = last.Parent
					if v:IsA("GuiObject") and #v:GetChildren() > 0 then
						v.MouseEnter:Connect(function()
							print("entered")
						end)
						return recurseMake(element)
					end
				end
			end
			
			uiScreen.Parent = self.interface
			recurseMake(uiScreen)
			uiScreen:Destroy()
		end
	end	
end

function main:initialize()
	local maxSize = 1000000
	self.gridImage = self:createInstance("ImageLabel",{
		AnchorPoint = Vector2.new(0,0);
		BackgroundColor3 = Color3.new(0.180392, 0.180392, 0.180392);
		BorderSizePixel = 0;
		Position = UDim2.new(.5,-maxSize/2,.5,-maxSize/2);
		Size = UDim2.fromOffset(maxSize,maxSize);
		ZIndex = -10000;
		--
		Image = "rbxassetid://6104495091";
		ImageColor3 = Color3.fromRGB(77, 77, 77);
		
		ScaleType = Enum.ScaleType.Tile;
		TileSize = UDim2.fromOffset(self.defaultZoom,self.defaultZoom);
		--
		Parent = self.interface
	})
	--
	self:enableGridFunctions(self.gridImage, false)
	
	-- create current startergui uis
	self:createFromStarterGui()
end

function main:makeSelectionBasedOnLayer()
	
end

function main:enableGridFunctions(gridImage, constraint)
	if not gridImage then warn("gridImage not found") return false end
	local holdingDown, dragStart, startPos, dragInput
	local function update(input)
		local delta = input.Position - dragStart
		gridImage.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
	end

	gridImage.InputBegan:Connect(function(input)
		if (input.UserInputType == Enum.UserInputType.MouseButton1) or (input.UserInputType == Enum.UserInputType.Touch) then
			self:makeSelectionBasedOnLayer()
			
			holdingDown = true
			dragStart = input.Position
			startPos = gridImage.Position
			
			local inputEvent
			inputEvent = gridImage.InputChanged:Connect(function(input) -- may encounter issues.
				if input == dragInput then
					if holdingDown then
						update(input)
					else
						inputEvent:Disconnect()
					end
				end
			end)
		end
	end)

	gridImage.InputChanged:Connect(function(input)
		--if input.UserInputType == Enum.UserInputType.MouseMovement then
		--	local GUIs = self.interface:GetGuiObjectsAtPosition(input.Position.X, input.Position.Y)
		--	for _,guiObject in pairs(GUIs)do
		--		print(guiObject)
		--	end
		--end
		if ((input.UserInputType == Enum.UserInputType.MouseMovement) or (input.UserInputType == Enum.UserInputType.Touch)) then
			dragInput = input
		end
	end)

	gridImage.InputEnded:Connect(function(input)
		if (input.UserInputType == Enum.UserInputType.MouseButton1) or (input.UserInputType == Enum.UserInputType.Touch) then
			holdingDown = false
			gridImage.Position = constraint and startPos or gridImage.Position
		end
	end)
	
	--
	local zoomTween
	
	local function calculateZoom(increment)
		if not gridImage then return false end
		increment = increment and increment or 0
		return math.clamp(((gridImage.TileSize.X.Offset+gridImage.TileSize.Y.Offset)/2) + increment, self.minZoom, self.maxZoom)
	end
	
	
	gridImage.MouseWheelBackward:Connect(function()
		if self.canZoom then
			local newZoom = calculateZoom(-5)
			if (zoomTween) then
				zoomTween:Cancel()
			end
			zoomTween = TweenService:Create(gridImage, TweenInfo.new(.3, Enum.EasingStyle.Quint), {TileSize = UDim2.fromOffset(newZoom,newZoom)})
			zoomTween:Play()
			--gridImage.TileSize = UDim2.fromOffset(newZoom,newZoom);
		end	
	end)

	gridImage.MouseWheelForward:Connect(function()
		if self.canZoom then
			local newZoom = calculateZoom(15)
			if (zoomTween) then
				zoomTween:Cancel()
			end
			zoomTween = TweenService:Create(gridImage, TweenInfo.new(.3, Enum.EasingStyle.Quint), {TileSize = UDim2.fromOffset(newZoom,newZoom)})
			zoomTween:Play()
			print(newZoom)
			--gridImage.TileSize = UDim2.fromOffset(newZoom,newZoom);
		end
	end)
end

local widget = main.new(main)
widget.initialize(main)

--warn(activelyViewButton,typeof(activelyViewButton),activelyViewButton.ClassName)
--if activelyViewButton:FindFirstChild("Image") then
--	print("ya hooo")
--end
--rbxassetid://5755112243 -- checkmark
--rbxassetid://5755112316 -- close/exit

local function onButtonClick()
	if not false then
		--
		local selectedObject = Selection:Get()
		--print(selectedObject,type(selectedObject),type(selectedObject)=="table" and #selectedObject or "")
		if selectedObject then
			selectedObject = selectedObject[1]
		end
		
		if typeof(selectedObject) == "Instance" then
			local targetPath = selectedObject:IsA("Model") and selectedObject.PrimaryPart or selectedObject
			
		end
		
		
		widget.interface.Enabled = true
	else
		
	end
end

-- runs everytime studio selection changes
Selection.SelectionChanged:Connect(function()
	local selectedObject = Selection:Get()
	--print(selectedObject,type(selectedObject),type(selectedObject)=="table" and #selectedObject or "")
	if selectedObject then
		for index,object in pairs(selectedObject)do
			if not object then
				continue
			elseif object:IsA("GuiObject") then
				selectedObject = object;
				break
			end
		end
	end

	if selectedObject and typeof(selectedObject) == "Instance" then
		widget.selection = selectedObject
	else
		widget.selection = nil
	end
	
	widget:updateInterfaceTitle(selectedObject and selectedObject.Name,false)
end)

pluginButton.Click:Connect(onButtonClick)