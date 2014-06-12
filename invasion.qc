
/*
	Zombie stuff
*/
void() inv_spawn_think =
{
	// TODO, cleanup this code to support multiple enemy types in a cleaner way

	// Preserve oldself or this will die when monster dies
	entity oldself;
	oldself = self;
	self = spawn();
	self.classname = "monster_zombie";
	self.origin = oldself.origin;
	monster_zombie();

	self = oldself;

	self.nextthink = time + 5;
}

void() inv_spawn_zombie = 
{
	self.think = inv_spawn_think;
	self.nextthink = time + 2;
};

void() inv_think_dog
{
	entity oldself;
	oldself = self;
	self = spawn();
	self.classname = "monster_dog";
	self.origin = oldself.origin;
	monster_dog();

	self = oldself;

	self.nextthink = time + 3;
	
}

void() inv_spawn_dog =
{
	self.think = inv_think_dog;
	self.nextthink = time + 2;
}

void() inv_think_army
{
	entity oldself;
	oldself = self;
	self = spawn();
	self.classname = "monster_army";
	self.origin = oldself.origin;
	monster_army();

	self = oldself;

	self.nextthink = time + 3;
	
}

void() inv_spawn_army =
{
	self.think = inv_think_army;
	self.nextthink = time + 2;
}

void() inv_think_hknight
{
	entity oldself;
	oldself = self;
	self = spawn();
	self.classname = "monster_hell_knight";
	self.origin = oldself.origin;
	monster_hell_knight();

	self = oldself;

	self.nextthink = time + 3;
	
}

void() inv_spawn_hknight =
{
	self.think = inv_think_hknight;
	self.nextthink = time + 2;
}
