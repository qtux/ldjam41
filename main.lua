-- Flowly - A flower defense game
--
-- Copyright (C) 2018  Matthias Gazzari, Annemarie Mattmann
--
-- This program is free software: you can redistribute it and/or modify
-- it under the terms of the GNU General Public License as published by
-- the Free Software Foundation, either version 3 of the License, or
-- (at your option) any later version.
--
-- This program is distributed in the hope that it will be useful,
-- but WITHOUT ANY WARRANTY; without even the implied warranty of
-- MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
-- GNU General Public License for more details.
--
-- You should have received a copy of the GNU General Public License
-- along with this program.  If not, see <https://www.gnu.org/licenses/>.

suit = require "suit"

local conf = {
	-- time settings
	t = {
		sunPhase =	{value = 0.5, min = 0, max = 1.75, str = "Sun phase", unit = "times pi"},
		dawn =		{value = 5, min = 0, max = 24, str = "Dawn", unit = "h"},
		sunrise =	{value = 6, min = 0, max = 24, str = "Sunrise", unit = "h"},
		sunset =	{value = 18, min = 0, max = 24, str = "Sunset", unit = "h"},
		dusk =		{value = 19, min = 0, max = 24, str = "Dusk", unit = "h"},
		midnight =	{value = 24, min = 0, max = 24, str = "Midnight", unit = "h"},
		speed =		{value = 10, min = 0, max = 32, str = "Time speedup exponent", unit = ""},
		flowDir =	{value = 1, min = -1, max = 1, str = "Time flow direction", unit = ""},
	},
	-- rain settings
	rain = {
		minLife =	{value = 1, min = 0, max = 5, str = "Minimum drop life", unit = "s"},
		maxLife =	{value = 3, min = 0, max = 5, str = "Maximum drop life", unit = "s"},
		rate =		{value = 2000, min = 0, max = 10000, str = "Emission rate", unit = "Hz"},
		minSpeed =	{value = 600, min = 0, max = 5000, str = "Minimum drop speed", unit = "px/s"},
		maxSpeed =	{value = 1000, min = 0, max = 5000, str = "Maximum drop speed", unit = "px/s"},
		direction =	{value = 0.5, min = 0, max = 2, str = "Rain direction", unit = "times pi"},
		enabled =	{checked = false, text = "let it rain"},
		chance =	{value = 0, min = 0, max = 100, str = "Rain probability per day", unit = "%"},
		duration =	{value = 24 * 3600, min = 0, max = 24 * 3600, str = "Maximum rain duration", unit = "s"},
	},
	-- world settings
	world = {
		horizon = 175,
		w = 4 * 1920,
		h = 1080,
	},
	-- view settings
	view = {
		w = 1920,
		h = 1080,
	},
}

-- current state with their initial values
local state = {
	t = 6*60*60,			-- current time
	nextUpdate = "dusk",	-- next state update time
	sunIntensity = 1,		-- current sun intensity (should be between 0.2 and 1)
	view_offset = 0,		-- camera x offset
	rain = {enabled = false, raining = false, start = 0, stop = 0, duration = 0},
}

