-- Roblox Rivals Script with Rayfield UI
-- Features: Aimbot, Skin Changer, Chams (Highlight ESP), Fly, Triggerbot, Ragebot, and more

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
local currentCombatTarget = nil
local autoFireReleaseAt = 0
local autoFireActive = false
local RENDER_STEP_KEY = "RivalsMain"
local fovCircle = Drawing.new("Circle")
fovCircle.Visible = false
fovCircle.Color = Color3.new(1, 0, 0)
fovCircle.Thickness = 2
fovCircle.Filled = false
fovCircle.Transparency = 0.5
fovCircle.Radius = aimbotFOV

-- Chams (Highlight ESP) Variables
local espHighlights = {}
local chamsColor = Color3.fromRGB(255, 0, 0)
local chamsOutlineColor = Color3.fromRGB(255, 255, 255)
local chamsFillTransparency = 0.5

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

function getClosestTargetData()
    local closestTarget = nil
    local shortestDistance = math.huge
    local viewport = Camera.ViewportSize
    local screenCenter = Vector2.new(viewport.X / 2, viewport.Y / 2)
    
    for _, player in pairs(Players:GetPlayers()) do
        if player ~= LocalPlayer and isEnemy(player) then
            local character = player.Character
            local humanoid = character and character:FindFirstChildOfClass("Humanoid")
            local part = character and character:FindFirstChild(aimbotPart)
            local hrp = character and character:FindFirstChild("HumanoidRootPart")
            if humanoid and humanoid.Health > 0 and part and hrp then
                local screenPos, onScreen = Camera:WorldToViewportPoint(part.Position)
                local deltaX = screenPos.X - screenCenter.X
                local deltaY = screenPos.Y - screenCenter.Y
                local distance = math.sqrt(deltaX * deltaX + deltaY * deltaY)
                
                if onScreen and distance < shortestDistance and distance < aimbotFOV then
                    if not wallCheck or not isWallBetween(part) then
                        shortestDistance = distance
                        closestTarget = {
                            player = player,
                            character = character,
                            humanoid = humanoid,
                            part = part,
                            hrp = hrp,
                            screenPosition = screenPos,
                            distanceFromCrosshair = distance
                        }
                    end
                end
            end
        end
    end
    
    return closestTarget
end

function isWallBetween(target)
    if not wallCheck then return false end
    
    local origin = Camera.CFrame.Position
    local targetPos = target.Position
    local dist = (targetPos - origin).Magnitude
    if dist < 1 then return false end

    local raycastParams = RaycastParams.new()
    local excluded = {}
    for _, player in pairs(Players:GetPlayers()) do
        if player.Character then
            table.insert(excluded, player.Character)
        end
    end
    raycastParams.FilterDescendantsInstances = excluded
    raycastParams.FilterType = Enum.RaycastFilterType.Exclude
    -- Cast ray to just before the target so only map geometry counts as a wall
    local result = workspace:Raycast(origin, (targetPos - origin).Unit * (dist * 0.99), raycastParams)

    return result ~= nil
end

function aimbot(targetData)
    if not aimbotEnabled then return end

    targetData = targetData or currentCombatTarget
    if not targetData then return end
    local targetPart = targetData.part

    -- Velocity-based prediction for leading the target
    local velocity = targetData.hrp and targetData.hrp.AssemblyLinearVelocity or Vector3.new()
    local dist = (Camera.CFrame.Position - targetPart.Position).Magnitude
    local predTime = dist / 800
    local predicted = targetPart.Position + velocity * predTime

    -- Smoothly rotate the camera toward the predicted position
    local goalCF = CFrame.new(Camera.CFrame.Position, predicted)
    Camera.CFrame = Camera.CFrame:Lerp(goalCF, aimbotSmoothness)
end

function silentAim(targetData)
    if not silentAimEnabled then return end
    
    targetData = targetData or currentCombatTarget
    if targetData then
        local targetPart = targetData.part
        local targetPos = Camera:WorldToScreenPoint(targetPart.Position)
        
        if targetPos.Z > 0 then
            -- Modify the CFrame of the camera to aim at the target without moving the mouse
            local currentCFrame = Camera.CFrame
            local lookAt = CFrame.new(currentCFrame.Position, targetPart.Position)
            Camera.CFrame = currentCFrame:Lerp(lookAt, aimbotSmoothness)
        end
    end
end

function requestAutoFire(delay)
    local now = tick()
    if autoFireActive then return false end

    mouse1press()
    autoFireActive = true
    autoFireReleaseAt = now + delay
    return true
end

function updateAutoFire()
    if autoFireActive and tick() >= autoFireReleaseAt then
        mouse1release()
        autoFireActive = false
    end
end

function triggerbot(targetData)
    if not triggerbotEnabled then return end
    
    targetData = targetData or currentCombatTarget
    if targetData then
        local targetPos = targetData.screenPosition
        
        if targetPos.Z > 0 then
            local mousePos = UserInputService:GetMouseLocation()
            local distance = (Vector2.new(targetPos.X, targetPos.Y) - mousePos).Magnitude
            
            if distance < 50 then
                requestAutoFire(triggerbotDelay)
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

function ragebot(targetData)
    if not ragebotEnabled then return end
    
    targetData = targetData or currentCombatTarget
    if targetData then
        local targetPart = targetData.part
        
        -- Instant aim at target
        local lookAt = CFrame.new(Camera.CFrame.Position, targetPart.Position)
        Camera.CFrame = lookAt
        
        -- Auto shoot
        requestAutoFire(ragebotDelay)
    end
end

function createESP(player)
    if espHighlights[player] then return end

    local highlight = Instance.new("Highlight")
    highlight.FillColor = chamsColor
    highlight.OutlineColor = chamsOutlineColor
    highlight.FillTransparency = chamsFillTransparency
    highlight.OutlineTransparency = 0
    highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
    highlight.Enabled = false

    espHighlights[player] = highlight
