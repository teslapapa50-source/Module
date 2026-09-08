-- Zen Reanimations Runner (ZenScript Theme)
-- Loads local module.lua and animation files

local CoreGui = game:GetService("CoreGui")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local lp = Players.LocalPlayer

-- ═══════════════════════════════════════════════════
-- ZEN THEME PALETTE
-- ═══════════════════════════════════════════════════
local C = {
    bg              = Color3.fromRGB(0, 0, 0),       -- Pure black
    bgCard          = Color3.fromRGB(10, 10, 10),    -- Deep dark grey
    surface         = Color3.fromRGB(16, 16, 16),    -- Surface grey
    surfaceHover    = Color3.fromRGB(26, 26, 26),    -- Hover grey
    input           = Color3.fromRGB(12, 12, 12),    -- Input background
    accent          = Color3.fromRGB(255, 255, 255), -- Pure white accent
    danger          = Color3.fromRGB(50, 50, 50),    -- Muted dark grey for danger buttons
    success         = Color3.fromRGB(255, 255, 255), -- White for success state
    text            = Color3.fromRGB(240, 240, 240), -- Clean white text
    textMuted       = Color3.fromRGB(130, 130, 130), -- Muted grey text
    divider         = Color3.fromRGB(28, 28, 28)     -- Subtle borders
}

local function applyCorner(parent, radius)
    local corner = Instance.new("UICorner", parent)
    corner.CornerRadius = UDim.new(0, radius or 8)
    return corner
end

local function applyStroke(parent, color, thickness, transparency)
    local s = Instance.new("UIStroke", parent)
    s.Color = color or C.accent
    s.Thickness = thickness or 1
    s.Transparency = transparency or 0.6
    s.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    return s
end

local function tween(obj, props, dur, style, dir)
    local info = TweenInfo.new(dur or 0.2, style or Enum.EasingStyle.Quad, dir or Enum.EasingDirection.Out)
    TweenService:Create(obj, info, props):Play()
end

local isMobile = UserInputService.TouchEnabled and not UserInputService.KeyboardEnabled
local GUI_W = isMobile and 280 or 340
local GUI_H = isMobile and 360 or 440
local GUI_H_MIN = 46
local GUI_MIN_W = isMobile and 240 or 280
local GUI_MIN_H = isMobile and 280 or 320

-- Clean up old GUI if it exists
if CoreGui:FindFirstChild("ZenReanimationsRunner") then
    CoreGui.ZenReanimationsRunner:Destroy()
end

-- 1. Load the Cloud Module
local api
local success, result = pcall(function()
    return loadstring(game:HttpGet("https://raw.githubusercontent.com/teslapapa50-source/Module/refs/heads/main/d"))()
end)

if success and type(result) == "table" then
    api = result
else
    warn("Zen Reanimations: Failed to load module.lua from GitHub. Error: " .. tostring(result))
    return
end

-- 2. Load Animations List from Cloud
local animations = {}
local HttpService = game:GetService("HttpService")

local anim_success, anim_data = pcall(function()
    return game:HttpGet("https://raw.githubusercontent.com/teslapapa50-source/Module/refs/heads/main/animations.json")
end)

if anim_success then
    local decode_success, decoded = pcall(function()
        return HttpService:JSONDecode(anim_data)
    end)
    if decode_success and type(decoded) == "table" then
        for _, item in ipairs(decoded) do
            if item.name and item.path then
                table.insert(animations, item)
            end
        end
    else
        warn("Zen Reanimations: Failed to parse animations.json")
    end
else
    warn("Zen Reanimations: Failed to download animations.json from GitHub")
end

local CONFIG_FILE = "ZenReanimConfig.json"
local savedConfig = { favs = {}, binds = {} }

if isfile and readfile and isfile(CONFIG_FILE) then
    pcall(function()
        local data = HttpService:JSONDecode(readfile(CONFIG_FILE))
        if data.favs then savedConfig.favs = data.favs end
        if data.binds then savedConfig.binds = data.binds end
    end)
end

local function saveConfig()
    if writefile then
        pcall(function()
            writefile(CONFIG_FILE, HttpService:JSONEncode(savedConfig))
        end)
    end
end


-- Background Fetch Favorites
task.spawn(function()
    task.wait(2) -- Let UI load first
    if api and api.preload_animation then
        for animName, _ in pairs(savedConfig.favs) do
            local path = nil
            for _, a in ipairs(animations) do
                if a.name == animName then path = a.path break end
            end
            if path then
                api.preload_animation(path)
                task.wait(0.5) -- Prevent network spam
            end
        end
    end
end)

-- 3. Create GUI
local gui = Instance.new("ScreenGui")
gui.Name = "ZenReanimationsRunner"
gui.ResetOnSpawn = false
gui.Parent = CoreGui

local mainFrame = Instance.new("Frame")
mainFrame.Size = UDim2.new(0, GUI_W, 0, GUI_H)
mainFrame.Position = UDim2.new(0.5, -math.floor(GUI_W/2), 0.5, -math.floor(GUI_H/2))
mainFrame.BackgroundColor3 = C.bgCard
mainFrame.BorderSizePixel = 0
mainFrame.ClipsDescendants = true
mainFrame.Active = true
mainFrame.Parent = gui

applyCorner(mainFrame, 18)
local mainStroke = applyStroke(mainFrame, C.accent, 1.5, 0.15)

local strokeGradient = Instance.new("UIGradient")
strokeGradient.Transparency = NumberSequence.new({
    NumberSequenceKeypoint.new(0, 1),
    NumberSequenceKeypoint.new(0.45, 1),
    NumberSequenceKeypoint.new(0.5, 0),
    NumberSequenceKeypoint.new(0.55, 1),
    NumberSequenceKeypoint.new(1, 1)
})
strokeGradient.Color = ColorSequence.new(C.accent)
strokeGradient.Parent = mainStroke

task.spawn(function()
    while mainStroke and mainStroke.Parent do
        if strokeGradient then
            strokeGradient.Rotation = (strokeGradient.Rotation + 2.5) % 360
        end
        task.wait()
    end
end)

local titleBar = Instance.new("Frame")
titleBar.Size = UDim2.new(1, 0, 0, GUI_H_MIN)
titleBar.BackgroundColor3 = C.surface
titleBar.BorderSizePixel = 0
titleBar.Active = true
titleBar.Parent = mainFrame
applyCorner(titleBar, 18)

