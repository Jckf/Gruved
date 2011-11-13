#!/dev/null
package Block;

use strict;
use warnings;

use constant {
	TYPE => 0,
	DATA => 1,
	BLOCKLIGHT => 2,
	SKYLIGHT => 3,
	SOLID => 4,

	STONE => 1,
	GRASS => 2,
	DIRT => 3,
	BEDROCK => 7
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
		defined $type	? $type : 0,
		defined $data	? $data : 0,
		defined $blocklight	? $blocklight	: 0xF,
		defined $skylight	? $skylight		: 0xF,
		0
	];

	$self->[SOLID] = $solids->{$self->[TYPE]};

	bless($self,$class);
}

1;
