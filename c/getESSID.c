#include <stdio.h>  // printf
#include <string.h> // strdup prototype
#include <stdlib.h> // free protype

/* socket systemcall */
#include <sys/types.h>
#include <sys/socket.h>


#include <linux/if.h>

/* Wireless monitoring */
#include <linux/wireless.h>

char *
get_essid (char *iface)
{
   int           fd;
   struct iwreq  w;
   char          essid[IW_ESSID_MAX_SIZE];

   if (!iface) return NULL;

   fd = socket(AF_INET, SOCK_DGRAM, 0);

   strncpy (w.ifr_ifrn.ifrn_name, iface, IFNAMSIZ);
   memset (essid, 0, IW_ESSID_MAX_SIZE);
   w.u.essid.pointer = (caddr_t *) essid;
   w.u.data.length = IW_ESSID_MAX_SIZE;
   w.u.data.flags = 0;

   ioctl (fd, SIOCGIWESSID, &w);
   close (fd);

   return strdup (essid);
}

int
main (int argc, char *argv[])
{
  char *essid = NULL;

  printf ("ESSID: %s\n", (essid = get_essid ("wlan0")));
  free (essid); // Remember you have to free the memory.... or change get_essid implementation :)

  return 0;
}
