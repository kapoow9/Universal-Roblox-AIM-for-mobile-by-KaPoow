local gui = Instance.new("ScreenGui", game.CoreGui)
local mbBtn, pcBtn, alBtn, il, bindLabel = Instance.new("TextButton"), Instance.new("TextButton"), Instance.new("TextButton"), Instance.new("TextLabel"), Instance.new("TextLabel")
local player, aiming, loop, lockedTarget, bindKey = game.Players.LocalPlayer, false, nil, nil, nil

local function createButton(name, size, pos, text, parent)
    local btn = Instance.new("TextButton", parent)
    btn.Name, btn.Size, btn.Position = name, size, pos
    btn.BackgroundColor3, btn.TextColor3, btn.Font, btn.TextScaled = Color3.new(0, 0, 0), Color3.new(1, 1, 1), Enum.Font.GothamBold, true
    btn.Text = text
    return btn
end

local screenCenterX = 0.5
local screenCenterY = 0.5
local buttonOffsetX = 0.15
local buttonSize = UDim2.new(0, 150, 0, 150)

mbBtn = createButton("MobileButton", buttonSize, UDim2.new(screenCenterX - buttonOffsetX - 0.075, 0, screenCenterY - 0.075, 0), "Mobile", gui)
pcBtn = createButton("PCButton", buttonSize, UDim2.new(screenCenterX + buttonOffsetX - 0.075, 0, screenCenterY - 0.075, 0), "PC", gui)
alBtn = createButton("AimLockButton", UDim2.new(0, 50, 0, 50), UDim2.new(0.85, 0, 0.08, 0), "AL", nil)
alBtn.TextColor3 = Color3.new(1, 0, 0)
Instance.new("UICorner", alBtn).CornerRadius = UDim.new(0, 5)

il.Name, il.Size, il.Position = "InfoLabel", UDim2.new(0, 130, 0, 25), UDim2.new(0.8, 0, -0.01, 0)
il.BackgroundColor3, il.TextColor3, il.Font, il.TextScaled, il.Parent, il.Visible = Color3.new(0, 0, 0), Color3.new(1, 1, 1), Enum.Font.GothamBold, true, gui, false

bindLabel.Name, bindLabel.Size, bindLabel.Position = "BindLabel", UDim2.new(0, 130, 0, 25), UDim2.new(0.8, 0, 0.02, 0)
bindLabel.BackgroundColor3, bindLabel.TextColor3, bindLabel.Font, bindLabel.TextScaled, bindLabel.Parent, bindLabel.Visible = Color3.new(0, 0, 0), Color3.new(1, 1, 1), Enum.Font.GothamBold, true, gui, false

local function getNearestPlayerToCrosshair()
    local nearest, shortest, cam = nil, math.huge, workspace.CurrentCamera
    for _, target in ipairs(game.Players:GetPlayers()) do
        if target ~= player and target.Character and target.Character:FindFirstChild("Head") then
            local pos, onScreen = cam:WorldToScreenPoint(target.Character.Head.Position)
            if onScreen then
                local dist = (Vector2.new(pos.X, pos.Y) - Vector2.new(cam.ViewportSize.X / 2, cam.ViewportSize.Y / 2)).magnitude
                if dist < shortest then nearest, shortest = target, dist end
            end
        end
    end
    return nearest, shortest
end

local function lookAtLockedTarget()
    if lockedTarget and lockedTarget.Character and lockedTarget.Character:FindFirstChild("Head") then
        local head, playerPos = lockedTarget.Character.Head, player.Character.HumanoidRootPart.Position
        local targetPos = (head.Position + head.Velocity * 0.1) or (head.Position + Vector3.new(0, 1, 0))
        local lookVector = (targetPos - playerPos).unit
        player.Character.HumanoidRootPart.CFrame = CFrame.new(playerPos, playerPos + lookVector)
        workspace.CurrentCamera.CFrame = CFrame.new(workspace.CurrentCamera.CFrame.Position, targetPos)
    end
end

local function toggleAiming()
    aiming = not aiming
    if not bindKey then alBtn.TextColor3 = aiming and Color3.new(0, 1, 0) or Color3.new(1, 0, 0) end
    if aiming then
        lockedTarget, distance = getNearestPlayerToCrosshair()
        il.Text = lockedTarget and "NP: " .. lockedTarget.Name .. " [" .. math.floor(distance) .. "]" or "NP: None"
        loop = game:GetService("RunService").RenderStepped:Connect(lookAtLockedTarget)
    else
        if loop then loop:Disconnect() end
        lockedTarget, il.Text = nil, ""
    end
end

alBtn.MouseButton1Click:Connect(toggleAiming)

local function updateInfoLabel()
    while true do
        local nearestPlayer, distance = getNearestPlayerToCrosshair()
        il.Text = nearestPlayer and "NP: " .. nearestPlayer.Name .. " [" .. math.floor(distance) .. "]" or "NP: None"
        wait(0.1)
    end
end

local function enablePCMode()
    mbBtn.Visible, pcBtn.Visible = false, false
    il.Text, il.Visible, il.Position = "Press any key to bind AimLock", true, UDim2.new(0.8, 0, -0.01, 0)
    local inputService = game:GetService("UserInputService")
    local function onInputBegan(input, gameProcessed)
        if not gameProcessed and not bindKey then
            bindKey, bindLabel.Visible = input.KeyCode, true
            bindLabel.Text = "AimLock: " .. tostring(bindKey):gsub("Enum.KeyCode.", "")
            inputService.InputBegan:Connect(function(key, processed)
                if not processed and key.KeyCode == bindKey then toggleAiming() end
            end)
        end
    end
    inputService.InputBegan:Connect(onInputBegan)
end

mbBtn.MouseButton1Click:Connect(function()
    mbBtn.Visible, pcBtn.Visible = false, false
    alBtn.Parent, alBtn.Visible, il.Visible = gui, true, true
    coroutine.resume(coroutine.create(updateInfoLabel))
end)

pcBtn.MouseButton1Click:Connect(enablePCMode)

coroutine.resume(coroutine.create(updateInfoLabel))

player.CharacterAdded:Connect(function() gui.Parent = game.CoreGui end)
