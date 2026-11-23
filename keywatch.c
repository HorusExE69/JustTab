/*
 * JustTab keywatch: waits until the Tab key is physically released (X11),
 * then prints "up" and exits. Exits 2 without printing if X11 is unavailable.
 * Built automatically by justtab.plugin.zsh on first use.
 */
#include <X11/Xlib.h>
#include <X11/keysym.h>
#include <stdio.h>
#include <time.h>

int main(void)
{
	Display *d = XOpenDisplay(NULL);
	if (!d)
		return 2;
	KeyCode kc = XKeysymToKeycode(d, XK_Tab);
	if (!kc)
		return 2;

	char keys[32];
	struct timespec step = {0, 4 * 1000 * 1000};   /* check every 4 ms */
	for (int i = 0; i < 15000; i++) {              /* give up after 60 s */
		XQueryKeymap(d, keys);
		if (!(keys[kc / 8] & (1 << (kc % 8))))
			break;
		nanosleep(&step, NULL);
	}
	puts("up");
	fflush(stdout);
	XCloseDisplay(d);
	return 0;
}
