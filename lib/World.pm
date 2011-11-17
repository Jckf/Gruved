#!/dev/null
package World;

use strict;
use warnings;
use Time::HiRes 'time';
use Storable qw(nstore retrieve);
use Timer;
use SocketFactory;
use ChunkGenerator;

sub new {
	my ($class,%options) = @_;
	my $self = {};

	$self->{'timer'} = Timer->new(30,int rand(30));
	$self->{'timer'}->bind(sub { $self->save() });
	$::tick->bind(sub { $self->{'timer'}->tick() });

	$self->{'chunks'} = {};
	$self->{'generator'} = ChunkGenerator->new();

	$self->{'name'}   = 'world';
	$self->{'height'} = 128;
	$self->{'seed'}   = 0;

	$self->{$_} = $options{$_} for keys %options;

	bless($self,$class);
}

sub save {
	my ($self) = @_;

	$self->save_chunk(split(',')) for (keys %{$self->{'chunks'}});
}

sub load_chunk {
	my ($self,$x,$z) = @_;

	return 0 if $self->chunk_loaded($x,$z) || !$self->chunk_exists($x,$z);

	$self->{'chunks'}->{$x . ',' . $z} = retrieve('worlds/' . $self->{'name'} . '/chunks/' . $x . ',' . $z) or return 0;

	return 1;
}

sub save_chunk {
	my ($self,$x,$z) = @_;

	return 0 if !$self->chunk_loaded($x,$z);

	my $chunk = $self->get_chunk($x,$z);

	return 0 if !$chunk->{'modified'};

	my $d = 'worlds/' . $self->{'name'} . '/chunks';
	mkdir $d if !-d $d;
	
	$chunk->{'modified'} = 0;
	
	nstore($chunk,$d . '/' . $x . ',' . $z) or do {
		$chunk->{'modified'} = 1;
		return 0;
	};

	return 1;
}

sub unload_chunk {
	my ($self,$x,$z) = @_;

	return 0 if !$self->chunk_loaded($x,$z);

	$self->save_chunk($x,$z) if $self->{'chunks'}->{$x . ',' . $z}->{'modified'};

	delete($self->{'chunks'}->{$x . ',' . $z});

	return 1;
}

sub delete_chunk {
	my ($self,$x,$z) = @_;

	my $f = 'worlds/' . $self->{'name'} . '/chunks/' . $x . ',' . $z;
	return 0 if !-e $f;
	return unlink $f;
}

sub chunk_loaded { defined($_[0]->{'chunks'}->{$_[1] . ',' . $_[2]}) }

sub chunk_exists { -e 'worlds/' . $_[0]->{'name'} . '/chunks/' . $_[1] . ',' . $_[2] }

sub get_chunk {
	my ($self,$x,$z) = @_;

	if (!$self->chunk_loaded($x,$z)) { # Do we have it?
		if (!$self->load_chunk($x,$z)) { # No. Can we load it?
			$self->{'chunks'}->{$x . ',' . $z} = $self->{'generator'}->generate($x,$z); # No. Generate it =)
		}
	}

	return $self->{'chunks'}->{$x . ',' . $z};
}

1;
