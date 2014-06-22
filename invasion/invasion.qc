/*
	Invasion Mod code
	by: Thunderrump

	Some ugly code is below, but overall a functional invasion mod.  Was
	fun to experience the limitations of QuakeC and come up with workarounds.
	The original QuakeC didn't have arrays! The mods that support arrays
	only support global arrays.

*/

// Prototypes
void(float wave) init_wave_data;
void() inv_controller;
void() inv_controller_think;
void() inv_spawn;
void(entity e) next_wave;
void(entity e) wave_spawn;

// Monster spawn convenience functions
void(entity e) spawn_army;
void(entity e) spawn_demon1;
void(entity e) spawn_dog;
void(entity e) spawn_enforcer;
void(entity e) spawn_fish;
void(entity e) spawn_knight;
void(entity e) spawn_hknight;
void(entity e) spawn_ogre;
void(entity e) spawn_shambler;
void(entity e) spawn_shalrath;
void(entity e) spawn_tarbaby;
void(entity e) spawn_wizard;
void(entity e) spawn_zombie;


// How many waves to carry out?
.float wave_limit;

// What wave are we on?
.float curr_wave;

// Last entity type spawned
.float last_spawn;

// Is spawner done for this wave?
.float complete;


// Limits for each monster per wave
/*
	Supported monsters:
		Army (Soldier/Grunt) - monster_army
		Demon - monster_demon1
		Dog - monster_dog
		Enforcer - monster_enforcer
		Fish - monster_fish
		Knight - monster_knight
		Hellknight - monster_hell_knight
		Ogre - monster_ogre
		Shambler - monster_shambler
		Shalrath - monster_shalrath
		Tarbaby - monster_tarbaby
		Wizard - monster_wizard
		Zombie - monster_zombie
*/

// Entity vars for waves
.float wave_0_army, wave_1_army, wave_2_army, wave_3_army, wave_4_army, wave_5_army, wave_6_army, wave_7_army, wave_8_army, wave_9_army;
.float wave_0_demon1, wave_1_demon1, wave_2_demon1, wave_3_demon1, wave_4_demon1, wave_5_demon1, wave_6_demon1, wave_7_demon1, wave_8_demon1, wave_9_demon1;
.float wave_0_dog, wave_1_dog, wave_2_dog, wave_3_dog, wave_4_dog, wave_5_dog, wave_6_dog, wave_7_dog, wave_8_dog, wave_9_dog;
.float wave_0_enforcer, wave_1_enforcer, wave_2_enforcer, wave_3_enforcer, wave_4_enforcer, wave_5_enforcer, wave_6_enforcer, wave_7_enforcer, wave_8_enforcer, wave_9_enforcer;
.float wave_0_fish, wave_1_fish, wave_2_fish, wave_3_fish, wave_4_fish, wave_5_fish, wave_6_fish, wave_7_fish, wave_8_fish, wave_9_fish;
.float wave_0_knight, wave_1_knight, wave_2_knight, wave_3_knight, wave_3_knight, wave_4_knight, wave_5_knight, wave_6_knight, wave_7_knight, wave_8_knight, wave_9_knight;
.float wave_0_hknight, wave_1_hknight, wave_2_hknight, wave_3_hknight, wave_4_hknight, wave_5_hknight, wave_5_hknight, wave_6_hknight, wave_7_hknight, wave_8_hknight, wave_9_hknight;
.float wave_0_ogre, wave_1_ogre, wave_2_ogre, wave_3_ogre, wave_4_ogre, wave_5_ogre, wave_6_ogre, wave_7_ogre, wave_8_ogre, wave_9_ogre;
.float wave_0_shambler, wave_1_shambler, wave_2_shambler, wave_3_shambler, wave_4_shambler, wave_5_shambler, wave_6_shambler, wave_7_shambler, wave_8_shambler, wave_9_shambler;
.float wave_0_shalrath, wave_1_shalrath, wave_2_shalrath, wave_3_shalrath, wave_4_shalrath, wave_5_shalrath, wave_6_shalrath, wave_7_shalrath, wave_8_shalrath, wave_9_shalrath;
.float wave_0_tarbaby, wave_1_tarbaby, wave_2_tarbaby, wave_3_tarbaby, wave_4_tarbaby, wave_5_tarbaby, wave_6_tarbaby, wave_7_tarbaby, wave_8_tarbaby, wave_9_tarbaby;
.float wave_0_wizard, wave_1_wizard, wave_2_wizard, wave_3_wizard, wave_4_wizard, wave_5_wizard, wave_6_wizard, wave_7_wizard, wave_8_wizard, wave_9_wizard;
.float wave_0_zombie, wave_1_zombie, wave_2_zombie, wave_3_zombie, wave_4_zombie, wave_5_zombie, wave_6_zombie, wave_7_zombie, wave_8_zombie, wave_9_zombie;

