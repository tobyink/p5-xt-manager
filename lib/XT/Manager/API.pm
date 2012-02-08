package XT::Manager::API;

use MooseX::Declare;
no warnings;
use common::sense;

BEGIN {
	$XT::Manager::API::AUTHORITY = 'cpan:TOBYINK';
	$XT::Manager::API::VERSION   = '0.001';
}

class XT::Manager::Test
{
	BEGIN {
		$XT::Manager::Test::AUTHORITY = 'cpan:TOBYINK';
		$XT::Manager::Test::VERSION   = '0.001';
	}
	
	use MooseX::Types::Moose ':all';
	use MooseX::Types::Path::Class qw/Dir File/;
	
	has t_file => (
		is       => 'ro',
		isa      => File,
		required => 1,
		coerce   => 1,
		handles  => {
			name     => 'basename',
			}
		);
	
	has config_file => (
		is         => 'ro',
		isa        => File|Undef,
		coerce     => 1,
		lazy_build => 1,
		);
		
	method _build_file (Str $extension)
	{
		my $abs = $self->t_file->absolute;
		$abs =~ s/\.\Kt$/$extension/;
		return unless -f $abs;
		return $abs;
	}
	
	method _build_config_file ()
	{
		$self->_build_file('config');
	}
	
	# meh
	around has_config_file ()
	{
		defined $self->config_file;
	}
}

class XT::Manager::TestSet
{
	BEGIN {
		$XT::Manager::TestSet::AUTHORITY = 'cpan:TOBYINK';
		$XT::Manager::TestSet::VERSION   = '0.001';
	}
	
	use MooseX::Types::Moose ':all';
	
	has tests => (
		is       => 'rw',
		isa      => 'ArrayRef[XT::Manager::Test]',
		required => 1,
		lazy     => 1,
		builder  => '_build_tests',
		);

	has disposable_config_files => (
		is         => 'ro',
		isa        => Bool,
		default    => 1,
		);
	
	method _build_tests () { }

	method is_ignored (Str $name)
	{
		return;
	}
	
	method test (Str $name)
	{
		my @results = grep { $_->name eq $name } @{ $self->tests };
		wantarray ? @results : $results[0];
	}
	
	method add_test ()
	{
		confess "not implemented";
	}

	method remove_test ()
	{
		confess "not implemented";
	}
}

role XT::Manager::FileSystemTestSet
{
	BEGIN {
		$XT::Manager::FileSystemTestSet::AUTHORITY = 'cpan:TOBYINK';
		$XT::Manager::FileSystemTestSet::VERSION   = '0.001';
	}
	
	use MooseX::Types::Moose ':all';
	use MooseX::Types::Path::Class qw/Dir/;
	
	has dir => (
		is       => 'ro',
		isa      => Dir,
		required => 1,
		coerce   => 1,
		);
	
	method _build_tests ()
	{
		$self->dir->mkpath unless -d $self->dir;
		
		my @tests =
			map { XT::Manager::Test->new(t_file => $_) }
			grep { (!$_->is_dir) && ($_->basename =~ /\.t$/) }
			$self->dir->children;
		
		$self->tests(\@tests);
	}
	
	method compare ($other)
	{
		my %results;
		foreach my $t (@{ $self->tests })
		{
			$results{ $t->name }{L} = [ $t->t_file->stat->mtime ];
		}
		foreach my $t (@{ $other->tests })
		{
			$results{ $t->name }{R} = [ $t->t_file->stat->mtime ];
		}
		
		XT::Manager::Comparison->new(
			left  => $self,
			right => $other,
			data  => \%results,
			);
	}
	
	around add_test ($t)
	{
		my $o = $t;
		$t = $self->test($t) unless ref $t;
		die ("$o not found in ".$self->dir) unless ref $t;
		
		my $dir = $self->dir;
		my ($t_file, $config_file);
		my $dump = sub {
			my ($old, $new) = @_;
			my $fh = $new->openw;
			print $fh $old->slurp;
			close $fh;
			utime $old->stat->mtime, $old->stat->mtime, "$new";
		};
		
		$t_file = Path::Class::File->new("$dir", $t->t_file->basename);
		$dump->($t->t_file, $t_file);
		
		if ($t->has_config_file)
		{
			$config_file = Path::Class::File->new("$dir", $t->config_file->basename);
			$dump->($t->config_file, $config_file)
				if $self->disposable_config_files
				|| !(-e $config_file);
		}
		
		my $object = XT::Manager::Test->new(
			t_file      => $t_file,
			config_file => $config_file,
			);
		push @{ $self->tests }, $object;
		
		return $object;
	}
	
	around remove_test ($t)
	{
		my $o = $t;
		$t = $self->test($t) unless ref $t;
		die ("$o not found in ".$self->dir) unless ref $t;
		
		$t->t_file->remove;
		if ($t->has_config_file)
		{
			$t->config_file->remove
				if $self->disposable_config_files
				|| !(-e $t->config_file);
		}
		
		my @tests =
			grep { $_->name ne $t->name }
			@{ $self->tests };
		$self->tests(\@tests);
		
		return $self;
	}
}

