#include <stdio.h>
#include <sys/types.h>
#include <stdlib.h>
#include <fcntl.h>
#include <sys/file.h>
#include <sys/stat.h>
#include <unistd.h>

#include "pppd.h"
#include "syncppp.h"

int syncppp(void)
{
    int fd; 
    int fdlock;
    npppvaltype buf;

    /* open the npppfile, lock the file, read, increment, and write */
    if ((fd = open(npppfilename,O_RDWR)) < 0) {
        error("npppfile open error");
        return -1;
    }   

    if (flock(fd, LOCK_EX) < 0) {
        error("lock npppfile error");
        return -1;
    }
    if (read(fd, &buf, sizeof(buf)) < 0) {
        error("npppfile read error");
        return -1;
    }
    buf++;
    lseek(fd, 0, SEEK_SET);
    if (write(fd, &buf, sizeof(buf)) != 1) {
        error("npppfile write error");
        return -1;
    }

    if (flock(fd, LOCK_UN) < 0) {
        error("npppfile unlock error");
        return -1;
    }

    /* try to lock the lockfile */
    if ((fdlock = open(lockfilename, O_RDWR)) < 0) {
        error("lockfile open error");
        return -1;
    }
    flock(fdlock, LOCK_SH);

    close(fd);
    close(fdlock);

    return 0;
}