// Arrays to hold above entity variables to avoid excessive DRY violation
.float curr_wave_army, curr_wave_demon1, curr_wave_dog, curr_wave_enforcer, curr_wave_fish;
.float curr_wave_knight, curr_wave_hknight, curr_wave_ogre, curr_wave_shambler;
.float curr_wave_shalrath, curr_wave_tarbaby, curr_wave_wizard, curr_wave_zombie;

/*
	The brains of the invasion operation

	Loops over inv_spawn entities and spawns new monsters if necessary.
	Once all spawners are complete, move to next wave or next map
*/
void() inv_controller_think = {
	local entity e;
	local float spawners_complete;
	
	spawners_complete = 1;
	for(e = world; (e = find(e, classname, "inv_spawn")); ) { 
		// Self at this point is the inv_controller, e is an inv_spawn entity
		wave_spawn(e);

		if not (e.complete) {
			spawners_complete = 0;
		}
	}

	// Wave progression/completion
	if(spawners_complete && (total_monsters - killed_monsters == 0)) {
		if(self.curr_wave + 1 < self.wave_limit ) {
			// Next Wave
			for(e = world; (e = find(e, classname, "inv_spawn")); ) { 
				next_wave(e);
			}
			self.curr_wave++;
			bprint("Wave complete!\n");
		} else {
			// TODO: Figure out best mapcycle handling, would prefer to read from maplist.txt
			// Dummy repeat of single map for now
			nextmap = mapname;
			GotoNextMap();
		}
	}

	self.nextthink = time + 5;
};

/*
	Entity hookup for invasion controller

	Think method init
*/
void() inv_controller = 
{
	self.curr_wave = 0;

	self.think = inv_controller_think;
	self.nextthink = time + 2;
}

/*
	Entity hookup for inv_spawn

	Prepares data from inv_spawn entity
*/
void() inv_spawn =
{
	// Setup wave data
	self.curr_wave = 0;
	self.last_spawn = -1;
	self.complete = 0;

	init_wave_data(self.curr_wave);
};

/*
	Progress to the next wave, load next waves data
*/
void(entity e) next_wave = {
	local entity oldself;
	
	oldself = self;
	self = e;

	self.curr_wave++;
	self.last_spawn = -1;
	self.complete = 0;

	init_wave_data(self.curr_wave);

	self = oldself;
};

