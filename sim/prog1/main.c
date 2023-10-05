int main(void){
  extern int array_size;
  extern int array_addr; //source
  extern int _test_start;//destination
  // bubble sort
  int tmp;
	for(int i = 0; i < array_size-1; i++) {
		for(int j = i + 1; j < array_size; j++) {
			if( *(&array_addr + i) > *(&array_addr + j) ) {
				tmp = *(&array_addr + i);
				*(&array_addr + i) = *(&array_addr + j);
				*(&array_addr + j) = tmp;
			}
		}
	}
  // copy array
  for(int i=0;i<array_size;i++){
    *(&_test_start + i) = *(&array_addr + i);
  }
  return 0;
}