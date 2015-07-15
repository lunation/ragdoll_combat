AddCSLuaFile( "cl_init.lua" )
AddCSLuaFile( "shared.lua" )

include( 'shared.lua' )

util.AddNetworkString("ragcom_msg")
util.AddNetworkString("ragcom_gui")

local function gm_msg(str,col)
	net.Start("ragcom_msg")
	net.WriteString(str)
	net.WriteColor(col)
	net.Broadcast()
end

function GM:PlayerSpawn( ply )
    self.BaseClass:PlayerSpawn( ply )   
 
    ply:SetGravity  ( 1 )  
    ply:SetMaxHealth( 100, true )  
 
    ply:SetWalkSpeed( 190 )  
    ply:SetRunSpeed ( 235 ) 
 
end

function GM:PlayerLoadout( ply )
	ply:Give("weapon_physgun")
end


local function spawn_doll(ply,n,r)
	local ragdoll_control = ents.Create("ragcom_controller")
	ragdoll_control:SetPos(Vector(math.sin(n)*r,math.cos(n)*r,-12260))
	ragdoll_control:SetController(ply)
	ragdoll_control:Spawn()
end

local function resetView(ply)
	ply:SetPos(Vector(1166,1065,-11889))
	ply:SetEyeAngles(Angle(28,-138,0))
end

--I'm sorry ):
if RAGCOM_ROUND_RUNNING==nil then
	RAGCOM_ROUND_RUNNING = false
end

if RAGCOM_GAME_RUNNING==nil then
	RAGCOM_GAME_RUNNING = false
end

if RAGCOM_ROUND_N==nil then
	RAGCOM_ROUND_N=1
end

local function round_start()
	gm_msg("Round #"..RAGCOM_ROUND_N..": Fight!",Color(50,50,255))
	RAGCOM_ROUND_N=RAGCOM_ROUND_N+1
	RAGCOM_ROUND_RUNNING = true
	local players = player.GetAll()
	for k,v in pairs(players) do
		//v:Spectate(OBS_MODE_FREEZECAM) //Stop from moving outside the map D:
		local n = (k/#players)*6.28
		spawn_doll(v,n,#players*50)
		v:SetEyeAngles(Angle(0,-90-math.deg(n),0))
	end
end

local function round_end()
	RAGCOM_ROUND_RUNNING = false
	timer.Simple(3,function()
		local players = player.GetAll()
		for k,v in pairs(players) do
			if IsValid(v.controller) then
				v.controller:Remove()
				//resetView(v)
			end
		end
		if #players>=2 then
			timer.Simple(1,round_start)
		else
			RAGCOM_GAME_RUNNING=false
			gm_msg("Not enough players to continue combat. Waiting...",Color(50,50,255))
		end
	end)
end

// No spawning allowed!
function GM:PlayerSpawn(ply)
	ply:KillSilent()
	ply:Spectate(OBS_MODE_ROAMING)
	resetView(ply)
end

function GM:PlayerDeathThink(ply)
	return false
end

function GM:Think()
	if not RAGCOM_GAME_RUNNING and #player.GetAll()>=2 then
		gm_msg("Let the combat begin!",Color(50,50,255))
		RAGCOM_GAME_RUNNING=true
		round_start()
	end

	if not RAGCOM_ROUND_RUNNING then return end
	local controllers = ents.FindByClass("ragcom_controller")

	if #controllers==1 then
		local ply = controllers[1]:GetController()
		controllers[1]:WinTaunt()
		ply:AddFrags(1)
		gm_msg(ply:GetName().." won the round!",Color(50,255,50))
		round_end()
	elseif #controllers==0 then
		local ply = controllers[1]:GetController()
		gm_msg("Evidently there's nobody left so I guess it's time to reset.",Color(50,255,50))
		round_end()
	end

	for k,ent in pairs(controllers) do
		if ent:GetPos().z<-12700 then
			ent.limp_timer = 2
			timer.Simple(.5,function()
				if not IsValid(ent) or ent.won then return end
				local ed = EffectData()
				ed:SetOrigin(ent:GetPos())
				util.Effect("HelicopterMegaBomb",ed)

				//EmitSound("", Vector position, number entity, number channel=CHAN_AUTO, number volume=1, number soundLevel=75, number soundFlags=0, number pitch=100 )
				sound.Play("weapons/physcannon/energy_sing_explosion2.wav",ent:GetPos(),100,50,.5)

				local ply = ent:GetController()

				ent:Remove()

				gm_msg(ply:GetName().." was KO'd!",Color(255,50,50))
				resetView(ply)
			end)
		end
	end
end

function GM:ShowHelp(ply)
	net.Start("ragcom_gui")
	net.WriteInt(1,8)
	net.Send(ply)
end

function GM:ShowTeam(ply)
	net.Start("ragcom_gui")
	net.WriteInt(2,8)
	net.Send(ply)
end