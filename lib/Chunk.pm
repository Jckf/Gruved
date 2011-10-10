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

sub set_block {
	$_[0]->{'modified'} = 1;
	$_[0]->{'blocks'}->[$_[2] + ($_[1] * 128) + ($_[3] * 128 * 16)] = $_[4];
}

sub get_block {
	$_[0]->{'blocks'}->[$_[2] + ($_[1] * 128) + ($_[3] * 128 * 16)] || Block->new();
}

sub deflate {
	my ($self) = @_;

	my ($types,$data,$light,$skylight) = ('','','','');

	foreach my $i (0 .. (16 * 16 * 128) - 1) {
		my $block = $self->{'blocks'}->[$i] || Block->new();

		$types .= chr($block->{'type'});
		$data .= chr($block->{'data'});
		$light .= substr(unpack('H*',chr($block->{'light'})),1);
		$skylight .= substr(unpack('H*',chr($block->{'skylight'})),1);
	}

	my $z = deflateInit();
	return $z->deflate($types . $data . pack('H*','0x' . $light) . pack('H*','0x' . $skylight)) . $z->flush();
}

1;
