# 1 基础语法

## 1.1 编码

默认情况下，Python 3 源码文件以 **UTF-8** 编码，所有字符串都是 unicode 字符串。

使用 Windows-1252 字符集中的字符编码

```
#!/usr/bin/env python3
# _*_ coding: cp1252 _*_
```

## 1.2 标识符（变量？）

- 第一个字符必须是字母表中字母或下划线 _ 。
- 标识符的其他的部分由字母、数字和下划线组成。
- 标识符对大小写敏感。

在 Python 3 中，可以用中文作为变量名，非 ASCII 标识符也是允许的了。

## 1.3 python保留字

保留字即关键字，我们不能把它们用作任何标识符名称。Python 的标准库提供了一个 keyword 模块，可以输出当前版本的所有关键字：

```
import keyword
print(keyword.kwlist)
```

## 1.4 注释

Python中单行注释以 **#** 开头
示例:单行注释
```
# 注释1
```

多行注释可以用多个 `#` 号，还有 `'''` 和 `"""`;多行注释是由三个单引号 `'''` 或三个双引号 `"""` 来定义的，而且这种注释方式并不能嵌套使用。

示例:多行注释
```
# 注释1
# 注释2

'''
注释1
注释2
...
注释n
'''
"""
注释1
注释2
...
注释n
"""
```

## 1.5 行与缩进

python最具特色的就是使用缩进来表示代码块，不需要使用大括号 `{}`。

```
if True:
    print ("True")
else:
    print ("False")
```

## 1.6 多行语句

Python 通常是一行写完一条语句，但如果语句很长，我们可以使用反斜杠 \ 来实现多行语句，例如：

```
total = item_one + \
        item_two + \
        item_three
```

在 `[]`,`{}`, 或 `()` 中的多行语句，不需要使用反斜杠 `\`，例如：

```
total = ['item_one', 'item_two', 'item_three',
        'item_four', 'item_five']
```

## 1.7 数字(Number)类型

python中数字有四种类型：整数、布尔型、浮点数和复数。

- **int** (整数), 如 1, 只有一种整数类型 int，表示为长整型，没有 python2 中的 Long。
- **bool** (布尔), 如 True。
- **float** (浮点数), 如 1.23、3E-2
- **complex** (复数) - 复数由实部和虚部组成，形式为 a + bj，其中 a 是实部，b 是虚部，j 表示虚数单位。如 1 + 2j、 1.1 + 2.2j

## 1.8 字符串(String)

- Python 中单引号`'`和双引号`"`使用完全相同。
- 使用三引号(`'''` 或` """`)可以指定一个多行字符串。
- 转义符 `\`。
- 反斜杠可以用来转义，使用 `r`可以让反斜杠不发生转义。 如 **`r"this is a line with \n"`** 则 `\n`会显示，并不是换行。
- 按字面意义级联字符串，如 **`"this " "is " "string"`** 会被自动转换为 **`this is string`**。
- 字符串可以用 `+` 运算符连接在一起，用 `*` 运算符重复。
- Python 中的字符串有两种索引方式，从左往右以 0 开始，从右往左以 -1 开始。
- Python 中的字符串不能改变。
- Python 没有单独的字符类型，一个字符就是长度为 1 的字符串。
- 字符串切片 `str[start:end]`，其中 start（包含）是切片开始的索引，end（不包含）是切片结束的索引。
- 字符串的切片可以加上步长参数 step，语法格式如下：`str[start:end:step]`

```
#!/usr/bin/python3
 
str='123456789'
 
print(str)                 # 输出字符串
print(str[0:-1])           # 输出第一个到倒数第二个的所有字符
print(str[0])              # 输出字符串第一个字符
print(str[2:5])            # 输出从第三个开始到第六个的字符（不包含）
print(str[2:])             # 输出从第三个开始后的所有字符
print(str[1:5:2])          # 输出从第二个开始到第五个且每隔一个的字符（步长为2）
print(str * 2)             # 输出字符串两次
print(str + '你好')         # 连接字符串
 
print('------------------------------')
print('\n')                 #打印空行
 
print('hello\nrunoob')      # 使用反斜杠(\)+n转义特殊字符
print(r'hello\nrunoob')     # 在字符串前面添加一个 r，表示原始字符串，不会发生转义
```

## 1.9 空行

函数之间或类的方法之间用空行分隔，表示一段新的代码的开始。类和函数入口之间也用一行空行分隔，以突出函数入口的开始。

空行与代码缩进不同，空行并不是 Python 语法的一部分。书写时不插入空行，Python 解释器运行也不会出错。但是空行的作用在于分隔两段不同功能或含义的代码，便于日后代码的维护或重构。

**记住：空行也是程序代码的一部分。**

## 1.10 等待用户输入

```
#!/usr/bin/python3
 
input("\n\n按下 enter 键后退出。")
```

## 1.11 同一行显示多条语句

Python 可以在同一行中使用多条语句，语句之间使用分号 ; 分割，以下是一个简单的实例：

```
#!/usr/bin/python3
 
import sys; x = 'runoob'; sys.stdout.write(x + '\n')
```

## 1.12 多个语句构成代码组

缩进相同的一组语句构成一个代码块，我们称之代码组。

像`if`、`while`、`def`和`class`这样的复合语句，首行以关键字开始，以冒号( `:` )结束，该行之后的一行或多行代码构成代码组。

我们将首行及后面的代码组称为一个子句(clause)。

如下实例：

```
if expression : 
   suite
elif expression : 
   suite 
else : 
   suite
```

## 1.13 print 输出

**print** 默认输出是换行的，如果要实现不换行需要在变量末尾加上 `end=""`：

```
#!/usr/bin/python3
 
x="a"
y="b"
# 换行输出
print( x )
print( y )
 
print('---------')
# 不换行输出
print( x, end=" " )
print( y, end=" " )
print()
```

## 1.14 import 与 from...import

在 python 用 `import` 或者 `from...import` 来导入相应的模块。

将整个模块(somemodule)导入，格式为： `import somemodule`

从某个模块中导入某个函数,格式为： `from somemodule import somefunction`

从某个模块中导入多个函数,格式为： `from somemodule import firstfunc, secondfunc, thirdfunc`

将某个模块中的全部函数导入，格式为： `from somemodule import *`

```
import sys
print('================Python import mode==========================')
print ('命令行参数为:')
for i in sys.argv:
    print (i)
print ('\n python 路径为',sys.path)
```

```
from sys import argv,path  #  导入特定的成员
 
print('================python from import===================================')
print('path:',path) # 因为已经导入path成员，所以此处引用时不需要加sys.path
```

## 1.15 命令行参数

很多程序可以执行一些操作来查看一些基本信息，Python可以使用-h参数查看各参数帮助信息：

```
$ python -h
usage: python [option] ... [-c cmd | -m mod | file | -] [arg] ...
Options and arguments (and corresponding environment variables):
-c cmd : program passed in as string (terminates option list)
-d     : debug output from parser (also PYTHONDEBUG=x)
-E     : ignore environment variables (such as PYTHONPATH)
-h     : print this help message and exit

[ etc. ]

```

## 1.16 获取帮助

通过命令 **`help("print")`** 我们知道这个方法里第三个为缺省参数 **`sep=' '`**。

```
help("print")
```

输出结果：
```
Help on built-in function print in module builtins:

print(...)
    print(value, ..., sep=' ', end='\n', file=sys.stdout, flush=False)

    Prints the values to a stream, or to sys.stdout by default.
    Optional keyword arguments:
    file:  a file-like object (stream); defaults to the current sys.stdout.
    sep:   string inserted between values, default a space.
    end:   string appended after the last value, default a newline.
    flush: whether to forcibly flush the stream.
```

# 2. 基础数据类型

## 2.1 变量

Python 中的变量不需要声明。每个变量在使用前都必须赋值，变量赋值以后该变量才会被创建。

在 Python 中，变量就是变量，它没有类型，我们所说的"类型"是变量所指的内存中对象的类型。

等号（`=`）用来给变量赋值。

等号（`=`）运算符左边是一个变量名,等号（`=`）运算符右边是存储在变量中的值。例如：

示例:单个变量赋值
```
#!/usr/bin/python3

counter = 100          # 整型变量
miles   = 1000.0       # 浮点型变量
name    = "runoob"     # 字符串

