#!/dev/null
package Entity;

use strict;
use warnings;

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
	$self->{'on_ground'} = 1;

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

	$self->{'chunk_x'} = int($self->{'x'} / 16);
	$self->{'chunk_z'} = int($self->{'z'} / 16);

	$self->{'chunk_x'}-- if $self->{'x'} < 0;
	$self->{'chunk_y'}-- if $self->{'y'} < 0;
}

1;
