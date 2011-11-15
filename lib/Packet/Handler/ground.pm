#!/dev/null
use strict;
use warnings;
use Packet;

$::pp->bind(Packet::GROUND,sub {
	$::srv->get_player($_[1])->{'on_ground'} = $_[2];
});

1;
