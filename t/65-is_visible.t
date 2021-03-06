#!perl -w
use strict;
use Test::More;
use WWW::Mechanize::Firefox;

my $mech = eval { WWW::Mechanize::Firefox->new( 
    autodie => 1,
    events => ['DOMContentLoaded', 'load', qw[DOMFrameContentLoaded DOMContentLoaded error abort stop]],
    #log => [qw[debug]],
)};

if (! $mech) {
    my $err = $@;
    plan skip_all => "Couldn't connect to MozRepl: $@";
    exit
};

my @files = qw<
     65-is_visible_text.html
     65-is_visible_hidden.html
     65-is_visible_none.html
     65-is_visible_remove.html
     65-is_visible_reload.html
>;

# Check that we can execute JS
$mech->get_local($files[0]);
$mech->allow('javascript' => 1);
my ($triggered,$type,$ok);
eval {
    ($triggered, $type) = $mech->eval_in_page('timer');
    $ok = 1;
};
if (! $triggered) {
    plan skip_all => "Couldn't get at 'timer'. Do you have a Javascript blocker?";
    exit;
} else {
    plan tests => 0+@files*12;
};

for my $file (@files) {
    $mech->get_local($file);
    is $mech->title, $file, "We loaded the right file ($file)";
    $mech->allow('javascript' => 1);
    my ($timer,$type) = $mech->eval_in_page('timer');

    ok $mech->is_visible(selector => 'body'), "We can see the body";

    ok !$mech->is_visible(selector => '#standby'), "We can't see #standby";
    my @status = 
    ok !$mech->is_visible(selector => '.status', any => 1), "We can't see .status even though there exist multiple such elements";
    $mech->click({ selector => '#start', synchronize => 0 });
    ok $mech->is_visible(selector => '#standby'), "We can see #standby";
    my $ok = eval {
        $mech->wait_until_invisible(selector => '#start', timeout => $timer+2);
        1;
    };
    is $ok, 1, "No timeout" or diag $@;
    ok !$mech->is_visible(selector => '#standby'), "The #standby is invisible";

    # Now test with plain text
    $mech->get_local($file);
    is $mech->title, $file, "We loaded the right file ($file)";
    $mech->allow('javascript' => 1);
    ($timer,$type) = $mech->eval_in_page('timer');

    ok !$mech->is_visible(xpath => '//*[contains(text(),"stand by")]'), "We can't see the standby message";
    $mech->click({ selector => '#start', synchronize => 0 });
   
    ok $mech->is_visible(xpath => '//*[contains(text(),"stand by")]'), "We can see the standby message";
    $ok = eval {
        $mech->wait_until_invisible(xpath => '//*[contains(text(),"stand by")]', timeout => $timer+2);
        1;
    };
    is $ok, 1, "No timeout" or diag $@;
    ok !$mech->is_visible(selector => '#standby'), "The #standby is invisible";
};