#include <pthread.h>

#ifndef HOOK_PATH
#define HOOK_PATH "/usr/bin/pi400kb-hook"
#endif

int initUSB();
int main();
void sendHIDReport();
