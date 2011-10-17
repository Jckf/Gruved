#!/dev/null
package Block;

use strict;
use warnings;

sub new {
	my ($class,$type) = @_;
	my $self = [
		$type || 0,
		0,
		0xF,
		0xF
	];
	bless($self,$class);
}

1;
