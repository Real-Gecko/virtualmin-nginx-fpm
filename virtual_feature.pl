do 'virtualmin-nginx-fpm-lib.pl';

sub feature_name {
    return $text{'feat_name'};
}

sub feature_label {
    return $text{'feat_label'};
}

sub feature_losing {
    return $text{'feat_loosing'};
}

sub feature_disname {
    return $text{'feat_disname'};
}

sub feature_check {
    if (! &has_command($config{'nginx_cmd'})) {
        return $text{'feat_req_nginx'};
    }
    if (! &has_command($config{'fpm_cmd'})) {
        return $text{'feat_req_fpm'};
    } else {
        return undef;
    }
}

sub feature_clash {
    my ($d) = @_;
    if ($d->{'virtualmin-nginx'} or $d{'web'}) {
        return $text{'feat_clash'};
    }
    if (-r "$config{'nginx_sites_available'}/$d->{'dom'}.conf") {
        return $text{'feat_nginx_exists'};
    }
    if (-r "$config{'fpm_poold'}/$d->{'dom'}.conf") {
        return $text{'feat_fpm_exists'};
    } else {
        return undef;
    }
}

sub feature_depends {
    my ($d) = @_;
    return $text{'feat_edepunix'} if (!$d->{'unix'} && !$d->{'parent'});
    return $text{'feat_edepdir'} if (!$d->{'dir'} && !$d->{'alias'});
    return $text{'feat_eapache'} if ($d->{'web'});
    return $text{'feat_nginx'} if ($d->{'virtualmin-nginx'});
    return undef;
}

sub feature_suitable {
    my ($parentdom, $aliasdom, $subdom) = @_;
    return $aliasdom ? 0 : 1;
}

sub feature_setup {
    my ($d) = @_;

    %conf = ();
    $conf{'pm'} = 'dynamic';
    $conf{'pm.max_children'} = 5;
    $conf{'pm.start_servers'} = 2;
    $conf{'pm.min_spare_servers'} = 1;
    $conf{'pm.max_spare_servers'} = 3;
    $conf{'pm.max_requests'} = 500;

    &virtual_server::generate_default_certificate($d);
    
    &$virtual_server::first_print($text{'feat_setup'});
    &create_nginx_config($d);
    &create_fpm_pool($d, \%conf);

    &$virtual_server::second_print($virtual_server::text{'setup_done'});
    # Add nginx user to domain group
    my $web_user = $config{'nginx_user'};
    if ($web_user && $web_user ne 'none') {
        &virtual_server::add_user_to_domain_group($d, $web_user, 'setup_webuser');
    }
    &reload_services;
}

sub feature_delete {
    my ($d) = @_;
    &$virtual_server::first_print($text{'feat_delete'});
    &unlink_file(
        "$config{'nginx_sites_available'}/$d->{'dom'}.conf",
        "$config{'fpm_poold'}/$d->{'dom'}.conf"
    );
    if($config{'nginx_sites_enabled'}) {
        &unlink_file(
            "$config{'nginx_sites_enabled'}/$d->{'dom'}.conf",
        );
    }
    &reload_services;
    &$virtual_server::second_print($virtual_server::text{'setup_done'});
}

sub feature_modify {
    my ($d, $oldd) = @_;
#    if ($d->{'dom'} ne $oldd->{'dom'}) {
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
        %conf = get_fpm_config($d);
        &create_fpm_pool($d, \%conf);
        &reload_services;
        &$virtual_server::second_print($virtual_server::text{'setup_done'});
#    }
}

sub feature_disable {
    my ($d) = @_;
    &$virtual_server::first_print($text{'feat_disable'});
    if($config{'nginx_sites_enabled'}) {
        &unlink_file("$config{'nginx_sites_enabled'}/$d->{'dom'}.conf");
    } else {
        &unlink_file("$config{'nginx_sites_available'}/$d->{'dom'}.conf");        
    }
    &rename_file("$config{'fpm_poold'}/$d->{'dom'}.conf", "$config{'fpm_poold'}/$d->{'dom'}.conf.dis");
    &reload_services;
    &$virtual_server::second_print($virtual_server::text{'setup_done'});
}

sub feature_enable {
    my ($d) = @_;
    &$virtual_server::first_print($text{'feat_enable'});
    if($config{'nginx_sites_enabled'}) {
        &symlink_file("$config{'nginx_sites_available'}/$d->{'dom'}.conf", "$config{'nginx_sites_enabled'}/$d->{'dom'}.conf");
    } else {
        &create_nginx_config($d);
    }
    &rename_file("$config{'fpm_poold'}/$d->{'dom'}.conf.dis", "$config{'fpm_poold'}/$d->{'dom'}.conf");
    &reload_services;
    &$virtual_server::second_print($virtual_server::text{'setup_done'});
}

