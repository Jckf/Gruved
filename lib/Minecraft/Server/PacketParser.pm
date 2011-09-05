#!/dev/null
use strict;
use warnings;
use Minecraft::Server::Events;

package Minecraft::Server::PacketParser;

use Encode;

my %data_types = %{{
	'bool' => sub {
		sysread($_[0],my $data,1);
		return ord($data) ? 1 : 0;
	},
	'byte' => sub {
		sysread($_[0],my $data,1);
		return ord($data);
	},
	'int' => sub {
		sysread($_[0],my $data,4);
		return unpack('i>',$data);
	},
	'short' => sub {
		sysread($_[0],my $data,2);
		return unpack('s>',$data);
	},
	'long' => sub {
		sysread($_[0],my $data,8);
		return unpack('q>',$data);
	},
	'float' => sub {
		sysread($_[0],my $data,4);
		return unpack('f>',$data);
	},
	'double' => sub {
		sysread($_[0],my $data,8);
		return unpack('d>',$data);
	},
	'string16' => sub {
		sysread($_[0],my $length,2);
		$length = unpack('s>',$length);
		sysread($_[0],my $data,$length * 2);
		return decode('ucs-2be',$data);
	}
}};

my %packet_structures = %{{
	0x00 => [],
	0x01 => ['int','string16','long','byte'],
	0x02 => ['string16'],
	0x03 => ['string16'],
	0x0A => ['byte'],
	0x0B => ['double','double','double','double','bool'],
	0x0C => ['float','float','bool'],
	0x0D => ['double','double','double','double','float','float','bool']
}};

sub new {
	my ($object) = @_;
	my $self = { 'events' => Minecraft::Server::Events->new() };
	bless($self,$object);
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

		my @filters = $self->{'events'}->trigger('filter',$socket,$packet_id,@data);
		foreach my $filter (@filters) {
			return 0 if !$filter;
		}

		$self->{'events'}->trigger($packet_id,$socket,@data);

		return 1;
	}

	return 0;
}

1;
