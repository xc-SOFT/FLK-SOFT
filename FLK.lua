script:SetAttribute("RobloxTranslationEnabled", false)

if _G.FLK_ScriptRunning then
    if _G.FLK_CleanupFunction then
        _G.FLK_CleanupFunction()
    end
    task.wait(0.1)
end

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local LocalizationService = game:GetService("LocalizationService")
local player = Players.LocalPlayer
local workspace = game:GetService("Workspace")
local camera = workspace.CurrentCamera

local FLICK_PLACE_ID = 136801880565837
local currentPlaceId = game.PlaceId

if currentPlaceId ~= FLICK_PLACE_ID then
    local isRussian = false
    local success, translator = pcall(function()
        return LocalizationService:GetTranslatorForPlayerAsync(player)
    end)
    
    if success and translator then
        local localeId = translator.LocaleId
        isRussian = (localeId:sub(1, 2) == "ru")
    end
    
    local notifGui = Instance.new("ScreenGui")
    notifGui.Name = "FLK_WrongGameNotification"
    notifGui.ResetOnSpawn = false
    notifGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    notifGui.Parent = game.CoreGui  
    
    local notifFrame = Instance.new("Frame")
    notifFrame.Name = "Notification"
    notifFrame.Size = UDim2.new(0, 320, 0, 60)
    notifFrame.Position = UDim2.new(1, 350, 1, -80) 
    notifFrame.BackgroundColor3 = Color3.fromRGB(180, 50, 50)
    notifFrame.BorderSizePixel = 0
    notifFrame.Parent = notifGui
    
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 12)
    corner.Parent = notifFrame
    
    local stroke = Instance.new("UIStroke")
    stroke.Color = Color3.fromRGB(255, 100, 100)
    stroke.Thickness = 2
    stroke.Parent = notifFrame
    
    local iconLabel = Instance.new("TextLabel")
    iconLabel.Size = UDim2.new(0, 40, 1, 0)
    iconLabel.Position = UDim2.new(0, 10, 0, 0)
    iconLabel.BackgroundTransparency = 1
    iconLabel.Text = "⚠️"
    iconLabel.TextColor3 = Color3.new(1, 1, 1)
    iconLabel.Font = Enum.Font.GothamBold
    iconLabel.TextSize = 24
    iconLabel.TextXAlignment = Enum.TextXAlignment.Center
    iconLabel.TextYAlignment = Enum.TextYAlignment.Center
    iconLabel.Parent = notifFrame
    
    local textLabel = Instance.new("TextLabel")
    textLabel.Size = UDim2.new(1, -70, 1, -10)
    textLabel.Position = UDim2.new(0, 55, 0, 5)
    textLabel.BackgroundTransparency = 1
    textLabel.Text = isRussian and "Зайдите во Flick для использования скрипта" or "Please join Flick to use this script"
    textLabel.TextColor3 = Color3.new(1, 1, 1)
    textLabel.Font = Enum.Font.GothamBold
    textLabel.TextSize = 13
    textLabel.TextXAlignment = Enum.TextXAlignment.Left
    textLabel.TextYAlignment = Enum.TextYAlignment.Center
    textLabel.TextWrapped = true
    textLabel.Parent = notifFrame
    
    notifFrame:TweenPosition(
        UDim2.new(1, -340, 1, -80),
        Enum.EasingDirection.Out,
        Enum.EasingStyle.Quart,
        0.4,
        true
    )
    
    task.delay(5, function()
        if notifFrame and notifFrame.Parent then
            notifFrame:TweenPosition(
                UDim2.new(1, 350, 1, -80),
                Enum.EasingDirection.In,
                Enum.EasingStyle.Quart,
                0.4,
                true
            )
            task.wait(0.4)
            notifGui:Destroy()
        end
    end)
    
    if isRussian then
        print("⚠️ FLK SOFT - Зайдите во Flick для использования скрипта")
    else
        print("⚠️ FLK SOFT - Please join Flick to use this script")
    end
    
    return
end

