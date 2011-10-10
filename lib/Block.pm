#!/dev/null
package Block;

use strict;
use warnings;

sub new {
	my ($class,%options) = @_;
	my $self = {};

	$self->{'type'} = 0;
	$self->{'data'} = 0;
	$self->{'light'} = 0xF;
	$self->{'skylight'} = 0xF;

	$self->{$_} = $options{$_} for keys %options;

	bless($self,$class);
}

1;
