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

function love.load()
	currentState = "game"
	menuState = nil
	hand = nil

	-- set window properties
	love.window.setTitle("Flower Defence")
	love.window.setMode(1920, 1080, {resizable=true, vsync=false, minwidth=600, minheight=400})

	-- set graphics properties
	love.graphics.setDefaultFilter("nearest", "nearest") -- avoid blurry scaling
	view = 0 -- initial camera x offset

	-- load images
	landscape = love.graphics.newImage("assets/landscapeSketch.png")
	--landscape:setWrap("repeat", "clamp")
	landscapeData = love.image.newImageData("assets/landscapeSketch.png")
	grassSprite = love.graphics.newImage("assets/grass.png")
	flowerSprite = love.graphics.newImage("assets/flower.png")

	-- load menu icons which are listed in the initial menuIcons table at the corresponding position
	menuIcons = {time=0, weather=1, stationaryBeings=2, menu=5, quit=6}
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
		{count=3, hand={x=16, y=32, quad=love.graphics.newQuad(96,0,16,32,flowerSprite:getDimensions())}}, -- red flower
		{count=1, hand={x=10*16, y=10*16, quad=love.graphics.newQuad(0,4*16,10*16,10*16,flowerSprite:getDimensions())}} -- tree
	}
	-- load stationary beings menu icons
	stationaryBeingsMenuIcons = {}
	local stationaryMenuIconsSheet = love.image.newImageData("assets/stationaryMenuIcons.png")
	for i = 1, #stationaryBeingsList do
		stationaryBeingsMenuIcons[i] = {normal=0, hovered=1, active=2}
		for sub_key, row in pairs(stationaryBeingsMenuIcons[i]) do
			local iconImgData = love.image.newImageData(64, 64)
			iconImgData:paste(stationaryMenuIconsSheet, 0, 0, 64 * (i-1), 64 * row, 64, 64)
			stationaryBeingsMenuIcons[i][sub_key] = love.graphics.newImage(iconImgData)
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
	canvas = love.graphics.newCanvas(4 * 1920, 1080)
	canvas:setWrap("repeat", "clampzero")

	-- initialize global time
	t = 0

	-- play music
	afternoonBirds = love.audio.newSource("assets/sounds/afternoonBirds.ogg", "stream")
	afternoonBirds:setLooping(true)
	nightBirds = love.audio.newSource("assets/sounds/nightingale.ogg", "stream")
	nightBirds:setLooping(true)
	morningBirds = love.audio.newSource("assets/sounds/morningBirds.ogg", "stream")
	morningBirds:setLooping(true)
end

