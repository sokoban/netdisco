package App::Netdisco::Web::Plugin::Report::Netbios;

use Dancer ':syntax';
use Dancer::Plugin::DBIC;
use Dancer::Plugin::Auth::Extensible;

use App::Netdisco::Web::Plugin;

register_report(
    {   category     => 'Node',
        tag          => 'netbios',
        label        => 'NetBIOS Inventory',
        provides_csv => 1,
    }
);

hook 'before_template' => sub {
    my $tokens = shift;

    return
        unless ( request->path eq uri_for('/report/netbios')->path
        or
        index( request->path, uri_for('/ajax/content/report/netbios')->path )
        == 0 );

    # used in the search sidebar template to set selected items
    foreach my $opt (qw/domain/) {
        my $p = (
            ref [] eq ref param($opt)
            ? param($opt)
            : ( param($opt) ? [ param($opt) ] : [] )
        );
        $tokens->{"${opt}_lkp"} = { map { $_ => 1 } @$p };
    }
};

get '/ajax/content/report/netbios' => require_login sub {

    my $domain = param('domain');

    my $rs = schema('netdisco')->resultset('NodeNbt');

    if ( defined $domain ) {
        my $search = $domain eq 'blank' ? '' : $domain;
        $rs
            = $rs->search( { domain => $search } )
            ->order_by( [ { -asc => 'domain' }, { -desc => 'time_last' } ] )
            ->hri;
    }
    else {
        $rs = $rs->search(
            {},
            {   select   => [ 'domain', { count => 'domain' } ],
                as       => [qw/ domain count /],
                group_by => [qw/ domain /]
            }
        )->order_by( { -desc => 'count' } )->hri;

    }

    my @results = $rs->all;
    return unless scalar @results;

    if ( request->is_ajax ) {
        my $json = to_json( \@results );
        template 'ajax/report/netbios.tt',
            { results => $json, opt => $domain },
            { layout => undef };
    }
    else {
        header( 'Content-Type' => 'text/comma-separated-values' );
        template 'ajax/report/netbios_csv.tt',
            { results => \@results, opt => $domain },
            { layout => undef };
    }
};

1;
