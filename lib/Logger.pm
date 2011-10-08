#!/dev/null
package Logger;

use strict;
use warnings;
use Term::ANSIColor;

BEGIN {
	if ($^O eq 'MSWin32') {
		require Win32::Console::ANSI;
	}
}

sub new {
	my ($class) = @_;
	my $self = {};

	$self->{'level'} = 1;

	bless($self,$class);
}

sub _log {
	my ($self,$level,$data1,$data2) = @_;

	if ($level <= $self->{'level'}) {
		my ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) = localtime();

		print color ('bold yellow');
		print
			'' . (1900 + $year) . '/' .
			sprintf('%02s',$mon) . '/' .
			sprintf('%02s',$mday) . ' ' .
			sprintf('%02s',$hour) . ':' .
			sprintf('%02s',$min) . '.' .
			sprintf('%02s',$sec) . ' '
		;

		if (defined($data2)) {
			print color ($data1);
			$data1 = $data2;
		}

		print $data1 . "\n";

		print color ('reset');
	}
}

sub log {
	my ($self,$data1,$data2) = @_;
	$self->_log(1,$data1,$data2);
}

sub center {
	print color ('black on_white');
	my $first = ' ' x ((80 - length($_[1])) / 2) . $_[1];
	print $first . ' ' x (80 - length($first));
	print color ('reset');
}

1;