local conf = {
	-- time settings
	t = {
		sunPhase =	{value = 0.5, min = 0, max = 1.75, str = "Sun phase", unit = "times pi"},
		dawn =		{value = 5, min = 0, max = 24, str = "Dawn", unit = "h"},
		sunrise =	{value = 6, min = 0, max = 24, str = "Sunrise", unit = "h"},
		sunset =	{value = 18, min = 0, max = 24, str = "Sunset", unit = "h"},
		dusk =		{value = 19, min = 0, max = 24, str = "Dusk", unit = "h"},
		speed =		{value = 10, min = 0, max = 32, str = "Time speedup exponent", unit = ""},
		flowDir =	{value = 1, min = -1, max = 1, str = "Time flow direction", unit = ""},
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

function love.update(dt)
	-- update content dependent on current state
	if currentState == "menu" then
		if suit.Button("Start Game", 100, 100, 300, 30).hit then
			currentState = "game"
		end
		if suit.Button("Quit", 100, 150, 300, 30).hit then
			love.event.quit(0)
		end
	elseif currentState == "game" then
		-- check GUI input
		if suit.ImageButton(nil, menuIcons["time"], 16, 16).hit then
			menuState = toggleState(menuState, "time")
		end
		if suit.ImageButton(nil, menuIcons["stationaryBeings"], 18+32*1, 16).hit then
			menuState = toggleState(menuState, "stationaryBeings")
		end
		if suit.ImageButton(nil, menuIcons["menu"], 20+32*2, 16).hit then
			currentState = "menu"
		end
		if suit.ImageButton(nil, menuIcons["quit"], 22+32*3, 16).hit then
			love.event.quit(0)
		end
		-- stationary beings menu (includes plants)
		if menuState == "stationaryBeings" then
			suit.layout:reset(love.graphics.getWidth()/2 - 200, love.graphics.getHeight()/2 - 400)
			suit.layout:padding(10,10)
			for entry = 1, #stationaryBeingsList do
				if suit.ImageButton(nil, stationaryBeingsMenuIcons[entry], suit.layout:col(64,64)).hit and stationaryBeingsList[entry]["count"] > 0 then
					hand = stationaryBeingsList[entry]["hand"]
					stationaryBeingsList[entry]["count"] = stationaryBeingsList[entry]["count"] - 1
					menuState = nil
				end
				suit.Label(stationaryBeingsList[entry]["count"], suit.layout:col())
			end
		end
		-- do time calculation
		t = t + dt * 2^conf.t.speed.value * conf.t.flowDir.value
		local horizon = 175
		local hour = t / 3600 % 24
		local minute = t / 60 % 60
		local second = t % 60
		local day = t / (3600 * 24) % 365 + 1
		local year = t / (3600 * 24 * 365)
		local intensity
		if hour > conf.t.dawn.value and hour <= conf.t.sunrise.value then
			intensity = (1 - ((conf.t.sunrise.value - hour) / (conf.t.sunrise.value - conf.t.dawn.value)))^2 * 0.8 + 0.2
			love.audio.play(morningBirds)
			love.audio.pause(nightBirds)
		elseif hour > conf.t.sunrise.value and hour <= conf.t.sunset.value then
			intensity = 1
			love.audio.play(afternoonBirds)
			love.audio.pause(morningBirds)
		elseif hour > conf.t.sunset.value and hour <= conf.t.dusk.value then
			intensity = ((conf.t.dusk.value - hour) / (conf.t.dusk.value - conf.t.sunset.value))^2 * 0.8 + 0.2
			love.audio.pause()
		else
			intensity = 0.2
			love.audio.play(nightBirds)
		end
		dayNightShader:send("intensity", intensity)
		wrapShader:send("x_offset", view/(1920 * 4))
		backgroundShader:send("intensity", intensity)
		backgroundShader:send("sun_x", 1920 * math.cos(t/3600/24 * 2 * math.pi + conf.t.sunPhase.value * math.pi) + 1920 * 2 + view)
		backgroundShader:send("sun_y", 1080 * math.sin(t/3600/24 * 2 * math.pi + conf.t.sunPhase.value * math.pi) + horizon)
		backgroundShader:send("sun_r", 50)
		-- expose time configuration menu
		if menuState == "time" then
			-- reset layout
			suit.layout:reset(100, 100)
			suit.layout:padding(4, 4)
			-- draw sliders for time values
			function setSlider(var)
				local value = tostring(round(var.value, 2))
				suit.Label(var.str..": "..value.." "..var.unit, {align="left"}, suit.layout:row(300, 16))
				suit.Slider(var, suit.layout:row())
			end
			setSlider(conf.t.flowDir)
			setSlider(conf.t.speed)
			setSlider(conf.t.dawn)
			setSlider(conf.t.sunrise)
			setSlider(conf.t.sunset)
			setSlider(conf.t.dusk)
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
		-- render background and landscape to canvas
		love.graphics.setCanvas(canvas)
		love.graphics.clear()
		love.graphics.setShader(backgroundShader)
		love.graphics.rectangle('fill', 0, 0, 1920*4, 1080)
		love.graphics.setShader(dayNightShader)
		love.graphics.draw(landscape)
		love.graphics.setShader()
		love.graphics.setCanvas()
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
			love.graphics.draw(grassBatches[index], view, 0, 0, 1, 1, 5, 20) -- grass
			love.graphics.draw(flowerBatches[index], view, 0, 0, 1, 1, 0, 0)--1+0.008*index) -- flowers
		end
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
		hand = {x=16, y=32, quad=love.graphics.newQuad(96,0,16,32,flowerSprite:getDimensions())}
	end
	if (key == "t") and (currentState == "game") then
		hand = {x=10*16, y=10*16, quad=love.graphics.newQuad(0,4*16,10*16,10*16,flowerSprite:getDimensions())}
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
		mouse.x = (mouse.x - spriteOffsetX - view) % (4 * 1920)
		mouse.y = mouse.y - spriteOffsetY
		for index,value in ipairs(layers) do
			scaleFactor = 0.004*value
			if value >= mouse.y then
				flowerBatches[index]:add(hand["quad"], mouse.x-(spriteOffsetX*scaleFactor), value-(spriteOffsetY*scaleFactor), 0, 1+scaleFactor, 1+scaleFactor)
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
		view = view + y * 100
	end
end
