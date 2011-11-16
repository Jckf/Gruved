#!/dev/null
package Shutdown;

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
	$::plugins{'Commands'}->bind('shutdown',sub {
		my $p = $::srv->get_player($_[1]);
		if ($p->has_permission('shutdown')) {
			$::sf->{'listener'}->close();
			undef $::sf->{'listener'};
		}
	});
}

1;
