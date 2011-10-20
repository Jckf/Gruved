#!/dev/null
package Packet::Parser;

use strict;
use warnings;
use Data::Dumper;
use Encode;
use Events;
use Packet;

use constant {
	FILTER => 0
};

my (@types,@structures,@dynamic);

$types[Packet::BOOL    ] = sub { sysread($_[0],my $data,1); ord($data) ? 1 : 0; };
$types[Packet::BYTE    ] = sub { sysread($_[0],my $data,1); ord($data);         };
$types[Packet::INT     ] = sub { sysread($_[0],my $data,4); unpack('i>',$data); };
$types[Packet::SHORT   ] = sub { sysread($_[0],my $data,2); unpack('s>',$data); };
$types[Packet::LONG    ] = sub { sysread($_[0],my $data,8); unpack('q>',$data); };
$types[Packet::FLOAT   ] = sub { sysread($_[0],my $data,4); unpack('f>',$data); };
$types[Packet::DOUBLE  ] = sub { sysread($_[0],my $data,8); unpack('d>',$data); };
$types[Packet::STRING16] = sub {
	sysread($_[0],my $length,2);
	sysread($_[0],my $data,unpack('s>',$length) * 2);
	decode('ucs-2be',$data);
};

@{$structures[Packet::PING    ]} = (Packet::INT);
@{$structures[Packet::LOGIN   ]} = (Packet::INT,Packet::STRING16,Packet::LONG,Packet::INT,Packet::BYTE,Packet::BYTE,Packet::BYTE,Packet::BYTE);
@{$structures[Packet::HELLO   ]} = (Packet::STRING16);
@{$structures[Packet::CHAT    ]} = (Packet::STRING16);
@{$structures[Packet::USE     ]} = (Packet::INT,Packet::INT,Packet::BOOL);
@{$structures[Packet::RESPAWN ]} = (Packet::BYTE,Packet::BYTE,Packet::BYTE,Packet::SHORT,Packet::LONG);
@{$structures[Packet::GROUND  ]} = (Packet::BOOL);
@{$structures[Packet::POSITION]} = (Packet::DOUBLE,Packet::DOUBLE,Packet::DOUBLE,Packet::DOUBLE,Packet::BOOL);
@{$structures[Packet::LOOK    ]} = (Packet::FLOAT,Packet::FLOAT,Packet::BOOL);
@{$structures[Packet::POSLOOK ]} = (Packet::DOUBLE,Packet::DOUBLE,Packet::DOUBLE,Packet::DOUBLE,Packet::FLOAT,Packet::FLOAT,Packet::BOOL);
@{$structures[Packet::DIG     ]} = (Packet::BYTE,Packet::INT,Packet::BYTE,Packet::INT,Packet::BYTE);
@{$structures[Packet::PLACE   ]} = (Packet::INT,Packet::BYTE,Packet::INT,Packet::BYTE,Packet::SHORT);
@{$structures[Packet::SELECT  ]} = (Packet::SHORT);
@{$structures[Packet::ANIMATE ]} = (Packet::INT,Packet::BYTE);
@{$structures[Packet::ACTION  ]} = (Packet::INT,Packet::BYTE);
@{$structures[Packet::CLOSE   ]} = (Packet::BYTE);
@{$structures[Packet::CLICK   ]} = (Packet::BYTE,Packet::SHORT,Packet::BYTE,Packet::SHORT,Packet::BOOL,Packet::SHORT,Packet::BYTE,Packet::SHORT);
@{$structures[Packet::STATUS  ]} = ();
@{$structures[Packet::QUIT    ]} = ();

$dynamic[Packet::PLACE] = sub {
	if ($_[5] >= 0) {
		push(@_,&{$types[Packet::BYTE]}($_[0]));
		push(@_,&{$types[Packet::SHORT]}($_[0]));
	}
	shift;
	return @_;
};

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

	sysread($socket,my $id,1) or return 0;
	$id = ord($id);

	if (defined($structures[$id])) {
		my @data;
		foreach my $type (@{$structures[$id]}) {
			push(@data,&{$types[$type]}($socket));
		}
		if (defined($dynamic[$id])) {
			@data = &{$dynamic[$id]}($socket,@data);
		}

		my $e = $self->{'events'}->trigger(FILTER,$socket,$id,@data);
		if ($e->{'cancelled'}) {
			$self->{'error'} = 'Packet 0x' . uc(unpack('H*',chr($id))) . ' was denied by filter.';
			return -1;
		}

		$self->{'events'}->trigger($id,$socket,@data);

		return 1;
	}

	$self->{'error'} = 'Invalid packet 0x' . uc(unpack('H*',chr($id))) . '.';

	return -1;
}

1;
