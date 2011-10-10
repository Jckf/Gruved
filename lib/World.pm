#!/dev/null
package World;

use strict;
use warnings;
use Time::HiRes 'time';
use ChunkGenerator;

sub new {
	my ($class,%options) = @_;
	my $self = {};

	$self->{'chunks'} = {};
	$self->{'generator'} = ChunkGenerator->new();

	$self->{$_} = $options{$_} for keys %options;

	bless($self,$class);
}

sub load_chunk {
	# We don't know how to do this =(
}

sub save_chunk {
	# We don't know how to do this =(
}

sub unload_chunk {
	my ($self,$x,$z) = @_;

	return 0 if !defined($self->{'chunks'}->{$x . ',' . $z});

	if ($self->{'chunks'}->{$x . ',' . $z}->{'modified'}) {
		$self->save_chunk($x,$z);
	}

	delete($self->{'chunks'}->{$x . ',' . $z});

	return 1;
}

sub get_chunk {
	my ($self,$x,$z) = @_;

	if (!defined($self->{'chunks'}->{$x . ',' . $z})) {
		if (0) { # TODO: Check if it exists on disk here. If it does, we should load it.
			$self->load_chunk($x,$z);
		} else {
			$self->{'chunks'}->{$x . ',' . $z} = $self->{'generator'}->generate($x,$z);
		}
	}

	return $self->{'chunks'}->{$x . ',' . $z};
}

1;
