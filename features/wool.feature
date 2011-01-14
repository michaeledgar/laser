Feature: Find Warnings
  In order to clean code
  A user should be able to
  scan for warnings

  Scenario: Scan Single File
    Given the following inputs and outputs:
      | input     | output  |
      | 1_input   | 1       |
      | 2_input   | 4       |
      | 3_input   | 6       |
      | 4_input   | 3       |
      | 5_input   | 4       |
    When I scan for warnings
    Then the input and output tables should match

  Scenario: Scan-n-fix Single File
    Given the following inputs and outputs:
      | input     | output   |
      | 1_input   | 1_output |
      | 2_input   | 2_output |
      | 3_input   | 3_output |
      | 4_input   | 4_output |
    When I scan-and-fix warnings
    Then the input and output tables should match
