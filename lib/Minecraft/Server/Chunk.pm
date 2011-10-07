#!/dev/null
package Minecraft::Server::Chunk;

use strict;
use warnings;
use Minecraft::Server::Block;
use Compress::Zlib;

sub new {
	my ($class) = @_;
	my $self = {};

	$self->{'blocks'} = [];

	bless($self,$class);
}

sub set_block {
	$_[0]->{'blocks'}->[$_[2] + ($_[1] * 128) + ($_[3] * 128 * 16)] = $_[4];
}

sub get_block {
	$_[0]->{'blocks'}->[$_[2] + ($_[1] * 128) + ($_[3] * 128 * 16)] || Minecraft::Server::Block->new();
}

sub deflate {
	my ($self) = @_;

	my ($types,$data,$light,$skylight) = ('','','','');

	foreach my $i (0 .. (16 * 16 * 128) - 1) {
		my $block = $self->{'blocks'}->[$i] || Minecraft::Server::Block->new();

		$types .= chr($block->{'type'});
		$data .= chr($block->{'data'});
		$light .= substr(unpack('H*',chr($block->{'light'})),1);
		$skylight .= substr(unpack('H*',chr($block->{'skylight'})),1);
	}

	my $z = deflateInit();
	return $z->deflate($types . $data . pack('H*','0x' . $light) . pack('H*','0x' . $skylight)) . $z->flush();
}

1;
