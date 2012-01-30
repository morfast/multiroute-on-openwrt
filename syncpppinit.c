#include<stdio.h>
#include<sys/types.h>
#include<sys/shm.h>
#include<sys/ipc.h>
#include<stdlib.h>
#include <semaphore.h>
#include <fcntl.h>
#include <sys/file.h>
#include <sys/stat.h>
#include<unistd.h>
#include "syncppp.h"

int openlockfile()
{
    int fdlock;

    if ((fdlock = creat(lockfilename, 0644)) < 0) {
        perror("fdlock open error");
        exit(1);
    }
    return fdlock;
}

void lockfile(int fdlock)
{
    if (flock(fdlock, LOCK_EX) < 0) {
        perror("flock lock error");
        exit(1);
    }    
    fprintf(stderr,"syncpppinit: locked\n");
}

void unlockfile(int fdlock)
{
    if (flock(fdlock, LOCK_UN) < 0) {
        perror("flock unlock error");
        exit(1);
    }
}


int main(int argc, char *argv[])
{
    int shm_id;
    int ppp_num;
    int fdlock;
    sem_t *p_sem;
    key_t key;
    struct semaphores *semphs;

    if (argc != 2) {
        fprintf(stderr, "Usage: %s <number of pppd>\n", argv[0]);
        exit(1);
    }
    
    ppp_num = atoi(argv[1]);
    if (ppp_num > MAX_PPP_NUM || ppp_num <= 0) {
        fprintf(stderr, "Number of pppd beyoung limit\n");
        exit(1);
    }

    /* create a uniqe key */
    creat(keyfilename, 0755);
    key = ftok(keyfilename, 4);
    if (key < 0) {
        perror("key error\n");
        exit(1);
    }

    //printf("the key is: %x\n", key);

    shm_id = shmget(key, sizeof(struct semaphores), IPC_CREAT | IPC_EXCL | 0644);
    if (shm_id < 0) {
        /* exist */
        shm_id = shmget(key, 1, 0644);
    }

    //printf("shm id: %u\n", shm_id);

    if ( (void *)(semphs = shmat(shm_id, 0, 0)) == (void *)-1) {
        perror("shmat error");
        exit(1);
    }

    sem_init(&(semphs->count), 1, 0); /* shared between processes, init 0 */
    fdlock = openlockfile();
    lockfile(fdlock);

    while (ppp_num > 0) {
        sem_wait(&(semphs->count));
        fprintf(stderr,"%d ",ppp_num);
        ppp_num--;
    }
    unlockfile(fdlock);
    fprintf(stderr,"\nsyncpppinit: unlocked\n");

    return 0;
}
