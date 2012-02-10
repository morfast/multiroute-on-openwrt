#include<stdio.h>
#include<sys/file.h>
#include <sys/types.h>
#include <sys/stat.h>
#include <fcntl.h>
#include <stdlib.h>
#include<unistd.h>

int main(int argc, char *argv[])
{
    int fd;
    int fdlock;
    int nppp;
    char buf[1];
    char *lockfilename = "/tmp/ppplockfile";

    nppp = atoi(argv[1]);

    if (nppp <=0 || nppp > 30) {
        perror("nppp input error");
        exit(1);
    }

    fdlock = creat(lockfilename, 0644);
    fd = open("/tmp/ppp_sync",O_RDONLY);

    if (fd < 0 || fdlock < 0) {
        fprintf(stderr, "open error\n");
        exit(1);
    }

    if (flock(fdlock, LOCK_EX) < 0) {
        fprintf(stderr, "lock error\n");
    } else {
        fprintf(stderr, "lock success\n");
    }


    while (1) {
        lseek(fd, 0, SEEK_SET);
        if (read(fd, buf, 1) != 1) {
            fprintf(stderr, "read error\n");
            exit(1);
        }
        if (buf[0] >= nppp) {
            fprintf(stderr, "%d Challenges Recieved, unlock the lockfile\n", nppp);
            break;
        } 
    }

    if (flock(fdlock, LOCK_UN) < 0) {
        fprintf(stderr, "unlock error\n");
    } else {
        fprintf(stderr, "unlock success\n");
    }

    return 0;
}
