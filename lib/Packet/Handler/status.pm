#!/dev/null
use strict;
use warnings;
use Packet;

$::pp->bind(Packet::STATUS,sub {
	$::srv->get_player($_[1])->kick(
		$::srv->{'description'} . '§' .
		$::srv->get_players()   . '§' .
		$::srv->{'max_players'},
		1
	);
});

1;
