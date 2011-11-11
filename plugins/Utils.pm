#!/dev/null
package Utils;

use lib 'lib';
use Packet;
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
			$::worlds{$args[1]}=World->new(
				name => $args[1]
			);
			$p->message('Created world '.$args[1]);
		}elsif ($args[0] eq 'goto') {
			if ($::worlds{$args[1]}) {
				goto_world($p,$args[1]);
			}else{
				$p->message('No such world: '.$args[1]);
			}
		}else{
			if ($::worlds{$args[0]}) {
				goto_world($p,$args[0]);
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
	
	$::plugins{'Commands'}->bind('gamemode',sub {
		my ($e,$s,@args)=@_;
		my $p=$::srv->get_player($s);
		$p->update_gamemode($args[0]);
	});
	
	bless($self,$class);
};

sub goto_world {
	my ($p,$world)=@_;
	$p->message('Whoosh!');
	$p->{'entity'}->{'world'}=$::worlds{$world};
	foreach my $o ($::srv->get_players()) {
		next if $o->{'username'} eq $p->{'username'};
		if ($o->{'entity'}->{'world'}->{'name'} eq $::worlds{$world}->{'name'}) {
			$p->load_entity_named($o->{'entity'});
			$o->load_entity_named($p->{'entity'});
		} else {
			$o->send(
				$::pf->build(
					Packet::REMOVE,
					$p->{'entity'}->{'id'}
				)
			);
			$p->send(
				$::pf->build(
					Packet::REMOVE,
					$o->{'entity'}->{'id'}
				)
			);
		}
	}
	$p->update_chunks();
	$p->{'entity'}->{'y'}+=0.25;
	$p->{'entity'}->{'y2'}+=0.25;
	$p->update_position();
}
