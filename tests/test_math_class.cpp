#include <gtest/gtest.h>
#include "app.h"

class MathClassTest : public ::testing::Test {
protected:
  // TEST_F uses this member through a GoogleTest-generated subclass.
  // cppcheck-suppress unusedStructMember
  MATH m;
};

TEST_F(MathClassTest, AddsPositiveNumbers) {
  EXPECT_EQ(m.add(1, 2), 3);
  EXPECT_EQ(m.add(10, 15), 25);
}

TEST_F(MathClassTest, AddsNegativeNumbers) {
  EXPECT_EQ(m.add(-1, -2), -3);
  EXPECT_EQ(m.add(-10, 5), -5);
}

TEST_F(MathClassTest, AddsWithZero) {
  EXPECT_EQ(m.add(0, 0), 0);
  EXPECT_EQ(m.add(0, 7), 7);
  EXPECT_EQ(m.add(9, 0), 9);
}
