#!/dev/null
package Block;

use strict;
use warnings;

BEGIN {%Block::members=(
	'TYPE' => 0,    #Members
	'DATA' => 1,
	'BLOCKLIGHT' => 2,
	'SKYLIGHT' => 3,
	'SOLID' => 4
	);
	%Block::directions=(
	'NORTH' => 1,   #'NESW' are bitwise combinable
	'EAST' => 2,
	'SOUTH' => 4,
	'WEST' => 8,
	'N_EAST' => 3,  #2-part directions are made of bitwise 'OR' of NESW
	'S_EAST' => 6,
	'S_WEST' => 12,
	'N_WEST' => 9,
	'NN_EAST' => 5, #3-part directions are arbitrary
	'NE_EAST' => 7,
	'SE_EAST' => 10,
	'SS_EAST' => 11,
	'SS_WEST' => 13,
	'SW_WEST' => 14,
	'NW_WEST' => 15,
	'NN_WEST' => 16,
	
	'UP' => 32,     #Flags
	'WALL' => 32
	);
	%Block::blocks=(
	'AIR' => 0,     #Blocks
	'STONE' => 1,
	'GRASS' => 2,
	'DIRT' => 3,
	'COBBLE' => 4,
	'COBBLESTONE' => 4,
	'PLANK' => 5,
	'SAPLING' => 6,
	'BEDROCK' => 7,
	'WATER' => 8,
	'STILL_WATER' => 9,
	'LAVA' => 10,
	'STILL_LAVA' => 11,
	'SAND' => 12,
	'GRAVEL' => 13,
	
	'GOLD_ORE' => 14,
	'IRON_ORE' => 15,
	'COAL_ORE' => 16,
	'WOOD' => 17,
	'LOG' => 17,
	'LEAVES' => 18,
	'SPONGE' => 19,
	'GLASS' => 20,
	'LAPIS_LAZULI_ORE' => 21,
	'LAPIS_LAZULI' => 22,
	
	'DISPENSER' => 23,
	'SANDSTONE' => 24,
	'NOTE_BLOCK' => 25,
	'BED' => 26,
	'DETECTOR_RAIL' => 27,
	'POWER_RAIL' => 28,
	'STICKY_PISTON' => 29,
	'COBWEB' => 30,
	'TALL_GRASS' => 31,
	'DEAD_BUSH' => 32,
	'PISTON' => 33,
	'PISTON_HEAD' => 34,
	'WOOL' => 35,
	'BLOCK_MOVED_BY_PISTON' => 36,
	'DANDELION' => 37,
	'ROSE' => 38,
	'BROWN_MUSHROOM' => 39,
	'RED_MUSHROOM' => 40,
	'GOLD' => 41,
	'IRON' => 42,
	'DOUBLE_SLAB' => 43,
	'SLAB' => 44,
	'BRICK' => 45,
	'TNT' => 46,
	'BOOKSHELF' => 47,
	'MOSSY_COBBLE' => 48,
	'OBSIDIAN' => 49,
	'TORCH' => 50,
	'FIRE' => 51,
	'SPAWNER' => 52,
	'WOODEN_STAIRS' => 53,
	'CHEST' => 54,
	'REDSTONE' => 55,
	'DIAMOND_ORE' => 56,
	'DIAMOND' => 57,
	'CRAFTING_TABLE' => 58,
	'WHEAT' => 59,
	'FARMLAND' => 60,
	'FURNACE' => 61,
	'FURNACE_ON' => 62,
	'SIGN' => 63,
	'WOODEN_DOOR' => 64,
	'LADDER' => 65,
	'RAIL' => 66,
	'COBBLE_STAIRS' => 67,
	'WALL_SIGN' => 68,
	'LEVER' => 69,
	'STONE_PLATE' => 70,
	'IRON_DOOR' => 71,
	'WOODEN_PLATE' => 72,
	'REDSTONE_ORE' => 73,
	'REDSTONE_ORE_ON' => 74,
	'RS_TORCH_OFF' => 75,
	'RS_TORCH_ON' => 76,
	'BUTTON' => 77,
	'SNOW' => 78,
	'ICE' => 79,
	'SNOW_BLOCK' => 80,
	'CACTUS' => 81,
	'CLAY' => 82,
	'SUGAR_CANE' => 83,
	'JUKEBOX' => 84,
	'FENCE' => 85,
	'PUMPKIN' => 86,
	'NETHERRACK' => 87,
	'SOUL_SAND' => 88,
	'GLOWSTONE' => 89,
	'PORTAL' => 90,
	'JACK_O_LANTERN' => 91,
	'CAKE' => 92,
	'REPEATER' => 93,
	'REPEATER_ON' => 94,
	'LOCKED_CHEST' => 95,
	'TRAPDOOR' => 96,
	'SILVERFISH' => 97,
	'STONEBRICK' => 98,
	'HUGE_BROWN_MUSHROOM' => 99,
	'HUGE_RED_MUSHROOM' => 100,
	'IRON_BARS' => 101,
	'GLASS_PANE' => 102,
	'MELON' => 103,
	'PUMPKIN_STEM' => 104,
	'MELON_STEM' => 105,
	'VINE' => 106,
	'FENCE_GATE' => 107,
	'BRICK_STAIRS' => 108,
	'STONEBRICK_STAIRS' => 109,
	'MYCELIUM' => 110,
	'LILY_PAD' => 111,
	'NETHERBRICK' => 112,
	'NETHERBRICK_FENCE' => 113,
	'NETHERBRICK_STAIRS' => 114,
	'NETHER_WART' => 115,
	'ENCHANTMENT_TABLE' => 116,
	'BREWING_STAND' => 117,
	'CAULDRON' => 118,
	'END_PORTAL' => 119,
	'END_PORTAL_FRAME' => 120,
	'END_STONE' => 121,
	'DRAGON_EGG' => 122
);
};

