local Players = game:GetService("Players")
local UIS = game:GetService("UserInputService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

-- ===== 获取执行器全局函数的兼容写法 =====
local function getGlobalFn(name)
    local ok, v = pcall(function() return rawget(getfenv(), name) end)
    if ok and type(v) == "function" then return v end
    if getgenv then
        local ok2, env = pcall(getgenv)
        if ok2 and type(env) == "table" then
            local v2 = rawget(env, name)
            if type(v2) == "function" then return v2 end
        end
    end
    return rawget(_G, name)
end

-- ===== 界面容器 =====
local gui = Instance.new("ScreenGui")
gui.Name = "豆包中心"
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = true
gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
gui.Parent = playerGui

-- ===== 窗口本体 =====
local win = Instance.new("Frame")
win.Name = "Win"
win.Size = UDim2.fromOffset(500, 580)
win.Position = UDim2.fromScale(0.5, 0.45)
win.AnchorPoint = Vector2.new(0.5, 0.5)
win.BackgroundColor3 = Color3.fromRGB(18, 18, 18)
win.BorderSizePixel = 0
win.ClipsDescendants = true
win.Parent = gui

local winStroke = Instance.new("UIStroke")
winStroke.Color = Color3.fromRGB(60, 60, 60)
winStroke.Thickness = 1
winStroke.Parent = win

-- ===== 标题栏 =====
local titleBar = Instance.new("Frame")
titleBar.Size = UDim2.new(1, 0, 0, 42)
titleBar.BackgroundColor3 = Color3.fromRGB(28, 28, 28)
titleBar.BorderSizePixel = 0
titleBar.Active = true
titleBar.Parent = win

local title = Instance.new("TextLabel")
title.Size = UDim2.new(1, -60, 1, 0)
title.Position = UDim2.fromOffset(14, 0)
title.BackgroundTransparency = 1
title.Text = "豆包中心 · 多任务循环"
title.Font = Enum.Font.SourceSansBold
title.TextSize = 15
title.TextColor3 = Color3.fromRGB(240, 240, 240)
title.TextXAlignment = Enum.TextXAlignment.Left
title.Parent = titleBar

-- ===== 关闭按钮 =====
local close = Instance.new("TextButton")
close.Size = UDim2.fromOffset(28, 28)
close.Position = UDim2.new(1, -36, 0.5, 0)
close.AnchorPoint = Vector2.new(0, 0.5)
close.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
close.BorderSizePixel = 0
close.AutoButtonColor = false
close.Text = "×"
close.Font = Enum.Font.SourceSansBold
close.TextSize = 18
close.TextColor3 = Color3.fromRGB(160, 160, 160)
close.Parent = titleBar

close.MouseEnter:Connect(function()
    close.BackgroundColor3 = Color3.fromRGB(220, 70, 70)
    close.TextColor3 = Color3.fromRGB(255, 255, 255)
end)
close.MouseLeave:Connect(function()
    close.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
    close.TextColor3 = Color3.fromRGB(160, 160, 160)
end)

-- ===== 下拉头部 =====
local dropdownHeader = Instance.new("TextButton")
dropdownHeader.Size = UDim2.new(1, -70, 0, 36)
dropdownHeader.Position = UDim2.fromOffset(10, 52)
dropdownHeader.BackgroundColor3 = Color3.fromRGB(28, 28, 28)
dropdownHeader.BorderSizePixel = 0
dropdownHeader.AutoButtonColor = false
dropdownHeader.Text = "  任务 1"
dropdownHeader.Font = Enum.Font.SourceSans
dropdownHeader.TextSize = 14
dropdownHeader.TextColor3 = Color3.fromRGB(220, 220, 220)
dropdownHeader.TextXAlignment = Enum.TextXAlignment.Left
dropdownHeader.TextTruncate = Enum.TextTruncate.AtEnd
dropdownHeader.Parent = win

local ddStroke = Instance.new("UIStroke")
ddStroke.Color = Color3.fromRGB(60, 60, 60)
ddStroke.Thickness = 1
ddStroke.Parent = dropdownHeader

local arrow = Instance.new("TextLabel")
arrow.Size = UDim2.fromOffset(20, 36)
arrow.Position = UDim2.new(1, -24, 0, 0)
arrow.BackgroundTransparency = 1
arrow.Text = "▾"
arrow.Font = Enum.Font.SourceSansBold
arrow.TextSize = 14
arrow.TextColor3 = Color3.fromRGB(160, 160, 160)
arrow.Parent = dropdownHeader

-- ===== 加号按钮 =====
local addBtn = Instance.new("TextButton")
addBtn.Size = UDim2.fromOffset(40, 36)
addBtn.Position = UDim2.fromOffset(450, 52)
addBtn.BackgroundColor3 = Color3.fromRGB(40, 100, 60)
addBtn.BorderSizePixel = 0
addBtn.AutoButtonColor = false
addBtn.Text = "+"
addBtn.Font = Enum.Font.SourceSansBold
addBtn.TextSize = 22
addBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
addBtn.Parent = win

local addStroke = Instance.new("UIStroke")
addStroke.Color = Color3.fromRGB(60, 60, 60)
addStroke.Thickness = 1
addStroke.Parent = addBtn

addBtn.MouseEnter:Connect(function()
    addBtn.BackgroundColor3 = Color3.fromRGB(55, 140, 85)
end)
addBtn.MouseLeave:Connect(function()
    addBtn.BackgroundColor3 = Color3.fromRGB(40, 100, 60)
end)

-- ===== 下拉列表 =====
local listFrame = Instance.new("ScrollingFrame")
listFrame.Size = UDim2.new(1, -20, 0, 120)
listFrame.Position = UDim2.fromOffset(10, 92)
listFrame.BackgroundColor3 = Color3.fromRGB(24, 24, 24)
listFrame.BorderSizePixel = 0
listFrame.ScrollBarThickness = 6
listFrame.ScrollBarImageColor3 = Color3.fromRGB(80, 80, 80)
listFrame.CanvasSize = UDim2.new(0, 0, 0, 0)
listFrame.AutomaticCanvasSize = Enum.AutomaticSize.Y
listFrame.Visible = false
listFrame.Parent = win

local listStroke = Instance.new("UIStroke")
listStroke.Color = Color3.fromRGB(60, 60, 60)
listStroke.Thickness = 1
listStroke.Parent = listFrame

local listLayout = Instance.new("UIListLayout")
listLayout.Padding = UDim.new(0, 1)
listLayout.SortOrder = Enum.SortOrder.LayoutOrder
listLayout.Parent = listFrame

-- ===== 开关按钮 =====
local switchBtn = Instance.new("TextButton")
switchBtn.Size = UDim2.fromOffset(220, 44)
switchBtn.Position = UDim2.fromOffset(10, 218)
switchBtn.BackgroundColor3 = Color3.fromRGB(40, 120, 60)
switchBtn.BorderSizePixel = 0
switchBtn.AutoButtonColor = false
switchBtn.Text = "▶ 开始循环"
switchBtn.Font = Enum.Font.SourceSansBold
switchBtn.TextSize = 16
switchBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
switchBtn.Parent = win

local switchStroke = Instance.new("UIStroke")
switchStroke.Color = Color3.fromRGB(60, 60, 60)
switchStroke.Thickness = 1
switchStroke.Parent = switchBtn

-- ===== 状态标签 =====
local statusLabel = Instance.new("TextLabel")
statusLabel.Size = UDim2.fromOffset(250, 44)
statusLabel.Position = UDim2.fromOffset(240, 218)
statusLabel.BackgroundColor3 = Color3.fromRGB(28, 28, 28)
statusLabel.BorderSizePixel = 0
statusLabel.Text = "已停止"
statusLabel.Font = Enum.Font.SourceSans
statusLabel.TextSize = 14
statusLabel.TextColor3 = Color3.fromRGB(180, 180, 180)
statusLabel.TextTruncate = Enum.TextTruncate.AtEnd
statusLabel.Parent = win

local statusStroke = Instance.new("UIStroke")
statusStroke.Color = Color3.fromRGB(60, 60, 60)
statusStroke.Thickness = 1
statusStroke.Parent = statusLabel

-- ===== 脚本标签 =====
local scriptLabel = Instance.new("TextLabel")
scriptLabel.Size = UDim2.new(1, -20, 0, 22)
scriptLabel.Position = UDim2.fromOffset(10, 272)
scriptLabel.BackgroundTransparency = 1
scriptLabel.Text = "要循环执行的脚本"
scriptLabel.Font = Enum.Font.SourceSansBold
scriptLabel.TextSize = 13
scriptLabel.TextColor3 = Color3.fromRGB(180, 180, 180)
scriptLabel.TextXAlignment = Enum.TextXAlignment.Left
scriptLabel.Parent = win

-- ===== 脚本输入区 =====
local scriptScroll = Instance.new("ScrollingFrame")
scriptScroll.Size = UDim2.new(1, -20, 0, 160)
scriptScroll.Position = UDim2.fromOffset(10, 296)
scriptScroll.BackgroundColor3 = Color3.fromRGB(28, 28, 28)
scriptScroll.BorderSizePixel = 0
scriptScroll.ScrollBarThickness = 6
scriptScroll.ScrollBarImageColor3 = Color3.fromRGB(80, 80, 80)
scriptScroll.CanvasSize = UDim2.new(0, 0, 0, 0)
scriptScroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
scriptScroll.Parent = win

local scriptScrollStroke = Instance.new("UIStroke")
scriptScrollStroke.Color = Color3.fromRGB(60, 60, 60)
scriptScrollStroke.Thickness = 1
scriptScrollStroke.Parent = scriptScroll

local scriptBox = Instance.new("TextBox")
scriptBox.Size = UDim2.new(1, -12, 0, 40)
scriptBox.Position = UDim2.fromOffset(6, 6)
scriptBox.BackgroundTransparency = 1
scriptBox.Text = ""
scriptBox.PlaceholderText = "-- 在这里写要循环执行的脚本"
scriptBox.PlaceholderColor3 = Color3.fromRGB(100, 100, 100)
scriptBox.Font = Enum.Font.Code
scriptBox.TextSize = 13
scriptBox.TextColor3 = Color3.fromRGB(150, 200, 255)
scriptBox.TextWrapped = false
scriptBox.TextXAlignment = Enum.TextXAlignment.Left
scriptBox.TextYAlignment = Enum.TextYAlignment.Top
scriptBox.MultiLine = true
scriptBox.ClearTextOnFocus = false
scriptBox.Parent = scriptScroll

local function updateScriptBoxHeight()
    local lineCount = 1
    for _ in string.gmatch(scriptBox.Text, "\n") do lineCount += 1 end
    local h = math.max(lineCount * 18 + 12, 40)
    scriptBox.Size = UDim2.new(1, -12, 0, h)
end

-- ===== 等待标签 =====
local waitLabel = Instance.new("TextLabel")
waitLabel.Size = UDim2.new(1, -20, 0, 22)
waitLabel.Position = UDim2.fromOffset(10, 464)
waitLabel.BackgroundTransparency = 1
waitLabel.Text = "每次循环等待（秒）"
waitLabel.Font = Enum.Font.SourceSansBold
waitLabel.TextSize = 13
waitLabel.TextColor3 = Color3.fromRGB(180, 180, 180)
waitLabel.TextXAlignment = Enum.TextXAlignment.Left
waitLabel.Parent = win

-- ===== 等待输入框 =====
local waitBox = Instance.new("TextBox")
waitBox.Size = UDim2.fromOffset(200, 38)
waitBox.Position = UDim2.fromOffset(10, 488)
waitBox.BackgroundColor3 = Color3.fromRGB(28, 28, 28)
waitBox.BorderSizePixel = 0
waitBox.Text = "1"
waitBox.PlaceholderText = "例如 1"
waitBox.Font = Enum.Font.Code
waitBox.TextSize = 14
waitBox.TextColor3 = Color3.fromRGB(230, 230, 230)
waitBox.TextXAlignment = Enum.TextXAlignment.Left
waitBox.ClearTextOnFocus = false
waitBox.Parent = win

local waitPadding = Instance.new("UIPadding")
waitPadding.PaddingLeft = UDim.new(0, 10)
waitPadding.Parent = waitBox

local waitStroke = Instance.new("UIStroke")
waitStroke.Color = Color3.fromRGB(60, 60, 60)
waitStroke.Thickness = 1
waitStroke.Parent = waitBox

-- ===== 底部提示 =====
local hint = Instance.new("TextLabel")
hint.Size = UDim2.new(1, -20, 0, 40)
hint.Position = UDim2.fromOffset(10, 534)
hint.BackgroundTransparency = 1
hint.Text = "下拉切换任务；「+」新增任务。每个任务独立开关、独立循环，互不干扰。"
hint.Font = Enum.Font.SourceSans
hint.TextSize = 12
hint.TextColor3 = Color3.fromRGB(120, 120, 120)
hint.TextXAlignment = Enum.TextXAlignment.Left
hint.TextYAlignment = Enum.TextYAlignment.Top
hint.TextWrapped = true
hint.Parent = win

-- ===== 任务数据 =====
local tasks = {}
local currentTaskIndex = 1
local syncing = false

local function createTask(name)
    table.insert(tasks, {
        name = name,
        running = false,
        script = "",
        wait = 1,
        count = 0,
        generation = 0,
        lastError = nil,
    })
    return #tasks
end

local function getWaitValue(t)
    local w = t.wait
    if type(w) ~= "number" or w < 0.05 then return 0.05 end
    return w
end

-- ===== UI 刷新 =====
local function updateStatusOnly()
    local t = tasks[currentTaskIndex]
    if not t then return end

    if t.running then
        switchBtn.Text = "■ 停止循环"
        switchBtn.BackgroundColor3 = Color3.fromRGB(180, 50, 50)
        if t.lastError then
            statusLabel.Text = t.lastError
            statusLabel.TextColor3 = Color3.fromRGB(220, 70, 70)
        else
            statusLabel.Text = "运行中 · 已执行 " .. t.count .. " 次"
            statusLabel.TextColor3 = Color3.fromRGB(0, 220, 120)
        end
    else
        switchBtn.Text = "▶ 开始循环"
        switchBtn.BackgroundColor3 = Color3.fromRGB(40, 120, 60)
        if t.lastError then
            statusLabel.Text = t.lastError
            statusLabel.TextColor3 = Color3.fromRGB(220, 70, 70)
        else
            statusLabel.Text = "已停止 · 共 " .. t.count .. " 次"
            statusLabel.TextColor3 = Color3.fromRGB(180, 180, 180)
        end
    end
end

local function refreshUI()
    local t = tasks[currentTaskIndex]
    if not t then return end

    dropdownHeader.Text = "  " .. t.name

    syncing = true
    scriptBox.Text = t.script
    if type(t.wait) == "number" and t.wait > 0 then
        waitBox.Text = tostring(t.wait)
    else
        waitBox.Text = "1"
    end
    syncing = false

    updateScriptBoxHeight()
    updateStatusOnly()
end

-- ===== 下拉列表渲染 =====
local function renderList()
    for _, c in ipairs(listFrame:GetChildren()) do
        if c:IsA("TextButton") then c:Destroy() end
    end

    for i, task in ipairs(tasks) do
        local item = Instance.new("TextButton")
        item.Name = "TaskItem_" .. i
        item.Size = UDim2.new(1, 0, 0, 28)
        item.BackgroundColor3 = Color3.fromRGB(24, 24, 24)
        item.BorderSizePixel = 0
        item.AutoButtonColor = false
        item.Text = "  " .. task.name .. (task.running and "  ●" or "")
        item.Font = Enum.Font.SourceSans
        item.TextSize = 14
        item.TextColor3 = Color3.fromRGB(200, 200, 200)
        item.TextXAlignment = Enum.TextXAlignment.Left
        item.TextTruncate = Enum.TextTruncate.AtEnd
        item.LayoutOrder = i
        item.Parent = listFrame

        if i == currentTaskIndex then
            item.BackgroundColor3 = Color3.fromRGB(50, 80, 130)
        end

        item.MouseEnter:Connect(function()
            if i ~= currentTaskIndex then
                item.BackgroundColor3 = Color3.fromRGB(42, 42, 42)
            end
        end)
        item.MouseLeave:Connect(function()
            if i ~= currentTaskIndex then
                item.BackgroundColor3 = Color3.fromRGB(24, 24, 24)
            end
        end)
        item.MouseButton1Click:Connect(function()
            currentTaskIndex = i
            listFrame.Visible = false
            arrow.Text = "▾"
            renderList()
            refreshUI()
        end)
    end
end

-- ===== 启动 / 停止任务 =====
local function startTask(idx)
    local t = tasks[idx]
    if not t or t.running then return end
    if not t.script or t.script == "" then
        t.lastError = "脚本为空"
        if currentTaskIndex == idx then updateStatusOnly() end
        return
    end

    t.running = true
    t.generation = t.generation + 1
    t.lastError = nil
    local myGen = t.generation

    if currentTaskIndex == idx then
        updateStatusOnly()
        renderList()
    end

    task.spawn(function()
        local loadstringFn = getGlobalFn("loadstring") or loadstring
        if type(loadstringFn) ~= "function" then
            t.running = false
            t.lastError = "执行器不支持 loadstring"
            if currentTaskIndex == idx then updateStatusOnly() end
            return
        end

        while t.running and t.generation == myGen do
            local code = t.script
            if code ~= "" then
                local fn, err = loadstringFn(code)
                if fn then
                    local ok, err2 = pcall(fn)
                    if not ok then
                        t.lastError = "运行错误: " .. tostring(err2)
                    end
                else
                    t.lastError = "语法错误: " .. tostring(err)
                end
                t.count = t.count + 1
            end

            if currentTaskIndex == idx then
                updateStatusOnly()
            end

            if not t.running or t.generation ~= myGen then break end
            task.wait(getWaitValue(t))
        end

        if t.generation == myGen then
            t.running = false
            if currentTaskIndex == idx then
                updateStatusOnly()
                renderList()
            end
        end
    end)
end

local function stopTask(idx)
    local t = tasks[idx]
    if not t or not t.running then return end
    t.running = false
    t.generation = t.generation + 1
    if currentTaskIndex == idx then
        updateStatusOnly()
        renderList()
    end
end

-- ===== 开关按钮 =====
switchBtn.MouseEnter:Connect(function()
    local t = tasks[currentTaskIndex]
    if not t then return end
    if t.running then
        switchBtn.BackgroundColor3 = Color3.fromRGB(210, 60, 60)
    else
        switchBtn.BackgroundColor3 = Color3.fromRGB(50, 150, 75)
    end
end)
switchBtn.MouseLeave:Connect(updateStatusOnly)

switchBtn.MouseButton1Click:Connect(function()
    local t = tasks[currentTaskIndex]
    if not t then return end
    if t.running then
        stopTask(currentTaskIndex)
    else
        startTask(currentTaskIndex)
    end
end)

-- ===== 下拉头部点击 =====
dropdownHeader.MouseButton1Click:Connect(function()
    listFrame.Visible = not listFrame.Visible
    arrow.Text = listFrame.Visible and "▴" or "▾"
end)

-- ===== 加号：新增任务 =====
addBtn.MouseButton1Click:Connect(function()
    local n = createTask("任务 " .. (#tasks + 1))
    currentTaskIndex = n
    renderList()
    refreshUI()
    listFrame.Visible = false
    arrow.Text = "▾"
end)

-- ===== 输入同步 =====
scriptBox:GetPropertyChangedSignal("Text"):Connect(function()
    if syncing then return end
    local t = tasks[currentTaskIndex]
    if t then
        t.script = scriptBox.Text
        t.lastError = nil
    end
    updateScriptBoxHeight()
end)

waitBox:GetPropertyChangedSignal("Text"):Connect(function()
    if syncing then return end
    local t = tasks[currentTaskIndex]
    if t then
        t.wait = tonumber(waitBox.Text) or 0
    end
end)

-- ===== 拖动 =====
local dragging = false
local dragInput = nil
local dragTouch = nil
local lastPos = nil
local DRAG_MAX_DELTA = 150

local function normalizePos()
    local ap = win.AbsolutePosition
    local as = win.AbsoluteSize
    win.Position = UDim2.fromOffset(
        ap.X + as.X * win.AnchorPoint.X,
        ap.Y + as.Y * win.AnchorPoint.Y
    )
end

local function beginDrag(input)
    if dragging then return end
    dragging = true
    dragInput = input
    dragTouch = (input.UserInputType == Enum.UserInputType.Touch) and input or nil
    lastPos = input.Position
    normalizePos()
end

local function endDrag()
    dragging = false
    dragInput = nil
    dragTouch = nil
    lastPos = nil
end

local function moveDrag(dx, dy)
    local cam = workspace.CurrentCamera
    local vp = cam and cam.ViewportSize or Vector2.new(1280, 720)
    local as = win.AbsoluteSize
    local ax, ay = win.AnchorPoint.X, win.AnchorPoint.Y
    local x = math.clamp(win.Position.X.Offset + dx, as.X * ax, math.max(as.X * ax, vp.X - as.X * (1 - ax)))
    local y = math.clamp(win.Position.Y.Offset + dy, as.Y * ay, math.max(as.Y * ay, vp.Y - as.Y * (1 - ay)))
    win.Position = UDim2.fromOffset(x, y)
end

titleBar.InputBegan:Connect(function(input)
    local t = input.UserInputType
    if t == Enum.UserInputType.MouseButton1 or t == Enum.UserInputType.Touch then
        beginDrag(input)
    end
end)

UIS.InputChanged:Connect(function(input)
    if not dragging then return end
    local t = input.UserInputType
    if t == Enum.UserInputType.Touch then
        if input ~= dragTouch then return end
    elseif t == Enum.UserInputType.MouseMovement then
        if not dragInput or dragInput.UserInputType ~= Enum.UserInputType.MouseButton1 then return end
    else
        return
    end

    local d = input.Delta
    if d.Magnitude <= 0 then
        if not lastPos then return end
        d = input.Position - lastPos
    end
    lastPos = input.Position
    if d.Magnitude <= 0 or d.Magnitude > DRAG_MAX_DELTA then return end

    moveDrag(d.X, d.Y)
end)

UIS.InputEnded:Connect(function(input)
    if not dragging then return end
    local t = input.UserInputType
    if t == Enum.UserInputType.MouseButton1 then
        endDrag()
    elseif t == Enum.UserInputType.Touch and input == dragTouch then
        endDrag()
    end
end)

-- ===== 关闭：停掉所有任务 =====
close.MouseButton1Click:Connect(function()
    for _, t in ipairs(tasks) do
        t.running = false
        t.generation = t.generation + 1
    end
    gui:Destroy()
end)

-- ===== 初始化 =====
createTask("任务 1")
renderList()
refreshUI()
