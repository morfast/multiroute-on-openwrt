#include<stdio.h>
#include<sys/types.h>
#include<sys/shm.h>
#include<sys/ipc.h>
#include<stdlib.h>
#include<semaphore.h>
#include <fcntl.h>
#include <sys/file.h>
#include"syncppp.h"
#include <sys/stat.h>
#include<unistd.h>

void syncppp(void)
{
    int shm_id;
    key_t key;
    int fdlock;
    struct semaphores *semphs;

    key = ftok(keyfilename, 4);

    if (key < 0) {
        perror("key error\n");
        exit(1);
    }

    //printf("the key is: %x\n", key);

    shm_id = shmget(key, 1, 0644);
    if (shm_id < 0) {
        perror("shmget");
        exit(1);
    }
    //printf("shm id: %u\n", shm_id);

    if ( (void *)(semphs = shmat(shm_id, 0, 0)) == (void *)-1) {
        perror("shmat error");
        exit(1);
    }

    sem_post(&(semphs->count));
    shmdt(semphs);

    if ((fdlock = open(lockfilename,O_RDONLY, 0644)) < 0) {
        perror("lockfile open error");
        exit(1);
    }

    flock(fdlock,LOCK_SH);

    close(fdlock);

}
