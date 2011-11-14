#!/usr/bin/perl
use strict;
use warnings;
use Devel::SimpleTrace;
use POSIX 'floor';
use lib 'lib';
use Logger;
use Eventss;
use Timer;
use Server;
use SocketFactory;
use Packet;
use Packet::Parser;
use Packet::Factory;
use World;
use Chunk;
use Block;
use Player;
use Entity;

local $SIG{'INT'} = sub {
	$::sf->{'listener'}->close();
	undef $::sf->{'listener'};
};

our $log = Logger->new();

$log->clear();

$log->header('Gruved, the Minecraft server daemon');
$log->header('Distributed under the GNU GPL v3 license');

$log->magenta('Initializing core objects...');

#our $cfg = Config->new();
our $srv = Server->new();
our $sf  = SocketFactory->new();
our $pp  = Packet::Parser ->new();
our $pf  = Packet::Factory->new();

my $tick = Timer->new(0.05);

#$log->magenta('Loading configuration...');

#$cfg->load('somefile');

$log->magenta('Binding to core events...');

$sf->bind(SocketFactory::TICK,\&sf_tick);

$tick->bind(\&timer_tick);

$sf->bind(SocketFactory::ACCEPT,   \&sf_accept);
$sf->bind(SocketFactory::READ,     \&sf_read);
$sf->bind(SocketFactory::EXCEPTION,\&sf_exception);
$sf->bind(SocketFactory::CLOSE,    \&sf_close);

$pp->bind(Packet::Parser::FILTER,\&pp_filter);

$pp->bind(Packet::LOGIN   ,\&pp_login);
$pp->bind(Packet::HELLO   ,\&pp_hello);
$pp->bind(Packet::CHAT    ,\&pp_chat);
$pp->bind(Packet::GROUND  ,\&pp_ground);
$pp->bind(Packet::POSITION,\&pp_position);
$pp->bind(Packet::LOOK    ,\&pp_look);
$pp->bind(Packet::POSLOOK ,\&pp_poslook);
$pp->bind(Packet::DIG     ,\&pp_dig);
$pp->bind(Packet::PLACE   ,\&pp_place);
$pp->bind(Packet::ACTION  ,\&pp_action);
$pp->bind(Packet::STATUS  ,\&pp_status);
$pp->bind(Packet::QUIT    ,\&pp_quit);

$log->magenta('Loading plugins...');

our %plugins;
do { # do() to keep us in our own scope.
	our $onload = Eventss->new();

	foreach my $file (glob 'plugins/*.pm') {
		my $plugin = $file; $plugin =~ s/.*\/(.*)\.pm/$1/i;

		if (do $file && ($plugins{$plugin} = $plugin->new())) {
			$onload->trigger($plugin);
		} elsif ($@)  {
			$log->red("\t" . 'Error: ' . $@);
		} elsif ($!) {
			$log->red("\t" . 'Error: ' . $!);
		} else {
			$log->red("\t" . 'Error: Did not return a true value.'); # or something horrible!
		}
	}
};

$log->magenta('Loading worlds...');

# TODO: Move %worlds into $srv.
mkdir 'worlds' if !-d 'worlds';
mkdir 'worlds/world' if !glob 'worlds/*'; # TODO: This should create a directory with the name of the default world (config).

our %worlds;
foreach my $dir (glob 'worlds/*') {
	if (-d $dir) {
		my $world = $dir; $world =~ s/.*\///;
		$worlds{$world} = World->new(
			'name' => $world
		);
	}
}

$log->green('Waiting for connections...');

$sf->run();

$_->kick("Server is shutting down",1) for $srv->get_players();
$worlds{$_}->save() for keys %worlds;

$log->red('Server stopped!');

exit;

sub sf_tick {
	$tick->tick();
}

sub timer_tick {
	$srv->{'time'}++;

	if ($srv->{'time'} % 20 == 0) { # TODO: Make time world spesific.
		foreach my $p ($srv->get_players()) {
			$p->set_time($srv->{'time'} % 24000);

			if ($p->{'runlevel'} == Player::LOGIN) {
				if (time() - $p->{'keepalive'} >= 10) {
					$p->{'keepalive'} = time();
					$p->ping();
				}
			}
		}
	}
}

sub sf_accept {
	$log->green('New connection from ' . $_[1]->peerhost() . '.');

	$srv->add_player(
		Player->new(
			'socket' => $_[1]
		)
	);
}

sub sf_read {
	my ($e,$s) = @_;
	my $p = $srv->get_player($s);

	my $parsed = $pp->parse($s);

	if ($parsed == -1) {
		$log->red('Could not parse data! ' . $pp->{'error'});
		$p->kick($pp->{'error'});
		return;
	} elsif ($parsed == 0) {
		$sf->close($s);
		return;
	}
}

# TODO: Remove? I've never seen a socket with an exception.
sub sf_exception {
	$log->red('Socket ' . $_[1]->peerhost() . ' has an exception!');
	$sf->close($_[1]);
}

sub sf_close {
	my ($e,$s) = @_;
	my $p = $srv->get_player($s);

	$log->red('Closing socket ' . $s->peerhost() . '...');

	if ($p->{'runlevel'} == Player::LOGIN) {
		foreach my $o ($srv->get_players()) {
			$o->send(
				$pf->build(
					Packet::LIST,
					$p->{'displayname'} . '§f', # Yes, we need the color white here. See list population at login.
					0,
					0
				),
				$pf->build(
					Packet::REMOVE,
					$p->{'entity'}->{'id'}
				),
				$pf->build(
					Packet::CHAT,
					$p->{'displayname'} . '§e left the game.'
				)
			);
		}
	}

	$srv->remove_player($s);
}

