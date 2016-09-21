FROM phusion/baseimage:0.9.16
MAINTAINER Vasilis Giannoulis <vgiannoul@2square.gr>

ENV HOME /root

# Use baseimage-docker's init system.
CMD ["/sbin/my_init"]

# Install required packages
# LANG=C.UTF-8 line is needed for ondrej/php5 repository
RUN \
	export LANG=C.UTF-8 && \
	add-apt-repository ppa:mc3man/trusty-media && \
	add-apt-repository ppa:ondrej/php5-5.6 && \
	add-apt-repository -y ppa:nginx/stable && \
	add-apt-repository -y ppa:rwky/graphicsmagick && \
	apt-get update && \
	apt-get -y install nginx php5-fpm php5-mysql php5-curl php5-mcrypt graphicsmagick ffmpeg pwgen wget unzip

# Configuration
RUN \
	sed -i -e"s/events\s{/events {\n\tuse epoll;/" /etc/nginx/nginx.conf && \
	sed -i -e"s/keepalive_timeout\s*65/keepalive_timeout 2;\n\tclient_max_body_size 100m;\n\tport_in_redirect off/" /etc/nginx/nginx.conf && \
	echo "daemon off;" >> /etc/nginx/nginx.conf && \
	sed -i -e "s/;cgi.fix_pathinfo=1/cgi.fix_pathinfo=0/g" /etc/php5/fpm/php.ini && \
	sed -i -e "s/upload_max_filesize\s*=\s*2M/upload_max_filesize = 100M/g" /etc/php5/fpm/php.ini && \
	sed -i -e "s/post_max_size\s*=\s*8M/post_max_size = 101M/g" /etc/php5/fpm/php.ini && \
	sed -i -e "s/;daemonize\s*=\s*yes/daemonize = no/g" /etc/php5/fpm/php-fpm.conf && \
	sed -i -e "s/;pm.max_requests\s*=\s*500/pm.max_requests = 500/g" /etc/php5/fpm/pool.d/www.conf && \
	echo "env[KOKEN_HOST] = 'koken-docker-lemp'" >> /etc/php5/fpm/pool.d/www.conf && \
	cp /etc/php5/fpm/pool.d/www.conf /etc/php5/fpm/pool.d/images.conf && \
	sed -i -e "s/\[www\]/[images]/" /etc/php5/fpm/pool.d/images.conf && \
	sed -i -e "s#listen\s*=\s*/var/run/php5-fpm\.sock#listen = /var/run/php5-fpm-images.sock#" /etc/php5/fpm/pool.d/images.conf

# nginx site conf
ADD ./conf/nginx-site.conf /etc/nginx/sites-available/default

# Add runit files for each service
ADD ./services/nginx /etc/service/nginx/run
ADD ./services/php-fpm /etc/service/php-fpm/run
ADD ./services/koken /etc/service/koken/run

# Cron
ADD ./shell/koken.sh /etc/cron.daily/koken


# Execute permissions where needed
RUN \
	chmod +x /etc/service/nginx/run && \
	chmod +x /etc/service/php-fpm/run && \
	chmod +x /etc/service/koken/run && \
	chmod +x /etc/cron.daily/koken

# Expose 8080 to the host
EXPOSE 8080

# Disable SSH
RUN rm -rf /etc/service/sshd /etc/my_init.d/00_regen_ssh_host_keys.sh

# Clean up APT when done.
RUN apt-get clean && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*