print (counter)
print (miles)
print (name)
```

示例:多个变量赋值
```
a = b = c = 1
print(a)
print(b)
print(c)
```

```
a, b, c = 1, 2, "runoob"
print(a)
print(b)
print(c)
```

## 2.2 标准数据类型

Python3 中常见的数据类型有：

- Number（数字）
- String（字符串）
- bool（布尔类型）
- List（列表）
- Tuple（元组）
- Set（集合）
- Dictionary（字典）

Python3 的六个标准数据类型中：

- **不可变数据（3 个）**：**Number（数字）、String（字符串）、Tuple（元组）**；
- **可变数据（3 个）**：**List（列表）、Dictionary（字典）、Set（集合）**。

```
a, b, c, d = 20, 5.5, True, 4+3j
print(type(a), type(b), type(c), type(d))
```

>[!TIP]
>内置的 `type()`函数可以用来查询变量所指的对象类型。
>此外还可以用 `isinstance`来判断.

### 2.2.1  Number（数字）

#### 1)操作数字

Python3 支持 **int、float、bool、complex（复数）**。

在Python 3里，只有一种整数类型 int，表示为长整型，没有 python2 中的 Long。

像大多数语言一样，数值类型的赋值和计算都是很直观的。

```
var1 = 1
var2 = 10
```

删除一些数字对象的引用
```
del var1[,var2[,var3[....,varN]]]
```

您可以通过使用del语句删除单个或多个对象的引用，例如：
```
del var
del var_a, var_b

```
 
 #### 2)数字运算

表达式的语法很直白： +, -, * 和 /, 和其它语言（如Pascal或C）里一样。例如：

```
+    #加
-    #减
*    #乘
/    #除
//   #取整
**   #乘方
```

#### 3)随机数函数

```
choice(seq)                          #从序列的元素中随机挑选一个元素，比如random.choice(range(10))，从0到9中随机挑选一个整数。
randrange ([start,] stop [,step])    #从指定范围内，按指定基数递增的集合中获取一个随机数，基数默认值为 1
random()                             #随机生成下一个实数，它在[0,1)范围内。
seed([x])                            #改变随机数生成器的种子seed。如果你不了解其原理，你不必特别去设定seed，Python会帮你选择seed。
shuffle(lst)                         #将序列的所有元素随机排序
uniform(x, y)                        #随机生成下一个实数，它在[x,y]范围内。
```

#### 4)数学常量

```
pi    #数学常量 pi（圆周率，一般以π来表示）
e     #数学常量 e，e即自然常数（自然常数）。
```

### 2.2.2 字符串

字符串是 Python 中最常用的数据类型。我们可以使用引号( ' 或 " )来创建字符串。

#### 1)操作字符串
创建字符串很简单，只要为变量分配一个值即可。例如：

```
var1 = 'Hello World!'
var2 = "Runoob"
```

Python 访问子字符串，可以使用方括号 [] 来截取字符串，字符串的截取的语法格式如下：

```
变量[头下标:尾下标]
```

你可以截取字符串的一部分并与其他字段拼接，如下实例：

```
#!/usr/bin/python3  
var1 = 'Hello World!'  
print('字符串的内容是: '+var1)  
print('第一个字符是: '+var1[0])  
print('最后一个字符是: '+var1[-1])  
print('第7个字符是: '+var1[6])  
print("第7个字符之前的内容是: ",var1[:6])   #不包含第7个字符,前6个字符  
print('第7个字符之后的内容是: ' ,var1[6:])  #包含第7个字符
```
运行结果:
```
字符串的内容是: Hello World!
第一个字符是: H
最后一个字符是: !
第7个字符是: W
第7个字符之前的内容是:  Hello 
第7个字符之后的内容是:  World!
```

#### 2)转义字符

在需要在字符中使用特殊字符时，python 用反斜杠 \ 转义字符。如下表：

|转义字符|描述|实例|
|---|---|---|
|\(在行尾时)|续行符|>>> print("line1 \<br>... line2 \<br>... line3")<br>line1 line2 line3<br>>>>|
|\\|反斜杠符号|>>> print("\\")<br>\|
|\'|单引号|>>> print('\'')<br>'|
|\"|双引号|>>> print("\"")<br>"|
|\a|响铃|>>> print("\a")<br><br>执行后电脑有响声。|
|\b|退格(Backspace)|>>> print("Hello \b World!")<br>Hello World!|
|\000|空|>>> print("\000")<br><br>>>>|
|\n|换行|>>> print("\n")<br><br>>>>|
|\v|纵向制表符|>>> print("Hello \v World!")<br>Hello <br>       World!<br>>>>|
|\t|横向制表符|>>> print("Hello \t World!")<br>Hello      World!<br>>>>|
|\r|回车，将 \r 后面的内容移到字符串开头，并逐一替换开头部分的字符，直至将 \r 后面的内容完全替换完成。|>>> print("Hello\rWorld!")<br>World!<br>>>> print('google runoob taobao\r123456')<br>123456 runoob taobao|
|\f|换页|>>> print("Hello \f World!")<br>Hello <br>       World!<br>>>>|
|\yyy|八进制数，y 代表 0~7 的字符，例如：\012 代表换行。|>>> print("\110\145\154\154\157\40\127\157\162\154\144\41")<br>Hello World!|
|\xyy|十六进制数，以 \x 开头，y 代表的字符，例如：\x0a 代表换行|>>> print("\x48\x65\x6c\x6c\x6f\x20\x57\x6f\x72\x6c\x64\x21")<br>Hello World!|
|\other|其它的字符以普通格式输出|
使用 `\r` 实现百分比进度：
```
import time

for i in range(101):
    print("\r{:3}%".format(i),end=' ')
    time.sleep(0.05)
```
#### 3)字符串格式化

示例:
```
#!/usr/bin/python3
 
