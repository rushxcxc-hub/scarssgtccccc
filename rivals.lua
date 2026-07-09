-- Roblox Rivals Script with Rayfield UI
-- Features: Aimbot, Skin Changer, ESP, Fly, Triggerbot, Ragebot, and more

local Rayfield = loadstring(game:HttpGet('https://sirius.menu/rayfield'))()
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local Camera = workspace.CurrentCamera
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local HttpService = game:GetService("HttpService")
local TweenService = game:GetService("TweenService")

-- Variables
local aimbotEnabled = false
local silentAimEnabled = false
local triggerbotEnabled = false
local flyEnabled = false
local ragebotEnabled = false
local espEnabled = false
local skinChangerEnabled = false
local aimbotFOV = 100
local aimbotSmoothness = 0.2
local aimbotPart = "Head"
local triggerbotDelay = 0.1
local flySpeed = 50
local ragebotDelay = 0.05
local wallCheck = true
local teamCheck = false
local fovCircle = Drawing.new("Circle")
fovCircle.Visible = false
fovCircle.Color = Color3.new(1, 0, 0)
fovCircle.Thickness = 2
fovCircle.Filled = false
fovCircle.Transparency = 0.5
fovCircle.Radius = aimbotFOV

-- ESP Variables
local espBoxes = {}
local espTracers = {}
local espNames = {}

-- Skin Changer Variables
local allSkins = {}
local equippedSkins = {}

-- AI Detection Variables
local aiDetectionEnabled = false
local aiConfidence = 0.7
local aiModel = nil

-- Functions
function isEnemy(player)
    if not teamCheck then return true end
    -- If either player has no team assigned, treat as enemy (cannot determine affiliation)
    if LocalPlayer.Team == nil or player.Team == nil then return true end
    return player.Team ~= LocalPlayer.Team
end

function getClosestPlayer()
    local closestPlayer = nil
    local shortestDistance = math.huge
    
    for _, player in pairs(Players:GetPlayers()) do
        if player ~= LocalPlayer and isEnemy(player) then
            local character = player.Character
            if character and character:FindFirstChild(aimbotPart) then
                local part = character[aimbotPart]
                local screenPos, onScreen = Camera:WorldToScreenPoint(part.Position)
                local distance = (Vector2.new(screenPos.X, screenPos.Y) - Vector2.new(Camera.ViewportSize.X/2, Camera.ViewportSize.Y/2)).Magnitude
                
                if onScreen and distance < shortestDistance and distance < aimbotFOV then
                    if not wallCheck or not isWallBetween(part) then
                        shortestDistance = distance
                        closestPlayer = player
                    end
                end
            end
        end
    end
    
    return closestPlayer
end

function isWallBetween(target)
    if not wallCheck then return false end
    
    local character = LocalPlayer.Character
    if not character or not character:FindFirstChild("HumanoidRootPart") then return false end
    
    local origin = Camera.CFrame.Position
    local direction = (target.Position - origin).Unit * 1000
    
    local raycastParams = RaycastParams.new()
    raycastParams.FilterDescendantsInstances = {character}
    raycastParams.FilterType = Enum.RaycastFilterType.Exclude
    local result = workspace:Raycast(origin, direction, raycastParams)
    
    if result then
        if result.Instance:IsDescendantOf(target.Parent) then
            return false
        end
        return true
    end
    
    return false
end

function aimbot()
    if not aimbotEnabled then return end
    
    local closestPlayer = getClosestPlayer()
    if closestPlayer and closestPlayer.Character and closestPlayer.Character:FindFirstChild(aimbotPart) then
        local targetPart = closestPlayer.Character[aimbotPart]
        local targetPos = Camera:WorldToScreenPoint(targetPart.Position)
        
        if targetPos.Z > 0 then
            local mousePos = UserInputService:GetMouseLocation()
            local targetX = targetPos.X - mousePos.X
            local targetY = targetPos.Y - mousePos.Y
            
            mousemoverel(targetX * aimbotSmoothness, targetY * aimbotSmoothness)
        end
    end
end