class XT::Manager::Repository
	extends XT::Manager::TestSet
	with XT::Manager::FileSystemTestSet
{
	BEGIN {
		$XT::Manager::Repository::AUTHORITY = 'cpan:TOBYINK';
		$XT::Manager::Repository::VERSION   = '0.001';
	}
}

class XT::Manager::XTdir
	extends XT::Manager::TestSet
	with XT::Manager::FileSystemTestSet
{
	BEGIN {
		$XT::Manager::XTdir::AUTHORITY = 'cpan:TOBYINK';
		$XT::Manager::XTdir::VERSION   = '0.001';
	}
	
	use MooseX::Types::Moose ':all';
	
	has ignore_list => (
		is         => 'ro',
		isa        => Any,
		lazy_build => 1,
		);

	has '+disposable_config_files' => (
		default    => 0,
		);

	method _build_ignore_list ()
	{
		$self->dir->mkpath unless -d $self->dir;
		
		my $file  = Path::Class::File->new($self->dir, '.xt-ignore');
		return unless -f "$file";
		my @ignore =
			map { qr{$_} }
			map { chomp; $_ }
			$file->slurp;
		return \@ignore;
	}
	
	method is_ignored (Str $name)
	{
		return 1 if $name ~~ $self->ignore_list;
		return;
	}
	
	method add_ignore (Str $string)
	{
		$self->dir->mkpath unless -d $self->dir;
		
		my $file  = Path::Class::File->new($self->dir, '.xt-ignore');
		open my $fh, '>>', "$file";
		print $fh quotemeta($string);
		close $fh;
		push @{ $self->ignore_list }, qr{ \Q $string \E }x;
	}
}

class XT::Manager::Comparison
{
	BEGIN {
		$XT::Manager::Comparison::AUTHORITY = 'cpan:TOBYINK';
		$XT::Manager::Comparison::VERSION   = '0.001';
	}

	use MooseX::Types::Moose ':all';

	use constant {
		LEFT_ONLY     => '+   ',
		RIGHT_ONLY    => '  ? ',
		LEFT_NEWER    => 'U   ',
		RIGHT_NEWER   => '  M ',
		};
	
	has data => (
		is       => 'ro',
		isa      => HashRef,
		required => 1,
		);
	
	has [qw/left right/] => (
		is       => 'ro',
		isa      => 'XT::Manager::TestSet',
		required => 1,
		);
	
	method test_names ()
	{
		sort keys %{ $self->data };
	}
	
	method left_has ($name)
	{
		return $self->data->{$name}{L};
	}
	
	method right_has ($name)
	{
		return $self->data->{$name}{R};
	}
	
	method status ($name)
	{
		my $L = $self->left_has($name);
		my $R = $self->right_has($name);
		
		return LEFT_ONLY   if (  $L and !$R );
		return RIGHT_ONLY  if ( !$L and  $R );
		return LEFT_NEWER  if (  $L and  $R  and $L->[0] > $R->[0] );
		return RIGHT_NEWER if (  $L and  $R  and $L->[0] < $R->[0] );
		return;
	}
	
	method show ($verbose?)
	{
		my $str = '';
		foreach my $t ($self->test_names)
		{
			next if $self->right->is_ignored($t);
			
			my $status = $self->status($t);
			if (defined $status and length $status)
			{
				$str .= sprintf("%s  %s\n", $status, $t);
			}
			elsif ($verbose)
			{
				$str .= "      $t\n";
			}
		}
		return $str;
	}
	
	method should_pull ()
	{
		grep
		{
			my $f = $_;
			if ($self->right->is_ignored($f))
			{
				0;
			}
			else
			{
				my $st = $self->status($f) // '';
				$st eq LEFT_ONLY || $st eq LEFT_NEWER;
			}
		} $self->test_names;
	}
}

__FILE__
__END__

=head1 NAME

XT::Manager::API - this is the interface you want to use for scripting XT::Manager

=head1 DESCRIPTION

Currently this is not documented, and subject to change in backwards
incompatible ways without notice.

This module defines the following classes:

=over

=item * C<< XT::Manager::Test >> - a single test file

=item * C<< XT::Manager::TestSet >> - a set of test files

=item * C<< XT::Manager::Repository >> - a repository of test files

=item * C<< XT::Manager::XTdir >> - an "xt" directory

=item * C<< XT::Manager::Comparison >> - the result of comparing two TestSet objects

=back

The source code of the C<< XT::Manager::Command::* >> modules are fairly
good examples of how these classes can be used.

=head1 BUGS

Please report any bugs to
L<http://rt.cpan.org/Dist/Display.html?Queue=XT-Manager>.

=head1 SEE ALSO

L<XT::Manager>, L<XT::Util>.

=head1 AUTHOR

Toby Inkster E<lt>tobyink@cpan.orgE<gt>.

=head1 COPYRIGHT AND LICENCE

This software is copyright (c) 2012 by Toby Inkster.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 DISCLAIMER OF WARRANTIES

THIS PACKAGE IS PROVIDED "AS IS" AND WITHOUT ANY EXPRESS OR IMPLIED
WARRANTIES, INCLUDING, WITHOUT LIMITATION, THE IMPLIED WARRANTIES OF
MERCHANTIBILITY AND FITNESS FOR A PARTICULAR PURPOSE.

