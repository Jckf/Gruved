#!/dev/null
package Chunk;

use strict;
use warnings;
use Compress::Zlib;
use Block;

sub new {
	my ($class) = @_;
	my $self = {};

	$self->{'modified'} = 0;

	my $n = 16 * 16 * 128; # TODO: World height.

	$self->{'types'} = "\0" x $n;
	$self->{'data'} = "\0" x ($n / 2);
	$self->{'blocklight'} = chr(0xF) x ($n / 2);
	$self->{'skylight'} = chr(0xF) x ($n / 2);

	bless($self,$class);
}

sub set_block {
	my ($self,$x,$y,$z,$b) = @_;

	if ($x > 15 || $z > 15 || $y > 127 || $x < 0 || $z < 0 || $y < 0) {
		$::log->red('Invalid block placement! (' . $x . ',' . $y . ',' . $z . ')');
		return 0;
	}

	my $i = $y + ($z * 128) + ($x * 128 * 16); # TODO: World height.

	$self->{'modified'} = 1;

	vec($self->{'types'     },$i,8) = $b->[Block::TYPE];
	vec($self->{'data'      },$i,4) = $b->[Block::DATA];
	vec($self->{'blocklight'},$i,4) = $b->[Block::BLOCKLIGHT];
	vec($self->{'skylight'  },$i,4) = $b->[Block::SKYLIGHT];

	return 1;
}

sub get_block {
	my ($self,$x,$y,$z) = @_;

	my $i = $y + ($z * 128) + ($x * 128 * 16); # TODO: World height.

	return Block->new(
		vec($self->{'types'     },$i,8),
		vec($self->{'data'      },$i,4),
		vec($self->{'blocklight'},$i,4),
		vec($self->{'skylight'  },$i,4)
	);
}

sub deflate {
	my ($self) = @_;

	my $z = deflateInit(-Level => Z_NO_COMPRESSION);

	return $z->deflate(
		$self->{'types'} .
		$self->{'data'} .
		$self->{'blocklight'} .
		$self->{'skylight'}
	) . $z->flush();
}

1;
