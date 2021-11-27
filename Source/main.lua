
GAME_VERSION = "0.01"
love.window.setTitle("Stock Block " .. GAME_VERSION)

-- Global screen dimensions
SCREEN_WIDTH = 800
SCREEN_HEIGHT = 650

Inspect = require 'lib.inspect'
-- https://github.com/kikito/inspect.lua

-- https://love2d.org/wiki/TLfres
TLfres = require 'lib.tlfres'

-- https://github.com/coding-jackalope/Slab/wiki
Slab = require 'lib.Slab.Slab'

-- https://github.com/gvx/bitser
Bitser = require 'lib.bitser'

-- https://github.com/megagrump/nativefs
Nativefs = require 'lib.nativefs'

-- https://github.com/camchenry/Sock.lua
Sock = require 'lib.sock'

-- https://github.com/Loucee/Lovely-Toasts
LovelyToasts = require 'lib.lovelyToasts'

-- Common functions
Cf = require 'lib.commonfunctions'

SCREEN_STACK = {}
CHAIN = {}
CHAIN.BLOCK = {}

MSGLOG = ""
PLAYER = {}

function sealBlock()

	local lastBlock = #CHAIN.BLOCK
	local serialisedString = Bitser.dumps(CHAIN.BLOCK[lastBlock])
	
	local blockHash = love.data.hash("sha1", serialisedString)
	CHAIN.BLOCK[lastBlock].thisBlockHash = blockHash
	
	saveChain()

end

