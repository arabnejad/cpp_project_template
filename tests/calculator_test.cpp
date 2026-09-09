#include "calculator.h"

#include <limits>

#include <gtest/gtest.h>

class CalculatorTest : public ::testing::Test {
protected:
  // TEST_F uses this member through a GoogleTest-generated subclass.
  // cppcheck-suppress unusedStructMember
  Calculator calculator;
};

TEST_F(CalculatorTest, AddsPositiveNumbers) {
  EXPECT_EQ(calculator.add(1, 2), 3);
  EXPECT_EQ(calculator.add(10, 15), 25);
}

TEST_F(CalculatorTest, AddsNegativeNumbers) {
  EXPECT_EQ(calculator.add(-1, -2), -3);
  EXPECT_EQ(calculator.add(-10, 5), -5);
}

TEST_F(CalculatorTest, AddsWithZero) {
  EXPECT_EQ(calculator.add(0, 0), 0);
  EXPECT_EQ(calculator.add(0, 7), 7);
  EXPECT_EQ(calculator.add(9, 0), 9);
}

TEST_F(CalculatorTest, AddsAtIntegerBoundariesWithoutOverflow) {
  constexpr int minimum = std::numeric_limits<int>::min();
  constexpr int maximum = std::numeric_limits<int>::max();

  EXPECT_EQ(calculator.add(maximum, 0), maximum);
  EXPECT_EQ(calculator.add(minimum, 0), minimum);
  EXPECT_EQ(calculator.add(maximum, -1), maximum - 1);
  EXPECT_EQ(calculator.add(minimum, 1), minimum + 1);
}
