package Config::Templated;

# ABSTRACT: Template values in a config structure

use Moo;
use Hash::Merge qw(merge);
use Clone qw(clone);
use Data::Visitor::Callback;
use Params::Validate;
use Scalar::Util qw(blessed);
use List::Util qw(reduce);
use List::MoreUtils qw(any all);
use Data::Dumper;
use Carp;

our $VERSION = '0.002';

has config_files => (
    is   => 'ro',
    isa  => sub {
        (ref $_[0] eq 'ARRAY' and all { ! ref $_ } @{$_[0]})
            or croak "Not an 'ArrayRef[Str]'";
    },
);

has config => (
    is       => 'ro',
    isa      => sub {
        ref $_[0] eq 'HASH'
            or croak "Not a 'HashRef'";
    },
    lazy     => 1,
    builder  => '_build_config',
);

has config_array => (
    is       => 'ro',
    isa      => sub {
        (ref $_[0] eq 'ARRAY' and all { ref $_ eq 'HASH' } @{$_[0]})
            or croak "Not an 'ArrayRef[HashRef]'";
    },
    lazy     => 1,
    builder  => '_build_config_array',
);

has templater => (
    is       => 'ro',
    isa      => sub {
        blessed($_[0])
            or croak "Not an 'Object'";
    },
    lazy     => 1,
    builder  => '_build_templater',
);

has defaults => (
    is       => 'ro',
    lazy     => 1,
    builder  => '_build_defaults',
);

has data => (
    is   => 'ro',
    isa  => sub {
        ref $_[0] eq 'HASH'
            or croak "Not a 'HashRef'";
    },
);

sub _build_config {
    my ($self) = @_;
    return reduce { merge($a, $b) } @{ $self->config_array };
}

sub _build_config_array {
    my ($self) = @_;
    require Config::Any;
    return [
        map { values %$_ }
            Config::Any->load_files({
                files    => $self->config_files,
                use_ext  => 1,
            }),
    ];
}

sub _build_templater {
    require Template::Tiny;
    return Template::Tiny->new;
}

sub _build_defaults {
    # my ($self) = @_;
    my %defaults;
    if (eval { require FindBin }) {
        $defaults{findbin}{bin} = $FindBin::Bin;
    }
    # and so on... Config.pm, various special variables like $$
    return \%defaults;
}

sub process {
    my ($self, $data) = @_;
    $data ||= $self->data;
    return $self->process_structure(
        $self->config_array,
        $data,
        $self->templater,
    );
}

sub process_structure {
    my ($proto, $configs, $data, $tmpl) = @_;

    my $config = ref $configs eq 'ARRAY' ? reduce { merge($a, $b) } @$configs : $configs;

    $data ||= $proto->_build_defaults;

    $tmpl ||= $proto->_build_templater;

    my $visitor = Data::Visitor::Callback->new(
        value => sub {
            my $out;
            $tmpl->process(\$_, $data, \$out);
            $_ = $out;
        },
    );

    $visitor->visit($config);

    return $config;
}

1;
__END__

=head1 NAME

Config::Templated

=head1 SYNOPSIS

=head1 TODO

=over 4

=item Provide a nice set of defaults using core modules

=item Support a predicate that tells when a config entry is to be left alone
However Data::Visitor and ::Callback don't seem to have a nice way of telling you where in a structure you are, or even what key/index you are at

=item Support different delimiters for substitution (does Template::Tiny support this?)
However Template::Tiny does not support this

=item Config library agnostic

=item Template any old hash

=back

=cut
