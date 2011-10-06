#!/dev/null
package Minecraft::Server;

use strict;
use warnings;

sub new {
	my ($class) = @_;
	my $self = {};

	$self->{'description'} = 'A Minecraft server.';
	$self->{'max_players'} = 32;

	$self->{'players'} = [];
	$self->{'sockmap'} = [];

	$self->{'entities'} = [];

	bless($self,$class);
}

sub add_player {
	my ($self,$p) = @_;
	push(@{$self->{'players'}},$p);
	$self->{'sockmap'}->[fileno($p->{'socket'})] = length(@{$self->{'players'}}) - 1;
}

sub get_player {
	my ($self,$ref) = @_;

	if (ref($ref) eq 'IO::Socket::INET') {
		return $self->{'players'}->[$self->{'sockmap'}->[fileno($ref)]];
	}
}

sub remove_player {
	my ($self,$ref) = @_;

	if (ref($ref) eq 'IO::Socket::INET') {
		splice(@{$self->{'players'}},$self->{'sockmap'}->[fileno($ref)],1);
		splice(@{$self->{'sockmap'}},fileno($ref),1);
	}
}

sub add_entity {
	my ($self,$ent) = @_;

	$ent->{'id'} = length(@{$self->{'entities'}});
	$self->{'entities'}->[$ent->{'id'}] = $ent;
}

1;
