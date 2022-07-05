#if defined _JJBA_included
 #endinput
#endif
#define _JJBA_included
#include <basic>
#include <vscripts>
#include <float>

#define TICKRATE 0.1
#define TARGET_DISTANCE 5000.0
#define RETARGET_TIME 7.5
#define SPEED_FORWARD 1.0
#define SPEED_TURNING 0.5

stock float FloatMod(float num, float denom)
{
    return num - denom * RoundToFloor(num / denom);
}

stock float operator%(float oper1, float oper2)
{
    return FloatMod(oper1, oper2);
}

public bool IsValidPlayer(int player)
{
	return player >= 1 && player <= 64 && IsValidEntity(player) && IsPlayerAlive(player);
}

public float GetDistance(const float v1[3], const float v2[3])
{
	return SquareRoot((v1[0] - v2[0]) * (v1[0] - v2[0]) + (v1[1] - v2[1]) * (v1[1] - v2[1]) + (v1[2] - v2[2]) * (v1[2] - v2[2]));
}

methodmap MovingNpc < Basic
{
	public MovingNpc(int entity)
	{
		Basic myclass = new Basic();
		myclass.SetInt("iEntity", entity);
		myclass.SetInt("iTarget", -1);
		myclass.SetInt("iTf", -1);
		myclass.SetInt("iTs", -1);
		myclass.SetFloat("fTtime", 0.0);
		myclass.SetBool("bTicking", false);
		return view_as<MovingNpc>(myclass);
	}
	property int entity
	{
		public get()
		{
			return this.GetInt("iEntity");
		}
		public set(int val)
		{
			this.SetInt("iEntity", val);
		}
	}
	property int target
	{
		public get()
		{
			return this.GetInt("iTarget");
		}
		public set(int val)
		{
			this.SetInt("iTarget", val);
		}
	}
	property int tf
	{
		public get()
		{
			return this.GetInt("iTf");
		}
		public set(int val)
		{
			this.SetInt("iTf", val);
		}
	}
	property int ts
	{
		public get()
		{
			return this.GetInt("iTs");
		}
		public set(int val)
		{
			this.SetInt("iTs", val);
		}
	}
	property float ttime
	{
		public get()
		{
			return this.GetFloat("fTtime");
		}
		public set(float val)
		{
			this.SetFloat("fTtime", val);
		}
	}
	property bool ticking
	{
		public get()
		{
			return this.GetBool("bTicking");
		}
		public set(bool val)
		{
			this.SetBool("bTicking", val);
		}
	}
	
	public void Start()
	{
		if(!this.ticking)
		{
			this.ticking = true;
			CreateTimer(TICKRATE, Tick_Cb, this, TIMER_FLAG_NO_MAPCHANGE);
		}
	}
	
	public void Stop()
	{
		if(this.ticking)
		{
			this.ticking = false;
		}
	}
	
	public float GetTargetYaw(const float start[3], const float target[3])
	{
		float yaw = 0.00;
		float v[3];
		SubtractVectors(start, target, v);
		float vl = SquareRoot(v[0] * v[0] + v[1] * v[1]);
		yaw = 180.0 * ArcCosine(v[0] / vl) / 3.14159;
		if (v[1] < 0.0)
			yaw = -yaw;
		
		return yaw;
	}
	
	public void SetThruster(bool fwd, int caller)
	{
		if(fwd)
			this.tf = caller;
		else 
			this.ts = caller;
	}
	
	public void SearchTarget()
	{
		this.ttime = 0.00;
		this.target = -1;
		int h = -1;
		ArrayList candidates = new ArrayList();
		float orig[3];
		GetOrigin(this.entity, orig);
		while (-1 != (h = FindEntityByClassnameWithin(h, "player", orig, TARGET_DISTANCE)))
		{
			//check if target is a valid player + CT team(3) + health above 0 (not dead)
			if (GetClientTeam(h) == 3 && IsPlayerAlive(h))
			{
				//check if the target is in sight of the npc (this physbox origin+48 height)
				float t_orig[3];
				GetOrigin(this.entity, orig);
				orig[2] += 40.0;
				GetOrigin(h, t_orig);
				t_orig[2] += 48.0;
				if (TraceLine(orig, t_orig, this.entity) == 1.00)
					candidates.Push(h);	//if everything required is OK, add the target to the list of candidates
			}
		}
		if(candidates.Length == 0)
		{
			delete candidates;
			return;
		}
		this.target = candidates.Get(GetRandomInt(0, candidates.Length - 1));
		
		delete candidates;
	}
	
	public void Tick()
	{
		EntFireByIndex(this.tf, "Deactivate", "", "0.00", -1);
		EntFireByIndex(this.ts, "Deactivate", "", "0.00", -1);
		if (!IsValidPlayer(this.target) || GetClientTeam(this.target) != 3 || this.ttime >= RETARGET_TIME)
		{
			this.SearchTarget();
		}
		this.ttime+=TICKRATE;
		EntFireByIndex(this.tf, "Activate", "", "0.02", -1);
		EntFireByIndex(this.ts, "Activate", "", "0.02", -1);
		float angl[3], s_orig[3], t_orig[3];
		GetAngles(this.entity, angl);
		float sa = angl[1];
		GetOrigin(this.entity, s_orig);
		GetOrigin(this.target, t_orig);
		float ta = this.GetTargetYaw(s_orig, t_orig);
		float ang = FloatAbs((sa - ta + 360.0) % 360.0);
		if (ang >= 180.0)
			EntFireByIndex(this.ts, "AddOutput", "angles 0 270 0", "0.00", -1);
		else 
			EntFireByIndex(this.ts, "AddOutput", "angles 0 90 0", "0.00", -1);
		float angdif = (sa - ta - 180.0);
		while (angdif > 360.0) { angdif -= 180.0; }
		while (angdif < -180.0) { angdif += 360.0; }
		angdif = FloatAbs(angdif);
		GetOrigin(this.entity, s_orig);
		GetOrigin(this.target, t_orig);
		//float tdist = GetDistance(s_orig, t_orig);
		//float tdistz = (t_orig[2] - s_orig[2]);
		char input[128];
		Format(input, sizeof(input), "force %.4f", 3000.0 * SPEED_FORWARD);
		EntFireByIndex(this.tf, "AddOutput", input, "0.00", -1);
		Format(input, sizeof(input), "force %.4f", (3.0 * SPEED_TURNING) * angdif);
		EntFireByIndex(this.ts, "AddOutput", input, "0.00", -1);
		CreateTimer(TICKRATE, Tick_Cb, this, TIMER_FLAG_NO_MAPCHANGE);
	}
}

public Action Tick_Cb(Handle timer, MovingNpc npc)
{
	KillTimer(timer);
	if(npc.ticking)
	{
		npc.Tick();
	}
	else
	{
		EntFireByIndex(npc.tf, "Deactivate", "", "0.00", -1);
		EntFireByIndex(npc.ts, "Deactivate", "", "0.00", -1);
		delete npc;
	}
	return Plugin_Stop;
}
