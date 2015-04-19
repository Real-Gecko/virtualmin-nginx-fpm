use WebminCore;
&init_config();
&foreign_require("virtual-server", "virtual-server-lib.pl");

sub get_fpm_config {
    my ($d) = @_;
    my $lines = &read_file_lines("$config{'fpm_poold'}/$d->{'dom'}.conf");
    my %conf = ();
    foreach my $line (@$lines) {
        my ($n, $v) = split(/\s+=\s+/, $line, 2);
        if ($n) {
           $conf{$n} = $v;
        }
    }
    return %conf;
}

sub create_nginx_config {
    my ($d) = @_;
    open(FILE, ">> $config{'nginx_sites_available'}/$d->{'dom'}.conf") or die ("Unable to create nginx config");
print FILE <<"NGINX";
server {
    server_name $d->{'dom'} www.$d->{'dom'};
    listen $d->{'ip'};
    root $d->{'home'}/public_html;
    index index.html index.htm index.php;
    access_log /var/log/nginx/$d->{'dom'}_access_log;
    error_log /var/log/nginx/$d->{'dom'}_error_log;
    fastcgi_param GATEWAY_INTERFACE CGI/1.1;
    fastcgi_param SERVER_SOFTWARE nginx;
    fastcgi_param QUERY_STRING \$query_string;
    fastcgi_param REQUEST_METHOD \$request_method;
    fastcgi_param CONTENT_TYPE \$content_type;
    fastcgi_param CONTENT_LENGTH \$content_length;
    fastcgi_param SCRIPT_FILENAME $d->{'home'}/public_html\$fastcgi_script_name;
    fastcgi_param SCRIPT_NAME \$fastcgi_script_name;
    fastcgi_param REQUEST_URI \$request_uri;
    fastcgi_param DOCUMENT_URI \$document_uri;
    fastcgi_param DOCUMENT_ROOT $d->{'home'}/public_html;
    fastcgi_param SERVER_PROTOCOL \$server_protocol;
    fastcgi_param REMOTE_ADDR \$remote_addr;
    fastcgi_param REMOTE_PORT \$remote_port;
    fastcgi_param SERVER_ADDR \$server_addr;
    fastcgi_param SERVER_PORT \$server_port;
    fastcgi_param SERVER_NAME \$server_name;
    fastcgi_param HTTPS \$https;
    location ~ (^|/)\\. {
        return 403;
    }
    location / {
        try_files \$uri \$uri/ /index.php?q=\$uri&\$args;
    }
    location ~ \\.php\$ {
        try_files \$uri =404;
        fastcgi_pass unix:/var/run/php5-fpm-$d->{'dom'}.sock;
    }
NGINX
if ($d->{'ssl'}) {
print FILE <<"NGINX";
    listen $d->{'ip'}:443 ssl;
    ssl_certificate $d->{'home'}/ssl.cert;
    ssl_certificate_key $d->{'home'}/ssl.key;
NGINX
}
print FILE "}";

    close(FILE);
    if($config{'nginx_sites_enabled'}) {
        &symlink_file("$config{'nginx_sites_available'}/$d->{'dom'}.conf", "$config{'nginx_sites_enabled'}/$d->{'dom'}.conf");
    }
}

sub create_fpm_pool {
    my $d = shift;
    my $conf = shift;
    
    if (!-r "$d->{'home'}/.tmp") {
        &make_dir("$d->{'home'}/.tmp", oct(755), 0);
        &set_ownership_permissions($d->{'user'}, $d->{'group'}, undef, "$d->{'home'}/.tmp");
    }
    open(FILE, ">> $config{'fpm_poold'}/$d->{'dom'}.conf") or die ("Unable to create fpm pool config");
print FILE <<"FPM";
[$d->{'dom'}]
user = $d->{'user'}
group = $d->{'group'}
listen = /var/run/php5-fpm-$d->{'dom'}.sock
listen.owner = $config{'nginx_user'}
listen.group = $config{'nginx_user'}
pm = $conf->{'pm'}
pm.max_children = $conf->{'pm.max_children'}
pm.start_servers = $conf->{'pm.start_servers'}
pm.min_spare_servers = $conf->{'pm.min_spare_servers'}
pm.max_spare_servers = $conf->{'pm.max_spare_servers'}
pm.max_requests = $conf->{'pm.max_requests'}
chdir = /
env[TMP] = $d->{'home'}/.tmp
env[TMPDIR] = $d->{'home'}/.tmp
env[TEMP] = $d->{'home'}/.tmp
php_admin_value[cgi.fix_pathinfo] = 0
php_admin_value[open_basedir] = $d->{'home'}/public_html/:$d->{'home'}/.tmp/
FPM
    close(FILE);
}

sub reload_services {
    system("$config{'nginx_reload_cmd'} >/dev/null 2>&1");
    system("$config{'fpm_reload'} >/dev/null 2>&1");
}
1;

