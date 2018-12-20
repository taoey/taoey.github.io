---
layout: post
title: springboot教程之快速入门(一)
categories: springboot
description: springboot教程之快速入门(一)
keywords: springboot
---

[Spring Boot](http://projects.spring.io/spring-boot/) 并不是一个全新的框架，而是将已有的 Spring 组件整合起来。特点是去掉了繁琐的 XML 配置，改使用约定或注解。所以熟悉了 Spring Boot 之后，开发效率将会提升一个档次。

## springboot 特征
- 创建可以独立运行的 Spring 应用。
- 直接嵌入 Tomcat 或 Jetty 服务器，不需要部署 WAR 文件。
- 提供推荐的基础 POM 文件来简化 Apache Maven 配置。
- 尽可能的根据项目依赖来自动配置 Spring 框架。
- 提供可以直接在生产环境中使用的功能，如性能指标、应用信息和应用健康检查。
- 没有代码生成，也没有 XML 配置文件。

通过springboot创建应用非常简单，只需要简单几步就可以创建出一个spring web项目。下面介绍使用 Maven 作为构建工具创建的 Spring Boot 应用。

## pom.xml

> 使用maven建立多模块项目。

**父项目maven pom.xml文件**
```
<?xml version="1.0" encoding="UTF-8"?>
<project xmlns="http://maven.apache.org/POM/4.0.0" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:schemaLocation="http://maven.apache.org/POM/4.0.0 http://maven.apache.org/xsd/maven-4.0.0.xsd">
	<modelVersion>4.0.0</modelVersion>

	<groupId>com.pinkylam</groupId>
	<artifactId>oh-springboot</artifactId>
	<version>0.0.1-SNAPSHOT</version>
	<packaging>pom</packaging>
	<name>oh-springboot</name>

	<parent>
		<groupId>org.springframework.boot</groupId>
		<artifactId>spring-boot-starter-parent</artifactId>
		<version>1.5.2.RELEASE</version>
		<relativePath/>
	</parent>

	<modules>
		<module>startSpringBoot</module>
  </modules>

</project>
```

**子项目maven pom.xml文件**
```
<?xml version="1.0"?>
<project
	xsi:schemaLocation="http://maven.apache.org/POM/4.0.0 http://maven.apache.org/xsd/maven-4.0.0.xsd"
	xmlns="http://maven.apache.org/POM/4.0.0" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">
	<modelVersion>4.0.0</modelVersion>

	<parent>
		<artifactId>oh-springboot</artifactId>
		<groupId>com.pinkylam</groupId>
		<version>0.0.1-SNAPSHOT</version>
	</parent>

	<artifactId>startSpringBoot</artifactId>
	<name>startSpringBoot</name>

	<properties>
		<project.build.sourceEncoding>UTF-8</project.build.sourceEncoding>
		<java.version>1.8</java.version>
	</properties>

	<dependencies>

		<dependency>
			<groupId>org.springframework.boot</groupId>
			<artifactId>spring-boot-starter-web</artifactId>
		</dependency>

	</dependencies>

	<build>
		<plugins>
			<plugin>
				<groupId>org.springframework.boot</groupId>
				<artifactId>spring-boot-maven-plugin</artifactId>
			</plugin>
		</plugins>
	</build>

</project>
```

从pom代码清淡看来，项目所要声明的依赖很少，其实并不然，点开项目maven dependencies发现其中包含了 Spring MVC 框架、SLF4J、Jackson、Hibernate Validator 和 Tomcat 等依赖。

![运行实例图](/images/posts/springbootmaven.png)

## App.java
```
package org.startSpringBoot;

import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.EnableAutoConfiguration;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.ResponseBody;
import org.springframework.web.bind.annotation.RestController;

/**
 * @author Pinky Lam 908716835@qq.com
 * @date 2017年6月5日 下午3:54:41
 */
@RestController
@EnableAutoConfiguration
public class App {

	public static void main(String[] args) {
		SpringApplication.run(App.class, args);
	}

	@RequestMapping("/")
    @ResponseBody
    String home() {
        return "Hello World!";
    }

}
```
**App**是一个可以独立运行的web应用程序。直接运行该类会启动一个tomcat服务器。默认端口号是8080，启动完访问浏览器“http://localhost:8080”就可以看到“Hello World!”啦。简单吧，只需要简单的两步就可以开发出一个独立运行的web应用程序。

## springboot推荐pom
[Spring Boot application starters](http://docs.spring.io/spring-boot/docs/1.5.3.RELEASE/reference/htmlsingle/#using-boot-starter)

## 结语
以上代码都在我的github上，其中有问题或者不对的地方欢迎交流。
项目地址：[oh-springboot](https://github.com/handexing/oh-springboot)




