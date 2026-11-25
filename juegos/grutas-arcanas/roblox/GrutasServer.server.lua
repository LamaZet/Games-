--[[
	GRUTAS ARCANAS · Servidor
	Va en: ServerScriptService  (tipo: Script)
	Crea el mundo de bloques, los mobs, los hechizos y todo lo del servidor.
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Lighting = game:GetService("Lighting")
local Debris = game:GetService("Debris")

---------------------------------------------------------------- REMOTES
local remotes = Instance.new("Folder")
remotes.Name = "GrutasRemotes"
remotes.Parent = ReplicatedStorage
local function remote(name)
	local r = Instance.new("RemoteEvent")
	r.Name = name
	r.Parent = remotes
	return r
end
local CastEv = remote("Cast")
local StateEv = remote("State")
local SwapEv = remote("Swap")
local ChoiceEv = remote("Choice")
local MsgEv = remote("Msg")
local InfoEv = remote("Info")

---------------------------------------------------------------- AMBIENTE
Lighting.ClockTime = 0
Lighting.Brightness = 0.4
Lighting.Ambient = Color3.fromRGB(28, 22, 40)
Lighting.OutdoorAmbient = Color3.fromRGB(28, 22, 40)
Lighting.FogColor = Color3.fromRGB(10, 6, 18)
Lighting.FogStart = 40
Lighting.FogEnd = 220
Lighting.GlobalShadows = true
for _, c in ipairs(Lighting:GetChildren()) do
	if c:IsA("PostEffect") or c:IsA("Sky") or c:IsA("Atmosphere") then c:Destroy() end
end
local bloom = Instance.new("BloomEffect")
bloom.Intensity = 0.7
bloom.Size = 28
bloom.Threshold = 0.85
bloom.Parent = Lighting
local cc = Instance.new("ColorCorrectionEffect")
cc.Saturation = 0.15
cc.Contrast = 0.08
cc.Parent = Lighting

---------------------------------------------------------------- BLOQUES
local B = 4 -- tamaño de bloque en studs
local SX, SY, SZ = 30, 54, 30
local ORIGIN = Vector3.new(-SX * B / 2, 0, -SZ * B / 2)

local AIR, STONE, DIRT, GRASS, WOOD, SAND, GOLD, CRYSTAL, LAVA, BEDROCK, PURPLE, BASALT, ICE, OBSIDIAN, CHEST =
	0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14

local BLOCK = {
	[STONE] = { n = "Piedra", c = Color3.fromRGB(120, 118, 128), m = Enum.Material.Slate, hard = 1 },
	[DIRT] = { n = "Tierra", c = Color3.fromRGB(121, 85, 58), m = Enum.Material.Ground, hard = 0 },
	[GRASS] = { n = "Musgo", c = Color3.fromRGB(86, 140, 70), m = Enum.Material.Grass, hard = 0 },
	[WOOD] = { n = "Madera", c = Color3.fromRGB(150, 104, 60), m = Enum.Material.WoodPlanks, hard = 0, burns = true },
	[SAND] = { n = "Arena", c = Color3.fromRGB(219, 196, 130), m = Enum.Material.Sand, hard = 0, falls = true },
	[GOLD] = { n = "Oro", c = Color3.fromRGB(230, 190, 60), m = Enum.Material.Slate, hard = 1, gold = 6 },
	[CRYSTAL] = { n = "Cristal", c = Color3.fromRGB(170, 110, 255), m = Enum.Material.Neon, hard = 2, glow = true },
	[LAVA] = { n = "Lava", c = Color3.fromRGB(255, 110, 30), m = Enum.Material.Neon, liquid = true, glow = true, dmg = 40 },
	[BEDROCK] = { n = "Roca madre", c = Color3.fromRGB(30, 28, 36), m = Enum.Material.Basalt, hard = 99 },
	[PURPLE] = { n = "Piedra arcana", c = Color3.fromRGB(88, 64, 120), m = Enum.Material.Slate, hard = 1 },
	[BASALT] = { n = "Basalto", c = Color3.fromRGB(58, 48, 50), m = Enum.Material.Basalt, hard = 2 },
	[ICE] = { n = "Hielo", c = Color3.fromRGB(160, 220, 255), m = Enum.Material.Ice, hard = 0 },
	[OBSIDIAN] = { n = "Obsidiana", c = Color3.fromRGB(40, 20, 60), m = Enum.Material.Glass, hard = 3 },
	[CHEST] = { n = "Cofre", c = Color3.fromRGB(140, 90, 40), m = Enum.Material.Wood, hard = 99 },
}

local world = Instance.new("Folder")
world.Name = "Grutas"
world.Parent = workspace
local blockFolder, mobFolder, fxFolder

local grid = {}
local parts = {}
local burning = {}
local fallQueue = {}
local floorN = 1
local generating = false

local function idx(x, y, z)
	return (y - 1) * SX * SZ + (z - 1) * SX + x
end
local function inb(x, y, z)
	return x >= 1 and x <= SX and y >= 1 and y <= SY and z >= 1 and z <= SZ
end
local function get(x, y, z)
	if not inb(x, y, z) then return BEDROCK end
	return grid[idx(x, y, z)] or AIR
end
local function solidId(id)
	return id ~= AIR and not (BLOCK[id] and BLOCK[id].liquid)
end
local function cellCenter(x, y, z)
	return ORIGIN + Vector3.new((x - 0.5) * B, (y - 0.5) * B, (z - 0.5) * B)
end
local function cellOf(pos)
	local p = (pos - ORIGIN) / B
	return math.floor(p.X) + 1, math.floor(p.Y) + 1, math.floor(p.Z) + 1
end
local function solidAt(pos)
	local x, y, z = cellOf(pos)
	return solidId(get(x, y, z))
end
local function biome(y)
	if y > 36 then return 1 elseif y > 18 then return 2 else return 3 end
end

local NB = { { 1, 0, 0 }, { -1, 0, 0 }, { 0, 1, 0 }, { 0, -1, 0 }, { 0, 0, 1 }, { 0, 0, -1 } }
local function exposed(x, y, z)
	for _, d in ipairs(NB) do
		local n = get(x + d[1], y + d[2], z + d[3])
		if not solidId(n) then return true end
	end
	return false
end

local function makePart(x, y, z)
	local i = idx(x, y, z)
	local id = grid[i]
	if not id or id == AIR or parts[i] then return end
	local d = BLOCK[id]
	local p = Instance.new("Part")
	p.Anchored = true
	p.Size = Vector3.new(B, B, B)
	p.CFrame = CFrame.new(cellCenter(x, y, z))
	p.Material = d.m
	local v = (math.noise(x * 0.37, y * 0.37, z * 0.37) + 1) * 0.5
	p.Color = d.c:Lerp(Color3.new(0, 0, 0), 0.06 + v * 0.16)
	p.TopSurface = Enum.SurfaceType.Smooth
	p.BottomSurface = Enum.SurfaceType.Smooth
	p.CastShadow = not d.liquid
	if d.liquid then
		p.CanCollide = false
		p.Transparency = 0.05
		p.Size = Vector3.new(B, B * 0.85, B)
		p.CFrame = CFrame.new(cellCenter(x, y, z) - Vector3.new(0, B * 0.075, 0))
	end
	if id == CRYSTAL then
		p.Size = Vector3.new(B * 0.6, B * 0.9, B * 0.6)
		p.CFrame = CFrame.new(cellCenter(x, y, z)) * CFrame.Angles(0, math.rad((x * 37 + z * 11) % 90), math.rad(8))
		p.Transparency = 0.15
	end
	if d.glow and (x + y + z) % 3 == 0 then
		local l = Instance.new("PointLight")
		l.Color = d.c
		l.Range = 14
		l.Brightness = 1.2
		l.Shadows = false
		l.Parent = p
	end
	if id == CHEST then
		p.Size = Vector3.new(B * 0.8, B * 0.7, B * 0.8)
		p.CFrame = CFrame.new(cellCenter(x, y, z) - Vector3.new(0, B * 0.15, 0))
		local lid = Instance.new("Part")
		lid.Anchored = true
		lid.CanCollide = false
		lid.Size = Vector3.new(B * 0.84, B * 0.2, B * 0.84)
		lid.CFrame = p.CFrame * CFrame.new(0, B * 0.4, 0)
		lid.Color = Color3.fromRGB(110, 70, 30)
		lid.Material = Enum.Material.Wood
		lid.Parent = p
		local lock = Instance.new("Part")
		lock.Anchored = true
		lock.CanCollide = false
		lock.Size = Vector3.new(0.6, 0.8, 0.3)
		lock.CFrame = p.CFrame * CFrame.new(0, B * 0.15, -B * 0.41)
		lock.Material = Enum.Material.Neon
		lock.Color = Color3.fromRGB(255, 205, 80)
		lock.Parent = p
		local l = Instance.new("PointLight")
		l.Color = Color3.fromRGB(255, 205, 80)
		l.Range = 10
		l.Brightness = 1
		l.Parent = p
		local pr = Instance.new("ProximityPrompt")
		pr.ActionText = "Abrir cofre"
		pr.ObjectText = "Cofre arcano"
		pr.HoldDuration = 0.3
		pr.MaxActivationDistance = 12
		pr.RequiresLineOfSight = false
		pr.Parent = p
		pr:SetAttribute("chest", i)
	end
	p:SetAttribute("i", i)
	p.Parent = blockFolder
	parts[i] = p
end

local function refreshAround(x, y, z)
	for _, d in ipairs(NB) do
		local nx, ny, nz = x + d[1], y + d[2], z + d[3]
		if inb(nx, ny, nz) and get(nx, ny, nz) ~= AIR and not parts[idx(nx, ny, nz)] then
			makePart(nx, ny, nz)
		end
	end
end

local function setBlock(x, y, z, id)
	if not inb(x, y, z) then return end
	local i = idx(x, y, z)
	if parts[i] then
		parts[i]:Destroy()
		parts[i] = nil
	end
	burning[i] = nil
	grid[i] = id
	if id ~= AIR then
		makePart(x, y, z)
	else
		refreshAround(x, y, z)
		local above = get(x, y + 1, z)
		if BLOCK[above] and BLOCK[above].falls then table.insert(fallQueue, { x, y + 1, z }) end
	end
end

---------------------------------------------------------------- GENERACIÓN
local spawnPos = Vector3.new(0, 0, 0)
local portalPart
local chestsLeft = 0

local function generate()
	generating = true
	if world:FindFirstChild("Bloques") then world.Bloques:Destroy() end
	if world:FindFirstChild("Mobs") then world.Mobs:Destroy() end
	if world:FindFirstChild("Efectos") then world.Efectos:Destroy() end
	blockFolder = Instance.new("Folder")
	blockFolder.Name = "Bloques"
	blockFolder.Parent = world
	mobFolder = Instance.new("Folder")
	mobFolder.Name = "Mobs"
	mobFolder.Parent = world
	fxFolder = Instance.new("Folder")
	fxFolder.Name = "Efectos"
	fxFolder.Parent = world
	table.clear(grid)
	table.clear(parts)
	table.clear(burning)
	table.clear(fallQueue)

	local seed = math.random() * 1000
	local top = SY - 3
	for y = 1, SY do
		for z = 1, SZ do
			for x = 1, SX do
				local id
				if x == 1 or x == SX or z == 1 or z == SZ or y == 1 then
					id = BEDROCK
				elseif y > top then
					id = AIR
				elseif y == top then
					id = GRASS
				elseif y >= top - 2 then
					id = DIRT
				else
					local n = math.noise(x / 7.5 + seed, y / 6, z / 7.5) + 0.5 * math.noise(x / 3.2, y / 3.2 + seed, z / 3.2)
					local b = biome(y)
					local thr = b == 3 and 0.14 or 0.2
					if n > thr then
						id = AIR
					else
						local r = math.noise(x / 4 + 50, y / 4, z / 4 + seed)
						if b == 1 then
							id = (r > 0.25) and DIRT or STONE
							if r < -0.45 then id = SAND end
						elseif b == 2 then
							id = PURPLE
							if r > 0.4 then id = SAND end
						else
							id = BASALT
							if r > 0.35 then id = STONE end
						end
						if math.noise(x / 2.5 + seed, y / 2.5, z / 2.5) > 0.55 then id = GOLD end
					end
				end
				grid[idx(x, y, z)] = id
			end
		end
	end
	-- pozo de entrada en el centro del campamento
	local cx, cz = math.floor(SX / 2), math.floor(SZ / 2)
	for y = top - 14, top do
		for dx = 0, 1 do
			for dz = 0, 1 do
				grid[idx(cx + dx, y, cz + dz)] = AIR
			end
		end
	end
	-- cámara del portal al fondo
	for y = 2, 6 do
		for z = cz - 3, cz + 4 do
			for x = cx - 3, cx + 4 do
				if inb(x, y, z) and x > 1 and x < SX and z > 1 and z < SZ then grid[idx(x, y, z)] = AIR end
			end
		end
	end
	-- decoración: vigas, cristales, lava, cofres
	local chestSpots = {}
	for y = 2, top - 1 do
		for z = 2, SZ - 1 do
			for x = 2, SX - 1 do
				local i = idx(x, y, z)
				if grid[i] == AIR and solidId(get(x, y - 1, z)) then
					local b = biome(y)
					local r = math.random()
					local inPortalRoom = y <= 6 and math.abs(x - cx) <= 4 and math.abs(z - cz) <= 4
					if not inPortalRoom then
						if b == 1 and r < 0.012 and get(x, y + 1, z) == AIR then
							grid[i] = WOOD
							grid[idx(x, y + 1, z)] = WOOD
						elseif b == 2 and r < 0.03 then
							grid[i] = CRYSTAL
						elseif b == 3 and y <= 14 and r < 0.18 and math.noise(x / 5, y / 5 + seed, z / 5) > 0 then
							grid[i] = LAVA
						elseif r > 0.993 then
							table.insert(chestSpots, { x, y, z })
						end
					end
				end
			end
		end
	end
	chestsLeft = 0
	for k = 1, math.min(8, #chestSpots) do
		local s = table.remove(chestSpots, math.random(1, #chestSpots))
		grid[idx(s[1], s[2], s[3])] = CHEST
		chestsLeft += 1
	end
	-- construir solo bloques visibles
	local count = 0
	for y = 1, SY do
		for z = 1, SZ do
			for x = 1, SX do
				local id = grid[idx(x, y, z)]
				if id ~= AIR and (BLOCK[id].liquid or id == CHEST or id == CRYSTAL or exposed(x, y, z)) then
					makePart(x, y, z)
					count += 1
					if count % 400 == 0 then task.wait() end
				end
			end
		end
	end
	-- campamento
	spawnPos = cellCenter(cx - 4, top + 1, cz - 4)
	local sp = workspace:FindFirstChild("CampamentoSpawn")
	if not sp then
		sp = Instance.new("SpawnLocation")
		sp.Name = "CampamentoSpawn"
		sp.Anchored = true
		sp.Size = Vector3.new(8, 1, 8)
		sp.Material = Enum.Material.Cobblestone
		sp.Color = Color3.fromRGB(90, 80, 110)
		sp.Duration = 0
		sp.Parent = workspace
	end
	sp.CFrame = CFrame.new(cellCenter(cx - 4, top, cz - 4) + Vector3.new(0, B / 2 + 0.5, 0))
	local fire = Instance.new("Part")
	fire.Anchored = true
	fire.CanCollide = false
	fire.Size = Vector3.new(2, 1, 2)
	fire.Material = Enum.Material.Neon
	fire.Color = Color3.fromRGB(255, 140, 40)
	fire.CFrame = CFrame.new(cellCenter(cx + 5, top, cz + 5) + Vector3.new(0, B / 2 + 0.5, 0))
	local f = Instance.new("Fire")
	f.Size = 6
	f.Parent = fire
	local fl = Instance.new("PointLight")
	fl.Color = Color3.fromRGB(255, 160, 80)
	fl.Range = 30
	fl.Brightness = 2
	fl.Parent = fire
	fire.Parent = fxFolder
	-- portal
	portalPart = Instance.new("Part")
	portalPart.Anchored = true
	portalPart.CanCollide = false
	portalPart.Shape = Enum.PartType.Cylinder
	portalPart.Size = Vector3.new(0.6, 12, 12)
	portalPart.Material = Enum.Material.Neon
	portalPart.Color = Color3.fromRGB(170, 110, 255)
	portalPart.Transparency = 0.2
	portalPart.CFrame = CFrame.new(cellCenter(cx, 3, cz) + Vector3.new(B / 2, 2, B / 2)) * CFrame.Angles(0, 0, 0)
	local pl = Instance.new("PointLight")
	pl.Color = portalPart.Color
	pl.Range = 40
	pl.Brightness = 3
	pl.Parent = portalPart
	local pe = Instance.new("ParticleEmitter")
	pe.Color = ColorSequence.new(Color3.fromRGB(220, 180, 255), Color3.fromRGB(120, 60, 255))
	pe.LightEmission = 1
	pe.Rate = 40
	pe.Lifetime = NumberRange.new(1, 2)
	pe.Speed = NumberRange.new(2, 5)
	pe.SpreadAngle = Vector2.new(180, 180)
	pe.Size = NumberSequence.new(0.5, 0)
	pe.Parent = portalPart
	portalPart.Parent = fxFolder
	generating = false
	return cx, cz, top
end

---------------------------------------------------------------- HECHIZOS
local SP = {
	chispa = { n = "Chispa", t = "p", mana = 5, delay = 0.06, dmg = 10, speed = 110, life = 0.8, col = Color3.fromRGB(150, 220, 255), size = 0.6, r = 1, d = "Rápida y barata." },
	fuego = { n = "Bola de fuego", t = "p", mana = 20, delay = 0.15, dmg = 8, speed = 70, life = 2, grav = 18, boom = 2, fire = true, col = Color3.fromRGB(255, 120, 40), size = 1.2, r = 1, d = "Explota, rompe bloques y quema madera." },
	taladro = { n = "Taladro arcano", t = "p", mana = 3, delay = 0.05, dmg = 4, speed = 80, life = 0.22, dig = 1, col = Color3.fromRGB(220, 180, 120), size = 0.7, r = 1, d = "Perfora bloques a corta distancia." },
	bomba = { n = "Bomba", t = "p", mana = 35, delay = 0.5, dmg = 0, speed = 50, life = 1.8, grav = 70, bounce = 4, boom = 3.5, col = Color3.fromRGB(50, 45, 60), size = 1.4, r = 1, d = "Rebota y destruye una zona grande." },
	rayo = { n = "Relámpago", t = "h", mana = 25, delay = 0.25, dmg = 24, range = 100, col = Color3.fromRGB(255, 240, 150), r = 2, d = "Golpe instantáneo que salta entre enemigos." },
	sierra = { n = "Disco sierra", t = "p", mana = 15, delay = 0.12, dmg = 12, speed = 60, life = 3, bounce = 6, pierce = true, col = Color3.fromRGB(210, 215, 230), size = 1, r = 2, d = "Rebota y atraviesa enemigos." },
	misil = { n = "Misil mágico", t = "p", mana = 14, delay = 0.12, dmg = 16, speed = 55, life = 2.5, homing = 3, col = Color3.fromRGB(255, 80, 200), size = 0.8, r = 2, d = "Persigue al enemigo más cercano." },
	meteoro = { n = "Meteoro", t = "p", mana = 40, delay = 0.45, dmg = 12, speed = 35, life = 3, grav = 90, boom = 3, fire = true, col = Color3.fromRGB(255, 80, 20), size = 1.8, r = 3, d = "Cae pesado y explota." },
	hielo = { n = "Flecha de hielo", t = "p", mana = 12, delay = 0.1, dmg = 12, speed = 95, life = 1, freeze = 2.5, col = Color3.fromRGB(150, 220, 255), size = 0.7, r = 1, d = "Congela enemigos y la lava cercana." },
	agua = { n = "Bomba de agua", t = "p", mana = 10, delay = 0.1, dmg = 2, speed = 60, life = 2, grav = 50, water = 2, col = Color3.fromRGB(60, 140, 255), size = 1.1, r = 1, d = "Apaga fuego y convierte lava en obsidiana." },
	tele = { n = "Teletransporte", t = "p", mana = 22, delay = 0.25, dmg = 0, speed = 130, life = 0.6, tele = true, col = Color3.fromRGB(200, 160, 255), size = 0.6, r = 2, d = "Te lleva adonde impacta." },
	curar = { n = "Orbe de vida", t = "u", mana = 50, delay = 0.6, heal = 25, col = Color3.fromRGB(255, 90, 110), r = 3, d = "Recupera 25 de vida." },
	doble = { n = "Doble", t = "m", mana = 0, draw = 1, col = Color3.fromRGB(210, 160, 255), r = 1, d = "Lanza los 2 hechizos siguientes a la vez." },
	triple = { n = "Triple", t = "m", mana = 2, draw = 2, col = Color3.fromRGB(210, 160, 255), r = 2, d = "Lanza los 3 hechizos siguientes a la vez." },
	teledir = { n = "Teledirigido", t = "m", mana = 8, homing = 3, col = Color3.fromRGB(255, 120, 210), r = 2, d = "Los proyectiles persiguen enemigos." },
	rebote = { n = "Rebote", t = "m", mana = 3, bounce = 3, col = Color3.fromRGB(160, 240, 110), r = 1, d = "Rebota 3 veces más." },
	danio = { n = "Daño +", t = "m", mana = 5, dmgAdd = 10, col = Color3.fromRGB(255, 90, 90), r = 1, d = "+10 de daño." },
	veloz = { n = "Velocidad", t = "m", mana = 3, speedMul = 1.8, col = Color3.fromRGB(120, 240, 255), r = 1, d = "Proyectiles más rápidos." },
	dispersion = { n = "Dispersión", t = "m", mana = 0, spread = 14, delay = -0.05, col = Color3.fromRGB(255, 210, 100), r = 1, d = "Más dispersión, más rapidez." },
	explosivo = { n = "Explosivo", t = "m", mana = 15, boomAdd = 1.5, col = Color3.fromRGB(255, 150, 60), r = 2, d = "Explosión extra al impactar." },
	gatillo = { n = "Gatillo", t = "m", mana = 10, trig = true, col = Color3.fromRGB(255, 210, 80), r = 2, d = "El siguiente proyectil lanza otro hechizo al impactar." },
	rapido = { n = "Lanzamiento rápido", t = "m", mana = 1, delay = -0.15, col = Color3.fromRGB(255, 230, 120), r = 1, d = "Menos retraso entre lanzamientos." },
}
local SPELL_IDS = {}
for k in pairs(SP) do table.insert(SPELL_IDS, k) end
table.sort(SPELL_IDS)

local function randSpell(tier)
	local w = ({ { 1, 0.3, 0.06 }, { 1, 0.6, 0.2 }, { 0.8, 0.8, 0.45 } })[math.clamp(tier, 1, 3)]
	local tot = 0
	for _, id in ipairs(SPELL_IDS) do tot += w[SP[id].r] end
	local r = math.random() * tot
	for _, id in ipairs(SPELL_IDS) do
		r -= w[SP[id].r]
		if r <= 0 then return id end
	end
	return "chispa"
end

---------------------------------------------------------------- JUGADORES
local PD = {}
local WAND_SLOTS, BAG_SLOTS = 6, 16

local function buildOrder(w)
	w.order = {}
	for i = 1, WAND_SLOTS do
		if w.slots[i] then table.insert(w.order, i) end
	end
	w.pos = 1
end

local function newData()
	local w = { slots = { "taladro", "chispa", "doble", "chispa", nil, nil }, delay = 0.1, recharge = 0.35, manaMax = 160, mana = 160, regen = 45 }
	buildOrder(w)
	local bag = {}
	bag[1] = "fuego"
	bag[2] = randSpell(1)
	return { wand = w, bag = bag, gold = 0, ready = 0, reloadEnd = 0, kills = 0 }
end

local function sendState(plr)
	local d = PD[plr]
	if not d then return end
	local w = d.wand
	local slots, bag = {}, {}
	for i = 1, WAND_SLOTS do slots[i] = w.slots[i] or "" end
	for i = 1, BAG_SLOTS do bag[i] = d.bag[i] or "" end
	StateEv:FireClient(plr, {
		slots = slots, bag = bag, mana = w.mana, manaMax = w.manaMax, gold = d.gold, floor = floorN,
		next = w.order[w.pos] or 1, reload = math.max(0, d.reloadEnd - os.clock()), delay = w.delay, recharge = w.recharge,
	})
end

local function msg(plr, text)
	if plr then MsgEv:FireClient(plr, text) else MsgEv:FireAllClients(text) end
end

local function addToBag(plr, id)
	local d = PD[plr]
	for i = 1, BAG_SLOTS do
		if not d.bag[i] then
			d.bag[i] = id
			sendState(plr)
			return true
		end
	end
	msg(plr, "¡Bolsa llena!")
	return false
end

local function spellInfo()
	local t = {}
	for id, s in pairs(SP) do
		t[id] = { n = s.n, t = s.t, mana = s.mana, d = s.d, col = s.col }
	end
	return t
end

local function onCharacter(plr, char)
	local hrp = char:WaitForChild("HumanoidRootPart", 10)
	if not hrp then return end
	local l = Instance.new("PointLight")
	l.Color = Color3.fromRGB(255, 220, 170)
	l.Range = 26
	l.Brightness = 1.6
	l.Shadows = true
	l.Parent = hrp
	local hum = char:WaitForChild("Humanoid", 10)
	if hum then
		hum.MaxHealth = 100
		hum.Health = 100
		hum.Died:Connect(function()
			local d = PD[plr]
			if d then
				local lost = math.floor(d.gold / 2)
				d.gold -= lost
				msg(plr, "Caíste… pierdes " .. lost .. " de oro.")
				sendState(plr)
			end
		end)
	end
end

Players.PlayerAdded:Connect(function(plr)
	PD[plr] = newData()
	local ls = Instance.new("Folder")
	ls.Name = "leaderstats"
	ls.Parent = plr
	local g = Instance.new("IntValue")
	g.Name = "Oro"
	g.Parent = ls
	local p = Instance.new("IntValue")
	p.Name = "Piso"
	p.Value = floorN
	p.Parent = ls
	plr.CharacterAdded:Connect(function(c) onCharacter(plr, c) end)
	if plr.Character then task.spawn(onCharacter, plr, plr.Character) end
	task.delay(1, function()
		InfoEv:FireClient(plr, spellInfo())
		sendState(plr)
		msg(plr, "¡Bienvenido a las Grutas Arcanas! Baja hasta el portal del fondo.")
	end)
end)
Players.PlayerRemoving:Connect(function(plr) PD[plr] = nil end)

SwapEv.OnServerEvent:Connect(function(plr, aT, aI, bT, bI)
	local d = PD[plr]
	if not d or type(aI) ~= "number" or type(bI) ~= "number" then return end
	local function arr(t) return t == "w" and d.wand.slots or (t == "b" and d.bag or nil) end
	local A, Bt = arr(aT), arr(bT)
	if not A or not Bt then return end
	local maxA = aT == "w" and WAND_SLOTS or BAG_SLOTS
	local maxB = bT == "w" and WAND_SLOTS or BAG_SLOTS
	if aI < 1 or aI > maxA or bI < 1 or bI > maxB then return end
	A[aI], Bt[bI] = Bt[bI], A[aI]
	buildOrder(d.wand)
	sendState(plr)
end)

---------------------------------------------------------------- MOBS
local mobs = {}
local MOB = {
	slime = { hp = 30, size = Vector3.new(3, 3, 3), col = Color3.fromRGB(94, 196, 106), speed = 14, dmg = 12, gold = 4 },
	bat = { hp = 16, size = Vector3.new(2, 1.4, 1.4), col = Color3.fromRGB(90, 60, 130), speed = 16, dmg = 8, gold = 3, fly = true },
	wisp = { hp = 26, size = Vector3.new(2, 2, 2), col = Color3.fromRGB(110, 230, 255), speed = 10, dmg = 10, gold = 6, fly = true, shoot = true },
	golem = { hp = 120, size = Vector3.new(4, 6, 4), col = Color3.fromRGB(110, 95, 95), speed = 7, dmg = 25, gold = 15 },
}
local function weld(a, b)
	local w = Instance.new("WeldConstraint")
	w.Part0 = a
	w.Part1 = b
	w.Parent = a
end
local function mobModel(kind)
	local def = MOB[kind]
	local m = Instance.new("Model")
	m.Name = kind
	local root = Instance.new("Part")
	root.Name = "Root"
	root.Anchored = true
	root.CanCollide = false
	root.Size = def.size
	root.Color = def.col
	root.Material = kind == "wisp" and Enum.Material.Neon or (kind == "golem" and Enum.Material.Slate or Enum.Material.SmoothPlastic)
	if kind == "slime" then root.Transparency = 0.2 end
	if kind == "wisp" then root.Shape = Enum.PartType.Ball; root.Transparency = 0.25 end
	root.Parent = m
	m.PrimaryPart = root
	local function deco(size, off, col, mat)
		local p = Instance.new("Part")
		p.Anchored = false
		p.CanCollide = false
		p.Massless = true
		p.Size = size
		p.Color = col
		p.Material = mat or Enum.Material.SmoothPlastic
		p.CFrame = root.CFrame * off
		p.Parent = m
		weld(root, p)
		return p
	end
	local black = Color3.fromRGB(20, 20, 28)
	if kind == "slime" then
		deco(Vector3.new(0.5, 0.6, 0.2), CFrame.new(-0.6, 0.4, -1.5), black)
		deco(Vector3.new(0.5, 0.6, 0.2), CFrame.new(0.6, 0.4, -1.5), black)
		deco(Vector3.new(1.6, 1.6, 1.6), CFrame.new(0, -0.3, 0), Color3.fromRGB(60, 150, 80))
	elseif kind == "bat" then
		deco(Vector3.new(2.2, 0.2, 1), CFrame.new(-1.8, 0.2, 0), def.col):SetAttribute("wing", -1)
		deco(Vector3.new(2.2, 0.2, 1), CFrame.new(1.8, 0.2, 0), def.col):SetAttribute("wing", 1)
		deco(Vector3.new(0.3, 0.3, 0.2), CFrame.new(-0.4, 0.2, -0.75), Color3.fromRGB(255, 60, 80), Enum.Material.Neon)
		deco(Vector3.new(0.3, 0.3, 0.2), CFrame.new(0.4, 0.2, -0.75), Color3.fromRGB(255, 60, 80), Enum.Material.Neon)
	elseif kind == "wisp" then
		local l = Instance.new("PointLight")
		l.Color = def.col
		l.Range = 16
		l.Brightness = 2
		l.Parent = root
		local pe = Instance.new("ParticleEmitter")
		pe.Color = ColorSequence.new(def.col)
		pe.LightEmission = 1
		pe.Rate = 25
		pe.Lifetime = NumberRange.new(0.4, 0.8)
		pe.Speed = NumberRange.new(1, 2)
		pe.Size = NumberSequence.new(0.6, 0)
		pe.Parent = root
	elseif kind == "golem" then
		deco(Vector3.new(2.6, 2.2, 2.6), CFrame.new(0, 4, 0), Color3.fromRGB(95, 82, 82), Enum.Material.Slate)
		deco(Vector3.new(0.6, 0.4, 0.2), CFrame.new(-0.6, 4.2, -1.35), Color3.fromRGB(255, 140, 40), Enum.Material.Neon)
		deco(Vector3.new(0.6, 0.4, 0.2), CFrame.new(0.6, 4.2, -1.35), Color3.fromRGB(255, 140, 40), Enum.Material.Neon)
		deco(Vector3.new(1.4, 4, 1.4), CFrame.new(-2.8, 0.5, 0), Color3.fromRGB(95, 82, 82), Enum.Material.Slate)
		deco(Vector3.new(1.4, 4, 1.4), CFrame.new(2.8, 0.5, 0), Color3.fromRGB(95, 82, 82), Enum.Material.Slate)
	end
	for _, p in ipairs(m:GetDescendants()) do
		if p:IsA("BasePart") then p:SetAttribute("mob", true) end
	end
	return m
end
local function spawnMob(kind, pos)
	local def = MOB[kind]
	local m = mobModel(kind)
	m:PivotTo(CFrame.new(pos))
	m.Parent = mobFolder
	local hpScale = 1 + (floorN - 1) * 0.35
	local mob = { kind = kind, model = m, root = m.PrimaryPart, pos = pos, vel = Vector3.zero, hp = def.hp * hpScale, maxHp = def.hp * hpScale, cd = 0, shootCd = 2 + math.random() * 2, frozen = 0, phase = math.random() * 6, lastHit = nil }
	local bb = Instance.new("BillboardGui")
	bb.Size = UDim2.fromOffset(40, 5)
	bb.StudsOffset = Vector3.new(0, def.size.Y / 2 + (kind == "golem" and 4 or 1.2), 0)
	bb.AlwaysOnTop = true
	bb.Enabled = false
	local bg = Instance.new("Frame")
	bg.Size = UDim2.fromScale(1, 1)
	bg.BackgroundColor3 = Color3.fromRGB(30, 20, 30)
	bg.BorderSizePixel = 0
	bg.Parent = bb
	local fg = Instance.new("Frame")
	fg.Size = UDim2.fromScale(1, 1)
	fg.BackgroundColor3 = Color3.fromRGB(232, 69, 90)
	fg.BorderSizePixel = 0
	fg.Parent = bg
	bb.Parent = mob.root
	mob.bar = fg
	mob.barGui = bb
	mobs[m] = mob
	return mob
end
local function populate(top)
	local n = 0
	local tries = 0
	while n < 34 and tries < 4000 do
		tries += 1
		local x, y, z = math.random(2, SX - 1), math.random(4, top - 6), math.random(2, SZ - 1)
		if get(x, y, z) == AIR and get(x, y + 1, z) == AIR and solidId(get(x, y - 1, z)) then
			local b = biome(y)
			local r = math.random()
			local kind
			if b == 1 then kind = r < 0.6 and "slime" or "bat"
			elseif b == 2 then kind = r < 0.35 and "slime" or (r < 0.65 and "bat" or "wisp")
			else kind = r < 0.5 and "golem" or (r < 0.75 and "wisp" or "bat") end
			spawnMob(kind, cellCenter(x, y, z) + Vector3.new(0, MOB[kind].size.Y / 2 - B / 2 + 0.1, 0))
			n += 1
		end
	end
end

local function nearestPlayer(pos, range)
	local best, bd = nil, range
	for _, plr in ipairs(Players:GetPlayers()) do
		local c = plr.Character
		local h = c and c:FindFirstChild("HumanoidRootPart")
		local hum = c and c:FindFirstChildOfClass("Humanoid")
		if h and hum and hum.Health > 0 then
			local d = (h.Position - pos).Magnitude
			if d < bd then best, bd = h, d end
		end
	end
	return best, bd
end

local function popText(pos, text, col)
	local a = Instance.new("Part")
	a.Anchored = true
	a.CanCollide = false
	a.CanQuery = false
	a.Transparency = 1
	a.Size = Vector3.new(0.2, 0.2, 0.2)
	a.CFrame = CFrame.new(pos)
	local bb = Instance.new("BillboardGui")
	bb.Size = UDim2.fromOffset(80, 30)
	bb.AlwaysOnTop = true
	local t = Instance.new("TextLabel")
	t.Size = UDim2.fromScale(1, 1)
	t.BackgroundTransparency = 1
	t.Text = text
	t.TextColor3 = col or Color3.new(1, 1, 1)
	t.TextStrokeTransparency = 0
	t.Font = Enum.Font.Arcade
	t.TextScaled = true
	t.Parent = bb
	bb.Parent = a
	a.Parent = fxFolder
	task.spawn(function()
		for i = 1, 20 do
			a.CFrame = a.CFrame + Vector3.new(0, 0.12, 0)
			t.TextTransparency = i / 20
			task.wait(0.03)
		end
		a:Destroy()
	end)
end

local pickups = {}
local function killMob(mob, killer)
	mobs[mob.model] = nil
	local def = MOB[mob.kind]
	if killer and PD[killer] then
		PD[killer].gold += def.gold
		PD[killer].kills += 1
		local ls = killer:FindFirstChild("leaderstats")
		if ls then ls.Oro.Value = PD[killer].gold end
		sendState(killer)
	end
	local ex = Instance.new("Explosion")
	ex.BlastPressure = 0
	ex.DestroyJointRadiusPercent = 0
	ex.BlastRadius = 3
	ex.Position = mob.pos
	ex.Parent = fxFolder
	if math.random() < 0.18 then
		local id = randSpell(biome(select(2, cellOf(mob.pos))))
		local orb = Instance.new("Part")
		orb.Anchored = true
		orb.CanCollide = false
		orb.Shape = Enum.PartType.Ball
		orb.Size = Vector3.new(1.4, 1.4, 1.4)
		orb.Material = Enum.Material.Neon
		orb.Color = SP[id].col
		orb.CFrame = CFrame.new(mob.pos)
		local l = Instance.new("PointLight")
		l.Color = orb.Color
		l.Range = 10
		l.Parent = orb
		orb.Parent = fxFolder
		pickups[orb] = { id = id, base = mob.pos, t = 0 }
	end
	mob.model:Destroy()
end
local function damageMob(mob, dmg, plr, crit)
	if not mobs[mob.model] then return end
	mob.hp -= dmg
	mob.lastHit = plr or mob.lastHit
	mob.barGui.Enabled = true
	mob.bar.Size = UDim2.fromScale(math.clamp(mob.hp / mob.maxHp, 0, 1), 1)
	popText(mob.pos + Vector3.new(0, 2.5, 0), tostring(math.floor(dmg + 0.5)), crit and Color3.fromRGB(255, 210, 80) or Color3.new(1, 1, 1))
	for _, p in ipairs(mob.model:GetDescendants()) do
		if p:IsA("BasePart") and p:GetAttribute("wing") == nil and p.Name == "Root" then
			local old = p.Color
			p.Color = Color3.new(1, 1, 1)
			task.delay(0.08, function() if p.Parent then p.Color = old end end)
		end
	end
	if mob.hp <= 0 then killMob(mob, mob.lastHit) end
end
local function mobFromPart(p)
	local m = p:FindFirstAncestorOfClass("Model")
	return m and mobs[m]
end

---------------------------------------------------------------- EFECTOS DEL MUNDO
local function hurtPlayersNear(pos, radius, dmg)
	for _, plr in ipairs(Players:GetPlayers()) do
		local c = plr.Character
		local h = c and c:FindFirstChild("HumanoidRootPart")
		local hum = c and c:FindFirstChildOfClass("Humanoid")
		if h and hum and (h.Position - pos).Magnitude < radius then hum:TakeDamage(dmg) end
	end
end
local function giveGold(plr, n, pos)
	if plr and PD[plr] then
		PD[plr].gold += n
		local ls = plr:FindFirstChild("leaderstats")
		if ls then ls.Oro.Value = PD[plr].gold end
		popText(pos, "+" .. n .. " oro", Color3.fromRGB(255, 205, 80))
		sendState(plr)
	end
end
local function breakBlock(x, y, z, plr, power)
	local id = get(x, y, z)
	if id == AIR or id == CHEST or id == BEDROCK then return end
	local d = BLOCK[id]
	if d.liquid then return end
	if (d.hard or 0) > (power or 1) then return end
	if d.gold then giveGold(plr, d.gold, cellCenter(x, y, z)) end
	setBlock(x, y, z, AIR)
end
local function ignite(x, y, z)
	local i = idx(x, y, z)
	if grid[i] ~= WOOD or burning[i] then return end
	burning[i] = 3 + math.random() * 2
	local p = parts[i]
	if p then
		local f = Instance.new("Fire")
		f.Size = 5
		f.Heat = 8
		f.Parent = p
		local l = Instance.new("PointLight")
		l.Color = Color3.fromRGB(255, 150, 60)
		l.Range = 14
		l.Brightness = 1.5
		l.Parent = p
	end
end
local function explode(pos, r, dmg, fire, plr)
	local ex = Instance.new("Explosion")
	ex.BlastPressure = 0
	ex.DestroyJointRadiusPercent = 0
	ex.BlastRadius = r * B
	ex.Position = pos
	ex.Parent = fxFolder
	local cx, cy, cz = cellOf(pos)
	local ri = math.ceil(r)
	for dx = -ri, ri do
		for dy = -ri, ri do
			for dz = -ri, ri do
				if dx * dx + dy * dy + dz * dz <= r * r then
					local x, y, z = cx + dx, cy + dy, cz + dz
					local id = get(x, y, z)
					if fire and id == WOOD then ignite(x, y, z)
					else breakBlock(x, y, z, plr, (dx * dx + dy * dy + dz * dz <= (r * 0.6) ^ 2) and 2 or 1) end
				end
			end
		end
	end
	for _, mob in pairs(mobs) do
		local d = (mob.pos - pos).Magnitude
		if d < r * B + 2 then damageMob(mob, dmg * (1 - d / (r * B + 6)), plr) end
	end
	hurtPlayersNear(pos, r * B * 0.8, dmg * 0.12)
end
local function waterSplash(pos, r)
	local cx, cy, cz = cellOf(pos)
	for dx = -r, r do
		for dy = -r, r do
			for dz = -r, r do
				local x, y, z = cx + dx, cy + dy, cz + dz
				local id = get(x, y, z)
				if id == LAVA then setBlock(x, y, z, OBSIDIAN)
				elseif id == WOOD and burning[idx(x, y, z)] then
					burning[idx(x, y, z)] = nil
					local p = parts[idx(x, y, z)]
					if p then for _, c in ipairs(p:GetChildren()) do if c:IsA("Fire") or c:IsA("PointLight") then c:Destroy() end end end
				end
			end
		end
	end
	local pe = Instance.new("Part")
	pe.Anchored = true
	pe.CanCollide = false
	pe.Transparency = 1
	pe.CFrame = CFrame.new(pos)
	local e = Instance.new("ParticleEmitter")
	e.Color = ColorSequence.new(Color3.fromRGB(120, 180, 255))
	e.Speed = NumberRange.new(10, 20)
	e.SpreadAngle = Vector2.new(180, 180)
	e.Size = NumberSequence.new(0.6, 0)
	e.Lifetime = NumberRange.new(0.4, 0.8)
	e.Parent = pe
	pe.Parent = fxFolder
	e:Emit(40)
	Debris:AddItem(pe, 1.5)
end

---------------------------------------------------------------- PROYECTILES
local projs = {}
local castSpec
local rayParams = RaycastParams.new()
rayParams.FilterType = Enum.RaycastFilterType.Include

local function statsFor(spec)
	local b = SP[spec.id]
	local s = { dmg = b.dmg or 0, speed = b.speed or 60, life = b.life or 1, grav = b.grav or 0, bounce = b.bounce or 0, homing = b.homing or 0, spread = 2, boom = b.boom or 0, pierce = b.pierce or false }
	for _, m in ipairs(spec.mods) do
		local d = SP[m]
		if d.homing then s.homing += d.homing end
		if d.bounce then s.bounce += d.bounce end
		if d.dmgAdd then s.dmg += d.dmgAdd end
		if d.speedMul then s.speed *= d.speedMul; s.life /= 1.3 end
		if d.spread then s.spread += d.spread end
		if d.boomAdd then s.boom = math.max(s.boom, 0) + d.boomAdd end
	end
	return s
end

local function nearestMob(pos, range)
	local best, bd = nil, range
	for _, mob in pairs(mobs) do
		local d = (mob.pos - pos).Magnitude
		if d < bd then best, bd = mob, d end
	end
	return best
end

local function beam(a, b, col, w)
	local d = (b - a).Magnitude
	local p = Instance.new("Part")
	p.Anchored = true
	p.CanCollide = false
	p.CanQuery = false
	p.Material = Enum.Material.Neon
	p.Color = col
	p.Size = Vector3.new(w or 0.3, w or 0.3, d)
	p.CFrame = CFrame.lookAt((a + b) / 2, b)
	p.Parent = fxFolder
	Debris:AddItem(p, 0.12)
end

local function firePayload(pr, pos)
	if pr.payload and #pr.payload > 0 then
		local dir = pr.vel.Magnitude > 0 and pr.vel.Unit or Vector3.yAxis
		for _, sp in ipairs(pr.payload) do
			castSpec(pr.owner, sp, pos - dir * 1.5, (dir + Vector3.new(math.random() - 0.5, math.random() - 0.5, math.random() - 0.5) * 0.5).Unit, 6)
		end
	end
end

local function impact(pr, pos, normal)
	if pr.dead then return end
	pr.dead = true
	local b = SP[pr.id]
	if pr.boom > 0 then explode(pos, pr.boom, 35 + (pr.dmg - (b.dmg or 0)) * 1.5, b.fire, pr.owner) end
	if b.water then waterSplash(pos, b.water) end
	if b.freeze then
		local cx, cy, cz = cellOf(pos)
		for dx = -1, 1 do for dy = -1, 1 do for dz = -1, 1 do
			if get(cx + dx, cy + dy, cz + dz) == LAVA then setBlock(cx + dx, cy + dy, cz + dz, ICE) end
		end end end
	end
	if b.tele and pr.owner and pr.owner.Character then
		local hrp = pr.owner.Character:FindFirstChild("HumanoidRootPart")
		if hrp then hrp.CFrame = CFrame.new(pos + (normal or Vector3.yAxis) * 4 + Vector3.new(0, 2, 0)) end
	end
	firePayload(pr, pos)
	pr.part:Destroy()
end

local function makeProjPart(id, size)
	local b = SP[id]
	local p = Instance.new("Part")
	p.Anchored = true
	p.CanCollide = false
	p.CanQuery = false
	p.Shape = Enum.PartType.Ball
	p.Size = Vector3.new(size, size, size)
	p.Material = Enum.Material.Neon
	p.Color = b.col
	if id == "bomba" then p.Material = Enum.Material.Metal end
	if id == "sierra" then p.Shape = Enum.PartType.Cylinder; p.Size = Vector3.new(0.3, size * 1.8, size * 1.8); p.Material = Enum.Material.Metal end
	local l = Instance.new("PointLight")
	l.Color = b.col
	l.Range = 12
	l.Brightness = 1.6
	l.Parent = p
	local a0 = Instance.new("Attachment")
	a0.Position = Vector3.new(0, 0.2, 0)
	a0.Parent = p
	local a1 = Instance.new("Attachment")
	a1.Position = Vector3.new(0, -0.2, 0)
	a1.Parent = p
	local tr = Instance.new("Trail")
	tr.Attachment0 = a0
	tr.Attachment1 = a1
	tr.Color = ColorSequence.new(b.col)
	tr.LightEmission = 1
	tr.Lifetime = 0.25
	tr.WidthScale = NumberSequence.new(1, 0)
	tr.Transparency = NumberSequence.new(0.2, 1)
	tr.Parent = p
	if b.fire then
		local f = Instance.new("Fire")
		f.Size = size * 2
		f.Heat = 2
		f.Parent = p
	end
	p.Parent = fxFolder
	return p
end

local function hitscan(owner, spec, origin, dir)
	local b = SP[spec.id]
	local s = statsFor(spec)
	rayParams.FilterDescendantsInstances = { blockFolder, mobFolder }
	local res = workspace:Raycast(origin, dir * b.range, rayParams)
	local endPos = res and res.Position or origin + dir * b.range
	beam(origin, endPos, b.col, 0.35)
	if res then
		local mob = mobFromPart(res.Instance)
		if mob then
			damageMob(mob, s.dmg, owner)
			local hit = { [mob] = true }
			local from = mob
			for _ = 1, 2 do
				local nxt, nd = nil, 30
				for _, m in pairs(mobs) do
					if not hit[m] then
						local d = (m.pos - from.pos).Magnitude
						if d < nd then nxt, nd = m, d end
					end
				end
				if not nxt then break end
				beam(from.pos, nxt.pos, b.col, 0.25)
				damageMob(nxt, s.dmg * 0.7, owner)
				hit[nxt] = true
				from = nxt
			end
		end
	end
	if spec.payload then
		firePayload({ payload = spec.payload, owner = owner, vel = dir }, endPos)
	end
end

castSpec = function(owner, spec, origin, dir, extraSpread)
	local b = SP[spec.id]
	if b.t == "u" then
		if spec.id == "curar" and owner.Character then
			local hum = owner.Character:FindFirstChildOfClass("Humanoid")
			if hum then hum.Health = math.min(hum.MaxHealth, hum.Health + b.heal) end
			popText(origin + Vector3.new(0, 2, 0), "+" .. b.heal, Color3.fromRGB(140, 255, 140))
		end
		return
	end
	if b.t == "h" then return hitscan(owner, spec, origin, dir) end
	local s = statsFor(spec)
	local sp = math.rad(s.spread + (extraSpread or 0))
	local d = (CFrame.lookAt(Vector3.zero, dir) * CFrame.Angles((math.random() - 0.5) * sp, (math.random() - 0.5) * sp, 0)).LookVector
	local pr = {
		id = spec.id, owner = owner, pos = origin, vel = d * s.speed, life = s.life, age = 0, dmg = s.dmg, grav = s.grav, bounce = s.bounce,
		homing = s.homing, pierce = s.pierce, boom = s.boom, dig = b.dig, payload = spec.payload, hits = {},
		part = makeProjPart(spec.id, b.size or 0.8),
	}
	pr.part.CFrame = CFrame.new(origin)
	table.insert(projs, pr)
end

local function drawN(w, n, c, depth)
	local out, mods = {}, {}
	while n > 0 do
		if w.pos > #w.order then
			if c.wrapped or #w.order == 0 then break end
			c.wrapped = true
			w.pos = 1
		end
		c.taken += 1
		if c.taken > #w.order * 2 then break end
		local id = w.slots[w.order[w.pos]]
		w.pos += 1
		local s = SP[id]
		if s then
			c.mana += s.mana
			c.delay += s.delay or 0
			if s.t == "m" then
				if s.draw then n += s.draw else table.insert(mods, id) end
			else
				local spec = { id = id, mods = {} }
				local trig = false
				for _, m in ipairs(mods) do
					if SP[m].trig then trig = true else table.insert(spec.mods, m) end
				end
				if trig and depth < 3 then spec.payload = drawN(w, 1, c, depth + 1) end
				local keep = {}
				for _, m in ipairs(mods) do if not SP[m].trig then table.insert(keep, m) end end
				mods = keep
				table.insert(out, spec)
				n -= 1
			end
		end
	end
	return out
end

CastEv.OnServerEvent:Connect(function(plr, dir)
	local d = PD[plr]
	if not d or generating or typeof(dir) ~= "Vector3" or dir.Magnitude < 0.5 then return end
	dir = dir.Unit
	local now = os.clock()
	if now < d.ready then return end
	local char = plr.Character
	local head = char and char:FindFirstChild("Head")
	local hum = char and char:FindFirstChildOfClass("Humanoid")
	if not head or not hum or hum.Health <= 0 then return end
	local w = d.wand
	if #w.order == 0 then return end
	local save = w.pos
	local c = { mana = 0, delay = w.delay, wrapped = false, taken = 0 }
	local list = drawN(w, 1, c, 0)
	if c.mana > w.mana then
		w.pos = save
		d.ready = now + 0.25
		msg(plr, "¡Sin maná!")
		return
	end
	w.mana -= c.mana
	local origin = head.Position + dir * 2.5
	for _, sp in ipairs(list) do castSpec(plr, sp, origin, dir) end
	local wait = math.max(0.05, c.delay)
	if c.wrapped or w.pos > #w.order then
		wait = math.max(wait, w.recharge)
		d.reloadEnd = now + wait
		buildOrder(w)
	end
	d.ready = now + wait
	sendState(plr)
end)

---------------------------------------------------------------- COFRES Y PORTAL
local pendingChoice = {}
game:GetService("ProximityPromptService").PromptTriggered:Connect(function(prompt, plr)
	local i = prompt:GetAttribute("chest")
	if not i or grid[i] ~= CHEST then return end
	local y = math.floor((i - 1) / (SX * SZ)) + 1
	local rem = (i - 1) % (SX * SZ)
	local z = math.floor(rem / SX) + 1
	local x = rem % SX + 1
	setBlock(x, y, z, AIR)
	chestsLeft -= 1
	local tier = 4 - biome(y)
	local choices = {}
	while #choices < 3 do
		local id = randSpell(tier)
		if not table.find(choices, id) then table.insert(choices, id) end
	end
	pendingChoice[plr] = choices
	giveGold(plr, 10 * tier, cellCenter(x, y, z))
	ChoiceEv:FireClient(plr, choices)
end)
ChoiceEv.OnServerEvent:Connect(function(plr, id)
	local ch = pendingChoice[plr]
	if not ch or not table.find(ch, id) then return end
	pendingChoice[plr] = nil
	if addToBag(plr, id) then msg(plr, "Nuevo hechizo: " .. SP[id].n) end
end)

local function startFloor()
	msg(nil, "Generando el piso " .. floorN .. "…")
	local _, _, top = generate()
	populate(top)
	for _, plr in ipairs(Players:GetPlayers()) do
		local ls = plr:FindFirstChild("leaderstats")
		if ls then ls.Piso.Value = floorN end
		local c = plr.Character
		local h = c and c:FindFirstChild("HumanoidRootPart")
		if h then h.CFrame = CFrame.new(spawnPos + Vector3.new(math.random(-4, 4), 4, math.random(-4, 4))) end
		if PD[plr] then
			PD[plr].wand.mana = PD[plr].wand.manaMax
			sendState(plr)
		end
	end
	msg(nil, "Piso " .. floorN .. ": ¡encuentra el portal del fondo!")
end

---------------------------------------------------------------- BUCLE PRINCIPAL
local stateT, fallT, fireT, lavaT = 0, 0, 0, 0
RunService.Heartbeat:Connect(function(dt)
	if generating then return end
	-- maná
	for plr, d in pairs(PD) do
		local w = d.wand
		w.mana = math.min(w.manaMax, w.mana + w.regen * dt)
	end
	stateT += dt
	if stateT > 0.25 then
		stateT = 0
		for plr in pairs(PD) do sendState(plr) end
	end
	-- proyectiles
	rayParams.FilterDescendantsInstances = { blockFolder, mobFolder }
	for k = #projs, 1, -1 do
		local pr = projs[k]
		if pr.dead then
			table.remove(projs, k)
		else
			pr.age += dt
			pr.life -= dt
			if pr.homing > 0 then
				local t = nearestMob(pr.pos, 80)
				if t then
					local sp = pr.vel.Magnitude
					local want = (t.pos - pr.pos).Unit * sp
					pr.vel = pr.vel:Lerp(want, math.clamp(pr.homing * dt, 0, 1)).Unit * sp
				end
			end
			pr.vel += Vector3.new(0, -pr.grav * dt, 0)
			local step = pr.vel * dt
			local res = workspace:Raycast(pr.pos, step, rayParams)
			if res then
				local mob = mobFromPart(res.Instance)
				if mob then
					if not pr.hits[mob] then
						pr.hits[mob] = true
						damageMob(mob, pr.dmg, pr.owner)
						if pr.id == "hielo" then mob.frozen = 2.5 end
						if not pr.pierce then impact(pr, res.Position, res.Normal) end
					end
					if not pr.dead then pr.pos += step end
				elseif pr.dig then
					local cx, cy, cz = cellOf(res.Position - res.Normal * 0.5)
					for dx = -pr.dig, pr.dig do for dy = -pr.dig, pr.dig do for dz = -pr.dig, pr.dig do
						if dx * dx + dy * dy + dz * dz <= pr.dig * pr.dig then breakBlock(cx + dx, cy + dy, cz + dz, pr.owner, 2) end
					end end end
					pr.pos += step
				elseif pr.bounce > 0 then
					pr.bounce -= 1
					local n = res.Normal
					pr.vel = (pr.vel - 2 * pr.vel:Dot(n) * n) * 0.8
					pr.pos = res.Position + n * 0.4
					if pr.id == "sierra" then pr.hits = {} end
				else
					impact(pr, res.Position, res.Normal)
				end
			else
				pr.pos += step
			end
			if not pr.dead then
				pr.part.CFrame = CFrame.lookAt(pr.pos, pr.pos + pr.vel) * (pr.id == "sierra" and CFrame.Angles(0, 0, pr.age * 20) or CFrame.identity)
				if pr.life <= 0 then
					local b = SP[pr.id]
					if pr.boom > 0 or b.water or b.tele then impact(pr, pr.pos, Vector3.yAxis)
					else
						pr.dead = true
						firePayload(pr, pr.pos)
						pr.part:Destroy()
					end
				end
			end
		end
	end
	-- mobs
	for _, mob in pairs(mobs) do
		local def = MOB[mob.kind]
		mob.phase += dt
		mob.cd -= dt
		local target, dist = nearestPlayer(mob.pos, 70)
		local pos = mob.pos
		if mob.frozen > 0 then
			mob.frozen -= dt
			mob.root.Color = Color3.fromRGB(170, 220, 255)
		else
			mob.root.Color = def.col
			if def.fly then
				local want = Vector3.new(math.sin(mob.phase) * 3, math.cos(mob.phase * 1.3) * 2, 0)
				if target then
					local to = target.Position - pos
					if mob.kind == "wisp" then
						local dd = to.Magnitude
						want = to.Unit * def.speed * (dd > 26 and 1 or (dd < 14 and -1 or 0)) + Vector3.new(math.sin(mob.phase * 2) * 4, math.sin(mob.phase * 3) * 2, 0)
						mob.shootCd -= dt
						if mob.shootCd <= 0 and dd < 60 then
							mob.shootCd = 2.4
							local o = Instance.new("Part")
							o.Anchored = true
							o.CanCollide = false
							o.CanQuery = false
							o.Shape = Enum.PartType.Ball
							o.Size = Vector3.new(1, 1, 1)
							o.Material = Enum.Material.Neon
							o.Color = def.col
							o.CFrame = CFrame.new(pos)
							o.Parent = fxFolder
							local v = to.Unit * 28
							task.spawn(function()
								local p = pos
								for _ = 1, 120 do
									local dt2 = task.wait()
									p += v * dt2
									o.CFrame = CFrame.new(p)
									if solidAt(p) then break end
									local hit = false
									for _, plr in ipairs(Players:GetPlayers()) do
										local h = plr.Character and plr.Character:FindFirstChild("HumanoidRootPart")
										local hm = plr.Character and plr.Character:FindFirstChildOfClass("Humanoid")
										if h and hm and (h.Position - p).Magnitude < 3 then hm:TakeDamage(def.dmg); hit = true end
									end
									if hit then break end
								end
								o:Destroy()
							end)
						end
					else
						want = to.Unit * def.speed + Vector3.new(0, math.sin(mob.phase * 6) * 4, 0)
					end
				end
				mob.vel = mob.vel:Lerp(want, math.clamp(dt * 3, 0, 1))
				local np = pos + mob.vel * dt
				if not solidAt(np) then pos = np else mob.vel *= -0.3 end
				if mob.kind == "bat" then
					for _, p in ipairs(mob.model:GetChildren()) do
						local wv = p:IsA("BasePart") and p:GetAttribute("wing")
						if wv then p.Transparency = (math.floor(mob.phase * 12) % 2 == 0) and 0 or 0.6 end
					end
				end
			else
				local half = def.size.Y / 2
				local grounded = solidAt(pos - Vector3.new(0, half + 0.2, 0))
				local vy = mob.vel.Y - 70 * dt
				local hv = Vector3.new(mob.vel.X, 0, mob.vel.Z)
				if target and dist < 60 then
					local to = target.Position - pos
					local flat = Vector3.new(to.X, 0, to.Z)
					if flat.Magnitude > 0.1 then
						if mob.kind == "slime" then
							if grounded and math.random() < dt * 1.6 then vy = 26; hv = flat.Unit * def.speed end
						else
							hv = flat.Unit * def.speed
							if grounded and solidAt(pos + flat.Unit * 3) then vy = 24 end
						end
					end
				end
				if grounded and vy < 0 then vy = 0; if mob.kind == "slime" then hv *= 0.6 end end
				local nx = pos + Vector3.new(hv.X * dt, 0, hv.Z * dt)
				if solidAt(nx) or solidAt(nx + Vector3.new(0, half - 0.5, 0)) then hv = Vector3.zero else pos = nx end
				local ny = pos + Vector3.new(0, vy * dt, 0)
				if vy < 0 and solidAt(ny - Vector3.new(0, half, 0)) then vy = 0
				elseif vy > 0 and solidAt(ny + Vector3.new(0, half, 0)) then vy = 0
				else pos = ny end
				mob.vel = Vector3.new(hv.X, vy, hv.Z)
				local cx, cy, cz = cellOf(pos)
				if get(cx, cy, cz) == LAVA then damageMob(mob, 40 * dt, nil) end
			end
		end
		if mobs[mob.model] then
			mob.pos = pos
			local look = target and Vector3.new(target.Position.X, pos.Y, target.Position.Z) or pos + Vector3.new(0, 0, 1)
			if (look - pos).Magnitude < 0.1 then look = pos + Vector3.new(0, 0, 1) end
			mob.model:PivotTo(CFrame.lookAt(pos, look))
			if target and dist < (def.size.X / 2 + 3) and mob.cd <= 0 and mob.frozen <= 0 then
				mob.cd = 0.9
				local hum = target.Parent:FindFirstChildOfClass("Humanoid")
				if hum then hum:TakeDamage(def.dmg) end
				target.AssemblyLinearVelocity = (target.Position - pos).Unit * 50 + Vector3.new(0, 25, 0)
			end
		end
	end
	-- recogidas
	for orb, info in pairs(pickups) do
		info.t += dt
		orb.CFrame = CFrame.new(info.base + Vector3.new(0, math.sin(info.t * 3) * 0.6, 0))
		for _, plr in ipairs(Players:GetPlayers()) do
			local h = plr.Character and plr.Character:FindFirstChild("HumanoidRootPart")
			if h and (h.Position - orb.Position).Magnitude < 5 then
				if addToBag(plr, info.id) then
					msg(plr, "Nuevo hechizo: " .. SP[info.id].n)
					pickups[orb] = nil
					orb:Destroy()
				end
				break
			end
		end
	end
	-- arena que cae
	fallT += dt
	if fallT > 0.07 and #fallQueue > 0 then
		fallT = 0
		local q = fallQueue
		fallQueue = {}
		for _, c in ipairs(q) do
			local x, y, z = c[1], c[2], c[3]
			if BLOCK[get(x, y, z)] and BLOCK[get(x, y, z)].falls and get(x, y - 1, z) == AIR then
				local id = get(x, y, z)
				setBlock(x, y, z, AIR)
				setBlock(x, y - 1, z, id)
				table.insert(fallQueue, { x, y - 1, z })
				hurtPlayersNear(cellCenter(x, y - 1, z), 3, 15)
			end
		end
	end
	-- fuego
	fireT += dt
	if fireT > 0.25 then
		fireT = 0
		for i, t in pairs(burning) do
			burning[i] = t - 0.25
			local y = math.floor((i - 1) / (SX * SZ)) + 1
			local rem = (i - 1) % (SX * SZ)
			local z = math.floor(rem / SX) + 1
			local x = rem % SX + 1
			for _, d in ipairs(NB) do
				if math.random() < 0.06 then ignite(x + d[1], y + d[2], z + d[3]) end
			end
			hurtPlayersNear(cellCenter(x, y, z), 5, 4)
			for _, mob in pairs(mobs) do if (mob.pos - cellCenter(x, y, z)).Magnitude < 5 then damageMob(mob, 4, nil) end end
			if burning[i] and burning[i] <= 0 then setBlock(x, y, z, AIR) end
		end
	end
	-- lava daña a jugadores
	lavaT += dt
	if lavaT > 0.3 then
		lavaT = 0
		for _, plr in ipairs(Players:GetPlayers()) do
			local h = plr.Character and plr.Character:FindFirstChild("HumanoidRootPart")
			local hm = plr.Character and plr.Character:FindFirstChildOfClass("Humanoid")
			if h and hm and hm.Health > 0 then
				local cx, cy, cz = cellOf(h.Position - Vector3.new(0, 2, 0))
				if get(cx, cy, cz) == LAVA or get(cellOf(h.Position)) == LAVA then hm:TakeDamage(12) end
				if portalPart and (h.Position - portalPart.Position).Magnitude < 7 then
					floorN += 1
					msg(nil, "¡" .. plr.Name .. " encontró el portal!")
					generating = true
					task.spawn(startFloor)
					return
				end
				if h.Position.Y < -30 then h.CFrame = CFrame.new(spawnPos + Vector3.new(0, 4, 0)) end
			end
		end
	end
end)

---------------------------------------------------------------- INICIO
task.spawn(startFloor)
