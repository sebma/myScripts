#include <stdio.h>
#include <stdint.h> //uint8_t, etc...

int main (int argc, char **argv) {

  printf("sizeof(char):   %d bits\n", 8 * (int) sizeof(char));

  printf("sizeof(short): %d bits\n", 8 * (int) sizeof(short));

  printf("sizeof(int):   %d bits\n", 8 * (int) sizeof(int));

  printf("sizeof(long):  %d bits\n", 8 * (int) sizeof(long));

  printf("sizeof(void *):%d bits\n", 8 * (int) sizeof(void *));

  printf("sizeof(long long): %d bits\n", 8 * (int) sizeof(long long));

  printf("=> Standard types from stdint.h :\n");

  printf("sizeof(uint8_t): %d bits\n", 8 * (int) sizeof(uint8_t));

  printf("sizeof(int16_t): %d bits\n", 8 * (int) sizeof(int16_t));

  printf("sizeof(int32_t): %d bits\n", 8 * (int) sizeof(int32_t));

  printf("sizeof(int64_t): %d bits\n", 8 * (int) sizeof(int64_t));

//  printf("Hit enter to exit.\n");
//  char *scannedText;
//  scanf("%s", scannedText);

  return 0;

}
