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
-  -f  禁用Bash扩展
# 2. 注释
## 2.1 单行注释

```
#注释1
#注释2
```
## 2.2 多行注释

方式1：
```
:<<EOF
注释1
注释2
EOF
```

方式2：`: + 空格 + 单引号`
```
: '
注释1
注释2
'
```
# 3. 命令格式及操作符

## 3.1 基础格式

```
command [arg1 ... [argN]]
```

`command`是具体的命令或者一个可执行文件，`arg1 ... argN`是传递给命令的参数，它们是可选的。

```
ls -l
```

`ls`是命令,`-l`是参数
## 3.2 空格和TAB

Bash 使用空格（或 Tab 键）分割命令和参数。
如果参数之间有多个空格，Bash 会自动忽略多余的空格。
## 3.3 反斜杠（`\`）

Bash 单个命令一般都是一行，用户按下回车键，就开始执行。有些命令比较长，写成多行会有利于阅读和编辑，这时可以在每一行的结尾加上反斜杠，Bash 就会将下一行跟当前行放在一起解释。

```
./config --prefix=/usr/local/openssl \
--with-zlib-lib=/usr/local/zlib/lib \
--with-zlib-include=/usr/local/zlib/include \
enable-md2 \
shared
```

## 3.4 分号 `;`

分号（`;`）是命令的结束符，使得一行可以放置多个命令，上一个命令执行结束后，再执行第二个命令。

```
clear ; ls -l
```

>[!IMPORTANT]
>使用分号时，第二个命令总是接着第一个命令执行，不管第一个命令执行成功或失败

## 3.5 命令组合符号 `&&`和`||`

除了分号，Bash 还提供两个命令组合符`&&`和`||`，允许更好地控制多个命令之间的继发关系。

```
Command1 && Command2
```

上面命令的意思是，如果`Command1`命令运行成功，则继续运行`Command2`命令。

```
Command1 || Command2
```

上面命令的意思是，如果`Command1`命令运行失败，则继续运行`Command2`命令。

## 3.6 `type`

`type`命令用来判断命令的来源。
如果要查看一个命令的所有定义，可以使用`type`命令的`-a`参数。
`type`命令的`-t`参数，可以返回一个命令的类型：别名（alias），关键词（keyword），函数（function），内置命令（builtin）和文件（file）
# 4. 模式扩展
## 4.1 简介

Shell 接收到用户输入的命令以后，会根据空格将用户的输入，拆分成一个个词元（token）。然后，Shell 会扩展词元里面的特殊字符，扩展完成后才会调用相应的命令。

这种特殊字符的扩展，称为模式扩展（globbing）。其中有些用到通配符，又称为通配符扩展（wildcard expansion）。Bash 一共提供八种扩展。

