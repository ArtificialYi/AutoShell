### 做单层跳板机跳转
1. 项目拉下来之后在根目录下创建一个gw.ini文件（内容可以和gwDemo.ini一样）
2. 将yzgw.sh加入到alias中
如：alias yzgw="~/learn/AutoShell/yzgw.sh"
3. 脚本运行demo
``yzgw qa schedule 0``
第一个参数为运行环境（如：qa、pre、prod）
第二个参数为应用名（如：schedule）
第三个参数为机器索引（如0、1、2，默认为0）
4. 脚本逻辑
4.1. 根据运行环境获取执行跳板机命令
4.2. 根据应用名获取在跳板机执行的命令
4.3. 将命令组合后发送到跳板机

#### gw.ini文件格式
看gwDemo.ini文件