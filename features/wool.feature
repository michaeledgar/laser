Feature: Find Warnings
  In order to clean code
  A user should be able to
  scan for warnings

  Scenario: Scan Single File
    Given the following inputs and outputs:
      | input     | output  |
      | 1_input   | 1       |
      | 2_input   | 3       |
    When I scan for warnings
    Then the input and output tables should match

  Scenario: Scan-n-fix Single File
    Given the following inputs and outputs:
      | input     | output   |
      | 1_input   | 1_output |
      | 2_input   | 2_output |
    When I scan-and-fix warnings
    Then the input and output tables should match
