AddCSLuaFile()

ENT.Type   = "anim"

local energy_fall = 5

ENT.MaxEnergy = 60

//ENT.RenderGroup = RENDERGROUP_TRANSLUCENT

function ENT:SetupDataTables()
	self:NetworkVar("Entity",0,"Ragdoll")
	self:NetworkVar("Entity",1,"Controller")

	self:NetworkVar("Int",0,"Energy")
	self:NetworkVar("Int",1,"Weakness")
	self:NetworkVar("Int",2,"Char")
end

local SIDE_LEFT = true
local SIDE_RIGHT = false

local step_time = .33
local stride_length = 60 //60
local stride_height = 25

function ENT:Initialize()		
	if SERVER then
		self:SetModel("models/props_c17/computer01_keyboard.mdl")

		local ragdoll = ents.Create("prop_ragdoll")
		ragdoll:SetModel(RAGCOM_CHARS[self:GetChar()].model)
		ragdoll:SetPos(self:GetPos())
		ragdoll:Spawn()
		self:SetRagdoll(ragdoll)

		ragdoll:SetFlexWeight(0,1)
		ragdoll:SetFlexWeight(1,1)
		

		self:DeleteOnRemove(ragdoll)

		RAGCOM_CHARS[self:GetChar()].setup(ragdoll)

		/*for i=1,100 do
			print(i,ragdoll:GetBoneName(i),ragdoll:TranslateBoneToPhysBone(i))
		end*/

		for i=26,55 do
			if (i-26)%15>11 then //Thumbs
				ragdoll:ManipulateBoneAngles(i,Angle(0,30,0))
			else
				ragdoll:ManipulateBoneAngles(i,Angle(0,-30,0))
			end
		end
 

		/*self.step_timer = 0
		self.step_cycle = 0

		self.step_base = Vector(5,1000,-145)

		self.step_alt = Vector(-5,1000,-145)

		self.step_goal = self.step_base*/

		self.type_sound = CreateSound(self,"ambient/machines/keyboard_fast1_1second.wav")

		self.lean = Vector(0,0,0)

		self.steps = {}
		self.step_wait = true

		self.do_limp = false
		self.limp_timer = 0

		self.punch_l = 0
		self.punch_r = 0
		self.blocking = false

		self.duck = false

		self.next_jump = CurTime()

		self:SetEnergy(self.MaxEnergy)
		self:SetWeakness(0)

		local ply = self:GetController()
		self.yaw=ply:EyeAngles()
		self.yaw.p = 0

		
		//ply:SetViewEntity(self)
		ply.controller = self
		
		self:StartMotionController()
		self:AddToMotionController(ragdoll:GetPhysicsObject())

		self:SetParent(ragdoll)
		//self:SetPos(ragdoll:GetBonePosition(1)+Vector(0,0,0))
		//self:FollowBone(ragdoll,1)
		self:SetLocalPos(Vector())

		/*self:SetColor(Color(0,0,0,0))
		self:SetRenderMode(RENDERMODE_TRANSALPHA)*/
		self:DrawShadow(false)

		for i=1, ragdoll:GetPhysicsObjectCount() do
			ragdoll:GetPhysicsObjectNum(i-1):AddGameFlag(FVPHYSICS_NO_SELF_COLLISIONS)
		end

		self.body_set = { -- our damageable physobjs (head and body)
			ragdoll:GetPhysicsObjectNum(0),
			ragdoll:GetPhysicsObjectNum(1),
			ragdoll:GetPhysicsObjectNum(10)
		}

		ragdoll:AddCallback("PhysicsCollide",function(ragdoll,data) self:RagdollCollide(ragdoll,data) end)

		//base steps
		local control = Vector()

		self:StepStart(SIDE_LEFT,self:GetStepPos(SIDE_LEFT,control),.1,5)
		self:StepStart(SIDE_RIGHT,self:GetStepPos(SIDE_RIGHT,control),.1,5)
	else
		//I would fix this gud but I am running out of time FAST
		//timer.Simple(.1,function()
			//if not IsValid(self) then return end
			//local ragdoll = self:GetRagdoll()
			
			
			//print(">>",self:GetChar())

			if self:GetController()==LocalPlayer() then
				LocalPlayerController = self
			end
		//end)
	end
