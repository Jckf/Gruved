#!/dev/null
use strict;
use warnings;

package Minecraft::Server::Events;

sub new {
	my ($class) = @_;
	my $self = { 'events' => {} };
	bless($self,$class);
}

sub bind {
	my ($self,$event,$handler) = @_;
	return push(@{$self->{'events'}->{$event}},$handler) - 1;
}

sub trigger {
	my ($self,$event,@data) = @_;

	if (defined $self->{'events'}->{$event}) {
		my @returns;
		push(@returns,&{$_}(@data)) for @{$self->{'events'}->{$event}};
		return @returns;
	}

	return 0;
}

1;
