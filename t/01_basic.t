#!/usr/bin/env perl

use Test::Most 'no_plan';
use FindBin;
use lib "$FindBin::Bin/../lib";
use Clone qw(clone);
use FindBin;
use Template;

use_ok('Config::Templated');

my $config_array = [
	{ key1 => '[% findbin.bin %]' },
	{ key2 => 'One thing' },
	{ key2 => 'Something else' },
	{ key3 => 'Something [% moar %]' },
];

my $data = {
	moar => 'sinister',
};

my $expected_proto = {
	key1 => '',
	key2 => 'One thing',
	key3 => 'Something ',
};

my $cfg = Config::Templated->new(
	config_array => $config_array,
);

# use Data::Dumper; warn "config: ".Dumper($cfg->config);

isa_ok($cfg, 'Config::Templated');

my $expected = clone $expected_proto;
$expected->{key1} .= $FindBin::Bin;
is_deeply($cfg->process(), $expected, 'default substitution');

$expected = clone $expected_proto;
$expected->{key3} .= $data->{moar};
is_deeply($cfg->process(clone $data), $expected, 'nondefault substitution');

$cfg = Config::Templated->new(
	templater => Template->new,
	config_array => $config_array,
);

is_deeply($cfg->process(clone $data), $expected, 'Template Toolkit');

# FIXME
# Test at depth
# Test keys
# Test arrays
# Test some failure modes - objects, scalars, undef