local titleBarMask = Instance.new("Frame")
titleBarMask.Size = UDim2.new(1, 0, 0, 14)
titleBarMask.Position = UDim2.new(0, 0, 1, -14)
titleBarMask.BackgroundColor3 = C.surface
titleBarMask.BorderSizePixel = 0
titleBarMask.Parent = titleBar

local titleText = Instance.new("TextLabel")
titleText.Size = UDim2.new(1, isMobile and -150 or -200, 1, 0)
titleText.Position = UDim2.new(0, 14, 0, 0)
titleText.BackgroundTransparency = 1
titleText.Text = "Zen Reanimations"
titleText.TextColor3 = C.text
titleText.TextSize = isMobile and 12 or 14
titleText.Font = Enum.Font.GothamBold
titleText.TextXAlignment = Enum.TextXAlignment.Left
titleText.Parent = titleBar

-- window controls on the RIGHT
local winControls = Instance.new("Frame")
winControls.Size = UDim2.new(0, 56, 0, 28)
winControls.Position = UDim2.new(1, -64, 0.5, -14)
winControls.BackgroundTransparency = 1
winControls.Parent = titleBar

local minBtn = Instance.new("TextButton")
minBtn.Size = UDim2.new(0, 22, 0, 22)
minBtn.Position = UDim2.new(0, 0, 0.5, -11)
minBtn.BackgroundColor3 = Color3.fromRGB(255, 190, 60)
minBtn.Text = ""
minBtn.AutoButtonColor = false
minBtn.Parent = winControls
applyCorner(minBtn, 11)

local closeBtn = Instance.new("TextButton")
closeBtn.Size = UDim2.new(0, 22, 0, 22)
closeBtn.Position = UDim2.new(0, 30, 0.5, -11)
closeBtn.BackgroundColor3 = Color3.fromRGB(255, 90, 90)
closeBtn.Text = ""
closeBtn.AutoButtonColor = false
closeBtn.Parent = winControls
applyCorner(closeBtn, 11)

local controlsFrame = Instance.new("Frame")
controlsFrame.Size = UDim2.new(0, isMobile and 78 or 110, 0, 28)
controlsFrame.Position = UDim2.new(1, isMobile and -150 or -186, 0.5, -14)
controlsFrame.BackgroundTransparency = 1
controlsFrame.Parent = titleBar

local toggleBtn = Instance.new("TextButton")
toggleBtn.Size = UDim2.new(1, 0, 1, 0)
toggleBtn.Position = UDim2.new(0, 0, 0, 0)
toggleBtn.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
toggleBtn.Text = isMobile and "Reanim" or "Enable Reanim"
toggleBtn.TextColor3 = C.text
toggleBtn.Font = Enum.Font.GothamSemibold
toggleBtn.TextSize = isMobile and 10 or 12
toggleBtn.Parent = controlsFrame
applyCorner(toggleBtn, 14)
local toggleStroke = applyStroke(toggleBtn, C.textMuted, 1, 0.5)

local isMinimized = false
minBtn.MouseEnter:Connect(function() tween(minBtn, {BackgroundColor3 = Color3.fromRGB(255, 220, 100)}, 0.15) end)
minBtn.MouseLeave:Connect(function() tween(minBtn, {BackgroundColor3 = Color3.fromRGB(255, 190, 60)}, 0.15) end)
minBtn.MouseButton1Click:Connect(function()
    isMinimized = not isMinimized
    if isMinimized then
        tween(mainFrame, {Size = UDim2.new(0, GUI_W, 0, GUI_H_MIN)}, 0.3, Enum.EasingStyle.Quart, Enum.EasingDirection.Out)
    else
        tween(mainFrame, {Size = UDim2.new(0, GUI_W, 0, GUI_H)}, 0.3, Enum.EasingStyle.Quart, Enum.EasingDirection.Out)
    end
end)

closeBtn.MouseEnter:Connect(function() tween(closeBtn, {BackgroundColor3 = Color3.fromRGB(255, 130, 130)}, 0.15) end)
closeBtn.MouseLeave:Connect(function() tween(closeBtn, {BackgroundColor3 = Color3.fromRGB(255, 90, 90)}, 0.15) end)
closeBtn.MouseButton1Click:Connect(function() gui:Destroy() end)

-- Dragging logic (PC + mobile)
local dragging, dragStart, startPos = false, nil, nil
local function beginDrag(input)
    if input.UserInputType ~= Enum.UserInputType.MouseButton1 and input.UserInputType ~= Enum.UserInputType.Touch then
        return
    end
    dragging = true
    dragStart = input.Position
    startPos = mainFrame.Position
end
local function updateDrag(input)
    if not dragging then return end
    if input.UserInputType ~= Enum.UserInputType.MouseMovement and input.UserInputType ~= Enum.UserInputType.Touch then
        return
    end
    local delta = input.Position - dragStart
    mainFrame.Position = UDim2.new(
        startPos.X.Scale, startPos.X.Offset + delta.X,
        startPos.Y.Scale, startPos.Y.Offset + delta.Y
    )
