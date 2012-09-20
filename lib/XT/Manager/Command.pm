package XT::Manager::Command;

use 5.010;
use strict;
use utf8;

BEGIN {
	$XT::Manager::Command::AUTHORITY = 'cpan:TOBYINK';
	$XT::Manager::Command::VERSION   = '0.002';
}

use base qw/App::Cmd::Command/;

use XT::Manager::API;
use Cwd;

sub opt_spec
{
	my ($self) = @_;
	return (
		[
			"repo|R=s",
			sprintf("custom xt repository path [default: %s]", $self->_default_repo),
			{ default => $self->_default_repo },
		],
		[
			"xtdir|X=s",
			sprintf("local xt directory [default: %s]", $self->_default_xtdir),
			{ default => $self->_default_xtdir },
		],
	);
}

sub _default_repo
{
	$ENV{PERL_XT_MANAGER_DIR} // "$ENV{HOME}/perl5/xt";
}

sub _default_xtdir
{
	(cwd =~ m{[\\\/]xt$}) ? '.' : 'xt';
}

sub get_repository
{
	my ($self, $opts) = @_;
	return XT::Manager::Repository->new(
		dir => ($opts->{repo} // $self->_default_repo),
	);
}

sub get_xtdir
{
	my ($self, $opts) = @_;
	return XT::Manager::XTdir->new(
		dir => ($opts->{xtdir} // $self->_default_xtdir),
	);
}

__PACKAGE__
__END__