local ESP_FILL = Color3.fromRGB(0, 170, 255)
local ESP_OUTLINE = Color3.fromRGB(0, 255, 255)
local GUI_BG = Color3.fromRGB(35, 35, 45)
local GUI_BTN = Color3.fromRGB(50, 50, 70)
local GUI_ACTIVE = Color3.fromRGB(0, 100, 50)

local FOV = 120
local AIM_SMOOTHNESS = 0.2
local PREDICTION_FACTOR = 0.05

local espEnabled = false
local aimbotEnabled = false
local menuVisible = true
local ignoreMagnifierClick = false
local keybindLock = false
local highlightedPlayers = {}
local currentTarget = nil
local espLines = {}
local espLinesEnabled = false
local selectedColorIndex = 1
local notificationActive = false

local keybinds = { Menu = Enum.KeyCode.K, Aim = Enum.KeyCode.LeftAlt }

local isRussian = false
local success, translator = pcall(function()
    return LocalizationService:GetTranslatorForPlayerAsync(player)
end)

if success and translator then
    local localeId = translator.LocaleId
    isRussian = (localeId:sub(1, 2) == "ru")
end

local function isInLobbyTeam(plr)
    local team = plr.Team
    return team and team.Name == "Lobby"
end

local colorNames = isRussian and {"Голубой", "Красный", "Зелёный", "Пурпурный"} or {"Blue", "Red", "Green", "Magenta"}

local colorOptions = {
    {Color3.fromRGB(0, 170, 255), colorNames[1]},
    {Color3.fromRGB(255, 0, 0), colorNames[2]},
    {Color3.fromRGB(0, 255, 0), colorNames[3]},
    {Color3.fromRGB(255, 0, 255), colorNames[4]}
}

local function formatKey(kc)
    if not kc then return"..."end
    local n=tostring(kc):gsub("Enum.KeyCode.","")
    local s={LeftAlt="ALT",RightAlt="ALT",LeftControl="CTRL",RightControl="CTRL",LeftShift="SHIFT",RightShift="SHIFT",Space="SPACE",Backspace="BACK",Return="ENTER",Tab="TAB",Escape="ESC",Delete="DEL",Insert="INS",Home="HOME",End="END",PageUp="PGUP",PageDown="PGDN",Up="↑",Down="↓",Left="←",Right="→"}
    return s[n]or n
end

local labels = {
    title="FLK SOFT",
    esp="👁️ ESP",
    espOn="👁️ ESP: ON",
    espOff="👁️ ESP",
    aim="🎯 Aimbot",
    aimOn="🎯 Aimbot: ON",
    aimOff="🎯 Aimbot",
    hotkeys="⌨️ Hotkeys",
    espSettings="⚙️ ESP Settings",
    menuKey="Menu:",
    aimKey="Aim:",
    back="←",
    pressKey="Press...",
    lines="ESP Lines",
    linesOn="ESP Lines ON",
    linesOff="ESP Lines OFF",
    color="Color:"
}

local function createUIElement(e,p) for k,v in pairs(p)do e[k]=v end;return e end
local function addCorner(i,r) local c=Instance.new("UICorner");c.CornerRadius=UDim.new(0,r or 10);c.Parent=i end
local function addStroke(i,c,t) local s=Instance.new("UIStroke");s.Color=c or Color3.fromRGB(60,60,80);s.Thickness=t or 2;s.Parent=i end

local function makeDraggable(f,d)
    local dr,di,ds,sp
    d.InputBegan:Connect(function(ip)
        if ip.UserInputType==Enum.UserInputType.MouseButton1 then
            dr=true;ds=ip.Position;sp=f.Position
            ip.Changed:Connect(function()if ip.UserInputState==Enum.UserInputState.End then dr=false end end)
        end
    end)
    d.InputChanged:Connect(function(ip)if ip.UserInputType==Enum.UserInputType.MouseMovement then di=ip end end)
    UserInputService.InputChanged:Connect(function(ip)
        if ip==di and dr then
            local dt=ip.Position-ds
            f.Position=UDim2.new(sp.X.Scale,sp.X.Offset+dt.X,sp.Y.Scale,sp.Y.Offset+dt.Y)
        end
    end)
end

