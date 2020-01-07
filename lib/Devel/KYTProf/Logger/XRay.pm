package Devel::KYTProf::Logger::XRay;

use 5.012000;
use strict;
use warnings;

use AWS::XRay;
use Time::HiRes();

our $VERSION = "0.04";

sub new {
    my ($class) = @_;
    return bless {}, $class;
}

sub log {
    my ($self, %args) = @_;

    return if !$AWS::XRay::ENABLED;

    AWS::XRay::capture $args{module}, sub {
        my $segment = shift;
        my $elapsed = $args{time} / 1000; # msec -> sec
        my $end     = Time::HiRes::time();
        my $start   = $end - $elapsed;
        $segment->{start_time} = $start;
        $segment->{end_time}   = $end;

        my $data = $args{data};
        $segment->{metadata} = $data;
        if (exists $data->{http_method}) {
            $segment->{http} = {
                request => {
                    method => $data->{http_method},
                    url    => $data->{http_url},
                },
            };
        }
        elsif (exists $data->{sql}) {
            $segment->{sql} = {
                sanitized_query => delete $data->{sql},
            };
        }
        for my $n (qw/method package file line/) {
            $segment->{metadata}->{$n} = $args{$n};
        }
    }
}

1;
__END__

=encoding utf-8

=head1 NAME

Devel::KYTProf::Logger::XRay - Logger for AWS::XRay

=head1 SYNOPSIS

    use Devel::KYTProf::Logger::XRay;
    my $logger = Devel::KYTProf::Logger::XRay->new;
    Devel::KYTProf->logger($logger);

=head1 DESCRIPTION

Devel::KYTProf::Logger::XRay is a logger for AWS::XRay.

See also L<AWS::XRay>.

=head1 LICENSE

Copyright (C) FUJIWARA Shunichiro.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHOR

FUJIWARA Shunichiro E<lt>fujiwara.shunichiro@gmail.comE<gt>

=cut

