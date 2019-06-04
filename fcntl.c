#include<stdio.h>
#include<unistd.h>
#include<errno.h>
#include<fcntl.h>
#include<stdlib.h>
#include <sys/stat.h>

#define SERVFIFO "/Users/alex/.locking/ql/locks/a/fifo.lock"
#define FILE_MODE (S_IRUSR | S_IWUSR | S_IRGRP | S_IROTH)

void syserr(const char *str){
    perror(str);
    exit(1);
}

int main(int argc, char** argv){

    umask(0);

//    if (mkfifo(SERVFIFO, FILE_MODE) < 0 && errno != EEXIST){
//      syserr("mkfifo");
//    }

    // try to open for write with no readers

    int fdw = open(SERVFIFO, O_WRONLY | O_NONBLOCK);

    if (fdw == -1){
      syserr("non-blocking open for write with no readers failed");
    }

    // create a reader - the process itself - non-blocking

    int fdr = open(SERVFIFO, O_RDONLY | O_NONBLOCK);
    if (fdr == -1){
      syserr("non-blocking open for read no writers failed");
    }

    // try again to open for write but this time with a reader
    fdw = open(SERVFIFO, O_WRONLY | O_NONBLOCK);

    if (fdw == -1){
      syserr("non-blocking open with readers failed");
    }


    printf("non-blocking open for write succeeded\n");

    close(fdw);
    close(fdr);
//    unlink(SERVFIFO);
}