/*
	Spawn whatever monster is in the queue

	If no monsters left, set complete for entity.
*/
void(entity e) wave_spawn = 
{
	while(1) {
		if(e.curr_wave_army && e.last_spawn < 0) {
			e.curr_wave_army = e.curr_wave_army - 1;
			e.last_spawn = 0;
			spawn_army(e);
			break;
		} else if(e.curr_wave_demon1 && e.last_spawn < 1) {
			e.curr_wave_demon1 = e.curr_wave_demon1 - 1;
			e.last_spawn = 1;
			spawn_demon1(e);
			break;
		} else if(e.curr_wave_dog && e.last_spawn < 2) {
			e.curr_wave_dog = e.curr_wave_dog - 1;
			e.last_spawn = 2;
			spawn_dog(e);
			break;
		} else if(e.curr_wave_enforcer && e.last_spawn < 3) {
			e.curr_wave_enforcer = e.curr_wave_enforcer - 1;
			e.last_spawn = 3;
			spawn_enforcer(e);
			break;
		} else if(e.curr_wave_fish && e.last_spawn < 4) {
			e.curr_wave_fish = e.curr_wave_fish - 1;
			e.last_spawn = 4;
			spawn_fish(e);
			break;
		} else if(e.curr_wave_knight && e.last_spawn < 5) {
			e.curr_wave_knight = e.curr_wave_knight - 1;
			e.last_spawn = 5;
			spawn_knight(e);
			break;
		} else if(e.curr_wave_hknight && e.last_spawn < 6) {
			e.curr_wave_hknight = e.curr_wave_hknight - 1;
			e.last_spawn = 6;
			spawn_hknight(e);
			break;
		} else if(e.curr_wave_ogre && e.last_spawn < 7) {
			e.curr_wave_ogre = e.curr_wave_ogre - 1;
			e.last_spawn = 7;
			spawn_ogre(e);
			break;
		} else if(e.curr_wave_shalrath && e.last_spawn < 8) {
			e.curr_wave_shalrath = e.curr_wave_shalrath - 1;
			e.last_spawn = 8;
			spawn_shalrath(e);
			break;
		} else if(e.curr_wave_shambler && e.last_spawn < 9) {
			e.curr_wave_shambler = e.curr_wave_shambler - 1;
			e.last_spawn = 9;
			spawn_shambler(e);
			break;
		} else if(e.curr_wave_tarbaby && e.last_spawn < 10) {
			e.curr_wave_tarbaby = e.curr_wave_tarbaby - 1;
			e.last_spawn = 10;
			spawn_tarbaby(e);
			break;
		} else if(e.curr_wave_wizard && e.last_spawn < 11) {
			e.curr_wave_wizard = e.curr_wave_wizard - 1;
			e.last_spawn = 11;
			spawn_wizard(e);
			break;
		} else if(e.curr_wave_zombie && e.last_spawn < 12) {
			e.curr_wave_zombie = e.curr_wave_zombie - 1;
			e.last_spawn = 12;
			spawn_zombie(e);
			break;
		}

		// Getting here means loop didn't break
		// If only thing left was last spawn, reset to spawn it
		if(e.last_spawn != -1) {
			e.last_spawn = -1;
		// Otherwise, this spawner is done for the wave
		} else {
			e.complete = 1;
			break;
		}
	}
};


/*
	Monster spawning code, might be able to clean this up some
*/
void(entity e) spawn_army = {
	local entity oldself;
	oldself = self;
	self = spawn();
	self.classname = "monster_army";
	self.origin = e.origin;
	monster_army();
	self = oldself;
};

void(entity e) spawn_demon1 = {
	local entity oldself;
	oldself = self;
	self = spawn();
	self.classname = "monster_demon1";
	self.origin = e.origin;
	monster_demon1();
	self = oldself;

};

void(entity e) spawn_dog = {
	local entity oldself;
	oldself = self;
	self = spawn();
	self.classname = "monster_dog";
	self.origin = e.origin;
	monster_dog();
	self = oldself;

};

void(entity e) spawn_enforcer = {
	local entity oldself;
	oldself = self;
	self = spawn();
	self.classname = "monster_enforcer";
	self.origin = e.origin;
	monster_enforcer();
	self = oldself;

};

void(entity e) spawn_fish = {
	local entity oldself;
	oldself = self;
	self = spawn();
	self.classname = "monster_fish";
	self.origin = e.origin;
	monster_fish();
	self = oldself;

};

void(entity e) spawn_knight = {
	local entity oldself;
	oldself = self;
	self = spawn();
	self.classname = "monster_knight";
	self.origin = e.origin;
	monster_hell_knight();
	self = oldself;

};

void(entity e) spawn_hknight = {
	local entity oldself;
	oldself = self;
	self = spawn();
	self.classname = "monster_knight";
	self.origin = e.origin;
	monster_knight();
	self = oldself;

};

void(entity e) spawn_ogre = {
	local entity oldself;
	oldself = self;
	self = spawn();
	self.classname = "monster_ogre";
	self.origin = e.origin;
	monster_ogre();
	self = oldself;

};

void(entity e) spawn_shambler = {
	local entity oldself;
	oldself = self;
	self = spawn();
	self.classname = "monster_shambler";
	self.origin = e.origin;
	monster_shambler();
	self = oldself;

};

void(entity e) spawn_shalrath = {
	local entity oldself;
	oldself = self;
	self = spawn();
	self.classname = "monster_shalrath";
	self.origin = e.origin;
	monster_shalrath();
	self = oldself;

};

void(entity e) spawn_tarbaby = {
	local entity oldself;
	oldself = self;
	self = spawn();
	self.classname = "monster_tarbaby";
	self.origin = e.origin;
	monster_tarbaby();
	self = oldself;

};

void(entity e) spawn_wizard = {
	local entity oldself;
	oldself = self;
	self = spawn();
	self.classname = "monster_wizard";
	self.origin = e.origin;
	monster_wizard();
	self = oldself;

};

