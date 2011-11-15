#!/dev/null
use strict;
use warnings;
use Packet;

$::pp->bind(Packet::CHAT,sub {
	if (!$_[0]->{'cancelled'}) {
		$::srv->broadcast($::srv->get_player($_[1])->{'displayname'} . '§f: ' . $_[2]);
	}
});

1;
