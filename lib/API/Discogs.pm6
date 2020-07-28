#--------------- external modules ----------------------------------------------

use Hash2Class;
use Cro::HTTP::Client;

#--------------- file lexical constants ----------------------------------------

# supported currencies
my constant @currencies = <
  USD GBP EUR CAD AUD JPY CHF MXN BRL NZD SEK ZAR
>;

# not constant because of https://github.com/rakudo/rakudo/issues/3828
my %valid_query_key is Set = <
  anv artist barcode catno contributor country credit format genre
  label query release_title style submitter title track type year
>;

# needs to be defined here for visibility
my $default-client;

#--------------- useful subtypes -----------------------------------------------

subset AllowedCurrency of Str where * (elem) @currencies;
subset Country of Str;
subset Genre of Str;
subset Quality of Str;
subset Price of Real;
subset Status of Str where "Accepted";
subset Style of Str;
subset URL of Str where .starts-with("https://") || .starts-with("http://");
subset Username of Str where /^ \w+ $/;
subset ValidRating of Int where 1 <= $_ <= 5;
subset Year of UInt where $_ > 1900 && $_ <= 2100;

#--------------- useful roles --------------------------------------------------

my role PaginationShortcuts {
    has $.client is rw;

    method first-page-url(::?CLASS:D:)    { $.pagination.urls<first> // Nil }
    method next-page-url(::?CLASS:D:)     { $.pagination.urls<next>  // Nil }
    method previous-page-url(::?CLASS:D:) { $.pagination.urls<prev>  // Nil }
    method last-page-url(::?CLASS:D:)     { $.pagination.urls<first> // Nil }

    method items(::?CLASS:D:)    { $.pagination.items }
    method page(::?CLASS:D:)     { $.pagination.page }
    method pages(::?CLASS:D:)    { $.pagination.pages }
    method per-page(::?CLASS:D:) { $.pagination.per-page }

    method !GET(Str:D $URL) {
        $URL
          ?? self.client.GET($URL, self.WHAT)
          !! $URL
    }

    method first-page(::?CLASS:D:)    { self!GET(self.first-page-url)    }
    method next-page(::?CLASS:D:)     { self!GET(self.next-page-url)     }
    method previous-page(::?CLASS:D:) { self!GET(self.previous-page-url) }
    method last-page(::?CLASS:D:)     { self!GET(self.last-page-url)     }
}

#--------------- actual class and its attributes -------------------------------

our class API::Discogs:ver<0.0.1>:auth<cpan:ELIZABETH> {
    has Cro::HTTP::Client $.client = $default-client;
    has AllowedCurrency $.currency = %*ENV<DISCOGS_CURRENCY> // @currencies[0];
    has UInt            $.per-page = 50;
    has Str $!token  is built = %*ENV<DISCOGS_TOKEN>;
    has Str $.key;
    has Str $!secret is built;

#--------------- the specific methods one can call -----------------------------

    # helper method for setting pagination parameters
    method !pagination(%nameds --> Str:D) {
        my UInt $page     := %nameds<page>:delete     // 1;
        my UInt $per-page := %nameds<per-page>:delete // $.per-page;
        "page=$page&per_page=$per-page"
    }

    # helper method for gathering named parameters
    method !gather-nameds(%nameds, @keys --> Str:D) {
        my str @text;
        for @keys -> $key {
            if %nameds{$key}:delete -> $value {
                @text.push("$key.subst('-','_',:g)='$value'")
            }
        }
        @text.join('&')
    }

    # main worker for creating non-asynchronous work
    method GET(API::Discogs:D: $uri, $class) {
        my @headers;
        @headers.push((Authorization => "Discogs key=$.key, secret=$!secret"))
          if $!secret && $.key;
        @headers.push((Authorization => "Discogs token=$!token"))
          if $!token;

        my $resp := await $.client.get($uri, :@headers);
        my $object := $class.new(await $resp.body);

        $object.client = self if $class ~~ PaginationShortcuts;
        $object
    }

    # accessing the Cro::HTTP::Client
    multi method client(API::Discogs:U:) { $default-client }
    multi method client(API::Discogs:D:) { $!client }

#--------------- supporting classes derived from the JSON API ------------------

    our class ArtistSummary does Hash2Class[ # OK
      anv          => Str,
      id           => UInt,
      join         => Str,
      name         => Str,
      resource_url => { type => URL, name => "resource-url" },
      role         => Str,
      tracks       => Str,
    ] { }

    our class Rating does Hash2Class[ # OK
      average => Numeric,
      count   => Int,
    ] { }

    our class User does Hash2Class[
      resource_url => { type => URL, name => 'resource-url' },
      username     => Username,
    ] { }

    our class Community does Hash2Class[ # OK
      '@contributors' => User,
      data_quality    => { type => Quality, name => 'data-quality' },
      have            => Int,
      rating          => Rating,
      status          => Status,
      submitter       => User,
      want            => Int,
    ] { }

    our class CatalogEntry does Hash2Class[
      catno            => Str,
      entity_type      => { type => Int, name => 'entity_type' },
      entity_type_name => { type => Str, name => 'entity-type-name' },
      id               => UInt,
      name             => Str,
      resource_url => { type => URL, name => 'resource-url' },
    ] { }

    our class Format does Hash2Class[
      '@descriptions' => Str,
      name            => Str,
      qty             => Int,
    ] { }

    our class Identifier does Hash2Class[
      type  => Str,
      value => Str,
    ] { }

    our class Image does Hash2Class[ # OK
      height       => UInt,
      resource_url => { type => URL, name => 'resource-url' },
      type         => Str,
      uri          => URL,
      uri150       => URL,
      width        => UInt,
    ] { }

    our class Track does Hash2Class[ # OK
      duration => Str,
      position => UInt(Str),
      title    => Str,
      type_    => { type => Str, name => 'type' },
    ] { }

    our class Video does Hash2Class[ # OK
      description => Str,
      duration    => Int,
      embed       => Bool,
      title       => Str,
      uri         => URL,
    ] { }

    our class Member does Hash2Class[ # OK
      active       => Bool,
      id           => UInt,
      name         => Str,
      resource_url => { type => URL, name => 'resource-url' },
    ] { }

    our class Value does Hash2Class[
      count => Int,
      title => Str,
      value => Str,
    ] { }

    our class Pagination does Hash2Class[ # OK
      '%urls'  => URL,
      items    => UInt,
      page     => UInt,
      pages    => UInt,
      per_page => { type => UInt, name => 'per-page' },
    ] { }

#-------------- getting the information of a specific release -------------------

    our class Release does Hash2Class[ # OK
      '@artists'        => ArtistSummary,
      '@companies'      => CatalogEntry,
      '@extraartists'   => ArtistSummary,
      '@formats'        => Format,
      '@genres'         => Genre,
      '@identifiers'    => Identifier,
      '@images'         => Image,
      '@labels'         => CatalogEntry,
      '@series'         => CatalogEntry,
      '@styles'         => Style,
      '@tracklist'      => Track,
      '@videos'         => Video,
      artists_sort      => { type => Str, name => 'artists-sort' },
      community         => Community,
      country           => Country,
      data_quality      => { type => Quality, name => 'data-quality' },
      date_added        => { type => DateTime(Str), name => 'date-added' },
      date_changed      => { type => DateTime(Str), name => 'date-changed' },
      estimated_weight  => { type => UInt, name => 'estimated-weight' },
      format_quantity   => { type => UInt, name => 'format-quantity' },
      id                => UInt,
      lowest_price      => { type => Price, name => 'lowest-price' },
      master_id         => { type => UInt, name => 'master-id' },
      master_url        => { type => URL, name => 'master-url' },
      notes             => Str,
      num_for_sale      => { type => UInt, name => 'num-for-sale' },
      released          => Str,
      release_formatted => { type => Str, name => 'release-formatted' },
      resource_url      => { type => URL, name => 'resource-url' },
    ] {
        method average()      { $.community.rating.average }
        method contributors() { $.community.contributors   }
        method count()        { $.community.rating.count   }
        method have()         { $.community.have           }
        method submitter()    { $.community.submitter      }
        method want()         { $.community.have           }
    }

    our class StatsData does Hash2Class[
      in_collection => { type => Int, name => 'in-collection' },
      in_wantlist   => { type => Int, name => 'in-wantlist' },
    ] { }

    our class Stats does Hash2Class[
      '%source' => StatsData,
    ] { }

    our class UserReleaseRating does Hash2Class[
      rating      => ValidRating,
      release     => UInt,
      username    => Username,
    ] { }

    our class CommunityReleaseRating does Hash2Class[
      rating     => Rating,
      release_id => { type => UInt, name => 'release-id' },
    ] { }

    method release(API::Discogs:D:
      UInt:D $id, AllowedCurrency:D :$currency = $.currency
    --> Release:D) {
        self.GET("/releases/$id?$currency", Release)
    }

    multi method user-release-rating(API::Discogs:D:
      UInt:D $id, Username $username
    --> UserReleaseRating:D) {
        self.GET("/releases/$id/rating/$username", UserReleaseRating)
    }
    multi method user-release-rating(API::Discogs:D:
      Release:D $release, Username $username
    --> UserReleaseRating:D) {
        self.user-release-rating($release.id, $username)
    }

    multi method community-release-rating(API::Discogs:D:
      UInt:D $id
    --> CommunityReleaseRating:D) {
        self.GET("/releases/$id/rating", CommunityReleaseRating)
    }
    multi method community-release-rating(API::Discogs:D:
      Release:D $release
    --> CommunityReleaseRating:D) {
        self.community-release-rating($release.id)
    }

#-------------- getting the information of a master release ---------------------

    our class MasterRelease does Hash2Class[ # OK
      '@artists'              => ArtistSummary,
      '@genres'               => Genre,
      '@images'               => Image,
      '@styles'               => Style,
      '@tracklist'            => Track,
      '@videos'               => Video,
      data_quality            => { type => Quality, name => 'data-quality' },
      id                      => UInt,
      lowest_price            => { type => Price, name => 'lowest-price' },
      main_release            => { type => UInt, name => 'main-release' },
      main_release_url        => { type => URL, name => 'main-release-url' },
      most_recent_release     => { type => UInt,
                                   name => 'most-recent-release' },
      most_recent_release_url => { type => URL,
                                   name => 'most-recent-release-url' },
      num_for_sale            => { type => UInt, name => 'num-for-sale' },
      resource_url            => { type => URL, name => 'resource-url' },
      title                   => Str,
      uri                     => URL,
      versions_url            => { type => URL, name => 'versions-url' },
      year                    => Year,
    ] { }

    method master-release(API::Discogs:D:
      UInt:D $id
    --> MasterRelease:D) {
        self.GET("/masters/$id", MasterRelease)
    }

#-------------- getting the versions of a release -------------------------------

    our class FilterFacet does Hash2Class[
      '@values'              => Value,
      allows_multiple_values => { type => Bool,
                                  name => 'allows-multiple-values' },
      id                     => Str,
      title                  => Str,
    ] { }

    our class Filters does Hash2Class[
      '%applied'   => FilterFacet,
      '%available' => UInt,
    ] { }

    our class MasterReleaseVersion does Hash2Class[
      '@major_formats' => { type => Str, name => 'major-formats' },
      '%label'         => Str,
      catno            => Str,
      country          => Country,
      format           => Str,
      id               => UInt,
      released         => Str,
      resource_url     => { type => URL, name => 'resource-url' },
      stats            => Stats,
      status           => Status,
      thumb            => URL,
      title            => Str,
    ] { }

    our class MasterReleaseVersions does Hash2Class[ # OK
      '@filter_facets' => { type => FilterFacet, name => 'filter-facets' },
      '@filters'       => Filters,
      '@versions'      => MasterReleaseVersion,
      pagination       => Pagination,
    ] does PaginationShortcuts { }

    method master-release-versions(API::Discogs:D:
      UInt:D $id,
    --> MasterReleaseVersions:D) {
        self.GET(
          "/masters/$id/versions?"
            ~ self!gather-nameds(
                %_, <format label released country sort sort-order>
              ),
            ~ self!pagination(%_),
          MasterReleaseVersions
        )
    }

#-------------- getting the information of a label ------------------------------

    our class SubLabel does Hash2Class[ # OK
      id           => UInt,
      name         => Str,
      resource_url => { type => URL, name => 'resource-url' },
    ] { }

    our class Label does Hash2Class[ # OK
      '@images'    => Image,
      '@sublabels' => SubLabel,
      '@urls'      => URL,
      contact_info => { type => Str, name => 'contact-info' },
      data_quality => { type => Quality, name => 'data-quality' },
      id           => UInt,
      name         => Str,
      profile      => Str,
      releases_url => { type => URL, name => 'releases-url' },
      resource_url => { type => URL, name => 'resource-url' },
      uri          => URL,
    ] { }

    method label(API::Discogs:D:
      UInt:D $id
    --> Label:D) {
        self.GET("/labels/$id", Label)
    }

#-------------- getting the releases of a label ---------------------------------

    our class LabelRelease does Hash2Class[
      artist       => Str,
      catno        => Str,
      format       => Format,
      id           => UInt,
      resource_url => { type => URL, name => 'resource-url' },
      status       => Status,
      thumb        => URL,
      title        => Str,
      year         => UInt,
    ] { }

    our class LabelReleases does Hash2Class[ # OK
      '@releases' => LabelRelease,
      pagination  => Pagination,
    ] does PaginationShortcuts { }

    method label-releases(API::Discogs:D:
      UInt:D $id
    --> LabelReleases:D) {
        self.GET(
          "/labels/$id/releases?" ~ self!pagination(%_),
          LabelReleases
        )
    }

#-------------- getting the information about an artist -------------------------

    our class Artist does Hash2Class[ # OK
      '@images'         => Image,
      '@members'        => Member,
      '@namevariations' => Str,
      '@urls'           => URL,
      data_quality      => { type => Quality, name => 'data-quality' },
      id                => UInt,
      name              => Str,
      profile           => Str,
      releases_url      => { type => URL, name => 'releases-url' },
      resource_url      => { type => URL, name => 'resource-url' },
      uri               => URL,
    ] { }

    method artist(API::Discogs:D:
      UInt:D $id
    --> Artist:D) {
        self.GET("/artists/$id", Artist)
    }

#-------------- getting the releases of an artist -------------------------------

    our class ArtistRelease does Hash2Class[
      '%stats'     => StatsData,
      artist       => Str,
      format       => Str,
      id           => UInt,
      label        => Str,
      resource_url => { type => URL, name => 'resource-url' },
      role         => Str,
      status       => Status,
      thumb        => URL,
      title        => Str,
      type         => Str,
      year         => Year,
    ] { }

    our class ArtistReleases does Hash2Class[ # OK
      '@releases' => ArtistRelease,
      pagination  => Pagination,
    ] does PaginationShortcuts { }

    method artist-releases(API::Discogs:D:
      UInt:D $id
    --> ArtistReleases:D) {
        self.GET(
          "/artists/$id/releases?" ~ self!pagination(%_),
          ArtistReleases
        )
    }

#-------------- searching the Discogs database ----------------------------------

    our class SearchResult does Hash2Class[
      cover_image  => URL,
      id           => UInt,
      master_id    => { type => UInt, name => 'master-id' },
      master_url   => { type => URL, name => 'master-url' },
      resource_url => { type => URL, name => 'resource-url' },
      thumb        => URL,
      title        => Str,
      type         => Str,
      uri          => URL,
      user_data    => { type => StatsData, name => 'user-data' },
    ] { }

    our class SearchResults does Hash2Class[ # OK
      '@results' => SearchResult,
      pagination => Pagination,
    ] does PaginationShortcuts { }

    method search(API::Discogs:D: *%_ --> SearchResults:D) {
        my str @params = self!pagination(%_);
        for %_.kv -> $key, $value {
            if %valid_query_key{$key} {
                @params.push($key eq 'query'
                  ?? "q=$value"
                  !! "$key=$value"
                );
                %_{$key}:delete;
            }
        }
        if %_.keys -> @extra {
            die "Found unsupported query keys: @extra.sort()";
        }
        self.GET("/database/search?" ~ @params.join("&"), SearchResults)
    }
}

#--------------- runtime initialisations ---------------------------------------

$default-client := Cro::HTTP::Client.new:
  base-uri => "https://api.discogs.com",
  headers => (
    Accepts    => "application/vnd.discogs.v2.discogs+json",
    User-agent => "Raku Discogs Agent v" ~ API::Discogs.^ver,
  );

=begin pod

=head1 NAME

API::Discogs - Provide basic API to Discogs

=head1 SYNOPSIS

=begin code :lang<raku>

use API::Discogs;
my $discogs = Discogs.new;

my $release = $discogs.release(249504);

=end code

=head1 DESCRIPTION

API::Discogs provides a Raku library with access to the
L<Discogs|https://discogs.com> data and functions.  It tries to follow
the API as closely as possible, so the up-to-date
L<Discogs developer information|https://www.discogs.com/developers>
can be used to look up matters that are unclear from thie documentation
in this module.

One exception to this rule is that fieldnames in the JSON generated by
Discogs that are using snake_case, are converted to use kebab-case in
the Raku interface.  So a field called C<allows_multiple_values> in
the JSON blob, will be accessible using a C<allow-multiple-values>
method in this module.

=head1 UTILITY METHODS

=head2 new

=begin code :lang<raku>

my $discogs = Discogs.new(
  client   => $client,     # Cro::HTTP::Client compatible, optional
  token    => "xfhgh1624", # Discogs access token, default: none
  key      => "kahgjkhdg", # Discogs access key, default: none
  secret   => "454215642", # Discogs access secret, default: none
  currency => "EUR",       # default: "USD"
  per-page => 10,          # default: 50
;

=end code

Create an object to access the services that the Discogs API has to offer.

=item client - a Cro::HTTP::Client compatible client

One will be provided if not specified.

=item token - Discogs Access Token

A token needed to access certain parts of the Discogs API.  See
L<https://www.discogs.com/settings/developers> for more information.
Defaults to whatever is specified with the DISCOGS_TOKEN environment
variable.

=item key - Discogs Access Key

A string needed to access certain parts of the Discogs API.  See
L<https://www.discogs.com/developers#page:authentication> for more
information.

=item secret - Discogs Access Secret

A string needed to access certain parts of the Discogs API.  See
L<https://www.discogs.com/developers#page:authentication> for more
information.

=item currency

A string indicating the default currency to be used when producing
prices of releases in the Discogs Marketplace.  It should be one of
the following strings:

  USD GBP EUR CAD AUD JPY CHF MXN BRL NZD SEK ZAR

=item per-page

An integer indicating the default number of items per page that should
be produced by methods that return objects that support pagination.

=head2 client

=begin code :lang<raku>

my $default = API::Discogs.client;  # the default client

my $client = $discogs.client;       # the actual client to be used

=end code

Return the default C<Cro::HTTP::Client> object when called as a class
method.  That object will be used by default when creating a C<API::Discogs>
object.  Intended to be used as a base for alterations, e.g. by
overriding the C<GET> method during testing.

Returns the actual object that was (implicitely) specified during the
creation of the C<API::Discogs> object when called as an instance method.

=head2 GET

=begin code :lang<raku>

my $content = $discogs.GET("/artists/108713", API::Discogs::Artist);

=end code

Helper method to fetch data using the Discogs API for the given URI,
and interpret it as data of the given class.  Returns an instance of
the given class, or throws if something went wrong.

=head1 CONTENT METHODS

=head2 artist

=begin code :lang<raku>

my $artist = $discogs.artist(108713);

=end code

Fetch the information for the given artist ID and return that in
an L<API::Discogs::Artist> object.

=head2 artist-releases

=begin code :lang<raku>

my $artist-releases = $discogs.artist-releases(
  108713,         # the artist ID
  page     => 2,  # page number, default: 1
  per-page => 25, # items per page, default: object
);

=end code

Fetch all of the releases of given artist ID and return them in
pages in a L<API::Discogs::ArtistReleases> object.

=head2 label

=begin code :lang<raku>

my $label = $discogs.label(1);

=end code

Fetch the information for the given label ID and return that in
an L<API::Discogs::Label> object.

=head2 label-releases

=begin code :lang<raku>

my $label-releases = $discogs.label-releases(
  1,              # the label ID
  page     => 2,  # page number, default: 1
  per-page => 25, # items per page, default: object
);

=end code

Fetch all of the releases of given label ID and return them in
pages in a L<API::Discogs::LabelReleases> object.

=head2 master-release

=begin code :lang<raku>

my $master-release = $discogs.master-release(1000);

=end code

Fetch the information for the given master release ID and return
that in an L<API::Discogs::MasterRelease> object.

=head2 master-release-versions

=begin code :lang<raku>

my $master-release-versions = $discogs.master-release-versions(
  1000,                 # the master release ID
  page     => 2,        # page number, default: 1
  per-page => 25,       # items per page, default: object

  format => "CD",       # limit to format, default no limit
  label  => "Foo",      # limit to label, default no limit
  released => 1992,     # limit to year, default no limit
  country => "Belgium", # limit to country, default no limit
  sort => "released",   # sort on given key, default no sort
  sort-order => "desc", # sort order, default to "asc"
);

=end code

Fetch all of the versions of a given master release ID and return
them in pages in a L<API::Discogs::MasterReleaseVersions> object.  It
supports the following optional named parameters:

=item page

An integer indicating the page to obtain the C<MasterReleaseVersion>
objects of.  Defaults to 1.

=item per-page

An integer indicating the maximum number of items per page to be
produced.  Defaults to what was (implicitely) specified with the
creation of the C<API::Discogs> object.

=item format

A string indicating the C<format> of the C<MasterReleaseVersion> objects
to be returned.  Defaults to no limitation on format.

=item label

A string indicating the C<label> of the C<MasterReleaseVersion> objects
to be returned.  Defaults to no limitation on label.

=item released

An integer indicating the year of release of the C<MasterReleaseVersion>
objects to be returned.  Defaults to no limitation on year.

=item country

A string indicating the C<country> of the C<MasterReleaseVersion> objects
to be returned.  Defaults to no limitation on country.

=item sort

A string indicating how the C<MasterReleaseVersion> objects to be returned.
Defaults to no sorting.  The following fields can be specified:

  released title format label catno country

=item sort-order

A string indicating the sort order of any sort action to be performed
on the C<MasterReleaseVersion> objects to be returned.  Defaults to "asc".
The following fields can be specified:

  asc desc

=head2 release

=begin code :lang<raku>

my $release = $discogs.release(249504, currency => "EUR");

=end code

Fetch the information for the given release ID and return that in
an L<API::Discogs::Release> object.  Optionally takes a named
C<currency> parameter that should have one of the supported
currency strings.  This defaults to the value for the currency
that was (implicitely) specified when creating the C<API::Discogs>
object.

=head1 ADDITIONAL CLASSES

In alphatical order:

=head2 API::Discogs::Artist

=item data-quality

String indicating the quality of the data.

=item id

The artist ID.

=item images

A list of L<API::Discogs::Image> objects for this artist.

=item members

A list of L<API::Discogs::Member> objects of this artist.

=item name

String with the main name of the artist.

=item namevariations

A list of strings with alternate names / spellings of the artist.

=item profile

A string with a profile of the artist.

=item releases-url

The URL to fetch all of the releases of this Artist using the Discogs API.

=item resource-url

The URL to fetch this object using the Discogs API.

=item uri

The URL to access information about this artist on the Discogs website.

=item urls

A list of URLs associated with this artist.

=head2 API::Discogs::ArtistReleases

Retrieves a list of all L<API::Discogs::ArtistRelease> objects that were
made by the given artist ID, and pagination settings.

=item first-page

Returns the first page of the information of this object, or C<Nil> if
already on the first page.

=item first-page-url

The URL to fetch the data of the B<first> page of this object using the
Discogs API.  Returns C<Nil> if the there is only one page of information
available.

=item items

An integer indicating the total number of L<API::Discogs::LabelRelease>
objects there are available for this artist.

=item last-page

Returns the last page of the information of this object, or C<Nil> if
already on the last page.

=item last-page-url

The URL to fetch the data of the B<last> page of this object using the
Discogs API.  Returns C<Nil> if already on the last page.

=item next-page

Returns the next page of the information of this object, or C<Nil> if
already on the last page.

=item next-page-url

The URL to fetch the data of the B<next> page of this object using the
Discogs API.  Returns C<Nil> if already on the last page.

=item page

An integer indicating the page number of this object.

=item pages

An integer indicating the number of pages of information available for
this object.

=item pagination

The L<API::Discogs::Pagination> object associted with this object.
Usually not needed, as its information is available in shortcut methods.

=item per-page

An integer representing the maximum number of items on a page.

=item previous-page

Returns the previous page of the information of this object, or C<Nil> if
already on the first page.

=item previous-page-url

The URL to fetch the data of the B<previous> page of this object using the
Discogs API.  Returns C<Nil> if already on the first page.

=item releases

A list of L<API::Discogs::ArtistRelease> objects.

=head2 API::Discogs::ArtistSummary

=item anv

A string with the artist name variation.

=item id

The artist ID.

=item join

A string indicating joining.

=item name

A string with the name.

=item resource-url

The URL to fetch the full artist information using the Discogs API.

=item role

A string indicating the role of this artist.

=item tracks

A string indicating the tracks on which the artist participated.

=head2 API::Discogs::Community

Usually obtained indirectly from the C<community> method on the
L<API::Discogs::Release> object.  These methods can also be called
directly on the L<API::Discogs::Release> object, as these are also
provided as shortcuts.

=item contributors

A list of L<API::Discogs::User> objects of contributors to the
community information of this release.

=item data-quality

A string describing the quality of the data of this release.

=item have

An integer indicating how many community members have this release.

=item rating

A rational number indicating the rating the members of the community
have given this release.

=item status

The status of the information about this release in the community.

=item submitter

The L<API::Discogs::User> object for the submitter of this release.

=item want

An integer indicating how many community members want to have this release.

=head2 API::Discogs::Image

=item height

The height of the image in pixels.

=item resource-url

The URL to access this image on the Discogs image website.

=item type

String with the type for this image: either "primary" or "secondary".

=item uri

The URL to access this image on the Discogs image website.

=item uri150

The URL to access a 150x150 pixel version of the  image on the Discogs
image website.

=item width

The width of the image in pixels.

=head2 API::Discogs::Label

The C<Label> object represents a label, company, recording studio,
location, or other entity involved with L<API::Discogs::Artist>s and
L<API::Discogs::Release>s.  Labels were recently expanded in scope
to include things that aren't labels – the name is an artifact of this
history.

=item contact-info

A string with contact information for this label.

=item data-quality

A string describing the quality of the data of this label.

=item id

The ID of this label.

=item images

A list of L<API::Discogs::Image> objects for this label.

=item name

A string with the name of this label.

=item profile

A string with a profile about this label.

=item releases-url

A URL to retrieve all the L<API::Discogs::Release> objects associated
with this label using the Discogs API.

=item resource-url

The URL to obtain the information about this label using the Discogs API.

=item sublabels

A list of L<API::Discogs::SubLabel> objects describing subdivisions of this label.

=item uri

A URL to see the information of this label on the Discogs website.

=item urls

A list of URLs related to this label.

=head2 API::Discogs::LabelReleases

Retrieves a list of all L<API::Discogs::LabelRelease> objects that are
versions of a given master release ID, and pagination settings.

=item first-page

Returns the first page of the information of this object, or C<Nil> if
already on the first page.

=item first-page-url

The URL to fetch the data of the B<first> page of this object using the
Discogs API.  Returns C<Nil> if the there is only one page of information
available.

=item items

An integer indicating the total number of L<API::Discogs::LabelRelease>
objects there are available for label.

=item last-page

Returns the last page of the information of this object, or C<Nil> if
already on the last page.

=item last-page-url

The URL to fetch the data of the B<last> page of this object using the
Discogs API.  Returns C<Nil> if already on the last page.

=item next-page

Returns the next page of the information of this object, or C<Nil> if
already on the last page.

=item next-page-url

The URL to fetch the data of the B<next> page of this object using the
Discogs API.  Returns C<Nil> if already on the last page.

=item page

An integer indicating the page number of this object.

=item pages

An integer indicating the number of pages of information available for
this object.

=item pagination

The L<API::Discogs::Pagination> object associted with this object.
Usually not needed, as its information is available in shortcut methods.

=item per-page

An integer representing the maximum number of items on a page.

=item previous-page

Returns the previous page of the information of this object, or C<Nil> if
already on the first page.

=item previous-page-url

The URL to fetch the data of the B<previous> page of this object using the
Discogs API.  Returns C<Nil> if already on the first page.

=item releases

A list of L<API::Discogs::LabelRelease> objects.

=head2 API::Discogs::MasterRelease

The MasterRelease object represents a set of similar
L<API::Discogs::Release>s.  Master releases have a "main release"
which is often the chronologically earliest.

=item artists

A list of L<API::Discogs::ArtistSummary> objects for this master release.

=item data-quality

A string describing the quality of the data of this master release.

=item genres

A list of strings describing the genres of this master release.

=item id

The ID of this master release.

=item images

A list if L<API::Discogs::Image> objects associated with this master release.

=item lowest-price

The lowest price seen for any of the releases of this master release
on the Discogs Marketplace, in the currency that was (implicitely)
specified when the L<API::Discogs> object was made.

=item main-release

The ID of the L<API::Discogs::Release> object that is considered to
be the main release.

=item main-release-url

The URL to access the data of the main release using the Discogs API.

=item most-recent-release

The ID of the L<API::Discogs::Release> object that is considered to
be the most recent release.

=item most-recent-release-url

The URL to access the data of the most recent release using the
Discogs API.

=item num-for-sale

An integer indicating the number of copies of any release of this
main release, that are for sale on the Discogs Marketplace.

=item resource-url

The URL to obtain the information about this master release using
the Discogs API.

=item styles

A list of strings describing the styles of this master release.

=item title

A string with the title of this master release.

=item tracklist

A list of L<API::Discogs::Track> objects describing the tracks of this master
release.

=item uri

A URL to see the information of this master release on the Discogs
website.

=item versions-url

A URL to fetch the L<API::Discogs::MasterReleaseVersion> objects for this
master release using the Discogs API.

=item videos

A list of L<API::Discogs::Video> objects associated with this master
release.

=item year

An integer for the year in which this master release was released.

=head2 API::Discogs::MasterReleaseVersions

Retrieves a list of all L<API::Discogs::MasterReleaseVersion> objects that are
versions of a given master release ID, and pagination settings.

=item filter-facets

A list of L<API::Discogs::FilterFacet> objects associated with this object.

=item filters

A list of L<API::Discogs::Filter> objects associated with this object.

=item first-page

Returns the first page of the information of this object, or C<Nil> if
already on the first page.

=item first-page-url

The URL to fetch the data of the B<first> page of this object using the
Discogs API.  Returns C<Nil> if the there is only one page of information
available.

=item items

An integer indicating the total number of L<API::Discogs::MasterReleaseVersion>
objects there are available for this master release.

=item last-page

Returns the last page of the information of this object, or C<Nil> if
already on the last page.

=item last-page-url

The URL to fetch the data of the B<last> page of this object using the
Discogs API.  Returns C<Nil> if already on the last page.

=item next-page

Returns the next page of the information of this object, or C<Nil> if
already on the last page.

=item next-page-url

The URL to fetch the data of the B<next> page of this object using the
Discogs API.  Returns C<Nil> if already on the last page.

=item page

An integer indicating the page number of this object.

=item pages

An integer indicating the number of pages of information available for
this object.

=item pagination

The L<API::Discogs::Pagination> object associted with this object.
Usually not needed, as its information is available in shortcut methods.

=item per-page

An integer representing the maximum number of items on a page.

=item previous-page

Returns the previous page of the information of this object, or C<Nil> if
already on the first page.

=item previous-page-url

The URL to fetch the data of the B<previous> page of this object using the
Discogs API.  Returns C<Nil> if already on the first page.

=item versions

A list of L<API::Discogs::MasterReleaseVersion> objects.

=head2 API::Discogs::Member

=item active

A Boolean indicating whether this member is still active with the
L<API::Discogs::Artist> it is associated with.

=item id

The ID of this member as a separate L<API::Discogs::Artist>.

=item name

The name of this member.

=item resource-url

The URL to fetch L<API::Discogs::Artist> object of this member using
the Discogs API.

=head2 API::Discogs::Pagination

This object is usually created as part of some kind of search result that
allows for pagination.

=item items

An integer with the number of items in this page.

=item page

An integer with the page number of the information of this page.

=item pages

An integer with the total number of pages available with the current
C<per-page> value.

=item per-page

An integer with the maximum number of items per page.

=item urls

A hash of URLs for moving between pages.  Usually accessed with
shortcut methods of the object incorporating this C<Pagination>
object.

=head2 API::Discogs::Rating

A rating, usually automatically created with a L<API::Discogs::Community>
object.

=item average

A rational value indicating the average rating of the object associated
with the associated L<API::Discogs::Community> object.

=item count

An integer value indicating the number of votes cast by community members.

=head2 API::Discogs::Release

The C<API::Discogs::Release> object represents a particular physical or
digital object released by one or more L<API::Discogs::Artist>s.

=item artists

A list of L<API::Discogs::ArtistSummary> objects for this release.

=item average

A rational value indicating the average rating of this release by
community members.

=item artists-sort

A string with the artists, sorted.

=item community

The L<API::Discogs::Community> object with all of the Discogs community
information associated with this release.

=item companies

A list of L<API::Discogs::CatalogEntry> objects of entities that had
something to do with this release.

=item contributors

A list of L<API::Discogs::User> objects of contributors to the community
information of this release.

=item count

An integer value indicating the number of votes cast by community members
about this release.

=item country

A string with the country of origin of this release.

=item data-quality

String indicating the quality of the data.

=item date-added

A C<Date> object of the date this release was added to the Discogs system.

=item date-changed

A C<Date> object of the date this release was last changed in the Discogs
system.

=item estimated-weight

An integer value to indicate the weight of this release compared to other
release in the L<API::Discogs::MasterRelease>.

=item extraartists

A list of L<API::Discogs::ArtistSummary> objects for additional artists
in this release.

=item format-quantity

An integer value for the number of formats available for this release.

=item formats

A list of L<API::Discogs::Format> objects that are available for this
release.

=item genres

A list of strings describing the genres of this release.

=item have

An integer indicating how many community members have this release.

=item id

The integer value that identifies this release.

=item identifiers

A list of L<API::Discogs::Identifier> objects for this release.

=item images

A list of L<API::Discogs::Image> objects for this release.

=item labels

A list of L<API::Discogs::CatalogEntry> objects that serve as a
"label"  for this release.

=item lowest-price

A rational value indicating the lowest price if this release is
available in the Discogs Marketplace in the currency that was
(implicitely) specified when creating the L<API::Discogs> object.

=item master-id

The integer value of the L<API::Discogs::MasterRelease> id of this
release.

=item master-url

The URL to fetch the master release of this release using the
Discogs API.

=item notes

A string with additional notes about this release.

=item num-for-sale

An integer value indicating the number of copies for sale for this release
on the Discogs Marketplace.

=item rating

A rational number indicating the rating the members of the community
have given this release.

=item release-formatted

A string with a human readable form of the date this release was released.

=item released

A string with a machine readable for of the date this release was released.

=item resource-url

The URL to fetch this L<API::Discogs::Release> object using the Discogs API.

=item series

A list of L<API::Discogs::CatalogEntry> objects of which this release is
a part of.

=item status

A string indicating the status of the information of this release.

=item styles

A list of strings indicating the styles of this release.

=item submitter

The L<API::Discogs::User> object for the submitter of this release.

=item thumb

A URL for a thumbnail image for this release.

=item title

A string with the title of this release.

=item tracklist

A list of L<API::Discogs::Track> objects of this release.

=item uri

The URL to access this release on the Discogs image website.

=item videos

A list of L<API::Discogs::Video> objects associated with this release.

=item want

An integer indicating how many community members want to have this release.

=item year

An integer value of the year this release was released.

=head2 API::Discogs::SearchResults

Retrieves a list of L<API::Discogs::Searchresult> objects that match
the given query parameters, and pagination settings.

=item first-page

Returns the first page of the information of this object, or C<Nil> if
already on the first page.

=item first-page-url

The URL to fetch the data of the B<first> page of this object using the
Discogs API.  Returns C<Nil> if the there is only one page of information
available.

=item items

An integer indicating the total number of L<API::Discogs::SearchResult>
objects there are available.

=item last-page

Returns the last page of the information of this object, or C<Nil> if
already on the last page.

=item last-page-url

The URL to fetch the data of the B<last> page of this object using the
Discogs API.  Returns C<Nil> if already on the last page.

=item next-page

Returns the next page of the information of this object, or C<Nil> if
already on the last page.

=item next-page-url

The URL to fetch the data of the B<next> page of this object using the
Discogs API.  Returns C<Nil> if already on the last page.

=item page

An integer indicating the page number of this object.

=item pages

An integer indicating the number of pages of information available for
this object.

=item pagination

The L<API::Discogs::Pagination> object associted with this object.
Usually not needed, as its information is available in shortcut methods.

=item per-page

An integer representing the maximum number of items on a page.

=item previous-page

Returns the previous page of the information of this object, or C<Nil> if
already on the first page.

=item previous-page-url

The URL to fetch the data of the B<previous> page of this object using the
Discogs API.  Returns C<Nil> if already on the first page.

=item results

A list of L<API::Discogs::SearchResult> objects.

=head2 API::Discogs::SubLabel

This object is usually created as part of the L<API::Discogs::Label>
object.

=item id

The ID of this sublabel.

=item name

A string with the name of this sublabel.

=item resource-url

The URL to get the full L<API::Discogs::Label> information of this
C<SubLabel> using the Discogs API.

=head2 API::Discogs::Track

The information about a track on a release, usually created automatically
as part of a L<API::Discogs::Release> object.

=item duration

A string indicating the duration of this track, usually as "mm:ss".

=item position

A string indication the position of this track, "A" side or "B" side.

=item title

A string containing the title of this track.

=item type

A string to indicate the type of track, usually "track".

=head2 API::Discogs::Video

The information about a video, usually created automatically as part
of a L<API::Discogs::Release> object.

=item description

A string containing the description of this C<Video> object.

=item duration

A string indicating the duration of the video, usually as "mm:ss".

=item embed

A Bool indicating whether this video can be embedded.

=item title

A string containing the title (usually "artist - title") of this
C<Video> object.

=item uri

The URL of the video, usually a link to a YouTube video.

=head1 AUTHOR

Elizabeth Mattijsen <liz@wenzperl.nl>

Source can be located at: https://github.com/lizmat/API-Discogs . Comments
and Pull Requests are welcome.

=head1 COPYRIGHT AND LICENSE

Copyright 2020 Elizabeth Mattijsen

This library is free software; you can redistribute it and/or modify it under
the Artistic License 2.0.

=end pod

# vim: expandtab shiftwidth=4