print ("我叫 %s 今年 %d 岁!" % ('小明', 10))
```

python字符串格式化符号:

|符   号|描述|
|---|---|
|%c|格式化字符及其ASCII码|
|%s|格式化字符串|
|%d|格式化整数|
|%u|格式化无符号整型|
|%o|格式化无符号八进制数|
|%x|格式化无符号十六进制数|
|%X|格式化无符号十六进制数（大写）|
|%f|格式化浮点数字，可指定小数点后的精度|
|%e|用科学计数法格式化浮点数|
|%E|作用同%e，用科学计数法格式化浮点数|
|%g|%f和%e的简写|
|%G|%f 和 %E 的简写|
|%p|用十六进制数格式化变量的地址|

格式化操作符辅助指令:

|符号|功能|
|---|---|
|*|定义宽度或者小数点精度|
|-|用做左对齐|
|+|在正数前面显示加号( + )|
|<sp>|在正数前面显示空格|
|#|在八进制数前面显示零('0')，在十六进制前面显示'0x'或者'0X'(取决于用的是'x'还是'X')|
|0|显示的数字前面填充'0'而不是默认的空格|
|%|'%%'输出一个单一的'%'|
|(var)|映射变量(字典参数)|
|m.n.|m 是显示的最小总宽度,n 是小数点后的位数(如果可用的话)|

>[!NOTE]
>函数 `str.format()`，它增强了字符串格式化的功能.

#### 4)Python 的字符串内建函数

Python 的字符串常用内建函数如下：

|序号|方法及描述|
|---|---|
|1|[capitalize()](https://www.runoob.com/python3/python3-string-capitalize.html)  <br>将字符串的第一个字符转换为大写|
|2|[center(width, fillchar)](https://www.runoob.com/python3/python3-string-center.html)<br><br>返回一个指定的宽度 width 居中的字符串，fillchar 为填充的字符，默认为空格。|
|3|[count(str, beg= 0,end=len(string))](https://www.runoob.com/python3/python3-string-count.html)<br><br>  <br>返回 str 在 string 里面出现的次数，如果 beg 或者 end 指定则返回指定范围内 str 出现的次数|
|4|[bytes.decode(encoding="utf-8", errors="strict")](https://www.runoob.com/python3/python3-string-decode.html)<br><br>  <br>Python3 中没有 decode 方法，但我们可以使用 bytes 对象的 decode() 方法来解码给定的 bytes 对象，这个 bytes 对象可以由 str.encode() 来编码返回。|
|5|[encode(encoding='UTF-8',errors='strict')](https://www.runoob.com/python3/python3-string-encode.html)<br><br>  <br>以 encoding 指定的编码格式编码字符串，如果出错默认报一个ValueError 的异常，除非 errors 指定的是'ignore'或者'replace'|
|6|[endswith(suffix, beg=0, end=len(string))](https://www.runoob.com/python3/python3-string-endswith.html)  <br>检查字符串是否以 suffix 结束，如果 beg 或者 end 指定则检查指定的范围内是否以 suffix 结束，如果是，返回 True,否则返回 False。|
|7|[expandtabs(tabsize=8)](https://www.runoob.com/python3/python3-string-expandtabs.html)<br><br>  <br>把字符串 string 中的 tab 符号转为空格，tab 符号默认的空格数是 8 。|
|8|[find(str, beg=0, end=len(string))](https://www.runoob.com/python3/python3-string-find.html)<br><br>  <br>检测 str 是否包含在字符串中，如果指定范围 beg 和 end ，则检查是否包含在指定范围内，如果包含返回开始的索引值，否则返回-1|
|9|[index(str, beg=0, end=len(string))](https://www.runoob.com/python3/python3-string-index.html)<br><br>  <br>跟find()方法一样，只不过如果str不在字符串中会报一个异常。|
|10|[isalnum()](https://www.runoob.com/python3/python3-string-isalnum.html)<br><br>  <br>检查字符串是否由字母和数字组成，即字符串中的所有字符都是字母或数字。如果字符串至少有一个字符，并且所有字符都是字母或数字，则返回 True；否则返回 False。|
|11|[isalpha()](https://www.runoob.com/python3/python3-string-isalpha.html)<br><br>  <br>如果字符串至少有一个字符并且所有字符都是字母或中文字则返回 True, 否则返回 False|
|12|[isdigit()](https://www.runoob.com/python3/python3-string-isdigit.html)<br><br>  <br>如果字符串只包含数字则返回 True 否则返回 False..|
|13|[islower()](https://www.runoob.com/python3/python3-string-islower.html)<br><br>  <br>如果字符串中包含至少一个区分大小写的字符，并且所有这些(区分大小写的)字符都是小写，则返回 True，否则返回 False|
|14|[isnumeric()](https://www.runoob.com/python3/python3-string-isnumeric.html)<br><br>  <br>如果字符串中只包含数字字符，则返回 True，否则返回 False|
|15|[isspace()](https://www.runoob.com/python3/python3-string-isspace.html)<br><br>  <br>如果字符串中只包含空白，则返回 True，否则返回 False.|
|16|[istitle()](https://www.runoob.com/python3/python3-string-istitle.html)<br><br>  <br>如果字符串是标题化的(见 title())则返回 True，否则返回 False|
|17|[isupper()](https://www.runoob.com/python3/python3-string-isupper.html)<br><br>  <br>如果字符串中包含至少一个区分大小写的字符，并且所有这些(区分大小写的)字符都是大写，则返回 True，否则返回 False|
|18|[join(seq)](https://www.runoob.com/python3/python3-string-join.html)<br><br>  <br>以指定字符串作为分隔符，将 seq 中所有的元素(的字符串表示)合并为一个新的字符串|
|19|[len(string)](https://www.runoob.com/python3/python3-string-len.html)<br><br>  <br>返回字符串长度|
|20|[ljust(width[, fillchar])](https://www.runoob.com/python3/python3-string-ljust.html)<br><br>  <br>返回一个原字符串左对齐,并使用 fillchar 填充至长度 width 的新字符串，fillchar 默认为空格。|
|21|[lower()](https://www.runoob.com/python3/python3-string-lower.html)<br><br>  <br>转换字符串中所有大写字符为小写.|
|22|[lstrip()](https://www.runoob.com/python3/python3-string-lstrip.html)<br><br>  <br>截掉字符串左边的空格或指定字符。|
|23|[maketrans()](https://www.runoob.com/python3/python3-string-maketrans.html)<br><br>  <br>创建字符映射的转换表，对于接受两个参数的最简单的调用方式，第一个参数是字符串，表示需要转换的字符，第二个参数也是字符串表示转换的目标。|
|24|[max(str)](https://www.runoob.com/python3/python3-string-max.html)<br><br>  <br>返回字符串 str 中最大的字母。|
|25|[min(str)](https://www.runoob.com/python3/python3-string-min.html)<br><br>  <br>返回字符串 str 中最小的字母。|
|26|[replace(old, new [, max])](https://www.runoob.com/python3/python3-string-replace.html)<br><br>  <br>把 将字符串中的 old 替换成 new,如果 max 指定，则替换不超过 max 次。|
|27|[rfind(str, beg=0,end=len(string))](https://www.runoob.com/python3/python3-string-rfind.html)<br><br>  <br>类似于 find()函数，不过是从右边开始查找.|
|28|[rindex( str, beg=0, end=len(string))](https://www.runoob.com/python3/python3-string-rindex.html)<br><br>  <br>类似于 index()，不过是从右边开始.|
|29|[rjust(width,[, fillchar])](https://www.runoob.com/python3/python3-string-rjust.html)<br><br>  <br>返回一个原字符串右对齐,并使用fillchar(默认空格）填充至长度 width 的新字符串|
|30|[rstrip()](https://www.runoob.com/python3/python3-string-rstrip.html)<br><br>  <br>删除字符串末尾的空格或指定字符。|
|31|[split(str="", num=string.count(str))](https://www.runoob.com/python3/python3-string-split.html)<br><br>  <br>以 str 为分隔符截取字符串，如果 num 有指定值，则仅截取 num+1 个子字符串|
|32|[splitlines([keepends])](https://www.runoob.com/python3/python3-string-splitlines.html)<br><br>  <br>按照行('\r', '\r\n', \n')分隔，返回一个包含各行作为元素的列表，如果参数 keepends 为 False，不包含换行符，如果为 True，则保留换行符。|
|33|[startswith(substr, beg=0,end=len(string))](https://www.runoob.com/python3/python3-string-startswith.html)<br><br>  <br>检查字符串是否是以指定子字符串 substr 开头，是则返回 True，否则返回 False。如果beg 和 end 指定值，则在指定范围内检查。|
|34|[strip([chars])](https://www.runoob.com/python3/python3-string-strip.html)<br><br>  <br>在字符串上执行 lstrip()和 rstrip()|
|35|[swapcase()](https://www.runoob.com/python3/python3-string-swapcase.html)<br><br>  <br>将字符串中大写转换为小写，小写转换为大写|
|36|[title()](https://www.runoob.com/python3/python3-string-title.html)<br><br>  <br>返回"标题化"的字符串,就是说所有单词都是以大写开始，其余字母均为小写(见 istitle())|
|37|[translate(table, deletechars="")](https://www.runoob.com/python3/python3-string-translate.html)<br><br>  <br>根据 table 给出的表(包含 256 个字符)转换 string 的字符, 要过滤掉的字符放到 deletechars 参数中|
|38|[upper()](https://www.runoob.com/python3/python3-string-upper.html)<br><br>  <br>转换字符串中的小写字母为大写|
|39|[zfill (width)](https://www.runoob.com/python3/python3-string-zfill.html)<br><br>  <br>返回长度为 width 的字符串，原字符串右对齐，前面填充0|
|40|[isdecimal()](https://www.runoob.com/python3/python3-string-isdecimal.html)<br><br>  <br>检查字符串是否只包含十进制字符，如果是返回 true，否则返回 false。|
### 2.2.3 列表

序列是 Python 中最基本的数据结构。

序列中的每个值都有对应的位置值，称之为索引，第一个索引是 0，第二个索引是 1，依此类推。

Python 有 6 个序列的内置类型，但最常见的是列表和元组。

列表都可以进行的操作包括索引，切片，加，乘，检查成员。

此外，Python 已经内置确定序列的长度以及确定最大和最小的元素的方法。

列表是最常用的 Python 数据类型，它可以作为一个方括号内的逗号分隔值出现。

列表的数据项不需要具有相同的类型

#### 1)创建列表
创建一个列表，只要把逗号分隔的不同的数据项使用方括号括起来即可。如下所示
```
list1 = ['Google', 'Runoob', 1997, 2000]
list2 = [1, 2, 3, 4, 5 ]
list3 = ["a", "b", "c", "d"]
list4 = ['red', 'green', 'blue', 'yellow', 'white', 'black']
```

#### 2)访问列表中的值
与字符串的索引一样，列表索引从 0 开始，第二个索引是 1，依此类推。

通过索引列表可以进行截取、组合等操作。
```
#!/usr/bin/python3  
  