end
local function endDrag(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        dragging = false
    end
end
titleBar.InputBegan:Connect(beginDrag)
titleBar.InputChanged:Connect(updateDrag)
UserInputService.InputChanged:Connect(function(input)
    if dragging then updateDrag(input) end
end)
UserInputService.InputEnded:Connect(endDrag)

-- Tabs Area
local currentSpeed = 1.0

local tabsFrame = Instance.new("Frame")
tabsFrame.Size = UDim2.new(1, -32, 0, 34)
tabsFrame.Position = UDim2.new(0, 16, 0, GUI_H_MIN + 12)
tabsFrame.BackgroundColor3 = C.input
tabsFrame.Parent = mainFrame
applyCorner(tabsFrame, 12)
applyStroke(tabsFrame, C.divider, 1, 0)

local tabIndicator = Instance.new("Frame")
tabIndicator.Size = UDim2.new(1/3, -6, 1, -8)
tabIndicator.Position = UDim2.new(0, 4, 0, 4)
tabIndicator.BackgroundColor3 = C.surfaceHover
tabIndicator.BorderSizePixel = 0
tabIndicator.Parent = tabsFrame
applyCorner(tabIndicator, 10)
applyStroke(tabIndicator, C.divider, 1, 0)

local tabMain = Instance.new("TextButton")
tabMain.Size = UDim2.new(1/3, 0, 1, 0)
tabMain.Position = UDim2.new(0, 0, 0, 0)
tabMain.BackgroundTransparency = 1
tabMain.Text = "Fun"
tabMain.TextColor3 = C.text
tabMain.Font = Enum.Font.GothamSemibold
tabMain.TextSize = isMobile and 11 or 12
tabMain.Parent = tabsFrame

local tabBang = Instance.new("TextButton")
tabBang.Size = UDim2.new(1/3, 0, 1, 0)
tabBang.Position = UDim2.new(1/3, 0, 0, 0)
tabBang.BackgroundTransparency = 1
tabBang.Text = "Bang"
tabBang.TextColor3 = C.textMuted
tabBang.Font = Enum.Font.GothamSemibold
tabBang.TextSize = isMobile and 11 or 12
tabBang.Parent = tabsFrame

local tabFavs = Instance.new("TextButton")
tabFavs.Size = UDim2.new(1/3, 0, 1, 0)
tabFavs.Position = UDim2.new(2/3, 0, 0, 0)
tabFavs.BackgroundTransparency = 1
tabFavs.Text = "Favorites"
tabFavs.TextColor3 = C.textMuted
tabFavs.Font = Enum.Font.GothamSemibold
tabFavs.TextSize = isMobile and 11 or 12
tabFavs.Parent = tabsFrame

local currentTab = "Main"

-- Search Bar
-- Speed Slider
local sliderContainer = Instance.new("Frame")
sliderContainer.Size = UDim2.new(1, -32, 0, 34)
sliderContainer.Position = UDim2.new(0, 16, 0, GUI_H_MIN + 54)
sliderContainer.BackgroundColor3 = C.input
sliderContainer.Parent = mainFrame
applyCorner(sliderContainer, 6)
applyStroke(sliderContainer, C.divider, 1, 0)

local sliderLabel = Instance.new("TextLabel")
sliderLabel.Size = UDim2.new(0, 50, 1, 0)
sliderLabel.Position = UDim2.new(0, 10, 0, 0)
sliderLabel.BackgroundTransparency = 1
sliderLabel.Text = "Speed"
sliderLabel.TextColor3 = C.textMuted
sliderLabel.Font = Enum.Font.GothamSemibold
sliderLabel.TextSize = 12
sliderLabel.TextXAlignment = Enum.TextXAlignment.Left
sliderLabel.Parent = sliderContainer

local sliderTrack = Instance.new("Frame")
sliderTrack.Size = UDim2.new(1, -120, 0, 4)
sliderTrack.Position = UDim2.new(0, 60, 0.5, -2)
sliderTrack.BackgroundColor3 = C.bgCard
sliderTrack.BorderSizePixel = 0
sliderTrack.Parent = sliderContainer
applyCorner(sliderTrack, 2)

local sliderFill = Instance.new("Frame")
sliderFill.Size = UDim2.new(0.3, 0, 1, 0) -- default ~1.0 on a 0.1 to 3.0 scale
sliderFill.BackgroundColor3 = C.accent
sliderFill.BorderSizePixel = 0
sliderFill.Parent = sliderTrack
applyCorner(sliderFill, 2)

local sliderKnob = Instance.new("Frame")
sliderKnob.Size = UDim2.new(0, 12, 0, 12)
sliderKnob.Position = UDim2.new(1, -6, 0.5, -6)
sliderKnob.BackgroundColor3 = C.text
sliderKnob.BorderSizePixel = 0
sliderKnob.Parent = sliderFill
applyCorner(sliderKnob, 6)

local sliderValue = Instance.new("TextLabel")
sliderValue.Size = UDim2.new(0, 40, 1, 0)
sliderValue.Position = UDim2.new(1, -45, 0, 0)
sliderValue.BackgroundTransparency = 1
sliderValue.Text = "1.0x"
sliderValue.TextColor3 = C.text
sliderValue.Font = Enum.Font.GothamBold
sliderValue.TextSize = 12
sliderValue.TextXAlignment = Enum.TextXAlignment.Right
sliderValue.Parent = sliderContainer

local draggingSlider = false
local function updateSlider(input)
    local relX = math.clamp(input.Position.X - sliderTrack.AbsolutePosition.X, 0, sliderTrack.AbsoluteSize.X)
    local percent = relX / sliderTrack.AbsoluteSize.X
    sliderFill.Size = UDim2.new(percent, 0, 1, 0)
    
    local minSpd, maxSpd = 0.1, 3.0
    local spd = minSpd + ((maxSpd - minSpd) * percent)
    currentSpeed = math.floor(spd * 10) / 10
    sliderValue.Text = string.format("%.1fx", currentSpeed)
    
    if api.is_reanimated() then
        api.set_animation_speed(currentSpeed)
    end
end

sliderContainer.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        draggingSlider = true
        updateSlider(input)
    end
end)
UserInputService.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        draggingSlider = false
    end
end)
UserInputService.InputChanged:Connect(function(input)
    if draggingSlider and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
        updateSlider(input)
    end
end)

local currentlyBinding = nil

-- Speed Presets
local presetSpeeds = {0.5, 1.0, 1.5, 3.0}
local presetsContainer = Instance.new("Frame")
presetsContainer.Size = UDim2.new(1, -32, 0, 58)
presetsContainer.Position = UDim2.new(0, 16, 0, GUI_H_MIN + 94)
presetsContainer.BackgroundTransparency = 1
presetsContainer.Parent = mainFrame

local presetLabel = Instance.new("TextLabel")
presetLabel.Size = UDim2.new(1, 0, 0, 12)
presetLabel.Position = UDim2.new(0, 5, 0, -2)
presetLabel.BackgroundTransparency = 1
presetLabel.Text = "Speed Presets — click speed to edit, [+] to bind key"
presetLabel.TextColor3 = C.textMuted
presetLabel.Font = Enum.Font.GothamSemibold
presetLabel.TextSize = 10
presetLabel.TextXAlignment = Enum.TextXAlignment.Left
presetLabel.Parent = presetsContainer

