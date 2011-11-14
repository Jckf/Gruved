#!/dev/null
package Gamemode;

use strict;
use warnings;

sub new {
	my ($class) = @_;
	my $self = {};

	bless($self,$class);

	$self->{'loaded'}=0;
	
	if (!$self->checkload()) {
		$::onload->bind('Commands',sub {$self->checkload()});
		$::onload->bind('Permissions',sub {$self->checkload()});
	}

	return $self;
}

sub checkload {
	my ($self)=@_;
	if (defined $::plugins{'Commands'} && defined $plugins{'Permissions'}) {
		$self->register();
		$self->{'loaded'}=1;
		return 1;
	}
	return 0;
}

sub register {
	$::plugins{'Commands'}->bind('gamemode',sub {
		my ($e,$s,$m) = @_;
		my $p = $::srv->get_player($s);

		if (($m == 0 || $m == 1) && $::plugins{'Permissions'}->can($p,'gamemode.set')) {
			$p->set_gamemode($m);
		}
	});
}

1;
