#!/dev/null
package Gamemode;

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
	$::plugins{'Commands'}->bind('gamemode',sub {
		my ($e,$s,$m) = @_;
		my $p = $::srv->get_player($s);

		if ($::plugins{'Permissions'}->can($p,'gamemode.set')) {
			$p->set_gamemode($m);
		}
	});
}

1;
