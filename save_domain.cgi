#!/usr/bin/perl

require 'virtualmin-nginx-fpm-lib.pl';
&ReadParse();

#use Data::Dumper;

&ui_print_header(undef, $module_info{'desc'}, "", undef, 1, 1);
$d = &virtual_server::get_domain_by("dom", $in{'dom'});

if(($in{'fpm_pm_max_spare_servers'} > $in{'fpm_pm_max_children'}) or ($in{'fpm_pm_min_spare_servers'} > $in{'fpm_pm_max_children'})) {
    &ui_print_header(undef, $module_info{'desc'}, "", undef, 1, 1);
    print("<h4>$text{'error_max_children'}</h4>");
    &ui_print_footer('javascript:history.back()', $text{'previous_page'});
} else {
    $d->{'ssl'} = $in{'ssl'} ? 1 : 0;
    &virtual_server::save_domain($d);
    %conf = ();
    $conf{'pm'} = $in{'fpm_pm_type'};
    $conf{'pm.max_children'} = $in{'fpm_pm_max_children'};
    $conf{'pm.start_servers'} = $in{'fpm_pm_start_servers'};
    $conf{'pm.min_spare_servers'} = $in{'fpm_pm_min_spare_servers'};
    $conf{'pm.max_spare_servers'} = $in{'fpm_pm_max_spare_servers'};
    $conf{'pm.max_requests'} = $in{'fpm_pm_max_requests'};

    &$virtual_server::first_print($text{'feat_modify_domain'});
    &unlink_file(
        "$config{'nginx_sites_available'}/$d->{'dom'}.conf",
        "$config{'fpm_poold'}/$d->{'dom'}.conf"
    );
    if($config{'nginx_sites_enabled'}) {
        &unlink_file(
            "$config{'nginx_sites_enabled'}/$d->{'dom'}.conf",
        );
    }
    &create_nginx_config($d);
    &create_fpm_pool($d, \%conf);
    &reload_services;
    &$virtual_server::second_print($virtual_server::text{'setup_done'});
}
