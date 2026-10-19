// popupwatch X Y W H: exits once the pointer leaves the rectangle (global
// top-left coordinates). Polls in-process at ~60Hz; SketchyBar's own
// mouse.exited events are unreliable around popups.
#include <ApplicationServices/ApplicationServices.h>
#include <stdlib.h>
#include <unistd.h>

int main(int argc, char **argv) {
  if (argc != 5) return 2;
  CGRect r = CGRectMake(atof(argv[1]), atof(argv[2]), atof(argv[3]), atof(argv[4]));
  for (;;) {
    CGEventRef e = CGEventCreate(NULL);
    CGPoint p = CGEventGetLocation(e);
    CFRelease(e);
    if (!CGRectContainsPoint(r, p)) return 0;
    usleep(16000);
  }
}