function silentAim()
    if not silentAimEnabled then return end
    
    local closestPlayer = getClosestPlayer()
    if closestPlayer and closestPlayer.Character and closestPlayer.Character:FindFirstChild(aimbotPart) then
        local targetPart = closestPlayer.Character[aimbotPart]
        local targetPos = Camera:WorldToScreenPoint(targetPart.Position)
        
        if targetPos.Z > 0 then
            -- Modify the CFrame of the camera to aim at the target without moving the mouse
            local currentCFrame = Camera.CFrame
            local lookAt = CFrame.new(currentCFrame.Position, targetPart.Position)
            Camera.CFrame = currentCFrame:Lerp(lookAt, aimbotSmoothness)
        end
    end
end

function triggerbot()
    if not triggerbotEnabled then return end
    
    local closestPlayer = getClosestPlayer()
    
    if closestPlayer and closestPlayer.Character and closestPlayer.Character:FindFirstChild(aimbotPart) then
        local targetPart = closestPlayer.Character[aimbotPart]
        local targetPos = Camera:WorldToScreenPoint(targetPart.Position)
        
        if targetPos.Z > 0 then
            local mousePos = UserInputService:GetMouseLocation()
            local distance = (Vector2.new(targetPos.X, targetPos.Y) - mousePos).Magnitude
            
            if distance < 50 then
                mouse1press()
                wait(triggerbotDelay)
                mouse1release()
            end
        end
    end
end

function fly()
    if not flyEnabled then return end
    
    local character = LocalPlayer.Character
    if not character or not character:FindFirstChild("HumanoidRootPart") then return end
    
    local humanoid = character:FindFirstChildOfClass("Humanoid")
    if not humanoid then return end
    
    humanoid:ChangeState("Freefall")
    
    local velocity = Instance.new("BodyVelocity")
    velocity.MaxForce = Vector3.new(math.huge, math.huge, math.huge)
    velocity.Velocity = Vector3.new(0, 0, 0)
    velocity.Parent = character.HumanoidRootPart
    
    local moveDirection = humanoid.MoveDirection * flySpeed
    
    if UserInputService:IsKeyDown(Enum.KeyCode.Space) then
        velocity.Velocity = Vector3.new(moveDirection.X, flySpeed, moveDirection.Z)
    elseif UserInputService:IsKeyDown(Enum.KeyCode.LeftControl) then
        velocity.Velocity = Vector3.new(moveDirection.X, -flySpeed, moveDirection.Z)
    else
        velocity.Velocity = Vector3.new(moveDirection.X, 0, moveDirection.Z)
    end
    
    game:GetService("Debris"):AddItem(velocity, 0.1)
end

function ragebot()
    if not ragebotEnabled then return end
    
    local closestPlayer = getClosestPlayer()
    if closestPlayer and closestPlayer.Character and closestPlayer.Character:FindFirstChild(aimbotPart) then
        local targetPart = closestPlayer.Character[aimbotPart]
        
        -- Instant aim at target
        local lookAt = CFrame.new(Camera.CFrame.Position, targetPart.Position)
        Camera.CFrame = lookAt
        
        -- Auto shoot
        mouse1press()
        wait(ragebotDelay)
        mouse1release()
    end
end

function createESP(player)
    if espBoxes[player] then return end
    
    local box = Drawing.new("Square")
    box.Color = Color3.new(1, 0, 0)
    box.Thickness = 1
    box.Transparency = 0.5
    box.Visible = false
    
    local tracer = Drawing.new("Line")
    tracer.Color = Color3.new(1, 0, 0)
    tracer.Thickness = 1
    tracer.Transparency = 0.5
    tracer.Visible = false
    
    local name = Drawing.new("Text")
    name.Color = Color3.new(1, 1, 1)
    name.Size = 14
    name.Center = true
    name.Visible = false
    
    espBoxes[player] = box
    espTracers[player] = tracer
    espNames[player] = name
end

