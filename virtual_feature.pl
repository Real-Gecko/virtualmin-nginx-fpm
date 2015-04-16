do 'virtualmin-nginx-fpm-lib.pl';

sub feature_name {
    return $text{'feat_name'};
}

sub feature_label {
    return $text{'feat_label'};
}

sub feature_check {
    if (! &has_command("nginx")) {
        return $text{'feat_req_nginx'};
    }
    if (! &has_command("php5-fpm")) {
        return $text{'feat_req_fpm'};
    } else {
        return undef;
    }
}

sub feature_losing {
    return $text{'feat_loosing'};
}

sub feature_disname {
    return $text{'feat_disname'};
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
    return $subdom ? 0 : 1;
}

sub feature_setup {
    my ($d) = @_;
    &$virtual_server::first_print($text{'feat_setup'});
    &create_nginx_config($d);
    &create_fpm_pool($d);

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
        "$config{'nginx_sites_enabled'}/$d->{'dom'}.conf",
        "$config{'nginx_sites_available'}/$d->{'dom'}.conf",
        "$config{'fpm_poold'}/$d->{'dom'}.conf"
    );
    &reload_services;
    &$virtual_server::second_print($virtual_server::text{'setup_done'});
}

sub feature_modify {
    my ($d, $oldd) = @_;
    if ($d->{'dom'} ne $oldd->{'dom'}) {
        &$virtual_server::first_print($text{'feat_modify_domain'});
        &unlink_file(
            "$config{'nginx_sites_enabled'}/$d->{'dom'}.conf",
            "$config{'nginx_sites_available'}/$d->{'dom'}.conf",
            "$config{'fpm_poold'}/$d->{'dom'}.conf"
        );
        &create_nginx_config($d);
        &create_fpm_pool($d);
        &reload_services;
        &$virtual_server::second_print($virtual_server::text{'setup_done'});
    }
}

sub feature_disable {
    my ($d) = @_;
    &$virtual_server::first_print($text{'feat_disable'});
    &unlink_file("$config{'nginx_sites_enabled'}/$d->{'dom'}.conf");
    &rename_file("$config{'fpm_poold'}/$d->{'dom'}.conf", "$config{'fpm_poold'}/$d->{'dom'}.conf.dis");
    &reload_services;
    &$virtual_server::second_print($virtual_server::text{'setup_done'});
}

sub feature_enable {
    my ($d) = @_;
    &$virtual_server::first_print($text{'feat_enable'});
    &symlink_file("$config{'nginx_sites_available'}/$d->{'dom'}.conf", "$config{'nginx_sites_enabled'}/$d->{'dom'}.conf");
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
               'page' => 'index.cgi?dom='.$d->{'dom'},
               'cat' => 'services',
             } );
}

sub feature_validate {
    my ($d) = @_;
    if (!-r "$config{'nginx_sites_enabled'}/$d->{'dom'}.conf") {
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
    $command = "$command \"$config{'nginx_nginx_sites_enabled'}/$d->{'dom'}.conf\"";
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