local screenGui=Instance.new("ScreenGui");screenGui.Name="FleakCheatGUI";screenGui.ResetOnSpawn=false;screenGui.Parent=game.CoreGui;screenGui.DisplayOrder=100;screenGui.IgnoreGuiInset=true

local mainGuiFrame=createUIElement(Instance.new("Frame"),{Name="MainGuiFrame",Size=UDim2.new(0,300,0,225),Position=UDim2.new(0.5,-150,0.5,-112.5),BackgroundColor3=GUI_BG,BorderSizePixel=0,Visible=true})
mainGuiFrame.Parent=screenGui;addCorner(mainGuiFrame,12);addStroke(mainGuiFrame,Color3.fromRGB(60,60,80),2)

local titleBar=createUIElement(Instance.new("Frame"),{Name="TitleBar",Size=UDim2.new(1,0,0,40),Position=UDim2.new(0,0,0,0),BackgroundColor3=Color3.fromRGB(25,25,35),BorderSizePixel=0})
titleBar.Parent=mainGuiFrame;addCorner(titleBar,12)

local titleLabel=createUIElement(Instance.new("TextLabel"),{Name="TitleLabel",Size=UDim2.new(1,-80,1,0),Position=UDim2.new(0,10,0,0),BackgroundTransparency=1,TextColor3=ESP_FILL,Font=Enum.Font.GothamBold,TextSize=18,Text=labels.title,TextXAlignment=Enum.TextXAlignment.Left,TextYAlignment=Enum.TextYAlignment.Center})
titleLabel.Parent=titleBar

local minimizeButton=createUIElement(Instance.new("TextButton"),{Name="MinimizeButton",Size=UDim2.new(0,24,0,24),Position=UDim2.new(1,-60,0,8),Text="-",BackgroundColor3=Color3.fromRGB(50,50,70),TextColor3=Color3.new(1,1,1),Font=Enum.Font.GothamBold,TextSize=18,BorderSizePixel=0})
minimizeButton.Parent=titleBar;addCorner(minimizeButton,6)

local closeButton=createUIElement(Instance.new("TextButton"),{Name="CloseButton",Size=UDim2.new(0,24,0,24),Position=UDim2.new(1,-30,0,8),Text="X",BackgroundColor3=Color3.fromRGB(180,50,50),TextColor3=Color3.new(1,1,1),Font=Enum.Font.GothamBold,TextSize=14,BorderSizePixel=0})
closeButton.Parent=titleBar;addCorner(closeButton,6)

makeDraggable(mainGuiFrame,titleBar)

local contentFrame=createUIElement(Instance.new("Frame"),{Name="ContentFrame",Size=UDim2.new(1,-16,1,-56),Position=UDim2.new(0,8,0,48),BackgroundColor3=Color3.fromRGB(45,45,60),BorderSizePixel=0})
contentFrame.Parent=mainGuiFrame;addCorner(contentFrame,10)

local espSettingsButton=createUIElement(Instance.new("TextButton"),{Name="ESPSettingsButton",Size=UDim2.new(0,45,0,40),Position=UDim2.new(1,-55,0,15),Text="⚙️",BackgroundColor3=Color3.fromRGB(60,60,90),TextColor3=Color3.new(1,1,1),Font=Enum.Font.GothamBold,TextSize=20,BorderSizePixel=0})
espSettingsButton.Parent=contentFrame;addCorner(espSettingsButton,8);addStroke(espSettingsButton,Color3.fromRGB(80,80,100),2)

local espButton=createUIElement(Instance.new("TextButton"),{Name="ESPButton",Size=UDim2.new(0,208,0,40),Position=UDim2.new(0,12,0,15),Text=labels.esp,BackgroundColor3=GUI_BTN,TextColor3=Color3.new(1,1,1),Font=Enum.Font.GothamBold,TextSize=14,BorderSizePixel=0})
espButton.Parent=contentFrame;addCorner(espButton,8)

