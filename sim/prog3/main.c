int main(void){
  extern int div1; //source
  extern int div2; //source
  extern int _test_start;   //destination
  
  while(div1 != 0 && div2 != 0){
    if(div1 > div2)
      div1 = div1 % div2;
    else
      div2 = div2 % div1;
  }
  *(&_test_start) = div1 ^ div2;
}