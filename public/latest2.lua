--// OrcaPlusByRuzh - latest2.lua
-- Version Plus personalizada por Ruzh (TRuzh_)
-- Inspirado en Orca Hub, mejorado para compatibilidad de juegos.

--------------------------------------------------------------------------------
--// Servicios
--------------------------------------------------------------------------------
local Players = game:GetService("Players")
local Teams = game:GetService("Teams")
local Workspace = game:GetService("Workspace")
local TweenService = game:GetService("TweenService")
local VirtualInputManager = game:GetService("VirtualInputManager")
local UserInputService = game:GetService("UserInputService")
local CoreGui = game:GetService("CoreGui")

--------------------------------------------------------------------------------
--// Variables Globales
--------------------------------------------------------------------------------
local LocalPlayer = Players.LocalPlayer
local espEnabled = false
local overlayEnabled = true
local autoTaskMode = "Auto" -- Puede ser "Auto", "Manual", "Off"
local watermarkText = "TRuzh_"
local connections = {}

local function bindConnection(signal, callback)
    local connection = signal:Connect(callback)
    table.insert(connections, connection)
    return connection
end

--------------------------------------------------------------------------------
--// Watermark (TRuzh_)
--------------------------------------------------------------------------------
local function createWatermark()
    local screenGui = Instance.new("ScreenGui")
    screenGui.Name = "Watermark"
    screenGui.Parent = CoreGui
    screenGui.ResetOnSpawn = false

    local textLabel = Instance.new("TextLabel")
    textLabel.Size = UDim2.new(0, 200, 0, 40)
    textLabel.Position = UDim2.new(1, -210, 0, 10)
    textLabel.BackgroundTransparency = 1
    textLabel.TextTransparency = 0.3
    textLabel.TextScaled = true
    textLabel.Font = Enum.Font.SourceSansBold
    textLabel.TextColor3 = Color3.new(1, 1, 1)
    textLabel.Text = watermarkText
    textLabel.Parent = screenGui

    local gradient = Instance.new("UIGradient")
    gradient.Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0, Color3.fromRGB(255,0,0)),
        ColorSequenceKeypoint.new(0.17, Color3.fromRGB(255,165,0)),
        ColorSequenceKeypoint.new(0.33, Color3.fromRGB(255,255,0)),
        ColorSequenceKeypoint.new(0.5, Color3.fromRGB(0,255,0)),
        ColorSequenceKeypoint.new(0.67, Color3.fromRGB(0,0,255)),
        ColorSequenceKeypoint.new(0.83, Color3.fromRGB(75,0,130)),
        ColorSequenceKeypoint.new(1, Color3.fromRGB(238,130,238)),
    })
    gradient.Parent = textLabel

    local tweenInfo = TweenInfo.new(8, Enum.EasingStyle.Linear, Enum.EasingDirection.InOut, -1, true)
    TweenService:Create(gradient, tweenInfo, {Rotation = 360}):Play()
end

createWatermark()
--------------------------------------------------------------------------------
--// Sistema de Stamina Infinita
--------------------------------------------------------------------------------
local function setupInfiniteStamina()
    local success, err = pcall(function()
        local stamina = LocalPlayer.PlayerGui:WaitForChild("Modules"):WaitForChild("Gameplay"):WaitForChild("Sprint"):WaitForChild("Stamina")
        stamina.Value = math.huge
        bindConnection(stamina:GetPropertyChangedSignal("Value"), function()
            if stamina.Value ~= math.huge then
                stamina.Value = math.huge
            end
        end)
    end)
    if not success then
        warn("[Stamina] No se encontró el módulo de Stamina.")
    end
end

setupInfiniteStamina()
--------------------------------------------------------------------------------
--// AutoTask System (Be NPC or Die)
--------------------------------------------------------------------------------
local autoTaskEnabled = true