local aimButton=createUIElement(Instance.new("TextButton"),{Name="AimButton",Size=UDim2.new(1,-20,0,40),Position=UDim2.new(0,10,0,65),Text=labels.aim,BackgroundColor3=GUI_BTN,TextColor3=Color3.new(1,1,1),Font=Enum.Font.GothamBold,TextSize=14,BorderSizePixel=0})
aimButton.Parent=contentFrame;addCorner(aimButton,8)

local hotkeysButton=createUIElement(Instance.new("TextButton"),{Name="HotkeysButton",Size=UDim2.new(1,-20,0,40),Position=UDim2.new(0,10,0,115),Text=labels.hotkeys,BackgroundColor3=GUI_BTN,TextColor3=Color3.new(1,1,1),Font=Enum.Font.GothamBold,TextSize=14,BorderSizePixel=0})
hotkeysButton.Parent=contentFrame;addCorner(hotkeysButton,8)

local espSettingsFrame=createUIElement(Instance.new("Frame"),{Name="ESPSettingsFrame",Size=UDim2.new(1,-16,1,-56),Position=UDim2.new(0,8,0,48),BackgroundColor3=Color3.fromRGB(45,45,60),BorderSizePixel=0,Visible=false})
espSettingsFrame.Parent=mainGuiFrame;addCorner(espSettingsFrame,10)

local espSettingsTitle=createUIElement(Instance.new("TextLabel"),{Name="TitleLabel",Size=UDim2.new(1,0,0,40),Position=UDim2.new(0,0,0,8),BackgroundTransparency=1,TextColor3=Color3.new(1,1,1),Font=Enum.Font.GothamBold,TextSize=16,Text=labels.espSettings,TextXAlignment=Enum.TextXAlignment.Center})
espSettingsTitle.Parent=espSettingsFrame

local espSettingsBack=createUIElement(Instance.new("TextButton"),{Name="BackButton",Size=UDim2.new(0,30,0,30),Position=UDim2.new(0,8,0,8),Text=labels.back,BackgroundColor3=Color3.fromRGB(60,60,90),TextColor3=Color3.new(1,1,1),Font=Enum.Font.GothamBold,TextSize=18,BorderSizePixel=0})
espSettingsBack.Parent=espSettingsFrame;addCorner(espSettingsBack,6)

local colorLabel=createUIElement(Instance.new("TextLabel"),{Name="ColorLabel",Size=UDim2.new(0.5,-10,0,25),Position=UDim2.new(0,15,0,55),BackgroundTransparency=1,TextColor3=Color3.new(1,1,1),Font=Enum.Font.Gotham,TextSize=12,Text=labels.color,TextXAlignment=Enum.TextXAlignment.Left})
colorLabel.Parent=espSettingsFrame

local colorNameLabel=createUIElement(Instance.new("TextLabel"),{Name="ColorNameLabel",Size=UDim2.new(0.45,-10,0,25),Position=UDim2.new(0.55,5,0,55),BackgroundTransparency=1,TextColor3=colorOptions[1][1],Font=Enum.Font.GothamBold,TextSize=12,Text=colorOptions[1][2],TextXAlignment=Enum.TextXAlignment.Center})
colorNameLabel.Parent=espSettingsFrame

for i,colData in ipairs(colorOptions) do
    local col,colName=colData[1],colData[2]
    local cb=createUIElement(Instance.new("TextButton"),{Size=UDim2.new(0,50,0,30),Position=UDim2.new(0,20+(i-1)*65,0,90),BackgroundColor3=col,TextColor3=Color3.new(0,0,0),Text="",BorderSizePixel=0})
    cb.Parent=espSettingsFrame;addCorner(cb,5)
    cb.MouseButton1Click:Connect(function()
        ESP_OUTLINE=col;ESP_FILL=col;selectedColorIndex=i
        colorNameLabel.TextColor3=col;colorNameLabel.Text=colName
        for _,hl in pairs(highlightedPlayers) do if hl and hl:IsA("Highlight") then hl.OutlineColor=col;hl.FillColor=col end end
    end)
end

