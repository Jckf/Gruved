#!/dev/null
package PacketParser;

use strict;
use warnings;
use Encode;
use Events;
use Packet;

my @types = [
	Packet::BOOL     => sub { sysread($_[0],my $data,1); ord($data) ? 1 : 0; },
	Packet::BYTE     => sub { sysread($_[0],my $data,1); ord($data); },
	Packet::INT      => sub { sysread($_[0],my $data,4); unpack('i>',$data); },
	Packet::SHORT    => sub { sysread($_[0],my $data,2); unpack('s>',$data); },
	Packet::LONG     => sub { sysread($_[0],my $data,8); unpack('q>',$data); },
	Packet::FLOAT    => sub { sysread($_[0],my $data,4); unpack('f>',$data); },
	Packet::DOUBLE   => sub { sysread($_[0],my $data,8); unpack('d>',$data); },
	Packet::STRING16 => sub {
		sysread($_[0],my $length,2);
		sysread($_[0],my $data,unpack('s>',$length) * 2);
		decode('ucs-2be',$data);
	}
];

my @structures = [
	Packet::PING     => [Packet::INT],
	Packet::LOGIN    => [Packet::INT,'string16','long',Packet::INT,'byte','byte','byte','byte'],
	Packet::HELLO    => ['string16'],
	Packet::CHAT     => ['string16'],
	Packet::USE      => [Packet::INT,Packet::INT,'bool'],
	Packet::RESPAWN  => ['byte','byte','byte','short','long'],
	Packet::GROUND   => ['bool'],
	Packet::POSITION => ['double','double','double','double','bool'],
	Packet::LOOK     => ['float','float','bool'],
	Packet::POSLOOK  => ['double','double','double','double','float','float','bool'],
	Packet::DIG      => ['byte',Packet::INT,'byte',Packet::INT,'byte'],
	Packet::PLACE    => [Packet::INT,'byte',Packet::INT,'byte','short'],
	Packet::SELECT   => ['short'],
	Packet::ANIMATE  => [Packet::INT,'byte'],
	Packet::ACTION   => [Packet::INT,'byte'],
	Packet::CLOSE    => ['byte'],
	Packet::CLICK    => ['byte','short','byte','short','bool','short','byte','short'],
	Packet::STATUS   => [],
	Packet::QUIT     => []
];

my @dynamic = [
	Packet::PLACE => sub {
		if ($_[5] >= 0) {
			push(@_,&{$data_types{'byte'}}($_[0]));
			push(@_,&{$data_types{'short'}}($_[0]));
		}
		shift;
		return @_;
	}
];

sub new {
	my ($object) = @_;
	my $self = {};

	$self->{'events'} = Events->new();
	$self->{'error'} = '';

	bless($self,$object);
}

sub bind {
	$_[0]->{'events'}->bind($_[1],$_[2]);
}

sub parse {
	my ($self,$socket) = @_;

	sysread($socket,my $packet_id,1) or return 0;
	$packet_id = ord($packet_id);

	if (defined($packet_structures{$packet_id})) {
		my @data;
		foreach my $data_type (@{$packet_structures{$packet_id}}) {
			push(@data,&{$data_types{$data_type}}($socket));
		}
		if (defined($dynamic_structures{$packet_id})) {
			@data = &{$dynamic_structures{$packet_id}}($socket,@data);
		}

		my $e = $self->{'events'}->trigger('filter',$socket,$packet_id,@data);
		if ($e->{'cancelled'}) {
			$self->{'error'} = 'Packet 0x' . unpack('H*',chr($packet_id)) . ' was denied by filter.';
			return -1;
		}

		$self->{'events'}->trigger($packet_id,$socket,@data);

		return 1;
	}

	$self->{'error'} = 'Invalid packet 0x' . unpack('H*',chr($packet_id)) . '.';

	return -1;
}

1;
