---
layout: post
title: 基于Nginx的多级文件缓存系统设计
categories: [nginx,golang]
description: 基于Nginx的多级文件缓存系统设计
keywords: nginx,golang
---

## 一、系统架构

### 1、系统整体原理架构图

![image.png](https://raw.githubusercontent.com/Taoey/Taoey.github.io/master/_posts/greatArticle/2021-2-5-nginx-cdn.assets/image.png)

### 2、节点连接事件通信逻辑

![image.png](https://raw.githubusercontent.com/Taoey/Taoey.github.io/master/_posts/greatArticle/2021-2-5-nginx-cdn.assets/image-1612519708685.png)



### 3、配置更新事件通信逻辑

![image.png](https://raw.githubusercontent.com/Taoey/Taoey.github.io/master/_posts/greatArticle/2021-2-5-nginx-cdn.assets/image-1612519708730.png)



## 二、Nginx必备知识

### 1、Nginx带宽限速

目录结构为：

![image.png](https://raw.githubusercontent.com/Taoey/Taoey.github.io/master/_posts/greatArticle/2021-2-5-nginx-cdn.assets/image-1612519708768.png)

nginx.conf主配置文件添加：

```nginx
include  other/limit_rate.conf;
```

limit_rate.conf文件内容：

```nginx
map $remote_addr $response_rate {
        # Default bandwidth
        default 204800k;

        # limit ip
        #192.168.44.7 100k;
}
```

在对应的server下添limit配置：

```nginx
location /file/path {
    set $limit_rate $response_rate;
    # limit_conn addr 3;                    限制每个下载的并发数量，超过并发数量可能导致下载不成功
    alias   /smartrtb/smartrtb-server/files;
    allow all;
    autoindex on;
}
```



### 2、Nginx负载均衡

```nginx
    ### 设置上级代理服务器
    upstream uphost {
        #upstream的负载均衡，weight是权重，可以根据机器配置定义权重。weigth参数表示权值，权值越高被分配到的几率越大。
        #max_fails 允许请求失败的次数默认为1.当超过最大次数时，返回proxy_next_upstream 模块定义的错误。
        #fail_timeout 是max_fails次失败后，暂停的时间。
        server 192.168.165.192:9002 weight=1 max_fails=2 fail_timeout=30s;
    }
```

### 3、Nginx权限问题

问题：

> failed (13: Permission denied) while reading upstream

修改Nginx配置，首行添加：

```nginx
user root
```



## 三、部署实战

本案例采用docker进行Nginx的安装工作，参考[Docker 安装 Nginx](https://www.runoob.com/docker/docker-install-nginx.html)

Nginx版本信息：1.16

### 1、Nginx安装

拟安装四个节点，其层级关系图如下，关于docker中涉及的具体的配置信息，可先参考后面Nginx配置

![1570936576104.png](https://raw.githubusercontent.com/Taoey/Taoey.github.io/master/_posts/greatArticle/2021-2-5-nginx-cdn.assets/1592660893173-6b60bbd2-5605-41d0-b0f6-44f186b113d5.png)



主节点安装

```bash
docker run \
    --name nginx-main \
    -d -p 9000:80 \
    -v /root/data/nginx/main/html:/etc/nginx/html \
    -v /root/data/nginx/main/conf/nginx.conf:/etc/nginx/nginx.conf \
    -v /root/data/nginx/main/logs:/var/log/nginx \
    nginx:1.16
```



从节点1安装

```bash
docker run \
    --name nginx-server1 \
    --privileged=true  \
    -d -p 9001:80 \
    -v /root/data/nginx/server1/html/files:/etc/nginx/html/files \
    -v /root/data/nginx/server1/html/cache:/etc/nginx/html/cache \
    -v /root/data/nginx/server1/conf/nginx.conf:/etc/nginx/nginx.conf \
    -v /root/data/nginx/server1/logs:/var/log/nginx \
    nginx:1.16
```

从节点2安装

```bash
docker run \
    --name nginx-server2 \
    --privileged=true  \
    -d -p 9002:80 \
    -v /root/data/nginx/server2/html/files:/etc/nginx/html/files \
    -v /root/data/nginx/server2/html/cache:/etc/nginx/html/cache \
    -v /root/data/nginx/server2/conf/nginx.conf:/etc/nginx/nginx.conf \
    -v /root/data/nginx/server2/logs:/var/log/nginx \
    nginx:1.16
```



从节点3安装

```bash
docker run \
    --name nginx-server3 \
    --privileged=true  \
    -d -p 9003:80 \
    -v /root/data/nginx/server3/html/files:/etc/nginx/html/files \
    -v /root/data/nginx/server3/html/cache:/etc/nginx/html/cache \
    -v /root/data/nginx/server3/conf/nginx.conf:/etc/nginx/nginx.conf \
    -v /root/data/nginx/server3/logs:/var/log/nginx \
    nginx:1.16
```

### 2、Nginx配置

#### 2.1、nginx配置文件存放位置

添加如下配置

```nginx
location /files/ {
    root html;
    index  index.html index.htm; 
 }
```

并将文件存放在：html目录下

![1570935605616.png](https://raw.githubusercontent.com/Taoey/Taoey.github.io/master/_posts/greatArticle/2021-2-5-nginx-cdn.assets/1592660892231-029c92d6-2f32-4a5d-b031-22a47f39fd9c.png)

文件访问地址:

```
http://ip:host/files/1.jpg
```

参考资料

- [nginx实现简单的图片服务器（windows）+静态文件服务器](https://blog.csdn.net/qq_23974323/article/details/80067250)

#### 2.2、nginx配置限速

参考资料：

- [Nginx 限制IP带宽占用](https://www.w3cschool.cn/nginxsysc/nginxsysc-limit-rate.html)

#### 2.3、nginx配置反向代理并进行多级缓存

需要实现的效果：

访问server3

- 获取目标文件“1.zip“，但是server3中并没有该文件
- server3向上级server2获取该文件

- - server2存在该文件，直接下发到server3中，并在server3中缓存
  - server2中不存在该文件，server2请求上级服务器，获取该文件，并缓存到本地，发送给server3

配置缓存模式（成功）：

```nginx
#user  nobody;
worker_processes  1;

#error_log  logs/error.log;
#error_log  logs/error.log  notice;
#error_log  logs/error.log  info;

#pid        logs/nginx.pid;


# 单个进程最大连接数（最大连接数=连接数*进程数）
events {
    use epoll;
    worker_connections  1024;
}


http {
    include       mime.types;


    ## 缓存配置
    #指定临时文件目录
    proxy_temp_path /etc/nginx/html/files;
    #指定缓存区路径，设置Web缓存区名称为cache_one，内存缓存为500MB，自动清除1天内没有被访问的文件，硬盘缓存为30GB。
    proxy_cache_path /etc/nginx/html/cache levels=1:2 keys_zone=cache_one:500m inactive=1d max_size=30g;
    #定义缓冲区代理缓冲客户端请求的最大字节数
    client_body_buffer_size 512k;
    #定义连接后端服务器超时时间
    proxy_connect_timeout 60;
    #定义后端服务器响应请求超时时间
    proxy_read_timeout 60;
    #定义后端服务器发送数据超时时间
    proxy_send_timeout 60;
    #定义代理请求缓存区大小
    proxy_buffer_size 32k;
    proxy_buffers 4 64k;
    #定义系统繁忙时可申请的proxy_buffers大小
    proxy_busy_buffers_size 128k;
    #定义proxy缓存临时文件的大小
    proxy_temp_file_write_size 128k;
    #定义故障转移，如果后端的服务器返回502、504、执行超时等错误，自动将请求转发到upstream负载均衡池中的另一台服务器，实现故障转移。
    proxy_next_upstream error timeout invalid_header http_500 http_502 http_503 http_404;
    #定义使用web缓存区cache_one
    proxy_cache cache_one;


    ### 设置上级代理服务器
    upstream uphost {
    #upstream的负载均衡，weight是权重，可以根据机器配置定义权重。weigth参数表示权值，权值越高被分配到的几率越大。
    #max_fails 允许请求失败的次数默认为1.当超过最大次数时，返回proxy_next_upstream 模块定义的错误。
    #fail_timeout 是max_fails次失败后，暂停的时间。
    server 192.168.165.192:9002 weight=1 max_fails=2 fail_timeout=30s;
    }

    #开启高效文件传输模式
    sendfile on;
    tcp_nopush on;

    #长连接超时时间，单位是秒
    keepalive_timeout 360;
    #防止网络阻塞
    tcp_nodelay on;

    default_type  application/octet-stream;

    #log_format  main  '$remote_addr - $remote_user [$time_local] "$request" '
    #                  '$status $body_bytes_sent "$http_referer" '
    #                  '"$http_user_agent" "$http_x_forwarded_for"';

    #access_log  logs/access.log  main;


    #gzip  on;

    server {
        listen       80;
        server_name  localhost;

        #charset koi8-r;

        #access_log  logs/host.access.log  main;

        location / {
            root   html;
            index  index.html index.htm;
        }

    location /files/ {
        root html;
        index  index.html index.htm; 

        #配置的upstream 服务器池
        proxy_pass http://uphost ;
        #增加设置web缓存的key值，nginx根据key值md5哈希存储缓存
        proxy_cache_key $host$uri$is_args$args;
        proxy_set_header Host $host;
        #后端的Web服务器可以通过X-Forwarded-For获取用户真实IP
        proxy_set_header X-Forwarded-For $remote_addr;
        proxy_cache_valid 200 304 12h;
        expires 2d;
        proxy_ignore_headers "Cache-Control" "Expires" "Set-Cookie";

     }

        #error_page  404              /404.html;

        # redirect server error pages to the static page /50x.html
        #
        error_page   500 502 503 504  /50x.html;
        location = /50x.html {
            root   html;
        }

        # proxy the PHP scripts to Apache listening on 127.0.0.1:80
        #
        #location ~ \.php$ {
        #    proxy_pass   http://127.0.0.1;
        #}

        # pass the PHP scripts to FastCGI server listening on 127.0.0.1:9000
        #
        #location ~ \.php$ {
        #    root           html;
        #    fastcgi_pass   127.0.0.1:9000;
        #    fastcgi_index  index.php;
        #    fastcgi_param  SCRIPT_FILENAME  /scripts$fastcgi_script_name;
        #    include        fastcgi_params;
        #}

        # deny access to .htaccess files, if Apache's document root
        # concurs with nginx's one
        #
        #location ~ /\.ht {
        #    deny  all;
        #}
    }


    # another virtual host using mix of IP-, name-, and port-based configuration
    #
    #server {
    #    listen       8000;
    #    listen       somename:8080;
    #    server_name  somename  alias  another.alias;

    #    location / {
    #        root   html;
    #        index  index.html index.htm;
    #    }
    #}


    # HTTPS server
    #
    #server {
    #    listen       443 ssl;
    #    server_name  localhost;

    #    ssl_certificate      cert.pem;
    #    ssl_certificate_key  cert.key;

    #    ssl_session_cache    shared:SSL:1m;
    #    ssl_session_timeout  5m;

    #    ssl_ciphers  HIGH:!aNULL:!MD5;
    #    ssl_prefer_server_ciphers  on;

    #    location / {
    #        root   html;
    #        index  index.html index.htm;
    #    }
    #}

}
```



配置镜像模式

（1）server3请求server2内容测试

server3获取到server2中内容，并复制到了本地

（2） server3 请求server1中的内容测试

server3获取到server1中的内容，并复制到了本地

server2获取到server1中的内容，并复制到了本地

（2）server3请求main中的内容

只有server3获取到了main中的内容

查看报错信息（省略了相关文件名）：

```
failed (13: Permission denied) while reading upstream
```

问题最终解决，其解决办法为：[nginx的权限问题(Permission denied)解决办法](https://www.cnblogs.com/zdz8207/p/nginx-Permission-denied-nobody.html)

```
查看nginx.conf:
user nobody
改成：user root
注意：只是注释掉（#user nobody），没重新赋值默认还是nobody

停止nginx -s stop
重启nginx -c nginx.conf
测试...
```

最终的节点服务器的配置，如下：

```nginx
#user  nobody;
user root;
worker_processes  1;

#error_log  logs/error.log;
#error_log  logs/error.log  notice;
#error_log  logs/error.log  info;

#pid        logs/nginx.pid;


# 单个进程最大连接数（最大连接数=连接数*进程数）
events {
    use epoll;
    worker_connections  1024;
}


http {
    include       mime.types;




    ### 设置上级代理服务器
    upstream uphost {
        #upstream的负载均衡，weight是权重，可以根据机器配置定义权重。weigth参数表示权值，权值越高被分配到的几率越大。
        #max_fails 允许请求失败的次数默认为1.当超过最大次数时，返回proxy_next_upstream 模块定义的错误。
        #fail_timeout 是max_fails次失败后，暂停的时间。
        server 47.98.165.192:9001 weight=1 max_fails=2 fail_timeout=30s;
    }

    #开启高效文件传输模式
    sendfile on;
    tcp_nopush on;

    #长连接超时时间，单位是秒
    keepalive_timeout 360;
    #防止网络阻塞
    tcp_nodelay on;

    default_type  application/octet-stream;

    #log_format  main  '$remote_addr - $remote_user [$time_local] "$request" '
    #                  '$status $body_bytes_sent "$http_referer" '
    #                  '"$http_user_agent" "$http_x_forwarded_for"';

    #access_log  logs/access.log  main;


    #gzip  on;

    server {
        listen       80;
        server_name  localhost;

        #charset koi8-r;

        #access_log  logs/host.access.log  main;

        location / {
            root   html;
            index  index.html index.htm;
        }

    location /files/ {
        root html;
        index  index.html index.htm; 

        proxy_store on;
        proxy_store_access user:rw group:rw all:rw;
        proxy_temp_path /etc/nginx/html/cache;
        if ( !-e $request_filename) {
            proxy_pass http://uphost ;
        }
     }

        #error_page  404              /404.html;

        # redirect server error pages to the static page /50x.html
        #
        error_page   500 502 503 504  /50x.html;
        location = /50x.html {
            root   html;
        }

        # proxy the PHP scripts to Apache listening on 127.0.0.1:80
        #
        #location ~ \.php$ {
        #    proxy_pass   http://127.0.0.1;
        #}

        # pass the PHP scripts to FastCGI server listening on 127.0.0.1:9000
        #
        #location ~ \.php$ {
        #    root           html;
        #    fastcgi_pass   127.0.0.1:9000;
        #    fastcgi_index  index.php;
        #    fastcgi_param  SCRIPT_FILENAME  /scripts$fastcgi_script_name;
        #    include        fastcgi_params;
        #}

        # deny access to .htaccess files, if Apache's document root
        # concurs with nginx's one
        #
        #location ~ /\.ht {
        #    deny  all;
        #}
    }


    # another virtual host using mix of IP-, name-, and port-based configuration
    #
    #server {
    #    listen       8000;
    #    listen       somename:8080;
    #    server_name  somename  alias  another.alias;

    #    location / {
    #        root   html;
    #        index  index.html index.htm;
    #    }
    #}


    # HTTPS server
    #
    #server {
    #    listen       443 ssl;
    #    server_name  localhost;

    #    ssl_certificate      cert.pem;
    #    ssl_certificate_key  cert.key;

    #    ssl_session_cache    shared:SSL:1m;
    #    ssl_session_timeout  5m;

    #    ssl_ciphers  HIGH:!aNULL:!MD5;
    #    ssl_prefer_server_ciphers  on;

    #    location / {
    #        root   html;
    #        index  index.html index.htm;
    #    }
    #}

}
```



参考文章：

- 用Nginx搭建CDN服务器方法-开启Nginx缓存与镜像,自建图片服务器：
- [https://jishusuishouji.github.io/2017/03/23/nginx/%E7%94%A8Nginx%E6%90%AD%E5%BB%BACDN%E6%9C%8D%E5%8A%A1%E5%99%A8%E6%96%B9%E6%B3%95-%E5%BC%80%E5%90%AFNginx%E7%BC%93%E5%AD%98%E4%B8%8E%E9%95%9C%E5%83%8F,%E8%87%AA%E5%BB%BA%E5%9B%BE%E7%89%87%E6%9C%8D%E5%8A%A1%E5%99%A8/](https://jishusuishouji.github.io/2017/03/23/nginx/用Nginx搭建CDN服务器方法-开启Nginx缓存与镜像,自建图片服务器/)
- [nginx 配置反向代理（CDN服务）](https://www.cnops.xyz/archives/81)
- [初识nginx——配置解析篇](https://cloud.tencent.com/developer/article/1037811)
- [nginx完整配置文件例子](https://blog.csdn.net/JackLiu16/article/details/79444327)
- [Nginx 限制IP带宽占用](https://www.w3cschool.cn/nginxsysc/nginxsysc-limit-rate.html)
- [使用Nginx反向代理，自建CDN加速节点](https://www.moewah.com/archives/963.html)
- [nginx的权限问题(Permission denied)解决办法](https://www.cnblogs.com/zdz8207/p/nginx-Permission-denied-nobody.html)