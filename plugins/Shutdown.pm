#!/dev/null
package Shutdown;

use strict;
use warnings;

sub new {
	my ($class) = @_;
	my $self = {};

	$::cmd->bind('shutdown',sub {
		my ($e,$s,@args) = @_;
		if ($::srv->get_player($s)->{'username'} eq 'Jckf') {
			exit;
		}
	});

	bless($self,$class);
}
1;
