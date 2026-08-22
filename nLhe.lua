-- ==========================================
-- nLhe 0.3.3 — ПОЛНАЯ ВЕРСИЯ
-- ЧАСТЬ 1: ЗАГРУЗЧИК + UI SETTINGS
-- ==========================================

print("🔄 Loading nLhe...")

-- ==========================================
-- 1. БИБЛИОТЕКИ
-- ==========================================

local repo = "https://raw.githubusercontent.com/deividcomsono/Obsidian/main/"
local Library = loadstring(game:HttpGet(repo .. "Library.lua"))()
local ThemeManager = loadstring(game:HttpGet(repo .. "addons/ThemeManager.lua"))()
local SaveManager = loadstring(game:HttpGet(repo .. "addons/SaveManager.lua"))()

-- ==========================================
-- 2. СОЗДАНИЕ ОКНА
-- ==========================================

local Window = Library:CreateWindow({
    Title = "nLhe",
    Footer = "v0.3.3 · Obsidian UI",
    Center = true,
    AutoShow = true,
    NotifySide = "Right",
    ShowCustomCursor = true,
})

-- ==========================================
-- 3. ТАБЫ
-- ==========================================

local Tabs = {
    Defense    = Window:AddTab("Defense",     "shield"),
    Target     = Window:AddTab("Target",      "crosshair"),
    Player     = Window:AddTab("Player",      "user"),
    Teleport   = Window:AddTab("Teleport",    "map-pin"),
    Auras      = Window:AddTab("Auras",       "sparkles"),
    Server     = Window:AddTab("Server",      "server"),
    Keybinds   = Window:AddTab("Keybinds",    "keyboard"),
    Visuals    = Window:AddTab("Visuals",     "eye"),
    Toys       = Window:AddTab("Toys",        "shapes"),
    Figure     = Window:AddTab("Figure Grab", "mouse"),
    UISettings = Window:AddTab("UI Settings", "settings"),
}

-- ==========================================
-- 4. ГЛОБАЛЬНЫЕ ПЕРЕМЕННЫЕ
-- ==========================================

_G.nLhe = {
    Tabs = Tabs,
    Library = Library,
    ThemeManager = ThemeManager,
    SaveManager = SaveManager,
    Window = Window,
    Players = game:GetService("Players"),
    UIS = game:GetService("UserInputService"),
    CoreGui = game:GetService("CoreGui"),
    RS = game:GetService("ReplicatedStorage"),
    RunService = game:GetService("RunService"),
    Workspace = game:GetService("Workspace"),
    Lighting = game:GetService("Lighting"),
    TweenService = game:GetService("TweenService"),
    Stats = game:GetService("Stats"),
    Debris = game:GetService("Debris"),
    SoundService = game:GetService("SoundService"),
    plr = game:GetService("Players").LocalPlayer,
    bool = {},
    int = {},
    cons = {},
    etc = {SelectedTarget = nil, FG_Target = nil},
}

-- ==========================================
-- 5. ВСПОМОГАТЕЛЬНЫЕ ФУНКЦИИ
-- ==========================================

function _G.nLhe.discCon(key)
    if _G.nLhe.cons[key] then
        _G.nLhe.cons[key]:Disconnect()
        _G.nLhe.cons[key] = nil
    end
end

function _G.nLhe.notify(title, content, duration)
    _G.nLhe.Library:Notify({
        Title = title or "nLhe",
        Content = content or "",
        Duration = duration or 5,
    })
end

function _G.nLhe.sno(part)
    if not part or not part.Parent then return end
    local setOwner = _G.nLhe.RS:FindFirstChild("GrabEvents") and _G.nLhe.RS.GrabEvents:FindFirstChild("SetNetworkOwner")
    pcall(function() if setOwner then setOwner:FireServer(part, part.CFrame) end end)
end

function _G.nLhe.GetMagnitude(a, b)
    return (a.Position - b.Position).Magnitude
end

-- ==========================================
-- 6. HUD
-- ==========================================

local function CreateHUD()
    local hudFrame = Instance.new("ScreenGui")
    hudFrame.Name = "nLhe_HUD"
    hudFrame.ResetOnSpawn = false
    hudFrame.Parent = _G.nLhe.CoreGui

    local function CreateBlock(text, color, pos, size)
        local f = Instance.new("Frame")
        f.Size = size or UDim2.new(0, 85, 0, 28)
        f.Position = pos
        f.BackgroundColor3 = Color3.fromRGB(10, 10, 16)
        f.BackgroundTransparency = 0.15
        f.BorderSizePixel = 0
        f.ZIndex = 2
        f.Parent = hudFrame
        Instance.new("UICorner", f).CornerRadius = UDim.new(0, 8)
        local l = Instance.new("TextLabel")
        l.Size = UDim2.new(1, 0, 1, 0)
        l.Text = text
        l.TextColor3 = color
        l.BackgroundTransparency = 1
        l.Font = Enum.Font.GothamBold
        l.TextSize = 13
        l.TextXAlignment = Enum.TextXAlignment.Center
        l.ZIndex = 3
        l.Parent = f
        return {Frame = f, Label = l}
    end

    local cx = 0.5
    local sx = -350
    local sp = 95
    local plr = _G.nLhe.plr

    CreateBlock("✦ nLhe", Color3.fromRGB(180, 120, 255), UDim2.new(cx, sx, 0, 6), UDim2.new(0, 80, 0, 28))
    CreateBlock("✦ " .. (plr.DisplayName or plr.Name), Color3.fromRGB(200, 220, 255), UDim2.new(cx, sx + sp * 1, 0, 6), UDim2.new(0, 110, 0, 28))
    local fpsBlock = CreateBlock("FPS: --", Color3.fromRGB(100, 200, 255), UDim2.new(cx, sx + sp * 2, 0, 6), UDim2.new(0, 85, 0, 28))
    local pingBlock = CreateBlock("Ping: -- ms", Color3.fromRGB(100, 220, 120), UDim2.new(cx, sx + sp * 3, 0, 6), UDim2.new(0, 95, 0, 28))
    local timeBlock = CreateBlock("00:00:00", Color3.fromRGB(180, 180, 200), UDim2.new(cx, sx + sp * 4, 0, 6), UDim2.new(0, 85, 0, 28))

    local fpsCount = 0
    local lastTick = tick()

    _G.nLhe.RunService.Heartbeat:Connect(function()
        fpsCount = fpsCount + 1
        local now = tick()
        if now - lastTick >= 1 then
            local cfps = fpsCount
            fpsCount = 0
            lastTick = now
            fpsBlock.Label.Text = "FPS: " .. cfps
            fpsBlock.Label.TextColor3 = cfps >= 55 and Color3.fromRGB(100, 200, 255) or cfps >= 30 and Color3.fromRGB(240, 200, 60) or Color3.fromRGB(240, 80, 80)
            local t = os.date("*t")
            timeBlock.Label.Text = string.format("%02d:%02d:%02d", t.hour, t.min, t.sec)
            local ping = nil
            pcall(function()
                local stats = _G.nLhe.Stats
                local network = stats:FindFirstChild("Network")
                if network then
                    local ss = network:FindFirstChild("ServerStatsItem")
                    if ss then
                        local dp = ss:FindFirstChild("Data Ping")
                        if dp then ping = math.floor(dp:GetValue()) end
                    end
                end
            end)
            if ping then
                pingBlock.Label.Text = "Ping: " .. ping .. " ms"
                pingBlock.Label.TextColor3 = ping < 60 and Color3.fromRGB(80, 220, 100) or ping < 150 and Color3.fromRGB(240, 200, 60) or Color3.fromRGB(240, 80, 80)
            else
                pingBlock.Label.Text = "Ping: -- ms"
                pingBlock.Label.TextColor3 = Color3.fromRGB(180, 180, 200)
            end
        end
    end)

    return hudFrame
end

CreateHUD()

-- ==========================================
-- 7. UI SETTINGS
-- ==========================================

local MenuGroup = Tabs.UISettings:AddLeftGroupbox("Menu", "user-lock")
local BackGroup = Tabs.UISettings:AddRightGroupbox("Background", "mail")

MenuGroup:AddToggle("KeybindMenuOpen", {
    Name = "Open Keybind Menu",
    Default = Library.KeybindFrame.Visible,
    Callback = function(v) Library.KeybindFrame.Visible = v end
})

MenuGroup:AddToggle("ShowCustomCursor", {
    Name = "Custom Cursor",
    Default = true,
    Callback = function(v) Library.ShowCustomCursor = v end
})

MenuGroup:AddDropdown("NotificationSide", {
    Name = "Notification Side",
    Values = {"Left", "Right"},
    Default = "Right",
    Callback = function(v) Library:SetNotifySide(v) end
})

MenuGroup:AddDropdown("DPIDropdown", {
    Name = "DPI Scale",
    Values = {"50%", "75%", "100%", "125%", "150%", "175%", "200%"},
    Default = "100%",
    Callback = function(v)
        local val = tonumber(v:gsub("%%", "")) or 100
        Library:SetDPIScale(val)
    end
})

MenuGroup:AddLabel("Menu bind"):AddKeyPicker("MenuKeybind", {
    Default = "RightShift",
    NoUI = true,
    Text = "Menu keybind"
})

MenuGroup:AddButton({
    Name = "Unload",
    Callback = function() Library:Unload() end,
    DoubleClick = false
})

-- Background
local bgData = {Enabled = true, Image = "0", Last = nil, Transparency = 0.15}
local bgToken = 0

local function formatImage(id)
    id = tostring(id or ""):gsub("%s+", "")
    if id == "" then return "rbxassetid://0" end
    if id:find("rbxassetid://") then return id end
    return "rbxassetid://" .. id
end

local function applyBackground()
    bgToken = bgToken + 1
    local current = bgToken
    task.delay(0.05, function()
        if current ~= bgToken then return end
        local image = bgData.Enabled and formatImage(bgData.Image) or "rbxassetid://0"
        if bgData.Last == image then return end
        bgData.Last = image
        pcall(function()
            Window:SetBackgroundImage(image)
            Window:SetBackgroundTransparency(bgData.Transparency)
        end)
    end)
end

BackGroup:AddToggle("EnableBackground", {
    Name = "Enable Background",
    Default = true,
    Callback = function(v)
        bgData.Enabled = v
        applyBackground()
    end
})

BackGroup:AddInput("BackgroundAsset", {
    Name = "Asset ID",
    Default = "0",
    Callback = function(v)
        bgData.Image = tostring(v)
        applyBackground()
    end
})

BackGroup:AddButton({
    Name = "Clear Background",
    Callback = function()
        bgData.Image = "0"
        applyBackground()
    end
})

applyBackground()

-- ==========================================
-- 8. ТЕМЫ И СОХРАНЕНИЯ
-- ==========================================

Library.ToggleKeybind = Options.MenuKeybind

ThemeManager:SetLibrary(Library)
SaveManager:SetLibrary(Library)
SaveManager:IgnoreThemeSettings()
SaveManager:SetIgnoreIndexes({"MenuKeybind"})
ThemeManager:SetFolder("nLhe")
SaveManager:SetFolder("nLhe/Configs")
ThemeManager:ApplyToTab(Tabs.UISettings)
SaveManager:BuildConfigSection(Tabs.UISettings)

Window:SetCornerRadius(20)
Library.ShowCustomCursor = true

-- ==========================================
-- ЧАСТЬ 2: DEFENSE
-- ==========================================

print("🔄 Loading Defense...")

local plr = _G.nLhe.plr
local RS = _G.nLhe.RS
local RunService = _G.nLhe.RunService
local Workspace = _G.nLhe.Workspace
local Players = _G.nLhe.Players

local SetNetworkOwner = RS:FindFirstChild("GrabEvents") and RS.GrabEvents:FindFirstChild("SetNetworkOwner")
local DestroyToy = RS:FindFirstChild("MenuToys") and RS.MenuToys:FindFirstChild("DestroyToy")
local RagdollRemote = RS:FindFirstChild("CharacterEvents") and RS.CharacterEvents:FindFirstChild("RagdollRemote")
local Struggle = RS:FindFirstChild("CharacterEvents") and RS.CharacterEvents:FindFirstChild("Struggle")
local SpawnToyRemote = RS:FindFirstChild("MenuToys") and RS.MenuToys:FindFirstChild("SpawnToyRemoteFunction")
local DestroyGrabLine = RS:FindFirstChild("GrabEvents") and RS.GrabEvents:FindFirstChild("DestroyGrabLine")
local CreateGrabLine = RS:FindFirstChild("GrabEvents") and RS.GrabEvents:FindFirstChild("CreateGrabLine")
local StickyEvent = RS:FindFirstChild("PlayerEvents") and RS.PlayerEvents:FindFirstChild("StickyPartEvent")

local DefGroup = _G.nLhe.Tabs.Defense:AddLeftGroupbox("Defense", "shield")
local DefExtra = _G.nLhe.Tabs.Defense:AddRightGroupbox("Extra Defense", "shield")
local AntiKickGroup = _G.nLhe.Tabs.Defense:AddLeftGroupbox("Anti-Kick", "shield")

local bool = _G.nLhe.bool
local int = _G.nLhe.int
local cons = _G.nLhe.cons
local etc = _G.nLhe.etc

local function discCon(key) _G.nLhe.discCon(key) end
local function notify(t, c, d) _G.nLhe.notify(t, c, d) end
local function sno(part) _G.nLhe.sno(part) end
local function GetMagnitude(a, b) return _G.nLhe.GetMagnitude(a, b) end

-- ==========================================
-- 2.1. ANTI GRAB [BEST]
-- ==========================================

do
    local AntiGrab = false
    local AntiGrabProc = false
    local AGWalk = false
    local Cons = {}

    local function DiscAll()
        for k, v in pairs(Cons) do
            if v then v:Disconnect() end
        end
        table.clear(Cons)
    end

    local function ApplyAntiGrab(char)
        if not char or not AntiGrab then return end

        local hrp = char:WaitForChild("HumanoidRootPart", 5)
        local hum = char:WaitForChild("Humanoid", 5)
        local head = char:WaitForChild("Head", 5)
        if not (hrp and hum and head) then return end

        for _, v in pairs(char:GetChildren()) do
            if v:IsA("BasePart") and v:FindFirstChild("BallSocketConstraint") and v.Name ~= "Head" then
                v.BallSocketConstraint.Enabled = false
                if v:FindFirstChild("RagdollLimbPart") then
                    v.RagdollLimbPart.WeldConstraint.Enabled = false
                end
            end
        end

        Cons["AGHead"] = head.ChildAdded:Connect(function(PartOwner)
            if PartOwner.Name == "PartOwner" then
                if not AntiGrabProc then
                    AntiGrabProc = true
                    hum.Sit = false
                    if Struggle then Struggle:FireServer(plr) end

                    task.spawn(function()
                        while (head and head:FindFirstChild("PartOwner")) or (plr:FindFirstChild("IsHeld") and plr.IsHeld.Value) do
                            if Struggle then Struggle:FireServer(plr) end
                            if RagdollRemote then RagdollRemote:FireServer(hrp, 0) end
                            task.wait()
                        end
                    end)

                    hrp.Anchored = true
                    if not AGWalk then
                        AGWalk = true
                        while plr:FindFirstChild("IsHeld") and plr.IsHeld.Value and task.wait() do
                            hrp.CFrame = hrp.CFrame + hum.MoveDirection * 0.43
                        end
                    end
                    hrp.Anchored = false
                    AntiGrabProc = false
                    AGWalk = false
                end
            end
        end)
    end

    DefGroup:AddToggle("AntiGrabBest", {
        Name = "Anti Grab [BEST (use solo)]",
        Default = false,
        Callback = function(Value)
            AntiGrab = Value
            DiscAll()

            if AntiGrab then
                ApplyAntiGrab(plr.Character)
                Cons["AGChar"] = plr.CharacterAdded:Connect(ApplyAntiGrab)
                notify("nLhe", "Anti Grab [BEST]: ON", 2)
            else
                local char = plr.Character
                if char then
                    for _, v in pairs(char:GetChildren()) do
                        if v:IsA("BasePart") and v:FindFirstChild("BallSocketConstraint") and v.Name ~= "Head" then
                            v.BallSocketConstraint.Enabled = false
                            if v:FindFirstChild("RagdollLimbPart") then
                                v.RagdollLimbPart.WeldConstraint.Enabled = true
                            end
                        end
                    end
                end
                notify("nLhe", "Anti Grab [BEST]: OFF", 2)
            end
        end
    })
end

-- ==========================================
-- 2.2. ANTI GRAB V2
-- ==========================================

do
    local AntiGrabEnabled = false
    local HeldConnection = nil

    local isHeld = plr:FindFirstChild("IsHeld") or plr:WaitForChild("IsHeld", 10)
    if not isHeld then return end

    local struggleEvent = RS:FindFirstChild("CharacterEvents") and RS.CharacterEvents:FindFirstChild("Struggle")

    local function StopAntiGrab()
        AntiGrabEnabled = false
        if HeldConnection then HeldConnection:Disconnect(); HeldConnection = nil end
        local Root = plr.Character and plr.Character:FindFirstChild("HumanoidRootPart")
        if Root then Root.Anchored = false end
        if plr.Character then
            for _, part in pairs(plr.Character:GetDescendants()) do
                if part:IsA("BasePart") then part.CanCollide = true end
            end
        end
    end

    local function StartAntiGrab()
        if HeldConnection then HeldConnection:Disconnect() end
        HeldConnection = isHeld:GetPropertyChangedSignal("Value"):Connect(function()
            if not AntiGrabEnabled or not isHeld.Value then return end
            local Char = plr.Character
            if not Char then return end

            local Root = Char:FindFirstChild("HumanoidRootPart")
            local Hum = Char:FindFirstChildOfClass("Humanoid")

            for _, part in pairs(Char:GetDescendants()) do
                if part:IsA("BasePart") then part.CanCollide = false end
            end

            task.spawn(function()
                while AntiGrabEnabled and isHeld.Value do
                    pcall(function()
                        if struggleEvent then struggleEvent:FireServer() end
                        if RagdollRemote then RagdollRemote:FireServer(Root, 0) end
                        if RS:FindFirstChild("GameCorrectionEvents") and RS.GameCorrectionEvents:FindFirstChild("StopAllVelocity") then
                            RS.GameCorrectionEvents.StopAllVelocity:FireServer()
                        end
                    end)
                    task.wait()
                end
            end)

            task.spawn(function()
                while AntiGrabEnabled and isHeld.Value do
                    pcall(function()
                        if Hum then
                            Hum.Sit = false
                            Hum:ChangeState(Enum.HumanoidStateType.GettingUp)
                            Hum:SetStateEnabled(Enum.HumanoidStateType.Jumping, true)
                        end
                        if Root then
                            Root.Anchored = true
                            Root.AssemblyLinearVelocity = Vector3.zero
                            Root.AssemblyAngularVelocity = Vector3.zero
                        end
                    end)
                    task.wait()
                end
                if Root then Root.Anchored = false end
            end)
        end)
    end

    DefGroup:AddToggle("AntiGrabV2", {
        Name = "Anti Grab V2 (anti perm die)",
        Default = false,
        Callback = function(Value)
            AntiGrabEnabled = Value
            if Value then
                StartAntiGrab()
                notify("nLhe", "Anti Grab V2: ON", 2)
            else
                StopAntiGrab()
                notify("nLhe", "Anti Grab V2: OFF", 2)
            end
        end
    })

    plr.CharacterAdded:Connect(function(char)
        task.wait(1)
        if AntiGrabEnabled and isHeld.Value then StartAntiGrab() end
    end)
end

-- ==========================================
-- 2.3. ANTI BANANA [SIT]
-- ==========================================

do
    local antibananaSit = false

    DefGroup:AddToggle("AntiBananaSit", {
        Name = "Anti Banana [SIT]",
        Default = false,
        Callback = function(Value)
            antibananaSit = Value

            task.spawn(function()
                while antibananaSit do
                    local char = plr.Character
                    if char then
                        local hum = char:FindFirstChildOfClass("Humanoid")
                        local hrp = char:FindFirstChild("HumanoidRootPart")
                        if hum and hrp and hum.Health > 0 then
                            hum.Sit = true
                            hum:ChangeState(Enum.HumanoidStateType.Running)
                            local Vec = Workspace.CurrentCamera.CFrame.LookVector
                            hrp.CFrame = CFrame.new(hrp.Position, hrp.Position + Vector3.new(Vec.X, 0, Vec.Z))
                        end
                    end
                    task.wait()
                end
            end)
            notify("nLhe", "Anti Banana [SIT]: " .. (Value and "ON" or "OFF"), 2)
        end
    })
end

-- ==========================================
-- 2.4. ANTI SNOWBALL
-- ==========================================

local loopRagdoll = false
DefGroup:AddToggle("AntiSnowball", {
    Name = "Anti Snowball",
    Default = false,
    Callback = function(Value)
        loopRagdoll = Value

        if Value then
            task.spawn(function()
                while loopRagdoll and task.wait(0.05) do
                    pcall(function()
                        local char = plr.Character
                        local hrp = char and char:FindFirstChild("HumanoidRootPart")
                        if hrp and RagdollRemote then
                            RagdollRemote:FireServer(hrp, 0.5)
                        end
                    end)
                end
            end)
        end
        notify("nLhe", "Anti Snowball: " .. (Value and "ON" or "OFF"), 2)
    end
})

-- ==========================================
-- 2.5. AUTO RESET
-- ==========================================

DefGroup:AddToggle("AutoReset", {
    Name = "Auto Reset",
    Default = false,
    Callback = function(v)
        if _G.AutoResetCon then _G.AutoResetCon:Disconnect() end

        if v then
            local gameCorrections = RS:FindFirstChild("GameCorrectionEvents")
            if gameCorrections and gameCorrections:FindFirstChild("GameCorrectionsNotify") then
                _G.AutoResetCon = gameCorrections.GameCorrectionsNotify.OnClientEvent:Connect(function(r)
                    if r == "Flying" then
                        local char = plr.Character
                        local hum = char and char:FindFirstChildOfClass("Humanoid")
                        if hum then
                            notify("nLhe", "Resetting to prevent Ban", 3)
                            char:BreakJoints()
                            hum.Health = 0
                        end
                    end
                end)
            end
        end
        notify("nLhe", "Auto Reset: " .. (v and "ON" or "OFF"), 2)
    end
})

-- ==========================================
-- 2.6. AUTO LEAVE
-- ==========================================

DefGroup:AddToggle("AutoLeave", {
    Name = "Auto Leave",
    Default = false,
    Callback = function(v)
        if _G.AutoLeaveCon then _G.AutoLeaveCon:Disconnect() end

        if v then
            local warnTimestamps = {}
            local gameCorrections = RS:FindFirstChild("GameCorrectionEvents")
            if gameCorrections and gameCorrections:FindFirstChild("GameCorrectionsNotify") then
                _G.AutoLeaveCon = gameCorrections.GameCorrectionsNotify.OnClientEvent:Connect(function(r)
                    if r == "Flying" then
                        local currentTime = os.clock()
                        table.insert(warnTimestamps, currentTime)
                        for i = #warnTimestamps, 1, -1 do
                            if currentTime - warnTimestamps[i] > 1 then
                                table.remove(warnTimestamps, i)
                            end
                        end
                        if #warnTimestamps >= 3 then
                            plr:Kick("nLhe Safety: Disconnected to prevent ban.")
                        end
                    end
                end)
            end
        end
        notify("nLhe", "Auto Leave: " .. (v and "ON" or "OFF"), 2)
    end
})

-- ==========================================
-- 2.7. ANTI VOID
-- ==========================================

DefGroup:AddToggle("AntiVoid", {
    Name = "Anti Void",
    Default = false,
    Callback = function(v)
        if v then
            Workspace.FallenPartsDestroyHeight = 0/0
        else
            Workspace.FallenPartsDestroyHeight = -100
        end
        notify("nLhe", "Anti Void: " .. (v and "ON" or "OFF"), 2)
    end
})

-- ==========================================
-- 2.8. ANTI BLOB
-- ==========================================

local antiblob = false
DefGroup:AddToggle("AntiBlob", {
    Name = "Anti Blob",
    Default = false,
    Callback = function(Value)
        antiblob = Value

        if antiblob and plr.Character then
            if not plr.Character:FindFirstChild("TruePositionPart") then
                local truePosPart = Instance.new("Part")
                truePosPart.Parent = plr.Character
                truePosPart.Name = "TruePositionPart"
                truePosPart.Anchored = true
                truePosPart.Transparency = 0.8
                truePosPart.CanCollide = false
                truePosPart.Size = Vector3.new(0.1, 0.1, 0.1)
                truePosPart.CFrame = CFrame.new(0, -10000000, 0)
            end
        end

        task.spawn(function()
            while antiblob and task.wait() do
                if plr.Character then
                    local hrp = plr.Character:FindFirstChild("HumanoidRootPart")
                    local truePosPart = plr.Character:FindFirstChild("TruePositionPart")

                    if hrp and truePosPart then
                        local rootAttachment = hrp:FindFirstChild("RootAttachment")
                        if rootAttachment and rootAttachment.Parent == hrp then
                            rootAttachment.Parent = truePosPart
                        end

                        local isGrabbed = false
                        for _, part in pairs(plr.Character:GetChildren()) do
                            if part:IsA("Part") and part.Massless then
                                part.Massless = false
                                isGrabbed = true
                            end
                        end

                        if isGrabbed then
                            hrp.AssemblyLinearVelocity = Vector3.new(0, 15000000, 0)

                            local function fireDrop(item)
                                local blobScript = item:FindFirstChild("BlobmanSeatAndOwnerScript")
                                local rightDetector = item:FindFirstChild("RightDetector")
                                local leftDetector = item:FindFirstChild("LeftDetector")
                                if blobScript and rightDetector and leftDetector then
                                    local dropEvent = blobScript:FindFirstChild("CreatureDrop")
                                    local rightWeld = rightDetector:FindFirstChild("RightWeld")
                                    local leftWeld = leftDetector:FindFirstChild("LeftWeld")
                                    if dropEvent then
                                        if rightWeld then dropEvent:FireServer(rightWeld, hrp) end
                                        if leftWeld then dropEvent:FireServer(leftWeld, hrp) end
                                    end
                                    if RS:FindFirstChild("CharacterEvents") and RS.CharacterEvents:FindFirstChild("Struggle") then
                                        RS.CharacterEvents.Struggle:FireServer(plr)
                                    end
                                end
                            end

                            for _, plot in pairs(Workspace.PlotItems:GetChildren()) do
                                if plot.Name ~= "PlayersInPlots" then
                                    for _, item in pairs(plot:GetChildren()) do
                                        if item.Name == "CreatureBlobman" then
                                            fireDrop(item)
                                        end
                                    end
                                end
                            end

                            for _, plr in pairs(Players:GetPlayers()) do
                                local toyFolder = Workspace:FindFirstChild(plr.Name .. "SpawnedInToys")
                                if toyFolder then
                                    for _, item in pairs(toyFolder:GetChildren()) do
                                        if item.Name == "CreatureBlobman" then
                                            fireDrop(item)
                                        end
                                    end
                                end
                            end
                        end
                    end
                end
            end
        end)

        if not antiblob and plr.Character then
            local hrp = plr.Character:FindFirstChild("HumanoidRootPart")
            local truePosPart = plr.Character:FindFirstChild("TruePositionPart")
            if hrp and truePosPart then
                local rootAttachment = truePosPart:FindFirstChild("RootAttachment")
                if rootAttachment then rootAttachment.Parent = hrp end
                truePosPart:Destroy()
            end
        end
        notify("nLhe", "Anti Blob: " .. (Value and "ON" or "OFF"), 2)
    end,
})

-- ==========================================
-- 2.9. ANTI-BLOBMAN AURA
-- ==========================================

local auraConnection = nil

DefGroup:AddToggle("AntiBlobmanAura", {
    Name = "Anti-Blobman Aura",
    Default = false,
    Callback = function(enabled)
        if auraConnection then auraConnection:Disconnect() end

        if enabled then
            auraConnection = RunService.Heartbeat:Connect(function()
                local myCharacter = plr.Character
                local myRootPart = myCharacter and myCharacter:FindFirstChild("HumanoidRootPart")
                if not myRootPart then return end

                for _, player in pairs(Players:GetPlayers()) do
                    if player ~= plr then
                        local playerCharacter = player.Character
                        local playerRootPart = playerCharacter and playerCharacter:FindFirstChild("HumanoidRootPart")
                        local playerHumanoid = playerCharacter and playerCharacter:FindFirstChild("Humanoid")
                        if playerRootPart and playerHumanoid and playerHumanoid.SeatPart then
                            local seatParent = playerHumanoid.SeatPart.Parent
                            if seatParent and seatParent.Name == "CreatureBlobman" then
                                if GetMagnitude(playerRootPart, myRootPart) <= 19 then
                                    sno(playerRootPart)
                                end
                            end
                        end
                    end
                end
            end)
        else
            if auraConnection then
                auraConnection:Disconnect()
                auraConnection = nil
            end
        end
        notify("nLhe", "Anti-Blobman Aura: " .. (enabled and "ON" or "OFF"), 2)
    end,
})

-- ==========================================
-- 2.10. ANTI EXPLOSION
-- ==========================================

local antiExplodeT = false
DefGroup:AddToggle("AntiExplosion", {
    Name = "Anti Explosion",
    Default = false,
    Callback = function(on)
        antiExplodeT = on
        if on then
            local char = plr.Character
            if not char then return end
            local hrp = char:WaitForChild("HumanoidRootPart")

            Workspace.ChildAdded:Connect(function(model)
                if model.Name == "Part" and antiExplodeT then
                    local mag = (model.Position - hrp.Position).Magnitude
                    if mag <= 20 then
                        hrp.Anchored = true
                        task.wait(0.01)
                        local rightArm = char:FindFirstChild("Right Arm")
                        if rightArm and rightArm:FindFirstChild("RagdollLimbPart") then
                            while rightArm.RagdollLimbPart.CanCollide do
                                task.wait(0.001)
                            end
                        end
                        hrp.Anchored = false
                    end
                end
            end)
        end
        notify("nLhe", "Anti Explosion: " .. (on and "ON" or "OFF"), 2)
    end
})

-- ==========================================
-- 2.11. ANTI BURN
-- ==========================================

local hookBurnConn
local function hookBurn(char)
    local hum = char:WaitForChild("Humanoid")
    local hrp = char:WaitForChild("HumanoidRootPart")
    char.PrimaryPart = hrp
    if hookBurnConn then
        hookBurnConn:Disconnect()
    end
    hookBurnConn = hum.FireDebounce.Changed:Connect(function(isBurning)
        if isBurning then
            local me = char
            local oldCF = hrp.CFrame
            local plots = Workspace:FindFirstChild("Plots")
            if plots and plots:FindFirstChild("Plot2") then
                local plot2 = plots.Plot2
                local barrier = plot2:FindFirstChild("Barrier")
                local pb = barrier and barrier:FindFirstChild("PlotBarrier")
                if pb and pb:IsA("BasePart") then
                    local safeCF = pb.CFrame * CFrame.new(0, 6, 0)
                    me:SetPrimaryPartCFrame(safeCF)
                    task.wait(0.3)
                    local firePart = me:FindFirstChild("FirePlayerPart", true)
                    if firePart then
                        for _, obj in ipairs(firePart:GetChildren()) do
                            if obj:IsA("Sound") then obj:Stop() end
                            if obj:IsA("Light") or obj:IsA("ParticleEmitter") then
                                obj.Enabled = false
                            end
                        end
                        if firePart:FindFirstChild("CanBurn") then
                            firePart.CanBurn.Value = false
                        end
                        if hum:FindFirstChild("FireDebounce") then
                            hum.FireDebounce.Value = false
                        end
                    end
                    task.wait(0.6)
                    if me and me.PrimaryPart then
                        me:SetPrimaryPartCFrame(oldCF)
                    end
                end
            end
        end
    end)
end

