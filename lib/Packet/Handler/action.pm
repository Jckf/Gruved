#!/dev/null
use strict;
use warnings;
use Packet;
use Entity;

$::pp->bind(Packet::ACTION,sub {
	my ($e,$s,$i,$a) = @_;
	my $p = $::srv->get_player($s);

	if ($a == Entity::CROUCH) {
		$::log->cyan('Crouch');
		$p->{'entity'}->{'crouching'} = 1;
		$p->send(
			$::pf->build(
				Packet::ANIMATE,
				$p->{'entity'}->{'id'},
				104
			)
		);
	} elsif ($a == Entity::UNCROUCH) {
		$::log->cyan('Uncrouch');
		$p->{'entity'}->{'crouching'} = 0;
		$p->send(
			$::pf->build(
				Packet::ANIMATE,
				$p->{'entity'}->{'id'},
				105
			)
		);
	}
});

1;
