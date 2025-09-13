#include <iostream>
#include "app.h"

int main() {
  MATH m;
  int  a      = 2;
  int  b      = 3;
  int  result = m.add(a, b);
  std::cout << "Sum of " << a << " and " << b << " is " << result << std::endl;
  return 0;
}