list = ['red', 'green', 'blue', 'yellow', 'white', 'black']  
print( list[0] )  
print( list[1] )  
print( list[2] )  
print( list[-1] )  
print( list[-2] )  
print( list[-3] )  
print( list[0:4] )  
print( list[1:-1])
```

#### 3)更新列表
你可以对列表的数据项进行修改或更新，你也可以使用 `append()` 方法来添加列表项，如下所示：
```
#!/usr/bin/python3
list = ['red', 'green', 'blue', 'yellow', 'white', 'black']
print(list[-1])
list.append('orange')
print(list)
print(list[-1])
```

#### 4)删除列表元素
可以使用 `del`语句来删除列表中的元素，如下实例：
```
#!/usr/bin/python3  
list = ['red', 'green', 'blue', 'yellow', 'white', 'black']  
print(list[-1])  
del list[-1]  
print(list)  
print(list[-1])
```

使用`remove()`方法删除列表中的元素,如下
```
#!/usr/bin/python3  
list = ['red', 'green', 'blue', 'yellow', 'white', 'black']  
print(list[-1])  
list.remove(list[-1])  
print(list)  
print(list[-1])
```
#### 5)列表脚本操作符

列表对 + 和 * 的操作符与字符串相似。+ 号用于组合列表，* 号用于重复列表。

如下所示：

| Python 表达式                            | 结果                           | 描述         |
| ------------------------------------- | ---------------------------- | ---------- |
| len([1, 2, 3])                        | 3                            | 长度         |
| [1, 2, 3] + [4, 5, 6]                 | [1, 2, 3, 4, 5, 6]           | 组合         |
| ['Hi!'] * 4                           | ['Hi!', 'Hi!', 'Hi!', 'Hi!'] | 重复         |
| 3 in [1, 2, 3]                        | True                         | 元素是否存在于列表中 |
| for x in [1, 2, 3]: print(x, end=" ") | 1 2 3                        | 迭代         |

#### 6)列表截取与拼接

示例:
```
#!/usr/bin/python3 
list = ['red', 'orange' ,'green', 'blue', 'yellow', 'white', 'black']  
print('列表的内容是: ',list)  
print('第1个元素是:',list[0])  #第1个元素  
print('最后第1个元素是:',list[-1]) #倒数第一个元素  
print('第6个元素是:',list[5])  
print('第6个以后的元素:',list[5:]) #第6个以后的  
print('第6个之前的元素:',list[:5]) #第6个以前的元素,前五个元素  
print('倒数第5个元素是:',list[-5])  
print('倒数第5个元素之后的元素是:',list[-5:]) #倒数5个元素  
print('倒数第5个元素之前的元素是:',list[:-5]) #倒数5个元素之前的元素
```
运行结果:
```
列表的内容是:  ['red', 'orange', 'green', 'blue', 'yellow', 'white', 'black']
第1个元素是: red
最后第1个元素是: black
第6个元素是: white
第6个以后的元素: ['white', 'black']
第6个之前的元素: ['red', 'orange', 'green', 'blue', 'yellow']
倒数第5个元素是: green
倒数第5个元素之后的元素是: ['green', 'blue', 'yellow', 'white', 'black']
倒数第5个元素之前的元素是: ['red', 'orange']
```

列表还支持拼接操作：

示例:
```
#!/usr/bin/python3
squares = [1, 4, 9, 16, 25]  
squares += [36, 49, 64, 81, 100]  
print(squares)
```
运行结果:
```
[1, 4, 9, 16, 25, 36, 49, 64, 81, 100]
```
#### 7)嵌套列表

使用嵌套列表即在列表里创建其它列表，例如：
```
#!/usr/bin/python3  
a=['a','b','c']  
n=[1,2,3]  
x=[a,n]  
print(x)  
print(x[0])  
print(x[0][1])
```
运行结果:
```
[['a', 'b', 'c'], [1, 2, 3]]
['a', 'b', 'c']
b
```
#### 8)列表函数&方法

Python包含以下函数:

|序号|函数|
|---|---|
|1|[len(list)](https://www.runoob.com/python3/python3-att-list-len.html)  <br>列表元素个数|
|2|[max(list)](https://www.runoob.com/python3/python3-att-list-max.html)  <br>返回列表元素最大值|
|3|[min(list)](https://www.runoob.com/python3/python3-att-list-min.html)  <br>返回列表元素最小值|
|4|[list(seq)](https://www.runoob.com/python3/python3-att-list-list.html)  <br>将元组转换为列表|

Python包含以下方法:

| 序号  | 方法                                                                                                                     |
| --- | ---------------------------------------------------------------------------------------------------------------------- |
| 1   | [list.append(obj)](https://www.runoob.com/python3/python3-att-list-append.html)  <br>在列表末尾添加新的对象                       |
| 2   | [list.count(obj)](https://www.runoob.com/python3/python3-att-list-count.html)  <br>统计某个元素在列表中出现的次数                     |
| 3   | [list.extend(seq)](https://www.runoob.com/python3/python3-att-list-extend.html)  <br>在列表末尾一次性追加另一个序列中的多个值（用新列表扩展原来的列表） |
| 4   | [list.index(obj)](https://www.runoob.com/python3/python3-att-list-index.html)  <br>从列表中找出某个值第一个匹配项的索引位置                |
| 5   | [list.insert(index, obj)](https://www.runoob.com/python3/python3-att-list-insert.html)  <br>将对象插入列表                    |
| 6   | [list.pop([index=-1])](https://www.runoob.com/python3/python3-att-list-pop.html)  <br>移除列表中的一个元素（默认最后一个元素），并且返回该元素的值   |
| 7   | [list.remove(obj)](https://www.runoob.com/python3/python3-att-list-remove.html)  <br>移除列表中某个值的第一个匹配项                   |
| 8   | [list.reverse()](https://www.runoob.com/python3/python3-att-list-reverse.html)  <br>反向列表中元素                            |
| 9   | [list.sort( key=None, reverse=False)](https://www.runoob.com/python3/python3-att-list-sort.html)  <br>对原列表进行排序         |
| 10  | [list.clear()](https://www.runoob.com/python3/python3-att-list-clear.html)  <br>清空列表                                   |
| 11  | [list.copy()](https://www.runoob.com/python3/python3-att-list-copy.html)  <br>复制列表                                     |

### 2.2.4 元组

Python 的元组与列表类似，不同之处在于元组的元素不能修改。

元组使用小括号 ( )，列表使用方括号 [ ]。

#### 1)创建元组

元组创建很简单，只需要在括号中添加元素，并使用逗号隔开即可。

```
>>> tup1 = ('Google', 'Runoob', 1997, 2000)
>>> tup2 = (1, 2, 3, 4, 5 )
>>> tup3 = "a", "b", "c", "d"   #  不需要括号也可以
>>> type(tup3)
<class 'tuple'>
```

创建空元组

```
tup1 = ()
```

>[!IMPORTANT]
>元组中只包含一个元素时，需要在元素后面添加逗号 , ，否则括号会被当作运算符使用：

```
#!/usr/bin/python3
tup1 = (50)  
print(type(tup1))  
tup1 = (50,)  
print(type(tup1))
```
运行结果
```
<class 'int'>
<class 'tuple'>
```

#### 2)修改元组

元组中的元素值是不允许修改的，但我们可以对元组进行连接组合，如下实例:

```
#!/usr/bin/python3  
tup1 = (12, 34.56)  
tup2 = ('abc', 'xyz')  
# 以下修改元组元素操作是非法的。  
#tup1[0] = 100  
#TypeError: 'tuple' object does not support item assignment  
# 创建一个新的元组  
tup3 = tup1 + tup2  
print(tup3)
```

运行结果:
```
(12, 34.56, 'abc', 'xyz')
```

#### 3)删除元组

元组中的元素值是不允许删除的，但我们可以使用del语句来删除整个元组，如下实例:
```
#!/usr/bin/python3  
tup = ('Google', 'Runoob', 1997, 2000)  
print(tup)  
del tup  
print("删除后的元组 tup : ")  
print(tup)
```

运行结果:
```
    print(tup)
NameError: name 'tup' is not defined
('Google', 'Runoob', 1997, 2000)
删除后的元组 tup : 

