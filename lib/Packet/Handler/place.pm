#!/dev/null
use strict;
use warnings;
use Packet;
use Block;

$::pp->bind(Packet::PLACE,sub {
	return                     if $_[3] == 127;
	return pp_place_none(@_)   if $_[6] <  0;
	return pp_place_block(@_)  if $_[6] <  255;
	return pp_place_object(@_) if $_[6] >  255;
});

sub pp_place_none {
	# Interact?
}

sub pp_place_block {
	my ($e,$s,$x,$y,$z,$f,$t,$n,$d) = @_;
	my $p = $::srv->get_player($s);

	my ($bx,$by,$bz) = ($x,$y,$z);
	$by-- if $f == 0;
	$by++ if $f == 1;
	$bz-- if $f == 2;
	$bz++ if $f == 3;
	$bx-- if $f == 4;
	$bx++ if $f == 5;

	# TODO: Placing a slab on top of a slab should replace the bottom slab with a double slab.
	# TODO: Fences cannot be placed wherever. Create a system for this?
	# TODO: Check if there is already a block in where we want this block.
	# TODO: Stairs, chest, furnaces, torches and so on need data set for direction.

	my ($cx,$cz) = (floor($bx / 16),floor($bz / 16));
	my ($lx,$lz) = ($bx % 16,$bz % 16);

	my $chunk = $p->{'entity'}->{'world'}->get_chunk($cx,$cz);

	my $block = $chunk->get_block($lx,$by,$lz);

	return if $block->[Block::TYPE] != Block::AIR; # TODO: One can also place blocks in water and lava.

	$block = Block->new($t,$d);

	$chunk->set_block($lx,$by,$lz,$block);

	foreach my $o ($::srv->get_players()) {
		next unless $o->{'entity'}->{'world'}->{'name'} eq $p->{'entity'}->{'world'}->{'name'}; # TODO: Implement a get_players() in World.pm.
		$o->send(
			$::pf->build(
				Packet::BLOCK,
				$bx,
				$by,
				$bz,
				$block->[Block::TYPE],
				$block->[Block::DATA]
			)
		);
	}
}

sub pp_place_object {
	# Minecarts, snowballs, arrows...
}

1;
