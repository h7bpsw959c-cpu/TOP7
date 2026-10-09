--// ==========================================
--//                 TOP7 HUB                 
--// ==========================================

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local StarterPack = game:GetService("StarterPack")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Camera = workspace.CurrentCamera
local LocalPlayer = Players.LocalPlayer

-- التحقق من المعرفات المسموحة
local AllowedUserIDs = {
    [9660032322] = true,
    [9680871870] = true,
    [7909497107] = true,
    [9443560044] = true,
    [10983064661] = true,
    [9034198439] = true,
    [9886939282] = true,
    [9090000346] = true,
    [2041444475] = true,
    [9435614564] = true,
    [9835423112] = true,
    [9781601906] = true,
    [3691056715] = true,
    [9444790877] = true,
}

local function CheckUserID()
    local userId = LocalPlayer.UserId
    if AllowedUserIDs[userId] then
        return true
    else
        return false
    end
end

-- === CONFIGURATION ===
local espInventoryEnabled = true 
local MAX_DISTANCE = 2000 
local UPDATE_INTERVAL = 1 
local BillboardCache = {}
local nameCache = {} 

local RARITY_COLORS = {
    ["Common"] = Color3.fromRGB(255, 255, 255),
    ["Uncommon"] = Color3.fromRGB(99, 255, 52),
    ["Rare"] = Color3.fromRGB(51, 170, 255),
    ["Epic"] = Color3.fromRGB(237, 44, 255),
    ["Legendary"] = Color3.fromRGB(255, 150, 0),
    ["Omega"] = Color3.fromRGB(255, 20, 51),
}

local function getRealName(t)
    if not t or not t.Name then return nil end
    local originalName = t.Name
    local lowerName = originalName:lower()

    local cleaned = lowerName
        :gsub("%d+$", "")
        :gsub("_%d+$", "")
        :gsub("%s*%d+%s*$", "")
        :gsub("[%s_]+", " ")
        :gsub("([^%w%s])", "")
        :match("^%s*(.-)%s*$")

    if nameCache[originalName] then 
        return nameCache[originalName] 
    end
    
    local h = t:FindFirstChild("Handle")
    local fallbackName = cleaned
    
    for _, folder in ipairs({ReplicatedStorage:FindFirstChild("Items"), StarterPack}) do
        if folder then
            for _, item in ipairs(folder:GetDescendants()) do
                if item:IsA("Tool") and item:FindFirstChild("Handle") then
                    local match = true
                    if h then
                        for _, c in ipairs(h:GetChildren()) do
                            if not item.Handle:FindFirstChild(c.Name) then 
                                match = false 
                                break 
                            end
                        end
                    else
                        match = false
                    end
                    if match then 
                        nameCache[originalName] = item.Name 
                        return item.Name 
                    end
                end
            end
        end
    end
    
    nameCache[originalName] = fallbackName
    return fallbackName
end

