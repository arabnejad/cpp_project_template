#include "calculator.h"

#include <iostream>

int main() {
  const Calculator calculator;
  const int        lhs    = 2;
  const int        rhs    = 3;
  const int        result = calculator.add(lhs, rhs);

  std::cout << "Sum of " << lhs << " and " << rhs << " is " << result << '\n';
  return 0;
}
