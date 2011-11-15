#!/dev/null
use strict;
use warnings;
use Packet;
use Block;

$::pp->bind(Packet::POSLOOK,sub {
	my ($e,$s,$x,$y,$y2,$z,$yaw,$pitch,$on_ground) = @_;
	my $p = $::srv->get_player($s);

	if (defined $x && defined $y && defined $z) {
		my ($wx,$wy,$wz) = (floor($x),floor($y),floor($z));
		my ($cx,$cz) = (floor($wx / 16),floor($wz / 16));

		if (!$p->{'entity'}->{'world'}->chunk_loaded($cx,$cz)) {
			$p->update_position();
			return;
		}

		my $chunk = $p->{'entity'}->{'world'}->get_chunk($cx,$cz);

		my ($lx,$lz) = ($wx % 16,$wz % 16);

		if ($chunk->get_block($lx,$wy,$lz)->[Block::SOLID]) {
			$p->update_position();
			return;
		}

		if (
			$p->{'gamemode'} != Player::CREATIVE &&
			$on_ground &&
			$chunk->get_block($lx    ,$wy - 1,$lz    )->[Block::TYPE] == Block::AIR &&
			$chunk->get_block($lx - 1,$wy - 1,$lz - 1)->[Block::TYPE] == Block::AIR &&
			$chunk->get_block($lx - 1,$wy - 1,$lz    )->[Block::TYPE] == Block::AIR &&
			$chunk->get_block($lx - 1,$wy - 1,$lz + 1)->[Block::TYPE] == Block::AIR &&
			$chunk->get_block($lx    ,$wy - 1,$lz - 1)->[Block::TYPE] == Block::AIR &&
			$chunk->get_block($lx    ,$wy - 1,$lz + 1)->[Block::TYPE] == Block::AIR &&
			$chunk->get_block($lx + 1,$wy - 1,$lz - 1)->[Block::TYPE] == Block::AIR &&
			$chunk->get_block($lx + 1,$wy - 1,$lz    )->[Block::TYPE] == Block::AIR &&
			$chunk->get_block($lx + 1,$wy - 1,$lz + 1)->[Block::TYPE] == Block::AIR
		) {
			# Claiming to be on the ground when there is no ground around!
			$p->kick('Flying, are we?');
			return;
		}
	}

	$p->teleport($x,$y,$y2,$z,$yaw,$pitch,$on_ground);
});

1;
