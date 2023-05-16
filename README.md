# CSPB-3753  Lab 2 :  Tracing the System Calls with eBPF
<figure width=100%>
  <IMG SRC="https://www.colorado.edu/cs/profiles/express/themes/cuspirit/logo.png" WIDTH=100 ALIGN="right" style="margin:20px">
</figure>
 
### Exploring the Linux Kernel using eBPF

In this lab, you'll use a cutting-edge program tracing tool to monitor
your `file-io` program *and how it uses the operating system*.
We'll use the [`bpftool`](https://github.com/libbpf/bpftool/blob/master/README.md) 
package which uses the [eBPF technology](https://ebpf.io/).

[eBPF technology](https://ebpf.io/) (*e*xtended *B*erkeley *P*acket *F*ilters) lets you insert code into the Linux kernel in a controlled and safe manner. There are lots of applications for eBPF, including networking and 
[building performance tools](https://learning.oreilly.com/library/view/bpf-performance-tools/9780136588870/).

We will use `bpftrace` to:
* Print a string we enter & exist the `native`, `with_syscall` and `with_asm` functions of our program `file-io`.
* Print a string when `file-io` calls the `open(2)` library routine.
* Print an alert when `file-io` executes an `open` system call; this alert will occur in the kernel.
* Print yet another alert when `file-io` executes the `vfs_open` function which is part of the [virtual file system layer](https://learning.oreilly.com/library/view/bpf-performance-tools/9780136588870/ch08.xhtml#sec8_1) called by the open system call
* And, lastly, print an alert when the actual file system routine `ext4_file_open` is called.

By using `bpftrace` this way, you'll both gain a better understanding of the kernel functions you'll need for the next lab, but you'll also have built a debugging tool that helps you during the next lab.

We'll first describe `bpftrace` briefly, then describe how to install the tool and then the specific details of what you need to do.

## bpftrace

You can read more about `bpftrace` in the book [BPF Performance Tools (chapter 5) by Brendan Gregg](https://learning.oreilly.com/library/view/bpf-performance-tools/9780136588870/ch05.xhtml#ch05). That book is in the CU Library and you should be able to access it [here](https://discovery.ebsco.com/c/3czfwv/details/sk2672xrrj?limiters=FT1%3AY&q=BPF%20Performance%20Tools) by logging in with your CU credential (Access Options -> Online Access).
Additional information is in the [bpftool reference file on github](https://github.com/iovisor/bpftrace/blob/master/docs/reference_guide.md#1-builtins).

`bpftool` lets you instrument the Linux kernel and applications. You can instrument **kernel probbes** when you enter and exit a kernel function (kprobe/kretprobe).
Similarly, you can instrument **user probbes** when you enter and exit a function in a user-space program (uprobe/uretprobe).
Lastly, you can instrument system calls (tracepoints:syscalls) and other "well known" kernel functions.
The "instrumentation" is a small, simple program in
a specialized programming language described [here](https://learning.oreilly.com/library/view/bpf-performance-tools/9780136588870/ch05.xhtml#ch05).

This lets you measure and explore the Linux kernel and the running system with ease. For example, the following 1-line program:
```
ubuntu@bpftrace:~$ sudo bpftrace -e 'kprobe:ext4_file_open { print(kstack()); exit(); }'
```
will

1. Locate the routine `ext4_file_open` (the code that opens a file in the ext4 file system) and insert a "kernel probe",
2. Once that trap is triggered, the code following in braces is executed.
3. That code prints out the kernel stack trace ( the sequence of procedure calls leading to `ext4_file_open`) and then,
4. exits.

Note that you **must** be the root user (using `sudo`) when executing `bpftrace`.
A sample output is shown below; different outputs are possible because
different parts of the kernel may open files.

```
Attaching 1 probe...

        ext4_file_open+1
        vfs_open+45
        do_open+525
        path_openat+274
        do_filp_open+178
        do_sys_openat2+159
        __x64_sys_openat+85
        do_syscall_64+92
        entry_SYSCALL_64_after_hwframe+97
```

From this, we see that the function specific to a file system (`ext_file_open`) is called by the [*virtual file system layer*](https://learning.oreilly.com/library/view/bpf-performance-tools/9780136588870/ch08.xhtml#sec8_1)
routine, `vfs_open`. That routine is in turn called by other functions
upto the code that does a syscall (`do_syscall`) and the entry point
for syscalls (`entry_SYSCALL_64_after_hwframe`).

Similarly, the following example:
```
sudo bpftrace -e 'tracepoint:syscalls:sys_enter_open { printf("did an open on %s", str(args -> filename)); exit()}'
Attaching 1 probe...
did an open on output.txt
```
instruments the `open` system call (in the kernel) and prints out the name
of the file being opened and then exits. That trap be executed by *any*
process or program that does an `open` call; it turns out most programs use
a related call, `openat` rather than `open` itself, so this trap was caused by
our `file-io` program.

We can add *filters* to only execute the code if a condition is met.
For example, if we only want to trap the `openat` calls from the `/bin/echo`
program we could write:
```
 sudo bpftrace -e 'tracepoint:syscalls:sys_enter_openat /comm=="echo"/ { printf("%s did an openat on %s", comm, str(args -> filename)); exit()}'
Attaching 1 probe...
echo did an openat on /etc/ld.so.cache
```
and the filter specified by `/comm=="echo"/` would only trigger if the **comm**and (the filename) is `echo`. Even if we invoke the program
as `/bin/echo`, the filter is matching against the last file in the path.

At this point, you should install `bpftool` and work through the examples
we've included above and the examples in this [bpftrace tutorial](https://learning.oreilly.com/library/view/bpf-performance-tools/9780136588870/ch05.xhtml#ch05). You can skip the discussion of the *map* data types in that tutorial since you don't need them for this lab.


## Installing `bpftrace`

Although there are pre-compiled versions of `bpftrace` for Ubuntu and other versions of Linux, you need to build and install a version using the [INSTALL-BPFTRACE.sh](INSTALL-BPFTRACE.sh) script provided because
the packaged versions are typically lacking needed features (debugging support needed for `uprobes`).

This script:
* Installs needed packages to build the software
* Retrieves the `bpftool` git repository
* Configures, builds and installs the tools and libraries.

You'll need to have `sudo` for this to work. Once `bpftool` is installed,
you can execute it using `/usr/local/bin/bpftool` or just `bpftool` if the
`/usr/local/bin/` library is on your path.

## What you should do

The previous `bpftool` examples were "one-liners" that specified the program on the command line. You will modify file `trace.bt` with a more complex
multi-line `bpftool` program that is a series of match, filter and & action
rules that:

* Use user-space probes to indicate when the `native`, `with_syscall` and `with_asm` routines are entered and exited,
* use tracepoints for system calls to indicate when the open system call is entered,
* use kernel probes to indicate when the kernel routines `open`, `vfs_open` and `ext4_file_open` are called.

Your resulting output should look something like the below. 

```
sudo ./trace.bt
Attaching 14 probes...
> native
.. enter open(output.txt)
.... .... Called vfs_open
.... .... .... Called ext4_file_open with command file-io
.... .... .... Return from ext4_file_open
.... .... Return from vfs_open
.. exit open
.. enter open(output.txt)
.... .... Called vfs_open
.... .... .... Called ext4_file_open with command file-io
.... .... .... Return from ext4_file_open
.... .... Return from vfs_open
.. exit open
< native
> with_syscall
.... Enter open() systemcall, argument is output.txt
.... .... Called vfs_open
.... .... .... Called ext4_file_open with command file-io
.... .... .... Return from ext4_file_open
.... .... Return from vfs_open
.... Exit open() systemcall
.... Enter open() systemcall, argument is output.txt
.... .... Called vfs_open
.... .... .... Called ext4_file_open with command file-io
.... .... .... Return from ext4_file_open
.... .... Return from vfs_open
.... Exit open() systemcall
< with_syscall
> with_asm
.... Enter open() systemcall, argument is output.txt
.... .... Called vfs_open
.... .... .... Called ext4_file_open with command file-io
.... .... .... Return from ext4_file_open
.... .... Return from vfs_open
.... Exit open() systemcall
.... Enter open() systemcall, argument is 
.... Exit open() systemcall
.... Enter open() systemcall, argument is output.txt
.... .... Called vfs_open
.... .... .... Called ext4_file_open with command file-io
.... .... .... Return from ext4_file_open
.... .... Return from vfs_open
.... Exit open() systemcall
.... Enter open() systemcall, argument is 
.... Exit open() systemcall
< with_asm
```

* Notice that although the `native` code calls `open` from libc, the `open` system call is not actually triggered. This is because `native` uses the C library routine which uses the `openat` system call to implement `open`.
* Note that the `with_syscall` interface triggers the `open` system call
but doesn't call the `open` from libc -- that actual open system call was
done using the `syscall` function.
* The `open` in `with_asm()` has something squirrely going on! There appear to be extra calls to the `open` syscall with an empty argument. Perhaps my implementation had bugs?

For tracepoints, you can print arguments by knowing the function specification and the names given to arguments.
For example, the [kernel `open` function is at line 1361 of this kernel tree](https://elixir.bootlin.com/linux/v6.3.1/source/fs/open.c).
You can examine that to get the name of the file being opened.

Likewise, the [`ext4_file_open` is in `fs/ext4/file.c`](https://elixir.bootlin.com/linux/v6.3.1/source/fs/ext4/file.c). The end of that file contains a data structure that defines the functions to call for different
methods in the virtual file system layer which is how we learned
that `open` is implemented using `ext4_file_open`.
In the next lab, you'll be writing your own kernel module
and need to define tables like the one in `file.c`.

For `kprobes` and `uprobes`,
you can directly access the Intel registers being passed to the function
but you can't relate them to argument names like you can for tracepoints.
If you look at the code for `ext4_file_open` you'll see that
it no longer takes a simple file name as an argument.

The `trace.bt` file is marked executable and the first line
in that file indicates that it should be executed using `bpftool`.
If you have problems using it that way, you can simply execute `bpftool btrace.bt` to pass in the program.

You'll need two terminals on your VM - one in which to run `trace.bt` and
another to execute `file-io` when `trace.bt` has been started.

You should comment your `trace.bt` file as needed. The total length shouldn't
be more than ~50 files without comments. You should start in steps:

1. Start with the `uprobe` for your `file-io` program's `native` function.
2. Once you get `uprobe` working, try using `kprobe` for the `ext4_file_open` routine.
3.  You'll find that `ext4_file_open` generates a lot of output. Figure out how to use *filters* to limit the output only those processes running the `file-io` progam.
4. Then add in the `tracepoint` type for the system call and get the formatting to work on both entry *and* exit for each routine.

<hr><hr>

## Submission Instructions

**Although your assignment will be graded from your files in the remote repository,**
**you must follow the instructions carefully; otherwise, your solution will not interface with the script `test.py` and you will lose points.**

<img src="images/deliverable.png" alt="Deliverable Item" WIDTH=40 ALIGN="left" style="margin:10px" />
You will need to push your solutions to your repository <br>and it should include the following files:
 
- `Makefile`: A makefile that will compile your LKM code (simply modify the Makefile in the repository).
- `load.sh`: An executable `bash` script that will run the `mknod` and `insmod` commands to install your character device driver.
- `unload.sh`: An executable `bash` script that will run the `rm` and `rmmod` commands to uninstall your character device driver.
- `my_driver.c:` Your LKM driver code.
 
##### **You must submit the following text to Moodle when you have completed the assignment:**
* Your name: 
* CU ID:
* GitHub Username:
* Hours to complete:

**IMPORTANT**: Make sure that all your added files and changes are **pushed** to the remote repository before going to Moodle to submit your completion information in the Moodle assignment.

<hr><hr><hr>