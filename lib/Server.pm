#!/dev/null

# TODO: Move players and entities to World.

package Server;

use strict;
use warnings;

sub new {
	my ($class) = @_;
	my $self = {};

	$self->{'description'} = 'A Minecraft server';
	$self->{'max_players'} = 32;
	$self->{'view_distance'} = 10;

	$self->{'time'} = 0;

	$self->{'players'} = [];
	$self->{'entities'} = [];

	bless($self,$class);
}

sub add_player {
	$_[0]->{'players'}->[fileno($_[1]->{'socket'})] = $_[1];
}

sub get_player {
	my ($self,$ref) = @_;

	if (ref($ref) eq 'IO::Socket::INET') {
		return $self->{'players'}->[fileno($ref)];
	}
}

sub get_players {
	my ($self,$runlevel) = @_;
	$runlevel = 2 if !defined $runlevel;

	my @result;
	foreach my $p (@{$self->{'players'}}) {
		if (defined $p && $p->{'runlevel'} >= $runlevel) {
			push(@result,$p);
		}
	}

	return @result;
}

sub remove_player {
	my ($self,$ref) = @_;

	if (ref($ref) eq 'IO::Socket::INET') {
		$self->remove_entity($self->{'players'}->[fileno($ref)]->{'entity'}->{'id'}) if defined $self->{'players'}->[fileno($ref)]->{'entity'};
		$self->{'players'}->[fileno($ref)] = undef;
	}
}

sub add_entity {
	my ($self,$ent) = @_;

	my $test = @{$self->{'entities'}};
	$test++ while (!$test || defined($self->{'entities'}->[$test]));

	$ent->{'id'} = $test;

	$self->{'entities'}->[$ent->{'id'}] = $ent;
}

sub remove_entity {
	$_[0]->{'entities'}->[$_[1]] = undef;
}

sub broadcast {
	my ($self,$msg) = @_;

	foreach my $p ($self->get_players()) {
		$p->message($msg);
	}
}

1;