DefGroup:AddToggle("AntiBurn", {
    Name = "Anti Burn",
    Default = false,
    Callback = function(on)
        if on then
            hookBurn(plr.Character)
        elseif hookBurnConn then
            hookBurnConn:Disconnect()
        end
        notify("nLhe", "Anti Burn: " .. (on and "ON" or "OFF"), 2)
    end
})

-- ==========================================
-- 2.12. ANTI STICKY
-- ==========================================

DefGroup:AddToggle("AntiSticky", {
    Name = "Anti Sticky",
    Default = false,
    Callback = function(Value)
        if plr.PlayerScripts:FindFirstChild("StickyPartsTouchDetection") then
            plr.PlayerScripts.StickyPartsTouchDetection.Disabled = Value
        end
        notify("nLhe", "Anti Sticky: " .. (Value and "ON" or "OFF"), 2)
    end,
})

-- ==========================================
-- 2.13. ANTI LOOP KILL
-- ==========================================

if not _G.cons then _G.cons = {} end

DefGroup:AddToggle("AntiLoopKill", {
    Name = "Anti Loop Kill",
    Default = false,
    Callback = function(v)
        if _G.cons["antiloopkill"] then
            _G.cons["antiloopkill"]:Disconnect()
            _G.cons["antiloopkill"] = nil
        end

        if v then
            _G.cons["antiloopkill"] = plr.CharacterAdded:Connect(function(char)
                local hrp = char:WaitForChild("HumanoidRootPart", 5)
                if hrp then
                    RunService.RenderStepped:Wait()
                    local target = CFrame.new(524.703979, 93.7120056, -375.040985)
                    hrp.CFrame = target
                    for i = 1, 2 do
                        RunService.RenderStepped:Wait()
                        hrp.CFrame = target
                    end
                end
            end)
        end
        notify("nLhe", "Anti Loop Kill: " .. (v and "ON" or "OFF"), 2)
    end
})

-- ==========================================
-- 2.14. ANTI LAG
-- ==========================================

DefGroup:AddToggle("AntiLag", {
    Name = "Anti Lag",
    Default = false,
    Callback = function(Value)
        if Value then
            local grabFolder = RS:FindFirstChild("GrabEvents")
            if grabFolder then
                local create = grabFolder:FindFirstChild("CreateGrabLine")
                local extend = grabFolder:FindFirstChild("ExtendGrabLine")
                if create and create:IsA("RemoteEvent") then create:Destroy() end
                if extend and extend:IsA("RemoteEvent") then extend:Destroy() end
            end
            for _, v in ipairs(Workspace:GetDescendants()) do
                if v:IsA("Beam") or v.Name:lower():find("line") then v:Destroy() end
            end
        end
        notify("nLhe", "Anti Lag: " .. (Value and "ON" or "OFF"), 2)
    end
})

-- ==========================================
-- 2.15. AUTO DELETE LEGS
-- ==========================================

local AutoDeleteLegsActive = false
local DeleteLegsConnection = nil

local function PerformLegDeletion(char)
    task.wait(0.5)
    if not AutoDeleteLegsActive then return end

    local hrp = char:FindFirstChild("HumanoidRootPart")
    local hum = char:FindFirstChild("Humanoid")
    local torso = char:FindFirstChild("Torso")
    local ll = char:FindFirstChild("Left Leg")
    local rl = char:FindFirstChild("Right Leg")

    if hrp and hum and torso and ll and rl then
        local void = Workspace.FallenPartsDestroyHeight
        local pos = torso.CFrame

        Workspace.FallenPartsDestroyHeight = -100
        if RagdollRemote then RagdollRemote:FireServer(hrp, 2) end
        task.wait(0.5)

        if ll and rl then
            rl.CFrame = CFrame.new(0, -10000, 0)
            ll.CFrame = CFrame.new(0, -10000, 0)
        end

        task.wait(0.3)
        if torso then torso.CFrame = CFrame.new(0, -9970, 0) end

        task.wait(0.5)
        if torso then torso.CFrame = pos end

        task.wait(0.5)
        Workspace.FallenPartsDestroyHeight = void

        task.spawn(function()
            while AutoDeleteLegsActive and char.Parent and hum.Health > 0 and not char:FindFirstChild("Left Leg") and not char:FindFirstChild("Right Leg") do
                pcall(function()
                    local controls = plr.PlayerGui:FindFirstChild("ControlsGui")
                    if controls and controls:FindFirstChild("PCFrame") and controls.PCFrame:FindFirstChild("Stand") then
                        if controls.PCFrame.Stand.Visible == false then
                            hum.HipHeight = 2
                        else
                            hum.HipHeight = 0
                        end
                    end
                end)
                task.wait()
            end
        end)
    end
end

DefGroup:AddToggle("AutoDeleteLegs", {
    Name = "Auto Delete Legs",
    Default = false,
    Callback = function(Value)
        AutoDeleteLegsActive = Value

        if Value then
            task.spawn(function()
                PerformLegDeletion(plr.Character)
            end)

            if not DeleteLegsConnection then
                DeleteLegsConnection = plr.CharacterAdded:Connect(function(newChar)
                    if AutoDeleteLegsActive then
                        task.spawn(function()
                            PerformLegDeletion(newChar)
                        end)
                    end
                end)
            end
        else
            if DeleteLegsConnection then
                DeleteLegsConnection:Disconnect()
                DeleteLegsConnection = nil
            end
        end
        notify("nLhe", "Auto Delete Legs: " .. (Value and "ON" or "OFF"), 2)
    end
})

-- ==========================================
-- 2.16. PERM RAGDOLL
-- ==========================================

DefGroup:AddToggle("PermRagdoll", {
    Name = "Perm Ragdoll",
    Default = false,
    Callback = function(state)
        if state then
            cons["PermRag"] = RunService.Heartbeat:Connect(function()
                if not state then return end
                local char = plr.Character
                local hrp = char and char:FindFirstChild("HumanoidRootPart")
                if not hrp then return end
                pcall(function() if RagdollRemote then RagdollRemote:FireServer(hrp, 1) end end)
            end)
        else
            discCon("PermRag")
        end
        notify("nLhe", "Perm Ragdoll: " .. (state and "ON" or "OFF"), 2)
    end
})

-- ==========================================
-- 2.17. ANTI PAINT
-- ==========================================

local paintPartsBackup = {}
local paintConnections = {}

DefExtra:AddToggle("AntiPaint", {
    Name = "Anti Paint",
    Default = false,
    Callback = function(Value)
        if Value then
            for _, obj in ipairs(Workspace:GetDescendants()) do
                if obj:IsA("BasePart") and obj.Name == "PaintPlayerPart" then
                    local clone = obj:Clone()
                    clone.Archivable = true
                    paintPartsBackup[obj:GetDebugId()] = { clone = clone, parent = obj.Parent }
                    obj:Destroy()
                end
            end
            table.insert(paintConnections, Workspace.DescendantAdded:Connect(function(obj)
                if obj:IsA("BasePart") and obj.Name == "PaintPlayerPart" then
                    task.defer(function()
                        if obj and obj.Parent then
                            local clone = obj:Clone()
                            clone.Archivable = true
                            paintPartsBackup[obj:GetDebugId()] = { clone = clone, parent = obj.Parent }
                            obj:Destroy()
                        end
                    end)
                end
            end))
        else
            for _, data in pairs(paintPartsBackup) do
                if data.clone and data.parent then
                    data.clone.Parent = data.parent
                end
            end
            paintPartsBackup = {}
            for _, conn in ipairs(paintConnections) do
                if conn.Connected then conn:Disconnect() end
            end
            paintConnections = {}
        end
        notify("nLhe", "Anti Paint: " .. (Value and "ON" or "OFF"), 2)
    end
})

-- ==========================================
-- 2.18. PLATFORM TP
-- ==========================================

local platformPart = nil
local platformTPActive = false
local oldPlatformPos = nil

DefExtra:AddToggle("PlatformTP", {
    Name = "Enable Platform TP",
    Default = false,
    Callback = function(Value)
        if Value then
            if not platformPart then
                platformPart = Instance.new("Part", Workspace)
                platformPart.Name = "SkyBase"
                platformPart.Anchored = true
                platformPart.Size = Vector3.new(1500, 2, 1500)
                platformPart.CFrame = CFrame.new(0, 1000000, 0)
                Workspace.FallenPartsDestroyHeight = -9999999
            end
        end
        notify("nLhe", "Platform TP: " .. (Value and "ON" or "OFF"), 2)
    end
})

DefExtra:AddButton({
    Name = "Platform TP Execute",
    Callback = function()
        if not platformPart then
            notify("nLhe", "Enable Platform TP first!", 3)
            return
        end
        local char = plr.Character
        local root = char and char:FindFirstChild("HumanoidRootPart")
        if not root then return end
        if not platformTPActive then
            platformTPActive = true
            oldPlatformPos = root.CFrame
            root.CFrame = platformPart.CFrame + Vector3.new(0, 5, 0)
            root.AssemblyLinearVelocity = Vector3.zero
            root.AssemblyAngularVelocity = Vector3.zero
            notify("nLhe", "Teleported to platform", 2)
        else
            platformTPActive = false
            if oldPlatformPos then
                root.CFrame = oldPlatformPos
                notify("nLhe", "Returned from platform", 2)
            end
        end
    end
})

-- ==========================================
-- 2.19. ANTI INPUT LAG [XOCO]
-- ==========================================

local ToyListXOCO = {
    ["Coconut"] = "FoodCoconut",
    ["Banana"] = "FoodBanana",
    ["Fries"] = "FoodFrenchFries",
    ["MeatStick"] = "FoodMeatStick",
    ["Poop"] = "PoopPile",
    ["Donut"] = "FoodDonut",
    ["Cake"] = "FoodCakePink",
    ["Burger"] = "FoodHamburger",
    ["Pizza"] = "FoodPizzaCheese",
    ["Hotdog"] = "FoodHotdog",
    ["Mushroom"] = "FoodMushroomPoison",
    ["Banjo"] = "InstrumentGuitarBanjo",
    ["Violin"] = "InstrumentGuitarViolin",
    ["Ukulele"] = "InstrumentGuitarUkulele",
    ["Sax"] = "InstrumentWoodwindSaxophone",
    ["Vuvuzela"] = "InstrumentBrassVuvuzela",
    ["Bongos"] = "InstrumentDrumBongos",
    ["Mic"] = "InstrumentVoiceMicrophone",
    ["Pepperoni"] = "FoodPizzaPepperoni",
    ["Piano"] = "InstrumentPianoMelodica",
    ["Bread"] = "FoodBread",
    ["Egg"] = "FoodDippyEgg",
    ["Mayo"] = "FoodMayonnaise",
    ["WhiteMug"] = "CupMugWhite",
    ["Ocarina"] = "InstrumentWoodwindOcarina",
    ["SparklePoop"] = "PoopPileSparkle",
    ["BrownMug"] = "CupMugBrown",
    ["Trumpet"] = "InstrumentBrassTrumpet",
    ["Snare"] = "InstrumentDrumSnare",
    ["Lyre"] = "InstrumentGuitarLyre",
}

local DropdownValuesXOCO = {}
for shortName, _ in pairs(ToyListXOCO) do
    table.insert(DropdownValuesXOCO, shortName)
end
table.sort(DropdownValuesXOCO)

local SelectedToyXOCO = ToyListXOCO["Burger"] or ToyListXOCO[DropdownValuesXOCO[1]]

DefExtra:AddDropdown("SelectInputLagToyXOCO", {
    Name = "Select Input Lag Toy [XOCO]",
    Values = DropdownValuesXOCO,
    Default = "Burger",
    Callback = function(Value)
        SelectedToyXOCO = ToyListXOCO[Value]
    end
})

DefExtra:AddToggle("AntiInputLagXOCO", {
    Name = "Anti Input Lag [XOCO]",
    Default = false,
    Callback = function(Value)
        _G.InstantLagActiveXOCO = Value

        if Value then
            task.spawn(function()
                while _G.InstantLagActiveXOCO do
                    local char = plr.Character
                    local hrp = char and char:FindFirstChild("HumanoidRootPart")

                    if hrp and SpawnToyRemote then
                        local toysFolder = Workspace:FindFirstChild(plr.Name.."SpawnedInToys")
                        local name = SelectedToyXOCO
                        local item = toysFolder and toysFolder:FindFirstChild(name)

                        if not item or not item.Parent then
                            task.spawn(function()
                                pcall(function()
                                    SpawnToyRemote:InvokeServer(name, hrp.CFrame * CFrame.new(0, -12, 0), Vector3.zero)
                                end)
                            end)
                            task.wait(0.1)
                        else
                            local holdPart = item:FindFirstChild("HoldPart")
                            if holdPart then
                                task.spawn(function()
                                    pcall(function()
                                        if holdPart:FindFirstChild("HoldItemRemoteFunction") then
                                            holdPart.HoldItemRemoteFunction:InvokeServer(item, char)
                                        end
                                    end)
                                end)
                                task.wait(0.02)
                                task.spawn(function()
                                    pcall(function()
                                        if holdPart:FindFirstChild("DropItemRemoteFunction") then
                                            holdPart.DropItemRemoteFunction:InvokeServer(item, CFrame.new(0, 5000, 0), Vector3.zero)
                                        end
                                    end)
                                end)
                            end
                        end
                    end
                    task.wait(0.15)
                end
            end)
        end
        notify("nLhe", "Anti Input Lag [XOCO]: " .. (Value and "ON" or "OFF"), 2)
    end
})

-- ==========================================
-- 2.20. ANTI KICK [SHURIKEN]
-- ==========================================

AntiKickGroup:AddToggle("AntiKickShuriken", {
    Name = "Anti Kick [SHURIKEN]",
    Default = false,
    Callback = function(Value)
        _G.ShurikenAntiKick = Value

        local function ClearKunai()
            local inv = Workspace:FindFirstChild(plr.Name .. "SpawnedInToys")
            local destroyrem = RS:FindFirstChild("MenuToys") and RS.MenuToys:FindFirstChild("DestroyToy")
            if inv and destroyrem then
                for _, v in pairs(inv:GetChildren()) do
                    if v.Name == "AntiKick" or v.Name == "NinjaShuriken" then
                        pcall(function() destroyrem:FireServer(v) end)
                    end
                end
            end
        end

        if Value then
            task.spawn(function()
                if not SetNetworkOwner then return end
                if not StickyEvent then return end
                if not SpawnToyRemote then return end

                local setOwner = SetNetworkOwner
                local stickyEvent = StickyEvent
                local spawnRemote = SpawnToyRemote
                local canSpawn = plr:FindFirstChild("CanSpawnToy") or plr:WaitForChild("CanSpawnToy")

                local function getHRP()
                    if plr.Character and plr.Character:FindFirstChild("HumanoidRootPart") then
                        return plr.Character.HumanoidRootPart
                    else
                        return plr.CharacterAdded:Wait():WaitForChild("HumanoidRootPart")
                    end
                end

                local function CheckForHome()
                    if not Workspace.PlotItems.PlayersInPlots:FindFirstChild(plr.Name) then return false end
                    for _, v in pairs(Workspace.Plots:GetChildren()) do
                        local sign = v:FindFirstChild("PlotSign")
                        local owners = sign and sign:FindFirstChild("ThisPlotsOwners")
                        if owners then
                            for _, b in pairs(owners:GetChildren()) do
                                if b.Value == plr.Name then
                                    local folder = Workspace.PlotItems:FindFirstChild(v.Name)
                                    if folder then return true, folder end
                                end
                            end
                        end
                    end
                    return false
                end

                local function StickKunai(kunai)
                    if not kunai or not kunai:FindFirstChild("StickyPart") then return end
                    local currentHRP = getHRP()
                    if not currentHRP then return end

                    if kunai:FindFirstChild("SoundPart") then
                        if not kunai.SoundPart:FindFirstChild("PartOwner") or kunai.SoundPart.PartOwner.Value ~= plr.Name then
                            setOwner:FireServer(kunai.SoundPart, kunai.SoundPart.CFrame)
                        end
                    end

                    local firePart = currentHRP:FindFirstChild("FirePlayerPart") or currentHRP:WaitForChild("FirePlayerPart", 5)
                    if firePart then
                        stickyEvent:FireServer(kunai.StickyPart, firePart, CFrame.new(0,0,0) * CFrame.Angles(0,math.rad(90),math.rad(90)))
                    end

                    for _, obj in pairs(kunai:GetChildren()) do
                        if obj:IsA("BasePart") then
                            obj.CanTouch = false
                            obj.CanCollide = false
                            obj.CanQuery = false
                            obj.Transparency = 0.8
                        end
                    end
                end

                local function SpawnToy(name)
                    local t = tick()
                    while not canSpawn.Value do
                        if not _G.ShurikenAntiKick or tick() - t > 5 then return nil end
                        task.wait(0.1)
                    end
                    local currentHRP = getHRP()
                    if currentHRP then
                        task.spawn(function()
                            pcall(function()
                                spawnRemote:InvokeServer(name, currentHRP.CFrame * CFrame.new(0, 12, 20), Vector3.new(0,0,0))
                            end)
                        end)
                    end
                    local boolik, house = CheckForHome()
                    local inv = Workspace:FindFirstChild(plr.Name.."SpawnedInToys")
                    if boolik and house then
                        return house:WaitForChild(name, 2)
                    elseif not Workspace.PlotItems.PlayersInPlots:FindFirstChild(plr.Name) and inv then
                        return inv:WaitForChild(name, 2)
                    end
                    return nil
                end

                while _G.ShurikenAntiKick do
                    task.wait(0.005)
                    if not plr.Character or not plr.Character:FindFirstChild("Humanoid") or plr.Character.Humanoid.Health <= 0 then
                        continue
                    end

                    local inv = Workspace:FindFirstChild(plr.Name.."SpawnedInToys")
                    local kunai = inv and inv:FindFirstChild("NinjaShuriken")

                    if Workspace.PlotItems.PlayersInPlots:FindFirstChild(plr.Name) then
                        local boolik, house = CheckForHome()
                        if boolik and house and Workspace.Plots:FindFirstChild(house.Name) then
                            local sign = Workspace.Plots[house.Name]:FindFirstChild("PlotSign")
                            if sign and sign.ThisPlotsOwners.Value.TimeRemainingNum.Value > 89 then
                                kunai = SpawnToy("NinjaShuriken")
                                if kunai == nil then continue end
                                kunai.Name = "AntiKick"
                                StickKunai(kunai)
                            end
                        end
                    end

                    if not kunai then
                        if Workspace.PlotItems.PlayersInPlots:FindFirstChild(plr.Name) then continue end
                        kunai = SpawnToy("NinjaShuriken")
                        if kunai == nil then continue end
                        kunai.Name = "AntiKick"
                        if not kunai then continue end
                    end

                    repeat
                        if kunai and kunai:FindFirstChild("StickyPart") and kunai.StickyPart.CanTouch == true then
                            StickKunai(kunai)
                            kunai.Name = "AntiKick"
                        end
                        task.wait(0.3)
                    until not kunai or not _G.ShurikenAntiKick or not kunai:FindFirstChild("StickyPart") or kunai.StickyPart.CanTouch == false
                        or not plr.Character or not plr.Character:FindFirstChild("HumanoidRootPart")
                        or not kunai:FindFirstChild("StickyPart")
                        or (plr.Character.HumanoidRootPart.Position - kunai.StickyPart.Position).Magnitude >= 20

                    if not kunai or not kunai:FindFirstChild("StickyPart") or not plr.Character or not plr.Character:FindFirstChild("HumanoidRootPart") or (plr.Character.HumanoidRootPart.Position - kunai.StickyPart.Position).Magnitude >= 20 then
                        ClearKunai()
                    end
                end
                ClearKunai()
            end)
        else
            _G.ShurikenAntiKick = false
            ClearKunai()
        end
        notify("nLhe", "Anti Kick [SHURIKEN]: " .. (Value and "ON" or "OFF"), 2)
    end
})

-- ==========================================
-- 2.21. ANTI KICK [ITEM]
-- ==========================================

do
    local AntiKickItemActive = false
    local MyPCLD = nil
    local pcldConn = nil

    local function FindPCLD(hrp)
        if pcldConn then pcldConn:Disconnect() end
        MyPCLD = nil
        pcldConn = RunService.Heartbeat:Connect(function()
            if MyPCLD or not hrp or not hrp.Parent then
                if pcldConn then pcldConn:Disconnect() pcldConn = nil end
                return
            end
            for _, v in pairs(Workspace:GetChildren()) do
                if v.Name == "PlayerCharacterLocationDetector" and v:IsA("BasePart") then
                    if GetMagnitude(v, hrp) <= 2 then
                        MyPCLD = v
                        break
                    end
                end
            end
        end)
    end

    AntiKickGroup:AddToggle("AntiKickItem", {
        Name = "Anti Kick [ITEM]",
        Default = false,
        Callback = function(Val)
            AntiKickItemActive = Val

            if Val then
                task.spawn(function()
                    local Item, SoundPart
                    while AntiKickItemActive and task.wait() do
                        local char = plr.Character
                        local hrp = char and char:FindFirstChild("HumanoidRootPart")
                        local hum = char and char:FindFirstChild("Humanoid")
                        local inPlot = plr:FindFirstChild("InPlot")
                        local inv = Workspace:FindFirstChild(plr.Name.."SpawnedInToys")
                        local destroyToy = RS:FindFirstChild("MenuToys") and RS.MenuToys:FindFirstChild("DestroyToy")

                        if not hrp or not hum or hum.Health <= 0 or not inv then continue end
                        if inPlot and inPlot.Value then continue end

                        if not MyPCLD and not pcldConn then
                            FindPCLD(hrp)
                        end

                        Item = inv:FindFirstChild("AntiKickItem")
                        SoundPart = Item and Item:FindFirstChild("Hitbox")

                        if not Item or not SoundPart then
                            for _,v in pairs(inv:GetChildren()) do
                                if v.Name == "AntiKickItem" then
                                    pcall(function() if destroyToy then destroyToy:FireServer(v) end end)
                                end
                            end

                            if SpawnToyRemote then
                                pcall(function()
                                    SpawnToyRemote:InvokeServer("SpookyCandle1", (MyPCLD or hrp).CFrame * CFrame.new(0, 14, 20), Vector3.zero)
                                end)
                            end

                            task.wait(0.3)
                            Item = inv:FindFirstChild("SpookyCandle1")
                            if not Item then continue end

                            SoundPart = Item:FindFirstChild("Hitbox") or Item:WaitForChild("Hitbox", 0.5)
                            if not SoundPart then continue end

                            sno(SoundPart)
                            for _,v in pairs(Item:GetChildren()) do
                                if v:IsA("BasePart") then
                                    v.CanCollide = false
                                    v.Transparency = 0.8
                                end
                            end

                            local targetPart = MyPCLD or hrp
                            SoundPart.CFrame = targetPart.CFrame

                            local Weld = Instance.new("WeldConstraint")
                            Weld.Part0 = SoundPart
                            Weld.Part1 = targetPart
                            Weld.Parent = SoundPart
                            Weld.Name = "WeldBlabla"
                            Item.Name = "AntiKickItem"
                        end

                        local Weld = SoundPart and SoundPart:FindFirstChild("WeldBlabla")
                        if SoundPart and not SetNetworkOwner then
                            sno(SoundPart)
                        end

                        local targetPart = MyPCLD or hrp
                        if Weld and Weld.Part1 ~= targetPart then
                            Weld.Enabled = false
                            SoundPart.CFrame = targetPart.CFrame
                            Weld.Part1 = targetPart
                            Weld.Enabled = true
                        end
                        if SoundPart and Weld then
                            SoundPart.CFrame = targetPart.CFrame
                        end
                    end
                end)
            else
                if pcldConn then pcldConn:Disconnect() pcldConn = nil end
                MyPCLD = nil
                task.spawn(function()
                    local inv = Workspace:FindFirstChild(plr.Name.."SpawnedInToys")
                    local destroyToy = RS:FindFirstChild("MenuToys") and RS.MenuToys:FindFirstChild("DestroyToy")
                    if inv and destroyToy then
                        for _,v in pairs(inv:GetChildren()) do
                            if v.Name == "AntiKickItem" or v.Name == "SpookyCandle1" then
                                pcall(function() destroyToy:FireServer(v) end)
                            end
                        end
                    end
                end)
            end
            notify("nLhe", "Anti Kick [ITEM]: " .. (Val and "ON" or "OFF"), 2)
        end
    })

    plr.CharacterAdded:Connect(function(char)
        if AntiKickItemActive then
            MyPCLD = nil
            local hrp = char:WaitForChild("HumanoidRootPart", 5)
            if hrp then FindPCLD(hrp) end
        end
    end)
end

-- ==========================================
-- 2.22. ANTI KICK [ITEM-CANDLE]
-- ==========================================

AntiKickGroup:AddToggle("AntiKickItemCandle", {
    Name = "Anti Kick [ITEM-CANDLE]",
    Default = false,
    Callback = function(Val)
        _G.bool.AntiKickItemCandle = Val
        task.spawn(function()
            local Item, SoundPart, Weld
            while _G.bool.AntiKickItemCandle and task.wait() do
                local char = plr.Character
                local hrp = char and char:FindFirstChild("HumanoidRootPart")
                local hum = char and char:FindFirstChild("Humanoid")
                local inPlot = plr:FindFirstChild("InPlot")
                local inv = Workspace:FindFirstChild(plr.Name.."SpawnedInToys")
                local destroyToy = RS:FindFirstChild("MenuToys") and RS.MenuToys:FindFirstChild("DestroyToy")

                if not hrp or not hum or hum.Health == 0 then continue end
                if inPlot and inPlot.Value then continue end

                Item = inv:FindFirstChild("AntiKickItemCandle")
                SoundPart = Item and Item:FindFirstChild("Hitbox")

                if not Item or not SoundPart then
                    for _,v in pairs(inv:GetChildren()) do
                        if v.Name == "AntiKickItemCandle" then
                            if destroyToy then destroyToy:FireServer(v) end
                        end
                    end

                    if SpawnToyRemote then
                        pcall(function()
                            SpawnToyRemote:InvokeServer("SpookyCandle1", (etc["MyPCLD"] or hrp).CFrame * CFrame.new(0, 14, 20), Vector3.zero)
                        end)
                    end

                    task.wait(0.3)
                    Item = inv:FindFirstChild("SpookyCandle1")
                    if not Item then continue end

                    SoundPart = Item:FindFirstChild("Hitbox") or Item:WaitForChild("Hitbox", 0.5)
                    if not SoundPart then continue end

                    sno(SoundPart)
                    for _,v in pairs(Item:GetChildren()) do
                        if v:IsA("BasePart") then
                            v.CanCollide = false
                            v.CanQuery = false
                            v.Transparency = 0.8
                        end
                    end

                    local targetPart = etc["MyPCLD"] or hrp
                    SoundPart.CFrame = targetPart.CFrame

                    Weld = Instance.new("WeldConstraint")
                    Weld.Part0 = SoundPart
                    Weld.Part1 = targetPart
                    Weld.Parent = SoundPart
                    Weld.Name = "WeldBlabla"
                    Item.Name = "AntiKickItemCandle"
                end

                Weld = SoundPart and SoundPart:FindFirstChild("WeldBlabla")
                if SoundPart and not SetNetworkOwner then
                    sno(SoundPart)
                end

                local targetPart = etc["MyPCLD"] or hrp
                if Weld and Weld.Part1 ~= targetPart then
                    Weld.Enabled = false
                    SoundPart.CFrame = targetPart.CFrame
                    Weld.Part1 = targetPart
                    Weld.Enabled = true
                end
                if SoundPart and Weld then
                    SoundPart.CFrame = targetPart.CFrame
                end
            end
        end)
        notify("nLhe", "Anti Kick [ITEM-CANDLE]: " .. (Val and "ON" or "OFF"), 2)
    end
})

-- ==========================================
-- ЧАСТЬ 3: TARGET
-- ==========================================

print("🔄 Loading Target...")

local plr = _G.nLhe.plr
local RS = _G.nLhe.RS
local RunService = _G.nLhe.RunService
local Workspace = _G.nLhe.Workspace
local Players = _G.nLhe.Players
local UIS = _G.nLhe.UIS

local SetNetworkOwner = RS:FindFirstChild("GrabEvents") and RS.GrabEvents:FindFirstChild("SetNetworkOwner")
local DestroyToy = RS:FindFirstChild("MenuToys") and RS.MenuToys:FindFirstChild("DestroyToy")
local RagdollRemote = RS:FindFirstChild("CharacterEvents") and RS.CharacterEvents:FindFirstChild("RagdollRemote")
local Struggle = RS:FindFirstChild("CharacterEvents") and RS.CharacterEvents:FindFirstChild("Struggle")
local SpawnToyRemote = RS:FindFirstChild("MenuToys") and RS.MenuToys:FindFirstChild("SpawnToyRemoteFunction")
local DestroyGrabLine = RS:FindFirstChild("GrabEvents") and RS.GrabEvents:FindFirstChild("DestroyGrabLine")
local CreateGrabLine = RS:FindFirstChild("GrabEvents") and RS.GrabEvents:FindFirstChild("CreateGrabLine")
local StickyEvent = RS:FindFirstChild("PlayerEvents") and RS.PlayerEvents:FindFirstChild("StickyPartEvent")

local TargetGroup = _G.nLhe.Tabs.Target:AddLeftGroupbox("Target", "crosshair")
local TargetActions = _G.nLhe.Tabs.Target:AddRightGroupbox("Actions", "sword")

local bool = _G.nLhe.bool
local int = _G.nLhe.int
local cons = _G.nLhe.cons
local etc = _G.nLhe.etc

local function discCon(key) _G.nLhe.discCon(key) end
local function notify(t, c, d) _G.nLhe.notify(t, c, d) end
local function sno(part) _G.nLhe.sno(part) end
local function GetMagnitude(a, b) return _G.nLhe.GetMagnitude(a, b) end

-- ==========================================
-- 3.1. ВЫБОР ЦЕЛИ
-- ==========================================

local targetList = {}
for _, p in pairs(Players:GetPlayers()) do
    if p ~= plr then
        table.insert(targetList, p.DisplayName .. " (@" .. p.Name .. ")")
    end
end

local targetDropdown = TargetGroup:AddDropdown("SelectTarget", {
    Name = "Select Target",
    Values = targetList,
    Default = targetList[1] or "",
    Callback = function(val)
        local username = val and val:match("@(.+)%)")
        if username then
            etc.SelectedTarget = Players:FindFirstChild(username)
            notify("nLhe", "Target: " .. (etc.SelectedTarget and etc.SelectedTarget.Name or "None"), 2)
        end
    end
})

TargetGroup:AddButton({
    Name = "Refresh List",
    Callback = function()
        local list = {}
        for _, p in pairs(Players:GetPlayers()) do
            if p ~= plr then
                table.insert(list, p.DisplayName .. " (@" .. p.Name .. ")")
            end
        end
        targetDropdown:SetValues(list)
        notify("nLhe", "List refreshed!", 2)
    end
})

-- ==========================================
-- 3.2. FLING TARGET
-- ==========================================

