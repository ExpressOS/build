AC_INIT([ExpressOS], [1.0], [haohui.mai@gmail.com])

# Minimum Autoconf version required.
AC_PREREQ(2.62)

# Checks for programs.
AC_PROG_CC
AC_PROG_CXX

AC_PROG_SED

AC_PATH_PROG(XORRISO,xorriso,false)
if test "x$XORRISO" = "xfalse"; then
  AC_MSG_ERROR([xorriso is required to build ISO images.])
fi

AC_PATH_PROG(PTYHON,python,false)
if test "x$PYTHON" = "xfalse"; then
  AC_MSG_ERROR([python is required.])
fi

AC_PATH_PROG(LLVM_CONFIG,llvm-config,false)
if test "x$LLVM_CONFIG" = "xfalse"; then
  AC_MSG_ERROR([llvm is required.])
fi

llvm_bin_dir=`$LLVM_CONFIG --bindir`
AC_SUBST(llvm_bin_dir)

AC_CACHE_CHECK([for clang++], [ac_cv_path_CLANG],
  [AC_PATH_PROGS_FEATURE_CHECK([CLANG],
    [clang++],
    [[clang_out=`echo -e '#include <iostream>\n int main() { std::cout << "Hello"; return 0; }'|$ac_path_CLANG -std=c++11 -x c++ - -o /dev/null; echo $?`
      test "x$clang_out" = x0 && ac_cv_path_CLANG=$ac_path_CLANG ac_path_CLANG_found=:
      ]],
    [AC_MSG_ERROR([could not find clang])])])
AC_SUBST([CLANG], [$ac_cv_path_CLANG])

AC_ARG_WITH([target],
            [AS_HELP_STRING([--with-target],
              [specify the target. Valid target is: x86_pentium (default=x86_pentium)])],
            [target="$withval"],
            [target="x86_pentium"])

AC_SUBST(target)

dnl Absolute source/build directory
abs_srcdir=`(cd $srcdir && pwd)`
abs_builddir=`pwd`

dnl If the source dir is not equal to the build dir, 
dnl then we are running in VPATH mode.

if test "$abs_builddir" == "$abs_srcdir"; then
  AC_MSG_ERROR([Only out-of-source build is supported.])
fi

cd $abs_builddir
AC_CONFIG_FILES([
  Makefile
])
AC_OUTPUT
