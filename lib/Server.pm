#!/dev/null
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

	$self->{'packets'} = 0;
	$self->{'pps'} = 0;

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
		splice(@{$self->{'players'}},fileno($ref),1);
	}
}

sub add_entity {
	my ($self,$ent) = @_;

	$ent->{'id'} = length(@{$self->{'entities'}});
	$self->{'entities'}->[$ent->{'id'}] = $ent;
}

sub remove_entity {
	splice(@{$_[0]->{'entities'}},$_[1],1);
}

sub broadcast {
	my ($self,$msg) = @_;

	$::log->white($msg);

	foreach my $p ($self->get_players()) {
		$p->message($msg);
	}
}

1;
