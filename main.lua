-- title:  Asteroids
-- author: Mansour
-- desc:   The Classic Asteroids game
-- script: lua

-- the comment below this is just for me testing out the fonts
-- ABCDEFGHIJKLMNOPQRSTUVWXYZ, abcdefghijklmnopqrstuv, 1234567890, -+=_{}[]|\/<>()&*%^#$!@~`

-- game state control
STATE_INIT = 5
STATE_START = 8
STATE_PLAY = 10
STATE_SHIP_KILLED = 12
STATE_SHIP_KILL_DELAY = 14
STATE_WAIT_RESPAWN = 16
STATE_NEW_LEVEL_DELAY = 18
STATE_END = 20

gameState = STATE_INIT

SCREEN_MAX_X = 240
SCREEN_MAX_Y = 136


-- table holding playerShip data
playerShip = {
	position = {
		x = 100,
		y = 60
	},
	velocity = {
		speed = 0,
		direction = 0
	},
	acceleration = 0.05,
	deceleration = 0.01,
	rotation = 0,
	rotationSpeed = 0.07,
	radius = 10,
	points = {
		{x=8,y=0, colour = 6},
		{x=-8,y=6, colour = 6},
		{x=-4,y=0, colour = 6},
		{x=-8,y=-6, colour = 6},
		{x=8,y=0, colour = 6}
	}
}

playerScore = 0
playerLevel = 1
playerLives = 3
playerBullets = {}
MAX_PLAYER_BULLETS = 4
PLAYER_BULLET_SPEED = 2
PLAYER_BULLET_TIME = 60
playerBulletOffset = {
	x=8,
	y=0
}
playerThrustOffset = {
	x=-5,
	y=0
}
MIN_RESPAWN_DIST = 30-- to spawn back into the world, you have to be 30 pixels away from an enemy ship or asteroid

asteroids = {}-- in lua tables are indexed at 1
NUM_ASTEROIDS = 10
ASTEROID_NUM_POINTS = 10
ASTEROID_RAD = 15
ASTEROID_RAD_PLUS = 4
ASTEROID_RAD_MINUS = 6
ASTEROID_MAX_VEL = 0.5
ASTEROID_MIN_VEL = 0.1
ASTEROID_MAX_ROT = 0.03

particles = {}
explosionColours = {6,9,14}
smokeColours = {3,7,10,15}

alienShip = {}
alienBullets = {}
MAX_ALIEN_BULLETS = 1
ALIEN_BULLET_SPEED = 2
ALIEN_BULLET_TIME = 60
ALIEN_BULLET_AIM = math.pi / 3

delayTimer = 0

function TIC()-- the TIC method is the qualivent of the main() method in other programming languages, or in other words, the entry point of the game

	if gameState == STATE_INIT then
		initGame()
		gameState = STATE_START
	elseif gameState == STATE_START then
		doStartScreen()
	elseif gameState == STATE_PLAY then
		doPlayGame()
	elseif gameState == STATE_SHIP_KILLED then
		doShipKilled()
	elseif gameState == STATE_SHIP_KILL_DELAY then
		doShipKillDelay()
	elseif gameState == STATE_WAIT_RESPAWN then
		doShipRespawn()
	elseif gameState == STATE_NEW_LEVEL_DELAY then
		doNewLevelDelay()
	elseif gameState == STATE_END then
		doEndScreen()
	end

end

function doStartScreen()

	doNoShipDisplay()
	
	print ("ASTEROIDS", 80,40)
	print ("press Z to start", 60,60)
	if btnp(4) then
		initGame()
		gameState = STATE_PLAY		
	end

end -- doStartScreen()

function doEndScreen()

	doNoShipDisplay()
	
	print ("GAME OVER", 80,40)
	print ("press Z to start", 60,60)
	if btnp(4) then
		initGame()
		gameState = STATE_PLAY
	end

end -- doEndScreen()

function doPlayGame()

	cls()
	
	-- update
	checkPlayerButtons()
	movePlayerShip()
	moveAlienShip()
	moveAsteroids()
	if checkShipCrash() then
		gameState = STATE_SHIP_KILLED
	end -- if
	movePlayerBullets()
	moveAlienBullets()
	checkBulletHits()
	moveParticles()
	
	-- draw
	drawVectorShape(playerShip)
	drawAsteroids()
	drawAlienShip()
	drawPlayerBullets()
	drawAlienBullets()
	drawParticles()
	drawGameInfo()
	
	if #asteroids == 0 then
		-- new level
		playerLevel = playerLevel + 1
		delayTimer = 180
		gameState = STATE_NEW_LEVEL_DELAY
	end -- if

