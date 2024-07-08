local ScreenGui = Instance.new("ScreenGui")
local MobileButton = Instance.new("TextButton")
local PCButton = Instance.new("TextButton")
local InfoLabel = Instance.new("TextLabel")
local AimLockButton = Instance.new("TextButton")
local player = game.Players.LocalPlayer
local aiming = false
local aimingLoop
local updateLoop
local lockedTarget = nil
local bindKey = nil

ScreenGui.Name = "AimLockGui"
ScreenGui.Parent = game.CoreGui

InfoLabel.Name = "InfoLabel"
InfoLabel.Size = UDim2.new(0, 130, 0, 25)
InfoLabel.Position = UDim2.new(0.80, 0, -0.01, 0)
InfoLabel.BackgroundColor3 = Color3.new(0, 0, 0)
InfoLabel.TextColor3 = Color3.new(1, 1, 1)
InfoLabel.Font = Enum.Font.GothamBold
InfoLabel.TextScaled = true
InfoLabel.Parent = ScreenGui

MobileButton.Name = "MobileButton"
MobileButton.Size = UDim2.new(0, 300, 0, 150)  -- Увеличен размер кнопки
MobileButton.Position = UDim2.new(0.35, 0, 0.35, 0)
MobileButton.BackgroundColor3 = Color3.new(0, 0, 0)
MobileButton.TextColor3 = Color3.new(1, 1, 1)
MobileButton.Font = Enum.Font.GothamBold
MobileButton.Text = "Mobile"
MobileButton.TextScaled = true
MobileButton.Parent = ScreenGui

PCButton.Name = "PCButton"
PCButton.Size = UDim2.new(0, 300, 0, 150)  -- Увеличен размер кнопки
PCButton.Position = UDim2.new(0.55, 0, 0.35, 0)
PCButton.BackgroundColor3 = Color3.new(0, 0, 0)
PCButton.TextColor3 = Color3.new(1, 1, 1)
PCButton.Font = Enum.Font.GothamBold
PCButton.Text = "PC"
PCButton.TextScaled = true
PCButton.Parent = ScreenGui

AimLockButton.Name = "AimLockButton"
AimLockButton.Size = UDim2.new(0, 50, 0, 50)
AimLockButton.Position = UDim2.new(0.85, 0, 0.08, 0)
AimLockButton.BackgroundColor3 = Color3.new(0, 0, 0)
AimLockButton.TextColor3 = Color3.new(1, 0, 0)
AimLockButton.Font = Enum.Font.GothamBold
AimLockButton.Text = "AL"
AimLockButton.TextScaled = true

local UICorner = Instance.new("UICorner")
UICorner.CornerRadius = UDim.new(0, 5)
UICorner.Parent = AimLockButton

local function getNearestPlayerToCrosshair()
    local nearestPlayer = nil
    local shortestDistance = math.huge
    local camera = workspace.CurrentCamera

    for _, target in ipairs(game.Players:GetPlayers()) do
        if target ~= player and target.Character and target.Character:FindFirstChild("Head") then
            local screenPos, onScreen = camera:WorldToScreenPoint(target.Character.Head.Position)
            if onScreen then
                local mousePos = Vector2.new(camera.ViewportSize.X / 2, camera.ViewportSize.Y / 2)
                local distance = (Vector2.new(screenPos.X, screenPos.Y) - mousePos).magnitude
                if distance < shortestDistance then
                    shortestDistance = distance
                    nearestPlayer = target
                end
            end
        end
    end

    return nearestPlayer, shortestDistance
end

local function predictTargetPosition(target)
    if target and target.Character and target.Character:FindFirstChild("Head") then
        local head = target.Character.Head
        local velocity = head.Velocity
        local predictionTime = 0.1  -- Adjust this value to change prediction accuracy
        return head.Position + velocity * predictionTime
    end
    return nil
end

local function lookAtLockedTarget()
    if lockedTarget and lockedTarget.Character and lockedTarget.Character:FindFirstChild("Head") then
        local targetPos = predictTargetPosition(lockedTarget) or (lockedTarget.Character.Head.Position + Vector3.new(0, 1, 0))
        local playerPos = player.Character.HumanoidRootPart.Position
        local lookVector = (targetPos - playerPos).unit

        player.Character.HumanoidRootPart.CFrame = CFrame.new(playerPos, playerPos + lookVector)
        workspace.CurrentCamera.CFrame = CFrame.new(workspace.CurrentCamera.CFrame.Position, targetPos)
    end
end

local function toggleAiming()
    aiming = not aiming
    if not bindKey then
        AimLockButton.TextColor3 = aiming and Color3.new(0, 1, 0) or Color3.new(1, 0, 0)
    end

    if aiming then
        lockedTarget, distance = getNearestPlayerToCrosshair()
        if lockedTarget then
            InfoLabel.Text = "NP: " .. lockedTarget.Name .. " [" .. math.floor(distance) .. "]"
        else
            InfoLabel.Text = "NP: None"
        end
        aimingLoop = game:GetService("RunService").RenderStepped:Connect(lookAtLockedTarget)
    else
        if aimingLoop then
            aimingLoop:Disconnect()
        end
        lockedTarget = nil
        InfoLabel.Text = ""
    end
end

AimLockButton.MouseButton1Click:Connect(toggleAiming)

local function updateInfoLabel()
    while true do
        local nearestPlayer, distance = getNearestPlayerToCrosshair()
        if nearestPlayer then
            InfoLabel.Text = "NP: " .. nearestPlayer.Name .. " [" .. math.floor(distance) .. "]"
        else
            InfoLabel.Text = "NP: None"
        end
        wait(0.1)
    end
end

local function enablePCMode()
    MobileButton.Visible = false
    PCButton.Visible = false
    InfoLabel.Text = "Press any button to bind AimLock"
    InfoLabel.Position = UDim2.new(0.45, 0, 0.45, 0)
    local inputService = game:GetService("UserInputService")

    local function onInputBegan(input, gameProcessed)
        if not gameProcessed then
            bindKey = input.KeyCode
            InfoLabel.Text = "Binded to: " .. tostring(bindKey)
            InfoLabel.Position = UDim2.new(0.80, 0, -0.01, 0)
            inputService.InputBegan:Connect(function(key, processed)
                if not processed and key.KeyCode == bindKey then
                    toggleAiming()
                end
            end)
        end
    end

    inputService.InputBegan:Connect(onInputBegan)
end

MobileButton.MouseButton1Click:Connect(function()
    MobileButton.Visible = false
    PCButton.Visible = false
    AimLockButton.Parent = ScreenGui
    AimLockButton.Visible = true
    coroutine.resume(updateLoop)
end)

PCButton.MouseButton1Click:Connect(enablePCMode)

updateLoop = coroutine.create(updateInfoLabel)

player.CharacterAdded:Connect(function()
    ScreenGui.Parent = game.CoreGui
end)

coroutine.resume(updateLoop)
