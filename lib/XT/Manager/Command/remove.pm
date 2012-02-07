package XT::Manager::Command::remove;

use 5.010;
use common::sense;
use utf8;

BEGIN {
	$XT::Manager::Command::remove::AUTHORITY = 'cpan:TOBYINK';
	$XT::Manager::Command::remove::VERSION   = '0.001';
}

use parent qw/XT::Manager::Command/;

sub abstract
{
	"remove a test from the local copy and don't pull it again"
}

sub command_names
{
	qw/remove rm/
}

sub execute
{
	my ($self, $opts, $args) = @_;
	my $repo  = $self->get_repository($opts);
	my $xtdir = $self->get_xtdir($opts);
	
	foreach my $f (@$args)
	{
		$xtdir->remove_test($f);
		$xtdir->add_ignore($f);
		$repo->remove_test($f) if $opts->{both};
	}
}

sub opt_spec
{
	my $self = shift;
	return (
		[ "both|b",
		  "remove at repository end too",
		],
		$self->SUPER::opt_spec(@_),
	);
}

__PACKAGE__
__END__