void(entity e) spawn_zombie = {
	local entity oldself;
	oldself = self;
	self = spawn();
	self.classname = "monster_zombie";
	self.origin = e.origin;
	monster_zombie();
	self = oldself;

};

/*
	End Monster Spawning Code
*/

/*
	Big ugly function for moving wave data into curr_wave vars

	float wave	What wave to load data for?
*/
void(float wave) init_wave_data = {
	switch(wave) {
	case 0:
		self.curr_wave_army = self.wave_0_army;
		self.curr_wave_demon1 = self.wave_0_demon1;
		self.curr_wave_dog = self.wave_0_dog;
		self.curr_wave_enforcer = self.wave_0_enforcer;
		self.curr_wave_fish = self.wave_0_fish;
		self.curr_wave_knight = self.wave_0_knight;
		self.curr_wave_hknight = self.wave_0_hknight;
		self.curr_wave_ogre = self.wave_0_ogre;
		self.curr_wave_shambler = self.wave_0_shambler;
		self.curr_wave_shalrath = self.wave_0_shalrath;
		self.curr_wave_tarbaby = self.wave_0_tarbaby;
		self.curr_wave_wizard = self.wave_0_wizard;
		self.curr_wave_zombie = self.wave_0_zombie;
		break;
	case 1:
		self.curr_wave_army = self.wave_1_army;
		self.curr_wave_demon1 = self.wave_1_demon1;
		self.curr_wave_dog = self.wave_1_dog;
		self.curr_wave_enforcer = self.wave_1_enforcer;
		self.curr_wave_fish = self.wave_1_fish;
		self.curr_wave_knight = self.wave_1_knight;
		self.curr_wave_hknight = self.wave_1_hknight;
		self.curr_wave_ogre = self.wave_1_ogre;
		self.curr_wave_shambler = self.wave_1_shambler;
		self.curr_wave_shalrath = self.wave_1_shalrath;
		self.curr_wave_tarbaby = self.wave_1_tarbaby;
		self.curr_wave_wizard = self.wave_1_wizard;
		self.curr_wave_zombie = self.wave_1_zombie;

		break;
	case 2:
		self.curr_wave_army = self.wave_2_army;
		self.curr_wave_demon1 = self.wave_2_demon1;
		self.curr_wave_dog = self.wave_2_dog;
		self.curr_wave_enforcer = self.wave_2_enforcer;
		self.curr_wave_fish = self.wave_2_fish;
		self.curr_wave_knight = self.wave_2_knight;
		self.curr_wave_hknight = self.wave_2_hknight;
		self.curr_wave_ogre = self.wave_2_ogre;
		self.curr_wave_shambler = self.wave_2_shambler;
		self.curr_wave_shalrath = self.wave_2_shalrath;
		self.curr_wave_tarbaby = self.wave_2_tarbaby;
		self.curr_wave_wizard = self.wave_2_wizard;
		self.curr_wave_zombie = self.wave_2_zombie;

		break;
	case 3:
		self.curr_wave_army = self.wave_3_army;
		self.curr_wave_demon1 = self.wave_3_demon1;
		self.curr_wave_dog = self.wave_3_dog;
		self.curr_wave_enforcer = self.wave_3_enforcer;
		self.curr_wave_fish = self.wave_3_fish;
		self.curr_wave_knight = self.wave_3_knight;
		self.curr_wave_hknight = self.wave_3_hknight;
		self.curr_wave_ogre = self.wave_3_ogre;
		self.curr_wave_shambler = self.wave_3_shambler;
		self.curr_wave_shalrath = self.wave_3_shalrath;
		self.curr_wave_tarbaby = self.wave_3_tarbaby;
		self.curr_wave_wizard = self.wave_3_wizard;
		self.curr_wave_zombie = self.wave_3_zombie;

		break;
	case 4:
		self.curr_wave_army = self.wave_4_army;
		self.curr_wave_demon1 = self.wave_4_demon1;
		self.curr_wave_dog = self.wave_4_dog;
		self.curr_wave_enforcer = self.wave_4_enforcer;
		self.curr_wave_fish = self.wave_4_fish;
		self.curr_wave_knight = self.wave_4_knight;
		self.curr_wave_hknight = self.wave_4_hknight;
		self.curr_wave_ogre = self.wave_4_ogre;
		self.curr_wave_shambler = self.wave_4_shambler;
		self.curr_wave_shalrath = self.wave_4_shalrath;
		self.curr_wave_tarbaby = self.wave_4_tarbaby;
		self.curr_wave_wizard = self.wave_4_wizard;
		self.curr_wave_zombie = self.wave_4_zombie;

		break;
	case 5:
		self.curr_wave_army = self.wave_5_army;
		self.curr_wave_demon1 = self.wave_5_demon1;
		self.curr_wave_dog = self.wave_5_dog;
		self.curr_wave_enforcer = self.wave_5_enforcer;
		self.curr_wave_fish = self.wave_5_fish;
		self.curr_wave_knight = self.wave_5_knight;
		self.curr_wave_hknight = self.wave_5_hknight;
		self.curr_wave_ogre = self.wave_5_ogre;
		self.curr_wave_shambler = self.wave_5_shambler;
		self.curr_wave_shalrath = self.wave_5_shalrath;
		self.curr_wave_tarbaby = self.wave_5_tarbaby;
		self.curr_wave_wizard = self.wave_5_wizard;
		self.curr_wave_zombie = self.wave_5_zombie;

		break;
	case 6:
		self.curr_wave_army = self.wave_6_army;
		self.curr_wave_demon1 = self.wave_6_demon1;
		self.curr_wave_dog = self.wave_6_dog;
		self.curr_wave_enforcer = self.wave_6_enforcer;
		self.curr_wave_fish = self.wave_6_fish;
		self.curr_wave_knight = self.wave_6_knight;
		self.curr_wave_hknight = self.wave_6_hknight;
		self.curr_wave_ogre = self.wave_6_ogre;
		self.curr_wave_shambler = self.wave_6_shambler;
		self.curr_wave_shalrath = self.wave_6_shalrath;
		self.curr_wave_tarbaby = self.wave_6_tarbaby;
		self.curr_wave_wizard = self.wave_6_wizard;
		self.curr_wave_zombie = self.wave_6_zombie;

		break;
	case 7:
		self.curr_wave_army = self.wave_7_army;
		self.curr_wave_demon1 = self.wave_7_demon1;
		self.curr_wave_dog = self.wave_7_dog;
		self.curr_wave_enforcer = self.wave_7_enforcer;
		self.curr_wave_fish = self.wave_7_fish;
		self.curr_wave_knight = self.wave_7_knight;
		self.curr_wave_hknight = self.wave_7_hknight;
		self.curr_wave_ogre = self.wave_7_ogre;
		self.curr_wave_shambler = self.wave_7_shambler;
		self.curr_wave_shalrath = self.wave_7_shalrath;
		self.curr_wave_tarbaby = self.wave_7_tarbaby;
		self.curr_wave_wizard = self.wave_7_wizard;
		self.curr_wave_zombie = self.wave_7_zombie;

		break;
	case 8:
		self.curr_wave_army = self.wave_8_army;
		self.curr_wave_demon1 = self.wave_8_demon1;
		self.curr_wave_dog = self.wave_8_dog;
		self.curr_wave_enforcer = self.wave_8_enforcer;
		self.curr_wave_fish = self.wave_8_fish;
		self.curr_wave_knight = self.wave_8_knight;
		self.curr_wave_hknight = self.wave_8_hknight;
		self.curr_wave_ogre = self.wave_8_ogre;
		self.curr_wave_shambler = self.wave_8_shambler;
		self.curr_wave_shalrath = self.wave_8_shalrath;
		self.curr_wave_tarbaby = self.wave_8_tarbaby;
		self.curr_wave_wizard = self.wave_8_wizard;
		self.curr_wave_zombie = self.wave_8_zombie;

		break;
	case 9:
		self.curr_wave_army = self.wave_9_army;
		self.curr_wave_demon1 = self.wave_9_demon1;
		self.curr_wave_dog = self.wave_9_dog;
		self.curr_wave_enforcer = self.wave_9_enforcer;
		self.curr_wave_fish = self.wave_9_fish;
		self.curr_wave_knight = self.wave_9_knight;
		self.curr_wave_hknight = self.wave_9_hknight;
		self.curr_wave_ogre = self.wave_9_ogre;
		self.curr_wave_shambler = self.wave_9_shambler;
		self.curr_wave_shalrath = self.wave_9_shalrath;
		self.curr_wave_tarbaby = self.wave_9_tarbaby;
		self.curr_wave_wizard = self.wave_9_wizard;
		self.curr_wave_zombie = self.wave_9_zombie;

		break;
	default:
		// No-op
		break;
	}
}
