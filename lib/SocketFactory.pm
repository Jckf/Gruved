#!/dev/null
package SocketFactory;

use strict;
use warnings;
use Time::HiRes 'sleep';
use IO::Select;
use IO::Socket::INET;
use Events;

use constant {
	TICK      => 0,
	ACCEPT    => 1,
	READ      => 2,
	EXCEPTION => 3,
	CLOSE     => 4
};

$SIG{'PIPE'} = 'IGNORE';

sub new {
	my ($class,%options) = @_;
	my $self = {};

	$self->{'port'} = 25565;
	$self->{'bind'} = '0.0.0.0';

	$self->{$_} = $options{$_} for keys %options;

	$self->{'events'} = Events->new();

	bless($self,$class);
}

sub bind {
	$_[0]->{'events'}->bind($_[1],$_[2]);
}

sub run {
	my ($self) = @_;

	$self->{'select'} = IO::Select->new();
	$self->{'listener'} = IO::Socket::INET->new(
		'Proto'	    => 'tcp',
		'LocalPort' => $self->{'port'},
		'LocalAddr' => $self->{'bind'},
		'Listen'    => 5
	)or die($!);

	$self->{'select'}->add($self->{'listener'});

	while ($self->{'listener'}) {
		my @sockets = $self->{'select'}->can_read(0) or sleep 0.01;
		foreach my $socket (@sockets) {
			if (fileno($socket) == fileno($self->{'listener'})) {
				my $client = $socket->accept();
				$self->{'select'}->add($client);
				$self->{'events'}->trigger(ACCEPT,$client);
			} else {
				$self->{'events'}->trigger(READ,$socket)
			}
		}
		$self->{'events'}->trigger(TICK);
	}

	return 0;
}

sub close {
	my ($self,$socket) = @_;
	$self->{'events'}->trigger(CLOSE,$socket);
	$self->{'select'}->remove($socket);
	$socket->close();
	return 1;
}

1;
