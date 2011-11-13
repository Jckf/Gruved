#!/dev/null
package Time;

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
    $::plugins{'Commands'}->bind('time',sub {
        my ($e,$s,@args) = @_;

        if ($::srv->get_player($s)->{'username'} eq 'Jckf') {
            if ($args[0] eq 'day') {
                $::srv->{'time'} = 6000;
            } elsif ($args[0] eq 'night') {
                $::srv->{'time'} = 18000;
            } else {
                $::srv->{'time'} = $args[0];
            }
        }
    });
}

1;