local linesToggle=createUIElement(Instance.new("TextButton"),{Name="LinesToggle",Size=UDim2.new(1,-30,0,30),Position=UDim2.new(0,15,0,130),BackgroundColor3=espLinesEnabled and GUI_ACTIVE or GUI_BTN,TextColor3=Color3.new(1,1,1),Font=Enum.Font.GothamBold,TextSize=13,Text=labels.lines..": OFF",BorderSizePixel=0})
linesToggle.Parent=espSettingsFrame;addCorner(linesToggle,6)

local hotkeysFrame=createUIElement(Instance.new("Frame"),{Name="HotkeysFrame",Size=UDim2.new(1,-16,1,-56),Position=UDim2.new(0,8,0,48),BackgroundColor3=Color3.fromRGB(45,45,60),BorderSizePixel=0,Visible=false})
hotkeysFrame.Parent=mainGuiFrame;addCorner(hotkeysFrame,10)

local hotkeysTitleLabel=createUIElement(Instance.new("TextLabel"),{Name="HotkeysTitleLabel",Size=UDim2.new(1,0,0,50),Position=UDim2.new(0,0,0,15),BackgroundTransparency=1,TextColor3=Color3.new(1,1,1),Font=Enum.Font.GothamBold,TextSize=20,Text=labels.hotkeys,TextXAlignment=Enum.TextXAlignment.Center})
hotkeysTitleLabel.Parent=hotkeysFrame

local hotkeysBackButton=createUIElement(Instance.new("TextButton"),{Name="BackButton",Size=UDim2.new(0,30,0,30),Position=UDim2.new(0,8,0,8),Text=labels.back,BackgroundColor3=Color3.fromRGB(60,60,90),TextColor3=Color3.new(1,1,1),Font=Enum.Font.GothamBold,TextSize=18,BorderSizePixel=0})
hotkeysBackButton.Parent=hotkeysFrame;addCorner(hotkeysBackButton,6)

local function createKeybindButton(lbl,kbType,yPos)
    local fr=createUIElement(Instance.new("Frame"),{Size=UDim2.new(1,-40,0,40),Position=UDim2.new(0,20,0,yPos),BackgroundColor3=Color3.fromRGB(35,35,45),BorderSizePixel=0})
    fr.Parent=hotkeysFrame;addCorner(fr,8)
    local lt=createUIElement(Instance.new("TextLabel"),{Size=UDim2.new(0.45,-10,1,0),Position=UDim2.new(0,10,0,0),BackgroundTransparency=1,TextColor3=Color3.new(1,1,1),Font=Enum.Font.Gotham,TextSize=12,Text=lbl,TextXAlignment=Enum.TextXAlignment.Left,TextTruncate=Enum.TextTruncate.AtEnd})
    lt.Parent=fr
    local kb=createUIElement(Instance.new("TextButton"),{Name="KeyButton",Size=UDim2.new(0.45,-10,0,30),Position=UDim2.new(0.55,5,0.5,-15),BackgroundColor3=Color3.fromRGB(60,60,90),TextColor3=Color3.new(1,1,1),Font=Enum.Font.GothamBold,TextSize=12,BorderSizePixel=0,Text=formatKey(keybinds[kbType]),TextTruncate=Enum.TextTruncate.AtEnd})
    kb.Parent=fr;addCorner(kb,6)
    return kb
end

local menuKeyButton=createKeybindButton(labels.menuKey,"Menu",65)
local aimKeyButton=createKeybindButton(labels.aimKey,"Aim",115)

local function changeKeybind(btn,kbType)
    keybindLock=true
    btn.Text=labels.pressKey
    btn.BackgroundColor3=Color3.fromRGB(100,50,0)
    local conn;conn=UserInputService.InputBegan:Connect(function(ip)
        if ip.UserInputType==Enum.UserInputType.Keyboard then
            keybinds[kbType]=ip.KeyCode
            btn.Text=formatKey(ip.KeyCode)
            btn.BackgroundColor3=Color3.fromRGB(60,60,90)
            conn:Disconnect()
            task.delay(0.5,function()keybindLock=false end)
        end
    end)
end
menuKeyButton.MouseButton1Click:Connect(function()changeKeybind(menuKeyButton,"Menu")end)
aimKeyButton.MouseButton1Click:Connect(function()changeKeybind(aimKeyButton,"Aim")end)

