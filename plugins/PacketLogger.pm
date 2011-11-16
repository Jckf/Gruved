#!/dev/null
package PacketLogger;

use IO::File;
use Packet::Parser;

my @packets;
$packets[0x00] = 'PING';
$packets[0x01] = 'LOGIN';
$packets[0x02] = 'HELLO';
$packets[0x03] = 'CHAT';
$packets[0x04] = 'TIME';
$packets[0x07] = 'USE';
$packets[0x09] = 'RESPAWN';
$packets[0x0A] = 'GROUND';
$packets[0x0B] = 'POSITION';
$packets[0x0C] = 'LOOK';
$packets[0x0D] = 'POSLOOK';
$packets[0x0E] = 'DIG';
$packets[0x0F] = 'PLACE';
$packets[0x10] = 'SELECT';
$packets[0x12] = 'ANIMATE';
$packets[0x13] = 'ACTION';
$packets[0x14] = 'SPAWNN';
$packets[0x17] = 'OBJECT';
$packets[0x1D] = 'REMOVE';
$packets[0x22] = 'TELEPORT';
$packets[0x32] = 'CHUNK';
$packets[0x33] = 'CHUNKD';
$packets[0x35] = 'BLOCK';
$packets[0x46] = 'STATE';
$packets[0x65] = 'CLOSE';
$packets[0x66] = 'CLICK';
$packets[0x67] = 'SLOT';
$packets[0x6B] = 'CREATIVE';
$packets[0x82] = 'SIGN';
$packets[0xC9] = 'LIST';
$packets[0xFE] = 'STATUS';
$packets[0xFF] = 'QUIT';

sub new {
	my ($class) = @_;
	my $self = {};

	bless($self,$class);

	$self->open() and $::pp->bind(Packet::Parser::FILTER,sub { $self->recv(@_) });

	return $self;
}

sub recv {
	my ($self,$e,$s,$p,@data) = @_;

	my $data = join(', ',@data);
	$data =~ s/(\d+)\.(\d{3})\d+/$1.$2/g;

	$self->{'file'}->printf("%20s 0x%02X %10s %s\n",$::srv->get_player($s)->{'username'},$p,$packets[$p] || 'UNKNOWN!',$data);
}

sub open {
	my ($self) = @_;

	$self->{'file'} = IO::File->new('packets.log',O_CREAT|O_WRONLY|O_APPEND);
	if (!$self->{'file'}) {
		$::log->red('PacketLogger failed to open packets.log for writing: ' . $!);
		return;
	}
	return 1;
}

sub close {
	my ($self) = @_;
	$self->{'file'}->close();
	delete $self->{'file'};
}

sub DESTROY {
	$self->close();
}

1;
