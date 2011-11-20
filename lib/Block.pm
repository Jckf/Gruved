#!/dev/null
package Block;

use strict;
use warnings;

use constant {
	TYPE => 0,    #Members
	DATA => 1,
	BLOCKLIGHT => 2,
	SKYLIGHT => 3,
	SOLID => 4,
	
	NORTH => 1,   #NESW are bitwise combinable
	EAST => 2,
	SOUTH => 4,
	WEST => 8,
	N_EAST => 3,  #2-part directions are made of bitwise OR of NESW
	S_EAST => 6,
	S_WEST => 12,
	N_WEST => 9,
	NN_EAST => 5, #3-part directions are arbitrary
	NE_EAST => 7
	SE_EAST => 10,
	SS_EAST => 11,
	SS_WEST => 13,
	SW_WEST => 14,
	NW_WEST => 15,
	NN_WEST => 16,
	
	UP => 32,     #Flags
	WALL => 32,

	AIR => 0,     #Blocks
	STONE => 1,
	GRASS => 2,
	DIRT => 3,
	BEDROCK => 7,
	TORCH => 50,
	
	RS_TORCH_OFF => 75
	RS_TORCH_ON => 76,
	LEVER => 69,
	BUTTON => 77,
	REPEATER => 93,
	REPEATER_ON => 94,
	
	RAIL => 66,
	DETECTOR_RAIL => 27,
	POWER_RAIL => 28,
	
	LADDER => 65,
	
	WOODEN_STAIRS => 53,
	COBBLE_STAIRS => 67,
	BRICK_STAIRS => 108,
	STONEBRICK_STAIRS => 109,
	HELLBRICK_STAIRS => 114,
	
	WOODEN_DOOR => 64,
	IRON_DOOR => 71,
	
	SIGN => 63,
	WALL_SIGN => 68,
	
	FURNACE => 61,
	FURNACE_ON => 62,
	
	DISPENSER => 23,
	
	CHEST => 54,
	
	PUMPKIN => 86,
	JACK_O_LANTERN => 91,
	
	TRAPDOOR => 96,
	
	PISTON => 33,
	STICKY_PISTON => 29,
	PISTON_HEAD => 34,
	
	HUGE_BROWN_SHROOM => 99,
	HUGE_RED_SHROOM => 100,
	
	VINE => 106,
	
	FENCE_GATE => 107
};

my $solids = {
	STONE => 1,
	GRASS => 1,
	DIRT => 1,
	BEDROCK => 1
};

sub new {
	my ($class,$type,$data,$blocklight,$skylight) = @_;

	my $self = [
		defined $type       ? $type       : AIR,
		defined $data       ? $data       : 0,
		defined $blocklight ? $blocklight : 0x0,
		defined $skylight   ? $skylight   : 0x0,
		0
	];

	$self->[SOLID] = 1 if defined $solids->{$self->[TYPE]};

	bless($self,$class);
}

#Standardization:
#
# Levers, torches etc: the direction they're facing, not the block face
#
# Stairs, ascending rails etc: the direction that is up
#
# For reverse conversion of straight stuff, North & East take precedence

my @d_orient;
my @s_orient;

$d_orient[BUTTON]=$d_orient[TORCH]=$d_orient[RS_TORCH_OFF]=$d_orient[RS_TORCH_ON]={
	EAST  => 0x1,
	WEST  => 0x2,
	SOUTH => 0x3,
	NORTH => 0x4,
	0     => 0x5,
	-UP => 1 #If 1, removes UP bit from direction
};

$d_orient[RAIL]={
	NORTH => 0x0,
	WEST  => 0x1,
	UP | EAST  => 0x2,
	UP | WEST  => 0x3,
	UP | NORTH => 0x4,
	UP | SOUTH => 0x5,
	S_EAST => 0x6,
	S_WEST => 0x7,
	N_WEST => 0x8,
	N_EAST => 0x9
};

$d_orient[LADDER]={
	SOUTH => 0x2,
	NORTH => 0x3,
	EAST  => 0x4,
	WEST  => 0x5,
	-UP => 1
};