end -- doPlayGame()

function doShipKilled()
	-- do explosion
 sfx(2,10,30,3,15)
	
	particleExplosion(playerShip, 500, 2,
		90, explosionColours, 3, 0.015)
	
	playerLives = playerLives -1
	delayTimer = 180
	gameState = STATE_SHIP_KILL_DELAY
end -- doShipKilled

function doShipKillDelay()

	doNoShipDisplay()

	-- wait for explosion to finish
	delayTimer = delayTimer - 1
	if delayTimer == 0 then
		-- delay finished
		if playerLives == 0 then
			-- game over
			gameState = STATE_END
		else
			-- respawn playerShip
			resetPlayerShip()
			gameState = STATE_WAIT_RESPAWN
		end -- if
	end -- if
	
end -- doShipKillDelay

function doNewLevelDelay()
	
	cls()

	-- update
	checkPlayerButtons()
	movePlayerShip()
	movePlayerBullets()
	checkBulletHits()
	moveParticles()
	
	-- draw
	drawVectorShape(playerShip)
	drawPlayerBullets()
	drawParticles()
	drawGameInfo()

	-- wait for explosion to finish
	delayTimer = delayTimer - 1
	if delayTimer == 0 then
		-- delay finished
		generateAsteroids()
		gameState = STATE_PLAY
	end -- if
	
end -- doNewLevelDelay

