--[[
	GRUTAS ARCANAS · Cliente
	Va en: StarterPlayer > StarterPlayerScripts  (tipo: LocalScript)
	Interfaz, apuntado y controles (PC y móvil).
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local UIS = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")

local player = Players.LocalPlayer
local R = ReplicatedStorage:WaitForChild("GrutasRemotes")
local CastEv, StateEv, SwapEv, ChoiceEv, MsgEv, InfoEv =
	R:WaitForChild("Cast"), R:WaitForChild("State"), R:WaitForChild("Swap"), R:WaitForChild("Choice"), R:WaitForChild("Msg"), R:WaitForChild("Info")

local INFO = {}
local STATE = nil
local casting = false
local selected = nil -- {t="w"|"b", i=n}

---------------------------------------------------------------- ESTILO
local INK = Color3.fromRGB(243, 233, 255)
local PANEL = Color3.fromRGB(22, 15, 36)
local EDGE = Color3.fromRGB(91, 63, 160)
local GOLD = Color3.fromRGB(255, 210, 63)
local FONT = Enum.Font.Arcade

local gui = Instance.new("ScreenGui")
gui.Name = "GrutasUI"
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = true
gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
gui.Parent = player:WaitForChild("PlayerGui")

local function new(class, props, parent)
	local o = Instance.new(class)
	for k, v in pairs(props) do o[k] = v end
	o.Parent = parent
	return o
end
local function box(parent, props)
	local f = new("Frame", props, parent)
	f.BackgroundColor3 = props.BackgroundColor3 or PANEL
	f.BorderSizePixel = 0
	new("UICorner", { CornerRadius = UDim.new(0, 6) }, f)
	new("UIStroke", { Color = EDGE, Thickness = 2 }, f)
	return f
end
local function label(parent, text, props)
	local l = new("TextLabel", {
		BackgroundTransparency = 1, Text = text, TextColor3 = INK, Font = FONT, TextScaled = true,
		TextStrokeTransparency = 0.4, Size = UDim2.fromScale(1, 1),
	}, parent)
	for k, v in pairs(props or {}) do l[k] = v end
	return l
end
local function button(parent, text, props)
	local b = new("TextButton", {
		Text = text, TextColor3 = Color3.fromRGB(26, 20, 10), Font = FONT, TextScaled = true, AutoButtonColor = true,
		BackgroundColor3 = GOLD, BorderSizePixel = 0,
	}, parent)
	for k, v in pairs(props or {}) do b[k] = v end
	new("UICorner", { CornerRadius = UDim.new(0, 8) }, b)
	new("UIStroke", { Color = Color3.fromRGB(0, 0, 0), Thickness = 2, ApplyStrokeMode = Enum.ApplyStrokeMode.Border }, b)
	new("UIPadding", { PaddingTop = UDim.new(0, 6), PaddingBottom = UDim.new(0, 6), PaddingLeft = UDim.new(0, 6), PaddingRight = UDim.new(0, 6) }, b)
	return b
end

---------------------------------------------------------------- HUD
local hud = box(gui, { Position = UDim2.new(0, 12, 0, 50), Size = UDim2.fromOffset(210, 86) })
local function bar(y, col)
	local bg = new("Frame", { Position = UDim2.new(0, 10, 0, y), Size = UDim2.new(1, -20, 0, 12), BackgroundColor3 = Color3.fromRGB(0, 0, 0), BorderSizePixel = 0 }, hud)
	local fg = new("Frame", { Size = UDim2.fromScale(1, 1), BackgroundColor3 = col, BorderSizePixel = 0 }, bg)
	return fg
end
local hpBar = bar(10, Color3.fromRGB(232, 69, 90))
local mpBar = bar(28, Color3.fromRGB(74, 163, 255))
local infoL = label(hud, "", { Position = UDim2.new(0, 10, 0, 48), Size = UDim2.new(1, -20, 0, 28), TextXAlignment = Enum.TextXAlignment.Left, TextColor3 = GOLD })

local cross = new("Frame", { AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.fromOffset(18, 18), BackgroundTransparency = 1 }, gui)
new("Frame", { AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.fromOffset(18, 2), BackgroundColor3 = INK, BorderSizePixel = 0, BackgroundTransparency = 0.2 }, cross)
new("Frame", { AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.fromOffset(2, 18), BackgroundColor3 = INK, BorderSizePixel = 0, BackgroundTransparency = 0.2 }, cross)

-- barra de varita
local wandBar = box(gui, { AnchorPoint = Vector2.new(0.5, 1), Position = UDim2.new(0.5, 0, 1, -14), Size = UDim2.fromOffset(6 * 54 + 14, 64) })
local reloadBar = new("Frame", { Position = UDim2.new(0, 0, 1, 2), Size = UDim2.new(0, 0, 0, 4), BackgroundColor3 = GOLD, BorderSizePixel = 0 }, wandBar)
local wandSlots = {}
for i = 1, 6 do
	local s = new("TextButton", { Position = UDim2.fromOffset(7 + (i - 1) * 54, 7), Size = UDim2.fromOffset(50, 50), BackgroundColor3 = Color3.fromRGB(10, 7, 18), BorderSizePixel = 0, Text = "", AutoButtonColor = false }, wandBar)
	new("UICorner", { CornerRadius = UDim.new(0, 6) }, s)
	local st = new("UIStroke", { Color = Color3.fromRGB(42, 32, 64), Thickness = 2, ApplyStrokeMode = Enum.ApplyStrokeMode.Border }, s)
	local t = label(s, "", { Size = UDim2.new(1, -6, 1, -6), Position = UDim2.fromOffset(3, 3) })
	wandSlots[i] = { btn = s, stroke = st, text = t }
end

local bagBtn = button(gui, "BOLSA", { AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, -12, 0, 50), Size = UDim2.fromOffset(110, 44) })
local castBtn = button(gui, "LANZAR", { AnchorPoint = Vector2.new(1, 1), Position = UDim2.new(1, -24, 1, -190), Size = UDim2.fromOffset(110, 110), BackgroundColor3 = Color3.fromRGB(232, 69, 90), TextColor3 = INK })
castBtn:FindFirstChildOfClass("UICorner").CornerRadius = UDim.new(1, 0)
castBtn.Visible = UIS.TouchEnabled

local toast = label(gui, "", { AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.new(0.5, 0, 0, 150), Size = UDim2.fromOffset(520, 30), TextColor3 = GOLD, TextTransparency = 1, TextStrokeTransparency = 1 })
local toastId = 0
local function showToast(text)
	toastId += 1
	local my = toastId
	toast.Text = text
	toast.TextTransparency = 0
	toast.TextStrokeTransparency = 0.3
	task.delay(2.6, function()
		if my == toastId then
			TweenService:Create(toast, TweenInfo.new(0.4), { TextTransparency = 1, TextStrokeTransparency = 1 }):Play()
		end
	end)
end
MsgEv.OnClientEvent:Connect(showToast)

local function abbr(id)
	local s = INFO[id]
	if not s then return "" end
	local n = s.n:gsub("^(%S+)%s.*", "%1")
	return string.upper(string.sub(n, 1, 4))
end
local function paintSlot(obj, id)
	local s = INFO[id]
	if s then
		obj.btn.BackgroundColor3 = s.col:Lerp(Color3.new(0, 0, 0), 0.45)
		obj.text.Text = abbr(id)
		obj.text.TextColor3 = s.col:Lerp(Color3.new(1, 1, 1), 0.5)
	else
		obj.btn.BackgroundColor3 = Color3.fromRGB(10, 7, 18)
		obj.text.Text = ""
	end
end

---------------------------------------------------------------- BOLSA
local bag = box(gui, { AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.fromOffset(420, 430), Visible = false, ZIndex = 5 })
new("UISizeConstraint", { MaxSize = Vector2.new(420, 430) }, bag)
local bagScale = new("UIScale", {}, bag)
label(bag, "TU VARITA", { Position = UDim2.fromOffset(16, 10), Size = UDim2.new(1, -32, 0, 20), TextXAlignment = Enum.TextXAlignment.Left, TextColor3 = GOLD })
label(bag, "Se lanzan en orden de izquierda a derecha", { Position = UDim2.fromOffset(16, 30), Size = UDim2.new(1, -32, 0, 14), TextXAlignment = Enum.TextXAlignment.Left, TextColor3 = Color3.fromRGB(170, 150, 210) })
local function cell(parent, x, y, t, i)
	local s = new("TextButton", { Position = UDim2.fromOffset(x, y), Size = UDim2.fromOffset(58, 58), BackgroundColor3 = Color3.fromRGB(10, 7, 18), BorderSizePixel = 0, Text = "", AutoButtonColor = false }, parent)
	new("UICorner", { CornerRadius = UDim.new(0, 6) }, s)
	local st = new("UIStroke", { Color = Color3.fromRGB(42, 32, 64), Thickness = 2, ApplyStrokeMode = Enum.ApplyStrokeMode.Border }, s)
	local tx = label(s, "", { Size = UDim2.new(1, -8, 1, -8), Position = UDim2.fromOffset(4, 4) })
	return { btn = s, stroke = st, text = tx, t = t, i = i }
end
local bagWand, bagCells = {}, {}
for i = 1, 6 do bagWand[i] = cell(bag, 16 + (i - 1) * 66, 52, "w", i) end
label(bag, "BOLSA", { Position = UDim2.fromOffset(16, 120), Size = UDim2.new(1, -32, 0, 20), TextXAlignment = Enum.TextXAlignment.Left, TextColor3 = GOLD })
for i = 1, 16 do
	local c, r = (i - 1) % 6, math.floor((i - 1) / 6)
	bagCells[i] = cell(bag, 16 + c * 66, 146 + r * 66, "b", i)
end
local infoBox = label(bag, "Toca un hechizo y luego otra casilla para moverlo.", { Position = UDim2.fromOffset(16, 346), Size = UDim2.new(1, -32, 0, 34), TextXAlignment = Enum.TextXAlignment.Left, TextWrapped = true, TextColor3 = INK })
local closeBtn = button(bag, "LISTO", { AnchorPoint = Vector2.new(1, 1), Position = UDim2.new(1, -16, 1, -10), Size = UDim2.fromOffset(110, 36) })

local function refreshBag()
	if not STATE then return end
	for i = 1, 6 do
		paintSlot(bagWand[i], STATE.slots[i])
		bagWand[i].stroke.Color = (selected and selected.t == "w" and selected.i == i) and GOLD or Color3.fromRGB(42, 32, 64)
	end
	for i = 1, 16 do
		paintSlot(bagCells[i], STATE.bag[i])
		bagCells[i].stroke.Color = (selected and selected.t == "b" and selected.i == i) and GOLD or Color3.fromRGB(42, 32, 64)
	end
end
local function onCell(c)
	if not STATE then return end
	local arr = c.t == "w" and STATE.slots or STATE.bag
	if not selected then
		local id = arr[c.i]
		if id and id ~= "" then
			selected = { t = c.t, i = c.i }
			local s = INFO[id]
			infoBox.Text = s.n .. " · " .. s.mana .. " maná · " .. (s.t == "m" and "Modificador" or "Hechizo") .. "\n" .. s.d
		end
	else
		if not (selected.t == c.t and selected.i == c.i) then SwapEv:FireServer(selected.t, selected.i, c.t, c.i) end
		selected = nil
		infoBox.Text = "Toca un hechizo y luego otra casilla para moverlo."
	end
	refreshBag()
end
for _, c in ipairs(bagWand) do c.btn.MouseButton1Click:Connect(function() onCell(c) end) end
for _, c in ipairs(bagCells) do c.btn.MouseButton1Click:Connect(function() onCell(c) end) end
local function toggleBag(v)
	bag.Visible = v
	selected = nil
	local vp = workspace.CurrentCamera.ViewportSize
	bagScale.Scale = math.min(1, (vp.X - 20) / 420, (vp.Y - 20) / 430)
	refreshBag()
end
bagBtn.MouseButton1Click:Connect(function() toggleBag(not bag.Visible) end)
closeBtn.MouseButton1Click:Connect(function() toggleBag(false) end)
for i = 1, 6 do wandSlots[i].btn.MouseButton1Click:Connect(function() toggleBag(true) end) end

---------------------------------------------------------------- COFRES
local choice = box(gui, { AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.fromOffset(380, 300), Visible = false, ZIndex = 6 })
local choiceScale = new("UIScale", {}, choice)
label(choice, "COFRE ARCANO · ELIGE UNO", { Position = UDim2.fromOffset(16, 12), Size = UDim2.new(1, -32, 0, 22), TextColor3 = GOLD })
local choiceBtns = {}
for k = 1, 3 do
	local b = button(choice, "", { Position = UDim2.fromOffset(16, 46 + (k - 1) * 82), Size = UDim2.new(1, -32, 0, 72), TextXAlignment = Enum.TextXAlignment.Left, TextWrapped = true, TextColor3 = INK, BackgroundColor3 = Color3.fromRGB(40, 28, 66) })
	choiceBtns[k] = b
end
local choiceIds = {}
ChoiceEv.OnClientEvent:Connect(function(ids)
	choiceIds = ids
	for k = 1, 3 do
		local s = INFO[ids[k]]
		choiceBtns[k].Text = s and (s.n .. " (" .. s.mana .. " maná)\n" .. s.d) or ""
		choiceBtns[k].BackgroundColor3 = s and s.col:Lerp(Color3.new(0, 0, 0), 0.6) or PANEL
	end
	local vp = workspace.CurrentCamera.ViewportSize
	choiceScale.Scale = math.min(1, (vp.X - 20) / 380, (vp.Y - 20) / 300)
	choice.Visible = true
end)
for k = 1, 3 do
	choiceBtns[k].MouseButton1Click:Connect(function()
		if choiceIds[k] then ChoiceEv:FireServer(choiceIds[k]) end
		choice.Visible = false
	end)
end

---------------------------------------------------------------- ESTADO
InfoEv.OnClientEvent:Connect(function(t) INFO = t end)
StateEv.OnClientEvent:Connect(function(s)
	STATE = s
	mpBar.Size = UDim2.fromScale(math.clamp(s.mana / s.manaMax, 0, 1), 1)
	infoL.Text = "ORO " .. s.gold .. "   PISO " .. s.floor
	for i = 1, 6 do
		paintSlot(wandSlots[i], s.slots[i])
		wandSlots[i].stroke.Color = (i == s.next) and GOLD or Color3.fromRGB(42, 32, 64)
	end
	if s.reload > 0 then
		reloadBar.Size = UDim2.new(1, 0, 0, 4)
		TweenService:Create(reloadBar, TweenInfo.new(s.reload, Enum.EasingStyle.Linear), { Size = UDim2.new(0, 0, 0, 4) }):Play()
	end
	if bag.Visible then refreshBag() end
end)

---------------------------------------------------------------- APUNTAR Y LANZAR
local function aimDir()
	local char = player.Character
	local head = char and char:FindFirstChild("Head")
	if not head then return nil end
	local cam = workspace.CurrentCamera
	local ray
	if UIS.MouseEnabled and not UIS.TouchEnabled then
		local m = UIS:GetMouseLocation()
		ray = cam:ViewportPointToRay(m.X, m.Y)
	else
		local vp = cam.ViewportSize
		ray = cam:ViewportPointToRay(vp.X / 2, vp.Y / 2)
	end
	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Exclude
	params.FilterDescendantsInstances = { char }
	local res = workspace:Raycast(ray.Origin, ray.Direction * 400, params)
	local target = res and res.Position or (ray.Origin + ray.Direction * 400)
	local dir = target - head.Position
	if dir.Magnitude < 1 then dir = ray.Direction end
	return dir.Unit
end

cross.Visible = not (UIS.MouseEnabled and not UIS.TouchEnabled)
local last = 0
RunService.RenderStepped:Connect(function()
	local char = player.Character
	local hum = char and char:FindFirstChildOfClass("Humanoid")
	if hum then hpBar.Size = UDim2.fromScale(math.clamp(hum.Health / hum.MaxHealth, 0, 1), 1) end
	if casting and not bag.Visible and not choice.Visible and os.clock() - last > 0.05 then
		last = os.clock()
		local d = aimDir()
		if d then CastEv:FireServer(d) end
	end
end)

castBtn.InputBegan:Connect(function(i)
	if i.UserInputType == Enum.UserInputType.Touch or i.UserInputType == Enum.UserInputType.MouseButton1 then casting = true end
end)
castBtn.InputEnded:Connect(function(i)
	if i.UserInputType == Enum.UserInputType.Touch or i.UserInputType == Enum.UserInputType.MouseButton1 then casting = false end
end)
UIS.InputBegan:Connect(function(i, gp)
	if gp then return end
	if i.UserInputType == Enum.UserInputType.MouseButton1 and not UIS.TouchEnabled then casting = true end
	if i.KeyCode == Enum.KeyCode.E or i.KeyCode == Enum.KeyCode.Tab then toggleBag(not bag.Visible) end
end)
UIS.InputEnded:Connect(function(i)
	if i.UserInputType == Enum.UserInputType.MouseButton1 and not UIS.TouchEnabled then casting = false end
end)

showToast("Mantén LANZAR (o clic) para usar tu varita. E abre la bolsa.")
