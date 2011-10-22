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

	$self->{'height'} = 128;
	$self->{'seed'} = 0;

	$self->{$_} = $options{$_} for keys %options;

	bless($self,$class);
}

sub load_chunk {
	my ($self,$x,$z) = @_;

	return 0 if !$self->chunk_loaded($x,$z);

	# TODO: Something!
}

sub save_chunk {
	my ($self,$x,$z) = @_;

	return 0 if !$self->chunk_loaded($x,$z);

	# TODO: Something!
}

sub unload_chunk {
	my ($self,$x,$z) = @_;

	return 0 if !$self->chunk_loaded($x,$z);

	$self->save_chunk($x,$z) if $self->{'chunks'}->{$x . ',' . $z}->{'modified'};

	delete($self->{'chunks'}->{$x . ',' . $z});

	return 1;
}

sub chunk_loaded {
	defined($_[0]->{'chunks'}->{$_[1] . ',' . $_[2]});
}

sub get_chunk {
	my ($self,$x,$z) = @_;

	if (!$self->chunk_loaded($x,$z)) { # Is it in memory?
		if (0) { # Can we load it from disk?
			$self->load_chunk($x,$z);
		} else { # Generate it.
			$self->{'chunks'}->{$x . ',' . $z} = $self->{'generator'}->generate($x,$z);
		}
	}

	return $self->{'chunks'}->{$x . ',' . $z};
}

1;
