#!/usr/bin/perl
use strict;
use warnings;
use Time::HiRes 'sleep';
use lib 'lib';
use Logger;
use Timer;
use Server;
use SocketFactory;
use PacketParser;
use PacketFactory;
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
my  $pp  = PacketParser ->new();
our $pf  = PacketFactory->new();

my $t1s  = Timer->new(1);

$log->magenta('Binding to core events...');

$sf->{'events'}->bind('tick',\&sf_tick);

$t1s->bind(\&timer_time);
$t1s->bind(\&timer_pps );

$sf->{'events'}->bind('accept',       \&sf_accept);
$sf->{'events'}->bind('can_read',     \&sf_can_read);
$sf->{'events'}->bind('has_exception',\&sf_has_exception);
$sf->{'events'}->bind('close',        \&sf_close);

$pp->{'events'}->bind('filter',\&pp_filter);

$pp->{'events'}->bind(0x01,\&pp_0x01);
$pp->{'events'}->bind(0x02,\&pp_0x02);
$pp->{'events'}->bind(0x03,\&pp_0x03);
$pp->{'events'}->bind(0x0A,\&pp_0x0A);
$pp->{'events'}->bind(0x0B,\&pp_0x0B);
$pp->{'events'}->bind(0x0C,\&pp_0x0C);
$pp->{'events'}->bind(0x0D,\&pp_0x0D);
$pp->{'events'}->bind(0xFE,\&pp_0xFE);
$pp->{'events'}->bind(0xFF,\&pp_0xFF);

$log->magenta('Loading plugins...');

foreach my $plugin (<plugins/*.pm>) {
	print $_ . "\n";
}

$log->magenta('Loading worlds...');

# TODO: Automate this based on data on disk.
my %worlds;
$worlds{'world'} = new World();

$log->green('Waiting for connections...');

$sf->run();

$log->red('Server stopped!');

exit;

sub sf_tick {
	$t1s->tick();
	sleep 0.01 if !$_[0];
}

sub timer_time {
	$srv->{'time'}++;

	foreach my $p ($srv->get_players()) {
		$p->set_time($srv->{'time'} * 20 % 24000);
	}
}

sub timer_pps {
	$srv->{'pps'} = $srv->{'packets'};
	$srv->{'packets'} = 0;
}

sub sf_accept {
	$log->green('New connection from x.x.x.x.');

	$srv->add_player(
		Player->new(
			'socket' => $_[0]
		)
	);
}

sub sf_can_read {
	my ($s) = @_;
	my $p = $srv->get_player($s);

	if (!defined $p) {
		$log->red('Dead socket has data!');
		while (sysread($s,my $junk,32) == 32) {}
		return;
	}

	if (!$pp->parse($s)) {
		$log->red('Could not parse data! ' . $pp->{'error'});
		$p->kick($pp->{'error'});
		return 0;
	}

	$srv->{'packets'}++;

	if ($p->{'runlevel'} == 2) {
		if (time() - $p->{'keepalive'} >= 10) {
			$p->{'keepalive'} = time();
			$p->ping();
		}
	}

	return 1;
}

sub sf_has_exception {
	$log->red('Socket x.x.x.x:x has an exception!');
	$sf->close($_[0]);
}

sub sf_close {
	my ($s) = @_;
	my $p = $srv->get_player($s);

	$log->red('Closing socket x.x.x.x:x...');

	if ($p->{'runlevel'} == 2) {
		$srv->broadcast('§e' . $p->{'username'} . ' left the game.');

		foreach my $o ($srv->get_players()) {
			$o->send(
				$pf->build(
					0xC9,
					$p->{'username'},
					0,
					0
				)
			);
		}
	}

	$srv->remove_player($s);
}

sub pp_filter {
	my ($s,$id) = @_;
	my $p = $srv->get_player($s);

	if ($p->{'runlevel'} == 0) {
		if ($id == 0x02 || $id == 0xFE) {
			return 1;
		}
	} elsif ($p->{'runlevel'} == 1) {
		if ($id == 0x01) {
			return 1;
		}
	} elsif ($p->{'runlevel'} == 2) {
		return 1;
	}

	$log->red('Packet 0x' . uc(unpack('H*',chr($id))) . ' from x.x.x.x:x was denied by filter!');

	return 0;
}

sub pp_0x01 {
	my ($s,$proto,$un) = @_;

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
				0xC9,
				$p->{'displayname'} . '§f',
				1,
				$p->{'latency'}
			)
		);
		$p->send(
			$pf->build(
				0xC9,
				$o->{'displayname'} . '§f',
				1,
				$o->{'latency'}
			)
		);
	}
}

sub pp_0x02 {
	my ($s,$un) = @_;

	my $p = $srv->get_player($s);
	$p->{'username'} = $un;
	$p->{'displayname'} = ($un eq 'Jckf' ? '§cJckf' : $un);

	$p->send(
		$pf->build(
			0x02,
			'-'
		)
	);

	$p->{'runlevel'} = 1;
}

sub pp_0x03 {
	my ($s,$msg) = @_;
	$srv->broadcast($srv->get_player($s)->{'displayname'} . '§f: ' . $msg);
}

sub pp_0x0A {
	$srv->get_player($_[0])->{'on_ground'} = $_[1];
}

sub pp_0x0B {
	my ($s,$x,$y,$y2,$z,$on_ground) = @_;
	pp_0x0D($s,$x,$y,$y2,$z,undef,undef,$on_ground);
}

sub pp_0x0C {
	my ($s,$yaw,$pitch,$on_ground) = @_;
	pp_0x0D($s,undef,undef,undef,undef,$yaw,$pitch,$on_ground);
}

sub pp_0x0D {
	my ($s,$x,$y,$y2,$z,$yaw,$pitch,$on_ground) = @_;

	# TODO: Check if the player is inside an unloaded chunk or inside a block. If he is, don't allow movement.

	$srv->get_player($s)->teleport($x,$y,$y2,$z,$yaw,$pitch,$on_ground);
}

sub pp_0xFE {
	$srv->get_player($_[0])->kick(
		$srv->{'description'} . '§' .
		$srv->get_players() . '§' .
		$srv->{'max_players'},
		1
	);
}

sub pp_0xFF {
	$sf->close($_[0]);
}
