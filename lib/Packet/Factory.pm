#!/dev/null
package Packet::Factory;

use strict;
use warnings;
use Encode;
use Packet;

my @types = [
	Packet::RAW      => sub { $_[0] },
	Packet::BOOL     => sub { chr($_[0] ? 1 : 0) },
	Packet::BYTE     => sub { chr($_[0]) },
	Packet::INT      => sub { pack('i>',$_[0]) },
	Packet::SHORT    => sub { pack('s>',$_[0]) },
	Packet::LONG     => sub { pack('q>',$_[0]) },
	Packet::FLOAT    => sub { pack('f>',$_[0]) },
	Packet::DOUBLE   => sub { pack('d>',$_[0]) },
	Packet::STRING16 => sub { pack('s>',length($_[0])) . encode('ucs-2be',$_[0]) }
];

my @structures = [
	Packet::PING     => [Packet::INT],
	Packet::LOGIN    => [Packet::INT,Packet::STRING16,Packet::LONG,Packet::INT,Packet::BYTE,Packet::BYTE,Packet::BYTE,Packet::BYTE],
	Packet::HELLO    => [Packet::STRING16],
	Packet::CHAT     => [Packet::STRING16],
	Packet::TIME     => [Packet::LONG],
	Packet::POSITION => [Packet::DOUBLE,Packet::DOUBLE,Packet::DOUBLE,Packet::DOUBLE,Packet::FLOAT,Packet::FLOAT,Packet::BOOL],
	Packet::SPAWNN   => [Packet::INT,Packet::STRING16,Packet::INT,Packet::INT,Packet::INT,Packet::BYTE,Packet::BYTE,Packet::SHORT],
	Packet::DESTROY  => [Packet::INT],
	Packet::TELEPORT => [Packet::INT,Packet::INT,Packet::INT,Packet::INT,Packet::BYTE,Packet::BYTE],
	Packet::CHUNK    => [Packet::INT,Packet::INT,Packet::BOOL],
	Packet::CHUNKD   => [Packet::INT,Packet::SHORT,Packet::INT,Packet::BYTE,Packet::BYTE,Packet::BYTE,Packet::INT,Packet::RAW],
	Packet::LIST     => [Packet::STRING16,String::BOOL,String::SHORT],
	Packet::QUIT	 => [Packet::STRING16]
];

sub new {
	my ($class) = @_;
	my $self = {};
	bless($self,$class);
}

sub build {
	my ($self,$id,@data) = @_;

	my $packet = &{$types[Packet::BYTE]}($id);
	$packet .= &{$types[$structures[$id][$_]]}($data[$_]) for (0 .. @data - 1);

	return $packet;
}

1;
