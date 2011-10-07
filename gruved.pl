#!/usr/bin/perl
use strict;
use warnings;
use lib './lib';
use Minecraft::Server;
use Minecraft::Server::SocketFactory;
use Minecraft::Server::PacketParser;
use Minecraft::Server::PacketFactory;
use Minecraft::Server::Chunk;
use Minecraft::Server::Player;
use Minecraft::Server::EntityNamed;

my $srv = Minecraft::Server->new();

our $sf = Minecraft::Server::SocketFactory->new();
my $pp = Minecraft::Server::PacketParser->new();
our $pf = Minecraft::Server::PacketFactory->new();

$sf->{'events'}->bind('accept',\&sf_accept);
$sf->{'events'}->bind('can_read',\&sf_can_read);
$sf->{'events'}->bind('has_exception',\&sf_has_exception);
$sf->{'events'}->bind('close',\&sf_close);

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

$sf->run();

sub sf_accept {
	print 'Ohai!' . "\n";

	$srv->add_player(
		Minecraft::Server::Player->new(
			'socket' => $_[0]
		)
	);
}

sub sf_can_read {
	my ($s) = @_;
	my $p = $srv->get_player($s);

	if (!defined $p) {
		#print 'Getting shit from a disconnected client. Fuck that.' . "\n";
		return;
	}

	if ($pp->parse($s)) {
		if (time() - $p->{'keepalive'} >= 10) {
			$p->{'keepalive'} = time();
			$p->ping();
		}
		return 1;
	}

	print 'Could not parse.' . "\n";
	$p->kick('Junk in data stream.');
	return 0;
}

sub sf_has_exception {
	print 'Has exception.' . "\n";
	$sf->close($_[0]);
}

sub sf_close {
	my ($s) = @_;
	my $p = $srv->get_player($s);

	print 'Close.' . "\n";

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

	print 'Denied by filter rule.' . "\n";

	return 0;
}

sub pp_0x01 {
	my ($s,$proto,$un) = @_;

	my $p = $srv->get_player($s);

	$p->{'entity'} = Minecraft::Server::EntityNamed->new(
		'player' => $p,
		'name' => $un
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

	my $chunk = Minecraft::Server::Chunk->new();
	my $chunk2 = Minecraft::Server::Chunk->new();
	foreach my $x (0 .. 16) {
		foreach my $z (0 .. 16) {
			# Dummy chunk.
			$chunk->set_block($x,63,$z,Minecraft::Server::Block->new(
				'type' => 1
			));
			$chunk->set_block($x,64,$z,Minecraft::Server::Block->new(
				'type' => 3
			));
			$chunk->set_block($x,65,$z,Minecraft::Server::Block->new(
				'type' => 2
			));

			# Dummy chunk with water.
			$chunk2->set_block($x,63,$z,Minecraft::Server::Block->new(
				'type' => 1
			));
			$chunk2->set_block($x,64,$z,Minecraft::Server::Block->new(
				'type' => 3
			));
			$chunk2->set_block($x,65,$z,Minecraft::Server::Block->new(
				'type' => 9
			));
		}
	}
	$chunk = $chunk->deflate();
	$chunk2 = $chunk2->deflate();

	foreach my $cx (-3 .. 3) {
		foreach my $cz (-3 .. 3) {
			$p->send(
				$pf->build(
					0x32,
					$cx,
					$cz,
					1
				),
				$pf->build(
					0x33,
					$cx * 16,
					0,
					$cz * 16,
					15,
					127,
					15,
					length($cx == 1 && $cz == 0 ? $chunk2 : $chunk),
					($cx == 1 && $cz == 0 ? $chunk2 : $chunk)
				)
			);
		}
	}

	$p->update_position();

	$p->{'runlevel'} = 2;

	$srv->broadcast('§e' . $p->{'username'} . ' joined the game.');

	foreach my $o ($srv->get_players()) {
		$o->send(
			$pf->build(
				0xC9,
				$p->{'username'},
				1,
				$p->{'latency'}
			)
		);
		$p->send(
			$pf->build(
				0xC9,
				$o->{'username'},
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
	$srv->broadcast($srv->get_player($s)->{'username'} . ': ' . $msg);
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
	$srv->get_player($s)->teleport($x,$y,$y2,$z,$yaw,$pitch,$on_ground);
}

sub pp_0xFE {
	$srv->get_player($_[0])->kick(
		$srv->{'description'} . '§' .
		$srv->get_players() . '§' .
		$srv->{'max_players'}
	);
}

sub pp_0xFF {
	$sf->close($_[0]);
}
