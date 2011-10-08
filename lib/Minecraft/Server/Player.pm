#!/dev/null
package Minecraft::Server::Player;

use strict;
use warnings;

sub new {
	my ($class,%options) = @_;
	my $self = {};

	$self->{'runlevel'} = 0;
	$self->{'keepalive'} = time();
	$self->{'latency'} = 0;

	$self->{'username'} = '';
	$self->{'displayname'} = '';

	$self->{'gamemode'} = 0;
	$self->{'dimension'} = 0;
	$self->{'difficulty'} = 0;

	$self->{$_} = $options{$_} for keys %options;

	bless($self,$class);
}

sub send {
	my ($self,@data) = @_;

	foreach (@data) {
		syswrite($self->{'socket'},$_);
	}
}

sub ping {
	my ($self) = @_;
	$self->send(
		$::pf->build(
			0x00,
			0
		)
	);
}

sub message {
	my ($self,$msg) = @_;

	$self->send(
		$::pf->build(
			0x03,
			$msg
		)
	);
}

sub set_time {
	$_[0]->send(
		$::pf->build(
			0x04,
			$_[1]
		)
	);
}

sub update_position {
	my ($self) = @_;

	$self->send(
		$::pf->build(
			0x0D,
			$self->{'entity'}->{'x'},
			$self->{'entity'}->{'y2'},
			$self->{'entity'}->{'y'},
			$self->{'entity'}->{'z'},
			$self->{'entity'}->{'yaw'},
			$self->{'entity'}->{'pitch'},
			$self->{'entity'}->{'on_ground'}
		)
	);
}

sub kick {
	my ($self,$msg,$automated) = @_;

	$::logger->log('red',($self->{'runlevel'} >= 1 ? $self->{'username'} : 'x.x.x.x:x') . ' was kicked!') if !defined($automated);

	$self->send(
		$::pf->build(
			0xFF,
			$msg
		)
	);

	$::sf->close($self->{'socket'});
}

sub teleport {
	my ($self,$x,$y,$y2,$z,$yaw,$pitch,$on_ground) = @_;
	$self->{'entity'}->teleport($x,$y,$y2,$z,$yaw,$pitch,$on_ground);
}

1;
