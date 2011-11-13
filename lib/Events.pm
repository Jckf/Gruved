#!/dev/null
package Events;

use strict;
use warnings;

sub new {
	my ($class) = @_;
	my $self = { 'events' => [] };
	bless($self,$class);
}

sub bind {
	push(@{$_[0]->{'events'}->[$_[1]]},$_[2]) - 1;
}

sub trigger {
	my ($self,$event,@data) = @_;

	if (defined $self->{'events'}->[$event]) {
		my $e = { 'cancelled' => 0 };
		&{$_}($e,@data) for (reverse @{$self->{'events'}->[$event]});
		return $e;
	}
}

1;