local function setupESP(plr)
    if plr==player or isInLobbyTeam(plr) then return end
    local function apply(chr)
        if not chr or not chr:FindFirstChild("HumanoidRootPart")then return end
        local old=chr:FindFirstChild("ESP_HL")
        if old then old:Destroy()end
        if espEnabled then
            local hl=Instance.new("Highlight")
            hl.Name="ESP_HL"
            hl.Adornee=chr
            hl.FillColor=ESP_FILL
            hl.OutlineColor=ESP_OUTLINE
            hl.FillTransparency=0.5
            hl.OutlineTransparency=0.3
            hl.Enabled=true
            hl.Parent=chr
            highlightedPlayers[plr]=hl
        end
    end
    if plr.Character then apply(plr.Character)end
    plr.CharacterAdded:Connect(function(c)task.wait(0.5);if espEnabled then apply(c)end end)
end

local function removeESP(plr)
    if highlightedPlayers[plr]then highlightedPlayers[plr]:Destroy();highlightedPlayers[plr]=nil end
end

local connections = {}
local scriptActive = true

local function connectEvent(event, callback)
    local conn = event:Connect(callback)
    table.insert(connections, conn)
    return conn
end

local espLinesConnection = connectEvent(RunService.RenderStepped, function()
    if not scriptActive then return end
    if espEnabled and espLinesEnabled then
        local localChar = player.Character
        if not localChar or not localChar:FindFirstChild("HumanoidRootPart") then return end
        local localPos = localChar.HumanoidRootPart.Position
        for p,line in pairs(espLines) do if line and line.Parent then line:Destroy() end end
        espLines = {}
        for _,p in ipairs(Players:GetPlayers()) do
            if p~=player and not isInLobbyTeam(p) and p.Character and p.Character:FindFirstChild("HumanoidRootPart") then
                local targetHRP = p.Character.HumanoidRootPart
                local targetPos = targetHRP.Position
                local line = Instance.new("Part")
                line.Anchored = true; line.CanCollide = false; line.CastShadow = false
                line.Size = Vector3.new(0.1, 0.1, (targetPos - localPos).Magnitude)
                line.CFrame = CFrame.lookAt(localPos, targetPos) * CFrame.new(0, 0, -(targetPos - localPos).Magnitude / 2)
                line.Color = ESP_OUTLINE; line.Material = Enum.Material.Neon; line.Transparency = 0.3
                line.Parent = workspace
                espLines[p] = line
            end
        end
    else for p,line in pairs(espLines) do if line and line.Parent then line:Destroy() end end; espLines = {} end
end)

local espConnection = connectEvent(RunService.RenderStepped, function()
    if not scriptActive then return end
    if espEnabled then
        for _,p in ipairs(Players:GetPlayers())do 
            if p~=player and not isInLobbyTeam(p) and not highlightedPlayers[p] and p.Character and p.Character:FindFirstChild("HumanoidRootPart")then 
                setupESP(p)
            end 
        end
        for _,hl in pairs(highlightedPlayers) do if hl and hl:IsA("Highlight") then hl.OutlineColor=ESP_OUTLINE;hl.FillColor=ESP_FILL end end
    else for p,_ in pairs(highlightedPlayers)do removeESP(p)end end
end)

connectEvent(Players.PlayerAdded, function(p)
    if espEnabled and p~=player and not isInLobbyTeam(p) then 
        setupESP(p)
    end 
end)
connectEvent(Players.PlayerRemoving, function(p)removeESP(p)end)

