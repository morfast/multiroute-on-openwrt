#include<semaphore.h>

#define MAX_PPP_NUM 30

#define keyfilename "/tmp/pppkeyfile"

#define lockfilename "/tmp/ppplockfile"

void syncppp(void);

struct semaphores {
    sem_t count;  /* count the pppd processes which has recieved the challenge */
    //int ppp_num;  /* total number of pppd */
};