end

local shadow_data = {
	secondstoarrive = .0001,
	
	maxangular = 1000,
	maxangulardamp = 10000,
	
	maxspeed = 1000,
	maxspeeddamp = 10000,

	dampfactor = .8,

	teleportdistance = 1000
}

local function doControl(phys,pos,ang)

	shadow_data.pos = pos
	shadow_data.angle = ang

	if !ang then
		shadow_data.maxangular = 0
		phys:ComputeShadowControl(shadow_data)
		shadow_data.maxangular = 1000
	else
		phys:ComputeShadowControl(shadow_data)
	end
end

function ENT:PhysicsSimulate(phys_body,dt)
	if not IsValid(self:GetController()) then
		self:Remove()
		return
	end

	self:GetController():SetPos(self:GetPos())

	//`debugoverlay.Cross(self:GetController():GetPos(), 10, 1,Color(255,255,0), false)

	local ragdoll = self:GetRagdoll()

	local phys_footl = ragdoll:GetPhysicsObjectNum(13)
	local phys_footr = ragdoll:GetPhysicsObjectNum(14)

	local vang = self:GetController():EyeAngles()
	vang.p = 0

	self.yaw = LerpAngle(.1,self.yaw,vang)

	if self.limp_timer>0 then
		self.limp_timer = self.limp_timer-dt

		if self.limp_timer>0 then
			return
		else
			local tr_l = util.TraceLine{start = phys_footl:GetPos(), endpos = phys_footl:GetPos()+Vector(0,0,-10), filter=ragdoll}
			local tr_r = util.TraceLine{start = phys_footl:GetPos(), endpos = phys_footl:GetPos()+Vector(0,0,-10), filter=ragdoll}

			//if tr_l.Hit and tr_r.Hit then
				//self:StepStart(SIDE_LEFT,tr_l.HitPos,.1,5)
				//self:StepStart(SIDE_RIGHT,tr_r.HitPos,.1,5)
				local control = Vector()

				self:StepStart(SIDE_LEFT,self:GetStepPos(SIDE_LEFT,control),.1,5)
				self:StepStart(SIDE_RIGHT,self:GetStepPos(SIDE_RIGHT,control),.1,5)

				if self.do_limp then
					self.limp_timer=.5
					self.do_limp=false
					return //failed to stand up... notify user somehow?
				end
				self.limp_invuln = false
				
				self.ctrl_jump=nil
				self.ctrl_attack_1=nil
				self.ctrl_attack_2=nil

				self.next_jump = CurTime()+1
			/*else
				self.limp_timer=1
				print("cant get up")
				return //failed to stand up... notify user somehow?
			end*/
		end
	end

	local phys_head = ragdoll:GetPhysicsObjectNum(10)

	if self.ctrl_jump and CurTime()>self.next_jump then
		self:EmitSound("player/pl_pain5.wav")
		self.limp_timer = 2
		local vel = Vector(0,0,900)+self.lean*self:GetEnergy()*10
		phys_body:SetVelocity(vel)
		phys_head:SetVelocity(vel)
		return
	end

	shadow_data.deltatime = dt

	if self:GetController():IsTyping() != self.type_sound:IsPlaying() then
		if self:GetController():IsTyping() then
			self.type_sound:Play()
		else
			self.type_sound:Stop()
		end
	end

	local phys_fistl = ragdoll:GetPhysicsObjectNum(5)
	local phys_fistr = ragdoll:GetPhysicsObjectNum(7)

	if self:GetController():IsTyping() then
		doControl(phys_fistl,phys_body:GetPos()+Vector(0,0,10+math.sin(CurTime()*50)*10)+self.yaw:Forward()*15+self.yaw:Right()*-5)
		doControl(phys_fistr,phys_body:GetPos()+Vector(0,0,10-math.sin(CurTime()*50)*10)+self.yaw:Forward()*15+self.yaw:Right()*5)
	elseif self.won then
		doControl(phys_fistl,phys_body:GetPos()+Vector(0,0,40+math.sin(CurTime()*10)*20)+self.yaw:Forward()*10+self.yaw:Right()*-5)
		doControl(phys_fistr,phys_body:GetPos()+Vector(0,0,40+math.sin(CurTime()*10)*20)+self.yaw:Forward()*10+self.yaw:Right()*5)
	elseif self.punch_l>0 then
		self.punch_l=self.punch_l-dt
		if self.punch_l>.3 then
			doControl(phys_fistl,phys_body:GetPos()+Vector(0,0,80)+self.yaw:Forward()*100)
		else
			doControl(phys_fistl,phys_body:GetPos()+Vector(0,0,10)+self.yaw:Forward()*10+self.yaw:Right()*-5)
		end
		doControl(phys_fistr,phys_body:GetPos()+Vector(0,0,10)+self.yaw:Forward()*10+self.yaw:Right()*5)
	elseif self.punch_r>0 then
		self.punch_r=self.punch_r-dt
		if self.punch_r>.3 then
			doControl(phys_fistr,phys_body:GetPos()+Vector(0,0,80)+self.yaw:Forward()*100)
		else
			doControl(phys_fistr,phys_body:GetPos()+Vector(0,0,10)+self.yaw:Forward()*10+self.yaw:Right()*5)
		end
		doControl(phys_fistl,phys_body:GetPos()+Vector(0,0,10)+self.yaw:Forward()*10+self.yaw:Right()*-5)
	else
		self.blocking = self:GetController():KeyDown(IN_RELOAD)
		if self.blocking then
			doControl(phys_fistl,phys_body:GetPos()+Vector(0,0,30)+self.yaw:Forward()*10+self.yaw:Right()*-3)
			doControl(phys_fistr,phys_body:GetPos()+Vector(0,0,30)+self.yaw:Forward()*10+self.yaw:Right()*3)
		else
			if self.ctrl_attack_1 then
				self.punch_l=.4
				self:EmitSound("npc/vort/claw_swing1.wav")
			elseif self.ctrl_attack_2 then
				self.punch_r=.4
				self:EmitSound("npc/vort/claw_swing2.wav")
			end

			doControl(phys_fistl,phys_body:GetPos()+Vector(0,0,10)+self.yaw:Forward()*10+self.yaw:Right()*-5)
			doControl(phys_fistr,phys_body:GetPos()+Vector(0,0,10)+self.yaw:Forward()*10+self.yaw:Right()*5)
		end
	end

	self.ctrl_jump=nil
	self.ctrl_attack_1=nil
	self.ctrl_attack_2=nil
	

	

	local foot_base = (phys_footl:GetPos()+phys_footr:GetPos())/2  //self.step_alt //(self.step_alt+self.step_goal)*.5
	foot_base.z = math.min(phys_footl:GetPos().z,phys_footr:GetPos().z)
	foot_base = foot_base + self.lean

	self.duck = self:GetController():KeyDown(IN_DUCK)


	foot_base = foot_base + (self.duck and Vector(0,0,10) or Vector(0,0,30))

	doControl(phys_body,foot_base,self.yaw+Angle(0,90,90))
	doControl(phys_head,foot_base+Vector(0,0,40),self.yaw+Angle(-90,90,0)) //mid vec component = -n to lean fwd


	if self.step_wait then
		self:StepPoll()
	end


	self:StepThink(SIDE_LEFT,dt)
	self:StepThink(SIDE_RIGHT,dt)

	ragdoll:GetPhysicsObjectNum(8):AddAngleVelocity( Vector(0,0,-50) )
	ragdoll:GetPhysicsObjectNum(11):AddAngleVelocity( Vector(0,0,-50) )