sub pp_filter {
	my ($e,$s,$id) = @_;
	my $p = $srv->get_player($s);

	return if ($p->{'runlevel'} == Player::LOGIN);

	if ($p->{'runlevel'} == Player::NEW) {
		if ($id == Packet::HELLO || $id == Packet::STATUS) {
			return;
		}
	} elsif ($p->{'runlevel'} == Player::HELLO) {
		if ($id == Packet::LOGIN) {
			return;
		}
	}

	$e->{'cancelled'} = 1;
}

sub pp_login {
	my ($e,$s,$proto,$un) = @_;

	my $p = $srv->get_player($s);

	$p->{'entity'} = Entity->new(
		'player' => $p,
		'name' => $un,
		'world' => $worlds{'world'} # TODO: Load from player or configuration variable for default world.
	);

	# TODO: Get data from the player object and place them into the entity (coordinates and so on).

	$srv->add_entity($p->{'entity'});

	$p->send(
		$pf->build(
			Packet::LOGIN,
			$p->{'entity'}->{'id'},
			'',
			$p->{'entity'}->{'world'}->{'seed'},
			$p->{'gamemode'},
			$p->{'dimension'},
			$p->{'difficulty'},
			$p->{'entity'}->{'world'}->{'height'},
			$srv->{'max_players'}
		)
	);

	$p->set_time($srv->{'time'});

	$p->update_chunks();
	$p->update_position();

	$p->{'runlevel'} = Player::LOGIN;

	$srv->broadcast($p->{'displayname'} . ' §ejoined the game.');

	foreach my $o ($srv->get_players()) {
		$o->send(
			$pf->build(
				Packet::LIST,
				$p->{'displayname'} . '§f',
				1,
				$p->{'latency'}
			)
		);
		$p->send(
			$pf->build(
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
}

sub pp_hello {
	my ($e,$s,$u) = @_;

	my $p = $srv->get_player($s);
	$p->{'username'} = $u;
	$p->{'displayname'} = ($u eq 'Jckf' ? '§cJckf' : $u); # Yes, I am cooler than you ;)

	$p->send(
		$pf->build(
			Packet::HELLO,
			'-'
		)
	);

	$p->{'runlevel'} = Player::HELLO;
}

sub pp_chat {
	if (!$_[0]->{'cancelled'}) {
		$srv->broadcast($srv->get_player($_[1])->{'displayname'} . '§f: ' . $_[2]);
	}
}

sub pp_ground {
	$srv->get_player($_[1])->{'on_ground'} = $_[2];
}

sub pp_position {
	my ($e,$s,$x,$y,$y2,$z,$on_ground) = @_;
	pp_poslook($e,$s,$x,$y,$y2,$z,undef,undef,$on_ground);
}

sub pp_look {
	my ($e,$s,$yaw,$pitch,$on_ground) = @_;
	pp_poslook($e,$s,undef,undef,undef,undef,$yaw,$pitch,$on_ground);
}

sub pp_poslook {
	my ($e,$s,$x,$y,$y2,$z,$yaw,$pitch,$on_ground) = @_;
	my $p = $srv->get_player($s);

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
}

sub pp_dig {
	my ($e,$s,$a,$x,$y,$z,$f) = @_;
	my $p = $srv->get_player($s);

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
	foreach my $o ($srv->get_players()) {
		$o->send(
			$pf->build(
				Packet::BLOCK,
				$x,
				$y,
				$z,
				$block->[Block::TYPE],
				$block->[Block::DATA]
			)
		);
	}
}

sub pp_place {
	return if $_[3] == 127;
	return pp_place_none(@_) if $_[6] < 0;
	return pp_place_block(@_) if $_[6] < 255;
	return pp_place_object(@_) if $_[6] > 255;
}

sub pp_place_none {
	# Interact?
}

sub pp_place_block {
	my ($e,$s,$x,$y,$z,$f,$t,$n,$d) = @_;
	my $p = $srv->get_player($s);

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

	foreach my $o ($srv->get_players()) {
		next unless $o->{'entity'}->{'world'}->{'name'} eq $p->{'entity'}->{'world'}->{'name'}; # TODO: Implement a get_players() in World.pm.
		$o->send(
			$pf->build(
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

sub pp_action {
	my ($e,$s,$i,$a) = @_;
	my $p = $srv->get_player($s);

	if ($a == Entity::CROUCH) {
		$p->{'entity'}->{'crouching'} = 1;
		$p->send(
			$pf->build(
				Packet::ANIMATE,
				$p->{'entity'}->{'id'},
				104
			)
		);
	} elsif ($a == Entity::UNCROUCH) {
		$p->{'entity'}->{'crouching'} = 0;
		$p->send(
			$pf->build(
				Packet::ANIMATE,
				$p->{'entity'}->{'id'},
				105
			)
		);
	}
}

sub pp_status {
	$srv->get_player($_[1])->kick(
		$srv->{'description'} . '§' .
		$srv->get_players() . '§' .
		$srv->{'max_players'},
		1
	);
}

sub pp_quit {
	$sf->close($_[1]);
}
