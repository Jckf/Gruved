#!/dev/null
package Logger;

use strict;
use warnings;
use Term::ANSIScreen qw(:all);
use Scalar::Util qw(blessed);

BEGIN {
	if ($^O eq 'MSWin32') {
		require Win32::Console::ANSI;
	}
}

our $AUTOLOAD;

sub new {
	my ($class) = @_;
	my $self = {};
	
	#Initialize "background fix" for non-black terminals
	$self->{'bgcolor'}='black'; #<< Change here for testing
	print color ('on_'.$self->{'bgcolor'});
	cldown();
	print color ('reset');
	
	bless($self,$class);
}

sub header {
	print color ('on_'.$_[0]->{'bgcolor'}.' reverse');
	my $first = ' ' x (39 - length($_[1]) / 2) . $_[1];
	print $first . ' ' x (79 - length($first));
	print color ('reset');
	print "\n";
}

sub log {
	my ($self,$data1,$data2) = @_;

	my ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) = localtime();

	print color ('on_'.$self->{'bgcolor'}.' bold yellow');
	print
		#'' . (1900 + $year) . '/' .
		#sprintf('%02s',$mon) . '/' .
		#sprintf('%02s',$mday) . ' ' .
		sprintf('%02s',$hour) . ':' .
		sprintf('%02s',$min) . '.' .
		sprintf('%02s',$sec) . ' '
	;

	if (defined($data2)) {
		print color ('on_'.$self->{'bgcolor'}.' '.$data2);
	} else {
		print color ('on_'.$self->{'bgcolor'}.'reset');
	}

	print $data1;

	print color ('reset');

	print "\n";
}

sub AUTOLOAD {
	my ($self,$data) = @_;

	my $c = uc $AUTOLOAD;
	$c =~ s/.*://;

	$self->log($data,$c) if $c ne 'DESTROY';
}

sub DESTROY {
	print color ('reset');
	cldown();
}

1;
