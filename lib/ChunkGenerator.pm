#!/dev/null
package ChunkGenerator;

use strict;
use warnings;
use Chunk;
use Block;

sub new {
	my ($class) = @_;
	my $self = {};

	$self->{'layers'} = [
		7, # Bedrock.
		1, # Stone.
		1, # Stone.
		3, # Dirt.
		3, # Dirt.
		2  # Grass.
	];

	bless($self,$class);
}

sub generate {
	if (!defined($_[0]->{'cache'})) {
		$::log->cyan('Generating cache chunk...');

		my $chunk = Chunk->new();
		foreach my $x (0 .. 15) {
			foreach my $z (0 .. 15) {
				foreach my $y (0 .. @{$_[0]->{'layers'}}) {
					$chunk->set_block($x,$y,$z,Block->new($_[0]->{'layers'}->[$y]));
				}
			}
		}
		$_[0]->{'cache'} = $chunk;
	}

	return $_[0]->{'cache'};
}

1;