进程已结束，退出代码为 1
```

#### 4)元组运算符

与字符串一样，元组之间可以使用 +、+=和 * 号进行运算。这就意味着他们可以组合和复制，运算后会生成一个新的元组。

|Python 表达式|结果|描述|
|---|---|---|
|len((1, 2, 3))|3|计算元素个数|
|>>> a = (1, 2, 3)<br>>>> b = (4, 5, 6)<br>>>> c = a+b<br>>>> c<br>(1, 2, 3, 4, 5, 6)|(1, 2, 3, 4, 5, 6)|连接，c 就是一个新的元组，它包含了 a 和 b 中的所有元素。|
|>>> a = (1, 2, 3)<br>>>> b = (4, 5, 6)<br>>>> a += b<br>>>> a<br>(1, 2, 3, 4, 5, 6)|(1, 2, 3, 4, 5, 6)|连接，a 就变成了一个新的元组，它包含了 a 和 b 中的所有元素。|
|('Hi!',) * 4|('Hi!', 'Hi!', 'Hi!', 'Hi!')|复制|
|3 in (1, 2, 3)|True|元素是否存在|
|for x in (1, 2, 3): <br>    print (x, end=" ")|1 2 3|迭代|

#### 5)元组索引,截取

因为元组也是一个序列，所以我们可以访问元组中的指定位置的元素，也可以截取索引中的一段元素，如下所示：

```
#!/usr/bin/python3  
tup = ('Google', 'Runoob', 'Taobao', 'Wiki', 'Weibo','Weixin')  
print('元组内容:',tup)  
print('第1个元素:',tup[0])  
print('最后1个元素:',tup[-1])  
print('第3个元素:',tup[2])  
print('第3个以后元素:',tup[2:])  
print('第3个以前元素:',tup[:2])
```
运行结果:
```
元组内容: ('Google', 'Runoob', 'Taobao', 'Wiki', 'Weibo', 'Weixin')
第1个元素: Google
最后1个元素: Weixin
第3个元素: Taobao
第3个以后元素: ('Taobao', 'Wiki', 'Weibo', 'Weixin')
第3个以前元素: ('Google', 'Runoob')
```

示例:
```
#!/usr/bin/python3  
tup1 = ('Google', 'Runoob', 'Taobao', 'Wiki', 'Weibo','Weixin')  
tup2 = ('one', 'two', 'three', 'four')  
tup3 = (tup1,tup2)  
print(tup3)  
print(tup3[0])  
print(tup3[0][-1])
```
运行结果:
```
(('Google', 'Runoob', 'Taobao', 'Wiki', 'Weibo', 'Weixin'), ('one', 'two', 'three', 'four'))
('Google', 'Runoob', 'Taobao', 'Wiki', 'Weibo', 'Weixin')
Weixin
```
#### 6)元组内置函数

Python元组包含了以下内置函数

|序号|方法及描述|实例|
|---|---|---|
|1|len(tuple)  <br>计算元组元素个数。|>>> tuple1 = ('Google', 'Runoob', 'Taobao')<br>>>> len(tuple1)<br>3<br>>>>|
|2|max(tuple)  <br>返回元组中元素最大值。|>>> tuple2 = ('5', '4', '8')<br>>>> max(tuple2)<br>'8'<br>>>>|
|3|min(tuple)  <br>返回元组中元素最小值。|>>> tuple2 = ('5', '4', '8')<br>>>> min(tuple2)<br>'4'<br>>>>|
|4|tuple(iterable)  <br>将可迭代系列转换为元组。|>>> list1= ['Google', 'Taobao', 'Runoob', 'Baidu']<br>>>> tuple1=tuple(list1)<br>>>> tuple1<br>('Google', 'Taobao', 'Runoob', 'Baidu')|
### 2.2.5 字典

字典是另一种可变容器模型，且可存储任意类型对象。

字典的每个键值 `key=>value` 对用冒号 `: `分割，每个对之间用逗号(**`,`**)分割，整个字典包括在花括号 `{}` 中 ,格式如下所示：

```
d = {key1 : value1, key2 : value2, key3 : value3 }
```

>[!NOTE]
>1.`dict` 作为 Python 的关键字和内置函数，变量名不建议命名为 **`dict`**。
>2.键必须是唯一的，但值则不必。
>3.值可以取任何数据类型，但键必须是不可变的，如字符串，数字。

#### 1)创建字典
示例:
```
tinydict = {'name': 'runoob', 'likes': 123, 'url': 'www.runoob.com'}  
tinydict1 = { 'abc': 456 }  
tinydict2 = { 'abc': 123,98.6:37 }  
tinydict3 = { 'abc': 123, 98.6: 37 }

```

示例:创建空字典
```
# 使用大括号 {} 来创建空字典
emptyDict = {}
 
# 打印字典
print(emptyDict)
 
# 查看字典的数量
print("Length:", len(emptyDict))
 
# 查看类型
print(type(emptyDict))
```
运行结果:
```
{}
Length: 0
<class 'dict'>
```
示例:使用内建函数`dict()`创建字典
```
emptyDict = dict()
 
# 打印字典
print(emptyDict)
 
# 查看字典的数量
print("Length:",len(emptyDict))
 
# 查看类型
print(type(emptyDict))
```
运行结果:
```
{}
Length: 0
<class 'dict'>
```

#### 2)访问字典里的值

示例:
```
#!/usr/bin/python3
 
tinydict = {'Name': 'Runoob', 'Age': 7, 'Class': 'First'}
 
print ("tinydict['Name']: ", tinydict['Name'])
print ("tinydict['Age']: ", tinydict['Age'])
```
运行结果:
```
tinydict['Name']:  Runoob
tinydict['Age']:  7
```

#### 3)修改字典

示例:
```
#!/usr/bin/python3  
tinydict = {'Name': 'Runoob', 'Age': 7, 'Class': 'First'}  
tinydict['Age'] = 8  # 更新 Agetinydict['School'] = "中科大"  # 添加信息  
print("tinydict['Age']: ", tinydict['Age'])  
print("tinydict['School']: ", tinydict['School'])
```
运行结果:
```
tinydict['Age']:  8
tinydict['School']:  中科大
```

#### 4)删除字典元素

示例:
```
#!/usr/bin/python3  
tinydict = {'Name': 'Runoob', 'Age': 7, 'Class': 'First'}  
del tinydict['Name']  # 删除键 'Name'tinydict.clear()  # 清空字典  
del tinydict  # 删除字典  
print("tinydict['Age']: ", tinydict['Age'])  
print("tinydict['School']: ", tinydict['School'])
```
运行结果:
```
Traceback (most recent call last):
  File "E:\ProgramData\PycharmProjects\Learning\.venv\mytest.py", line 6, in <module>
    print("tinydict['Age']: ", tinydict['Age'])
NameError: name 'tinydict' is not defined

进程已结束，退出代码为 1
```

>[!IMPORTANT]
>#### 字典键的特性
>1.不允许同一个键出现两次;创建时如果同一个键被赋值两次，后一个值会被记住
>2.键必须不可变，所以可以用数字，字符串或元组充当，而用列表就不行

#### 5)字典的嵌套

示例:
```
cities={  
    '北京':{  
        '朝阳':{'国贸','CBD','天阶','我爱我家','链接地产'},  
        '海淀':{'圆明园','苏州街','中关村','北京大学'},  
        '昌平':{'沙河','南口','小汤山',},  
        '怀柔':{'桃花','梅花','大山'},  
        '密云':{'密云A','密云B','密云C'}  
    },  
    '河北':{  
        '石家庄':{'石家庄A','石家庄B','石家庄C','石家庄D','石家庄E'},  
        '张家口':{'张家口A','张家口B','张家口C'},  
        '承德':{'承德A','承德B','承德C','承德D'}  
    }  
}
for i in cities['北京']:  
    print(i)
