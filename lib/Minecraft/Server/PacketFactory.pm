#!/dev/null
package Minecraft::Server::PacketFactory;

use strict;
use warnings;
use Encode;

my %data_types = %{{
	'raw' => sub { $_[0] },
	'bool' => sub { chr($_[0] ? 1 : 0) },
	'byte' => sub { chr($_[0]) },
	'int' => sub { pack('i>',$_[0]) },
	'short' => sub { pack('s>',$_[0]) },
	'long' => sub { pack('q>',$_[0]) },
	'float' => sub { pack('f>',$_[0]) },
	'double' => sub { pack('d>',$_[0]) },
	'string16' => sub { pack('s>',length($_[0])) . encode('ucs-2be',$_[0]) }
}};

my %packet_structures = %{{
	0x00 => ['int'],
	0x01 => ['int','string16','long','int','byte','byte','byte','byte'],
	0x02 => ['string16'],
	0x03 => ['string16'],
	0x0D => ['double','double','double','double','float','float','bool'],
	0x32 => ['int','int','bool'],
	0x33 => ['int','short','int','byte','byte','byte','int','raw'],
	0xC9 => ['string16','bool','short'],
	0xFF => ['string16']
}};

sub new {
	my ($class) = @_;
	my $self = {};
	bless($self,$class);
}

sub build {
	my ($self,$packet_id,@data) = @_;

	my $packet = &{$data_types{'byte'}}($packet_id);
	$packet .= &{$data_types{$packet_structures{$packet_id}[$_]}}($data[$_]) foreach (keys(@data));

	return $packet;
}

1;
