# Bash Logger

## logging module for bash scripts

This script is used to log messages to the console and to a log file and is designed to be similar the API of the python
logging module.  It includes log rotation by size and by number of log files.

There are a couple of additional functions to show how you could create custom logging functions for yourself.

There is a test script that you can run to see how the logging works.

## Log rotation

Log rotation is handled by the rotateLogs function. When logging to a file is enabled, the rotateLogs
function is called during each run and by default maintains a history of 5 runs. The number of log history files to
maintain
can be changed by calling the log_rotation_count function. The function creates a new copy of the log file with the next
number in the sequence and then deletes the oldest log file. For example, if the log file is named "mylog.log" and the
log_rotation_count is set to 5, the log files will be named "mylog.log.1", "mylog.log.2", "mylog.log.3", "mylog.log.4",
and
"mylog.log.5". When the rotation is full the log file will be renamed to "mylog.log.1" and the oldest log file, "
mylog.log.5",
will be deleted. The numbers are in reverse order so that the newest log file is always named "mylog.log".

```bash
log_rotation_count 10
```

## Usage:

Import this file with the following statement near the top of your script

```bash
. ./logger.sh
```

By default, the level is set to INFO, colored logging to the screen is enabled, and logging to a file is disabled.

You can initialize the logging level, turn off/on logging to screen,
and set the log file name ( which will turn logging to file on/off ) with the following function:

```bash
set_logging [log_level] [log_to_screen] [log_file_name]
```

Set the logging level to one of CRITICAL ERROR WARNING INFO DEBUG

```bash
set_log_level DEBUG
```

By default, the logs will rotate when the size is greater than 100 kb. You can change the size of the log file before it
rotates with the following function:  
*NOTE: This function must be called before set_logging or log_file_name*

```bash
log_file_rotate_size 10000 # 10 kb
```

Turn logging to screen on/off

```bash
log_to_screen true/false
```

Turn colors on/off (default is on) when logging to screen

```bash
log_color_output true/false
```

Set the log file name and turn on logging to that file. If you do not set the log file name, logging to file will be
turned off. Once you set the log file name, logging to file will be turned on and log rotation will be enabled.

```bash
log_file_name /path/to/log/file
```

You can log to the screen and/or to a file with the following functions:

```bash
log_critical "This is a critical error"
log_error "This is an error"
log_warning "This is a warning"
log_info "This is a info log"
log_debug "This is a debug statement"
```

You can also run a command and log the output to the screen and/or to a file if you have set the log file name:  
The output will be prepended and appended with a begin and end message.  
This will run ls -l and log the output to the screen and/or to a file if you have set the log file name:

```bash
log_execute DEBUG ls -l
```

You can also create custom functions  (which will log to the screen and/or to a file if you have set the log file
name):  
I have included a sample of two functions which you can use as examples of how to create your own custom functions.  
First create a file to test with:

```bash
date &> /tmp/date.out
```

Then run the following commands:
this will run cat /tmp/date.out and log the output to the screen and/or to a file if you have set the log file name:  
The output will bre prepended and appended with a begin and end message.

```bash
log_cat_file /tmp/date.out
```

This will run ls -l /tmp/date.out and log the output to the screen and/or to a file if you have set the log file name:  
The output will bre prepended and appended with a begin and end message.

```bash
log_info_file /tmp/date.out
```


## Example:

The following is an example of how to use this script:  
Import the script - by default, the level is set to INFO, colored logging to the screen is enabled, and logging to a
file is disabled.
Run an example of each standard log function
Note that the debug line produces no output because the default log level is INFO
log the execution lf ls -l
create a sample file to test with which has hte date inside of it
log the output of cat /tmp/date.out
This will produce no output because the function is set to DEBUG and the default log level is INFO
log the output of ls -l /tmp/date.out
set the log level to DEBUG
run a debug level log function to see that it now produces output

```bash
. ./logger.sh
log_critical "This is a critical error"
log_error "This is an error"
log_warning "This is a warning"
log_info "This is a info log"
log_debug "This is a debug statement"
log_execute INFO ls -l
date &> /tmp/date.out
log_cat_file /tmp/date.out
log_info_file /tmp/date.out
log_level DEBUG
log_debug "This is another debug statement"
```

## License
See LICENSE file

## Author
Written by:  Leon Letto

## Contributions
Contributions and suggestions are welcome.  Please submit a pull request.