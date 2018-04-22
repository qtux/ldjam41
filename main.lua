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


-- load love-nuklear
package.cpath = package.cpath .. ";./love-nuklear/?.so"
local nk = require 'nuklear'

function love.load()
	nk.init()
	currentState = "main_menu"

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

	-- play music
	afternoonBirds = love.audio.newSource("assets/sounds/afternoonBirds.ogg", "stream")
	afternoonBirds:setLooping(true)
	love.audio.play(afternoonBirds)
end

function love.update(dt)
	-- update GUI dependent on current state
	nk.frameBegin()
	if currentState == "main_menu" then
		if nk.windowBegin('Flower Defense!!!', 400 - 60, 300 - 60, 120, 120, 'border', 'title', 'movable') then
			nk.layoutRow('dynamic', 30, 1)
			if nk.button('Start Game') then
				currentState = "game"
			end
			nk.layoutRow('dynamic', 30, 1)
			if nk.button('Quit') then
				love.event.quit(0)
			end
		end
	elseif currentState == "game" then
		if nk.windowBegin('Game Controls', 0, 0, 120, 120, 'border', 'title', 'movable') then
			nk.layoutRow('dynamic', 30, 1)
			if nk.button('Exit to Menu') then
				currentState = "main_menu"
			end
			nk.layoutRow('dynamic', 30, 1)
			if nk.button('Quit') then
				love.event.quit(0)
			end
		end
	end
	nk.windowEnd()
	nk.frameEnd()
	-- update content dependent on current state
end

function love.draw()
	-- draw dependent on current state
	if currentState == "game" then
		love.graphics.draw(landscape, view, 0) -- background
		love.graphics.draw(grassBatch, view, 0, 0, 1, 1, 5, 20) -- grass
	end
	-- draw GUI on top of the content
	nk.draw()
end

function love.keypressed(key, scancode, isrepeat)
	-- process input for GUI
	nk.keypressed(key, scancode, isrepeat)
end

function love.keyreleased(key, scancode)
	-- process input for GUI
	nk.keyreleased(key, scancode)
end

function love.mousepressed(x, y, button, istouch)
	-- process input for GUI
	nk.mousepressed(x, y, button, istouch)
end

function love.mousereleased(x, y, button, istouch)
	-- process input for GUI
	nk.mousereleased(x, y, button, istouch)
end

function love.mousemoved(x, y, dx, dy, istouch)
	-- process input for GUI
	nk.mousemoved(x, y, dx, dy, istouch)
end

function love.textinput(text)
	-- process input for GUI
	nk.textinput(text)
end

function love.wheelmoved(x, y)
	-- process input for GUI
	nk.wheelmoved(x, y)
	-- process input dependent on current state
	if currentState == "game" then
		if y > 0 then
			view = view + y*100
		elseif y < 0 then
			view = view + y*100
		end
	end
end
