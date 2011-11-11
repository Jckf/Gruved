package FloodControl;
use Time::HiRes 'time';
sub new {
	my ($class)=@_;
	my $self={};
	
	$::pp->bind(Packet::CHAT,sub {
		my ($e,$s,$m) = @_;
		my $p = $::srv->get_player($s);
		if (length($m) > 119) {
			$p->kick("Oversize chat");
			$e->{'cancelled'}=1;
		}
		my $diff=time() - $p->{'plugindata'}->{'FloodControl'}->{'lastmsg'};
		$p->{'plugindata'}->{'FloodControl'}->{'level'}=0 unless defined $p->{'plugindata'}->{'FloodControl'}->{'level'};
		if ($diff < 0.25) {
			$p->{'plugindata'}->{'FloodControl'}->{'level'}+=length($m)/($diff*128);
		}elsif ($p->{'plugindata'}->{'FloodControl'}->{'level'} > 0) {
			$p->{'plugindata'}->{'FloodControl'}->{'level'}*=1/($diff);
		}
		$::log->magenta($p->{'plugindata'}->{'FloodControl'}->{'level'});
		if ($p->{'plugindata'}->{'FloodControl'}->{'level'} > 1000) {
			$p->kick('Chat flooder!');
			$e->{'cancelled'}=1;
		}
		$p->{'plugindata'}->{'FloodControl'}->{'lastmsg'}=time();
	});
	
	bless($self,$class);
}