use Const::Fast;

BEGIN {
	no strict 'refs'; #FOR GOOD REASON!
	#Note! String references *are* faster than eval ""
	#I had to replace use constant with Const::Fast since
	#in a lot of places, barewords are interpolated as strings.
	#Jckf, please don't revert this. $AIR can peacefully coexist with AIR, if you want to
	#leave both in.
	foreach (keys %Block::members) {
		const ${"Block::$_"} => $Block::members{$_};
		#eval "const \$Block::$_ => \$Block::members{$_}";
	}
	foreach (keys %Block::directions) {
		const ${"Block::$_"} => $Block::directions{$_};
		#eval "const \$Block::$_ => \$Block::directions{$_}";
	}
	foreach (keys %Block::blocks) {
		const ${"Block::$_"} => $Block::blocks{$_};
		#eval "const \$Block::$_ => \$Block::blocks{$_}";
	}
}

package Block;

#Phase these out of the other packages, replacing with $CONSTANTS
use constant \%Block::members;
use constant \%Block::directions;
use constant \%Block::blocks;

no strict 'vars'; #"Not imported"

my $solids = {
	$AIR => 0,     #Blocks
	$STONE => 1,
	$GRASS => 1,
	$DIRT => 1,
	$COBBLESTONE => 1,
	$PLANK => 1,
	$SAPLING => 0,
	$BEDROCK => 1,
	$WATER => 0,
	$STILL_WATER => 0,
	$LAVA => 0,
	$STILL_LAVA => 0,
	$SAND => 1,
	$GRAVEL => 1,
	
	$GOLD_ORE => 1,
	$IRON_ORE => 1,
	$COAL_ORE => 1,
	$WOOD => 1,
	$LOG => 1,
	$LEAVES => 1,
	$SPONGE => 1,
	$GLASS => 1,
	$LAPIS_LAZULI_ORE => 1,
	$LAPIS_LAZULI => 1,
	
	$DISPENSER => 1,
	$SANDSTONE => 1,
	$NOTE_BLOCK => 1,
	$BED => 0,
	$DETECTOR_RAIL => 0,
	$POWER_RAIL => 0,
	$STICKY_PISTON => 1,
	$COBWEB => 0,
	$TALL_GRASS => 0,
	$DEAD_BUSH => 0,
	$PISTON => 1,
	$PISTON_HEAD => 0,
	$WOOL => 1,
	$BLOCK_MOVED_BY_PISTON => 0,
	$DANDELION => 0,
	$ROSE => 0,
	$BROWN_MUSHROOM => 0,
	$RED_MUSHROOM => 0,
	$GOLD => 1,
	$IRON => 1,
	$DOUBLE_SLAB => 1,
	$SLAB => 0,
	$BRICK => 1,
	$TNT => 1,
	$BOOKSHELF => 1,
	$MOSSY_COBBLE => 1,
	$OBSIDIAN => 1,
	$TORCH => 0,
	$FIRE => 0,
	$SPAWNER => 1,
	$WOODEN_STAIRS => 0,
	$CHEST => 1,
	$REDSTONE => 0,
	$DIAMOND_ORE => 1,
	$DIAMOND => 1,
	$CRAFTING_TABLE => 1,
	$WHEAT => 0,
	$FARMLAND => 0,  #Farmland is 1px smaller than other blocks
	$FURNACE => 1,
	$FURNACE_ON => 1,
	$SIGN => 0,
	$WOODEN_DOOR => 0,
	$LADDER => 0,
	$RAIL => 0,
	$COBBLE_STAIRS => 0,
	$WALL_SIGN => 0,
	$LEVER => 0,
	$STONE_PLATE => 0,
	$IRON_DOOR => 0,
	$WOODEN_PLATE => 0,
	$REDSTONE_ORE => 1,
	$REDSTONE_ORE_ON => 1,
	$RS_TORCH_OFF => 0,
	$RS_TORCH_ON => 0,
	$BUTTON => 0,
	$SNOW => 0,
	$ICE => 1,
	$SNOW_BLOCK => 1,
	$CACTUS => 1,
	$CLAY => 1,
	$SUGAR_CANE => 0,
	$JUKEBOX => 1,
	$FENCE => 0, #Fences are thinner than normal blocks
	$PUMPKIN => 1,
	$NETHERRACK => 1,
	$SOUL_SAND => 0, #Soul sand is smaller than normal blocks
	$GLOWSTONE => 1,
	$PORTAL => 0,
	$JACK_O_LANTERN => 1,
	$CAKE => 0,
	$REPEATER => 0,
	$REPEATER_ON => 0,
	$LOCKED_CHEST => 1,
	$TRAPDOOR => 0,
	$SILVERFISH => 1,
	$STONEBRICK => 1,
	$HUGE_BROWN_MUSHROOM => 1,
	$HUGE_RED_MUSHROOM => 1,
	$IRON_BARS => 0,
	$GLASS_PANE => 0,
	$MELON => 1,
	$PUMPKIN_STEM => 0,
	$MELON_STEM => 0,
	$VINE => 0,
	$FENCE_GATE => 0,
	$BRICK_STAIRS => 0,
	$STONEBRICK_STAIRS => 0,
	$MYCELIUM => 1,
	$LILY_PAD => 0,
	$NETHERBRICK => 1,
	$NETHERBRICK_FENCE => 0,
	$NETHERBRICK_STAIRS => 0,
	$NETHER_WART => 0,
	$ENCHANTMENT_TABLE => 0,
	$BREWING_STAND => 0,
	$CAULDRON => 1,
	$END_PORTAL => 0,
	$END_PORTAL_FRAME => 1,
	$END_STONE => 1,
	$DRAGON_EGG => 0
};