```
运行结果:
```
朝阳
海淀
昌平
怀柔
密云
```

#### 6)字典内置函数及方法

Python字典包含了以下内置函数：

|序号|函数及描述|实例|
|---|---|---|
|1|len(dict)  <br>计算字典元素个数，即键的总数。|>>> tinydict = {'Name': 'Runoob', 'Age': 7, 'Class': 'First'}<br>>>> len(tinydict)<br>3|
|2|str(dict)  <br>输出字典，可以打印的字符串表示。|>>> tinydict = {'Name': 'Runoob', 'Age': 7, 'Class': 'First'}<br>>>> str(tinydict)<br>"{'Name': 'Runoob', 'Class': 'First', 'Age': 7}"|
|3|type(variable)  <br>返回输入的变量类型，如果变量是字典就返回字典类型。|>>> tinydict = {'Name': 'Runoob', 'Age': 7, 'Class': 'First'}<br>>>> type(tinydict)<br><class 'dict'>|

Python字典包含了以下内置方法：

|序号|函数及描述|
|---|---|
|1|[dict.clear()](https://www.runoob.com/python3/python3-att-dictionary-clear.html)  <br>删除字典内所有元素|
|2|[dict.copy()](https://www.runoob.com/python3/python3-att-dictionary-copy.html)  <br>返回一个字典的浅复制|
|3|[dict.fromkeys()](https://www.runoob.com/python3/python3-att-dictionary-fromkeys.html)  <br>创建一个新字典，以序列seq中元素做字典的键，val为字典所有键对应的初始值|
|4|[dict.get(key, default=None)](https://www.runoob.com/python3/python3-att-dictionary-get.html)  <br>返回指定键的值，如果键不在字典中返回 default 设置的默认值|
|5|[key in dict](https://www.runoob.com/python3/python3-att-dictionary-in.html)  <br>如果键在字典dict里返回true，否则返回false|
|6|[dict.items()](https://www.runoob.com/python3/python3-att-dictionary-items.html)  <br>以列表返回一个视图对象|
|7|[dict.keys()](https://www.runoob.com/python3/python3-att-dictionary-keys.html)  <br>返回一个视图对象|
|8|[dict.setdefault(key, default=None)](https://www.runoob.com/python3/python3-att-dictionary-setdefault.html)  <br>和get()类似, 但如果键不存在于字典中，将会添加键并将值设为default|
|9|[dict.update(dict2)](https://www.runoob.com/python3/python3-att-dictionary-update.html)  <br>把字典dict2的键/值对更新到dict里|
|10|[dict.values()](https://www.runoob.com/python3/python3-att-dictionary-values.html)  <br>返回一个视图对象|
|11|[pop(key[,default])](https://www.runoob.com/python3/python3-att-dictionary-pop.html)  <br>删除字典 key（键）所对应的值，返回被删除的值。|
|12|[popitem()](https://www.runoob.com/python3/python3-att-dictionary-popitem.html)  <br>返回并删除字典中的最后一对键和值。|

### 2.2.6 集合

集合（set）是一个无序的不重复元素序列。

集合中的元素不会重复，并且可以进行交集、并集、差集等常见的集合操作。

可以使用大括号 { } 创建集合，元素之间用逗号 , 分隔， 或者也可以使用 set() 函数创建集合。
#### 1)创建集合

格式:
```
parame = {value01,value02,...}
或者
set(value)

```

示例:
```
set1 = {1, 2, 3, 4}            # 直接使用大括号创建集合
set2 = set([4, 5, 6, 7])      # 使用 set() 函数从列表创建集合
```

示例:创建空集合
```
emptyset = set( )  
print(emptyset)  
print('Length:',len(emptyset))  
print(type(emptyset))
```
运行结果
```
set()
Length: 0
<class 'set'>
```

>[!NOTE]
>#### 创建空集合
>创建一个空集合必须用 `set( )`而不是` { }`，因为`{ }` 是用来创建一个空字典。

示例
```
basket={'apple','orange','apple','pear','orange','banana'}  
print(basket)#这里演示的是去重功能  
print('orange' in basket)  
print('crabgrass' in basket)
```
运行结果
```
{'orange', 'pear', 'apple', 'banana'}
True
False
```

示例:集合的运算
```
a=set('abcdefghabc')  
b = set('cdefghijklmcdfg')  
print('集合a:',a)  
print('集合b:',b)  
print('a相对于b的差集a-b:',a-b)  
print('b相对于a的差集b-a:',b-a)  
print('并集a|b:',a|b)  
print('交集a&b:',a&b)  
print('对称差集(交集取反)a^b:',a^b)
```
运行结果:
```
集合a: {'b', 'e', 'c', 'h', 'f', 'd', 'a', 'g'}
集合b: {'e', 'c', 'h', 'k', 'i', 'f', 'l', 'd', 'm', 'j', 'g'}
a相对于b的差集a-b: {'b', 'a'}
b相对于a的差集b-a: {'k', 'i', 'l', 'm', 'j'}
并集a|b: {'e', 'c', 'h', 'k', 'f', 'd', 'b', 'l', 'i', 'm', 'j', 'a', 'g'}
交集a&b: {'e', 'c', 'h', 'f', 'd', 'g'}
对称差集(交集取反)a^b: {'b', 'k', 'i', 'l', 'm', 'j', 'a'}
```

#### 2)添加元素

语法如下:
```
s.add(x)
```
将元素 x 添加到集合 s 中，如果元素已存在，则不进行任何操作。
还有一个方法，也可以添加元素，且参数可以是列表，元组，字典等，语法格式如下：
```
s.update( x )
```

示例:
```
thisset = set(("Google", "Runoob", "Taobao"))  
print(thisset)  
thisset.add("Facebook")  
print(thisset)  
thisset.update(("QQ",))  
print(thisset)  
thisset.update(("ICQ","Youtube"))  
print(thisset)
```
运行结果
```
{'Google', 'Runoob', 'Taobao'}
{'Google', 'Facebook', 'Runoob', 'Taobao'}
{'Facebook', 'Taobao', 'Runoob', 'Google', 'QQ'}
{'Facebook', 'Taobao', 'ICQ', 'Runoob', 'Youtube', 'Google', 'QQ'}
```

#### 3)移除元素

语法:
```
s.remove()
```
将元素 x 从集合 s 中移除，如果元素不存在，则会发生错误。

示例:
```
thisset = set(("Google", "Runoob", "Taobao","QQ","ICQ","Youtube"))  
print(thisset)  
thisset.remove("QQ")  
print(thisset)  
thisset.remove("qq")  
print(thisset)
```
运行结果:
```
E:\ProgramData\PycharmProjects\Learning\.venv\Scripts\python.exe E:\ProgramData\PycharmProjects\Learning\.venv\mytest.py 
{'QQ', 'ICQ', 'Youtube', 'Runoob', 'Taobao', 'Google'}
{'ICQ', 'Youtube', 'Runoob', 'Taobao', 'Google'}
Traceback (most recent call last):
  File "E:\ProgramData\PycharmProjects\Learning\.venv\mytest.py", line 5, in <module>
    thisset.remove("qq")
KeyError: 'qq'

进程已结束，退出代码为 1
```

此外还有一个方法也是移除集合中的元素，且如果元素不存在，不会发生错误。格式如下所示：
```
s.discard( x )
```
示例:
```
thisset = set(("Google", "Runoob", "Taobao","QQ","ICQ","Youtube"))  
print(thisset)  
thisset.discard("QQ")  
print(thisset)  
thisset.discard("qq")  
print(thisset)
```
运行结果:
```
{'ICQ', 'Runoob', 'QQ', 'Youtube', 'Google', 'Taobao'}
{'ICQ', 'Runoob', 'Youtube', 'Google', 'Taobao'}
{'ICQ', 'Runoob', 'Youtube', 'Google', 'Taobao'}
```

随机删除1个元素,set 集合的 pop 方法会对集合进行无序的排列，然后将这个无序排列集合的左面第一个元素进行删除。

```
s.pop()
```

示例:
```
thisset = set(("Google", "Runoob", "Taobao","QQ","ICQ","Youtube"))  
print(thisset)  
print(thisset.pop())
```
运行结果
```
{'Youtube', 'Google', 'Taobao', 'ICQ', 'QQ', 'Runoob'}
Youtube

