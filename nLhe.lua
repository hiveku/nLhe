-- nlhe
-- https://t.me/nLheNews

print("[nLhe] Начинаем загрузку...")
repo = "https://raw.githubusercontent.com/deividcomsono/Obsidian/refs/heads/main/"
-- === ОПТИМИЗАЦИЯ ЗАГРУЗКИ: все 3 HTTP-запроса параллельно ===
Library, ThemeManager, SaveManager = nil, nil, nil
libDone, themeDone, saveDone = false, false, false
task.spawn(function()
 print("[nLhe] Скачиваем Library с GitHub...")
 local success, res = pcall(function() return loadstring(game:HttpGet(repo .. "Library.lua"))() end)
 if success then 
 Library = res
 libDone = true
 print("[nLhe] Library успешно скачана!")
 else
 warn("[nLhe] ОШИБКА загрузки Library: " .. tostring(res))
 end
end)
task.spawn(function()
 local success, res = pcall(function()
  return loadstring(game:HttpGet(repo .. "addons/ThemeManager.lua"))()
 end)
 if success then
  ThemeManager = res
  themeDone = true
  print("[nLhe] ThemeManager успешно скачан!")
 else
  warn("[nLhe] Не удалось загрузить ThemeManager: " .. tostring(res))
 end
end)
task.spawn(function()
 local success, res = pcall(function()
  return loadstring(game:HttpGet(repo .. "addons/SaveManager.lua"))()
 end)
 if success then
  SaveManager = res
  saveDone = true
  print("[nLhe] SaveManager успешно скачан!")
 else
  warn("[nLhe] Не удалось загрузить SaveManager: " .. tostring(res))
 end
end)
-- Ждём только Library
t0 = tick()
while not libDone do
 if tick() - t0 > 30 then 
 warn("[nLhe] ТАЙМАУТ: Библиотека не скачалась за 30 секунд!")
 break 
 end
 task.wait(0.05)
end

if not Library then
 warn("[nLhe] КРИТИЧЕСКАЯ ОШИБКА: Library = nil. Скрипт остановлен.")
 return
end
print("[nLhe] Создаем главное окно...")
Players = game:GetService("Players")
RunService = game:GetService("RunService")
LocalPlayer = Players.LocalPlayer

UserInputService = game:GetService("UserInputService")
Window = Library:CreateWindow({
 Title = "nLhe",
 Footer = "nLhe by hiveku",
  Icon = 9013498700,
 Center = true,
 AutoShow = true,
 Resizable = true,
 NotifySide = "Right",
 ShowCustomCursor = true,
 NoLabels = true,              
 EnableCompacting = true,      
 SidebarCompacted = true,      
})
Tabs = {
 Def = Window:AddTab("Def", "shield"),
 Target = Window:AddTab("Target", "target"),
 Visual = Window:AddTab("Visual", "eye"),
 Server = Window:AddTab("Server", "atom"),
 Settings = Window:AddTab("Settings", "settings")
}

Toggles = Library.Toggles
Options = Library.Options

-- ==============================================
-- СЕРВИСЫ И ПЕРЕМЕННЫЕ
-- ==============================================

local Players = game:GetService("Players")
local UIS = game:GetService("UserInputService")
local CoreGui = game:GetService("CoreGui")
local RS = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")
local Lighting = game:GetService("Lighting")
local TweenService = game:GetService("TweenService")
local Stats = game:GetService("Stats")
local Debris = game:GetService("Debris")
local HttpService = game:GetService("HttpService")

local plr = Players.LocalPlayer
local char = plr.Character or plr.CharacterAdded:Wait()
local hum = char:FindFirstChild("Humanoid") or char:WaitForChild("Humanoid")
local hrp = char:FindFirstChild("HumanoidRootPart") or char:WaitForChild("HumanoidRootPart")
local head = char:FindFirstChild("Head") or char:WaitForChild("Head")

-- Ремуты
local SetNetworkOwner = RS.GrabEvents:FindFirstChild("SetNetworkOwner") or RS.GrabEvents:WaitForChild("SetNetworkOwner")
local StickyEvent = RS.PlayerEvents:FindFirstChild("StickyPartEvent") or RS.PlayerEvents:WaitForChild("StickyPartEvent")
local DestroyToy = RS.MenuToys:FindFirstChild("DestroyToy") or RS.MenuToys:WaitForChild("DestroyToy")
local Struggle = RS.CharacterEvents:FindFirstChild("Struggle") or RS.CharacterEvents:WaitForChild("Struggle")
local CreateGrabLine = RS.GrabEvents:FindFirstChild("CreateGrabLine") or RS.GrabEvents:WaitForChild("CreateGrabLine")
local SpawnToyRemote = RS.MenuToys:FindFirstChild("SpawnToyRemoteFunction") or RS.MenuToys:WaitForChild("SpawnToyRemoteFunction")
local DestroyGrabLine = RS.GrabEvents:FindFirstChild("DestroyGrabLine") or RS.GrabEvents:WaitForChild("DestroyGrabLine")
local RagdollRemote = RS.CharacterEvents:FindFirstChild("RagdollRemote") or RS.CharacterEvents:WaitForChild("RagdollRemote")

local bool = {}
local int = {}
local cons = {}
local etc = {
    InPlot = false,
    InOwnedPlot = false,
    OwnedPlot = nil,
    SelectedTarget = nil,
}

local function discCon(key)
    if cons[key] then cons[key]:Disconnect(); cons[key] = nil end
end

local function notify(title, content)
    warn("[nLhe] " .. title .. ": " .. content)
end

local function GetMagnitude(a, b)
    return (a.Position - b.Position).Magnitude
end

local function sno(part)
    pcall(function() SetNetworkOwner:FireServer(part, part.CFrame) end)
end

local function unsno(part)
    pcall(function() DestroyGrabLine:FireServer(part) end)
end

local function isnetworkowner(part)
    local ok, r = pcall(function() return part:GetNetworkOwner() == plr end)
    return ok and r
end

local function StopAllVelocity(obj)
    for _, v in pairs(obj:GetDescendants()) do
        if v:IsA("BasePart") then
            v.AssemblyLinearVelocity = Vector3.zero
            v.AssemblyAngularVelocity = Vector3.zero
        end
    end
end

-- Обновление InPlot
local function UpdateInPlot()
    local char = plr.Character
    local hrp = char and char:FindFirstChild("HumanoidRootPart")
    if not hrp then etc.InPlot = false; return end
    local plotsFolder = Workspace:FindFirstChild("Plots")
    if not plotsFolder then etc.InPlot = false; return end
    etc.InPlot = false
    etc.InOwnedPlot = false
    etc.OwnedPlot = nil
    for _, plot in pairs(plotsFolder:GetChildren()) do
        local plotArea = plot:FindFirstChild("PlotArea")
        if plotArea and plotArea:IsA("BasePart") then
            local dist = (hrp.Position - plotArea.Position).Magnitude
            if dist < 15 then
                etc.InPlot = true
                local plotSign = plot:FindFirstChild("PlotSign")
                if plotSign then
                    local owners = plotSign:FindFirstChild("ThisPlotsOwners")
                    if owners then
                        for _, owner in pairs(owners:GetChildren()) do
                            if owner:IsA("StringValue") and owner.Value == plr.Name then
                                etc.InOwnedPlot = true
                                etc.OwnedPlot = plot
                                break
                            end
                        end
                    end
                end
                break
            end
        end
    end
end

cons["InPlotUpdate"] = RunService.Heartbeat:Connect(UpdateInPlot)

-- ==============================================
-- ВКЛАДКА DEFENSE
-- ==============================================

local DefGroup = Tabs.Def:AddLeftGroupbox("Защиты", "shield")

-- Анти-граб V2
DefGroup:AddToggle("Anti_Grab_V2", {
    Text = "Anti Grab V2",
    Default = false,
    Callback = function(state)
        bool.AntiGrabV2 = state
        if state then
            cons["AntiGrabV2_Held"] = plr:WaitForChild("IsHeld"):GetPropertyChangedSignal("Value"):Connect(function()
                if not bool.AntiGrabV2 or not plr.IsHeld.Value then return end
                local char = plr.Character
                if not char then return end
                local root = char:FindFirstChild("HumanoidRootPart")
                local hum = char:FindFirstChild("Humanoid")
                if not root or not hum then return end
                for _, part in pairs(char:GetDescendants()) do
                    if part:IsA("BasePart") then part.CanCollide = false end
                end
                task.spawn(function()
                    while bool.AntiGrabV2 and plr.IsHeld.Value do
                        pcall(function()
                            Struggle:FireServer()
                            RagdollRemote:FireServer(root, 0)
                            RS.GameCorrectionEvents.StopAllVelocity:FireServer()
                            hum.Sit = false
                            hum:ChangeState(Enum.HumanoidStateType.GettingUp)
                            if root then
                                root.Anchored = true
                                root.AssemblyLinearVelocity = Vector3.zero
                                root.AssemblyAngularVelocity = Vector3.zero
                            end
                        end)
                        task.wait()
                    end
                    if root then root.Anchored = false end
                end)
            end)
        else
            discCon("AntiGrabV2_Held")
            local char = plr.Character
            if char then
                for _, part in pairs(char:GetDescendants()) do
                    if part:IsA("BasePart") then part.CanCollide = true end
                end
                local root = char:FindFirstChild("HumanoidRootPart")
                if root then root.Anchored = false end
            end
        end
    end
})

-- Anti Grab ULTIMATE (V2 + XOCU combined)
DefGroup:AddToggle("Anti_Grab_ULTIMATE", {
    Text = "Anti Grab ULTIMATE",
    Default = false,
    Tooltip = "Anti-Grab best",
    Callback = function(state)
        bool.AntiGrabULTIMATE = state
        if state then
            cons["AntiGrabULTIMATE_Held"] = plr:WaitForChild("IsHeld"):GetPropertyChangedSignal("Value"):Connect(function()
                if not bool.AntiGrabULTIMATE or not plr.IsHeld.Value then return end
                local char = plr.Character
                if not char then return end
                local root = char:FindFirstChild("HumanoidRootPart")
                local hum = char:FindFirstChild("Humanoid")
                if not root or not hum then return end
                
                -- Отключаем коллизию всех частей тела
                for _, part in pairs(char:GetDescendants()) do
                    if part:IsA("BasePart") then
                        part.CanCollide = false
                    end
                end
                root.Anchored = true
                
                task.spawn(function()
                    while bool.AntiGrabULTIMATE and plr.IsHeld.Value do
                        pcall(function()
                            -- Struggle (из XOCU — с передачей plr)
                            Struggle:FireServer(plr)
                            -- Рагдолл
                            RagdollRemote:FireServer(root, 0)
                            -- Остановка всей скорости
                            RS.GameCorrectionEvents.StopAllVelocity:FireServer()
                            -- Снимаем сидение и встаём
                            hum.Sit = false
                            hum:ChangeState(Enum.HumanoidStateType.GettingUp)
                            -- Включаем прыжок (из XOCU)
                            hum:SetStateEnabled(Enum.HumanoidStateType.Jumping, true)
                            -- Обнуляем скорость
                            root.AssemblyLinearVelocity = Vector3.zero
                            root.AssemblyAngularVelocity = Vector3.zero
                        end)
                        task.wait()
                    end
                    
                    -- Возвращаем всё как было
                    if root then
                        root.Anchored = false
                        for _, part in pairs(char:GetDescendants()) do
                            if part:IsA("BasePart") then
                                part.CanCollide = true
                            end
                        end
                    end
                end)
            end)
        else
            discCon("AntiGrabULTIMATE_Held")
            local char = plr.Character
            if char then
                for _, part in pairs(char:GetDescendants()) do
                    if part:IsA("BasePart") then
                        part.CanCollide = true
                    end
                end
                local root = char:FindFirstChild("HumanoidRootPart")
                if root then
                    root.Anchored = false
                end
            end
        end
    end
})

-- ==============================================
-- GUCCI ANTI GRAB
-- ==============================================
local gucciRunId = 0
local gucciActive = false
local gucciTask = nil
local checkGucciSeatTask = nil

local function FWC(Parent, Name, Time)
    return Parent:FindFirstChild(Name) or Parent:WaitForChild(Name, Time or 3)
end

local function toy_spawn_gucci(name, cframe, vector)
    local ToySpawn = RS.MenuToys.SpawnToyRemoteFunction
    local InPlot = plr:FindFirstChild("InPlot")
    local InOwnedPlot = plr:FindFirstChild("InOwnedPlot")
    local CanSpawn = plr:FindFirstChild("CanSpawnToy")

    while InPlot and InPlot.Value and not (InOwnedPlot and InOwnedPlot.Value) and not (CanSpawn and CanSpawn.Value) do
        task.wait(0.01)
    end

    task.spawn(function()
        ToySpawn:InvokeServer(name, cframe, vector or Vector3.new())
    end)
    
    local BackPack = Workspace:FindFirstChild(plr.Name .. 'SpawnedInToys')
    local SpawnedToy
    BackPack.ChildAdded:Once(function(toy)
        if toy.Name == name and toy:IsA("Model") then
            SpawnedToy = toy
        end
    end)
    
    local time = tick()
    while not SpawnedToy do
        if tick() - time < 2 then
            task.wait(0.01)
        else
            return false
        end
    end
    return SpawnedToy
end

local function GucciAntiGrab()
    if not gucciActive then return end
    
    gucciRunId = gucciRunId + 1
    local MyId = gucciRunId
    
    local char = plr.Character or plr.CharacterAdded:Wait()
    local hum = FWC(char, "Humanoid")
    
    hum.Sit = true
    task.wait(0.02)
    hum.Sit = false
    task.wait(0.02)
    
    task.spawn(function()
        local time = tick()
        while tick() - time < 0.8 do
            for _, v in pairs(char:GetChildren()) do
                if v:IsA('BasePart') then
                    v.Velocity = Vector3.new()
                end
            end
            task.wait(0.01)
        end
    end)
    
    local autoGucciT, sitJumpT, Blob, BHead = true, false, nil, nil
    
    task.spawn(function()
        while not Blob and MyId == gucciRunId do
            task.wait(0.01)
        end
        if MyId ~= gucciRunId then return end
        
        BHead = FWC(Blob, "Head")
        local HitBox = FWC(Blob, "GrabbableHitbox")
        
        while MyId == gucciRunId and BHead and
        (not BHead:FindFirstChild("PartOwner") or BHead.PartOwner.Value ~= plr.Name) do
            if HitBox then
                SetNetworkOwner:FireServer(HitBox, HitBox.CFrame)
            end
            task.wait(0.01)
        end
    end)
    
    local hrp = FWC(char, "HumanoidRootPart")
    Blob = toy_spawn_gucci(
        "CreatureBlobman",
        hrp.CFrame * CFrame.new(0, 0, -5),
        Vector3.new(0, -15.716, 0)
    )
    
    if not Blob then return end
    
    local Seat = FWC(Blob, "VehicleSeat")
    
    task.defer(function()
        if not(char or hum) then return end
        
        local startTime = tick()
        while autoGucciT and MyId == gucciRunId and tick() - startTime < 0.3 do
            if Blob and Blob.Parent then
                if Seat and Seat.Parent and Seat.Occupant ~= hum then
                    Seat:Sit(hum)
                end
            end
            task.wait(0.03)
            if char and hum and hum.Parent then
                hum:ChangeState(Enum.HumanoidStateType.Jumping)
            end
            task.wait(0.03)
        end
        autoGucciT = false
        sitJumpT = false
    end)
    
    sitJumpT = true
    
    task.defer(function()
        while sitJumpT and MyId == gucciRunId do
            if char and hrp and hrp.Parent then
                RagdollRemote:FireServer(hrp, 0.095)
            end
            task.wait(0.01)
        end
    end)
    
    task.wait(0.4)
    
    if MyId ~= gucciRunId then return end
    
    hum.Sit = false
    Blob.Name = "Gucci"
    
    local BackPack = Workspace:FindFirstChild(plr.Name .. 'SpawnedInToys')
    local index
    for i, v in pairs(BackPack:GetChildren()) do
        if v.Name == "Gucci" then
            index = i
            break
        end
    end
    
    for _, v in pairs(Blob:GetChildren()) do
        if v:IsA("BasePart") then
            v.CanCollide = false
            v.CanTouch = false
            v.CanQuery = false
        end
    end
    
    task.defer(function()
        while MyId == gucciRunId and Blob and BHead do
            BHead.CFrame = CFrame.new(BHead.Position.X, 1e5, BHead.Position.Z)
            task.wait(0.01)
        end
    end)
    
    local success, contents = pcall(function()
        return plr.PlayerGui.MenuGui.Menu.TabContents.ToyDestroy.Contents
    end)
    
    if success and contents and index then
        for i, v in ipairs(contents:GetChildren()) do
            if v.Name == "CreatureBlobman" and i == index then
                local view = v.ViewItemButton
                view.Text = "GUCCI"
                view.TextScaled = true
                view.LowResImage.Image = ""
            end
        end
    end
end

DefGroup:AddToggle("GucciAntiGrab", {
    Text = "Gucci Anti Grab",
    Default = false,
    Tooltip = "ыаыаыаыаы гучи",
    Callback = function(Value)
        gucciActive = Value
        
        if gucciTask then
            task.cancel(gucciTask)
            gucciTask = nil
        end
        if checkGucciSeatTask then
            task.cancel(checkGucciSeatTask)
            checkGucciSeatTask = nil
        end
        
        if not Value then
            local BackPack = Workspace:FindFirstChild(plr.Name .. 'SpawnedInToys')
            if BackPack then
                local gucci = BackPack:FindFirstChild("Gucci")
                if gucci then
                    pcall(function()
                        DestroyToy:FireServer(gucci)
                    end)
                end
                for _, v in pairs(BackPack:GetChildren()) do
                    if v.Name == "Gucci" or v.Name == "CreatureBlobman" then
                        pcall(function()
                            DestroyToy:FireServer(v)
                        end)
                    end
                end
            end
            return
        end
        
        gucciTask = task.spawn(function()
            while gucciActive do
                local BackPack = Workspace:FindFirstChild(plr.Name .. 'SpawnedInToys')
                local gucci = BackPack and BackPack:FindFirstChild("Gucci")
                
                if not gucci then
                    GucciAntiGrab()
                end
                task.wait(0.5)
            end
        end)
        
        checkGucciSeatTask = task.spawn(function()
            while gucciActive do
                local char = plr.Character
                local hum = char and char:FindFirstChild("Humanoid")
                
                if hum and hum.SeatPart then
                    local seatParent = hum.SeatPart.Parent
                    if seatParent and (seatParent.Name == "Gucci" or seatParent.Name == "CreatureBlobman") then
                        local isOurGucci = false
                        local BackPack = Workspace:FindFirstChild(plr.Name .. 'SpawnedInToys')
                        if BackPack then
                            for _, v in pairs(BackPack:GetChildren()) do
                                if v == seatParent then
                                    isOurGucci = true
                                    break
                                end
                            end
                        end
                        
                        if isOurGucci then
                            pcall(function()
                                DestroyToy:FireServer(seatParent)
                            end)
                            task.wait(0.2)
                            
                            if gucciActive then
                                GucciAntiGrab()
                            end
                        end
                    end
                end
                
                task.wait(0.3)
            end
        end)
    end
})

-- ==============================================
-- AUTO GUCCI (TRAIN)
-- ==============================================
local autoGucciActive = false
local autoGucciTask = nil
local trainLoopConnection = nil
local trainJumpCounter = 0
local trainRootPos = nil

local function stopTrainRide()
    if trainLoopConnection then
        trainLoopConnection:Disconnect()
        trainLoopConnection = nil
    end
end

local function initTrainRide()
    local runService = RunService
    local character = plr.Character or plr.CharacterAdded:Wait()
    local humanoid = character:WaitForChild('Humanoid')
    local rootPart = character:WaitForChild('HumanoidRootPart')
    trainRootPos = rootPart.Position
    
    local trainObject = Workspace:FindFirstChild("Map")
    if trainObject then
        trainObject = trainObject:FindFirstChild("AlwaysHereTweenedObjects")
    end
    local train = trainObject and trainObject:FindFirstChild('Train')
    local trainSeat = nil
    
    if train then
        for _, descendant in ipairs(train:GetDescendants()) do
            if descendant:IsA('Seat') then
                trainSeat = descendant
                break
            end
        end
    end
    
    if not train or not trainSeat then
        return
    end
    
    rootPart.CFrame = trainSeat.CFrame + Vector3.new(0, 2, 0)
    trainSeat:Sit(humanoid)
    
    humanoid:GetPropertyChangedSignal('Jump'):Connect(function()
        if (humanoid.Jump and humanoid.Sit) then
            trainJumpCounter = 15
            trainRootPos = rootPart.Position
        end
    end)
    
    if trainLoopConnection then
        trainLoopConnection:Disconnect()
    end
    
    trainLoopConnection = runService.Heartbeat:Connect(function()
        if (not rootPart or not humanoid) then
            return
        end
        pcall(function()
            RagdollRemote:FireServer(rootPart, 0)
        end)
        if (trainJumpCounter > 0) then
            rootPart.CFrame = CFrame.new(trainRootPos)
            trainJumpCounter = trainJumpCounter - 1
        end
    end)
    
    task.spawn(function()
        while humanoid.Sit do
            task.wait(1)
        end
        task.wait(0.5)
        rootPart.CFrame = CFrame.new(trainRootPos)
    end)
end

DefGroup:AddToggle("AutoGucciTrain", {
    Text = "Auto Gucci (Train)",
    Default = false,
    Tooltip = "такое же гучи, но на поезде",
    Callback = function(Value)
        autoGucciActive = Value
        
        if Value then
            initTrainRide()
            
            autoGucciTask = task.spawn(function()
                while autoGucciActive do
                    pcall(function()
                        local trainObject = Workspace:FindFirstChild("Map")
                        if trainObject then
                            trainObject = trainObject:FindFirstChild("AlwaysHereTweenedObjects")
                        end
                        local train = trainObject and trainObject:FindFirstChild('Train')
                        
                        if not train then
                            stopTrainRide()
                            local attempts = 0
                            repeat
                                task.wait(0.2)
                                attempts = attempts + 1
                                trainObject = Workspace:FindFirstChild("Map")
                                if trainObject then
                                    trainObject = trainObject:FindFirstChild("AlwaysHereTweenedObjects")
                                end
                            until (trainObject and trainObject:FindFirstChild('Train')) or (attempts > 25) or not autoGucciActive
                            
                            if (autoGucciActive and trainObject and trainObject:FindFirstChild('Train')) then
                                initTrainRide()
                            end
                        end
                    end)
                    task.wait(0.5)
                end
            end)
        else
            autoGucciActive = false
            stopTrainRide()
            
            if autoGucciTask then
                task.cancel(autoGucciTask)
                autoGucciTask = nil
            end
        end
    end
})

-- ==============================================
-- ANTI OWNERSHIP
-- ==============================================
local antiOwnershipActive = false
local antiOwnershipTask = nil

DefGroup:AddToggle("AntiOwnership", {
    Text = "Anti Ownership",
    Default = false,
    Tooltip = "типа защита от овнершипа что еще сказать ( может не работать, не тестил)",
    Callback = function(Value)
        antiOwnershipActive = Value
        if Value then
            antiOwnershipTask = task.spawn(function()
                local Struggle = RS.CharacterEvents.Struggle
                while antiOwnershipActive do
                    pcall(function()
                        local character = plr.Character
                        if character and character:FindFirstChild("Head") then
                            local head = character.Head
                            if head:FindFirstChild("PartOwner") then
                                Struggle:FireServer(plr)
                                for _, part in pairs(character:GetChildren()) do
                                    if part:IsA("BasePart") then
                                        part.Anchored = true
                                    end
                                end
                                local isHeld = plr:FindFirstChild("IsHeld")
                                while isHeld and isHeld.Value and antiOwnershipActive do
                                    task.wait()
                                end
                                for _, part in pairs(character:GetChildren()) do
                                    if part:IsA("BasePart") then
                                        part.Anchored = false
                                    end
                                end
                            end
                        end
                    end)
                    task.wait(0.1)
                end
            end)
        else
            if antiOwnershipTask then
                task.cancel(antiOwnershipTask)
                antiOwnershipTask = nil
            end
            local char = plr.Character
            if char then
                for _, part in pairs(char:GetChildren()) do
                    if part:IsA("BasePart") then
                        part.Anchored = false
                    end
                end
            end
        end
    end
})

-- Anti Banana [SIT]
DefGroup:AddToggle("Anti_Banana_Sit", {
    Text = "Anti Banana [SIT]",
    Default = false,
    Callback = function(state)
        bool.AntiBananaSit = state
        if state then
            cons["AntiBananaSit"] = RunService.Heartbeat:Connect(function()
                if not bool.AntiBananaSit then return end
                local char = plr.Character
                if not char then return end
                local hum = char:FindFirstChild("Humanoid")
                local hrp = char:FindFirstChild("HumanoidRootPart")
                if hum and hrp and hum.Health > 0 then
                    hum.Sit = true
                    hum:ChangeState(Enum.HumanoidStateType.Running)
                    local lookVec = Workspace.CurrentCamera.CFrame.LookVector
                    hrp.CFrame = CFrame.new(hrp.Position, hrp.Position + Vector3.new(lookVec.X, 0, lookVec.Z))
                end
            end)
        else
            discCon("AntiBananaSit")
        end
    end
})

-- Anti Snowball
DefGroup:AddToggle("Anti_Snowball", {
    Text = "Anti Snowball",
    Default = false,
    Callback = function(state)
        bool.AntiSnowball = state
        if state then
            cons["AntiSnowball"] = RunService.Heartbeat:Connect(function()
                if not bool.AntiSnowball then return end
                local char = plr.Character
                local hrp = char and char:FindFirstChild("HumanoidRootPart")
                if hrp then
                    pcall(function() RagdollRemote:FireServer(hrp, 0.5) end)
                end
            end)
        else
            discCon("AntiSnowball")
        end
    end
})

-- Auto Reset (Anti-Flying)
DefGroup:AddToggle("Auto_Reset", {
    Text = "Auto Reset (Anti-Flying)",
    Default = false,
    Callback = function(state)
        bool.AutoReset = state
        if state then
            cons["AutoReset"] = RS.GameCorrectionEvents.GameCorrectionsNotify.OnClientEvent:Connect(function(reason)
                if reason == "Flying" then
                    local char = plr.Character
                    local hum = char and char:FindFirstChild("Humanoid")
                    if hum then
                        char:BreakJoints()
                        hum.Health = 0
                    end
                end
            end)
        else
            discCon("AutoReset")
        end
    end
})

-- Auto Leave
DefGroup:AddToggle("Auto_Leave", {
    Text = "Auto Leave",
    Default = false,
    Callback = function(state)
        bool.AutoLeave = state
        if state then
            local warnTimestamps = {}
            cons["AutoLeave"] = RS.GameCorrectionEvents.GameCorrectionsNotify.OnClientEvent:Connect(function(reason)
                if reason == "Flying" then
                    local currentTime = os.clock()
                    table.insert(warnTimestamps, currentTime)
                    for i = #warnTimestamps, 1, -1 do
                        if currentTime - warnTimestamps[i] > 1 then table.remove(warnTimestamps, i) end
                    end
                    if #warnTimestamps >= 3 then
                        plr:Kick("Auto Leave: Prevented ban")
                    end
                end
            end)
        else
            discCon("AutoLeave")
        end
    end
})

-- Anti Void
DefGroup:AddToggle("Anti_Void", {
    Text = "Anti Void",
    Default = false,
    Callback = function(state)
        bool.AntiVoid = state
        Workspace.FallenPartsDestroyHeight = state and 0/0 or -100
    end
})

-- ==============================================
-- ANTI BLOB
-- ==============================================
local hkABlob = false

DefGroup:AddToggle("AntiBlob", {
    Text = "Anti-Blob",
    Default = false,
    Tooltip = "защита от блоба (выкидывает RootAttachment)",
    Callback = function(Value)
        hkABlob = Value
        task.spawn(function()
            while hkABlob do
                if plr.Character then
                    if not plr.Character:FindFirstChild("TruePositionPart") then
                        local tp = Instance.new("Part")
                        tp.Parent = plr.Character 
                        tp.Name = "TruePositionPart"
                        tp.Anchored = true 
                        tp.CFrame = CFrame.new(0, -100, 0)
                    end
                    for _, prt in pairs(plr.Character:GetChildren()) do
                        if prt:IsA("BasePart") and prt.Massless then 
                            prt.Massless = false 
                        end
                        if prt.Name == "HumanoidRootPart" and plr.Character.HumanoidRootPart:FindFirstChild("RootAttachment") then
                            task.wait() 
                            task.wait() 
                            task.wait() 
                            task.wait() 
                            task.wait()
                            task.wait() 
                            task.wait() 
                            task.wait() 
                            task.wait() 
                            task.wait()
                            if plr.Character and plr.Character:FindFirstChild("HumanoidRootPart") and
                               plr.Character.HumanoidRootPart:FindFirstChild("RootAttachment") and
                               plr.Character:FindFirstChild("TruePositionPart") then
                                plr.Character.HumanoidRootPart.RootAttachment.Parent = plr.Character.TruePositionPart
                            end
                        end
                    end
                end
                task.wait()
            end
        end)
        if not Value and plr.Character then
            if plr.Character:FindFirstChild("HumanoidRootPart") and plr.Character:FindFirstChild("TruePositionPart") then
                if plr.Character.TruePositionPart:FindFirstChild("RootAttachment") then
                    plr.Character.TruePositionPart.RootAttachment.Parent = plr.Character.HumanoidRootPart
                end
            end
        end
    end
})

-- Anti Loop Kill
DefGroup:AddToggle("Anti_Loop_Kill", {
    Text = "Anti Loop Kill",
    Default = false,
    Callback = function(state)
        bool.AntiLoopKill = state
        if state then
            cons["AntiLoopKill"] = plr.CharacterAdded:Connect(function(char)
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
        else
            discCon("AntiLoopKill")
        end
    end
})

-- Auto PCLD Break
DefGroup:AddToggle("Auto_PCLD_Break", {
    Text = "Auto PCLD Break",
    Default = false,
    Callback = function(state)
        bool.AutoPCLDBreak = state
        if state then
            cons["AutoPCLDBreak"] = plr.CharacterAdded:Connect(function(char)
                task.wait(0.1)
                local hrp = char:FindFirstChild("HumanoidRootPart")
                local hum = char:FindFirstChild("Humanoid")
                if hrp and hum then
                    local savedCF = hrp.CFrame
                    hrp.CFrame = CFrame.new(hrp.Position.X, 50000, hrp.Position.Z)
                    task.wait(0.05)
                    hum.Health = 0
                    char:BreakJoints()
                end
            end)
        else
            discCon("AutoPCLDBreak")
        end
    end
})

-- Anti Paint
DefGroup:AddToggle("Anti_Paint", {
    Text = "Anti Paint",
    Default = false,
    Callback = function(state)
        bool.AntiPaint = state
        if state then
            for _, obj in ipairs(Workspace:GetDescendants()) do
                if obj:IsA("BasePart") and obj.Name == "PaintPlayerPart" then obj:Destroy() end
            end
            cons["AntiPaint"] = Workspace.DescendantAdded:Connect(function(obj)
                if bool.AntiPaint and obj:IsA("BasePart") and obj.Name == "PaintPlayerPart" then obj:Destroy() end
            end)
        else
            discCon("AntiPaint")
        end
    end
})

-- Anti Explosion
DefGroup:AddToggle("Anti_Explosion_", {
    Text = "Anti Explosion",
    Default = false,
    Tooltip = "Защита от взрывов",
    Callback = function(state)
        bool.AntiExplode = state
        if state then
            -- Подключаем детекцию взрывов
            cons["AntiExplode"] = Workspace.ChildAdded:Connect(function(model)
                if not bool.AntiExplode then return end
                if model.Name ~= "Part" then return end
                
                local char = plr.Character
                local hrp = char and char:FindFirstChild("HumanoidRootPart")
                if not hrp then return end
                
                pcall(function()
                    local mag = (model.Position - hrp.Position).Magnitude
                    if mag <= 20 then
                        hrp.Anchored = true
                        task.wait(0.01)
                        
                        local rightArm = char:FindFirstChild("Right Arm")
                        if rightArm then
                            local ragdollPart = rightArm:FindFirstChild("RagdollLimbPart")
                            if ragdollPart then
                                while ragdollPart.CanCollide and bool.AntiExplode do
                                    task.wait(0.001)
                                end
                            end
                        end
                        
                        if bool.AntiExplode then
                            hrp.Anchored = false
                        end
                    end
                end)
            end)
        else
            disconnect("AntiExplode")
            local char = plr.Character
            if char then
                local hrp = char:FindFirstChild("HumanoidRootPart")
                if hrp then hrp.Anchored = false end
            end
        end
    end
})

-- Anti Fire
local hkFirePart = nil
local antiFireTask = nil

DefGroup:AddToggle("Anti_Fire", {
    Text = "Anti Fire",
    Default = false,
    Tooltip = "Защита от огня",
    Callback = function(state)
        bool.AntiFire = state
        
        if state then
            pcall(function()
                if Workspace.Plots and Workspace.Plots.Plot5 and Workspace.Plots.Plot5.Barrier then
                    if Workspace.Plots.Plot5.Barrier:FindFirstChild("AntiFirePart") then
                        hkFirePart = Workspace.Plots.Plot5.Barrier.AntiFirePart
                    else
                        hkFirePart = Workspace.Plots.Plot5.Barrier:FindFirstChild("PlotBarrier")
                    end
                    
                    if hkFirePart then
                        hkFirePart.CanCollide = true
                        hkFirePart.CanQuery = true
                        hkFirePart.Name = "AntiFirePart"
                        
                        local h2 = hkFirePart:Clone()
                        h2.Name = "FalseBorder"
                        h2.Parent = hkFirePart.Parent
                        
                        hkFirePart.Size = Vector3.new(1, 1, 1)
                        
                        for _, prt in pairs(hkFirePart:GetChildren()) do
                            prt:Destroy()
                        end
                        
                        hkFirePart.CanQuery = false
                        hkFirePart.CanCollide = false
                    end
                end
            end)
            
            antiFireTask = task.spawn(function()
                while bool.AntiFire do
                    pcall(function()
                        if hkFirePart then
                            local char = plr.Character
                            local hrp = char and char:FindFirstChild("HumanoidRootPart")
                            if hrp then
                                hkFirePart.CFrame = hrp.CFrame
                            end
                            -- Двойное переключение для обновления состояния
                            hkFirePart.CanCollide = not hkFirePart.CanCollide
                            hkFirePart.CanCollide = not hkFirePart.CanCollide
                        end
                    end)
                    task.wait()
                end
                
                if hkFirePart then
                    hkFirePart.CFrame = CFrame.new(0, -15, 0)
                end
            end)
        else
            if antiFireTask then
                task.cancel(antiFireTask)
                antiFireTask = nil
            end
            
            if hkFirePart then
                hkFirePart.CFrame = CFrame.new(0, -15, 0)
            end
        end
    end
})

-- Anti Sticky
DefGroup:AddToggle("Anti_Sticky", {
    Text = "Anti Sticky",
    Default = false,
    Callback = function(state)
        bool.AntiSticky = state
        if state then
            if plr.PlayerScripts:FindFirstChild("StickyPartsTouchDetection") then
                plr.PlayerScripts.StickyPartsTouchDetection.Disabled = true
            end
        else
            if plr.PlayerScripts:FindFirstChild("StickyPartsTouchDetection") then
                plr.PlayerScripts.StickyPartsTouchDetection.Disabled = false
            end
        end
    end
})

-- ==============================================
-- ANTI LAG + AUTO ANTI LAG
-- ==============================================
local ocnAntiLagOn = false
local ocnFpsThreshold = 30
local ocnFpsFrames = 0
local ocnLastFpsCheck = tick()
local ocnAutoLagStartDelay = tick()
local ocnAutoLagEnabled = false

DefGroup:AddToggle("AntiLag", {
    Text = "Anti Lag",
    Default = false,
    Tooltip = "Отключает CharacterAndBeamMove",
    Callback = function(Value)
        ocnAntiLagOn = Value
        if Value then
            pcall(function()
                plr.PlayerScripts.CharacterAndBeamMove.Disabled = true
                for _, plr in pairs(Players:GetPlayers()) do
                    if plr.Character and plr.Character:FindFirstChild("GrabParts") then
                        plr.Character.GrabParts:Destroy()
                    end
                end
            end)
        else
            pcall(function()
                plr.PlayerScripts.CharacterAndBeamMove.Disabled = false
            end)
        end
    end
})

-- ==============================================
-- AUTO ANTI LAG (всегда активен в фоне)
-- ==============================================
local ocnFpsThreshold = 30
local ocnFpsFrames = 0
local ocnLastFpsCheck = tick()
local ocnAutoLagStartDelay = tick()
local ocnAntiLagOn = false

-- Ползунок для настройки порога FPS
DefGroup:AddSlider("AntiLagFPSThreshold", {
    Text = "Auto Anti Lag FPS Threshold",
    Min = 10,
    Max = 120,
    Default = 30,
    Rounding = 0,
    Suffix = " FPS",
    Tooltip = "При каком фпс будет работать авто анти лаг",
    Callback = function(Value)
        ocnFpsThreshold = Value
    end
})

-- Основной цикл Auto Anti Lag (всегда работает в фоне)
task.spawn(function()
    -- Даём скрипту 5 секунд на инициализацию
    ocnAutoLagStartDelay = tick()
    
    while true do
        task.wait()
        
        -- Пропускаем первые 5 секунд после запуска
        if tick() - ocnAutoLagStartDelay < 5 then
            continue
        end
        
        -- Считаем FPS
        ocnFpsFrames = ocnFpsFrames + 1
        local now = tick()
        
        if now - ocnLastFpsCheck >= 1 then
            local fps = ocnFpsFrames / (now - ocnLastFpsCheck)
            ocnFpsFrames = 0
            ocnLastFpsCheck = now
            
            -- Если FPS ниже порога и Anti Lag выключен — включаем
            if fps <= ocnFpsThreshold and not ocnAntiLagOn then
                ocnAntiLagOn = true
                pcall(function()
                    plr.PlayerScripts.CharacterAndBeamMove.Disabled = true
                    for _, player in pairs(Players:GetPlayers()) do
                        if player.Character and player.Character:FindFirstChild("GrabParts") then
                            player.Character.GrabParts:Destroy()
                        end
                    end
                end)
            -- Если FPS выше порога и Anti Lag включён — выключаем
            elseif fps > ocnFpsThreshold and ocnAntiLagOn then
                ocnAntiLagOn = false
                pcall(function()
                    plr.PlayerScripts.CharacterAndBeamMove.Disabled = false
                end)
            end
        end
    end
end)

-- Platform TP
local platformPart = nil
local platformTPActive = false
local platformOldPos = nil

DefGroup:AddToggle("Platform_TP", {
    Text = "Enable Platform TP",
    Default = false,
    Callback = function(state)
        bool.PlatformTP = state
        if state then
            if not platformPart then
                platformPart = Instance.new("Part", Workspace)
                platformPart.Name = "SkyBase"
                platformPart.Anchored = true
                platformPart.Size = Vector3.new(1500, 2, 1500)
                platformPart.CFrame = CFrame.new(0, 1000000, 0)
                Workspace.FallenPartsDestroyHeight = -9999999
            end
        end
    end
})

DefGroup:AddButton({
    Text = "Platform TP Execute",
    Callback = function()
        if not bool.PlatformTP then
            notify("Error", "Enable Platform TP first!")
            return
        end
        local char = plr.Character
        local root = char and char:FindFirstChild("HumanoidRootPart")
        if not root then return end
        if not platformTPActive then
            platformTPActive = true
            platformOldPos = root.CFrame
            root.CFrame = platformPart.CFrame + Vector3.new(0, 5, 0)
            root.AssemblyLinearVelocity = Vector3.zero
            root.AssemblyAngularVelocity = Vector3.zero
            notify("Platform", "Teleported to platform")
        else
            platformTPActive = false
            if platformOldPos then
                root.CFrame = platformOldPos
                notify("Platform", "Returned")
            end
        end
    end
})

-- Anti Input Lag
DefGroup:AddToggle("Anti_Input_Lag", {
    Text = "Anti Input Lag",
    Default = false,
    Callback = function(state)
        bool.AntiInputLag = state
        if state then
            cons["AntiInputLag"] = RunService.Heartbeat:Connect(function()
                if not bool.AntiInputLag then return end
                local char = plr.Character
                local hrp = char and char:FindFirstChild("HumanoidRootPart")
                if not hrp then return end
                local inv = Workspace:FindFirstChild(plr.Name.."SpawnedInToys")
                if not inv then return end
                local item = inv:FindFirstChild("FoodHamburger")
                if not item then
                    pcall(function()
                        SpawnToyRemote:InvokeServer("FoodHamburger", hrp.CFrame * CFrame.new(0, 5, 10), Vector3.zero)
                    end)
                    task.wait(0.1)
                    item = inv:FindFirstChild("FoodHamburger")
                end
                if item then
                    local holdPart = item:FindFirstChild("HoldPart")
                    if holdPart then
                        pcall(function()
                            holdPart.HoldItemRemoteFunction:InvokeServer(item, char)
                            task.wait(0.05)
                            holdPart.DropItemRemoteFunction:InvokeServer(item, CFrame.new(0, 5000, 0), Vector3.zero)
                        end)
                    end
                end
            end)
        else
            discCon("AntiInputLag")
        end
    end
})

-- Perm Ragdoll
DefGroup:AddToggle("Perm_Ragdoll", {
    Text = "Perm Ragdoll",
    Default = false,
    Callback = function(state)
        bool.PermRag = state
        if state then
            cons["PermRag"] = RunService.Heartbeat:Connect(function()
                if not bool.PermRag then return end
                local char = plr.Character
                local hrp = char and char:FindFirstChild("HumanoidRootPart")
                if not hrp then return end
                pcall(function() RagdollRemote:FireServer(hrp, 1) end)
            end)
        else
            discCon("PermRag")
        end
    end
})

-- ==============================================
-- ANTI KICKS GROUP (Right Side)
-- ==============================================
local DefK = Tabs.Def:AddGroupbox({
    Side = "Right",
    Name = "Anti Kicks (I RECOMMEND USING THIRD PERSON)",
    IconName = "ban",
})

-- ==============================================
-- 1. OAT ANTI-KICK (Break PCLD)
-- ==============================================
DefK:AddToggle("OatAntiKick", {
    Text = "Oat Anti-Kick (Break PCLD)",
    Default = false,
    Tooltip = "Ломает PCLD для защиты",
    Callback = function(Value)
        local hkExpectDeath = false
        local hkSalmonList = {}
        hkSalmonList[LocalPlayer.UserId] = true
        
        local function hkApplySalmon(char)
            if not char then return end
            local newHum = char:WaitForChild("Humanoid", 5)
            if not newHum then return end
            if hkSalmonList[LocalPlayer.UserId] and not hkExpectDeath then
                hkExpectDeath = true
                newHum:ChangeState(Enum.HumanoidStateType.Dead)
            else
                hkExpectDeath = false
            end
        end
        
        LocalPlayer.CharacterAdded:Connect(function(char)
            hkApplySalmon(char)
        end)
        
        hkSalmonList[LocalPlayer.UserId] = Value and true or nil
        if Value then
            hkExpectDeath = false
            local char = LocalPlayer.Character
            local hum = char and char:FindFirstChildOfClass("Humanoid")
            if hum then hum.Health = 0 end
        end
    end
})

-- ==============================================
-- 2. DELETE LEGS (Button)
-- ==============================================
DefK:AddButton({
    Text = "Delete Legs",
    Tooltip = "Удаляет ноги ( ыыы огурчик)",
    Func = function()
        pcall(function()
            local char = LocalPlayer.Character
            if not char then return end
            
            if char:FindFirstChild("Left Leg") and char:FindFirstChild("Right Leg") then
                local ll = char:FindFirstChild("Left Leg")
                local rl = char:FindFirstChild("Right Leg")
                local void = workspace.FallenPartsDestroyHeight
                local torso = char:FindFirstChild("Torso") or char:FindFirstChild("UpperTorso")
                
                if not torso then return end
                
                local pos = torso.CFrame
                local hrp = char:FindFirstChild("HumanoidRootPart")
                local hum = char:FindFirstChild("Humanoid")
                
                if not hrp or not hum then return end
                
                workspace.FallenPartsDestroyHeight = -100
                game:GetService("ReplicatedStorage").CharacterEvents.RagdollRemote:FireServer(hrp, 2)
                task.wait(0.5)
                
                rl.CFrame = CFrame.new(0, -10000, 0)
                ll.CFrame = CFrame.new(0, -10000, 0)
                task.wait(0.3)
                
                torso.CFrame = CFrame.new(0, -9970, 0)
                task.wait(0.5)
                
                torso.CFrame = pos
                task.wait(0.5)
                workspace.FallenPartsDestroyHeight = void
                
                task.spawn(function()
                    if not char:FindFirstChild("Left Leg") and not char:FindFirstChild("Right Leg") then
                        while char and char.Parent and hum and hum.Health > 0 do
                            pcall(function()
                                local controls = LocalPlayer.PlayerGui:FindFirstChild("ControlsGui")
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
                    end
                end)
            end
        end)
    end
})

-- ==============================================
-- 3. SELECT ANTI KICK METHOD (Dropdown)
-- ==============================================
local ShurikenToyList = {
    ["Shuriken"] = "NinjaShuriken",
    ["Pickaxe"] = "ToolPickaxe",
    ["Kunai"] = "NinjaKunai",
    ["Cleaver"] = "ToolCleaver",
}

local ShurikenDropdownValues = {}
for shortName, _ in pairs(ShurikenToyList) do
    table.insert(ShurikenDropdownValues, shortName)
end
table.sort(ShurikenDropdownValues)

local SelectedShurikenToy = ShurikenToyList["Shuriken"] or ShurikenToyList[ShurikenDropdownValues[1]]

DefK:AddDropdown("ShurikenItemSelect", {
    Text = "Select Anti Kick Method",
    Values = ShurikenDropdownValues,
    Default = "Shuriken",
    Tooltip = "метод работы анти кика",
    Callback = function(Value)
        SelectedShurikenToy = ShurikenToyList[Value]
    end
})

-- ==============================================
-- 4. ANTI KICK (Shuriken/Kunai)
-- ==============================================
do
    local shurikenAntiKickActive = false
    local shurikenAntiKickTask = nil
    local shurikenCharFixConnection = nil
    local shurikenRespawnConnection = nil

    local function fixShurikenCharacter(char)
        if not char then return end
        local hum = char:FindFirstChild("Humanoid")
        local hrp = char:FindFirstChild("HumanoidRootPart")
        if hum and hrp then
            hum.AutoRotate = true
            hum.Sit = false
            hrp.Velocity = Vector3.zero
            hrp.AssemblyLinearVelocity = Vector3.zero
            hrp.AssemblyAngularVelocity = Vector3.zero
            hrp.CanCollide = true
            hrp.CanTouch = true
            hrp.CanQuery = true
            for _, part in pairs(char:GetChildren()) do
                if part:IsA("BasePart") then
                    part.CanCollide = true
                    part.CanTouch = true
                    part.CanQuery = true
                    part.Velocity = Vector3.zero
                    part.AssemblyLinearVelocity = Vector3.zero
                    part.AssemblyAngularVelocity = Vector3.zero
                end
            end
            hum:ChangeState(Enum.HumanoidStateType.Running)
        end
    end

    local function ClearKunai()
        local inv = workspace:FindFirstChild(LocalPlayer.Name.."SpawnedInToys")
        local destroyrem = game:GetService("ReplicatedStorage"):FindFirstChild("MenuToys") and game:GetService("ReplicatedStorage").MenuToys:FindFirstChild("DestroyToy")
        if inv and destroyrem then
            for _, v in pairs(inv:GetChildren()) do
                if v.Name == "AntiKick" or v.Name == SelectedShurikenToy then
                    pcall(function() destroyrem:FireServer(v) end)
                end
            end
        end
    end

    DefK:AddToggle("ShurikenAntiKick", {
        Text = "Anti Kick (Shuriken)",
        Default = false,
        Tooltip = "анти кик",
        Callback = function(Value)
            shurikenAntiKickActive = Value
            
            if Value then
                fixShurikenCharacter(LocalPlayer.Character)
                
                if shurikenCharFixConnection then shurikenCharFixConnection:Disconnect() end
                shurikenCharFixConnection = LocalPlayer.CharacterAdded:Connect(function(char)
                    task.wait(0.5)
                    fixShurikenCharacter(char)
                end)

                if shurikenRespawnConnection then shurikenRespawnConnection:Disconnect() end
                shurikenRespawnConnection = LocalPlayer.CharacterAdded:Connect(function()
                    task.wait(1)
                    if shurikenAntiKickActive then
                        ClearKunai()
                    end
                end)
                
                shurikenAntiKickTask = task.spawn(function()
                    local plr = LocalPlayer
                    local ReplicatedStorage = game:GetService("ReplicatedStorage")
                    local setOwner = ReplicatedStorage:WaitForChild("GrabEvents"):WaitForChild("SetNetworkOwner")
                    local stickyEvent = ReplicatedStorage:WaitForChild("PlayerEvents"):WaitForChild("StickyPartEvent")
                    local spawnRemote = ReplicatedStorage.MenuToys.SpawnToyRemoteFunction
                    local destroyrem = ReplicatedStorage:WaitForChild("MenuToys"):WaitForChild("DestroyToy")
                    local canSpawn = plr:WaitForChild("CanSpawnToy")
                    
                    local function getHRP()
                        if plr.Character and plr.Character:FindFirstChild("HumanoidRootPart") then
                            return plr.Character.HumanoidRootPart
                        else
                            local character = plr.CharacterAdded:Wait()
                            return character:WaitForChild("HumanoidRootPart")
                        end
                    end
                    
                    local function CheckForHome()
                        if not workspace.PlotItems.PlayersInPlots:FindFirstChild(plr.Name) then 
                            return false
                        end
                        for _, v in pairs(workspace.Plots:GetChildren()) do
                            local sign = v:FindFirstChild("PlotSign")
                            local owners = sign and sign:FindFirstChild("ThisPlotsOwners")
                            if owners then
                                for _, b in pairs(owners:GetChildren()) do
                                    if b.Value == plr.Name then
                                        local folder = workspace.PlotItems:FindFirstChild(v.Name)
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
                        if kunai:FindFirstChild("Handle") then
                            local handle = kunai.Handle
                            if not handle:FindFirstChild("Highlight") then
                                local high = Instance.new("Highlight", handle)
                                high.FillColor = Color3.fromRGB(0, 255, 255)
                            end
                        end
                    end
                    
                    local function SpawnToy(name)
                        local t = tick()
                        while not canSpawn.Value do
                            if not shurikenAntiKickActive or tick() - t > 5 then return nil end
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
                        local inv = workspace:FindFirstChild(plr.Name.."SpawnedInToys")
                        if boolik and house then 
                            return house:WaitForChild(name, 2)
                        elseif not workspace.PlotItems.PlayersInPlots:FindFirstChild(plr.Name) and inv then 
                            return inv:WaitForChild(name, 2)
                        end
                        return nil
                    end
                    
                    while shurikenAntiKickActive do 
                        task.wait(0.005)
                        if not plr.Character or not plr.Character:FindFirstChild("Humanoid") or plr.Character.Humanoid.Health <= 0 then 
                            task.wait(0.5)
                            ClearKunai()
                            return
                        end
                        local inv = workspace:FindFirstChild(plr.Name.."SpawnedInToys")
                        local kunai = inv and inv:FindFirstChild(SelectedShurikenToy)
                        
                        if workspace.PlotItems.PlayersInPlots:FindFirstChild(plr.Name) then 
                            local boolik, house = CheckForHome()
                            if boolik and house and workspace.Plots:FindFirstChild(house.Name) then
                                local sign = workspace.Plots[house.Name]:FindFirstChild("PlotSign")
                                if sign and sign.ThisPlotsOwners.Value.TimeRemainingNum.Value > 89 then 
                                    kunai = SpawnToy(SelectedShurikenToy)
                                    if kunai == nil then return end
                                    kunai.Name = "AntiKick" 
                                    StickKunai(kunai)
                                end
                            end
                        end
                        
                        if not kunai then
                            if workspace.PlotItems.PlayersInPlots:FindFirstChild(plr.Name) then return end 
                            kunai = SpawnToy(SelectedShurikenToy)
                            if kunai == nil then return end 
                            kunai.Name = "AntiKick"
                            if not kunai then return end 
                        end
                        
                        repeat
                            if kunai and kunai:FindFirstChild("StickyPart") and kunai.StickyPart.CanTouch == true then
                                StickKunai(kunai)
                                kunai.Name = "AntiKick"
                            end
                            task.wait(0.3)
                        until not kunai or not shurikenAntiKickActive or not kunai:FindFirstChild("StickyPart") or kunai.StickyPart.CanTouch == false 
                            or not plr.Character or not plr.Character:FindFirstChild("HumanoidRootPart") 
                            or not kunai:FindFirstChild("StickyPart") 
                            or (plr.Character.HumanoidRootPart.Position - kunai.StickyPart.Position).Magnitude >= 20
                        
                        if not kunai or not kunai:FindFirstChild("StickyPart") or not plr.Character or not plr.Character:FindFirstChild("HumanoidRootPart") or (plr.Character.HumanoidRootPart.Position - kunai.StickyPart.Position).Magnitude >= 20 then 
                            ClearKunai()
                        end 
                        
                        pcall(function()
                            repeat
                                task.wait(0.05)
                            until not shurikenAntiKickActive or not plr.Character or not plr.Character:FindFirstChild("Humanoid") or not kunai or not kunai:FindFirstChild("StickyPart") or not kunai.StickyPart:FindFirstChild("StickyWeld") or not kunai.StickyPart.StickyWeld.Part1
                            if not kunai or not kunai:FindFirstChild("StickyPart") or (plr.Character and plr.Character:FindFirstChild("Humanoid") and plr.Character.Humanoid.Health <= 0) or not kunai["StickyPart"]:FindFirstChild("StickyWeld").Part1 then 
                                ClearKunai()
                            end
                        end)
                    end
                    ClearKunai()
                end)
            else
                shurikenAntiKickActive = false
                if shurikenAntiKickTask then
                    task.cancel(shurikenAntiKickTask)
                    shurikenAntiKickTask = nil
                end
                if shurikenCharFixConnection then
                    shurikenCharFixConnection:Disconnect()
                    shurikenCharFixConnection = nil
                end
                if shurikenRespawnConnection then
                    shurikenRespawnConnection:Disconnect()
                    shurikenRespawnConnection = nil
                end
                
                fixShurikenCharacter(LocalPlayer.Character)
                ClearKunai()
            end
        end
    })
end

-- ==============================================
-- 5. ANTI KICK (Pencil)
-- ==============================================
do
    local pencilAntiKickActive = false
    local pencilAntiKickTask = nil
    local pencilRespawnConnection = nil

    local function spawnPencil()
        local spawnFolder = workspace:FindFirstChild(LocalPlayer.Name .. "SpawnedInToys")
        if not spawnFolder then return end
        
        local pencil = spawnFolder:FindFirstChild("ToolPencil")
        if pencil then return pencil end
        
        if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
            pcall(function()
                game:GetService("ReplicatedStorage").MenuToys.SpawnToyRemoteFunction:InvokeServer(
                    "ToolPencil",
                    CFrame.new(LocalPlayer.Character.HumanoidRootPart.CFrame.Position) + Vector3.new(0, 0, 15),
                    Vector3.new(0, 0, 0)
                )
            end)
        end
        return nil
    end

    local function fixPencil()
        pcall(function()
            local playerName = LocalPlayer.Name
            local spawnFolder = workspace:FindFirstChild(playerName .. "SpawnedInToys")
            
            if not spawnFolder then return end
            
            local pencil = spawnFolder:FindFirstChild("ToolPencil")
            
            if not pencil then
                pencil = spawnPencil()
                if not pencil then return end
            end
            
            local char = LocalPlayer.Character
            if not char then return end
            
            local torso = char:FindFirstChild("Torso")
            local root = char:FindFirstChild("HumanoidRootPart")
            if not (torso and root) then return end
            
            local stickyPart = pencil:FindFirstChild("StickyPart")
            local soundPart = pencil:FindFirstChild("SoundPart")
            
            if stickyPart and stickyPart:FindFirstChild("StickyWeld") then
                local weld = stickyPart.StickyWeld
                
                if weld.Part1 ~= torso then
                    local a = soundPart and soundPart.CFrame.Position or Vector3.zero
                    local b = root.CFrame.Position
                    local dist = (a - b).Magnitude
                    
                    if dist > 20 then
                        pcall(function()
                            game:GetService("ReplicatedStorage").MenuToys.DestroyToy:FireServer(pencil)
                        end)
                    else
                        pcall(function()
                            game:GetService("ReplicatedStorage").PlayerEvents.StickyPartEvent:FireServer(
                                stickyPart,
                                torso,
                                CFrame.new(0, -1, 0) * CFrame.Angles(0, math.pi, 0)
                            )
                        end)
                        
                        for _, prt in pairs(pencil:GetChildren()) do
                            if prt:IsA("BasePart") then
                                prt.CanQuery = false
                                prt.CanCollide = false
                                prt.CanTouch = false
                            end
                        end
                    end
                end
            end
        end)
    end

    DefK:AddToggle("AntiKickPencil", {
        Text = "Anti Kick (Pencil)",
        Default = false,
        Tooltip = "анти кик через карандаш",
        Callback = function(Value)
            pencilAntiKickActive = Value
            
            if Value then
                if pencilRespawnConnection then pencilRespawnConnection:Disconnect() end
                pencilRespawnConnection = LocalPlayer.CharacterAdded:Connect(function()
                    task.wait(1)
                    if pencilAntiKickActive then
                        fixPencil()
                    end
                end)
                
                pencilAntiKickTask = task.spawn(function()
                    while pencilAntiKickActive do
                        fixPencil()
                        task.wait(0.5)
                    end
                end)
            else
                pencilAntiKickActive = false
                if pencilAntiKickTask then
                    task.cancel(pencilAntiKickTask)
                    pencilAntiKickTask = nil
                end
                if pencilRespawnConnection then
                    pencilRespawnConnection:Disconnect()
                    pencilRespawnConnection = nil
                end
                
                local spawnFolder = workspace:FindFirstChild(LocalPlayer.Name .. "SpawnedInToys")
                if spawnFolder then
                    local pencil = spawnFolder:FindFirstChild("ToolPencil")
                    if pencil then
                        pcall(function()
                            game:GetService("ReplicatedStorage").MenuToys.DestroyToy:FireServer(pencil)
                        end)
                    end
                end
            end
        end
    })
end

-- ==============================================
-- 6. ANTI KICK [ITEM]
-- ==============================================
do
    local Players = game:GetService("Players")
    local RS = game:GetService("ReplicatedStorage")
    local RunService = game:GetService("RunService")
    local plr = Players.LocalPlayer

    local AntiKickItemActive = false
    local MyPCLD = nil
    local pcldConn = nil
    local charFixConnection = nil

    local ToyList = {
        ["Japanese Lantern"] = "JapaneseLantern",
        ["Spray Can"]        = "SprayCanWD",
        ["Spooky Candle"]    = "SpookyCandle1",
    }

    local DropdownValues = {}
    for shortName, _ in pairs(ToyList) do
        table.insert(DropdownValues, shortName)
    end
    table.sort(DropdownValues)

    local SelectedToy = ToyList["Spooky Candle"] or ToyList[DropdownValues[1]]

    DefK:AddDropdown("AntiKickItemSelect", {
        Text = "Anti Kick Item",
        Values = DropdownValues,
        Default = "Spooky Candle",
        Tooltip = "анти кик предметом ( не сносится антикик аурой)",
        Callback = function(Value)
            SelectedToy = ToyList[Value]
        end
    })

    local function GetMagnitude(Part1, Part2)
        return (Part1.Position - Part2.Position).Magnitude
    end

    local function FWD(parent, part, timeOffset)
        return parent:FindFirstChild(part) or parent:WaitForChild(part, timeOffset or 1)
    end

    local function CheckNetworkOwnerOnPart(Part) 
        local po = Part:FindFirstChild("PartOwner")
        return po and po.Value == plr.Name
    end

    local function sno(part)
        pcall(function()
            local grabEvents = RS:FindFirstChild("GrabEvents")
            local setNetOwner = grabEvents and grabEvents:FindFirstChild("SetNetworkOwner")
            if setNetOwner then
                setNetOwner:FireServer(part, part.CFrame)
            end
        end)
    end

    local function CheckForHome()
        local plotItems = workspace:FindFirstChild("PlotItems")
        local plots = workspace:FindFirstChild("Plots")
        
        if plots and plotItems then
            for i = 1, 5 do 
                local Plot = plots:FindFirstChild("Plot"..i)
                if Plot then
                    local sign = Plot:FindFirstChild("PlotSign")
                    local owners = sign and sign:FindFirstChild("ThisPlotsOwners")
                    if owners then
                        for _,v in pairs(owners:GetChildren()) do 
                            if v.Value == plr.Name then 
                                return plotItems:FindFirstChild("Plot"..i)
                            end
                        end
                    end
                end
            end
        end
        return nil
    end

    local function SpawnToy(ToyName)
        local InPlot = plr:FindFirstChild("InPlot")
        local InOwnedPlot = plr:FindFirstChild("InOwnedPlot")
        local CanSpawnToy = plr:FindFirstChild("CanSpawnToy")
        local inv = workspace:FindFirstChild(plr.Name.."SpawnedInToys")

        if InPlot and InPlot.Value and InOwnedPlot and not InOwnedPlot.Value then 
            InPlot:GetPropertyChangedSignal("Value"):Wait()
        end 
        if CanSpawnToy and not CanSpawnToy.Value then 
            CanSpawnToy:GetPropertyChangedSignal("Value"):Wait()
        end

        local hrp = plr.Character and plr.Character:FindFirstChild("HumanoidRootPart")
        if not hrp then return nil end

        local SpawnCF = (MyPCLD or hrp).CFrame * CFrame.new(0, 14, 20)
        local Container = (InOwnedPlot and InOwnedPlot.Value) and CheckForHome() or inv
        if not Container then return nil end

        local spawnedObject = nil
        local connection
        connection = Container.ChildAdded:Connect(function(child)
            if child.Name == ToyName then
                spawnedObject = child
            end
        end)

        task.spawn(function()
            pcall(function()
                local menuToys = RS:FindFirstChild("MenuToys")
                local spawnRemote = menuToys and menuToys:FindFirstChild("SpawnToyRemoteFunction")
                if spawnRemote then
                    spawnRemote:InvokeServer(ToyName, SpawnCF, Vector3.zero)
                end
            end)
        end)

        local start = tick()
        repeat task.wait() until spawnedObject or (tick() - start) > 2.5

        if connection then connection:Disconnect() end
        return spawnedObject
    end

    local function FindPCLD(hrp)
        if pcldConn then pcldConn:Disconnect() end
        MyPCLD = nil
        pcldConn = RunService.Heartbeat:Connect(function()
            if MyPCLD or not hrp or not hrp.Parent then 
                if pcldConn then pcldConn:Disconnect() pcldConn = nil end
                return
            end
            for _, v in pairs(workspace:GetChildren()) do 
                if v.Name == "PlayerCharacterLocationDetector" and v:IsA("BasePart") then
                    if GetMagnitude(v, hrp) <= 2 then 
                        MyPCLD = v
                        break
                    end
                end
            end
        end)
    end

    local function fixCharacter(char)
        if not char then return end
        local hum = char:FindFirstChild("Humanoid")
        local hrp = char:FindFirstChild("HumanoidRootPart")
        if hum and hrp then
            hum.AutoRotate = true
            hum.Sit = false
            hrp.Velocity = Vector3.zero
            hrp.AssemblyLinearVelocity = Vector3.zero
            hrp.AssemblyAngularVelocity = Vector3.zero
            hrp.CanCollide = true
            hrp.CanTouch = true
            hrp.CanQuery = true
            for _, part in pairs(char:GetChildren()) do
                if part:IsA("BasePart") then
                    part.CanCollide = true
                    part.CanTouch = true
                    part.CanQuery = true
                    part.Velocity = Vector3.zero
                    part.AssemblyLinearVelocity = Vector3.zero
                    part.AssemblyAngularVelocity = Vector3.zero
                end
            end
            hum:ChangeState(Enum.HumanoidStateType.Running)
        end
    end

    DefK:AddToggle("AntiKickItem", {
        Text = "Anti Kick [ITEM]",
        Default = false,
        Tooltip = "анти кик предметами",
        Callback = function(Val)
            AntiKickItemActive = Val 
            
            if Val then
                fixCharacter(plr.Character)
                
                if charFixConnection then charFixConnection:Disconnect() end
                charFixConnection = plr.CharacterAdded:Connect(function(char)
                    task.wait(0.5)
                    fixCharacter(char)
                end)
                
                task.spawn(function()
                    local Item, SoundPart
                    while AntiKickItemActive and task.wait() do 
                        local char = plr.Character
                        local hrp = char and char:FindFirstChild("HumanoidRootPart")
                        local hum = char and char:FindFirstChild("Humanoid")
                        local inPlot = plr:FindFirstChild("InPlot")
                        local inv = workspace:FindFirstChild(plr.Name.."SpawnedInToys")
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
                                    pcall(function() destroyToy:FireServer(v) end)
                                end
                            end
                            
                            Item = SpawnToy(SelectedToy)
                            if not Item then continue end 
                            
                            SoundPart = Item and FWD(Item, "Hitbox", 0.5)
                            if SoundPart then sno(SoundPart) end
                            
                            for _,v in pairs(Item:GetChildren()) do 
                                if v:IsA("BasePart") then 
                                    v.CanCollide = false 
                                    v.Transparency = 0.8
                                    v.Color = Color3.fromRGB(0, 255, 255)
                                end
                            end
                            
                            Item.Name = "AntiKickItem"
                        end
                        
                        if SoundPart and not CheckNetworkOwnerOnPart(SoundPart) then 
                            sno(SoundPart)
                        end
                        
                        local targetPart = MyPCLD or hrp:FindFirstChild("FirePlayerPart") or hrp
                        
                        if SoundPart and targetPart then
                            SoundPart.CFrame = targetPart.CFrame
                            SoundPart.AssemblyLinearVelocity = Vector3.zero
                            SoundPart.AssemblyAngularVelocity = Vector3.zero
                        end
                    end
                end)
            else
                if pcldConn then pcldConn:Disconnect() pcldConn = nil end
                if charFixConnection then
                    charFixConnection:Disconnect()
                    charFixConnection = nil
                end
                MyPCLD = nil
                
                fixCharacter(plr.Character)
                
                task.spawn(function()
                    local inv = workspace:FindFirstChild(plr.Name.."SpawnedInToys")
                    local destroyToy = RS:FindFirstChild("MenuToys") and RS.MenuToys:FindFirstChild("DestroyToy")
                    if inv and destroyToy then
                        for _,v in pairs(inv:GetChildren()) do 
                            if v.Name == "AntiKickItem" then 
                                pcall(function() destroyToy:FireServer(v) end)
                            end
                        end
                    end
                end)
            end
        end
    })

    plr.CharacterAdded:Connect(function(char)
        if AntiKickItemActive then
            MyPCLD = nil
            local hrp = char:WaitForChild("HumanoidRootPart", 5)
            if hrp then FindPCLD(hrp) end
            task.wait(0.5)
            fixCharacter(char)
        end
    end)
end

-- ==============================================
-- THIRD PARTY PROTECTION (Right Side)
-- ==============================================
local DefT = Tabs.Def:AddGroupbox({
    Side = "Right",
    Name = "Third Party Protection",
    IconName = "shield",
})

local tppTargets = {}
local tppMethod = "Grab"
local tppEnabled = false
local tppDropdown = nil
local tppCountLabel = nil
local tppStatusLabel = nil

-- Переменные для защиты друзей
local friendShurikens = {}
local friendFireExtinguishers = {}
local friendGrabs = {}
local friendExplosionProtection = {}

-- Системные переменные
local friendAntiKickEnabled = false
local friendAntiFireEnabled = false
local friendAntiGrabEnabled = false
local friendAntiExplosionEnabled = false

local friendAntiKickTask = nil
local friendAntiFireTask = nil
local friendAntiGrabTask = nil
local friendAntiKickRespawnConn = nil
local friendAntiFireRespawnConn = nil

-- ==============================================
-- ВСПОМОГАТЕЛЬНЫЕ ФУНКЦИИ
-- ==============================================

local function refreshPlayers()
    local list = {}
    for _, pl in pairs(Players:GetPlayers()) do
        if pl ~= plr then
            table.insert(list, pl.DisplayName .. " (" .. pl.Name .. ")")
        end
    end
    if tppDropdown then
        tppDropdown:SetValues(list)
    end
end

local function isTPPActive()
    return tppEnabled
end

local function getFriendTargets()
    return tppTargets
end

-- ==============================================
-- ОСНОВНАЯ ЗАЩИТА TPP (Grab/Bring)
-- ==============================================

local function runTPPLoop()
    task.spawn(function()
        while tppEnabled do
            RunService.RenderStepped:Wait()
            if #tppTargets == 0 then
                continue
            end

            for _, targetName in ipairs(tppTargets) do
                local target = Players:FindFirstChild(targetName)
                if not target or not target.Character then
                    continue
                end

                local char = target.Character
                local hrp = char:FindFirstChild("HumanoidRootPart")
                local head = char:FindFirstChild("Head")

                if not hrp or not head then
                    continue
                end

                local partOwner = head:FindFirstChild("PartOwner")
                if not partOwner or partOwner.Value == "" or partOwner.Value == plr.Name then
                    continue
                end

                local myHRP = plr.Character and plr.Character:FindFirstChild("HumanoidRootPart")
                if not myHRP then continue end
                
                local distance = (hrp.Position - myHRP.Position).Magnitude

                if distance <= 30 then
                    pcall(function()
                        SetNetworkOwner:FireServer(hrp, hrp.CFrame)
                        CreateGrabLine:FireServer(hrp, Vector3.zero, hrp.Position, false)
                    end)

                    local weOwnIt = head:FindFirstChild("PartOwner") and head.PartOwner.Value == plr.Name

                    if weOwnIt then
                        if tppMethod == "Bring" then
                            hrp.CFrame = myHRP.CFrame * CFrame.new(0, 5, 0)
                            hrp.AssemblyLinearVelocity = Vector3.zero
                            hrp.AssemblyAngularVelocity = Vector3.zero
                        end
                        pcall(function()
                            DestroyGrabLine:FireServer(hrp)
                        end)
                    end
                end
            end
        end
    end)
end

-- ==============================================
-- 1. ANTI GRAB ДЛЯ ДРУЗЕЙ
-- ==============================================

local function clearFriendGrabs()
    for targetName, data in pairs(friendGrabs) do
        if data.conn then
            pcall(function() data.conn:Disconnect() end)
        end
    end
    friendGrabs = {}
end

local function protectFriendFromGrab(targetName)
    local target = Players:FindFirstChild(targetName)
    if not target or not target.Character then return end
    
    local targetChar = target.Character
    local targetHRP = targetChar:FindFirstChild("HumanoidRootPart")
    local targetHum = targetChar:FindFirstChild("Humanoid")
    
    if not targetHRP or not targetHum then return end
    
    -- Создаём коннект для защиты от граба
    local conn = target:WaitForChild("IsHeld"):GetPropertyChangedSignal("Value"):Connect(function()
        if not tppEnabled or not friendAntiGrabEnabled then return end
        if not target.IsHeld.Value then return end
        if not target.Character then return end
        
        local char = target.Character
        local root = char:FindFirstChild("HumanoidRootPart")
        local hum = char:FindFirstChild("Humanoid")
        if not root or not hum then return end
        
        -- Отключаем коллизию
        for _, part in pairs(char:GetDescendants()) do
            if part:IsA("BasePart") then
                part.CanCollide = false
            end
        end
        root.Anchored = true
        
        task.spawn(function()
            while tppEnabled and friendAntiGrabEnabled and target.IsHeld.Value do
                pcall(function()
                    Struggle:FireServer(target)
                    RagdollRemote:FireServer(root, 0)
                    if RS.GameCorrectionEvents and RS.GameCorrectionEvents.StopAllVelocity then
                        RS.GameCorrectionEvents.StopAllVelocity:FireServer()
                    end
                    hum.Sit = false
                    hum:ChangeState(Enum.HumanoidStateType.GettingUp)
                    hum:SetStateEnabled(Enum.HumanoidStateType.Jumping, true)
                    root.AssemblyLinearVelocity = Vector3.zero
                    root.AssemblyAngularVelocity = Vector3.zero
                end)
                task.wait()
            end
            
            if root then
                root.Anchored = false
                for _, part in pairs(char:GetDescendants()) do
                    if part:IsA("BasePart") then
                        part.CanCollide = true
                    end
                end
            end
        end)
    end)
    
    friendGrabs[targetName] = {
        conn = conn,
        target = target,
    }
end

-- ==============================================
-- 2. ANTI KICK ДЛЯ ДРУЗЕЙ (Shuriken)
-- ==============================================

local function clearFriendShurikens()
    for targetName, data in pairs(friendShurikens) do
        pcall(function()
            if data.toy and data.toy.Parent then
                DestroyToy:FireServer(data.toy)
            end
        end)
    end
    friendShurikens = {}
end

local function attachShurikenToFriend(targetName)
    local target = Players:FindFirstChild(targetName)
    if not target or not target.Character then return end
    
    local targetChar = target.Character
    local targetHRP = targetChar:FindFirstChild("HumanoidRootPart")
    local targetFirePart = targetHRP and targetHRP:FindFirstChild("FirePlayerPart")
    
    if not targetHRP or not targetFirePart then return end
    
    -- Проверяем дистанцию только если TPP включён
    if tppEnabled and plr.Character and plr.Character:FindFirstChild("HumanoidRootPart") then
        local dist = (targetHRP.Position - plr.Character.HumanoidRootPart.Position).Magnitude
        if dist > 40 then return end
    end
    
    -- Спавним ширикен
    local function spawnShurikenForFriend()
        if not plr.CanSpawnToy.Value then
            plr.CanSpawnToy.Changed:Wait()
        end
        
        local inv = Workspace:FindFirstChild(plr.Name .. "SpawnedInToys")
        if not inv then return nil end
        
        local shu = nil
        local conn = inv.ChildAdded:Connect(function(c)
            if c.Name == "NinjaShuriken" then
                shu = c
                conn:Disconnect()
            end
        end)
        
        task.spawn(function()
            SpawnToyRemote:InvokeServer("NinjaShuriken", targetHRP.CFrame * CFrame.new(5, 10, 20), Vector3.zero)
        end)
        
        local start = tick()
        while not shu and tick() - start < 2 do
            task.wait(0.05)
        end
        return shu
    end
    
    local shu = spawnShurikenForFriend()
    if not shu then return end
    
    local part = shu:WaitForChild("StickyPart", 0.5)
    if not part then
        pcall(function() DestroyToy:FireServer(shu) end)
        return
    end
    
    -- Забираем овнершип
    SetNetworkOwner:FireServer(part, part.CFrame)
    task.wait(0.1)
    
    -- Приклеиваем к другу
    StickyEvent:FireServer(part, targetFirePart, CFrame.new(0, 0, 0, 1, 0, 0, 0, 0, -1, 0, 1, 0))
    
    -- Прячем ширикен
    for _, v in pairs(shu:GetDescendants()) do
        if v:IsA("BasePart") then
            v.CanTouch = false
            v.CanCollide = false
            v.CanQuery = false
            v.Transparency = 1
        end
    end
    
    shu.Name = "TPPShuriken_" .. targetName
    friendShurikens[targetName] = {
        toy = shu,
        part = part,
    }
end

-- ==============================================
-- 4. ANTI EXPLOSION ДЛЯ ДРУЗЕЙ
-- ==============================================

local function clearFriendExplosionProtection()
    for targetName, data in pairs(friendExplosionProtection) do
        if data.conn then
            pcall(function() data.conn:Disconnect() end)
        end
    end
    friendExplosionProtection = {}
end

local function protectFriendFromExplosions(targetName)
    local target = Players:FindFirstChild(targetName)
    if not target or not target.Character then return end
    
    local targetChar = target.Character
    local targetHRP = targetChar:FindFirstChild("HumanoidRootPart")
    
    if not targetHRP then return end
    
    -- Создаём коннект для защиты от взрывов
    local conn = Workspace.ChildAdded:Connect(function(model)
        if not tppEnabled or not friendAntiExplosionEnabled then return end
        if model.Name ~= "Part" then return end
        if not target.Character or not target.Character:FindFirstChild("HumanoidRootPart") then return end
        
        local tHRP = target.Character.HumanoidRootPart
        local mag = (model.Position - tHRP.Position).Magnitude
        
        if mag <= 20 then
            pcall(function()
                tHRP.Anchored = true
                task.wait(0.01)
                
                local rightArm = target.Character:FindFirstChild("Right Arm")
                if rightArm then
                    local ragdollPart = rightArm:FindFirstChild("RagdollLimbPart")
                    if ragdollPart then
                        while ragdollPart.CanCollide and tppEnabled and friendAntiExplosionEnabled do
                            task.wait(0.001)
                        end
                    end
                end
                
                if tppEnabled and friendAntiExplosionEnabled then
                    tHRP.Anchored = false
                end
            end)
        end
    end)
    
    friendExplosionProtection[targetName] = {
        conn = conn,
        target = target,
    }
end

-- ==============================================
-- ФУНКЦИИ ОБНОВЛЕНИЯ ВСЕЙ ЗАЩИТЫ
-- ==============================================

local function updateAllFriendProtection()
    -- Очищаем всё
    clearFriendShurikens()
    clearFriendFireExtinguishers()
    clearFriendGrabs()
    clearFriendExplosionProtection()
    
    if not tppEnabled then return end
    
    task.wait(0.2)
    
    for _, targetName in ipairs(tppTargets) do
        if friendAntiKickEnabled then
            attachShurikenToFriend(targetName)
        end
        if friendAntiFireEnabled then
            attachFireExtinguisherToFriend(targetName)
        end
        if friendAntiGrabEnabled then
            protectFriendFromGrab(targetName)
        end
        if friendAntiExplosionEnabled then
            protectFriendFromExplosions(targetName)
        end
    end
end

-- ==============================================
-- UI ЭЛЕМЕНТЫ
-- ==============================================

tppDropdown = DefT:AddDropdown("TPPTarget", {
    Text = "Защищать игроков",
    Values = {},
    Default = {},
    Multi = true,
    Tooltip = "Выбери игроков на которых будет дейстовать защита",
    Callback = function(v)
        tppTargets = {}
        if typeof(v) == "table" then
            for key, state in pairs(v) do
                if state == true then
                    local name = key:match("%((.-)%)")
                    if name then
                        table.insert(tppTargets, name)
                    end
                end
            end
        end
        task.wait(0.3)
        updateAllFriendProtection()
    end
})

DefT:AddButton({
    Text = "refresh",
    Tooltip = "Обновляет список игроков",
    Func = refreshPlayers
})

DefT:AddButton({
    Text = "clear all",
    Tooltip = "Убирает всех из списка дефа",
    Func = function()
        tppTargets = {}
        tppDropdown:SetValue({})
        clearAllFriendProtection()
    end
})

tppCountLabel = DefT:AddLabel("Защищается: 0 игроков")
tppStatusLabel = DefT:AddLabel("Статус: Отключено")

task.spawn(function()
    while task.wait(0.5) do
        if tppCountLabel then
            tppCountLabel:SetText("Защищается: " .. #tppTargets .. " игроков")
        end
        if tppStatusLabel then
            if not tppEnabled then
                tppStatusLabel:SetText("Статус: Отключено")
            elseif #tppTargets == 0 then
                tppStatusLabel:SetText("Статус: Нет целей")
            else
                tppStatusLabel:SetText("Статус: Активно - " .. #tppTargets .. " целей")
            end
        end
    end
end)

DefT:AddDropdown("TPPMethod", {
    Text = "Метод",
    Values = {"Grab", "Bring"},
    Default = "Grab",
    Tooltip = "Метод защиты (Grab - перехват Bring - притягивание)",
    Callback = function(v)
        tppMethod = v
    end
})

-- ==============================================
-- ГЛАВНЫЙ ТОГГЛ TPP
-- ==============================================
DefT:AddToggle("TPPEnabled", {
    Text = "Third Party Protection",
    Default = false,
    Tooltip = "включает защиту от третьих лиц (все функции работают только при включённом)",
    Callback = function(v)
        tppEnabled = v
        if v then
            runTPPLoop()
            -- Запускаем фоновые задачи для поддержки
            if friendAntiKickEnabled then
                if friendAntiKickTask then task.cancel(friendAntiKickTask) end
                friendAntiKickTask = task.spawn(function()
                    while tppEnabled and friendAntiKickEnabled do
                        task.wait(3)
                        for _, targetName in ipairs(tppTargets) do
                            local data = friendShurikens[targetName]
                            if not data or not data.toy or not data.toy.Parent then
                                attachShurikenToFriend(targetName)
                            end
                        end
                    end
                end)
            end
            
            if friendAntiFireEnabled then
                if friendAntiFireTask then task.cancel(friendAntiFireTask) end
                friendAntiFireTask = task.spawn(function()
                    while tppEnabled and friendAntiFireEnabled do
                        task.wait(3)
                        for _, targetName in ipairs(tppTargets) do
                            local data = friendFireExtinguishers[targetName]
                            if not data or not data.toy or not data.toy.Parent then
                                attachFireExtinguisherToFriend(targetName)
                            end
                        end
                    end
                end)
            end
            
            updateAllFriendProtection()
        else
            clearAllFriendProtection()
            if friendAntiKickTask then
                task.cancel(friendAntiKickTask)
                friendAntiKickTask = nil
            end
            if friendAntiFireTask then
                task.cancel(friendAntiFireTask)
                friendAntiFireTask = nil
            end
        end
    end
})

-- ==============================================
-- ANTI GRAB
-- ==============================================

-- Переменные
local friendAntiGrabEnabled = false
local friendGrabs = {}

-- Очистка
local function clearFriendGrabs()
    for targetName, data in pairs(friendGrabs) do
        if data.conn then
            pcall(function() data.conn:Disconnect() end)
        end
    end
    friendGrabs = {}
end

-- Защита от граба для одного друга
local function protectFriendFromGrab(targetName)
    local target = Players:FindFirstChild(targetName)
    if not target or not target.Character then return end
    
    local targetChar = target.Character
    local targetHRP = targetChar:FindFirstChild("HumanoidRootPart")
    local targetHum = targetChar:FindFirstChild("Humanoid")
    
    if not targetHRP or not targetHum then return end
    
    -- Слушаем IsHeld друга
    local conn = target:WaitForChild("IsHeld"):GetPropertyChangedSignal("Value"):Connect(function()
        -- Проверки: включён ли TPP, включён ли Anti Grab, держат ли друга
        if not tppEnabled or not friendAntiGrabEnabled then return end
        if not target.IsHeld.Value then return end
        if not target.Character then return end
        
        local char = target.Character
        local root = char:FindFirstChild("HumanoidRootPart")
        local hum = char:FindFirstChild("Humanoid")
        if not root or not hum then return end
        
        -- МГНОВЕННО отпускаем граб
        pcall(function()
            -- Струггл (с передачей друга)
            Struggle:FireServer(target)
            -- Рагдолл (минимальный)
            RagdollRemote:FireServer(root, 0)
            -- Остановка всей скорости
            if RS.GameCorrectionEvents and RS.GameCorrectionEvents.StopAllVelocity then
                RS.GameCorrectionEvents.StopAllVelocity:FireServer()
            end
            -- Снимаем сидение
            hum.Sit = false
            -- Встаём
            hum:ChangeState(Enum.HumanoidStateType.GettingUp)
            -- Разрешаем прыжок
            hum:SetStateEnabled(Enum.HumanoidStateType.Jumping, true)
            -- Обнуляем скорость
            root.AssemblyLinearVelocity = Vector3.zero
            root.AssemblyAngularVelocity = Vector3.zero
        end)
        
        -- Возвращаем коллизию частей тела
        for _, part in pairs(char:GetDescendants()) do
            if part:IsA("BasePart") then
                part.CanCollide = true
            end
        end
    end)
    
    -- Сохраняем коннект
    friendGrabs[targetName] = {
        conn = conn,
        target = target,
    }
end

-- Обновление защиты для всех друзей
local function updateFriendGrabProtection()
    -- Если TPP выключен или Anti Grab выключен — очищаем всё
    if not tppEnabled or not friendAntiGrabEnabled then
        clearFriendGrabs()
        return
    end
    
    -- Для каждого выбранного друга
    for _, targetName in ipairs(tppTargets) do
        -- Если защиты нет — создаём
        if not friendGrabs[targetName] or not friendGrabs[targetName].conn then
            protectFriendFromGrab(targetName)
        end
    end
end

-- ==============================================
-- TOGGLE ANTI GRAB
-- ==============================================
DefT:AddToggle("FriendAntiGrab", {
    Text = "Anti Grab для друзей",
    Default = false,
    Tooltip = "Мгновенно отпускает друга, если его схватили",
    Callback = function(Value)
        friendAntiGrabEnabled = Value
        if tppEnabled then
            updateFriendGrabProtection()
        end
    end
})

-- ==============================================
-- ANTI KICK
-- ==============================================
DefT:AddToggle("FriendAntiKick", {
    Text = "Anti Kick для друзей (Shuriken)",
    Default = false,
    Tooltip = "Приклеивает сюрикен к другу для защиты от кика (работает только при включённом TPP)",
    Callback = function(Value)
        friendAntiKickEnabled = Value
        
        if Value then
            if not friendAntiKickRespawnConn then
                friendAntiKickRespawnConn = plr.CharacterAdded:Connect(function()
                    task.wait(1)
                    if tppEnabled and friendAntiKickEnabled then
                        updateAllFriendProtection()
                    end
                end)
            end
            if tppEnabled then
                updateAllFriendProtection()
                if friendAntiKickTask then task.cancel(friendAntiKickTask) end
                friendAntiKickTask = task.spawn(function()
                    while tppEnabled and friendAntiKickEnabled do
                        task.wait(3)
                        for _, targetName in ipairs(tppTargets) do
                            local data = friendShurikens[targetName]
                            if not data or not data.toy or not data.toy.Parent then
                                attachShurikenToFriend(targetName)
                            end
                        end
                    end
                end)
            end
        else
            if tppEnabled then
                clearFriendShurikens()
            end
            if friendAntiKickRespawnConn then
                friendAntiKickRespawnConn:Disconnect()
                friendAntiKickRespawnConn = nil
            end
            if friendAntiKickTask then
                task.cancel(friendAntiKickTask)
                friendAntiKickTask = nil
            end
        end
    end
})

-- ==============================================
-- ANTI EXPLOSION
-- ==============================================
DefT:AddToggle("FriendAntiExplosion", {
    Text = "Anti Explosion для друзей",
    Default = false,
    Tooltip = "Защищает друга от взрывов (работает только при включённом TPP)",
    Callback = function(Value)
        friendAntiExplosionEnabled = Value
        if tppEnabled then
            updateAllFriendProtection()
        end
    end
})

-- ==============================================
-- ФУНКЦИЯ ПОЛНОЙ ОЧИСТКИ
-- ==============================================
function clearAllFriendProtection()
    clearFriendShurikens()
    clearFriendFireExtinguishers()
    clearFriendGrabs()
    clearFriendExplosionProtection()
end

-- ==============================================
-- ИНИЦИАЛИЗАЦИЯ
-- ==============================================
refreshPlayers()
Players.PlayerAdded:Connect(refreshPlayers)
Players.PlayerRemoving:Connect(function()
    task.wait(0.1)
    refreshPlayers()
end)

-- Подписываемся на изменение списка целей
local originalCallback = tppDropdown.Callback
tppDropdown.Callback = function(v)
    if originalCallback then
        originalCallback(v)
    end
    task.wait(0.3)
    if tppEnabled then
        updateAllFriendProtection()
    end
end

-- ==============================================
-- ВКЛАДКА TARGET SELECTOR (ПЕРЕДЕЛАНО ПОД OBSIDIAN UI)
-- ==============================================

local TargetGroup = Tabs.Target:AddLeftGroupbox("Target Selector", "crosshair")

-- ==============================================
-- ГЛОБАЛЬНЫЕ ПЕРЕМЕННЫЕ (ДЛЯ DEFENSE)
-- ==============================================
SelectedPlayer = nil
lastGrabberDisplay = 'None'
lastGrabberName = nil
_selectedPlayers = {}
_killRoundIndex = 1
_dropdownUpdating = false
_previouslyTargeted = {}
_tracerEnabled = false
_tracerConnections = {}
_tracerParts = {}
_tracerObjects = {}
_isViewing = false

PLOT_NAMES = {
    [1] = 'Blue House',
    [2] = 'Pink House',
    [3] = 'Spooky House',
    [4] = 'Chinese House',
    [5] = 'Green House',
}
PLOT_COLORS = {
    [1] = '#5eb8ff',
    [2] = '#ff85c2',
    [3] = '#b06fff',
    [4] = '#ffcc55',
    [5] = '#55e87a',
}

-- ==============================================
-- ЦИКЛИЧЕСКИЙ ВЫБОР ЦЕЛИ
-- ==============================================
RunService.Heartbeat:Connect(function()
    if #_selectedPlayers == 0 then
        SelectedPlayer = nil
        return
    end
    if _killRoundIndex > #_selectedPlayers then
        _killRoundIndex = 1
    end
    SelectedPlayer = _selectedPlayers[_killRoundIndex]
    _killRoundIndex = _killRoundIndex % #_selectedPlayers + 1
end)

-- ==============================================
-- ФУНКЦИИ
-- ==============================================
function getPlayerList()
    local list = {}
    for _, plr in pairs(Players:GetPlayers()) do
        if plr ~= LocalPlayer then
            table.insert(list, plr.DisplayName .. ' (@' .. plr.Name .. ')')
        end
    end
    return list
end

function extractUsername(entry)
    return entry and entry:match('@([%w_]+)')
end

function getSelectedPlayer()
    for _, un in pairs(_selectedPlayers) do
        local p = Players:FindFirstChild(un)
        if p then
            return p
        end
    end
    return nil
end

function _syncPreviousTargets()
    for _, un in pairs(_selectedPlayers) do
        _previouslyTargeted[un] = true
    end
end

function _removeFromTargets(username)
    for i, un in pairs(_selectedPlayers) do
        if un == username then
            table.remove(_selectedPlayers, i)
            break
        end
    end
end

function _refreshDropdown()
    _dropdownUpdating = true
    PlayerDropdown:SetValues(getPlayerList())
    _dropdownUpdating = false
end

function getPlayerPlot(player)
    local plotsFolder = workspace:FindFirstChild('Plots') or workspace:FindFirstChild('plots')
    if not plotsFolder then
        return nil, nil
    end
    for i = 1, 5 do
        local plot = plotsFolder:FindFirstChild('Plot' .. i)
        if plot then
            for _, desc in pairs(plot:GetDescendants()) do
                local vt = desc.ClassName
                if vt == 'StringValue' or vt == 'ObjectValue' or vt == 'IntValue' then
                    local ok, v = pcall(function()
                        return tostring(desc.Value)
                    end)
                    if ok and v and v:find(player.Name, 1, true) then
                        return plot, i
                    end
                end
            end
        end
    end
    return nil, nil
end

function targetInPlot(player)
    if not player or not player.Character then
        return false
    end
    local hrp = player.Character:FindFirstChild('HumanoidRootPart')
    local plot = getPlayerPlot(player)
    if not hrp or not plot then
        return false
    end
    local base = plot:FindFirstChild('Base') or plot:FindFirstChildWhichIsA('BasePart')
    if not base then
        return false
    end
    local pos = base.CFrame:PointToObjectSpace(hrp.Position)
    local half = base.Size / 2
    return math.abs(pos.X) <= half.X and math.abs(pos.Z) <= half.Z and math.abs(pos.Y) <= (half.Y + 25)
end

function getPlotRichText(player)
    local plot, idx = getPlayerPlot(player)
    if not plot or not idx then
        return "<font color='#555555'>None</font>"
    end
    local name = PLOT_NAMES[idx] or ('Plot ' .. idx)
    local col = PLOT_COLORS[idx] or '#ffffff'
    local inside = targetInPlot(player)
    local tag = inside and "  <font color='#55e87a'>[Inside]</font>" or "  <font color='#ffaa33'>[Nearby]</font>"
    return "<font color='" .. col .. "'><b>" .. name .. '</b></font>' .. tag
end

_currentAvatarUserId = nil

function _updateAvatarDisplay()
    local primary = _selectedPlayers[1] and Players:FindFirstChild(_selectedPlayers[1])
    if not primary then
        _currentAvatarUserId = nil
        pcall(function()
            AvatarImage:SetImage('rbxassetid://0')
        end)
        return
    end
    local uid = primary.UserId
    if uid == _currentAvatarUserId then
        return
    end
    _currentAvatarUserId = uid
    task.spawn(function()
        local ok, content = pcall(Players.GetUserThumbnailAsync, Players, uid, Enum.ThumbnailType.AvatarBust, Enum.ThumbnailSize.Size420x420)
        if ok and content and content ~= '' then
            pcall(function()
                AvatarImage:SetImage(content)
            end)
        end
    end)
end

_tracerObjects = {}

function _cleanupTracers()
    for _, c in pairs(_tracerConnections) do
        pcall(function()
            c:Disconnect()
        end)
    end
    for _, obj in pairs(_tracerObjects) do
        pcall(function()
            obj.line:Remove()
        end)
        pcall(function()
            if obj.shadow then
                obj.shadow:Remove()
            end
        end)
        pcall(function()
            if obj.dot then
                obj.dot:Remove()
            end
        end)
        pcall(function()
            obj.highlight:Destroy()
        end)
    end
    _tracerConnections = {}
    _tracerObjects = {}
    for _, p in pairs(_tracerParts) do
        pcall(function()
            p:Destroy()
        end)
    end
    _tracerParts = {}
end

function _buildTracerFor(plr)
    if not plr or not plr.Character then
        return
    end
    local char = plr.Character
    local hrp = char:FindFirstChild('HumanoidRootPart')
    if not hrp then
        return
    end
    local hl = Instance.new('Highlight')
    hl.Name = '_PhantHL_' .. plr.Name
    hl.Adornee = char
    hl.OutlineColor = Color3.fromRGB(255, 255, 255)
    hl.OutlineTransparency = 0
    hl.FillColor = Color3.fromRGB(255, 255, 255)
    hl.FillTransparency = 1
    hl.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
    hl.Parent = char
    
    local shadow = Drawing.new('Line')
    shadow.Thickness = 3
    shadow.Color = Color3.fromRGB(20, 20, 20)
    shadow.Transparency = 0.55
    shadow.Visible = false
    
    local core = Drawing.new('Line')
    core.Thickness = 1.5
    core.Color = Color3.fromRGB(255, 255, 255)
    core.Transparency = 1
    core.Visible = false
    
    local dot = Drawing.new('Circle')
    dot.Radius = 3
    dot.Color = Color3.fromRGB(255, 80, 80)
    dot.Thickness = 1.5
    dot.Filled = true
    dot.Transparency = 1
    dot.Visible = false
    
    local camera = Workspace.CurrentCamera

    local function getOrigin()
        local vp = camera.ViewportSize
        return Vector2.new(vp.X * 0.5, vp.Y)
    end

    local conn = RunService.RenderStepped:Connect(function()
        if not _tracerEnabled then
            return
        end
        if not hrp or not hrp.Parent then
            core.Visible = false
            shadow.Visible = false
            dot.Visible = false
            return
        end
        local origin = getOrigin()
        local cam = camera
        local toTarget = hrp.Position - cam.CFrame.Position
        local lookVec = cam.CFrame.LookVector
        local inFront = toTarget:Dot(lookVec) > 0
        local tipPos
        if inFront then
            local screenPos, onScreen = cam:WorldToViewportPoint(hrp.Position)
            if onScreen then
                tipPos = Vector2.new(screenPos.X, screenPos.Y)
            else
                local vp = cam.ViewportSize
                local raw = Vector2.new(screenPos.X, screenPos.Y)
                tipPos = Vector2.new(math.clamp(raw.X, 0, vp.X), math.clamp(raw.Y, 0, vp.Y))
            end
        else
            local vp = cam.ViewportSize
            local centre = Vector2.new(vp.X * 0.5, vp.Y * 0.5)
            local rightVec = cam.CFrame.RightVector
            local upVec = cam.CFrame.UpVector
            local sx = toTarget:Dot(rightVec)
            local sy = -toTarget:Dot(upVec)
            local dir2 = Vector2.new(sx, sy)
            if dir2.Magnitude > 0 then
                dir2 = dir2.Unit
            end
            local edgeX = sx > 0 and (vp.X - 10) or 10
            local edgeY = math.clamp(centre.Y + dir2.Y * vp.Y * 0.4, 10, vp.Y - 10)
            tipPos = Vector2.new(edgeX, edgeY)
        end
        core.From = origin
        core.To = tipPos
        core.Visible = true
        shadow.From = origin
        shadow.To = tipPos
        shadow.Visible = true
        dot.Position = tipPos
        dot.Visible = true
        if hl.Adornee ~= plr.Character then
            hl.Adornee = plr.Character
        end
    end)

    table.insert(_tracerConnections, conn)
    table.insert(_tracerObjects, {
        line = core,
        shadow = shadow,
        dot = dot,
        highlight = hl,
        conn = conn,
        username = plr.Name,
    })
end

function _rebuildTracers()
    _cleanupTracers()
    if not _tracerEnabled then
        return
    end
    for _, un in pairs(_selectedPlayers) do
        local plr = Players:FindFirstChild(un)
        if plr then
            _buildTracerFor(plr)
        end
    end
end

-- ==============================================
-- ОСНОВНЫЕ ФУНКЦИИ
-- ==============================================
function setTargetsFromTable(selectedMap, source)
    _selectedPlayers = {}
    for entry, state in pairs(selectedMap) do
        if state then
            local un = extractUsername(entry)
            if un then
                local plr = Players:FindFirstChild(un)
                if plr and plr ~= LocalPlayer then
                    table.insert(_selectedPlayers, un)
                end
            end
        end
    end
    _killRoundIndex = 1
    _syncPreviousTargets()
    
    local first = _selectedPlayers[1] and Players:FindFirstChild(_selectedPlayers[1])
    if first then
        pcall(function()
            BlobmanTarget:SetValue(first.DisplayName .. ' (' .. first.Name .. ')')
        end)
        pcall(function()
            GrabTarget:SetValue(first.DisplayName .. ' (' .. first.Name .. ')')
        end)
    end
    
    local count = #_selectedPlayers
    local src = source and (' [' .. source .. ']') or ''
    if count == 0 then
        Library:Notify({Title = "Target", Description = "No targets selected", Duration = 2})
    elseif count == 1 then
        local p = Players:FindFirstChild(_selectedPlayers[1])
        Library:Notify({Title = "Target set" .. src, Description = p and (p.DisplayName .. ' (@' .. p.Name .. ')') or _selectedPlayers[1], Duration = 4})
    else
        Library:Notify({Title = "Target set" .. src, Description = count .. ' players targeted', Duration = 4})
    end
    _updateAvatarDisplay()
    if _tracerEnabled then
        _rebuildTracers()
    end
end

function addTarget(plr, sourceTag)
    if plr == LocalPlayer then
        return
    end
    for _, un in pairs(_selectedPlayers) do
        if un == plr.Name then
            Library:Notify({Title = "Target", Description = plr.DisplayName .. ' is already selected in your dropdown.', Duration = 2})
            return
        end
    end
    table.insert(_selectedPlayers, plr.Name)
    _previouslyTargeted[plr.Name] = true
    _dropdownUpdating = true
    pcall(function()
        PlayerDropdown:SetValue(plr.DisplayName .. ' (@' .. plr.Name .. ')')
    end)
    _dropdownUpdating = false
    Library:Notify({Title = "Target added", Description = plr.DisplayName .. ' (@' .. plr.Name .. ')', Duration = 4})
    _updateAvatarDisplay()
    if _tracerEnabled then
        _rebuildTracers()
    end
end

-- ==============================================
-- UI ЭЛЕМЕНТЫ
-- ==============================================
TargetGroup:AddDivider()

AvatarImage = TargetGroup:AddImage("AvatarDisplay", {
    Image = 'rbxassetid://0',
})

TargetGroup:AddDivider()

SelectedLabel = TargetGroup:AddLabel("<b><font color='#aaaaaa'>Selected</font></b> <font color='#888888'>None</font>")
TargetDistLabel = TargetGroup:AddLabel("<b><font color='#aaaaaa'>Distance</font></b>  <font color='#555555'>\u{2014}</font>")
LastGrabberLabel = TargetGroup:AddLabel("<b><font color='#aaaaaa'>Last Grabber</font></b> <font color='#888888'>None</font>")

TargetGroup:AddDivider()

PlayerDropdown = TargetGroup:AddDropdown("PlayerDropdown", {
    Text = "Select A Target",
    Values = getPlayerList(),
    Default = {},
    Multi = true,
    Callback = function(v)
        if _dropdownUpdating then
            return
        end
        setTargetsFromTable(v, 'Dropdown')
    end
})

TargetGroup:AddDivider()

-- ==============================================
-- КНОПКА REFRESH (ДОБАВЛЕНО)
-- ==============================================
TargetGroup:AddButton({
    Text = "Refresh Players",
    Tooltip = "Обновить список игроков в дропдауне",
    Func = function()
        _refreshDropdown()
        Library:Notify({Title = "Target", Description = "Player list refreshed", Duration = 2})
    end,
})

TargetGroup:AddDivider()

-- ==============================================
-- VIEW TARGET
-- ==============================================
local ViewButton = TargetGroup:AddButton({
    Text = "View Target",
    Func = function()
        if _isViewing then
            local char = LocalPlayer.Character
            local hum = char and char:FindFirstChildOfClass('Humanoid')
            if hum then
                workspace.CurrentCamera.CameraSubject = hum
            end
            workspace.CurrentCamera.CameraType = Enum.CameraType.Custom
            _isViewing = false
            ViewButton:SetText("View Target")
            Library:Notify({Title = "View", Description = "Camera restored", Duration = 2})
        else
            local plr = _selectedPlayers[1] and Players:FindFirstChild(_selectedPlayers[1])
            if not plr or not plr.Character then
                return Library:Notify({Title = "View", Description = "No valid target", Duration = 2})
            end
            local hrp = plr.Character:FindFirstChild('HumanoidRootPart')
            if not hrp then
                return Library:Notify({Title = "View", Description = "No character root", Duration = 2})
            end
            workspace.CurrentCamera.CameraSubject = hrp
            workspace.CurrentCamera.CameraType = Enum.CameraType.Follow
            _isViewing = true
            ViewButton:SetText("<b><font color='#55e87a'>Unview Target</font></b>")
            Library:Notify({Title = "View", Description = "Now viewing " .. plr.DisplayName, Duration = 3})
        end
    end,
})

TargetGroup:AddButton({
    Text = "<b><font color='#ff5050'>Clear All Targets</font></b>",
    Func = function()
        _selectedPlayers = {}
        _previouslyTargeted = {}
        _killRoundIndex = 1
        SelectedPlayer = nil
        _tracerEnabled = false
        _cleanupTracers()
        if _isViewing then
            local char = LocalPlayer.Character
            local hum = char and char:FindFirstChildOfClass('Humanoid')
            if hum then
                workspace.CurrentCamera.CameraSubject = hum
            end
            workspace.CurrentCamera.CameraType = Enum.CameraType.Custom
            _isViewing = false
            ViewButton:SetText("View Target")
        end
        _refreshDropdown()
        _updateAvatarDisplay()
        Library:Notify({Title = "Target", Description = "All targets cleared", Duration = 2})
    end,
})

TargetGroup:AddDivider()

-- ==============================================
-- УБРАЛ Add Target (LeftAlt) — КАК ТЫ ПРОСИЛ
-- ==============================================

-- ==============================================
-- ФОНОВОЕ ОБНОВЛЕНИЕ UI
-- ==============================================
task.spawn(function()
    local prev = {
        sel = '',
        dist = '',
        grab = '',
    }
    while true do
        task.wait(0.5)
        local g = "<b><font color='#aaaaaa'>Last Grabber</font></b> <font color='#ff9955'>" .. lastGrabberDisplay .. '</font>'
        if g ~= prev.grab then
            prev.grab = g
            LastGrabberLabel:SetText(g)
        end
        
        local count = #_selectedPlayers
        local sel
        if count == 0 then
            sel = "<b><font color='#aaaaaa'>Selected</font></b> <font color='#555555'>None</font>"
        elseif count == 1 then
            local p = Players:FindFirstChild(_selectedPlayers[1])
            if p then
                sel = "<b><font color='#aaaaaa'>Selected</font></b> " .. "<font color='#fff'>" .. p.DisplayName .. '</font>' .. "<font color='#777'> (@" .. p.Name .. ')</font>'
            else
                sel = "<b><font color='#aaaaaa'>Selected</font></b> <font color='#555555'>left</font>"
            end
        else
            local t = {}
            for _, n in pairs(_selectedPlayers) do
                local p = Players:FindFirstChild(n)
                table.insert(t, p and p.DisplayName or n)
            end
            sel = "<b><font color='#aaaaaa'>Selected</font></b> " .. "<font color='#fff'>" .. table.concat(t, ', ') .. '</font>'
        end
        if sel ~= prev.sel then
            prev.sel = sel
            SelectedLabel:SetText(sel)
        end
        
        local primary = _selectedPlayers[1] and Players:FindFirstChild(_selectedPlayers[1])
        local distText
        if primary and primary.Character then
            local hrp = primary.Character:FindFirstChild('HumanoidRootPart')
            local lhrp = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild('HumanoidRootPart')
            if hrp and lhrp then
                local d = math.floor((hrp.Position - lhrp.Position).Magnitude)
                local col = '#55e87a'
                if d < 50 then
                    col = '#ff5050'
                elseif d < 150 then
                    col = '#ffcc55'
                end
                distText = "<b><font color='#aaaaaa'>Distance</font></b> " .. "<font color='" .. col .. "'><b>" .. d .. ' studs</b></font>'
            end
        end
        distText = distText or "<b><font color='#aaaaaa'>Distance</font></b> <font color='#555555'>\u{2014}</font>"
        if distText ~= prev.dist then
            prev.dist = distText
            TargetDistLabel:SetText(distText)
        end
    end
end)

-- ==============================================
-- ОБРАБОТЧИКИ ИГРОКОВ
-- ==============================================
Players.PlayerAdded:Connect(function(plr)
    task.wait(0.5)
    if _previouslyTargeted[plr.Name] and plr ~= LocalPlayer then
        table.insert(_selectedPlayers, plr.Name)
        _killRoundIndex = 1
        _dropdownUpdating = true
        pcall(function()
            PlayerDropdown:SetValue(plr.DisplayName .. ' (@' .. plr.Name .. ')')
        end)
        _dropdownUpdating = false
        Library:Notify({Title = "Target Rejoined", Description = plr.DisplayName, Duration = 6})
        if _tracerEnabled then
            task.wait(1)
            _rebuildTracers()
        end
    end
    _refreshDropdown()
end)

Players.PlayerRemoving:Connect(function(plr)
    task.wait(0.5)
    _removeFromTargets(plr.Name)
    _refreshDropdown()
end)

-- ==============================================
-- АВТООБНОВЛЕНИЕ КАЖДЫЕ 3 СЕКУНДЫ
-- ==============================================
task.spawn(function()
    while true do
        task.wait(3)
        _refreshDropdown()
    end
end)

-- ==============================================
-- ИНИЦИАЛИЗАЦИЯ
-- ==============================================
_refreshDropdown()
_updateAvatarDisplay()

-- ==============================================
-- ПРАВАЯ СТОРОНА (ВЕРХ): NO BLOBMAN METHODS
-- ==============================================
local NoBlobGroup = Tabs.Target:AddGroupbox({
    Side = "Right",
    Name = "No blobman methods",
    IconName = "axe",
})

-- ==============================================
-- 1. LOOP KILL
-- ==============================================
do
    local loopKillActive = false
    local loopKillHB = nil
    local loopKillCameraAnchor = nil
    local HEIGHT_LIMIT = 100000
    local TELEPORT_OFFSET = Vector3.new(6, -18.5, 0)
    
    local function isTooHigh(player)
        local c = player.Character
        local hrp = c and c:FindFirstChild("HumanoidRootPart")
        return not hrp or hrp.Position.Y > HEIGHT_LIMIT
    end

    local function setNoCollideChar(char)
        for _, v in pairs(char:GetDescendants()) do
            if v:IsA("BasePart") then v.CanCollide = false end
        end
    end

    local function saveOriginalPos()
        local char = plr.Character
        local hrp = char and char:FindFirstChild("HumanoidRootPart")
        if hrp then char:SetAttribute("OriginalPosition", hrp:GetPivot()) end
    end

    local function getOriginalPos()
        local char = plr.Character
        return char and char:GetAttribute("OriginalPosition") or nil
    end

    local function findBlobman()
        local toys = Workspace:FindFirstChild(plr.Name .. "SpawnedInToys")
        return toys and toys:FindFirstChild("CreatureBlobman") or nil
    end

    local function ensureBlobman()
        local b = findBlobman()
        if b then return b end
        pcall(function()
            local SpawnToy = RS.MenuToys.SpawnToyRemoteFunction
            if SpawnToy then
                SpawnToy:InvokeServer("CreatureBlobman", plr.Character.HumanoidRootPart.CFrame * CFrame.new(0, 0, -5), Vector3.new(0, -15, 0))
            end
        end)
        for _ = 1, 30 do
            task.wait(0.1)
            local b = findBlobman()
            if b then return b end
        end
        return nil
    end

    local function modifyTarget(root, hum)
        if not (root and hum) or hum.Health <= 0 then return end
        local blob = ensureBlobman()
        if blob and blob:FindFirstChild("BlobmanSeatAndOwnerScript") then
            local drop = blob.BlobmanSeatAndOwnerScript:FindFirstChild("CreatureDrop")
            if drop then
                for _, part in pairs(hum.Parent:GetDescendants()) do
                    if part:IsA("Weld") or part:IsA("BallSocketConstraint") then
                        drop:FireServer(part, part)
                    end
                end
            end
        end
        hum.Sit = false
        hum:ChangeState(Enum.HumanoidStateType.Running)
        hum:SetStateEnabled(Enum.HumanoidStateType.Seated, false)
        hum:ChangeState(Enum.HumanoidStateType.GettingUp)

        local player = Players:GetPlayerFromCharacter(hum.Parent)
        if player and player:FindFirstChild("IsHeld") then player.IsHeld.Value = false end
        local rag = hum:FindFirstChild("Ragdolled")
        if rag then rag.Value = false end

        local bv = Instance.new("BodyVelocity")
        local bav = Instance.new("BodyAngularVelocity")
        bv.MaxForce = Vector3.new(1e7, -1e7, 1e7)
        bv.P = 1e6
        bv.Velocity = Vector3.new(math.random(-500, 50), -50, math.random(-50, 50))
        bav.MaxTorque = Vector3.new(-1e7, -1e7, -1e7)
        bav.P = 1e6
        bav.AngularVelocity = Vector3.new(math.random(-500, 300), math.random(-300, 300), math.random(-500, 500))
        bv.Parent = root
        bav.Parent = root
        hum.BreakJointsOnDeath = false
        hum:ChangeState(Enum.HumanoidStateType.Dead)
        task.delay(2, function()
            if bv.Parent then bv:Destroy() end
            if bav.Parent then bav:Destroy() end
        end)
    end

    local function performKill()
        if not loopKillActive then return end
        local target = getSelectedPlayer()
        if not target then return end
        local tChar = target and target.Character
        local tRoot = tChar and tChar:FindFirstChild("HumanoidRootPart")
        local tHum = tChar and tChar:FindFirstChild("Humanoid")
        local tHead = tChar and tChar:FindFirstChild("Head")
        
        if not (target and tRoot and tHum and tHead) then return end
        if isTooHigh(target) then return end
        if tHum:GetState() == Enum.HumanoidStateType.Dead then return end

        local char = plr.Character
        local hrp = char and char:FindFirstChild("HumanoidRootPart")
        if not (char and hrp) then return end

        if not char:GetAttribute("SavingOriginalPos") then
            saveOriginalPos()
        end
        char:SetAttribute("SavingOriginalPos", true)
        getgenv().originalFallenHeight = Workspace.FallenPartsDestroyHeight
        Workspace.FallenPartsDestroyHeight = 0/0

        local originalPos = getOriginalPos()
        if originalPos and loopKillCameraAnchor then loopKillCameraAnchor:attach(originalPos) end

        hrp:PivotTo(CFrame.new(tRoot.Position + TELEPORT_OFFSET))
        setNoCollideChar(tChar)
        pcall(function() RS.GrabEvents.SetNetworkOwner:FireServer(tRoot, tRoot.CFrame) end)
        task.wait(0.05)
        pcall(function() RS.GrabEvents.DestroyGrabLine:FireServer(tRoot) end)
        task.wait(0.05)

        if tHead:FindFirstChild("PartOwner") and tHead.PartOwner.Value == plr.Name then
            task.wait(0.05)
            modifyTarget(tRoot, tHum)
        end
        scheduleReturnHome()
    end

    local function scheduleReturnHome()
        if not loopKillActive then return end
        local originalPos = getOriginalPos()
        if not originalPos then return end
        local conn
        conn = RunService.Heartbeat:Connect(function()
            if not loopKillActive then
                conn:Disconnect()
                return
            end
            local char = plr.Character
            local hrp = char and char:FindFirstChild("HumanoidRootPart")
            if hrp then
                hrp:PivotTo(originalPos)
                if getgenv().originalFallenHeight then
                    Workspace.FallenPartsDestroyHeight = getgenv().originalFallenHeight
                end
                char:SetAttribute("SavingOriginalPos", false)
            end
            if loopKillCameraAnchor then loopKillCameraAnchor:detach() end
            conn:Disconnect()
        end)
    end

    NoBlobGroup:AddToggle("LoopKill", {
        Text = "Loop Kill",
        Default = false,
        Tooltip = "Убивает выбранную цель в цикле",
        Callback = function(Value)
            loopKillActive = Value
            
            if not loopKillCameraAnchor then
                loopKillCameraAnchor = {}
                loopKillCameraAnchor.__index = loopKillCameraAnchor
                function loopKillCameraAnchor:attach(cf)
                    self:detach()
                    local p = Instance.new("Part")
                    p.Name = "CameraAnchor"
                    p.Size = Vector3.new(0.2, 0.2, 0.2)
                    p.Transparency = 1
                    p.Anchored = true
                    p.CanCollide = false
                    p.CFrame = cf
                    p.Parent = Workspace
                    self.part = p
                    local cam = Workspace.CurrentCamera
                    cam.CameraType = Enum.CameraType.Custom
                    cam.CameraSubject = p
                end
                function loopKillCameraAnchor:detach()
                    if self.part then self.part:Destroy() self.part = nil end
                    local cam = Workspace.CurrentCamera
                    local char = plr.Character
                    if char and char:FindFirstChild("Humanoid") then
                        cam.CameraSubject = char.Humanoid
                    else
                        cam.CameraType = Enum.CameraType.Custom
                    end
                end
            end
            
            if Value then
                local target = getSelectedPlayer()
                if not target then
                    loopKillActive = false
                    Toggles.LoopKill:SetValue(false)
                    return
                end
                if loopKillHB then loopKillHB:Disconnect() end
                loopKillHB = RunService.Heartbeat:Connect(performKill)
            else
                loopKillActive = false
                if loopKillHB then 
                    loopKillHB:Disconnect() 
                    loopKillHB = nil 
                end
                if loopKillCameraAnchor then 
                    loopKillCameraAnchor:detach() 
                end
                getgenv().originalFallenHeight = nil
                local char = plr.Character
                if char then
                    char:SetAttribute("SavingOriginalPos", false)
                    char:SetAttribute("OriginalPosition", nil)
                end
                Workspace.FallenPartsDestroyHeight = -100
            end
        end
    })
end

-- ==============================================
-- 2. OATS KICK
-- ==============================================
do
    local oatsKickActive = false
    local oatsKickTask = nil
    local oatsKickGrabConnection = nil

    NoBlobGroup:AddToggle("OatsKick", {
        Text = "Oats Kick",
        Default = false,
        Tooltip = "Кикает цель через Oats метод",
        Callback = function(Value)
            oatsKickActive = Value
            
            local function sno(part)
                pcall(function()
                    local grabEvents = RS:FindFirstChild("GrabEvents")
                    local setNetOwner = grabEvents and grabEvents:FindFirstChild("SetNetworkOwner")
                    if setNetOwner then
                        setNetOwner:FireServer(part, part.CFrame)
                    end
                end)
            end
            
            if Value then
                local targetPlayer = getSelectedPlayer()
                if not targetPlayer then
                    oatsKickActive = false
                    Library:Notify({Title = "Oats Kick", Description = "Please select a target first!", Duration = 3})
                    Toggles.OatsKick:SetValue(false)
                    return
                end
                
                if oatsKickGrabConnection then
                    oatsKickGrabConnection:Disconnect()
                    oatsKickGrabConnection = nil
                end
                
                oatsKickGrabConnection = Workspace.ChildAdded:Connect(function(child)
                    if child.Name ~= "GrabParts" then return end
                    if not oatsKickActive then return end
                    
                    local grabPart = child:FindFirstChild("GrabPart")
                    if not grabPart then return end
                    
                    local weld = grabPart:FindFirstChild("WeldConstraint")
                    if not weld then return end
                    
                    local part1 = weld.Part1
                    if not part1 then return end
                    
                    local targetPlayer = Players:GetPlayerFromCharacter(part1.Parent)
                    if not targetPlayer then return end
                    
                    local destroyGrabLineEvent = RS:FindFirstChild("GrabEvents") and RS.GrabEvents:FindFirstChild("DestroyGrabLine")
                    local setNetworkOwnerEvent = RS:FindFirstChild("GrabEvents") and RS.GrabEvents:FindFirstChild("SetNetworkOwner")
                    
                    if not destroyGrabLineEvent or not setNetworkOwnerEvent then return end

                    task.spawn(function()
                        while child.Parent and grabPart.Parent and oatsKickActive do
                            for i = 1, 8 do
                                if not (child.Parent and grabPart.Parent and oatsKickActive) then
                                    break
                                end

                                pcall(function()
                                    destroyGrabLineEvent:FireServer(grabPart)
                                end)
                                RunService.RenderStepped:Wait()

                                if not (child.Parent and grabPart.Parent and oatsKickActive) then
                                    break
                                end

                                pcall(function()
                                    setNetworkOwnerEvent:FireServer(grabPart, grabPart.CFrame)
                                end)
                                RunService.RenderStepped:Wait()
                            end
                            
                            local myChar = plr.Character
                            local myHRP = myChar and myChar:FindFirstChild("HumanoidRootPart")
                            if myHRP and part1 and part1.Parent then
                                local kickPos = myHRP.CFrame * CFrame.new(0, 15, 0)
                                part1.CFrame = kickPos
                                part1.AssemblyLinearVelocity = Vector3.zero
                                part1.AssemblyAngularVelocity = Vector3.zero
                            end
                        end
                    end)
                end)
                
                oatsKickTask = task.spawn(function()
                    local target = targetPlayer
                    
                    local myChar = plr.Character
                    local myHRP = myChar and myChar:FindFirstChild("HumanoidRootPart")
                    if not (myChar and myHRP) then
                        oatsKickActive = false
                        return
                    end

                    local savedPos = myHRP.CFrame
                    local lastRemoteFire = tick()

                    while oatsKickActive and RunService.Heartbeat:Wait() do
                        local targetPlayer = getSelectedPlayer()
                        
                        if not targetPlayer then
                            break
                        end

                        myChar = plr.Character
                        myHRP = myChar and myChar:FindFirstChild("HumanoidRootPart")
                        local myHead = myChar and myChar:FindFirstChild("Head")

                        local tChar = targetPlayer.Character
                        local tHRP = tChar and tChar:FindFirstChild("HumanoidRootPart")
                        local tHum = tChar and tChar:FindFirstChild("Humanoid")

                        if not (myChar and myHRP and myHead) or not (tHRP and tHum) or tHum.Health <= 0 then
                            continue
                        end

                        local dist = (tHRP.Position - myHRP.Position).Magnitude

                        if dist > 30 then
                            pcall(function()
                                myChar:PivotTo(tHRP.CFrame * CFrame.new(0, 2, 4))
                            end)
                            
                            sno(tHRP)

                            if not tHRP:FindFirstChild("KickAlign") then
                                local oldBp = tHRP:FindFirstChildOfClass("BodyPosition")
                                if oldBp then oldBp:Destroy() end

                                local att0 = Instance.new("Attachment", tHRP)
                                att0.Name = "KickAtt0"
                                
                                local att1 = Instance.new("Attachment", Workspace.Terrain)
                                att1.Name = "KickAtt1"

                                local alignPos = Instance.new("AlignPosition")
                                alignPos.Name = "KickAlign"
                                alignPos.Attachment0 = att0
                                alignPos.Attachment1 = att1
                                alignPos.MaxForce = math.huge
                                alignPos.Responsiveness = 200
                                alignPos.Parent = tHRP

                                local alignRot = Instance.new("AlignOrientation")
                                alignRot.Name = "KickRot"
                                alignRot.Attachment0 = att0
                                alignRot.Mode = Enum.OrientationAlignmentMode.OneAttachment
                                alignRot.CFrame = CFrame.new() 
                                alignRot.MaxTorque = math.huge
                                alignRot.Responsiveness = 200
                                alignRot.Parent = tHRP
                            end

                            local grabStartTime = tick()
                            while (tick() - grabStartTime) < 0.3 and oatsKickActive do
                                task.wait(0.05)
                                sno(tHRP)
                                pcall(function()
                                    local grabEvents = RS:FindFirstChild("GrabEvents")
                                    local destroyLine = grabEvents and grabEvents:FindFirstChild("DestroyGrabLine")
                                    if destroyLine then
                                        destroyLine:FireServer(tHRP)
                                    end
                                end)
                                
                                local align = tHRP:FindFirstChild("KickAlign")
                                if myHead and align and align.Attachment1 then
                                    align.Attachment1.WorldPosition = myHead.Position + Vector3.new(0, 15, 0)
                                end
                            end

                            if oatsKickActive then
                                pcall(function()
                                    myChar:PivotTo(savedPos)
                                    tHRP.CFrame = savedPos * CFrame.new(0, 15, 0)
                                end)
                            end
                            
                            continue
                        end

                        if not tHRP:FindFirstChild("KickAlign") then
                            local oldBp = tHRP:FindFirstChildOfClass("BodyPosition")
                            if oldBp then oldBp:Destroy() end

                            local att0 = Instance.new("Attachment", tHRP)
                            att0.Name = "KickAtt0"
                            
                            local att1 = Instance.new("Attachment", Workspace.Terrain)
                            att1.Name = "KickAtt1"

                            local alignPos = Instance.new("AlignPosition")
                            alignPos.Name = "KickAlign"
                            alignPos.Attachment0 = att0
                            alignPos.Attachment1 = att1
                            alignPos.MaxForce = math.huge
                            alignPos.Responsiveness = 200
                            alignPos.Parent = tHRP

                            local alignRot = Instance.new("AlignOrientation")
                            alignRot.Name = "KickRot"
                            alignRot.Attachment0 = att0
                            alignRot.Mode = Enum.OrientationAlignmentMode.OneAttachment
                            alignRot.CFrame = CFrame.new() 
                            alignRot.MaxTorque = math.huge
                            alignRot.Responsiveness = 200
                            alignRot.Parent = tHRP
                        end

                        sno(tHRP)

                        local align = tHRP:FindFirstChild("KickAlign")
                        if align and align.Attachment1 and oatsKickActive then
                            align.Attachment1.WorldPosition = myHead.Position + Vector3.new(0, 20, 0)
                        end

                        local rot = tHRP:FindFirstChild("KickRot")
                        if rot then 
                            rot.CFrame = CFrame.Angles(0, 0, 0) 
                        end

                        if tick() - lastRemoteFire > 0.05 and oatsKickActive then
                            pcall(function()
                                local grabEvents = RS:FindFirstChild("GrabEvents")
                                local destroyLine = grabEvents and grabEvents:FindFirstChild("DestroyGrabLine")
                                if destroyLine then
                                    destroyLine:FireServer(tHRP)
                                end
                            end)
                            lastRemoteFire = tick()
                        end
                    end

                    if targetPlayer and targetPlayer.Character then
                        local tH = targetPlayer.Character:FindFirstChild("HumanoidRootPart")
                        if tH then
                            local align = tH:FindFirstChild("KickAlign")
                            local rot = tH:FindFirstChild("KickRot")
                            local att0 = tH:FindFirstChild("KickAtt0")
                            
                            if align then 
                                if align.Attachment1 then align.Attachment1:Destroy() end
                                align:Destroy() 
                            end
                            if rot then rot:Destroy() end
                            if att0 then att0:Destroy() end

                            pcall(function()
                                local grabEvents = RS:FindFirstChild("GrabEvents")
                                local destroyLine = grabEvents and grabEvents:FindFirstChild("DestroyGrabLine")
                                if destroyLine then
                                    destroyLine:FireServer(tH)
                                end
                            end)
                        end
                    end

                    oatsKickActive = false
                end)
            else
                oatsKickActive = false
                if oatsKickTask then
                    task.cancel(oatsKickTask)
                    oatsKickTask = nil
                end
                if oatsKickGrabConnection then
                    oatsKickGrabConnection:Disconnect()
                    oatsKickGrabConnection = nil
                end
                
                local targetPlayer = getSelectedPlayer()
                if targetPlayer and targetPlayer.Character then
                    local tH = targetPlayer.Character:FindFirstChild("HumanoidRootPart")
                    if tH then
                        local align = tH:FindFirstChild("KickAlign")
                        local rot = tH:FindFirstChild("KickRot")
                        local att0 = tH:FindFirstChild("KickAtt0")
                        
                        if align then 
                            if align.Attachment1 then align.Attachment1:Destroy() end
                            align:Destroy() 
                        end
                        if rot then rot:Destroy() end
                        if att0 then att0:Destroy() end

                        pcall(function()
                            local grabEvents = RS:FindFirstChild("GrabEvents")
                            local destroyLine = grabEvents and grabEvents:FindFirstChild("DestroyGrabLine")
                            if destroyLine then
                                destroyLine:FireServer(tH)
                            end
                        end)
                    end
                end
            end
        end
    })
end

-- ==============================================
-- 3. OWNERSHIP KICK
-- ==============================================
do
    local OwnershipKickEnabled = false
    local OwnershipKickTask = nil

    NoBlobGroup:AddToggle("OwnershipKick", {
        Text = "Ownership Kick",
        Default = false,
        Tooltip = "Кикает цель через овнершип",
        Callback = function(Value)
            OwnershipKickEnabled = Value
            
            if Value then
                local targetPlayer = getSelectedPlayer()
                if not targetPlayer then
                    OwnershipKickEnabled = false
                    Library:Notify({Title = "Ownership Kick", Description = "Please select a target first!", Duration = 3})
                    Toggles.OwnershipKick:SetValue(false)
                    return
                end
                
                OwnershipKickTask = task.spawn(function()
                    local RS = game:GetService("ReplicatedStorage")
                    local GE = RS:FindFirstChild("GrabEvents")
                    
                    if not GE then
                        OwnershipKickEnabled = false
                        return
                    end
                    
                    local myChar = plr.Character
                    local myRoot = myChar and myChar:FindFirstChild("HumanoidRootPart")
                    if not myRoot then
                        OwnershipKickEnabled = false
                        return
                    end

                    local savedPos = myRoot.CFrame 
                    local dragging = false
                    local grabStartTime = 0
                    local checkStartTime = 0
                    
                    local currentFPS = 60
                    local fpsConnection = RunService.RenderStepped:Connect(function(dt)
                        currentFPS = 1 / dt
                    end)

                    local bodyPos = nil
                    local bodyGyro = nil

                    local function cleanupBodies()
                        pcall(function()
                            if bodyPos then bodyPos:Destroy() bodyPos = nil end
                            if bodyGyro then bodyGyro:Destroy() bodyGyro = nil end
                        end)
                    end

                    local function createBodies(targetRoot, pos)
                        cleanupBodies()
                        
                        for _, v in pairs(targetRoot:GetChildren()) do
                            if v:IsA("BodyPosition") or v:IsA("BodyGyro") then
                                v:Destroy()
                            end
                        end
                        
                        bodyPos = Instance.new("BodyPosition")
                        bodyPos.MaxForce = Vector3.new(9e9, 9e9, 9e9)
                        bodyPos.D = 100
                        bodyPos.Position = pos
                        bodyPos.Parent = targetRoot
                        
                        bodyGyro = Instance.new("BodyGyro")
                        bodyGyro.MaxTorque = Vector3.new(9e9, 9e9, 9e9)
                        bodyGyro.D = 100
                        bodyGyro.CFrame = CFrame.new(pos)
                        bodyGyro.Parent = targetRoot
                    end

                    while OwnershipKickEnabled do
                        local currentTarget = getSelectedPlayer()
                        if not currentTarget or not currentTarget.Parent then 
                            cleanupBodies()
                            break 
                        end
                        
                        myChar = plr.Character
                        myRoot = myChar and myChar:FindFirstChild("HumanoidRootPart")
                        local tChar = currentTarget.Character
                        local tRoot = tChar and tChar:FindFirstChild("HumanoidRootPart")
                        local tHum = tChar and tChar:FindFirstChild("Humanoid")
                        
                        if tRoot and tHum and tHum.Health > 0 and myRoot then
                            if not dragging then
                                myRoot.CFrame = tRoot.CFrame * CFrame.new(0, 0, 3)
                                cleanupBodies()
                                checkStartTime = 0
                                
                                pcall(function()
                                    tHum.PlatformStand = true
                                    tHum.Sit = true
                                    if GE.SetNetworkOwner then GE.SetNetworkOwner:FireServer(tRoot, tRoot.CFrame) end
                                    if GE.SetNetworkOwner then GE.SetNetworkOwner:FireServer(tRoot, tRoot.CFrame) end
                                    if GE.DestroyGrabLine then GE.DestroyGrabLine:FireServer(tRoot) end
                                end)
                                
                                myRoot.AssemblyLinearVelocity = Vector3.zero
                                myRoot.AssemblyAngularVelocity = Vector3.zero
                                
                                if grabStartTime == 0 then grabStartTime = tick() end
                                if tick() - grabStartTime > 0.35 then
                                    dragging = true
                                    grabStartTime = 0
                                    checkStartTime = tick()
                                    local lockPos = savedPos * CFrame.new(5, 20, 4)
                                    createBodies(tRoot, lockPos.Position)
                                end
                            else
                                myRoot.CFrame = savedPos
                                local lockPos = savedPos * CFrame.new(5, 20, 4)
                                
                                myRoot.AssemblyLinearVelocity = Vector3.zero
                                myRoot.AssemblyAngularVelocity = Vector3.zero
                                
                                if bodyPos and bodyPos.Parent then
                                    bodyPos.Position = lockPos.Position
                                    if bodyGyro then
                                        bodyGyro.CFrame = lockPos
                                    end
                                else
                                    createBodies(tRoot, lockPos.Position)
                                end
                                
                                tHum.PlatformStand = true
                                
                                pcall(function()
                                    if GE.SetNetworkOwner and GE.DestroyGrabLine then
                                        if currentFPS > 200 then
                                            GE.SetNetworkOwner:FireServer(tRoot, lockPos)
                                            GE.SetNetworkOwner:FireServer(tRoot, lockPos)
                                            GE.DestroyGrabLine:FireServer(tRoot)
                                        elseif currentFPS >= 155 and currentFPS <= 200 then
                                            GE.SetNetworkOwner:FireServer(tRoot, lockPos)
                                            GE.SetNetworkOwner:FireServer(tRoot, lockPos)
                                            GE.SetNetworkOwner:FireServer(tRoot, lockPos)
                                            GE.DestroyGrabLine:FireServer(tRoot)
                                        else 
                                            GE.SetNetworkOwner:FireServer(tRoot, lockPos)
                                            GE.SetNetworkOwner:FireServer(tRoot, lockPos)
                                            GE.SetNetworkOwner:FireServer(tRoot, lockPos)
                                            GE.SetNetworkOwner:FireServer(tRoot, lockPos)
                                            GE.DestroyGrabLine:FireServer(tRoot)
                                        end
                                    end
                                end)
                                
                                if checkStartTime > 0 and tick() - checkStartTime > 0.30 then
                                    local currentDist = (tRoot.Position - lockPos.Position).Magnitude
                                    
                                    if currentDist > 10 then
                                        dragging = false
                                        grabStartTime = 0
                                        checkStartTime = 0
                                        cleanupBodies()
                                        myRoot.CFrame = tRoot.CFrame * CFrame.new(0, 0, 3)
                                    else
                                        checkStartTime = tick()
                                    end
                                end
                            end
                        else
                            dragging = false
                            grabStartTime = 0
                            checkStartTime = 0
                            cleanupBodies()
                        end
                        RunService.Heartbeat:Wait()
                    end
                    
                    fpsConnection:Disconnect()
                    cleanupBodies()
                    if myRoot then myRoot.CFrame = savedPos end
                end)
            else
                OwnershipKickEnabled = false
                if OwnershipKickTask then
                    task.cancel(OwnershipKickTask)
                    OwnershipKickTask = nil
                end
                
                local targetPlayer = getSelectedPlayer()
                if targetPlayer and targetPlayer.Character then
                    local tRoot = targetPlayer.Character:FindFirstChild("HumanoidRootPart")
                    if tRoot then
                        for _, v in pairs(tRoot:GetChildren()) do
                            if v:IsA("BodyPosition") or v:IsA("BodyGyro") then
                                pcall(function() v:Destroy() end)
                            end
                        end
                        pcall(function()
                            tRoot.AssemblyLinearVelocity = Vector3.zero
                            tRoot.AssemblyAngularVelocity = Vector3.zero
                        end)
                    end
                end
            end
        end
    })
end

-- ==============================================
-- 4. REMOVE TARGET ANTI KICK [AURA]
-- ==============================================
NoBlobGroup:AddToggle("RemoveAntiKickToggle", {
    Text = "[AURA] Remove Target Anti Kick",
    Default = false,
    Tooltip = "Удаляет анти-кик предметы у цели",
    Callback = function(Value)
        local antiAntiKickActive = Value
        if Value then
            task.spawn(function()
                local SetNetOwner = RS.GrabEvents.SetNetworkOwner
                while antiAntiKickActive do
                    local target = getSelectedPlayer()
                    if target then
                        local spawned = Workspace:FindFirstChild(target.Name .. "SpawnedInToys")
                        if spawned then
                            local toys = {"NinjaKunai", "NinjaShuriken", "AntiKick", "ToolCleaver", "ToolPencil"}
                            for _, toyName in ipairs(toys) do
                                local toy = spawned:FindFirstChild(toyName)
                                if toy then
                                    local part = toy:FindFirstChild("SoundPart") or toy:FindFirstChild("StickyPart")
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
                    task.wait(0.1)
                end
            end)
        end
    end
})

-- ==============================================
-- 5. REMOVE TARGET GUCCI [SIT]
-- ==============================================
do
    local DestroyTargetGucciActive = false

    NoBlobGroup:AddToggle("DestroyTargetGucci", {
        Text = "[SIT] Remove Target Gucci",
        Default = false,
        Tooltip = "Удаляет Gucci у цели",
        Callback = function(Value)
            DestroyTargetGucciActive = Value
            if Value then
                local target = getSelectedPlayer()
                if not target then
                    Toggles.DestroyTargetGucci:SetValue(false)
                    return
                end
                local char = plr.Character
                local root = char and char:FindFirstChild("HumanoidRootPart")
                if not root then
                    return
                end
                local SafeSpot = root.CFrame
                local folderName = target.Name .. "SpawnedInToys"
                task.spawn(function()
                    while DestroyTargetGucciActive do
                        local target = getSelectedPlayer()
                        if not target or not target.Parent then
                            DestroyTargetGucciActive = false
                            Toggles.DestroyTargetGucci:SetValue(false)
                            break
                        end
                        local toysFolder = Workspace:FindFirstChild(folderName)
                        if toysFolder then
                            for _, obj in pairs(toysFolder:GetChildren()) do
                                if not DestroyTargetGucciActive then
                                    break
                                end
                                if obj.Name == "CreatureBlobman" then
                                    local seat = obj:FindFirstChild("VehicleSeat") or obj:FindFirstChildWhichIsA("VehicleSeat", true)
                                    if seat then
                                        local myChar = plr.Character
                                        local myRoot = myChar and myChar:FindFirstChild("HumanoidRootPart")
                                        local myHum = myChar and myChar:FindFirstChild("Humanoid")
                                        if myRoot and myHum and myHum.SeatPart ~= seat then
                                            local magnetConn
                                            magnetConn = RunService.Stepped:Connect(function()
                                                if myRoot and seat then
                                                    myRoot.CFrame = seat.CFrame
                                                    myRoot.Velocity = Vector3.zero
                                                    if obj.PrimaryPart then
                                                        obj.PrimaryPart.Velocity = Vector3.zero
                                                        obj.PrimaryPart.RotVelocity = Vector3.zero
                                                    end
                                                end
                                            end)
                                            local sitStart = tick()
                                            while tick() - sitStart < 1 do
                                                if not DestroyTargetGucciActive then
                                                    break
                                                end
                                                if myHum.SeatPart == seat then
                                                    break
                                                end
                                                seat:Sit(myHum)
                                                task.wait()
                                            end
                                            if magnetConn then
                                                magnetConn:Disconnect()
                                            end
                                            if myHum.SeatPart == seat then
                                                task.wait(0.3)
                                                myHum.Sit = false
                                                myHum.Jump = true
                                                task.wait(0.05)
                                                myRoot.CFrame = SafeSpot
                                                myRoot.Velocity = Vector3.zero
                                                task.wait(0.5)
                                            else
                                                myRoot.CFrame = SafeSpot
                                            end
                                        end
                                    end
                                end
                            end
                        end
                        task.wait(1)
                    end
                end)
            end
        end
    })
end

-- ==============================================
-- 6. PALLET RAGDOLL
-- ==============================================
NoBlobGroup:AddToggle("PalletRagdoll", {
    Text = "Pallet Ragdoll (Invis)",
    Default = false,
    Tooltip = "Рагдоллит цель через палетку",
    Callback = function(Value)
        local RS = game:GetService("ReplicatedStorage")
        local DestroyToy = RS:WaitForChild("MenuToys"):WaitForChild("DestroyToy")
        local SetNetOwner = RS:WaitForChild("GrabEvents"):WaitForChild("SetNetworkOwner")
        local DestroyLine = RS:WaitForChild("GrabEvents"):WaitForChild("DestroyGrabLine")
        local toysFolder = Workspace:WaitForChild(plr.Name .. "SpawnedInToys")
        local lpName = plr.Name

        local function clearAttackLoop()
            if getgenv().ragdollSteppedConn then
                getgenv().ragdollSteppedConn:Disconnect()
                getgenv().ragdollSteppedConn = nil
            end
        end

        if Value then
            local target = getSelectedPlayer()
            if not target then
                Toggles.PalletRagdoll:SetValue(false)
                return
            end

            getgenv().palletRagdollActive = true
            getgenv().PalletForRagdoll = nil
            
            if getgenv().palletCacheConn then
                getgenv().palletCacheConn:Disconnect()
            end
            clearAttackLoop()

            getgenv().palletCacheConn = toysFolder.ChildAdded:Connect(function(child)
                if not getgenv().palletRagdollActive then return end
                if child.Name ~= "PalletLightBrown" and child.Name ~= "PalletForRagdoll" then return end

                local soundPart = child:WaitForChild("SoundPart", 3)
                if not soundPart then return end

                pcall(function()
                    SetNetOwner:FireServer(soundPart, soundPart.CFrame)
                    DestroyLine:FireServer(soundPart)
                end)

                local partOwner = soundPart:WaitForChild("PartOwner", 1)
                if partOwner and partOwner.Value == lpName then
                    for _, v in pairs(child:GetChildren()) do
                        if v:IsA("BasePart") then
                            v.CanCollide = false
                            v.CanQuery = false
                            v.Transparency = 1 
                        end
                    end

                    child.Name = "PalletForRagdoll"
                    getgenv().PalletForRagdoll = child

                    local strikePhase = false

                    getgenv().ragdollSteppedConn = RunService.Stepped:Connect(function()
                        if not getgenv().palletRagdollActive or not child.Parent then 
                            clearAttackLoop()
                            return 
                        end

                        local tChar = target and target.Character
                        local tRoot = tChar and tChar:FindFirstChild("HumanoidRootPart")
                        local tHum = tChar and tChar:FindFirstChildOfClass("Humanoid")

                        if tRoot and tHum and soundPart.Parent and tHum.Health > 0 then
                            local ragdolledVal = tHum:FindFirstChild("Ragdolled")
                            local isRagdolled = ragdolledVal and ragdolledVal.Value or false

                            if not isRagdolled then
                                strikePhase = not strikePhase
                                if strikePhase then
                                    soundPart.CFrame = tRoot.CFrame * CFrame.new(0, 2, 0)
                                    soundPart.AssemblyLinearVelocity = Vector3.new(0, -9e5, 0)
                                else
                                    soundPart.CFrame = tRoot.CFrame * CFrame.new(0, -1, 0)
                                    soundPart.AssemblyLinearVelocity = Vector3.new(0, 9e5, 0)
                                end
                            else
                                soundPart.CFrame = CFrame.new(0, 9e9, 0)
                                soundPart.AssemblyLinearVelocity = Vector3.zero
                            end
                        else
                            soundPart.CFrame = CFrame.new(0, 9e9, 0)
                            soundPart.AssemblyLinearVelocity = Vector3.zero
                        end
                    end)

                    child.AncestryChanged:Connect(function()
                        if not child.Parent then
                            clearAttackLoop()
                            getgenv().PalletForRagdoll = nil
                            if getgenv().palletRagdollActive then
                                task.wait(0.03)
                                if getgenv().spawnNewPallet then getgenv().spawnNewPallet() end
                            end
                        end
                    end)
                else
                    pcall(function() DestroyToy:FireServer(child) end)
                end
            end)

            getgenv().spawnNewPallet = function()
                if not getgenv().palletRagdollActive then return end
                if getgenv().PalletForRagdoll and getgenv().PalletForRagdoll.Parent then return end
                
                local c = plr.Character
                local h = c and c:FindFirstChild("HumanoidRootPart")
                if not h then return end

                task.spawn(function()
                    pcall(function()
                        RS.MenuToys.SpawnToyRemoteFunction:InvokeServer(
                            "PalletLightBrown",
                            h.CFrame * CFrame.new(0, 10, 20),
                            Vector3.zero
                        )
                    end)
                end)
            end

            getgenv().spawnNewPallet()
        else
            getgenv().palletRagdollActive = false
            clearAttackLoop()

            if getgenv().palletCacheConn then
                getgenv().palletCacheConn:Disconnect()
                getgenv().palletCacheConn = nil
            end

            local pallet = getgenv().PalletForRagdoll
            if pallet and pallet.Parent then
                pcall(function() DestroyToy:FireServer(pallet) end)
            end

            getgenv().PalletForRagdoll = nil

            if toysFolder:FindFirstChild("PalletForRagdoll") then
                pcall(function() DestroyToy:FireServer(toysFolder.PalletForRagdoll) end)
            end
        end
    end
})

-- ==============================================
-- ПРАВАЯ СТОРОНА (НИЗ): BLOBMAN METHODS
-- ==============================================
local BlobGroup = Tabs.Target:AddGroupbox({
    Side = "Right",
    Name = "Blobman methods",
    IconName = "loop",
})

-- ==============================================
-- AUTO SIT BLOBMAN
-- ==============================================
do
    local autoSitBlobActive = false
    local autoSitBlobTask = nil

    BlobGroup:AddToggle("AutoSitBlobman", {
        Text = "Auto Sit Blobman (fixing)",
        Default = false,
        Tooltip = "Автоматически садится на блобмана",
        Callback = function(Value)
            autoSitBlobActive = Value
            
            if Value then
                autoSitBlobTask = task.spawn(function()
                    while autoSitBlobActive do
                        pcall(function()
                            local Char = plr.Character
                            if not Char then return end
                            local Hum = Char:FindFirstChildOfClass("Humanoid")
                            local Root = Char:FindFirstChild("HumanoidRootPart")
                            if not Hum or not Root then return end
                            
                            if Hum.SeatPart then
                                task.wait(0.1)
                                return
                            end
                            
                            local folder = Workspace:FindFirstChild(plr.Name .. "SpawnedInToys")
                            local blob = folder and folder:FindFirstChild("CreatureBlobman")

                            if not blob then
                                pcall(function()
                                    SpawnToyRemote:InvokeServer("CreatureBlobman", Root.CFrame * CFrame.new(0, 5, 5), Vector3.zero)
                                end)
                                local t0 = tick()
                                repeat
                                    RunService.Heartbeat:Wait()
                                    folder = Workspace:FindFirstChild(plr.Name .. "SpawnedInToys")
                                    blob = folder and folder:FindFirstChild("CreatureBlobman")
                                until blob or tick() - t0 > 5 or not autoSitBlobActive
                            end

                            if blob then
                                local seat = blob:FindFirstChildWhichIsA("VehicleSeat")
                                if seat then
                                    Root.CFrame = seat.CFrame * CFrame.new(0, 1, 0)
                                    Root.Velocity = Vector3.zero
                                    pcall(function()
                                        seat:Sit(Hum)
                                    end)
                                end
                            end
                        end)
                        task.wait(0.1)
                    end
                end)
            else
                autoSitBlobActive = false
                if autoSitBlobTask then
                    task.cancel(autoSitBlobTask)
                    autoSitBlobTask = nil
                end
            end
        end
    })
end

-- ==============================================
-- BLOB KILL TARGET
-- ==============================================
do
    local BlobKillList = {}
    local blobKillActive = false

    local function checkgrab(itm)
        for _, prt in pairs(itm:GetChildren()) do
            if prt:IsA("BasePart") and prt:FindFirstChild("PartOwner") and prt.PartOwner.Value == plr.Name then
                return true
            end
        end
        return false
    end

    local function BlobKick()
        while true do
            local gotsomeone = false
            
            for _, player in pairs(Players:GetPlayers()) do
                if BlobKillList[player.UserId] and blobKillActive then
                    local j, h
                    if plr.Character and plr.Character:FindFirstChild("HumanoidRootPart") then
                        j = plr.Character.HumanoidRootPart.CFrame
                        h = plr.Character.HumanoidRootPart.AssemblyLinearVelocity
                    end

                    if player ~= plr then
                        local continue = false
                        if player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
                            if player.Character.HumanoidRootPart.Massless then
                                if player.Character.Humanoid.SeatPart then
                                    continue = true
                                end
                            else
                                continue = true
                            end
                        end

                        local smegma = true
                        while smegma and plr.Character and plr.Character:FindFirstChild("HumanoidRootPart") and player and player.Character and player.Character.Parent == Workspace and player.Character:FindFirstChild("HumanoidRootPart") and player.Character:FindFirstChild("Humanoid") and player.Character.Humanoid:GetState() ~= Enum.HumanoidStateType.Dead and continue do
                            if not BlobKillList[player.UserId] or not blobKillActive then
                                smegma = false
                                break
                            end

                            gotsomeone = true
                            continue = false
                            continue = true

                            local vel = player.Character.HumanoidRootPart.AssemblyLinearVelocity
                            if vel.Magnitude > 10000 then
                                vel = Vector3.zero
                            end
                            if player.Character.HumanoidRootPart.CFrame.Position.Magnitude > 1000000 then
                                continue = false
                            end

                            if smegma and continue and plr.Character and plr.Character:FindFirstChild("Humanoid") and player.Character.Humanoid:GetState() ~= Enum.HumanoidStateType.Dead and plr.Character.Humanoid.SeatPart and plr.Character.Humanoid.SeatPart.Parent and plr.Character.Humanoid.SeatPart.Parent.Name == "CreatureBlobman" then
                                local blob = plr.Character.Humanoid.SeatPart.Parent
                                if (player.Character.HumanoidRootPart.CFrame.Position - plr.Character.HumanoidRootPart.CFrame.Position + plr.Character.HumanoidRootPart.AssemblyLinearVelocity).Magnitude > 30 and player.Character.Parent == Workspace then
                                    plr.Character.HumanoidRootPart.CFrame = player.Character.HumanoidRootPart.CFrame + (player.Character.HumanoidRootPart.AssemblyLinearVelocity / math.pi)
                                    plr.Character.HumanoidRootPart.AssemblyLinearVelocity = player.Character.HumanoidRootPart.AssemblyLinearVelocity

                                    if player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
                                        if player.Character:FindFirstChild("Humanoid") and player.Character.Humanoid:GetState() ~= Enum.HumanoidStateType.Dead and blob and blob:FindFirstChild("RightDetector") and blob.RightDetector:FindFirstChild("RightWeld") and blob:FindFirstChild("BlobmanSeatAndOwnerScript") and blob.BlobmanSeatAndOwnerScript:FindFirstChild("CreatureGrab") and blob.BlobmanSeatAndOwnerScript:FindFirstChild("CreatureRelease") then
                                            player.Character.Humanoid:ChangeState(Enum.HumanoidStateType.Dead)
                                            task.wait(0.15)
                                            blob.BlobmanSeatAndOwnerScript.CreatureGrab:FireServer(blob.RightDetector, player.Character.HumanoidRootPart, blob.RightDetector.RightWeld)
                                            task.wait(0.1)
                                            blob.BlobmanSeatAndOwnerScript.CreatureRelease:FireServer(blob.RightDetector.RightWeld, player.Character.HumanoidRootPart)
                                        end
                                    end
                                end
                            elseif continue then
                                if plr.Character:FindFirstChild("Humanoid") and plr.Character.Humanoid.SeatPart and (plr.Character.Humanoid.SeatPart.Parent and plr.Character.Humanoid.SeatPart.Name ~= "CreatureBlobman" or not plr.Character.Humanoid.SeatPart.Parent) then
                                    plr.Character.Humanoid.Sit = false
                                end

                                local blob = nil
                                local foundblob = false
                                for _, itm in pairs(Workspace[plr.Name .. "SpawnedInToys"]:GetChildren()) do
                                    if itm.Name == "CreatureBlobman" and itm:FindFirstChild("VehicleSeat") then
                                        foundblob = true
                                        blob = itm
                                    elseif itm.Name == "CreatureBlobman" then
                                        while itm do
                                            RS.MenuToys.DestroyToy:FireServer(itm)
                                            task.wait(0.1)
                                        end
                                    end
                                end

                                if blob and plr.Character and plr.Character:FindFirstChild("Humanoid") and player.Character.Humanoid:GetState() ~= Enum.HumanoidStateType.Dead then
                                    blob.VehicleSeat:Sit(plr.Character.Humanoid)
                                end
                                if not foundblob then
                                    task.wait(1)
                                    while smegma and not blob do
                                        if Workspace:FindFirstChild(plr.Name .. "SpawnedInToys"):FindFirstChild("CreatureBlobman") then
                                            blob = Workspace:FindFirstChild(plr.Name .. "SpawnedInToys").CreatureBlobman
                                        else
                                            task.spawn(function()
                                                RS.MenuToys.SpawnToyRemoteFunction:InvokeServer("CreatureBlobman", CFrame.new(plr.Character.HumanoidRootPart.CFrame.Position) + Vector3.new(0, 0, 15), Vector3.new(0, 0, 0))
                                            end)
                                        end
                                        task.wait()
                                    end
                                end
                            end
                            task.wait(0.15)
                        end

                        if plr.Character and plr.Character:FindFirstChild("HumanoidRootPart") and j then
                            plr.Character.HumanoidRootPart.CFrame = j
                            plr.Character.HumanoidRootPart.AssemblyLinearVelocity = h
                        end
                    end
                end
            end

            if not gotsomeone and blob then
                if plr.Character and plr.Character:FindFirstChild("Humanoid") and plr.Character.Humanoid.SeatPart and plr.Character.Humanoid.SeatPart.Parent == blob then
                    plr.Character.Humanoid.Sit = false
                end
                task.wait()
                if blob and blob:FindFirstChild("HumanoidRootPart") then
                    blob.HumanoidRootPart.CFrame = CFrame.new(0, 1e15, 0)
                end
            end
            task.wait(0.5)
        end
    end

    task.spawn(BlobKick)

    BlobGroup:AddToggle("BlobKillTarget", {
        Text = "Blob Kill Target",
        Default = false,
        Tooltip = "Убивает цель через блоба",
        Callback = function(Value)
            blobKillActive = Value
            local target = getSelectedPlayer()
            
            if Value then
                if not target then
                    blobKillActive = false
                    Toggles.BlobKillTarget:SetValue(false)
                    return
                end
                BlobKillList[target.UserId] = true
            else
                if target then
                    BlobKillList[target.UserId] = nil
                end
            end
        end
    })
end

-- ==============================================
-- LOOP KICK BLOB
-- ==============================================
do
    local kickLoopEnabled = false
    local kickHeight = 25

    BlobGroup:AddToggle("LoopKickBlob", {
        Text = "Loop Kick (Grab + Blob)",
        Default = false,
        Tooltip = "Кикает цель через граб блоба",
        Callback = function(Value)
            kickLoopEnabled = Value
            
            if Value then
                local target = getSelectedPlayer()
                if not target then
                    kickLoopEnabled = false
                    Toggles.LoopKickBlob:SetValue(false)
                    return
                end
                
                task.spawn(function()
                    local GE = RS:FindFirstChild("GrabEvents")
                    local myChar = plr.Character
                    local myRoot = myChar and myChar:FindFirstChild("HumanoidRootPart")
                    
                    if not myRoot then 
                        kickLoopEnabled = false
                        return 
                    end

                    local savedPos = myRoot.CFrame
                    local dragging = false
                    local grabStartTime = 0

                    while kickLoopEnabled do
                        local target = getSelectedPlayer()
                        if not target or not target.Parent or not target.Character then 
                            kickLoopEnabled = false
                            break 
                        end
                        
                        local tChar = target.Character
                        local tRoot = tChar:FindFirstChild("HumanoidRootPart")
                        local tHum = tChar:FindFirstChild("Humanoid")
                        
                        local seat = myChar and myChar.Humanoid and myChar.Humanoid.SeatPart
                        
                        if tRoot and tHum and tHum.Health > 0 then
                            tRoot.AssemblyLinearVelocity = Vector3.zero
                            tRoot.Velocity = Vector3.zero

                            if seat then
                                local blobman = seat.Parent
                                local remoteFolder = blobman:FindFirstChild("BlobmanSeatAndOwnerScript")
                                local grab = remoteFolder and remoteFolder:FindFirstChild("CreatureGrab")
                                local drop = remoteFolder and remoteFolder:FindFirstChild("CreatureDrop")
                                
                                local L_Det = blobman:FindFirstChild("LeftDetector")
                                local R_Det = blobman:FindFirstChild("RightDetector")
                                local L_Weld = L_Det and (L_Det:FindFirstChild("LeftWeld") or L_Det:FindFirstChild("RigidConstraint"))
                                local R_Weld = R_Det and (R_Det:FindFirstChild("RightWeld") or R_Det:FindFirstChild("RigidConstraint"))

                                if grab and drop and L_Weld and R_Weld then
                                    pcall(function()
                                        grab:FireServer(L_Det, tRoot, L_Weld)
                                        grab:FireServer(R_Det, tRoot, R_Weld)
                                        drop:FireServer(L_Weld, tRoot)
                                        drop:FireServer(R_Weld, tRoot)
                                    end)
                                end
                            end

                            if not dragging then
                                myRoot.CFrame = tRoot.CFrame
                                if GE then
                                    pcall(function()
                                        tHum.PlatformStand = true
                                        if GE.SetNetworkOwner then GE.SetNetworkOwner:FireServer(tRoot, myRoot.CFrame) end
                                        if GE.CreateGrabLine then GE.CreateGrabLine:FireServer(tRoot, Vector3.zero, tRoot.Position, false) end
                                    end)
                                end
                                
                                if grabStartTime == 0 then grabStartTime = tick() end
                                if tick() - grabStartTime > 0.3 then
                                    dragging = true
                                    grabStartTime = 0
                                end
                            else
                                local lockPos = savedPos * CFrame.new(0, kickHeight, 0)
                                myRoot.CFrame = savedPos
                                tRoot.CFrame = lockPos
                                
                                if GE then
                                    pcall(function()
                                        tHum.PlatformStand = true
                                        if GE.SetNetworkOwner then GE.SetNetworkOwner:FireServer(tRoot, lockPos) end
                                        if GE.DestroyGrabLine then GE.DestroyGrabLine:FireServer(tRoot) end
                                        if GE.CreateGrabLine then GE.CreateGrabLine:FireServer(tRoot, Vector3.zero, tRoot.Position, false) end
                                    end)
                                end
                            end
                        else
                            dragging = false
                            grabStartTime = 0
                        end
                        
                        RunService.Heartbeat:Wait()
                    end

                    if myRoot and savedPos then
                        myRoot.CFrame = savedPos
                    end
                    kickLoopEnabled = false
                end)
            else
                kickLoopEnabled = false
            end
        end
    })
end

-- ==============================================
-- SPIN LOOP KICK
-- ==============================================
do
    local spinLoopActive = false
    local spinLoopTask = nil
    local spinAngle = 0
    local spinRadius = 25
    local spinSpeed = 0.25

    BlobGroup:AddSlider("SpinRadius", {
        Text = "Spin Radius",
        Default = 25,
        Min = 5,
        Max = 50,
        Tooltip = "Радиус вращения",
        Callback = function(v)
            spinRadius = v
        end
    })

   BlobGroup:AddSlider("SpinSpeed", {
    Text = "Spin Speed",
    Default = 0.25,
    Min = 0.05,
    Max = 1,
    Rounding = 2,          
    Increment = 0.05,     
    Compact = false,
    Tooltip = "Скорость вращения",
    Callback = function(v)
        spinSpeed = v
    end
})

    BlobGroup:AddToggle("SpinLoopKick", {
        Text = "Spin Loop Kick",
        Default = false,
        Tooltip = "Кикает цель по спирали",
        Callback = function(Value)
            spinLoopActive = Value
            
            if Value then
                local target = getSelectedPlayer()
                if not target then
                    spinLoopActive = false
                    Toggles.SpinLoopKick:SetValue(false)
                    return
                end
                
                spinAngle = 0
                
                spinLoopTask = task.spawn(function()
                    local GE = RS:FindFirstChild("GrabEvents")
                    
                    local myChar = plr.Character
                    local myRoot = myChar and myChar:FindFirstChild("HumanoidRootPart")
                    
                    if not myRoot then 
                        spinLoopActive = false
                        return 
                    end

                    local savedPos = myRoot.CFrame
                    local dragging = false
                    local grabStartTime = 0

                    while spinLoopActive do
                        local target = getSelectedPlayer()
                        if not target or not target.Parent or not target.Character then 
                            spinLoopActive = false
                            break 
                        end
                        
                        local tChar = target.Character
                        local tRoot = tChar:FindFirstChild("HumanoidRootPart")
                        local tHum = tChar:FindFirstChild("Humanoid")
                        
                        local seat = myChar and myChar.Humanoid and myChar.Humanoid.SeatPart
                        
                        if tRoot and tHum and tHum.Health > 0 then
                            tRoot.AssemblyLinearVelocity = Vector3.zero
                            tRoot.Velocity = Vector3.zero

                            if seat then
                                local blobman = seat.Parent
                                local remoteFolder = blobman:FindFirstChild("BlobmanSeatAndOwnerScript")
                                local grab = remoteFolder and remoteFolder:FindFirstChild("CreatureGrab")
                                local drop = remoteFolder and remoteFolder:FindFirstChild("CreatureDrop")
                                
                                local L_Det = blobman:FindFirstChild("LeftDetector")
                                local R_Det = blobman:FindFirstChild("RightDetector")
                                local L_Weld = L_Det and (L_Det:FindFirstChild("LeftWeld") or L_Det:FindFirstChild("RigidConstraint"))
                                local R_Weld = R_Det and (R_Det:FindFirstChild("RightWeld") or R_Det:FindFirstChild("RigidConstraint"))

                                if grab and drop and L_Weld and R_Weld then
                                    pcall(function()
                                        grab:FireServer(L_Det, tRoot, L_Weld)
                                        grab:FireServer(R_Det, tRoot, R_Weld)
                                        drop:FireServer(L_Weld, tRoot)
                                        drop:FireServer(R_Weld, tRoot)
                                    end)
                                end
                            end

                            if not dragging then
                                spinAngle = spinAngle + spinSpeed
                                if spinAngle > 6.28 then spinAngle = 0 end
                                
                                local x = math.cos(spinAngle) * spinRadius
                                local z = math.sin(spinAngle) * spinRadius
                                
                                myRoot.CFrame = tRoot.CFrame * CFrame.new(x, 0, z)
                                
                                if GE then
                                    pcall(function()
                                        tHum.PlatformStand = true
                                        if GE.SetNetworkOwner then GE.SetNetworkOwner:FireServer(tRoot, myRoot.CFrame) end
                                        if GE.CreateGrabLine then GE.CreateGrabLine:FireServer(tRoot, Vector3.zero, tRoot.Position, false) end
                                    end)
                                end
                                
                                if grabStartTime == 0 then grabStartTime = tick() end
                                if tick() - grabStartTime > 0.3 then
                                    dragging = true
                                    grabStartTime = 0
                                end
                            else
                                spinAngle = spinAngle + spinSpeed
                                if spinAngle > 6.28 then spinAngle = 0 end
                                
                                local x = math.cos(spinAngle) * spinRadius
                                local z = math.sin(spinAngle) * spinRadius
                                
                                myRoot.CFrame = tRoot.CFrame * CFrame.new(x, 0, z)
                                
                                local lockPos = savedPos * CFrame.new(0, spinRadius * 0.8, 0)
                                tRoot.CFrame = lockPos
                                
                                if GE then
                                    pcall(function()
                                        tHum.PlatformStand = true
                                        if GE.SetNetworkOwner then GE.SetNetworkOwner:FireServer(tRoot, lockPos) end
                                        if GE.DestroyGrabLine then GE.DestroyGrabLine:FireServer(tRoot) end
                                        if GE.CreateGrabLine then GE.CreateGrabLine:FireServer(tRoot, Vector3.zero, tRoot.Position, false) end
                                    end)
                                end
                            end
                        else
                            dragging = false
                            grabStartTime = 0
                        end
                        
                        RunService.Heartbeat:Wait()
                    end

                    if myRoot and savedPos then
                        myRoot.CFrame = savedPos
                    end
                    spinLoopActive = false
                end)
            else
                spinLoopActive = false
                if spinLoopTask then
                    task.cancel(spinLoopTask)
                    spinLoopTask = nil
                end
                spinAngle = 0
            end
        end
    })
end

-- ==============================================
-- ВКЛАДКА VISUAL (ПОЛНОСТЬЮ ПЕРЕПИСАНА)
-- ==============================================

-- ==============================================
-- CAMERA (Левая сторона)
-- ==============================================
local VisualCamera = Tabs.Visual:AddLeftGroupbox("Camera")
defaultFOV = 70 

function UpdateFOV()
 local camera = workspace.CurrentCamera
 if camera then
 if Toggles.EnableFOV.Value then
 camera.FieldOfView = Options.FOVValue.Value
 else
 camera.FieldOfView = defaultFOV
 end
 end
end

VisualCamera:AddToggle("EnableFOV", {
 Text = "Custom FOV",
 Default = false,
 Tooltip = "Включить кастомный Field of View",
 Callback = function(Value)
 UpdateFOV()
 end
})

VisualCamera:AddSlider("FOVValue", {
 Text = "FOV Amount",
 Default = 70,
 Min = 0,
 Max = 120,
 Rounding = 0,
 Compact = false,
 Tooltip = "Настройка угла обзора",
 Callback = function(Value)
 UpdateFOV()
 end
})

task.spawn(function()
 while task.wait(0.1) do
 if Toggles.EnableFOV and Toggles.EnableFOV.Value then
 local camera = workspace.CurrentCamera
 if camera and camera.FieldOfView ~= Options.FOVValue.Value then
 camera.FieldOfView = Options.FOVValue.Value
 end
 end
 end
end)

-- 3rd Person
local tpDefCamMode = LocalPlayer.CameraMode
local tpDefMaxZoom = LocalPlayer.CameraMaxZoomDistance
local tpDefMinZoom = LocalPlayer.CameraMinZoomDistance

VisualCamera:AddToggle("EnableThirdPerson", {
 Text = "3rd Person",
 Default = false,
 Tooltip = "Вид от третьего лица",
 Callback = function(Value)
 LocalPlayer.CameraMaxZoomDistance = 1e9
 if Value then
 LocalPlayer.CameraMode = Enum.CameraMode.Classic
 else
 LocalPlayer.CameraMode = Enum.CameraMode.LockFirstPerson
 end
 end
})

VisualCamera:AddSlider("ThirdPersonDistance", {
 Text = "Дальность камеры",
 Default = 128,
 Min = 5,
 Max = 400,
 Rounding = 0,
 Compact = false,
 Tooltip = "Максимальное отдаление камеры колесиком мыши",
 Callback = function(Value)
 if Toggles.EnableThirdPerson and Toggles.EnableThirdPerson.Value then
 LocalPlayer.CameraMaxZoomDistance = Value
 end
 end
})

VisualCamera:AddToggle("Enable4x3", {
 Text = "Camera 4:3",
 Default = false,
 Tooltip = "Сплющить экран в 4:3 (через FOV)",
 Callback = function(Value)
 local cam = workspace.CurrentCamera
 if not cam then return end
 if Value then
 _G.Cam4x3DefaultFOV = cam.FieldOfView
 local vFOV = math.rad(cam.FieldOfView)
 local newFOV = math.deg(2 * math.atan(math.tan(vFOV / 2) * 0.75))
 cam.FieldOfView = newFOV
 _G.Cam4x3Conn = RunService.RenderStepped:Connect(function()
 if workspace.CurrentCamera and _G.Cam4x3DefaultFOV then
 local cur = math.rad(_G.Cam4x3DefaultFOV)
 local nf = math.deg(2 * math.atan(math.tan(cur / 2) * 0.75))
 workspace.CurrentCamera.FieldOfView = nf
 end
 end)
 else
 if _G.Cam4x3Conn then _G.Cam4x3Conn:Disconnect() _G.Cam4x3Conn = nil end
 if _G.Cam4x3DefaultFOV then
 if workspace.CurrentCamera then workspace.CurrentCamera.FieldOfView = _G.Cam4x3DefaultFOV end
 _G.Cam4x3DefaultFOV = nil
 end
 end
 end
})

-- ==============================================
-- SHADERS (Левая сторона)
-- ==============================================
local VisualShaders = Tabs.Visual:AddLeftGroupbox("Shaders")
local Lighting = game:GetService("Lighting")

-- Сохраняем оригинальные настройки освещения
originalLight = {
 Brightness = Lighting.Brightness,
 Ambient = Lighting.Ambient,
 OutdoorAmbient = Lighting.OutdoorAmbient,
 TimeOfDay = Lighting.TimeOfDay,
 ClockTime = Lighting.ClockTime,
 FogEnd = Lighting.FogEnd,
 FogStart = Lighting.FogStart,
 ExposureCompensation = Lighting.ExposureCompensation,
}

-- Темы шейдеров
local ShaderThemes = {
 ["Ночь"] = {
 Brightness = 2.0,
 Ambient = Color3.fromRGB(60, 70, 130),
 OutdoorAmbient = Color3.fromRGB(70, 80, 150),
 ClockTime = 12,
 FogEnd = 100000,
 FogStart = 90000,
 ExposureCompensation = 0.3,
 CC = { Brightness = 0, Contrast = 0.1, Saturation = -0.1, Tint = Color3.fromRGB(120, 140, 220) },
 Bloom = { Intensity = 0.6, Size = 32, Threshold = 0.7 },
 },
 ["Вечер"] = {
 Brightness = 2.5,
 Ambient = Color3.fromRGB(170, 110, 75),
 OutdoorAmbient = Color3.fromRGB(190, 120, 85),
 ClockTime = 12,
 FogEnd = 100000,
 FogStart = 90000,
 ExposureCompensation = 0.4,
 CC = { Brightness = 0, Contrast = 0.1, Saturation = 0.2, Tint = Color3.fromRGB(255, 200, 160) },
 Bloom = { Intensity = 0.6, Size = 32, Threshold = 0.7 },
 },
 ["Закат"] = {
 Brightness = 2.5,
 Ambient = Color3.fromRGB(210, 120, 75),
 OutdoorAmbient = Color3.fromRGB(230, 130, 85),
 ClockTime = 12,
 FogEnd = 100000,
 FogStart = 90000,
 ExposureCompensation = 0.4,
 CC = { Brightness = 0, Contrast = 0.15, Saturation = 0.35, Tint = Color3.fromRGB(255, 170, 120) },
 Bloom = { Intensity = 0.8, Size = 40, Threshold = 0.5 },
 },
 ["Туман"] = {
 Brightness = 2.5,
 Ambient = Color3.fromRGB(200, 200, 210),
 OutdoorAmbient = Color3.fromRGB(200, 200, 210),
 ClockTime = 12,
 FogEnd = 300,
 FogStart = 50,
 ExposureCompensation = 0,
 CC = { Brightness = 0.05, Contrast = -0.1, Saturation = -0.2, Tint = Color3.fromRGB(220, 220, 230) },
 Bloom = { Intensity = 0.3, Size = 48, Threshold = 0.9 },
 },
 ["Яркий"] = {
 Brightness = 3.0,
 Ambient = Color3.fromRGB(220, 220, 220),
 OutdoorAmbient = Color3.fromRGB(240, 240, 240),
 ClockTime = 12,
 FogEnd = 100000,
 FogStart = 90000,
 ExposureCompensation = 0.5,
 CC = { Brightness = 0.1, Contrast = 0.2, Saturation = 0.5, Tint = Color3.fromRGB(255, 255, 240) },
 Bloom = { Intensity = 1.0, Size = 32, Threshold = 0.4 },
 },
 ["Неон"] = {
 Brightness = 2.5,
 Ambient = Color3.fromRGB(80, 40, 120),
 OutdoorAmbient = Color3.fromRGB(90, 50, 140),
 ClockTime = 22,
 FogEnd = 1500,
 FogStart = 200,
 ExposureCompensation = 0.3,
 CC = { Brightness = 0, Contrast = 0.4, Saturation = 0.8, Tint = Color3.fromRGB(180, 100, 255) },
 Bloom = { Intensity = 1.3, Size = 44, Threshold = 0.35 },
 },
 ["Холодный"] = {
 Brightness = 2.5,
 Ambient = Color3.fromRGB(120, 140, 180),
 OutdoorAmbient = Color3.fromRGB(140, 160, 200),
 ClockTime = 12,
 FogEnd = 100000,
 FogStart = 90000,
 ExposureCompensation = 0.1,
 CC = { Brightness = 0, Contrast = 0.1, Saturation = 0.1, Tint = Color3.fromRGB(150, 180, 255) },
 Bloom = { Intensity = 0.4, Size = 24, Threshold = 0.8 },
 },
 ["Тёплый"] = {
 Brightness = 2.5,
 Ambient = Color3.fromRGB(180, 140, 100),
 OutdoorAmbient = Color3.fromRGB(200, 160, 120),
 ClockTime = 12,
 FogEnd = 100000,
 FogStart = 90000,
 ExposureCompensation = 0.2,
 CC = { Brightness = 0.02, Contrast = 0.1, Saturation = 0.3, Tint = Color3.fromRGB(255, 200, 150) },
 Bloom = { Intensity = 0.5, Size = 28, Threshold = 0.6 },
 },
 ["Реалистичный"] = {
 Brightness = 3.5,
 Ambient = Color3.fromRGB(80, 80, 80),
 OutdoorAmbient = Color3.fromRGB(120, 120, 120),
 ClockTime = 14,
 FogEnd = 50000,
 FogStart = 5000,
 ExposureCompensation = 0.3,
 GlobalShadows = true,
 Use2022Materials = true,
 CC = { Brightness = 0.05, Contrast = 0.2, Saturation = 0.3, Tint = Color3.fromRGB(255, 250, 245) },
 Bloom = { Intensity = 0.3, Size = 24, Threshold = 0.8 },
 SunRays = { Intensity = 0.05, Spread = 0.1 },
 },
 ["Ультра-Реализм"] = {
 Brightness = 3.0,
 Ambient = Color3.fromRGB(50, 50, 50),
 OutdoorAmbient = Color3.fromRGB(130, 130, 130),
 ClockTime = 15.5,
 FogEnd = 8000,
 FogStart = 500,
 ExposureCompensation = 0.2,
 GlobalShadows = true,
 Use2022Materials = true,
 ForceMaterials = true,
 EnvDiffuse = 1.0,
 EnvSpecular = 1.0,
 CC = { Brightness = 0.05, Contrast = 0.25, Saturation = 0.3, Tint = Color3.fromRGB(255, 250, 240) },
 Bloom = { Intensity = 0.05, Size = 10, Threshold = 2.0 },
 SunRays = { Intensity = 0.3, Spread = 0.2 },
 DOF = { FocusDistance = 25, InFocusRadius = 50, NearIntensity = 0.1, FarIntensity = 0.3 },
 },
 -- 4 шейдера из unstable.txt (точные параметры)
 ["Twilight"] = {
 Brightness = 3.5,
 Ambient = Color3.fromRGB(59, 33, 27),
 OutdoorAmbient = Color3.fromRGB(34, 0, 49),
 ClockTime = 6.7,
 FogEnd = 1000,
 FogStart = 0,
 FogColor = Color3.fromRGB(94, 76, 106),
 ExposureCompensation = 0.24,
 ColorShift_Top = Color3.fromRGB(240, 127, 14),
 ColorShift_Bottom = Color3.fromRGB(11, 0, 20),
 CC = { Brightness = 0, Contrast = 0, Saturation = 0.05, Tint = Color3.fromRGB(255, 224, 219) },
 Bloom = { Intensity = 0.1, Size = 100, Threshold = 0 },
 SunRays = { Intensity = 0.05, Spread = 0.8 },
 CustomSkybox = { Bk = "rbxassetid://323494035", Dn = "rbxassetid://323494368", Ft = "rbxassetid://323494130", Lf = "rbxassetid://323494252", Rt = "rbxassetid://323494067", Up = "rbxassetid://323493360" },
 },
 ["Luminous"] = {
 Brightness = 2,
 Ambient = Color3.fromRGB(50, 50, 50),
 OutdoorAmbient = Color3.fromRGB(150, 150, 150),
 ClockTime = 10,
 FogEnd = 10000,
 FogStart = 0,
 FogColor = Color3.fromRGB(20, 20, 20),
 ExposureCompensation = 0.5,
 ColorShift_Top = Color3.fromRGB(250, 250, 250),
 ColorShift_Bottom = Color3.fromRGB(250, 250, 250),
 CC = { Brightness = 0, Contrast = 0, Saturation = 0, Tint = Color3.fromRGB(255, 255, 255) },
 Bloom = { Intensity = 0.1, Size = 100, Threshold = 0 },
 CustomSkybox = { Bk = "rbxassetid://323494035", Dn = "rbxassetid://323494368", Ft = "rbxassetid://323494130", Lf = "rbxassetid://323494252", Rt = "rbxassetid://323494067", Up = "rbxassetid://323493360" },
 },
 ["Sandstorm"] = {
 Brightness = 2.5,
 Ambient = Color3.fromRGB(80, 40, 10),
 OutdoorAmbient = Color3.fromRGB(100, 50, 10),
 ClockTime = 7,
 FogEnd = 1000,
 FogStart = 0,
 FogColor = Color3.fromRGB(100, 55, 20),
 ExposureCompensation = 0.5,
 ColorShift_Top = Color3.fromRGB(240, 127, 14),
 ColorShift_Bottom = Color3.fromRGB(240, 120, 20),
 CC = { Brightness = 0, Contrast = 0, Saturation = 0, Tint = Color3.fromRGB(255, 220, 180) },
 Bloom = { Intensity = 0.1, Size = 100, Threshold = 0 },
 CustomSkybox = { Bk = "rbxassetid://323494035", Dn = "rbxassetid://323494368", Ft = "rbxassetid://323494130", Lf = "rbxassetid://323494252", Rt = "rbxassetid://323494067", Up = "rbxassetid://323493360" },
 },
 ["Arctic"] = {
 Brightness = 2,
 Ambient = Color3.fromRGB(0, 50, 100),
 OutdoorAmbient = Color3.fromRGB(150, 170, 200),
 GlobalShadows = true,
 ExposureCompensation = 0,
 CC = { Brightness = 0, Contrast = 0.2, Saturation = -0.3, Tint = Color3.fromRGB(220, 240, 255) },
 Bloom = { Intensity = 0.8, Size = 24, Threshold = 0.6 },
 Atmosphere = { Density = 0.45, Color = Color3.fromRGB(180, 200, 255), Decay = Color3.fromRGB(255, 255, 255), Glare = 0.6 },
 },
}

-- Ссылки на пост-эффекты
local origMaterials = {}
local function applyRealMaterials()
 task.spawn(function()
 for _, v in ipairs(workspace:GetDescendants()) do
 if v:IsA("BasePart") then
 if not origMaterials[v] then
 origMaterials[v] = v.Material
 end
 if v.Material == Enum.Material.Plastic or v.Material == Enum.Material.SmoothPlastic then
 v.Material = Enum.Material.Concrete
 end
 end
 end
 end)
end
local function restoreMaterials()
 task.spawn(function()
 for k, v in pairs(origMaterials) do
 if k and k.Parent then
 k.Material = v
 end
 end
 origMaterials = {}
 end)
end

local ccEffect, bloomEffect, sunRaysEffect, dofEffect
currentShaderTheme = nil

existingEffects = {}
local function clearExistingEffects()
 for _, v in ipairs(Lighting:GetChildren()) do
 if v:IsA("ColorCorrectionEffect") or v:IsA("BloomEffect") or v:IsA("BlurEffect") or v:IsA("SunRaysEffect") or v:IsA("DepthOfFieldEffect") then
 table.insert(existingEffects, v)
 v.Enabled = false
 end
 end
end
local function restoreExistingEffects()
 for _, v in ipairs(existingEffects) do
 v.Enabled = true
 end
 existingEffects = {}
end

local function applyShaderTheme(themeName)
 local theme = ShaderThemes[themeName]
 if not theme then return end
 currentShaderTheme = themeName

 clearExistingEffects()

 Lighting.Brightness = theme.Brightness
 Lighting.Ambient = theme.Ambient
 Lighting.OutdoorAmbient = theme.OutdoorAmbient
 if theme.ClockTime then
 Lighting.ClockTime = theme.ClockTime
 elseif theme.TimeOfDay then
 Lighting.TimeOfDay = theme.TimeOfDay
 end
 Lighting.FogEnd = theme.FogEnd
 if theme.FogStart then
 Lighting.FogStart = theme.FogStart
 end
 if theme.ExposureCompensation then
 Lighting.ExposureCompensation = theme.ExposureCompensation
 end
 
 if theme.GlobalShadows ~= nil then
 Lighting.GlobalShadows = theme.GlobalShadows
 else
 Lighting.GlobalShadows = false
 end

 if theme.Use2022Materials then
 pcall(function() game:GetService("MaterialService").Use2022Materials = true end)
 else
 pcall(function() game:GetService("MaterialService").Use2022Materials = false end)
 end

 if theme.EnvDiffuse then pcall(function() Lighting.EnvironmentDiffuseScale = theme.EnvDiffuse end) end
 if theme.EnvSpecular then pcall(function() Lighting.EnvironmentSpecularScale = theme.EnvSpecular end) end

 local atm = Lighting:FindFirstChildOfClass("Atmosphere")
 if atm then atm.Enabled = false end

 if theme.CC then
 if not ccEffect then
 ccEffect = Instance.new("ColorCorrectionEffect")
 ccEffect.Parent = Lighting
 end
 ccEffect.Brightness = theme.CC.Brightness
 ccEffect.Contrast = theme.CC.Contrast
 ccEffect.Saturation = theme.CC.Saturation
 ccEffect.TintColor = theme.CC.Tint
 ccEffect.Enabled = true
 end

 if theme.Bloom then
 if not bloomEffect then
 bloomEffect = Instance.new("BloomEffect")
 bloomEffect.Parent = Lighting
 end
 bloomEffect.Intensity = theme.Bloom.Intensity
 bloomEffect.Size = theme.Bloom.Size
 bloomEffect.Threshold = theme.Bloom.Threshold
 bloomEffect.Enabled = true
 else
 if bloomEffect then bloomEffect.Enabled = false end
 end

 if theme.SunRays then
 if not sunRaysEffect then
 sunRaysEffect = Instance.new("SunRaysEffect")
 sunRaysEffect.Parent = Lighting
 end
 sunRaysEffect.Intensity = theme.SunRays.Intensity
 sunRaysEffect.Spread = theme.SunRays.Spread
 sunRaysEffect.Enabled = true
 else
 if sunRaysEffect then sunRaysEffect.Enabled = false end
 end

 if theme.DOF then
 if not dofEffect then
 dofEffect = Instance.new("DepthOfFieldEffect")
 dofEffect.Parent = Lighting
 end
 dofEffect.FocusDistance = theme.DOF.FocusDistance
 dofEffect.InFocusRadius = theme.DOF.InFocusRadius
 dofEffect.NearIntensity = theme.DOF.NearIntensity
 dofEffect.FarIntensity = theme.DOF.FarIntensity
 dofEffect.Enabled = true
 else
 if dofEffect then dofEffect.Enabled = false end
 end

 if theme.CustomSkybox then
  local sky = Lighting:FindFirstChildOfClass("Sky")
  if not sky then
   sky = Instance.new("Sky")
   sky.Parent = Lighting
  end
  sky.SkyboxBk = theme.CustomSkybox.Bk
  sky.SkyboxDn = theme.CustomSkybox.Dn
  sky.SkyboxFt = theme.CustomSkybox.Ft
  sky.SkyboxLf = theme.CustomSkybox.Lf
  sky.SkyboxRt = theme.CustomSkybox.Rt
  sky.SkyboxUp = theme.CustomSkybox.Up
  sky.SunAngularSize = 14
  sky.Parent = nil
  sky.Parent = Lighting
 else
 end

 if theme.Atmosphere then
  local atmos = Lighting:FindFirstChildOfClass("Atmosphere")
  if not atmos then
   atmos = Instance.new("Atmosphere")
   atmos.Parent = Lighting
  end
  atmos.Density = theme.Atmosphere.Density
  atmos.Color = theme.Atmosphere.Color
  atmos.Decay = theme.Atmosphere.Decay
  atmos.Glare = theme.Atmosphere.Glare
 end

 if theme.ColorShift_Top then Lighting.ColorShift_Top = theme.ColorShift_Top end
 if theme.ColorShift_Bottom then Lighting.ColorShift_Bottom = theme.ColorShift_Bottom end
 if theme.FogColor then Lighting.FogColor = theme.FogColor end
end

local function restoreLighting()
 Lighting.Brightness = originalLight.Brightness
 Lighting.Ambient = originalLight.Ambient
 Lighting.OutdoorAmbient = originalLight.OutdoorAmbient
 if originalLight.ClockTime then
 Lighting.ClockTime = originalLight.ClockTime
 else
 Lighting.TimeOfDay = originalLight.TimeOfDay
 end
 Lighting.FogEnd = originalLight.FogEnd
 Lighting.FogStart = originalLight.FogStart
 Lighting.ExposureCompensation = originalLight.ExposureCompensation
 Lighting.GlobalShadows = true
 local atm = Lighting:FindFirstChildOfClass("Atmosphere")
 if atm then atm.Enabled = true end
 if ccEffect then ccEffect:Destroy(); ccEffect = nil end
 if bloomEffect then bloomEffect:Destroy(); bloomEffect = nil end
 if sunRaysEffect then sunRaysEffect:Destroy(); sunRaysEffect = nil end
 if dofEffect then dofEffect:Destroy(); dofEffect = nil end
 pcall(function() game:GetService("MaterialService").Use2022Materials = false end)
 if _G.MaterialsForced then
 _G.MaterialsForced = false
 restoreMaterials()
 end
 restoreExistingEffects()
 currentShaderTheme = nil
end

VisualShaders:AddToggle("EnableShaders", {
 Text = "Shaders",
 Default = false,
 Tooltip = "Включить шейдеры",
 Callback = function(Value)
 if Value then
 applyShaderTheme(Options.ShaderTheme.Value)
 else
 restoreLighting()
 end
 end
})

-- ПОСТОЯННОЕ ПРИМЕНЕНИЕ ТЕМЫ
task.spawn(function()
 while task.wait(0.05) do
 if Toggles.EnableShaders and Toggles.EnableShaders.Value and currentShaderTheme then
 local theme = ShaderThemes[currentShaderTheme]
 if theme then
 Lighting.Brightness = theme.Brightness
 Lighting.Ambient = theme.Ambient
 Lighting.OutdoorAmbient = theme.OutdoorAmbient
 if theme.ClockTime then
 Lighting.ClockTime = theme.ClockTime
 end
 if theme.ExposureCompensation then
 Lighting.ExposureCompensation = theme.ExposureCompensation
 end
 if theme.GlobalShadows ~= nil then
 Lighting.GlobalShadows = theme.GlobalShadows
 else
 Lighting.GlobalShadows = false
 end
 Lighting.FogEnd = theme.FogEnd
 if theme.FogStart then Lighting.FogStart = theme.FogStart end
 
 if theme.Use2022Materials then
 pcall(function() game:GetService("MaterialService").Use2022Materials = true end)
 else
 pcall(function() game:GetService("MaterialService").Use2022Materials = false end)
 end

 if theme.ForceMaterials then
 if not _G.MaterialsForced then
 _G.MaterialsForced = true
 applyRealMaterials()
 end
 else
 if _G.MaterialsForced then
 _G.MaterialsForced = false
 restoreMaterials()
 end
 end

 local atm = Lighting:FindFirstChildOfClass("Atmosphere")
 if atm then 
 if Toggles.EnableCustomSky and Toggles.EnableCustomSky.Value then
 atm.Enabled = true
 else
 atm.Enabled = false 
 end
 end

 for _, v in ipairs(Lighting:GetChildren()) do
 if v ~= ccEffect and v ~= bloomEffect and v ~= sunRaysEffect then
 if v:IsA("ColorCorrectionEffect") or v:IsA("BloomEffect") or v:IsA("BlurEffect") or v:IsA("SunRaysEffect") or v:IsA("DepthOfFieldEffect") then
 v.Enabled = false
 end
 end
 end

 if ccEffect and theme.CC then
 ccEffect.Enabled = true
 if not ccEffect.Parent then ccEffect.Parent = Lighting end
 end
 if bloomEffect and theme.Bloom then
 bloomEffect.Enabled = true
 if not bloomEffect.Parent then bloomEffect.Parent = Lighting end
 end
 if sunRaysEffect and theme.SunRays then
 sunRaysEffect.Enabled = true
 if not sunRaysEffect.Parent then sunRaysEffect.Parent = Lighting end
 end
 if dofEffect and theme.DOF then
 dofEffect.Enabled = true
 if not dofEffect.Parent then dofEffect.Parent = Lighting end
 end
 
 if theme.EnvDiffuse then pcall(function() Lighting.EnvironmentDiffuseScale = theme.EnvDiffuse end) end
 if theme.EnvSpecular then pcall(function() Lighting.EnvironmentSpecularScale = theme.EnvSpecular end) end
 end
 end
 end
end)

VisualShaders:AddDropdown("ShaderTheme", {
 Text = "Тема",
 Default = "Ночь",
 Values = {"Ночь", "Вечер", "Закат", "Туман", "Яркий", "Неон", "Холодный", "Тёплый", "Ультра-Реализм", "Twilight", "Luminous", "Sandstorm", "Arctic"},
 Multi = false,
 Tooltip = "выбери шейдеры",
 Callback = function(Value)
 if Toggles.EnableShaders and Toggles.EnableShaders.Value then
 applyShaderTheme(Value)
 end
 end
})

-- ==============================================
-- АТМОСФЕРА (Левая сторона)
-- ==============================================
local VisualAtmo = Tabs.Visual:AddLeftGroupbox("Атмосфера")

atmoOriginal = {
 saved = false,
 ClockTime = Lighting.ClockTime,
 TimeOfDay = Lighting.TimeOfDay,
 FogEnd = Lighting.FogEnd,
 FogStart = Lighting.FogStart,
 FogColor = Lighting.FogColor,
 OutdoorAmbient = Lighting.OutdoorAmbient,
 ColorShift_Top = Lighting.ColorShift_Top,
 ColorShift_Bottom = Lighting.ColorShift_Bottom,
}

atmoOriginalSky = {}
atmoCustomObjects = {}

SkyboxList = {
 ["HD"]={Bk="http://www.roblox.com/asset/?id=16553658937",Dn="http://www.roblox.com/asset/?id=16553660713",Ft="http://www.roblox.com/asset/?id=16553662144",Lf="http://www.roblox.com/asset/?id=16553664042",Rt="http://www.roblox.com/asset/?id=16553665766",Up="http://www.roblox.com/asset/?id=16553667750"},
 ["Black Storm"]={Bk="rbxassetid://15502511288",Dn="rbxassetid://15502508460",Ft="rbxassetid://15502510289",Lf="rbxassetid://15502507918",Rt="rbxassetid://15502509398",Up="rbxassetid://15502511911"},
 ["Snow"]={Bk="http://www.roblox.com/asset/?id=155657655",Dn="http://www.roblox.com/asset/?id=155674246",Ft="http://www.roblox.com/asset/?id=155657609",Lf="http://www.roblox.com/asset/?id=155657671",Rt="http://www.roblox.com/asset/?id=155657619",Up="http://www.roblox.com/asset/?id=155674931"},
 ["Blue Space"]={Bk="rbxassetid://15536110634",Dn="rbxassetid://15536112543",Ft="rbxassetid://15536116141",Lf="rbxassetid://15536114370",Rt="rbxassetid://15536118762",Up="rbxassetid://15536117282"},
 ["Realistic"]={Bk="rbxassetid://653719502",Dn="rbxassetid://653718790",Ft="rbxassetid://653719067",Lf="rbxassetid://653719190",Rt="rbxassetid://653718931",Up="rbxassetid://653719321"},
 ["Sunset"]={Bk="rbxassetid://600830446",Dn="rbxassetid://600831635",Ft="rbxassetid://600832720",Lf="rbxassetid://600886090",Rt="rbxassetid://600833862",Up="rbxassetid://600835177"},
 ["Space"]={Bk="http://www.roblox.com/asset/?id=166509999",Dn="http://www.roblox.com/asset/?id=166510057",Ft="http://www.roblox.com/asset/?id=166510116",Lf="http://www.roblox.com/asset/?id=166510092",Rt="http://www.roblox.com/asset/?id=166510131",Up="http://www.roblox.com/asset/?id=166510114"},
 ["Pink"]={Bk="rbxassetid://12216109205",Dn="rbxassetid://12216109875",Ft="rbxassetid://12216109489",Lf="rbxassetid://12216110170",Rt="rbxassetid://12216110471",Up="rbxassetid://12216108877"},
 ["Galaxy"]={Bk="rbxassetid://15983968922",Dn="rbxassetid://15983966825",Ft="rbxassetid://15983965025",Lf="rbxassetid://15983967420",Rt="rbxassetid://15983966246",Up="rbxassetid://15983964246"},
 ["Roblox Default"]={Bk="rbxasset://textures/sky/sky512_bk.tex",Dn="rbxasset://textures/sky/sky512_dn.tex",Ft="rbxasset://textures/sky/sky512_ft.tex",Lf="rbxasset://textures/sky/sky512_lf.tex",Rt="rbxasset://textures/sky/sky512_rt.tex",Up="rbxasset://textures/sky/sky512_up.tex"},
}
currentSkybox = nil
skyboxOriginal = { saved = false, originalSky = nil, originalBk = nil, originalDn = nil, originalFt = nil, originalLf = nil, originalRt = nil, originalUp = nil }

function saveSkyboxOriginal()
 if skyboxOriginal.saved then return end
 local existing = Lighting:FindFirstChildOfClass("Sky")
 if existing then
 skyboxOriginal.originalSky = existing
 skyboxOriginal.originalBk = existing.SkyboxBk
 skyboxOriginal.originalDn = existing.SkyboxDn
 skyboxOriginal.originalFt = existing.SkyboxFt
 skyboxOriginal.originalLf = existing.SkyboxLf
 skyboxOriginal.originalRt = existing.SkyboxRt
 skyboxOriginal.originalUp = existing.SkyboxUp
 skyboxOriginal.saved = true
 else
 skyboxOriginal.saved = true
 end
end

function applySkybox(skyboxName)
 if currentSkybox == skyboxName then return end
 saveSkyboxOriginal()
 local s = SkyboxList[skyboxName] or SkyboxList["HD"]
 local sky = Lighting:FindFirstChildOfClass("Sky")
 if not sky then
 sky = Instance.new("Sky")
 sky.Parent = Lighting
 end
 sky.SkyboxBk = s.Bk
 sky.SkyboxDn = s.Dn
 sky.SkyboxFt = s.Ft
 sky.SkyboxLf = s.Lf
 sky.SkyboxRt = s.Rt
 sky.SkyboxUp = s.Up
 sky.StarCount = 3000
 sky.SunAngularSize = 11
 sky.MoonAngularSize = 11
 sky.Parent = nil
 sky.Parent = Lighting
 currentSkybox = skyboxName
end

function disableSkybox()
 if currentSkybox == nil then return end
 if skyboxOriginal.originalSky then
 local sky = skyboxOriginal.originalSky
 sky.SkyboxBk = skyboxOriginal.originalBk or ""
 sky.SkyboxDn = skyboxOriginal.originalDn or ""
 sky.SkyboxFt = skyboxOriginal.originalFt or ""
 sky.SkyboxLf = skyboxOriginal.originalLf or ""
 sky.SkyboxRt = skyboxOriginal.originalRt or ""
 sky.SkyboxUp = skyboxOriginal.originalUp or ""
 if not sky.Parent then sky.Parent = Lighting end
 else
 for _, s in ipairs(Lighting:GetChildren()) do
 if s:IsA("Sky") then s:Destroy() end
 end
 end
 currentSkybox = nil
end

function saveAtmoOriginal()
 if atmoOriginal.saved then return end
 atmoOriginal.ClockTime = Lighting.ClockTime
 atmoOriginal.TimeOfDay = Lighting.TimeOfDay
 atmoOriginal.FogEnd = Lighting.FogEnd
 atmoOriginal.FogStart = Lighting.FogStart
 atmoOriginal.FogColor = Lighting.FogColor
 atmoOriginal.OutdoorAmbient = Lighting.OutdoorAmbient
 atmoOriginal.ColorShift_Top = Lighting.ColorShift_Top
 atmoOriginal.saved = true

 atmoOriginalSky = {}
 for _, obj in ipairs(Lighting:GetChildren()) do
 if obj:IsA("Sky") or obj:IsA("Atmosphere") then
 atmoOriginalSky[obj] = {
 parent = obj.Parent,
 props = obj:IsA("Atmosphere") and {
 Density = obj.Density,
 Offset = obj.Offset,
 Glare = obj.Glare,
 Haze = obj.Haze,
 Color = obj.Color,
 Decay = obj.Decay,
 Enabled = obj.Enabled,
 } or nil
 }
 end
 end
end

function restoreAtmoOriginal()
 if not atmoOriginal.saved then return end

 Lighting.ClockTime = atmoOriginal.ClockTime
 Lighting.TimeOfDay = atmoOriginal.TimeOfDay
 Lighting.FogEnd = atmoOriginal.FogEnd
 Lighting.FogStart = atmoOriginal.FogStart
 Lighting.FogColor = atmoOriginal.FogColor
 Lighting.OutdoorAmbient = atmoOriginal.OutdoorAmbient
 Lighting.ColorShift_Top = atmoOriginal.ColorShift_Top
 if atmoOriginal.ColorShift_Bottom then Lighting.ColorShift_Bottom = atmoOriginal.ColorShift_Bottom end

 disableSkybox()
 for _, obj in ipairs(atmoCustomObjects) do
 pcall(function() obj:Destroy() end)
 end
 atmoCustomObjects = {}

 for obj, data in pairs(atmoOriginalSky) do
 if obj and obj.Parent then
 if obj:IsA("Atmosphere") and data.props then
 obj.Density = data.props.Density
 obj.Offset = data.props.Offset
 obj.Glare = data.props.Glare
 obj.Haze = data.props.Haze
 obj.Color = data.props.Color
 obj.Decay = data.props.Decay
 obj.Enabled = data.props.Enabled
 end
 elseif obj and not obj.Parent then
 pcall(function() obj.Parent = data.parent end)
 end
 end
end

local function maintainAtmosphere()
 if Toggles.EnableCustomTime and Toggles.EnableCustomTime.Value then
 local timeVal = Options.CustomTimeValue and Options.CustomTimeValue.Value or 12
 Lighting.ClockTime = timeVal
 end

 if Toggles.EnableCustomFog and Toggles.EnableCustomFog.Value then
 local fogColor = Options.CustomFogColor and Options.CustomFogColor.Value or Color3.fromRGB(200, 200, 200)
 local fogDist = Options.CustomFogDistance and Options.CustomFogDistance.Value or 1000
 Lighting.FogColor = fogColor
 Lighting.FogEnd = fogDist
 Lighting.FogStart = 0
 end
end

function applyAtmosphere()
 saveAtmoOriginal()

 local shadersActive = Toggles.EnableShaders and Toggles.EnableShaders.Value

 if Toggles.EnableCustomTime and Toggles.EnableCustomTime.Value then
 local timeVal = Options.CustomTimeValue and Options.CustomTimeValue.Value or 12
 Lighting.ClockTime = timeVal
 Lighting.TimeOfDay = tostring(timeVal) .. ":00:00"
 else
 if not shadersActive then
 Lighting.ClockTime = atmoOriginal.ClockTime
 Lighting.TimeOfDay = atmoOriginal.TimeOfDay
 end
 end

 if Toggles.EnableCustomFog and Toggles.EnableCustomFog.Value then
 fogColor = Options.CustomFogColor and Options.CustomFogColor.Value or Color3.fromRGB(200, 200, 200)
 fogDist = Options.CustomFogDistance and Options.CustomFogDistance.Value or 1000
 Lighting.FogColor = fogColor
 Lighting.FogEnd = fogDist
 Lighting.FogStart = 0
 else
 if not shadersActive then
 Lighting.FogEnd = atmoOriginal.FogEnd
 Lighting.FogStart = atmoOriginal.FogStart
 Lighting.FogColor = atmoOriginal.FogColor
 end
 end

 if Toggles.EnableCustomSky and Toggles.EnableCustomSky.Value then
 applySkybox(Options.SkyboxType and Options.SkyboxType.Value or "HD")
 else
 disableSkybox()
 for obj, data in pairs(atmoOriginalSky) do
 if obj:IsA("Sky") and not obj.Parent then
 pcall(function() obj.Parent = data.parent end)
 end
 end
 end

 if Toggles.EnableSkyboxColor and Toggles.EnableSkyboxColor.Value then
 local sc = Options.SkyboxColor and Options.SkyboxColor.Value or Color3.fromRGB(128, 128, 128)
 Lighting.ColorShift_Top = sc
 Lighting.ColorShift_Bottom = sc
 else
 Lighting.ColorShift_Top = atmoOriginal.ColorShift_Top or Color3.fromRGB(0, 0, 0)
 Lighting.ColorShift_Bottom = atmoOriginal.ColorShift_Bottom or Color3.fromRGB(0, 0, 0)
 end
end

VisualAtmo:AddToggle("EnableCustomTime", {
 Text = "Время суток",
 Default = false,
 Tooltip = "Заморозить и изменить время суток",
 Callback = function(Value)
 if Value then
 applyAtmosphere()
 else
 if not (Toggles.EnableShaders and Toggles.EnableShaders.Value) then
 Lighting.ClockTime = atmoOriginal.ClockTime
 Lighting.TimeOfDay = atmoOriginal.TimeOfDay
 end
 end
 end
})
VisualAtmo:AddSlider("CustomTimeValue", {
 Text = "Час",
 Default = 12,
 Min = 0,
 Max = 24,
 Rounding = 1,
 Compact = false,
 Callback = function(Value)
 if Toggles.EnableCustomTime and Toggles.EnableCustomTime.Value then
 applyAtmosphere()
 end
 end
})

VisualAtmo:AddToggle("EnableCustomSky", {
 Text = "Skybox",
 Default = false,
 Tooltip = "Заменяет небо на кастомный скайбокс",
 Callback = function(Value)
 if Value then
 applySkybox(Options.SkyboxType and Options.SkyboxType.Value or "HD")
 else
 disableSkybox()
 if not (Toggles.EnableShaders and Toggles.EnableShaders.Value) then
 restoreAtmoOriginal()
 end
 end
 end
})

VisualAtmo:AddDropdown("SkyboxType", {
 Text = "Список скайбоксов",
 Default = "HD",
 Values = {"HD", "Black Storm", "Snow", "Blue Space", "Realistic", "Sunset", "Space", "Pink", "Galaxy", "Roblox Default"},
 Multi = false,
 Tooltip = "Выбери скайбокс",
 Callback = function(Value)
 if Toggles.EnableCustomSky and Toggles.EnableCustomSky.Value then
 applySkybox(Value)
 end
 end
})

VisualAtmo:AddToggle("EnableSkyboxColor", {
 Text = "Цвет скайбокса",
 Default = false,
 Tooltip = "Изменить цвет неба на кастомный через цветовую палитру",
 Callback = function(Value)
 if Value then
 local sc = Options.SkyboxColor and Options.SkyboxColor.Value or Color3.fromRGB(128, 128, 128)
 Lighting.ColorShift_Top = sc
 Lighting.ColorShift_Bottom = sc
 else
 Lighting.ColorShift_Top = atmoOriginal.ColorShift_Top or Color3.fromRGB(0, 0, 0)
 Lighting.ColorShift_Bottom = atmoOriginal.ColorShift_Bottom or Color3.fromRGB(0, 0, 0)
 end
 end
})

VisualAtmo:AddLabel("Цвет неба"):AddColorPicker("SkyboxColor", {
 Default = Color3.fromRGB(128, 128, 128),
 Title = "Цвет скайбокса",
 Callback = function(Value)
 if Toggles.EnableSkyboxColor and Toggles.EnableSkyboxColor.Value then
 Lighting.ColorShift_Top = Value
 Lighting.ColorShift_Bottom = Value
 end
 end
})

VisualAtmo:AddToggle("EnableCustomFog", {
 Text = "Туман",
 Default = false,
 Tooltip = "Густой туман с настраиваемым цветом",
 Callback = function(Value)
 applyAtmosphere()
 if not Value and not (Toggles.EnableShaders and Toggles.EnableShaders.Value) then
 Lighting.FogEnd = atmoOriginal.FogEnd
 Lighting.FogStart = atmoOriginal.FogStart
 Lighting.FogColor = atmoOriginal.FogColor
 end
 end
}):AddColorPicker("CustomFogColor", {
 Default = Color3.fromRGB(200, 200, 200),
 Title = "Цвет тумана",
 Callback = function(Value)
 if Toggles.EnableCustomFog and Toggles.EnableCustomFog.Value then
 applyAtmosphere()
 end
 end
})
VisualAtmo:AddSlider("CustomFogDistance", {
 Text = "Дальность тумана",
 Default = 1000,
 Min = 50,
 Max = 10000,
 Rounding = 0,
 Compact = false,
 Callback = function(Value)
 if Toggles.EnableCustomFog and Toggles.EnableCustomFog.Value then
 applyAtmosphere()
 end
 end
})

RunService.Heartbeat:Connect(function()
 local anyAtmo = (Toggles.EnableCustomTime and Toggles.EnableCustomTime.Value)
 or (Toggles.EnableCustomFog and Toggles.EnableCustomFog.Value)
 or (Toggles.EnableCustomSky and Toggles.EnableCustomSky.Value)
 if anyAtmo then
 maintainAtmosphere()
 end
end)

-- ==============================================
-- ОСВЕЩЕНИЕ (Левая сторона)
-- ==============================================
local VisualBright = Tabs.Visual:AddLeftGroupbox("Освещение")

VisualBright:AddToggle("EnableFullbright", {
    Text = "Fullbright",
    Default = false,
    Tooltip = "типа максимальная яркость",
    Callback = function(Value)
        if Value then
            if not originalLight._fbSaved then
                originalLight._fbSaved = true
                originalLight._fbBrightness = Lighting.Brightness
                originalLight._fbAmbient = Lighting.Ambient
                originalLight._fbOutdoorAmbient = Lighting.OutdoorAmbient
                originalLight._fbClockTime = Lighting.ClockTime
                originalLight._fbGlobalShadows = Lighting.GlobalShadows
                originalLight._fbExposure = Lighting.ExposureCompensation
            end
            Lighting.Brightness = 3
            Lighting.Ambient = Color3.fromRGB(255, 255, 255)
            Lighting.OutdoorAmbient = Color3.fromRGB(255, 255, 255)
            Lighting.ClockTime = 12
            Lighting.GlobalShadows = false
            Lighting.ExposureCompensation = 0.5
        else
            if originalLight._fbSaved then
                Lighting.Brightness = originalLight._fbBrightness
                Lighting.Ambient = originalLight._fbAmbient
                Lighting.OutdoorAmbient = originalLight._fbOutdoorAmbient
                Lighting.ClockTime = originalLight._fbClockTime
                Lighting.GlobalShadows = originalLight._fbGlobalShadows
                Lighting.ExposureCompensation = originalLight._fbExposure
            end
        end
    end
})

-- ==============================================
-- ТЕКСТУРЫ КАРТЫ (Правая сторона)
-- ==============================================
local VisualTex = Tabs.Visual:AddRightGroupbox("Текстуры карты")

VisualTex:AddToggle("EnableGeneralTint", {
 Text = "Общее",
 Default = false,
 Tooltip = "Красит всё глобальное освещение и атмосферу карты",
})
VisualTex:AddLabel("Цвет общего освещения"):AddColorPicker("GeneralTintColor", {
 Default = Color3.fromRGB(150, 200, 255),
 Title = "Общий цвет",
})

origPartColors = {}
recoloredMats = {
 [Enum.Material.Grass] = Color3.fromRGB(75, 150, 75),
 [Enum.Material.Wood] = Color3.fromRGB(130, 100, 75),
 [Enum.Material.Concrete] = Color3.fromRGB(150, 150, 150),
 [Enum.Material.Plastic] = Color3.fromRGB(200, 200, 200),
 [Enum.Material.SmoothPlastic] = Color3.fromRGB(200, 200, 200),
}

function applyTextureColors()
 if not Toggles or not Toggles.EnableTexColors then return end
 if not Toggles.EnableTexColors.Value then return end
 
 if Options.TexColorGrass then recoloredMats[Enum.Material.Grass] = Options.TexColorGrass.Value end
 if Options.TexColorWood then recoloredMats[Enum.Material.Wood] = Options.TexColorWood.Value end
 if Options.TexColorConcrete then recoloredMats[Enum.Material.Concrete] = Options.TexColorConcrete.Value end
 if Options.TexColorPlastic then
 recoloredMats[Enum.Material.Plastic] = Options.TexColorPlastic.Value
 recoloredMats[Enum.Material.SmoothPlastic] = Options.TexColorPlastic.Value
 end

 task.spawn(function()
 for _, part in ipairs(workspace:GetDescendants()) do
 if part:IsA("BasePart") then
 local tColor = recoloredMats[part.Material]
 if tColor then
 if not origPartColors[part] then
 origPartColors[part] = part.Color
 end
 part.Color = tColor
 end
 end
 end
 pcall(function()
 if Options.TexColorGrass then workspace.Terrain:SetMaterialColor(Enum.Material.Grass, Options.TexColorGrass.Value) end
 if Options.TexColorWood then workspace.Terrain:SetMaterialColor(Enum.Material.Wood, Options.TexColorWood.Value) end
 if Options.TexColorConcrete then workspace.Terrain:SetMaterialColor(Enum.Material.Concrete, Options.TexColorConcrete.Value) end
 if Options.TexColorPlastic then workspace.Terrain:SetMaterialColor(Enum.Material.Plastic, Options.TexColorPlastic.Value) end
 end)
 end)
end

VisualTex:AddToggle("EnableTexColors", {
 Text = "Изменить цвета текстур",
 Default = false,
 Tooltip = "Перекрашивает объекты на карте по их материалу",
 Callback = function(Value)
 if Value then
 applyTextureColors()
 else
 for part, color in pairs(origPartColors) do
 if part and part.Parent then
 part.Color = color
 end
 end
 origPartColors = {}
 pcall(function()
 workspace.Terrain:SetMaterialColor(Enum.Material.Grass, Color3.fromRGB(106, 127, 63))
 workspace.Terrain:SetMaterialColor(Enum.Material.Wood, Color3.fromRGB(212, 175, 55))
 workspace.Terrain:SetMaterialColor(Enum.Material.Concrete, Color3.fromRGB(127, 127, 127))
 workspace.Terrain:SetMaterialColor(Enum.Material.Plastic, Color3.fromRGB(200, 200, 200))
 end)
 end
 end
})

VisualTex:AddLabel("Цвет травы"):AddColorPicker("TexColorGrass", {
 Default = Color3.fromRGB(75, 150, 75),
 Title = "Цвет травы",
 Callback = applyTextureColors
})
VisualTex:AddLabel("Цвет дерева"):AddColorPicker("TexColorWood", {
 Default = Color3.fromRGB(130, 100, 75),
 Title = "Цвет дерева",
 Callback = applyTextureColors
})
VisualTex:AddLabel("Цвет камня/бетона"):AddColorPicker("TexColorConcrete", {
 Default = Color3.fromRGB(150, 150, 150),
 Title = "Цвет камня/бетона",
 Callback = applyTextureColors
})
VisualTex:AddLabel("Цвет пластика"):AddColorPicker("TexColorPlastic", {
 Default = Color3.fromRGB(200, 200, 200),
 Title = "Цвет пластика",
 Callback = applyTextureColors
})

origGeneralTint = {}

RunService.Heartbeat:Connect(function()
 if not Toggles then return end
 local lighting = game:GetService("Lighting")

 if Toggles.EnableGeneralTint and Toggles.EnableGeneralTint.Value then
 local cColor = Options.GeneralTintColor and Options.GeneralTintColor.Value or Color3.fromRGB(150, 200, 255)
 
 if not origGeneralTint["OutdoorAmbient"] then
 origGeneralTint["OutdoorAmbient"] = lighting.OutdoorAmbient
 origGeneralTint["ColorShift_Top"] = lighting.ColorShift_Top
 end
 lighting.OutdoorAmbient = cColor
 lighting.ColorShift_Top = cColor

 local atm = lighting:FindFirstChildOfClass("Atmosphere")
 if not atm then
 atm = Instance.new("Atmosphere")
 atm.Name = "CustomAtmosphere"
 atm.Density = 0.3
 atm.Offset = 0.25
 atm.Parent = lighting
 origGeneralTint[atm] = "Created"
 elseif not origGeneralTint[atm] then
 origGeneralTint[atm] = {Color = atm.Color, Decay = atm.Decay, Enabled = atm.Enabled}
 end
 
 atm.Enabled = true
 atm.Color = cColor
 atm.Decay = Color3.new(cColor.R * 0.5, cColor.G * 0.5, cColor.B * 0.5)
 else
 if origGeneralTint["OutdoorAmbient"] then
 lighting.OutdoorAmbient = origGeneralTint["OutdoorAmbient"]
 lighting.ColorShift_Top = origGeneralTint["ColorShift_Top"]
 origGeneralTint["OutdoorAmbient"] = nil
 end
 for obj, data in pairs(origGeneralTint) do
 if typeof(obj) == "Instance" and obj:IsA("Atmosphere") then
 if data == "Created" then
 obj:Destroy()
 else
 obj.Color = data.Color
 obj.Decay = data.Decay
 obj.Enabled = data.Enabled
 end
 end
 end
 origGeneralTint = {}
 end
end)

-- ==============================================
-- ANTI-KICK ITEM ESP (ОПТИМИЗИРОВАННЫЙ — БЕЗ ФРИЗОВ)
-- ==============================================
do
    local AntiKickItemESP = Tabs.Visual:AddRightGroupbox("Anti-Kick Item ESP")
    
    local akItemESP = {
        active = false,
        color = Color3.fromRGB(255, 255, 255),
        mode = "Заливка",
        items = {}, -- [item] = highlight
        connections = {},
        scanTask = nil,
        knownFolders = {}, -- кэшируем папки SpawnedInToys
    }
    
    -- ТОЛЬКО ЭТИ 7 ПРЕДМЕТОВ
    local ANTI_KICK_ITEM_NAMES = {
        "NinjaShuriken",
        "ToolPickaxe",
        "NinjaKunai",
        "ToolCleaver",
        "JapaneseLantern",
        "SprayCanWD",
        "SpookyCandle1",
    }
    
    -- Быстрая проверка по имени (без лишних вызовов)
    local function isAntiKickItem(obj)
        if not obj or not obj:IsA("Model") then return false end
        local name = obj.Name
        for _, itemName in ipairs(ANTI_KICK_ITEM_NAMES) do
            if name == itemName then return true end
        end
        return false
    end
    
    -- Создать Highlight
    local function createItemHighlight(item)
        if akItemESP.items[item] then return end
        local hl = Instance.new("Highlight")
        hl.Name = "AK_Item_ESP"
        hl.Adornee = item
        hl.FillColor = akItemESP.color
        hl.OutlineColor = akItemESP.color
        hl.FillTransparency = akItemESP.mode == "Контур" and 1 or 0.5
        hl.OutlineTransparency = akItemESP.mode == "Контур" and 0 or 0.2
        hl.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
        hl.Parent = item
        akItemESP.items[item] = hl
    end
    
    -- Удалить Highlight
    local function removeItemHighlight(item)
        local hl = akItemESP.items[item]
        if hl then
            hl:Destroy()
            akItemESP.items[item] = nil
        end
    end
    
    -- Обновить стиль всех подсветок (быстро)
    local function updateAllItemStyles()
        local mode = akItemESP.mode
        local fillT = mode == "Контур" and 1 or 0.5
        local outlineT = mode == "Контур" and 0 or 0.2
        for item, hl in pairs(akItemESP.items) do
            if hl and hl.Parent then
                hl.FillColor = akItemESP.color
                hl.OutlineColor = akItemESP.color
                hl.FillTransparency = fillT
                hl.OutlineTransparency = outlineT
            end
        end
    end
    
    -- Сканируем ОДНУ папку (без перебора всего workspace)
    local function scanFolder(folder)
        if not folder or not folder.Parent then return end
        for _, child in ipairs(folder:GetChildren()) do
            if isAntiKickItem(child) and not akItemESP.items[child] then
                createItemHighlight(child)
            end
        end
    end
    
    -- Найти все папки SpawnedInToys и просканировать их
    local function scanAllSpawnFolders()
        if not akItemESP.active then return end
        
        -- Проверяем существующие папки
        local folders = {}
        for _, player in ipairs(Players:GetPlayers()) do
            local folder = workspace:FindFirstChild(player.Name .. "SpawnedInToys")
            if folder then
                table.insert(folders, folder)
                if not akItemESP.knownFolders[folder] then
                    akItemESP.knownFolders[folder] = true
                    -- Подписываемся на новые предметы в этой папке
                    local conn = folder.ChildAdded:Connect(function(child)
                        if akItemESP.active and isAntiKickItem(child) then
                            createItemHighlight(child)
                        end
                    end)
                    table.insert(akItemESP.connections, conn)
                    scanFolder(folder)
                end
            end
        end
        
        -- Удаляем подсветку с предметов, которых больше нет (лёгкая проверка)
        for item, hl in pairs(akItemESP.items) do
            if not item or not item.Parent then
                if hl then hl:Destroy() end
                akItemESP.items[item] = nil
            end
        end
    end
    
    -- Полная очистка
    local function clearAllItems()
        for item, hl in pairs(akItemESP.items) do
            if hl then hl:Destroy() end
        end
        akItemESP.items = {}
        akItemESP.knownFolders = {}
    end
    
    -- === UI ===
    
    AntiKickItemESP:AddToggle("EnableAntiKickItemESP", {
        Text = "Anti-Kick Item ESP",
        Default = false,
        Tooltip = "Подсвечивает: Shuriken, Kunai, Pickaxe, Cleaver, Lantern, SprayCan, Candle",
        Callback = function(v)
            akItemESP.active = v
            
            -- Отключаем старые коннекты
            for _, conn in ipairs(akItemESP.connections) do
                pcall(conn.Disconnect, conn)
            end
            akItemESP.connections = {}
            if akItemESP.scanTask then
                task.cancel(akItemESP.scanTask)
                akItemESP.scanTask = nil
            end
            
            if v then
                -- Сканируем всё сразу (один раз)
                scanAllSpawnFolders()
                
                -- Подписываемся на новых игроков (у них появится папка)
                local playerConn = Players.PlayerAdded:Connect(function(player)
                    task.wait(0.5)
                    if akItemESP.active then
                        local folder = workspace:FindFirstChild(player.Name .. "SpawnedInToys")
                        if folder and not akItemESP.knownFolders[folder] then
                            akItemESP.knownFolders[folder] = true
                            local conn = folder.ChildAdded:Connect(function(child)
                                if akItemESP.active and isAntiKickItem(child) then
                                    createItemHighlight(child)
                                end
                            end)
                            table.insert(akItemESP.connections, conn)
                            scanFolder(folder)
                        end
                    end
                end)
                table.insert(akItemESP.connections, playerConn)
                
                -- Фоновый цикл: только проверка живых предметов (без перебора workspace)
                akItemESP.scanTask = task.spawn(function()
                    while akItemESP.active do
                        -- Проверяем, не пропали ли предметы
                        for item, hl in pairs(akItemESP.items) do
                            if not item or not item.Parent then
                                if hl then hl:Destroy() end
                                akItemESP.items[item] = nil
                            end
                        end
                        task.wait(0.5) -- редкая проверка, не грузит
                    end
                end)
                
                Library:Notify("Anti-Kick Item ESP ВКЛ (оптимизирован)", 2)
            else
                clearAllItems()
                Library:Notify("Anti-Kick Item ESP ВЫКЛ", 2)
            end
        end
    })
    
    AntiKickItemESP:AddLabel("Цвет подсветки"):AddColorPicker("AntiKickItemESPColor", {
        Default = Color3.fromRGB(255, 255, 255),
        Title = "Цвет Anti-Kick Item ESP",
        Callback = function(v)
            akItemESP.color = v
            updateAllItemStyles()
        end
    })
    
    AntiKickItemESP:AddDropdown("AntiKickItemESPMode", {
        Text = "Режим",
        Default = "Заливка",
        Values = {"Контур", "Заливка"},
        Multi = false,
        Tooltip = "Контур — только обводка, Заливка — заливка + обводка",
        Callback = function(v)
            akItemESP.mode = v
            updateAllItemStyles()
        end
    })
    
    AntiKickItemESP:AddButton({
        Text = "Сканировать заново",
        Tooltip = "Пересканировать папки SpawnedInToys",
        Func = function()
            if akItemESP.active then
                clearAllItems()
                akItemESP.knownFolders = {}
                for _, conn in ipairs(akItemESP.connections) do
                    pcall(conn.Disconnect, conn)
                end
                akItemESP.connections = {}
                scanAllSpawnFolders()
                Library:Notify("Anti-Kick Item ESP: пересканировано", 2)
            else
                Library:Notify("Сначала включи Anti-Kick Item ESP!", 2)
            end
        end
    })
    
    -- Автозапуск при загрузке
    task.spawn(function()
        task.wait(0.5)
        if Toggles.EnableAntiKickItemESP and Toggles.EnableAntiKickItemESP.Value then
            akItemESP.active = true
            scanAllSpawnFolders()
            if akItemESP.scanTask then task.cancel(akItemESP.scanTask) end
            akItemESP.scanTask = task.spawn(function()
                while akItemESP.active do
                    for item, hl in pairs(akItemESP.items) do
                        if not item or not item.Parent then
                            if hl then hl:Destroy() end
                            akItemESP.items[item] = nil
                        end
                    end
                    task.wait(0.5)
                end
            end)
        end
    end)
end

-- ==============================================
-- EFFECTS (Левая сторона)
-- ==============================================
local VisualEffects = Tabs.Visual:AddLeftGroupbox("Effects")

VisualEffects:AddToggle("EnableBlur", {
 Text = "Blur",
 Default = false,
 Tooltip = "Размытие экрана",
 Callback = function(Value)
 if Value then
 local blur = Instance.new("BlurEffect")
 blur.Name = "nLheBlur"
 blur.Size = Options.BlurSize.Value
 blur.Parent = game:GetService("Lighting")
 else
 local ex = game:GetService("Lighting"):FindFirstChild("nLheBlur")
 if ex then ex:Destroy() end
 end
 end
})

VisualEffects:AddSlider("BlurSize", {
 Text = "Blur Size",
 Default = 10,
 Min = 0,
 Max = 24,
 Rounding = 1,
 Increment = 0.5,
 Tooltip = "Сила размытия",
 Callback = function(Value)
 local blur = game:GetService("Lighting"):FindFirstChild("nLheBlur")
 if blur then blur.Size = Value end
 end
})

-- ==============================================
-- 3RD PERSON EFFECTS (Левая сторона)
-- ==============================================
local Visual3rdEffects = Tabs.Visual:AddLeftGroupbox("3rd Person Effects")

Visual3rdEffects:AddToggle("Enable3rdPersonEffects", {
 Text = "Эффекты (3rd Person)",
 Default = false,
 Tooltip = "Визуальные эффекты на персонаже, видны только от 3 лица",
 Callback = function(Value)
 if Value then
 apply3rdPersonEffect(Options.EffectType and Options.EffectType.Value or "Fire")
 else
 remove3rdPersonEffect()
 end
 end
})

Visual3rdEffects:AddDropdown("EffectType", {
 Text = "Список эффектов",
 Default = "Fire",
 Values = {"Fire", "Sparkles", "Toxic", "Godly", "Super Sayien", "North Star", "Blue Lord", "Pink Aura", "Angel Wing", "Sweet Heart", "Ethereal Aura"},
 Multi = false,
 Tooltip = "Выбери эффект для персонажа",
 Callback = function(Value)
 if Toggles.Enable3rdPersonEffects and Toggles.Enable3rdPersonEffects.Value then
 apply3rdPersonEffect(Value)
 end
 end
})

Visual3rdEffects:AddLabel("Цвет эффектов"):AddColorPicker("EffectColor", {
 Default = Color3.fromRGB(255, 100, 0),
 Title = "Цвет эффекта",
 Callback = function(Value)
 if Toggles.Enable3rdPersonEffects and Toggles.Enable3rdPersonEffects.Value then
 apply3rdPersonEffect(Options.EffectType and Options.EffectType.Value or "Fire")
 end
 end
})

local current3rdEffectName = nil
local current3rdEffectParts = {}

local function clear3rdEffectParts()
 for _, part in ipairs(current3rdEffectParts) do
 pcall(function() part:Destroy() end)
 end
 current3rdEffectParts = {}
end

AuraModels = {
 ["Godly"] = "rbxassetid://16699750981",
 ["Super Sayien"] = "rbxassetid://116109508364297",
 ["North Star"] = "rbxassetid://83945069652732",
 ["Blue Lord"] = "rbxassetid://10974316799",
 ["Pink Aura"] = "rbxassetid://115980859615239",
 ["Angel Wing"] = "rbxassetid://90022969696073",
 ["Sweet Heart"] = "rbxassetid://91724768175470",
 ["Ethereal Aura"] = "rbxassetid://97041568674250",
}
currentAuraModel = nil
lastLoadedAura = nil

function loadAuraModel(effectName)
 local id = AuraModels[effectName]
 if not id then return false end
 local ok, m = pcall(function() return game:GetObjects(id)[1] end)
 if ok and m then
 currentAuraModel = m
 return true
 end
 return false
end

function enableAuraModel(char)
 if not currentAuraModel then return end
 local tmp = currentAuraModel:Clone()
 local allowedTypes = {
 ParticleEmitter = true, Fire = true, Smoke = true, Sparkles = true,
 PointLight = true, SpotLight = true, SurfaceLight = true,
 Beam = true, Trail = true, BillboardGui = true,
 }
 local ec = (Options.EffectColor and Options.EffectColor.Value) or nil
 for _, o in ipairs(tmp:GetDescendants()) do
 if allowedTypes[o.ClassName] then
 local cl = o:Clone()
 local pn = o.Parent and o.Parent.Name
 local tgt = pn and char:FindFirstChild(pn) or char:FindFirstChildWhichIsA("BasePart")
 if tgt and not tgt:FindFirstChild(cl.Name) then
 cl.Parent = tgt
 if ec then
 pcall(function()
 if cl:IsA("ParticleEmitter") then
 cl.Color = ColorSequence.new(ec)
 elseif cl:IsA("Fire") then
 cl.Color = ec
 cl.SecondaryColor = ec
 elseif cl:IsA("Smoke") then
 cl.Color = ec
 elseif cl:IsA("Sparkles") then
 cl.SparkleColor = ec
 elseif cl:IsA("PointLight") or cl:IsA("SpotLight") or cl:IsA("SurfaceLight") then
 cl.Color = ec
 elseif cl:IsA("Beam") then
 cl.Color = ColorSequence.new(ec)
 elseif cl:IsA("Trail") then
 cl.Color = ColorSequence.new(ec)
 end
 end)
 end
 table.insert(current3rdEffectParts, cl)
 end
 end
 end
 tmp:Destroy()
end

function apply3rdPersonEffect(effectName)
 remove3rdPersonEffect()
 local char = LocalPlayer.Character
 if not char then return end
 local hrp = char:FindFirstChild("HumanoidRootPart")
 local torso = char:FindFirstChild("Torso") or char:FindFirstChild("UpperTorso")
 if not hrp or not torso then return end

 current3rdEffectName = effectName

 if effectName == "Fire" then
 local ec = (Options.EffectColor and Options.EffectColor.Value) or Color3.fromRGB(255, 100, 0)
 local fire = Instance.new("Fire")
 fire.Name = "nLhe3rdEffect"
 fire.Size = 5
 fire.Color = ec
 fire.SecondaryColor = ec
 fire.Heat = 5
 fire.Parent = torso
 table.insert(current3rdEffectParts, fire)
 local fire2 = Instance.new("Fire")
 fire2.Name = "nLhe3rdEffect2"
 fire2.Size = 3
 fire2.Color = ec
 fire2.SecondaryColor = ec
 fire2.Heat = 3
 fire2.Parent = hrp
 table.insert(current3rdEffectParts, fire2)
 local pl = Instance.new("PointLight")
 pl.Name = "nLhe3rdEffectLight"
 pl.Color = ec
 pl.Range = 12
 pl.Brightness = 3
 pl.Parent = hrp
 table.insert(current3rdEffectParts, pl)

 elseif effectName == "Sparkles" then
 local ec = (Options.EffectColor and Options.EffectColor.Value) or Color3.fromRGB(255, 255, 255)
 local sparkles = Instance.new("Sparkles")
 sparkles.Name = "nLhe3rdEffect"
 sparkles.SparkleColor = ec
 sparkles.Parent = torso
 table.insert(current3rdEffectParts, sparkles)
 local att = Instance.new("Attachment")
 att.Name = "nLhe3rdEffectAtt"
 att.Parent = hrp
 local pe = Instance.new("ParticleEmitter")
 pe.Texture = "rbxassetid://243660364"
 pe.Color = ColorSequence.new(ec)
 pe.Size = NumberSequence.new({NumberSequenceKeypoint.new(0, 0.5, 0), NumberSequenceKeypoint.new(1, 1, 0)})
 pe.Transparency = NumberSequence.new({NumberSequenceKeypoint.new(0, 0, 0), NumberSequenceKeypoint.new(1, 1, 0)})
 pe.Lifetime = NumberRange.new(1)
 pe.Rate = 30
 pe.Speed = NumberRange.new(1, 3)
 pe.Parent = att
 table.insert(current3rdEffectParts, att)
 local pl = Instance.new("PointLight")
 pl.Name = "nLhe3rdEffectLight"
 pl.Color = ec
 pl.Range = 10
 pl.Brightness = 2
 pl.Parent = hrp
 table.insert(current3rdEffectParts, pl)

 elseif effectName == "Toxic" then
 local ec = (Options.EffectColor and Options.EffectColor.Value) or Color3.fromRGB(50, 255, 0)
 local smoke = Instance.new("Smoke")
 smoke.Name = "nLhe3rdEffect"
 smoke.Color = ec
 smoke.Size = 5
 smoke.RiseVelocity = 2
 smoke.Opacity = 0.6
 smoke.Parent = torso
 table.insert(current3rdEffectParts, smoke)
 local smoke2 = Instance.new("Smoke")
 smoke2.Name = "nLhe3rdEffect2"
 smoke2.Color = ec
 smoke2.Size = 3
 smoke2.RiseVelocity = 1
 smoke2.Opacity = 0.5
 smoke2.Parent = hrp
 table.insert(current3rdEffectParts, smoke2)
 local pl = Instance.new("PointLight")
 pl.Name = "nLhe3rdEffectLight"
 pl.Color = ec
 pl.Range = 12
 pl.Brightness = 3
 pl.Parent = hrp
 table.insert(current3rdEffectParts, pl)

 elseif AuraModels[effectName] then
 if lastLoadedAura ~= effectName then
 if currentAuraModel then pcall(function() currentAuraModel:Destroy() end) end
 currentAuraModel = nil
 if loadAuraModel(effectName) then
 lastLoadedAura = effectName
 end
 end
 if currentAuraModel then
 enableAuraModel(char)
 end
 end
end

function remove3rdPersonEffect()
 clear3rdEffectParts()
 current3rdEffectName = nil
 local char = LocalPlayer.Character
 if char then
 for _, child in ipairs(char:GetDescendants()) do
 if child.Name == "nLhe3rdEffect" or child.Name == "nLhe3rdEffect2" or child.Name == "nLhe3rdEffectAtt" or child.Name == "nLhe3rdEffectLight" then
 pcall(function() child:Destroy() end)
 end
 end
 end
end

LocalPlayer.CharacterAdded:Connect(function()
 task.wait(1)
 if Toggles.Enable3rdPersonEffects and Toggles.Enable3rdPersonEffects.Value then
 apply3rdPersonEffect(Options.EffectType and Options.EffectType.Value or "Fire")
 end
end)

-- ==============================================
-- COIN (Левая сторона)
-- ==============================================
local VisualCoin = Tabs.Visual:AddLeftGroupbox("Coin")

VisualCoin:AddButton({
 Text = "Set Coins",
 Tooltip = "тут введи число и нажми энтер",
 Func = function()
 local sg = Instance.new("ScreenGui")
 sg.Name = "CoinInputGui"
 sg.ResetOnSpawn = false
 sg.IgnoreGuiInset = true
 sg.DisplayOrder = 9999
 sg.Parent = (gethui and gethui()) or game:GetService("CoreGui")

 local overlay = Instance.new("Frame")
 overlay.Size = UDim2.new(1, 0, 1, 0)
 overlay.BackgroundColor3 = Color3.new(0, 0, 0)
 overlay.BackgroundTransparency = 0.5
 overlay.BorderSizePixel = 0
 overlay.Parent = sg

 local frame = Instance.new("Frame")
 frame.Size = UDim2.new(0, 340, 0, 180)
 frame.Position = UDim2.new(0.5, -170, 0.5, -90)
 frame.BackgroundColor3 = Color3.fromRGB(25, 25, 35)
 frame.BorderSizePixel = 0
 frame.Parent = sg

 local fc = Instance.new("UICorner")
 fc.CornerRadius = UDim.new(0, 12)
 fc.Parent = frame

 local fs = Instance.new("UIStroke")
 fs.Color = Color3.fromRGB(100, 80, 200)
 fs.Thickness = 2
 fs.Transparency = 0.2
 fs.Parent = frame

 local fg = Instance.new("UIGradient")
 fg.Rotation = 90
 fg.Color = ColorSequence.new(Color3.fromRGB(35, 35, 50), Color3.fromRGB(20, 20, 30))
 fg.Parent = frame

 local titleBar = Instance.new("Frame")
 titleBar.Size = UDim2.new(1, 0, 0, 40)
 titleBar.BackgroundColor3 = Color3.fromRGB(100, 80, 200)
 titleBar.BorderSizePixel = 0
 titleBar.Parent = frame

 local tbc = Instance.new("UICorner")
 tbc.CornerRadius = UDim.new(0, 12)
 tbc.Parent = titleBar

 local tbg = Instance.new("UIGradient")
 tbg.Rotation = 90
 tbg.Color = ColorSequence.new(Color3.fromRGB(120, 100, 220), Color3.fromRGB(80, 60, 180))
 tbg.Parent = titleBar

 local title = Instance.new("TextLabel")
 title.Size = UDim2.new(1, -40, 1, 0)
 title.Position = UDim2.new(0, 15, 0, 0)
 title.BackgroundTransparency = 1
 title.Text = "Установка Монеты"
 title.TextColor3 = Color3.fromRGB(255, 255, 255)
 title.Font = Enum.Font.SourceSansBold
 title.TextSize = 18
 title.TextXAlignment = Enum.TextXAlignment.Left
 title.Parent = titleBar

 local closeBtn = Instance.new("TextButton")
 closeBtn.Size = UDim2.new(0, 30, 0, 30)
 closeBtn.Position = UDim2.new(1, -35, 0, 5)
 closeBtn.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
 closeBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
 closeBtn.Font = Enum.Font.SourceSansBold
 closeBtn.TextSize = 16
 closeBtn.Text = "X"
 closeBtn.BorderSizePixel = 0
 closeBtn.Parent = titleBar

 local cbc = Instance.new("UICorner")
 cbc.CornerRadius = UDim.new(0, 6)
 cbc.Parent = closeBtn

 closeBtn.MouseButton1Click:Connect(function() sg:Destroy() end)

 local hint = Instance.new("TextLabel")
 hint.Size = UDim2.new(1, -30, 0, 20)
 hint.Position = UDim2.new(0, 15, 0, 48)
 hint.BackgroundTransparency = 1
 hint.Text = "Введите количество монет:"
 hint.TextColor3 = Color3.fromRGB(180, 180, 200)
 hint.Font = Enum.Font.SourceSans
 hint.TextSize = 14
 hint.TextXAlignment = Enum.TextXAlignment.Left
 hint.Parent = frame

 local box = Instance.new("TextBox")
 box.Size = UDim2.new(1, -30, 0, 40)
 box.Position = UDim2.new(0, 15, 0, 75)
 box.BackgroundColor3 = Color3.fromRGB(45, 45, 60)
 box.TextColor3 = Color3.fromRGB(255, 255, 255)
 box.Font = Enum.Font.SourceSansBold
 box.TextSize = 20
 box.PlaceholderText = "Например: 999999"
 box.PlaceholderColor3 = Color3.fromRGB(120, 120, 140)
 box.Text = ""
 box.ClearTextOnFocus = false
 box.BorderSizePixel = 0
 box.Parent = frame

 local bxc = Instance.new("UICorner")
 bxc.CornerRadius = UDim.new(0, 8)
 bxc.Parent = box

 local bxs = Instance.new("UIStroke")
 bxs.Color = Color3.fromRGB(100, 80, 200)
 bxs.Thickness = 1.5
 bxs.Transparency = 0.3
 bxs.Parent = box

 box:CaptureFocus()

 local btn = Instance.new("TextButton")
 btn.Size = UDim2.new(1, -30, 0, 38)
 btn.Position = UDim2.new(0, 15, 0, 128)
 btn.BackgroundColor3 = Color3.fromRGB(0, 170, 80)
 btn.TextColor3 = Color3.fromRGB(255, 255, 255)
 btn.Font = Enum.Font.SourceSansBold
 btn.TextSize = 16
 btn.Text = "✓ Применить"
 btn.BorderSizePixel = 0
 btn.Parent = frame

 local bnc = Instance.new("UICorner")
 bnc.CornerRadius = UDim.new(0, 8)
 bnc.Parent = btn

 local bng = Instance.new("UIGradient")
 bng.Rotation = 90
 bng.Color = ColorSequence.new(Color3.fromRGB(0, 200, 100), Color3.fromRGB(0, 140, 60))
 bng.Parent = btn

 local function applyCoins()
 local amt = tonumber(box.Text) or 0
 pcall(function() LocalPlayer.PlayerGui.MenuGui.TopRight.CoinsFrame.CoinsDisplay.Coins.Text = tostring(amt) end)
 Library:Notify("Монеты: " .. tostring(amt), 2)
 sg:Destroy()
 end

 btn.MouseButton1Click:Connect(applyCoins)
 box.FocusLost:Connect(function(ep) if ep then applyCoins() end end)
 overlay.MouseButton1Click:Connect(function() sg:Destroy() end)
 end
})

-- ==============================================
-- ESP (Правая сторона) — ОСНОВНОЙ ESP
-- ==============================================
local VisualESP = Tabs.Visual:AddRightGroupbox("ESP")

espColor = Color3.fromRGB(0, 255, 0)
guiParent = (gethui and gethui()) or game:GetService("CoreGui")
playerGui = LocalPlayer:FindFirstChild("PlayerGui") or LocalPlayer:WaitForChild("PlayerGui", 10)

espObjects = {}

VisualESP:AddToggle("EnableESP", {
 Text = "ESP",
 Default = false,
 Tooltip = "Включить/выключить ESP",
}):AddColorPicker("ESPColor", {
 Default = Color3.fromRGB(0, 255, 0),
 Title = "Цвет ESP",
 Callback = function(Value)
 espColor = Value
 for _, obj in pairs(espObjects) do
 if obj.hl then obj.hl.FillColor = Value; obj.hl.OutlineColor = Value end
 if obj.box then obj.box.Color3 = Value end
 if obj.name then obj.name.TextColor3 = Value end
 if obj.dist then obj.dist.TextColor3 = Value end
 if obj.drawing then obj.drawing.Color = Value end
 end
 end,
})

VisualESP:AddDropdown("ESPMode", {
 Text = "Режим",
 Default = "Контур",
 Values = {"Контур", "Заливка", "Box"},
 Multi = false,
 Tooltip = "Режим отображения ESP",
})

-- ==============================================
-- PCLD ESP (ВНУТРИ ГРУППЫ ESP, ПОД ОСНОВНЫМ ESP)
-- ==============================================
local smoothPCLDs = {}
local pcldPlayerCache = {}
local espColorPCLD = Color3.fromRGB(255, 60, 60)
local smoothTime = 0.18
local consPCLD = {}
local rainbowPCLD = false

local function getPlayerFromPCLD(pcld)
    local closestPlayer
    local closestDist = 10

    for _, player in ipairs(Players:GetPlayers()) do
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
        pcldPlayerCache[pcld] = {
            player = closestPlayer,
            time = tick(),
        }
        return closestPlayer.DisplayName .. " (@ " .. closestPlayer.Name .. ")"
    end

    local cached = pcldPlayerCache[pcld]
    if cached and tick() - cached.time < 2 then
        local p = cached.player
        return p.DisplayName .. " (@ " .. p.Name .. ")"
    end

    return "Unknown"
end

VisualESP:AddLabel("PCLD ESP Color"):AddColorPicker("PCLDColor", {
    Default = espColorPCLD,
    Title = "PCLD ESP Color",
    Callback = function(v)
        espColorPCLD = v
        if not rainbowPCLD then
            for _, d in pairs(smoothPCLDs) do
                if d.box then
                    d.box.Color = v
                end
                if d.outline then
                    d.outline.Color3 = v
                end
            end
        end
    end,
})

VisualESP:AddToggle("RainbowPCLD", {
    Text = "PCLD Rainbow",
    Default = false,
    Tooltip = "Переливание pcld esp всеми цветами радуги",
    Callback = function(v)
        rainbowPCLD = v
        if v then
            task.spawn(function()
                while rainbowPCLD do
                    local hue = tick() % 1
                    local color = Color3.fromHSV(hue, 1, 1)
                    for _, d in pairs(smoothPCLDs) do
                        if d.box then
                            d.box.Color = color
                        end
                        if d.outline then
                            d.outline.Color3 = color
                        end
                    end
                    task.wait(0.05)
                end
            end)
        else
            espColorPCLD = Options.PCLDColor.Value or Color3.fromRGB(255, 60, 60)
            for _, d in pairs(smoothPCLDs) do
                if d.box then
                    d.box.Color = espColorPCLD
                end
                if d.outline then
                    d.outline.Color3 = espColorPCLD
                end
            end
        end
    end
})

local function createSmoothPCLD(original)
    if smoothPCLDs[original] then
        return
    end

    original.Transparency = 1

    local box = Instance.new("Part")
    box.Name = "PCLD_Box"
    box.Size = original.Size
    box.CFrame = original.CFrame
    box.Anchored = true
    box.CanCollide = false
    box.CanTouch = false
    box.CanQuery = false
    box.CastShadow = false
    box.Material = Enum.Material.Neon
    box.Color = espColorPCLD
    box.Transparency = 0.45
    box.Parent = Workspace

    local outline = Instance.new("SelectionBox")
    outline.Adornee = box
    outline.LineThickness = 0.02
    outline.Color3 = espColorPCLD
    outline.Transparency = 0.1
    outline.Parent = box

    local data = {
        box = box,
        outline = outline,
        original = original,
        lastUpdate = tick(),
        tween = nil,
    }

    smoothPCLDs[original] = data

    task.spawn(function()
        local lastPos = original.Position
        while box.Parent and original.Parent do
            local pos = original.Position
            local cf = original.CFrame
            if (pos - lastPos).Magnitude > 0.02 then
                lastPos = pos
                if data.tween then
                    data.tween:Cancel()
                end
                data.tween = TweenService:Create(box, TweenInfo.new(smoothTime, Enum.EasingStyle.Linear), {CFrame = cf})
                data.tween:Play()
            end
            task.wait(0.03)
        end
    end)
end

local function removeSmoothPCLD(original)
    local d = smoothPCLDs[original]
    if not d then
        return
    end
    if d.tween then
        d.tween:Cancel()
    end
    if d.box then
        d.box:Destroy()
    end
    smoothPCLDs[original] = nil
    pcldPlayerCache[original] = nil
end

local function clearAllSmoothPCLDs()
    for _, d in pairs(smoothPCLDs) do
        if d.tween then
            d.tween:Cancel()
        end
        if d.box then
            d.box:Destroy()
        end
    end
    smoothPCLDs = {}
    pcldPlayerCache = {}
end

VisualESP:AddToggle("ViewPCLD", {
    Text = "PCLD ESP",
    Default = false,
    Tooltip = "Показывает pcld esp",
    Callback = function(v)
        if v then
            for _, obj in ipairs(Workspace:GetChildren()) do
                if obj.Name == "PlayerCharacterLocationDetector" then
                    createSmoothPCLD(obj)
                end
            end

            consPCLD.viewpcld = Workspace.ChildAdded:Connect(function(child)
                if child.Name == "PlayerCharacterLocationDetector" then
                    task.wait(0.1)
                    createSmoothPCLD(child)
                end
            end)

            consPCLD.pcldRemoved = Workspace.ChildRemoved:Connect(function(child)
                if child.Name == "PlayerCharacterLocationDetector" then
                    removeSmoothPCLD(child)
                end
            end)
        else
            if consPCLD.viewpcld then
                consPCLD.viewpcld:Disconnect()
            end
            if consPCLD.pcldRemoved then
                consPCLD.pcldRemoved:Disconnect()
            end
            clearAllSmoothPCLDs()
        end
    end,
})

Options.PCLDColor:OnChanged(function()
    if not rainbowPCLD then
        espColorPCLD = Options.PCLDColor.Value
        for _, d in pairs(smoothPCLDs) do
            if d.box then
                d.box.Color = espColorPCLD
            end
            if d.outline then
                d.outline.Color3 = espColorPCLD
            end
        end
    end
end)

-- ==============================================
-- NOTIFY (Отдельная группа под PCLD ESP)
-- ==============================================
local NotifyGroup = Tabs.Visual:AddRightGroupbox("Notify", "bell")

NotifyGroup:AddToggle("KickNotify", {
    Text = "Kick Notify",
    Default = false,
    Tooltip = "Уведомление о появлении объекта кика (блекхол и тд.)",
    Callback = function(Value)
        if Value then
            kickNotifyConnection = Workspace.ChildAdded:Connect(function(obj)
                local kickObjectNames = {
                    ["blackholekick"] = true,
                    ["blackholekicktweens(old)"] = true,
                    ["blackholekicktweens"] = true,
                    ["jhole"] = true,
                    ["blackhole"] = true,
                    ["black_hole"] = true,
                    ["voidhole"] = true,
                    ["singularity"] = true,
                }
                if not obj.Name or not kickObjectNames[obj.Name:lower()] then return end
                task.wait(0.1)
                local pos
                if obj:IsA("BasePart") then 
                    pos = obj.Position 
                else
                    local part = obj:FindFirstChildWhichIsA("BasePart", true)
                    if part then pos = part.Position end
                end
                if not pos then return end
                local closestPlayer = getClosestPlayer(pos)
                if closestPlayer then
                    local displayName = closestPlayer.DisplayName or "Unknown"
                    local realName = closestPlayer.Name or "Unknown"
                    
                    Library:Notify({
                        Title = "KICK DETECTED",
                        Description = "Player: " .. realName .. " (" .. displayName .. ")",
                        Duration = 5,
                    })
                end
            end)
        else
            if kickNotifyConnection then
                kickNotifyConnection:Disconnect()
                kickNotifyConnection = nil
            end
        end
    end
})

packetLagNotifyEnabled = false
lastLagSource = false
packetLagConnection = nil

local function GetSizeMB(StringLength)
    return StringLength / (1024 * 1024)
end

local function StartPacketLagDetector()
    if packetLagConnection then
        packetLagConnection:Disconnect()
        packetLagConnection = nil
    end
    
    packetLagConnection = ReplicatedStorage.GrabEvents.ExtendGrabLine.OnClientEvent:Connect(function(arg1, data)
        if typeof(data) == "string" and not lastLagSource and packetLagNotifyEnabled then
            lastLagSource = true
            local StringLen = string.len(data)
            
            if StringLen > 300 then
                local SizeRounded = math.round(GetSizeMB(StringLen) * 1000) / 1000
                
                Library:Notify({
                    Title = "PACKET LAG DETECTED",
                    Description = "Source: " .. tostring(arg1) .. "\nSize: " .. tostring(SizeRounded) .. " MB",
                    Duration = 5,
                })
            end
            
            task.delay(5, function()
                lastLagSource = false
            end)
        end
    end)
end

NotifyGroup:AddToggle("PacketLagNotify", {
    Text = "Packet Lag Notify",
    Default = false,
    Tooltip = "Уведомление о большом пакете (>300 символов)",
    Callback = function(Value)
        packetLagNotifyEnabled = Value
        if Value then
            StartPacketLagDetector()
        else
            if packetLagConnection then
                packetLagConnection:Disconnect()
                packetLagConnection = nil
            end
        end
    end
})

-- ==============================================
-- ОСТАЛЬНЫЕ ГРУППЫ (ESP элементы, трассеры, граб лайн и т.д.)
-- ==============================================

updateESP = nil

VisualESP:AddDropdown("ESPElements", {
 Text = "Элементы",
 Default = {},
 Values = {"Ник", "Дистанция", "Иконка"},
 Multi = true,
 Tooltip = "ну типа элементы есп",
 Callback = function(Value)
 end,
})

VisualESP:AddButton({
 Text = "Сбросить элементы",
 Tooltip = "Снимает все элементы ESP (Ник, Дистанция, Иконка)",
 Func = function()
 if Options.ESPElements and Options.ESPElements.SetValue then
 pcall(function() Options.ESPElements:SetValue({}) end)
 end
 end,
})

VisualESP:AddSlider("ESPSize", {
 Text = "Размер",
 Default = 12,
 Min = 6,
 Max = 30,
 Rounding = 0,
 Tooltip = "Размер текста и иконок",
})

function createESP(plr)
 if espObjects[plr] then return end
 local hl = Instance.new("Highlight")
 hl.FillColor = espColor
 hl.OutlineColor = espColor
 hl.FillTransparency = 1
 hl.OutlineTransparency = 1
 hl.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
 hl.Enabled = false
 hl.Parent = workspace

 local box = Instance.new("SelectionBox")
 box.Color3 = espColor
 box.Transparency = 0
 box.Adornee = nil
 box.LineThickness = 0.05
 box.Parent = workspace

 local boxPart = Instance.new("Part")
 boxPart.Name = "ESPBox"
 boxPart.Size = Vector3.new(4, 6, 2)
 boxPart.Transparency = 1
 boxPart.CanCollide = false
 boxPart.Anchored = true
 boxPart.Parent = workspace

 local bb = Instance.new("BillboardGui")
 bb.Size = UDim2.new(0, 200, 0, 80)
 bb.StudsOffset = Vector3.new(0, 3, 0)
 bb.AlwaysOnTop = true
 bb.LightInfluence = 0
 bb.MaxDistance = 600
 bb.Enabled = false
 bb.ResetOnSpawn = false
 bb.Parent = guiParent

 local nLabel = Instance.new("TextLabel")
 nLabel.Size = UDim2.new(1, 0, 0, 20)
 nLabel.BackgroundTransparency = 1
 nLabel.Text = ""
 nLabel.TextColor3 = espColor
 nLabel.Font = Enum.Font.SourceSansBold
 nLabel.TextSize = 14
 nLabel.TextStrokeTransparency = 0.5
 nLabel.Parent = bb

 local dLabel = Instance.new("TextLabel")
 dLabel.Size = UDim2.new(1, 0, 0, 16)
 dLabel.Position = UDim2.new(0, 0, 0, 20)
 dLabel.BackgroundTransparency = 1
 dLabel.Text = ""
 dLabel.TextColor3 = espColor
 dLabel.Font = Enum.Font.SourceSans
 dLabel.TextSize = 12
 dLabel.TextStrokeTransparency = 0.5
 dLabel.Parent = bb

 local iLabel = Instance.new("ImageLabel")
 iLabel.Size = UDim2.new(0, 40, 0, 40)
 iLabel.Position = UDim2.new(0.5, -20, 0, 40)
 iLabel.BackgroundTransparency = 1
 iLabel.Image = ""
 iLabel.Parent = bb

 espObjects[plr] = {hl = hl, box = box, boxPart = boxPart, bb = bb, name = nLabel, dist = dLabel, icon = iLabel}
 
 local draw = Drawing.new("Square")
 draw.Thickness = 1.5
 draw.Filled = false
 draw.Color = espColor
 draw.Visible = false
 espObjects[plr].drawing = draw
end

function removeESP(plr)
 local obj = espObjects[plr]
 if not obj then return end
 if obj.hl then obj.hl:Destroy() end
 if obj.box then obj.box:Destroy() end
 if obj.boxPart then obj.boxPart:Destroy() end
 if obj.bb then obj.bb:Destroy() end
 if obj.drawing then obj.drawing:Remove() end
 espObjects[plr] = nil
end

function hasElement(el, name)
 if type(el) ~= "table" then return false end
 if el[name] == true then return true end
 for _, v in pairs(el) do
 if v == name then return true end
 end
 return false
end

updateESP = function(plr)
 local obj = espObjects[plr]
 if not obj then return end

 local function hideElements()
 if obj.bb then
 obj.bb.Adornee = nil
 obj.bb.Enabled = false
 end
 if obj.name then obj.name.Visible = false end
 if obj.dist then obj.dist.Visible = false end
 if obj.icon then obj.icon.Visible = false end
 end

 local function hideVisuals()
 if obj.hl then obj.hl.Enabled = false; obj.hl.Adornee = nil end
 if obj.box then obj.box.Adornee = nil end
 if obj.drawing then obj.drawing.Visible = false end
 end

 if not (Toggles.EnableESP and Toggles.EnableESP.Value) then
 hideVisuals()
 hideElements()
 return
 end
 local char = plr.Character
 if not char then
 hideVisuals()
 hideElements()
 return
 end
 local root = char:FindFirstChild("HumanoidRootPart")
 local hum = char:FindFirstChild("Humanoid")
 local head = char:FindFirstChild("Head")
 if not root or not hum or hum.Health <= 0 then
 hideVisuals()
 hideElements()
 return
 end

 obj.hl.FillColor = espColor
 obj.hl.OutlineColor = espColor
 obj.name.TextColor3 = espColor
 obj.dist.TextColor3 = espColor
 obj.box.Color3 = espColor

 local mode = Options.ESPMode and Options.ESPMode.Value or "Контур"
 if mode == "Контур" then
 obj.hl.FillTransparency = 1
 obj.hl.OutlineTransparency = 0
 obj.hl.Adornee = char
 obj.hl.Enabled = true
 obj.box.Adornee = nil
 elseif mode == "Заливка" then
 obj.hl.FillTransparency = 0.5
 obj.hl.OutlineTransparency = 0.2
 obj.hl.Adornee = char
 obj.hl.Enabled = true
 obj.box.Adornee = nil
 elseif mode == "Box" then
 obj.hl.Enabled = false; obj.hl.Adornee = nil
 obj.box.Adornee = nil
 end
 if mode ~= "Box" and obj.drawing then
 obj.drawing.Visible = false
 end

 local elements = Options.ESPElements and Options.ESPElements.Value or {}
 local showN = hasElement(elements, "Ник")
 local showD = hasElement(elements, "Дистанция")
 local showI = hasElement(elements, "Иконка")
 local anyElement = showN or showD or showI

 if not anyElement then
 hideElements()
 return
 end

 obj.bb.Adornee = head or root
 obj.bb.Enabled = true

 local ts = Options.ESPSize and Options.ESPSize.Value or 12
 obj.name.TextSize = ts
 obj.dist.TextSize = math.max(ts - 2, 6)
 obj.icon.Size = UDim2.new(0, ts * 3, 0, ts * 3)
 obj.icon.Position = UDim2.new(0.5, -ts * 1.5, 0, ts + 20)

 obj.name.Visible = showN
 obj.name.Text = showN and plr.DisplayName or ""

 if showD then
 local cam = workspace.CurrentCamera
 if cam and root then
 obj.dist.Text = string.format("%.0f studs", (root.Position - cam.CFrame.Position).Magnitude)
 obj.dist.Visible = true
 end
 else
 obj.dist.Visible = false
 end

 obj.icon.Visible = showI
 if showI and obj.icon.Image == "" then
 obj.icon.Image = string.format("rbxthumb://type=AvatarHeadShot&id=%d&w=150&h=150", plr.UserId)
 end
end

task.spawn(function()
 while task.wait(0.1) do
 if Toggles.EnableESP and Toggles.EnableESP.Value then
 for _, plr in ipairs(Players:GetPlayers()) do
 if plr ~= LocalPlayer then
 local obj = espObjects[plr]
 if obj and (not obj.bb.Parent or not obj.hl.Parent) then
 removeESP(plr)
 obj = nil
 end
 if not obj then createESP(plr) end
 updateESP(plr)
 end
 end
 end
 end
end)

Players.PlayerRemoving:Connect(removeESP)

Toggles.EnableESP:OnChanged(function()
 if not Toggles.EnableESP.Value then
 for _, obj in pairs(espObjects) do
 obj.hl.Enabled = false
 obj.box.Adornee = nil
 obj.bb.Enabled = false
 if obj.drawing then obj.drawing.Visible = false end
 end
 end
end)

RunService.RenderStepped:Connect(function()
 if not (Toggles.EnableESP and Toggles.EnableESP.Value) then return end
 if not (Options.ESPMode and Options.ESPMode.Value == "Box") then return end
 local cam = workspace.CurrentCamera
 if not cam then return end
 for plr, obj in pairs(espObjects) do
 if plr ~= LocalPlayer and obj.drawing then
 local char = plr.Character
 if not char then obj.drawing.Visible = false; continue end
 local root = char:FindFirstChild("HumanoidRootPart")
 local hum = char:FindFirstChild("Humanoid")
 local head = char:FindFirstChild("Head")
 if not root or not hum or hum.Health <= 0 then
 obj.drawing.Visible = false
 continue
 end
 local topWorld = (head and head.Position or root.Position) + Vector3.new(0, 0.5, 0)
 local botWorld = root.Position - Vector3.new(0, 3, 0)
 local screenTop, onTop = cam:WorldToViewportPoint(topWorld)
 local screenBot, onBot = cam:WorldToViewportPoint(botWorld)
 if onTop and onBot then
 local height = math.abs(screenTop.Y - screenBot.Y)
 local width = height * 0.5
 width = math.max(width, 15)
 height = math.max(height, 25)
 local centerX = (screenTop.X + screenBot.X) / 2
 obj.drawing.Size = Vector2.new(width, height)
 obj.drawing.Position = Vector2.new(centerX - width / 2, screenTop.Y)
 obj.drawing.Color = espColor
 obj.drawing.Thickness = 1.5
 obj.drawing.Visible = true
 else
 obj.drawing.Visible = false
 end
 end
 end
end)

-- ==============================================
-- TRACER LINES (Правая сторона)
-- ==============================================
local VisualTracers = Tabs.Visual:AddRightGroupbox("Tracer Lines")

tracerColor = Color3.fromRGB(255, 0, 0)
tracerObjects = {}

VisualTracers:AddToggle("EnableTracers", {
 Text = "Tracer Lines",
 Default = false,
 Tooltip = "Линии от экрана к игрокам",
}):AddColorPicker("TracerColor", {
 Default = Color3.fromRGB(255, 0, 0),
 Title = "Цвет линий",
 Callback = function(Value)
 tracerColor = Value
 for _, obj in pairs(tracerObjects) do
 if obj.line then obj.line.Color = tracerColor end
 end
 end,
})

VisualTracers:AddSlider("TracerWidth", {
 Text = "Толщина линии",
 Default = 1,
 Min = 1,
 Max = 5,
 Rounding = 0,
 Tooltip = "Ширина трассера",
})

VisualTracers:AddDropdown("TracerOrigin", {
 Text = "Откуда вести",
 Default = "Центр экрана",
 Values = {"Сверху по центру", "Центр экрана", "Снизу по центру"},
 Multi = false,
 Tooltip = "Точка откуда ведутся линии",
})

VisualTracers:AddToggle("TracerThroughWalls", {
 Text = "Показывать за спиной",
 Default = false,
 Tooltip = "Показывать линии к игрокам даже если они за камерой",
})

function getTracerOrigin()
 local cam = workspace.CurrentCamera
 if not cam then return Vector2.new(0, 0) end
 local vp = cam.ViewportSize
 local origin = Options.TracerOrigin and Options.TracerOrigin.Value or "Центр экрана"
 if origin == "Сверху по центру" then
 return Vector2.new(vp.X / 2, 0)
 elseif origin == "Снизу по центру" then
 return Vector2.new(vp.X / 2, vp.Y)
 else
 return Vector2.new(vp.X / 2, vp.Y / 2)
 end
end

function createTracer(plr)
 if tracerObjects[plr] then return end
 local line = Drawing.new("Line")
 line.Thickness = 1
 line.Color = tracerColor
 line.Visible = false
 tracerObjects[plr] = {line = line}
end

function removeTracer(plr)
 local obj = tracerObjects[plr]
 if not obj then return end
 if obj.line then obj.line:Remove() end
 tracerObjects[plr] = nil
end

function updateTracer(plr)
 local obj = tracerObjects[plr]
 if not obj then return end
 if not (Toggles.EnableTracers and Toggles.EnableTracers.Value) then
 obj.line.Visible = false
 return
 end
 local char = plr.Character
 if not char then obj.line.Visible = false; return end
 local root = char:FindFirstChild("HumanoidRootPart")
 local hum = char:FindFirstChild("Humanoid")
 if not root or not hum or hum.Health <= 0 then
 obj.line.Visible = false
 return
 end
 local cam = workspace.CurrentCamera
 if not cam then obj.line.Visible = false; return end
 local origin = getTracerOrigin()
 local throughWalls = Toggles.TracerThroughWalls and Toggles.TracerThroughWalls.Value or false
 local screenPos, onScreen = cam:WorldToViewportPoint(root.Position)
 if onScreen then
 obj.line.From = origin
 obj.line.To = Vector2.new(screenPos.X, screenPos.Y)
 elseif throughWalls then
 local camCF = cam.CFrame
 local toPlayer = root.Position - camCF.Position
 local dx = toPlayer:Dot(camCF.RightVector)
 local dy = toPlayer:Dot(camCF.UpVector)
 local angle = math.atan2(-dy, dx)
 local lineLen = 200
 obj.line.From = origin
 obj.line.To = origin + Vector2.new(math.cos(angle), math.sin(angle)) * lineLen
 else
 obj.line.Visible = false
 return
 end
 obj.line.Color = tracerColor
 obj.line.Thickness = Options.TracerWidth and Options.TracerWidth.Value or 1
 obj.line.Visible = true
end

RunService.RenderStepped:Connect(function()
 if not (Toggles.EnableTracers and Toggles.EnableTracers.Value) then return end
 if Window and Window.Visible == true then return end
 for _, plr in ipairs(Players:GetPlayers()) do
 if plr ~= LocalPlayer then
 local obj = tracerObjects[plr]
 if not obj then createTracer(plr); obj = tracerObjects[plr] end
 if obj then updateTracer(plr) end
 end
 end
end)

Players.PlayerRemoving:Connect(removeTracer)

Toggles.EnableTracers:OnChanged(function()
 if not Toggles.EnableTracers.Value then
 for _, obj in pairs(tracerObjects) do
 if obj.line then obj.line.Visible = false end
 end
 end
end)

-- ==============================================
-- GRAB LINE (Правая сторона)
-- ==============================================
local VisualGrabLine = Tabs.Visual:AddRightGroupbox("Grab Line")

grabLineOriginals = setmetatable({}, { __mode = "k" })
grabBeams = {}

function isGrabBeam(obj)
 return obj:IsA("Beam") and obj.Name == "GrabBeam"
end

function saveGrabBeamOriginal(beam)
 if grabLineOriginals[beam] then return end
 grabLineOriginals[beam] = {
 Width0 = beam.Width0, Width1 = beam.Width1,
 Texture = beam.Texture, TextureLength = beam.TextureLength,
 TextureSpeed = beam.TextureSpeed, TextureMode = beam.TextureMode,
 LightEmission = beam.LightEmission,
 Color = beam.Color,
 Transparency = beam.Transparency,
 }
end

function restoreGrabBeam(beam)
 local o = grabLineOriginals[beam]
 if not o then return end
 pcall(function()
 beam.Width0 = o.Width0; beam.Width1 = o.Width1
 beam.Texture = o.Texture; beam.TextureLength = o.TextureLength
 beam.TextureSpeed = o.TextureSpeed; beam.TextureMode = o.TextureMode
 beam.LightEmission = o.LightEmission
 beam.Color = o.Color
 beam.Transparency = o.Transparency
 end)
end

grabTextures = {
 ["Молния"] = { id = "rbxasset://textures/particles/sparkles_main.dds", length = 0.7, speed = 5 },
 ["Взрыв"] = { id = "rbxasset://textures/particles/explosion01_implosion_main.dds", length = 2.5, speed = 1.5 },
 ["Вспышка"] = { id = "rbxasset://textures/particles/explosion01_seeds.dds", length = 1.4, speed = 2.5 },
 ["Плазма"] = { id = "rbxasset://textures/particles/explosion01_layer2.dds", length = 3, speed = 1.5, width = 1.0 },
 ["Дым"] = { id = "rbxasset://textures/particles/smoke_main.dds", length = 2, speed = 1, width = 1.4 },
 ["Пламя"] = { id = "rbxasset://textures/particles/fire_main.dds", length = 1.6, speed = 3, width = 1.2 },
 ["Искры"] = { id = "rbxasset://textures/particles/sparkles_main.dds", length = 1.2, speed = 2, width = 0.9 },
 ["Non-Gamepass"] = { id = "rbxassetid://8933346550", length = 1, speed = 1, width = 1.0 },
 ["Gamepass"] = { id = "rbxassetid://8933355899", length = 1, speed = 1, width = 1.0 },
 ["Chain"] = { id = "rbxassetid://81358145120405", length = 1, speed = 1, width = 1.0 },
 ["Chain 2"] = { id = "rbxassetid://132910145874066", length = 1, speed = 1, width = 1.0 },
 ["Chain 3"] = { id = "rbxassetid://128466395060514", length = 1, speed = 1, width = 1.0 },
 ["Chain 4"] = { id = "rbxassetid://73368670987191", length = 1, speed = 1, width = 1.0 },
 ["Rope"] = { id = "rbxassetid://78999022056924", length = 1, speed = 1, width = 1.0 },
 ["Spring"] = { id = "rbxassetid://18837732116", length = 1, speed = 1, width = 1.0 },
 ["Circle"] = { id = "rbxassetid://5367817750", length = 1, speed = 1, width = 1.0 },
 ["Circle-Outline"] = { id = "rbxassetid://12201347372", length = 1, speed = 1, width = 1.0 },
 ["Triangle"] = { id = "rbxassetid://4704920160", length = 1, speed = 1, width = 1.0 },
 ["Triangle-Outline"] = { id = "rbxassetid://94666748694025", length = 1, speed = 1, width = 1.0 },
 ["Square"] = { id = "rbxassetid://15007588972", length = 1, speed = 1, width = 1.0 },
 ["Square-Outline"] = { id = "rbxassetid://15420927706", length = 1, speed = 1, width = 1.0 },
 ["Heart"] = { id = "rbxassetid://89015294175898", length = 1, speed = 1, width = 1.0 },
 ["Heart-Outline"] = { id = "rbxassetid://125373934805238", length = 1, speed = 1, width = 1.0 },
 ["Moon"] = { id = "rbxassetid://9013498676", length = 1, speed = 1, width = 1.0 },
 ["Dots"] = { id = "rbxassetid://9169659357", length = 1, speed = 1, width = 1.0 },
 ["Bubble"] = { id = "rbxassetid://1249690853", length = 1, speed = 1, width = 1.0 },
 ["Star"] = { id = "rbxassetid://5639840603", length = 1, speed = 1, width = 1.0 },
 ["Robux"] = { id = "rbxassetid://11560341132", length = 1, speed = 1, width = 1.0 },
 ["Roblox-Logo"] = { id = "rbxassetid://12348119032", length = 1, speed = 1, width = 1.0 },
 ["Brick"] = { id = "rbxassetid://4430903072", length = 1, speed = 1, width = 1.0 },
 ["Studs"] = { id = "rbxassetid://15539356451", length = 1, speed = 1, width = 1.0 },
 ["Fire"] = { id = "rbxassetid://18654087326", length = 1, speed = 1, width = 1.0 },
 ["Lazar"] = { id = "rbxassetid://8922958725", length = 1, speed = 1, width = 1.0 },
 ["Spider-Web"] = { id = "rbxassetid://123815660139244", length = 1, speed = 1, width = 1.0 },
 ["Smoke"] = { id = "rbxassetid://12900071392", length = 1, speed = 1, width = 1.0 },
 ["Audio-Visualiser"] = { id = "rbxassetid://81588563590679", length = 1, speed = 1, width = 1.0 },
 ["Pulse"] = { id = "rbxassetid://82163767314193", length = 1, speed = 1, width = 1.0 },
 ["Arrow"] = { id = "rbxassetid://9006027964", length = 1, speed = 1, width = 1.0 },
 ["Arrow 2"] = { id = "rbxassetid://10249261576", length = 1, speed = 1, width = 1.0 },
}

grabDashSeq = NumberSequence.new({
 NumberSequenceKeypoint.new(0, 0),
 NumberSequenceKeypoint.new(0.12, 0),
 NumberSequenceKeypoint.new(0.13, 1),
 NumberSequenceKeypoint.new(0.24, 1),
 NumberSequenceKeypoint.new(0.25, 0),
 NumberSequenceKeypoint.new(0.37, 0),
 NumberSequenceKeypoint.new(0.38, 1),
 NumberSequenceKeypoint.new(0.49, 1),
 NumberSequenceKeypoint.new(0.5, 0),
 NumberSequenceKeypoint.new(0.62, 0),
 NumberSequenceKeypoint.new(0.63, 1),
 NumberSequenceKeypoint.new(0.74, 1),
 NumberSequenceKeypoint.new(0.75, 0),
 NumberSequenceKeypoint.new(0.87, 0),
 NumberSequenceKeypoint.new(0.88, 1),
 NumberSequenceKeypoint.new(1, 1),
})
grabDotSeq = NumberSequence.new({
 NumberSequenceKeypoint.new(0, 0),
 NumberSequenceKeypoint.new(0.05, 0),
 NumberSequenceKeypoint.new(0.06, 1),
 NumberSequenceKeypoint.new(0.24, 1),
 NumberSequenceKeypoint.new(0.25, 0),
 NumberSequenceKeypoint.new(0.3, 0),
 NumberSequenceKeypoint.new(0.31, 1),
 NumberSequenceKeypoint.new(0.49, 1),
 NumberSequenceKeypoint.new(0.5, 0),
 NumberSequenceKeypoint.new(0.55, 0),
 NumberSequenceKeypoint.new(0.56, 1),
 NumberSequenceKeypoint.new(0.74, 1),
 NumberSequenceKeypoint.new(0.75, 0),
 NumberSequenceKeypoint.new(0.8, 0),
 NumberSequenceKeypoint.new(0.81, 1),
 NumberSequenceKeypoint.new(0.99, 1),
 NumberSequenceKeypoint.new(1, 0),
})
grabCometSeq = NumberSequence.new({
 NumberSequenceKeypoint.new(0, 1),
 NumberSequenceKeypoint.new(0.6, 0.55),
 NumberSequenceKeypoint.new(1, 0),
})
grabSolidSeq = NumberSequence.new(0)

function applyGrabBeamStyle(beam)
 local style = (Options.GrabLineStyle and Options.GrabLineStyle.Value) or "Обычная"
 local o = grabLineOriginals[beam]
 local t = tick()
 local tex = grabTextures[style]
 local baseW = (Options.GrabLineWidth and Options.GrabLineWidth.Value) or 1

 if style == "Обычная" then
  if o then
   beam.Texture = o.Texture
   beam.TextureLength = o.TextureLength
   beam.TextureSpeed = o.TextureSpeed
   beam.TextureMode = o.TextureMode
   beam.Width0 = o.Width0; beam.Width1 = o.Width1
   beam.LightEmission = o.LightEmission
   beam.Transparency = o.Transparency
   beam.Color = o.Color
  end
  return
 end

 if style == "Low Quality" then
  beam.Texture = ""
  if o then
   beam.TextureLength = o.TextureLength
   beam.TextureSpeed = o.TextureSpeed
   beam.TextureMode = o.TextureMode
  end
  beam.Width0 = baseW; beam.Width1 = baseW
  beam.LightEmission = (Options.GrabLineLightEm and Options.GrabLineLightEm.Value) or 1
  beam.Transparency = grabSolidSeq
 elseif style == "Custom" then
  local customId = (Options.GrabCustomTexId and Options.GrabCustomTexId.Value) or ""
  local cleanId = tostring(customId):gsub("%D", "")
  if cleanId ~= "" then
   beam.Texture = "rbxassetid://" .. cleanId
   beam.TextureMode = Enum.TextureMode.Wrap
   beam.TextureLength = (Options.GrabLineLengthEnabled and Options.GrabLineLengthEnabled.Value and Options.GrabLineLength and Options.GrabLineLength.Value) or 1
   beam.TextureSpeed = (Options.GrabLineSpeedEnabled and Options.GrabLineSpeedEnabled.Value and Options.GrabLineSpeed and Options.GrabLineSpeed.Value) or 1
  elseif o then
   beam.Texture = o.Texture
   beam.TextureLength = o.TextureLength
   beam.TextureSpeed = o.TextureSpeed
   beam.TextureMode = o.TextureMode
  end
  beam.Width0 = baseW; beam.Width1 = baseW
  beam.LightEmission = (Options.GrabLineLightEm and Options.GrabLineLightEm.Value) or 1
  beam.Transparency = grabSolidSeq
 elseif tex then
  local texId = tex.id
  beam.Texture = texId
  beam.TextureMode = Enum.TextureMode.Wrap
  if Options.GrabLineLengthEnabled and Options.GrabLineLengthEnabled.Value and Options.GrabLineLength then
   beam.TextureLength = Options.GrabLineLength.Value
  else
   beam.TextureLength = tex.length
  end
  if Options.GrabLineSpeedEnabled and Options.GrabLineSpeedEnabled.Value and Options.GrabLineSpeed then
   beam.TextureSpeed = Options.GrabLineSpeed.Value
  else
   beam.TextureSpeed = tex.speed
  end
  beam.Width0 = baseW; beam.Width1 = baseW
  beam.LightEmission = (Options.GrabLineLightEm and Options.GrabLineLightEm.Value) or 1
  beam.Transparency = grabSolidSeq
 else
  beam.Width0 = baseW; beam.Width1 = baseW
  beam.LightEmission = (Options.GrabLineLightEm and Options.GrabLineLightEm.Value) or 1
  beam.Transparency = grabSolidSeq
 end

 if Toggles.GrabLineRainbow and Toggles.GrabLineRainbow.Value then
  local h = (tick() * 0.5) % 1
  local c = Color3.fromHSV(h, 1, 1)
  beam.Color = ColorSequence.new(c, c)
 elseif Toggles.GrabLineColorEnabled and Toggles.GrabLineColorEnabled.Value then
  local c0 = (Options.GrabLineColor0 and Options.GrabLineColor0.Value) or Color3.fromRGB(255, 255, 255)
  local c1 = (Options.GrabLineColor1 and Options.GrabLineColor1.Value) or c0
  beam.Color = ColorSequence.new(c0, c1)
 elseif o then
  beam.Color = o.Color
 end

 if Toggles.GrabLinePulse and Toggles.GrabLinePulse.Value then
  local pulseSpeed = (Options.GrabLinePulseSpeed and Options.GrabLinePulseSpeed.Value) or 2
  local w = baseW * (0.55 + 0.45 * (0.5 + 0.5 * math.sin(t * pulseSpeed * 2)))
  beam.Width0 = w; beam.Width1 = w
 end
end

VisualGrabLine:AddToggle("EnableGrabLine", {
 Text = "Custom Grab Line",
 Default = false,
 Tooltip = "Меняет форму и вид линии захвата (Grab), которой ты хватаешь",
})

VisualGrabLine:AddDropdown("GrabLineStyle", {
 Text = "Форма линии",
 Default = "Обычная",
 Values = {
  "Обычная",
  "Дым", "Пламя", "Искры", "Молния", "Плазма", "Взрыв", "Вспышка",
  "Non-Gamepass", "Gamepass",
  "Chain", "Chain 2", "Chain 3", "Chain 4",
  "Rope", "Spring",
  "Circle", "Circle-Outline",
  "Triangle", "Triangle-Outline",
  "Square", "Square-Outline",
  "Heart", "Heart-Outline",
  "Moon", "Dots", "Bubble", "Star",
  "Robux", "Roblox-Logo",
  "Brick", "Studs",
  "Fire", "Lazar",
  "Spider-Web", "Smoke",
  "Audio-Visualiser", "Pulse",
  "Arrow", "Arrow 2",
 },
 Multi = false,
 Tooltip = "Вид линии граба",
})

VisualGrabLine:AddSlider("GrabLineWidth", {
 Text = "Ширина линии",
 Default = 1,
 Min = 0.05,
 Max = 3,
 Rounding = 2,
 Compact = false,
 Tooltip = "Толщина линии захвата (для всего кроме «Обычная»)",
})

VisualGrabLine:AddInput("GrabCustomTexId", {
 Text = "Custom Texture ID",
 Default = "",
 Placeholder = "rbxassetid://1234567890",
 Tooltip = "ну типа нельзя, да, но можешь попробывать",
})

VisualGrabLine:AddLabel("Цвет линии — Start"):AddColorPicker("GrabLineColor0", {
 Default = Color3.fromRGB(255, 255, 255),
 Title = "Цвет начала линии",
})

VisualGrabLine:AddLabel("Цвет линии — End"):AddColorPicker("GrabLineColor1", {
 Default = Color3.fromRGB(255, 255, 255),
 Title = "Цвет конца линии",
})

VisualGrabLine:AddToggle("GrabLineColorEnabled", {
 Text = "Включить цвет линии",
 Default = false,
 Tooltip = "Применять выбранные цвета к линии (иначе — цвет игры)",
})

VisualGrabLine:AddToggle("GrabLineRainbow", {
 Text = "Rainbow (перелив)",
 Default = false,
 Tooltip = "Линия автоматически переливается всеми цветами радуги",
})

VisualGrabLine:AddToggle("GrabLineSpeedEnabled", {
 Text = "Своя скорость текстуры",
 Default = false,
 Tooltip = "Включить ползунок скорости прокрутки текстуры",
})

VisualGrabLine:AddSlider("GrabLineSpeed", {
 Text = "Скорость текстуры",
 Default = 1,
 Min = -10,
 Max = 10,
 Rounding = 1,
 Compact = false,
 Tooltip = "Скорость прокрутки текстуры вдоль линии (отрицательная = реверс)",
})

VisualGrabLine:AddToggle("GrabLineLengthEnabled", {
 Text = "Своя длина текстуры",
 Default = false,
 Tooltip = "Включить ползунок длины текстуры",
})

VisualGrabLine:AddSlider("GrabLineLength", {
 Text = "Длина текстуры",
 Default = 1,
 Min = 0.1,
 Max = 10,
 Rounding = 2,
 Compact = false,
 Tooltip = "Длина (размер) текстуры вдоль линии",
})

VisualGrabLine:AddSlider("GrabLineLightEm", {
 Text = "Свечение (LightEmission)",
 Default = 1,
 Min = 0,
 Max = 1,
 Rounding = 2,
 Compact = false,
 Tooltip = "Сила свечения текстуры (0 = нет, 1 = максимум)",
})

VisualGrabLine:AddToggle("GrabLinePulse", {
 Text = "Пульсация ширины",
 Default = false,
 Tooltip = "Ширина линии пульсирует (как дыхание)",
})

VisualGrabLine:AddSlider("GrabLinePulseSpeed", {
 Text = "Скорость пульсации",
 Default = 2,
 Min = 0.1,
 Max = 10,
 Rounding = 1,
 Compact = false,
 Tooltip = "Как быстро пульсирует ширина",
})

task.spawn(function()
 for _, obj in ipairs(workspace:GetDescendants()) do
 if isGrabBeam(obj) then grabBeams[obj] = true end
 end
end)
workspace.DescendantAdded:Connect(function(obj)
 if isGrabBeam(obj) then grabBeams[obj] = true end
end)
workspace.DescendantRemoving:Connect(function(obj)
 if grabBeams[obj] then
 grabBeams[obj] = nil
 grabLineOriginals[obj] = nil
 end
end)

Toggles.EnableGrabLine:OnChanged(function()
 if not Toggles.EnableGrabLine.Value then
 for beam in pairs(grabBeams) do
 if beam and beam.Parent then restoreGrabBeam(beam) end
 end
 end
end)

RunService.RenderStepped:Connect(function()
 if not (Toggles.EnableGrabLine and Toggles.EnableGrabLine.Value) then return end
 for beam in pairs(grabBeams) do
 if beam.Parent then
 saveGrabBeamOriginal(beam)
 pcall(applyGrabBeamStyle, beam)
 else
 grabBeams[beam] = nil
 end
 end
end)

-- ==============================================
-- TARGET ESP (Правая сторона)
-- ==============================================
local VisualHoverHL = Tabs.Visual:AddRightGroupbox("Target ESP")

VisualHoverHL:AddDropdown("TargetESPMode", {
 Text = "Target ESP Mode",
 Default = "None",
 Values = {"None", "Style 1 (Highlight)", "Style 2 (Box)", "Style 3 (Brackets)", "Style 4 (Particles)"},
 Tooltip = "Выделять игрока при наведении",
})

VisualHoverHL:AddLabel("Цвет Target ESP"):AddColorPicker("TargetESPColor", {
 Default = Color3.fromRGB(200, 0, 255),
 Title = "Цвет Target ESP",
})

VisualHoverHL:AddDropdown("HoverHighlightDist", {
 Text = "Дистанция",
 Default = "30 studs",
 Values = {"20 studs", "30 studs"},
 Multi = false,
 Tooltip = "Максимальная дистанция для выделения",
})

local targetEspHl = nil
local targetEspBox = nil
local targetEspBrackets = nil
local targetEspParticles = nil

local function removeTargetESP()
 if targetEspHl then pcall(function() targetEspHl:Destroy() end) targetEspHl = nil end
 if targetEspBox then pcall(function() targetEspBox:Destroy() end) targetEspBox = nil end
 if targetEspBrackets then pcall(function() targetEspBrackets:Destroy() end) targetEspBrackets = nil end
 if targetEspParticles then pcall(function() targetEspParticles:Destroy() end) targetEspParticles = nil end
end

local function createBrackets(parent, color)
 local bgui = Instance.new("BillboardGui")
 bgui.Name = "nLheTargetBrackets"
 bgui.Adornee = parent
 bgui.Size = UDim2.new(4, 0, 5.5, 0)
 bgui.AlwaysOnTop = true
 bgui.LightInfluence = 0

 local thickness = 10
 local length = 0.25

 local function makeLine(size, pos, anchor)
  local f = Instance.new("Frame")
  f.BorderSizePixel = 0
  f.BackgroundColor3 = color
  f.Size = size
  f.Position = pos
  f.AnchorPoint = anchor
  f.Parent = bgui
  local uiCorner = Instance.new("UICorner")
  uiCorner.CornerRadius = UDim.new(1, 0)
  uiCorner.Parent = f
  return f
 end

 makeLine(UDim2.new(length, 0, 0, thickness), UDim2.new(0, 0, 0, 0), Vector2.new(0, 0))
 makeLine(UDim2.new(0, thickness, length, 0), UDim2.new(0, 0, 0, 0), Vector2.new(0, 0))
 makeLine(UDim2.new(length, 0, 0, thickness), UDim2.new(1, 0, 0, 0), Vector2.new(1, 0))
 makeLine(UDim2.new(0, thickness, length, 0), UDim2.new(1, 0, 0, 0), Vector2.new(1, 0))
 makeLine(UDim2.new(length, 0, 0, thickness), UDim2.new(0, 0, 1, 0), Vector2.new(0, 1))
 makeLine(UDim2.new(0, thickness, length, 0), UDim2.new(0, 0, 1, 0), Vector2.new(0, 1))
 makeLine(UDim2.new(length, 0, 0, thickness), UDim2.new(1, 0, 1, 0), Vector2.new(1, 1))
 makeLine(UDim2.new(0, thickness, length, 0), UDim2.new(1, 0, 1, 0), Vector2.new(1, 1))

 bgui.Parent = parent
 return bgui
end

local function createParticles(parent, color)
 local att = Instance.new("Attachment")
 att.Name = "nLheTargetParticlesAtt"
 att.Position = Vector3.new(0, -1.5, 0)
 
 local pe = Instance.new("ParticleEmitter")
 pe.Name = "nLheTargetParticles"
 pe.Texture = "rbxassetid://284205403"
 pe.Color = ColorSequence.new(color)
 pe.Size = NumberSequence.new({NumberSequenceKeypoint.new(0, 0), NumberSequenceKeypoint.new(0.5, 2), NumberSequenceKeypoint.new(1, 0)})
 pe.Rate = 40
 pe.Lifetime = NumberRange.new(1, 2)
 pe.Speed = NumberRange.new(3, 7)
 pe.VelocitySpread = 60
 pe.EmissionDirection = Enum.NormalId.Top
 pe.Parent = att
 
 att.Parent = parent
 return att
end

RunService.RenderStepped:Connect(function()
 local mode = Options.TargetESPMode and Options.TargetESPMode.Value or "None"
 if mode == "None" then
  removeTargetESP()
  return
 end

 local mouse = LocalPlayer:GetMouse()
 local hitPart = mouse.Target
 if not hitPart then
  removeTargetESP()
  return
 end
 
 local distStr = Options.HoverHighlightDist and Options.HoverHighlightDist.Value or "30 studs"
 local maxDist = tonumber(distStr:match("(%d+)")) or 30
 local targetChar = hitPart:FindFirstAncestorOfClass("Model")
 if not targetChar then
  removeTargetESP()
  return
 end
 local plr = Players:GetPlayerFromCharacter(targetChar)
 if not plr or plr == LocalPlayer then
  removeTargetESP()
  return
 end
 local myChar = LocalPlayer.Character
 local myRoot = myChar and myChar:FindFirstChild("HumanoidRootPart")
 local theirRoot = targetChar:FindFirstChild("HumanoidRootPart")
 if not myRoot or not theirRoot then
  removeTargetESP()
  return
 end
 local dist = (myRoot.Position - theirRoot.Position).Magnitude
 if dist > maxDist then
  removeTargetESP()
  return
 end

 local root = targetChar:FindFirstChild("HumanoidRootPart")
 if not root then removeTargetESP() return end
 
 local espColor = Options.TargetESPColor and Options.TargetESPColor.Value or Color3.fromRGB(200, 0, 255)

 if mode == "Style 1 (Highlight)" then
  if targetEspBox then pcall(function() targetEspBox:Destroy() end) targetEspBox = nil end
  if targetEspBrackets then pcall(function() targetEspBrackets:Destroy() end) targetEspBrackets = nil end
  if targetEspParticles then pcall(function() targetEspParticles:Destroy() end) targetEspParticles = nil end
  
  if not targetEspHl or targetEspHl.Parent ~= targetChar then
   if targetEspHl then pcall(function() targetEspHl:Destroy() end) end
   targetEspHl = Instance.new("Highlight")
 targetEspHl.Name = "nLheTargetESP"
   targetEspHl.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
   targetEspHl.FillTransparency = 0.5
   targetEspHl.OutlineTransparency = 0
   targetEspHl.Parent = targetChar
  end
  targetEspHl.FillColor = espColor
  targetEspHl.OutlineColor = espColor

 elseif mode == "Style 2 (Box)" then
  if targetEspHl then pcall(function() targetEspHl:Destroy() end) targetEspHl = nil end
  if targetEspBrackets then pcall(function() targetEspBrackets:Destroy() end) targetEspBrackets = nil end
  if targetEspParticles then pcall(function() targetEspParticles:Destroy() end) targetEspParticles = nil end
  
  if not targetEspBox or targetEspBox.Parent ~= root then
   if targetEspBox then pcall(function() targetEspBox:Destroy() end) end
   targetEspBox = Instance.new("SelectionBox")
 targetEspBox.Name = "nLheTargetESPBox"
   targetEspBox.LineThickness = 0.05
   targetEspBox.SurfaceTransparency = 0.8
   targetEspBox.Adornee = root
   targetEspBox.Parent = root
  end
  targetEspBox.Color3 = espColor
  targetEspBox.SurfaceColor3 = espColor

 elseif mode == "Style 3 (Brackets)" then
  if targetEspHl then pcall(function() targetEspHl:Destroy() end) targetEspHl = nil end
  if targetEspBox then pcall(function() targetEspBox:Destroy() end) targetEspBox = nil end
  if targetEspParticles then pcall(function() targetEspParticles:Destroy() end) targetEspParticles = nil end

  if not targetEspBrackets or targetEspBrackets.Parent ~= root then
   if targetEspBrackets then pcall(function() targetEspBrackets:Destroy() end) end
   targetEspBrackets = createBrackets(root, espColor)
  else
   for _, child in ipairs(targetEspBrackets:GetChildren()) do
    if child:IsA("Frame") then child.BackgroundColor3 = espColor end
   end
  end

 elseif mode == "Style 4 (Particles)" then
  if targetEspHl then pcall(function() targetEspHl:Destroy() end) targetEspHl = nil end
  if targetEspBox then pcall(function() targetEspBox:Destroy() end) targetEspBox = nil end
  if targetEspBrackets then pcall(function() targetEspBrackets:Destroy() end) targetEspBrackets = nil end

  if not targetEspParticles or targetEspParticles.Parent ~= root then
   if targetEspParticles then pcall(function() targetEspParticles:Destroy() end) end
   targetEspParticles = createParticles(root, espColor)
  else
 local pe = targetEspParticles:FindFirstChild("nLheTargetParticles")
   if pe then pe.Color = ColorSequence.new(espColor) end
  end
 end
end)

-- ==============================================
-- PALLET COLOR (Левая сторона)
-- ==============================================
local VisualPallet = Tabs.Visual:AddLeftGroupbox("Pallet Color")

palletColor = Color3.fromRGB(0, 255, 128)
palletColorData = {}

VisualPallet:AddToggle("EnablePalletColor", {
 Text = "Цвет палетки под ногами",
 Default = false,
 Tooltip = "Красит палетку, на которой стоишь",
}):AddColorPicker("PalletColor", {
 Default = Color3.fromRGB(0, 255, 128),
 Title = "Цвет палетки",
 Callback = function(Value)
 palletColor = Value
 end,
})

VisualPallet:AddSlider("PalletResetDelay", {
 Text = "Сброс через (сек)",
 Default = 3,
 Min = 0,
 Max = 10,
 Rounding = 1,
 Compact = false,
 Tooltip = "Через сколько секунд после схода палетка вернёт исходный цвет",
})

VisualPallet:AddSlider("PalletTransparency", {
 Text = "Прозрачность",
 Default = 0.5,
 Min = 0,
 Max = 1,
 Rounding = 2,
 Compact = false,
 Tooltip = "0 — непрозрачная, 1 — полностью невидимая",
})

VisualPallet:AddSlider("PalletGlow", {
 Text = "Подсветка",
 Default = 0,
 Min = 0,
 Max = 1,
 Rounding = 2,
 Compact = false,
 Tooltip = "0 — без подсветки, 1 — максимальное свечение со всех сторон",
})

VisualPallet:AddSlider("PalletSmoothness", {
 Text = "Плавность появления",
 Default = 0,
 Min = 0,
 Max = 1,
 Rounding = 2,
 Compact = false,
 Tooltip = "0 — цвет появляется сразу; 1 — очень плавное появление",
})

local function getPalletFromPart(part)
 local cur = part
 while cur and cur ~= workspace do
 if string.find(string.lower(cur.Name), "pallet") then
 return cur
 end
 cur = cur.Parent
 end
 return nil
end

local function getPalletParts(pallet)
 local parts = {}
 if pallet:IsA("BasePart") then
 table.insert(parts, pallet)
 end
 for _, d in ipairs(pallet:GetDescendants()) do
 if d:IsA("BasePart") then
 table.insert(parts, d)
 end
 end
 return parts
end

local function restorePallet(data)
 for part, orig in pairs(data.originals) do
 if part and part.Parent then
 pcall(function()
 part.Color = orig.color
 part.Transparency = orig.transparency
 local light = part:FindFirstChild("nLhePalletLight")
 if light then light:Destroy() end
 if part.Material == Enum.Material.Neon then
 part.Material = Enum.Material.SmoothPlastic
 end
 end)
 end
 end
 if data.boxes then
 for p, box in pairs(data.boxes) do
 pcall(function() box:Destroy() end)
 data.boxes[p] = nil
 end
 end
 if data.highlight then
 pcall(function() data.highlight:Destroy() end)
 data.highlight = nil
 end
end

local function restoreAllPallets()
 for _, data in pairs(palletColorData) do
 restorePallet(data)
 end
 palletColorData = {}
end

Toggles.EnablePalletColor:OnChanged(function()
 if not Toggles.EnablePalletColor.Value then
 restoreAllPallets()
 end
end)

RunService.Heartbeat:Connect(function()
 if not (Toggles.EnablePalletColor and Toggles.EnablePalletColor.Value) then
 return
 end
 local char = LocalPlayer.Character
 local root = char and char:FindFirstChild("HumanoidRootPart")
 local hum = char and char:FindFirstChildOfClass("Humanoid")
 local now = tick()
 local delay = Options.PalletResetDelay and Options.PalletResetDelay.Value or 3

 local standingPallet = nil
 if root and hum and hum.Health > 0 and hum.FloorMaterial ~= Enum.Material.Air then
 local params = RaycastParams.new()
 params.FilterType = Enum.RaycastFilterType.Exclude
 params.FilterDescendantsInstances = { char }
 local result = workspace:Raycast(root.Position, Vector3.new(0, -10, 0), params)
 if result then
 standingPallet = getPalletFromPart(result.Instance)
 end
 end

 if standingPallet then
 local data = palletColorData[standingPallet]
 if not data then
 data = { originals = {}, lastStand = now }
 for _, part in ipairs(getPalletParts(standingPallet)) do
 data.originals[part] = { color = part.Color, transparency = part.Transparency }
 end
 palletColorData[standingPallet] = data
 end
 data.lastStand = now
 local wantT = (Options.PalletTransparency and Options.PalletTransparency.Value) or 0
 local smooth = (Options.PalletSmoothness and Options.PalletSmoothness.Value) or 0

 for part in pairs(data.originals) do
 if part and part.Parent then
 if smooth > 0 then
 local dt = 1/60
 local alpha = math.clamp(dt / math.max(0.05, smooth), 0.01, 1)
 if part.Color ~= palletColor then
 part.Color = part.Color:Lerp(palletColor, alpha)
 end
 if math.abs(part.Transparency - wantT) > 0.01 then
 part.Transparency = part.Transparency + (wantT - part.Transparency) * alpha
 end
 else
 if part.Color ~= palletColor then part.Color = palletColor end
 if part.Transparency ~= wantT then part.Transparency = wantT end
 end
 local glow = (Options.PalletGlow and Options.PalletGlow.Value) or 0
 local light = part:FindFirstChild("nLhePalletLight")
 if glow > 0 then
 if glow >= 0.55 then part.Material = Enum.Material.Neon else part.Material = Enum.Material.SmoothPlastic end
 part.Color = palletColor:Lerp(Color3.new(1, 1, 1), glow * 0.35)
 if not light then
 light = Instance.new("PointLight")
 light.Name = "nLhePalletLight"
 light.Shadows = false
 light.Parent = part
 end
 light.Enabled = true
 light.Color = palletColor
 light.Brightness = 0.2 + glow * 7
 light.Range = 3 + glow * 20
 else
 if light then light.Enabled = false end
 if part.Material == Enum.Material.Neon then part.Material = Enum.Material.SmoothPlastic end
 end
 end
 end
 end

 for pallet, data in pairs(palletColorData) do
 if not pallet.Parent then
 palletColorData[pallet] = nil
 elseif pallet ~= standingPallet and now - data.lastStand >= delay then
 restorePallet(data)
 palletColorData[pallet] = nil
 end
 end
end)

-- ==============================================
-- INPUT OVERLAY (Левая сторона)
-- ==============================================
inputOverlayGui = nil
inputOverlayKeys = {}
inputOverlayMouse = {}
inputOverlayConn = nil

local function createInputOverlay()
 if inputOverlayGui then return end
 local sg = Instance.new("ScreenGui")
 sg.Name = "InputOverlay"
 sg.ResetOnSpawn = false
 sg.IgnoreGuiInset = true
 sg.DisplayOrder = 9999
 sg.Parent = game:GetService("CoreGui")
 local container = Instance.new("Frame")
 container.Name = "Container"
 container.Size = UDim2.new(0, 230, 0, 110)
 container.Position = UDim2.new(0, 20, 1, -130)
 container.BackgroundTransparency = 1
 container.Parent = sg
 inputOverlayGui = sg
 local keySize = 35
 local keyGap = 4
 local keyStartX = 0
 local keyStartY = 35
 local keyLayout = {
 {key = "W", x = keyStartX + keySize + keyGap, y = keyStartY},
 {key = "A", x = keyStartX, y = keyStartY + keySize + keyGap},
 {key = "S", x = keyStartX + keySize + keyGap, y = keyStartY + keySize + keyGap},
 {key = "D", x = keyStartX + (keySize + keyGap) * 2, y = keyStartY + keySize + keyGap},
 }
 for _, layout in ipairs(keyLayout) do
 local frame = Instance.new("Frame")
 frame.Name = "Key_" .. layout.key
 frame.Size = UDim2.new(0, keySize, 0, keySize)
 frame.Position = UDim2.new(0, layout.x, 0, layout.y)
 frame.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
 frame.BackgroundTransparency = 0.3
 frame.BorderSizePixel = 1
 frame.BorderColor3 = Color3.fromRGB(60, 60, 60)
 frame.Parent = container
 local corner = Instance.new("UICorner")
 corner.CornerRadius = UDim.new(0, 6)
 corner.Parent = frame
 local label = Instance.new("TextLabel")
 label.Size = UDim2.new(1, 0, 1, 0)
 label.BackgroundTransparency = 1
 label.Text = layout.key
 label.TextColor3 = Color3.fromRGB(200, 200, 200)
 label.Font = Enum.Font.GothamBold
 label.TextSize = 16
 label.Parent = frame
 inputOverlayKeys[layout.key] = frame
 end
 local mouseX = keyStartX + (keySize + keyGap) * 3 + 18
 local mouseY = keyStartY - 2
 local mouseBody = Instance.new("Frame")
 mouseBody.Name = "MouseBody"
 mouseBody.Size = UDim2.new(0, 40, 0, 72)
 mouseBody.Position = UDim2.new(0, mouseX, 0, mouseY)
 mouseBody.BackgroundColor3 = Color3.fromRGB(35, 35, 40)
 mouseBody.BackgroundTransparency = 0.1
 mouseBody.BorderSizePixel = 0
 mouseBody.Parent = container
 local mbCorner = Instance.new("UICorner")
 mbCorner.CornerRadius = UDim.new(0, 12)
 mbCorner.Parent = mouseBody
 local mbStroke = Instance.new("UIStroke")
 mbStroke.Color = Color3.fromRGB(80, 80, 90)
 mbStroke.Thickness = 1.5
 mbStroke.Transparency = 0.15
 mbStroke.Parent = mouseBody
 local mbGrad = Instance.new("UIGradient")
 mbGrad.Rotation = 90
 mbGrad.Color = ColorSequence.new({
 ColorSequenceKeypoint.new(0, Color3.fromRGB(50, 50, 58)),
 ColorSequenceKeypoint.new(0.5, Color3.fromRGB(38, 38, 44)),
 ColorSequenceKeypoint.new(1, Color3.fromRGB(28, 28, 33)),
 })
 mbGrad.Parent = mouseBody
 local splitLine = Instance.new("Frame")
 splitLine.Name = "SplitLine"
 splitLine.Size = UDim2.new(0, 1, 0, 32)
 splitLine.Position = UDim2.new(0, 19.5, 0, 3)
 splitLine.BackgroundColor3 = Color3.fromRGB(70, 70, 80)
 splitLine.BackgroundTransparency = 0.3
 splitLine.BorderSizePixel = 0
 splitLine.Parent = mouseBody
 local mouseLeft = Instance.new("Frame")
 mouseLeft.Name = "MouseLeft"
 mouseLeft.Size = UDim2.new(0, 17, 0, 32)
 mouseLeft.Position = UDim2.new(0, 2, 0, 2)
 mouseLeft.BackgroundColor3 = Color3.fromRGB(45, 45, 52)
 mouseLeft.BackgroundTransparency = 0.05
 mouseLeft.BorderSizePixel = 0
 mouseLeft.Parent = mouseBody
 local mlCorner = Instance.new("UICorner")
 mlCorner.CornerRadius = UDim.new(0, 8)
 mlCorner.Parent = mouseLeft
 local mlStroke = Instance.new("UIStroke")
 mlStroke.Color = Color3.fromRGB(65, 65, 75)
 mlStroke.Thickness = 1
 mlStroke.Transparency = 0.25
 mlStroke.Parent = mouseLeft
 local mouseRight = Instance.new("Frame")
 mouseRight.Name = "MouseRight"
 mouseRight.Size = UDim2.new(0, 17, 0, 32)
 mouseRight.Position = UDim2.new(0, 21, 0, 2)
 mouseRight.BackgroundColor3 = Color3.fromRGB(45, 45, 52)
 mouseRight.BackgroundTransparency = 0.05
 mouseRight.BorderSizePixel = 0
 mouseRight.Parent = mouseBody
 local mrCorner = Instance.new("UICorner")
 mrCorner.CornerRadius = UDim.new(0, 8)
 mrCorner.Parent = mouseRight
 local mrStroke = Instance.new("UIStroke")
 mrStroke.Color = Color3.fromRGB(65, 65, 75)
 mrStroke.Thickness = 1
 mrStroke.Transparency = 0.25
 mrStroke.Parent = mouseRight
 inputOverlayMouse.Left = mouseLeft
 inputOverlayMouse.Right = mouseRight
 inputOverlayMouse.LeftStroke = mlStroke
 inputOverlayMouse.RightStroke = mrStroke
end

local function destroyInputOverlay()
 if inputOverlayGui and inputOverlayGui.Parent then inputOverlayGui:Destroy() end
 inputOverlayGui = nil
 inputOverlayKeys = {}
 inputOverlayMouse = {}
end

local function startInputOverlayTracking()
 if inputOverlayConn then return end
 local UIS = game:GetService("UserInputService")
 inputOverlayConn = RunService.RenderStepped:Connect(function()
 if not inputOverlayGui then return end
 for key, frame in pairs(inputOverlayKeys) do
 local pressed = false
 if key == "W" then pressed = UIS:IsKeyDown(Enum.KeyCode.W) end
 if key == "A" then pressed = UIS:IsKeyDown(Enum.KeyCode.A) end
 if key == "S" then pressed = UIS:IsKeyDown(Enum.KeyCode.S) end
 if key == "D" then pressed = UIS:IsKeyDown(Enum.KeyCode.D) end
 if pressed then
 frame.BackgroundColor3 = Color3.fromRGB(100, 200, 100)
 frame.BackgroundTransparency = 0.1
 else
 frame.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
 frame.BackgroundTransparency = 0.3
 end
 end
 if inputOverlayMouse.Left then
 if UIS:IsMouseButtonPressed(Enum.UserInputType.MouseButton1) then
 inputOverlayMouse.Left.BackgroundColor3 = Color3.fromRGB(80, 140, 255)
 inputOverlayMouse.Left.BackgroundTransparency = 0
 if inputOverlayMouse.LeftStroke then
 inputOverlayMouse.LeftStroke.Color = Color3.fromRGB(120, 180, 255)
 inputOverlayMouse.LeftStroke.Transparency = 0
 end
 else
 inputOverlayMouse.Left.BackgroundColor3 = Color3.fromRGB(50, 50, 55)
 inputOverlayMouse.Left.BackgroundTransparency = 0.1
 if inputOverlayMouse.LeftStroke then
 inputOverlayMouse.LeftStroke.Color = Color3.fromRGB(60, 60, 70)
 inputOverlayMouse.LeftStroke.Transparency = 0.3
 end
 end
 end
 if inputOverlayMouse.Right then
 if UIS:IsMouseButtonPressed(Enum.UserInputType.MouseButton2) then
 inputOverlayMouse.Right.BackgroundColor3 = Color3.fromRGB(255, 80, 80)
 inputOverlayMouse.Right.BackgroundTransparency = 0
 if inputOverlayMouse.RightStroke then
 inputOverlayMouse.RightStroke.Color = Color3.fromRGB(255, 140, 140)
 inputOverlayMouse.RightStroke.Transparency = 0
 end
 else
 inputOverlayMouse.Right.BackgroundColor3 = Color3.fromRGB(50, 50, 55)
 inputOverlayMouse.Right.BackgroundTransparency = 0.1
 if inputOverlayMouse.RightStroke then
 inputOverlayMouse.RightStroke.Color = Color3.fromRGB(60, 60, 70)
 inputOverlayMouse.RightStroke.Transparency = 0.3
 end
 end
 end
 end)
end

local function stopInputOverlayTracking()
 if inputOverlayConn then inputOverlayConn:Disconnect() inputOverlayConn = nil end
end

VisualPallet:AddToggle("EnableInputOverlay", {
 Text = "Input Overlay",
 Default = false,
 Tooltip = "типа оверлей, показывает клавиши wasd и нажатия мыши",
}):OnChanged(function()
 if Toggles.EnableInputOverlay.Value then
 createInputOverlay()
 startInputOverlayTracking()
 else
 stopInputOverlayTracking()
 destroyInputOverlay()
 end
end)

-- ==============================================
-- CUSTOM SKIN (Левая сторона)
-- ==============================================
local XocoSkinSection = Tabs.Visual:AddLeftGroupbox("Custom Skin")

local skinConn = nil
local skinOriginals = {}

local function getXocoColor()
 if Options.CustomSkinColor and Options.CustomSkinColor.Value then
  return Options.CustomSkinColor.Value
 end
 return Color3.fromRGB(255, 255, 255)
end

local function getXocoMaterial()
 local name = Options.CustomSkinMaterial and Options.CustomSkinMaterial.Value or "Default"
 if name == "Default" then return nil end
 local ok, mat = pcall(function() return Enum.Material[name] end)
 if ok then return mat end
 return nil
end

local function applyXocoSkin()
 local char = LocalPlayer.Character
 if not char then return end
 local color = getXocoColor()
 local mat = getXocoMaterial()
 for _, part in ipairs(char:GetDescendants()) do
  if part:IsA("Clothing") or part:IsA("ShirtGraphic") or part:IsA("Decal") then
   if not skinOriginals[part] then
    skinOriginals[part] = { Type = "Clothing", Parent = part.Parent }
   end
   pcall(function() part.Parent = game:GetService("Lighting") end)
  elseif part:IsA("BasePart") then
   if not skinOriginals[part] then
    local tex = part:IsA("MeshPart") and part.TextureID or nil
    skinOriginals[part] = { Type = "BasePart", Material = part.Material, Color = part.Color, Transparency = part.Transparency, TextureID = tex }
   end
   pcall(function()
    part.Color = color
    if mat then part.Material = mat end
    if part:IsA("MeshPart") then part.TextureID = "" end
   end)
  elseif part:IsA("SpecialMesh") then
   if not skinOriginals[part] then
    skinOriginals[part] = { Type = "SpecialMesh", TextureId = part.TextureId }
   end
   pcall(function() part.TextureId = "" end)
  end
 end
end

XocoSkinSection:AddToggle("EnableCustomSkin", {
 Text = "Custom Skin",
 Default = false,
 Tooltip = "Красит твоего игрока в выбранный цвет",
 Callback = function(Value)
  if Value then
   if not skinConn then
    skinConn = RunService.Heartbeat:Connect(function()
     applyXocoSkin()
    end)
   end
  else
   if skinConn then
    skinConn:Disconnect()
    skinConn = nil
   end
   for part, orig in pairs(skinOriginals) do
    if part then
     if orig.Type == "Clothing" and orig.Parent then
      pcall(function() part.Parent = orig.Parent end)
     elseif orig.Type == "BasePart" and part.Parent then
      pcall(function()
       part.Material = orig.Material
       part.Color = orig.Color
       part.Transparency = orig.Transparency
       if part:IsA("MeshPart") and orig.TextureID then part.TextureID = orig.TextureID end
      end)
     elseif orig.Type == "SpecialMesh" and part.Parent then
      pcall(function() part.TextureId = orig.TextureId end)
     end
    end
   end
   skinOriginals = {}
  end
 end
})

XocoSkinSection:AddLabel("Paint Color"):AddColorPicker("CustomSkinColor", {
 Default = Color3.fromRGB(255, 255, 255),
 Title = "Цвет краски",
})

XocoSkinSection:AddDropdown("CustomSkinMaterial", {
 Text = "Material",
 Values = {"Default", "ForceField", "Neon", "Glass", "Foil", "Ice", "CorrodedMetal", "DiamondPlate", "Wood", "WoodPlanks", "Marble", "Granite", "Slate", "Brick", "Fabric", "Sand", "Plastic", "SmoothPlastic", "Cobblestone", "Grass"},
 Default = "Default",
 Tooltip = "Материал частей тела",
})

LocalPlayer.CharacterAdded:Connect(function(char)
 if Toggles.EnableCustomSkin and Toggles.EnableCustomSkin.Value then
  task.wait(0.2)
  applyXocoSkin()
 end
end)

-- ==============================================
-- CUSTOM IMAGE (Правая сторона)
-- ==============================================
local XocoImageSection = Tabs.Visual:AddRightGroupbox("Custom Image")

local imageGui = nil
local imageLabel = nil

local customImages = {
 ["Skull"] = "rbxassetid://17754592235",
 ["Fire"] = "rbxassetid://1215152788",
 ["Galaxy"] = "rbxassetid://940794397",
 ["Smile"] = "rbxassetid://10932783329",
 ["Target"] = "rbxassetid://16885137630",
 ["Custom"] = "",
}

XocoImageSection:AddToggle("EnableCustomImage", {
 Text = "Custom Image",
 Default = false,
 Tooltip = "Показывает картинку на экране",
 Callback = function(Value)
  if not Value and imageGui then
   pcall(function() imageGui:Destroy() end)
   imageGui = nil
   imageLabel = nil
  end
 end,
})

XocoImageSection:AddDropdown("CustomImageSelect", {
 Text = "Image",
 Values = {"Skull", "Fire", "Galaxy", "Smile", "Target", "Custom"},
 Default = "Skull",
 Tooltip = "ну типа касмтоную нельзя, но можно выбрать из готовых",
})

XocoImageSection:AddSlider("CustomImageX", {
 Text = "Position X",
 Default = 50,
 Min = 0,
 Max = 100,
 Rounding = 0,
 Suffix = "%",
})

XocoImageSection:AddSlider("CustomImageY", {
 Text = "Position Y",
 Default = 50,
 Min = 0,
 Max = 100,
 Rounding = 0,
 Suffix = "%",
})

XocoImageSection:AddSlider("CustomImageZ", {
 Text = "Scale / ZIndex",
 Default = 50,
 Min = 10,
 Max = 200,
 Rounding = 0,
})

local function updateXocoImage()
 if not (Toggles.EnableCustomImage and Toggles.EnableCustomImage.Value) then
  if imageGui then
   pcall(function() imageGui:Destroy() end)
   imageGui = nil
   imageLabel = nil
  end
  return
 end

 if not imageGui then
  imageGui = Instance.new("ScreenGui")
  imageGui.Name = "XocoImageGui"
  imageGui.ResetOnSpawn = false
  imageGui.IgnoreGuiInset = true
  local targetParent = LocalPlayer:WaitForChild("PlayerGui")
  pcall(function() targetParent = game:GetService("CoreGui") end)
  pcall(function() if gethui then targetParent = gethui() end end)
  imageGui.Parent = targetParent

  imageLabel = Instance.new("ImageLabel")
  imageLabel.Name = "XocoImage"
  imageLabel.BackgroundTransparency = 1
  imageLabel.Size = UDim2.new(0, 200, 0, 200)
  imageLabel.AnchorPoint = Vector2.new(0.5, 0.5)
  imageLabel.Parent = imageGui
 end

 local imgName = Options.CustomImageSelect and Options.CustomImageSelect.Value or "Skull"
 local customID = Options.CustomImageCustomID and Options.CustomImageCustomID.Value or ""
 local imageID = customImages[imgName] or ""
 
 if imgName == "Custom" and customID ~= "" then
  imageID = customID
 end

 if imageID ~= "" then
  imageLabel.Image = imageID
  imageLabel.ImageColor3 = Color3.fromRGB(255, 255, 255)
 else
  imageLabel.Image = ""
 end

 local posX = Options.CustomImageX and Options.CustomImageX.Value or 50
 local posY = Options.CustomImageY and Options.CustomImageY.Value or 50
 local scaleZ = Options.CustomImageZ and Options.CustomImageZ.Value or 50

 imageLabel.Position = UDim2.new(posX / 100, 0, posY / 100, 0)
 imageLabel.Size = UDim2.new(0, 100 + scaleZ, 0, 100 + scaleZ)
 imageLabel.ZIndex = math.clamp(scaleZ, 1, 100)
end

RunService.RenderStepped:Connect(updateXocoImage)

-- ==============================================
-- WORLD (Правая сторона)
-- ==============================================
local VisualWater = Tabs.Visual:AddRightGroupbox("World")

local waterSavedData = {}

VisualWater:AddToggle("EnableRealisticWater", {
 Text = "Realistic Water",
 Default = false,
 Tooltip = "плыли мы по морю ветер мачту рвал...",
 Callback = function(Value)
 pcall(function()
 local terrain = workspace.Terrain
 local model = workspace:FindFirstChild("Map")
 model = model and model:FindFirstChild("AlwaysHereTweenedObjects")
 model = model and model:FindFirstChild("Ocean")
 model = model and model:FindFirstChild("Object")
 model = model and model:FindFirstChild("ObjectModel")
 
 if model then
 if Value then
 for _, part in ipairs(model:GetChildren()) do
 if part.Name == "Ocean" and part:IsA("BasePart") then
 if not waterSavedData[part] then
 local cf = part.CFrame
 local size = part.Size
 local region = Region3.new(
 cf.Position - (size / 2),
 cf.Position + (size / 2) - Vector3.new(0, 1, 0)
 ):ExpandToGrid(4)
 
 waterSavedData[part] = {
 region = region,
 transparency = part.Transparency,
 cancollide = part.CanCollide
 }
 end
 
 local data = waterSavedData[part]
 part.Transparency = 1
 part.CanCollide = false
 terrain:FillRegion(data.region, 4, Enum.Material.Water)
 end
 end
 else
 for part, data in pairs(waterSavedData) do
 if part and part.Parent then
 part.Transparency = data.transparency
 if Toggles.EnableWaterWalk and Toggles.EnableWaterWalk.Value then
 part.CanCollide = true
 else
 part.CanCollide = data.cancollide
 end
 end
 terrain:FillRegion(data.region, 4, Enum.Material.Air)
 end
 end
 end
 end)
 end
})

VisualWater:AddSlider("WaterWaveSize", {
 Text = "Размер волн",
 Default = 0.15,
 Min = 0,
 Max = 3,
 Rounding = 2,
 Compact = false,
 Tooltip = "размеры волн, чем больше тем сильнее",
 Callback = function(Value)
 pcall(function()
 workspace.Terrain.WaterWaveSize = Value
 workspace.Terrain.WaterWaveSpeed = Value * 20
 end)
 end
})

-- ==============================================
-- CUSTOM BLACK HOLE (Правая сторона)
-- ==============================================
local CBHGroup = Tabs.Visual:AddRightGroupbox("Custom Black Hole")

local CBH = {}
CBH.RS = game:GetService("ReplicatedStorage")
CBH.WS = game:GetService("Workspace")
CBH.RunService = game:GetService("RunService")
CBH.Players = game:GetService("Players")
CBH.LocalPlayer = CBH.Players.LocalPlayer

CBH.settings = {
    colorMode = "Default",
    neonGlow = false,
    silent = false,
    rainbow = false,
    hideBillboard = false,
    beamWidth0 = 1,
    beamWidth1 = 1,
    beamTransparency = 0,
    billboardSize = 10,
    realistic = false,
}

CBH.rainbowConn = nil
CBH.watcherConn = nil

CBH.palette = {
    ["Default"]   = { hole = Color3.fromRGB(0,   0,   0),   beam = Color3.fromRGB(170, 0, 255),  gui = Color3.fromRGB(150, 0, 255) },
    ["White"]     = { hole = Color3.fromRGB(255, 255, 255), beam = Color3.fromRGB(255, 255, 255),gui = Color3.fromRGB(255, 255, 255) },
    ["Red"]       = { hole = Color3.fromRGB(180,  0,   0),   beam = Color3.fromRGB(255, 50, 50),  gui = Color3.fromRGB(200, 30, 30) },
    ["Blue"]      = { hole = Color3.fromRGB(0,   50, 180),   beam = Color3.fromRGB(50, 120, 255), gui = Color3.fromRGB(30,  80, 220) },
    ["Green"]     = { hole = Color3.fromRGB(0,  120,  30),   beam = Color3.fromRGB(50, 255, 100), gui = Color3.fromRGB(20, 180, 60) },
    ["Gold"]      = { hole = Color3.fromRGB(180,140,   0),   beam = Color3.fromRGB(255, 220, 50), gui = Color3.fromRGB(220, 180, 20) },
    ["Cyan"]      = { hole = Color3.fromRGB(0,  180, 200),   beam = Color3.fromRGB(50, 230, 255), gui = Color3.fromRGB(0,  200, 230) },
    ["Pink"]      = { hole = Color3.fromRGB(220, 50, 180),   beam = Color3.fromRGB(255, 100, 220),gui = Color3.fromRGB(230, 60, 200) },
}

CBH.colorList = {}
for k, _ in pairs(CBH.palette) do table.insert(CBH.colorList, k) end
table.sort(CBH.colorList, function(a, b)
    if a == "Default" then return true end
    if b == "Default" then return false end
    return a < b
end)

CBH.applyToModel = function(model)
    if not model then return end
    local hole = model:FindFirstChild("Hole")
    if not hole then return end

    hole.Material = CBH.settings.neonGlow and Enum.Material.Neon or Enum.Material.Plastic

    if not CBH.settings.rainbow then
        local ct = CBH.palette[CBH.settings.colorMode]
        if ct then
            hole.Color = ct.hole
            local beam = hole:FindFirstChild("Attachment") and hole.Attachment:FindFirstChild("Beam")
            if beam then beam.Color = ColorSequence.new(ct.beam) end
            local gui = hole:FindFirstChild("BillboardGui")
            if gui then
                if gui:FindFirstChild("Large") then gui.Large.ImageColor3 = ct.gui end
                if gui:FindFirstChild("Small") then gui.Small.ImageColor3 = ct.gui end
            end
        end
    end

    local beam = hole:FindFirstChild("Attachment") and hole.Attachment:FindFirstChild("Beam")
    if beam then
        beam.Width0 = CBH.settings.beamWidth0
        beam.Width1 = CBH.settings.beamWidth1
        beam.Transparency = NumberSequence.new(CBH.settings.beamTransparency / 100)
    end

    local gui = hole:FindFirstChild("BillboardGui")
    if gui then
        gui.Size = UDim2.new(CBH.settings.billboardSize, 0, CBH.settings.billboardSize, 0)
        gui.Enabled = not CBH.settings.hideBillboard
    end

    local drone  = hole:FindFirstChild("Drone")
    local scream = hole:FindFirstChild("Scream")
    if drone  then drone.Volume  = CBH.settings.silent and 0 or 1 end
    if scream then scream.Volume = CBH.settings.silent and 0 or 1 end
end

CBH.applyCurrent = function()
    CBH.applyToModel(CBH.WS:FindFirstChild("BlackHoleKick"))
end

CBH.applyRealistic = function(model)
    if not model then return end
    local hole = model:FindFirstChild("Hole")
    if not hole then return end

    local success, realisticModel = pcall(function()
        return game:GetObjects("rbxassetid://16797584940")[1]
    end)
    if not success or not realisticModel then return end

    for _, obj in ipairs(realisticModel:GetDescendants()) do
        if obj:IsA("ParticleEmitter") or obj:IsA("Beam") or obj:IsA("Sound") or obj:IsA("Trail") then
            local clone = obj:Clone()
            clone.Parent = hole
        end
        if obj:IsA("BillboardGui") then
            local curGui = hole:FindFirstChild("BillboardGui")
            if curGui then
                local newGui = obj:Clone()
                newGui.Parent = hole
                if curGui:FindFirstChild("Large") and newGui:FindFirstChild("Large") then
                    curGui.Large.Image = newGui.Large.Image
                end
                if curGui:FindFirstChild("Small") and newGui:FindFirstChild("Small") then
                    curGui.Small.Image = newGui.Small.Image
                end
                newGui:Destroy()
            end
        end
    end

    realisticModel:Destroy()
end

CBH.setupWatcher = function()
    if CBH.watcherConn then CBH.watcherConn:Disconnect() end
    CBH.watcherConn = CBH.WS.ChildAdded:Connect(function(child)
        if child.Name == "BlackHoleKick" then
            task.wait(0.1)
            CBH.applyToModel(child)
            if CBH.settings.realistic then
                CBH.applyRealistic(child)
            end
        end
    end)
end

CBH.setupWatcher()

CBHGroup:AddDropdown("CBHColorMode", {
    Text = "Цвет дыры",
    Values = CBH.colorList,
    Default = "Default",
    Multi = false,
    Tooltip = "цвет черной дыры",
    Callback = function(Value)
        CBH.settings.colorMode = Value
        if CBH.settings.rainbow then
            CBH.settings.rainbow = false
            if Toggles.CBHRainbow then Toggles.CBHRainbow:SetValue(false) end
            if CBH.rainbowConn then CBH.rainbowConn:Disconnect() CBH.rainbowConn = nil end
        end
        CBH.applyCurrent()
    end,
})

CBHGroup:AddToggle("CBHNeonGlow", {
    Text = "Neon Glow",
    Default = false,
    Tooltip = "Дыра светится, ну неон же",
    Callback = function(Value)
        CBH.settings.neonGlow = Value
        CBH.applyCurrent()
    end,
})

CBHGroup:AddToggle("CBHRainbow", {
    Text = "Rainbow Mode",
    Default = false,
    Tooltip = "Дыра переливается цветами радуги",
    Callback = function(Value)
        CBH.settings.rainbow = Value
        if CBH.rainbowConn then CBH.rainbowConn:Disconnect() CBH.rainbowConn = nil end
        if Value then
            local hue = 0
            CBH.rainbowConn = CBH.RunService.Heartbeat:Connect(function(dt)
                hue = (hue + dt * 0.3) % 1
                local c = Color3.fromHSV(hue, 1, 1)
                local model = CBH.WS:FindFirstChild("BlackHoleKick")
                if not model then return end
                local hole = model:FindFirstChild("Hole")
                if not hole then return end
                hole.Color = c
                local beam = hole:FindFirstChild("Attachment") and hole.Attachment:FindFirstChild("Beam")
                if beam then beam.Color = ColorSequence.new(c) end
                local gui = hole:FindFirstChild("BillboardGui")
                if gui then
                    if gui:FindFirstChild("Large") then gui.Large.ImageColor3 = c end
                    if gui:FindFirstChild("Small") then gui.Small.ImageColor3 = c end
                end
            end)
        else
            CBH.applyCurrent()
        end
    end,
})

CBHGroup:AddToggle("CBHRealistic", {
    Text = "Realistic Black Hole",
    Default = false,
    Tooltip = "Загружает реалистичную модель с частицами/звуками/трейлами",
    Callback = function(Value)
        CBH.settings.realistic = Value
        if Value then
            local current = CBH.WS:FindFirstChild("BlackHoleKick")
            if current then
                CBH.applyRealistic(current)
            end
        end
    end,
})

CBHGroup:AddDivider()

CBHGroup:AddToggle("CBHHideBillboard", {
    Text = "Hide Billboard",
    Default = false,
    Tooltip = "Прячет иконку-картинку",
    Callback = function(Value)
        CBH.settings.hideBillboard = Value
        CBH.applyCurrent()
    end,
})

CBHGroup:AddToggle("CBHSilent", {
    Text = "Silent (без звука)",
    Default = false,
    Tooltip = "Убирает звуки Drone + Scream",
    Callback = function(Value)
        CBH.settings.silent = Value
        CBH.applyCurrent()
    end,
})

CBHGroup:AddDivider()

CBHGroup:AddSlider("CBHBeamW0", {
    Text = "Beam ширина (внутренняя)",
    Default = 1,
    Min = 0,
    Max = 20,
    Rounding = 1,
    Compact = false,
    Tooltip = "Толщина луча у центра дыры",
    Callback = function(Value)
        CBH.settings.beamWidth0 = Value
        local model = CBH.WS:FindFirstChild("BlackHoleKick")
        if model then
            local hole = model:FindFirstChild("Hole")
            local beam = hole and hole:FindFirstChild("Attachment") and hole.Attachment:FindFirstChild("Beam")
            if beam then beam.Width0 = Value end
        end
    end,
})

CBHGroup:AddSlider("CBHBeamW1", {
    Text = "Beam ширина (внешняя)",
    Default = 1,
    Min = 0,
    Max = 20,
    Rounding = 1,
    Compact = false,
    Tooltip = "Толщина луча у края дыры",
    Callback = function(Value)
        CBH.settings.beamWidth1 = Value
        local model = CBH.WS:FindFirstChild("BlackHoleKick")
        if model then
            local hole = model:FindFirstChild("Hole")
            local beam = hole and hole:FindFirstChild("Attachment") and hole.Attachment:FindFirstChild("Beam")
            if beam then beam.Width1 = Value end
        end
    end,
})

CBHGroup:AddSlider("CBHBeamTransparency", {
    Text = "Beam прозрачность (%)",
    Default = 0,
    Min = 0,
    Max = 100,
    Rounding = 0,
    Compact = false,
    Tooltip = "0 = полностью непрозрачный, 100 = невидимый",
    Callback = function(Value)
        CBH.settings.beamTransparency = Value
        local model = CBH.WS:FindFirstChild("BlackHoleKick")
        if model then
            local hole = model:FindFirstChild("Hole")
            local beam = hole and hole:FindFirstChild("Attachment") and hole.Attachment:FindFirstChild("Beam")
            if beam then
                beam.Transparency = NumberSequence.new(Value / 100)
            end
        end
    end,
})

CBHGroup:AddSlider("CBHBillboardSize", {
    Text = "Billboard размер",
    Default = 10,
    Min = 2,
    Max = 40,
    Rounding = 0,
    Compact = false,
    Tooltip = "Размер иконки-картинки над дырой (studs)",
    Callback = function(Value)
        CBH.settings.billboardSize = Value
        local model = CBH.WS:FindFirstChild("BlackHoleKick")
        if model then
            local hole = model:FindFirstChild("Hole")
            local gui  = hole and hole:FindFirstChild("BillboardGui")
            if gui then gui.Size = UDim2.new(Value, 0, Value, 0) end
        end
    end,
})

CBHGroup:AddButton({
    Text = "Применить к текущей дыре",
    Tooltip = "Применяет все настройки к workspace.BlackHoleKick если она существует",
    Func = function()
        CBH.applyCurrent()
        Library:Notify("Custom Black Hole: настройки применены", 3)
    end,
})

CBHGroup:AddButton({
    Text = "Сброс к Default",
    Tooltip = "Сбрасывает все настройки к стандартным",
    Func = function()
        CBH.settings.colorMode = "Default"
        CBH.settings.neonGlow = false
        CBH.settings.silent = false
        CBH.settings.hideBillboard = false
        CBH.settings.beamWidth0 = 1
        CBH.settings.beamWidth1 = 1
        CBH.settings.beamTransparency = 0
        CBH.settings.billboardSize = 10

        if CBH.settings.rainbow then
            CBH.settings.rainbow = false
            if Toggles.CBHRainbow then Toggles.CBHRainbow:SetValue(false) end
            if CBH.rainbowConn then CBH.rainbowConn:Disconnect() CBH.rainbowConn = nil end
        end

        if Options.CBHColorMode then Options.CBHColorMode:SetValue("Default") end
        if Toggles.CBHNeonGlow then Toggles.CBHNeonGlow:SetValue(false) end
        if Toggles.CBHHideBillboard then Toggles.CBHHideBillboard:SetValue(false) end
        if Toggles.CBHSilent then Toggles.CBHSilent:SetValue(false) end
        if Options.CBHBeamW0 then Options.CBHBeamW0:SetValue(1) end
        if Options.CBHBeamW1 then Options.CBHBeamW1:SetValue(1) end
        if Options.CBHBeamTransparency then Options.CBHBeamTransparency:SetValue(0) end
        if Options.CBHBillboardSize then Options.CBHBillboardSize:SetValue(10) end

        CBH.applyCurrent()
        Library:Notify("Custom Black Hole: сброс к Default", 3)
    end,
})

-- ==============================================
-- ПОГОДА (Левая сторона)
-- ==============================================
local VisualWeather = Tabs.Visual:AddLeftGroupbox("Погода")

VisualWeather:AddToggle("EnableWeather", {
 Text = "Погода",
 Default = false,
 Tooltip = "Включить красивые погодные эффекты",
})

VisualWeather:AddDropdown("WeatherType", {
 Text = "Тип погоды",
 Default = "Снег",
 Values = {"Снег", "Дождь", "Радуга", "Гроза с дождем"},
 Multi = false,
 Tooltip = "Выбери эффект",
})

VisualWeather:AddSlider("WeatherAmount", {
 Text = "Количество",
 Default = 1,
 Min = 0.2,
 Max = 3,
 Rounding = 1,
 Compact = false,
 Tooltip = "Сила снега, дождя и грозы",
})

VisualWeather:AddSlider("WeatherSpeed", {
 Text = "Скорость",
 Default = 1,
 Min = 0.2,
 Max = 3,
 Rounding = 1,
 Compact = false,
 Tooltip = "Скорость падения снега, дождя и грозы",
})

VisualWeather:AddLabel("Цвет всего"):AddColorPicker("WeatherColor", {
 Default = Color3.fromRGB(255, 255, 255),
 Title = "Цвет всей погоды",
})

VisualWeather:AddButton({
 Text = "Сброс цвета",
 Tooltip = "Вернуть обычные цвета снега, дождя, радуги и грозы",
 Func = function()
 if Options.WeatherColor and Options.WeatherColor.SetValue then
 pcall(function() Options.WeatherColor:SetValue(Color3.fromRGB(255, 255, 255)) end)
 end
 local rb = workspace:FindFirstChild("RainbowFixed")
 if rb then rb:Destroy() end
 end,
})

task.spawn(function()
 local weatherPart = nil
 local weatherEmitter = nil
 local weatherLight = nil
 local weatherObjects = {}
 local weatherDrops = {}
 local weatherAnchorPos = nil
 local lastDropSpawn = 0
 local lastLightning = 0
 local lastRainbowColorKey = nil

 local function addWeatherObject(obj)
 weatherObjects[#weatherObjects + 1] = obj
 return obj
 end

 local function clearDrops()
 for i = #weatherDrops, 1, -1 do
 pcall(function() weatherDrops[i].part:Destroy() end)
 weatherDrops[i] = nil
 end
 end

 local function clearWeatherVisuals(keepPart)
 for _, obj in ipairs(weatherObjects) do
 pcall(function() obj:Destroy() end)
 end
 weatherObjects = {}
 clearDrops()
 if weatherEmitter then weatherEmitter.Enabled = false end
 if weatherLight then weatherLight.Enabled = false end
 if not keepPart and weatherPart then
 weatherPart:Destroy()
 weatherPart = nil
 weatherEmitter = nil
 weatherLight = nil
 end
 end

 local function getHRP()
 local char = LocalPlayer.Character
 return char and char:FindFirstChild("HumanoidRootPart")
 end

 local function getWeatherAmount()
 return math.clamp((Options.WeatherAmount and Options.WeatherAmount.Value) or 1, 0.2, 3)
 end

 local function getWeatherSpeed()
 return math.clamp((Options.WeatherSpeed and Options.WeatherSpeed.Value) or 1, 0.2, 3)
 end

 local function getWeatherColor()
 return (Options.WeatherColor and Options.WeatherColor.Value) or Color3.fromRGB(255, 255, 255)
 end

 local function isCustomWeatherColor()
 local c = getWeatherColor()
 return not (c.R > 0.98 and c.G > 0.98 and c.B > 0.98)
 end

 local function weatherColor(defaultColor)
 if isCustomWeatherColor() then
 return getWeatherColor()
 end
 return defaultColor
 end

 local function getGroundY(pos, fallbackY)
 local params = RaycastParams.new()
 params.FilterType = Enum.RaycastFilterType.Blacklist
 params.FilterDescendantsInstances = {LocalPlayer.Character, weatherPart}
 local result = workspace:Raycast(pos + Vector3.new(0, 35, 0), Vector3.new(0, -500, 0), params)
 if result then
 return result.Position.Y + 0.35
 end
 return fallbackY or (pos.Y - 90)
 end

 local function makePart(name, parent, size, cframe, color, transparency)
 local p = Instance.new("Part")
 p.Name = name
 p.Anchored = true
 p.CanCollide = false
 p.CanQuery = false
 p.CanTouch = false
 p.Material = Enum.Material.Neon
 p.Color = color
 p.Transparency = transparency or 0
 p.Size = size
 p.CFrame = cframe
 p.Parent = parent
 return addWeatherObject(p)
 end

 local function spawnDrop(kind, basePos, speedMul)
 speedMul = speedMul or getWeatherSpeed()
 local maxDrops = kind == "snow" and math.floor(420 * getWeatherAmount()) or math.floor(260 * getWeatherAmount())
 if #weatherDrops >= maxDrops then return end
 local p = Instance.new("Part")
 p.Anchored = true
 p.CanCollide = false
 p.CanQuery = false
 p.CanTouch = false
 p.Material = Enum.Material.Neon
 if kind == "snow" then
 p.Name = "WeatherSnowflake"
 p.Shape = Enum.PartType.Ball
 p.Color = weatherColor(Color3.fromRGB(255, 255, 255))
 p.Transparency = 0.03
 local sz = math.random(7, 14) / 10
 local spawnPos = basePos + Vector3.new(math.random(-190,190), math.random(55,95), math.random(-190,190))
 p.Size = Vector3.new(sz, sz, sz)
 p.CFrame = CFrame.new(spawnPos)
 weatherDrops[#weatherDrops + 1] = {
 part = p,
 vel = Vector3.new(math.random(-4,4)/10, -math.random(80,140)/10 * speedMul, math.random(-4,4)/10),
 life = 16,
 groundLife = 1.8,
 groundY = getGroundY(spawnPos, basePos.Y - 4),
 kind = kind,
 phase = math.random()*10,
 landed = false,
 }
 else
 p.Name = "WeatherRainDrop"
 p.Color = weatherColor(Color3.fromRGB(120, 175, 255))
 p.Transparency = 0.02
 p.Size = Vector3.new(0.08, math.random(38, 62) / 10, 0.08)
 p.CFrame = CFrame.new(basePos + Vector3.new(math.random(-210,210), math.random(70,115), math.random(-210,210)))
 weatherDrops[#weatherDrops + 1] = {part = p, vel = Vector3.new(math.random(-8,8)/10, -math.random(120,170) * speedMul, math.random(-8,8)/10), life = 1.8 / speedMul, kind = kind, phase = 0}
 end
 p.Parent = workspace
 end

 local function updateDrops(dt, basePos, kind)
 for i = #weatherDrops, 1, -1 do
 local d = weatherDrops[i]
 if not d.part or not d.part.Parent or d.kind ~= kind then
 if d.part then pcall(function() d.part:Destroy() end) end
 table.remove(weatherDrops, i)
 else
 d.life = d.life - dt
 if kind == "snow" then
 if d.landed then
 d.groundLife = d.groundLife - dt
 d.part.Transparency = math.clamp(1 - (d.groundLife / 1.8), 0.03, 1)
 if d.groundLife <= 0 then
 pcall(function() d.part:Destroy() end)
 table.remove(weatherDrops, i)
 end
 else
 local sway = Vector3.new(math.sin(tick()*1.1 + d.phase) * 0.45, 0, math.cos(tick()*1.0 + d.phase) * 0.45)
 d.part.CFrame = d.part.CFrame * CFrame.Angles(0, math.rad(18*dt), math.rad(12*dt))
 d.part.CFrame = d.part.CFrame + ((d.vel + sway) * dt)
 if d.part.Position.Y <= d.groundY then
 d.landed = true
 d.part.CFrame = CFrame.new(d.part.Position.X, d.groundY, d.part.Position.Z)
 d.part.Transparency = 0.1
 elseif d.life <= 0 then
 pcall(function() d.part:Destroy() end)
 table.remove(weatherDrops, i)
 end
 end
 else
 d.part.CFrame = d.part.CFrame + (d.vel * dt)
 local pos = d.part.Position
 if d.life <= 0 or pos.Y < basePos.Y - 15 or (Vector3.new(pos.X, basePos.Y, pos.Z) - Vector3.new(basePos.X, basePos.Y, basePos.Z)).Magnitude > 300 then
 pcall(function() d.part:Destroy() end)
 table.remove(weatherDrops, i)
 end
 end
 end
 end
 end

 function makeLightning(origin)
 local boltColor = weatherColor(Color3.fromRGB(215, 235, 255))
 local lastPos = origin + Vector3.new(math.random(-30,30), 380, math.random(-30,30))
 local segments = math.random(8, 12)
 for i = 1, segments do
 local nextPos = origin + Vector3.new(math.random(-70, 70), 380 - (i * (380 / segments)), math.random(-70, 70))
 local mid = (lastPos + nextPos) / 2
 local len = (lastPos - nextPos).Magnitude
 local part = makePart("WeatherLightning", workspace, Vector3.new(7, 7, len + 2), CFrame.lookAt(mid, nextPos), boltColor, 0)
 task.delay(0.22, function() if part then part:Destroy() end end)
 lastPos = nextPos
 end
 if math.random(1, 2) == 1 then
 local branchStart = origin + Vector3.new(math.random(-80,80), 260, math.random(-80,80))
 local branchEnd = branchStart + Vector3.new(math.random(-160,160), -math.random(80,150), math.random(-160,160))
 local mid = (branchStart + branchEnd) / 2
 local len = (branchStart - branchEnd).Magnitude
 local branch = makePart("WeatherLightningBranch", workspace, Vector3.new(5, 5, len + 2), CFrame.lookAt(mid, branchEnd), boltColor, 0)
 task.delay(0.22, function() if branch then branch:Destroy() end end)
 end
 end

 function makeRainbowSegment(parent, p1, p2, color, thick)
 local mid = (p1 + p2) / 2
 local len = (p1 - p2).Magnitude
 local seg = Instance.new("Part")
 seg.Name = "RainbowSegment"
 seg.Anchored = true
 seg.CanCollide = false
 seg.CanQuery = false
 seg.CanTouch = false
 seg.Material = Enum.Material.Neon
 seg.Color = color
 seg.Transparency = 0.08
 seg.Size = Vector3.new(thick, thick, len + 3)
 seg.CFrame = CFrame.lookAt(mid, p2)
 seg.Parent = parent
 end

 function ensureRainbow(hrp)
 local c = getWeatherColor()
 local colorKey = tostring(math.floor(c.R*255))..":"..tostring(math.floor(c.G*255))..":"..tostring(math.floor(c.B*255))
 local oldRainbow = workspace:FindFirstChild("RainbowFixed")
 if oldRainbow and lastRainbowColorKey == colorKey then return end
 if oldRainbow then oldRainbow:Destroy() end
 lastRainbowColorKey = colorKey
 clearWeatherVisuals(true)
 local model = Instance.new("Model")
 model.Name = "RainbowFixed"
 model.Parent = workspace
 addWeatherObject(model)

 weatherAnchorPos = weatherAnchorPos or (hrp.Position + Vector3.new(0, 0, -1150))
 local center = weatherAnchorPos + Vector3.new(0, 80, 0)
 local colors = {
 weatherColor(Color3.fromRGB(255, 0, 0)), weatherColor(Color3.fromRGB(255, 120, 0)), weatherColor(Color3.fromRGB(255, 255, 0)),
 weatherColor(Color3.fromRGB(0, 255, 0)), weatherColor(Color3.fromRGB(0, 120, 255)), weatherColor(Color3.fromRGB(100, 0, 200)), weatherColor(Color3.fromRGB(180, 0, 255)),
 }
 local radiusBase = 620
 local steps = 120
 for band, color in ipairs(colors) do
 local radius = radiusBase - (band * 16)
 local last = nil
 for i = 0, steps do
 local a = math.rad(180 - (i * 180 / steps))
 local pos = center + Vector3.new(math.cos(a) * radius, math.sin(a) * radius, 0)
 if last then makeRainbowSegment(model, last, pos, color, 14) end
 last = pos
 end
 end
 end

 function ensureWeatherPart()
 if weatherPart then return end
 weatherPart = Instance.new("Part")
 weatherPart.Name = "nLheWeatherPart"
 weatherPart.Transparency = 1
 weatherPart.CanCollide = false
 weatherPart.CanQuery = false
 weatherPart.CanTouch = false
 weatherPart.Anchored = true
 weatherPart.Size = Vector3.new(460, 1, 460)
 weatherPart.Parent = workspace
 weatherEmitter = Instance.new("ParticleEmitter")
 weatherEmitter.Parent = weatherPart
 weatherEmitter.EmissionDirection = Enum.NormalId.Bottom
 weatherLight = Instance.new("PointLight")
 weatherLight.Parent = weatherPart
 weatherLight.Enabled = false
 end

 function updateWeather()
 if not (Toggles.EnableWeather and Toggles.EnableWeather.Value) then
 clearWeatherVisuals(false)
 weatherAnchorPos = nil
 return
 end

 local hrp = getHRP()
 if not hrp then return end
 ensureWeatherPart()
 local wType = Options.WeatherType and Options.WeatherType.Value or "Снег"
 local now = tick()
 local amountMul = getWeatherAmount()
 local speedMul = getWeatherSpeed()
 weatherPart.CFrame = CFrame.new(hrp.Position + Vector3.new(0, 85, 0))

 if wType ~= "Радуга" and workspace:FindFirstChild("RainbowFixed") then clearWeatherVisuals(true) end

 if wType == "Снег" then
 weatherEmitter.Enabled = false
 weatherEmitter.Texture = ""
 weatherEmitter.Acceleration = Vector3.new(0, -6, 0)
 weatherEmitter.Drag = 12
 weatherEmitter.Rate = 0
 weatherEmitter.Lifetime = NumberRange.new(9, 14)
 weatherEmitter.Speed = NumberRange.new(0, 0)
 weatherEmitter.Rotation = NumberRange.new(0, 360)
 weatherEmitter.RotSpeed = NumberRange.new(-55, 55)
 weatherEmitter.SpreadAngle = Vector2.new(70, 70)
 weatherEmitter.Size = NumberSequence.new({NumberSequenceKeypoint.new(0, 1.7), NumberSequenceKeypoint.new(1, 2.6)})
 weatherEmitter.Transparency = NumberSequence.new(0.02)
 weatherEmitter.Color = ColorSequence.new(weatherColor(Color3.fromRGB(255,255,255)))
 weatherLight.Enabled = false
 updateDrops(1/60, hrp.Position, "snow")
 if now - lastDropSpawn > math.max(0.035, 0.075 / amountMul) then
 lastDropSpawn = now
 for i = 1, math.max(1, math.floor(4 * amountMul)) do spawnDrop("snow", hrp.Position, speedMul) end
 end
 elseif wType == "Дождь" then
 weatherEmitter.Enabled = true
 weatherEmitter.Texture = "rbxassetid://182285145"
 weatherEmitter.Acceleration = Vector3.new(0, -320 * speedMul, 0)
 weatherEmitter.Drag = 0
 weatherEmitter.Rate = 12000 * amountMul
 weatherEmitter.Lifetime = NumberRange.new(0.9 / speedMul, 1.4 / speedMul)
 weatherEmitter.Speed = NumberRange.new(120 * speedMul, 180 * speedMul)
 weatherEmitter.SpreadAngle = Vector2.new(18, 18)
 weatherEmitter.Rotation = NumberRange.new(0, 0)
 weatherEmitter.RotSpeed = NumberRange.new(0, 0)
 weatherEmitter.Size = NumberSequence.new(3.2)
 weatherEmitter.Transparency = NumberSequence.new(0.02)
 weatherEmitter.Color = ColorSequence.new(weatherColor(Color3.fromRGB(95, 160, 255)))
 weatherLight.Enabled = false
 updateDrops(1/60, hrp.Position, "rain")
 if now - lastDropSpawn > math.max(0.008, 0.02 / amountMul) then
 lastDropSpawn = now
 for i = 1, math.max(1, math.floor(12 * amountMul)) do spawnDrop("rain", hrp.Position, speedMul) end
 end
 elseif wType == "Радуга" then
 clearDrops()
 weatherEmitter.Enabled = false
 weatherLight.Enabled = false
 ensureRainbow(hrp)
 elseif wType == "Гроза с дождем" then
 weatherEmitter.Enabled = true
 weatherEmitter.Texture = "rbxassetid://182285145"
 weatherEmitter.Acceleration = Vector3.new(0, -360 * speedMul, 0)
 weatherEmitter.Drag = 0
 weatherEmitter.Rate = 15000 * amountMul
 weatherEmitter.Lifetime = NumberRange.new(0.8 / speedMul, 1.2 / speedMul)
 weatherEmitter.Speed = NumberRange.new(150 * speedMul, 210 * speedMul)
 weatherEmitter.SpreadAngle = Vector2.new(20, 20)
 weatherEmitter.Rotation = NumberRange.new(0, 0)
 weatherEmitter.RotSpeed = NumberRange.new(0, 0)
 weatherEmitter.Size = NumberSequence.new(3.5)
 weatherEmitter.Transparency = NumberSequence.new(0.01)
 weatherEmitter.Color = ColorSequence.new(weatherColor(Color3.fromRGB(80, 130, 230)))
 updateDrops(1/60, hrp.Position, "rain")
 if now - lastDropSpawn > math.max(0.006, 0.016 / amountMul) then
 lastDropSpawn = now
 for i = 1, math.max(1, math.floor(16 * amountMul)) do spawnDrop("rain", hrp.Position, speedMul) end
 end
 if now - lastLightning > (math.random(15, 35) / 10) / amountMul then
 lastLightning = now
 for i = 1, math.random(math.max(1, math.floor(2 * amountMul)), math.max(2, math.floor(4 * amountMul))) do
 local side = math.random(1, 2) == 1 and -1 or 1
 local origin = hrp.Position + Vector3.new(math.random(-1000,1000), 0, side * math.random(900,1500))
 makeLightning(origin)
 end
 end
 end
 end

 RunService.Heartbeat:Connect(updateWeather)
end)

-- ==============================================
-- КОНЕЦ VISUAL ВКЛАДКИ
-- ==============================================

-- ==============================================
-- ВКЛАДКА SERVER (LAGS + DESTROY)
-- ==============================================

local ServerTab = Tabs.Server

local ServL = ServerTab:AddLeftGroupbox("Lags", "zap")
local ServR = ServerTab:AddRightGroupbox("Server Destroy", "skull")

-- ==============================================
-- ПЕРЕМЕННЫЕ
-- ==============================================

local GrabEvents = RS:FindFirstChild("GrabEvents")
local CreateLine = GrabEvents and GrabEvents:FindFirstChild("CreateGrabLine")
local SetNetworkOwner = GrabEvents and GrabEvents:FindFirstChild("SetNetworkOwner")
local DestroyGrabLine = GrabEvents and GrabEvents:FindFirstChild("DestroyGrabLine")
local SpawnToy = RS:FindFirstChild("MenuToys") and RS.MenuToys:FindFirstChild("SpawnToyRemoteFunction")
local DestroyToy = RS:FindFirstChild("MenuToys") and RS.MenuToys:FindFirstChild("DestroyToy")

-- ==============================================
-- 1. LINE LAG
-- ==============================================

local lineLagActive = false
local lineLagTask = nil
local lineAmount = 500

ServL:AddSlider("LineLagAmount", {
    Text = "Line Lag Amount",
    Default = 500,
    Min = 50,
    Max = 2000,
    Rounding = 0,
    Suffix = " lines",
    Tooltip = "Количество линий за один цикл",
    Callback = function(v)
        lineAmount = v
    end
})

ServL:AddToggle("LineLag", {
    Text = "Line Lag",
    Default = false,
    Tooltip = "Спамит линиями захвата для лага сервера",
    Callback = function(v)
        lineLagActive = v
        
        if v then
            if not CreateLine then
                Library:Notify("CreateGrabLine не найден!", 3)
                Toggles.LineLag:SetValue(false)
                return
            end
            
            lineLagTask = task.spawn(function()
                while lineLagActive do
                    pcall(function()
                        local spawn = Workspace:FindFirstChild("SpawnLocation") or Workspace:FindFirstChild("Spawn")
                        if spawn then
                            for i = 1, lineAmount do
                                CreateLine:FireServer(spawn, CFrame.new(math.random(-9e9, 9e9), 0, math.random(-9e9, 9e9)))
                            end
                        end
                    end)
                    task.wait(0.5)
                end
            end)
        else
            if lineLagTask then
                task.cancel(lineLagTask)
                lineLagTask = nil
            end
        end
    end
})

ServL:AddButton({
    Text = "Stop Line Lag",
    Tooltip = "Останавливает линий лаг",
    Func = function()
        lineLagActive = false
        if lineLagTask then
            task.cancel(lineLagTask)
            lineLagTask = nil
        end
        Library:Notify("Line Lag остановлен!", 2)
    end
})

-- ==============================================
-- 2. PACKET LAG
-- ==============================================

local packetLagActive = false
local packetLagTask = nil
local packetStrength = 6250

ServL:AddSlider("PacketLagStrength", {
    Text = "Packet Lag Strength",
    Default = 6250,
    Min = 100,
    Max = 6250,
    Rounding = 0,
    Tooltip = "Сила пакетного лага (чем больше, тем сильнее)",
    Callback = function(v)
        packetStrength = v
    end
})

ServL:AddButton({
    Text = "Send Packet Lag (Once)",
    Tooltip = "Отправить один большой пакет",
    Func = function()
        local ExtendGrabLine = GrabEvents and GrabEvents:FindFirstChild("ExtendGrabLine")
        if not ExtendGrabLine then
            Library:Notify("ExtendGrabLine не найден!", 3)
            return
        end
        
        pcall(function()
            ExtendGrabLine:FireServer(string.rep("😂😂😂😂🤣🤣🤣🤣", 100 * packetStrength))
            Library:Notify("Пакет отправлен! Сила: " .. packetStrength, 2)
        end)
    end
})

ServL:AddToggle("PacketLag", {
    Text = "Packet Lag (Loop)",
    Default = false,
    Tooltip = "Циклическая отправка больших пакетов",
    Callback = function(v)
        packetLagActive = v
        
        if v then
            local ExtendGrabLine = GrabEvents and GrabEvents:FindFirstChild("ExtendGrabLine")
            if not ExtendGrabLine then
                Library:Notify("ExtendGrabLine не найден!", 3)
                Toggles.PacketLag:SetValue(false)
                return
            end
            
            packetLagTask = task.spawn(function()
                while packetLagActive do
                    pcall(function()
                        ExtendGrabLine:FireServer(string.rep("😂😂😂😂🤣🤣🤣🤣", 100 * packetStrength))
                    end)
                    task.wait(1)
                end
            end)
        else
            if packetLagTask then
                task.cancel(packetLagTask)
                packetLagTask = nil
            end
        end
    end
})

-- ==============================================
-- 3. DESTROY SERVER
-- ==============================================

local selectedHeight = "Spawn"

ServR:AddDropdown("DestroyHeight", {
    Text = "Destroy Height",
    Values = {"Spawn", "Heaven"},
    Default = "Spawn",
    Tooltip = "Куда телепортировать игроков",
    Callback = function(v)
        selectedHeight = v
    end
})

local function getAllPlayers()
    local list = {}
    for _, plr in pairs(Players:GetPlayers()) do
        if plr ~= LocalPlayer then
            table.insert(list, plr)
        end
    end
    return list
end

local function spamOwnership(hrp)
    if SetNetworkOwner and hrp then
        pcall(function()
            SetNetworkOwner:FireServer(hrp, hrp.CFrame)
        end)
    end
end

local function destroyLineOnPlayer(hrp)
    if DestroyGrabLine and hrp then
        pcall(function()
            DestroyGrabLine:FireServer(hrp)
        end)
    end
end

ServR:AddButton({
    Text = "Destroy Server",
    Tooltip = "Ломает сервер (комбинация лагов + телепорт)",
    Func = function()
        Library:Notify("Запуск дестроя сервера...", 3)
        
        task.spawn(function()
            local height = (selectedHeight == "Heaven") and 1e9 or 35
            
            -- Включаем Line Lag на время дестроя
            if not lineLagActive then
                Toggles.LineLag:SetValue(true)
                task.wait(0.5)
            end
            
            local players = getAllPlayers()
            if #players == 0 then
                Library:Notify("Нет игроков для дестроя!", 3)
                return
            end
            
            local myChar = plr.Character
            local myHrp = myChar and myChar:FindFirstChild("HumanoidRootPart")
            if not myHrp then
                Library:Notify("Нет персонажа!", 3)
                return
            end
            
            local playerData = {}
            for _, plr in ipairs(players) do
                local char = plr.Character
                local hrp = char and char:FindFirstChild("HumanoidRootPart")
                if hrp then
                    table.insert(playerData, {player = plr, hrp = hrp})
                end
            end
            
            for _, data in ipairs(playerData) do
                pcall(function()
                    myHrp.CFrame = data.hrp.CFrame * CFrame.new(0, 5, 5)
                    task.wait(0.1)
                    spamOwnership(data.hrp)
                    task.wait()
                end)
            end
            
            local radius = 40
            local angleStep = (math.pi * 2) / #playerData
            for idx, data in ipairs(playerData) do
                local angle = (idx - 1) * angleStep
                local x = math.cos(angle) * radius
                local z = math.sin(angle) * radius
                
                pcall(function()
                    data.hrp.CFrame = CFrame.new(x, height, z)
                    data.hrp.AssemblyLinearVelocity = Vector3.zero
                    
                    local bp = Instance.new("BodyPosition")
                    bp.MaxForce = Vector3.new(1e9, 1e9, 1e9)
                    bp.P = 40000000
                    bp.Position = Vector3.new(x, height, z)
                    bp.Parent = data.hrp
                    task.delay(2, function() pcall(function() bp:Destroy() end) end)
                end)
                task.wait()
            end
            
            for i = 1, 8 do
                for _, data in ipairs(playerData) do
                    destroyLineOnPlayer(data.hrp)
                end
                task.wait(0.1)
            end
            
            Library:Notify("Сервер уничтожен! Игроков: " .. #playerData, 3)
            
            if lineLagActive then
                Toggles.LineLag:SetValue(false)
            end
        end)
    end
})

ServR:AddButton({
    Text = "Stop All Lags",
    Tooltip = "Останавливает все лаги",
    Func = function()
        lineLagActive = false
        if lineLagTask then
            task.cancel(lineLagTask)
            lineLagTask = nil
        end
        
        packetLagActive = false
        if packetLagTask then
            task.cancel(packetLagTask)
            packetLagTask = nil
        end
        
        if Toggles.LineLag then Toggles.LineLag:SetValue(false) end
        if Toggles.PacketLag then Toggles.PacketLag:SetValue(false) end
        
        Library:Notify("Все лаги остановлены!", 2)
    end
})

-- ==============================================
-- ВКЛАДКА SETTINGS (исправленный конец)
-- ==============================================

local SettingsSection = Tabs.Settings:AddLeftGroupbox("Menu", "wrench")

-- Menu keybind
pcall(function()
 SettingsSection:AddLabel("Menu bind")
 :AddKeyPicker("MenuKeybind", { Default = "RightShift", NoUI = true, Text = "Menu keybind" })
end)

-- Custom cursor
pcall(function()
 SettingsSection:AddToggle("ShowCustomCursor", {
 Text = "Custom Cursor",
 Default = true,
 Callback = function(Value)
 Library.ShowCustomCursor = Value
 end,
 })
end)

-- Notification side
pcall(function()
 SettingsSection:AddDropdown("NotificationSide", {
 Values = { "Left", "Right" },
 Default = "Right",
 Text = "Notification Side",
 Callback = function(Value)
 pcall(function() Library:SetNotifySide(Value) end)
 end,
 })
end)

-- DPI scale
pcall(function()
 SettingsSection:AddDropdown("DPIDropdown", {
 Values = { "50%", "75%", "100%", "125%", "150%", "175%", "200%" },
 Default = "100%",
 Text = "DPI Scale",
 Callback = function(Value)
 Value = Value:gsub("%%", "")
 pcall(function() Library:SetDPIScale(tonumber(Value)) end)
 end,
 })
end)

-- Corner radius
pcall(function()
 local defCorner = 5
 pcall(function() defCorner = Library.CornerRadius or 5 end)
 SettingsSection:AddSlider("UICornerSlider", {
 Text = "Corner Radius",
 Default = defCorner,
 Min = 0,
 Max = 20,
 Rounding = 0,
 Callback = function(value)
 pcall(function() Window:SetCornerRadius(value) end)
 end
 })
end)

-- ==============================================
-- WATERMARK (Неубираемый, перетаскиваемый)
-- ==============================================
task.spawn(function()
    -- Создаём перетаскиваемый лейбл
    local watermark = Library:AddDraggableLabel("•nLhe | 0 FPS | 0 ms")
    
    -- Делаем его НЕУБИРАЕМЫМ (прячем кнопку закрытия и отключаем возможность убрать)
    pcall(function()
        -- Пытаемся найти кнопку закрытия и скрыть её
        for _, child in pairs(watermark:GetChildren()) do
            if child:IsA("TextButton") and child.Text == "X" then
                child.Visible = false
                child.Active = false
            end
        end
    end)
    
    -- Обновляем FPS и Ping
    while task.wait(0.5) do
        local fps = math.floor(1 / RunService.RenderStepped:Wait())
        local ping = math.floor(game:GetService('Stats').Network.ServerStatsItem['Data Ping']:GetValue())
        watermark:SetText(string.format("•nLhe | %d FPS | %d ms", fps, ping))
    end
end)

SettingsSection:AddDivider()

-- Unload button
SettingsSection:AddButton({
 Text = "Unload",
 Func = function()
 if workspace.CurrentCamera then
 workspace.CurrentCamera.FieldOfView = defaultFOV
 end
 Library:Unload()
 end,
 Tooltip = "Полностью выгрузить из игры"
})

-- Назначаем бинд меню
pcall(function() Library.ToggleKeybind = Options.MenuKeybind end)

-- Отслеживание выгрузки
pcall(function()
 Library:OnUnload(function()
 if workspace.CurrentCamera then
 workspace.CurrentCamera.FieldOfView = defaultFOV
 end
 if watermarkGui then watermarkGui:Destroy() end
 end)
end)

-- ThemeManager и SaveManager
task.spawn(function()
 local t0 = tick()
 while not (themeDone and saveDone) do
 if tick() - t0 > 15 then break end
 task.wait(0.05)
 end
 pcall(function()
 ThemeManager:SetLibrary(Library)
 SaveManager:SetLibrary(Library)
 SaveManager:IgnoreThemeSettings()
 SaveManager:SetIgnoreIndexes({ "MenuKeybind" })
 ThemeManager:SetFolder("nLhe_FTAP")
 SaveManager:SetFolder("nLhe_FTAP/Configs")
 SaveManager:BuildConfigSection(Tabs.Settings)
 ThemeManager:ApplyToTab(Tabs.Settings)
 SaveManager:LoadAutoloadConfig()
 end)
end)

-- ==============================================
-- КАСТОМНЫЕ УВЕДОМЛЕНИЯ nLhe (С ЭМОДЗИ)
-- ==============================================

local function nLheNotify(title, description, duration)
    Library:Notify({
        Title = "🩸 " .. title,
        Description = description or "",
        Duration = duration or 5
    })
end

-- ==============================================
-- 1. KICK NOTIFY (Black Hole, Singularity)
-- ==============================================

task.spawn(function()
    Workspace.ChildAdded:Connect(function(obj)
        local kickObjectNames = {
            ["blackholekick"] = true,
            ["blackholekicktweens(old)"] = true,
            ["blackholekicktweens"] = true,
            ["jhole"] = true,
            ["blackhole"] = true,
            ["black_hole"] = true,
            ["voidhole"] = true,
            ["singularity"] = true,
        }
        
        if not obj.Name or not kickObjectNames[obj.Name:lower()] then return end
        
        task.wait(0.1)
        
        local pos
        if obj:IsA("BasePart") then 
            pos = obj.Position 
        else
            local part = obj:FindFirstChildWhichIsA("BasePart", true)
            if part then pos = part.Position end
        end
        
        if not pos then return end
        
        local closestPlayer = nil
        local minDistance = math.huge
        
        for _, player in pairs(Players:GetPlayers()) do
            if player ~= LocalPlayer and player.Character then
                local hrp = player.Character:FindFirstChild("HumanoidRootPart")
                if hrp then
                    local distance = (hrp.Position - pos).Magnitude
                    if distance < minDistance then
                        minDistance = distance
                        closestPlayer = player
                    end
                end
            end
        end
        
        if closestPlayer then
            nLheNotify("Kick detected", closestPlayer.Name, 5)
        end
    end)
end)

-- ==============================================
-- 2. PACKET LAG NOTIFY
-- ==============================================

task.spawn(function()
    local lastLagSource = false
    local ExtendGrabLine = ReplicatedStorage:FindFirstChild("GrabEvents") and 
                           ReplicatedStorage.GrabEvents:FindFirstChild("ExtendGrabLine")
    
    if not ExtendGrabLine then return end
    
    ExtendGrabLine.OnClientEvent:Connect(function(arg1, data)
        if typeof(data) == "string" and not lastLagSource then
            lastLagSource = true
            local StringLen = string.len(data)
            
            if StringLen > 300 then
                local SizeRounded = math.round((StringLen / (1024 * 1024)) * 1000) / 1000
                
                nLheNotify(
                    "Packet detected",
                    "Player: " .. tostring(arg1) .. "\nSize: " .. tostring(SizeRounded) .. " MB",
                    5
                )
            end
            
            task.delay(5, function()
                lastLagSource = false
            end)
        end
    end)
end)

-- ==============================================
-- 3. PLAYER LEFT
-- ==============================================

task.spawn(function()
    Players.PlayerRemoving:Connect(function(leavingPlr)
        if leavingPlr ~= LocalPlayer then
            nLheNotify("Player left", leavingPlr.Name, 4)
        end
    end)
end)

-- ==============================================
-- 4. PLAYER JOINED
-- ==============================================

task.spawn(function()
    Players.PlayerAdded:Connect(function(newPlr)
        if newPlr ~= LocalPlayer then
            task.wait(0.5)
            nLheNotify("Player joined", newPlr.Name, 4)
        end
    end)
end)

-- ==============================================
-- 5. TARGET LEFT (ДЛЯ ТВОЕГО СЕЛЕКТОРА)
-- ==============================================

task.spawn(function()
    -- Сохраняем оригинальный обработчик, если он есть
    local originalRemoving = Players.PlayerRemoving
    
    Players.PlayerRemoving:Connect(function(leavingPlr)
        if leavingPlr ~= LocalPlayer then
            -- Если это твой выбранный игрок из профиля
            if hkProfileInstance and leavingPlr == hkProfileInstance then
                nLheNotify("Target left", leavingPlr.Name .. " (" .. leavingPlr.DisplayName .. ")", 4)
            else
                nLheNotify("Player left", leavingPlr.Name, 4)
            end
        end
    end)
end)

-- ==============================================
-- 6. ПРИМЕР: ТЕСТОВАЯ КНОПКА (В НАСТРОЙКИ)
-- ==============================================

-- Если хочешь добавить тестовую кнопку в Settings:
-- SettingsSection:AddButton({
--     Text = "🩸 Test Notify",
--     Func = function()
--         nLheNotify("Test notification", "Это тестовое уведомление с эмодзи", 5)
--     end
-- })

Library:Notify("nLhe Loaded!", 3)