function love.load()
	currentState = "game"
	menuState = nil
	hand = nil
	stationaryBeings = {
		redFlower = {},
		tree = {}
	}
	movingBeings = {
		bee = {}
	}

	-- set window properties
	love.window.setTitle("Flower Defence")
	love.window.setMode(conf.view.w, conf.view.h, {resizable=false, vsync=false})

	-- set graphics properties
	love.graphics.setDefaultFilter("nearest", "nearest") -- avoid blurry scaling

	-- load images
	landscape = love.graphics.newImage("assets/landscapeSketch.png")
	--landscape:setWrap("repeat", "clamp")
	landscapeData = love.image.newImageData("assets/landscapeSketch.png")
	grassSprite = love.graphics.newImage("assets/grass.png")
	flowerSprite = love.graphics.newImage("assets/flower.png")
	movingBeingsSprite = love.graphics.newImage("assets/movingbeings.png")

	-- load menu icons which are listed in the initial menuIcons table at the corresponding position
	menuIcons = {time=0, weather=1, stationaryBeings=2, movingBeings=3, menu=5, quit=6}
	local menuIconsSheet = love.image.newImageData("assets/menuIcons.png")
	for main_key, col in pairs(menuIcons) do
		menuIcons[main_key] = {normal=0, hovered=1, active=2}
		for sub_key, row in pairs(menuIcons[main_key]) do
			local iconImgData = love.image.newImageData(32, 32)
			iconImgData:paste(menuIconsSheet, 0, 0, 32 * col, 32 * row, 32, 32)
			menuIcons[main_key][sub_key] = love.graphics.newImage(iconImgData)
		end
	end

	-- stationary beings initialization
	stationaryBeingsList = {
		redFlower = {id=0, count=3, hand={x=16, y=32, quad=love.graphics.newQuad(0,0,16,32,flowerSprite:getDimensions()), name="redFlower"}},
		tree = {id=1, count=1, hand={x=10*16, y=10*16, quad=love.graphics.newQuad(0,4*16,10*16,10*16,flowerSprite:getDimensions()), name="tree"}}
	}
	-- load stationary beings menu icons
	stationaryBeingsMenuIcons = {}
	local stationaryMenuIconsSheet = love.image.newImageData("assets/stationaryMenuIcons.png")
	for species, content in pairs(stationaryBeingsList) do
		stationaryBeingsMenuIcons[species] = {normal=0, hovered=1, active=2}
		for sub_key, row in pairs(stationaryBeingsMenuIcons[species]) do
			local iconImgData = love.image.newImageData(64, 64)
			iconImgData:paste(stationaryMenuIconsSheet, 0, 0, 64 * content["id"], 64 * row, 64, 64)
			stationaryBeingsMenuIcons[species][sub_key] = love.graphics.newImage(iconImgData)
		end
	end
	-- moving beings initialization
	movingBeingsList = {
		{count=0, quad=love.graphics.newQuad(0,0,16,16,movingBeingsSprite:getDimensions()), species="bee"}
	}
	-- load moving beings menu icons
	movingBeingsMenuIcons = {}
	local movingMenuIconsSheet = love.image.newImageData("assets/movingMenuIcons.png")
	for i = 1, #movingBeingsList do
		movingBeingsMenuIcons[i] = {normal=0, hovered=1, active=2}
		for sub_key, row in pairs(movingBeingsMenuIcons[i]) do
			local iconImgData = love.image.newImageData(64, 64)
			iconImgData:paste(movingMenuIconsSheet, 0, 0, 64 * (i-1), 64 * row, 64, 64)
			movingBeingsMenuIcons[i][sub_key] = love.graphics.newImage(iconImgData)
		end
	end

	-- load grass quads (sprite sheet elements)
	grassQuad = {}
	for x = 0, 17 do
		for y = 0, 6 do
			table.insert(grassQuad, love.graphics.newQuad(x*16,y*16,16,16,grassSprite:getDimensions()))
		end
	end
	-- get grass-green pixels
	grass = {}
	for y = 1, landscapeData:getHeight() do
		grass[y] = {}
		for x = 1, landscapeData:getWidth() do
			local r, g, b, a = landscapeData:getPixel(x-1, y-1)
			if g > 0.62 and g < 0.63 then
				table.insert(grass[y], x)
			end
		end
	end
	-- plant grass on grass-green pixels
	layers = {}
	grassBatches = {}
	flowerBatches = {}
	for y = 1, #grass, 8 do
		if #grass[y] > 0 then
			grassBatch = love.graphics.newSpriteBatch(grassSprite, 1000)
			flowerBatch = love.graphics.newSpriteBatch(flowerSprite, 100)
			for x = 1, #grass[y], 8 do
				grassBatch:add(grassQuad[math.random(#grassQuad)], grass[y][x], y, 0, 1, 1+0.008*y)
			end
			table.insert(grassBatches, grassBatch)
			table.insert(flowerBatches, flowerBatch)
			table.insert(layers, y)
		end
	end

	-- load shaders
	local shaderStr = love.filesystem.read("shaders/background.frag")
	backgroundShader = love.graphics.newShader(shaderStr)
	shaderStr = love.filesystem.read("shaders/day_night.frag")
	dayNightShader = love.graphics.newShader(shaderStr)
	shaderStr = love.filesystem.read("shaders/wrap.frag")
	wrapShader = love.graphics.newShader(shaderStr)

	-- initialise canvas
	canvas = love.graphics.newCanvas(conf.world.w, conf.world.h)
	canvas:setWrap("repeat", "clampzero")

	-- play music
	afternoonBirds = love.audio.newSource("assets/sounds/afternoonBirds.ogg", "stream")
	afternoonBirds:setLooping(true)
	nightBirds = love.audio.newSource("assets/sounds/nightingale.ogg", "stream")
	nightBirds:setLooping(true)
	morningBirds = love.audio.newSource("assets/sounds/morningBirds.ogg", "stream")
	morningBirds:setLooping(true)

	-- rain particle system
	local rainDrop = love.graphics.newImage('assets/rain_drop.png')
	rainSystem = love.graphics.newParticleSystem(rainDrop, 100000)
	rainSystem:setColors(255, 255, 255, 255, 255, 255, 255, 0)
	rainSystem:setEmissionArea("uniform", love.graphics.getWidth() * 0.5, love.graphics.getHeight(), 0, false)
end

local checkBeing = {
	redFlower = {
		maxThirstyDays = 6,
		maxAge = 11,
		growSpeed = 3,
		mature = 6
	},
	tree = { -- trees don't age right now
		maxThirstyDays = -1,
		maxAge = -1,
		growSpeed = 1000,
		mature = 0
	}
}
local checkMovingBeing = {
	bee = {
		animationSteps = 2,
		maxHungryDays = 10,
		maxSpeed = 64,
		maxAcceleration = 16
	}
}

function toggleState(old, new)
	if old == new then
		return nil
	else
		return new
	end
end

function round(num, digits)
	local multiplier = 10^digits
	return math.floor(num * multiplier + 0.5) / multiplier
end

function setSlider(var)
	local value = tostring(round(var.value, 2))
	suit.Label(var.str..": "..value.." "..var.unit, {align="left"}, suit.layout:row(300, 16))
	suit.Slider(var, suit.layout:row())
end

function love.update(dt)
	-- update screen content dependent on current state
	if currentState == "menu" then
		if suit.Button("Start Game", 100, 100, 300, 30).hit then
			currentState = "game"
		end
		if suit.Button("Quit", 100, 150, 300, 30).hit then
			love.event.quit(0)
		end
	elseif currentState == "game" then

		----------------
		-- GAME LOGIC --
		----------------

		-- do time calculation
		state.t = state.t + dt * 2^conf.t.speed.value * conf.t.flowDir.value
		local hour = state.t / 3600 % 24
		local minute = state.t / 60 % 60
		local second = state.t % 60
		local day = state.t / (3600 * 24) % 365 + 1
		local year = state.t / (3600 * 24 * 365)
		if hour > conf.t.dawn.value and hour <= conf.t.sunrise.value then
			-- continuous updates
			state.sunIntensity = (1 - ((conf.t.sunrise.value - hour) / (conf.t.sunrise.value - conf.t.dawn.value)))^2 * 0.8 + 0.2

			-- one-shot updates
			if nextUpdate == "dawn" then
				print(nextUpdate)
				love.audio.play(morningBirds)
				love.audio.pause(nightBirds)

				-- check for new possibilities
				if #movingBeings["bee"] < #stationaryBeings["tree"] then
					movingBeingsList[1]["count"] = #stationaryBeings["tree"] - #movingBeings["bee"]
				end

				-- update beings state
				for species, beings in pairs(stationaryBeings) do
					for name, individual in pairs(beings) do
						individual["thirsty"] = individual["thirsty"] + 1
						individual["sleeping"] = false
						-- age
						if checkBeing[individual["species"]]["maxAge"] > 0 then
							individual["age"] = individual["age"] + 1
							-- grow
							if individual["age"] % checkBeing[individual["species"]]["growSpeed"] == 0 then
								local quad = love.graphics.newQuad((individual["age"]/checkBeing[individual["species"]]["growSpeed"])*individual["sizeX"]+individual["quadX"],individual["quadY"],individual["sizeX"],individual["sizeY"],flowerSprite:getDimensions())
								flowerBatches[individual["layer"]]:set(individual["batchID"], quad, individual["posX"], individual["posY"], 0, individual["scaleX"], individual["scaleY"])
							end
							-- die of age
							if individual["state"] ~= "dead" and individual["age"] >= checkBeing[individual["species"]]["maxAge"]*checkBeing[individual["species"]]["growSpeed"] then
								print(individual["pollinated"])
								print(individual["age"])
								individual["state"] = "dead"
								if individual["pollinated"] then
									stationaryBeingsList[individual["species"]]["count"] = stationaryBeingsList[individual["species"]]["count"] + 3
								end
								flowerBatches[individual["layer"]]:set(individual["batchID"], 0, 0, 0, 0, 0)
							end
						end
						--print(individual["species"], individual["age"])
						--print(individual["species"], individual["state"])
					end
				end
			end

			-- set next one-shot update time
			nextUpdate = "day"
		elseif hour > conf.t.sunrise.value and hour <= conf.t.sunset.value then
			-- continuous updates
			state.sunIntensity = 1

			-- one-shot updates
			if nextUpdate == "day" then
				print(nextUpdate)
				love.audio.play(afternoonBirds)
				love.audio.pause(morningBirds)
			end

			-- set next one-shot update time
			nextUpdate = "dusk"
		elseif hour > conf.t.sunset.value and hour <= conf.t.dusk.value then
			-- continuous updates
			state.sunIntensity = ((conf.t.dusk.value - hour) / (conf.t.dusk.value - conf.t.sunset.value))^2 * 0.8 + 0.2

			-- one-shot updates
			if nextUpdate == "dusk" then
				print(nextUpdate)
				love.audio.pause()
				for species, beings in pairs(stationaryBeings) do
					for name, individual in pairs(beings) do
						individual["sleeping"] = true
					end
				end
			end

			-- set next one-shot update time
			nextUpdate = "premidnight"
		elseif hour > conf.t.dusk.value and hour <= conf.t.midnight.value then
			-- continuous updates
			state.sunIntensity = 0.2

			-- one-shot updates
			if nextUpdate == "premidnight" then
				print(nextUpdate)
			end

			-- set next one-shot update time
			nextUpdate = "postmidnight"
		else
			-- continuous updates
			state.sunIntensity = 0.2
			-- one-shot updates
			if nextUpdate == "postmidnight" then
				print(nextUpdate)
				love.audio.play(nightBirds)
				state.rain.enabled = math.random() < (conf.rain.chance.value / 100)
				state.rain.start = state.t + math.random() * 24 * 3600
				state.rain.duration = math.random() * conf.rain.duration.value
				print(state.rain.enabled)
				print(state.rain.start / 3600 % 24)
				print(state.rain.duration)
			end

			-- set next one-shot update time
			nextUpdate = "dawn"
		end

		-- do weather calculation
		rainSystem:setParticleLifetime(conf.rain.minLife.value, conf.rain.maxLife.value)
		rainSystem:setEmissionRate(conf.rain.rate.value)
		rainSystem:setSpeed(conf.rain.minSpeed.value, conf.rain.maxSpeed.value)
		rainSystem:setDirection(math.pi * conf.rain.direction.value)
		-- start rain
		if not state.rain.raining and state.rain.enabled and state.t > state.rain.start then
			state.rain.stop = state.rain.start + state.rain.duration
			state.rain.raining = true
			state.rain.enabled = false
		end
		-- stop rain
		if state.rain.raining and state.t > state.rain.stop then
			state.rain.raining = false
		end
		-- force rain
		state.rain.raining = state.rain.raining or conf.rain.enabled.checked
		-- let it rain
		if state.rain.raining then
			rainSystem:start()
		else
			rainSystem:stop()
		end
		-- update rain droplets
		rainSystem:update(dt)

		-- do animal behaviour update
		-- bee
		for beename, beedividual in pairs(movingBeings["bee"]) do
			if beedividual["target"] == nil and not beedividual["sleeping"] then
				for species, beings in pairs(stationaryBeings) do
					for name, individual in pairs(beings) do
						local checkIndividual = checkBeing[individual["species"]]
						if individual["pollinated"] == false and individual["age"] >= checkIndividual["mature"]*checkIndividual["growSpeed"] and individual["age"] < (checkIndividual["mature"]+1)*checkIndividual["growSpeed"] then
							beedividual["target"] = {
								posX = individual["posX"] + (individual["sizeX"]/2) * individual["scaleX"],
								posY = individual["posY"] + (individual["sizeY"]/3) * individual["scaleY"],
								being = individual
							}
						end
					end
				end
			end
			if beedividual["target"] == nil and not beedividual["sleeping"] then
				beedividual["target"] = beedividual["home"]
				beedividual["target"]["being"] = nil
			end
			if beedividual["target"] ~= nil and not beedividual["sleeping"] then
				-- move
				deltaX = beedividual["target"]["posX"] - beedividual["posX"]
				deltaY = beedividual["target"]["posY"] - beedividual["posY"]
				distance = math.sqrt(math.pow(deltaX,2) + math.pow(deltaY,2))
				if distance < math.pow(beedividual["speed"], 2)/(2 * checkMovingBeing["bee"]["maxAcceleration"]) then
					beedividual["speed"] = math.max(beedividual["speed"] - checkMovingBeing["bee"]["maxAcceleration"] * dt, 0)
				else
					beedividual["speed"] = math.min(beedividual["speed"] + checkMovingBeing["bee"]["maxAcceleration"] * dt, checkMovingBeing["bee"]["maxSpeed"])
				end
				angle = math.atan2(deltaY, deltaX)
				beedividual["posX"] = beedividual["posX"] + beedividual["speed"] * math.cos(angle) * dt * math.random()
				beedividual["posY"] = beedividual["posY"] + beedividual["speed"] * math.sin(angle) * dt * math.random()
				--beedividual["posX"] = beedividual["posX"] + deltaX * (beedividual["speed"]/distance) * dt
				--beedividual["posY"] = beedividual["posY"] + deltaY * (beedividual["speed"]/distance) * dt
				-- check reached goal
				if distance < beedividual["speed"] * dt then --beedividual["posX"] >= beedividual["target"]["posX"] - 2 and beedividual["posX"] <= beedividual["target"]["posX"] + 2 and beedividual["posY"] >= beedividual["target"]["posY"] - 2 and beedividual["posY"] <= beedividual["target"]["posY"] + 2 then
					if beedividual["target"]["being"] then
						beedividual["target"]["being"]["pollinated"] = true
					end
					beedividual["target"] = nil
					beedividual["speed"] = 0
				end
			end
		end

		---------------
		-- RENDERING --
		---------------

		-- update shaders
		dayNightShader:send("intensity", state.sunIntensity)
		wrapShader:send("x_offset", state.view_offset / conf.world.w)
		backgroundShader:send("intensity", state.sunIntensity)
		backgroundShader:send("sun_x", conf.world.w / 4 * math.cos(state.t/3600/24 * 2 * math.pi + conf.t.sunPhase.value * math.pi) + conf.world.w / 2 + state.view_offset)
		backgroundShader:send("sun_y", conf.world.h * math.sin(state.t/3600/24 * 2 * math.pi + conf.t.sunPhase.value * math.pi) + conf.world.horizon)
		backgroundShader:send("sun_r", 50)

		-- render background and landscape to canvas
		love.graphics.setCanvas(canvas)
		love.graphics.clear()
		love.graphics.setShader(backgroundShader)
		love.graphics.rectangle('fill', 0, 0, conf.world.w, conf.world.h)
		love.graphics.setShader(dayNightShader)
		love.graphics.draw(landscape)
		love.graphics.setShader()
		love.graphics.setCanvas()

		----------
		-- GUI  --
		----------

		-- expose main image based menu
		suit.layout:reset(16, 16)
		suit.layout:padding(2, 2)
		if suit.ImageButton(nil, menuIcons["time"], suit.layout:col(32, 32)).hit then
			menuState = toggleState(menuState, "time")
		end
		if suit.ImageButton(nil, menuIcons["weather"], suit.layout:col()).hit then
			menuState = toggleState(menuState, "weather")
		end
		if suit.ImageButton(nil, menuIcons["stationaryBeings"], suit.layout:col()).hit then
			menuState = toggleState(menuState, "stationaryBeings")
		end
		if suit.ImageButton(nil, menuIcons["movingBeings"], suit.layout:col()).hit then
			menuState = toggleState(menuState, "movingBeings")
		end
		if suit.ImageButton(nil, menuIcons["menu"], suit.layout:col()).hit then
			currentState = "menu"
		end
		if suit.ImageButton(nil, menuIcons["quit"], suit.layout:col()).hit then
			love.event.quit(0)
		end

		-- expose time configuration menu
		if menuState == "time" then
			-- reset layout
			suit.layout:reset(100, 100)
			suit.layout:padding(4, 4)
			-- draw sliders for time values
			setSlider(conf.t.flowDir)
			setSlider(conf.t.speed)
			setSlider(conf.t.dawn)
			setSlider(conf.t.sunrise)
			setSlider(conf.t.sunset)
			setSlider(conf.t.dusk)
			setSlider(conf.t.midnight)
			setSlider(conf.t.sunPhase)
			-- show additional time information
			function formatTime(seconds, minutes, hours)
				s = string.format("%02.f", math.floor(seconds))
				m = string.format("%02.f", math.floor(minutes))
				h = string.format("%02.f", math.floor(hours))
				return h..":"..m..":"..s
			end
			suit.Label("Current time: "..formatTime(second, minute, hour).." (day "..tostring(math.floor(day))..", year "..tostring(math.floor(year))..")", {align="left"}, suit.layout:row())
		end

		-- expose weather configuration menu
		if menuState == "weather" then
			-- reset layout
			suit.layout:reset(100, 100)
			suit.layout:padding(4, 4)
			-- draw sliders for weather values
			setSlider(conf.rain.minLife)
			setSlider(conf.rain.maxLife)
			setSlider(conf.rain.rate)
			setSlider(conf.rain.minSpeed)
			setSlider(conf.rain.maxSpeed)
			setSlider(conf.rain.direction)
			setSlider(conf.rain.chance)
			setSlider(conf.rain.duration)
			-- show checkobx to let it rain
			suit.Checkbox(conf.rain.enabled, {align='right'}, suit.layout:row())
			-- show number of emitted rain drops
			suit.Label("Emitted rain drops: "..tostring(rainSystem:getCount()), {align="left"}, suit.layout:row())
		end

		-- expose stationary beings menu (includes plants)
		if menuState == "stationaryBeings" then
			suit.layout:reset(love.graphics.getWidth()/2 - 200, love.graphics.getHeight()/2 - 400)
			suit.layout:padding(10,10)
			for species, content in pairs(stationaryBeingsList) do
				if suit.ImageButton(nil, stationaryBeingsMenuIcons[species], suit.layout:col(64,64)).hit and content["count"] > 0 then
					hand = content["hand"]
					content["count"] = content["count"] - 1
					menuState = nil
				end
				suit.Label(content["count"], suit.layout:col())
			end
		end

		-- expose moving beings menu (includes animals)
		if menuState == "movingBeings" then
			suit.layout:reset(love.graphics.getWidth()/2 - 200, love.graphics.getHeight()/2 - 400)
			suit.layout:padding(10,10)
			for entry = 1, #movingBeingsList do
				if suit.ImageButton(nil, movingBeingsMenuIcons[entry], suit.layout:col(64,64)).hit and movingBeingsList[entry]["count"] > 0 then
					movingBeingsList[entry]["count"] = movingBeingsList[entry]["count"] - 1
					qx, qy, sx, sy = movingBeingsList[entry]["quad"]:getViewport()
					if movingBeingsList[entry]["species"] == "bee" then
						hometree = stationaryBeings["tree"][#movingBeings["bee"]+1]
						px = hometree["posX"] + (hometree["sizeX"]/2) * hometree["scaleX"]
						py = hometree["posY"] + (hometree["sizeY"]/2) * hometree["scaleY"]
					else
						px = math.random(love.graphics.getWidth()/2 - 300, love.graphics.getWidth()/2 + 300)
						py = layers[math.random(#layers)]
					end
					for index,value in ipairs(layers) do
						if value >= py then
							sc = 0.004*value
							ly = index
						end
					end
					table.insert(movingBeings[movingBeingsList[entry]["species"]], {
						quadX = qx,
						quadY = qy,
						sizeX = sx,
						sizeY = sy,
						posX = px,
						posY = py,
						scale = sc,
						layer = ly,
						state = "happy",
						home = {posX=px, posY=py},
						target = nil,
						speed = 0,
						hungry = 0,
						sleeping = false,
						age = 0,
						species = movingBeingsList[entry]["species"]
					})
				end
				suit.Label(movingBeingsList[entry]["count"], suit.layout:col())
			end
		end
	end
end

function love.draw()
	-- draw dependent on current state
	if currentState == "game" then
		-- draw wrapped canvas
		love.graphics.setShader(wrapShader)
		love.graphics.draw(canvas)
		love.graphics.setShader()
		-- draw foreground
		love.graphics.setShader(dayNightShader)
		for index,value in ipairs(layers) do
			love.graphics.draw(grassBatches[index], state.view_offset, 0, 0, 1, 1, 5, 20) -- grass
			love.graphics.draw(flowerBatches[index], state.view_offset, 0, 0, 1, 1, 0, 0)--1+0.008*index) -- flowers
			for species, beings in pairs(movingBeings) do
				for name, individual in pairs(beings) do
					if individual["layer"] == index then
						local quad = love.graphics.newQuad(individual["quadX"],individual["quadY"],individual["sizeX"],individual["sizeY"],movingBeingsSprite:getDimensions())
						love.graphics.draw(movingBeingsSprite, quad, individual["posX"]+state.view_offset, individual["posY"])--, 0, individual["scale"], individual["scale"]) TODO
					end
				end
			end
		end
		-- draw rain particle system
		love.graphics.draw(rainSystem, love.graphics.getWidth() * 0.5, love.graphics.getHeight() * 0.5)
		love.graphics.setShader()
		-- draw items in hand
		if (hand ~= nil) then
			mouse = {}
			mouse.x, mouse.y = love.mouse.getPosition()
			love.graphics.draw(flowerSprite, hand["quad"], mouse.x-20, mouse.y-20)
		end
	end
	-- draw GUI on top of the content
	suit.draw()
end

function love.keypressed(key, scancode, isrepeat)
	-- process key input for GUI
	suit.keypressed(key)
	-- process key input
	if (key == "escape" or key == "q") and (currentState == "game" or currentState == "main_menu") then
		love.event.quit(0)
	end
	if (key == "f") and (currentState == "game") then
		hand = {x=16, y=32, quad=love.graphics.newQuad(0,0,16,32,flowerSprite:getDimensions()), name="redFlower"}
	end
	if (key == "t") and (currentState == "game") then
		hand = {x=10*16, y=10*16, quad=love.graphics.newQuad(0,4*16,10*16,10*16,flowerSprite:getDimensions()), name="tree"}
	end
end

function love.mousepressed(x, y, button, istouch)
	-- process input for GUI
	if (hand ~= nil) then
		mouse = {}
		mouse.x, mouse.y = love.mouse.getPosition()
		-- center standard sized sprite
		spriteOffsetX = hand["x"]/2
		spriteOffsetY = hand["y"]
		mouse.x = (mouse.x - spriteOffsetX - state.view_offset) % conf.world.w
		mouse.y = mouse.y - spriteOffsetY
		for index,value in ipairs(layers) do
			scaleFactor = 0.004*value
			if value >= mouse.y then
				-- store being
				-- flowerSprite is assumed
				qx, qy, sx, sy = hand["quad"]:getViewport()
				px = mouse.x-(spriteOffsetX*scaleFactor)
				py = value-(spriteOffsetY*scaleFactor)
				scx = 1+scaleFactor
				scy = 1+scaleFactor
				table.insert(stationaryBeings[hand["name"]], {
					quadX = qx,
					quadY = qy,
					sizeX = sx,
					sizeY = sy,
					posX = px,
					posY = py,
					scaleX = scx,
					scaleY = scy,
					layer = index,
					batchID = flowerBatches[index]:add(hand["quad"], px, py, 0, scx, scy),
					state = "happy",
					thirsty = 0,
					sleeping = false,
					pollinated = false,
					age = 0,
					species = hand["name"]
				})
				break
			end
		end
		hand = nil
	end
end

function love.textinput(text)
	-- process input for GUI
	suit.textinput(text)
end

function love.wheelmoved(x, y)
	-- process input for GUI
	-- process input dependent on current state
	if currentState == "game" then
		state.view_offset = state.view_offset + y * 100
	end
end