{'QQ', 'Youtube', 'ICQ', 'Google', 'Taobao', 'Runoob'}
QQ
```

#### 4) 集合内置方法完整列表

|方法|描述|
|---|---|
|[add()](https://www.runoob.com/python3/ref-set-add.html)|为集合添加元素|
|[clear()](https://www.runoob.com/python3/ref-set-clear.html)|移除集合中的所有元素|
|[copy()](https://www.runoob.com/python3/ref-set-copy.html)|拷贝一个集合|
|[difference()](https://www.runoob.com/python3/ref-set-difference.html)|返回多个集合的差集|
|[difference_update()](https://www.runoob.com/python3/ref-set-difference_update.html)|移除集合中的元素，该元素在指定的集合也存在。|
|[discard()](https://www.runoob.com/python3/ref-set-discard.html)|删除集合中指定的元素|
|[intersection()](https://www.runoob.com/python3/ref-set-intersection.html)|返回集合的交集|
|[intersection_update()](https://www.runoob.com/python3/ref-set-intersection_update.html)|返回集合的交集。|
|[isdisjoint()](https://www.runoob.com/python3/ref-set-isdisjoint.html)|判断两个集合是否包含相同的元素，如果没有返回 True，否则返回 False。|
|[issubset()](https://www.runoob.com/python3/ref-set-issubset.html)|判断指定集合是否为该方法参数集合的子集。|
|[issuperset()](https://www.runoob.com/python3/ref-set-issuperset.html)|判断该方法的参数集合是否为指定集合的子集|
|[pop()](https://www.runoob.com/python3/ref-set-pop.html)|随机移除元素|
|[remove()](https://www.runoob.com/python3/ref-set-remove.html)|移除指定元素|
|[symmetric_difference()](https://www.runoob.com/python3/ref-set-symmetric_difference.html)|返回两个集合中不重复的元素集合。|
|[symmetric_difference_update()](https://www.runoob.com/python3/ref-set-symmetric_difference_update.html)|移除当前集合中在另外一个指定集合相同的元素，并将另外一个指定集合中不同的元素插入到当前集合中。|
|[union()](https://www.runoob.com/python3/ref-set-union.html)|返回两个集合的并集|
|[update()](https://www.runoob.com/python3/ref-set-update.html)|给集合添加元素|
|[len()](https://www.runoob.com/python3/python3-string-len.html)|计算集合元素个数|

### 2.2.7 数据类型转换

有时候，我们需要对数据内置的类型进行转换，数据类型的转换，一般情况下你只需要将数据类型作为函数名即可。

Python 数据类型转换可以分为两种：

- 隐式类型转换 - 自动完成
- 显式类型转换 - 需要使用类型函数来转换

显示转换函数：
- `int()`强制转换为整型 
- `float()`强制转换为浮点型
- `complex(x)` 将x转换到一个复数，实数部分为 x，虚数部分为 0。    
- `complex(x, y)` 将 x 和 y 转换到一个复数，实数部分为 x，虚数部分为 y。x 和 y 是数字表达式。
- `str()`强制转换为字符串类型

# 3. 运算符

Python 语言支持以下类型的运算符:

- 算术运算符
- 比较（关系）运算符
- 赋值运算符
- 逻辑运算符
- 位运算符
- 成员运算符
- 身份运算符
- 运算符优先级
## 3.1 算术运算符

以下假设变量 a=10，变量 b=21：

|运算符|描述|实例|
|---|---|---|
|+|加 - 两个对象相加|a + b 输出结果 31|
|-|减 - 得到负数或是一个数减去另一个数|a - b 输出结果 -11|
|*|乘 - 两个数相乘或是返回一个被重复若干次的字符串|a * b 输出结果 210|
|/|除 - x 除以 y|b / a 输出结果 2.1|
|%|取模 - 返回除法的余数|b % a 输出结果 1|
|**|幂 - 返回x的y次幂|a**b 为10的21次方|
|//|取整除 - 往小的方向取整数|>>> 9//2<br>4<br>>>> -9//2<br>-5|
示例:
```
#!/usr/bin/python3  
  
a = 21  
b = 10  
  
c = a + b  
print("a+b=", c)  
  
c = a - b  
print("a-b=", c)  
  
c = a * b  
print("a*b=", c)  
  
c = a / b  
print("a/b=", c)  
  
c = a % b  
print("a%b=", c)  
  
c = a ** b  
print("a**3=", c)  
  
c = a // b  
print("a//b=", c)
```
运行结果
```
a+b= 31
a-b= 11
a*b= 210
a/b= 2.1
a%b= 1
a**3= 16679880978201
a//b= 2
```

## 3.2 比较运算符

以下假设变量 a 为 10，变量 b 为20：

|运算符|描述|实例|
|---|---|---|
|==|等于 - 比较对象是否相等|(a == b) 返回 False。|
|!=|不等于 - 比较两个对象是否不相等|(a != b) 返回 True。|
|>|大于 - 返回x是否大于y|(a > b) 返回 False。|
|<|小于 - 返回x是否小于y。所有比较运算符返回1表示真，返回0表示假。这分别与特殊的变量True和False等价。注意，这些变量名的大写。|(a < b) 返回 True。|
|>=|大于等于 - 返回x是否大于等于y。|(a >= b) 返回 False。|
|<=|小于等于 - 返回x是否小于等于y。|(a <= b) 返回 True。|
示例:
```
#!/usr/bin/python3  
  
a = 21  
b = 10  
  
if (a == b):  
    print("1 - a 等于 b")  
else:  
    print("1 - a 不等于 b")  
  
if (a != b):  
    print("2 - a 不等于 b")  
else:  
    print("2 - a 等于 b")  
  
if (a < b):  
    print("3 - a 小于 b")  
else:  
    print("3 - a 大于等于 b")  
  
if (a > b):  
    print("4 - a 大于 b")  
else:  
    print("4 - a 小于等于 b")  
  
if (a <= b):  
    print("5 - a 小于等于 b")  
else:  
    print("5 - a 大于 b")  
  
if (b >= a):  
    print("6 - b 大于等于 a")  
else:  
    print("6 - b 小于 a")
```
运行结果:
```
1 - a 不等于 b
2 - a 不等于 b
3 - a 大于等于 b
4 - a 大于 b
5 - a 大于 b
6 - b 小于 a
```

## 3.3 赋值运算符

以下假设变量a为10，变量b为20：

| 运算符 | 描述                                                         | 实例                                                                                                                          |
| --- | ---------------------------------------------------------- | --------------------------------------------------------------------------------------------------------------------------- |
| =   | 简单的赋值运算符                                                   | c = a + b 将 a + b 的运算结果赋值为 c                                                                                                |
| +=  | 加法赋值运算符                                                    | c += a 等效于 c = c + a                                                                                                        |
| -=  | 减法赋值运算符                                                    | c -= a 等效于 c = c - a                                                                                                        |
| *=  | 乘法赋值运算符                                                    | c \*= a 等效于 c = c * a                                                                                                       |
| /=  | 除法赋值运算符                                                    | c /= a 等效于 c = c / a                                                                                                        |
| %=  | 取模赋值运算符                                                    | c %= a 等效于 c = c % a                                                                                                        |
| **= | 幂赋值运算符                                                     | c \*\*= a 等效于 c = c ** a                                                                                                    |
| //= | 取整除赋值运算符                                                   | c //= a 等效于 c = c // a                                                                                                      |
| :=  | 海象运算符，这个运算符的主要目的是在表达式中同时进行赋值和返回赋值的值。**Python3.8 版本新增运算符**。 | 在这个示例中，赋值表达式可以避免调用 len() 两次:<br><br>if (n := len(a)) > 10:<br>    print(f"List is too long ({n} elements, expected <= 10)") |

示例:
```
#!/usr/bin/python3  
a = 21  
b = 10  
  
c = a + b  
print("c = a + b", c)  
c += a  
print("c += a", c)  
c -= a  
print("c -= a", c)  
c *= a  
print("c *= a", c)  
c /= a  
print("c /= a", c)  
c %= a  
print("c %= a", c)  
c **= a  
print("c **= a", c)  
c //= a  
print("c //= a", c)
```
运行结果:
```
c = a + b 31
c += a 52
c -= a 31
c *= a 651
c /= a 31.0
c %= a 10.0
c **= a 1e+21
c //= a 4.761904761904762e+19
```


示例:海象运算
```
# 传统写法
n = 10
if n > 5:
    print(n)

# 使用海象运算符
if (n := 10) > 5:
    print(n)
```

## 3.4 位运算符

按位运算符是把数字看作二进制来进行计算的。Python中的按位运算法则如下：

变量 a 为 60，b 为 13二进制格式如下：

```
a = 0011 1100

b = 0000 1101

-----------------

a&b = 0000 1100

a|b = 0011 1101

a^b = 0011 0001

