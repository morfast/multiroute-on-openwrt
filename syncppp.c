#include <stdio.h>
#include <sys/types.h>
#include <sys/shm.h>
#include <sys/ipc.h>
#include <stdlib.h>
#include <semaphore.h>
#include <fcntl.h>
#include <sys/file.h>
#include "pppd.h"
#include "syncppp.h"
#include <sys/stat.h>
#include <unistd.h>

int syncppp(void)
{
    int shm_id;
    key_t key;
    int fdlock;
    struct semaphores *semphs;

    if ((key = ftok(keyfilename, PROJ_ID)) == -1) {
        error("ftok key error");
        return -1;
    }

    if ((shm_id = shmget(key, 1, 0644)) < 0) {
        error("shmget error");
        return -1;
    }

    if ( (void *)(semphs = shmat(shm_id, 0, 0)) == (void *)-1) {
        error("shmat error");
        return -1;
    }

    if ((sem_post(&(semphs->count))) < 0) {
        error("sem_post error");
        return -1;
    }

    shmdt(semphs);

    if ((fdlock = open(lockfilename,O_RDONLY, 0644)) < 0) {
        error("lockfile open error");
        return -1;
    }

    if (flock(fdlock,LOCK_SH) < 0) {
        error("flock error");
        return -1;
    }
    close(fdlock);

    return 0;

}
