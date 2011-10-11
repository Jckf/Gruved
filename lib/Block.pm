#!/dev/null
package Block;

use strict;
use warnings;

sub new {
	my ($class,$type) = @_;
	my $self = {};

	$self->{'type'} = $type || 0;
	#$self->{'data'} = 0;
	#$self->{'light'} = 0;
	#$self->{'skylight'} = 0;

	bless($self,$class);
}

1;
