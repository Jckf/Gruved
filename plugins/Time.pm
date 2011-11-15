#!/dev/null
package Time;

use strict;
use warnings;

sub new {
	my ($class) = @_;
	my $self = {};

	bless($self,$class);

	if (!$self->ready()) {
		$::onload->bind('Commands'   ,sub { $self->ready() });
		$::onload->bind('Permissions',sub { $self->ready() });
	}

	return $self;
}

sub ready {
	$_[0]->register() if (defined $::plugins{'Commands'} && defined $::plugins{'Permissions'});
}

sub register {
	$::plugins{'Commands'}->bind('time',sub {
		my ($e,$s,$time) = @_;

		if (defined $time && $::plugins{'Permissions'}->can($s,'time.set')) {
			if ($time eq 'day') {
				$::srv->{'time'} = 6000;
			} elsif ($time eq 'night') {
				$::srv->{'time'} = 18000;
			} else {
				$::srv->{'time'} = $time;
			}
		}
	});

	return 1;
}

1;
