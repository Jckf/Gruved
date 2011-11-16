#!/dev/null
use strict;
use warnings;
use POSIX 'floor';
use Packet;
use Player;
use Block;

$::pp->bind(Packet::DIG,sub {
	my ($e,$s,$a,$x,$y,$z,$f) = @_;
	my $p = $::srv->get_player($s);

	return if ($a != 2 && $p->{'gamemode'} == Player::SURVIVAL); # TODO: Record when a player starts digging and return if he finishes early.

	my ($wx,$wy,$wz) = (floor($x),floor($y),floor($z));
	my ($cx,$cz) = (floor($wx / 16),floor($wz / 16));
	my ($lx,$lz) = ($wx % 16,$wz % 16);

	my $chunk = $p->{'entity'}->{'world'}->get_chunk($cx,$cz);

	my $block = $chunk->get_block($x % 16,$y,$z % 16);

	return if $block->[Block::TYPE] == Block::AIR;

	$block = Block->new();

	$chunk->set_block($x % 16,$y,$z % 16,$block);

	# TODO: We should probably create an automatic system for sending changes at the end of
	#       each tick (we've already set_block() so the server knows it has changed and should act on that).
	foreach my $o ($::srv->get_players()) {
		$o->send(
			$::pf->build(
				Packet::BLOCK,
				$x,
				$y,
				$z,
				$block->[Block::TYPE],
				$block->[Block::DATA]
			)
		);
	}
});

1;