local function attemptAutoTask()
    if not autoTaskEnabled then return end

    local playerModel = Workspace:FindFirstChild(LocalPlayer.Name)
    if not playerModel then return end

    local taskName = playerModel:GetAttribute("TaskName")
    if not taskName or taskName == "" or taskName:match("^%s*$") then
        return
    end

    -- Buscar y activar ProximityPrompt automáticamente
    for _, folder in ipairs(Workspace:GetChildren()) do
        if folder:IsA("Folder") and folder:FindFirstChild("Tasks") then
            local taskModel = folder.Tasks:FindFirstChild(taskName)
            if taskModel then
                local prompt = taskModel:FindFirstChildOfClass("ProximityPrompt")
                if prompt then
                    prompt.HoldDuration = 0
                    prompt.MaxActivationDistance = 1000
                    fireproximityprompt(prompt)
                end
            end
        end
    end
end

task.spawn(function()
    while task.wait(1) do
        if autoTaskMode == "Auto" then
            attemptAutoTask()
        end
    end
end)
--------------------------------------------------------------------------------
--// ESP para Jugadores (ignorando NPCs)
--------------------------------------------------------------------------------
local function createPlayerESP(player)
    if player == LocalPlayer then return end
    player.CharacterAdded:Connect(function(char)
        local head = char:WaitForChild("Head", 5)
        if head then
            if not head:FindFirstChild("ESPHighlight") then
                local esp = Instance.new("BillboardGui")
                esp.Name = "ESPHighlight"
                esp.Size = UDim2.new(0, 30, 0, 30)
                esp.StudsOffset = Vector3.new(0, 2, 0)
                esp.AlwaysOnTop = true
                esp.Parent = head

                local frame = Instance.new("Frame")
                frame.Size = UDim2.new(1, 0, 1, 0)
                frame.BackgroundTransparency = 0.4
                frame.BackgroundColor3 = Color3.fromRGB(255, 0, 0)
                frame.BorderSizePixel = 0
                frame.Parent = esp
            end
        end
    end)
end

local function setupESP()
    for _, player in ipairs(Players:GetPlayers()) do
        createPlayerESP(player)
    end

    Players.PlayerAdded:Connect(function(player)
        createPlayerESP(player)
    end)
end

setupESP()
--------------------------------------------------------------------------------
--// Overlay de Estados Activos
--------------------------------------------------------------------------------
local function createOverlay()
    local screenGui = Instance.new("ScreenGui")
    screenGui.Name = "StatusOverlay"
    screenGui.Parent = CoreGui
    screenGui.ResetOnSpawn = false

    local frame = Instance.new("Frame")
    frame.Size = UDim2.new(0, 500, 0, 30)
    frame.Position = UDim2.new(0.5, -250, 1, -40)
    frame.BackgroundTransparency = 0.5
    frame.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
    frame.BorderSizePixel = 0
    frame.Parent = screenGui

    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(1, 0, 1, 0)
    label.BackgroundTransparency = 1
    label.TextColor3 = Color3.new(1, 1, 1)
    label.Font = Enum.Font.SourceSansBold
    label.TextScaled = true
    label.Parent = frame

    task.spawn(function()
        while task.wait(1) do
            local statusText = string.format(
                "ESP: %s  |  AutoTask: %s",
                espEnabled and "ON" or "OFF",
                autoTaskMode
            )
            label.Text = statusText
        end
    end)
end

createOverlay()
--------------------------------------------------------------------------------
--// Kill All Changes
--------------------------------------------------------------------------------
local function killAll()
    _G.ensureloop = false
    autoTaskEnabled = false

    for _, conn in ipairs(connections) do
        if conn.Connected then
            conn:Disconnect()
        end
    end

    for _, gui in ipairs(CoreGui:GetChildren()) do
        if gui.Name == "Watermark" or gui.Name == "StatusOverlay" or gui.Name == "TaskGui" then
            gui:Destroy()
        end
    end
end

