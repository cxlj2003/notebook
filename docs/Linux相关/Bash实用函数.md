# 1. 版权信息

```
cat <<_EOF_

_EOF_
```
#  2. 菜单

```
#!/bin/bash

menu_option_one() {
  echo "Hello John!!!"
}

menu_option_two() {
  echo "Some super cool code by John."
}

press_enter() {
  echo ""
  echo -n "	Press Enter to continue "
  read
  clear
}

incorrect_selection() {
  echo "Incorrect selection! Try again."
}
until [ "$selection" = "0" ]; do
  clear
    clear
    cat<<_EOF_
    ==============================
    Menusystem experiment
    ------------------------------
    Please enter your choice:

    Option (1)
    Option (2)
    Option (3)
           (0) Quit
    ------------------------------
_EOF_
  echo -n "  Enter selection: "
  read selection
  echo ""
  case $selection in
    1 ) clear ; menu_option_one ; press_enter ;;
    2 ) clear ; menu_option_two ; press_enter ;;
    3 ) clear ; menu_option_three ; press_enter ;;
    0 ) clear ; exit 0;;
    * ) clear ; incorrect_selection ; press_enter ;;
  esac
done

```