TargetActions:AddToggle("FlingTarget", {
    Name = "Fling Target",
    Default = false,
    Callback = function(v)
        bool.FlingTarget = v
        if v then
            if not etc.SelectedTarget then
                notify("nLhe", "Select target first!", 3)
                bool.FlingTarget = false
                return
            end
            cons["FlingTarget"] = RunService.Heartbeat:Connect(function()
                if not bool.FlingTarget or not etc.SelectedTarget then return end
                local target = etc.SelectedTarget
                if not target or not target.Character then return end
                local tRoot = target.Character:FindFirstChild("HumanoidRootPart")
                local tHum = target.Character:FindFirstChild("Humanoid")
                if not tRoot or not tHum or tHum.Health <= 0 then return end
                local hrp = plr.Character and plr.Character:FindFirstChild("HumanoidRootPart")
                if hrp and hrp.Parent then
                    if not cons["FlingTarget_BAV"] or not cons["FlingTarget_BAV"].Parent then
                        cons["FlingTarget_BAV"] = Instance.new("BodyAngularVelocity")
                        cons["FlingTarget_BAV"].MaxTorque = Vector3.new(math.huge, math.huge, math.huge)
                        cons["FlingTarget_BAV"].AngularVelocity = Vector3.new(0, 10000, 0)
                        cons["FlingTarget_BAV"].P = 10000
                        cons["FlingTarget_BAV"].Parent = hrp
                    end
                    for _, part in pairs(plr.Character:GetDescendants()) do
                        if part:IsA("BasePart") then part.CanCollide = false end
                    end
                    hrp.CFrame = tRoot.CFrame
                    hrp.AssemblyLinearVelocity = Vector3.zero
                    hrp.AssemblyAngularVelocity = Vector3.zero
                end
            end)
        else
            discCon("FlingTarget")
            if cons["FlingTarget_BAV"] then
                cons["FlingTarget_BAV"]:Destroy()
                cons["FlingTarget_BAV"] = nil
            end
            local char = plr.Character
            if char then
                for _, part in pairs(char:GetDescendants()) do
                    if part:IsA("BasePart") then part.CanCollide = true end
                end
                local hrp = char:FindFirstChild("HumanoidRootPart")
                if hrp then
                    hrp.AssemblyLinearVelocity = Vector3.zero
                    hrp.AssemblyAngularVelocity = Vector3.zero
                end
            end
        end
        notify("nLhe", "Fling Target: " .. (v and "ON" or "OFF"), 2)
    end
})

-- ==========================================
-- 3.3. LOOP KILL
-- ==========================================

TargetActions:AddToggle("LoopKill", {
    Name = "Loop Kill",
    Default = false,
    Callback = function(v)
        bool.LoopKill = v
        if v then
            if not etc.SelectedTarget then
                notify("nLhe", "Select target first!", 3)
                bool.LoopKill = false
                return
            end
            cons["LoopKill"] = RunService.Heartbeat:Connect(function()
                if not bool.LoopKill or not etc.SelectedTarget then return end
                local target = etc.SelectedTarget
                if not target or not target.Character then return end
                local tRoot = target.Character:FindFirstChild("HumanoidRootPart")
                local tHead = target.Character:FindFirstChild("Head")
                local tHum = target.Character:FindFirstChild("Humanoid")
                if not tRoot or not tHead or not tHum or tHum.Health <= 0 then return end
                local char = plr.Character
                local hrp = char and char:FindFirstChild("HumanoidRootPart")
                if not hrp then return end
                local savedPos = hrp.CFrame
                for _, part in pairs(target.Character:GetDescendants()) do
                    if part:IsA("BasePart") then part.CanCollide = false end
                end
                hrp.CFrame = tRoot.CFrame + Vector3.new(5, -18.5, 0)
                if SetNetworkOwner then SetNetworkOwner:FireServer(tRoot, tRoot.CFrame) end
                task.wait()
                hrp.CFrame = savedPos
                task.wait(0.1)
                if DestroyGrabLine then DestroyGrabLine:FireServer(tRoot) end
                task.wait(0.1)
                if tHead:FindFirstChild("PartOwner") and tHead.PartOwner.Value == plr.Name then
                    for _, part in pairs(target.Character:GetChildren()) do
                        if part:IsA("BasePart") then
                            part.CFrame = CFrame.new(-999999999999, 9999999999999, -999999999999)
                        end
                    end
                    task.wait()
                    local bv = Instance.new("BodyVelocity")
                    bv.Velocity = Vector3.new(0, 99999999999, 0)
                    bv.MaxForce = Vector3.new(math.huge, math.huge, math.huge)
                    bv.P = 100000075
                    bv.Parent = tRoot
                    tHum.Sit = false
                    tHum.Jump = true
                    tHum.BreakJointsOnDeath = false
                    tHum:ChangeState(Enum.HumanoidStateType.Dead)
                    task.delay(2, function() if bv and bv.Parent then bv:Destroy() end end)
                end
            end)
        else
            discCon("LoopKill")
        end
        notify("nLhe", "Loop Kill: " .. (v and "ON" or "OFF"), 2)
    end
})

-- ==========================================
-- 3.4. OATS KICK
-- ==========================================

TargetActions:AddToggle("OatsKick", {
    Name = "Oats Kick",
    Default = false,
    Callback = function(v)
        bool.OatsKick = v
        if v then
            if not etc.SelectedTarget then
                notify("nLhe", "Select target first!", 3)
                bool.OatsKick = false
                return
            end
            cons["OatsKick"] = RunService.Heartbeat:Connect(function()
                if not bool.OatsKick or not etc.SelectedTarget then return end
                local target = etc.SelectedTarget
                if not target or not target.Character then return end
                local tRoot = target.Character:FindFirstChild("HumanoidRootPart")
                local tHum = target.Character:FindFirstChild("Humanoid")
                if not tRoot or not tHum or tHum.Health <= 0 then return end
                local char = plr.Character
                local hrp = char and char:FindFirstChild("HumanoidRootPart")
                local head = char and char:FindFirstChild("Head")
                if not hrp or not head then return end
                local dist = (tRoot.Position - hrp.Position).Magnitude
                if dist > 30 then
                    hrp.CFrame = tRoot.CFrame * CFrame.new(0, 2, 4)
                    if SetNetworkOwner then SetNetworkOwner:FireServer(tRoot, tRoot.CFrame) end
                end
                if not tRoot:FindFirstChild("KickAlign") then
                    local att0 = Instance.new("Attachment", tRoot)
                    att0.Name = "KickAtt0"
                    local att1 = Instance.new("Attachment", Workspace.Terrain)
                    att1.Name = "KickAtt1"
                    local alignPos = Instance.new("AlignPosition")
                    alignPos.Name = "KickAlign"
                    alignPos.Attachment0 = att0
                    alignPos.Attachment1 = att1
                    alignPos.MaxForce = math.huge
                    alignPos.Responsiveness = 200
                    alignPos.Parent = tRoot
                end
                local align = tRoot:FindFirstChild("KickAlign")
                if align and align.Attachment1 then
                    align.Attachment1.WorldPosition = head.Position + Vector3.new(0, 20, 0)
                end
                if DestroyGrabLine then DestroyGrabLine:FireServer(tRoot) end
            end)
        else
            discCon("OatsKick")
            if etc.SelectedTarget then
                local target = etc.SelectedTarget
                if target and target.Character then
                    local tRoot = target.Character:FindFirstChild("HumanoidRootPart")
                    if tRoot then
                        local align = tRoot:FindFirstChild("KickAlign")
                        if align then
                            if align.Attachment1 then align.Attachment1:Destroy() end
                            align:Destroy()
                        end
                        local att0 = tRoot:FindFirstChild("KickAtt0")
                        if att0 then att0:Destroy() end
                    end
                end
            end
        end
        notify("nLhe", "Oats Kick: " .. (v and "ON" or "OFF"), 2)
    end
})

-- ==========================================
-- 3.5. OWNERSHIP KICK
-- ==========================================

TargetActions:AddToggle("OwnershipKick", {
    Name = "Ownership Kick",
    Default = false,
    Callback = function(v)
        bool.OwnershipKick = v
        if v then
            if not etc.SelectedTarget then
                notify("nLhe", "Select target first!", 3)
                bool.OwnershipKick = false
                return
            end
            cons["OwnershipKick"] = RunService.Heartbeat:Connect(function()
                if not bool.OwnershipKick or not etc.SelectedTarget then return end
                local target = etc.SelectedTarget
                if not target or not target.Character then return end
                local tRoot = target.Character:FindFirstChild("HumanoidRootPart")
                local tHum = target.Character:FindFirstChild("Humanoid")
                if not tRoot or not tHum or tHum.Health <= 0 then return end
                local char = plr.Character
                local hrp = char and char:FindFirstChild("HumanoidRootPart")
                if not hrp then return end
                if not tRoot:FindFirstChild("BodyPosition") then
                    local bp = Instance.new("BodyPosition")
                    bp.MaxForce = Vector3.new(9e9, 9e9, 9e9)
                    bp.D = 100
                    bp.Position = hrp.Position + Vector3.new(0, 20, 0)
                    bp.Parent = tRoot
                    local bg = Instance.new("BodyGyro")
                    bg.MaxTorque = Vector3.new(9e9, 9e9, 9e9)
                    bg.D = 100
                    bg.CFrame = hrp.CFrame
                    bg.Parent = tRoot
                end
                if SetNetworkOwner then SetNetworkOwner:FireServer(tRoot, tRoot.CFrame) end
                if DestroyGrabLine then DestroyGrabLine:FireServer(tRoot) end
                tHum.PlatformStand = true
            end)
        else
            discCon("OwnershipKick")
            if etc.SelectedTarget then
                local target = etc.SelectedTarget
                if target and target.Character then
                    local tRoot = target.Character:FindFirstChild("HumanoidRootPart")
                    if tRoot then
                        for _, v in pairs(tRoot:GetChildren()) do
                            if v:IsA("BodyPosition") or v:IsA("BodyGyro") then v:Destroy() end
                        end
                        tRoot.AssemblyLinearVelocity = Vector3.zero
                        tRoot.AssemblyAngularVelocity = Vector3.zero
                    end
                end
            end
        end
        notify("nLhe", "Ownership Kick: " .. (v and "ON" or "OFF"), 2)
    end
})

-- ==========================================
-- 3.6. REMOVE TARGET ANTI KICK [AURA]
-- ==========================================

TargetActions:AddToggle("RemoveTargetAntiKick", {
    Name = "[AURA] Remove Target Anti Kick",
    Default = false,
    Callback = function(v)
        bool.RemoveTargetAntiKick = v
        if v then
            cons["RemoveTargetAntiKick"] = RunService.Heartbeat:Connect(function()
                if not bool.RemoveTargetAntiKick or not etc.SelectedTarget then return end
                local target = etc.SelectedTarget
                if not target then return end
                local spawned = Workspace:FindFirstChild(target.Name .. "SpawnedInToys")
                if spawned then
                    for _, toyName in ipairs({"NinjaKunai", "NinjaShuriken", "AntiKick", "ToolCleaver", "ToolPencil"}) do
                        local toy = spawned:FindFirstChild(toyName)
                        if toy then
                            local part = toy:FindFirstChild("SoundPart") or toy:FindFirstChild("StickyPart")
                            if part then
                                pcall(function()
                                    if SetNetworkOwner then SetNetworkOwner:FireServer(part, part.CFrame) end
                                    if part:FindFirstChild("PartOwner") and part.PartOwner.Value == plr.Name then
                                        part.CFrame = CFrame.new(0, 1000, 0)
                                    end
                                end)
                            end
                        end
                    end
                end
            end)
        else
            discCon("RemoveTargetAntiKick")
        end
        notify("nLhe", "Remove Target Anti Kick: " .. (v and "ON" or "OFF"), 2)
    end
})

-- ==========================================
-- 3.7. SPIN LOOP KICK
-- ==========================================

local spinAngle = 0
local spinRadius = 25
local spinSpeed = 0.25

TargetActions:AddSlider("SpinRadius", {
    Name = "Spin Radius",
    Min = 5,
    Max = 50,
    Default = 25,
    Callback = function(val) spinRadius = val end
})

TargetActions:AddSlider("SpinSpeed", {
    Name = "Spin Speed",
    Min = 0.05,
    Max = 1,
    Default = 0.25,
    Callback = function(val) spinSpeed = val end
})

TargetActions:AddToggle("SpinLoopKick", {
    Name = "Spin Loop Kick",
    Default = false,
    Callback = function(v)
        bool.SpinLoopKick = v
        if v then
            if not etc.SelectedTarget then
                notify("nLhe", "Select target first!", 3)
                bool.SpinLoopKick = false
                return
            end
            cons["SpinLoopKick"] = RunService.Heartbeat:Connect(function()
                if not bool.SpinLoopKick or not etc.SelectedTarget then return end
                local target = etc.SelectedTarget
                if not target or not target.Character then return end
                local tRoot = target.Character:FindFirstChild("HumanoidRootPart")
                local tHum = target.Character:FindFirstChild("Humanoid")
                if not tRoot or not tHum or tHum.Health <= 0 then return end

                local char = plr.Character
                local hrp = char and char:FindFirstChild("HumanoidRootPart")
                local hum = char and char:FindFirstChild("Humanoid")
                if not hrp or not hum then return end

                local inv = Workspace:FindFirstChild(plr.Name.."SpawnedInToys")
                if not inv then return end
                local blob = inv:FindFirstChild("CreatureBlobman")
                if not blob then
                    if SpawnToyRemote then
                        SpawnToyRemote:InvokeServer("CreatureBlobman", hrp.CFrame * CFrame.new(0, 5, 5), Vector3.zero)
                    end
                    task.wait(0.3)
                    blob = inv:FindFirstChild("CreatureBlobman")
                end
                if blob then
                    local seat = blob:FindFirstChild("VehicleSeat")
                    if seat then
                        spinAngle = spinAngle + spinSpeed
                        if spinAngle > 6.28 then spinAngle = 0 end
                        local x = math.cos(spinAngle) * spinRadius
                        local z = math.sin(spinAngle) * spinRadius
                        hrp.CFrame = tRoot.CFrame * CFrame.new(x, 0, z)
                        hrp.AssemblyLinearVelocity = Vector3.zero
                        hrp.AssemblyAngularVelocity = Vector3.zero
                        seat:Sit(hum)
                        local timeout = 0
                        while not hum.SeatPart and timeout < 30 do
                            task.wait(0.05)
                            timeout = timeout + 1
                        end
                        if hum.SeatPart then
                            local scriptObj = blob:FindFirstChild("BlobmanSeatAndOwnerScript")
                            if scriptObj then
                                local CreatureGrab = scriptObj:FindFirstChild("CreatureGrab")
                                local CreatureDrop = scriptObj:FindFirstChild("CreatureDrop")
                                local L_Det = blob:FindFirstChild("LeftDetector")
                                local R_Det = blob:FindFirstChild("RightDetector")
                                local L_Weld = L_Det and (L_Det:FindFirstChild("LeftWeld") or L_Det:FindFirstChild("RigidConstraint"))
                                local R_Weld = R_Det and (R_Det:FindFirstChild("RightWeld") or R_Det:FindFirstChild("RigidConstraint"))
                                if CreatureGrab and CreatureDrop and L_Weld and R_Weld then
                                    CreatureGrab:FireServer(L_Det, tRoot, L_Weld)
                                    CreatureGrab:FireServer(R_Det, tRoot, R_Weld)
                                    task.wait(0.05)
                                    CreatureDrop:FireServer(L_Weld, tRoot)
                                    CreatureDrop:FireServer(R_Weld, tRoot)
                                end
                            end
                        end
                    end
                end
            end)
        else
            discCon("SpinLoopKick")
            spinAngle = 0
        end
        notify("nLhe", "Spin Loop Kick: " .. (v and "ON" or "OFF"), 2)
    end
})

-- ==========================================
-- ЧАСТЬ 4: PLAYER
-- ==========================================

print("🔄 Loading Player...")

local plr = _G.nLhe.plr
local RS = _G.nLhe.RS
local RunService = _G.nLhe.RunService
local Workspace = _G.nLhe.Workspace
local Players = _G.nLhe.Players
local UIS = _G.nLhe.UIS
local Lighting = _G.nLhe.Lighting

local PlayerGroup = _G.nLhe.Tabs.Player:AddLeftGroupbox("Movement", "user")
local PlayerESP = _G.nLhe.Tabs.Player:AddRightGroupbox("ESP", "eye")
local PlayerPerf = _G.nLhe.Tabs.Player:AddRightGroupbox("Performance", "settings")

local bool = _G.nLhe.bool
local int = _G.nLhe.int
local cons = _G.nLhe.cons

local function discCon(key) _G.nLhe.discCon(key) end
local function notify(t, c, d) _G.nLhe.notify(t, c, d) end

-- ==========================================
-- 4.1. WALKSPEED
-- ==========================================

PlayerGroup:AddToggle("Walkspeed", {
    Name = "Walkspeed",
    Default = false,
    Callback = function(v)
        bool.Walkspeed = v
        if v then
            cons["Walkspeed"] = RunService.Stepped:Connect(function()
                if not bool.Walkspeed then return end
                local char = plr.Character
                local hum = char and char:FindFirstChildOfClass("Humanoid")
                local hrp = char and char:FindFirstChild("HumanoidRootPart")
                if hum and hrp then
                    local dir = hum.MoveDirection
                    if dir.Magnitude > 0 then
                        hrp.AssemblyLinearVelocity = Vector3.new(
                            dir.X * (int.WalkSpeedValue or 16),
                            hrp.AssemblyLinearVelocity.Y,
                            dir.Z * (int.WalkSpeedValue or 16)
                        )
                    end
                end
            end)
        else
            discCon("Walkspeed")
        end
        notify("nLhe", "Walkspeed: " .. (v and "ON" or "OFF"), 2)
    end
})

PlayerGroup:AddSlider("SpeedValue", {
    Name = "Speed Value",
    Min = 0,
    Max = 500,
    Default = 16,
    Callback = function(v)
        int.WalkSpeedValue = v
    end
})

-- ==========================================
-- 4.2. INFINITE JUMP
-- ==========================================

PlayerGroup:AddToggle("InfiniteJump", {
    Name = "Infinite Jump",
    Default = false,
    Callback = function(v)
        bool.InfiniteJump = v
        if v then
            cons["InfiniteJump"] = UIS.JumpRequest:Connect(function()
                if bool.InfiniteJump then
                    local char = plr.Character
                    local hum = char and char:FindFirstChildOfClass("Humanoid")
                    if hum and hum:GetState() ~= Enum.HumanoidStateType.Jumping then
                        hum:ChangeState(Enum.HumanoidStateType.Jumping)
                    end
                end
            end)
        else
            discCon("InfiniteJump")
        end
        notify("nLhe", "Infinite Jump: " .. (v and "ON" or "OFF"), 2)
    end
})

-- ==========================================
-- 4.3. NO CLIP
-- ==========================================

PlayerGroup:AddToggle("NoClip", {
    Name = "No Clip",
    Default = false,
    Callback = function(v)
        bool.NoClip = v
        if v then
            cons["NoClip"] = RunService.Stepped:Connect(function()
                if bool.NoClip then
                    local char = plr.Character
                    if char then
                        for _, part in pairs(char:GetDescendants()) do
                            if part:IsA("BasePart") then part.CanCollide = false end
                        end
                    end
                end
            end)
        else
            discCon("NoClip")
            local char = plr.Character
            if char then
                for _, part in pairs(char:GetDescendants()) do
                    if part:IsA("BasePart") then part.CanCollide = true end
                end
            end
        end
        notify("nLhe", "No Clip: " .. (v and "ON" or "OFF"), 2)
    end
})

-- ==========================================
-- 4.4. FLY
-- ==========================================

local flyEnabled = false
local flySpeed = 120
local flyConnection = nil
local flyVelocity = nil
local flyGyro = nil

PlayerGroup:AddToggle("Fly", {
    Name = "Fly",
    Default = false,
    Callback = function(v)
        flyEnabled = v
        if v then
            if flyConnection then flyConnection:Disconnect() end
            flyConnection = RunService.RenderStepped:Connect(function()
                if not flyEnabled then return end
                local char = plr.Character
                local hum = char and char:FindFirstChildOfClass("Humanoid")
                local hrp = char and char:FindFirstChild("HumanoidRootPart")
                if not hum or not hrp then return end
                local controlPart = (hum.Sit and hum.SeatPart and hum.SeatPart.AssemblyRootPart) or hrp
                if not flyVelocity or flyVelocity.Parent ~= controlPart then
                    if flyVelocity then flyVelocity:Destroy() end
                    flyVelocity = Instance.new("BodyVelocity")
                    flyVelocity.MaxForce = Vector3.new(1e9, 1e9, 1e9)
                    flyVelocity.Parent = controlPart
                end
                if not flyGyro or flyGyro.Parent ~= controlPart then
                    if flyGyro then flyGyro:Destroy() end
                    flyGyro = Instance.new("BodyGyro")
                    flyGyro.MaxTorque = Vector3.new(1e9, 1e9, 1e9)
                    flyGyro.D = 100
                    flyGyro.Parent = controlPart
                end
                local move = Vector3.zero
                if UIS:IsKeyDown(Enum.KeyCode.W) then move = move + Vector3.new(0, 0, -1) end
                if UIS:IsKeyDown(Enum.KeyCode.S) then move = move + Vector3.new(0, 0, 1) end
                if UIS:IsKeyDown(Enum.KeyCode.A) then move = move + Vector3.new(-1, 0, 0) end
                if UIS:IsKeyDown(Enum.KeyCode.D) then move = move + Vector3.new(1, 0, 0) end
                if UIS:IsKeyDown(Enum.KeyCode.Space) then move = move + Vector3.new(0, 1, 0) end
                if UIS:IsKeyDown(Enum.KeyCode.LeftControl) then move = move + Vector3.new(0, -1, 0) end
                local cam = Workspace.CurrentCamera
                local speed = flySpeed
                if move.Magnitude > 0 then
                    flyVelocity.Velocity = (cam.CFrame.LookVector * -move.Z + cam.CFrame.RightVector * move.X + Vector3.new(0, move.Y, 0)) * speed
                else
                    flyVelocity.Velocity = Vector3.zero
                end
                flyGyro.CFrame = CFrame.new(controlPart.Position, controlPart.Position + cam.CFrame.LookVector)
                hum.PlatformStand = not hum.Sit
            end)
        else
            if flyConnection then flyConnection:Disconnect(); flyConnection = nil end
            if flyVelocity then flyVelocity:Destroy(); flyVelocity = nil end
            if flyGyro then flyGyro:Destroy(); flyGyro = nil end
            local char = plr.Character
            local hum = char and char:FindFirstChildOfClass("Humanoid")
            if hum then
                hum.PlatformStand = false
                hum:ChangeState(Enum.HumanoidStateType.GettingUp)
            end
        end
        notify("nLhe", "Fly: " .. (v and "ON" or "OFF"), 2)
    end
})

PlayerGroup:AddSlider("FlySpeed", {
    Name = "Fly Speed",
    Min = 1,
    Max = 1000,
    Default = 120,
    Callback = function(v)
        flySpeed = v
    end
})

-- ==========================================
-- 4.5. WATER WALK
-- ==========================================

PlayerGroup:AddToggle("WaterWalk", {
    Name = "Water Walk",
    Default = false,
    Callback = function(v)
        bool.WaterWalk = v
        local ocean = Workspace:FindFirstChild("Map")
        if ocean then
            ocean = ocean:FindFirstChild("AlwaysHereTweenedObjects")
            if ocean then
                ocean = ocean:FindFirstChild("Ocean")
                if ocean then
                    ocean = ocean:FindFirstChild("Object")
                    if ocean then
                        ocean = ocean:FindFirstChild("ObjectModel")
                    end
                end
            end
        end
        if not ocean then
            notify("nLhe", "Ocean not found!", 3)
            return
        end
        for _, part in pairs(ocean:GetChildren()) do
            if part:IsA("BasePart") then
                part.CanCollide = v
                part.CanTouch = v
                part.CanQuery = v
            end
        end
        notify("nLhe", "Water Walk: " .. (v and "ON" or "OFF"), 2)
    end
})

-- ==========================================
-- 4.6. PLAYER ESP (ИЗ RR9)
-- ==========================================

do
    local espEnabled = false
    local espColor = Color3.fromRGB(255, 0, 0)
    local rainbowEnabled = false
    local espConnections = {}
    local espObjects = {}

    local function createESP(player)
        if not player or not player.Character then return end
        local char = player.Character
        local hrp = char:FindFirstChild("HumanoidRootPart")
        if not hrp then return end

        local highlight = Instance.new("Highlight")
        highlight.Name = "ESP_Highlight"
        highlight.Adornee = char
        highlight.FillColor = espColor
        highlight.OutlineColor = Color3.fromRGB(255, 255, 255)
        highlight.FillTransparency = 0.4
        highlight.OutlineTransparency = 0
        highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
        highlight.Parent = char

        local billboard = Instance.new("BillboardGui")
        billboard.Name = "ESP_Name"
        billboard.Adornee = hrp
        billboard.Size = UDim2.new(0, 200, 0, 30)
        billboard.StudsOffset = Vector3.new(0, 3, 0)
        billboard.AlwaysOnTop = true
        billboard.Parent = hrp

        local label = Instance.new("TextLabel")
        label.Size = UDim2.new(1, 0, 1, 0)
        label.BackgroundTransparency = 1
        label.Text = player.DisplayName .. " (" .. player.Name .. ")"
        label.TextColor3 = Color3.fromRGB(255, 255, 255)
        label.TextStrokeTransparency = 0
        label.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
        label.Font = Enum.Font.GothamBold
        label.TextScaled = true
        label.Parent = billboard

        local distBillboard = Instance.new("BillboardGui")
        distBillboard.Name = "ESP_Distance"
        distBillboard.Adornee = hrp
        distBillboard.Size = UDim2.new(0, 100, 0, 20)
        distBillboard.StudsOffset = Vector3.new(0, -2, 0)
        distBillboard.AlwaysOnTop = true
        distBillboard.Parent = hrp

        local distLabel = Instance.new("TextLabel")
        distLabel.Size = UDim2.new(1, 0, 1, 0)
        distLabel.BackgroundTransparency = 1
        distLabel.Text = "0 studs"
        distLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
        distLabel.TextStrokeTransparency = 0
        distLabel.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
        distLabel.Font = Enum.Font.GothamBold
        distLabel.TextScaled = true
        distLabel.Parent = distBillboard

        table.insert(espObjects, {
            player = player,
            highlight = highlight,
            billboard = billboard,
            distBillboard = distBillboard,
        })

        local conn = RunService.RenderStepped:Connect(function()
            if not espEnabled or not player.Character then
                conn:Disconnect()
                return
            end
            local localChar = plr.Character
            local localHrp = localChar and localChar:FindFirstChild("HumanoidRootPart")
            if localHrp and hrp and hrp.Parent then
                local dist = math.floor((hrp.Position - localHrp.Position).Magnitude)
                distLabel.Text = dist .. " studs"
            end
        end)
        table.insert(espConnections, conn)
    end

    local function clearESP()
        for _, conn in ipairs(espConnections) do
            pcall(function() conn:Disconnect() end)
        end
        espConnections = {}
        for _, obj in ipairs(espObjects) do
            pcall(function()
                if obj.highlight then obj.highlight:Destroy() end
                if obj.billboard then obj.billboard:Destroy() end
                if obj.distBillboard then obj.distBillboard:Destroy() end
            end)
        end
        espObjects = {}
    end

    local function updateAllESP()
        clearESP()
        if not espEnabled then return end
        for _, p in pairs(Players:GetPlayers()) do
            if p ~= plr and p.Character then
                createESP(p)
            end
        end
    end

    local function updateColors()
        for _, obj in ipairs(espObjects) do
            pcall(function()
                if obj.highlight then
                    obj.highlight.FillColor = espColor
                end
            end)
        end
    end

    PlayerESP:AddColorpicker("ESPColor", {
        Name = "ESP Color",
        Default = Color3.fromRGB(255, 0, 0),
        Callback = function(v)
            espColor = v
            if not rainbowEnabled then updateColors() end
        end
    })

    PlayerESP:AddToggle("RainbowESP", {
        Name = "Rainbow ESP",
        Default = false,
        Callback = function(v)
            rainbowEnabled = v
            if v then
                task.spawn(function()
                    while rainbowEnabled and espEnabled do
                        local hue = tick() % 1
                        espColor = Color3.fromHSV(hue, 1, 1)
                        updateColors()
                        task.wait(0.05)
                    end
                end)
            else
                espColor = Options.ESPColor.Value or Color3.fromRGB(255, 0, 0)
                updateColors()
            end
        end
    })

    PlayerESP:AddToggle("PlayerESP", {
        Name = "Enable Player ESP",
        Default = false,
        Callback = function(v)
            espEnabled = v
            if v then
                updateAllESP()
                local playerAddedConn = Players.PlayerAdded:Connect(function(p)
                    task.wait(0.5)
                    if espEnabled and p ~= plr and p.Character then
                        createESP(p)
                    end
                end)
                table.insert(espConnections, playerAddedConn)
            else
                clearESP()
            end
            notify("nLhe", "Player ESP: " .. (v and "ON" or "OFF"), 2)
        end
    })

    Players.PlayerRemoving:Connect(function(p)
        for i, obj in ipairs(espObjects) do
            if obj.player == p then
                pcall(function()
                    if obj.highlight then obj.highlight:Destroy() end
                    if obj.billboard then obj.billboard:Destroy() end
                    if obj.distBillboard then obj.distBillboard:Destroy() end
                end)
                table.remove(espObjects, i)
                break
            end
        end
    end)
end

-- ==========================================
-- 4.7. BOOST FPS (ИЗ RR9)
-- ==========================================

local oldProperties = {}

PlayerPerf:AddButton({
    Name = "Boost FPS",
    Callback = function()
        for _, v in pairs(Workspace:GetDescendants()) do
            if v:IsA("BasePart") then
                if not oldProperties[v] then
                    oldProperties[v] = {
                        Material = v.Material,
                        Reflectance = v.Reflectance,
                        CastShadow = v.CastShadow
                    }
                end
                v.Material = Enum.Material.Plastic
                v.Reflectance = 0
                v.CastShadow = false
            elseif v:IsA("ParticleEmitter") or v:IsA("Trail") or v:IsA("Smoke") or v:IsA("Fire") then
                if not oldProperties[v] then
                    oldProperties[v] = { Enabled = v.Enabled }
                end
                v.Enabled = false
            end
        end

        for _, p in pairs(Players:GetPlayers()) do
            if p.Character then
                for _, part in pairs(p.Character:GetDescendants()) do
                    if part:IsA("BasePart") and part.Name ~= "HumanoidRootPart" then
                        if not oldProperties[part] then
                            oldProperties[part] = {
                                Material = part.Material,
                                Reflectance = part.Reflectance,
                                CastShadow = part.CastShadow
                            }
                        end
                        part.Material = Enum.Material.Plastic
                        part.Reflectance = 0
                        part.CastShadow = false
                    end
                end
            end
        end

        if not oldProperties["Lighting"] then
            oldProperties["Lighting"] = {
                GlobalShadows = Lighting.GlobalShadows,
                FogEnd = Lighting.FogEnd,
                Brightness = Lighting.Brightness
            }
        end
        Lighting.GlobalShadows = false
        Lighting.FogEnd = 100000
        Lighting.Brightness = 2
        notify("nLhe", "FPS Boost applied!", 3)
    end
})

PlayerPerf:AddButton({
    Name = "Revert FPS Boost",
    Callback = function()
        for obj, props in pairs(oldProperties) do
            if typeof(obj) == "Instance" and obj.Parent then
                for prop, value in pairs(props) do
                    obj[prop] = value
                end
            elseif obj == "Lighting" then
                for prop, value in pairs(props) do
                    Lighting[prop] = value
                end
            end
        end
        oldProperties = {}
        notify("nLhe", "FPS Boost reverted!", 3)
    end
})
-- ==========================================
-- ЧАСТЬ 5: TELEPORT + AURAS
-- ==========================================

print("🔄 Loading Teleport + Auras...")

local plr = _G.nLhe.plr
local RS = _G.nLhe.RS
local RunService = _G.nLhe.RunService
local Workspace = _G.nLhe.Workspace
local Players = _G.nLhe.Players
local UIS = _G.nLhe.UIS

local SetNetworkOwner = RS:FindFirstChild("GrabEvents") and RS.GrabEvents:FindFirstChild("SetNetworkOwner")
local SpawnToyRemote = RS:FindFirstChild("MenuToys") and RS.MenuToys:FindFirstChild("SpawnToyRemoteFunction")

local TeleportGroup = _G.nLhe.Tabs.Teleport:AddLeftGroupbox("Teleports", "map-pin")
local AurasGroup = _G.nLhe.Tabs.Auras:AddLeftGroupbox("Auras", "sparkles")

local bool = _G.nLhe.bool
local int = _G.nLhe.int
local cons = _G.nLhe.cons
local etc = _G.nLhe.etc

local function discCon(key) _G.nLhe.discCon(key) end
local function notify(t, c, d) _G.nLhe.notify(t, c, d) end
local function sno(part) _G.nLhe.sno(part) end
local function GetMagnitude(a, b) return _G.nLhe.GetMagnitude(a, b) end