function updateESP()
    if not espEnabled then
        for _, box in pairs(espBoxes) do box.Visible = false end
        for _, tracer in pairs(espTracers) do tracer.Visible = false end
        for _, name in pairs(espNames) do name.Visible = false end
        return
    end
    
    for _, player in pairs(Players:GetPlayers()) do
        if player ~= LocalPlayer and isEnemy(player) then
            local character = player.Character
            if character and character:FindFirstChild("HumanoidRootPart") then
                local humanoid = character:FindFirstChildOfClass("Humanoid")
                if humanoid and humanoid.Health > 0 then
                    createESP(player)
                    
                    local bbCF, size = character:GetBoundingBox()
                    local center = bbCF.Position
                    local pos, onScreen = Camera:WorldToScreenPoint(center)
                    
                    if onScreen then
                        local box = espBoxes[player]
                        local tracer = espTracers[player]
                        local name = espNames[player]
                        
                        -- Update box
                        local top = Camera:WorldToScreenPoint(center + Vector3.new(0, size.Y/2, 0))
                        local bottom = Camera:WorldToScreenPoint(center - Vector3.new(0, size.Y/2, 0))
                        local height = bottom.Y - top.Y
                        local width = height * (size.X / size.Y)
                        
                        box.Size = Vector2.new(width, height)
                        box.Position = Vector2.new(pos.X - width/2, top.Y)
                        box.Visible = true
                        
                        -- Update tracer
                        tracer.From = Vector2.new(Camera.ViewportSize.X/2, Camera.ViewportSize.Y)
                        tracer.To = Vector2.new(bottom.X, bottom.Y)
                        tracer.Visible = true
                        
                        -- Update name
                        name.Text = player.Name .. " [" .. math.floor(humanoid.Health) .. "/" .. humanoid.MaxHealth .. "]"
                        name.Position = Vector2.new(pos.X, top.Y - 15)
                        name.Visible = true
                    else
                        espBoxes[player].Visible = false
                        espTracers[player].Visible = false
                        espNames[player].Visible = false
                    end
                else
                    if espBoxes[player] then espBoxes[player].Visible = false end
                    if espTracers[player] then espTracers[player].Visible = false end
                    if espNames[player] then espNames[player].Visible = false end
                end
            else
                if espBoxes[player] then espBoxes[player].Visible = false end
                if espTracers[player] then espTracers[player].Visible = false end
                if espNames[player] then espNames[player].Visible = false end
            end
        end
    end
    
    -- Clean up ESP for players who left
    for player, _ in pairs(espBoxes) do
        if not Players:FindFirstChild(player.Name) then
            espBoxes[player]:Remove()
            espTracers[player]:Remove()
            espNames[player]:Remove()
            espBoxes[player] = nil
            espTracers[player] = nil
            espNames[player] = nil
        end
    end
end

-- Skin Changer Functions
function getAllSkins()
    -- This would need to be customized based on the specific game's skin system
    -- For now, we'll create a placeholder function
    
    -- Try to find skin containers in the game
    local skinContainers = {}
    allSkins = {}
    
    -- Check player backpack for skins
    local backpack = LocalPlayer:FindFirstChild("Backpack")
    if backpack then
        for _, item in pairs(backpack:GetChildren()) do
            if item:FindFirstChild("SkinId") or item.Name:find("Skin") then
                table.insert(skinContainers, item)
            end
        end
    end
    
    -- Check player character for equipped skins
    local character = LocalPlayer.Character
    if character then
        for _, item in pairs(character:GetChildren()) do
            if item:FindFirstChild("SkinId") or item.Name:find("Skin") then
                table.insert(skinContainers, item)
            end
        end
    end
    
    -- Check game UI for skin options
    local playerGui = LocalPlayer:FindFirstChild("PlayerGui")
    if playerGui then
        for _, gui in pairs(playerGui:GetChildren()) do
            if gui.Name:find("Shop") or gui.Name:find("Inventory") or gui.Name:find("Skin") then
                for _, item in pairs(gui:GetDescendants()) do
                    if item:IsA("ImageButton") or item:IsA("ImageLabel") then
                        table.insert(allSkins, {
                            Name = item.Name,
                            Image = item.Image,
                            Object = item
                        })
                    end
                end
            end
        end
    end
    
    return allSkins
end

