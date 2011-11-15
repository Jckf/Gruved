#!/dev/null
use strict;
use warnings;
use Packet;

$::pp->bind(Packet::LOGIN,sub {
	my ($e,$s,$proto,$un) = @_;

	my $p = $::srv->get_player($s);

	$p->{'entity'} = Entity->new(
		'player' => $p,
		'name' => $un,
		'world' => $::worlds{'world'} # TODO: Load from player or configuration variable for default world.
	);

	# TODO: Get data from the player object and place them into the entity (coordinates and so on).

	$::srv->add_entity($p->{'entity'}); # TODO: This should go in the world, not the server.

	$p->send(
		$::pf->build(
			Packet::LOGIN,
			$p->{'entity'}->{'id'},
			'',
			$p->{'entity'}->{'world'}->{'seed'},
			$p->{'gamemode'},
			$p->{'dimension'},
			$p->{'difficulty'},
			$p->{'entity'}->{'world'}->{'height'},
			$::srv->{'max_players'}
		)
	);

	$p->set_time($::srv->{'time'});

	$p->update_chunks();
	$p->update_position();

	$p->{'runlevel'} = Player::LOGIN;

	$::srv->broadcast($p->{'displayname'} . ' §ejoined the game.');

	foreach my $o ($::srv->get_players()) {
		$o->send(
			$::pf->build(
				Packet::LIST,
				$p->{'displayname'} . '§f',
				1,
				$p->{'latency'}
			)
		);
		$p->send(
			$::pf->build(
				Packet::LIST,
				$o->{'displayname'} . '§f',
				1,
				$o->{'latency'}
			)
		);

		if ($o->{'username'} ne $p->{'username'} && $o->{'entity'}->{'world'}->{'name'} eq $p->{'entity'}->{'world'}->{'name'}) {
			$o->load_entity_named($p->{'entity'});
			$p->load_entity_named($o->{'entity'});
		}
	}
});

1;
