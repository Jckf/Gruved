#!/dev/null
package Minecraft::Server::SocketFactory;

use strict;
use warnings;
use Time::HiRes 'sleep';
use IO::Select;
use IO::Socket::INET;
use Events;

sub new {
	my ($class,%options) = @_;
	my $self = {};

	$self->{'port'} = 25565;
	$self->{'bind'} = '0.0.0.0';

	$self->{$_} = $options{$_} for keys %options;

	$self->{'events'} = Events->new();

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
		my $loops = 0;
		foreach my $socket ($self->{'select'}->has_exception(0)) {
			$loops++;
			if (fileno($socket) == fileno($self->{'listener'})) {
				undef $self->{'listener'};
			} else {
				$self->{'events'}->trigger('has_exception',$socket);
				$self->close($socket);
			}
		}
		foreach my $socket ($self->{'select'}->can_read(0)) {
			$loops++;
			if (fileno($socket) == fileno($self->{'listener'})) {
				my $client = $socket->accept();
				$self->{'select'}->add($client);
				$self->{'events'}->trigger('accept',$client);
			} else {
				foreach my $result ($self->{'events'}->trigger('can_read',$socket)) {
					if (!$result) {
						next;
					}
				}
			}
		}
		$self->{'events'}->trigger('tick');
		sleep 0.01 if !$loops;
	}

	return 0;
}

sub close {
	my ($self,$socket) = @_;
	$self->{'events'}->trigger('close',$socket);
	$self->{'select'}->remove($socket);
	$socket->close();
	return 1;
}

1;
