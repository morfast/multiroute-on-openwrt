#include <stdio.h>
#include <sys/file.h>
#include <sys/types.h>
#include <sys/stat.h>
#include <fcntl.h>
#include <stdlib.h>
#include <unistd.h>

#include "syncppp.h"

int main(int argc, char *argv[])
{
    int fd;
    int fdlock;
    int nppp = 0;
    int oldnppp = 0;
    npppvaltype buf;

    if (argc != 2) {
        fprintf(stderr, "Usage: %s <number of pppd>\n", argv[0]);
        exit(1);
    }

    /* read number of pppd from cmdline, check the range */
    nppp = atoi(argv[1]);
    if (nppp <=0 || nppp > MAX_PPP_NUM) {
        fprintf(stderr, "number of pppd should be >= 0 and <= %d\n", MAX_PPP_NUM);
        exit(1);
    }

    /* lockfile: create, lock */
    if ((fdlock = creat(lockfilename, 0644)) < 0) {
        perror("lockfile creat error");
        exit(1);
    }
    if (flock(fdlock, LOCK_EX) < 0) {
        fprintf(stderr, "lock error\n");
        exit(1);
    } else {
        fprintf(stderr, "lock success\n");
    }

    /* npppfile: create, write a 0 */
    if ((fd = creat(npppfilename, 0644)) < 0) {
        perror("npppfile creat error");
        exit(1);
    }
    buf = 0;
    if (write(fd, &buf, sizeof(buf)) != 1) {
        perror("npppfile write error");
        exit(1);
    }
    close(fd);
    if ((fd = open(npppfilename,O_RDONLY)) < 0) {
        perror("npppfile open error");
        exit(1);
    }   


    /* spin lock: check npppfile */
    while (1) {
        if (lseek(fd, 0, SEEK_SET) < 0) {
            perror("lseek");
            exit(1);
        }
        if (read(fd, &buf, sizeof(buf)) < 0) {
            fprintf(stderr, "read error\n");
            exit(1);
        }
        if ((int)buf >= nppp) {
            fprintf(stderr, "%d Challenges recieved, unlock the lockfile\n", nppp);
            break;
        } 
        if (oldnppp != (int)buf) {
            oldnppp = (int)buf;
            fprintf(stderr, "%d Challenges recieved, waiting for the left %d\n", oldnppp, nppp-oldnppp);
        }
    }

    /* unlock the lockfile */
    if (flock(fdlock, LOCK_UN) < 0) {
        fprintf(stderr, "unlock error\n");
    } else {
        fprintf(stderr, "unlock success\n");
    }

    return 0;
}