local aimbotConnection = connectEvent(RunService.RenderStepped, function()
    if not scriptActive then return end
    if aimbotEnabled and UserInputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton2)then
        if not currentTarget then 
            local best,dMin=nil,math.huge
            local center=camera.ViewportSize/2
            local lp=player.Character and player.Character:FindFirstChild("HumanoidRootPart")
            if lp then
                for _,p in ipairs(Players:GetPlayers())do
                    if p~=player and p.Character then
                        local hd=p.Character:FindFirstChild("Head")
                        local hm=p.Character:FindFirstChild("Humanoid")
                        if hd and hm and hm.Health>0 then
                            local d3=(lp.Position-hd.Position).Magnitude
                            local pt,os=camera:WorldToViewportPoint(hd.Position)
                            local d2=(Vector2.new(pt.X,pt.Y)-center).Magnitude
                            if os and d2<dMin and d2<=FOV then best,dMin=p,d2 end
                        end
                    end
                end
            end
            currentTarget = best
        end
        if currentTarget and currentTarget.Character then
            local hd=currentTarget.Character:FindFirstChild("Head")
            if hd then
                local v=hd.Velocity or Vector3.new(0,0,0)
                local pr=math.clamp(PREDICTION_FACTOR+(currentTargetDistance or 100)/2000,0.02,0.1)
                local pred=hd.Position+(v*pr)
                camera.CFrame=camera.CFrame:Lerp(CFrame.new(camera.CFrame.Position,pred),AIM_SMOOTHNESS)
            else currentTarget=nil end
        end
    else currentTarget=nil end
end)

local function updateLabels()
    if not scriptActive then return end
    titleLabel.Text=labels.title
    espButton.Text=espEnabled and labels.espOn or labels.espOff
    aimButton.Text=aimbotEnabled and labels.aimOn or labels.aimOff
    hotkeysButton.Text=labels.hotkeys
    espSettingsTitle.Text=labels.espSettings
    colorLabel.Text=labels.color
    linesToggle.Text=labels.lines..": "..(espLinesEnabled and "ON" or "OFF")
    menuKeyButton.Text=formatKey(keybinds.Menu)
    aimKeyButton.Text=formatKey(keybinds.Aim)
end

local function showMinimizeNotification()
    if notificationActive then return end
    notificationActive = true
    
    local keyStr = formatKey(keybinds.Menu)
    local message = "Press ["..keyStr.."] to reopen menu"
    
    local notifGui = Instance.new("ScreenGui")
    notifGui.Name = "FLK_MinimizeNotification"
    notifGui.ResetOnSpawn = false
    notifGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    notifGui.Parent = game.CoreGui  
    
    local notifFrame = Instance.new("Frame")
    notifFrame.Name = "Notification"
    notifFrame.Size = UDim2.new(0, 280, 0, 50)
    notifFrame.Position = UDim2.new(1, 300, 1, -70)
    notifFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 50)
    notifFrame.BorderSizePixel = 0
    notifFrame.Parent = notifGui
    
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 10)
    corner.Parent = notifFrame
    
    local stroke = Instance.new("UIStroke")
    stroke.Color = ESP_OUTLINE
    stroke.Thickness = 2
    stroke.Parent = notifFrame
    
    local textLabel = Instance.new("TextLabel")
    textLabel.Size = UDim2.new(1, -20, 1, -10)
    textLabel.Position = UDim2.new(0, 10, 0, 5)
    textLabel.BackgroundTransparency = 1
    textLabel.Text = message
    textLabel.TextColor3 = Color3.new(1, 1, 1)
    textLabel.Font = Enum.Font.Gotham
    textLabel.TextSize = 13
    textLabel.TextXAlignment = Enum.TextXAlignment.Left
    textLabel.TextYAlignment = Enum.TextYAlignment.Center
    textLabel.Parent = notifFrame
    
    notifFrame:TweenPosition(
        UDim2.new(1, -300, 1, -70),
        Enum.EasingDirection.Out,
        Enum.EasingStyle.Quart,
        0.4,
        true
    )
    
    task.delay(3, function()
        if notifFrame and notifFrame.Parent then
            notifFrame:TweenPosition(
                UDim2.new(1, 300, 1, -70),
                Enum.EasingDirection.In,
                Enum.EasingStyle.Quart,
                0.4,
                true
            )
            task.wait(0.4)
            notifGui:Destroy()
        end
        notificationActive = false
    end)
end