-- Botón Kill All
local function createKillButton()
    local screenGui = Instance.new("ScreenGui")
    screenGui.Name = "KillGui"
    screenGui.Parent = CoreGui
    screenGui.ResetOnSpawn = false

    local killButton = Instance.new("TextButton")
    killButton.Size = UDim2.new(0, 100, 0, 30)
    killButton.Position = UDim2.new(0, 10, 1, -40)
    killButton.BackgroundColor3 = Color3.fromRGB(255, 0, 0)
    killButton.Text = "Kill Changes"
    killButton.TextColor3 = Color3.new(1, 1, 1)
    killButton.Font = Enum.Font.SourceSansBold
    killButton.TextScaled = true
    killButton.Parent = screenGui

    killButton.MouseButton1Click:Connect(function()
        killAll()
    end)
end

createKillButton()
--------------------------------------------------------------------------------
--// Tab de Juegos Compatibles (Estilo Orca Hub)
--------------------------------------------------------------------------------
local function createGamesTab()
    local screenGui = Instance.new("ScreenGui")
    screenGui.Name = "GamesTabGui"
    screenGui.Parent = CoreGui
    screenGui.ResetOnSpawn = false

    local mainFrame = Instance.new("Frame")
    mainFrame.Size = UDim2.new(0, 250, 0, 400)
    mainFrame.Position = UDim2.new(0, 10, 0.5, -200)
    mainFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
    mainFrame.BorderSizePixel = 0
    mainFrame.BackgroundTransparency = 0.2
    mainFrame.Parent = screenGui

    local uiCorner = Instance.new("UICorner")
    uiCorner.CornerRadius = UDim.new(0, 8)
    uiCorner.Parent = mainFrame

    local titleLabel = Instance.new("TextLabel")
    titleLabel.Size = UDim2.new(1, 0, 0, 40)
    titleLabel.BackgroundTransparency = 1
    titleLabel.Text = "Juegos Compatibles"
    titleLabel.Font = Enum.Font.SourceSansBold
    titleLabel.TextScaled = true
    titleLabel.TextColor3 = Color3.new(1, 1, 1)
    titleLabel.Parent = mainFrame

    local scrollingFrame = Instance.new("ScrollingFrame")
    scrollingFrame.Size = UDim2.new(1, 0, 1, -40)
    scrollingFrame.Position = UDim2.new(0, 0, 0, 40)
    scrollingFrame.BackgroundTransparency = 1
    scrollingFrame.CanvasSize = UDim2.new(0, 0, 0, 0)
    scrollingFrame.ScrollBarThickness = 6
    scrollingFrame.Parent = mainFrame

    local uiListLayout = Instance.new("UIListLayout")
    uiListLayout.Padding = UDim.new(0, 6)
    uiListLayout.SortOrder = Enum.SortOrder.LayoutOrder
    uiListLayout.Parent = scrollingFrame

    -- Juego: Be NPC or Die
    local function createGameCard(name, description)
        local card = Instance.new("Frame")
        card.Size = UDim2.new(1, -10, 0, 80)
        card.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
        card.BorderSizePixel = 0
        card.Parent = scrollingFrame

        local uiCornerCard = Instance.new("UICorner")
        uiCornerCard.CornerRadius = UDim.new(0, 8)
        uiCornerCard.Parent = card

        local title = Instance.new("TextLabel")
        title.Size = UDim2.new(1, -10, 0, 30)
        title.Position = UDim2.new(0, 5, 0, 5)
        title.BackgroundTransparency = 1
        title.Text = name
        title.Font = Enum.Font.SourceSansBold
        title.TextScaled = true
        title.TextColor3 = Color3.new(1, 1, 1)
        title.Parent = card

        local desc = Instance.new("TextLabel")
        desc.Size = UDim2.new(1, -10, 0, 30)
        desc.Position = UDim2.new(0, 5, 0, 40)
        desc.BackgroundTransparency = 1
        desc.Text = description
        desc.Font = Enum.Font.SourceSans
        desc.TextScaled = true
        desc.TextColor3 = Color3.fromRGB(200, 200, 200)
        desc.TextWrapped = true
        desc.Parent = card
    end

    createGameCard("Be NPC or Die", "Auto Task + Infinite Stamina by Ruzh.")
end

createGamesTab()
