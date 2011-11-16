#!/dev/null
package Logger;

use strict;
use warnings;
use Term::ANSIScreen qw(:all);
use Text::Wrap qw(wrap);
use List::Util qw(min);

our $have_tsize;
BEGIN {
	local $@;
	eval {
		require Term::Size::Any;
		Term::Size::Any->import(qw(chars));
		1;
	} and $have_tsize=1;
}

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
	
	$self->{'stampsize'}=9;
	$self->{'termsize'}=min(80,((scalar($have_tsize ? chars() : 9001) || 9001))); #It's complicated in case chars() returns 0, so that in that case, wrapping still works to 80-char width
	$Text::Wrap::columns=$self->{'termsize'} - $self->{'stampsize'};
	if ($self->{'termsize'} < 20+$self->{'stampsize'}) {
		die "Terminal too small!\n";
	}
	
	$self->{'last_u_length'}=0;
	
	bless($self,$class);
}

sub header { #DEPRECATED! use $::log->bc_reverse() instead
	my ($self,$message)=@_;
	warn 'header() is deprecated. Use bc_reverse() instead' unless $self->{'annoying_message'};
	$self->{'annoying_message'}=1;
	return $self->bc_reverse($message);
	print color ('on_'.$self->{'bgcolor'}.' reverse');
	my $first = ' ' x (39 - length($message) / 2) . $message;
	print $first . ' ' x (79 - length($first));
	print color ('reset');
	print "\n";
}

sub log {
	my ($self,$message,$color,$isBare,$isCROnly) = @_;
	local $Text::Wrap::columns=$self->{'termsize'} if $isBare;
	my ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) = localtime();

	if (!$isBare) {
		print color ('on_'.$self->{'bgcolor'}.' bold yellow');
		print
			#'' . (1900 + $year) . '/' .
			#sprintf('%02s',$mon) . '/' .
			#sprintf('%02s',$mday) . ' ' .
			sprintf('%02s',$hour) . ':' .
			sprintf('%02s',$min) . '.' .
			sprintf('%02s',$sec) . ' '
		;
	}

	my @lines=split /\n/,wrap('','',$message);
	
	my $n=0;
	foreach (@lines) {
		print ' ' x $self->{'stampsize'} if $n++ != 0 && !$isBare;
		if (defined($color)) {
			print color ('reset on_'.$self->{'bgcolor'}.(lc($color) =~ 'reverse' ? ' ' : ' bold ').$color);
		} else {
			print color ('reset on_'.$self->{'bgcolor'});
		}
		print "$_";
		print color('reset');
		print $isCROnly ? '' : "\n";
		$self->{'last_u_length'}=length($_) + ($isBare ? 0 : $self->{'stampsize'}) if $isCROnly;
	}
}

sub center {
	my ($self,$message,$isBare)=@_; #isBare - is the message going to get a timestamp later?
	local $Text::Wrap::columns=$self->{'termsize'} if $isBare;
	my @lines=split /\n/,wrap('','',$message);
	my $w=80;
	$w-=$self->{'stampsize'} unless $isBare;
	$w--;
	my $d2='';
	foreach (@lines) {
		my $l=length($_);
		my $p=(($w/2) - ($l/2)) - $self->{'last_u_length'};
		my $a=' ' x (($w/2) - ($l/2)) . $_;
		$d2.=$a . ' ' x ($w-length($a));
		$self->{'last_u_length'}=$p+length($a);
		$d2.="\n";
	}
	chomp $d2;
	return $d2;
}

sub right_align {
	my ($self,$message,$isBare)=@_;
	my @lines=split /\n/,wrap('','',$message);
	my $w=$isBare ? 80 : 80 - $self->{'stampsize'};
	my $d2='';
	foreach (@lines) {
		my $l=length($_);
		$w--;
		$d2.=' ' x (($w - $l - $self->{'last_u_length'})) . $_;
		$d2.="\n";
	}
	chomp $d2;
	return $d2;
}

sub AUTOLOAD {
	my ($self,$data) = @_;

	my $c=$AUTOLOAD;
	
	$c =~ s/.*://;
	
	return if $c eq 'DESTROY';
	
	my ($t);
	
	if ($c=~/^(?:([biu]*)([cr]?)_)?(.*)$/) {
		$t=$2.$1 || '';
		$c=$3 || $2 || $1;
		$c="$c on_white" if $t=~/i/;
		if ($t =~ /c/) {
			$data=$self->center($data,$t =~ /b/);
		}elsif ($t=~/r/) {
			$data=$self->right_align($data,$t =~ /b/);
		}
		$t=~s/u// if $t=~/[cr]/;
	}
	
	$self->log($data,$c,scalar($t =~ /b/),scalar($t =~ /u/));
}

sub DESTROY {
	print color ('reset');
	cldown();
}

1;
