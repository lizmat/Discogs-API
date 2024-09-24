use Test;
use Discogs::API;

use lib $?FILE.IO.parent;
use TestDiscogs;

my $id = 1000;
my $discogs := Discogs::API.new.test-with($?FILE.IO.sibling("client"));
my $master-release-versions := $discogs.master-release-versions($id);

isa-ok $master-release-versions, Discogs::API::MasterReleaseVersions,
  'did we get a master release versions';

my @filter-facets := $master-release-versions.filter-facets;
is +@filter-facets, 4, 'did we get correct number of filter facets';

for @filter-facets -> $filter-facet {
    isa-ok $filter-facet, Discogs::API::FilterFacet,
      'did we get a filter facet object';

    ok $filter-facet.allows-multiple-values ~~ Bool,
      'is allow multiple values a bool';
    ok $filter-facet.id ~~ Str, 'is id a string';
    ok $filter-facet.title ~~ Str, 'is title a string';

    for $filter-facet.values -> $value {
        isa-ok $value, Discogs::API::Value, 'did we get a value object';
        ok $value.count ~~ UInt, 'did we get an unsigned int for count';
        ok $value.title ~~ Str, 'did we get a string for title';
        ok $value.value ~~ Str, 'did we get a string for value';
    }
}

my %filters := $master-release-versions.filters;
is +%filters, 2, 'did we get correct number of filters';
for %filters -> %filter {    # XXX should be %filters.values
    for %filter.values -> %hash {
        for %hash.values -> \value {
            ok value ~~ UInt, 'did we get an unsigned int as value';
        }
    }
}

my @versions := $master-release-versions.versions;
is +@versions, 6, 'did we get correct number of versions';

for @versions -> $version {
    isa-ok $version, Discogs::API::MasterReleaseVersion,
      'did we get a master release version object';

    ok $version.catno ~~ Str, 'did we get a string for catalog number';
    in-community-collection-wantlist-ok($version);

    ok $version.country ~~ Country, 'did we get a country for country';
    ok $version.format ~~ Str, 'did we get a string for format';
    ok $version.id ~~ UInt, 'did we get an unsigned integer for id';

#    my %label := $version.label;  #  XXX
#dd %label;
#    for %label.values -> $value {
#        ok $value ~~ Str, 'did we get a string for value';
#    }

    for $version.major-formats -> $major-format {
        ok $major-format ~~ Str, 'did we get a string for major format';
    }

    ok $version.released ~~ Year, 'did we get a year for released';
    ok $version.resource-url ~~ URL, 'did we get a URL for resource url';


    ok $version.status ~~ Status, 'did we get a status for status';
    ok $version.thumb ~~ URL, 'did we get a URL for thumb';
    ok $version.title ~~ Str, 'did we get a string for title';
    in-user-collection-wantlist-ok($version);
}

done-testing;

# vim: expandtab shiftwidth=4
