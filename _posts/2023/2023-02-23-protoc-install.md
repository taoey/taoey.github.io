---
layout: post
title: golang版protoc安装及使用
categories: [golang]
description: golang版protoc安装及使用
keywords: 工具,golang
---


要生成 gRPC 代码，需要安装 protoc 工具和 golang 的 protoc 插件。

首先安装 protoc 工具。可以从 protobuf releases 页面 下载相应平台的预编译二进制文件，或者从包管理器中安装。

安装 golang 的 protoc 插件。


```
go install google.golang.org/protobuf/cmd/protoc-gen-go
go install google.golang.org/grpc/cmd/protoc-gen-go-grpc
```

这里使用了 go install 命令来安装插件。如果你没有将 $GOPATH/bin 添加到 $PATH 环境变量中，可能需要手动添加。

安装完成后，可以使用以下命令生成 gRPC 代码：

```
protoc --go_out=. --go-grpc_out=. your_proto_file.proto
```

其中 your_proto_file.proto 是你的 proto 文件名。执行以上命令后，会在当前目录下生成对应的 gRPC 代码文件