-- ==========================================
-- 5.1. TELEPORT
-- ==========================================

local function GetMousePosition()
    local mouse = UIS:GetMouseLocation()
    local cam = Workspace.CurrentCamera
    if not cam then return nil end
    local ray = cam:ScreenPointToRay(mouse.X, mouse.Y)
    local params = RaycastParams.new()
    params.FilterType = Enum.RaycastFilterType.Blacklist
    params.FilterDescendantsInstances = {plr.Character}
    local result = Workspace:Raycast(ray.Origin, ray.Direction * 1000, params)
    if result then return result.Position end
    return nil
end

TeleportGroup:AddButton({
    Name = "Teleport to Mouse",
    Callback = function()
        local char = plr.Character
        local hrp = char and char:FindFirstChild("HumanoidRootPart")
        local pos = GetMousePosition()
        if pos and hrp and hrp.Parent then
            hrp.CFrame = CFrame.new(pos + Vector3.new(0, 3, 0))
            hrp.AssemblyLinearVelocity = Vector3.zero
            hrp.AssemblyAngularVelocity = Vector3.zero
            notify("nLhe", "Teleported to mouse position", 2)
        else
            notify("nLhe", "Could not teleport to mouse!", 3)
        end
    end
})

TeleportGroup:AddButton({
    Name = "Teleport to Spawn",
    Callback = function()
        local char = plr.Character
        local hrp = char and char:FindFirstChild("HumanoidRootPart")
        local spawn = Workspace:FindFirstChild("SpawnLocation")
        if spawn and hrp and hrp.Parent then
            hrp.CFrame = spawn.CFrame + Vector3.new(0, 3, 0)
            hrp.AssemblyLinearVelocity = Vector3.zero
            hrp.AssemblyAngularVelocity = Vector3.zero
            notify("nLhe", "Teleported to spawn", 2)
        else
            notify("nLhe", "Spawn not found!", 3)
        end
    end
})

TeleportGroup:AddButton({
    Name = "TP to Green House",
    Callback = function()
        local char = plr.Character
        local hrp = char and char:FindFirstChild("HumanoidRootPart")
        if hrp and hrp.Parent then
            hrp.CFrame = CFrame.new(-548.305054, -2.45424771, 79.3213348) + Vector3.new(0, 3, 0)
            hrp.AssemblyLinearVelocity = Vector3.zero
            hrp.AssemblyAngularVelocity = Vector3.zero
            notify("nLhe", "Teleported to Green House", 2)
        end
    end
})

TeleportGroup:AddButton({
    Name = "TP to Pink House",
    Callback = function()
        local char = plr.Character
        local hrp = char and char:FindFirstChild("HumanoidRootPart")
        if hrp and hrp.Parent then
            hrp.CFrame = CFrame.new(-475.493835, -2.70774508, -159.395279) + Vector3.new(0, 3, 0)
            hrp.AssemblyLinearVelocity = Vector3.zero
            hrp.AssemblyAngularVelocity = Vector3.zero
            notify("nLhe", "Teleported to Pink House", 2)
        end
    end
})

TeleportGroup:AddButton({
    Name = "TP to Blue House",
    Callback = function()
        local char = plr.Character
        local hrp = char and char:FindFirstChild("HumanoidRootPart")
        if hrp and hrp.Parent then
            hrp.CFrame = CFrame.new(501.939911, 88.2323608, -349.129211) + Vector3.new(0, 3, 0)
            hrp.AssemblyLinearVelocity = Vector3.zero
            hrp.AssemblyAngularVelocity = Vector3.zero
            notify("nLhe", "Teleported to Blue House", 2)
        end
    end
})

TeleportGroup:AddButton({
    Name = "TP to China House",
    Callback = function()
        local char = plr.Character
        local hrp = char and char:FindFirstChild("HumanoidRootPart")
        if hrp and hrp.Parent then
            hrp.CFrame = CFrame.new(545.441833, 128.004593, -99.4881439) + Vector3.new(0, 3, 0)
            hrp.AssemblyLinearVelocity = Vector3.zero
            hrp.AssemblyAngularVelocity = Vector3.zero
            notify("nLhe", "Teleported to China House", 2)
        end
    end
})

TeleportGroup:AddButton({
    Name = "TP to Target",
    Callback = function()
        local char = plr.Character
        local hrp = char and char:FindFirstChild("HumanoidRootPart")
        if not etc.SelectedTarget then
            notify("nLhe", "Select target first!", 3)
            return
        end
        local target = etc.SelectedTarget
        if not target or not target.Character then
            notify("nLhe", "Target has no character!", 3)
            return
        end
        local tRoot = target.Character:FindFirstChild("HumanoidRootPart")
        if not tRoot then
            notify("nLhe", "Target HumanoidRootPart not found!", 3)
            return
        end
        if hrp and hrp.Parent then
            hrp.CFrame = tRoot.CFrame + Vector3.new(0, 3, 2)
            hrp.AssemblyLinearVelocity = Vector3.zero
            hrp.AssemblyAngularVelocity = Vector3.zero
            notify("nLhe", "Teleported to " .. target.Name, 2)
        end
    end
})

TeleportGroup:AddToggle("LoopTPRandom", {
    Name = "Loop TP (Random)",
    Default = false,
    Callback = function(v)
        bool.LoopTPRandom = v
        if v then
            cons["LoopTPRandom"] = RunService.Heartbeat:Connect(function()
                if not bool.LoopTPRandom then return end
                local char = plr.Character
                local hrp = char and char:FindFirstChild("HumanoidRootPart")
                if hrp then
                    hrp.CFrame = CFrame.new(
                        math.random(-500, 500),
                        math.random(30, 480),
                        math.random(-500, 500)
                    )
                    hrp.AssemblyLinearVelocity = Vector3.zero
                    hrp.AssemblyAngularVelocity = Vector3.zero
                end
            end)
        else
            discCon("LoopTPRandom")
        end
        notify("nLhe", "Loop TP Random: " .. (v and "ON" or "OFF"), 2)
    end
})

-- ==========================================
-- 5.2. AURAS
-- ==========================================

AurasGroup:AddSlider("AuraRadius", {
    Name = "Aura Radius",
    Min = 5,
    Max = 50,
    Default = 20,
    Callback = function(v)
        int.AuraRadius = v
    end
})

AurasGroup:AddToggle("IgnoreFriends", {
    Name = "Ignore Friends",
    Default = true,
    Callback = function(v)
        bool.IgnoreFriends = v
    end
})

-- ==========================================
-- 5.3. REMOVE ANTI KICK AURA
-- ==========================================

local removeAntiKickAuraActive = false
local removeAntiKickAuraConnection = nil
local removeAntiKickRadius = 15
local useWhitelistRemoveAntiKick = true

AurasGroup:AddSlider("RemoveAntiKickRadius", {
    Name = "Remove Anti Kick Radius",
    Min = 5,
    Max = 50,
    Default = 15,
    Callback = function(v)
        removeAntiKickRadius = v
    end
})

AurasGroup:AddToggle("RemoveAntiKickWhitelist", {
    Name = "Ignore Friends (Remove Anti Kick)",
    Default = true,
    Callback = function(v)
        useWhitelistRemoveAntiKick = v
    end
})

AurasGroup:AddToggle("RemoveAntiKickAura", {
    Name = "Remove Anti Kick Aura",
    Default = false,
    Callback = function(on)
        removeAntiKickAuraActive = on
        if not on then
            if removeAntiKickAuraConnection then
                removeAntiKickAuraConnection:Disconnect()
                removeAntiKickAuraConnection = nil
            end
            notify("nLhe", "Remove Anti Kick Aura: OFF", 2)
            return
        end

        task.spawn(function()
            if not SetNetworkOwner then return end
            local SetNetOwner = SetNetworkOwner

            removeAntiKickAuraConnection = RunService.Heartbeat:Connect(function()
                local myChar = plr.Character
                local myRoot = myChar and myChar:FindFirstChild("HumanoidRootPart")
                if not myRoot then return end

                for _, target in ipairs(Players:GetPlayers()) do
                    if target ~= plr then
                        local tChar = target.Character
                        local tRoot = tChar and tChar:FindFirstChild("HumanoidRootPart")
                        if not tRoot then continue end

                        if useWhitelistRemoveAntiKick and plr:IsFriendsWith(target.UserId) then
                            continue
                        end

                        if GetMagnitude(tRoot, myRoot) <= removeAntiKickRadius then
                            local spawned = Workspace:FindFirstChild(target.Name .. "SpawnedInToys")
                            if spawned then
                                for _, toyName in ipairs({"NinjaKunai", "NinjaShuriken", "AntiKick"}) do
                                    local toy = spawned:FindFirstChild(toyName)
                                    if toy then
                                        local part = toy:FindFirstChild("SoundPart")
                                        if part then
                                            pcall(function()
                                                SetNetOwner:FireServer(part, part.CFrame)
                                                if part:FindFirstChild("PartOwner") and part.PartOwner.Value == plr.Name then
                                                    part.CFrame = CFrame.new(0, 1000, 0)
                                                end
                                            end)
                                        end
                                    end
                                end
                            end
                        end
                    end
                end
            end)
        end)
        notify("nLhe", "Remove Anti Kick Aura: ON", 2)
    end
})

-- ==========================================
-- ЧАСТЬ 6: SERVER + KEYBINDS
-- ==========================================

print("🔄 Loading Server + Keybinds...")

local plr = _G.nLhe.plr
local RS = _G.nLhe.RS
local RunService = _G.nLhe.RunService
local Workspace = _G.nLhe.Workspace
local Players = _G.nLhe.Players
local UIS = _G.nLhe.UIS
local Debris = _G.nLhe.Debris

local SetNetworkOwner = RS:FindFirstChild("GrabEvents") and RS.GrabEvents:FindFirstChild("SetNetworkOwner")
local DestroyToy = RS:FindFirstChild("MenuToys") and RS.MenuToys:FindFirstChild("DestroyToy")
local RagdollRemote = RS:FindFirstChild("CharacterEvents") and RS.CharacterEvents:FindFirstChild("RagdollRemote")
local SpawnToyRemote = RS:FindFirstChild("MenuToys") and RS.MenuToys:FindFirstChild("SpawnToyRemoteFunction")
local DestroyGrabLine = RS:FindFirstChild("GrabEvents") and RS.GrabEvents:FindFirstChild("DestroyGrabLine")
local CreateGrabLine = RS:FindFirstChild("GrabEvents") and RS.GrabEvents:FindFirstChild("CreateGrabLine")

local ServerGroup = _G.nLhe.Tabs.Server:AddLeftGroupbox("Server", "server")
local ServerLag = _G.nLhe.Tabs.Server:AddLeftGroupbox("Lags", "zap")
local ServerDestroy = _G.nLhe.Tabs.Server:AddRightGroupbox("Server Destroy", "skull")
local KeybindsGroup = _G.nLhe.Tabs.Keybinds:AddLeftGroupbox("Keybinds", "keyboard")

local bool = _G.nLhe.bool
local int = _G.nLhe.int
local cons = _G.nLhe.cons
local etc = _G.nLhe.etc

local function discCon(key) _G.nLhe.discCon(key) end
local function notify(t, c, d) _G.nLhe.notify(t, c, d) end

-- ==========================================
-- 6.1. LINE LAG
-- ==========================================

ServerLag:AddSlider("LineLagAmount", {
    Name = "Line Lag Amount",
    Min = 1,
    Max = 30000,
    Default = 50,
    Callback = function(v)
        int.LineLagAmount = v
    end
})

ServerLag:AddButton({
    Name = "Line Lag [USING AMOUNT]",
    Callback = function()
        for i = 1, int.LineLagAmount or 50 do
            pcall(function()
                if CreateGrabLine then
                    CreateGrabLine:FireServer(Workspace.SpawnLocation, CFrame.new(0, 9e9, 0))
                end
            end)
        end
        notify("nLhe", "Line Lag executed: " .. (int.LineLagAmount or 50) .. " lines", 2)
    end
})

ServerLag:AddToggle("LineLagLoop", {
    Name = "Line Lag (Loop)",
    Default = false,
    Callback = function(v)
        bool.LineLagLoop = v
        if v then
            cons["LineLagLoop"] = RunService.Heartbeat:Connect(function()
                if not bool.LineLagLoop then return end
                for i = 1, 10 do
                    pcall(function()
                        if CreateGrabLine then
                            CreateGrabLine:FireServer(Workspace.SpawnLocation, CFrame.new(0, 9e9, 0))
                        end
                    end)
                end
                task.wait(0.1)
            end)
        else
            discCon("LineLagLoop")
        end
        notify("nLhe", "Line Lag Loop: " .. (v and "ON" or "OFF"), 2)
    end
})

-- ==========================================
-- 6.2. PACKET LAG
-- ==========================================

local packetSizeExtra = 0.1
local packetRepeatsExtra = 100
local packetDelayExtra = 1.0
local packetSentCount = 0
local packetReceivedCount = 0
local packetLastSendTime = 0
local packetLagActive = false

local function CalculateRepeatsExtra(val)
    local targetBytes = val * 1024 * 1024
    packetRepeatsExtra = math.max(1, math.floor(targetBytes / 143))
end
CalculateRepeatsExtra(packetSizeExtra)

ServerLag:AddSlider("PacketSize", {
    Name = "Packet Size (MB)",
    Min = 0.01,
    Max = 19,
    Default = 0.1,
    Callback = function(v)
        packetSizeExtra = v
        CalculateRepeatsExtra(v)
    end
})

ServerLag:AddSlider("PacketDelay", {
    Name = "Packet Delay (seconds)",
    Min = 0.1,
    Max = 10,
    Default = 1.0,
    Callback = function(v)
        packetDelayExtra = v
    end
})

local sentLabel = ServerLag:AddLabel("🛜🔼 Sent packets: 0")
local receivedLabel = ServerLag:AddLabel("🛜🔽 Received packets: 0")

local function updatePacketLabels()
    sentLabel:SetText("🛜🔼 Sent packets: " .. packetSentCount)
    receivedLabel:SetText("🛜🔽 Received packets: " .. packetReceivedCount)
end

ServerLag:AddToggle("PacketLagServer", {
    Name = "Packet Lag Server",
    Default = false,
    Callback = function(v)
        packetLagActive = v
        packetLastSendTime = 0
        if v then
            if cons["PacketLagServer"] then discCon("PacketLagServer") end

            local extendGrabLine = RS:FindFirstChild("GrabEvents") and RS.GrabEvents:FindFirstChild("ExtendGrabLine")
            if not extendGrabLine then
                notify("nLhe", "ExtendGrabLine not found!", 3)
                packetLagActive = false
                return
            end

            cons["PacketLagServer"] = RunService.Heartbeat:Connect(function()
                if not packetLagActive then return end
                local now = tick()
                if now - packetLastSendTime >= packetDelayExtra then
                    packetLastSendTime = now
                    local text = string.rep("metaballs metaballs metaballs metaballs metaballs metaballs metaballs metaballs", packetRepeatsExtra)
                    pcall(function()
                        extendGrabLine:FireServer(text)
                        packetSentCount = packetSentCount + 1
                        updatePacketLabels()
                    end)
                end
            end)
            notify("nLhe", "Packet Lag: ON (size: " .. packetSizeExtra .. " MB, delay: " .. packetDelayExtra .. "s)", 3)
        else
            discCon("PacketLagServer")
            notify("nLhe", "Packet Lag: OFF", 2)
        end
    end
})

if RS:FindFirstChild("GrabEvents") and RS.GrabEvents:FindFirstChild("ExtendGrabLine") then
    RS.GrabEvents.ExtendGrabLine.OnClientEvent:Connect(function(data)
        if type(data) == "string" and string.len(data) > 300 then
            packetReceivedCount = packetReceivedCount + 1
            updatePacketLabels()
        end
    end)
end

ServerLag:AddButton({
    Name = "Reset Packet Stats",
    Callback = function()
        packetSentCount = 0
        packetReceivedCount = 0
        updatePacketLabels()
        notify("nLhe", "Packet stats reset!", 2)
    end
})

-- ==========================================
-- 6.3. MONSTER LAG
-- ==========================================

ServerLag:AddToggle("MonsterLag", {
    Name = "Monster Lag",
    Default = false,
    Callback = function(v)
        _G.MonsterLagEnabled = v
        if v then
            task.spawn(function()
                while _G.MonsterLagEnabled and CreateGrabLine do
                    local spawnLocation = Workspace:FindFirstChild("SpawnLocation") or Workspace:FindFirstChild("Spawn") or (plr.Character and plr.Character:FindFirstChild("HumanoidRootPart"))
                    if spawnLocation then
                        local randomX = math.random(-9e9, 9e9)
                        local randomZ = math.random(-9e9, 9e9)
                        CreateGrabLine:FireServer(spawnLocation, CFrame.new(randomX, 0, randomZ))
                    end
                    task.wait()
                end
            end)
        end
        notify("nLhe", "Monster Lag: " .. (v and "ON" or "OFF"), 2)
    end
})

-- ==========================================
-- 6.4. BLOBMAN KICK ALL / KILL ALL
-- ==========================================

ServerGroup:AddToggle("BlobmanKickAll", {
    Name = "Blobman Kick All",
    Default = false,
    Callback = function(v)
        bool.BlobmanKickAll = v
        if v then
            cons["BlobmanKickAll"] = RunService.Heartbeat:Connect(function()
                if not bool.BlobmanKickAll then return end
                pcall(function()
                    local inv = Workspace:FindFirstChild(plr.Name.."SpawnedInToys")
                    if not inv then return end
                    local blob = inv:FindFirstChild("CreatureBlobman")
                    if not blob then
                        if SpawnToyRemote then
                            SpawnToyRemote:InvokeServer("CreatureBlobman", hrp.CFrame * CFrame.new(0, 5, 5), Vector3.zero)
                        end
                        task.wait(0.3)
                        blob = inv:FindFirstChild("CreatureBlobman")
                    end
                    if blob then
                        local seat = blob:FindFirstChild("VehicleSeat")
                        if seat then
                            local hum = plr.Character and plr.Character:FindFirstChild("Humanoid")
                            if hum then
                                seat:Sit(hum)
                                while not hum.SeatPart do task.wait() end
                                local scriptObj = blob:FindFirstChild("BlobmanSeatAndOwnerScript")
                                if scriptObj then
                                    local CreatureGrab = scriptObj:FindFirstChild("CreatureGrab")
                                    local CreatureDrop = scriptObj:FindFirstChild("CreatureDrop")
                                    local R_Det = blob:FindFirstChild("RightDetector")
                                    local R_Weld = R_Det and R_Det:FindFirstChild("RightWeld")
                                    if CreatureGrab and CreatureDrop and R_Det and R_Weld then
                                        for _, target in pairs(Players:GetPlayers()) do
                                            if target ~= plr and target.Character then
                                                local tRoot = target.Character:FindFirstChild("HumanoidRootPart")
                                                if tRoot then
                                                    CreatureGrab:FireServer(R_Det, tRoot, R_Weld)
                                                    task.wait(0.05)
                                                    CreatureDrop:FireServer(R_Weld, tRoot)
                                                end
                                            end
                                        end
                                    end
                                end
                            end
                        end
                    end
                end)
                task.wait(0.5)
            end)
        else
            discCon("BlobmanKickAll")
        end
        notify("nLhe", "Blobman Kick All: " .. (v and "ON" or "OFF"), 2)
    end
})

ServerGroup:AddToggle("BlobmanKillAll", {
    Name = "Blobman Kill All",
    Default = false,
    Callback = function(v)
        bool.BlobmanKillAll = v
        if v then
            cons["BlobmanKillAll"] = RunService.Heartbeat:Connect(function()
                if not bool.BlobmanKillAll then return end
                pcall(function()
                    local inv = Workspace:FindFirstChild(plr.Name.."SpawnedInToys")
                    if not inv then return end
                    local blob = inv:FindFirstChild("CreatureBlobman")
                    if not blob then
                        if SpawnToyRemote then
                            SpawnToyRemote:InvokeServer("CreatureBlobman", hrp.CFrame * CFrame.new(0, 5, 5), Vector3.zero)
                        end
                        task.wait(0.3)
                        blob = inv:FindFirstChild("CreatureBlobman")
                    end
                    if blob then
                        local seat = blob:FindFirstChild("VehicleSeat")
                        if seat then
                            local hum = plr.Character and plr.Character:FindFirstChild("Humanoid")
                            if hum then
                                seat:Sit(hum)
                                while not hum.SeatPart do task.wait() end
                                local scriptObj = blob:FindFirstChild("BlobmanSeatAndOwnerScript")
                                if scriptObj then
                                    local CreatureGrab = scriptObj:FindFirstChild("CreatureGrab")
                                    local CreatureRelease = scriptObj:FindFirstChild("CreatureRelease")
                                    local R_Det = blob:FindFirstChild("RightDetector")
                                    local R_Weld = R_Det and R_Det:FindFirstChild("RightWeld")
                                    if CreatureGrab and CreatureRelease and R_Det and R_Weld then
                                        for _, target in pairs(Players:GetPlayers()) do
                                            if target ~= plr and target.Character then
                                                local tRoot = target.Character:FindFirstChild("HumanoidRootPart")
                                                local tHum = target.Character:FindFirstChild("Humanoid")
                                                if tRoot and tHum and tHum.Health > 0 then
                                                    CreatureGrab:FireServer(R_Det, tRoot, R_Weld)
                                                    task.wait(0.1)
                                                    CreatureRelease:FireServer(R_Weld, tRoot)
                                                    tHum:ChangeState(Enum.HumanoidStateType.Dead)
                                                end
                                            end
                                        end
                                    end
                                end
                            end
                        end
                    end
                end)
                task.wait(0.5)
            end)
        else
            discCon("BlobmanKillAll")
        end
        notify("nLhe", "Blobman Kill All: " .. (v and "ON" or "OFF"), 2)
    end
})

-- ==========================================
-- 6.5. DESTROY SERVER
-- ==========================================

local selectedHeight = "Spawn"

ServerDestroy:AddDropdown("DestroyHeight", {
    Name = "Destroy Height",
    Values = {"Spawn", "Heaven"},
    Default = "Spawn",
    Callback = function(v)
        selectedHeight = v
    end
})

ServerDestroy:AddButton({
    Name = "Destroy Server",
    Callback = function()
        notify("nLhe", "Destroying server...", 3)
        task.spawn(function()
            local height = (selectedHeight == "Heaven") and 1e9 or 35

            for i = 1, 100 do
                pcall(function()
                    if CreateGrabLine then
                        CreateGrabLine:FireServer(Workspace.SpawnLocation, CFrame.new(0, 9e9, 0))
                    end
                end)
            end

            local players = {}
            for _, p in pairs(Players:GetPlayers()) do
                if p ~= plr and p.Character then
                    local root = p.Character:FindFirstChild("HumanoidRootPart")
                    if root then table.insert(players, {player = p, root = root}) end
                end
            end

            if #players == 0 then
                notify("nLhe", "No players to destroy!", 3)
                return
            end

            local char = plr.Character
            local hrp = char and char:FindFirstChild("HumanoidRootPart")
            local savedPos = hrp and hrp.CFrame

            for _, data in pairs(players) do
                if hrp and hrp.Parent then
                    hrp.CFrame = data.root.CFrame * CFrame.new(0, 5, 5)
                    hrp.AssemblyLinearVelocity = Vector3.zero
                    hrp.AssemblyAngularVelocity = Vector3.zero
                end
                if SetNetworkOwner then
                    SetNetworkOwner:FireServer(data.root, data.root.CFrame)
                end
                task.wait(0.1)
            end

            local radius = 40
            local angleStep = (math.pi * 2) / #players
            for idx, data in pairs(players) do
                local angle = (idx - 1) * angleStep
                local x = math.cos(angle) * radius
                local z = math.sin(angle) * radius
                pcall(function()
                    data.root.CFrame = CFrame.new(x, height, z)
                    data.root.AssemblyLinearVelocity = Vector3.zero
                    data.root.AssemblyAngularVelocity = Vector3.zero
                end)
                local bp = Instance.new("BodyPosition")
                bp.MaxForce = Vector3.new(1e9, 1e9, 1e9)
                bp.P = 40000000
                bp.Position = Vector3.new(x, height, z)
                bp.Parent = data.root
                Debris:AddItem(bp, 2)
                task.wait()
            end

            for i = 1, 8 do
                for _, data in pairs(players) do
                    pcall(function()
                        if DestroyGrabLine then
                            DestroyGrabLine:FireServer(data.root)
                        end
                    end)
                end
                task.wait(0.1)
            end

            if savedPos and hrp and hrp.Parent then
                hrp.CFrame = savedPos
                hrp.AssemblyLinearVelocity = Vector3.zero
                hrp.AssemblyAngularVelocity = Vector3.zero
            end

            notify("nLhe", "Server destroyed! (" .. #players .. " players)", 3)
        end)
    end
})

ServerDestroy:AddButton({
    Name = "Stop Lag",
    Callback = function()
        bool.LineLagLoop = false
        packetLagActive = false
        _G.MonsterLagEnabled = false
        notify("nLhe", "All lags stopped!", 2)
    end
})

-- ==========================================
-- 6.6. KEYBINDS
-- ==========================================

local keybindStates = {
    Teleport = true,
    SitBlob = true,
}

-- Teleport to Mouse
KeybindsGroup:AddToggle("EnableTeleportKeybind", {
    Name = "Enable Teleport Keybind",
    Default = true,
    Callback = function(v)
        keybindStates.Teleport = v
    end
})

local teleportKey = Enum.KeyCode.X
local teleportLabel = KeybindsGroup:AddLabel("Current key: X → Teleport to Mouse")

KeybindsGroup:AddButton({
    Name = "Change Key (Teleport)",
    Callback = function()
        notify("nLhe", "Press any key to bind for Teleport...", 3)
        local connection
        connection = UIS.InputBegan:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.Keyboard then
                teleportKey = input.KeyCode
                local keyName = tostring(teleportKey):gsub("Enum.KeyCode.", "")
                teleportLabel:SetText("Current key: " .. keyName .. " → Teleport to Mouse")
                notify("nLhe", "Bound to " .. keyName, 3)
                connection:Disconnect()
            end
        end)
    end
})

if cons["TeleportKeybind"] then cons["TeleportKeybind"]:Disconnect(); cons["TeleportKeybind"] = nil end
cons["TeleportKeybind"] = UIS.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.Keyboard then
        if input.KeyCode == teleportKey and keybindStates.Teleport then
            local mouse = plr:GetMouse()
            if mouse and mouse.Target then
                local char = plr.Character
                local hrp = char and char:FindFirstChild("HumanoidRootPart")
                if hrp and hrp.Parent then
                    pcall(function()
                        hrp.AssemblyLinearVelocity = Vector3.zero
                        hrp.AssemblyAngularVelocity = Vector3.zero
                        hrp.CFrame = mouse.Hit * CFrame.new(0, 5, 0)
                    end)
                end
            end
        end
    end
end)

-- Sit on Blob
KeybindsGroup:AddToggle("EnableSitBlobKeybind", {
    Name = "Enable Sit Blob Keybind",
    Default = true,
    Callback = function(v)
        keybindStates.SitBlob = v
    end
})

local sitBlobKey = Enum.KeyCode.Z
local sitBlobLabel = KeybindsGroup:AddLabel("Current key: Z → Sit on Blob")

KeybindsGroup:AddButton({
    Name = "Change Key (Sit on Blob)",
    Callback = function()
        notify("nLhe", "Press any key to bind for Sit on Blob...", 3)
        local connection
        connection = UIS.InputBegan:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.Keyboard then
                sitBlobKey = input.KeyCode
                local keyName = tostring(sitBlobKey):gsub("Enum.KeyCode.", "")
                sitBlobLabel:SetText("Current key: " .. keyName .. " → Sit on Blob")
                notify("nLhe", "Bound to " .. keyName, 3)
                connection:Disconnect()
            end
        end)
    end
})

if cons["SitBlobKeybind"] then cons["SitBlobKeybind"]:Disconnect(); cons["SitBlobKeybind"] = nil end
cons["SitBlobKeybind"] = UIS.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.Keyboard then
        if input.KeyCode == sitBlobKey and keybindStates.SitBlob then
            local inv = Workspace:FindFirstChild(plr.Name .. "SpawnedInToys")
            if inv and SpawnToyRemote then
                local hum = plr.Character and plr.Character:FindFirstChild("Humanoid")
                if hum then
                    local blob = inv:FindFirstChild("CreatureBlobman")
                    if not blob then
                        pcall(function()
                            SpawnToyRemote:InvokeServer("CreatureBlobman", hrp.CFrame * CFrame.new(0, 5, 10), Vector3.zero)
                        end)
                        task.wait(0.5)
                        blob = inv:FindFirstChild("CreatureBlobman")
                    end
                    if blob then
                        local seat = blob:FindFirstChild("VehicleSeat")
                        if seat then
                            seat:Sit(hum)
                            notify("nLhe", "Sitting on blob", 2)
                        end
                    end
                end
            end
        end
    end
end)

-- Remove Left Leg (Keybind)
KeybindsGroup:AddLabel("Remove Left Leg"):AddKeyPicker("RemoveLeftLeg", {
    Default = "None",
    Text = "Remove Left Leg",
    Mode = "Press",
    Callback = function()
        local grabParts = Workspace:FindFirstChild("GrabParts")
        if grabParts and grabParts:FindFirstChild("GrabPart") then
            local weld = grabParts.GrabPart:FindFirstChild("WeldConstraint")
            if weld then
                local target = weld.Part1 and weld.Part1.Parent
                if target and target:FindFirstChild("Left Leg") and target:FindFirstChild("Humanoid") and target.Humanoid:FindFirstChild("Ragdolled") then
                    if target.Humanoid.Ragdolled.Value then
                        local torso = target:FindFirstChild("Torso")
                        if torso then
                            local pos = torso.CFrame
                            local void = Workspace.FallenPartsDestroyHeight
                            Workspace.FallenPartsDestroyHeight = -100
                            target["Left Leg"].CFrame = CFrame.new(0, -1e3, 0)
                            task.wait(0.1)
                            torso.CFrame = CFrame.new(0, -950, 0)
                            task.wait(0)
                            torso.CFrame = pos
                            Workspace.FallenPartsDestroyHeight = void
                            notify("nLhe", "Left Leg removed!", 2)
                        end
                    end
                end
            end
        end
    end
})

-- Remove Right Leg (Keybind)
KeybindsGroup:AddLabel("Remove Right Leg"):AddKeyPicker("RemoveRightLeg", {
    Default = "None",
    Text = "Remove Right Leg",
    Mode = "Press",
    Callback = function()
        local grabParts = Workspace:FindFirstChild("GrabParts")
        if grabParts and grabParts:FindFirstChild("GrabPart") then
            local weld = grabParts.GrabPart:FindFirstChild("WeldConstraint")
            if weld then
                local target = weld.Part1 and weld.Part1.Parent
                if target and target:FindFirstChild("Right Leg") and target:FindFirstChild("Humanoid") and target.Humanoid:FindFirstChild("Ragdolled") then
                    if target.Humanoid.Ragdolled.Value then
                        local torso = target:FindFirstChild("Torso")
                        if torso then
                            local pos = torso.CFrame
                            local void = Workspace.FallenPartsDestroyHeight
                            Workspace.FallenPartsDestroyHeight = -100
                            target["Right Leg"].CFrame = CFrame.new(0, -1e3, 0)
                            task.wait(0.1)
                            torso.CFrame = CFrame.new(0, -950, 0)
                            task.wait(0)
                            torso.CFrame = pos
                            Workspace.FallenPartsDestroyHeight = void
                            notify("nLhe", "Right Leg removed!", 2)
                        end
                    end
                end
            end
        end
    end
})

-- ==========================================
-- ЧАСТЬ 7: VISUALS
-- ==========================================

print("🔄 Loading Visuals...")

