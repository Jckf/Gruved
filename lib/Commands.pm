#!/dev/null
package Commands;

use strict;
use warnings;
use Eventss;
use Packet;

sub new {
	my ($class) = @_;
	my $self = {};

	$self->{'events'} = Eventss->new();

	$::pp->bind(Packet::CHAT,sub {
		my ($e,$s,$m) = @_;
		my $p = $::srv->get_player($s);

		if (substr($m,0,1) eq '/') {
			$e->{'cancelled'} = 1;
			my @d = split(' ',substr($m,1));
			my $c = shift @d;
			$self->{'events'}->trigger($c,$s,@d);
		}
	});

	bless($self,$class);
}

sub bind {
	$_[0]->{'events'}->bind($_[1],$_[2]);
}

sub command { #Convenience function - registers command as node as well, and checks permissions
	my ($self,$command,$node,$desc,$sub)=@_;
	$sub=$desc if ref $desc eq 'CODE';
	$sub=$node if ref $node eq 'CODE';
	$desc='' if ref $desc eq 'CODE';
	my @cmdparts=($command);
	if ($command =~ / /) {
		@cmdparts=split / /,$command;
	}
	$node=$::perm->_getpl().'.'.($node && ref $node ne 'CODE' ? $node : join '.',@cmdparts) ;
	$::perm->regnode($node,$desc) if not defined $::perm->{'nodes'}->{$::perm->_getpl()}->{$node};
	$::cmd->bind(shift @cmdparts,sub {
		my ($e,$s,@args) = @_;
		if (scalar(@cmdparts)) {
			foreach (0..scalar(@cmdparts)) {
				last if not $cmdparts[$_];
				return if (shift @args || '') ne ($cmdparts[$_]);
			}
		}
		my $p=$::srv->get_player($s);
		if ($::perm->can($p,$node)) {
			if ($sub->($e,$s,@args)) {
				$e->{'cancelled'}=1;
			}
		}else{
			$p->message("You don't have permission for $command ($desc)");
			$e->{'cancelled'}=1;
		}
	});
}

1;
