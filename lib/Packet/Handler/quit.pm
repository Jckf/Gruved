#!/dev/null
use strict;
use warnings;
use Packet;

$::pp->bind(Packet::QUIT,sub {
	$::sf->close($_[1]);
});

1;
