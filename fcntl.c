#include<stdio.h>
#include<unistd.h>
#include<errno.h>
#include<fcntl.h>
#include<stdlib.h>
#include <sys/stat.h>

#define FILE_MODE (S_IRUSR | S_IWUSR | S_IRGRP | S_IROTH)

void syserr(const char *str){
//    perror(str);
    exit(1);
}

int main(int argc, char** argv){

    umask(0);

    // try to open for write with no readers
    char * fifo =  argv[1];

    if (!fifo){
      syserr("You must pass fifo path as the first arg.");
    }

    int fdw = open(fifo, O_WRONLY | O_NONBLOCK);

    if (fdw == -1){
      syserr("non-blocking open for write with no readers failed");
    }

    // create a reader - the process itself - non-blocking

    int fdr = open(fifo, O_RDONLY | O_NONBLOCK);

    if (fdr == -1){
      syserr("non-blocking open for read no writers failed");
    }

    // try again to open for write but this time with a reader
    fdw = open(fifo, O_WRONLY | O_NONBLOCK);

    if (fdw == -1){
      syserr("non-blocking open with readers failed");
    }

//    printf("non-blocking open for write succeeded\n");

    close(fdw);
    close(fdr);

}