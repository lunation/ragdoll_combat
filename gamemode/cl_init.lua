include( 'shared.lua' )

DEFINE_BASECLASS( "gamemode_base" )

net.Receive("ragcom_msg",function()
	local str = net.ReadString()
	local color = net.ReadColor()
	chat.AddText(color,str)
end)

local window_help = vgui.Create("DFrame")
window_help:SetPos(50,50)
window_help:SetSize(ScrW()-100,ScrH()-100)
window_help:SetTitle("Ragdoll Combat II Help")
window_help:SetDraggable(false)
window_help:SetDeleteOnClose(false)
window_help:Hide()

local wh_html = window_help:Add("DHTML")
wh_html:SetPos(10,35)
wh_html:SetSize(window_help:GetWide()-20,window_help:GetTall()-100)
wh_html:SetHTML[[
<style>
	body {
		background-color: #fca;
	}
</style>
<h1>Welcome to Ragdoll Combat II!</h1>
<h2>Info</h2>
Ragdoll Combat II is a new <s>game of skill</s> <s>esport</s> <s>smash bros clone</s> <s>laggy mess</s> gamemode by Parakeet. 
<p>
The goal is to knock all the other ragdolls off the spawn platform.
The gamemode will continue until someone scores the number of wins listed on the scoreboard.
</p>
<p>
Every ragdoll has a bar above its head showing its name and power level.
When a ragdoll's power level reaches 0, it will be knocked over.
Every time a ragdoll is knocked over it will be flung farther.
The more red the power bar is, the farther the ragdoll will be flung.
<p>
To start playing, pick a character in the F2 menu.
Each character has his or her own unique appearance, positive/negative voice responses, description, and inspirational Dick Valentine quotes/song lyrics.
</p>
<h2>Controls</h2>
<ul>
<li> Movement Keys - Move (Duh)
<li> Left/Right Click - Punch
<li> Reload - Block (Absorb 2/3 damage, Move slowly)
<li> Duck - Duck (Duh, Move slowly)
<li> Jump - Tackle/Dive (Based on power level, movement keys control direction)
</ul>
<h2>About</h2>
This gamemode was created for the 1 week Garry's Mod gamemode competition in July 2015.
<h2>Credits</h2>
<ul>
<li>Parakeet - Code, Textures
<li>Dick Valentine - Inspirational Quotes/Song Lyrics
</ul>
]]

local wh_btn = window_help:Add("DButton")
wh_btn:SetPos(window_help:GetWide()/2-50,window_help:GetTall()-60)
wh_btn:SetSize(100,50)
wh_btn:SetText("Got it!")
wh_btn.DoClick = function()
	window_help:Hide()
end

net.Receive("ragcom_gui",function()
	local n = net.ReadInt(8)
	if n==1 then
		window_help:Show()
		window_help:MakePopup()
	elseif n==2 then
		print("---2")
	end
end)

function GM:CalcView(ply,pos,ang,fov,near,far)
	if IsValid(LocalPlayerController) then
		local ragdoll = LocalPlayerController:GetRagdoll()
		local headpos = ragdoll:GetBonePosition(6)

		local view = {}
		view.angles = ply:EyeAngles() // Stupid bullshit doesn't work and I have no time to figure out why.

		local tr = util.TraceLine{start=headpos,endpos=headpos+view.angles:Forward()*-120,filter=ragdoll}

		view.origin = tr.HitPos + tr.HitNormal*10
		//ply.last_view = view
		return view
	end
end

local black = Color(0,0,0)
local grey = Color(200,200,200)

local function getWeaknessColor(ent)
	local e = math.min(ent:GetWeakness()/5,1)
	e = e*math.pi/2

	return Color(math.sin(e)*255,math.cos(e)*255,0)
end

function GM:HUDPaint()
	BaseClass.HUDPaint( self )

	for k,ent in pairs(ents.FindByClass("ragcom_controller")) do
		local scrpos = (ent:GetPos()+Vector(0,0,40)):ToScreen()
		if scrpos.visible then
			local w = ent:GetEnergy()/ent.MaxEnergy

			surface.SetDrawColor(getWeaknessColor(ent))
			surface.DrawRect(scrpos.x-42,scrpos.y,84,14)
			surface.SetDrawColor(Color(255,255,255,100))
			surface.DrawRect(scrpos.x-40,scrpos.y+2,80*w,10)

			local ply = ent:GetController()

			if IsValid(ply) then
				draw.SimpleText(ply:GetName(),"Trebuchet18",scrpos.x,scrpos.y+6,black,TEXT_ALIGN_CENTER,TEXT_ALIGN_CENTER)
			end
		end
	end
end

local scoreboard = false

function GM:ScoreboardShow()
	scoreboard = true
end

function GM:ScoreboardHide()
	scoreboard = false
end

function GM:HUDDrawScoreBoard()
	if scoreboard then
		surface.SetDrawColor(grey)
		surface.DrawRect(ScrW()/4,80,ScrW()/2,70)

		draw.SimpleText(GetHostName(),"Trebuchet24",ScrW()/2,100,black,TEXT_ALIGN_CENTER,TEXT_ALIGN_CENTER)
		draw.SimpleText("Ragdoll Combat II: Flatgrass Smash","Trebuchet24",ScrW()/2,130,black,TEXT_ALIGN_CENTER,TEXT_ALIGN_CENTER)
		
		local t = {}
		for _,ent in pairs(ents.FindByClass("ragcom_controller")) do
			local ply = ent:GetController()
			t[ply] = ent
		end

		for k,ply in pairs(player.GetAll()) do
			surface.SetDrawColor(t[ply] and getWeaknessColor(t[ply]) or grey)
			surface.DrawRect(ScrW()/4,130+k*50,ScrW()/2,30)
			draw.SimpleText(ply:GetName(),"Trebuchet24",ScrW()/4+10,145+k*50,black,TEXT_ALIGN_LEFT,TEXT_ALIGN_CENTER)
			draw.SimpleText(ply:Frags()..(ply:Frags()==1 and " Win" or " Wins"),"Trebuchet24",ScrW()/2,145+k*50,black,TEXT_ALIGN_LEFT,TEXT_ALIGN_CENTER)
		end
	end
	//print(GetHostName())
end

local orange = Color(255,100,50)
local white = Color(255,255,255)
function GM:OnPlayerChat(ply, text, bTeamOnly, bPlayerIsDead) --No *Dead* tags, please!
	chat.AddText(orange,ply:GetName(),white,": ",text)
	return true
end

function GM:InitPostEntity()
	PrintTable(Entity(0):GetMaterials())
end