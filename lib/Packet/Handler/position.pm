#!/dev/bull
use strict;
use warnings;
use Packet;

$::pp->bind(Packet::POSITION,sub {
	my ($e,$s,$x,$y,$y2,$z,$on_ground) = @_;

	$::pp->{'events'}->trigger(Packet::POSLOOK,$s,$x,$y,$y2,$z,undef,undef,$on_ground);
});

1;