$d_orient[WOODEN_STAIRS] = $d_orient[COBBLE_STAIRS] = $d_orient[BRICK_STAIRS] = $d_orient[STONEBRICK_STAIRS] = $d_orient[HELLBRICK_STAIRS] = {
	EAST  => 0x0,
	WEST  => 0x1,
	SOUTH => 0x2,
	NORTH => 0x3,
	-UP => 1
};

$d_orient[LEVER] = {
	WALL | EAST  => 0x1,
	WALL | WEST  => 0x2,
	WALL | SOUTH => 0x3,
	WALL | NORTH => 0x4,
	NORTH => 0x5,
	EAST  => 0x6
};

$d_orient[WOODEN_DOOR] = $d_orient[IRON_DOOR] = {
	N_WEST => 0x0,
	N_EAST => 0x1,
	S_EAST => 0x2,
	S_WEST => 0x3,
	UP | N_WEST => 0x8,
	UP | N_EAST => 0x9,
	UP | S_EAST => 0x10,
	UP | S_WEST => 0x11
};

$d_orient[SIGN] = {
	SOUTH   => 0x0,
	SS_WEST => 0x1,
	S_WEST  => 0x2,
	SW_WEST => 0x3,
	WEST    => 0x4,
	NW_WEST => 0x5,
	N_WEST  => 0x6,
	NN_WEST => 0x7,
	NORTH   => 0x8,
	NN_EAST => 0x9,
	N_EAST  => 0xA,
	NE_EAST => 0xB,
	EAST    => 0xC,
	SE_EAST => 0xD,
	S_EAST  => 0xE,
	SS_EAST => 0xF,
	-UP => 1
};

$d_orient[WALL_SIGN = $d_orient[FURNACE] = $d_orient[FURNACE_ON] = $d_orient[CHEST] = $d_orient[DISPENSER] = {
	NORTH => 0x2,
	SOUTH => 0x3,
	WEST  => 0x4,
	EAST  => 0x5,
	-UP => 1
};

$d_orient[PUMPKIN] = $d_orient[JACK_O_LANTERN] = {
	SOUTH => 0x0,
	WEST  => 0x1,
	NORTH => 0x2,
	EAST  => 0x3,
	-UP => 1
};

$d_orient[REPEATER] = $d_orient[REPEATER_ON] = {
	NORTH => 0x0,
	EAST  => 0x1,
	SOUTH => 0x2,
	WEST  => 0x3,
	-UP => 1
};

$d_orient[TRAPDOOR] = {
	SOUTH => 0x0,
	NORTH => 0x1,
	EAST  => 0x2,
	WEST  => 0x3,
	-UP => 1
};

$d_orient[PISTON] = $d_orient[STICKY_PISTON] = $d_orient[PISTON_HEAD] = {
	0     => 0x0,
	UP    => 0x1,
	NORTH => 0x2,
	SOUTH => 0x3,
	WEST  => 0x4,
	EAST  => 0x5
};

$d_orient[VINE] = {
	UP    => 0x0,
	SOUTH => 0x1,
	WEST  => 0x2,
	NORTH => 0x4,
	EAST  => 0x8,
	'bitwise' => [SOUTH,WEST,NORTH,EAST] #Those are bitwise-combining flags
};

$d_orient{FENCE_GATE} = {
	SOUTH => 0x0,
	WEST  => 0x1,
	NORTH => 0x2,
	EAST  => 0x3
};

sub set_orientation {
	my ($self,$data1,$data2)=@_;
	if (ref($data1) eq 'Player') { #Smart orientation :)
		#TODO
	}else{ #Simple orientation
		if ($d_orient[$self->[TYPE]]) {
			$data1^=UP if $d_orient[$self->[TYPE]]->{-UP};
			if ($d_orient[$self->[TYPE]]->{'bitwise'}) { #Bitwise flags like vines
				my $dr=0;
				foreach (@{$d_orient[$self->[TYPE]]->{'bitwise'}}) {
					if ($data1 & $_) {
						$dr|=$d_orient[$self->[TYPE]]->{$_};
					}
				}
				$self->[DATA]=$dr;
			}else{
				$self->[DATA]=$d_orient[$self->[TYPE]]->{$data1} || 0x0;
			}
		}else{
			$self->[DATA]=0x0;
		}
	}
}

1;
