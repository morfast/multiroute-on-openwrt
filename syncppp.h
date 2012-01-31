#include<semaphore.h>

#define MAX_PPP_NUM 30
#define PROJ_ID 225
#define keyfilename "/tmp/pppkeyfile"
#define lockfilename "/tmp/ppplockfile"

int syncppp(void);

struct semaphores {
    sem_t count;  /* count the pppd processes which has recieved the challenge */
};