-  波浪线（`~` ）
-  问号（`?`）
-  星号（`*`）
-  方括号（`[]`）
-  大括号（`{}`）
-  变量（`$`）
-  子命令 （\`Command\`或`$(Command)`）
-  算术（`$((...))`）
## 4.2 开启和关闭

关闭Bash扩展

```
$ set -o noglob
# 或者
$ set -f
```

重新打开Bash扩展

```
$ set +o noglob
# 或者
$ set +f
```

>[!IMPORTANT]
>Bash 是先进行扩展，再执行命令。因此，扩展的结果是由 Bash 负责的，与所要执行的命令无关。命令本身并不存在参数扩展，收到什么参数就原样执行。这一点务必需要记住。

## 4.3 波浪线（`~` ）

波浪线`~`会自动扩展成当前用户的主目录。
`~user`表示扩展成用户`user`的主目录。

>[!NOTE]
>如果`~user`的`user`是不存在的用户名，则波浪号扩展不起作用。
>`~+`会扩展成当前所在的目录

## 4.4 问号（`?`）

`?`字符代表文件路径里面的任意单个字符，不包括空字符。

## 4.5 星号（`*`）

`*`字符代表文件路径里面的任意数量的任意字符，包括零个字符。

## 4.6  方括号（`[]`）

 ### 4.6.1 `[...]` `[^...]` `[!...]`
 
 `[aeiou]`可以匹配五个元音字母中的任意一个。
 
`[^abc]`或`[!abc]`表示匹配除了`a`、`b`、`c`以外的字符。

>[!NOTE]
>1.`[`字符，可以放在方括号内，比如`[[aeiou]`
>2.`-`字符，只能放在方括号内部的开头或结尾，比如`[-aeiou]`或`[aeiou-]`

 ### 4.6.2 `[start-end]` `[!start-end]`
 
 方括号扩展有一个简写形式`[start-end]`，表示匹配一个连续的范围。比如，`[a-c]`等同于`[abc]`，`[0-9]`匹配`[0123456789]`;
 否定形式`[!start-end]`，表示匹配不属于这个范围的字符。比如，`[!a-zA-Z]`表示匹配非英文字母的字符。

- `[a-z]`：所有小写字母。
- `[a-zA-Z]`：所有小写字母与大写字母。
- `[a-zA-Z0-9]`：所有小写字母、大写字母与数字。
- `[abc]*`：所有以`a`、`b`、`c`字符之一开头的文件名。
- `program.[co]`：文件`program.c`与文件`program.o`。
- `BACKUP.[0-9][0-9][0-9]`：所有以`BACKUP.`开头，后面是三个数字的文件名。

## 4.7 大括号（`{}`）

### 4.7.1 `{...}`

大括号扩展`{...}`表示分别扩展成大括号里面的所有值，各个值之间使用逗号分隔。比如，`{1,2,3}`扩展成`1 2 3`

```
#在opt目录下创建3个文件夹
mkdir -p /opt/{1,2,3}
```

>[!NOTE]
>大括号内部的逗号前后不能有空格。否则，大括号扩展会失效。
>大括号内部的逗号前后可以没有值，表示空值。
>大括号可以嵌套。
>大括号也可以与其他模式联用，并且总是先于其他模式进行扩展。

### 4.7.2 {start..end}  `{start..end..step}`

大括号扩展有一个简写形式`{start..end}`，表示扩展成一个连续序列。比如，`{a..z}`可以扩展成26个小写英文字母。这种简写形式支持逆序。比如，`{z..a}`可以扩展成26个小写英文字母。

```
echo {{a..z},{z..a}}
echo {001..100}
echo {001..100..2}
echo {a..c}{1..10..2}
echo {a..c}{2..10..2}
```

## 4.8 变量（`$`）

Bash 将美元符号`$`开头的词元视为变量，将其扩展成变量值，详见《Bash 变量》一章。

```
echo $SHELL
```

变量名除了放在美元符号后面，也可以放在`${}`里面。

```
echo ${SHELL}
```

`${!string*}`或`${!string@}`返回所有匹配给定字符串`string`的变量名。

```
echo ${!S*}
```

上面例子中，`${!S*}`扩展成所有以`S`开头的变量名。

## 4.9  子命令 （\`Command\`或`$(Command)`）

`$(...)`可以扩展成另一个命令的运行结果，该命令的所有输出都会作为返回值。
还有另一种较老的语法，子命令放在\`\`反引号之中，也可以扩展成命令的运行结果。
`$(...)`可以嵌套，比如 `echo $(ls -l $(pwd))`。

```
echo `date`
echo $(date)
echo $(ls -l $(pwd))
```

## 4.10 算术（`$((...))`）

`$((...))`可以扩展成整数运算的结果.

```
echo $((2 + 2))
```

# 5.  特殊字符

## 5.1  反斜杠`\`

1. 需要进行转义的特殊字符
	-  `$`
	-  `&`
	-  `*`
	-  `\`
	-  `` ` ``

1. 不可打印的字符
	- `\a`：响铃
	- `\b`：退格
	- `\n`：换行
	- `\r`：回车
	- `\t`：制表符


## 5.2 单引号 `'`

单引号用于保留字符的字面含义，各种特殊字符在单引号里面，都会变为普通字符，比如星号（`*`）、美元符号（`$`）、反斜杠（`\`）等。

单引号使得 Bash 扩展、变量引用、算术运算和子命令，都失效了。如果不使用单引号，它们都会被 Bash 自动扩展。

>[!IMPORTANT]
>由于反斜杠在单引号里面变成了普通字符，所以如果单引号之中，还要使用单引号，不能使用转义，需要在外层的单引号前面加上一个美元符号（`$`），然后再对里层的单引号转义。
>例如
>`echo $'it\'s'`
>更合理的做法`echo "it's"`


## 5.3 双引号`"`

双引号比单引号宽松，大部分特殊字符在双引号里面，都会失去特殊含义，变成普通字符。

- 美元符号（`$`）
- 反引号（`` ` ``）
- 反斜杠（`\`）

## 5.4 Here文档

Here 文档（here document）是一种输入多行字符串的方法，格式如下。

```
<< token
text
token
```

>[!NOTE]
>它的格式分成开始标记（`<< token`）和结束标记（`token`）。开始标记是两个小于号 + Here 文档的名称，名称可以随意取，后面必须是一个换行符；结束标记是单独一行顶格写的 Here 文档名称，如果不是顶格，结束标记不起作用。两者之间就是多行字符串的内容。

Here 文档内部会发生变量替换，同时支持反斜杠转义，但是不支持通配符扩展，双引号和单引号也失去语法作用，变成了普通字符。

```
$ foo='hello world'
$ cat << _example_
$foo
"$foo"
'$foo'
_example_

hello world
"hello world"
'hello world'
```

如果不希望发生变量替换，可以把 Here 文档的开始标记放在单引号之中。

```
$ foo='hello world'
$ cat << '_example_'
$foo
"$foo"
'$foo'
_example_

$foo
"$foo"
'$foo'
```

上面例子中，Here 文档的开始标记（`_example_`）放在单引号之中，导致变量替换失效了。

Here 文档的本质是重定向，它将字符串重定向输出给某个命令，相当于包含了`echo`命令。

```
$ command << token
  string
token

# 等同于

$ echo string | command
```

上面代码中，Here 文档相当于`echo`命令的重定向。

Here 文档还有一个变体，叫做 Here 字符串（Here string），使用三个小于号（`<<<`）表示。它的作用是将字符串通过标准输入，传递给命令。

```
<<< string
```

有些命令直接接受给定的参数，与通过标准输入接受参数，结果是不一样的。所以才有了这个语法，使得将字符串通过标准输入传递给命令更方便，比如`cat`命令只接受标准输入传入的字符串。

```
$ cat <<< 'hi there'
# 等同于
$ echo 'hi there' | cat
```

上面的第一种语法使用了 Here 字符串，要比第二种语法看上去语义更好，也更简洁。

```
$ md5sum <<< 'ddd'
# 等同于
$ echo 'ddd' | md5sum
```

上面例子中，`md5sum`命令只能接受标准输入作为参数，不能直接将字符串放在命令后面，会被当作文件名，即`md5sum ddd`里面的`ddd`会被解释成文件名。这时就可以用 Here 字符串，将字符串传给`md5sum`命令。
# 6. 变量

## 6.1 环境变量

### 6.1.1 全局环境变量

环境变量是 Bash 环境自带的变量，进入 Shell 时已经定义好了，可以直接使用。它们通常是系统定义好的，也可以由用户从父 Shell 传入子 Shell。

`env`命令或`printenv`命令，可以显示所有环境变量。

```
$ env
# 或者
$ printenv
```

下面是一些常见的环境变量。

- `BASHPID`：Bash 进程的进程 ID。
- `BASHOPTS`：当前 Shell 的参数，可以用`shopt`命令修改。
- `DISPLAY`：图形环境的显示器名字，通常是`:0`，表示 X Server 的第一个显示器。
- `EDITOR`：默认的文本编辑器。
- `HOME`：用户的主目录。
- `HOST`：当前主机的名称。
- `IFS`：词与词之间的分隔符，默认为空格。
- `LANG`：字符集以及语言编码，比如`zh_CN.UTF-8`。
- `PATH`：由冒号分开的目录列表，当输入可执行程序名后，会搜索这个目录列表。
- `PS1`：Shell 提示符。
- `PS2`： 输入多行命令时，次要的 Shell 提示符。
- `PWD`：当前工作目录。
- `RANDOM`：返回一个0到32767之间的随机数。
- `SHELL`：Shell 的名字。
- `SHELLOPTS`：启动当前 Shell 的`set`命令的参数。
- `TERM`：终端类型名，即终端仿真器所用的协议。
- `UID`：当前用户的 ID 编号。
- `USER`：当前用户的用户名。

很多环境变量很少发生变化，而且是只读的，可以视为常量。由于它们的变量名全部都是大写，所以传统上，如果用户要自己定义一个常量，也会使用全部大写的变量名。

>[!NOTE]
>Bash 变量名区分大小写，`HOME`和`home`是两个不同的变量。

查看单个环境变量的值，可以使用`printenv`命令或`echo`命令。

```
$ printenv PATH
# 或者
$ echo $PATH
```

>[!NOTE]
>`printenv`命令后面的变量名，不用加前缀`$`。

### 6.1.2 局部环境变量

局部环境变量只能在定义它们的进程中可见。尽管它们是局部的，但是和全局环境变量一样重要。事实上，Linux系统也默认定义了标准的局部环境变量，局部环境变量是用户在当前 Shell 里面自己定义的变量，仅在当前 Shell 可用。一旦退出当前 Shell，该变量就不存在了。

`set`命令可以显示所有变量（包括环境变量和自定义变量），以及所有的 Bash 函数。

```
$ set
```

>[!NOTE]
>命令env、printenv和set之间的差异
>set命令会显示出全局变量、局部变量以及用户定义变量。它还会按照字母顺序对结果进行排序;
>env和printenv命令同set命令的区别在于前两个命令不会对变量排序，也不会输出局部变量和用户定义变量;
## 6.2 用户定义变量
### 6.2.1 创建局部用户定义变量

用户创建变量的时候，变量名必须遵守下面的规则。

- 字母、数字和下划线字符组成。
- 第一个字符必须是一个字母或一个下划线，不能是数字。
- 不允许出现空格和标点符号。

变量声明的语法如下。

```
variable=value
```

上面命令中，等号左边是变量名，右边是变量。

>[!NOTE]
>注意，等号两边不能有空格。

如果变量的值包含空格，则必须将值放在引号中。

```
myvar="hello world"
```

Bash 没有数据类型的概念，所有的变量值都是字符串。

下面是一些自定义变量的例子。

```
a=z                     # 变量 a 赋值为字符串 z
b="a string"            # 变量值包含空格，就必须放在引号里面
c="a string and $b"     # 变量值可以引用其他变量的值
d="\t\ta string\n"      # 变量值可以使用转义字符
e=$(ls -l foo.txt)      # 变量值可以是命令的执行结果
f=$((5 * 7))            # 变量值可以是数学运算的结果
```

变量可以重复赋值，后面的赋值会覆盖前面的赋值。

```
$ foo=1
$ foo=2
$ echo $foo
2
```

上面例子中，变量`foo`的第二次赋值会覆盖第一次赋值。

如果同一行定义多个变量，必须使用分号（`;`）分隔。

```
$ foo=1;bar=2
```

上面例子中，同一行定义了`foo`和`bar`两个变量。

### 6.2.2 创建全局环境变量

在设定全局环境变量的进程所创建的子进程中，该变量都是可见的。创建全局环境变量的方法是先创建一个局部环境变量，然后再把它导出到全局环境中。这个过程通过export命令来完成，变量名前面不需要加$。

```
NAME=foo
export NAME
```

```
export NAME=value
```

### 6.2.3 创建包含默认值的变量

Bash 提供四个特殊语法，跟变量的默认值有关，目的是保证变量不为空。

```
${varname:-word}
```

上面语法的含义是，如果变量`varname`存在且不为空，则返回它的值，否则返回`word`。它的目的是返回一个默认值，比如`${count:-0}`表示变量`count`不存在时返回`0`。

```
${varname:=word}
```

上面语法的含义是，如果变量`varname`存在且不为空，则返回它的值，否则将它设为`word`，并且返回`word`。它的目的是设置变量的默认值，比如`${count:=0}`表示变量`count`不存在时返回`0`，且将`count`设为`0`。

```
${varname:+word}
```

上面语法的含义是，如果变量名存在且不为空，则返回`word`，否则返回空值。它的目的是测试变量是否存在，比如`${count:+1}`表示变量`count`存在时返回`1`（表示`true`），否则返回空值。

```
${varname:?message}
```

上面语法的含义是，如果变量`varname`存在且不为空，则返回它的值，否则打印出`varname: message`，并中断脚本的执行。如果省略了`message`，则输出默认的信息“parameter null or not set.”。它的目的是防止变量未定义，比如`${count:?"undefined!"}`表示变量`count`未定义时就中断执行，抛出错误，返回给定的报错信息`undefined!`。

上面四种语法如果用在脚本中，变量名的部分可以用数字`1`到`9`，表示脚本的参数。

```
filename=${1:?"filename missing."}
```

上面代码出现在脚本中，`1`表示脚本的第一个参数。如果该参数不存在，就退出脚本并报错。

### 6.2.4 声明特殊类型的变量

#### -  **`declare`命令**

`declare`命令可以声明一些特殊类型的变量，为变量设置一些限制，比如声明只读类型的变量和整数类型的变量。

它的语法形式如下。

```
declare OPTION VARIABLE=value
```

`declare`命令的主要参数（OPTION）如下。

- `-a`：声明数组变量。
- `-f`：输出所有函数定义。
- `-F`：输出所有函数名。
- `-i`：声明整数变量。
- `-l`：声明变量为小写字母。
- `-p`：查看变量信息。
- `-r`：声明只读变量。
- `-u`：声明变量为大写字母。
- `-x`：该变量输出为环境变量。

`declare`命令如果用在函数中，声明的变量只在函数内部有效，等同于`local`命令。

不带任何参数时，`declare`命令输出当前环境的所有变量，包括函数在内，等同于不带有任何参数的`set`命令。

```
$ declare
```

**（1）`-i`参数**

`-i`参数声明整数变量以后，可以直接进行数学运算。

```
$ declare -i val1=12 val2=5
$ declare -i result
$ result=val1*val2
$ echo $result
60
```

上面例子中，如果变量`result`不声明为整数，`val1*val2`会被当作字面量，不会进行整数运算。另外，`val1`和`val2`其实不需要声明为整数，因为只要`result`声明为整数，它的赋值就会自动解释为整数运算。

注意，一个变量声明为整数以后，依然可以被改写为字符串。

```
$ declare -i var=12
$ var=foo
$ echo $var
0
```

上面例子中，变量`var`声明为整数，覆盖以后，Bash 不会报错，但会赋以不确定的值，上面的例子中可能输出0，也可能输出的是3。

**（2）`-x`参数**

`-x`参数等同于`export`命令，可以输出一个变量为子 Shell 的环境变量。

```
$ declare -x foo
# 等同于
$ export foo
```

**（3）`-r`参数**

`-r`参数可以声明只读变量，无法改变变量值，也不能`unset`变量。

```
$ declare -r bar=1

$ bar=2
bash: bar：只读变量
$ echo $?
1

$ unset bar
bash: bar：只读变量
$ echo $?
1
```

上面例子中，后两个赋值语句都会报错，命令执行失败。

**（4）`-u`参数**

`-u`参数声明变量为大写字母，可以自动把变量值转成大写字母。

```
$ declare -u foo
$ foo=upper
$ echo $foo
UPPER
```

**（5）`-l`参数**

`-l`参数声明变量为小写字母，可以自动把变量值转成小写字母。

```
$ declare -l bar
$ bar=LOWER
$ echo $bar
lower
```

**（6）`-p`参数**

`-p`参数输出变量信息。

```
$ foo=hello
$ declare -p foo
declare -- foo="hello"
$ declare -p bar
bar：未找到
```

上面例子中，`declare -p`可以输出已定义变量的值，对于未定义的变量，会提示找不到。

如果不提供变量名，`declare -p`输出所有变量的信息。

```
$ declare -p
```

**（7）`-f`参数**

`-f`参数输出当前环境的所有函数，包括它的定义。

```
$ declare -f
```

**（8）`-F`参数**

`-F`参数输出当前环境的所有函数名，不包含函数定义。

```
$ declare -F
```


#### - ** `readonly`命令**

`readonly`命令等同于`declare -r`，用来声明只读变量，不能改变变量值，也不能`unset`变量。

```
$ readonly foo=1
$ foo=2
bash: foo：只读变量
$ echo $?
1
```

上面例子中，更改只读变量`foo`会报错，命令执行失败。

`readonly`命令有三个参数。

- `-f`：声明的变量为函数名。
- `-p`：打印出所有的只读变量。
- `-a`：声明的变量为数组。

#### - **`let`命令**

`let`命令声明变量时，可以直接执行算术表达式。

```
$ let foo=1+2
$ echo $foo
3
```

上面例子中，`let`命令可以直接计算`1 + 2`。

`let`命令的参数表达式如果包含空格，就需要使用引号。

```
$ let "foo = 1 + 2"
```

`let`可以同时对多个变量赋值，赋值表达式之间使用空格分隔。

```
$ let "v1 = 1" "v2 = v1++"
$ echo $v1,$v2
2,1
```

上面例子中，`let`声明了两个变量`v1`和`v2`，其中`v2`等于`v1++`，表示先返回`v1`的值，然后`v1`自增。
## 6.3 特殊变量

### 6.3.1 位置参数变量

从命令行传递到脚本的参数: $0, $1, $2, $3 . . .

1. $0, $1, $2, $3 . . 

$0就是脚本文件自身的名字, $1 是第一个参数, $2是第二个参数, $3是第三个参数, 然后是第四个. $9之后的位置参数就必须用大括号括起来了, 比如, ${10}, ${11}, ${12}.

2. `$@`和`$#`

`$#`表示脚本的参数数量，`$@`表示脚本的参数值。

### 6.3.2 其他特殊变量

Bash 提供一些特殊变量。这些变量的值由 Shell 提供，用户不能进行赋值。

（1）`$?`

`$?`为上一个命令的退出码，用来判断上一个命令是否执行成功。返回值是`0`，表示上一个命令执行成功；如果不是零，表示上一个命令执行失败。

```
$ ls doesnotexist
ls: doesnotexist: No such file or directory

$ echo $?
1
```

上面例子中，`ls`命令查看一个不存在的文件，导致报错。`$?`为1，表示上一个命令执行失败。

（2）`$$`

`$$`为当前 Shell 的进程 ID。

```
$ echo $$
10662
```

这个特殊变量可以用来命名临时文件。

```
LOGFILE=/tmp/output_log.$$
```

（3）`$_`

`$_`为上一个命令的最后一个参数。

```
$ grep dictionary /usr/share/dict/words
dictionary

$ echo $_
/usr/share/dict/words
```

（4）`$!`

`$!`为最近一个后台执行的异步命令的进程 ID。

```
$ firefox &
[1] 11064

$ echo $!
11064
```

上面例子中，`firefox`是后台运行的命令，`$!`返回该命令的进程 ID。

（5）`$0`

`$0`为当前 Shell 的名称（在命令行直接执行时）或者脚本名（在脚本中执行时）。

```
$ echo $0
bash
```

上面例子中，`$0`返回当前运行的是 Bash。

（6）`$-`

`$-`为当前 Shell 的启动参数。

```
$ echo $-
himBHs
```

（7）


## 6.4 读取和引用变量

读取变量的时候，直接在变量名前加上`$`就可以了。

```
$ foo=bar
$ echo $foo
bar
```

每当 Shell 看到以`$`开头的单词时，就会尝试读取这个变量名对应的值。

如果变量不存在，Bash 不会报错，而会输出空字符。

由于`$`在 Bash 中有特殊含义，把它当作美元符号使用时，一定要非常小心，

```
$ echo The total is $100.00
The total is 00.00
```

上面命令的原意是输入`$100`，但是 Bash 将`$1`解释成了变量，该变量为空，因此输入就变成了`00.00`。所以，如果要使用`$`的原义，需要在`$`前面放上反斜杠，进行转义。

```
$ echo The total is \$100.00
The total is $100.00
```

读取变量的时候，变量名也可以使用花括号`{}`包围，比如`$a`也可以写成`${a}`。这种写法可以用于变量名与其他字符连用的情况。

```
$ a=foo
$ echo $a_file

$ echo ${a}_file
foo_file
```

上面代码中，变量名`a_file`不会有任何输出，因为 Bash 将其整个解释为变量，而这个变量是不存在的。只有用花括号区分`$a`，Bash 才能正确解读。

事实上，读取变量的语法`$foo`，可以看作是`${foo}`的简写形式。

如果变量的值本身也是变量，可以使用`${!varname}`的语法，读取最终的值。

```
$ myvar=USER
$ echo ${!myvar}
ruanyf
```

上面的例子中，变量`myvar`的值是`USER`，`${!myvar}`的写法将其展开成最终的值。

如果变量值包含连续空格（或制表符和换行符），最好放在双引号里面读取。

```
$ a="1 2  3"
$ echo $a
1 2 3
$ echo "$a"
1 2  3
```

上面示例中，变量`a`的值包含两个连续空格。如果直接读取，Shell 会将连续空格合并成一个。只有放在双引号里面读取，才能保持原来的格式。

## 6.5 删除变量

`unset`命令用来删除一个变量。

```
unset NAME
```

这个命令不是很有用。因为不存在的 Bash 变量一律等于空字符串，所以即使`unset`命令删除了变量，还是可以读取这个变量，值为空字符串。

所以，删除一个变量，也可以将这个变量设成空字符串。

```
$ foo=''
$ foo=
```

上面两种写法，都是删除了变量`foo`。由于不存在的值默认为空字符串，所以后一种写法可以在等号右边不写任何值。

## 6.6 数组变量

### 6.6.1 声明

```
arry=(one two three four five)
declare -a arry #声明关联数组（类似字典）
```

```
NIC=`ip route | egrep -v "br|docker|default" | egrep "eth|ens|enp"|awk '{print $3}'` 
```


```
declare -A master
master=([ip]="172.16.41.50" [cnc]="61.156.14.176" [ctcc]="144.123.23.125" [cmcc]="120.220.248.125" [other]="61.156.14.176")

echo ${master[ip]}

```
### 6.6.2 数组相关操作

```
echo ${array[*]}    #打印数组中所有值
echo ${array[@]}    #打印数组中所有值

echo ${!array[*]}   #打印下标
echo ${!array[@]}   #打印下标

echo ${#array[2]}   #打印某个变量的长度

echo ${#array[*]}   #打印数组长度 
echo ${#array[@]}   #打印数组长度 

#以数组值的方式直接遍历数组
arry=(one two three four five)
for i in ${array[*]}
do 
	ehco $i
done

#以数组变量个数的方式遍历数组
arry=(one two three four five)
for ((i=0;i<${#array[*]};i++))
do
	echo ${array[$i]}
done

#以数组index的方式遍历数组
arry=(one two three four five)
for i in ${!array[*]}
do
	echo ${array[$i]}
done
```

# 7. 基础操作符

## 7.1 交互式输入

有时，脚本需要在执行过程中，由用户提供一部分数据，这时可以使用`read`命令。它将用户的输入存入一个变量，方便后面的代码使用。用户按下回车键，就表示输入结束。

`read`命令的格式如下。

```
read [-options] [variable...]
```

上面语法中，`options`是参数选项，`variable`是用来保存输入数值的一个或多个变量名。如果没有提供变量名，环境变量`REPLY`会包含用户输入的一整行数据。

下面是一个例子`demo.sh`。

```
#!/bin/bash

echo -n "输入一些文本 > "
read text
echo "你的输入：$text"
```

上面例子中，先显示一行提示文本，然后会等待用户输入文本。用户输入的文本，存入变量`text`，在下一行显示出来。

```
$ bash demo.sh
输入一些文本 > 你好，世界
你的输入：你好，世界
```

`read`可以接受用户输入的多个值。

```
#!/bin/bash
echo Please, enter your firstname and lastname
read FN LN
echo "Hi! $LN, $FN !"
```

上面例子中，`read`根据用户的输入，同时为两个变量赋值。

如果用户的输入项少于`read`命令给出的变量数目，那么额外的变量值为空。如果用户的输入项多于定义的变量，那么多余的输入项会包含到最后一个变量中。

如果`read`命令之后没有定义变量名，那么环境变量`REPLY`会包含所有的输入。

```
#!/bin/bash
# read-single: read multiple values into default variable
echo -n "Enter one or more values > "
read
echo "REPLY = '$REPLY'"
```

上面脚本的运行结果如下。

```
$ read-single
Enter one or more values > a b c d
REPLY = 'a b c d'
```

`read`命令除了读取键盘输入，可以用来读取文件。

```
#!/bin/bash

filename='/etc/hosts'

while read myline
do
  echo "$myline"
done < $filename
```

上面的例子通过`read`命令，读取一个文件的内容。`done`命令后面的定向符`<`，将文件内容导向`read`命令，每次读取一行，存入变量`myline`，直到文件读取完毕。

```
cat file | while read line
do 
	echo $line
done
```

## 7.2 重定向

### 7.2.1 输出重定向

```
command1 > file1
```

```
command1 >> file1
```

```
command1 &> /dev/null
```
### 7.2.2 输入重定向

```
command1 < file1
```

### 7.2.3 `|`管道符



# 8. 条件判断

## 8.1 `if-then`语句

最基本的结构化命令就是if-then语句。if-then语句有如下格式。

```
if command
then
	commands
fi
```

## 8.2 `if-then-else` 语句

if-then-else语句在语句中提供了另外一组命令。
```
if command
then
	commands
else
	commands
fi
```

## 8.3 嵌套if

elif使用另一个if-then语句延续else部分。

```
if command1
then
	commands
elif command2
then
	more commands
fi
```

可以继续将多个elif语句串起来，形成一个大的if-then-elif嵌套组合。

```
if command1
then
	command set 1
elif command2
then
	command set 2
elif command3
then
	command set 3
elif command4
then
	command set 4
fi
```

>[!NOTE]
>1.`if-then`语句只能以命令退出状态码为测试条件。
>2.bash shell会依次执行if语句，只有第一个返回退出状态码0的语句中的`then`部分会被执行。

## 8.4 `test`命令

test命令提供了在if-then语句中测试不同条件的途径。
- 如果test命令中列出的条件成立，test命令就会退出并返回退出状态码0
- 如果条件不成立，test命令就会退出并返回非零的退出状态码

`if`结构的判断条件，一般使用`test`命令，有三种形式。

```
# 写法一
test condition

# 写法二
[ condition ]

# 写法三
[[ condition ]]
```

上面三种形式是等价的，但是第三种形式还支持正则判断，前两种不支持。

>[!IMPORTANT]
>第一个方括号之后和第二个方括号之前必须加上一个空格，否则就会报错。
>例如:`[ condition ]`

## 8.5 判断表达式

`if`关键字后面，跟的是一个命令。这个命令可以是`test`命令，也可以是其他命令。命令的返回值为`0`表示判断成立，否则表示不成立。因为这些命令主要是为了得到返回值，所以可以视为表达式。

### 8.5.1 文件判断

以下表达式用来判断文件状态。

- `[ -a file ]`：如果 file 存在，则为`true`。
- `[ -b file ]`：如果 file 存在并且是一个块（设备）文件，则为`true`。
- `[ -c file ]`：如果 file 存在并且是一个字符（设备）文件，则为`true`。
- `[ -d file ]`：如果 file 存在并且是一个目录，则为`true`。
- `[ -e file ]`：如果 file 存在，则为`true`。
- `[ -f file ]`：如果 file 存在并且是一个普通文件，则为`true`。
- `[ -g file ]`：如果 file 存在并且设置了组 ID，则为`true`。
- `[ -G file ]`：如果 file 存在并且属于有效的组 ID，则为`true`。
- `[ -h file ]`：如果 file 存在并且是符号链接，则为`true`。
- `[ -k file ]`：如果 file 存在并且设置了它的“sticky bit”，则为`true`。
- `[ -L file ]`：如果 file 存在并且是一个符号链接，则为`true`。
- `[ -N file ]`：如果 file 存在并且自上次读取后已被修改，则为`true`。
- `[ -O file ]`：如果 file 存在并且属于有效的用户 ID，则为`true`。
- `[ -p file ]`：如果 file 存在并且是一个命名管道，则为`true`。
- `[ -r file ]`：如果 file 存在并且可读（当前用户有可读权限），则为`true`。
- `[ -s file ]`：如果 file 存在且其长度大于零，则为`true`。
- `[ -S file ]`：如果 file 存在且是一个网络 socket，则为`true`。
- `[ -t fd ]`：如果 fd 是一个文件描述符，并且重定向到终端，则为`true`。 这可以用来判断是否重定向了标准输入／输出／错误。
- `[ -u file ]`：如果 file 存在并且设置了 setuid 位，则为`true`。
- `[ -w file ]`：如果 file 存在并且可写（当前用户拥有可写权限），则为`true`。
- `[ -x file ]`：如果 file 存在并且可执行（有效用户有执行／搜索权限），则为`true`。
- `[ FILE1 -nt FILE2 ]`：如果 FILE1 比 FILE2 的更新时间更近，或者 FILE1 存在而 FILE2 不存在，则为`true`。
- `[ FILE1 -ot FILE2 ]`：如果 FILE1 比 FILE2 的更新时间更旧，或者 FILE2 存在而 FILE1 不存在，则为`true`。
- `[ FILE1 -ef FILE2 ]`：如果 FILE1 和 FILE2 引用相同的设备和 inode 编号，则为`true`。

### 8.5.2 字符串判断

以下表达式用来判断字符串。

- `[ string ]`：如果`string`不为空（长度大于0），则判断为真。
- `[ -n string ]`：如果字符串`string`的长度大于零，则判断为真。
- `[ -z string ]`：如果字符串`string`的长度为零，则判断为真。
- `[ string1 = string2 ]`：如果`string1`和`string2`相同，则判断为真。
- `[ string1 == string2 ]` 等同于`[ string1 = string2 ]`。
- `[ string1 != string2 ]`：如果`string1`和`string2`不相同，则判断为真。
- `[ string1 '>' string2 ]`：如果按照字典顺序`string1`排列在`string2`之后，则判断为真。
- `[ string1 '<' string2 ]`：如果按照字典顺序`string1`排列在`string2`之前，则判断为真。

>[!NOTE]
>`test`命令内部的`>`和`<`，必须用引号引起来（或者是用反斜杠转义）。
>否则，它们会被 shell 解释为重定向操作符。

### 8.5.3 整数判断

下面的表达式用于判断整数。

- `[ integer1 -eq integer2 ]`：如果`integer1`等于`integer2`，则为`true`。
- `[ integer1 -ne integer2 ]`：如果`integer1`不等于`integer2`，则为`true`。
- `[ integer1 -le integer2 ]`：如果`integer1`小于或等于`integer2`，则为`true`。
- `[ integer1 -lt integer2 ]`：如果`integer1`小于`integer2`，则为`true`。
- `[ integer1 -ge integer2 ]`：如果`integer1`大于或等于`integer2`，则为`true`。
- `[ integer1 -gt integer2 ]`：如果`integer1`大于`integer2`，则为`true`。
### 8.5.4 正则判断

`[[ expression ]]`这种判断形式，支持正则表达式。

```
[[ string1 =~ regex ]]
```

上面的语法中，`regex`是一个正则表示式，`=~`是正则比较运算符。

下面是一个例子。

```
#!/bin/bash

INT=-5

if [[ "$INT" =~ ^-?[0-9]+$ ]]; then
  echo "INT is an integer."
  exit 0
else
  echo "INT is not an integer." >&2
  exit 1
fi
```

上面代码中，先判断变量`INT`的字符串形式，是否满足`^-?[0-9]+$`的正则模式，如果满足就表明它是一个整数。

### 8.5.5 逻辑运算

通过逻辑运算，可以把多个`test`判断表达式结合起来，创造更复杂的判断。三种逻辑运算`AND`，`OR`，和`NOT`，都有自己的专用符号。

- `AND`运算：符号`&&`，也可使用参数`-a`。
- `OR`运算：符号`||`，也可使用参数`-o`。
- `NOT`运算：符号`!`。

示例：`AND`运算格式

```
if [ condition1 && condition2 ]
then
	command
fi
```

```
if [ condition1 ] && [ conditiron2 ]
then
	command
fi
```

示例：`OR`运算格式
```
if [ condition1 || condition2 ]
then
	command
fi
```

```
if [ condition1 ] || [ conditiron2 ]
then
	command
fi
```

示例：`NOT`运算格式
```
if !([ condition1 ] && [ condition2 ] )
then
	command
if
```

```
if !([ condition1 ] || [ condition2 ] )
then
	command
if
```

### 8.5.6 算术判断

Bash 还提供了`((...))`作为算术条件，进行算术运算的判断。

示例：
```
if ((3 > 2)); then
  echo "true"
fi
```

>[!NOTE]
>算术判断不需要使用`test`命令，而是直接使用`((...))`结构。
>这个结构的返回值，决定了判断的真伪。
>如果算术计算的结果是非零值，则表示判断成立。这一点跟命令的返回值正好相反，需要小心。

## 8.6 `case`语句

`case`结构用于多值判断，可以为每个值指定对应的命令，跟包含多个`elif`的`if`结构等价，但是语义更好。它的语法如下。

```
case expression in
  pattern )
    commands ;;
  pattern )
    commands ;;
  ...
esac
```

```
case variable in
pattern1 | pattern2) commands1;;
pattern3) commands2;;
*) default commands;;
esac
```
上面代码中，`expression`是一个表达式，`pattern`是表达式的值或者一个模式，可以有多条，用来匹配多个值，每条以两个分号（`;`）结尾。

```
#!/bin/bash

echo -n "输入一个1到3之间的数字"
read character
case character in
  1 ) echo 1
    ;;
  2 ) echo 2
    ;;
  3 ) echo 3
    ;;
  * ) echo 输入不符合要求
esac
```

上面例子中，最后一条匹配语句的模式是`*`，这个通配符可以匹配其他字符和没有输入字符的情况，类似`if`的`else`部分。

下面是另一个例子。

```
#!/bin/bash

OS=$(uname -s)

case "$OS" in
  FreeBSD) echo "This is FreeBSD" ;;
  Darwin) echo "This is Mac OSX" ;;
  AIX) echo "This is AIX" ;;
  Minix) echo "This is Minix" ;;
  Linux) echo "This is Linux" ;;
  *) echo "Failed to identify this OS" ;;
esac
```

上面的例子判断当前是什么操作系统。

`case`的匹配模式可以使用各种通配符，下面是一些例子。

- `a)`：匹配`a`。
- `a|b)`：匹配`a`或`b`。
- `[[:alpha:]])`：匹配单个字母。
- `???)`：匹配3个字符的单词。
- `*.txt)`：匹配`.txt`结尾。
- `*)`：匹配任意输入，通常作为`case`结构的最后一个模式。

```
#!/bin/bash

echo -n "输入一个字母或数字 > "
read character
case $character in
  [[:lower:]] | [[:upper:]] ) echo "输入了字母 $character"
                              ;;
  [0-9] )                     echo "输入了数字 $character"
                              ;;
  * )                         echo "输入不符合要求"
esac
```

上面例子中，使用通配符`[[:lower:]] | [[:upper:]]`匹配字母，`[0-9]`匹配数字。

Bash 4.0之前，`case`结构只能匹配一个条件，然后就会退出`case`结构。Bash 4.0之后，允许匹配多个条件，这时可以用`;;&`终止每个条件块。

```
#!/bin/bash
# test.sh

read -n 1 -p "Type a character > "
echo
case $REPLY in
  [[:upper:]])    echo "'$REPLY' is upper case." ;;&
  [[:lower:]])    echo "'$REPLY' is lower case." ;;&
  [[:alpha:]])    echo "'$REPLY' is alphabetic." ;;&
  [[:digit:]])    echo "'$REPLY' is a digit." ;;&
  [[:graph:]])    echo "'$REPLY' is a visible character." ;;&
  [[:punct:]])    echo "'$REPLY' is a punctuation symbol." ;;&
  [[:space:]])    echo "'$REPLY' is a whitespace character." ;;&
  [[:xdigit:]])   echo "'$REPLY' is a hexadecimal digit." ;;&
esac
```

执行上面的脚本，会得到下面的结果。

```
$ test.sh
Type a character > a
'a' is lower case.
'a' is alphabetic.
'a' is a visible character.
'a' is a hexadecimal digit.
```

可以看到条件语句结尾添加了`;;&`以后，在匹配一个条件之后，并没有退出`case`结构，而是继续判断下一个条件。

# 9. 循环 

## 9.1 `while`循环

`while`循环有一个判断条件，只要符合条件，就不断循环执行指定的语句。

```
while condition; do
  commands
done
```

上面代码中，只要满足条件`condition`，就会执行命令`commands`。然后，再次判断是否满足条件`condition`，只要满足，就会一直执行下去。只有不满足条件，才会退出循环。

循环条件`condition`可以使用`test`命令，跟`if`结构的判断条件写法一致。

```
#!/bin/bash

number=0
while [ "$number" -lt 10 ]; do
  echo "Number = $number"
  number=$((number + 1))
done
```

上面例子中，只要变量`$number`小于10，就会不断加1，直到`$number`等于10，然后退出循环。

关键字`do`可以跟`while`不在同一行，这时两者之间不需要使用分号分隔。

```
while true
do
  echo 'Hi, while looping ...';
done
```

上面的例子会无限循环，可以按下 Ctrl + c 停止。

`while`循环写成一行，也是可以的。

```
$ while true; do echo 'Hi, while looping ...'; done
```

`while`的条件部分也可以是执行一个命令。

```
$ while echo 'ECHO'; do echo 'Hi, while looping ...'; done
```

上面例子中，判断条件是`echo 'ECHO'`。由于这个命令总是执行成功，所以上面命令会产生无限循环。

`while`的条件部分可以执行任意数量的命令，但是执行结果的真伪只看最后一个命令的执行结果。

```
$ while true; false; do echo 'Hi, looping ...'; done
```

上面代码运行后，不会有任何输出，因为`while`的最后一个命令是`false`。

## 9.2 `until`循环

`until`循环与`while`循环恰好相反，只要不符合判断条件（判断条件失败），就不断循环执行指定的语句。一旦符合判断条件，就退出循环。

```
until condition; do
  commands
done
```

关键字`do`可以与`until`不写在同一行，这时两者之间不需要分号分隔。

```
until condition
do
  commands
done
```

下面是一个例子。

```
$ until false; do echo 'Hi, until looping ...'; done
Hi, until looping ...
Hi, until looping ...
Hi, until looping ...
^C
```

上面代码中，`until`的部分一直为`false`，导致命令无限运行，必须按下 Ctrl + c 终止。

```
#!/bin/bash

number=0
until [ "$number" -ge 10 ]; do
  echo "Number = $number"
  number=$((number + 1))
done
```

上面例子中，只要变量`number`小于10，就会不断加1，直到`number`大于等于10，就退出循环。

`until`的条件部分也可以是一个命令，表示在这个命令执行成功之前，不断重复尝试。

```
until cp $1 $2; do
  echo 'Attempt to copy failed. waiting...'
  sleep 5
done
```

上面例子表示，只要`cp $1 $2`这个命令执行不成功，就5秒钟后再尝试一次，直到成功为止。

`until`循环都可以转为`while`循环，只要把条件设为否定即可。上面这个例子可以改写如下。

```
while ! cp $1 $2; do
  echo 'Attempt to copy failed. waiting...'
  sleep 5
done
```

一般来说，`until`用得比较少，完全可以统一都使用`while`。

## 9.3 `for...in`循环

`for...in`循环用于遍历列表的每一项。

```
for variable in list
do
  commands
done
```

上面语法中，`for`循环会依次从`list`列表中取出一项，作为变量`variable`，然后在循环体中进行处理。

关键词`do`可以跟`for`写在同一行，两者使用分号分隔。

```
for variable in list; do
  commands
done
```

下面是一个例子。

```
#!/bin/bash

for i in word1 word2 word3; do
  echo $i
done
```

上面例子中，`word1 word2 word3`是一个包含三个单词的列表，变量`i`依次等于`word1`、`word2`、`word3`，命令`echo $i`则会相应地执行三次。

列表可以由通配符产生。

```
for i in *.png; do
  ls -l $i
done
```

上面例子中，`*.png`会替换成当前目录中所有 PNG 图片文件，变量`i`会依次等于每一个文件。

列表也可以通过子命令产生。

```
#!/bin/bash

count=0
for i in $(cat ~/.bash_profile); do
  count=$((count + 1))
  echo "Word $count ($i) contains $(echo -n $i | wc -c) characters"
done
```

上面例子中，`cat ~/.bash_profile`命令会输出`~/.bash_profile`文件的内容，然后通过遍历每一个词，计算该文件一共包含多少个词，以及每个词有多少个字符。

`in list`的部分可以省略，这时`list`默认等于脚本的所有参数`$@`。但是，为了可读性，最好还是不要省略，参考下面的例子。

```
for filename; do
  echo "$filename"
done

# 等同于

for filename in "$@" ; do
  echo "$filename"
done
```

在函数体中也是一样的，`for...in`循环省略`in list`的部分，则`list`默认等于函数的所有参数。

## 9.4 `for`循环

`for`循环还支持 C 语言的循环语法。

```
for (( expression1; expression2; expression3 )); do
  commands
done
```

上面代码中，`expression1`用来初始化循环条件，`expression2`用来决定循环结束的条件，`expression3`在每次循环迭代的末尾执行，用于更新值。

注意，循环条件放在双重圆括号之中。另外，圆括号之中使用变量，不必加上美元符号`$`。

它等同于下面的`while`循环。

```
(( expression1 ))
while (( expression2 )); do
  commands
  (( expression3 ))
done
```

下面是一个例子。

```
for (( i=0; i<5; i=i+1 )); do
  echo $i
done
```

上面代码中，初始化变量`i`的值为0，循环执行的条件是`i`小于5。每次循环迭代结束时，`i`的值加1。

`for`条件部分的三个语句，都可以省略。

```
for ((;;))
do
  read var
  if [ "$var" = "." ]; then
    break
  fi
done
```

上面脚本会反复读取命令行输入，直到用户输入了一个点（`.`）为止，才会跳出循环。

## 9.5 `break,continue`

Bash 提供了两个内部命令`break`和`continue`，用来在循环内部跳出循环。

`break`命令立即终止循环，程序继续执行循环块之后的语句，即不再执行剩下的循环。

```
#!/bin/bash

for number in 1 2 3 4 5 6
do
  echo "number is $number"
  if [ "$number" = "3" ]; then
    break
  fi
done
```

上面例子只会打印3行结果。一旦变量`$number`等于3，就会跳出循环，不再继续执行。

`continue`命令立即终止本轮循环，开始执行下一轮循环。

```
#!/bin/bash

while read -p "What file do you want to test?" filename
do
  if [ ! -e "$filename" ]; then
    echo "The file does not exist."
    continue
  fi

  echo "You entered a valid file.."
done
```

上面例子中，只要用户输入的文件不存在，`continue`命令就会生效，直接进入下一轮循环（让用户重新输入文件名），不再执行后面的打印语句。

## 9.6 `select`结构

`select`结构主要用来生成简单的菜单。它的语法与`for...in`循环基本一致。

```
select name
[in list]
do
  commands
done
```

Bash 会对`select`依次进行下面的处理。

1. `select`生成一个菜单，内容是列表`list`的每一项，并且每一项前面还有一个数字编号。
2. Bash 提示用户选择一项，输入它的编号。
3. 用户输入以后，Bash 会将该项的内容存在变量`name`，该项的编号存入环境变量`REPLY`。如果用户没有输入，就按回车键，Bash 会重新输出菜单，让用户选择。
4. 执行命令体`commands`。
5. 执行结束后，回到第一步，重复这个过程。

下面是一个例子。

```
#!/bin/bash
# select.sh

select brand in Samsung Sony iphone symphony Walton
do
  echo "You have chosen $brand"
done
```

执行上面的脚本，Bash 会输出一个品牌的列表，让用户选择。

```
$ ./select.sh
1) Samsung
2) Sony
3) iphone
4) symphony
5) Walton
#?
```

如果用户没有输入编号，直接按回车键。Bash 就会重新输出一遍这个菜单，直到用户按下`Ctrl + c`，退出执行。

`select`可以与`case`结合，针对不同项，执行不同的命令。

```
#!/bin/bash

echo "Which Operating System do you like?"

select os in Ubuntu LinuxMint Windows8 Windows10 WindowsXP
do
  case $os in
    "Ubuntu"|"LinuxMint")
      echo "I also use $os."
    ;;
    "Windows8" | "Windows10" | "WindowsXP")
      echo "Why don't you try Linux?"
    ;;
    *)
      echo "Invalid entry."
      break
    ;;
  esac
done
```

上面例子中，`case`针对用户选择的不同项，执行不同的命令。

# 10. 函数

函数（function）是可以重复使用的代码片段，有利于代码的复用。它与别名（alias）的区别是，别名只适合封装简单的单个命令，函数则可以封装复杂的多行命令。

函数总是在当前 Shell 执行，这是跟脚本的一个重大区别，Bash 会新建一个子 Shell 执行脚本。如果函数与脚本同名，函数会优先执行。但是，函数的优先级不如别名，即如果函数与别名同名，那么别名优先执行。

## 10.1 定义函数

Bash 函数定义的语法有两种。

```
# 第一种
fn() {
  # codes
}

# 第二种
function fn() {
  # codes
}
```

上面代码中，`fn`是自定义的函数名，函数代码就写在大括号之中。这两种写法是等价的。

示例：定义函数
```
hello() {
  echo "Hello $1"
}
```
## 10.2 调用函数

下面是一个简单函数的例子。

```
hello() {
  echo "Hello $1"
}
```

上面代码中，函数体里面的`$1`表示函数调用时的第一个参数。

调用时，就直接写函数名，参数跟在函数名后面。

```
$ hello world
Hello world
```

## 10.3 操作函数

删除函数
```
unset FunctionName
```
 
 查看当前shell所有函数
```
declare -f
```

查看当前shell所有函数名称
```
declare -F
```

查看当前shell指定函数的定义
```
declare -f FunctionName
```

## 10.4 参数变量

函数体内可以使用参数变量，获取函数参数。函数的参数变量，与脚本参数变量是一致的。

- `$1`~`$9`：函数的第一个到第9个的参数。
- `$0`：函数所在的脚本名。
- `$#`：函数的参数总数。
- `$@`：函数的全部参数，参数之间使用空格分隔。
- `$*`：函数的全部参数，参数之间使用变量`$IFS`值的第一个字符分隔，默认为空格，但是可以自定义。

如果函数的参数多于9个，那么第10个参数可以用`${10}`的形式引用，以此类推。

下面是一个示例脚本`test.sh`。

```
#!/bin/bash
# test.sh

function alice {
  echo "alice: $@"
  echo "$0: $1 $2 $3 $4"
  echo "$# arguments"

}

alice in wonderland
```

运行该脚本，结果如下。

```
$ bash test.sh
alice: in wonderland
test.sh: in wonderland
2 arguments
```

上面例子中，由于函数`alice`只有第一个和第二个参数，所以第三个和第四个参数为空。

下面是一个日志函数的例子。

```
function log_msg {
  echo "[`date '+ %F %T'` ]: $@"
}
```

使用方法如下。

```
$ log_msg "This is sample log message"
[ 2018-08-16 19:56:34 ]: This is sample log message
```

## 10.5 `return`命令

bash shell使用`return`命令来退出函数并返回特定的退出状态码。`return`命令允许指定一个整数值来定义函数的退出状态码，从而提供了一种简单的途径来编程设定函数退出状态码。

`return`命令用于从函数返回一个值。函数执行到这条命令，就不再往下执行了，直接返回了。

```
function func_return_value {
  return 10
}
```

函数将返回值返回给调用者。如果命令行直接执行函数，下一个命令可以用`$?`拿到返回值。

```
$ func_return_value
$ echo "Value returned by function is: $?"
Value returned by function is: 10
```

`return`后面不跟参数，只用于返回也是可以的。

```
function name {
  commands
  return
}
```

>[!NOTE]
>如果在用`$?`变量提取函数返回值之前执行了其他命令，函数的返回值就会丢失。记住，`$?`变量会返回执行的最后一条命令的退出状态码。
>退出状态码必须是0~255。
## 10.6 使用函数输出

示例：
```
#!/bin/bash
function dbl {
	read -p "Enter a value: " value
	echo $[ $value * 2 ]
}
result=$(dbl)
echo "The new value is $result"
```

新函数会用echo语句来显示计算的结果。该脚本会获取dbl函数的输出，而不是查看退出状态码。
这个例子中演示了一个不易察觉的技巧。你会注意到dbl函数实际上输出了两条消息。read命令输出了一条简短的消息来向用户询问输入值。bash shell脚本非常聪明，并不将其作为STDOUT输出的一部分，并且忽略掉它。如果你用echo语句生成这条消息来向用户查询，那么它会与输出值一起被读进shell变量中。
## 10.7 函数中使用变量

### 10.7.1 向函数传入参数

函数可以使用标准的参数环境变量来表示命令行上传给函数的参数。例如，函数名会在$0变量中定义，函数命令行上的任何参数都会通过$1、$2等定义。也可以用特殊变量$#来判断传给函数的参数数目。

示例：
```
#!/bin/bash
function dbl {
	read -p "Enter a value: " value
	echo $[ $value * 2 ]
}

dbl $value 10
```

运行结果
```
$dbl $value
Enter a value: 10
20
```
### 10.7.2 函数中处理变量

Bash 函数体内直接声明的变量，属于全局变量，整个脚本都可以读取。这一点需要特别小心。

```
# 脚本 test.sh
fn () {
  foo=1
  echo "fn: foo = $foo"
}

fn
echo "global: foo = $foo"
```

上面脚本的运行结果如下。

```
$ bash test.sh
fn: foo = 1
global: foo = 1
```

上面例子中，变量`$foo`是在函数`fn`内部声明的，函数体外也可以读取。

函数体内不仅可以声明全局变量，还可以修改全局变量。

```
#! /bin/bash
foo=1

fn () {
  foo=2
}

fn

echo $foo
```

上面代码执行后，输出的变量`$foo`值为2。

函数里面可以用`local`命令声明局部变量。

```
#! /bin/bash
# 脚本 test.sh
fn () {
  local foo
  foo=1
  echo "fn: foo = $foo"
}

fn
echo "global: foo = $foo"
```

上面脚本的运行结果如下。

```
$ bash test.sh
fn: foo = 1
global: foo =
```

上面例子中，`local`命令声明的`$foo`变量，只在函数体内有效，函数体外没有定义。

# 11. 数组

## 11.1 创建数组

数组可以采用逐个赋值的方法创建。

```
ARRAY[INDEX]=value
```

上面语法中，`ARRAY`是数组的名字，可以是任意合法的变量名。`INDEX`是一个大于或等于零的整数，也可以是算术表达式。注意数组第一个元素的下标是0， 而不是1。

下面创建一个三个成员的数组。

```
$ array[0]=val
$ array[1]=val
$ array[2]=val
```

数组也可以采用一次性赋值的方式创建。

```
ARRAY=(value1 value2 ... valueN)

# 等同于

ARRAY=(
  value1
  value2
  value3
)
```

采用上面方式创建数组时，可以按照默认顺序赋值，也可以在每个值前面指定位置。

```
$ array=(a b c)
$ array=([2]=c [0]=a [1]=b)

$ days=(Sun Mon Tue Wed Thu Fri Sat)
$ days=([0]=Sun [1]=Mon [2]=Tue [3]=Wed [4]=Thu [5]=Fri [6]=Sat)
```

只为某些值指定位置，也是可以的。

```
names=(hatter [5]=duchess alice)
```

上面例子中，`hatter`是数组的0号位置，`duchess`是5号位置，`alice`是6号位置。

没有赋值的数组元素的默认值是空字符串。

定义数组的时候，可以使用通配符。

```
$ mp3s=( *.mp3 )
```

上面例子中，将当前目录的所有 MP3 文件，放进一个数组。

先用`declare -a`命令声明一个数组，也是可以的。

```
$ declare -a ARRAYNAME
```

`read -a`命令则是将用户的命令行输入，存入一个数组。

```
$ read -a dice
```

上面命令将用户的命令行输入，存入数组`dice`。

## 11.2 读取数组

### 11.2.1 读取单个元素

读取数组指定位置的成员，要使用下面的语法。

```
$ echo ${array[i]}     # i 是索引
```

上面语法里面的大括号是必不可少的，否则 Bash 会把索引部分`[i]`按照原样输出。

```
$ array[0]=a

$ echo ${array[0]}
a

$ echo $array[0]
a[0]
```

上面例子中，数组的第一个元素是`a`。如果不加大括号，Bash 会直接读取`$array`首成员的值，然后将`[0]`按照原样输出。

### 11.2.2 读取所有成员

`@`和`*`是数组的特殊索引，表示返回数组的所有成员。

```
$ foo=(a b c d e f)
$ echo ${foo[@]}
a b c d e f
```

这两个特殊索引配合`for`循环，就可以用来遍历数组。

```
for i in "${names[@]}"; do
  echo $i
done
```

`@`和`*`放不放在双引号之中，是有差别的。

```
$ activities=( swimming "water skiing" canoeing "white-water rafting" surfing )
$ for act in ${activities[@]}; \
do \
echo "Activity: $act"; \
done

Activity: swimming
Activity: water
Activity: skiing
Activity: canoeing
Activity: white-water
Activity: rafting
Activity: surfing
```

上面的例子中，数组`activities`实际包含5个成员，但是`for...in`循环直接遍历`${activities[@]}`，导致返回7个结果。为了避免这种情况，一般把`${activities[@]}`放在双引号之中。

```
$ for act in "${activities[@]}"; \
do \
echo "Activity: $act"; \
done

Activity: swimming
Activity: water skiing
Activity: canoeing
Activity: white-water rafting
Activity: surfing
```

上面例子中，`${activities[@]}`放在双引号之中，遍历就会返回正确的结果。

`${activities[*]}`不放在双引号之中，跟`${activities[@]}`不放在双引号之中是一样的。

```
$ for act in ${activities[*]}; \
do \
echo "Activity: $act"; \
done

Activity: swimming
Activity: water
Activity: skiing
Activity: canoeing
Activity: white-water
Activity: rafting
Activity: surfing
```

`${activities[*]}`放在双引号之中，所有成员就会变成单个字符串返回。

```
$ for act in "${activities[*]}"; \
do \
echo "Activity: $act"; \
done

Activity: swimming water skiing canoeing white-water rafting surfing
```

所以，拷贝一个数组的最方便方法，就是写成下面这样。

```
$ hobbies=( "${activities[@]}" )
```

上面例子中，数组`activities`被拷贝给了另一个数组`hobbies`。

这种写法也可以用来为新数组添加成员。

```
$ hobbies=( "${activities[@]}" diving )
```

上面例子中，新数组`hobbies`在数组`activities`的所有成员之后，又添加了一个成员。

### 11.2.3 默认位置

如果读取数组成员时，没有读取指定哪一个位置的成员，默认使用`0`号位置。

```
$ declare -a foo
$ foo=A
$ echo ${foo[0]}
A
```

上面例子中，`foo`是一个数组，赋值的时候不指定位置，实际上是给`foo[0]`赋值。

引用一个不带下标的数组变量，则引用的是`0`号位置的数组元素。

```
$ foo=(a b c d e f)
$ echo ${foo}
a
$ echo $foo
a
```

上面例子中，引用数组元素的时候，没有指定位置，结果返回的是`0`号位置。

## 11.3 数组的长度

要想知道数组的长度（即一共包含多少成员），可以使用下面两种语法。

```
${#array[*]}
${#array[@]}
```

下面是一个例子。

```
$ a[100]=foo

$ echo ${#a[*]}
1

$ echo ${#a[@]}
1
```

上面例子中，把字符串赋值给`100`位置的数组元素，这时的数组只有一个元素。

注意，如果用这种语法去读取具体的数组成员，就会返回该成员的字符串长度。这一点必须小心。

```
$ a[100]=foo
$ echo ${#a[100]}
3
```

上面例子中，`${#a[100]}`实际上是返回数组第100号成员`a[100]`的值（`foo`）的字符串长度。

## 11.4 提取数组序号

`${!array[@]}`或`${!array[*]}`，可以返回数组的成员序号，即哪些位置是有值的。

```
$ arr=([5]=a [9]=b [23]=c)
$ echo ${!arr[@]}
5 9 23
$ echo ${!arr[*]}
5 9 23
```

上面例子中，数组的5、9、23号位置有值。

利用这个语法，也可以通过`for`循环遍历数组。

```
arr=(a b c d)

for i in ${!arr[@]};do
  echo ${arr[i]}
done
```

## 11.5 提取数组成员

`${array[@]:position:length}`的语法可以提取数组成员。

```
$ food=( apples bananas cucumbers dates eggs fajitas grapes )
$ echo ${food[@]:1:1}
bananas
$ echo ${food[@]:1:3}
bananas cucumbers dates
```

上面例子中，`${food[@]:1:1}`返回从数组1号位置开始的1个成员，`${food[@]:1:3}`返回从1号位置开始的3个成员。

如果省略长度参数`length`，则返回从指定位置开始的所有成员。

```
$ echo ${food[@]:4}
eggs fajitas grapes
```

上面例子返回从4号位置开始到结束的所有成员。

## 11.6 追加数组成员

数组末尾追加成员，可以使用`+=`赋值运算符。它能够自动地把值追加到数组末尾。否则，就需要知道数组的最大序号，比较麻烦。

```
$ foo=(a b c)
$ echo ${foo[@]}
a b c

$ foo+=(d e f)
$ echo ${foo[@]}
a b c d e f
```

## 11.7 删除数组

删除一个数组成员，使用`unset`命令。

```
$ foo=(a b c d e f)
$ echo ${foo[@]}
a b c d e f

$ unset foo[2]
$ echo ${foo[@]}
a b d e f
```

上面例子中，删除了数组中的第三个元素，下标为2。

将某个成员设为空值，可以从返回值中“隐藏”这个成员。

```
$ foo=(a b c d e f)
$ foo[1]=''
$ echo ${foo[@]}
a c d e f
```

上面例子中，将数组的第二个成员设为空字符串，数组的返回值中，这个成员就“隐藏”了。

注意，这里是“隐藏”，而不是删除，因为这个成员仍然存在，只是值变成了空值。

```
$ foo=(a b c d e f)
$ foo[1]=''
$ echo ${#foo[@]}
6
$ echo ${!foo[@]}
0 1 2 3 4 5
```

上面代码中，第二个成员设为空值后，数组仍然包含6个成员。

由于空值就是空字符串，所以下面这样写也有隐藏效果，但是不建议这种写法。

```
$ foo[1]=
```

上面的写法也相当于“隐藏”了数组的第二个成员。

直接将数组变量赋值为空字符串，相当于“隐藏”数组的第一个成员。

```
$ foo=(a b c d e f)
$ foo=''
$ echo ${foo[@]}
b c d e f
```

上面的写法相当于“隐藏”了数组的第一个成员。

`unset ArrayName`可以清空整个数组。

```
$ unset ARRAY

$ echo ${ARRAY[*]}
<--no output-->
```

## 11.8 关联数组

Bash 的新版本支持关联数组。关联数组使用字符串而不是整数作为数组索引。

`declare -A`可以声明关联数组。

```
declare -A colors
colors["red"]="#ff0000"
colors["green"]="#00ff00"
colors["blue"]="#0000ff"
```

关联数组必须用带有`-A`选项的`declare`命令声明创建。相比之下，整数索引的数组，可以直接使用变量名创建数组，关联数组就不行。

访问关联数组成员的方式，几乎与整数索引数组相同。

```
echo ${colors["blue"]}
```

# 12. 常用命令

## 12.1 `echo,printf`
## 12.2 `cd,pwd,mkdir,rmdir`
## 12.3 `ls`
## 12.4 `touch,file,cp,mv,rm,ln,tar`
## 12.5 `cat,head,taill,more,less`
## 12.6 `ps,top,kill`
## 12.7 `mount,df,du`
## 12.8 `grep,egrep,sort`
## 12.9 `whereis,find,which,type`

# 13. 正则表达式



# 14. 字符串处理工具

## 14.1 `grep`

## 14.2 `sed`

```
echo "This is a test" | sed 's/test/big test/'
```

```
echo "The quick brown fox jumps over the lazy dog." | sed -e 's/brown/green/; s/dog/cat/'

echo "The quick brown fox jumps over the lazy dog." | sed -e '
s/brown/green/
s/fox/elephant/
s/dog/cat/'
```

## 14.3 `awk`
## 14.4 `cut`

```
# -d 指定分割符
# -f 指定打印的列
cat /etc/passwd | head -n 5 | cut -d : -f 1,3-5
```
运行结果
```
root:0:0:root
daemon:1:1:daemon
bin:2:2:bin
sys:3:3:sys
sync:4:65534:sync
```


```
curl -s https://www.debian.org/releases/stable/index.html |awk -F \;  '/Release Information <\/title>/{print $(NF-1)}' |cut -d \& -f 1
```
运行结果
```
bookworm
```



