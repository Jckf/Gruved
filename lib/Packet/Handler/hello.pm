#!/dev/null
use strict;
use warnings;
use Packet;

$::pp->bind(Packet::HELLO,sub {
	my ($e,$s,$u) = @_;

	my $p = $::srv->get_player($s);
	$p->{'username'} = $u;
	$p->{'displayname'} = ($u eq 'Jckf' ? '§cJckf' : $u); # TODO: Move change of displayname to Permissions plugin.

	$p->send(
		$::pf->build(
			Packet::HELLO,
			'-'
		)
	);

	$p->{'runlevel'} = Player::HELLO;
});

1;