local function updateESP(p)
    local bb = BillboardCache[p]
    if not bb then return end
    
    local char = p.Character
    if not char or not char:FindFirstChild("HumanoidRootPart") then 
        bb.Enabled = false
        return 
    end
    
    local lChar = LocalPlayer.Character
    if lChar and lChar:FindFirstChild("HumanoidRootPart") then
        local dist = (lChar.HumanoidRootPart.Position - char.HumanoidRootPart.Position).Magnitude
        if dist > MAX_DISTANCE then
            bb.Enabled = false
            return
        end
    end

    local container = bb:FindFirstChild("EspContainer")
    if not container then return end
    container:ClearAllChildren()

    local layout = Instance.new("UIListLayout", container)
    layout.HorizontalAlignment = Enum.HorizontalAlignment.Center
    layout.VerticalAlignment = Enum.VerticalAlignment.Bottom 
    layout.Padding = UDim.new(0, 2)

    local tools = {}
    if p:FindFirstChild("Backpack") then
        for _, t in ipairs(p.Backpack:GetChildren()) do
            if t:IsA("Tool") and t.Name:lower() ~= "fists" then table.insert(tools, t) end
        end
    end
    if char then
        for _, t in ipairs(char:GetChildren()) do
            if t:IsA("Tool") and t.Name:lower() ~= "fists" then table.insert(tools, t) end
        end
    end

    bb.Enabled = espInventoryEnabled and (#tools > 0)
    
    for _, tool in ipairs(tools) do
        local name = getRealName(tool)
        if name then
            local lbl = Instance.new("TextLabel", container)
            lbl.Size = UDim2.new(0, 180, 0, 14)
            lbl.BackgroundTransparency = 1
            lbl.Text = name
            lbl.Font = Enum.Font.SourceSansBold
            lbl.TextSize = 11
            lbl.TextStrokeTransparency = 0.4
            
            local rarity = tool:GetAttribute("RarityName") or tool:GetAttribute("Rarity")
            lbl.TextColor3 = RARITY_COLORS[rarity] or Color3.new(1, 1, 1)
        end
    end
end

local function createESP(p)
    if p == LocalPlayer then return end
    
    local function setup(char)
        local root = char:WaitForChild("HumanoidRootPart", 15)
        if not root then return end
        
        if BillboardCache[p] then BillboardCache[p]:Destroy() end
        
        local bb = Instance.new("BillboardGui", root)
        bb.Name = "FixedUnderfootESP"
        bb.Size = UDim2.new(0, 200, 0, 150)
        bb.StudsOffset = Vector3.new(0, -3.5, 0) 
        bb.AlwaysOnTop = true
        bb.MaxDistance = MAX_DISTANCE
        
        local cont = Instance.new("Frame", bb)
        cont.Name = "EspContainer"
        cont.Size = UDim2.new(1, 0, 1, 0)
        cont.BackgroundTransparency = 1
        
        BillboardCache[p] = bb
        updateESP(p)
        
        char.ChildAdded:Connect(function(child)
            if child:IsA("Tool") then task.wait(0.1); updateESP(p) end
        end)
        char.ChildRemoved:Connect(function(child)
            if child:IsA("Tool") then task.wait(0.1); updateESP(p) end
        end)
        
        local backpack = p:WaitForChild("Backpack", 5)
        if backpack then
            backpack.ChildAdded:Connect(function() updateESP(p) end)
            backpack.ChildRemoved:Connect(function() updateESP(p) end)
        end

        task.spawn(function()
            while char.Parent and bb.Parent do
                updateESP(p)
                task.wait(UPDATE_INTERVAL)
            end
        end)
    end
    
    p.CharacterAdded:Connect(setup)
    if p.Character then setup(p.Character) end
end

for _, p in ipairs(Players:GetPlayers()) do createESP(p) end
Players.PlayerAdded:Connect(createESP)

-- === INTERFACE (TOP7 & Blue Theme) ===
local ScreenGui = Instance.new("ScreenGui", game.CoreGui)
ScreenGui.Name = "TOP7_Hub"
ScreenGui.IgnoreGuiInset = true
ScreenGui.ResetOnSpawn = false

-- شعار TOP7 أعلى الشاشة
local Top7Header = Instance.new("TextLabel", ScreenGui)
Top7Header.Size = UDim2.new(0, 150, 0, 35)
Top7Header.Position = UDim2.new(0.5, -75, 0.01, 0)
Top7Header.BackgroundColor3 = Color3.fromRGB(20, 30, 55)
Top7Header.Text = "TOP7"
Top7Header.TextColor3 = Color3.fromRGB(255, 255, 255)
Top7Header.TextScaled = true
Top7Header.Font = Enum.Font.SourceSansBold
Instance.new("UICorner", Top7Header).CornerRadius = UDim.new(0, 8)

-- زر الفتح والإغلاق العائم (ToggleButton)
local ToggleButton = Instance.new("TextButton", ScreenGui)
ToggleButton.Size = UDim2.new(0, 100, 0, 40)
ToggleButton.Position = UDim2.new(0.9, 0, 0.05, 0)
ToggleButton.BackgroundColor3 = Color3.fromRGB(41, 128, 185)
ToggleButton.Text = "Open TOP7"
ToggleButton.TextColor3 = Color3.fromRGB(255, 255, 255)
ToggleButton.TextScaled = true
Instance.new("UICorner", ToggleButton).CornerRadius = UDim.new(0, 8)
ToggleButton.Visible = true

local ToggleDrag = Instance.new("Frame", ToggleButton)
ToggleDrag.Size = UDim2.new(1, 0, 1, 0)
ToggleDrag.BackgroundTransparency = 1

local MainFrame = Instance.new("Frame", ScreenGui)
MainFrame.Size = UDim2.new(0.4, 0, 0.65, 0)
MainFrame.Position = UDim2.new(0.3, 0, 0.18, 0)
MainFrame.BackgroundColor3 = Color3.fromRGB(25, 35, 60)
MainFrame.BorderSizePixel = 0
MainFrame.Visible = false
Instance.new("UICorner", MainFrame).CornerRadius = UDim.new(0, 8)

local ProtectedLabel = Instance.new("TextLabel", MainFrame)
ProtectedLabel.Size = UDim2.new(0.8,0,0.08,0)
ProtectedLabel.Position = UDim2.new(0.1,0,0.02,0)
ProtectedLabel.BackgroundTransparency = 1
ProtectedLabel.Text = "TOP7 - FRIENDS"
ProtectedLabel.TextColor3 = Color3.fromRGB(0,255,255)
ProtectedLabel.TextScaled = true
ProtectedLabel.Font = Enum.Font.SourceSansBold

local MainDrag = Instance.new("Frame", MainFrame)
MainDrag.Size = UDim2.new(1,0,0.1,0)
MainDrag.BackgroundTransparency = 1

-- الأزرار والقوائم
local ESPInventoryToggle = Instance.new("TextButton", MainFrame)
ESPInventoryToggle.Size = UDim2.new(0.8,0,0.09,0)
ESPInventoryToggle.Position = UDim2.new(0.1,0,0.11,0)
ESPInventoryToggle.BackgroundColor3 = Color3.fromRGB(0,255,0)
ESPInventoryToggle.Text = "كشف لوت: ON"
ESPInventoryToggle.TextScaled = true
Instance.new("UICorner", ESPInventoryToggle).CornerRadius = UDim.new(0,8)

local ESPToggle = Instance.new("TextButton", MainFrame)
ESPToggle.Size = UDim2.new(0.8,0,0.09,0)
ESPToggle.Position = UDim2.new(0.1,0,0.21,0)
ESPToggle.BackgroundColor3 = Color3.fromRGB(255,0,0)
ESPToggle.Text = "كشف أشخاص + الأسماء: OFF"
ESPToggle.TextScaled = true
Instance.new("UICorner", ESPToggle).CornerRadius = UDim.new(0,8)

local AimbotToggle = Instance.new("TextButton", MainFrame)
AimbotToggle.Size = UDim2.new(0.8,0,0.09,0)
AimbotToggle.Position = UDim2.new(0.1,0,0.31,0)
AimbotToggle.BackgroundColor3 = Color3.fromRGB(255,0,0)
AimbotToggle.Text = "إيم بوت (أيم لوك): قفل"
AimbotToggle.TextScaled = true
Instance.new("UICorner", AimbotToggle).CornerRadius = UDim.new(0,8)

local WallcheckToggle = Instance.new("TextButton", MainFrame)
WallcheckToggle.Size = UDim2.new(0.8,0,0.09,0)
WallcheckToggle.Position = UDim2.new(0.1,0,0.41,0)
WallcheckToggle.BackgroundColor3 = Color3.fromRGB(0,255,0)
WallcheckToggle.Text = "Wallcheck: قفل"
WallcheckToggle.TextScaled = true
WallcheckToggle.TextColor3 = Color3.new(1,1,1)
Instance.new("UICorner", WallcheckToggle).CornerRadius = UDim.new(0,8)

local FOVSlider = Instance.new("TextBox", MainFrame)
FOVSlider.Size = UDim2.new(0.8,0,0.09,0)
FOVSlider.Position = UDim2.new(0.1,0,0.51,0)
FOVSlider.BackgroundColor3 = Color3.fromRGB(41, 128, 185)
FOVSlider.Text = "FOV: 110"
FOVSlider.TextColor3 = Color3.fromRGB(255,255,255)
FOVSlider.TextScaled = true
Instance.new("UICorner", FOVSlider).CornerRadius = UDim.new(0,8)

local AimPartToggle = Instance.new("TextButton", MainFrame)
AimPartToggle.Size = UDim2.new(0.8,0,0.09,0)
AimPartToggle.Position = UDim2.new(0.1,0,0.61,0)
AimPartToggle.BackgroundColor3 = Color3.fromRGB(52, 152, 219)
AimPartToggle.Text = "منطقة الإيم: رأس / بطن (سويتش)"
AimPartToggle.TextScaled = true
AimPartToggle.TextColor3 = Color3.new(1,1,1)
Instance.new("UICorner", AimPartToggle).CornerRadius = UDim.new(0,8)

-- زر نسخ رابط السيرفر
local ServerCopyBtn = Instance.new("TextButton", MainFrame)
ServerCopyBtn.Size = UDim2.new(0.8,0,0.09,0)
ServerCopyBtn.Position = UDim2.new(0.1,0,0.71,0)
ServerCopyBtn.BackgroundColor3 = Color3.fromRGB(39, 174, 96)
ServerCopyBtn.Text = "نسخ رابط السيرفر 📋"
ServerCopyBtn.TextScaled = true
ServerCopyBtn.TextColor3 = Color3.new(1,1,1)
Instance.new("UICorner", ServerCopyBtn).CornerRadius = UDim.new(0,8)

ServerCopyBtn.MouseButton1Click:Connect(function()
    local discordLink = "https://discord.gg/top7"
    if setclipboard then
        setclipboard(discordLink)
        ServerCopyBtn.Text = "تم النسخ بنجاح! ✅"
        task.wait(1.5)
        ServerCopyBtn.Text = "نسخ رابط السيرفر 📋"
    end
end)

local PlayerListFrame = Instance.new("ScrollingFrame", MainFrame)
PlayerListFrame.Size = UDim2.new(0.8,0,0.18,0)
PlayerListFrame.Position = UDim2.new(0.1,0,0.81,0)
PlayerListFrame.BackgroundColor3 = Color3.fromRGB(15, 25, 45)
PlayerListFrame.ScrollBarThickness = 6
PlayerListFrame.AutomaticCanvasSize = Enum.AutomaticSize.Y
Instance.new("UICorner", PlayerListFrame).CornerRadius = UDim.new(0,8)

local PlayerListLayout = Instance.new("UIListLayout", PlayerListFrame)
PlayerListLayout.Padding = UDim.new(0,4)

-- المتغيرات الأساسية للتحكم
local espEnabledStatus = false
local AimbotOn = false
local FOVRadius = 140
local WallCheckEnabled = true
local FOVCircleVisible = true
local FOVCircleForcedOff = false
local ProtectedPlayers = {}
local PlayerButtons = {}
local AIM_SMOOTHNESS = 0.8
local PREDICTION_TIME = 0.03
local guiOpen = false

local FOVCircle = Drawing.new("Circle")
FOVCircle.Radius = FOVRadius
FOVCircle.Thickness = 2
FOVCircle.Color = Color3.fromRGB(0, 150, 255)
FOVCircle.Transparency = 0.6
FOVCircle.Filled = false
FOVCircle.Visible = false

-- خيارات الإيم (وضع السويتش التلقائي بين الرأس والبطن)
local AIM_MODES = {
    {name = "الرأس فقط (Head)", parts = {"Head"}, color = Color3.fromRGB(52, 152, 219)},
    {name = "البطن فقط (Torso)", parts = {"HumanoidRootPart"}, color = Color3.fromRGB(41, 128, 185)},
    {name = "سويتش: بطن ⇄ رأس 🔄", parts = {"HumanoidRootPart", "Head"}, color = Color3.fromRGB(155, 89, 182)}
}
local currentModeIndex = 3 -- يبدأ بوضع السويتش افتراضياً
local currentAutoIndex = 1
local lastSwitchTime = 0
local SWITCH_INTERVAL = 0.6 -- سرعة التبديل بين البطن والرأس

local function IsAlive(char)
    local h = char and char:FindFirstChildOfClass("Humanoid")
    return h and h.Health > 0
end

local function IsVisible(part)
    if not part then return false end
    local origin = Camera.CFrame.Position
    local direction = (part.Position - origin)
    local params = RaycastParams.new()
    params.FilterType = Enum.RaycastFilterType.Blacklist
    params.FilterDescendantsInstances = {LocalPlayer.Character or workspace, part.Parent}
    local result = workspace:Raycast(origin, direction, params)
    return not result
end

local function removeESP(char)
    if char then
        local head = char:FindFirstChild("Head")
        if head then 
            local b = head:FindFirstChild("AnouarNameHP") 
            if b then b:Destroy() end 
        end
        local h = char:FindFirstChild("AnouarHighlight") 
        if h then h:Destroy() end
    end
end

local function applyESP(char)
    local plr = Players:GetPlayerFromCharacter(char)
    if not plr or plr == LocalPlayer then return end
    removeESP(char)

    local head = char:FindFirstChild("Head")
    local hum = char:FindFirstChildOfClass("Humanoid")
    if not head or not hum or not IsAlive(char) then return end

    local bill = Instance.new("BillboardGui", head)
    bill.Name = "AnouarNameHP"
    bill.Adornee = head
    bill.Size = UDim2.new(0,160,0,35)
    bill.StudsOffset = Vector3.new(0,2.8,0)
    bill.AlwaysOnTop = true

    local name = Instance.new("TextLabel", bill)
    name.Size = UDim2.new(1,0,0,16)
    name.BackgroundTransparency = 1
    name.Text = plr.DisplayName ~= plr.Name and (plr.DisplayName .. " (@" .. plr.Name .. ")") or plr.Name
    name.TextColor3 = Color3.fromRGB(255,255,255)
    name.TextStrokeTransparency = 0
    name.Font = Enum.Font.SourceSansBold
    name.TextSize = 14

    local hl = Instance.new("Highlight", char)
    hl.Name = "AnouarHighlight"
    hl.OutlineColor = Color3.fromRGB(0, 150, 255)
    hl.OutlineTransparency = 0
    hl.FillTransparency = 1
end

local function onCharAdded(char)
    local plr = Players:GetPlayerFromCharacter(char)
    if not plr or plr == LocalPlayer then return end
    task.delay(0.6, function()
        removeESP(char)
        if espEnabledStatus then applyESP(char) end
    end)
end

for _, p in Players:GetPlayers() do
    if p ~= LocalPlayer then
        p.CharacterAdded:Connect(onCharAdded)
        if p.Character then onCharAdded(p.Character) end
    end
end
Players.PlayerAdded:Connect(function(p)
    if p ~= LocalPlayer then
        p.CharacterAdded:Connect(onCharAdded)
        if p.Character then onCharAdded(p.Character) end
    end
end)

local function UpdateProtectedList()
    for _, b in pairs(PlayerButtons) do b:Destroy() end
    PlayerButtons = {}
    local currentPlayers = Players:GetPlayers()
    table.sort(currentPlayers, function(a, b) return a.Name < b.Name end)
    
    for _, p in ipairs(currentPlayers) do
        if p ~= LocalPlayer then
            local btn = Instance.new("TextButton", PlayerListFrame)
            btn.Size = UDim2.new(1,-10,0,30)
            local prot = ProtectedPlayers[p] or false
            btn.BackgroundColor3 = prot and Color3.fromRGB(0,150,255) or Color3.fromRGB(40,50,70)
            btn.Text = p.DisplayName .. " (@" .. p.Name .. ")" .. (prot and " (أخويان ✔)" or "")
            btn.TextColor3 = Color3.new(1,1,1)
            btn.TextScaled = true
            Instance.new("UICorner", btn).CornerRadius = UDim.new(0,6)
            table.insert(PlayerButtons, btn)

            btn.MouseButton1Click:Connect(function()
                ProtectedPlayers[p] = not ProtectedPlayers[p]
                UpdateProtectedList()
            end)
        end
    end
end

Players.PlayerAdded:Connect(UpdateProtectedList)
Players.PlayerRemoving:Connect(UpdateProtectedList)
UpdateProtectedList()

local function GetTargetPart(char)
    local mode = AIM_MODES[currentModeIndex]
    local partName = mode.parts[currentAutoIndex]
    local part = char:FindFirstChild(partName)
    return part or char:FindFirstChild("Head") or char:FindFirstChild("HumanoidRootPart")
end

local function GetPredictedPosition(char)
    local part = GetTargetPart(char)
    if not part then return nil end
    local root = char:FindFirstChild("HumanoidRootPart")
    if not root then return part.Position end
    return part.Position + (root.Velocity * PREDICTION_TIME)
end

local function GetClosest()
    local closest, distMin = nil, math.huge
    local center = Camera.ViewportSize / 2
    for _, p in pairs(Players:GetPlayers()) do
        if p ~= LocalPlayer and not ProtectedPlayers[p] and p.Character and IsAlive(p.Character) then
            local part = GetTargetPart(p.Character)
            if part then
                local predictedPos = GetPredictedPosition(p.Character) or part.Position
                local screenPos, onScreen = Camera:WorldToViewportPoint(predictedPos)
                if onScreen then
                    local dist = (Vector2.new(screenPos.X, screenPos.Y) - center).Magnitude
                    if dist < distMin and dist <= FOVRadius then
                        if not WallCheckEnabled or IsVisible(part) then
                            distMin = dist
                            closest = p
                        end
                    end
                end
            end
        end
    end
    return closest
end

RunService.RenderStepped:Connect(function()
    FOVCircle.Position = Camera.ViewportSize / 2
    FOVCircle.Radius = FOVRadius
    FOVCircle.Visible = AimbotOn and FOVCircleVisible and not FOVCircleForcedOff
    
    if AimbotOn then
        local target = GetClosest()
        if target and target.Character then
            local predictedPos = GetPredictedPosition(target.Character)
            if predictedPos then
                local cf = CFrame.new(Camera.CFrame.Position, predictedPos)
                Camera.CFrame = Camera.CFrame:Lerp(cf, AIM_SMOOTHNESS)
            end
        end
    end
end)

-- تحديث السويتش بين البطن والرأس بانتظام
RunService.Heartbeat:Connect(function(dt)
    if not AimbotOn then return end
    local mode = AIM_MODES[currentModeIndex]
    if #mode.parts <= 1 then return end
    
    lastSwitchTime = lastSwitchTime + dt
    if lastSwitchTime >= SWITCH_INTERVAL then
        lastSwitchTime = 0
        currentAutoIndex = currentAutoIndex % #mode.parts + 1
    end
end)

-- أزرار التحكم بالواجهة
ESPToggle.MouseButton1Click:Connect(function()
    espEnabledStatus = not espEnabledStatus
    ESPToggle.Text = "كشف أشخاص + الأسماء: " .. (espEnabledStatus and "ON" or "OFF")
    ESPToggle.BackgroundColor3 = espEnabledStatus and Color3.fromRGB(0,255,0) or Color3.fromRGB(255,0,0)
    for _, p in pairs(Players:GetPlayers()) do
        if p ~= LocalPlayer and p.Character then
            if espEnabledStatus then applyESP(p.Character) else removeESP(p.Character) end
        end
    end
end)

AimbotToggle.MouseButton1Click:Connect(function()
    AimbotOn = not AimbotOn
    AimbotToggle.Text = "إيم بوت (أيم لوك): " .. (AimbotOn and "ON" or "OFF")
    AimbotToggle.BackgroundColor3 = AimbotOn and Color3.fromRGB(0,255,0) or Color3.fromRGB(255,0,0)
end)

AimPartToggle.MouseButton1Click:Connect(function()
    currentModeIndex = currentModeIndex % #AIM_MODES + 1
    currentAutoIndex = 1
    local mode = AIM_MODES[currentModeIndex]
    AimPartToggle.Text = "منطقة الإيم: " .. mode.name
    AimPartToggle.BackgroundColor3 = mode.color
end)

WallcheckToggle.MouseButton1Click:Connect(function()
    WallCheckEnabled = not WallCheckEnabled
    WallcheckToggle.Text = "Wallcheck: " .. (WallCheckEnabled and "ON" or "OFF")
    WallcheckToggle.BackgroundColor3 = WallCheckEnabled and Color3.fromRGB(0,255,0) or Color3.fromRGB(255,100,100)
end)

ESPInventoryToggle.MouseButton1Click:Connect(function()
    espInventoryEnabled = not espInventoryEnabled
    ESPInventoryToggle.Text = "كشف لوت: " .. (espInventoryEnabled and "ON" or "OFF")
    ESPInventoryToggle.BackgroundColor3 = espInventoryEnabled and Color3.fromRGB(0,255,0) or Color3.fromRGB(255,0,0)
    for _, p in ipairs(Players:GetPlayers()) do updateESP(p) end
end)

local function makeDraggable(frame, dragArea)
    local dragging, startPos, startMouse
    dragArea.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = true
            startPos = frame.Position
            startMouse = input.Position
        end
    end)
    dragArea.InputChanged:Connect(function(input)
        if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
            local delta = input.Position - startMouse
            frame.Position = UDim2.new(
                startPos.X.Scale, startPos.X.Offset + delta.X,
                startPos.Y.Scale, startPos.Y.Offset + delta.Y
            )
        end
    end)
    UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then dragging = false end
    end)
end

makeDraggable(MainFrame, MainDrag)
makeDraggable(ToggleButton, ToggleDrag)

ToggleButton.MouseButton1Click:Connect(function()
    guiOpen = not guiOpen
    MainFrame.Visible = guiOpen
    ToggleButton.Text = guiOpen and "إغلاق" or "Open TOP7"
    if guiOpen then UpdateProtectedList() end
end)
