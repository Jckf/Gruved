#!/dev/null
package Time;

use strict;
use warnings;

sub new {
	my ($class) = @_;

	my $self = {
		'dependencies' => ['Commands','Permissions']
	};

	bless($self,$class);
}

sub init {
	$::plugins{'Commands'}->bind('time',sub {
		my ($e,$s,$time) = @_;

		if (defined $time && $::srv->get_player($s)->has_permission('time.set')) {
			if ($time eq 'day') {
				$::srv->{'time'} = 6000;
			} elsif ($time eq 'night') {
				$::srv->{'time'} = 18000;
			} else {
				$::srv->{'time'} = $time;
			}
		}
	});
}

1;
