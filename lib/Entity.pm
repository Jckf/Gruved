#!/dev/null
package Entity;

use strict;
use warnings;

use constant {
	CROUCH => 1,
	UNCROUCH => 2
};

sub new {
	my ($class,%options) = @_;
	my $self = {};

	$self->{'id'} = 0;
	$self->{'name'} = '';

	$self->{'x'} = 0;
	$self->{'y'} = 70;
	$self->{'y2'} = $self->{'y'} + 1.62;
	$self->{'z'} = 0;
	$self->{'yaw'} = 0;
	$self->{'pitch'} = 0;
	$self->{'on_ground'} = 0;
	$self->{'crouching'} = 0;

	$self->{$_} = $options{$_} for keys %options;

	bless($self,$class);
}

sub teleport {
	my ($self,$x,$y,$y2,$z,$yaw,$pitch,$on_ground) = @_;

	$self->{'x'} = $x if defined $x;
	$self->{'y'} = $y if defined $y;
	$self->{'y2'} = $y2 if defined $y2;
	$self->{'z'} = $z if defined $z;

	$self->{'yaw'} = $yaw if defined $yaw;
	$self->{'pitch'} = $pitch if defined $pitch;

	$self->{'on_ground'} = $on_ground if defined $on_ground;

	foreach my $p ($::srv->get_players()) {
		if ($self->{'id'} != $p->{'entity'}->{'id'} && $p->{'entity'}->{'world'}->{'name'} eq $self->{'world'}->{'name'}) {
			$p->send(
				$::pf->build(
					Packet::TELEPORT,
					$self->{'id'},
					$self->{'x'} * 32,
					$self->{'y'} * 32,
					$self->{'z'} * 32,
					($self->{'yaw'} % 360) / 360 * 255,
					($self->{'pitch'} % 360) / 360 * 255
				)
			);
		}
	}
}

1;