local presetWidth = 1 / #presetSpeeds
for i, spd in ipairs(presetSpeeds) do
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(presetWidth, -6, 0, 22)
    btn.Position = UDim2.new((i-1)*presetWidth, 3, 0, 14)
    btn.BackgroundColor3 = C.surface
    btn.Text = string.format("%.1f", spd)
    btn.TextColor3 = C.text
    btn.Font = Enum.Font.GothamBold
    btn.TextSize = 12
    btn.Parent = presetsContainer
    applyCorner(btn, 4)
    applyStroke(btn, C.divider, 1, 0)
    
    local bindBtn = Instance.new("TextButton")
    bindBtn.Size = UDim2.new(presetWidth, -6, 0, 20)
    bindBtn.Position = UDim2.new((i-1)*presetWidth, 3, 0, 40)
    bindBtn.BackgroundColor3 = C.input
    bindBtn.ZIndex = 5
    local boundKey = savedConfig.binds["SPEED_"..tostring(spd)]
    bindBtn.Text = boundKey and ("[" .. boundKey .. "]") or "[+]"
    bindBtn.TextColor3 = boundKey and C.accent or C.textMuted
    bindBtn.Font = Enum.Font.GothamSemibold
    bindBtn.TextSize = 11
    bindBtn.Parent = presetsContainer
    applyCorner(bindBtn, 4)
    applyStroke(bindBtn, C.divider, 1, 0)

    btn.MouseButton1Click:Connect(function()
        currentSpeed = spd
        sliderValue.Text = string.format("%.1fx", currentSpeed)
        
        local minSpd, maxSpd = 0.1, 3.0
        local percent = (spd - minSpd) / (maxSpd - minSpd)
        sliderFill.Size = UDim2.new(percent, 0, 1, 0)
        
        if api.is_reanimated() then
            api.set_animation_speed(currentSpeed)
        end
        tween(btn, {BackgroundColor3 = C.accent, TextColor3 = C.bgCard}, 0.1)
        task.delay(0.15, function()
            tween(btn, {BackgroundColor3 = C.surface, TextColor3 = C.text}, 0.2)
        end)
    end)
    
    bindBtn.MouseButton1Click:Connect(function()
        currentlyBinding = {name = "SPEED_"..tostring(spd), btn = bindBtn, isSpeed = true}
        bindBtn.Text = "[...]"
        bindBtn.TextColor3 = C.textMuted
    end)
end

-- Search Bar
local searchBox = Instance.new("TextBox")
searchBox.Size = UDim2.new(1, -32, 0, 34)
searchBox.Position = UDim2.new(0, 16, 0, GUI_H_MIN + 158)
applyCorner(searchBox, 10)
searchBox.BackgroundColor3 = C.input
searchBox.Text = ""
searchBox.PlaceholderText = "Search Animations..."
searchBox.PlaceholderColor3 = C.textMuted
searchBox.TextColor3 = C.text
searchBox.Font = Enum.Font.Gotham
searchBox.TextSize = 13
searchBox.Parent = mainFrame
applyStroke(searchBox, C.divider, 1, 0)

-- Animations List
local scrollFrame = Instance.new("ScrollingFrame")
scrollFrame.Size = UDim2.new(1, -24, 1, -(GUI_H_MIN + 200))
scrollFrame.Position = UDim2.new(0, 12, 0, GUI_H_MIN + 200)
scrollFrame.BackgroundTransparency = 1
scrollFrame.ScrollBarThickness = 4
scrollFrame.ScrollBarImageColor3 = C.textMuted
scrollFrame.BorderSizePixel = 0
scrollFrame.Parent = mainFrame

local listLayout = Instance.new("UIListLayout")
listLayout.Padding = UDim.new(0, 8)
listLayout.SortOrder = Enum.SortOrder.LayoutOrder
listLayout.Parent = scrollFrame


local activeAnim = nil -- forward for bang

--======= ZERO-DELAY BANG (sethiddenproperty) ======= hehe
local _setHiddenNative = (type(sethiddenproperty) == "function" and sethiddenproperty)
    or (type(set_hidden_property) == "function" and set_hidden_property)
    or (type(sethidden) == "function" and sethidden)
    or nil

local function setHidden(obj, prop, value)
    if not obj then return end
    if type(sethiddenproperty) == "function" then
        pcall(sethiddenproperty, obj, prop, value)
    end
    if type(set_hidden_property) == "function" then
        pcall(set_hidden_property, obj, prop, value)
    end
    if type(sethidden) == "function" then
        pcall(sethidden, obj, prop, value)
    end
    if _setHiddenNative then
        pcall(_setHiddenNative, obj, prop, value)
    end
end

local function forceNet()
    pcall(function()
        if type(sethiddenproperty) == "function" then
            sethiddenproperty(lp, "SimulationRadius", 9e9)
            sethiddenproperty(lp, "MaxSimulationRadius", 9e9)
        end
        if type(setsimulationradius) == "function" then
            setsimulationradius(9e9, 9e9)
        end
    end)
end

local bangRunning = false
local bangLoop = nil
local bangMode = nil -- "face" | "back"
local selectedBangAnim = nil -- {name, path}
local bangTargetName = ""
local bangTargetBox -- TextBox created later
local bangStatus -- label created later
local bangAnimLabel
local bangPanel

local function findPlayerByName(query)
    if not query or query == "" then return nil end
    query = query:lower()
    for _, p in ipairs(Players:GetPlayers()) do
        if p.Name:lower() == query or p.DisplayName:lower() == query then return p end
    end
    for _, p in ipairs(Players:GetPlayers()) do
        if p.Name:lower():find(query, 1, true) or p.DisplayName:lower():find(query, 1, true) then return p end
    end
    return nil
end

local function stopBang()
    bangRunning = false
    bangMode = nil
    if bangLoop then
        pcall(function() bangLoop:Disconnect() end)
        bangLoop = nil
    end
    pcall(function()
        if api and api.stop_animation then api.stop_animation() end
    end)
    activeAnim = nil
    local char = lp.Character
    if char then
        local root = char:FindFirstChild("HumanoidRootPart")
        local hum = char:FindFirstChildWhichIsA("Humanoid")
        if root then
            pcall(function()
                setHidden(root, "PhysicsRepRootPart", nil)
                if sethiddenproperty then sethiddenproperty(root, "PhysicsRepRootPart", nil) end
            end)
            root.Anchored = false
            root.AssemblyLinearVelocity = Vector3.zero
            root.AssemblyAngularVelocity = Vector3.zero
        end
        if hum then
            pcall(function()
                hum.WalkSpeed = 16
                hum.JumpPower = 50
                hum.JumpHeight = 7.2
                hum.AutoRotate = true
                hum:SetStateEnabled(Enum.HumanoidStateType.Freefall, true)
                hum:SetStateEnabled(Enum.HumanoidStateType.FallingDown, true)
                hum:ChangeState(Enum.HumanoidStateType.GettingUp)
                task.defer(function()
                    if hum.Parent then
                        hum:ChangeState(Enum.HumanoidStateType.RunningNoPhysics)
                        hum.WalkSpeed = 16
                    end
                end)
            end)
        end
    end
    if bangStatus then bangStatus.Text = "Idle" end
    print("[ZenBang] stopped")
