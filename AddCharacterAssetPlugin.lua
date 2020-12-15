local RunService = game:GetService("RunService")
local InsertService = game:GetService("InsertService")
local Selection = game:GetService("Selection")
local toolbar = plugin:CreateToolbar("Insert To Rig")

-- Create new 'DockWidgetPluginGuiInfo' object
local widgetInfo = DockWidgetPluginGuiInfo.new(
	Enum.InitialDockState.Left,  -- Widget will be initialized in floating panel
	true,   -- Widget will be initially enabled
	false,  -- Don't override the previous enabled state
	200,    -- Default width of the floating window
	300,    -- Default height of the floating window
	150,    -- Minimum width of the floating window (optional)
	110     -- Minimum height of the floating window (optional)
)
--
local pluginButton = toolbar:CreateButton("Add Asset", "Add assets to rigs in your game", "rbxassetid://963300406")
pluginButton.ClickableWhenViewportHidden = false
--
local main = {}

function main.new(self)
	self.uiObjects = {}
	self.interface = self:createInterface()
	
	self.selection = nil
	self.assetID = nil
	
	return self
end

function main:updateInterfaceTitle(selectionName, interface)
	interface = interface and interface or self.interface
	if (interface) then
		interface.Title = string.format("Insert - Rig %s", (selectionName and string.format("\"%s\"",selectionName)) or "None")
	end
end

function main:createInterface()
	local interface = plugin:CreateDockWidgetPluginGui("InsertAsset", widgetInfo)
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

function main:insertAsset(assetID)
	local lastSelection = self.selection
	if lastSelection and typeof(lastSelection) == "Instance" then
		local asset = InsertService:LoadAsset(assetID)
		if asset and #asset:GetChildren() > 0 then
			local extractedAsset
			if asset:FindFirstChildWhichIsA("Accessory") then
				extractedAsset = asset:FindFirstChildWhichIsA("Accessory")
				extractedAsset.Parent = lastSelection
			elseif asset:FindFirstChildWhichIsA("Decal") then
				extractedAsset = asset:FindFirstChildWhichIsA("Decal")
				if string.lower(extractedAsset.Name) == "face" then
					if self.Selection:FindFirstChild("Head") then
						extractedAsset.Parent = self.Selection:FindFirstChild("Head")
					end
				end
				--
			elseif asset:FindFirstChildWhichIsA("Shirt") or asset:FindFirstChildWhichIsA("Pants") then
				extractedAsset = (asset:FindFirstChildWhichIsA("Shirt") and asset:FindFirstChildWhichIsA("Shirt")) or (asset:FindFirstChildWhichIsA("Pants") and asset:FindFirstChildWhichIsA("Pants"))
				extractedAsset.Parent = lastSelection
			else
				warn("nothing found inside of asset")
			end
			extractedAsset = nil
		end
		if (asset) then
			asset:Destroy()
		end
	end
end

function main:addInsertConnection(button,textbox)
	button.MouseButton1Click:Connect(function()
		if tonumber(textbox.Text) then
			local assetID = tonumber(textbox.Text)
			self:insertAsset(assetID)
			textbox.Text = ""
			self.assetID = assetID
		end
	end)
end

function main:initialize()
	local insideFrame = self:createInstance("Frame",{
		BackgroundColor3 = Color3.new(0.180392, 0.180392, 0.180392);
		BorderSizePixel = 0;
		Size = UDim2.fromScale(1,1);
		ZIndex = -1;
		--
		Parent = self.interface
	})
	
	local borderSizePixel,buttonSize = 3,50
	local outsideFrame,assetIDBox
	do	
		outsideFrame = self:createInstance("Frame",{
			BackgroundColor3 = Color3.new(0.180392, 0.180392, 0.180392);
			BorderSizePixel = borderSizePixel;
			BorderColor3 = Color3.new(0.164706, 0.164706, 0.164706);
			BorderMode = Enum.BorderMode.Outline;
			
			Size = UDim2.new(1,0,0,50 + borderSizePixel);--UDim2.fromScale(1,.15);
			ZIndex = 1;
			--
			Parent = insideFrame
		})
		
		assetIDBox = self:createInstance("TextBox",{
			--BackgroundColor3 = Color3.new(0.180392, 0.180392, 0.180392);
			--BorderSizePixel = 1;
			BackgroundTransparency = 1;
			--
			Size = UDim2.fromScale(1,1);
			--
			ZIndex = 2;
			--
			Font = Enum.Font.Arial;
			TextScaled = true;
			TextSize = 24;
			
			Text = "";
			TextColor3 = Color3.new(0.670588, 0.670588, 0.670588);
			
			PlaceholderColor3 = Color3.new(0.505882, 0.505882, 0.505882);
			PlaceholderText = "AssetID";
			
			--
			Parent = outsideFrame
		})
	end
	
	do
		local outsideFrame = self:createInstance("Frame",{
			BackgroundColor3 = Color3.new(0.180392, 0.180392, 0.180392);
			BorderSizePixel = borderSizePixel;
			BorderColor3 = Color3.new(0.164706, 0.164706, 0.164706);
			BorderMode = Enum.BorderMode.Outline;
			
			AnchorPoint = Vector2.new(.5,0);
			Position = UDim2.new(.5,0,0,outsideFrame.Size.Y.Offset/2 + (buttonSize/2));

			Size = UDim2.new(1,0,0,50 + borderSizePixel);--UDim2.fromScale(1,.15);
			ZIndex = 1;
			--
			Parent = self.interface
		})
		local insertButton = self:createInstance("TextButton",{
			BackgroundColor3 = Color3.new(0.133333, 0.133333, 0.133333);
			--BorderSizePixel = 1;
			--BackgroundTransparency = 0;
			--
			AnchorPoint = Vector2.new(.5,0);
			Position = UDim2.fromScale(.5,0);
			Size = UDim2.fromScale(.5,1);
			--
			ZIndex = 2;
			--
			Font = Enum.Font.Arial;
			TextScaled = true;
			TextSize = 24;

			Text = "Add Asset";
			TextColor3 = Color3.new(0.670588, 0.670588, 0.670588);

			--
			Parent = outsideFrame
		})
		local uiCorner = self:createInstance("UICorner",{CornerRadius = UDim.new(.05,8)})
		uiCorner.Parent = insertButton
		
		self:addInsertConnection(insertButton,assetIDBox)
	end
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
			elseif object:FindFirstChild("HumanoidRootPart") then
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