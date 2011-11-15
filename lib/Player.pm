#!/dev/null
package Player;

use strict;
use warnings;
use Packet;

use constant {
	NEW   => 0,
	HELLO => 1,
	LOGIN => 2,

	SURVIVAL => 0,
	CREATIVE => 1
};

sub new {
	my ($class,%options) = @_;
	my $self = {};

	$self->{'runlevel'} = NEW;
	$self->{'keepalive'} = time();
	$self->{'latency'} = 0;

	$self->{'username'} = '';
	$self->{'displayname'} = '';

	$self->{'gamemode'} = SURVIVAL;
	$self->{'dimension'} = 0;
	$self->{'difficulty'} = 0;

	$self->{$_} = $options{$_} for keys %options;

	# TODO: Load player data from disk.

	bless($self,$class);
}

sub send {
	my ($self,@data) = @_;
	syswrite($self->{'socket'},$_) for @data;
}

sub ping {
	my ($self,$id) = @_;

	$self->send(
		$::pf->build(
			Packet::PING,
			$id || 0
		)
	);
}

sub message {
	my ($self,$msg) = @_;

	$self->send(
		$::pf->build(
			Packet::CHAT,
			$msg
		)
	);
}

sub set_time {
	$_[0]->send(
		$::pf->build(
			Packet::TIME,
			$_[1]
		)
	);
}

sub update_position {
	my ($self) = @_;

	$self->send(
		$::pf->build(
			Packet::POSITION,
			$self->{'entity'}->{'x'},
			$self->{'entity'}->{'y2'},
			$self->{'entity'}->{'y'},
			$self->{'entity'}->{'z'},
			$self->{'entity'}->{'on_ground'}
		)
	);
}

sub update_chunks {
	my ($self,$x,$z) = @_;

	my $y = 0;

	if (defined($x) && defined($z)) {
		# TODO: Check if we need to load/unload chunks based on current position and new position (if moving from one chunk to another).
	} else {
		$y = 1;
	}

	if ($y) {
		foreach my $cx (-$::srv->{'view_distance'} .. $::srv->{'view_distance'} ) {
			foreach my $cz (-$::srv->{'view_distance'} .. $::srv->{'view_distance'}) {
				$self->load_chunk($cx,$cz);
			}
		}
	}
}

sub load_chunk {
	my ($self,$x,$z) = @_;

	my $w = $self->{'entity'}->{'world'};
	my $c = $w->get_chunk($x,$z)->deflate();
	if (!defined $c) {
		$::log->cyan('Chunk ' . $x . ',' . $z . ' is broken. Regenerating...');
		$w->unload_chunk($x,$z);
		$w->delete_chunk($x,$z);
		$c = $w->get_chunk($x,$z)->deflate();
	}

	$self->send(
		$::pf->build(
			Packet::CHUNK,
			$x,
			$z,
			1
		),
		$::pf->build(
			Packet::CHUNKD,
			$x * 16,
			0,
			$z * 16,
			15,
			127, # TODO: World height.
			15,
			length($c),
			$c
		)
	);
}

sub unload_chunk {
	$_[0]->send(
		$::pf->build(
			Packet::CHUNK,
			$_[1],
			$_[2],
			0
		)
	);

	delete $_[0]->{'chunks_loaded'}->{$_[1].','.$_[2]};
}

sub kick {
	my ($self,$msg,$automated) = @_;

	if (!defined($automated)) {
		$::log->red(($self->{'runlevel'} >= HELLO ? $self->{'username'} : $self->{'socket'}->peerhost()) . ' was kicked!');
		$::srv->broadcast($self->{'displayname'} . '§c was kicked! ' . $msg);
	}

	$self->send(
		$::pf->build(
			Packet::QUIT,
			$msg
		)
	);

	$::sf->close($self->{'socket'});
}

sub teleport {
	my ($self,$x,$y,$y2,$z,$yaw,$pitch,$on_ground) = @_;
	
	$self->update_chunks($x,$z) if (defined($x) && defined($z));

	$self->{'entity'}->teleport($x,$y,$y2,$z,$yaw,$pitch,$on_ground);
}

sub load_entity_named {
	my ($self,$e) = @_;

	$self->send(
		$::pf->build(
			Packet::SPAWNN,
			$e->{'id'},
			$e->{'player'}->{'username'},
			$e->{'x'} * 32,
			$e->{'y'} * 32,
			$e->{'z'} * 32,
			($e->{'yaw'} % 360) / 360 * 255,
			($e->{'pitch'} % 360) / 360 * 255,
			0
		)
	);
}

sub set_gamemode {
	my ($self,$m) = @_;

	$self->{'gamemode'} = defined $m && ($m == 0 || $m == 1) ? $m : $::srv->{'gamemode'};

	$self->send(
		$::pf->build(
			Packet::STATE,
			3,
			$self->{'gamemode'}
		)
	);
}

1;
