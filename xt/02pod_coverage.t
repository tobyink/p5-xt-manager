use XT::Util;
use Test::More;
use Test::Pod::Coverage;

plan skip_all => __CONFIG__->{skip_all}
	if __CONFIG__->{skip_all};

my @modules = @{ __CONFIG__->{modules} };
pod_coverage_ok($_, "$_ is covered")
	foreach @modules;
done_testing(scalar @modules);