function unlockAllSkins()
    -- Ensure skins list is populated before attempting to unlock
    allSkins = getAllSkins()
    
    -- Try to find and modify skin ownership data
    local playerData = LocalPlayer:FindFirstChild("Data") or LocalPlayer:FindFirstChild("PlayerData")
    if playerData then
        for _, dataValue in pairs(playerData:GetChildren()) do
            if dataValue.Name:find("Skin") or dataValue.Name:find("Owned") then
                dataValue.Value = true
            end
        end
    end
    
    -- Try to find and modify skin purchase functions (search all descendants)
    local replicatedStorage = game:GetService("ReplicatedStorage")
    for _, remote in pairs(replicatedStorage:GetDescendants()) do
        if remote:IsA("RemoteEvent") or remote:IsA("RemoteFunction") then
            if remote.Name:find("Buy") or remote.Name:find("Purchase") or remote.Name:find("Unlock") then
                -- Try to call the remote with skin data
                for _, skin in pairs(allSkins) do
                    pcall(function()
                        if remote:IsA("RemoteEvent") then
                            remote:FireServer(skin.Name)
                        else
                            remote:InvokeServer(skin.Name)
                        end
                    end)
                end
            end
        end
    end
end

function changeSkin(skinName)
    -- This would need to be customized based on the specific game's skin system
    -- For now, we'll create a placeholder function
    
    local character = LocalPlayer.Character
    if not character then return end
    
    -- Try to find skin-related remotes
    local replicatedStorage = game:GetService("ReplicatedStorage")
    for _, remote in pairs(replicatedStorage:GetChildren()) do
        if remote:IsA("RemoteEvent") or remote:IsA("RemoteFunction") then
            if remote.Name:find("Equip") or remote.Name:find("Set") or remote.Name:find("Change") then
                pcall(function()
                    if remote:IsA("RemoteEvent") then
                        remote:FireServer(skinName)
                    else
                        remote:InvokeServer(skinName)
                    end
                end)
            end
        end
    end
    
    -- Try to directly modify character appearance
    for _, part in pairs(character:GetChildren()) do
        if part:IsA("MeshPart") or part:IsA("Part") then
            for _, skin in pairs(allSkins) do
                if skin.Name == skinName then
                    if part:FindFirstChild("MeshId") then
                        part.MeshId = skin.Image
                    end
                    if part:FindFirstChild("TextureID") then
                        part.TextureID = skin.Image
                    end
                end
            end
        end
    end
end

-- AI Detection Functions (YOLO-like implementation)
function initializeAIModel()
    -- This is a simplified version of YOLO-like detection
    -- In a real implementation, you would load a trained model
    
    -- For demonstration, we'll create a simple detection function
    aiModel = {
        Detect = function(image)
            -- This would normally use a neural network to detect players
            -- For now, we'll return placeholder results
            
            local detections = {}
            
            -- Check for players in the game
            for _, player in pairs(Players:GetPlayers()) do
                if player ~= LocalPlayer and isEnemy(player) then
                    local character = player.Character
                    if character and character:FindFirstChild("HumanoidRootPart") then
                        local humanoid = character:FindFirstChildOfClass("Humanoid")
                        if humanoid and humanoid.Health > 0 then
                            local rootPart = character.HumanoidRootPart
                            local pos, onScreen = Camera:WorldToScreenPoint(rootPart.Position)
                            
                            if onScreen then
                                table.insert(detections, {
                                    Class = "Player",
                                    Confidence = 0.9,
                                    Box = {
                                        X = pos.X - 50,
                                        Y = pos.Y - 100,
                                        Width = 100,
                                        Height = 200
                                    },
                                    Player = player
                                })
                            end
                        end
                    end
                end
            end
            
            return detections
        end
    }
    
    return aiModel
end

