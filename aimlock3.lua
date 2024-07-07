local ScreenGui = Instance.new("ScreenGui")
local AimLockButton = Instance.new("TextButton")
local player = game.Players.LocalPlayer
local aiming = false
local aimingLoop
local updateLoop
local lockedTarget = nil

ScreenGui.Name = "AimLockGui"
ScreenGui.Parent = game.CoreGui

local InfoLabel = Instance.new("TextLabel")
InfoLabel.Name = "InfoLabel"
InfoLabel.Size = UDim2.new(0, 130, 0, 25)
InfoLabel.Position = UDim2.new(0.80, 0, -0.01, 0)
InfoLabel.BackgroundColor3 = Color3.new(0, 0, 0)
InfoLabel.TextColor3 = Color3.new(1, 1, 1)
InfoLabel.Font = Enum.Font.GothamBold
InfoLabel.TextScaled = true
InfoLabel.Parent = ScreenGui

AimLockButton.Name = "AimLockButton"
AimLockButton.Size = UDim2.new(0, 50, 0, 50)
AimLockButton.Position = UDim2.new(0.85, 0, 0.08, 0)
AimLockButton.BackgroundColor3 = Color3.new(0, 0, 0)
AimLockButton.TextColor3 = Color3.new(1, 0, 0)
AimLockButton.Font = Enum.Font.GothamBold
AimLockButton.Text = "AL"
AimLockButton.TextScaled = true
AimLockButton.Parent = ScreenGui

local UICorner = Instance.new("UICorner")
UICorner.CornerRadius = UDim.new(0, 5)
UICorner.Parent = AimLockButton

local function getNearestPlayerToCrosshair()
    local nearestPlayer = nil
    local shortestDistance = math.huge
    local camera = workspace.CurrentCamera

    for _, target in ipairs(game.Players:GetPlayers()) do
        if target ~= player and target.Character and target.Character:FindFirstChild("HumanoidRootPart") then
            local screenPos, onScreen = camera:WorldToScreenPoint(target.Character.HumanoidRootPart.Position)
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
    if target and target.Character and target.Character:FindFirstChild("HumanoidRootPart") then
        local hrp = target.Character.HumanoidRootPart
        local velocity = hrp.Velocity
        local predictionTime = 0.1  -- Adjust this value to change prediction accuracy
        return hrp.Position + velocity * predictionTime
    end
    return nil
end

local function lookAtLockedTarget()
    if lockedTarget and lockedTarget.Character and lockedTarget.Character:FindFirstChild("HumanoidRootPart") then
        local targetPos = predictTargetPosition(lockedTarget) or (lockedTarget.Character.HumanoidRootPart.Position + Vector3.new(0, 1, 0))
        local playerPos = player.Character.HumanoidRootPart.Position
        local lookVector = (targetPos - playerPos).unit

        player.Character.HumanoidRootPart.CFrame = CFrame.new(playerPos, playerPos + lookVector)
        workspace.CurrentCamera.CFrame = CFrame.new(workspace.CurrentCamera.CFrame.Position, targetPos)
    end
end

AimLockButton.MouseButton1Click:Connect(function()
    aiming = not aiming
    AimLockButton.TextColor3 = aiming and Color3.new(0, 1, 0) or Color3.new(1, 0, 0)

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
end)

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

updateLoop = coroutine.create(updateInfoLabel)
coroutine.resume(updateLoop)

player.CharacterAdded:Connect(function()
    ScreenGui.Parent = game.CoreGui
end)
