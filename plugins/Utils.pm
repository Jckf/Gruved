#!/dev/null
package Utils;

use strict;
use warnings;

sub new {
	my ($class) = @_;
    my $self = {};
	no warnings;
    $::plugins{'Commands'}->bind('world',sub {
        my ($e,$s,@args) = @_;
		my $p=$::srv->get_player($s);
        if ($args[0] eq 'save') {
			$p->{'entity'}->{'world'}->save();
			$p->message('Saving world...');
		}elsif ($args[0] eq 'new') {
			mkdir 'worlds/'.$args[1];
			mkdir 'worlds/'.$args[1].'/chunks';
			$::worlds{$args[1]}=World->new(
				name => $args[1]
			);
			$p->message('Created world '.$args[1]);
		}elsif ($args[0] eq 'goto') {
			if ($::worlds{$args[1]}) {
				$p->message('Whoosh!');
				$p->{'entity'}->{'world'}=$::worlds{$args[1]};
				$p->update_chunks();
				$p->update_position();
			}else{
				$p->message('No such world: '.$args[1]);
			}
		}else{
			if ($::worlds{$args[0]}) {
				$p->message('Whoosh!');
				$p->{'entity'}->{'world'}=$::worlds{$args[0]};
				$p->update_chunks();
				$p->update_position();
			}else{
				$p->message('No such world or command: '.$args[0]);
			}
		}
    });

	$::plugins{'Commands'}->bind('/unstuck',sub {
		my ($e,$s,@args)=@_;
		my $p=$::srv->get_player($s);
		$p->{'entity'}->{'y'}+=2;
		$p->{'entity'}->{'y2'}+=2;
		$p->update_position();
	});
	
    bless($self,$class);
};
