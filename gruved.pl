#!/usr/bin/perl
use strict;
use warnings;
#use Devel::SimpleTrace;
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
our $pp  = PacketParser ->new();
our $pf  = PacketFactory->new();

my $t1s  = Timer->new(1);

$log->magenta('Binding to core events...');

$sf->bind('tick',\&sf_tick);

$t1s->bind(\&timer_time);

$sf->bind('accept',       \&sf_accept);
$sf->bind('can_read',     \&sf_can_read);
$sf->bind('has_exception',\&sf_has_exception);
$sf->bind('close',        \&sf_close);

$pp->bind('filter',\&pp_filter);

$pp->bind(0x01,\&pp_0x01);
$pp->bind(0x02,\&pp_0x02);
$pp->bind(0x03,\&pp_0x03);
$pp->bind(0x0A,\&pp_0x0A);
$pp->bind(0x0B,\&pp_0x0B);
$pp->bind(0x0C,\&pp_0x0C);
$pp->bind(0x0D,\&pp_0x0D);
$pp->bind(0xFE,\&pp_0xFE);
$pp->bind(0xFF,\&pp_0xFF);

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

sub sf_can_read {
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

sub sf_has_exception {
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
					0xC9,
					$p->{'username'},
					0,
					0
				),
				$pf->build(
					0x1D,
					$p->{'entity'}->{'id'}
				),
				$pf->build(
					0x03,
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

	if ($p->{'runlevel'} == 0) {
		if ($id == 0x02 || $id == 0xFE) {
			return;
		}
	} elsif ($p->{'runlevel'} == 1) {
		if ($id == 0x01) {
			return;
		}
	} elsif ($p->{'runlevel'} == 2) {
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
	$p->{'displayname'} = ($u eq 'Jckf' ? '§cJckf' : $u);

	$p->send(
		$pf->build(
			0x02,
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