end

local function getBangLockRoot()
    -- when reanimated, server sees real char; prefer real HRP for PhysicsRepRootPart
    if api and api.is_reanimated and api.is_reanimated() and api.get_real_character then
        local real = api.get_real_character()
        if real then
            local r = real:FindFirstChild("HumanoidRootPart")
            if r then return r, real end
        end
    end
    local char = lp.Character
    if not char then return nil, nil end
    return char:FindFirstChild("HumanoidRootPart"), char
end

local function startBang(mode)
    print("[ZenBang] click", mode)

    local query = ""
    if bangTargetBox and bangTargetBox.Parent then
        query = tostring(bangTargetBox.Text or "")
    end
    if query == "" then
        query = tostring(bangTargetName or "")
    end
    query = query:gsub("^%s+", ""):gsub("%s+$", "")
    print("[ZenBang] query raw=", query, "box=", bangTargetBox ~= nil)
    if query == "" then
        if bangStatus then bangStatus.Text = "Enter a target name" end
        print("[ZenBang] empty target")
        return
    end

    local TargetPlayer = findPlayerByName(query)
    if not TargetPlayer then
        if bangStatus then bangStatus.Text = "Target not found: " .. query end
        print("[ZenBang] not found", query)
        return
    end
    if not TargetPlayer.Character or not TargetPlayer.Character:FindFirstChild("HumanoidRootPart") then
        if bangStatus then bangStatus.Text = "Target has no character yet" end
        print("[ZenBang] no target char")
        return
    end
    if not lp.Character or not lp.Character:FindFirstChild("HumanoidRootPart") then
        if bangStatus then bangStatus.Text = "You have no character" end
        return
    end

    -- stop any previous
    bangRunning = false
    if bangLoop then pcall(function() bangLoop:Disconnect() end) bangLoop = nil end

    bangRunning = true
    bangMode = mode
    bangTargetName = TargetPlayer.Name
    if bangStatus then
        bangStatus.Text = (mode == "face" and "Face Bang → " or "Backshots → ") .. TargetPlayer.Name
    end

    -- face: in FRONT of target, hips/mid-body at their head (face height)
    -- back: behind target at waist height
    local PosY, PosZ, AngY
    if mode == "face" then
        -- mid-body (where legs start) on target's face, standing in front facing them
        PosY = 1.65
        PosZ = -0.55
        AngY = 180
    else
        PosY = 0
        PosZ = 0.9
        AngY = 0
    end

    -- humanoid physics prep (same as Angoor playEmoteInstant)
    local hum = lp.Character:FindFirstChildWhichIsA("Humanoid")
    if hum then
        pcall(function()
            hum:SetStateEnabled(Enum.HumanoidStateType.Freefall, false)
            hum:SetStateEnabled(Enum.HumanoidStateType.FallingDown, false)
            hum:ChangeState(Enum.HumanoidStateType.Physics)
            hum.WalkSpeed = 0
            hum.JumpPower = 0
            hum.AutoRotate = false
        end)
    end

    -- lock starts immediately; reanim/anim load in parallel (module delay is separate)
    if selectedBangAnim and selectedBangAnim.path and api then
        task.spawn(function()
            pcall(function()
                if api.is_reanimated and not api.is_reanimated() then
                    api.reanimate(true)
                    if toggleBtn then toggleBtn.Text = "Disable Reanim" end
                end
                if api.play_animation then
                    local res = api.play_animation(selectedBangAnim.path, currentSpeed or 1)
                    if type(res) == "string" then
                        warn("[ZenBang] anim:", res)
                    else
                        activeAnim = selectedBangAnim.name
                    end
                end
            end)
        end)
    else
        print("[ZenBang] no reanim selected — position lock only")
    end

    print("[ZenBang] locking onto", TargetPlayer.Name, mode)

    -- Instant lock: Heartbeat (physics) + RenderStepped (visual). No waits.
    local function applyLock()
        if not bangRunning then return end
        local tPlr = Players:FindFirstChild(bangTargetName) or TargetPlayer
        if not tPlr then return end
        local TargetRootPart = tPlr.Character and tPlr.Character:FindFirstChild("HumanoidRootPart")
        if not TargetRootPart then return end

        forceNet()
        local goal = TargetRootPart.CFrame * CFrame.new(0, PosY, PosZ) * CFrame.Angles(0, math.rad(AngY), 0)

        -- REAL body (what others see)
        local realRoot, realChar = getBangLockRoot()
        if realRoot then
            setHidden(realRoot, "NetworkIsSleeping", false)
            setHidden(realRoot, "PhysicsRepRootPart", TargetRootPart)
            realRoot.CFrame = goal
            setHidden(realRoot, "PhysicsRepRootPart", TargetRootPart)
            realRoot.AssemblyLinearVelocity = Vector3.zero
            realRoot.AssemblyAngularVelocity = Vector3.zero
            local realHum = realChar and realChar:FindFirstChildWhichIsA("Humanoid")
            if realHum then
                pcall(function()
                    realHum:ChangeState(Enum.HumanoidStateType.Physics)
                    realHum.PlatformStand = true
                end)
            end
        end

        -- LIVE character (clone when reanim) so local view matches
        local liveChar = lp.Character
        local liveRoot = liveChar and liveChar:FindFirstChild("HumanoidRootPart")
        if liveRoot then
            setHidden(liveRoot, "NetworkIsSleeping", false)
            setHidden(liveRoot, "PhysicsRepRootPart", TargetRootPart)
            liveRoot.CFrame = goal
            setHidden(liveRoot, "PhysicsRepRootPart", TargetRootPart)
            liveRoot.AssemblyLinearVelocity = Vector3.zero
            liveRoot.AssemblyAngularVelocity = Vector3.zero
        end
    end

    -- run once immediately (no 1-frame wait)
    applyLock()

    local connHb = RunService.Heartbeat:Connect(applyLock)
    local connRs = RunService.RenderStepped:Connect(applyLock)
    bangLoop = {
        Disconnect = function()
            pcall(function() connHb:Disconnect() end)
            pcall(function() connRs:Disconnect() end)
        end
    }
