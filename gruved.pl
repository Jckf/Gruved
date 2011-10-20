#!/usr/bin/perl
use strict;
use warnings;
use Devel::SimpleTrace;
use lib 'lib';
use Logger;
use Timer;
use Server;
use SocketFactory;
use Packet;
use Packet::Parser;
use Packet::Factory;
use World;
use Chunk;
use Player;
use Entity;

our $log = Logger->new();

$log->clear();

$log->header('Gruved, the Minecraft server daemon by Jim C K Flaten');
$log->header('Distributed under the GNU GPL v3 license');

$log->magenta('Initializing core objects...');

our $srv = Server->new();
our $sf  = SocketFactory->new();
our $pp  = Packet::Parser ->new();
our $pf  = Packet::Factory->new();

my $t1s  = Timer->new(1);

$log->magenta('Binding to core events...');

$sf->bind(SocketFactory::TICK,\&sf_tick);

$t1s->bind(\&timer_time);

$sf->bind(SocketFactory::ACCEPT,   \&sf_accept);
$sf->bind(SocketFactory::READ,     \&sf_read);
$sf->bind(SocketFactory::EXCEPTION,\&sf_exception);
$sf->bind(SocketFactory::CLOSE,    \&sf_close);

$pp->bind(Packet::Parser::FILTER,\&pp_filter);

$pp->bind(Packet::LOGIN   ,\&pp_0x01);
$pp->bind(Packet::HELLO   ,\&pp_0x02);
$pp->bind(Packet::CHAT    ,\&pp_0x03);
$pp->bind(Packet::GROUND  ,\&pp_0x0A);
$pp->bind(Packet::POSITION,\&pp_0x0B);
$pp->bind(Packet::LOOK    ,\&pp_0x0C);
$pp->bind(Packet::POSLOOK ,\&pp_0x0D);
$pp->bind(Packet::STATUS  ,\&pp_0xFE);
$pp->bind(Packet::QUIT    ,\&pp_0xFF);

$log->magenta('Loading plugins...');

# TODO: Create a class to handle this.
our %plugins;
foreach my $file (<plugins/*.pm>) {
	do $file;
	my $plugin = $file; $plugin =~ s/.*\/(.*)\.pm/$1/i;
	$plugins{$plugin} = $plugin->new();
}

$log->magenta('Loading worlds...');

# TODO: Automate this based on data on disk.
my %worlds;
$worlds{'world'} = World->new();

$log->green('Waiting for connections...');

$sf->run();

$log->red('Server stopped!');

exit;

sub sf_tick {
	$t1s->tick();
}

sub timer_time {
	$srv->{'time'}++;

	foreach my $p ($srv->get_players()) {
		$p->set_time($srv->{'time'} * 20 % 24000);
	}
}

sub sf_accept {
	$log->green('New connection from x.x.x.x.');

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

	if ($p->{'runlevel'} == 2) {
		if (time() - $p->{'keepalive'} >= 10) {
			$p->{'keepalive'} = time();
			$p->ping();
		}
	}
}

sub sf_exception {
	$log->red('Socket x.x.x.x:x has an exception!');
	$sf->close($_[1]);
}

sub sf_close {
	my ($e,$s) = @_;
	my $p = $srv->get_player($s);

	$log->red('Closing socket x.x.x.x:x...');

	if ($p->{'runlevel'} == 2) {
		foreach my $o ($srv->get_players()) {
			$o->send(
				$pf->build(
					Packet::LIST,
					$p->{'username'},
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

	if ($p->{'runlevel'} == Player::NEW) {
		if ($id == Packet::HELLO || $id == Packet::STATUS) {
			return;
		}
	} elsif ($p->{'runlevel'} == Player::HELLO) {
		if ($id == Packet::LOGIN) {
			return;
		}
	} elsif ($p->{'runlevel'} == Player::LOGIN) {
		return;
	}

	$e->{'cancelled'} = 1;
}

sub pp_0x01 {
	my ($e,$s,$proto,$un) = @_;

	my $p = $srv->get_player($s);

	# TODO: Load data from player file.

	$p->{'entity'} = Entity->new(
		'player' => $p,
		'name' => $un,
		'world' => $worlds{'world'}
	);

	$srv->add_entity($p->{'entity'});

	$p->send(
		$pf->build(
			0x01,
			$p->{'entity'}->{'id'},
			'',
			0, # Map seed.
			$p->{'gamemode'},
			$p->{'dimension'},
			$p->{'difficulty'},
			128, # World height.
			$srv->{'max_players'}
		)
	);

	$p->set_time($srv->{'time'});

	$p->update_position();

	$p->{'runlevel'} = 2;

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

		if ($o->{'username'} ne $p->{'username'}) {
			$o->load_entity_named($p->{'entity'});
			$p->load_entity_named($o->{'entity'});
		}
	}
}

sub pp_0x02 {
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

	$p->{'runlevel'} = 1;
}

sub pp_0x03 {
	if (!$_[0]->{'cancelled'}) {
		$srv->broadcast($srv->get_player($_[1])->{'displayname'} . '§f: ' . $_[2]);
	}
}

sub pp_0x0A {
	$srv->get_player($_[1])->{'on_ground'} = $_[2];
}

sub pp_0x0B {
	my ($e,$s,$x,$y,$y2,$z,$on_ground) = @_;
	pp_0x0D($e,$s,$x,$y,$y2,$z,undef,undef,$on_ground);
}

sub pp_0x0C {
	my ($e,$s,$yaw,$pitch,$on_ground) = @_;
	pp_0x0D($e,$s,undef,undef,undef,undef,$yaw,$pitch,$on_ground);
}

sub pp_0x0D {
	my ($e,$s,$x,$y,$y2,$z,$yaw,$pitch,$on_ground) = @_;

	# TODO: Check if the player is inside an unloaded chunk or inside a block. If he is, don't allow movement.

	$srv->get_player($s)->teleport($x,$y,$y2,$z,$yaw,$pitch,$on_ground);
}

sub pp_0xFE {
	$srv->get_player($_[1])->kick(
		$srv->{'description'} . '§' .
		$srv->get_players() . '§' .
		$srv->{'max_players'},
		1
	);
}

sub pp_0xFF {
	$sf->close($_[1]);
}