local plr = _G.nLhe.plr
local RS = _G.nLhe.RS
local RunService = _G.nLhe.RunService
local Workspace = _G.nLhe.Workspace
local Players = _G.nLhe.Players
local Lighting = _G.nLhe.Lighting
local TweenService = _G.nLhe.TweenService
local CoreGui = _G.nLhe.CoreGui

local VisualsGroup = _G.nLhe.Tabs.Visuals:AddLeftGroupbox("Visuals", "eye")
local VisualsExtra = _G.nLhe.Tabs.Visuals:AddLeftGroupbox("Extra Visuals", "eye")
local VisualsSkybox = _G.nLhe.Tabs.Visuals:AddLeftGroupbox("Skybox", "cloud")
local OceanGroup = _G.nLhe.Tabs.Visuals:AddRightGroupbox("Ocean", "waves-horizontal")
local VisualsEffects = _G.nLhe.Tabs.Visuals:AddLeftGroupbox("Effects", "sparkles")

local bool = _G.nLhe.bool
local int = _G.nLhe.int
local cons = _G.nLhe.cons

local function discCon(key) _G.nLhe.discCon(key) end
local function notify(t, c, d) _G.nLhe.notify(t, c, d) end

-- ==========================================
-- 7.1. 3RD PERSON
-- ==========================================

VisualsGroup:AddToggle("ThirdPerson", {
    Name = "3rd Person View",
    Default = false,
    Callback = function(v)
        bool.ThirdPerson = v
        if v then
            plr.CameraMode = Enum.CameraMode.Classic
            plr.CameraMaxZoomDistance = 100
            plr.CameraMinZoomDistance = 0.5
        else
            plr.CameraMode = Enum.CameraMode.LockFirstPerson
            plr.CameraMaxZoomDistance = 0
            plr.CameraMinZoomDistance = 0
        end
        notify("nLhe", "3rd Person: " .. (v and "ON" or "OFF"), 2)
    end
})

-- ==========================================
-- 7.2. FOV
-- ==========================================

VisualsGroup:AddSlider("FOV", {
    Name = "Field of View",
    Min = 40,
    Max = 120,
    Default = 70,
    Callback = function(v)
        Workspace.CurrentCamera.FieldOfView = v
    end
})

-- ==========================================
-- 7.3. CHINESE HAT
-- ==========================================

local hatEnabled = false
local hatTransparency = 0.3
local hatRainbow = false
local hatColor = Color3.fromRGB(0, 255, 255)
local hatParts = {}

local function removeHat(c)
    local h = hatParts[c]
    if h then h:Destroy(); hatParts[c] = nil end
end

local function addHat(c)
    task.wait(0.1)
    local head = c and c:FindFirstChild("Head")
    if not head then return end
    removeHat(c)
    local hat = Instance.new("Part")
    hat.Name = "Hat"
    hat.Transparency = hatTransparency
    hat.Color = hatColor
    hat.Material = Enum.Material.Neon
    hat.CanCollide = false
    hat.CanTouch = false
    hat.CanQuery = false
    hat.Massless = true
    local m = Instance.new("SpecialMesh")
    m.MeshId = "rbxassetid://1033714"
    m.Scale = Vector3.new(2.4, 1.6, 2.4)
    m.Parent = hat
    local w = Instance.new("WeldConstraint")
    w.Part0 = head
    w.Part1 = hat
    w.Parent = hat
    hat.CFrame = head.CFrame * CFrame.new(0, 1.1, 0)
    hat.Parent = c
    hatParts[c] = hat
end

local function updateHats()
    for c, h in pairs(hatParts) do
        if h and h.Parent and c == plr.Character then
            h.Transparency = hatTransparency
            h.Color = hatRainbow and Color3.fromHSV((tick() % 5) / 5, 1, 1) or hatColor
        end
    end
end

VisualsGroup:AddToggle("ChineseHat", {
    Name = "Chinese Hat",
    Default = false,
    Callback = function(v)
        hatEnabled = v
        if v and plr.Character then
            addHat(plr.Character)
        elseif plr.Character then
            removeHat(plr.Character)
        end
        notify("nLhe", "Chinese Hat: " .. (v and "ON" or "OFF"), 2)
    end
})

VisualsGroup:AddToggle("RainbowHat", {
    Name = "Rainbow Hat",
    Default = false,
    Callback = function(v)
        hatRainbow = v
    end
})

VisualsGroup:AddSlider("HatTransparency", {
    Name = "Hat Transparency",
    Min = 0,
    Max = 100,
    Default = 30,
    Callback = function(v)
        hatTransparency = v / 100
    end
})

plr.CharacterAdded:Connect(function(char)
    task.wait(1)
    if hatEnabled then
        addHat(char)
    end
end)

RunService.Heartbeat:Connect(function()
    if hatEnabled then
        updateHats()
    end
end)

-- ==========================================
-- 7.4. SKYBOX
-- ==========================================

local SkyboxAssets = {
    ["HD"] = {Bk="http://www.roblox.com/asset/?id=16553658937",Dn="http://www.roblox.com/asset/?id=16553660713",Ft="http://www.roblox.com/asset/?id=16553662144",Lf="http://www.roblox.com/asset/?id=16553664042",Rt="http://www.roblox.com/asset/?id=16553665766",Up="http://www.roblox.com/asset/?id=16553667750"},
    ["Red Night"] = {Bk="http://www.roblox.com/asset/?id=401664839",Dn="http://www.roblox.com/asset/?id=401664862",Ft="http://www.roblox.com/asset/?id=401664960",Lf="http://www.roblox.com/asset/?id=401664881",Rt="http://www.roblox.com/asset/?id=401664901",Up="http://www.roblox.com/asset/?id=401664936"},
    ["Blue Night"] = {Bk="http://www.roblox.com/asset/?id=12064107",Dn="http://www.roblox.com/asset/?id=12064152",Ft="http://www.roblox.com/asset/?id=12064121",Lf="http://www.roblox.com/asset/?id=12063984",Rt="http://www.roblox.com/asset/?id=12064115",Up="http://www.roblox.com/asset/?id=12064131"},
    ["Space"] = {Bk="http://www.roblox.com/asset/?id=166509999",Dn="http://www.roblox.com/asset/?id=166510057",Ft="http://www.roblox.com/asset/?id=166510116",Lf="http://www.roblox.com/asset/?id=166510092",Rt="http://www.roblox.com/asset/?id=166510131",Up="http://www.roblox.com/asset/?id=166510114"},
    ["Sunset"] = {Bk="rbxassetid://600830446",Dn="rbxassetid://600831635",Ft="rbxassetid://600832720",Lf="rbxassetid://600886090",Rt="rbxassetid://600833862",Up="rbxassetid://600835177"},
    ["Pink"] = {Bk="rbxassetid://12216109205",Dn="rbxassetid://12216109875",Ft="rbxassetid://12216109489",Lf="rbxassetid://12216110170",Rt="rbxassetid://12216110471",Up="rbxassetid://12216108877"},
    ["Black Storm"] = {Bk="rbxassetid://15502511288",Dn="rbxassetid://15502508460",Ft="rbxassetid://15502510289",Lf="rbxassetid://15502507918",Rt="rbxassetid://15502509398",Up="rbxassetid://15502511911"},
    ["Blue Space"] = {Bk="rbxassetid://15536110634",Dn="rbxassetid://15536112543",Ft="rbxassetid://15536116141",Lf="rbxassetid://15536114370",Rt="rbxassetid://15536118762",Up="rbxassetid://15536117282"},
    ["Realistic"] = {Bk="rbxassetid://653719502",Dn="rbxassetid://653718790",Ft="rbxassetid://653719067",Lf="rbxassetid://653719190",Rt="rbxassetid://653718931",Up="rbxassetid://653719321"},
    ["Stormy"] = {Bk="http://www.roblox.com/asset/?id=18703245834",Dn="http://www.roblox.com/asset/?id=18703243349",Ft="http://www.roblox.com/asset/?id=18703240532",Lf="http://www.roblox.com/asset/?id=18703237556",Rt="http://www.roblox.com/asset/?id=18703235430",Up="http://www.roblox.com/asset/?id=18703232671"},
    ["Snow"] = {Bk="http://www.roblox.com/asset/?id=155657655",Dn="http://www.roblox.com/asset/?id=155674246",Ft="http://www.roblox.com/asset/?id=155657609",Lf="http://www.roblox.com/asset/?id=155657671",Rt="http://www.roblox.com/asset/?id=155657619",Up="http://www.roblox.com/asset/?id=155674931"},
    ["Arctic"] = {Bk="http://www.roblox.com/asset/?id=225469390",Dn="http://www.roblox.com/asset/?id=225469395",Ft="http://www.roblox.com/asset/?id=225469403",Lf="http://www.roblox.com/asset/?id=225469450",Rt="http://www.roblox.com/asset/?id=225469471",Up="http://www.roblox.com/asset/?id=225469481"},
    ["Roblox Default"] = {Bk="rbxasset://textures/sky/sky512_bk.tex",Dn="rbxasset://textures/sky/sky512_dn.tex",Ft="rbxasset://textures/sky/sky512_ft.tex",Lf="rbxasset://textures/sky/sky512_lf.tex",Rt="rbxasset://textures/sky/sky512_rt.tex",Up="rbxasset://textures/sky/sky512_up.tex"},
    ["Deep Space 1"] = {Bk="http://www.roblox.com/asset/?id=149397692",Dn="http://www.roblox.com/asset/?id=149397686",Ft="http://www.roblox.com/asset/?id=149397697",Lf="http://www.roblox.com/asset/?id=149397684",Rt="http://www.roblox.com/asset/?id=149397688",Up="http://www.roblox.com/asset/?id=149397702"},
    ["Pink Skies"] = {Bk="http://www.roblox.com/asset/?id=151165214",Dn="http://www.roblox.com/asset/?id=151165197",Ft="http://www.roblox.com/asset/?id=151165224",Lf="http://www.roblox.com/asset/?id=151165191",Rt="http://www.roblox.com/asset/?id=151165206",Up="http://www.roblox.com/asset/?id=151165227"},
    ["Purple Sunset"] = {Bk="rbxassetid://264908339",Dn="rbxassetid://264907909",Ft="rbxassetid://264909420",Lf="rbxassetid://264909758",Rt="rbxassetid://264908886",Up="rbxassetid://264907379"},
    ["Blossom Daylight"] = {Bk="http://www.roblox.com/asset/?id=271042516",Dn="http://www.roblox.com/asset/?id=271077243",Ft="http://www.roblox.com/asset/?id=271042556",Lf="http://www.roblox.com/asset/?id=271042310",Rt="http://www.roblox.com/asset/?id=271042467",Up="http://www.roblox.com/asset/?id=271077958"},
    ["Blue Nebula"] = {Bk="http://www.roblox.com/asset?id=135207744",Dn="http://www.roblox.com/asset?id=135207662",Ft="http://www.roblox.com/asset?id=135207770",Lf="http://www.roblox.com/asset?id=135207615",Rt="http://www.roblox.com/asset?id=135207695",Up="http://www.roblox.com/asset?id=135207794"},
    ["Blue Planet"] = {Bk="rbxassetid://218955819",Dn="rbxassetid://218953419",Ft="rbxassetid://218954524",Lf="rbxassetid://218958493",Rt="rbxassetid://218957134",Up="rbxassetid://218950090"},
    ["Deep Space 2"] = {Bk="http://www.roblox.com/asset/?id=159248188",Dn="http://www.roblox.com/asset/?id=159248183",Ft="http://www.roblox.com/asset/?id=159248187",Lf="http://www.roblox.com/asset/?id=159248173",Rt="http://www.roblox.com/asset/?id=159248192",Up="http://www.roblox.com/asset/?id=159248176"},
    ["Summer"] = {Bk="rbxassetid://16648590964",Dn="rbxassetid://16648617436",Ft="rbxassetid://16648595424",Lf="rbxassetid://16648566370",Rt="rbxassetid://16648577071",Up="rbxassetid://16648598180"},
    ["Galaxy"] = {Bk="rbxassetid://15983968922",Dn="rbxassetid://15983966825",Ft="rbxassetid://15983965025",Lf="rbxassetid://15983967420",Rt="rbxassetid://15983966246",Up="rbxassetid://15983964246"},
    ["Stylized"] = {Bk="rbxassetid://18351376859",Dn="rbxassetid://18351374919",Ft="rbxassetid://18351376800",Lf="rbxassetid://18351376469",Rt="rbxassetid://18351376457",Up="rbxassetid://18351377189"},
    ["Minecraft"] = {Bk="rbxassetid://8735166756",Dn="http://www.roblox.com/asset/?id=8735166707",Ft="http://www.roblox.com/asset/?id=8735231668",Lf="http://www.roblox.com/asset/?id=8735166755",Rt="http://www.roblox.com/asset/?id=8735166751",Up="http://www.roblox.com/asset/?id=8735166729"},
    ["Cloudy Rain"] = {Bk="http://www.roblox.com/asset/?id=4498828382",Dn="http://www.roblox.com/asset/?id=4498828812",Ft="http://www.roblox.com/asset/?id=4498829917",Lf="http://www.roblox.com/asset/?id=4498830911",Rt="http://www.roblox.com/asset/?id=4498830417",Up="http://www.roblox.com/asset/?id=4498831746"},
    ["Black Cloudy Rain"] = {Bk="http://www.roblox.com/asset/?id=149679669",Dn="http://www.roblox.com/asset/?id=149681979",Ft="http://www.roblox.com/asset/?id=149679690",Lf="http://www.roblox.com/asset/?id=149679709",Rt="http://www.roblox.com/asset/?id=149679722",Up="http://www.roblox.com/asset/?id=149680199"},
}

local skyNames = {}
for k in pairs(SkyboxAssets) do table.insert(skyNames, k) end
table.sort(skyNames)

local currentSkybox = "HD"
local skyboxEnabled = false
local skyObject = nil

local function ApplySkybox(name)
    if not skyObject then
        skyObject = Instance.new("Sky")
        skyObject.Parent = Lighting
    end
    local s = SkyboxAssets[name]
    if not s then
        skyObject:Destroy()
        skyObject = nil
        return
    end
    skyObject.SkyboxBk = s.Bk
    skyObject.SkyboxDn = s.Dn
    skyObject.SkyboxFt = s.Ft
    skyObject.SkyboxLf = s.Lf
    skyObject.SkyboxRt = s.Rt
    skyObject.SkyboxUp = s.Up
end

local function RestoreDefaultSky()
    if skyObject then
        skyObject:Destroy()
        skyObject = nil
    end
end

VisualsSkybox:AddDropdown("SkyboxSelector", {
    Name = "Skybox",
    Values = skyNames,
    Default = "HD",
    Callback = function(v)
        currentSkybox = v
        if skyboxEnabled then ApplySkybox(v) end
    end
})

VisualsSkybox:AddToggle("EnableSkybox", {
    Name = "Enable Custom Skybox",
    Default = false,
    Callback = function(v)
        skyboxEnabled = v
        if v then
            ApplySkybox(currentSkybox)
        else
            RestoreDefaultSky()
        end
        notify("nLhe", "Skybox: " .. (v and "ON" or "OFF"), 2)
    end
})

-- ==========================================
-- 7.5. TRAIL
-- ==========================================

local trailEnabled = false
local trailColor = Color3.fromRGB(0, 255, 255)
local trailRainbow = false
local trailLifetime = 0.5
local trailTransparency = 0
local trailParts = {}

local function removeTrail(c)
    if trailParts[c] then
        trailParts[c]:Destroy()
        trailParts[c] = nil
    end
    local t = c and c:FindFirstChild("HumanoidRootPart")
    if t then
        local a0 = t:FindFirstChild("TrailAttach0")
        local a1 = t:FindFirstChild("TrailAttach1")
        if a0 then a0:Destroy() end
        if a1 then a1:Destroy() end
    end
end

local function addTrail(c)
    local t = c and c:FindFirstChild("HumanoidRootPart")
    if not t then return end
    removeTrail(c)
    local a0 = Instance.new("Attachment")
    a0.Name = "TrailAttach0"
    a0.Position = Vector3.new(0, 2, 0)
    a0.Parent = t
    local a1 = Instance.new("Attachment")
    a1.Name = "TrailAttach1"
    a1.Position = Vector3.new(0, -2, 0)
    a1.Parent = t
    local tr = Instance.new("Trail")
    tr.Attachment0 = a0
    tr.Attachment1 = a1
    tr.Lifetime = trailLifetime
    tr.LightEmission = 0.2
    tr.Enabled = true
    tr.Transparency = NumberSequence.new({
        NumberSequenceKeypoint.new(0, trailTransparency),
        NumberSequenceKeypoint.new(1, 1)
    })
    tr.Color = ColorSequence.new(trailColor)
    tr.Parent = c
    trailParts[c] = tr
end

local function updateTrails()
    for c, tr in pairs(trailParts) do
        if tr and tr.Parent and c == plr.Character then
            tr.Lifetime = trailLifetime
            tr.Transparency = NumberSequence.new({
                NumberSequenceKeypoint.new(0, trailTransparency),
                NumberSequenceKeypoint.new(1, 1)
            })
            local col = trailRainbow and Color3.fromHSV((tick() % 5) / 5, 1, 1) or trailColor
            tr.Color = ColorSequence.new(col)
        end
    end
end

VisualsExtra:AddToggle("Trail", {
    Name = "Trail",
    Default = false,
    Callback = function(v)
        trailEnabled = v
        if v and plr.Character then
            addTrail(plr.Character)
        elseif plr.Character then
            removeTrail(plr.Character)
        end
        notify("nLhe", "Trail: " .. (v and "ON" or "OFF"), 2)
    end
})

VisualsExtra:AddColorpicker("TrailColor", {
    Name = "Trail Color",
    Default = Color3.fromRGB(0, 255, 255),
    Callback = function(v)
        trailColor = v
    end
})

VisualsExtra:AddToggle("TrailRainbow", {
    Name = "Trail Rainbow",
    Default = false,
    Callback = function(v)
        trailRainbow = v
    end
})

VisualsExtra:AddSlider("TrailLifetime", {
    Name = "Trail Lifetime",
    Min = 1,
    Max = 30,
    Default = 5,
    Callback = function(v)
        trailLifetime = v / 10
    end
})

VisualsExtra:AddSlider("TrailTransparency", {
    Name = "Trail Transparency",
    Min = 0,
    Max = 100,
    Default = 0,
    Callback = function(v)
        trailTransparency = v / 100
    end
})

plr.CharacterAdded:Connect(function(char)
    task.wait(1)
    if trailEnabled then
        addTrail(char)
    end
end)

RunService.Heartbeat:Connect(function()
    if trailEnabled then
        updateTrails()
    end
end)

-- ==========================================
-- 7.6. PCLD ESP [RR9]
-- ==========================================

do
    local pcldEnabled = false
    local pcldColor = Color3.fromRGB(255, 60, 60)
    local pcldRainbow = false
    local smoothPCLDs = {}
    local pcldPlayerCache = {}
    local smoothTime = 0.18
    local pcldCons = {}

    local function getPlayerFromPCLD(pcld)
        local closestPlayer
        local closestDist = 10
        for _, player in pairs(Players:GetPlayers()) do
            local char = player.Character
            local hrp = char and char:FindFirstChild("HumanoidRootPart")
            if hrp then
                local dist = (hrp.Position - pcld.Position).Magnitude
                if dist < closestDist then
                    closestDist = dist
                    closestPlayer = player
                end
            end
        end
        if closestPlayer then
            pcldPlayerCache[pcld] = { player = closestPlayer, time = tick() }
            return closestPlayer.DisplayName .. " (@ " .. closestPlayer.Name .. ")"
        end
        local cached = pcldPlayerCache[pcld]
        if cached and tick() - cached.time < 2 then
            local p = cached.player
            return p.DisplayName .. " (@ " .. p.Name .. ")"
        end
        return "Unknown"
    end

    local function createSmoothPCLD(original)
        if smoothPCLDs[original] then return end
        original.Transparency = 1

        local box = Instance.new("Part")
        box.Name = "PCLD_Box_RR9"
        box.Size = original.Size
        box.CFrame = original.CFrame
        box.Anchored = true
        box.CanCollide = false
        box.CanTouch = false
        box.CanQuery = false
        box.CastShadow = false
        box.Material = Enum.Material.Neon
        box.Color = pcldColor
        box.Transparency = 0.45
        box.Parent = Workspace

        local outline = Instance.new("SelectionBox")
        outline.Adornee = box
        outline.LineThickness = 0.02
        outline.Color3 = pcldColor
        outline.Transparency = 0.1
        outline.Parent = box

        local data = { box = box, outline = outline, original = original, tween = nil }
        smoothPCLDs[original] = data

        task.spawn(function()
            local lastPos = original.Position
            while box.Parent and original.Parent do
                local pos = original.Position
                local cf = original.CFrame
                if (pos - lastPos).Magnitude > 0.02 then
                    lastPos = pos
                    if data.tween then data.tween:Cancel() end
                    data.tween = TweenService:Create(box, TweenInfo.new(smoothTime, Enum.EasingStyle.Linear), { CFrame = cf })
                    data.tween:Play()
                end
                task.wait(0.03)
            end
        end)
    end

    local function removeSmoothPCLD(original)
        local d = smoothPCLDs[original]
        if not d then return end
        if d.tween then d.tween:Cancel() end
        if d.box then d.box:Destroy() end
        smoothPCLDs[original] = nil
        pcldPlayerCache[original] = nil
    end

    local function clearAllSmoothPCLDs()
        for _, d in pairs(smoothPCLDs) do
            if d.tween then d.tween:Cancel() end
            if d.box then d.box:Destroy() end
        end
        smoothPCLDs = {}
        pcldPlayerCache = {}
    end

    VisualsExtra:AddToggle("PCLDESP", {
        Name = "PCLD ESP [RR9]",
        Default = false,
        Callback = function(v)
            pcldEnabled = v
            if v then
                for _, obj in ipairs(Workspace:GetChildren()) do
                    if obj.Name == "PlayerCharacterLocationDetector" then
                        createSmoothPCLD(obj)
                    end
                end
                pcldCons.viewpcld = Workspace.ChildAdded:Connect(function(child)
                    if child.Name == "PlayerCharacterLocationDetector" then
                        task.wait(0.1)
                        createSmoothPCLD(child)
                    end
                end)
                pcldCons.pcldRemoved = Workspace.ChildRemoved:Connect(function(child)
                    if child.Name == "PlayerCharacterLocationDetector" then
                        removeSmoothPCLD(child)
                    end
                end)
            else
                if pcldCons.viewpcld then pcldCons.viewpcld:Disconnect() end
                if pcldCons.pcldRemoved then pcldCons.pcldRemoved:Disconnect() end
                clearAllSmoothPCLDs()
            end
            notify("nLhe", "PCLD ESP: " .. (v and "ON" or "OFF"), 2)
        end
    })

    VisualsExtra:AddColorpicker("PCLDColor", {
        Name = "PCLD Color",
        Default = Color3.fromRGB(255, 60, 60),
        Callback = function(v)
            pcldColor = v
            if not pcldRainbow then
                for _, d in pairs(smoothPCLDs) do
                    if d.box then d.box.Color = pcldColor end
                    if d.outline then d.outline.Color3 = pcldColor end
                end
            end
        end
    })

    VisualsExtra:AddToggle("RainbowPCLD", {
        Name = "Rainbow PCLD",
        Default = false,
        Callback = function(v)
            pcldRainbow = v
            if v then
                task.spawn(function()
                    while pcldRainbow do
                        local hue = tick() % 1
                        local color = Color3.fromHSV(hue, 1, 1)
                        for _, d in pairs(smoothPCLDs) do
                            if d.box then d.box.Color = color end
                            if d.outline then d.outline.Color3 = color end
                        end
                        task.wait(0.05)
                    end
                end)
            else
                for _, d in pairs(smoothPCLDs) do
                    if d.box then d.box.Color = pcldColor end
                    if d.outline then d.outline.Color3 = pcldColor end
                end
            end
        end
    })
end

-- ==========================================
-- 7.7. OCEAN
-- ==========================================

local OceanFolder = Workspace:FindFirstChild("Map") and Workspace.Map:FindFirstChild("AlwaysHereTweenedObjects") and Workspace.Map.AlwaysHereTweenedObjects:FindFirstChild("Ocean") and Workspace.Map.AlwaysHereTweenedObjects.Ocean:FindFirstChild("Object") and Workspace.Map.AlwaysHereTweenedObjects.Ocean.Object:FindFirstChild("ObjectModel")
local cachedOceanParts = nil

local function oceanParts()
    if cachedOceanParts then return cachedOceanParts end
    if not OceanFolder then return {} end
    local parts = {}
    for _, obj in ipairs(OceanFolder:GetDescendants()) do
        if obj:IsA("BasePart") then
            table.insert(parts, obj)
        end
    end
    cachedOceanParts = parts
    return parts
end

local function setOceanMaterial(materialName)
    local material = Enum.Material[materialName]
    if not material then return end
    for _, part in ipairs(oceanParts()) do
        part.Material = material
    end
end

local function setOceanColor(color)
    for _, part in ipairs(oceanParts()) do
        part.Color = color
    end
end

OceanGroup:AddDropdown("WaterMaterial", {
    Name = "Ocean Material",
    Values = {"Water", "Glass", "Neon", "SmoothPlastic", "Ice", "Sand", "Rock", "Basalt", "Slate", "Mud", "Cobblestone"},
    Default = "Water",
    Callback = function(v)
        setOceanMaterial(v)
    end
})

OceanGroup:AddToggle("EnableOceanColor", {
    Name = "Custom Ocean Color",
    Default = true,
    Callback = function(v)
        if not v then
            setOceanColor(Color3.fromRGB(0, 170, 255))
        end
    end
}):AddColorPicker("OceanColorPicker", {
    Default = Color3.fromRGB(0, 170, 255),
    Title = "Ocean Color",
    Callback = function(v)
        setOceanColor(v)
    end
})

OceanGroup:AddButton({
    Name = "Refresh Ocean Cache",
    Callback = function()
        cachedOceanParts = nil
        cachedOceanParts = oceanParts()
        setOceanMaterial(Options.WaterMaterial.Value or "Water")
        setOceanColor(Options.OceanColorPicker.Value or Color3.fromRGB(0, 170, 255))
        notify("nLhe", "Ocean cache refreshed!", 2)
    end
})

OceanGroup:AddToggle("RealisticWater", {
    Name = "Realistic Water",
    Default = false,
    Callback = function(v)
        if v and OceanFolder then
            local terrain = Workspace.Terrain
            for _, part in ipairs(OceanFolder:GetChildren()) do
                if part:IsA("Part") then
                    local size = part.Size
                    local cf = part.CFrame
                    local region = Region3.new(cf.Position - size/2, cf.Position + size/2):ExpandToGrid(4)
                    terrain:FillRegion(region, 4, Enum.Material.Water)
                    part:Destroy()
                end
            end
            notify("nLhe", "Realistic Water enabled!", 2)
        end
    end
})

-- ==========================================
-- 7.8. SCREEN EFFECTS
-- ==========================================

local screenEnabled = false
local screenIntensity = 0
local screenConnection = nil

VisualsEffects:AddToggle("ScreenStretch", {
    Name = "Screen Stretch Effect",
    Default = false,
    Callback = function(v)
        screenEnabled = v
        if v then
            if screenConnection then screenConnection:Disconnect() end
            screenConnection = RunService.RenderStepped:Connect(function()
                local cam = Workspace.CurrentCamera
                if cam then
                    cam.CFrame = cam.CFrame * CFrame.new(0,0,0,1,0,0,0,0.65 + screenIntensity,0,0,0,1)
                end
            end)
        else
            if screenConnection then
                screenConnection:Disconnect()
                screenConnection = nil
            end
        end
        notify("nLhe", "Screen Stretch: " .. (v and "ON" or "OFF"), 2)
    end
})

VisualsEffects:AddSlider("ScreenIntensity", {
    Name = "Screen Intensity",
    Min = 0,
    Max = 20,
    Default = 0,
    Callback = function(v)
        screenIntensity = v / 100
    end
})

-- ==========================================
-- ЧАСТЬ 8: TOYS (SPAWN + FLINGER + SPARKLERS)
-- ==========================================

print("🔄 Loading Toys (Part 1)...")

local plr = _G.nLhe.plr
local RS = _G.nLhe.RS
local RunService = _G.nLhe.RunService
local Workspace = _G.nLhe.Workspace
local Players = _G.nLhe.Players
local Debris = _G.nLhe.Debris

local SetNetworkOwner = RS:FindFirstChild("GrabEvents") and RS.GrabEvents:FindFirstChild("SetNetworkOwner")
local DestroyToy = RS:FindFirstChild("MenuToys") and RS.MenuToys:FindFirstChild("DestroyToy")
local SpawnToyRemote = RS:FindFirstChild("MenuToys") and RS.MenuToys:FindFirstChild("SpawnToyRemoteFunction")
local DestroyGrabLine = RS:FindFirstChild("GrabEvents") and RS.GrabEvents:FindFirstChild("DestroyGrabLine")
local CreateGrabLine = RS:FindFirstChild("GrabEvents") and RS.GrabEvents:FindFirstChild("CreateGrabLine")
local StickyEvent = RS:FindFirstChild("PlayerEvents") and RS.PlayerEvents:FindFirstChild("StickyPartEvent")

local ToysSpawnGroup = _G.nLhe.Tabs.Toys:AddLeftGroupbox("Spawn Toy", "house")
local ToysFlingGroup = _G.nLhe.Tabs.Toys:AddLeftGroupbox("Object Flinger", "box")
local ToysSparklerGroup = _G.nLhe.Tabs.Toys:AddLeftGroupbox("Sparkler Auras", "flame")

local bool = _G.nLhe.bool
local int = _G.nLhe.int
local cons = _G.nLhe.cons
local etc = _G.nLhe.etc

local function discCon(key) _G.nLhe.discCon(key) end
local function notify(t, c, d) _G.nLhe.notify(t, c, d) end
local function sno(part) _G.nLhe.sno(part) end
local function GetMagnitude(a, b) return _G.nLhe.GetMagnitude(a, b) end

-- ==========================================
-- 8.1. СПАВН ИГРУШЕК
-- ==========================================

local ToyFriendlyNames = {
    PalletLightBrown = 'Pallet',
    BallSnowball = 'Snowball',
    BombMissile = 'Missile',
    NinjaShuriken = 'Shuriken',
    NinjaKunai = 'Kunai',
    ToolPencil = 'Pencil',
    ToolPickaxe = 'Pickaxe',
    ToolCleaver = 'Cleaver',
    FoodHamburger = 'Burger',
    FoodCoconut = 'Coconut',
    FoodBanana = 'Banana',
    FoodPizzaCheese = 'Pizza',
    FoodHotdog = 'Hotdog',
    FoodDonut = 'Donut',
    FoodCakePink = 'Cake',
    FoodFrenchFries = 'Fries',
    FoodMeatStick = 'Meat Stick',
    PoopPile = 'Poop',
    PoopPileSparkle = 'Sparkle Poop',
    CupMugWhite = 'White Mug',
    CupMugBrown = 'Brown Mug',
    InstrumentGuitarBanjo = 'Banjo',
    InstrumentGuitarViolin = 'Violin',
    InstrumentGuitarUkulele = 'Ukulele',
    InstrumentWoodwindOcarina = 'Ocarina',
    InstrumentDrumBongos = 'Bongos',
    InstrumentVoiceMicrophone = 'Mic',
    TractorGreen = 'Tractor (Green)',
    TractorOrange = 'Tractor (Orange)',
    TractorRed = 'Tractor (Red)',
    CreatureBlobman = 'Blobman',
    YouDecoy = 'Decoy',
    YouLittle = 'Mini Me',
    DiceBig = 'Big Dice',
    DiceSmall = 'Small Dice',
    FireworkSparkler = 'Sparkler',
    FireworkMissile = 'Firework Missile',
    BombBalloon = 'Balloon Bomb',
    BombDarkMatter = 'Dark Matter Bomb',
    PresentBig = 'Big Present',
    PresentSmall = 'Small Present',
    SpookyCandle1 = 'Candle (x1)',
    SpookyCandle3 = 'Candle (x3)',
    SpookyCandle5 = 'Candle (x5)',
    JapaneseLantern = 'Japanese Lantern',
    SprayCanWD = 'Spray Can',
}