sub new {
	my ($class,$type,$data,$blocklight,$skylight) = @_;

	my $self = [
		defined $type       ? $type       : $AIR,
		defined $data       ? $data       : 0,
		defined $blocklight ? $blocklight : 0x0,
		defined $skylight   ? $skylight   : 0x0,
		0
	];

	$self->[$SOLID] = 1 if defined $solids->{$self->[$TYPE]};

	bless($self,$class);
}

#Standardization:
#
# Levers, torches etc: the direction they're facing, not the block face
#
# Stairs, ascending rails etc: the direction that is up
#
# For reverse conversion of straight stuff, North & East take precedence

our @d_orient;
our @s_orient;

$d_orient[$BUTTON]=$d_orient[$TORCH]=$d_orient[$RS_TORCH_OFF]=$d_orient[$RS_TORCH_ON]={
	$EAST  => 0x1,
	$WEST  => 0x2,
	$SOUTH => 0x3,
	$NORTH => 0x4,
	0     => 0x5,
	-$UP => 1 #If 1, removes UP bit from direction
};

$d_orient[$RAIL]={
	$NORTH => 0x0,
	$WEST  => 0x1,
	$UP | $EAST  => 0x2,
	$UP | $WEST  => 0x3,
	$UP | $NORTH => 0x4,
	$UP | $SOUTH => 0x5,
	$S_EAST => 0x6,
	$S_WEST => 0x7,
	$N_WEST => 0x8,
	$N_EAST => 0x9
};

$d_orient[$LADDER]={
	$SOUTH => 0x2,
	$NORTH => 0x3,
	$EAST  => 0x4,
	$WEST  => 0x5,
	-$UP => 1
};

