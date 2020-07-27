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
    method first-page-url(::?CLASS:D:)    { $.pagination.urls<first> // Nil }
    method next-page-url(::?CLASS:D:)     { $.pagination.urls<next>  // Nil }
    method previous-page-url(::?CLASS:D:) { $.pagination.urls<prev>  // Nil }
    method last-page-url(::?CLASS:D:)     { $.pagination.urls<first> // Nil }

    method items(::?CLASS:D:)    { $.pagination.items }
    method page(::?CLASS:D:)     { $.pagination.page }
    method pages(::?CLASS:D:)    { $.pagination.pages }
    method per-page(::?CLASS:D:) { $.pagination.per-page }
}

#--------------- actual class and its attributes -------------------------------

our class API::Discogs:ver<0.0.1>:auth<cpan:ELIZABETH> {
    has Cro::HTTP::Client $.client = $default-client;
    has AllowedCurrency $.currency = %*ENV<DISCOGS_CURRENCY> // @currencies[0];
    has UInt            $.per-page = 50;
    has Str $!token  is built = %*ENV<DISCOGS_TOKEN>;
    has Str $.key;
    has Str $!secret is built;

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

#--------------- the specific methods one can call -----------------------------

    # helper method for setting pagination parameters
    method !pagination(%nameds --> Str:D) {
        my UInt $page     := %nameds<page>:delete     // 1;
        my UInt $per-page := %nameds<per-page>:delete // $.per-page;
        "page=$page&per_page=$per-page"
    }

    # main worker for creating non-asynchronous work
    method GET(API::Discogs:D: $uri, $class) {
        my @headers;
        @headers.push((Authorization => "Discogs key=$.key, secret=$!secret"))
          if $!secret && $.key;
        @headers.push((Authorization => "Discogs token=$!token"))
          if $!token;

        my $resp := await $.client.get($uri, :@headers);
        $class.new(await $resp.body)
    }

    multi method client(API::Discogs:U:) { $default-client }
    multi method client(API::Discogs:D:) { $!client }

#-------------- getting the information of a specific release -------------------

    our class Release does Hash2Class[
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

    our class MasterRelease does Hash2Class[
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

    our class ReleaseVersion does Hash2Class[
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

    our class ReleaseVersions does Hash2Class[
      '@filter_facets' => { type => FilterFacet, name => 'filter-facets' },
      '@filters'       => Filters,
      '@versions'      => ReleaseVersion,
      pagination       => Pagination,
    ] does PaginationShortcuts { }

    method release-versions(API::Discogs:D:
      UInt:D $id
    --> ReleaseVersions:D) {
        self.GET(
          "/masters/$id/versions?" ~ self!pagination(%_),
          ReleaseVersions
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

    our class LabelReleases does Hash2Class[
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

    our class ArtistReleases does Hash2Class[
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

    our class SearchResults does Hash2Class[
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

API::Discogs provides a Raku library with access to the L<Discogs|https://discogs.com>
data and functions.

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
a L<API::Discogs::Artist> object.

=head1 ADDITIONAL CLASSES

In alphatical order:

=head2 API::Discogs::Artist

=item data-quality

String indicating the quality of the data.

=item id

The artist ID.

=item images

A list of L<Image> objects for this artist.

=item members

A list of L<Member> objects of this artist.

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
L<Release> object.  These methods can also be called directly on
the L<Release> object, as these are also provided as shortcuts.

=item contributors

A list of L<User> objects of contributors to the community information
of this release.

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

The L<User> object for the submitter of this release.

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
location, or other entity involved with L<Artist>s and L<Release>s.
Labels were recently expanded in scope to include things that aren't
labels – the name is an artifact of this history.

=item contact-info

A string with contact information for this label.

=item data-quality

A string describing the quality of the data of this label.

=item id

The ID of this label.

=item images

A list of L<Image> objects for this label.

=item name

A string with the name of this label.

=item profile

A string with a profile about this label.

=item releases-url

A URL to retrieve all the L<Release> objects associated with this
label using the Discogs API.

=item resource-url

The URL to obtain the information about this label using the Discogs API.

=item sublabels

A list of L<SubLabel> objects describing subdivisions of this label.

=item uri

A URL to see the information of this label on the Discogs website.

=item urls

A list of URLs related to this label.

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

=head2 API::Discogs::Rating

A rating, usually automatically created with a L<Community> object.

=item average

A rational value indicating the average rating of the object associated
with the associated L<Community> object.

=item count

An integer value indicating the number of votes cast by community members.

=head2 API::Discogs::Release

=item artists

A list of L<ArtistSummary> objects for this release.

=item artists-sort

A string with the artists, sorted.

=item community

The L<Community> object with all of the Discogs community information
associated with this release.

=item companies

A list of L<CatalogEntry> objects of entities that had something to do
with this release.

=item contributors

A list of L<User> objects of contributors to the community information
of this release.

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
release in the L<MasterRelease>.

=item extraartists

A list of L<ArtistSummary> objects for additional artists in this release.

=item format-quantity

An integer value for the number of formats available for this release.

=item formats

A list of L<Format> objects that are available for this release.

=item genres

A list of strings describing the genres of this release.

=item have

An integer indicating how many community members have this release.

=item id

The integer value that identifies this release.

=item identifiers

A list of L<Identifier> objects for this release.

=item images

A list of L<Image> objects for this release.

=item labels

A list of L<CatalogEntry> objects that serve as a "label"  for this release.

=item lowest-price

A real value indicating the lowest price if this release is available in the
Discogs Marketplace.

=item master-id

The integer value of the L<MasterRelease> id of this release.

=item master-url

The URL to fetch the master release of this release using the Discogs API.

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

A list of L<CatalogEntry> objects of which this release is a part of.

=item status

A string indicating the status of the information of this release.

=item styles

A list of strings indicating the styles of this release.

=item submitter

The L<User> object for the submitter of this release.

=item thumb

A URL for a thumbnail image for this release.

=item title

A string with the title of this release.

=item tracklist

A list of L<Track> objects of this release.

=item uri

The URL to access this release on the Discogs image website.

=item videos

A list of L<Video> objects associated with this release.

=item want

An integer indicating how many community members want to have this release.

=item year

An integer value of the year this release was released.

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

=head2 API::Discogs::SubLabel

This object is usually created as part of the L<Label> object.

=item id

The ID of this sublabel.

=item name

A string with the name of this sublabel.

=item resource-url

The URL to get the full L<Label> information of this C<SubLabel> using
the Discogs API.

=head2 API::Discogs::Track

The information about a track on a release, usually created automatically
as part of a L<Release> object.

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
of a L<Release> object.

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