end

function updateESP()
    if not espEnabled then
        for _, highlight in pairs(espHighlights) do highlight.Enabled = false end
        return
    end

    for _, player in pairs(Players:GetPlayers()) do
        if player ~= LocalPlayer and isEnemy(player) then
            local character = player.Character
            if character and character:FindFirstChild("HumanoidRootPart") then
                local humanoid = character:FindFirstChildOfClass("Humanoid")
                if humanoid and humanoid.Health > 0 then
                    createESP(player)

                    local highlight = espHighlights[player]
                    -- Re-parent highlight into the character whenever it respawns
                    if highlight.Parent ~= character then
                        highlight.Parent = character
                    end
                    highlight.FillColor = chamsColor
                    highlight.OutlineColor = chamsOutlineColor
                    highlight.FillTransparency = chamsFillTransparency
                    highlight.Enabled = true
                else
                    if espHighlights[player] then espHighlights[player].Enabled = false end
                end
            else
                if espHighlights[player] then espHighlights[player].Enabled = false end
            end
        end
    end

    -- Clean up ESP for players who left
    for player, _ in pairs(espHighlights) do
        if not Players:FindFirstChild(player.Name) then
            espHighlights[player]:Destroy()
            espHighlights[player] = nil
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

-- AI Detection Functions
function initializeAIModel()
    -- Mark AI as ready; actual detection uses direct game data
    aiModel = true
    return aiModel
end

function aiAimbot()
    if not aiDetectionEnabled then return end

    local viewport = Camera.ViewportSize
    local center = Vector2.new(viewport.X / 2, viewport.Y / 2)
    local bestTarget = nil
    local bestScore = -math.huge

    for _, player in pairs(Players:GetPlayers()) do
        if player ~= LocalPlayer and isEnemy(player) then
            local character = player.Character
            if character then
                local humanoid = character:FindFirstChildOfClass("Humanoid")
                local head = character:FindFirstChild("Head")
                local hrp = character:FindFirstChild("HumanoidRootPart")

                if humanoid and humanoid.Health > 0 and head and hrp then
                    local screenPos, onScreen = Camera:WorldToViewportPoint(head.Position)

                    if onScreen and screenPos.Z > 0 then
                        local distFromCenter = (Vector2.new(screenPos.X, screenPos.Y) - center).Magnitude

                        if distFromCenter < aimbotFOV and not isWallBetween(head) then
                            -- Priority: closer to crosshair (70%) + lower health (30%)
                            local angleScore = 1 - (distFromCenter / aimbotFOV)
                            local healthScore = 1 - (humanoid.Health / humanoid.MaxHealth)
                            local score = angleScore * 0.7 + healthScore * 0.3

                            if score > bestScore then
                                bestScore = score
                                bestTarget = {head = head, hrp = hrp}
                            end
                        end
                    end
                end
            end
        end
    end

    if bestTarget then
        local velocity = bestTarget.hrp.AssemblyLinearVelocity
        local dist = (Camera.CFrame.Position - bestTarget.head.Position).Magnitude
        local predTime = dist / 800
        local predicted = bestTarget.head.Position + velocity * predTime

        local goalCF = CFrame.new(Camera.CFrame.Position, predicted)
        Camera.CFrame = Camera.CFrame:Lerp(goalCF, aimbotSmoothness)
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

VisualTab:CreateSection("Chams")
VisualTab:CreateToggle({
    Name = "Enable Chams",
    CurrentValue = false,
    Flag = "ESP",
    Callback = function(Value)
        espEnabled = Value
        if not Value then
            for _, highlight in pairs(espHighlights) do highlight.Enabled = false end
        end
    end
})

VisualTab:CreateColorPicker({
    Name = "Chams Fill Color",
    Color = Color3.fromRGB(255, 0, 0),
    Flag = "ChamsFillColor",
    Callback = function(Value)
        chamsColor = Value
    end
})

VisualTab:CreateColorPicker({
    Name = "Chams Outline Color",
    Color = Color3.fromRGB(255, 255, 255),
    Flag = "ChamsOutlineColor",
    Callback = function(Value)
        chamsOutlineColor = Value
    end
})

VisualTab:CreateSlider({
    Name = "Chams Fill Transparency",
    Range = {0, 1},
    Increment = 0.05,
    Suffix = "",
    CurrentValue = 0.5,
    Flag = "ChamsFillTransparency",
    Callback = function(Value)
        chamsFillTransparency = Value
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
        if Value then
            initializeAIModel()
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
        local viewport = Camera.ViewportSize
        fovCircle.Position = Vector2.new(viewport.X / 2, viewport.Y / 2)
    end
end)

-- Main Update Loop (runs after the game's camera script to ensure our CFrame changes persist)
RunService:BindToRenderStep(RENDER_STEP_KEY, Enum.RenderPriority.Camera.Value + 1, function()
    currentCombatTarget = nil
    if aimbotEnabled or silentAimEnabled or triggerbotEnabled or ragebotEnabled then
        currentCombatTarget = getClosestTargetData()
    end

    updateAutoFire()
    aimbot(currentCombatTarget)
    silentAim(currentCombatTarget)
    triggerbot(currentCombatTarget)
    fly()
    ragebot(currentCombatTarget)
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
    if espHighlights[player] then
        espHighlights[player]:Destroy()
        espHighlights[player] = nil
    end
end)

-- Initialize
print("Roblox Rivals Script loaded successfully!")
print("Features: Aimbot, Silent Aim, Triggerbot, Ragebot, Chams (Highlight ESP), Skin Changer, Fly, AI Detection")
