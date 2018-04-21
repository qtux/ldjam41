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
end

function love.update(dt)
	nk.frameBegin()
	if nk.windowBegin('Flower Defense!!!', 400 - 60, 300 - 60, 120, 120, 'border', 'title', 'movable') then
		nk.layoutRow('dynamic', 30, 1)
		if nk.button('Start Game') then
			print('Starting Game...')
		end
		nk.layoutRow('dynamic', 30, 1)
		if nk.button('Quit') then
			love.event.quit(0)
		end
	end
	nk.windowEnd()
	nk.frameEnd()
end

function love.draw()
	nk.draw()
end

function love.keypressed(key, scancode, isrepeat)
	nk.keypressed(key, scancode, isrepeat)
end

function love.keyreleased(key, scancode)
	nk.keyreleased(key, scancode)
end

function love.mousepressed(x, y, button, istouch)
	nk.mousepressed(x, y, button, istouch)
end

function love.mousereleased(x, y, button, istouch)
	nk.mousereleased(x, y, button, istouch)
end

function love.mousemoved(x, y, dx, dy, istouch)
	nk.mousemoved(x, y, dx, dy, istouch)
end

function love.textinput(text)
	nk.textinput(text)
end

function love.wheelmoved(x, y)
	nk.wheelmoved(x, y)
end