end

-- Bang panel UI


bangPanel = Instance.new("Frame")
bangPanel.Name = "BangPanel"
bangPanel.Size = UDim2.new(1, -24, 1, -(GUI_H_MIN + 200))
bangPanel.Position = UDim2.new(0, 12, 0, GUI_H_MIN + 200)
bangPanel.BackgroundTransparency = 1
bangPanel.Visible = false
bangPanel.Parent = mainFrame

bangTargetBox = Instance.new("TextBox")
bangTargetBox.Size = UDim2.new(1, 0, 0, 34)
bangTargetBox.Position = UDim2.new(0, 0, 0, 0)
bangTargetBox.BackgroundColor3 = C.input
bangTargetBox.PlaceholderText = "Target username..."
bangTargetBox.PlaceholderColor3 = C.textMuted
bangTargetBox.Text = ""
bangTargetBox.TextColor3 = C.text
bangTargetBox.Font = Enum.Font.Gotham
bangTargetBox.TextSize = 12
bangTargetBox.ClearTextOnFocus = false
bangTargetBox.Parent = bangPanel
applyCorner(bangTargetBox, 10)
applyStroke(bangTargetBox, C.divider, 1, 0)

bangTargetBox:GetPropertyChangedSignal("Text"):Connect(function()
    bangTargetName = tostring(bangTargetBox.Text or "")
end)
bangTargetBox.FocusLost:Connect(function()
    bangTargetName = tostring(bangTargetBox.Text or "")
end)

bangAnimLabel = Instance.new("TextLabel")
bangAnimLabel.Size = UDim2.new(1, 0, 0, 18)
bangAnimLabel.Position = UDim2.new(0, 0, 0, 40)
bangAnimLabel.BackgroundTransparency = 1
bangAnimLabel.Text = "Bang reanim: (none)"
bangAnimLabel.TextColor3 = C.textMuted
bangAnimLabel.Font = Enum.Font.GothamSemibold
bangAnimLabel.TextSize = 11
bangAnimLabel.TextXAlignment = Enum.TextXAlignment.Left
bangAnimLabel.Parent = bangPanel

local bangAnimScroll = Instance.new("ScrollingFrame")
bangAnimScroll.Size = UDim2.new(1, 0, 0, isMobile and 90 or 110)
bangAnimScroll.Position = UDim2.new(0, 0, 0, 60)
bangAnimScroll.BackgroundColor3 = C.input
bangAnimScroll.BorderSizePixel = 0
bangAnimScroll.ScrollBarThickness = 3
bangAnimScroll.Parent = bangPanel
applyCorner(bangAnimScroll, 10)
applyStroke(bangAnimScroll, C.divider, 1, 0)
local bangAnimLayout = Instance.new("UIListLayout", bangAnimScroll)
bangAnimLayout.Padding = UDim.new(0, 4)
bangAnimLayout.SortOrder = Enum.SortOrder.LayoutOrder
local bangAnimPad = Instance.new("UIPadding", bangAnimScroll)
bangAnimPad.PaddingTop = UDim.new(0, 4)
bangAnimPad.PaddingLeft = UDim.new(0, 4)
bangAnimPad.PaddingRight = UDim.new(0, 4)

local function refreshBangAnimList()
    for _, c in ipairs(bangAnimScroll:GetChildren()) do
        if c:IsA("TextButton") then c:Destroy() end
    end
    for _, anim in ipairs(animations) do
        if (anim.category or "Main") == "Unicorns" then continue end
        local b = Instance.new("TextButton")
        b.Size = UDim2.new(1, -8, 0, 26)
        b.BackgroundColor3 = (selectedBangAnim and selectedBangAnim.name == anim.name) and C.surfaceHover or C.bgCard
        b.Text = "  " .. anim.name
        b.TextXAlignment = Enum.TextXAlignment.Left
        b.TextColor3 = C.text
        b.Font = Enum.Font.GothamSemibold
        b.TextSize = 11
        b.AutoButtonColor = false
        b.Parent = bangAnimScroll
        applyCorner(b, 8)
        b.MouseButton1Click:Connect(function()
            selectedBangAnim = {name = anim.name, path = anim.path}
            bangAnimLabel.Text = "Bang reanim: " .. anim.name
            if api and api.preload_animation then
                task.spawn(api.preload_animation, anim.path)
            end
            refreshBangAnimList()
        end)
    end
    bangAnimScroll.CanvasSize = UDim2.new(0, 0, 0, bangAnimLayout.AbsoluteContentSize.Y + 10)
end
task.defer(refreshBangAnimList)

local faceBtn = Instance.new("TextButton")
faceBtn.Size = UDim2.new(0.48, 0, 0, 34)
faceBtn.Position = UDim2.new(0, 0, 0, isMobile and 160 or 180)
faceBtn.BackgroundColor3 = C.surface
faceBtn.Text = "Face Bang"
faceBtn.TextColor3 = C.text
faceBtn.Font = Enum.Font.GothamBold
faceBtn.TextSize = 12
faceBtn.Active = true
faceBtn.ZIndex = 5
faceBtn.Parent = bangPanel
applyCorner(faceBtn, 10)
applyStroke(faceBtn, C.divider, 1, 0)

local backBtn = Instance.new("TextButton")
backBtn.Size = UDim2.new(0.48, 0, 0, 34)
backBtn.Position = UDim2.new(0.52, 0, 0, isMobile and 160 or 180)
backBtn.BackgroundColor3 = C.surface
backBtn.Text = "Backshots"
backBtn.TextColor3 = C.text
backBtn.Font = Enum.Font.GothamBold
backBtn.TextSize = 12
backBtn.Active = true
backBtn.ZIndex = 5
backBtn.Parent = bangPanel
applyCorner(backBtn, 10)
applyStroke(backBtn, C.divider, 1, 0)


bangStatus = Instance.new("TextLabel")
bangStatus.Size = UDim2.new(1, 0, 0, 18)
bangStatus.Position = UDim2.new(0, 0, 0, isMobile and 202 or 222)
bangStatus.BackgroundTransparency = 1
bangStatus.Text = "Idle"
bangStatus.TextColor3 = C.textMuted
bangStatus.Font = Enum.Font.Gotham
bangStatus.TextSize = 11
bangStatus.TextXAlignment = Enum.TextXAlignment.Left
bangStatus.Parent = bangPanel

