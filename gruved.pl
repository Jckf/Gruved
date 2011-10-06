#!/usr/bin/perl
use strict;
use warnings;
use lib './lib';
use Minecraft::Server;
use Minecraft::Server::SocketFactory;
use Minecraft::Server::PacketParser;
use Minecraft::Server::PacketFactory;
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
	my ($s) = @_;

	$srv->add_player(
		Minecraft::Server::Player->new(
			'socket' => $s
		)
	);
}

sub sf_can_read {
	$sf->close($_[0]) if !$pp->parse($_[0]);
}

sub sf_has_exception {
	$sf->close($_[0]);
}

sub sf_close {
	$srv->remove_player($_[0]);
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

	$p->update_position();

	$p->{'runlevel'} = 2;
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

	# We don't know who's around yet. Send it to ourself for now.
	my $p = $srv->get_player($s);
	$p->send(
		$pf->build(
			0x03,
			$p->{'username'} . ': ' . $msg
		)
	);
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
		(length(@{$srv->{'players'}}) - 1) . '§' .
		$srv->{'max_players'}
	);
}

sub pp_0xFF {
	$sf->close($_[0]);
}
