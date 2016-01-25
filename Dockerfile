FROM quay.io/ukhomeofficedigital/centos-base

RUN rpm --rebuilddb && \
    yum install -y yum-utils epel-release && \
    yum-config-manager --enable cr && \
    yum install -y gc gcc gcc-c++ pcre-devel zlib-devel make wget openssl-devel libxml2-devel libxslt-devel gd-devel perl-ExtUtils-Embed GeoIP-devel gperftools gperftools-devel libatomic_ops-devel perl-ExtUtils-Embed git

ENV VERSION 1.9.9
RUN curl -o nginx.tar.gz http://nginx.org/download/nginx-${VERSION}.tar.gz && \
    useradd nginx && \
    usermod -s /sbin/nologin nginx && \
    tar -xvzf nginx.tar.gz && \
    mv nginx-${VERSION} nginx && \
    git clone https://bitbucket.org/nginx-goodies/nginx-sticky-module-ng.git

WORKDIR nginx
RUN ./configure --user=nginx --group=nginx --sbin-path=/usr/sbin/nginx --conf-path=/etc/nginx/nginx.conf --error-log-path=/var/log/nginx/error.log --http-log-path=/var/log/nginx/access.log  --with-select_module --with-poll_module --with-file-aio --with-ipv6 --with-http_ssl_module  --with-http_realip_module --with-http_addition_module --with-http_xslt_module --with-http_image_filter_module --with-http_geoip_module --with-http_sub_module --with-http_dav_module --with-http_flv_module --with-http_mp4_module --with-http_gunzip_module --with-http_gzip_static_module --with-http_auth_request_module --with-http_random_index_module --with-http_secure_link_module --with-http_degradation_module --with-http_stub_status_module --with-http_perl_module --with-mail --with-mail_ssl_module --with-cpp_test_module  --with-cpu-opt=CPU --with-pcre  --with-pcre-jit  --with-md5-asm  --with-sha1-asm  --with-zlib-asm=CPU --with-libatomic --with-debug --with-ld-opt="-Wl,-E" --add-module=/nginx-sticky-module-ng && \
    make && make install

RUN ln -s /dev/stderr /var/log/nginx/error.log && \
    ln -s /dev/stdout /var/log/nginx/access.log && \
    mkdir -p /usr/share/nginx/html

COPY entry-point.sh /entry-point.sh

ENTRYPOINT ["/entry-point.sh"]
CMD ["/usr/sbin/nginx", "-g", "daemon off;"]
