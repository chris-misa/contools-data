//
// libftrace_dump
//
// call current configed method to get trace pipe
// and dump lines to stdout
//
#include <unistd.h>
#include <stdio.h>
#include <stdlib.h>
#include <signal.h>
#include <string.h>

#include "libftrace.h"
#include "../time_common.h"

#define TRACING_FS_PATH "/sys/kernel/debug/tracing"
#define TRACE_BUFFER_SIZE 0x1000

static volatile int running = 1;

void usage()
{
  fprintf(stdout, "Usage: ftrace_dump\n");
}

void do_exit()
{
  running = 0;
}

int main(int argc, char *argv[])
{
  char buf[TRACE_BUFFER_SIZE];
  FILE *tp = NULL;
  int nbytes = 0;
  // This must match with events used in libftrace.h
  const char *events = "net:*";
  struct trace_event *evt;
  struct timeval start_send_time;
  struct timeval finish_send_time;

  signal(SIGINT, do_exit);

  tp = get_trace_pipe(TRACING_FS_PATH, events, NULL, NULL);

  if (!tp) {
    fprintf(stderr, "Failed to open trace pipe\n");
    return 1;
  }

  while (running) {
    if (fgets(buf, TRACE_BUFFER_SIZE, tp) != NULL) {
      fprintf(stdout, "%s", buf);
    }
  }

  release_trace_pipe(tp, TRACING_FS_PATH);

  fprintf(stdout, "Done.\n");
}
