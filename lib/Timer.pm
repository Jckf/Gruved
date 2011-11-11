#!/dev/null
package Timer;

use Time::HiRes qw(time);
use strict;
use warnings;

sub new {
	my ($class,$interval,$offset) = @_;
	my $self = {};

	$self->{'interval'} = $interval || 1;
	$self->{'previous'} = time()+($offset ? $offset : 0);
	$self->{'callbacks'} = [];

	bless($self,$class);
}

sub bind {
	push(@{$_[0]->{'callbacks'}},$_[1]);
}

sub tick {
	my ($self) = @_;

	if (time() - $self->{'previous'} >= $self->{'interval'}) {
		$self->{'previous'} = time();
		&{$_}() for @{$self->{'callbacks'}}
	}
}

1;
