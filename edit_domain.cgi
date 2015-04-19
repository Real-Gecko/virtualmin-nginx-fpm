#!/usr/bin/perl

require 'virtualmin-nginx-fpm-lib.pl';
&ReadParse();

@types= (
        ['dynamic', 'Dynamic'],
        ['static', 'Static'],
        ['ondemand', 'On demand']
    );
$d = &virtual_server::get_domain_by("dom", $in{'dom'});

&ui_print_header(undef, $module_info{'desc'}, "", undef, 1, 1);
print &ui_post_header("$in{'dom'}");

%conf = get_fpm_config($d);

print &ui_form_start("save_domain.cgi", "post");
print &ui_hidden("dom", $in{'dom'}),"\n";
print &ui_table_start($text{'nginx_fpm_config'},  "style='width: 100%;'", 2);
print &ui_table_row($text{'nginx_ssl'}, &ui_checkbox("ssl", "ssl", undef, $d->{'ssl'}));

print &ui_table_span($text{'fpm_config'});

print &ui_table_row($text{'fpm_pm_type'}, &ui_select("fpm_pm_type", $conf{'pm'}, \@types));
print &ui_table_row($text{'fpm_pm_max_children'}, &ui_textbox("fpm_pm_max_children", $conf{'pm.max_children'}, 50));
print &ui_table_row($text{'fpm_pm_start_servers'}, &ui_textbox("fpm_pm_start_servers", $conf{'pm.start_servers'}, 50));
print &ui_table_row($text{'fpm_pm_min_spare_servers'}, &ui_textbox("fpm_pm_min_spare_servers", $conf{'pm.min_spare_servers'}, 50));
print &ui_table_row($text{'fpm_pm_max_spare_servers'}, &ui_textbox("fpm_pm_max_spare_servers", $conf{'pm.max_spare_servers'}, 50));
print &ui_table_row($text{'fpm_pm_max_requests'}, &ui_textbox("fpm_pm_max_requests", $conf{'pm.max_requests'}, 50));

print &ui_table_end();
print &ui_form_end([ [ "save", $text{'save'} ] ]);

&ui_print_footer("/", $text{'index'});
