#!/usr/bin/expect
if {$argc < 2} {
    send_user "参数错误,最少传2个参数"
    exit
}

set timeout 5
# 设置关键文件
proc file2folder {file} {
    set splitIndex [string last / $file]
    return [string range $file 0 [expr $splitIndex - 1]]
}
set fileDir [file2folder $argv0]
set configFile "$fileDir/yzgw.ini"

lappend auto_path "$fileDir/"
package require Config 1.0

# 初始化参数
set envName [lindex $argv 0]
set machineName [lindex $argv 1]
set machineIndex [lindex $argv 2]
if {$machineIndex == ""} {
    set machineIndex 0
}

send_user "环境为：$envName\n"
send_user "应用名：$machineName\n"
send_user "机器编号：$machineIndex\n"

set gwName [Config::getGwName $configFile $envName]
set randNum [expr {int (rand() * 2)}]
set tmpCommand [Config::getGwCommand $configFile $gwName $randNum]
if {![Config::compareStr tmpCommand ""]} {
    eval "spawn $tmpCommand"
} else {
    send_user "没有这种环境配置:$envName:$gwName"
    exit
}
set tmpMachine [Config::getMachineName $configFile $envName $machineName]
set tmpMachineCommand "i $tmpMachine$machineIndex\n"

send $tmpMachineCommand
interact
