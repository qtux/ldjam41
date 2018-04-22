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

function love.load()
	currentState = "game"

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
	grassBatch = love.graphics.newSpriteBatch(grassSprite, 1000)
	for y = 1, #grass, 8 do
		for x = 1, #grass[y], 8 do
			grassBatch:add(grassQuad[math.random(#grassQuad)], grass[y][x], y, 0, 1, 1+0.008*y)
		end
	end

	-- load shaders
	local shaderStr = love.filesystem.read("shaders/background.frag")
	backgroundShader = love.graphics.newShader(shaderStr)
	shaderStr = love.filesystem.read("shaders/day_night.frag")
	dayNightShader = love.graphics.newShader(shaderStr)

	-- initialize global time
	t = 0

	-- play music
	afternoonBirds = love.audio.newSource("assets/sounds/afternoonBirds.ogg", "stream")
	afternoonBirds:setLooping(true)
	love.audio.play(afternoonBirds)
end

function love.update(dt)
	-- update content dependent on current state
	if currentState == "game" then
		-- do time calculation
		local speedup = 10000
		t = t + dt * speedup
		local phase = math.pi / 2;
		local horizon = 175
		local hour = t / 3600 % 24
		local dawn = 5
		local sunrise = 6
		local sunset = 18
		local dusk = 19
		local intensity
		if hour > dawn and hour <= sunrise then
			intensity = (1 - ((sunrise - hour) / (sunrise - dawn)))^2 * 0.8 + 0.2
		elseif hour > sunrise and hour <= sunset then
			intensity = 1
		elseif hour > sunset and hour <= dusk then
			intensity = ((dusk - hour) / (dusk - sunset))^2 * 0.8 + 0.2
		else
			intensity = 0.2
		end
		dayNightShader:send("intensity", intensity)
		backgroundShader:send("intensity", intensity)
		backgroundShader:send("sun_x", 1920 * math.cos(t/3600/24 * 2 * math.pi + phase) + 1920 * 2 + view)
		backgroundShader:send("sun_y", 1080 * math.sin(t/3600/24 * 2 * math.pi + phase) + horizon)
		backgroundShader:send("sun_r", 50)
	end
end

function love.draw()
	-- draw dependent on current state
	if currentState == "game" then
		love.graphics.setShader(backgroundShader)
		love.graphics.rectangle('fill', 0, 0, 1920, 1080)
		love.graphics.setShader(dayNightShader)
		love.graphics.draw(landscape, view, 0) -- background
		love.graphics.draw(grassBatch, view, 0, 0, 1, 1, 5, 20) -- grass
		love.graphics.setShader()
	end
	-- draw GUI on top of the content
end

function love.keypressed(key, scancode, isrepeat)
	-- process input for GUI
	if (key == "escape" or key == "q") and (currentState == "game" or currentState == "main_menu") then
		love.event.quit(0)
	end
end

function love.keyreleased(key, scancode)
	-- process input for GUI
end

function love.mousepressed(x, y, button, istouch)
	-- process input for GUI
end

function love.mousereleased(x, y, button, istouch)
	-- process input for GUI
end

function love.mousemoved(x, y, dx, dy, istouch)
	-- process input for GUI
end

function love.textinput(text)
	-- process input for GUI
end

function love.wheelmoved(x, y)
	-- process input for GUI
	-- process input dependent on current state
	if currentState == "game" then
		if y > 0 then
			view = view + y*100
		elseif y < 0 then
			view = view + y*100
		end
	end
end