function aiAimbot()
    if not aiDetectionEnabled or not aiModel then return end
    
    -- Get current viewport as image data (simplified)
    local viewport = Camera.ViewportSize
    local imageData = {
        Width = viewport.X,
        Height = viewport.Y
    }
    
    -- Use AI model to detect players
    local detections = aiModel:Detect(imageData)
    
    -- Find the best target
    local bestTarget = nil
    local bestScore = 0
    
    for _, detection in pairs(detections) do
        if detection.Class == "Player" and detection.Confidence >= aiConfidence then
            local box = detection.Box
            local centerX = box.X + box.Width / 2
            local centerY = box.Y + box.Height / 2
            
            local distance = math.sqrt(
                math.pow(centerX - viewport.X/2, 2) + 
                math.pow(centerY - viewport.Y/2, 2)
            )
            
            -- Score based on confidence and distance
            local score = detection.Confidence * (1 - distance / math.max(viewport.X, viewport.Y))
            
            if score > bestScore then
                bestScore = score
                bestTarget = detection
            end
        end
    end
    
    -- Aim at the best target
    if bestTarget then
        local box = bestTarget.Box
        local centerX = box.X + box.Width / 2
        local centerY = box.Y + box.Height / 2
        
        local mousePos = UserInputService:GetMouseLocation()
        local targetX = centerX - mousePos.X
        local targetY = centerY - mousePos.Y
        
        mousemoverel(targetX * aimbotSmoothness, targetY * aimbotSmoothness)
    end
end

-- Create UI
local Window = Rayfield:CreateWindow({
    Name = "Roblox Rivals Script",
    LoadingTitle = "Loading Script",
    LoadingSubtitle = "by Venice",
    ConfigurationSaving = {
        Enabled = true,
        FolderName = "RobloxRivals",
        FileName = "ScriptConfig"
    }
})

-- Combat Tab
local CombatTab = Window:CreateTab("Combat", 4483362458)

CombatTab:CreateSection("Aimbot")
CombatTab:CreateToggle({
    Name = "Enable Aimbot",
    CurrentValue = false,
    Flag = "Aimbot",
    Callback = function(Value)
        aimbotEnabled = Value
        fovCircle.Visible = Value
    end
})

CombatTab:CreateSlider({
    Name = "Aimbot FOV",
    Range = {1, 500},
    Increment = 1,
    Suffix = "°",
    CurrentValue = 100,
    Flag = "AimbotFOV",
    Callback = function(Value)
        aimbotFOV = Value
        fovCircle.Radius = Value
    end
})

CombatTab:CreateSlider({
    Name = "Aimbot Smoothness",
    Range = {0.05, 1},
    Increment = 0.05,
    Suffix = "",
    CurrentValue = 0.2,
    Flag = "AimbotSmoothness",
    Callback = function(Value)
        aimbotSmoothness = Value
    end
})

CombatTab:CreateDropdown({
    Name = "Aim Part",
    Options = {"Head", "UpperTorso", "HumanoidRootPart", "LowerTorso"},
    CurrentOption = "Head",
    Flag = "AimPart",
    Callback = function(Value)
        aimbotPart = Value
    end
})

CombatTab:CreateSection("Silent Aim")
CombatTab:CreateToggle({
    Name = "Enable Silent Aim",
    CurrentValue = false,
    Flag = "SilentAim",
    Callback = function(Value)
        silentAimEnabled = Value
    end
})

CombatTab:CreateSection("Triggerbot")
CombatTab:CreateToggle({
    Name = "Enable Triggerbot",
    CurrentValue = false,
    Flag = "Triggerbot",
    Callback = function(Value)
        triggerbotEnabled = Value
    end
})

CombatTab:CreateSlider({
    Name = "Triggerbot Delay",
    Range = {0.01, 0.5},
    Increment = 0.01,
    Suffix = "s",
    CurrentValue = 0.1,
    Flag = "TriggerbotDelay",
    Callback = function(Value)
        triggerbotDelay = Value
    end
})

CombatTab:CreateSection("Ragebot")
CombatTab:CreateToggle({
    Name = "Enable Ragebot",
    CurrentValue = false,
    Flag = "Ragebot",
    Callback = function(Value)
        ragebotEnabled = Value
    end
})

CombatTab:CreateSlider({
    Name = "Ragebot Delay",
    Range = {0.01, 0.5},
    Increment = 0.01,
    Suffix = "s",
    CurrentValue = 0.05,
    Flag = "RagebotDelay",
    Callback = function(Value)
        ragebotDelay = Value
    end
})

-- Visual Tab
local VisualTab = Window:CreateTab("Visual", 4483362458)

