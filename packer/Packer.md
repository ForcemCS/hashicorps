### 为什么要使用Packer

<img src="./img/1.png" alt="1" style="zoom:50%;" />

我们可以使用核心机器镜像（包含特定的软件包，是一个自定义的镜像），通过这个核心镜像可以部署很多不通的工作负载。

但是这个核心镜像不一定适用于每个工作负载，我们可以从核心机器镜像生成一个**new image**，此新镜像具有新的自定义packer配置，它将进一步定制我们的核心镜像，并且是可配置的（并且满足了核心镜像的一切安全之类的要求）

也就是说上边和下边的工作负载都是基于核心镜像的，只是下边的工作负载多了packer config



<img src="./img/2.png" alt="2" style="zoom:50%;" />

下图说明了在基于原始镜像构建新镜像的流程

<img src="./img/3.png" alt="3" style="zoom:50%;" />

#### 用例

+ 根据新提交建立镜像工厂，实现持续交付（本地和云环境的镜像的统一）
+ 自动进行每月的补丁 ，针对新的/现有的工作负载
+ 在 CI/CD 管道中使用 Packer 创建不可变基础架构

#### 收益

+ **Version Controlled**

  与手动控制镜像相比，使用 Packer 可以对镜像进行版本控制，从而简化组织内部的长期管理和更新。

+ **Consistent Images**

  当工作负载使用多个平台时，维护类似的镜像就成了一项艰巨的任务。Packer 可以协助跨多个平台进行管理。

+ **Automate Everything**

  在多个平台上手动管理镜像容易出现人为错误，并造成不必要的管理开销。

### 核心组件

- HashiCorp Packer 使用模板构建镜像
- Templates can be built using either JSON (old) or HCL2 (recommended for Packer 1.7.0+)
- Template defines settings using blocks:
  + 要使用的原始镜像（Source）
  + 构建镜像的位置 (AWS, VMware, OpenStack)
  + 要上传到镜像的文件 (scripts, packages, certificates)
  + 机器镜像的安装和配置
  + 构建时要检索的数据

#### Source

+ 用来定义要使用哪个初始镜像来创建自定义镜像。
+ 任何已定义的source代码都可在build模块中重复使用。

```json
source "azure-arm" "azure-arm-centos-7" {
  image_offer      = "CentOS"
  image_publisher  = "OpenLogic"
  image_sku       = "7.7"
  os_type         = "Linux"
  subscription_id  = "${var.azure_subscription_id}"
}
```

#### Builders

+ build负责从基础镜像创建machines，按照定义自定义镜像，然后创建生成的镜像。 
+ build是专为特定平台（如 AWS、Azure、VMware、OpenStack、Docker）开发的插件。 
+ 对镜像所做的一切都是在 BUILD 块内完成的。 

```json
build {
  source = ["source.azure-arm.azure-arm-centos-7"]

  provisioner "file" {
    destination = "/tmp/package_a.zip"
    source      = "${var.package_a_zip}"
  }
}
```

#### Provisioners

+ provisioners使用内置和第三方集成来安装软件包和配置机器映像
+ 内置集成包括file和不同的shell选项
+ **第三方集成包括：**
  + ansible
  + chef
  + ....

<img src="C:\Users\ForceCS\Desktop\Packer\img\13.png" alt="13" style="zoom:40%;" />



#### Post-Processors

+ Post-processors在镜像构建和供应器完成后执行。它可用于上传工件、执行上传的脚本、验证安装或导入镜像
+ **示例包括：**
  - 使用checksum验证软件包
  - 将软件包作为亚马逊机器镜像导入 AWS
  - 将 Docker 镜像推送到注册中心
  - 将工件转换为 Vagrant box
  - 从生成的构建中创建 VMware template

#### Communicators

+ Communicators (通信器)是 Packer 用来与新的构建和上传文件、执行脚本等进行通信的机制
+ 目前有两种通信工具
  + SSH
  + WinRM

#### Variables

+ 在构建过程中，HashiCorp Packer 可以使用变量来定义默认值
+ 变量可以声明在 `.pkrvars.hcl` 或 `.auto.pkrvars.hcl` 文件中，也可以存储在其他文件中，只要在执行构建时引用即可。

```json
variable "image_id" {  
  type        = string  
  description = "The id of the machine image (AMI) to use for the server."  
  default     = "ami-1234abcd"  

  validation {  
    condition     = length(var.image_id) > 4 && substr(var.image_id, 0, 4) == "ami-"  
    error_message = "The image_id value must be a valid AMI id, starting with \"ami-\"."  
  }  
}  
```

代码示例展示了如何在 Packer 配置文件（HCL 语言）中定义一个变量 `image_id`：

- `type = string`：定义变量类型为字符串。
- `description`：提供变量的描述信息。
- `default`：设置默认值 `ami-1234abcd`。
- validation
  - `length(var.image_id) > 4`：确保 `image_id` 至少有 5 个字符。
  - `substr(var.image_id, 0, 4) == "ami-"`：确保 `image_id` 以 `"ami-"` 开头。
  - `error_message`：如果验证失败，则返回错误消息。

### 安装

请参考[官方文档](https://developer.hashicorp.com/packer/install#linux)

#### 命令行

这里提取的文本如下：

```
packer <sub-command> <argument> <argument>

例如：packer build -var-file=vars.pkr.hcl aws.pkr.hcl
```

可用的子命令如下

+ build

  从模板构建镜像

  + -debug    - 启用调试模式，以便逐步排除故障
  + -var          - 在 Packer 模板中设置变量
  + -var-file   - 使用单独的变量文件

+ console         

  creates a console for testing variable interpolation

+ fix 

  Packer fix 命令会使用一个模板，找出其中向后不兼容的部分，并将其更新，使其可用于最新版本的 Packer。在将 Packer 更新到新版本后使用。

  ```
  $ packer fix old-template.json > new-template.json  
  ```

+ fmt             

  Rewrites HCL2 config files to canonical format

+ hcl2_upgrade    

  transform a JSON template into an HCL2 configuration

+ init

   Install missing plugins or upgrade plugins

+ inspect

  **packer inspect** 显示 Packer 模板的所有组件，包括变量、构建、源、供应器和后处理器。

  ```
  $ packer inspect aws-ubuntu.pkr.hcl  
  Packer Inspect: HCL2 mode  
  
  > input-variables:  
  > local-variables:  
  > builds:  
  > Amazon AMI:  
  sources:  
    amazon-ebs.ubuntu  
  provisioners:  
    shell  
  post-processors:  
  0:  
    manifest  
  ```

+ plugins         Interact with Packer plugins and catalog

+ validate        check that a template is valid

+ version         Prints the Packer version

#### 环境变量

+ PACKER_LOG 

   启用 Packer 详细日志（默认关闭）

+ PACKER_LOG_PATH 

  将 Packer 日志的路径设置为特定文件（而不是 stderr）

+ PKR_VAR_xxx 

  使用 ENV 而不是模板定义变量值

```
$ export PACKER_LOG=1  
$ export PACKER_LOG_PATH=/var/log/packer.log  
$ packer build base-image.pkr.hcl  

$ export PKR_VAR_aws_region=us-east-1  
$ packer build aws-base-image.pkr.hcl  
```

#### Workflow

![12](./img/12.jpg)

### Packer Templates

#### Block Organization

+ 一般来说，在 Packer 模板中，根块的顺序并不重要，因为 Packer 使用的是声明式模型。对其他资源的引用并不取决于它们的定义顺序。
+ 块甚至可以跨越多个 Packer 模板文件。
+ 在构建过程中，provisioner 或post-processor块的顺序是块顺序唯一重要的特征。

