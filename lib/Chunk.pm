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
	$_[0]->{'blocks'}->[$_[2] + ($_[1] * 128) + ($_[3] * 128 * 16)] || { 'type' => 0 };#Block->new();
}

sub deflate {
	my ($self) = @_;

	my $blocks = 16 * 16 * 128;
	my $types = '';
	my $data = "\0" x ($blocks / 2);
	my $light = chr(0xFF) x $blocks;

	# Tybalt.
	$types = join('',map { defined($_) ? chr($_->{'type'}) : "\0" } values @{$self->{'blocks'}});

	# Jkeats.
	#my $offset = 0;
	#while ($offset < $blocks) {
	#	vec($types,$offset,8) = defined($self->{'blocks'}->[$offset]) ? $self->{'blocks'}->[$offset]->{'type'} : 0;
	#	$offset++
	#}

	# Jckf.
	#$types = chr(0) x $blocks;
	#foreach my $b (keys @{$self->{'blocks'}}) {
	#	if (defined $self->{'blocks'}->[$b]) {
	#		substr($types,$b,1,chr($self->{'blocks'}->[$b]->{'type'}));
	#	}
	#}

	my $z = deflateInit();
	return $z->deflate($types . $data . $light) . $z->flush();
}

1;