VisualTab:CreateSection("ESP")
VisualTab:CreateToggle({
    Name = "Enable ESP",
    CurrentValue = false,
    Flag = "ESP",
    Callback = function(Value)
        espEnabled = Value
    end
})

VisualTab:CreateSection("Skin Changer")
VisualTab:CreateToggle({
    Name = "Enable Skin Changer",
    CurrentValue = false,
    Flag = "SkinChanger",
    Callback = function(Value)
        skinChangerEnabled = Value
        if Value then
            allSkins = getAllSkins()
        end
    end
})

VisualTab:CreateButton({
    Name = "Unlock All Skins",
    Callback = function()
        unlockAllSkins()
    end
})

VisualTab:CreateDropdown({
    Name = "Select Skin",
    Options = {"Default", "Skin 1", "Skin 2", "Skin 3", "Skin 4", "Skin 5"},
    CurrentOption = "Default",
    Flag = "SelectedSkin",
    Callback = function(Value)
        if skinChangerEnabled then
            changeSkin(Value)
        end
    end
})

-- Movement Tab
local MovementTab = Window:CreateTab("Movement", 4483362458)

MovementTab:CreateSection("Fly")
MovementTab:CreateToggle({
    Name = "Enable Fly",
    CurrentValue = false,
    Flag = "Fly",
    Callback = function(Value)
        flyEnabled = Value
    end
})

MovementTab:CreateSlider({
    Name = "Fly Speed",
    Range = {10, 200},
    Increment = 5,
    Suffix = " studs/s",
    CurrentValue = 50,
    Flag = "FlySpeed",
    Callback = function(Value)
        flySpeed = Value
    end
})

-- AI Tab
local AITab = Window:CreateTab("AI", 4483362458)

AITab:CreateSection("AI Detection")
AITab:CreateToggle({
    Name = "Enable AI Detection",
    CurrentValue = false,
    Flag = "AIDetection",
    Callback = function(Value)
        aiDetectionEnabled = Value
        if Value and not aiModel then
            aiModel = initializeAIModel()
        end
    end
})

AITab:CreateSlider({
    Name = "AI Confidence Threshold",
    Range = {0.1, 1},
    Increment = 0.05,
    Suffix = "",
    CurrentValue = 0.7,
    Flag = "AIConfidence",
    Callback = function(Value)
        aiConfidence = Value
    end
})

-- Settings Tab
local SettingsTab = Window:CreateTab("Settings", 4483362458)

SettingsTab:CreateSection("General")
SettingsTab:CreateToggle({
    Name = "Wall Check",
    CurrentValue = true,
    Flag = "WallCheck",
    Callback = function(Value)
        wallCheck = Value
    end
})

SettingsTab:CreateToggle({
    Name = "Team Check",
    CurrentValue = false,
    Flag = "TeamCheck",
    Callback = function(Value)
        teamCheck = Value
    end
})

SettingsTab:CreateButton({
    Name = "Destroy Script",
    Callback = function()
        Rayfield:Destroy()
    end
})

-- Update FOV Circle
RunService.Heartbeat:Connect(function()
    if aimbotEnabled then
        fovCircle.Position = UserInputService:GetMouseLocation()
    end
end)

-- Main Update Loop
RunService.RenderStepped:Connect(function()
    aimbot()
    silentAim()
    triggerbot()
    fly()
    ragebot()
    updateESP()
    
    if aiDetectionEnabled then
        aiAimbot()
    end
end)

-- Player Added/Removed Events
Players.PlayerAdded:Connect(function(player)
    if espEnabled then
        createESP(player)
    end
end)

Players.PlayerRemoving:Connect(function(player)
    if espBoxes[player] then
        espBoxes[player]:Remove()
        espTracers[player]:Remove()
        espNames[player]:Remove()
        espBoxes[player] = nil
        espTracers[player] = nil
        espNames[player] = nil
    end
end)

-- Initialize
print("Roblox Rivals Script loaded successfully!")
print("Features: Aimbot, Silent Aim, Triggerbot, Ragebot, ESP, Skin Changer, Fly, AI Detection")
