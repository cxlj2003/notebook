# 1. 脚本开头
## 1.1  shebang解释器

```
#!/bin/bash      #Bash
#!/bin/sh        #BourneShell
#!/usr/bin/pwsh  #PowerShell
#!/usr/bin/perl  #Per
#!/usr/bin/tcl   #TCL
#!/usr/bin/sed -f
#!/usr/bin/awk -f
#!/usr/bin/python3
#!/usr/bin/env python3
```
## 1.2 解释器选项

-  -e 当脚本发生第一个错误时, 就退出脚本, 换种说法就是, 当一个命令返回
非零值时, 就退出脚本;
-  -x 与-v选项类似, 但是会打印完整命令
-  -f  禁用文件名扩展
# 2. 注释
## 2.1 单行注释

```
#注释1
#注释2
```
## 2.2 多行注释

```
:<<EOF
注释1
注释2
EOF
```
# 3. 