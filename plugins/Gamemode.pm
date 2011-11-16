#!/dev/null
package Gamemode;

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
	$::plugins{'Commands'}->bind('gamemode',sub {
		my ($e,$s,$m) = @_;
		my $p = $::srv->get_player($s);

		if ($p->has_permission('gamemode.set')) {
			$p->set_gamemode($m);
		}
	});
}

1;
