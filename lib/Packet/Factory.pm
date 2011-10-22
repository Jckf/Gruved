#!/dev/null
package Packet::Factory;

use strict;
use warnings;
use Encode;
use Packet;

my (@types,@structures,@dynamic);

$types[Packet::RAW     ] = sub { $_[0]              };
$types[Packet::BOOL    ] = sub { chr($_[0] ? 1 : 0) };
$types[Packet::BYTE    ] = sub { chr($_[0])         };
$types[Packet::INT     ] = sub { pack('i>',$_[0])   };
$types[Packet::SHORT   ] = sub { pack('s>',$_[0])   };
$types[Packet::LONG    ] = sub { pack('q>',$_[0])   };
$types[Packet::FLOAT   ] = sub { pack('f>',$_[0])   };
$types[Packet::DOUBLE  ] = sub { pack('d>',$_[0])   };
$types[Packet::STRING16] = sub { pack('s>',length($_[0])) . encode('ucs-2be',$_[0]) };

@{$structures[Packet::PING    ]} = (Packet::INT);
@{$structures[Packet::LOGIN   ]} = (Packet::INT,Packet::STRING16,Packet::LONG,Packet::INT,Packet::BYTE,Packet::BYTE,Packet::BYTE,Packet::BYTE);
@{$structures[Packet::HELLO   ]} = (Packet::STRING16);
@{$structures[Packet::CHAT    ]} = (Packet::STRING16);
@{$structures[Packet::TIME    ]} = (Packet::LONG);
@{$structures[Packet::POSLOOK ]} = (Packet::DOUBLE,Packet::DOUBLE,Packet::DOUBLE,Packet::DOUBLE,Packet::FLOAT,Packet::FLOAT,Packet::BOOL);
@{$structures[Packet::SPAWNN  ]} = (Packet::INT,Packet::STRING16,Packet::INT,Packet::INT,Packet::INT,Packet::BYTE,Packet::BYTE,Packet::SHORT);
@{$structures[Packet::REMOVE  ]} = (Packet::INT);
@{$structures[Packet::TELEPORT]} = (Packet::INT,Packet::INT,Packet::INT,Packet::INT,Packet::BYTE,Packet::BYTE);
@{$structures[Packet::CHUNK   ]} = (Packet::INT,Packet::INT,Packet::BOOL);
@{$structures[Packet::CHUNKD  ]} = (Packet::INT,Packet::SHORT,Packet::INT,Packet::BYTE,Packet::BYTE,Packet::BYTE,Packet::INT,Packet::RAW);
@{$structures[Packet::SLOT    ]} = (Packet::BYTE,Packet::SHORT,Packet::SHORT);
@{$structures[Packet::LIST    ]} = (Packet::STRING16,Packet::BOOL,Packet::SHORT);
@{$structures[Packet::QUIT    ]} = (Packet::STRING16);

$dynamic[Packet::SLOT] = sub {
	if ($_[2] > -1) {
		return &{$types[Packet::BYTE]}($_[3]) . &{$types[Packet::SHORT]}($_[4]);
	}
};

sub new {
	my ($class) = @_;
	my $self = {};
	bless($self,$class);
}

sub build {
	my ($self,$id,@data) = @_;

	my $packet = &{$types[Packet::BYTE]}($id);
	$packet .= &{$types[$structures[$id][$_]]}($data[$_]) for (0 .. @{$structures[$id]} - 1);

	$packet .= &{$dynamic[$id]}(@data) if defined $dynamic[$id];

	return $packet;
}

1;
