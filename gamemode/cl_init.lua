include( 'shared.lua' )

DEFINE_BASECLASS( "gamemode_base" )

net.Receive("ragcom_msg",function()
	local str = net.ReadString()
	local color = net.ReadColor()
	chat.AddText(color,str)
end)

net.Receive("ragcom_sound",function()
	local str = net.ReadString()
	surface.PlaySound(str)
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
wh_html:SetAllowLua(true)
wh_html:SetHTML[[
<style>
	body {
		font-family: arial;
		background-color: #ddf;
	}
</style>
<h1>Welcome to Ragdoll Combat II!</h1>
<h2>Info</h2>
<p>Ragdoll Combat II is a new <s>game of skill</s> <s>esport</s> <s>smash bros clone</s> <s>laggy mess</s> gamemode by Parakeet.</p> 
<p>
The goal is to knock all the other ragdolls off the spawn platform.
</p>
<p>
Every ragdoll has a bar above its head showing its name and power level.
When a ragdoll's power level reaches 0, it will be knocked over.
Every time a ragdoll is knocked over it will be flung farther.
The more red the power bar is, the farther the ragdoll will be flung.
<p>
To start playing, pick a character in the F2 menu. (Use the chat command /char if F2 doesn't work!)
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
<p>
This gamemode was created for the <a steamui href="http://facepunch.com/showthread.php?t=1474356">1 Week Garry's Mod Gamemode Competition</a> in July 2015.
There are official discussions on <a steamui href="http://steamcommunity.com/groups/_lunation/discussions/0/535151589891117198/">Steam</a> and <a steamui href="http://facepunch.com/showthread.php?t=1476465">Facepunch</a>.
</p>
<p>
It was created by <a steamui href="http://steamcommunity.com/groups/_lunation">Lunation</a>, which is currently a one-man-show consisting of Parakeet (that one guy who made that one mod with the pills).
Lunation also hosts the official Ragdoll Combat server.
</p>
<p>
It can be downloaded for free at <a steamui href="https://garrysmods.org/download/48868/ragdoll-combat-ii">garrysmods.org</a>.
It will be available on the Workshop eventually.
</p>
<p>
It is open source! Contributions can be made via the <a steamui href="https://github.com/lunation/ragdoll_combat">Github Repository</a>.
</p>
<h2>Credits</h2>
<ul>
<li>Parakeet - Code, Textures
<li>Dick Valentine - Inspirational Quotes/Song Lyrics
<li>Sounds are from: "Shia LaBeouf" by Rob Cantor, Turrets Guy, and L4D2
<li>Special thanks to: Postal, Shia LaBeouf, Ellen Pao, whoever is repsonsible for "That Cat", Pugs, John Lua
<li>Extra special thanks to: Exploderguy, The Commander, James xX, sarge, TheMrFailz, NiandraLades, Fortune11709, Shotz, YourStalker, sarge997, Pdan4, Skylight
</ul>
Sorry if I forgot anyone, please don't ban me from the internet.
<script>
Array.prototype.forEach.call(document.querySelectorAll("a[steamui]"),function(e) {e.onclick = function() {console.log("RUNLUA:gui.OpenURL('"+e.href+"')");return false;}});
</script>
]]

local wh_btn = window_help:Add("DButton")
wh_btn:SetPos(window_help:GetWide()/2-50,window_help:GetTall()-60)
wh_btn:SetSize(100,50)
wh_btn:SetText("Got it!")
wh_btn.DoClick = function()
	window_help:Hide()
end

local window_char = vgui.Create("DFrame")
window_char:SetPos(50,50)
window_char:SetSize(ScrW()-100,ScrH()-100)
window_char:SetTitle("Character Selection")
window_char:SetDraggable(false)
window_char:SetDeleteOnClose(false)
window_char:Hide()

local wc_info = window_char:Add("DHTML")
wc_info:SetPos(20,35)
wc_info:SetSize(window_char:GetWide()/2-50,window_char:GetTall()/2-60)

local function setInfo(body)
	wc_info:SetHTML("<style>body {font-family: arial; background-color: #ddf;}</style>"..body)
end

local wc_model = window_char:Add("DModelPanel")
wc_model:SetPos(window_char:GetWide()/2-20,35)
wc_model:SetSize(window_char:GetWide()/2,window_char:GetTall()-105)
wc_model:SetFOV(50)
function wc_model:LayoutEntity( ent )
	 wc_model:RunAnimation()
end

local wc_select = window_char:Add("DListView")
wc_select:SetPos(20,window_char:GetTall()/2-20)
wc_select:SetSize(window_char:GetWide()/2-50,window_char:GetTall()/2-50)

wc_select:AddColumn("Character")
wc_select:AddLine("None [Spectate]")
for k,v in pairs(RAGCOM_CHARS) do
	wc_select:AddLine(v.name)
end

local selected_n=0
function wc_select:OnRowSelected(n)
	n=n-1
	selected_n=n
	if n==0 then
		setInfo("")
		wc_model:SetModel("")
	else
		setInfo("<b>Bio:</b> "..RAGCOM_CHARS[n].desc.."<hr><blockquote><i>"..string.Replace(RAGCOM_CHARS[n].quote,"\n","<br>").."</i></blockquote>-- Dick Valentine")
		wc_model:SetModel(RAGCOM_CHARS[n].model)
		local ent = wc_model:GetEntity()
		RAGCOM_CHARS[n].setup(ent)
	end
end

wc_select:SelectFirstItem()

local wc_btn = window_char:Add("DButton")
wc_btn:SetPos(window_char:GetWide()/2-50,window_char:GetTall()-60)
wc_btn:SetSize(100,50)
wc_btn:SetText("Apply")
wc_btn.DoClick = function()
	//apply logic
	window_char:Hide()
	net.Start("ragcom_select_char")
	net.WriteUInt(selected_n,8)
	net.SendToServer()
end

net.Receive("ragcom_gui",function()
	local n = net.ReadInt(8)
	if n==1 then
		window_help:Show()
		window_help:MakePopup()
	elseif n==2 then
		window_char:Show()
		window_char:MakePopup()
	end
end)

hook.Add("OnPlayerChat","ragcom",function(ply,txt)
	if txt=="/help" or txt=="!help" then
		if ply==LocalPlayer() then
			window_help:Show()
			window_help:MakePopup()
		end
		return true
	elseif txt=="/char" or txt=="!char" then
		if ply==LocalPlayer() then
			window_char:Show()
			window_char:MakePopup()
		end
		return true
	end
end)

function GM:CalcView(ply,pos,ang,fov,near,far)
	if IsValid(LocalPlayerController) then
		local ragdoll = LocalPlayerController:GetRagdoll()
		local headpos = ragdoll:GetBonePosition(6)

		local view = {}
		view.angles = ply:EyeAngles() -- Stupid bullshit doesn't work and I have no time to figure out why.

		local tr = util.TraceLine{start=headpos,endpos=headpos+view.angles:Forward()*-120,filter=ragdoll}

		view.origin = tr.HitPos + tr.HitNormal*10
		//ply.last_view = view
		return view
	end
end

local black = Color(0,0,0)
local grey = Color(200,200,200)


local icon_admin = Material("icon16/shield.png")
local icon_typing = Material("icon16/keyboard.png")
local icon_voice = Material("icon16/sound.png")

local voice_tracker = {}
hook.Add("PlayerStartVoice","ragcom",function(ply)
	voice_tracker[ply]=true
end)

hook.Add("PlayerEndVoice","ragcom",function(ply)
	voice_tracker[ply]=nil
end)

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
				surface.SetDrawColor(255,255,255,255)
				
				local ply_icon
				
				if LUNAR then
					ply_icon = LUNAR.getPlayerIcon(ply)
				end

				if !ply_icon and ply:IsAdmin() then
					ply_icon= icon_admin
				end

				if ply_icon then
					surface.SetMaterial(ply_icon)
					surface.DrawTexturedRect(scrpos.x-60,scrpos.y,16,16)
				end	
					
				if voice_tracker[ply] then
					surface.SetMaterial(icon_voice)
					surface.DrawTexturedRect(scrpos.x+46,scrpos.y,16,16)
				elseif ply:IsTyping() then
					surface.SetMaterial(icon_typing)
					surface.DrawTexturedRect(scrpos.x+46,scrpos.y,16,16)
				end

				draw.SimpleText(ply:GetName(),"Trebuchet18",scrpos.x,scrpos.y+6,black,TEXT_ALIGN_CENTER,TEXT_ALIGN_CENTER)

			end
		end
	end

	if not IsValid(LocalPlayerController) then
		draw.SimpleText("You are spectating. Press F1 for help. Press F2 to select a character.","Trebuchet18",ScrW()/2,ScrH()-100,black,TEXT_ALIGN_CENTER,TEXT_ALIGN_CENTER)
		draw.SimpleText("OR use the /help and /char chat commands.","Trebuchet18",ScrW()/2,ScrH()-80,black,TEXT_ALIGN_CENTER,TEXT_ALIGN_CENTER)
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
		surface.SetDrawColor(black)
		surface.DrawRect(ScrW()/4-5,80,ScrW()/2+10,70+#player.GetAll()*35)

		surface.SetDrawColor(grey)
		surface.DrawRect(ScrW()/4,85,ScrW()/2,60)

		draw.SimpleText(GetHostName(),"Trebuchet18",ScrW()/2,100,black,TEXT_ALIGN_CENTER,TEXT_ALIGN_CENTER)
		draw.SimpleText("Ragdoll Combat II: Flatgrass Smash","Trebuchet18",ScrW()/2,125,black,TEXT_ALIGN_CENTER,TEXT_ALIGN_CENTER)

		local t = {}
		for _,ent in pairs(ents.FindByClass("ragcom_controller")) do
			local ply = ent:GetController()
			t[ply] = ent
		end

		for k,ply in pairs(player.GetAll()) do
			surface.SetDrawColor(t[ply] and getWeaknessColor(t[ply]) or grey)
			surface.DrawRect(ScrW()/4,115+k*35,ScrW()/2,30)
			draw.SimpleText(ply:GetName(),"Trebuchet18",ScrW()/4+50,130+k*35,Color(0,0,0,255),TEXT_ALIGN_LEFT,TEXT_ALIGN_CENTER)
			draw.SimpleText(ply:Frags()..(ply:Frags()==1 and " Point" or " Points"),"Trebuchet18",ScrW()/2,130+k*35,Color(0,0,0,255),TEXT_ALIGN_LEFT,TEXT_ALIGN_CENTER)
			draw.SimpleText(ply:Ping().."ms","Trebuchet18",ScrW()/1.5,130+k*35,black,TEXT_ALIGN_LEFT,TEXT_ALIGN_CENTER)
			
			surface.SetDrawColor(255,255,255,255)
			
			local ply_icon
			
			if LUNAR then
				ply_icon = LUNAR.getPlayerIcon(ply)
			end

			if !ply_icon and ply:IsAdmin() then
				ply_icon= icon_admin
			end

			if ply_icon then
				surface.SetMaterial(ply_icon)
				surface.DrawTexturedRect(ScrW()/4+4,122+k*35,16,16)
			end

			if voice_tracker[ply] then
				surface.SetMaterial(icon_voice)
				surface.DrawTexturedRect(ScrW()/4+26,122+k*35,16,16)
			elseif ply:IsTyping() then
				surface.SetMaterial(icon_typing)
				surface.DrawTexturedRect(ScrW()/4+26,122+k*35,16,16)
			end
		end
	end
end

local red = Color(255,50,50)
local yellow = Color(255,255,50)
local white = Color(255,255,255)
function GM:OnPlayerChat(ply, text, bTeamOnly, bPlayerIsDead) --No *Dead* tags, please!
	if IsValid(ply) then
		chat.AddText(ply:IsAdmin() and red or yellow,ply:GetName(),white,": ",text)
		return true
	end
end

function GM:InitPostEntity()
	//PrintTable(Entity(0):GetMaterials())

	local colors_mappings = {
		["gm_construct/flatgrass"]=Vector(.02,.08,0),
		//["gm_construct/flatsign"]=Vector(0,0,0),
		["brick/brickwall053d"]=Vector(.01,.01,.01), --Brick upper/lower border
		["brick/brickwall003a_construct"]=Vector(.05,.05,.05),
		["maps/gm_flatgrass/concrete/concretefloor028a_0_96_-12032"]=Vector(.2,.2,.2), --top
		["maps/gm_flatgrass/concrete/concretefloor028a_0_-31_-12736"]=Vector(.01,.01,.01), --underside/inner room floor

		["maps/gm_flatgrass/concrete/concretefloor028c_0_1312_-12736"]=Vector(.01,.01,.01),
		["maps/gm_flatgrass/concrete/concretefloor028c_0_96_-12032"]=Vector(.01,.01,.01),
		["maps/gm_flatgrass/concrete/concretefloor028c_0_480_-12736"]=Vector(.01,.01,.01),
		["maps/gm_flatgrass/concrete/concretefloor028c_0_992_-12736"]=Vector(.01,.01,.01),
		["maps/gm_flatgrass/concrete/concretefloor028c_0_-1439_-12736"]=Vector(.01,.01,.01),
		["maps/gm_flatgrass/concrete/concretefloor028c_0_-991_-12736"]=Vector(.01,.01,.01),
		["maps/gm_flatgrass/concrete/concretefloor028c_0_-543_-12736"]=Vector(.01,.01,.01),

		["concrete/concreteceiling003a"]=Vector(.01,.01,.01)

	}

	local subtex = Material("models/debug/debugwhite"):GetTexture("$basetexture")

	for k,v in pairs(colors_mappings) do
		local m = Material(k)
		m:SetTexture("$basetexture",subtex)
		m:SetUndefined("$envmap")
		m:SetVector("$color",v)
		m:Recompute()
	end
end

-- Anti-AFK
-- Yes, I know it's easy to get around, but breaking Anti-AFK is easy anyway.

local lastbind = CurTime()
local lastangles = EyeAngles() 

function GM:PlayerBindPress( ply, bind, pressed )
	lastbind = CurTime()
	return false
end

timer.Create("ragcom_afk_check",10,0,function()
	if lastangles!=EyeAngles() then
		lastangles = EyeAngles()
		return
	end

	if IsValid(LocalPlayerController) then
		if lastbind+60<CurTime() then
			net.Start("ragcom_select_char")
			net.WriteUInt(selected_n,0)
			net.SendToServer()
			RunConsoleCommand("say","I'm being moved to Spectator because I'm AFK!")
			RunConsoleCommand("ragcom_rocket")
		end
	elseif !LocalPlayer():IsAdmin() then
		if lastbind+300<CurTime() then
			RunConsoleCommand("say","I'm being removed from the game because I'm AFK!")
			RunConsoleCommand("disconnect")
		end
	end
end)
