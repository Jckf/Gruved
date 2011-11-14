#!/dev/null
package Gamemode;

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
    $::plugins{'Commands'}->bind('gamemode',sub {
        my ($e,$s,$m) = @_;
		my $p = $::srv->get_player($s);

        #if ($p->{'username'} eq 'Jckf') {
            $p->set_gamemode($m);
        #}
    });
}

1;
