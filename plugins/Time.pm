#!/dev/null
package Time;

use strict;
use warnings;

sub new {
	my ($class) = @_;
    my $self = {};

    $::plugins{'Commands'}->bind('time',sub {
        my ($e,$s,@args) = @_;
        if ($::srv->get_player($s)->{'username'} eq 'Jckf') {
            if ($args[0] eq 'day') {
                $::srv->{'time'} = 6000 / 20;
            } elsif ($args[0] eq 'night') {
                $::srv->{'time'} = 18000 / 20;
            } else {
                $::srv->{'time'} = $args[0] / 20;
            }
        }
    });

    bless($self,$class);
}