~a  = 1100 0011
```

|运算符|描述|实例|
|---|---|---|
|&|按位与运算符：参与运算的两个值,如果两个相应位都为1,则该位的结果为1,否则为0|(a & b) 输出结果 12 ，二进制解释： 0000 1100|
|\||按位或运算符：只要对应的二个二进位有一个为1时，结果位就为1。|(a \| b) 输出结果 61 ，二进制解释： 0011 1101|
|^|按位异或运算符：当两对应的二进位相异时，结果为1|(a ^ b) 输出结果 49 ，二进制解释： 0011 0001|
|~|按位取反运算符：对数据的每个二进制位取反,即把1变为0,把0变为1。~x 类似于 -x-1|(~a ) 输出结果 -61 ，二进制解释： 1100 0011， 在一个有符号二进制数的补码形式。|
|<<|左移动运算符：运算数的各二进位全部左移若干位，由"<<"右边的数指定移动的位数，高位丢弃，低位补0。|a << 2 输出结果 240 ，二进制解释： 1111 0000|
|>>|右移动运算符：把">>"左边的运算数的各二进位全部右移若干位，">>"右边的数指定移动的位数|a >> 2 输出结果 15 ，二进制解释： 0000 1111|
示例:
```
#!/usr/bin/python3  
a = 60  # 60 = 0011 1100  
b = 13  # 13 = 0000 1101  
c = a & b  # 12 = 0000 1100  
print("a & b=", c)  
c = a | b  # 61 = 0011 1101  
print("a | b =", c)  
c = a ^ b  # 49 = 0011 0001  
print("a ^ b=", c)  
c = ~a  # -61 = 1100 0011  
print("~a=", c)  
c = a << 2  # 240 = 1111 0000  
print("a << 2=", c)  
c = a >> 2  # 15 = 0000 1111  
print("a >> 2=", c)
```
运行结果:
```
a & b= 12
a | b = 61
a ^ b= 49
~a= -61
a << 2= 240
a >> 2= 15
```

## 3.5 逻辑运算符

Python语言支持逻辑运算符，以下假设变量 a 为 10, b为 20:

|运算符|逻辑表达式|描述|实例|
|---|---|---|---|
|and|x and y|布尔"与" - 如果 x 为 False，x and y 返回 x 的值，否则返回 y 的计算值。|(a and b) 返回 20。|
|or|x or y|布尔"或" - 如果 x 是 True，它返回 x 的值，否则它返回 y 的计算值。|(a or b) 返回 10。|
|not|not x|布尔"非" - 如果 x 为 True，返回 False 。如果 x 为 False，它返回 True。|not(a and b) 返回 False|
示例:
```
#!/usr/bin/python3  
a = 10  
b = 20  
c = 0  
if (a and b):  
    print("1 - 变量 a 和 b 都为 true")  
else:  
    print("1 - 变量 a 和 b 有一个不为 true")  
if (a or b):  
    print("2 - 变量 a 和 b 都为 true，或其中一个变量为 true")  
else:  
    print("2 - 变量 a 和 b 都不为 true")  
if (c and b):  
    print("3 - 变量 c 和 b 都为 true")  
else:  
    print("3 - 变量 c 和 b 有一个不为 true")  
if (c or b):  
    print("4 - 变量 c 和 b 都为 true，或其中一个变量为 true")  
else:  
    print("4 - 变量 c 和 b 都不为 true")  
if not (c and b):  
    print("5 - 变量 c 和 b 都为 false，或其中一个变量为 false")  
else:  
    print("5 - 变量 c 和 b 都为 true")
```
运行结果:
```
1 - 变量 a 和 b 都为 true
2 - 变量 a 和 b 都为 true，或其中一个变量为 true
3 - 变量 c 和 b 有一个不为 true
4 - 变量 c 和 b 都为 true，或其中一个变量为 true
5 - 变量 c 和 b 都为 false，或其中一个变量为 false
```

## 3.6 成员运算符

除了以上的一些运算符之外，Python还支持成员运算符，测试实例中包含了一系列的成员，包括字符串，列表或元组。

|运算符|描述|实例|
|---|---|---|
|in|如果在指定的序列中找到值返回 True，否则返回 False。|x 在 y 序列中 , 如果 x 在 y 序列中返回 True。|
|not in|如果在指定的序列中没有找到值返回 True，否则返回 False。|x 不在 y 序列中 , 如果 x 不在 y 序列中返回 True。|
示例:
```
#!/usr/bin/python3  
a = 10  
b = 20  
list = [1, 2, 3, 4, 5]  
if (a in list):  
    print("1 - 变量 a 在给定的列表中 list 中")  
else:  
    print("1 - 变量 a 不在给定的列表中 list 中")  
if (b not in list):  
    print("2 - 变量 b 不在给定的列表中 list 中")  
else:  
    print("2 - 变量 b 在给定的列表中 list 中")  
# 修改变量 a 的值  
a = 2  
if (a in list):  
    print("3 - 变量 a 在给定的列表中 list 中")  
else:  
    print("3 - 变量 a 不在给定的列表中 list 中")
```
运行结果
```
1 - 变量 a 不在给定的列表中 list 中
2 - 变量 b 不在给定的列表中 list 中
3 - 变量 a 在给定的列表中 list 中
```

## 3.7 身份运算符

身份运算符用于比较两个对象的存储单元

|运算符|描述|实例|
|---|---|---|
|is|is 是判断两个标识符是不是引用自一个对象|**x is y**, 类似 **id(x) == id(y)** , 如果引用的是同一个对象则返回 True，否则返回 False|
|is not|is not 是判断两个标识符是不是引用自不同对象|**x is not y** ， 类似 **id(x) != id(y)**。如果引用的不是同一个对象则返回结果 True，否则返回 False。|

>[!NOTE] 注
>`id()`函数用于获取对象内存地址。

以下实例演示了Python所有身份运算符的操作：
```
#!/usr/bin/python3  
a = 20  
b = 20  
if (a is b):  
    print("1 - a 和 b 有相同的标识")  
else:  
    print("1 - a 和 b 没有相同的标识")  
  
if (id(a) == id(b)):  
    print("2 - a 和 b 有相同的标识")  
else:  
    print("2 - a 和 b 没有相同的标识")  
b = 30  
if (a is b):  
    print("3 - a 和 b 有相同的标识")  
else:  
    print("3 - a 和 b 没有相同的标识")  
if (a is not b):  
    print("4 - a 和 b 没有相同的标识")  
else:  
    print("4 - a 和 b 有相同的标识")
```
运行结果:
```
1 - a 和 b 有相同的标识
2 - a 和 b 有相同的标识
3 - a 和 b 没有相同的标识
4 - a 和 b 没有相同的标识
```

>[!NOTE]
>`is` 与 `==`区别
`is`用于判断两个变量引用对象是否为同一个，`==` 用于判断引用变量的值是否相等。

示例:
```
a = [1, 2, 3]  
b = a  
print('a和b是同一个对象?:',b is a)  
print('a和b的值是否相等?:',b == a)  
b = a[:]  
print('a和b是同一个对象?:',b is a)  
print('a和b的值是否相等?:',b == a)
```
运行结果:
```
a和b是同一个对象?: True
a和b的值是否相等?: True
a和b是同一个对象?: False
a和b的值是否相等?: True
```

## 3.8 运算符优先级

以下表格列出了从最高到最低优先级的所有运算符， 相同单元格内的运算符具有相同优先级。 运算符均指二元运算，除非特别指出。 相同单元格内的运算符从左至右分组（除了幂运算是从右至左分组）：

|运算符|描述|
|---|---|
|`(expressions...)`,<br><br>`[expressions...]`, `{key: value...}`, `{expressions...}`|圆括号的表达式|
|`x[index]`, `x[index:index]`, `x(arguments...)`, `x.attribute`|读取，切片，调用，属性引用|
|await x|await 表达式|
|`**`|乘方(指数)|
|`+x`, `-x`, `~x`|正，负，按位非 NOT|
|`*`, `@`, `/`, `//`, `%`|乘，矩阵乘，除，整除，取余|
|`+`, `-`|加和减|
|`<<`, `>>`|移位|
|`&`|按位与 AND|
|`^`|按位异或 XOR|
|`\|`|按位或 OR|
|`` `in`,`not in`, `is`,`is not`, `<`, `<=`, `>`, `>=`, `!=`, `==` ``|比较运算，包括成员检测和标识号检测|
|`` `not x` ``|逻辑非 NOT|
|`` `and` ``|逻辑与 AND|
|`` `or` ``|逻辑或 OR|
|`` `if` -- `else` ``|条件表达式|
|`` `lambda` ``|lambda 表达式|
|`:=`|赋值表达式|

# 4. 条件控制

## 4.1 `if`语句

格式:
```
if condition_1:
    statement_block_1
elif condition_2:
    statement_block_2
else:
    statement_block_3
```
>[!NOTE]
>`elif`和`else`语句不是必选项


# 5. 循环语句
# 6.推导式
# 7.迭代器和生成器
# 8.函数

