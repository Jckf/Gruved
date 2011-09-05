#!/dev/null
use strict;
use warnings;
use IO::Select;
use IO::Socket::INET;
use Minecraft::Server::Events;

package Minecraft::Server::SocketFactory;

use Time::HiRes qw(sleep);

sub new {
	my ($class,%options) = @_;
	my $self = {};

	$self->{'port'} = 25565;
	$self->{'bind'} = '0.0.0.0';

	$self->{$_} = $options{$_} for keys %options;

	$self->{'events'} = Minecraft::Server::Events->new();

	bless($self,$class);
}

sub run {
	my ($self) = @_;

	$self->{'select'} = IO::Select->new();
	$self->{'listener'} = IO::Socket::INET->new(
		'Proto'		=> 'tcp',
		'LocalPort'	=> $self->{'port'},
		'LocalAddr'	=> $self->{'bind'},
		'Listen'	=> 5
	)or die($!);

	$self->{'select'}->add($self->{'listener'});

	while ($self->{'listener'}) {
		my @can_read = $self->{'select'}->can_read(0);
		sleep 0.01 if !@can_read;
		foreach my $socket (@can_read) {
			if (fileno($socket) == fileno($self->{'listener'})) {
				my $client = $socket->accept();
				$self->{'select'}->add($client);
				$self->{'events'}->trigger('accept',$client);
			} else {
				$self->{'events'}->trigger('can_read',$socket);
			}
		}
	}

	return 0;
}

sub broadcast {
	my ($self,$data,$exclude) = @_;

	my @sockets = $self->{'select'}->handles();
	foreach my $socket (@sockets) {
		next if ((defined $exclude && fileno($socket) == fileno($exclude)) || fileno($socket) == fileno($self->{'listener'}));
		print $socket ($data);
	}

	return 1;
}

sub close {
	my ($self,$socket) = @_;
	$self->{'select'}->remove($socket);
	$socket->close();
	return 1;
}

1;