sub feature_import {
    my ($dname, $user, $db) = @_;
    if (-r "$config{'nginx_sites_available'}/$dname.conf" or -r "$config{'fpm_poold'}/$dname.conf") {
        return 1;
    } else {
        return 0;
    }
}

sub feature_links {
    local ($d) = @_;
    return ( { 'mod' => $module_name,
               'desc' => $text{'feat_manage'},
               'page' => 'edit_domain.cgi?dom='.$d->{'dom'},
               'cat' => 'services',
             } );
}

sub feature_validate {
    my ($d) = @_;
    if (!-r "$config{'nginx_sites_available'}/$d->{'dom'}.conf") {
        return $text{'feat_validate_nginx'};
    }
    if (!-r "$config{'fpm_poold'}/$d->{'dom'}.conf") {
        return $text{'feat_validate_fpm'};
    } else {
        return undef;
    }
}

sub feature_backup {
    my ($d, $file) = @_;
    &$virtual_server::first_print($text{'feat_backup'});

    $tmp_file = transname();

    $command = "tar czfP $tmp_file ";
    $command = "$command \"$config{'nginx_sites_available'}/$d->{'dom'}.conf\"";
    if($config{'nginx_sites_enabled'}) {
        $command = "$command \"$config{'nginx_nginx_sites_enabled'}/$d->{'dom'}.conf\"";
    }
    $command = "$command \"$config{'fpm_poold'}/$d->{'dom'}.conf\"";
    system($command);

    my $ok = &copy_source_dest($tmp_file, $file);
    if ($ok) {
        &$virtual_server::second_print($virtual_server::text{'setup_done'});
        return 1;
    }
    else {
        &$virtual_server::second_print($text{'feat_backup_failed'});
        return 0;
    }
}

sub feature_restore {
    my ($d, $file) = @_;
    &$virtual_server::first_print($text{'feat_restore'});
    my $ok = system("tar xzf $file -C /");
#    if ($ok) {
        &$virtual_server::second_print($virtual_server::text{'setup_done'});
        &reload_services();
        return 1;
#    } else {
#        &$virtual_server::second_print($text{'feat_restore_failed'}." tar xzf $file");
#        return 0;
#    }
}

sub feature_provides_web {
    return 1;
}

sub feature_provides_ssl {
    return 1;
}

sub feature_get_web_ssl_file {
    my ($d, $mode) = @_;
    if ($mode eq 'cert') {
            return "$d->{'home'}/ssl.cert";
        }
    elsif ($mode eq 'key') {
            return "$d->{'home'}/ssl.key";
        }
    elsif ($mode eq 'ca') {
            # Always appeneded to the cert file
            return $d->{'ssl_chain'};
        }
    return undef;
}

sub feature_web_supports_suexec {
    return -1;
}

sub feature_web_supports_cgi {
    return 1;
}

sub feature_restart_web_php {
    system("$config{'fpm_reload'} >/dev/null 2>&1");
}

sub feature_restart_web {
    system("$config{'nginx_reload_cmd'} >/dev/null 2>&1");
}

sub feature_restart_web_command {
    return $config{'nginx_reload_cmd'};
}

sub feature_get_web_suexec {
    return 1;
}

sub feature_inputs_show {
    return 1;
}
=begin
sub feature_inputs {
    @types= (    
            ['dynamic', 'Dynamic'],
            ['static', 'Static'],
            ['ondemand', 'On demand']
        );

#    $result = &ui_table_row($text{'fpm_pm_type'}, &ui_select("fpm_pm_type", $types[0]->[0], \@types));
#    $result.= &ui_table_row($text{'fpm_pm_max_children'}, &ui_textbox("fpm_pm_max_children", 5, 50));
#    $result.= &ui_table_row($text{'fpm_pm_start_servers'}, &ui_textbox("fpm_pm_start_servers", 2, 50));
#    $result.= &ui_table_row($text{'fpm_pm_min_spare_servers'}, &ui_textbox("fpm_pm_min_spare_servers", 1, 50));
#    $result.= &ui_table_row($text{'fpm_pm_max_spare_servers'}, &ui_textbox("fpm_pm_max_spare_servers", 3, 50));
#    $result.= &ui_table_row($text{'fpm_pm_max_requests'}, &ui_textbox("fpm_pm_max_requests", 500, 50));
    $result = &ui_table_row($text{'nginx_ssl'}, &ui_checkbox("nginx_ssl", "nginx_ssl", undef, 0));
    return $result;
}

sub feature_inputs_parse {
    return undef;
}
=cut
sub feature_start_service {
    system("$config{'nginx_start_cmd'} >/dev/null 2>&1");
    system("$config{'fpm_start'} >/dev/null 2>&1");
}

sub feature_stop_service {
    system("$config{'nginx_stop_cmd'} >/dev/null 2>&1");
    system("$config{'fpm_stop'} >/dev/null 2>&1");
}