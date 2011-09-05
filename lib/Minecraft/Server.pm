#!/dev/null
use strict;
use warnings;
use Minecraft::Server::Events;
use Minecraft::Server::SocketFactory;
use Minecraft::Server::PacketParser;
use Minecraft::Server::PacketFactory;

package Minecraft::Server;

use Compress::Zlib;

sub new {
	my ($class) = @_;

	my $self = {
		'clients' => {},
		'dimensions' => {},

		'events' => Minecraft::Server::Events->new(),
		'socketfactory' => Minecraft::Server::SocketFactory->new(),
		'packetparser' => Minecraft::Server::PacketParser->new(),
		'packetfactory' => Minecraft::Server::PacketFactory->new(),

		'view_distance' => 10
	};

	$self->{'events'}->bind('disconnect',sub { $self->{'socketfactory'}->close($_[0]) });

	bless($self,$class);
}

sub run {
	my ($self) = @_;

	$self->{'socketfactory'}->{'events'}->bind('accept',sub {
		# Initialize some data.
		%{$self->{'clients'}->{fileno($_[0])}} = %{{
			'keepalive' => time(),

			'x' => 0,
			'y' => 10,
			'y2' => 11.6,
			'z' => 0,

			'cx' => 0,
			'cz' => 0,

			'yaw' => 0,
			'pitch' => 0
		}};
	});

	$self->{'socketfactory'}->{'events'}->bind('can_read',sub {
		my ($socket) = @_;

		$self->{'packetparser'}->parse($_[0]) or return $self->{'events'}->trigger('disconnect',$_[0]);

		# This might be an expensive check. I don't know. It'll be okay for now =P
		if (time() - $self->{'clients'}->{fileno($socket)}{'keepalive'} >= 10) {
			print $socket ($self->{'packetfactory'}->build(0x00));
			$self->{'clients'}->{fileno($socket)}{'keepalive'} = time();
		}
	});

	$self->{'packetparser'}->{'events'}->bind('filter',sub {
		my ($socket,$packet_id,@data) = @_;

		# If it's not a handshake, and we haven't reveived one before.
		return 0 if $packet_id != 0x02 && !defined $self->{'clients'}->{fileno($socket)}{'handshake'};

		# If it's not a login request (or handshake) and we haven't received one before.
		return 0 if $packet_id > 0x02 && !defined $self->{'clients'}->{fileno($socket)}{'username'};

		return 1;
	});

	# Client login request.
	$self->{'packetparser'}->{'events'}->bind(0x01,sub {
		my ($socket,$protocol,$username,$seed,$dimension) = @_;

		$self->{'clients'}->{fileno($socket)}{'username'} = $username;

		print $socket ($self->{'packetfactory'}->build(
			0x01,
			fileno($socket),
			'',
			0,
			0
		));

		# TODO: Load previous coordinates.
		#$self->{'clients'}->{fileno($socket)}{'cx'} = int($self->{'clients'}->{fileno($socket)}{'x'} / 16);
		#$self->{'clients'}->{fileno($socket)}{'cz'} = int($self->{'clients'}->{fileno($socket)}{'z'} / 16);

		print $socket ($self->{'packetfactory'}->build(
			0x0D,
			$self->{'clients'}->{fileno($socket)}{'x'},
			$self->{'clients'}->{fileno($socket)}{'y2'},
			$self->{'clients'}->{fileno($socket)}{'y'},
			$self->{'clients'}->{fileno($socket)}{'z'},
			$self->{'clients'}->{fileno($socket)}{'yaw'},
			$self->{'clients'}->{fileno($socket)}{'pitch'},
			$self->{'clients'}->{fileno($socket)}{'grounded'}
		));

		$self->{'clients'}->{fileno($socket)}{'keepalive'} = 0;
	});

	# Client handshake.
	$self->{'packetparser'}->{'events'}->bind(0x02,sub {
		my ($socket,$username) = @_;

		$self->{'clients'}->{fileno($socket)}{'handshake'} = 1;

		print $socket ($self->{'packetfactory'}->build(
			0x02,
			'-'
		));
	});

	# Chatter.
	$self->{'packetparser'}->{'events'}->bind(0x03,sub {
		my ($socket,$message) = @_;
		# TODO: Parse and filter message.
		$self->{'socketfactory'}->broadcast($self->{'packetfactory'}->build(
			0x03,
			$self->{'clients'}->{fileno($socket)}{'username'} . ': ' . $message
		));
	});

	# Player movement.
	$self->{'packetparser'}->{'events'}->bind(0x0B,sub {
		my ($socket,$x,$y,$y2,$z,$grounded) = @_;

		# TODO: Validate movement.
		#		Tell the others about the move.

		# EVERYTHING BELOW HERE IS CODE FOR LOADING AND UNLOADING
		# CHUNKS AROUND THE PLAYER. IT WILL ONLY BE EXECUTED IF
		# THE PLAYER MOVES FROM ONE CHUNK TO ANOTHER, SO DON'T
		# WRITE ANYTHING BELOW HERE UNLESS THAT'S WHAT YOU WANT!
		my ($ccx,$ccz) = (int($x / 16),int($z / 16));
		$ccx-- if $x < 0;
		$ccz-- if $z < 0;
		return if $self->{'clients'}->{fileno($socket)}{'cx'} == $ccx && $self->{'clients'}->{fileno($socket)}{'cz'} == $ccz && defined $self->{'clients'}->{fileno($socket)}{'chunks'}{$ccx}{$ccz};
		$self->{'clients'}->{fileno($socket)}{'cx'} = $ccx;
		$self->{'clients'}->{fileno($socket)}{'cz'} = $ccz;

		my %needed;
		foreach my $cx ($ccx - $self->{'view_distance'} .. $ccx + $self->{'view_distance'}) {
			foreach my $cz ($ccz - $self->{'view_distance'} .. $ccz + $self->{'view_distance'}) {
				$needed{$cx}{$cz} = 1;
				next if defined $self->{'clients'}->{fileno($socket)}{'chunks'}{$cx}{$cz};

				# Build a new chunk.
				if (!defined($self->{'dimensions'}->{0}{$cx}{$cz})) {
					my @layers = (7,1,3,2);
					$self->{'dimensions'}->{0}{$cx}{$cz} = chr(0) x (16 * 16 * 128);
					foreach my $lx (0..15) {
						foreach my $lz (0..15) {
							foreach my $ly (0..@layers - 1) {
								my $index = ($ly + abs($cx) + abs($cz)) + ($lz * 128) + ($lx * 128 * 16);
								$self->{'dimensions'}->{0}{$cx}{$cz} =
									substr($self->{'dimensions'}->{0}{$cx}{$cz},0,$index) .
									chr($layers[$ly]) .
									substr($self->{'dimensions'}->{0}{$cx}{$cz},$index + 1)
								;
							}
						}
					}
				}

				$self->{'clients'}->{fileno($socket)}{'chunks'}{$cx}{$cz} = 1;
				print $socket ($self->{'packetfactory'}->build(
					0x32,
					$cx,
					$cz,
					1
				));

				my $zlib = deflateInit();
				my $chunk = $zlib->deflate(
					$self->{'dimensions'}->{0}{$cx}{$cz} .
					(chr(0x00) x (length($self->{'dimensions'}->{0}{$cx}{$cz}) / 2)) .
					(chr(0xFF) x length($self->{'dimensions'}->{0}{$cx}{$cz}))
				);
				$chunk .= $zlib->flush();

				print $socket ($self->{'packetfactory'}->build(
					0x33,
					$cx * 16,
					0,
					$cz * 16,
					15,
					127,
					15,
					length($chunk),
					$chunk
				));
			}
		}

		# Looping again to find out if the chunk is needed might be a bad idea.
		foreach my $cx (keys(%{$self->{'clients'}->{fileno($socket)}{'chunks'}})) {
			foreach my $cz (keys(%{$self->{'clients'}->{fileno($socket)}{'chunks'}{$cx}})) {
				if (!defined($needed{$cx}{$cz})) {
					delete $self->{'clients'}->{fileno($socket)}{'chunks'}{$cx}{$cz};
					print $socket ($self->{'packetfactory'}->build(
						0x32,
						$cx,
						$cz,
						0
					));
				}
			}
		}
	});

	# Player looking around.
	$self->{'packetparser'}->{'events'}->bind(0x0C,sub {
		my ($socket,$yaw,$pitch,$grounded) = @_;
	});

	# Player moving and looking.
	$self->{'packetparser'}->{'events'}->bind(0x0D,sub {
		my ($socket,$x,$y,$y2,$z,$yaw,$pitch,$grounded) = @_;
		$self->{'packetparser'}->{'events'}->trigger(0x0B,$socket,$x,$y,$y2,$z,$grounded);
		$self->{'packetparser'}->{'events'}->trigger(0x0C,$socket,$yaw,$pitch,$grounded);
	});

	return $self->{'socketfactory'}->run();
}

1;
