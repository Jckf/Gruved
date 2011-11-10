#!/usr/bin/perl
use strict;
use warnings;
use Devel::SimpleTrace;
use POSIX 'floor';
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
$log->header('http://redmine.mcdevs.org/projects/gruved/');
$log->header('Distributed under the GNU GPL v3 license');

$log->magenta('Initializing core objects...');

our $srv = Server->new();
our $sf  = SocketFactory->new();
our $pp  = Packet::Parser ->new();
our $pf  = Packet::Factory->new();

my $t1s = Timer->new(1);

#I'm not sure where this should go, but it's pretty important...
$SIG{'INT'}=sub {
	local $SIG{'INT'};
	$log->red("Closing due to SIGINT...");
	# TODO: Save worlds, player data...
	$log->red("Kicking players...");
	foreach ($srv->get_players()) {
		$_->kick("Server is shutting down");
	}
	$log->red("Destroying core objects...");
	undef $pf;
	undef $pp;
	undef $sf;
	undef $srv;
	$log->red("Done!");
	undef $log;
	exit 255;
};

$log->magenta('Binding to core events...');

$sf->bind(SocketFactory::TICK,\&sf_tick);

$t1s->bind(\&timer_time);

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
$pp->bind(Packet::STATUS  ,\&pp_status);
$pp->bind(Packet::QUIT    ,\&pp_quit);

$log->magenta('Loading plugins...');

our %plugins;
foreach my $file (<plugins/*.pm>) {
	do $file;
	my $plugin = $file; $plugin =~ s/.*\/(.*)\.pm/$1/i;
	$::log->magenta("\t" . $plugin . '...');
	local $@; #Prevent bugs with previous errors
	eval { #If a plugin fails, it shouldn't crash the whole server, right?
		$plugins{$plugin} = $plugin->new();
	};
	if ($@) {
		$::log->red("\t\t" . ' could not be loaded: '.$@);
		if ($@ =~ /Can\'t locate object method "new" via package "$plugin"/) {
			$::log->red("\t\tPerhaps you need to add a new() method (or a package $plugin; declaration) to $plugin?");
		}
	}else{
		$::log->green("\t\t" . ' loaded successfully');
	}
}

$log->magenta('Loading worlds...');

# TODO: Move %worlds into $srv.

if (!-d 'worlds') {
	$::log->magenta('World directory not found, creating...');
	mkdir 'worlds';
}

my %worlds;
foreach my $dir (<worlds/*>) {
	if (-d $dir) {
		my $world = $dir; $world =~ s/.*\///;
		$::log->magenta("\t" . $world . '...');
		$worlds{$world} = World->new(
			'name' => $world
		);
	}
}

if (!keys %worlds) {
	$::log->magenta('No worlds found, generating new world \'world\'...');
	$worlds{'world'} = World->new(
		'name' => 'world'
	);
	mkdir 'worlds/world';
	mkdir 'worlds/world/chunks';
}

$log->green('Waiting for connections...');

$sf->run();

$log->red('Server stopped!');

exit;

sub sf_tick {
	$t1s->tick();
}

sub timer_time {
	$srv->{'time'}++;
	$_->set_time(($srv->{'time'} * 20) % 24000) for $srv->get_players();
}

sub sf_accept {
	$log->green('New connection from ' . $_[1]->peerhost() . '/' . $_[1]->sockhost() . '.'); # TODO: Is peerhost() the remote address? Use that in place of x.x.x.x everywhere.

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
		warn('Closing socket ' . fileno($s));
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

# TODO: Remove? I've never seen a socket with an exception.
sub sf_exception {
	$log->red('Socket x.x.x.x:x has an exception!');
	$sf->close($_[1]);
}

sub sf_close {
	my ($e,$s) = @_;
	my $p = $srv->get_player($s);

	$log->red('Closing socket x.x.x.x:x...');

	if ($p->{'runlevel'} == Player::LOGIN) {
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

		if ($o->{'username'} ne $p->{'username'}) {
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
		my ($cx,$cz) = (floor($x / 16),floor($z / 16));
		$x-- if $x < 0; $z-- if $z < 0;
		if (!$p->{'entity'}->{'world'}->chunk_loaded($cx,$cz) || $p->{'entity'}->{'world'}->get_chunk($cx,$cz)->get_block(int($x % 16),int($y),int($z % 16))->[0] != 0) {
			$p->send(
				$pf->build(
					Packet::BLOCK,
					$x,
					$y,
					$z,
					1,
					0
				)
			);
			$p->update_position();
			return;
		}
	}

	$p->teleport($x,$y,$y2,$z,$yaw,$pitch,$on_ground);
}

sub pp_dig {
	my ($e,$s,$a,$x,$y,$z,$f) = @_;

	return if $a != 2; # TODO: Record when a player starts digging and return if he finishes early.

	my ($cx,$cz) = (floor($x / 16),floor($z / 16));

	my $p = $srv->get_player($s);

	$p->{'entity'}->{'world'}->get_chunk($cx,$cz)->set_block($x % 16,$y,$z % 16,[0]);

	# TODO: We should probably create an automatic system for sending changes at the end of
	#       each tick (we've already set_block() so the server knows it has changed and should act on that).
	foreach my $o ($srv->get_players()) {
		$o->send(
			$pf->build(
				Packet::BLOCK,
				$x,
				$y,
				$z,
				0,
				0
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