local ToyDropdownValues = {}
local DisplayToInternal = {}

for internal, display in pairs(ToyFriendlyNames) do
    table.insert(ToyDropdownValues, display)
    DisplayToInternal[display] = internal
end
table.sort(ToyDropdownValues)

local SelectedToy = 'PalletLightBrown'

ToysSpawnGroup:AddToggle("SpawnToyToggle", {
    Name = "Spawn Toy",
    Default = false,
    Callback = function(v)
        bool.SpawnToyToggle = v
        if v and SpawnToyRemote then
            local char = plr.Character
            local root = char and char:FindFirstChild("HumanoidRootPart")
            if root then
                pcall(function()
                    SpawnToyRemote:InvokeServer(SelectedToy, root.CFrame * CFrame.new(0, 5, 10), Vector3.zero)
                    notify("nLhe", "Toy spawned: " .. SelectedToy, 2)
                end)
            end
        end
    end
})

ToysSpawnGroup:AddDropdown("SpawnToyDropdown", {
    Name = "Selected Toy",
    Values = ToyDropdownValues,
    Default = "Pallet",
    Callback = function(v)
        SelectedToy = DisplayToInternal[v] or 'PalletLightBrown'
    end
})

local spawnKeybind = ToysSpawnGroup:AddKeyPicker("SpawnToyKeybind", {
    Default = "Tab",
    Text = "Spawn Keybind",
    Mode = "Toggle",
    Callback = function()
        if bool.SpawnToyToggle and SpawnToyRemote then
            local char = plr.Character
            local root = char and char:FindFirstChild("HumanoidRootPart")
            if root then
                pcall(function()
                    SpawnToyRemote:InvokeServer(SelectedToy, root.CFrame * CFrame.new(0, 5, 10), Vector3.zero)
                    notify("nLhe", "Toy spawned via keybind: " .. SelectedToy, 2)
                end)
            end
        end
    end
})

-- ==========================================
-- 8.2. OBJECT FLINGER (LOOP FLING TARGET)
-- ==========================================

do
    local flingEnabled = false
    local flingProcessing = false
    local flingConn = nil
    local currentDecoy = nil
    local currentTarget = nil
    local targetIndex = 1
    local flungMap = {}
    local ownershipMonitors = {}
    local velocityHistory = {}
    local FLING_FORCE = 500
    local selectedFlingToy = 'DiceBig'
    local flingTargets = {}

    local toyMap = {
        YouLittle = 'Head',
        YouDecoy = 'Head',
        DiceSmall = 'SoundPart',
        DiceBig = 'SoundPart',
    }

    local folder = Workspace:FindFirstChild(plr.Name .. 'SpawnedInToys') or Workspace:WaitForChild(plr.Name .. 'SpawnedInToys')
    local root = plr.Character and plr.Character:FindFirstChild('HumanoidRootPart')

    plr.CharacterAdded:Connect(function(newChar)
        root = newChar:FindFirstChild('HumanoidRootPart')
    end)

    local function getFlingTargets()
        local targetsList = {}
        for _, p in pairs(Players:GetPlayers()) do
            if p ~= plr and p:GetAttribute('IsFlingAdded') and p.Character and p.Character:FindFirstChild('HumanoidRootPart') then
                table.insert(targetsList, p)
            end
        end
        return targetsList
    end

    local function isFlung(p)
        local h = p.Character and p.Character:FindFirstChild('HumanoidRootPart')
        if not h then return true end
        local posY = h.Position.Y
        local v = h.Velocity
        local horizontalMag = Vector3.new(v.X, 0, v.Z).Magnitude

        if not velocityHistory[p] then velocityHistory[p] = {} end
        local hist = velocityHistory[p]
        table.insert(hist, {tick(), v, posY})
        if #hist > 15 then table.remove(hist, 1) end

        local badFrames = 0
        for _, data in ipairs(hist) do
            local vel = data[2]
            local y = data[3]
            if y > 3000 or y < -150 then
                badFrames = badFrames + 1
            elseif math.abs(vel.Y) > 220 or Vector3.new(vel.X, 0, vel.Z).Magnitude > 300 then
                badFrames = badFrames + 1
            end
        end
        return badFrames / #hist >= 0.4
    end

    local function isGrounded(p)
        local h = p.Character and p.Character:FindFirstChild('HumanoidRootPart')
        return h and h.Position.Y < 100 and math.abs(h.Velocity.Y) < 10
    end

    local function pickNextTarget(targets)
        local c = #targets
        if c == 0 then return nil end
        for i = 1, c do
            targetIndex = ((targetIndex + i - 1) % c) + 1
            local t = targets[targetIndex]
            if not flungMap[t] or isGrounded(t) then
                return t
            end
        end
        return nil
    end

    local function monitorFlingOwnership(toy, toyPart)
        if ownershipMonitors[toy] then
            ownershipMonitors[toy]:Disconnect()
            ownershipMonitors[toy] = nil
        end
        ownershipMonitors[toy] = RunService.Heartbeat:Connect(function()
            if not toy or not toy.Parent then
                if ownershipMonitors[toy] then
                    ownershipMonitors[toy]:Disconnect()
                    ownershipMonitors[toy] = nil
                end
                return
            end
            local tag = toyPart:FindFirstChild('PartOwner')
            if tag and tag:IsA('StringValue') and tag.Value ~= plr.Name and tag.Value ~= '' then
                if DestroyToy then DestroyToy:FireServer(toy) end
                if toy == currentDecoy then currentDecoy = nil end
                if ownershipMonitors[toy] then
                    ownershipMonitors[toy]:Disconnect()
                    ownershipMonitors[toy] = nil
                end
            end
        end)
    end

    local function spawnFlingDecoy()
        if currentDecoy and currentDecoy.Parent then return end
        local toy = selectedFlingToy or 'YouDecoy'
        if SpawnToyRemote and root then
            SpawnToyRemote:InvokeServer(toy, root.CFrame * CFrame.new(5, 0, 5), Vector3.new(0, 33, 0))
        end
    end

    local function handleFlingDecoy(d)
        if currentDecoy and currentDecoy.Parent then return end
        local partName = toyMap[d.Name]
        if not partName then return end
        local toyPart = d:FindFirstChild(partName)
        if not toyPart then return end
        local pivotCF = d:GetPivot()
        if SetNetworkOwner then SetNetworkOwner:FireServer(toyPart, pivotCF) end
        task.wait(0.09)

        local startTime = tick()
        local success = false
        local connection
        connection = RunService.Heartbeat:Connect(function()
            local tag = toyPart:FindFirstChild('PartOwner')
            if tag and tag:IsA('StringValue') and tag.Value == plr.Name then
                success = true
                connection:Disconnect()
                if not d:GetAttribute('OwnedByFling') then
                    d:SetAttribute('OwnedByFling', true)
                    currentDecoy = d
                    monitorFlingOwnership(d, toyPart)
                    if flingEnabled then
                        setupFling(d)
                    end
                end
            end
            if tick() - startTime >= 3 and not success then
                if DestroyToy then DestroyToy:FireServer(d) end
                connection:Disconnect()
            end
        end)
    end

    if folder then
        folder.ChildAdded:Connect(function(c)
            if toyMap[c.Name] then
                handleFlingDecoy(c)
            end
        end)

        folder.ChildRemoved:Connect(function(c)
            if c == currentDecoy then currentDecoy = nil end
            if ownershipMonitors[c] then
                ownershipMonitors[c]:Disconnect()
                ownershipMonitors[c] = nil
            end
        end)
    end

    RunService.Heartbeat:Connect(function()
        if not currentDecoy or not currentDecoy.Parent then
            if folder then
                for _, t in ipairs(folder:GetChildren()) do
                    if toyMap[t.Name] and t:GetAttribute('OwnedByFling') then
                        currentDecoy = t
                        local toyPart = t:FindFirstChild(toyMap[t.Name])
                        if toyPart and not ownershipMonitors[t] then
                            monitorFlingOwnership(t, toyPart)
                        end
                        return
                    end
                end
            end
            if flingEnabled then
                spawnFlingDecoy()
            end
        end
    end)

    local function setupFling(d)
        local hrp = d:FindFirstChild('HumanoidRootPart') or d.PrimaryPart or d:FindFirstChild(toyMap[d.Name])
        if not hrp then return end
        d.PrimaryPart = hrp
        hrp.CanCollide = false

        local bt = Instance.new('BodyThrust')
        bt.Force = Vector3.zero
        bt.Parent = hrp

        local bav = Instance.new('BodyAngularVelocity')
        bav.MaxTorque = Vector3.new(math.huge, math.huge, math.huge)
        bav.AngularVelocity = Vector3.new(-1e6, -1e6, -1e6)
        bav.Parent = hrp

        local params = RaycastParams.new()
        params.FilterType = Enum.RaycastFilterType.Blacklist
        params.FilterDescendantsInstances = {plr.Character, d}
        params.IgnoreWater = true

        flingConn = RunService.Heartbeat:Connect(function()
            if not d or not d.Parent or not flingEnabled then
                if flingConn then flingConn:Disconnect() end
                if bt.Parent then bt:Destroy() end
                if bav.Parent then bav:Destroy() end
                return
            end

            Workspace.FallenPartsDestroyHeight = 0/0

            local tList = getFlingTargets()
            for p in pairs(flungMap) do
                if not table.find(tList, p) or not p.Character or isGrounded(p) then
                    flungMap[p] = nil
                end
            end

            if currentTarget and (not currentTarget.Character or isFlung(currentTarget)) then
                flungMap[currentTarget] = true
                currentTarget = nil
            end
            if not currentTarget then
                currentTarget = pickNextTarget(tList)
            end

            local destCF
            if currentTarget and currentTarget.Character then
                local tHRP = currentTarget.Character:FindFirstChild('HumanoidRootPart')
                if tHRP then
                    local vel = tHRP.Velocity
                    local speed = vel.Magnitude
                    local time = math.clamp(speed / 40, 0.25, 0.6)
                    local predicted = tHRP.Position + vel * time + Vector3.new(0, 2, 0)
                    local dir = (predicted - hrp.Position).Unit
                    local dist = (predicted - hrp.Position).Magnitude
                    local result = Workspace:Raycast(hrp.Position, dir * dist, params)
                    if result and result.Instance and result.Instance:IsDescendantOf(currentTarget.Character) then
                        destCF = CFrame.new(result.Position)
                    else
                        destCF = CFrame.new(predicted)
                    end
                end
            end
            if not destCF then
                destCF = CFrame.new(0, 5000, 0)
            end

            for _, p in ipairs(d:GetDescendants()) do
                if p:IsA('BasePart') then
                    p.CFrame = destCF
                end
            end

            if bt.Parent then
                bt.Force = (destCF.Position - hrp.Position).Unit * FLING_FORCE
            end
        end)
    end

    local function processFling()
        if flingProcessing then return end
        flingProcessing = true
        if not currentDecoy or not currentDecoy.Parent or not currentDecoy:GetAttribute('OwnedByFling') then
            if flingEnabled then spawnFlingDecoy() end
        else
            setupFling(currentDecoy)
        end
        flingProcessing = false
    end

    -- UI для Flinger
    ToysFlingGroup:AddLabel("Select players to fling")

    local flingPlayerList = {}
    for _, p in pairs(Players:GetPlayers()) do
        if p ~= plr then
            table.insert(flingPlayerList, p.Name)
        end
    end

    ToysFlingGroup:AddDropdown("FlingTargetPlayers", {
        Name = "Select Players",
        Values = flingPlayerList,
        Default = flingPlayerList[1] or '',
        Multi = true,
        Callback = function(selected)
            flingTargets = {}
            for name, enabled in pairs(selected) do
                if enabled then
                    table.insert(flingTargets, name)
                end
            end
            for _, player in pairs(Players:GetPlayers()) do
                if player ~= plr then
                    local isSelected = false
                    for _, name in ipairs(flingTargets) do
                        if player.Name == name then
                            isSelected = true
                            break
                        end
                    end
                    player:SetAttribute('IsFlingAdded', isSelected)
                end
            end
        end
    })

    ToysFlingGroup:AddToggle("LoopFlingToggle", {
        Name = "Loop Fling Target",
        Default = false,
        Callback = function(v)
            flingEnabled = v
            if v then
                processFling()
            else
                flingProcessing = false
                if flingConn then
                    flingConn:Disconnect()
                    flingConn = nil
                end
                for toy, mon in pairs(ownershipMonitors) do
                    mon:Disconnect()
                end
                ownershipMonitors = {}
                if currentDecoy and currentDecoy.Parent then
                    if DestroyToy then DestroyToy:FireServer(currentDecoy) end
                end
                currentDecoy = nil
                currentTarget = nil
                flungMap = {}
                velocityHistory = {}
            end
            notify("nLhe", "Loop Fling: " .. (v and "ON" or "OFF"), 2)
        end
    })

    ToysFlingGroup:AddDropdown("FlingToyDropdown", {
        Name = "Fling Toy",
        Values = {"YouLittle", "YouDecoy", "DiceSmall", "DiceBig"},
        Default = "DiceBig",
        Callback = function(v)
            selectedFlingToy = v
        end
    })
end

-- ==========================================
-- 8.3. SPARKLER AURAS (50 ФОРМ)
-- ==========================================