$d_orient[$WOODEN_STAIRS] = $d_orient[$COBBLE_STAIRS] = $d_orient[$BRICK_STAIRS] = $d_orient[$STONEBRICK_STAIRS] = $d_orient[$NETHERBRICK_STAIRS] = {
	$EAST  => 0x0,
	$WEST  => 0x1,
	$SOUTH => 0x2,
	$NORTH => 0x3,
	-$UP => 1
};

$d_orient[$LEVER] = {
	$WALL | $EAST  => 0x1,
	$WALL | $WEST  => 0x2,
	$WALL | $SOUTH => 0x3,
	$WALL | $NORTH => 0x4,
	$NORTH => 0x5,
	$EAST  => 0x6
};

$d_orient[$WOODEN_DOOR] = $d_orient[$IRON_DOOR] = {
	$N_WEST => 0x0,
	$N_EAST => 0x1,
	$S_EAST => 0x2,
	$S_WEST => 0x3,
	$UP | $N_WEST => 0x8,
	$UP | $N_EAST => 0x9,
	$UP | $S_EAST => 0x10,
	$UP | $S_WEST => 0x11
};

$d_orient[$SIGN] = {
	$SOUTH   => 0x0,
	$SS_WEST => 0x1,
	$S_WEST  => 0x2,
	$SW_WEST => 0x3,
	$WEST    => 0x4,
	$NW_WEST => 0x5,
	$N_WEST  => 0x6,
	$NN_WEST => 0x7,
	$NORTH   => 0x8,
	$NN_EAST => 0x9,
	$N_EAST  => 0xA,
	$NE_EAST => 0xB,
	$EAST    => 0xC,
	$SE_EAST => 0xD,
	$S_EAST  => 0xE,
	$SS_EAST => 0xF,
	-$UP => 1
};

$d_orient[$WALL_SIGN] = $d_orient[$FURNACE] = $d_orient[$FURNACE_ON] = $d_orient[$CHEST] = $d_orient[$DISPENSER] = {
	$NORTH => 0x2,
	$SOUTH => 0x3,
	$WEST  => 0x4,
	$EAST  => 0x5,
	-$UP => 1
};

$d_orient[$PUMPKIN] = $d_orient[$JACK_O_LANTERN] = {
	$SOUTH => 0x0,
	$WEST  => 0x1,
	$NORTH => 0x2,
	$EAST  => 0x3,
	-$UP => 1
};

$d_orient[$REPEATER] = $d_orient[$REPEATER_ON] = {
	$NORTH => 0x0,
	$EAST  => 0x1,
	$SOUTH => 0x2,
	$WEST  => 0x3,
	-$UP => 1
};

$d_orient[$TRAPDOOR] = {
	$SOUTH => 0x0,
	$NORTH => 0x1,
	$EAST  => 0x2,
	$WEST  => 0x3,
	-$UP => 1
};

$d_orient[$PISTON] = $d_orient[$STICKY_PISTON] = $d_orient[$PISTON_HEAD] = {
	0     => 0x0,
	$UP    => 0x1,
	$NORTH => 0x2,
	$SOUTH => 0x3,
	$WEST  => 0x4,
	$EAST  => 0x5
};

$d_orient[$VINE] = {
	$UP    => 0x0,
	$SOUTH => 0x1,
	$WEST  => 0x2,
	$NORTH => 0x4,
	$EAST  => 0x8,
	'bitwise' => [$SOUTH,$WEST,$NORTH,$EAST] #Those are bitwise-combining flags
};

$d_orient[$FENCE_GATE] = {
	$SOUTH => 0x0,
	$WEST  => 0x1,
	$NORTH => 0x2,
	$EAST  => 0x3
};

sub set_orientation {
	my ($self,$data1,$data2)=@_;
	if (ref($data1) eq 'Player') { #Smart orientation :)
		#TODO
	}else{ #Simple orientation
		if ($d_orient[$self->[$TYPE]]) {
			$data1^=$UP if $d_orient[$self->[$TYPE]]->{-$UP};
			if ($d_orient[$self->[$TYPE]]->{'bitwise'}) { #Bitwise flags like vines
				my $dr=0;
				foreach (@{$d_orient[$self->[$TYPE]]->{'bitwise'}}) {
					if ($data1 & $_) {
						$dr|=$d_orient[$self->[$TYPE]]->{$_};
					}
				}
				$self->[$DATA]=$dr;
			}else{
				$self->[$DATA]=$d_orient[$self->[$TYPE]]->{$data1} || 0x0;
			}
		}else{
			$self->[$DATA]=0x0;
		}
	}
}

1;