end

if SERVER then
	function ENT:Think()
		local ragdoll = self:GetRagdoll()
		ragdoll:PhysWake()
	end
end

function ENT:GetFootBone(side)
	local ragdoll = self:GetRagdoll()
	return side and ragdoll:GetPhysicsObjectNum(14) or ragdoll:GetPhysicsObjectNum(13)
end

function ENT:StepStart(side,goal,time,height)
	local bone = self:GetFootBone(side)

	self.steps[side] = {
		t= 0,
		start= bone:GetPos(),
		goal= goal,
		time = time,
		height = height
	}

	self.step_wait = false
end

function ENT:StepThink(side,dt)
	local step = self.steps[side]
	if not step then return end

	local bone = self:GetFootBone(side)

	if step.t<1 then
		step.t = step.t + dt/step.time

		local foot_pos = LerpVector(step.t,step.start,step.goal)
		foot_pos.z = foot_pos.z + math.sin(step.t*math.pi)*step.height
		doControl(bone,foot_pos)

		if step.t>=1 then
			self.step_wait = true
			self:EmitSound("player/footsteps/wood"..math.random(1,4)..".wav")
		end
	else
		doControl(bone,step.goal)
	end
end

function ENT:StepPoll()
	if self.do_limp then
		self.do_limp = false
		self.limp_timer = 3

		self:EmitSound(RAGCOM_CHARS[self:GetChar()].neg)
		self:TryTakeEnergy(energy_fall)
		return
	end

	local fwd = 0
	if self:GetController():KeyDown(IN_FORWARD) then
		fwd = 1
	elseif self:GetController():KeyDown(IN_BACK) then
		fwd = -1
	end

	local left = 0
	if self:GetController():KeyDown(IN_MOVELEFT) then
		left = 1
	elseif self:GetController():KeyDown(IN_MOVERIGHT) then
		left = -1
	end

	local control = Vector(left,-fwd,0)
	control:Normalize()

	if self.duck or self.blocking then control=control*.5 end

	self.lean = control*10
	//self.lean.x = self.lean.x*.5
	self.lean:Rotate(self.yaw+Angle(0,90,0))

	local pos_l = self.steps[SIDE_LEFT] and self.steps[SIDE_LEFT].goal or self:GetFootBone(SIDE_LEFT):GetPos()
	local pos_r = self.steps[SIDE_RIGHT] and self.steps[SIDE_RIGHT].goal or self:GetFootBone(SIDE_RIGHT):GetPos()

	pos_l = WorldToLocal(pos_l,Angle(0,0,0),self:GetPos(),self.yaw+Angle(0,90,0))
	pos_r = WorldToLocal(pos_r,Angle(0,0,0),self:GetPos(),self.yaw+Angle(0,90,0))

	if fwd==0 then
		local feet_close = (pos_r.x-pos_l.x)<0

		if left==0 then
			local feet_dist_sqr = pos_l:DistToSqr(pos_r)

			if feet_close or feet_dist_sqr>400 then
				self:StepStart(SIDE_LEFT,self:GetStepPos(SIDE_LEFT,control),.1,5)
				self:StepStart(SIDE_RIGHT,self:GetStepPos(SIDE_RIGHT,control),.1,5)
			end
		elseif feet_close then
			/*if left==0 then
				self:StepStart(SIDE_LEFT,self:GetStepPos(SIDE_LEFT,control),.1,5)
				self:StepStart(SIDE_RIGHT,self:GetStepPos(SIDE_RIGHT,control),.1,5)
			end*/

			self:StepStart(left<0,self:GetStepPos(left<0,control),step_time,stride_height)
		else
			if left==0 then return end
			self:StepStart(left>0,self:GetStepPos(left>0,control),step_time,stride_height)
		end
	else
		local front = pos_r.y-pos_l.y>0
		local leader
		if fwd>0 then
			leader = !front
		else
			leader = front
		end

		self:StepStart(leader,self:GetStepPos(leader,control),step_time,stride_height)
	end
