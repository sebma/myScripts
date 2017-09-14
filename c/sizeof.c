#include <stdio.h>
#include <stdint.h> //uint8_t, etc...

int len_int(int *x) {
//	printf("=> __func__ = %s\n", __func__ );
	return (int)(sizeof(x) / sizeof(int));
}

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

	int a[15];

	printf("=> sizeof(a) = %lu\n", sizeof(a));

	printf("=> sizeof(a)/sizeof(int) = %lu\n", sizeof(a)/sizeof(int));

	printf("=> len_int = %d\n", len_int(a));

//  printf("Hit enter to exit.\n");
//  char *scannedText;
//  scanf("%s", scannedText);

	return 0;

}
