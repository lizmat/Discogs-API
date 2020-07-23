use API::Discogs::Classes;
use Cro::HTTP::Client;

# supported currencies
my constant @currencies = <
  USD GBP EUR CAD AUD JPY CHF MXN BRL NZD SEK ZAR
>;
subset AllowedCurrency of Str where * (elem) @currencies;

# needs to be defined here for visibility
my $default-client;

class API::Discogs:ver<0.0.1>:auth<cpan:ELIZABETH> {
    has AllowedCurrency $.currency = @currencies[0];
    has Cro::HTTP::Client $.client = $default-client;
    has Str $.key;
    has Str $!secret is built;

    # main worker for creating non-asynchronous work
    method !objectify($uri, $class) {
        my $resp := await $.client.get(
          $!secret && $.key
            ?? ($uri, headers => (
                 Authorization => "Discogs key=$.key, secret=$!secret"
               ))
            !! $uri
        );
        $class.new(await $resp.body)
    }

    method release(UInt:D $id, AllowedCurrency:D $currency = $.currency) {
        self!objectify("/releases/$id?$currency", Release)
    }

    multi method release-user-rating(UInt:D $id, Username $username) {
        self!objectify("/releases/$id/rating/$username", ReleaseUserRating)
    }
    multi method release-user-rating(Release:D $release, Username $username) {
        self.release-user-rating($release.id, $username)
    }
}

$default-client := Cro::HTTP::Client.new:
  base-uri => "https://api.discogs.com",
  headers => (
    Accepts    => "application/vnd.discogs.v2.discogs+json",
    User-agent => "Raku Discogs Agent v" ~ API::Discogs.^ver,
  );

my $discogs := API::Discogs.new;
my $release := $discogs.release(249504);

dd $_ for $release.community.contributors;
dd $release.released;
dd $release.date_added;
dd $release.artists;

my $rating := $discogs.release-user-rating($release, "memory");
dd $rating;

#dd $json<artists>[0];
#my $artist = Artist.new($json<artists>[0]);
#dd $artist.^methods>>.name.sort;
#dd $artist.name;

=begin pod

=head1 NAME

API::Discogs - Provide basic API to Discogs

=head1 SYNOPSIS

=begin code :lang<raku>

use API::Discogs;

=end code

=head1 DESCRIPTION

API::Discogs provides a Raku library with access to the L<Discogs|https://discogs.com>
data and functions.

=head1 AUTHOR

Elizabeth Mattijsen <liz@wenzperl.nl>

Source can be located at: https://github.com/lizmat/API-Discogs . Comments and
Pull Requests are welcome.

=head1 COPYRIGHT AND LICENSE

Copyright 2020 Elizabeth Mattijsen

This library is free software; you can redistribute it and/or modify it under
the Artistic License 2.0.

=end pod

# vim: expandtab shiftwidth=4
