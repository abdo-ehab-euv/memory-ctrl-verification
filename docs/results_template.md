# Results Template

> Copy this file when recording a run. Fill in the brackets.

## Run Metadata

| Field      | Value                                       |
| ---------- | ------------------------------------------- |
| Date/time  | `<YYYY-MM-DD HH:MM>`                       |
| Simulator  | `<Questa 2023.x / ModelSim Intel Starter>`  |
| Host OS    | `<Windows 11 / Ubuntu 22.04 / ...>`        |
| Git SHA    | `<commit hash>`                             |
| Flow       | `<simple / uvm-clean / uvm-bug>`           |
| Seed       | `<value or "default">`                      |

## Test Summary

| Metric        | Value      |
| ------------- | ---------- |
| Total checks  | `<N>`      |
| Passed        | `<N>`      |
| Failed        | `<N>`      |
| Pass rate     | `<NN.N%>`  |
| UVM\_ERROR    | `<N>`      |
| UVM\_FATAL    | `<N>`      |

## Coverage

| Coverpoint          | Coverage   |
| ------------------- | ---------- |
| Address             | `<NN.N%>`  |
| Operation           | `<NN.N%>`  |
| Data class          | `<NN.N%>`  |
| Cross addr × op     | `<NN.N%>`  |
| Address transitions | `<NN.N%>`  |
| **Overall**         | `<NN.N%>`  |

## Failing Checks

| #  | Test name | Expected | Actual | Notes |
| -- | --------- | -------- | ------ | ----- |
| 1  |           |          |        |       |

## Notes / Observations

- `<free-form text — e.g. "buggy DUT failed at addr 7 as expected, T1–T5 directed all PASS">`