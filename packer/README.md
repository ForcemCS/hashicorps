[TOC]

## Builders

- Builders 负责为各种平台创建machines并从中提取镜像。
- 您可以在模板中指定一个或多个构建块。
- 每个构建器模块可以引用一个或多个源模块
- 构建器有许多配置选项。有些选项是必须的，有些则是可选的。可选选项取决于构建器类型的支持。

+ 流行的builders请[参考](https://developer.hashicorp.com/packer/integrations)

### AWS AMI

请参考aws-example-1.pkr.hcl