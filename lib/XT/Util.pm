package XT::Util;

use 5.010;
use common::sense;
use utf8;

our @EXPORT;
BEGIN {
	$XT::Util::AUTHORITY = 'cpan:TOBYINK';
	$XT::Util::VERSION   = '0.001';
	
	@EXPORT = qw/__CONFIG__/;
}

use JSON qw/from_json/;

use parent qw/Exporter/;

sub __CONFIG__ (;$)
{
	my ($package, $file) = caller(0);
	$file = shift if @_;
	(my $config_file = $file) =~ s{\.t$}{};
	$config_file .= '.config';
	my $json = do { open my $fh, '<', $config_file; local $/ = <$fh> };
	return from_json($json);
}

__PACKAGE__
__END__

=head1 NAME

XT::Util - utilities for use within "xt" tests

=head1 SYNOPSIS

In xt/02pod_coverage.t:

  use Test::More;
  use Test::Pod::Coverage;
  use XT::Util;
  
  my @modules = @{ __CONFIG__->{modules} || [] };
  pod_coverage_ok($_, "$_ is covered")
    foreach @modules;
  done_testing(scalar @modules);

In xt/02pod_coverage.config:

  { "modules": ["Local::MyModule1", "Local::MyModule2"] }

=head1 DESCRIPTION

These utilities are aimed at making test cases easier to reuse. 

=head2 C<< __CONFIG__($testfile) >>

Where C<< $testfile >> is a filename like "foo.t", will strip ".t" from
the end of the file name, add ".config", slurp the contents and parse them
as JSON, returning the result.

If C<< $testfile >> is omitted, then uses the caller's filename.

By moving project-specific information (e.g. file names, package names,
etc) into config files, the test case itself can be shared between projects.

=head1 BUGS

Please report any bugs to
L<http://rt.cpan.org/Dist/Display.html?Queue=XT-Manager>.

=head1 SEE ALSO

L<XT::Manager>, L<XT::Manager::API>.

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