-- single handler (Activated on some devices duplicates MouseButton1Click)
local lastBangClick = 0
local function safeStart(mode)
    local now = tick()
    if now - lastBangClick < 0.2 then return end
    lastBangClick = now
    -- click same mode again = stop
    if bangRunning and bangMode == mode then
        stopBang()
        return
    end
    startBang(mode)
end
faceBtn.MouseButton1Click:Connect(function() safeStart("face") end)
backBtn.MouseButton1Click:Connect(function() safeStart("back") end)

-- Resize handle (bottom-right)
local resizeHandle = Instance.new("TextButton")
resizeHandle.Size = UDim2.new(0, 18, 0, 18)
resizeHandle.Position = UDim2.new(1, -20, 1, -20)
resizeHandle.BackgroundColor3 = C.surfaceHover
resizeHandle.Text = ""
resizeHandle.AutoButtonColor = false
resizeHandle.ZIndex = 20
resizeHandle.Parent = mainFrame
applyCorner(resizeHandle, 6)

local resizing, resizeStart, startSize = false, nil, nil
resizeHandle.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        resizing = true
        resizeStart = input.Position
        startSize = mainFrame.Size
    end
end)
UserInputService.InputChanged:Connect(function(input)
    if not resizing then return end
    if input.UserInputType ~= Enum.UserInputType.MouseMovement and input.UserInputType ~= Enum.UserInputType.Touch then return end
    local d = input.Position - resizeStart
    local nw = math.max(GUI_MIN_W, startSize.X.Offset + d.X)
    local nh = math.max(GUI_MIN_H, startSize.Y.Offset + d.Y)
    mainFrame.Size = UDim2.new(0, nw, 0, nh)
    GUI_W, GUI_H = nw, nh
end)
UserInputService.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        resizing = false
    end
end)


local animButtons = {}

local function setReanimState(state)
    api.reanimate(state)
    if state then
        toggleBtn.Text = "Disable Reanim"
        tween(toggleBtn, {BackgroundColor3 = C.text, TextColor3 = C.bg}, 0.2)
        tween(toggleStroke, {Color = C.text, Transparency = 0}, 0.2)
    else
        toggleBtn.Text = "Enable Reanim"
        tween(toggleBtn, {BackgroundColor3 = Color3.fromRGB(30, 30, 30), TextColor3 = C.text}, 0.2)
        tween(toggleStroke, {Color = C.textMuted, Transparency = 0.5}, 0.2)
    end
end

local isProcessing = false

local function toggleReanim()
    if isProcessing then return end
    isProcessing = true
    local isReanim = api.is_reanimated()
    setReanimState(not isReanim)
    task.wait(0.2)
    isProcessing = false
end

-- activeAnim already declared


local currentSpeed = 1.0

local function toggleAnimation(animName, animPath)
    if isProcessing then return end
    isProcessing = true
    if activeAnim == animName then
        api.stop_animation()
        activeAnim = nil
        isProcessing = false
    else
        task.spawn(function()
            if not api.is_reanimated() then
                setReanimState(true)
                local clone = api.get_clone()
                if clone then
                    local waited = 0
                    while not clone:FindFirstChild("HumanoidRootPart") and waited < 1.0 do
                        waited = waited + task.wait(0.05)
                    end
                    task.wait(0.15) 
                else
                    task.wait(0.5) 
                end
            end
            
            local result = api.play_animation(animPath, currentSpeed)
            if type(result) == "string" then
                warn("Reanimations Error:", result)
            else
                activeAnim = animName
            end
            task.wait(0.1)
            isProcessing = false
        end)
    end
end

local function populateList(filterText)
    for _, btn in ipairs(animButtons) do
        btn:Destroy()
    end
    table.clear(animButtons)
    
    filterText = filterText:lower()
    
    for _, anim in ipairs(animations) do
        local isFav = savedConfig.favs[anim.name]
        if currentTab == "Favorites" and not isFav then continue end
        
        local category = anim.category or "Main"
        -- Fun tab = everything except Unicorns category
        if currentTab == "Main" and category == "Unicorns" then continue end
        
        if filterText == "" or anim.name:lower():find(filterText) then
            local btn = Instance.new("TextButton")
            btn.Size = UDim2.new(1, -10, 0, 42)
            btn.BackgroundColor3 = C.bgCard
            btn.Text = "           " .. anim.name
            btn.TextXAlignment = Enum.TextXAlignment.Left
            btn.TextColor3 = C.text
            btn.Font = Enum.Font.GothamSemibold
            btn.TextSize = 13
            btn.AutoButtonColor = false
            btn.Parent = scrollFrame
            applyCorner(btn, 12)
            local stroke = applyStroke(btn, C.divider, 1, 0)
            
            local activeDot = Instance.new("Frame")
            activeDot.Size = UDim2.new(0, 4, 0, 20)
            activeDot.Position = UDim2.new(0, 10, 0.5, -10)
            activeDot.BackgroundColor3 = C.accent
            activeDot.BorderSizePixel = 0
            activeDot.BackgroundTransparency = (activeAnim == anim.name) and 0 or 1
            activeDot.Parent = btn
            applyCorner(activeDot, 2)
            
            if activeAnim == anim.name then
                btn.BackgroundColor3 = C.surfaceHover
                stroke.Color = C.accent
                stroke.Transparency = 0.5
            end
            
            -- Star Icon
            local starBtn = Instance.new("TextButton")
            starBtn.Size = UDim2.new(0, 30, 0, 24)
            starBtn.Position = UDim2.new(1, -125, 0.5, -12)
            starBtn.BackgroundTransparency = 1
            starBtn.Text = isFav and "★" or "☆"
            starBtn.TextColor3 = isFav and C.accent or C.textMuted
            starBtn.TextSize = 16
            starBtn.Font = Enum.Font.GothamBold
            starBtn.Parent = btn
            
            starBtn.MouseButton1Click:Connect(function()
                if savedConfig.favs[anim.name] then
                    savedConfig.favs[anim.name] = nil
                else
                    savedConfig.favs[anim.name] = true
                end
                saveConfig()
                if currentTab == "Favorites" then populateList(searchBox.Text) else
                    starBtn.Text = savedConfig.favs[anim.name] and "★" or "☆"
                    starBtn.TextColor3 = savedConfig.favs[anim.name] and C.accent or C.textMuted
                end
            end)
            
            -- Keybind Button
            local bindBtn = Instance.new("TextButton")
            bindBtn.Size = UDim2.new(0, 80, 0, 24)
            bindBtn.Position = UDim2.new(1, -90, 0.5, -12)
            bindBtn.BackgroundColor3 = C.input
            local boundKey = savedConfig.binds[anim.name]
            bindBtn.Text = boundKey and ("[" .. boundKey .. "]") or "[...]"
            bindBtn.TextColor3 = boundKey and C.accent or C.textMuted
            bindBtn.TextSize = 11
            bindBtn.Font = Enum.Font.GothamSemibold
            bindBtn.Parent = btn
            applyCorner(bindBtn, 4)
            applyStroke(bindBtn, C.divider, 1, 0)
            
            bindBtn.MouseButton1Click:Connect(function()
                currentlyBinding = {name = anim.name, btn = bindBtn}
                bindBtn.Text = "[...]"
                bindBtn.TextColor3 = C.textMuted
            end)
            
            btn.MouseEnter:Connect(function() 
                if activeAnim ~= anim.name then tween(btn, {BackgroundColor3 = C.surface}) end
            end)
            btn.MouseLeave:Connect(function() 
                if activeAnim ~= anim.name then tween(btn, {BackgroundColor3 = C.bgCard}) end
            end)
            
            btn.MouseButton1Click:Connect(function()
                if activeAnim ~= anim.name then
                    tween(btn, {BackgroundColor3 = C.accent, TextColor3 = C.bgCard}, 0.1)
                end
                task.delay(0.15, function()
                    if activeAnim ~= anim.name then tween(btn, {BackgroundColor3 = C.surfaceHover, TextColor3 = C.text}, 0.2) end
                end)
                toggleAnimation(anim.name, anim.path)
                task.wait(0.15)
                populateList(searchBox.Text)
            end)
            
            table.insert(animButtons, btn)
        end
    end
    
    scrollFrame.CanvasSize = UDim2.new(0, 0, 0, listLayout.AbsoluteContentSize.Y + 10)
