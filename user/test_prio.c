// #include "kernel/types.h"
// #include "user/user.h"

// int main(){
//   int pid = fork();

//   if(pid == 0){
//     setpriority(getpid(), 2);

//     for(int i = 0; i < 10; i++){
//       printf("HIGH priority process %d\n", getpid());
//       for(volatile int i = 0; i < 100000000; i++);
//     }
//   }
//   else{
//     setpriority(getpid(), 10);

//     for(int i = 0; i < 10; i++){
//       printf("LOW priority process %d\n", pid);
//       for(volatile int i = 0; i < 100000000; i++);
//     }
//   }

//   exit(0);
// }

#include "kernel/types.h"
#include "user/user.h"

int main(){
  for(int i = 1; i <= 20; i++){
    int pid = fork();

    if(pid == 0){
      // child process
      setpriority(getpid(), i);

        for(int j = 0; j < 5; j++){ 
          printatomic(getpid());
          for(volatile int i = 0; i < 10000; i++);
        }
      exit(0);
    }
  }

  // parent waits for all children
  for(int i = 0; i < 10; i++){
    wait(0);
  }

  exit(0);
}