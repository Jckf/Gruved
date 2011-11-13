#!/dev/null
package Shutdown;

use strict;
use warnings;

sub new {
	my ($class) = @_;
	my $self = {};

	bless($self,$class);

	if (defined $::plugins{'Commands'}) {
		$self->register();
	} else {
		$::onload->bind('Commands',sub {
			$self->register();
		});
	}

	return $self;
}

sub register {
	$::plugins{'Commands'}->bind('shutdown',sub {
		my ($e,$s,@args) = @_;
		if ($::srv->get_player($s)->{'username'} eq 'Jckf') {
			exit;
		}
	});
}

1;