function createNewBlock()
	-- 
	local newBlock = {}
	newBlock.previousBlockHash = 0
	newBlock.TRANSACTIONS = {}

	table.insert(CHAIN.BLOCK, newBlock)
	CHAIN.BLOCK[#CHAIN.BLOCK].TRANSACTIONS = {}
end

function purchaseStock(stockName, stockPrice)

	if PLAYER.name ~= nil and PLAYER.name ~= "" then
		local transaction = {}
		
		transaction.owner = PLAYER.name
		transaction.type = "purchase"
		transaction.stock = stockName
		transaction.price = Cf.round(stockPrice,2)
		
		if CHAIN.BLOCK == nil then
			CHAIN.BLOCK = {}
			createNewBlock()
		else
			if CHAIN.BLOCK[#CHAIN.BLOCK].thisBlockHash == nil then
			else
				createNewBlock()
			end
		end
		
		if CHAIN.BLOCK[#CHAIN.BLOCK].TRANSACTIONS == nil then
			CHAIN.BLOCK[#CHAIN.BLOCK].TRANSACTIONS = {}
		end
		table.insert(CHAIN.BLOCK[#CHAIN.BLOCK].TRANSACTIONS, transaction)

		MSGLOG = Inspect(CHAIN)
	else
		LovelyToasts.show("Provide a name first")
	end
end

function saveChain()
-- uses the globals because too hard to pass params

    local savefile
    local contents
    local success, message
    local savedir = love.filesystem.getSource()

    savefile = savedir .. "/" .. "chain.dat"
    serialisedString = Bitser.dumps(CHAIN)
    success, message = Nativefs.write(savefile, serialisedString )
end

function loadChain()

    local savedir = love.filesystem.getSource()
    love.filesystem.setIdentity( savedir )

    local savefile
    local contents
	local size
	local error = false

	savefile = savedir .. "/" .. "chain.dat"
	if Nativefs.getInfo(savefile) then
		contents, size = Nativefs.read(savefile)
	    CHAIN = bitser.loads(contents)
	else
		error = true
	end	
	
	if error then
		-- a file is missing, so display a popup on a new game
		LovelyToasts.show("ERROR: Unable to load chain.", 3, "middle")
	else
		MSGLOG = Inspect(CHAIN)
	end
end

local function createBlockChain(newChainName)

	if newChainName ~= nil and newChainName ~= "" then
		CHAIN = {}
		
		
		CHAIN.id = newChainName

		saveChain()
		
		PLAYER.wealth = 100
		
		MSGLOG = Inspect(CHAIN)
		
	else
		LovelyToasts.show("Provide a name first")
	end


end

local function DrawForm()

	local intSlabWidth = 400 -- the width of the main menu slab. Change this to change appearance.
	local intSlabHeight = 550 	-- the height of the main menu slab
	local fltSlabWindowX = SCREEN_WIDTH / 2 - intSlabWidth / 2
	local fltSlabWindowY = SCREEN_HEIGHT / 2 - intSlabHeight / 2	

	local mainMenuOptions = {
		Title = "Stock Block " .. GAME_VERSION,
		X = fltSlabWindowX,
		Y = fltSlabWindowY,
		W = intSlabWidth,
		H = intSlabHeight,
		Border = 10,
		AutoSizeWindow=false,
		AllowMove=false,
		AllowResize=false,
		NoSavedSettings=true
	}

	Slab.BeginWindow('MainMenu', mainMenuOptions)
	Slab.BeginLayout("MMLayout",{AlignX="center",AlignY="center",AlignRowY="center",ExpandW=false,Columns = 2})

		Slab.SetLayoutColumn(1)
		
		Slab.Text("Your name")
		
		if Slab.Input('playersName', {Text = PLAYER.name}) then
			PLAYER.name = Slab.GetInputText()
		end
		
		Slab.Text("Your wealth: " .. tostring(PLAYER.wealth))
		Slab.NewLine()
		
		local timeSinceOrigin = os.time()
		timeSinceOrigin = timeSinceOrigin / 1000
		
		local stock = {}
		stock[1] = {}
		stock[1].name = "AAA"
		stock[1].price = love.math.noise( 1, timeSinceOrigin )

		stock[2] = {}
		stock[2].name = "BBB"
		stock[2].price = love.math.noise( 2, timeSinceOrigin )		
		
		stock[3] = {}
		stock[3].name = "CCC"
		stock[3].price = love.math.noise( 3, timeSinceOrigin )		
		
		stock[4] = {}
		stock[4].name = "DDD"
		stock[4].price = love.math.noise( 4, timeSinceOrigin )

		for i = 1, 4 do
			local txt = stock[i].name .. ": $" ..  string.format("%.2f", Cf.round(stock[i].price, 2))
			Slab.Text(txt)
			if Slab.Button("Purchase " .. stock[i].name) then
				purchaseStock(stock[i].name, stock[i].price)
			end	
			if Slab.Button("Sell " .. stock[i].name) then
			end	
			Slab.NewLine()		
		end
		
		if Slab.Button("Create new chain") then
			createBlockChain(PLAYER.name)
		end	
		
		if Slab.Button("Load existing chain") then
			loadChain()
		end	

		if Slab.Button("Save chain") then
			sealBlock()
		end			
	
		if Slab.Button("OK") then
			-- return to the previous game state
			Cf.RemoveScreen(SCREEN_STACK)
		end
		
		Slab.SetLayoutColumn(2)
		
		-- Slab.Text(MSGLOG)
print(Inspect(CHAIN))

	Slab.EndLayout() -- layout-settings
	Slab.EndWindow()	
	
end

function love.load(args)
	
	Slab.Initialize(args)
	
	-- display = monitor number (1 or 2)
	local flags = {fullscreen = false,display = 1,resizable = true, borderless = false}
	love.window.setMode(SCREEN_WIDTH, SCREEN_HEIGHT, flags)
	
	LovelyToasts.options.queueEnabled = true
	
	Cf.AddScreen("MainMenu", SCREEN_STACK)

end

function love.draw()

	TLfres.beginRendering(SCREEN_WIDTH,SCREEN_HEIGHT)
	Slab.Draw()

	LovelyToasts.draw()
	
	TLfres.endRendering({0, 0, 0, 1})
end

function love.update(dt)

	Slab.Update(dt)
	
	if Cf.CurrentScreenName(SCREEN_STACK) == "MainMenu" then
		DrawForm()
	end

	LovelyToasts.update(dt)

end