local function toggleGui()
    if not scriptActive then return end
    menuVisible=not menuVisible
    if menuVisible then 
        mainGuiFrame.Visible=true
        contentFrame.Visible=true
        espSettingsFrame.Visible=false
        hotkeysFrame.Visible=false
    else 
        mainGuiFrame.Visible=false
        showMinimizeNotification()
        local keyStr = formatKey(keybinds.Menu)
        if isRussian then
            print("Нажмите ["..keyStr.."] чтобы открыть меню")
        else
            print("Press ["..keyStr.."] to reopen menu")
        end
        pcall(function() 
            if isRussian then
                player:Chat("/me Нажмите ["..keyStr.."] чтобы открыть меню")
            else
                player:Chat("/me Press ["..keyStr.."] to open menu")
            end
        end)
    end
end

local function cleanupAndDestroy()
    scriptActive = false
    espEnabled = false
    aimbotEnabled = false
    espLinesEnabled = false
    
    for p,_ in pairs(highlightedPlayers) do removeESP(p) end
    highlightedPlayers = {}
    
    for p,line in pairs(espLines) do
        if line and line.Parent then line:Destroy() end
    end
    espLines = {}
    
    for _,conn in ipairs(connections) do
        pcall(function()
            if conn and conn.Connected then
                conn:Disconnect()
            end
        end)
    end
    connections = {}
    
    _G.FLK_ScriptRunning = false
    _G.FLK_CleanupFunction = nil
    
    pcall(function()
        if screenGui then screenGui:Destroy() end
    end)
    
    if isRussian then
        print("FLK SOFT - Скрипт закрыт")
    else
        print("FLK SOFT - Script closed")
    end
end

_G.FLK_CleanupFunction = cleanupAndDestroy
_G.FLK_ScriptRunning = true

espButton.MouseButton1Click:Connect(function()if scriptActive then espEnabled=not espEnabled;espButton.BackgroundColor3=espEnabled and GUI_ACTIVE or GUI_BTN;espButton.Text=espEnabled and labels.espOn or labels.espOff end end)
aimButton.MouseButton1Click:Connect(function()if scriptActive then aimbotEnabled=not aimbotEnabled;aimButton.BackgroundColor3=aimbotEnabled and Color3.fromRGB(100,0,0)or GUI_BTN;aimButton.Text=aimbotEnabled and labels.aimOn or labels.aimOff end end)
hotkeysButton.MouseButton1Click:Connect(function()if scriptActive then contentFrame.Visible=false;espSettingsFrame.Visible=false;hotkeysFrame.Visible=true end end)
espSettingsButton.MouseButton1Click:Connect(function()if scriptActive then contentFrame.Visible=false;hotkeysFrame.Visible=false;espSettingsFrame.Visible=true end end)
espSettingsBack.MouseButton1Click:Connect(function()if scriptActive then espSettingsFrame.Visible=false;contentFrame.Visible=true end end)
hotkeysBackButton.MouseButton1Click:Connect(function()if scriptActive then hotkeysFrame.Visible=false;contentFrame.Visible=true end end)
linesToggle.MouseButton1Click:Connect(function()if scriptActive then espLinesEnabled=not espLinesEnabled;linesToggle.BackgroundColor3=espLinesEnabled and GUI_ACTIVE or GUI_BTN;linesToggle.Text=labels.lines..": "..(espLinesEnabled and "ON" or "OFF")end end)
minimizeButton.MouseButton1Click:Connect(function()if scriptActive then toggleGui() end end)
closeButton.MouseButton1Click:Connect(function()cleanupAndDestroy()end)

connectEvent(UserInputService.InputBegan, function(ip,gp)
    if not scriptActive then return end
    if gp or keybindLock then return end
    if ip.KeyCode==keybinds.Menu then toggleGui()
    elseif ip.KeyCode==keybinds.Aim then 
        aimbotEnabled=not aimbotEnabled
        aimButton.BackgroundColor3=aimbotEnabled and Color3.fromRGB(100,0,0)or GUI_BTN
        aimButton.Text=aimbotEnabled and labels.aimOn or labels.aimOff 
    end
end)

task.wait(1)
if scriptActive then
    for _,p in ipairs(Players:GetPlayers())do 
        if p~=player and not isInLobbyTeam(p) then 
            setupESP(p)
        end 
    end
    updateLabels()
end