do
    local activeSparklers = {}
    local sparklerConfig = {
        Height = 5,
        Speed = 2,
        Radius = 15,
        CurrentShape = 'Planet',
    }

    local shapeOptions = {
        'Planet', 'Sphere', 'Cylinder', 'Double Ring', 'Star', 'Infinity', 'Heart',
        'DNA Helix', 'Triple Helix', 'Tornado', 'Galaxy Spiral', 'Fibonacci Spiral',
        'Spring Coil', 'Vortex Funnel', 'Box', 'Rounded Cube', 'Torus', 'Torus Knot',
        'Möbius Strip', 'Saturn', 'Ice Cube', 'Black Hole', 'Hyper Sphere', 'Orbital Rings',
        'Lightning Tornado', 'Plasma Cage', 'Wormhole', 'Quantum Lattice', 'Neutron Burst',
        'Arc Discharge', 'Event Horizon', 'Butterfly', 'Rose Petal', 'Snowflake',
        'Crystal Bloom', 'Vine Wrap', 'Flower Bloom', 'Jellyfish', 'Coral Reef',
        'Volcano Burst', 'Cosmic Explosion', 'Supernova', 'Firework Pop', 'Shockwave',
        'Lissajous', 'Hypotrochoid', 'Epitrochoid', 'Trefoil', 'Klein Bottle Slice',
        'Harmonograph'
    }

    local TAU = math.pi * 2

    local function baseAngle(i, n, t, speed)
        return (i / n) * TAU + t * speed
    end

    -- ==========================================
    -- 50 ФОРМ (РАЗБИТЫ НА ГРУППЫ ДЛЯ ОБХОДА ЛИМИТА)
    -- ==========================================

    -- ГРУППА 1: Базовые формы
    local function ShapePlanet(i, n, t, r, h, sp)
        local spin = t * sp
        local phi = math.acos(1 - 2 * (i / n))
        local theta = i * math.pi * (3 - math.sqrt(5)) + spin
        return Vector3.new(
            math.cos(theta) * math.sin(phi) * r,
            math.cos(phi) * r + h,
            math.sin(theta) * math.sin(phi) * r
        )
    end

    local function ShapeSphere(i, n, t, r, h, sp)
        local phi = math.acos(1 - 2 * (i / n))
        local theta = i * math.pi * (3 - math.sqrt(5)) + t * sp * 2
        return Vector3.new(
            math.cos(theta) * math.sin(phi) * r,
            math.cos(phi) * r + h,
            math.sin(theta) * math.sin(phi) * r
        )
    end

    local function ShapeCylinder(i, n, t, r, h, sp)
        local a = baseAngle(i, n, t, sp)
        local y = (i / n) * r * 1.5 - r * 0.75
        return Vector3.new(math.cos(a) * r, h + y, math.sin(a) * r)
    end

    local function ShapeDoubleRing(i, n, t, r, h, sp)
        local a = (i / (n / 2)) * TAU + t * sp
        if i % 2 == 0 then
            return Vector3.new(math.cos(a) * r, h, math.sin(a) * r)
        else
            return Vector3.new(0, h + math.cos(a) * r, math.sin(a) * r)
        end
    end

    local function ShapeStar(i, n, t, r, h, sp)
        local a = baseAngle(i, n, t, sp)
        local rr = (i % 2 == 0) and r or r * 0.38
        return Vector3.new(
            math.cos(a) * rr,
            h + math.sin(t * sp * 1.5 + i * 0.3) * 1.5,
            math.sin(a) * rr
        )
    end

    local function ShapeInfinity(i, n, t, r, h, sp)
        local a = baseAngle(i, n, t, sp)
        local d = 1 + math.sin(a) ^ 2
        return Vector3.new(
            (r * math.cos(a)) / d,
            h + math.sin(t * sp + i * 0.2) * 1.2,
            (r * math.sin(a) * math.cos(a)) / d
        )
    end

    local function ShapeHeart(i, n, t, r, h, sp)
        local a = baseAngle(i, n, t, sp)
        local pulse = 1 + 0.12 * math.sin(t * sp * 2)
        local scale = (r / 15) * pulse
        local x = 16 * math.sin(a) ^ 3
        local z = -(13 * math.cos(a) - 5 * math.cos(2 * a) - 2 * math.cos(3 * a) - math.cos(4 * a))
        return Vector3.new(x * scale, h + math.sin(t * sp * 2) * 0.5, z * scale)
    end

    -- ГРУППА 2: Спирали и вихри
    local function ShapeDNAHelix(i, n, t, r, h, sp)
        local y = (i / n) * r * 2 - r
        local a = baseAngle(i, n, t, sp) + y * 0.5
        local side = (i % 2 == 0) and 1 or -1
        return Vector3.new(math.cos(a) * r * side, h + y, math.sin(a) * r * side)
    end

    local function ShapeTripleHelix(i, n, t, r, h, sp)
        local y = (i / n) * r * 2 - r
        local a = baseAngle(i, n, t, sp) + y * 0.5
        local phase = (i % 3) * (TAU / 3)
        return Vector3.new(math.cos(a + phase) * r, h + y, math.sin(a + phase) * r)
    end

    local function ShapeTornado(i, n, t, r, h, sp)
        local y = (i / n) * r * 2 - r
        local rr = ((y + r) / (r * 2)) * r + 2
        local a = baseAngle(i, n, t, sp) + y * 0.5
        return Vector3.new(math.cos(a) * rr, h + y, math.sin(a) * rr)
    end

    local function ShapeGalaxySpiral(i, n, t, r, h, sp)
        local frac = i / n
        local a = frac * 12 + t * sp
        return Vector3.new(
            math.cos(a) * r * (frac ^ 1.5),
            h + math.sin(t * sp * 2 + frac * 10),
            math.sin(a) * r * (frac ^ 1.5)
        )
    end

    local function ShapeFibonacciSpiral(i, n, t, r, h, sp)
        local frac = i / n
        local angle = frac * TAU * 6.18 + t * sp
        local dist = frac * r
        local wave = math.sin(t * sp + frac * TAU) * 2
        return Vector3.new(math.cos(angle) * dist, h + wave, math.sin(angle) * dist)
    end

    local function ShapeSpringCoil(i, n, t, r, h, sp)
        local frac = i / n
        local a = frac * TAU * 5 + t * sp
        local y = frac * r * 2 - r
        return Vector3.new(math.cos(a) * r * 0.5, h + y, math.sin(a) * r * 0.5)
    end

    local function ShapeVortexFunnel(i, n, t, r, h, sp)
        local frac = i / n
        local a = frac * TAU * 4 + t * sp
        local rr = frac * r
        local y = (1 - frac) * r * 1.5
        return Vector3.new(math.cos(a) * rr, h + y, math.sin(a) * rr)
    end

    -- ГРУППА 3: Геометрические
    local function ShapeBox(i, n, t, r, h, sp)
        local face = i % 6
        local a = baseAngle(i, n, t, sp)
        local s = r
        local edges = {
            Vector3.new(s, math.sin(a) * s, math.cos(a) * s),
            Vector3.new(-s, math.sin(a) * s, math.cos(a) * s),
            Vector3.new(math.sin(a) * s, s, math.cos(a) * s),
            Vector3.new(math.sin(a) * s, -s, math.cos(a) * s),
            Vector3.new(math.sin(a) * s, math.cos(a) * s, s),
            Vector3.new(math.sin(a) * s, math.cos(a) * s, -s),
        }
        local v = edges[face + 1]
        return Vector3.new(v.X, v.Y + h + math.sin(t * sp + i) * 0.3, v.Z)
    end

    local function ShapeRoundedCube(i, n, t, r, h, sp)
        local a = baseAngle(i, n, t, sp)
        local x = (math.cos(a) * r) ^ 0.85 * (math.cos(a) * r >= 0 and 1 or -1)
        local y = (math.sin(a * 1.3) * r * 0.6) ^ 0.85 * (math.sin(a * 1.3) * r * 0.6 >= 0 and 1 or -1)
        local z = (math.cos(a * 0.7) * r) ^ 0.85 * (math.cos(a * 0.7) * r >= 0 and 1 or -1)
        return Vector3.new(x, y + h, z)
    end

    local function ShapeTorus(i, n, t, r, h, sp)
        local a = baseAngle(i, n, t, sp)
        local b = baseAngle(i, n, t * 3, sp)
        local R = r
        local rt = r * 0.35
        return Vector3.new(
            (R + rt * math.cos(b)) * math.cos(a),
            rt * math.sin(b) + h,
            (R + rt * math.cos(b)) * math.sin(a)
        )
    end

    local function ShapeTorusKnot(i, n, t, r, h, sp)
        local p, q = 2, 3
        local a = baseAngle(i, n, t, sp)
        local phi = a * q
        local R = r * (1 + 0.35 * math.cos(p * a))
        return Vector3.new(R * math.cos(phi), r * 0.35 * math.sin(p * a) + h, R * math.sin(phi))
    end

    local function ShapeMobiusStrip(i, n, t, r, h, sp)
        local frac = i / n
        local u = frac * TAU + t * sp
        local v = (i % 2 == 0) and 0.5 or -0.5
        local w = r * 0.35
        return Vector3.new(
            (r + w * v * math.cos(u / 2)) * math.cos(u),
            w * v * math.sin(u / 2) + h,
            (r + w * v * math.cos(u / 2)) * math.sin(u)
        )
    end

    -- ГРУППА 4: Планетарные и космические
    local function ShapeSaturn(i, n, t, r, h, sp)
        local spin = t * sp
        if i <= n * 0.6 then
            local phi = math.acos(1 - 2 * (i / (n * 0.6)))
            local theta = i * math.pi * (3 - math.sqrt(5)) + spin
            local pr = r * 0.45
            return Vector3.new(
                math.cos(theta) * math.sin(phi) * pr,
                math.cos(phi) * pr + h,
                math.sin(theta) * math.sin(phi) * pr
            )
        else
            local idx = i - n * 0.6
            local c = n - n * 0.6
            local a = (idx / c) * TAU + spin
            local rr = r * 1.2
            return Vector3.new(
                math.cos(a) * rr,
                math.sin(a) * rr * math.sin(math.rad(25)) + h,
                math.sin(a) * rr * math.cos(math.rad(25))
            )
        end
    end

    local function ShapeIceCube(i, n, t, r, h, sp)
        local face = i % 6
        local frac = (i % math.max(math.floor(n / 6), 1)) / math.max(math.floor(n / 6), 1)
        local a = frac * TAU
        local s = r * 0.8
        local crack = math.sin(t * sp * 2 + i * 0.5) * 0.4
        local pts = {
            Vector3.new(s + crack, math.cos(a) * s, math.sin(a) * s),
            Vector3.new(-s - crack, math.cos(a) * s, math.sin(a) * s),
            Vector3.new(math.cos(a) * s, s + crack, math.sin(a) * s),
            Vector3.new(math.cos(a) * s, -s - crack, math.sin(a) * s),
            Vector3.new(math.cos(a) * s, math.sin(a) * s, s + crack),
            Vector3.new(math.cos(a) * s, math.sin(a) * s, -s - crack),
        }
        local v = pts[face + 1]
        return Vector3.new(v.X, v.Y + h, v.Z)
    end

    local function ShapeBlackHole(i, n, t, r, h, sp)
        local frac = i / n
        local a = frac * TAU * 3 + t * sp
        local dist = r * (1 - frac * 0.7)
        local suck = math.sin(t * sp * 2) * 0.5
        return Vector3.new(math.cos(a) * dist, h + suck * frac * 3, math.sin(a) * dist)
    end

    local function ShapeHyperSphere(i, n, t, r, h, sp)
        local phi = math.acos(1 - 2 * (i / n))
        local theta = i * math.pi * (3 - math.sqrt(5)) + t * sp
        local pulse = r + math.sin(t * sp + i * 0.3) * r * 0.25
        return Vector3.new(
            math.cos(theta) * math.sin(phi) * pulse,
            math.cos(phi) * pulse + h,
            math.sin(theta) * math.sin(phi) * pulse
        )
    end

    -- ГРУППА 5: Орбитальные и визуальные эффекты
    local function ShapeOrbitalRings(i, n, t, r, h, sp)
        local ring = i % 3
        local a = baseAngle(i, n, t, sp)
        local tilts = {math.rad(0), math.rad(60), math.rad(-60)}
        local tilt = tilts[ring + 1]
        return Vector3.new(math.cos(a) * r, math.sin(a) * r * math.sin(tilt) + h, math.sin(a) * r * math.cos(tilt))
    end

    local function ShapeLightningTornado(i, n, t, r, h, sp)
        local y = (i / n) * r * 2 - r
        local rr = ((y + r) / (r * 2)) * r + 2
        local bolt = math.sin(i * 7.3 + t * sp * 5) * 3
        local a = baseAngle(i, n, t, sp) + y * 0.5
        return Vector3.new(math.cos(a) * rr + bolt, h + y, math.sin(a) * rr + bolt)
    end

    local function ShapePlasmaCage(i, n, t, r, h, sp)
        local phi = math.acos(1 - 2 * (i / n))
        local theta = i * math.pi * (3 - math.sqrt(5))
        local arc = math.sin(t * sp * 2 + phi * 6) * r * 0.2
        local rr = r + arc
        return Vector3.new(
            math.cos(theta) * math.sin(phi) * rr,
            math.cos(phi) * rr + h,
            math.sin(theta) * math.sin(phi) * rr
        )
    end

    local function ShapeWormhole(i, n, t, r, h, sp)
        local frac = i / n
        local a = frac * TAU + t * sp
        local y = (frac - 0.5) * r * 3
        local neck = r * (1 - math.exp(-((y / (r * 0.8)) ^ 2))) + 0.5
        return Vector3.new(math.cos(a) * neck, h + y, math.sin(a) * neck)
    end

    local function ShapeQuantumLattice(i, n, t, r, h, sp)
        local grid = math.ceil(n ^ (1/3))
        local gx = i % grid
        local gy = math.floor(i / grid) % grid
        local gz = math.floor(i / (grid * grid)) % grid
        local scale = r * 2 / grid
        local jitter = math.sin(t * sp + i * 1.7) * 0.3
        return Vector3.new(
            (gx - grid/2) * scale + jitter,
            (gy - grid/2) * scale + h,
            (gz - grid/2) * scale + jitter
        )
    end

    -- ГРУППА 6: Взрывные и динамические
    local function ShapeNeutronBurst(i, n, t, r, h, sp)
        local phi = math.acos(1 - 2 * (i / n))
        local theta = i * math.pi * (3 - math.sqrt(5))
        local burst = r * math.abs(math.sin(t * sp + i * 0.4))
        return Vector3.new(
            math.cos(theta) * math.sin(phi) * burst,
            math.cos(phi) * burst + h,
            math.sin(theta) * math.sin(phi) * burst
        )
    end

    local function ShapeArcDischarge(i, n, t, r, h, sp)
        local frac = i / n
        local a = frac * TAU
        local arc = math.sin(frac * math.pi) * r
        local zap = math.sin(t * sp * 8 + i * 2.1) * r * 0.15
        return Vector3.new(math.cos(a) * r + zap, h + arc + zap, math.sin(a) * r + zap)
    end

    local function ShapeEventHorizon(i, n, t, r, h, sp)
        local frac = i / n
        local a = frac * TAU * 5 + t * sp
        local dist = r * (0.2 + 0.8 * math.abs(math.sin(frac * math.pi)))
        local warp = math.sin(t * sp * 3 + frac * TAU) * r * 0.1
        return Vector3.new(math.cos(a) * dist, h + warp, math.sin(a) * dist)
    end

    local function ShapeButterfly(i, n, t, r, h, sp)
        local a = baseAngle(i, n, t, sp * 0.5)
        local ex = math.exp(math.cos(a)) - 2 * math.cos(4 * a) - math.sin(a / 12) ^ 5
        local rr = ex * r * 0.4
        return Vector3.new(
            math.cos(a) * rr,
            h + math.sin(t * sp + i * 0.1) * 1.5,
            math.sin(a) * rr
        )
    end

    local function ShapeRosePetal(i, n, t, r, h, sp)
        local k = 5
        local a = baseAngle(i, n, t, sp * 0.3)
        local rr = r * math.cos(k * a)
        return Vector3.new(
            math.cos(a) * rr,
            h + math.sin(t * sp + i * 0.2) * 2,
            math.sin(a) * rr
        )
    end

    -- ГРУППА 7: Природные и органические
    local function ShapeSnowflake(i, n, t, r, h, sp)
        local arm = i % 6
        local frac = (i % math.max(math.floor(n / 6), 1)) / math.max(math.floor(n / 6), 1)
        local baseA = arm * (TAU / 6) + t * sp * 0.2
        local dist = frac * r
        local branch = math.sin(frac * math.pi * 4) * r * 0.2
        return Vector3.new(
            math.cos(baseA) * dist + math.cos(baseA + math.pi/2) * branch,
            h + math.cos(t * sp) * 0.5,
            math.sin(baseA) * dist + math.sin(baseA + math.pi/2) * branch
        )
    end

    local function ShapeCrystalBloom(i, n, t, r, h, sp)
        local petals = 8
        local arm = i % petals
        local frac = (i % math.max(math.floor(n / petals), 1)) / math.max(math.floor(n / petals), 1)
        local baseA = arm * (TAU / petals) + t * sp * 0.3
        local dist = frac * r
        local lift = math.sin(frac * math.pi) * r * 0.5
        return Vector3.new(math.cos(baseA) * dist, h + lift, math.sin(baseA) * dist)
    end

    local function ShapeVineWrap(i, n, t, r, h, sp)
        local frac = i / n
        local turns = 4
        local a = frac * TAU * turns + t * sp
        local y = frac * r * 2 - r
        local bulge = 1 + 0.3 * math.sin(frac * TAU * turns * 2)
        local rr = r * 0.5 * bulge
        return Vector3.new(math.cos(a) * rr, h + y, math.sin(a) * rr)
    end

    local function ShapeFlowerBloom(i, n, t, r, h, sp)
        local petals = 6
        local a = baseAngle(i, n, t, sp * 0.4)
        local rr = r * math.abs(math.cos(petals * a * 0.5))
        local bloom = 1 + 0.2 * math.sin(t * sp * 2)
        return Vector3.new(
            math.cos(a) * rr * bloom,
            h + math.sin(t * sp + a) * 1.5,
            math.sin(a) * rr * bloom
        )
    end

    local function ShapeJellyfish(i, n, t, r, h, sp)
        local bell = math.floor(n * 0.4)
        if i <= bell then
            local phi = (i / bell) * math.pi * 0.5
            local theta = baseAngle(i, bell, t, sp)
            local pulse = r * (1 + 0.2 * math.sin(t * sp * 3))
            return Vector3.new(
                math.cos(theta) * math.sin(phi) * pulse,
                math.cos(phi) * pulse * 0.5 + h,
                math.sin(theta) * math.sin(phi) * pulse
            )
        else
            local idx = i - bell
            local c = n - bell
            local a = (idx / c) * TAU + t * sp
            local drop = (idx / c) * r * 1.5
            local wave = math.sin(t * sp * 4 + a * 3) * r * 0.15
            return Vector3.new(
                math.cos(a) * r * 0.2 + wave,
                h - drop,
                math.sin(a) * r * 0.2 + wave
            )
        end
    end

    local function ShapeCoralReef(i, n, t, r, h, sp)
        local a = baseAngle(i, n, t, sp * 0.2)
        local frac = i / n
        local y = math.sin(frac * TAU * 3 + t * sp) * r * 0.8
        local rr = r * (0.5 + 0.5 * math.sin(frac * TAU * 5))
        local sway = math.sin(t * sp + frac * 12) * r * 0.1
        return Vector3.new(math.cos(a) * rr + sway, h + y, math.sin(a) * rr + sway)
    end

    -- ГРУППА 8: Взрывные финалы
    local function ShapeVolcanoBurst(i, n, t, r, h, sp)
        local a = baseAngle(i, n, t, sp)
        local burst = math.abs(math.sin(t * sp + i)) * r * 2
        return Vector3.new(math.cos(a) * burst, h + burst, math.sin(a) * burst)
    end

    local function ShapeCosmicExplosion(i, n, t, r, h, sp)
        local a = baseAngle(i, n, t, sp)
        local wave = math.abs(math.sin(t * sp * 2 - i * 0.1))
        return Vector3.new(
            math.cos(a) * r * wave * 3,
            h + wave * 5,
            math.sin(a) * r * wave * 3
        )
    end

    local function ShapeSupernova(i, n, t, r, h, sp)
        local phi = math.acos(1 - 2 * (i / n))
        local theta = i * math.pi * (3 - math.sqrt(5)) + t * sp
        local blast = r * (1 + math.sin(t * sp * 0.5) * 0.5)
        local eject = math.sin(phi * 3 + t * sp * 4) * r * 0.3
        return Vector3.new(
            math.cos(theta) * math.sin(phi) * (blast + eject),
            math.cos(phi) * (blast + eject) + h,
            math.sin(theta) * math.sin(phi) * (blast + eject)
        )
    end

    local function ShapeFireworkPop(i, n, t, r, h, sp)
        local phi = math.acos(1 - 2 * (i / n))
        local theta = i * math.pi * (3 - math.sqrt(5))
        local trail = math.abs(math.sin(t * sp * 3 + i * 0.7))
        local rr = r * trail
        local sparkle = math.sin(t * sp * 10 + i) * 0.8
        return Vector3.new(
            math.cos(theta) * math.sin(phi) * rr,
            math.cos(phi) * rr + h + sparkle,
            math.sin(theta) * math.sin(phi) * rr
        )
    end

    local function ShapeShockwave(i, n, t, r, h, sp)
        local a = baseAngle(i, n, t, sp)
        local ring = math.sin(t * sp * 3) * r
        local y = math.cos(t * sp * 2 + i * 0.2) * r * 0.3
        return Vector3.new(math.cos(a) * ring, h + y, math.sin(a) * ring)
    end

    -- ГРУППА 9: Математические кривые
    local function ShapeLissajous(i, n, t, r, h, sp)
        local a = baseAngle(i, n, t, sp)
        local p, q = 3, 2
        local d = math.pi / 2
        return Vector3.new(
            r * math.sin(p * a + d),
            h + r * 0.4 * math.sin(t * sp + i * 0.1),
            r * math.sin(q * a)
        )
    end

    local function ShapeHypotrochoid(i, n, t, r, h, sp)
        local R, rd, d = r, r * 0.4, r * 0.7
        local a = baseAngle(i, n, t, sp)
        local x = (R - rd) * math.cos(a) + d * math.cos((R - rd) / rd * a)
        local z = (R - rd) * math.sin(a) - d * math.sin((R - rd) / rd * a)
        return Vector3.new(x * 0.7, h + math.sin(t * sp + i * 0.2) * 2, z * 0.7)
    end

    local function ShapeEpitrochoid(i, n, t, r, h, sp)
        local R, rd, d = r * 0.6, r * 0.35, r * 0.5
        local a = baseAngle(i, n, t, sp)
        local x = (R + rd) * math.cos(a) - d * math.cos((R + rd) / rd * a)
        local z = (R + rd) * math.sin(a) - d * math.sin((R + rd) / rd * a)
        return Vector3.new(x * 0.7, h + math.sin(t * sp + i * 0.15) * 2, z * 0.7)
    end

    local function ShapeTrefoil(i, n, t, r, h, sp)
        local a = baseAngle(i, n, t, sp)
        local x = math.sin(a) + 2 * math.sin(2 * a)
        local y = math.cos(a) - 2 * math.cos(2 * a)
        local z = -math.sin(3 * a)
        local sc = r / 3
        return Vector3.new(x * sc, y * sc + h, z * sc)
    end

    local function ShapeKleinBottleSlice(i, n, t, r, h, sp)
        local u = baseAngle(i, n, t, sp)
        local v = baseAngle(i, math.max(n, 1), t * 2, sp)
        local a = r * 0.3
        local x = (a + a * math.cos(v)) * math.cos(u)
        local y = (a + a * math.cos(v)) * math.sin(u)
        local z = a * math.sin(v) + math.sin(t * sp + i * 0.2) * 2
        return Vector3.new(x, y + h, z)
    end

    local function ShapeHarmonograph(i, n, t, r, h, sp)
        local frac = i / n
        local decay = math.exp(-frac * 0.5)
        local f1, f2, f3, f4 = 3, 2, 3, 2
        local p1, p2 = math.pi / 4, math.pi / 6
        local a = frac * TAU * 8 + t * sp
        local x = r * decay * (math.sin(f1 * a + p1) + math.sin(f2 * a))
        local z = r * decay * (math.sin(f3 * a + p2) + math.sin(f4 * a))
        return Vector3.new(x * 0.5, h + math.sin(t * sp + frac * 12) * 1.5, z * 0.5)
    end

    -- ==========================================
    -- ТАБЛИЦА ФОРМ
    -- ==========================================

    local Shapes = {
        Planet = ShapePlanet,
        Sphere = ShapeSphere,
        Cylinder = ShapeCylinder,
        ['Double Ring'] = ShapeDoubleRing,
        Star = ShapeStar,
        Infinity = ShapeInfinity,
        Heart = ShapeHeart,
        ['DNA Helix'] = ShapeDNAHelix,
        ['Triple Helix'] = ShapeTripleHelix,
        Tornado = ShapeTornado,
        ['Galaxy Spiral'] = ShapeGalaxySpiral,
        ['Fibonacci Spiral'] = ShapeFibonacciSpiral,
        ['Spring Coil'] = ShapeSpringCoil,
        ['Vortex Funnel'] = ShapeVortexFunnel,
        Box = ShapeBox,
        ['Rounded Cube'] = ShapeRoundedCube,
        Torus = ShapeTorus,
        ['Torus Knot'] = ShapeTorusKnot,
        ['Möbius Strip'] = ShapeMobiusStrip,
        Saturn = ShapeSaturn,
        ['Ice Cube'] = ShapeIceCube,
        ['Black Hole'] = ShapeBlackHole,
        ['Hyper Sphere'] = ShapeHyperSphere,
        ['Orbital Rings'] = ShapeOrbitalRings,
        ['Lightning Tornado'] = ShapeLightningTornado,
        ['Plasma Cage'] = ShapePlasmaCage,
        Wormhole = ShapeWormhole,
        ['Quantum Lattice'] = ShapeQuantumLattice,
        ['Neutron Burst'] = ShapeNeutronBurst,
        ['Arc Discharge'] = ShapeArcDischarge,
        ['Event Horizon'] = ShapeEventHorizon,
        Butterfly = ShapeButterfly,
        ['Rose Petal'] = ShapeRosePetal,
        Snowflake = ShapeSnowflake,
        ['Crystal Bloom'] = ShapeCrystalBloom,
        ['Vine Wrap'] = ShapeVineWrap,
        ['Flower Bloom'] = ShapeFlowerBloom,
        Jellyfish = ShapeJellyfish,
        ['Coral Reef'] = ShapeCoralReef,
        ['Volcano Burst'] = ShapeVolcanoBurst,
        ['Cosmic Explosion'] = ShapeCosmicExplosion,
        Supernova = ShapeSupernova,
        ['Firework Pop'] = ShapeFireworkPop,
        Shockwave = ShapeShockwave,
        Lissajous = ShapeLissajous,
        Hypotrochoid = ShapeHypotrochoid,
        Epitrochoid = ShapeEpitrochoid,
        Trefoil = ShapeTrefoil,
        ['Klein Bottle Slice'] = ShapeKleinBottleSlice,
        Harmonograph = ShapeHarmonograph,
    }

    local function GetShapeOffset(index, total, t, cfg)
        local fn = Shapes[cfg.CurrentShape]
        if fn then
            return fn(index, total, t, cfg.Radius, cfg.Height, cfg.Speed)
        end
        local a = (index / total) * TAU + t * cfg.Speed
        return Vector3.new(math.cos(a) * cfg.Radius, cfg.Height, math.sin(a) * cfg.Radius)
    end

    local function SetupSparklerPhysics(obj, list)
        for _, v in ipairs(list) do
            if v == obj then return end
        end
        local mainPart = obj:IsA("BasePart") and obj or obj.PrimaryPart or obj:FindFirstChildWhichIsA("BasePart", true)
        if not mainPart then return end
        pcall(function()
            if mainPart:CanSetNetworkOwnership() then
                mainPart:SetNetworkOwner(plr)
            end
        end)
        mainPart.Anchored = false
        local bp = mainPart:FindFirstChild('ToyBodyPos') or Instance.new("BodyPosition", mainPart)
        bp.Name = 'ToyBodyPos'
        bp.MaxForce = Vector3.new(1e8, 1e8, 1e8)
        bp.P = 100000
        bp.D = 800
        local bg = mainPart:FindFirstChild('ToyBodyGyro') or Instance.new("BodyGyro", mainPart)
        bg.Name = 'ToyBodyGyro'
        bg.MaxTorque = Vector3.new(1e8, 1e8, 1e8)
        bg.P = 50000
        for _, p in ipairs(obj:GetDescendants()) do
            if p:IsA("BasePart") then
                p.CanCollide = false
            end
        end
        table.insert(list, obj)
    end

    -- UI для Sparklers
    ToysSparklerGroup:AddButton({
        Name = "Synchronize All Sparklers",
        Callback = function()
            for _, obj in ipairs(Workspace:GetDescendants()) do
                if obj.Name:find('FireworkSparkler') then
                    SetupSparklerPhysics(obj, activeSparklers)
                end
            end
            notify("nLhe", "Sparklers synchronized!", 2)
        end
    })

    ToysSparklerGroup:AddButton({
        Name = "Unsynchronize All Sparklers",
        Callback = function()
            table.clear(activeSparklers)
            notify("nLhe", "Sparklers unsynchronized!", 2)
        end
    })

    ToysSparklerGroup:AddSlider("HeightSlider", {
        Name = "Height Offset",
        Default = 5,
        Min = -20,
        Max = 150,
        Rounding = 0,
        Callback = function(v)
            sparklerConfig.Height = v
        end
    })

    ToysSparklerGroup:AddSlider("RadiusSlider", {
        Name = "Shape Radius",
        Default = 15,
        Min = 2,
        Max = 100,
        Rounding = 0,
        Callback = function(v)
            sparklerConfig.Radius = v
        end
    })

    ToysSparklerGroup:AddSlider("SpeedSlider", {
        Name = "Rotation Speed",
        Default = 2,
        Min = 0,
        Max = 20,
        Rounding = 1,
        Callback = function(v)
            sparklerConfig.Speed = v
        end
    })

    ToysSparklerGroup:AddDropdown("ShapeDropdown", {
        Name = "Select Shape",
        Values = shapeOptions,
        Default = "Planet",
        Callback = function(v)
            sparklerConfig.CurrentShape = v
        end
    })

    RunService.RenderStepped:Connect(function()
        local char = plr.Character
        local targetRoot = char and char:FindFirstChild("HumanoidRootPart")
        if not targetRoot then return end

        local t = tick()
        local prediction = targetRoot.AssemblyLinearVelocity * 0.12
        local rot = targetRoot.CFrame.Rotation

        for i = #activeSparklers, 1, -1 do
            local obj = activeSparklers[i]
            if obj and obj.Parent then
                local main = obj:IsA("BasePart") and obj or obj.PrimaryPart
                local bp = main and main:FindFirstChild('ToyBodyPos')
                local bg = main and main:FindFirstChild('ToyBodyGyro')
                if bp and bg then
                    local offset = GetShapeOffset(i, #activeSparklers, t, sparklerConfig)
                    bp.Position = targetRoot.Position + prediction + (rot * offset)
                    bg.CFrame = CFrame.new(main.Position, targetRoot.Position + prediction)
                end
            else
                table.remove(activeSparklers, i)
            end
        end
    end)
end

-- ==========================================
-- ЧАСТЬ 10: FIGURE GRAB (FGM МОДУЛЬ)
-- ==========================================

print("🔄 Loading Figure Grab...")

local plr = _G.nLhe.plr
local RS = _G.nLhe.RS
local RunService = _G.nLhe.RunService
local Workspace = _G.nLhe.Workspace
local Players = _G.nLhe.Players
local UIS = _G.nLhe.UIS
local TweenService = _G.nLhe.TweenService
local Lighting = _G.nLhe.Lighting

local SetNetworkOwner = RS:FindFirstChild("GrabEvents") and RS.GrabEvents:FindFirstChild("SetNetworkOwner")
local DestroyToy = RS:FindFirstChild("MenuToys") and RS.MenuToys:FindFirstChild("DestroyToy")
local DestroyGrabLine = RS:FindFirstChild("GrabEvents") and RS.GrabEvents:FindFirstChild("DestroyGrabLine")
local SpawnToyRemote = RS:FindFirstChild("MenuToys") and RS.MenuToys:FindFirstChild("SpawnToyRemoteFunction")

local FigureGroup = _G.nLhe.Tabs.Figure:AddLeftGroupbox("rr9 Figure Grab", "mouse")

local bool = _G.nLhe.bool
local int = _G.nLhe.int
local cons = _G.nLhe.cons
local etc = _G.nLhe.etc

local function discCon(key) _G.nLhe.discCon(key) end
local function notify(t, c, d) _G.nLhe.notify(t, c, d) end
local function sno(part) _G.nLhe.sno(part) end
local function GetMagnitude(a, b) return _G.nLhe.GetMagnitude(a, b) end

-- ==========================================
-- 10.1. FGM ОСНОВНОЙ МОДУЛЬ
-- ==========================================

_G.FGM = {
    State = {
        FigureGrabEnabled = false,
        FigureGrabConnection = nil,
        TargetCharacter = nil,
        TargetPlayer = nil,
        AnimationCopyEnabled = false,
        VectorZero = Vector3.new(0, 0, 0),
        AutoRagdollToggle = false,
        AutoRagdollEnabled = false,
        AutoRagdollConnection = nil,
        RagdollPallet = nil,
        RagdollSoundPart = nil,
        SmoothedCFrames = {},
        SelectedLimb = 'Torso',
        HighlightedLimb = nil,
        LimbHighlight = nil,
        PersistentGrabActive = false,
        PersistentGrabThread = nil,
        SavedPosition = nil,
        IsReturning = false,
        DistanceTPInProgress = false,
        FreezeLimbsEnabled = false,
        FrozenCFrames = {},
        VelSuppressEnabled = false,
        GravityFlipEnabled = false,
        LockRotationEnabled = false,
        LockedRotation = CFrame.identity,
        ForceLookAtEnabled = false,
        ForceUprightEnabled = false,
        FlingOnReleaseEnabled = false,
        FlingForce = 300,
        HoldAtCameraEnabled = false,
        OscillateEnabled = false,
        OscillateSpeed = 2,
        OscillateAmount = 3,
        OscillateTimer = 0,
        SpinEnabled = false,
        SpinSpeed = 180,
        SpinAngle = 0,
        ActiveNetworkTarget = nil,
        SelectedTarget = nil,
        RespawnConnection = nil,
        RejoinConnection = nil,
        LastGrabTargetRef = nil,
    },
    Configuration = {
        DampingEnabled = true,
        DampingSpeed = 12,
        SnapEnabled = false,
        SnapPosStep = 0.5,
        SnapRotStep = 15,
        LineDistance = 0,
        AutoTPDistance = 40,
        HoldPosition = { X = 0, Y = 0, Z = -5 },
        HoldRotation = { X = 0, Y = 0, Z = 0 },
        LeftArmPosition = { X = 0, Y = 0, Z = 0 },
        LeftArmRotation = { X = 0, Y = 0, Z = 0 },
        RightArmPosition = { X = 0, Y = 0, Z = 0 },
        RightArmRotation = { X = 0, Y = 0, Z = 0 },
        LeftLegPosition = { X = 0, Y = 0, Z = 0 },
        LeftLegRotation = { X = 0, Y = 0, Z = 0 },
        RightLegPosition = { X = 0, Y = 0, Z = 0 },
        RightLegRotation = { X = 0, Y = 0, Z = 0 },
        HeadPosition = { X = 0, Y = 0, Z = 0 },
        HeadRotation = { X = 0, Y = 0, Z = 0 },
    },
    Presets = {},
    CustomPresets = {},
}

local FGM = _G.FGM

-- ==========================================
-- 10.2. КОНСТАНТЫ И ВСПОМОГАТЕЛЬНЫЕ ФУНКЦИИ
-- ==========================================

local LIMB_OPTIONS = {'Torso', 'Head', 'Left Arm', 'Right Arm', 'Left Leg', 'Right Leg'}
local LIMB_SECTION_MAP = {
    Torso = { pos = 'HoldPosition', rot = 'HoldRotation' },
    Head = { pos = 'HeadPosition', rot = 'HeadRotation' },
    ['Left Arm'] = { pos = 'LeftArmPosition', rot = 'LeftArmRotation' },
    ['Right Arm'] = { pos = 'RightArmPosition', rot = 'RightArmRotation' },
    ['Left Leg'] = { pos = 'LeftLegPosition', rot = 'LeftLegRotation' },
    ['Right Leg'] = { pos = 'RightLegPosition', rot = 'RightLegRotation' },
}
local PART_NAME_MAP = {
    Torso = 'Torso',
    Head = 'Head',
    ['Left Arm'] = 'Left Arm',
    ['Right Arm'] = 'Right Arm',
    ['Left Leg'] = 'Left Leg',
    ['Right Leg'] = 'Right Leg',
}

local function GetActiveSections()
    local limb = FGM.State.SelectedLimb
    return LIMB_SECTION_MAP[limb] or LIMB_SECTION_MAP.Torso
end

local function LerpCFrame(a, b, alpha)
    return a:Lerp(b, alpha)
end

local function BuildTargetCFrame(partName, torsoWorldCFrame, config)
    local posKey, rotKey
    if partName == 'Left Arm' then posKey, rotKey = 'LeftArmPosition', 'LeftArmRotation'
    elseif partName == 'Right Arm' then posKey, rotKey = 'RightArmPosition', 'RightArmRotation'
    elseif partName == 'Left Leg' then posKey, rotKey = 'LeftLegPosition', 'LeftLegRotation'
    elseif partName == 'Right Leg' then posKey, rotKey = 'RightLegPosition', 'RightLegRotation'
    elseif partName == 'Head' then posKey, rotKey = 'HeadPosition', 'HeadRotation'
    else return nil end
    local p = config[posKey]
    local r = config[rotKey]
    if not p or not r then return nil end
    return torsoWorldCFrame * CFrame.new(p.X, p.Y, p.Z) * CFrame.Angles(math.rad(r.X), math.rad(r.Y), math.rad(r.Z))
end

local function SnapValue(value, step)
    if step == 0 then return value end
    return math.round(value / step) * step
end

-- ==========================================
-- 10.3. ПОЗЫ (PRESETS)
-- ==========================================

FGM.Presets = {
    Pose1 = {
        HoldPosition = { X = 0, Y = 0, Z = -7.5 },
        HoldRotation = { X = 90, Y = 0, Z = 108 },
        LeftArmPosition = { X = -1.5, Y = 1, Z = -1 },
        LeftArmRotation = { X = 283, Y = 0, Z = 0 },
        RightArmPosition = { X = 1.5, Y = 0.5, Z = 1 },
        RightArmRotation = { X = 270, Y = 0, Z = 0 },
        LeftLegPosition = { X = 0.5, Y = -1.5, Z = 0.5 },
        LeftLegRotation = { X = 312, Y = 0, Z = 0 },
        RightLegPosition = { X = -0.5, Y = -1.5, Z = 0.5 },
        RightLegRotation = { X = 283, Y = 0, Z = 0 },
        HeadPosition = { X = 0, Y = 1.5, Z = 0 },
        HeadRotation = { X = 0, Y = 0, Z = 0 },
    },
    Pose2 = {
        HoldPosition = { X = 0, Y = -1.5, Z = -12.5 },
        HoldRotation = { X = 272, Y = 0, Z = 0 },
        LeftArmPosition = { X = -1, Y = 1, Z = -0.5 },
        LeftArmRotation = { X = 90, Y = 0, Z = 0 },
        RightArmPosition = { X = 1, Y = 1, Z = -0.5 },
        RightArmRotation = { X = 90, Y = 0, Z = 0 },
        LeftLegPosition = { X = 1, Y = -1, Z = -0.5 },
        LeftLegRotation = { X = 90, Y = 0, Z = 0 },
        RightLegPosition = { X = -1, Y = -1, Z = -0.5 },
        RightLegRotation = { X = 90, Y = 0, Z = 0 },
        HeadPosition = { X = 0, Y = 1, Z = 1 },
        HeadRotation = { X = 90, Y = 0, Z = 0 },
    },
    Pose3 = {
        HoldPosition = { X = 0, Y = -5.5, Z = -4 },
        HoldRotation = { X = 0, Y = 0, Z = 0 },
        LeftArmPosition = { X = 1, Y = 7.5, Z = 1.5 },
        LeftArmRotation = { X = 0, Y = 0, Z = 0 },
        RightArmPosition = { X = 1, Y = 6, Z = 1.5 },
        RightArmRotation = { X = 0, Y = 0, Z = 0 },
        LeftLegPosition = { X = 0.5, Y = 5, Z = 1.5 },
        LeftLegRotation = { X = 0, Y = 0, Z = 92 },
        RightLegPosition = { X = -0.5, Y = 5, Z = 1.5 },
        RightLegRotation = { X = 0, Y = 0, Z = 90 },
        HeadPosition = { X = 0, Y = 0, Z = 0 },
        HeadRotation = { X = 0, Y = 0, Z = 0 },
    },
    Pose4 = {
        HoldPosition = { X = 1.5, Y = -8.5, Z = -1.5 },
        HoldRotation = { X = 0, Y = 0, Z = 0 },
        LeftArmPosition = { X = 0, Y = 0, Z = 0 },
        LeftArmRotation = { X = 0, Y = 0, Z = 0 },
        RightArmPosition = { X = 0, Y = 0, Z = 0 },
        RightArmRotation = { X = 0, Y = 0, Z = 0 },
        LeftLegPosition = { X = 0, Y = 0, Z = 0 },
        LeftLegRotation = { X = 0, Y = 0, Z = 0 },
        RightLegPosition = { X = 1.5, Y = 0, Z = 0 },
        RightLegRotation = { X = 0, Y = 0, Z = 0 },
        HeadPosition = { X = 0, Y = 9, Z = 0 },
        HeadRotation = { X = 0, Y = 0, Z = 0 },
    },
    Pose5 = {
        HoldPosition = { X = 0, Y = -3, Z = -6 },
        HoldRotation = { X = 270, Y = 0, Z = 0 },
        LeftArmPosition = { X = -1, Y = 0.5, Z = 0 },
        LeftArmRotation = { X = 180, Y = 0, Z = 0 },
        RightArmPosition = { X = 1, Y = 0.5, Z = 0 },
        RightArmRotation = { X = 180, Y = 0, Z = 0 },
        LeftLegPosition = { X = 0, Y = -3, Z = 0 },
        LeftLegRotation = { X = 0, Y = 0, Z = 0 },
        RightLegPosition = { X = 0, Y = -2, Z = 0.5 },
        RightLegRotation = { X = 45, Y = 0, Z = 0 },
        HeadPosition = { X = 0, Y = 1.5, Z = -0.5 },
        HeadRotation = { X = 270, Y = 0, Z = 0 },
    },
    Pose6 = {
        HoldPosition = { X = 5.5, Y = 0.5, Z = -1.5 },
        HoldRotation = { X = 345, Y = 39, Z = 0 },
        LeftArmPosition = { X = 2, Y = 0.5, Z = 0 },
        LeftArmRotation = { X = 0, Y = 43, Z = 121 },
        RightArmPosition = { X = -2, Y = 0, Z = 0 },
        RightArmRotation = { X = 64, Y = 112, Z = 0 },
        LeftLegPosition = { X = -0.5, Y = -2, Z = 0 },
        LeftLegRotation = { X = 349, Y = 0, Z = 360 },
        RightLegPosition = { X = 0.5, Y = -2, Z = 0 },
        RightLegRotation = { X = 345, Y = 360, Z = 10 },
        HeadPosition = { X = 0, Y = 1.5, Z = 0 },
        HeadRotation = { X = 0, Y = 344, Z = 0 },
    },
    Pose7 = {
        HoldPosition = { X = 0, Y = -2, Z = -10 },
        HoldRotation = { X = 90, Y = 0, Z = 0 },
        LeftArmPosition = { X = -1.5, Y = 0, Z = 0 },
        LeftArmRotation = { X = 270, Y = 0, Z = 315 },
        RightArmPosition = { X = 1.5, Y = 0, Z = 0 },
        RightArmRotation = { X = 270, Y = 0, Z = 45 },
        LeftLegPosition = { X = -1, Y = -1.5, Z = 0 },
        LeftLegRotation = { X = 90, Y = 0, Z = 0 },
        RightLegPosition = { X = 1, Y = -1.5, Z = 0 },
        RightLegRotation = { X = 90, Y = 0, Z = 0 },
        HeadPosition = { X = 0, Y = 1.5, Z = 0 },
        HeadRotation = { X = 0, Y = 0, Z = 0 },
    },
    JojoStand = {
        HoldPosition = { X = -4.5, Y = 0.5, Z = -1.5 },
        HoldRotation = { X = 8, Y = 349, Z = 0 },
        LeftArmPosition = { X = 1.5, Y = 0, Z = 0 },
        LeftArmRotation = { X = 15, Y = 62, Z = 41 },
        RightArmPosition = { X = -1.5, Y = 0.5, Z = -0.5 },
        RightArmRotation = { X = 65, Y = 149, Z = 6 },
        LeftLegPosition = { X = -0.5, Y = -2, Z = 0 },
        LeftLegRotation = { X = 349, Y = 0, Z = 360 },
        RightLegPosition = { X = 0.5, Y = -2, Z = 0 },
        RightLegRotation = { X = 345, Y = 360, Z = 10 },
        HeadPosition = { X = 0, Y = 1.5, Z = 0 },
        HeadRotation = { X = 0, Y = 344, Z = 0 },
    },
}

-- ==========================================
-- 10.4. ОСНОВНЫЕ ФУНКЦИИ FGM
-- ==========================================

function FGM.GetCharacter(player)
    local character = player.Character
    if not character and player.CharacterAdded then
        character = player.CharacterAdded:Wait()
    end
    return character
end

function FGM.GetPlayerList()
    local list = {}
    for _, p in pairs(Players:GetPlayers()) do
        if p ~= plr then
            table.insert(list, p.DisplayName .. " (@" .. p.Name .. ")")
        end
    end
    table.sort(list)
    return list
end

function FGM.GetUsernameFromFormatted(fmt)
    return fmt:match("%(@(.+)%)") or fmt
end

function FGM.BringTargetToMe(target)
    if not target then return false end
    local myChar = FGM.GetCharacter(plr)
    local myRoot = myChar and myChar:FindFirstChild("HumanoidRootPart")
    if not myRoot then return false end
    local savedPos = myRoot.CFrame
    if not target.Character then return false end
    local tRoot = target.Character:FindFirstChild("HumanoidRootPart")
    local tHum = target.Character:FindFirstChild("Humanoid")
    if not tRoot or not tHum then return false end

    myRoot.CFrame = tRoot.CFrame * CFrame.new(0, 0, 2.5)
    myRoot.AssemblyLinearVelocity = Vector3.zero
    task.wait(0.05)

    for i = 1, 8 do
        pcall(function() if SetNetworkOwner then SetNetworkOwner:FireServer(tRoot, tRoot.CFrame) end end)
        task.wait(0.01)
    end
    for i = 1, 4 do
        pcall(function() if DestroyGrabLine then DestroyGrabLine:FireServer(tRoot) end end)
        task.wait(0.01)
    end

    tRoot.CFrame = savedPos * CFrame.new(0, 0, 2)
    tRoot.AssemblyLinearVelocity = Vector3.zero
    pcall(function() tHum.PlatformStand = true end)
    task.wait(0.05)
    myRoot.CFrame = savedPos
    myRoot.AssemblyLinearVelocity = Vector3.zero
    return true
end

function FGM.JumpAndReturn()
    local myChar = FGM.GetCharacter(plr)
    local myHRP = myChar and myChar:FindFirstChild("HumanoidRootPart")
    if not myHRP then return end
    FGM.State.IsReturning = true
    if FGM.State.SavedPosition then
        myHRP.CFrame = FGM.State.SavedPosition
        myHRP.Velocity = Vector3.zero
        myHRP.AssemblyAngularVelocity = Vector3.zero
    end
    FGM.State.IsReturning = false
end

function FGM.ClearLimbHighlight()
    local state = FGM.State
    if state.LimbHighlight and state.LimbHighlight.Parent then
        state.LimbHighlight:Destroy()
    end
    state.LimbHighlight = nil
    state.HighlightedLimb = nil
end

function FGM.ApplyLimbHighlight(limbName)
    FGM.ClearLimbHighlight()
    local state = FGM.State
    local target = state.TargetCharacter
    if not target then return end
    local partName = PART_NAME_MAP[limbName]
    if not partName then return end
    local part = target:FindFirstChild(partName)
    if not part then return end
    local highlight = Instance.new("SelectionBox")
    highlight.Adornee = part
    highlight.Color3 = Color3.fromRGB(0, 120, 255)
    highlight.LineThickness = 0.05
    highlight.SurfaceTransparency = 0.6
    highlight.SurfaceColor3 = Color3.fromRGB(0, 100, 255)
    highlight.Parent = Workspace.CurrentCamera
    state.LimbHighlight = highlight
    state.HighlightedLimb = limbName
end

function FGM.ToggleAutoRagdoll(enabled)
    FGM.State.AutoRagdollEnabled = enabled
    if FGM.State.AutoRagdollConnection then
        FGM.State.AutoRagdollConnection:Disconnect()
        FGM.State.AutoRagdollConnection = nil
    end
    if not enabled then
        if FGM.State.RagdollPallet then
            pcall(function() if DestroyToy then DestroyToy:FireServer(FGM.State.RagdollPallet) end end)
        end
        FGM.State.RagdollPallet = nil
        FGM.State.RagdollSoundPart = nil
        return
    end

    task.spawn(function()
        local myChar = FGM.GetCharacter(plr)
        local myHRP = myChar and myChar:FindFirstChild("HumanoidRootPart")
        if not myHRP then return end

        local myToys = Workspace:FindFirstChild(plr.Name .. "SpawnedInToys")
        if not myToys then return end

        local pallet = myToys:FindFirstChild("RagdollPallet") or myToys:FindFirstChild("PalletLightBrown")
        if not pallet then
            if SpawnToyRemote then
                SpawnToyRemote:InvokeServer("PalletLightBrown", myHRP.CFrame * CFrame.new(5, 5, 20), Vector3.zero)
            end
            local t = tick() + 5
            repeat task.wait(0.05) until myToys:FindFirstChild("PalletLightBrown") or tick() > t
            pallet = myToys:FindFirstChild("PalletLightBrown")
        end
        if not pallet then return end

        pallet.Name = "RagdollPallet"
        local soundPart = pallet:WaitForChild("SoundPart", 5)
        if not soundPart then return end

        local t2 = tick() + 3
        repeat
            sno(soundPart)
            task.wait()
        until soundPart:FindFirstChild("PartOwner") or tick() > t2

        soundPart.AssemblyLinearVelocity = Vector3.new(0, 10000, 0)
        for _, v in pairs(pallet:GetDescendants()) do
            if v:IsA("BasePart") then
                v.Transparency = 1
                v.CanCollide = false
            end
        end

        FGM.State.RagdollPallet = pallet
        FGM.State.RagdollSoundPart = soundPart

        FGM.State.AutoRagdollConnection = RunService.Heartbeat:Connect(function()
            if not FGM.State.AutoRagdollEnabled then return end
            local sp = FGM.State.RagdollSoundPart
            if not sp or not sp.Parent then
                if FGM.State.AutoRagdollConnection then
                    FGM.State.AutoRagdollConnection:Disconnect()
                    FGM.State.AutoRagdollConnection = nil
                end
                FGM.State.RagdollPallet = nil
                FGM.State.RagdollSoundPart = nil
                return
            end

            local targets = {}
            if FGM.State.FigureGrabEnabled and FGM.State.TargetCharacter then
                table.insert(targets, FGM.State.TargetCharacter)
            end

            for _, targetChar in ipairs(targets) do
                local hrp = targetChar:FindFirstChild("HumanoidRootPart")
                local hum = targetChar:FindFirstChild("Humanoid")
                if hrp and hum then
                    local ragdolled = hum:FindFirstChild("Ragdolled")
                    if ragdolled and ragdolled.Value == false then
                        task.spawn(function()
                            sp.AssemblyLinearVelocity = Vector3.new(0, 100, 0)
                            sp.CFrame = hrp.CFrame
                            task.wait(0.05)
                            if sp and sp.Parent then
                                sp.CFrame = CFrame.new(0, 1e9, 0)
                            end
                        end)
                    end
                end
            end
        end)
    end)
end

function FGM.SetAnimationCopy(enabled)
    FGM.State.AnimationCopyEnabled = enabled
end

function FGM.ResetPose()
    local limbSections = {
        'LeftArmPosition', 'LeftArmRotation', 'RightArmPosition', 'RightArmRotation',
        'LeftLegPosition', 'LeftLegRotation', 'RightLegPosition', 'RightLegRotation',
        'HeadPosition', 'HeadRotation', 'HoldRotation',
    }
    for _, section in ipairs(limbSections) do
        local t = FGM.Configuration[section]
        if t then
            for axis in pairs(t) do
                t[axis] = 0
            end
        end
    end
    FGM.Configuration.HoldPosition = { X = 0, Y = 0, Z = -5 }
end

function FGM.ApplyPreset(presetName)
    local preset = FGM.Presets[presetName]
    if not preset then return end
    for section, values in pairs(preset) do
        if FGM.Configuration[section] then
            for axis, value in pairs(values) do
                FGM.Configuration[section][axis] = value
            end
        end
    end
end

function FGM.UpdateConfig(section, axis, rawValue)
    local cfg = FGM.Configuration
    if cfg[section] and cfg[section][axis] ~= nil then
        if FGM.Configuration.SnapEnabled then
            local isRot = section:find('Rotation')
            local step = isRot and FGM.Configuration.SnapRotStep or FGM.Configuration.SnapPosStep
            cfg[section][axis] = SnapValue(rawValue, step)
        else
            cfg[section][axis] = rawValue
        end
    end
end

function FGM.SnapshotLimbsForFreeze()
    local state = FGM.State
    local target = state.TargetCharacter
    state.FrozenCFrames = {}
    if not target then return end
    for _, name in ipairs({'Head', 'Left Arm', 'Right Arm', 'Left Leg', 'Right Leg'}) do
        local part = target:FindFirstChild(name)
        if part then
            state.FrozenCFrames[name] = part.CFrame
        end
    end
end

function FGM.SaveCustomPreset(name)
    if not name or name == '' then return false end
    FGM.CustomPresets[name] = FGM.GetCurrentConfigSnapshot()
    return true
end

function FGM.LoadCustomPreset(name)
    local preset = FGM.CustomPresets[name]
    if not preset then return false end
    for section, values in pairs(preset) do
        if FGM.Configuration[section] then
            for axis, value in pairs(values) do
                FGM.Configuration[section][axis] = value
            end
        end
    end
    return true
end

function FGM.DeleteCustomPreset(name)
    if not FGM.CustomPresets[name] then return false end
    FGM.CustomPresets[name] = nil
    return true
end

function FGM.GetCustomPresetNames()
    local names = {}
    for name in pairs(FGM.CustomPresets) do
        table.insert(names, name)
    end
    table.sort(names)
    return names
end

function FGM.GetCurrentConfigSnapshot()
    local cfg = FGM.Configuration
    local snapshot = {}
    local keys = {
        'HoldPosition', 'HoldRotation', 'LeftArmPosition', 'LeftArmRotation',
        'RightArmPosition', 'RightArmRotation', 'LeftLegPosition', 'LeftLegRotation',
        'RightLegPosition', 'RightLegRotation', 'HeadPosition', 'HeadRotation',
    }
    for _, key in ipairs(keys) do
        if cfg[key] then
            snapshot[key] = { X = cfg[key].X, Y = cfg[key].Y, Z = cfg[key].Z }
        end
    end
    return snapshot
end

function FGM.StartPersistentGrab()
    FGM.StopPersistentGrab()
    FGM.State.PersistentGrabActive = true
    FGM.State.PersistentGrabThread = task.spawn(function()
        while FGM.State.PersistentGrabActive do
            task.wait(0.1)
            local state = FGM.State
            local target = state.TargetCharacter
            if not target or not state.FigureGrabEnabled then
                continue
            end
            local myChar = FGM.GetCharacter(plr)
            if not myChar then continue end
            local myHRP = myChar:FindFirstChild("HumanoidRootPart")
            local targetHRP = target:FindFirstChild("HumanoidRootPart")
            if not myHRP or not targetHRP then continue end

            if DestroyGrabLine then DestroyGrabLine:FireServer(targetHRP) end
            sno(targetHRP)

            local dist = (targetHRP.Position - myHRP.Position).Magnitude
            if dist >= FGM.Configuration.AutoTPDistance then
                if not state.DistanceTPInProgress then
                    state.DistanceTPInProgress = true
                    task.spawn(function()
                        if state.TargetPlayer then
                            FGM.BringTargetToMe(state.TargetPlayer)
                        end
                        task.wait(0.3)
                        state.DistanceTPInProgress = false
                    end)
                end
            end
        end
    end)
end

function FGM.StopPersistentGrab()
    FGM.State.PersistentGrabActive = false
    if FGM.State.PersistentGrabThread then
        pcall(function() task.cancel(FGM.State.PersistentGrabThread) end)
        FGM.State.PersistentGrabThread = nil
    end
end

function FGM.WaitForCharacterReady(targetPlayer, timeout)
    timeout = timeout or 15
    local deadline = tick() + timeout
    while tick() < deadline do
        local char = targetPlayer.Character
        if char and char.Parent and char:FindFirstChild('HumanoidRootPart') and
           char:FindFirstChild('Torso') and char:FindFirstChild('Humanoid') and
           char.Humanoid.Health > 0 then
            return char
        end
        task.wait(0.15)
    end
    return nil
end

function FGM.ReattachToCharacter(newCharacter)
    local state = FGM.State
    if not state.FigureGrabEnabled then return end
    local myChar = FGM.GetCharacter(plr)
    if not myChar then return end
    FGM.ToggleAutoRagdoll(false)
    task.wait(0.1)
    state.TargetCharacter = newCharacter
    state.ActiveNetworkTarget = newCharacter:FindFirstChild('HumanoidRootPart')
    SetupBodyParts(newCharacter)
    if state.TargetPlayer then
        FGM.BringTargetToMe(state.TargetPlayer)
    end
    task.wait(0.1)
    RunHeartbeat(myChar)
    if state.AutoRagdollToggle then
        FGM.ToggleAutoRagdoll(true)
    end
    if state.HighlightedLimb then
        FGM.ApplyLimbHighlight(state.HighlightedLimb)
    end
end

function FGM.WatchForRespawn(targetPlayer)
    if FGM.State.RespawnConnection then
        pcall(function() FGM.State.RespawnConnection:Disconnect() end)
        FGM.State.RespawnConnection = nil
    end
    FGM.State.RespawnConnection = targetPlayer.CharacterAdded:Connect(function()
        if not FGM.State.FigureGrabEnabled then return end
        local readyChar = FGM.WaitForCharacterReady(targetPlayer, 15)
        if not readyChar then return end
        FGM.ReattachToCharacter(readyChar)
    end)
end

function FGM.WatchForRejoin(targetPlayer)
    if FGM.State.RejoinConnection then
        pcall(function() FGM.State.RejoinConnection:Disconnect() end)
        FGM.State.RejoinConnection = nil
    end
    local targetUserId = targetPlayer.UserId
    local removingConn
    removingConn = Players.PlayerRemoving:Connect(function(leavingPlayer)
        if leavingPlayer.UserId ~= targetUserId then return end
        if not FGM.State.FigureGrabEnabled then
            pcall(function() removingConn:Disconnect() end)
            FGM.State.RejoinConnection = nil
            return
        end
        task.spawn(function()
            local rejoinConn
            rejoinConn = Players.PlayerAdded:Connect(function(newPlayer)
                if newPlayer.UserId ~= targetUserId then return end
                pcall(function() rejoinConn:Disconnect() end)
                pcall(function() removingConn:Disconnect() end)
                FGM.State.RejoinConnection = nil
                if not FGM.State.FigureGrabEnabled then return end
                local readyChar = FGM.WaitForCharacterReady(newPlayer, 30)
                if not readyChar then return end
                FGM.State.TargetPlayer = newPlayer
                FGM.WatchForRespawn(newPlayer)
                FGM.WatchForRejoin(newPlayer)
                FGM.ReattachToCharacter(readyChar)
            end)
        end)
    end)
    FGM.State.RejoinConnection = removingConn
end

function SetupBodyParts(targetCharacter)
    local bodyParts = {'Head', 'Left Arm', 'Right Arm', 'Left Leg', 'Right Leg'}
    for _, partName in pairs(bodyParts) do
        local part = targetCharacter:FindFirstChild(partName)
        if part then
            part.Anchored = false
            part.CanCollide = true
            part.Massless = true
        end
    end
    FGM.State.SmoothedCFrames = {}
    local parts = {'Torso', 'Head', 'Left Arm', 'Right Arm', 'Left Leg', 'Right Leg'}
    for _, name in ipairs(parts) do
        local part = targetCharacter:FindFirstChild(name)
        if part then
            FGM.State.SmoothedCFrames[name] = part.CFrame
        end
    end
end

function RunHeartbeat(MyCharacter)
    local cfg = FGM.Configuration
    local state = FGM.State
    local zero = state.VectorZero
    local bodyParts = {'Head', 'Left Arm', 'Right Arm', 'Left Leg', 'Right Leg'}
    local lastTime = tick()

    if state.FigureGrabConnection then
        pcall(function() state.FigureGrabConnection:Disconnect() end)
    end

    state.FigureGrabConnection = RunService.Heartbeat:Connect(function()
        local now = tick()
        local dt = math.min(now - lastTime, 0.1)
        lastTime = now

        local target = state.TargetCharacter
        if not target or not MyCharacter then return end

        local MyRoot = MyCharacter:FindFirstChild("HumanoidRootPart")
        local TargetTorso = target:FindFirstChild("Torso")
        if not MyRoot or not TargetTorso then return end

        if state.SpinEnabled then
            state.SpinAngle = (state.SpinAngle + state.SpinSpeed * dt) % 360
        end

        if state.OscillateEnabled then
            state.OscillateTimer = state.OscillateTimer + dt
        end

        local holdOffsetZ = cfg.HoldPosition.Z
        if state.OscillateEnabled then
            holdOffsetZ = holdOffsetZ + math.sin(state.OscillateTimer * state.OscillateSpeed * math.pi * 2) * state.OscillateAmount
        end

        local baseHoldCFrame = MyRoot.CFrame * CFrame.new(cfg.HoldPosition.X, cfg.HoldPosition.Y, holdOffsetZ) *
            CFrame.Angles(math.rad(cfg.HoldRotation.X), math.rad(cfg.HoldRotation.Y), math.rad(cfg.HoldRotation.Z))

        if state.HoldAtCameraEnabled then
            local cam = Workspace.CurrentCamera
            baseHoldCFrame = cam.CFrame * CFrame.new(0, 0, -math.abs(cfg.HoldPosition.Z))
        end

        if state.GravityFlipEnabled then
            local pos = baseHoldCFrame.Position
            local myY = MyRoot.Position.Y
            local flippedY = myY - (pos.Y - myY)
            local rot = baseHoldCFrame.Rotation
            baseHoldCFrame = CFrame.new(pos.X, flippedY, pos.Z) * rot
        end

        local holdCFrame = baseHoldCFrame

        if state.ForceLookAtEnabled then
            local lookDir = (MyRoot.Position - baseHoldCFrame.Position)
            if lookDir.Magnitude > 0.01 then
                holdCFrame = CFrame.new(baseHoldCFrame.Position, baseHoldCFrame.Position + lookDir)
            end
        end

        if state.ForceUprightEnabled then
            local p = holdCFrame.Position
            holdCFrame = CFrame.new(p) * CFrame.Angles(0, math.rad(cfg.HoldRotation.Y), 0)
        end

        if state.LockRotationEnabled then
            holdCFrame = CFrame.new(holdCFrame.Position) * state.LockedRotation
        end

        if state.SpinEnabled then
            holdCFrame = holdCFrame * CFrame.Angles(0, math.rad(state.SpinAngle), 0)
        end

        if state.FreezeLimbsEnabled and next(state.FrozenCFrames) then
            for partName, frozenCF in pairs(state.FrozenCFrames) do
                local part = target:FindFirstChild(partName)
                if part and part.Parent then
                    pcall(function()
                        part.CFrame = frozenCF
                        part.Velocity = zero
                        part.RotVelocity = zero
                    end)
                end
            end
            if cfg.DampingEnabled then
                local prev = state.SmoothedCFrames.Torso or holdCFrame
                local alpha = math.min(1, cfg.DampingSpeed * dt)
                state.SmoothedCFrames.Torso = LerpCFrame(prev, holdCFrame, alpha)
                pcall(function()
                    TargetTorso.CFrame = state.SmoothedCFrames.Torso
                    TargetTorso.Velocity = zero
                    TargetTorso.RotVelocity = zero
                end)
            else
                pcall(function()
                    TargetTorso.CFrame = holdCFrame
                    TargetTorso.Velocity = zero
                    TargetTorso.RotVelocity = zero
                end)
            end
            sno(state.ActiveNetworkTarget)
            return
        end

        if cfg.DampingEnabled then
            local prev = state.SmoothedCFrames.Torso or holdCFrame
            local alpha = math.min(1, cfg.DampingSpeed * dt)
            state.SmoothedCFrames.Torso = LerpCFrame(prev, holdCFrame, alpha)
            pcall(function()
                TargetTorso.CFrame = state.SmoothedCFrames.Torso
                TargetTorso.Velocity = zero
                TargetTorso.RotVelocity = zero
            end)
        else
            pcall(function()
                TargetTorso.CFrame = holdCFrame
                TargetTorso.Velocity = zero
                TargetTorso.RotVelocity = zero
            end)
        end

        if state.VelSuppressEnabled then
            for _, part in pairs(target:GetChildren()) do
                if part:IsA("BasePart") then
                    pcall(function()
                        part.AssemblyLinearVelocity = zero
                        part.AssemblyAngularVelocity = zero
                    end)
                end
            end
        end

        if state.AnimationCopyEnabled then
            local MyTorso = MyCharacter:FindFirstChild("Torso")
            if MyTorso then
                for _, limbName in pairs(bodyParts) do
                    local myPart = MyCharacter:FindFirstChild(limbName)
                    local targetPart = target:FindFirstChild(limbName)
                    if myPart and targetPart then
                        local relative = MyTorso.CFrame:ToObjectSpace(myPart.CFrame)
                        pcall(function()
                            targetPart.CFrame = TargetTorso.CFrame:ToWorldSpace(relative)
                            targetPart.Velocity = zero
                            targetPart.RotVelocity = zero
                        end)
                    end
                end
            end
        else
            local torsoCF = TargetTorso.CFrame
            for _, partName in pairs(bodyParts) do
                local part = target:FindFirstChild(partName)
                if part and part.Parent then
                    local targetCF = BuildTargetCFrame(partName, torsoCF, cfg)
                    if targetCF then
                        if cfg.DampingEnabled then
                            local prev = state.SmoothedCFrames[partName] or targetCF
                            local alpha = math.min(1, cfg.DampingSpeed * dt)
                            state.SmoothedCFrames[partName] = LerpCFrame(prev, targetCF, alpha)
                            pcall(function()
                                part.CFrame = state.SmoothedCFrames[partName]
                                part.Velocity = zero
                                part.RotVelocity = zero
                            end)
                        else
                            pcall(function()
                                part.CFrame = targetCF
                                part.Velocity = zero
                                part.RotVelocity = zero
                            end)
                        end
                    end
                end
            end
        end

        sno(state.ActiveNetworkTarget)
    end)
end

function FGM.ToggleFigureGrab()
    if not FGM.State.FigureGrabEnabled then
        local tn = FGM.State.SelectedTarget
        if not tn or tn == "" then
            notify("nLhe", "Select a target first!", 3)
            return
        end
        local targetPlayer = Players:FindFirstChild(tn)
        if not targetPlayer then
            notify("nLhe", "Target not found!", 3)
            return
        end
        local targetChar = targetPlayer.Character
        if not targetChar then
            notify("nLhe", "Target has no character!", 3)
            return
        end
        if not targetChar:FindFirstChild('Torso') then
            notify("nLhe", "Target has no Torso!", 3)
            return
        end

        local MyCharacter = FGM.GetCharacter(plr)
        if not MyCharacter then
            notify("nLhe", "You have no character!", 3)
            return
        end

        local myHRP = MyCharacter:FindFirstChild("HumanoidRootPart")
        if myHRP then
            FGM.State.SavedPosition = myHRP.CFrame
        end

        local bringSuccess = FGM.BringTargetToMe(targetPlayer)
        if not bringSuccess then
            notify("nLhe", "Failed to bring target!", 3)
            return
        end
        task.wait(0.2)

        targetChar = targetPlayer.Character
        if not targetChar then
            notify("nLhe", "Target character lost!", 3)
            return
        end

        local state = FGM.State
        state.TargetCharacter = targetChar
        state.TargetPlayer = targetPlayer
        state.FigureGrabEnabled = true
        state.ActiveNetworkTarget = targetChar:FindFirstChild("HumanoidRootPart")
        FGM.Configuration.LineDistance = 5

        SetupBodyParts(targetChar)
        FGM.StartPersistentGrab()
        FGM.WatchForRespawn(targetPlayer)
        FGM.WatchForRejoin(targetPlayer)
        RunHeartbeat(MyCharacter)

        if state.HighlightedLimb then
            FGM.ApplyLimbHighlight(state.HighlightedLimb)
        end
        if state.AutoRagdollToggle then
            FGM.ToggleAutoRagdoll(true)
        end

        notify("nLhe", "Figure Grab enabled on " .. targetPlayer.DisplayName, 3)

    else
        local state = FGM.State
        if state.FlingOnReleaseEnabled and state.TargetCharacter then
            local targetHRP = state.TargetCharacter:FindFirstChild("HumanoidRootPart")
            local myChar = FGM.GetCharacter(plr)
            local myHRP = myChar and myChar:FindFirstChild("HumanoidRootPart")
            if targetHRP and myHRP then
                local flingDir = (targetHRP.Position - myHRP.Position)
                if flingDir.Magnitude > 0 then
                    flingDir = flingDir.Unit
                end
                pcall(function()
                    targetHRP.AssemblyLinearVelocity = flingDir * state.FlingForce
                end)
            end
        end

        FGM.JumpAndReturn()
        FGM.ClearLimbHighlight()
        FGM.StopPersistentGrab()
        state.FigureGrabEnabled = false
        state.AnimationCopyEnabled = false
        state.SmoothedCFrames = {}
        state.FrozenCFrames = {}
        state.SpinAngle = 0
        state.OscillateTimer = 0
        state.DistanceTPInProgress = false
        state.ActiveNetworkTarget = nil
        FGM.ToggleAutoRagdoll(false)

        if state.FigureGrabConnection then
            pcall(function() state.FigureGrabConnection:Disconnect() end)
            state.FigureGrabConnection = nil
        end
        if state.RespawnConnection then
            pcall(function() state.RespawnConnection:Disconnect() end)
            state.RespawnConnection = nil
        end
        if state.RejoinConnection then
            pcall(function() state.RejoinConnection:Disconnect() end)
            state.RejoinConnection = nil
        end

        state.TargetCharacter = nil
        state.TargetPlayer = nil
        state.LastGrabTargetRef = nil

        notify("nLhe", "Figure Grab disabled", 3)
    end
end

-- ==========================================
-- 10.5. UI ДЛЯ FIGURE GRAB
-- ==========================================

-- Target Selection
local figTargetDropdown = FigureGroup:AddDropdown("FG_TargetPlayer", {
    Name = "Select Target",
    Values = FGM.GetPlayerList(),
    Default = 1,
    Callback = function(v)
        FGM.State.SelectedTarget = FGM.GetUsernameFromFormatted(v)
    end
})

Players.PlayerAdded:Connect(function()
    task.wait(0.5)
    pcall(function() figTargetDropdown:SetValues(FGM.GetPlayerList()) end)
end)

Players.PlayerRemoving:Connect(function()
    task.wait(0.3)
    pcall(function() figTargetDropdown:SetValues(FGM.GetPlayerList()) end)
end)

FigureGroup:AddButton({
    Name = "Refresh Target List",
    Callback = function()
        pcall(function() figTargetDropdown:SetValues(FGM.GetPlayerList()) end)
    end
})

FigureGroup:AddDivider()

-- Main Toggle
FigureGroup:AddToggle("FG_EnableToggle", {
    Name = "Enable Figure Grab",
    Default = false,
    Callback = function(v)
        if v then
            if not FGM.State.SelectedTarget or FGM.State.SelectedTarget == "" then
                pcall(function() Toggles.FG_EnableToggle:SetValue(false) end)
                notify("nLhe", "Select a target first!", 3)
                return
            end
            FGM.ToggleFigureGrab()
        else
            if FGM.State.FigureGrabEnabled then
                FGM.ToggleFigureGrab()
            end
        end
        notify("nLhe", "Figure Grab: " .. (v and "ON" or "OFF"), 2)
    end
})

FigureGroup:AddToggle("FG_AutoRagdoll", {
    Name = "Auto Ragdoll Target",
    Default = false,
    Callback = function(v)
        FGM.State.AutoRagdollToggle = v
        if FGM.State.FigureGrabEnabled then
            FGM.ToggleAutoRagdoll(v)
        end
        notify("nLhe", "Auto Ragdoll: " .. (v and "ON" or "OFF"), 2)
    end
})

FigureGroup:AddDivider()
FigureGroup:AddLabel("<b>Behaviour</b>")

FigureGroup:AddToggle("FG_AnimCopy", {
    Name = "Mirror My Animations",
    Default = false,
    Callback = function(v)
        FGM.SetAnimationCopy(v)
        notify("nLhe", "Mirror Animations: " .. (v and "ON" or "OFF"), 2)
    end
})

FigureGroup:AddToggle("FG_DampingEnabled", {
    Name = "Smooth Movement",
    Default = true,
    Callback = function(v)
        FGM.Configuration.DampingEnabled = v
        if not v then
            FGM.State.SmoothedCFrames = {}
        end
        notify("nLhe", "Smooth Movement: " .. (v and "ON" or "OFF"), 2)
    end
})

FigureGroup:AddSlider("FG_DampingSpeed", {
    Name = "Damping Speed",
    Default = 12,
    Min = 1,
    Max = 60,
    Rounding = 0,
    Callback = function(v)
        FGM.Configuration.DampingSpeed = v
    end
})

FigureGroup:AddDivider()
FigureGroup:AddLabel("<b>Physics</b>")

FigureGroup:AddToggle("FG_VelSuppress", {
    Name = "Zero All Velocities",
    Default = false,
    Callback = function(v)
        FGM.State.VelSuppressEnabled = v
        notify("nLhe", "Zero Velocities: " .. (v and "ON" or "OFF"), 2)
    end
})

FigureGroup:AddToggle("FG_LockRotation", {
    Name = "Lock Torso Rotation",
    Default = false,
    Callback = function(v)
        FGM.State.LockRotationEnabled = v
        notify("nLhe", "Lock Rotation: " .. (v and "ON" or "OFF"), 2)
    end
})

FigureGroup:AddToggle("FG_ForceUpright", {
    Name = "Keep Target Upright",
    Default = false,
    Callback = function(v)
        FGM.State.ForceUprightEnabled = v
        notify("nLhe", "Keep Upright: " .. (v and "ON" or "OFF"), 2)
    end
})

FigureGroup:AddToggle("FG_ForceLookAt", {
    Name = "Face Toward Me",
    Default = false,
    Callback = function(v)
        FGM.State.ForceLookAtEnabled = v
        notify("nLhe", "Face Toward Me: " .. (v and "ON" or "OFF"), 2)
    end
})

FigureGroup:AddToggle("FG_HoldAtCamera", {
    Name = "Anchor to Camera",
    Default = false,
    Callback = function(v)
        FGM.State.HoldAtCameraEnabled = v
        notify("nLhe", "Anchor to Camera: " .. (v and "ON" or "OFF"), 2)
    end
})

FigureGroup:AddDivider()
FigureGroup:AddLabel("<b>Motion</b>")

FigureGroup:AddToggle("FG_Spin", {
    Name = "Spin Target",
    Default = false,
    Callback = function(v)
        FGM.State.SpinEnabled = v
        FGM.State.SpinAngle = 0
        notify("nLhe", "Spin Target: " .. (v and "ON" or "OFF"), 2)
    end
})

FigureGroup:AddSlider("FG_SpinSpeed", {
    Name = "Spin Speed",
    Default = 180,
    Min = 10,
    Max = 720,
    Rounding = 0,
    Callback = function(v)
        FGM.State.SpinSpeed = v
    end
})

FigureGroup:AddDivider()

FigureGroup:AddToggle("FG_Oscillate", {
    Name = "[FLOAT] Oscillate",
    Default = false,
    Callback = function(v)
        FGM.State.OscillateEnabled = v
        FGM.State.OscillateTimer = 0
        notify("nLhe", "Oscillate: " .. (v and "ON" or "OFF"), 2)
    end
})

FigureGroup:AddSlider("FG_OscillateSpeed", {
    Name = "Float Speed",
    Default = 2,
    Min = 1,
    Max = 10,
    Rounding = 1,
    Callback = function(v)
        FGM.State.OscillateSpeed = v
    end
})

FigureGroup:AddSlider("FG_OscillateAmount", {
    Name = "Float Distance",
    Default = 3,
    Min = 1,
    Max = 20,
    Rounding = 1,
    Callback = function(v)
        FGM.State.OscillateAmount = v
    end
})

FigureGroup:AddDivider()
FigureGroup:AddLabel("<b>Limb Control</b>")

FigureGroup:AddDropdown("FG_LimbSelector", {
    Name = "Select Limb",
    Values = LIMB_OPTIONS,
    Default = "Head",
    Callback = function(v)
        FGM.State.SelectedLimb = v
        FGM.ApplyLimbHighlight(v)
    end
})

local function updateLimb(section, axis, value)
    FGM.UpdateConfig(section, axis, value)
end

FigureGroup:AddSlider("FG_LimbPosX", {
    Name = "Left / Right",
    Default = 0,
    Min = -50,
    Max = 50,
    Rounding = 1,
    Callback = function(v)
        local sec = GetActiveSections()
        updateLimb(sec.pos, 'X', v)
    end
})

FigureGroup:AddSlider("FG_LimbPosY", {
    Name = "Up / Down",
    Default = 0,
    Min = -50,
    Max = 50,
    Rounding = 1,
    Callback = function(v)
        local sec = GetActiveSections()
        updateLimb(sec.pos, 'Y', v)
    end
})

FigureGroup:AddSlider("FG_LimbPosZ", {
    Name = "Forward / Back",
    Default = -5,
    Min = -50,
    Max = 50,
    Rounding = 1,
    Callback = function(v)
        local sec = GetActiveSections()
        updateLimb(sec.pos, 'Z', v)
    end
})

FigureGroup:AddDivider()
FigureGroup:AddLabel("<b>Rotation</b>")

FigureGroup:AddSlider("FG_LimbRotX", {
    Name = "Pitch (Up / Down)",
    Default = 0,
    Min = 0,
    Max = 360,
    Rounding = 0,
    Callback = function(v)
        local sec = GetActiveSections()
        updateLimb(sec.rot, 'X', v)
    end
})

FigureGroup:AddSlider("FG_LimbRotY", {
    Name = "Yaw (Left / Right)",
    Default = 0,
    Min = 0,
    Max = 360,
    Rounding = 0,
    Callback = function(v)
        local sec = GetActiveSections()
        updateLimb(sec.rot, 'Y', v)
    end
})

FigureGroup:AddSlider("FG_LimbRotZ", {
    Name = "Roll (Tilt)",
    Default = 0,
    Min = 0,
    Max = 360,
    Rounding = 0,
    Callback = function(v)
        local sec = GetActiveSections()
        updateLimb(sec.rot, 'Z', v)
    end
})

FigureGroup:AddDivider()
FigureGroup:AddLabel("<b>Poses</b>")

FigureGroup:AddDropdown("FG_PresetPose", {
    Name = "Select Pose",
    Values = {"Pose1", "Pose2", "Pose3", "Pose4", "Pose5", "Pose6", "Pose7", "JojoStand"},
    Default = "Pose1",
    Callback = function(v)
        int.FG_Pose = v
    end
})

FigureGroup:AddButton({
    Name = "Apply Pose",
    Callback = function()
        if int.FG_Pose then
            FGM.ApplyPreset(int.FG_Pose)
            notify("nLhe", "Pose applied: " .. int.FG_Pose, 2)
        end
    end
})

FigureGroup:AddButton({
    Name = "Reset to Default Pose",
    Callback = function()
        FGM.ResetPose()
        notify("nLhe", "Pose reset to default", 2)
    end
})

FigureGroup:AddDivider()
FigureGroup:AddLabel("<b>Actions</b>")

FigureGroup:AddButton({
    Name = "Freeze Limbs",
    Callback = function()
        local state = FGM.State
        local target = state.TargetCharacter
        state.FrozenCFrames = {}
        if not target then
            notify("nLhe", "No target grabbed!", 3)
            return
        end
        for _, name in ipairs({'Head', 'Left Arm', 'Right Arm', 'Left Leg', 'Right Leg'}) do
            local part = target:FindFirstChild(name)
            if part then
                state.FrozenCFrames[name] = part.CFrame
            end
        end
        state.FreezeLimbsEnabled = true
        notify("nLhe", "Limbs frozen!", 2)
    end
})

FigureGroup:AddButton({
    Name = "Unfreeze Limbs",
    Callback = function()
        FGM.State.FreezeLimbsEnabled = false
        FGM.State.FrozenCFrames = {}
        notify("nLhe", "Limbs unfrozen!", 2)
    end
})

FigureGroup:AddButton({
    Name = "Release Target",
    Callback = function()
        if FGM.State.FigureGrabEnabled then
            FGM.ToggleFigureGrab()
        else
            notify("nLhe", "Nothing is currently grabbed", 3)
        end
    end
})

_G.nLhe.notify("nLhe", "nLhe Loaded", 3)
print("nLhe Loaded!")
