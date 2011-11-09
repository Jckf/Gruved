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
	$self->{'blocks'} = [];

	bless($self,$class);
}

#  index = y + (z * (Size_Y+1)) + (x * (Size_Y+1) * (Size_Z+1))

sub set_block {
	$_[0]->{'modified'} = 1;
	$_[0]->{'blocks'}->[$_[2] + ($_[3] * 128) + ($_[1] * 128 * 16)] = $_[4];
}

sub get_block {
	$_[0]->{'blocks'}->[$_[2] + ($_[3] * 128) + ($_[1] * 128 * 16)] || [0];
}

sub deflate {
	my ($self) = @_;

	my $blocks = 16 * 16 * 128;
	my $types = '';
	my $data = "\0" x ($blocks / 2);
	my $light = chr(0xFF) x $blocks;

	$types = pack 'C*', map { $_ ? $_->[0] : 0 } @{$self->{blocks}};

	my $z = deflateInit(-Level => Z_BEST_SPEED);
	return $z->deflate($types . $data . $light) . $z->flush();
}

1;
