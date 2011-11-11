#!/dev/null
package Eventss;

use strict;
use warnings;

sub new {
	my ($class) = @_;
	my $self = { 'events' => {} };
	bless($self,$class);
}

sub bind {
	push(@{$_[0]->{'events'}->{$_[1]}},$_[2]) - 1;
}

sub trigger {
	my ($self,$event,@data) = @_;

	if (defined $self->{'events'}->{$event}) {
		my $e = { 'cancelled' => 0 };
		foreach (reverse @{$self->{'events'}->[$event]}) {
			&{$_}($e,@data) ;
			last if $e->{'cancelled'};
		}
		return $e;
	}
}

1;
