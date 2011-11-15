#!/dev/null
use strict;
use warnings;
use Packet;

$::pp->bind(Packet::LOOK,sub {
	my ($e,$s,$yaw,$pitch,$on_ground) = @_;

	$::pp->{'events'}->trigger(Packet::POSLOOK,$s,undef,undef,undef,undef,$yaw,$pitch,$on_ground);
});

1;