function doShipRespawn()

	doNoShipDisplay()
	
	local asteroidTooClose = false
	index = 1
	while(index <= #asteroids) and
		(not asteroidTooClose) do
		if checkSeparation(playerShip.position,
			asteroids[index].position,
			MIN_RESPAWN_DIST) then
			asteroidTooClose = true
		end --if
		index = index + 1
	end -- while

	if not asteroidTooClose then
		gameState = STATE_PLAY
	end -- if

end -- doShipRespawn

function doNoShipDisplay()

	cls()
	
	-- update
	moveAsteroids()
	movePlayerBullets()
	moveAlienBullets()
	moveAlienShip()
	checkBulletHits()
	moveParticles()
	
	-- draw
	drawAsteroids()
	drawPlayerBullets()
	drawAlienBullets()
	drawAlienShip()
	drawParticles()
	drawGameInfo()
	
end -- do NoShipDisplay

function initGame()
	playerScore = 0
	playerLevel = 1
	playerLives = 3
	resetPlayerShip()
	generateAsteroids()
	initAlienShip()
end -- initGame

function resetPlayerShip()
	playerShip.position = {
		x = 100,
		y = 60
	}
	playerShip.velocity = {
		speed = 0,
		direction = 0
	}
	playerShip.rotation = 0
		
end -- resetPlayerShip()

function drawGameInfo()
	local width = 0
	width = print("Score : ",0,0,14)
	width = width + print(playerScore, width,0,11)
	width = width + print("  Level : ", width,0,14)
	width = width + print(playerLevel, width,0,11)
	
	for count = 0,playerLives-2 do
		spr(1,230-(count * 6),0,0)
	end

end -- drawGameInfo

function drawVectorShape(shape)

	local firstPoint = true
	local lastPoint = 0
	local rotatedPoint = 0
	for index, point in ipairs(shape.points) do
	
		rotatedPoint = rotatePoint(point,shape.rotation)
	
		if firstPoint then
			lastPoint = rotatedPoint
			firstPoint = false
		else
			line(lastPoint.x + shape.position.x,
			 lastPoint.y + shape.position.y,
				rotatedPoint.x + shape.position.x,
				rotatedPoint.y + shape.position.y,
				point.colour)
				lastPoint = rotatedPoint
		end
	
	end -- for

end -- drawVectorShape

function rotatePoint(point, rotation)

	local rotatedX =
		(point.x * math.cos(rotation))
		- (point.y * math.sin(rotation))
		
	local rotatedY =
		(point.y * math.cos(rotation))
		+ (point.x * math.sin(rotation))
		
	return {x=rotatedX, y=rotatedY}

end -- rotatePoint

function checkPlayerButtons()
	
	-- thrust
	if btn(0) then -- up key
		playerShipThrust()
	end -- if
	
	if btn(2) then -- left
		playerShip.rotation = playerShip.rotation
			- playerShip.rotationSpeed
	end
	if  btn(3) then -- right
		playerShip.rotation = playerShip.rotation
			+ playerShip.rotationSpeed
	end
	
	playerShip.rotation = 
		keepAngleInRange(playerShip.rotation)
		
	if btnp(4) then -- fire Z
		firePlayerBullet()
	end

end -- checkPlayerButtons

function keepAngleInRange(angle)

	if angle < 0 then
		while angle < 0 do
			angle = angle + (2 * math.pi)
		end
	end
	if angle > (2 * math.pi) then
		while angle > (2 * math.pi) do
			angle = angle - (2 * math.pi)
		end
	end
	
	return angle

end -- keepAngleInRange

function movePointByVelocity(object)

	components =
		getVectorComponents(object.velocity)
	
	local newPosition = {
		x = object.position.x 
						+ components.xComp,
		y = object.position.y 
						+ components.yComp
	}
	
	return newPosition

end -- movePointByVelocity

function 	movePlayerShip()
	
	playerShip.velocity.speed = 
		playerShip.velocity.speed - 
			playerShip.deceleration
	
	if playerShip.velocity.speed < 0 then
		playerShip.velocity.speed = 0
	end

	playerShip.position = 
		movePointByVelocity(playerShip)
		
	playerShip.position = 
		wrapPosition(playerShip.position)

end -- movePlayerShip

function playerShipThrust()

	local acceleration = {
		speed = playerShip.acceleration,
		direction = playerShip.rotation
	}
	
	playerShip.velocity = 
		addVectors(playerShip.velocity,
			acceleration)
			
	sfx(3,10,10,3,-8,1)
	
	local particleVelocity = {}
	local direction = 0
	local relSpawnPosition =
			rotatePoint(playerThrustOffset,
				playerShip.rotation)
	local spawnPosition = {
		x = relSpawnPosition.x + playerShip.position.x,
		y = relSpawnPosition.y + playerShip.position.y
	}
	for particle = 1, 5 do
		direction = playerShip.rotation + math.pi
			+ (math.random() * math.pi / 6) - (math.pi / 12)
		direction = keepAngleInRange(direction)
		particleVelocity = {
			speed = math.random() * 2,
			direction = direction
		}
		spawnParticle(spawnPosition,
			particleVelocity,30, smokeColours,
			1, 0.01, math.random(1,2))
	end -- for 

end -- playerShipThrust

function firePlayerBullet()
	local bullet = {}
	if #playerBullets <= MAX_PLAYER_BULLETS then
		-- ok to fire
		local relSpawnPosition =
			rotatePoint(playerBulletOffset,
				playerShip.rotation)
		bullet = {
			position = {
				x = relSpawnPosition.x
					+ playerShip.position.x,
				y = relSpawnPosition.y
					+ playerShip.position.y 
			},
			velocity = {
				speed = PLAYER_BULLET_SPEED,
				direction = playerShip.rotation
			},
			timer = PLAYER_BULLET_TIME
		}
		table.insert(playerBullets, bullet)
		sfx(0,40,20,0,15,1)
	end
end -- firePlayerBullet

function movePlayerBullets()
	for index, bullet in ipairs(playerBullets) do
		bullet.timer = bullet.timer - 1
		if bullet.timer < 0 then
			-- kill bullet
			table.remove(playerBullets, index)
		else
			-- move bullet
			bullet.position = 
				movePointByVelocity(bullet)
		
			bullet.position = 
				wrapPosition(bullet.position)
				
		end -- if
	end -- for
end

function drawPlayerBullets()
	for index, bullet in ipairs(playerBullets) do
		spr(0,
			bullet.position.x,
			bullet.position.y, 0)
	end -- for
end -- drawPlayerBullets

function checkBulletHits()
	
	local bulletHasHit = false
	for bIndex, bullet in ipairs(playerBullets) do
		for aIndex, asteroid in ipairs(asteroids) do	
			-- course check
			if(checkSeparation(bullet.position,
				asteroid.position,
				ASTEROID_RAD + ASTEROID_RAD_PLUS)) then
				
				if pointInPolygon(bullet.position, asteroid) then
				 -- kill this bullet
					table.remove(playerBullets, bIndex)
					explodeAsteroid(aIndex, asteroid)
					break
				end -- if pointInPolygon
				
			end -- if checkSeparation
			
			
		end -- for asteroid
	end -- for bullet
	
	-- alien ship
	if alienShip.active == true then
		for bIndex, bullet in ipairs(playerBullets) do
	
			if(checkSeparation(bullet.position,
				alienShip.position,
				alienShip.radius)) then
				
				if pointInPolygon(bullet.position, alienShip) then
				 -- kill this bullet
					table.remove(playerBullets, bIndex)
					explodeAlienShip()
					break
				end -- if pointInPolygon			
			end -- if checkSeparation	
		end -- for bullet
	end -- if active
	
end -- checkBulletHits()

function checkShipCrash()
	local index = 1 -- set to first asteroid
	local shipCrashed = false
	while (index <= #asteroids) and (not shipCrashed) do
		shipCrashed =
			polygonInPolygon(playerShip, asteroids[index])
		index = index + 1
	end -- while
	
	-- check ship / alien ship
	if (not shipCrashed) and alienShip.active then
	 shipCrashed =
			polygonInPolygon(playerShip, alienShip)
	end -- if
	
	-- alien bullets
	index = 1 -- set to first bullet
	while (index <= #alienBullets) and (not shipCrashed) do
		shipCrashed =
			pointInPolygon(alienBullets[index].position, playerShip)
		if shipCrashed then
			table.remove(alienBullets, index)
		end
		index = index + 1
	end -- while
	
	return shipCrashed
end -- checkShipCrash()

function polygonInPolygon(shape1, shape2)

	local testPoint = {}
	local rotatedPoint = {}
	
	-- course check
	if(checkSeparation(shape1.position,
		shape2.position,
		shape1.radius + shape2.radius)) then
	
		-- first shape points in second shape?
		for index,point in ipairs(shape1.points) do
			rotatedPoint = rotatePoint(point,shape1.rotation)
			testPoint = {
				x = rotatedPoint.x + shape1.position.x,
				y = rotatedPoint.y + shape1.position.y
			}
			if pointInPolygon(testPoint, shape2) then
				return true
			end -- if
		end -- for
	
		-- second shape points in first shape?
		for index,point in ipairs(shape2.points) do
			rotatedPoint = rotatePoint(point,shape2.rotation)
			testPoint = {
				x = rotatedPoint.x + shape2.position.x,
				y = rotatedPoint.y + shape2.position.y
			}
			if pointInPolygon(point, shape1) then
				return true
			end -- if
		end -- for
	end -- course detection
	
	return false
	
end -- polygonInPolygon

function pointInPolygon(point, shape)

	local firstPoint = true
	local lastPoint = 0
	local rotatedPoint = 0
	local onRight = 0
	local onLeft = 0
	local xCrossing = 0
	
	for index,shapePoint in ipairs(shape.points) do
	
		rotatedPoint = rotatePoint(shapePoint,shape.rotation)
	
		if firstPoint then
			lastPoint = rotatedPoint
			firstPoint = false
		else
			startPoint = {
				x = lastPoint.x + shape.position.x,
			 y = lastPoint.y + shape.position.y
			}
			endPoint = {
				x = rotatedPoint.x + shape.position.x,
				y = rotatedPoint.y + shape.position.y
			}
			if ((startPoint.y >= point.y) and (endPoint.y < point.y))
				or ((startPoint.y < point.y) and (endPoint.y >= point.y)) then
				-- line crosses ray
				if (startPoint.x <= point.x) and (endPoint.x <= point.x) then
					-- line is to left
					onLeft = onLeft + 1
				elseif (startPoint.x >= point.x) and (endPoint.x >= point.x) then
					-- line is to right
					onRight = onRight + 1
				else
					-- need to calculate crossing x coordinate
					if (startPoint.y ~= endPoint.y) then
						-- filter out horizontal line
						xCrossing = startPoint.x +
							((point.y - startPoint.y)
							* (endPoint.x - startPoint.x)
							/ (endPoint.y - startPoint.y))
						if (xCrossing >= point.x) then
							onRight = onRight + 1
						else
							onLeft = onLeft + 1
						end -- if
					end -- if horizontal
				end -- if
			end -- if crosses ray
				
			lastPoint = rotatedPoint
		end
	
	end -- for

	-- only need to check on side
	if (onRight % 2) == 1 then
		-- odd = inside
		return true
	else
		return false
	end

end -- pointInPolygon

function checkSeparation(point1, point2, separation)
	-- leaving as squares removes need
	-- to do a sqrt
	local separationSq = separation * separation
	local distanceSq =
		((point1.x - point2.x) * (point1.x - point2.x))
		+ ((point1.y - point2.y) * (point1.y - point2.y))
	return (distanceSq <= separationSq)
end -- getDistance

function explodeAsteroid(index, asteroid)
	-- get position of exploded asteroid
	local position = asteroid.position
	local orgScale = asteroid.scale
	
	playerScore =
		playerScore + (50 * orgScale)
	sfx(1, 1, 50, 1, 15)
	
	particleExplosion(asteroid, 60, 1,
		30, explosionColours, 3, 0.01)
	
	-- delete exploded asteroid
	table.remove(asteroids, index)
	
	if orgScale < 4 then
	
		local newScale = orgScale * 2
	
		-- generate 2 new asteroids
		local asteroid
		for count = 1,2 do
			asteroid = spawnAsteroid(newScale)
			asteroid.velocity = {
				speed = (math.random()
												* (ASTEROID_MAX_VEL - ASTEROID_MIN_VEL))
												+ ASTEROID_MIN_VEL,
				direction = math.random() * math.pi * 2
			}
			asteroid.rotationSpeed = (math.random()
												* (2 * ASTEROID_MAX_ROT))
												- ASTEROID_MAX_ROT
												
			asteroid.position = position
			
			table.insert(asteroids, asteroid)
		end -- for
	end -- if

end -- explodeAsteroid

function particleExplosion(object, numParticles, maxSpeed,
	maxLifetime, colours, maxSize, deceleration)
	local particleVelocity = {}
	for particle = 1, numParticles do
		particleVelocity = {
			speed = math.random() * maxSpeed,
			direction = math.random() * math.pi * 2
		}
		spawnParticle(object.position,
			particleVelocity,maxLifetime, colours,
			maxSize, deceleration, math.random(1,3))
	end -- for 
end

function addVectors(vector1, vector2)

	v1Comp = getVectorComponents(vector1)
	v2Comp = getVectorComponents(vector2)
	resultantX = v1Comp.xComp + v2Comp.xComp
	resultantY = v1Comp.yComp + v2Comp.yComp

	local resVector =
		compToVector(resultantX, resultantY) 

	return resVector
	
end -- addVectors

function getVectorComponents(vector)

	local xComp = vector.speed
		* math.cos(vector.direction)
	
	local yComp = vector.speed
		* math.sin(vector.direction)
		
	local components = {
		xComp = xComp,
		yComp = yComp
	}
	
	return components

end -- getVectorComponents

function compToVector(x, y)

	local magnitude = 
		math.sqrt( (x * x) + (y * y))
	local direction = 
		math.atan2(y, x)
	direction = keepAngleInRange(direction)
		
	local vector = {
		speed = magnitude,
		direction = direction
	}
	
	return vector

end -- compToVector

function wrapPosition(position)

	if (position.x >= SCREEN_MAX_X) then
		position.x = 0
	elseif (position.x < 0) then
		position.x = SCREEN_MAX_X - 1
	end
	
	if (position.y >= SCREEN_MAX_Y) then
		position.y = 0
	elseif (position.y < 0) then
		position.y = SCREEN_MAX_Y - 1
	end
	
	return position

end -- wrapPosition

function spawnAsteroid(scale)

	local asteroid = {
		position = {
			x = 0,
			y = 0
		},
		velocity = {
			speed = 0,
			direction = 0
		},
		acceleration = 0.05,
		deceleration = 0.01,
		rotation = 0,
		rotationSpeed = 0.07,
		scale = scale,
		radius = 
			(ASTEROID_RAD + ASTEROID_RAD_PLUS) / scale,
		points = {}
	}
	
	-- generate points
	-- first point at default radius
	table.insert(asteroid.points,
		{
			x = ASTEROID_RAD/scale,
			y = 0,
			colour = 15
		}
	)
	
	local angle = 0
	local radius = 0
	local vector = {}
	
	for point=1, (ASTEROID_NUM_POINTS - 1) do
		-- create a random radius
		radius = math.random(
			ASTEROID_RAD - ASTEROID_RAD_MINUS,
			ASTEROID_RAD + ASTEROID_RAD_PLUS
		) / scale
		-- angles are evenly spaced
		angle = ((math.pi * 2) / ASTEROID_NUM_POINTS)
			 * point 
		
		vector = {
			speed = radius,
			direction = angle
		}
		
		components = getVectorComponents(vector)
		table.insert(asteroid.points,
			{
				x = components.xComp,
				y = components.yComp,
				colour = 15
			}
		)
		
	end -- for
	
	-- last point same as first
	table.insert(asteroid.points,
		{
			x = ASTEROID_RAD/scale,
			y = 0,
			colour = 15
		}
	)
	
	return asteroid

end -- spawnAsteroid

function generateAsteroids()
 asteroids = {}
	local asteroid
	for count = 1,NUM_ASTEROIDS do
		asteroid = spawnAsteroid(1)
		asteroid.velocity = {
			speed = (math.random()
												* (ASTEROID_MAX_VEL - ASTEROID_MIN_VEL))
												+ ASTEROID_MIN_VEL,
			direction = math.random() * math.pi * 2
		}
		asteroid.rotationSpeed = (math.random()
												* (2 * ASTEROID_MAX_ROT))
												- ASTEROID_MAX_ROT
												
		if math.random(1,2) == 1 then
			-- start at top of screen
			asteroid.position = {
				x = math.random(0,(SCREEN_MAX_X - 1)),
				y = 0
			}
		else
		 -- start at left of screen
			asteroid.position = {
				x = 0,
				y = math.random(0,(SCREEN_MAX_Y - 1))
			}
			end -- if
			
			table.insert(asteroids, asteroid)
	end -- for

end -- generateAsteroids

function drawAsteroids()

	for index, asteroid in ipairs(asteroids) do	
		drawVectorShape(asteroid)
	end -- for

end -- drawAsteroids

function moveAsteroids()

	for index, asteroid in ipairs(asteroids) do
		asteroid.rotation = asteroid.rotation
		 + asteroid.rotationSpeed
			
		asteroid.position = 
		movePointByVelocity(asteroid)
		
		asteroid.position = 
		wrapPosition(asteroid.position)
	end -- for

end -- moveAsteroids

function spawnParticle(position, velocity, maxLifetime,
	colours, maxSize, deceleration, type)

	local particle = {
		position = {
			x = position.x,
			y = position.y
		},
		velocity = {
			speed = velocity.speed,
			direction = velocity.direction
		},
		lifeTimer = (maxLifetime / 2) + 
			(math.random() * maxLifetime / 2),
		colours = colours,
		size = math.random(1, maxSize),
		deceleration = deceleration,
		type = type
	}
	table.insert(particles, particle)
	
end -- spawnParticle

function moveParticles()

	for index, particle in ipairs(particles) do
		particle.lifeTimer = particle.lifeTimer - 1
		if particle.lifeTimer < 0 then
			table.remove(particles, index)
		else
			particle.position = 
		 movePointByVelocity(particle)
		end --if
		particle.velocity.speed = 
		 	particle.velocity.speed - particle.deceleration
		if particle.velocity.speed < 0 then
			particle.velocity.speed = 0
		end
	end -- for
end

function drawParticles()

	local particleColour = 0
	
 for index, particle in ipairs(particles) do
	
		particleColour = particle.colours[
			math.random(1, #particle.colours)
		]
	
		if particle.type == 2 then
			circ(particle.position.x,
		 		particle.position.y,
					particle.size, particleColour)
		elseif particle.type == 1 then
			pix(particle.position.x,
		 		particle.position.y, particleColour)
		else
			rect(particle.position.x,
		 		particle.position.y,
					particle.size,
					particle.size,
					particleColour)
		end -- if
	end -- for

end

function initAlienShip()

alienShip = {
	position = {
		x = 0,
		y = 0
	},
	velocity = {
		speed = 0,
		direction = 0
	},
	rotation = 0,
	radius = 10,
	points = {
		{x=8,y=0, colour = 8},
		{x=-8,y=6, colour = 8},
		{x=-4,y=0, colour = 8},
		{x=-8,y=-6, colour = 8},
		{x=8,y=0, colour = 8}
	},
	active = false,
	spawnTimer = math.random(1200,2400)
}

end -- initAlienShip

function drawAlienShip()

	if alienShip.active then
		drawVectorShape(alienShip)
	end

end -- drawAlienShip

function moveAlienShip()

	if alienShip.active == false then
		alienShip.spawnTimer = 
			alienShip.spawnTimer - 1
		if alienShip.spawnTimer <= 0 then
			spawnAlienShip()
		end
	else
		-- move alien
		alienShip.position =
		 movePointByVelocity(alienShip)
		local xPos = alienShip.position.x
		wrapPosition(alienShip.position)
		-- don't wrap x position
		alienShip.position.x = xPos
		
		if alienShip.leftRight == 0 then
			-- left to right
			if alienShip.position.x > SCREEN_MAX_X then
				endAlienShip()
			end -- if
		else
			-- right to left
			if alienShip.position.x < 0 then
				endAlienShip()
			end -- if
		end
		
		alienShip.changeDirectionTimer =
		 alienShip.changeDirectionTimer - 1
		if alienShip.changeDirectionTimer <= 0 then
			-- change direction
			local direction = math.random() *
				math.pi * 5 / 6
			direction = direction - (math.pi * 5 / 12)
			if alienShip.leftRight == 1 then
				-- right to left
				direction = direction + math.pi
			end
			direction = keepAngleInRange(direction)
			alienShip.velocity.direction = direction
			alienShip.rotation = direction
			-- reset timer
			alienShip.changeDirectionTimer = 30
		end -- if
		
		if #alienBullets < MAX_ALIEN_BULLETS then
			fireAlienBullet()
		end -- if
	
	end

end -- moveAlienShip

function spawnAlienShip()

	alienShip.active = true
	
	local leftRight = math.random(0,1)
	-- 0 = left to right
	-- 1 = right to left
	local startX = 0
	if leftRight == 1 then
		startX = SCREEN_MAX_X - 1
	end

	alienShip.position = {
	 x = startX,
		y = math.random(0,SCREEN_MAX_Y)
	}
	alienShip.velocity = {
		speed = 1,
		direction = 0
	}
	alienShip.rotation = 0
	alienShip.spawnTimer = 0
	alienShip.changeDirectionTimer = 0
	alienShip.leftRight = leftRight
	
end -- spawnAlienShip()

function endAlienShip()
	alienShip.active = false
	alienShip.spawnTimer = math.random(600,1200)
end -- endAlienShip

function explodeAlienShip()

	playerScore =
		playerScore + 250
	sfx(1, 1, 50, 1, 15)
	
	particleExplosion(alienShip, 60, 1,
		30, explosionColours, 3, 0.01)
	
	-- reset Alien ship
	endAlienShip()

end -- explodeAlienShip()

function fireAlienBullet()

	local direction = 0
	local angleToShip = math.atan2(
		playerShip.position.y - alienShip.position.y,
		playerShip.position.x - alienShip.position.x
	)
	local angleVariation = math.random() * ALIEN_BULLET_AIM
		- (ALIEN_BULLET_AIM / 2)
	local direction = angleToShip + angleVariation
	direction = keepAngleInRange(direction)
	
	bullet = {
		position = {
			x = alienShip.position.x,
			y = alienShip.position.y 
		},
		velocity = {
			speed = ALIEN_BULLET_SPEED,
			direction = direction
		},
		timer = ALIEN_BULLET_TIME
	}
	table.insert(alienBullets, bullet)
	sfx(0,50,20,0,15,1) 
end -- fireAlienBullet

function moveAlienBullets()
	for index, bullet in ipairs(alienBullets) do
		bullet.timer = bullet.timer - 1
		if bullet.timer < 0 then
			-- kill bullet
			table.remove(alienBullets, index)
		else
			-- move bullet
			bullet.position = 
				movePointByVelocity(bullet)
		
			bullet.position = 
				wrapPosition(bullet.position)
				
		end -- if
	end -- for
end

function drawAlienBullets()
	for index, bullet in ipairs(alienBullets) do
		spr(16,
			bullet.position.x,
			bullet.position.y, 0)
	end -- for
end -- drawPlayerBullets

-- I label the end of each function so I know what function corrosponds with the end of the function.


