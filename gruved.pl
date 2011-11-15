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
use Player;
use World;

local $SIG{'INT'} = sub {
	$::sf->{'listener'}->close();
	undef $::sf->{'listener'};
};

our $log = Logger->new();

$log->clear();

$log->header('Gruved, the Minecraft server daemon');
$log->header('Distributed under the GNU GPL v3 license');

$log->magenta('Initializing core objects...');

our $srv = Server->new();
our $sf  = SocketFactory->new();
our $pp  = Packet::Parser ->new();
our $pf  = Packet::Factory->new();

our $tick = Timer->new(0.05);

$log->magenta('Binding to core events...');

$sf->bind(SocketFactory::TICK,\&sf_tick);
$sf->bind(SocketFactory::IDLE,\&sf_idle);

$tick->bind(\&timer_tick);

$sf->bind(SocketFactory::ACCEPT,   \&sf_accept);
$sf->bind(SocketFactory::READ,     \&sf_read);
$sf->bind(SocketFactory::EXCEPTION,\&sf_exception);
$sf->bind(SocketFactory::CLOSE,    \&sf_close);

$pp->bind(Packet::Parser::FILTER,\&pp_filter);

$log->magenta('Loading packet handlers...');

foreach my $file (glob 'lib/Packet/Handler/*.pm') {
	my $handler = $file; $handler =~ s/.*\/(.*)\.pm/$1/i;

	if (do $file) {
		# Great success!
	} elsif ($@)  {
		$log->red("\t" . $handler . ': ' . $@);
	} elsif ($!) {
		$log->red("\t" . $handler . ': ' . $!);
	} else {
		$log->red("\t" . $handler . ': Did not return a true value.'); # or something horrible!
	}
}

$log->magenta('Loading plugins...');

our %plugins; {
	our $onload = Eventss->new();

	foreach my $file (glob 'plugins/*.pm') {
		my $plugin = $file; $plugin =~ s/.*\/(.*)\.pm/$1/i;

		if (do $file && ($plugins{$plugin} = $plugin->new())) {
			$onload->trigger($plugin);
		} elsif ($@)  {
			$log->red("\t" . $plugin . ': ' . $@);
		} elsif ($!) {
			$log->red("\t" . $plugin . ': ' . $!);
		} else {
			$log->red("\t" . $plugin . ': Did not return a true value.'); # or something horrible!
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

$sf->run(); # TODO: Make $srv handle the main event loop.

$_->kick('Server is shutting down',1) for $srv->get_players();
$worlds{$_}->save() for keys %worlds;

$log->red('Server stopped!');

exit;

sub sf_tick {
	# Important stuff goes here.

	$tick->tick();
}

sub sf_idle {
	# Less important stuff goes here.
}

sub timer_tick {
	# Don't put anything in here. It is strictly for world time.
	# If you want to run something on each Minecraft tick, bind to
	# the $tick timer!

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

	my $parsed = $pp->parse($s);

	if ($parsed == -1) {
		$log->red('Could not parse data! ' . $pp->{'error'});
		$srv->get_player($s)->kick($pp->{'error'});
	} elsif ($parsed == 0) {
		$sf->close($s);
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