end

function ENT:GetStepPos(side,control)
	local ragdoll = self:GetRagdoll()

	local foot_offset = side and Vector(-5) or Vector(5)
	if control.y==0 and control.x!=0 then
		foot_offset.y = side and -5 or 5
	end

	foot_offset = foot_offset + control*stride_length

	foot_offset:Rotate(self.yaw+Angle(0,90,0))

	local base_pos = ragdoll:GetPhysicsObject():GetPos() + foot_offset
	
	local end_pos = base_pos+Vector(0,0,-80) // ~30 to ground, then another 50

	local tr = util.TraceLine{start = base_pos, endpos = end_pos, filter=ragdoll}

	if not tr.Hit or tr.StartSolid then
		self.do_limp = true
		//self:EmitSound("vo/npc/Barney/ba_ohshit03.wav")
	end

	return tr.HitPos
end

function ENT:TryTakeEnergy(n)
	local current = self:GetEnergy()
	if n<current then
		self:SetEnergy(current-n)
		return true
	end
end

function ENT:ForceTakeEnergy(n)
	local current = self:GetEnergy()
	if n>=current then
		self:SetEnergy(self.MaxEnergy)
		self:SetWeakness(self:GetWeakness()+1)
		self:EmitSound(RAGCOM_CHARS[self:GetChar()].neg)
		self.limp_timer = 2
		self.limp_invuln = true
		return true
	else
		self:SetEnergy(current-n)
	end
