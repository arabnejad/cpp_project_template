#include "calculator.h"

int main() {
  const Calculator calculator;
  return calculator.add(20, 22) == 42 ? 0 : 1;
}