end

searchBox.Changed:Connect(function(prop)
    if prop == "Text" then
        populateList(searchBox.Text)
    end
end)

local function updateTabsUI(selectedTab)
    currentTab = selectedTab
    tween(tabMain, {TextColor3 = selectedTab == "Main" and C.text or C.textMuted}, 0.2)
    tween(tabBang, {TextColor3 = selectedTab == "Bang" and C.text or C.textMuted}, 0.2)
    tween(tabFavs, {TextColor3 = selectedTab == "Favorites" and C.text or C.textMuted}, 0.2)
    local pos = 0
    if selectedTab == "Bang" then pos = 1/3
    elseif selectedTab == "Favorites" then pos = 2/3 end
    tween(tabIndicator, {Position = UDim2.new(pos, 4, 0, 4)}, 0.3, Enum.EasingStyle.Quint, Enum.EasingDirection.Out)
    if selectedTab == "Bang" then
        if bangPanel then bangPanel.Visible = true end
        if scrollFrame then scrollFrame.Visible = false end
        if searchBox then searchBox.Visible = false end
        if sliderContainer then sliderContainer.Visible = true end
        if presetsContainer then presetsContainer.Visible = true end
    else
        if bangPanel then bangPanel.Visible = false end
        if scrollFrame then scrollFrame.Visible = true end
        if searchBox then searchBox.Visible = true end
        if sliderContainer then sliderContainer.Visible = true end
        if presetsContainer then presetsContainer.Visible = true end
        populateList(searchBox.Text)
    end
end

tabMain.MouseButton1Click:Connect(function() updateTabsUI("Main") end)
tabBang.MouseButton1Click:Connect(function() updateTabsUI("Bang") end)
tabFavs.MouseButton1Click:Connect(function() updateTabsUI("Favorites") end)

populateList("")

-- Button Actions
toggleBtn.MouseEnter:Connect(function()
    if api.is_reanimated() then
        tween(toggleBtn, {BackgroundColor3 = Color3.fromRGB(200, 200, 200)})
    else
        tween(toggleBtn, {BackgroundColor3 = Color3.fromRGB(50, 50, 50)})
        tween(toggleStroke, {Color = C.text, Transparency = 0.3}, 0.2)
    end
end)
toggleBtn.MouseLeave:Connect(function()
    if api.is_reanimated() then
        tween(toggleBtn, {BackgroundColor3 = C.text})
    else
        tween(toggleBtn, {BackgroundColor3 = Color3.fromRGB(30, 30, 30)})
        tween(toggleStroke, {Color = C.textMuted, Transparency = 0.5}, 0.2)
    end
end)

toggleBtn.MouseButton1Click:Connect(function()
    toggleReanim()
end)


-- Global Keybind Handler
UserInputService.InputBegan:Connect(function(input, gp)
    if input.UserInputType == Enum.UserInputType.Keyboard then
        if currentlyBinding then
            local key = input.KeyCode.Name
            if key == "Escape" or key == "Backspace" then
                savedConfig.binds[currentlyBinding.name] = nil
                if currentlyBinding.btn and currentlyBinding.btn.Parent then
                    currentlyBinding.btn.Text = "[...]"
                    currentlyBinding.btn.TextColor3 = C.textMuted
                end
            else
                savedConfig.binds[currentlyBinding.name] = key
                if currentlyBinding.btn and currentlyBinding.btn.Parent then
                    currentlyBinding.btn.Text = "[" .. key .. "]"
                    currentlyBinding.btn.TextColor3 = C.accent
                end
            end
            saveConfig()
            currentlyBinding = nil
            return
        end
        
        if not gp then
            for animName, boundKey in pairs(savedConfig.binds) do
                if input.KeyCode.Name == boundKey then
                    if string.sub(animName, 1, 6) == "SPEED_" then
                        local spd = tonumber(string.sub(animName, 7))
                        if spd then
                            currentSpeed = spd
                            sliderValue.Text = string.format("%.1fx", currentSpeed)
                            local minSpd, maxSpd = 0.1, 3.0
                            local percent = (spd - minSpd) / (maxSpd - minSpd)
                            sliderFill.Size = UDim2.new(percent, 0, 1, 0)
                            if api.is_reanimated() then
                                api.set_animation_speed(currentSpeed)
                            end
                        end
                    else
                        local path = nil
                        for _, a in ipairs(animations) do
                            if a.name == animName then path = a.path break end
                        end
                        if path then
                            toggleAnimation(animName, path)
                        end
                    end
                end
            end
        end
    end
end)