end

-- note: self is the ragdoll :/
function ENT:RagdollCollide(ragdoll,data)
	//PrintTable(data)
	if self.limp_timer>0 then
		if not self.limp_invuln and math.random(10)==1 and data.Speed>10 then self:TryTakeEnergy(1) end
	elseif not data.HitEntity:IsWorld() then
		local hurt = false
		for k,v in pairs(self.body_set) do
			if v == data.PhysObject then hurt=true break end
		end

		//print(data.Speed)
		if hurt and data.Speed>50 then
			self:EmitSound("physics/flesh/flesh_impact_bullet1.wav",75,50,.5)
			if self:ForceTakeEnergy(self.blocking and 2 or 6) then
				local punt_dir = ragdoll:GetPos()-data.HitEntity:GetPos()
				punt_dir:Normalize()
				local punt_power = 100+300*self:GetWeakness()
				for i=1, ragdoll:GetPhysicsObjectCount() do
					ragdoll:GetPhysicsObjectNum(i-1):SetVelocity(punt_dir*punt_power)
				end

				//ragdoll:GetPhysicsObject():SetVelocity(punt_dir*punt_power)
			end
		end
	end

	//print(">>")
	//PrintTable(data)
	//print("<<")

	//local d = math.max(data.HitObject:GetMass(),data.PhysObject:GetMass()) * (data.TheirOldVelocity - data.OurOldVelocity):Length()

	//print(math.max(data.HitObject:GetMass(),data.PhysObject:GetMass()))
	//print( (data.TheirOldVelocity - data.OurOldVelocity):Length() )

	//local hurt = false
	//for k,v in pairs(self.body_set) do
	//	if v == data.PhysObject then hurt=true break end
	//end

	//if hurt then self:TryTakeEnergy(math.floor(d/3000)) end

	//print(self.body_set[data.PhysObject])
	//PrintTable(self.body_set)
end

function ENT:WinTaunt()
	net.Start("ragcom_sound")
	net.WriteString(RAGCOM_CHARS[self:GetChar()].pos)
	net.Broadcast()

	self.won=true
end

function ENT:Draw()
	if self:GetController():IsTyping() then
		//self:DrawModel()
	end
end