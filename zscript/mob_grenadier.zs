	// ------------------------------------------------------------
	// hehehe
	// ------------------------------------------------------------
	class HDGrenadier:HDHumanoid{
		default{
			//$Category "Monsters/Hideous Destructor"
			//$Title "Grenadier"
			//$Sprite "PLA5A1"
			
			monster;
			+floorclip
			+quicktoretaliate
			+activatepcross
			+hdmobbase.hashelmet

			seesound "freshgrunt/sight";
			painsound "freshgrunt/pain";
			deathsound "freshgrunt/death";
			activesound "grunt/active";
			tag "$TAG_GRENADIER";

			speed 10;
			mass 150;
			maxtargetrange 65536;
			painchance 240;
			
			decal "BulletScratch";
			meleesound "weapons/smack";
			meleedamage 4;
			
			obituary "$OB_GRENADIER";
			hitobituary "$OB_GRENADIER_HIT";
		}
		int user_colour;
		property user_colour:user_colour;
		bool glloaded;
		int pistolloaded;
		int lastinginjury;
		bool blastclear;
		bool canshoot;
		double spread;

        override void beginplay(){
            super.beginplay();

			//get colors
			string trnsl="";
            int melanin = random(1,3);
            if(melanin == 1) trnsl ="WhiteInfiltrator";
            else if(melanin == 3) trnsl = "WhiteInfiltrator";
            else trnsl = "BlackInfiltrator";

            A_SetTranslation(trnsl);
        }

		override void postbeginplay(){
			super.postbeginplay();
			bhashelmet=true;
			sprite=GetSpriteIndex("PLA5A1");
			glloaded=true;
			pistolloaded=15;
			spread = 0.1;
			givearmour(1.,0.06,-0.4);
		}
		
		override void Tick(){
			super.Tick();
			if(isfrozen())return;
		}
		
		override int damagemobj(
			actor inflictor,actor source,int damage,
			name mod,int flags,double angle
			){
			if(
				health>0
				&&!(flags&DMG_FORCED)
				&&damage<TELEFRAG_DAMAGE
				&&damage>=health
				&&mod!="raisedrop"
				&&mod!="spawndead"
				&&damage<random(12,300-(lastinginjury<<1))
				&&(
					(mod=="bleedout"&&random(0,12))
					||(random(0,2))
				)
			){
				lastinginjury+=max((mod=="bashing"?0:1),(damage>>5));
				damage=health-5;
			}
			return super.damagemobj(inflictor,source,damage,mod,flags,angle);
		}
		
		override void die(actor source,actor inflictor,int dmgflags){
			if(
				bfriendly
				&&!BotBot(self)
				&&!HDPlayerCorpse(self)
				&&getage()>TICRATE
			)A_Log(string.format("\cf%s died.",gettag()));
			super.die(source,inflictor,dmgflags);
		}
		
		override void deathdrop() {
			if (!bhasdropped) {
				bhasdropped = true;
				hdweapon wp = hdweapon(spawn("Blooper", pos, ALLOW_REPLACE));
				if (glloaded) wp.weaponstatus[0] |= BLOPF_LOADED;
			} else {
				int n = random(0, 3);
				for (int i = 0; i < n; i++) {
					let mmm = spawn("HDRocketAmmo", pos, ALLOW_REPLACE);
					if (mmm) mmm.vel = vel + (frandom(-1, 1), frandom(-1, 1), 1);
				}
			}
		}

		actor A_OpShot(class<actor> missiletype, bool userocket = false) {
			actor mmm = spawn(missiletype, (pos.xy, pos.z + gunheight), ALLOW_REPLACE);
			mmm.pitch = pitch + frandom(0, spread) - frandom(0, spread);
			mmm.angle = angle + frandom(0, spread) - frandom(0, spread);
			mmm.target = self;
			if (!(mmm is "SlowProjectile")) mmm.A_ChangeVelocity(
				mmm.speed * cos(mmm.pitch), 0, mmm.speed * sin(mmm.pitch), CVF_RELATIVE
			);
			return mmm;
		}

		states{
		spawn:
			PLA5 A 1;
			goto idle;
			
		idle: 
			// maybe check if grenade launcher is ready here
			PLA5 A 1 A_JumpIf(bambush, "spawnstill");
			PLA5 ABCD 6 A_HDWander(CHF_LOOK);
			loop;
			
		spawnstill:
			PLA5 E 10 A_HDLook();
			loop;
			
		see:
			PLA5 ABCD 4 A_HDChase(speedmult:0.6);
			PLA5 A 1;
			PLA5 A 0 A_JumpIf(targetinsight, "see");
			loop;
			
		missile:
			PLA5 ABCD 3 A_TurnToAim(40, shootstate: "aiming");
			loop;
			
		aiming:
			PLA5 E 1 A_StartAim(rate: 0.8, mintics: random(0, timesdied), dontlead: randompick(0, 0, 0, 1));
			PLA5 A 0 setstatelabel("shoot");
			
		shoot:
			PLA5 E 4 {
				if (!target || target.health <= 0 || !CheckSight(target)) {
					target = null;
					SetStateLabel("noshot");
					return;
				}

				// DOOM MAP UNITS - 1 Doom unit = ~1/32 of a meter
				double minGrenadeRange = 480.0;   // self-safety radius, 15m * 32
				double blastRadius     = 192.0;  // grenade blast (used for friend check), 6m * 32 
				double dist            = Distance3D(target);
				bool unsafeForGrenade = false;

				// suicide check (don't shoot if too close)
				if (dist < minGrenadeRange) {
					unsafeForGrenade = true;
				}

				/*
				// friend check
				// changed my mind, the grenadier should not care about friendlies
				// leaving this here cause maybe ill change my mind again
				BlockThingsIterator it = BlockThingsIterator.Create(self, blastRadius);
				while (it.Next()) {
					Actor other = it.Thing;
					if (other == self) continue;
					if (other.health <= 0) continue;
					if (!other.bFriendly) continue; // only consider friendlies
					if (other.Distance3D(target) < blastRadius) {
						unsafeForGrenade = true;
						break;
					}
				}
				*/

				if (glloaded && !unsafeForGrenade && dist >= minGrenadeRange) {
					SetStateLabel("shootgrenade");
					return;
				}

				if (glloaded && unsafeForGrenade) {
					if (pistolloaded > 0) {
						SetStateLabel("shootpistol");
					} else {
						SetStateLabel("reloadpistol");
					}
					return;
				}

				if (!glloaded && !unsafeForGrenade && dist >= minGrenadeRange) {
					SetStateLabel("reloadgrenade");
					return;
				}
				SetStateLabel("see");
			}
			PLA5 A 0 setstatelabel("see");
		
		shootgrenade:
			PLA5 E 2 {
				if (target && target.health > 0) {
					class<actor> mn = "RocketGrenade";
					if (mn) {
						A_LeadTarget(lasttargetdist / getdefaultbytype(mn).speed, randompick(0, 0, 0, 1));
						double aaa = angle;
						A_FaceLastTargetPos(10, targetheight: 1.0);
						angle = aaa;
						hdmobai.DropAdjust(self, mn, lasttargetdist);
					}
				}
			}
			PLA5 F 0 A_JumpIf(!glloaded, "uhohtbisfuckingempty");
			PLA5 F 1 bright light("SHOT") {
				glloaded = false;
				A_OpShot("RocketGrenade");
			}
			// change time between shots here, shorter time ex: PLA5 E 1; 
			PLA5 E 8;
			goto see;

			reloadgrenade: 
				PLA5 A 4 A_StartSound("weapons/grenopen", 8);
				PLA5 ABCD 4 A_HDChase(null,null,CHF_FLEE);
				PLA5 B 4;
				PLA5 AB 3 A_StartSound("weapons/rockreload",8);
				PLA5 A 3;
				PLA5 B 2;
				PLA5 C 2 {
					A_StartSound("weapons/grenopen",CHAN_WEAPON,CHANF_OVERLAP);
					A_HDChase("melee",null);
					glloaded = true;
				}
				PLA5 D 2;
				goto see;

		shootpistol:
			PLA5 E 1;
			PLA5 E 1 {
				if (target && target.health > 0) {
					class<actor> mn = "HDB_9";
					if (mn) {
						A_LeadTarget(lasttargetdist / getdefaultbytype(mn).speed, randompick(0, 0, 0, 1));
						hdmobai.DropAdjust(self, mn);
					}
				}
			}
			PLA5 A 0 setstatelabel("firepistol");
		
	   firepistol:
		   PLA5 F 0 A_JumpIf(pistolloaded < 1, "reloadpistol");
		   PLA5 F 1 bright light("SHOT") {
			   pistolloaded--;
			   A_StartSound("weapons/pistol", CHAN_WEAPON);
			   HDBulletActor.FireBullet(self, "HDB_9", spread: 3.0, speedfactor: frandom(0.97, 1.03));
			   A_ShoutAlert(0.25, SAF_SILENT);
		   }
		   PLA5 E random(1, 4) A_EjectPistolCasing();
		   PLA5 E random(1, 4);
		   goto see;

	   reloadpistol:
		   PLA5 A 1 A_StartSound("weapons/pismagclick", CHAN_WEAPON);
		   PLA5 AB 3 A_HDChase(null,null,CHF_FLEE);
		   PLA5 DAB 3 A_HDChase(null,null,CHF_FLEE);
		   PLA5 C 8 A_StartSound("weapons/pocket",8);
		   PLA5 C 2 {
			   pistolloaded = 15;
		   }
		   PLA5 D 3 A_HDChase(null,null);
		   goto see;

	   noshot:
		   PLA5 E 6;
		   PLA5 A 0 setstatelabel("see");

		uhohtbisfuckingempty:
			PLA5 E 2;
			PLA5 A 0 setstatelabel("see");

		pain:
			PLA5 G 3 A_Jump(12,1);
			PLA5 G 3 A_Vocalize(painsound);
			PLA5 A 0 setstatelabel("see");

		death:
			PLA5 H 5;
			PLA5 I 5 A_Vocalize(deathsound);
			PLA5 JK 5;
			
		dead:
			PLA5 K 3 canraise{if(abs(vel.z)<2.)frame++;}
			PLA5 L 5 canraise{if(abs(vel.z)>=2.)setstatelabel("dead");}
			wait;
		}
	}

	class DeadGrenadier:HDGrenadier{
		override void postbeginplay(){
			super.postbeginplay();
			A_Die("spawndead");
		}
		states{
		death.spawndead:
			PLA5 A 0;
			goto dead;
		}
	}