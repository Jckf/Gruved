#!/dev/null
package ChunkGenerator;

use strict;
use warnings;
use Chunk;
use Block;

sub new {
	my ($class) = @_;
	my $self = {};

	$self->{'layers'} = {
		1 => 7, # Bedrock.
		2 => 1, # Stone.
		3 => 1, # Stone.
		4 => 1, # Stone.
		5 => 3, # Dirt.
		6 => 3, # Dirt.
		7 => 3, # Dirt.
		8 => 3, # Dirt.
		9 => 3, # Dirt.
		10 => 2 # Grass.
	};

	bless($self,$class);
}

sub generate {
	my $chunk = Chunk->new();
	foreach my $x (0 .. 16) {
		foreach my $z (0 .. 16) {
			foreach my $y (keys %{$_[0]->{'layers'}}) {
				$chunk->set_block($x,$y,$z,Block->new('type' => $_[0]->{'layers'}->{$y}));
			}
		}
	}
	return $chunk;
}

1;
