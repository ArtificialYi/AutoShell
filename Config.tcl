#!/usr/bin/tclsh
namespace eval Config {
    set version 1.0
    proc getGwName {file envName} {
        set gwName "";

        set fp [open "$file" r]
        set findStack {"[runMode]"}
        set gwName [getValueByStackKey $fp $findStack $envName]
        close $fp

        return $gwName
    }

    proc getGwCommand {file gwName randNum} {
        set gwCommand "";

        set fp [open "$file" r]
        set tmpStackName [name2flag $gwName]
        set findStack [list $tmpStackName]
        set gwCommand [getValueByStackKey $fp $findStack $randNum]
        close $fp

        return $gwCommand
    }

    proc getMachineName {file envName appName} {
        set fp [open "$file" r]
        set findStack [list "\[machine]" [name2flag $envName]]
        set gwCommand [getValueByStackKey $fp $findStack $appName]
        close $fp
        return $gwCommand
    }

    proc name2flag {name} {
        set tmpStackName "\["
        append tmpStackName $name
        append tmpStackName "]"
        return $tmpStackName
    }

    proc getValueByStackKey {fp targetStack key} {
        set currentValue ""
        seek $fp 0 start
        set currentStack {}
        if {[findBeginStack $fp $targetStack $currentStack]} {
            set endStack [pop $targetStack]
            set tmpCurrentStack $targetStack
            while {[eof $fp] != 1} {
                set flag 0
                set line [getLine $fp]
                set nodeType [getNodeType $line]
                switch $nodeType {
                    "begin" {
                        set tmpCurrentStack [beginAction $tmpCurrentStack $line]
                        set flag 1
                    }
                    "end" {
                        set tmpCurrentStack [endAction $tmpCurrentStack $line]
                        set flag 1
                    }
                    "kv" {
                        set currentKey [parseKv2Key $line]
                        if {$key == $currentKey && [compareStack $tmpCurrentStack $targetStack]} {
                            set currentValue [parseKv2Value $line]
                            break
                        }
                    }
                    default {
                        continue
                    }
                }
                if {$flag && [compareStack $tmpCurrentStack $endStack]} {
                    break
                }
            }
        }
        return $currentValue
    }

    proc findBeginStack {fp findStack currentStack} {
        set tmpCurrentStack $currentStack
        if {[compareStack $tmpCurrentStack $findStack]} {
            return 1
        }
        while {[eof $fp] != 1} {
            set line [getLine $fp]
            set nodeType [getNodeType $line]
            switch $nodeType {
                "begin" {
                    set tmpCurrentStack [beginAction $tmpCurrentStack $line]
                }
                "end" {
                    set tmpCurrentStack [endAction $tmpCurrentStack $line]
                }
                default {
                    continue
                }
            }
            if {[compareStack $tmpCurrentStack $findStack]} {
                return 1
            }
        }
        return 0;
    }

    proc parseKv2Key {kv} {
        set eqIndex [string first = $kv]
        if {$eqIndex != -1} {
            return [string range $kv 0 [expr $eqIndex - 1]];
        }
        return ""
    }

    proc parseKv2Value {kv} {
        set eqIndex [string first = $kv]
        if {$eqIndex != -1} {
            return [string range $kv [expr $eqIndex + 1] [string length $kv]];
        }
        return ""
    }

    proc beginAction {stack line} {
        set stackPtr [lappend stack $line]
        return $stackPtr
    }

    proc endAction {stack line} {
        set topIndex [expr [llength $stack] - 1]
        set topStr [lindex $stack $topIndex]
        if {[compareStr [string trimleft $topStr "\["] [string trimleft $line "\[/"]]} {
            set stackPtr [lreplace $stack $topIndex $topIndex]
        } else {
            puts "这个结束节点是错的$stack:$line"
            exit
        }
        return $stackPtr
    }

    proc getNodeType {line} {
        if {[string length $line] >= 3} {
            set eqIndex [string first = $line]
            set startIndex [string first "\[" $line]
            set endIndex [string first "\]" $line]
            set endNodeIndex [string first "\/" $line]
            if {$eqIndex > 0} {
                return "kv";
            } elseif {$startIndex == 0 && $endIndex == [expr [string length $line] - 1]} {
                if {$endNodeIndex == 1} {
                    return "end"
                } else {
                    return "begin"
                }
            }
        }
        return ""
    }

    proc getLine {fp} {
        gets $fp line
        return [getNoTrimStr $line]
    }

    proc compareStr {expect line} {
        return [expr [string compare $expect $line] == 0];
    }

    proc compareStack {expect stack} {
        set res 0
        set expectSize [llength $expect]
        set stackSize [llength $stack]
        if {$expectSize != $stackSize} {
            return $res
        }
        for {set i 0} {$i < $expectSize} {incr i} {
            if {![compareStr [lindex $stack $i] [lindex $expect $i]]} {
                return 0
            }
        }
        return 1;
    }

    proc getNoTrimStr {line} {
        return [string trim $line];
    }

    proc pop {stack} {
        set topIndex [expr [llength $stack] - 1]
        set stackPtr [lreplace $stack $topIndex $topIndex]
        return stackPtr
    }
}

package provide Config $Config::version
package require Tcl 8.0