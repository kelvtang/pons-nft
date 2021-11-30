# Cadence Tests

This directory contains tests for the Pons NFT marketplace.

## Test Structure

Tests are arranged in a tree of directories, and every leaf directory represents a particular test. Within each test directory, Cadence transactions and scripts define the test.

Each test directory consists of a sequence of test files, named `1.verification.cdc`, `2.verification.cdc`, `3.verification.cdc`, and so on. These respectively define the first step of the test, the second step of the test, and so on, sequentially executed.  Each `n.verification.cdc` file is a Cadence script, which returns a value of type `{String: AnyStruct}`. The returned Dictionary must have a key `"verified"` of type `Bool`, and the value denotes the success value of the test. The other keys in the Dictionary define auxiliary data that is useful for the tester.

For each sequential step `n.verification.cdc`, an optional Cadence file `n.transaction.cdc` may be provided. Each `n.transaction.cdc` is a Cadence transaction, executed before `n.verification.cdc`. Transactions in `n.transaction.cdc` may perform actions to be verified by `n.verification.cdc`. The transaction, if present, can either succeed or fail, and its result will be passed to the verification script as an argument. Failure of a transaction may not indicate failure of a test; oftentimes, tests include transactions expected to fail, its result being checked in the verification script, with the test passing only when the transaction fails in the expected manner.

## Test Framework and Parameters

Tests are executed from Javascript, and helpful testing behaviour is provided by the TestUtils contract, at `testing-contracts/TestUtils.cdc`. The file `utils/flow.mjs` provides a function `run_known_test_from_ ()`, which allows the caller to run individual test folders, by providing the location of the test folder, a list of signers, and a list of Cadence arguments. Examples for usage of `run_known_test_from_ ()` can be found in `run-tests.mjs`. Account details used for provided signers is identical to those provided in `config.mjs`.

Signers and arguments are provided to test transactions and scripts in several ways. Primarily, the arguments provided to test transactions and scripts are those passed into the test from Javascript, via `run_known_test_from_ ()`. These arguments are provided to every transaction and verification script in the test, and all signers are provided to all transactions in the test as well.

Additionally, transactions and scripts receive arguments indicating the result of the most recently executed transaction. These arguments include:
- `transactionSuccess : Bool` indicating whether the transaction completed successfully, or if it failed and reverted
- `transactionErrorMessage : String?` indicating the error message of the transaction failure, if any
- `transactionEvents : [{String: String}]` indicating all the events that were emitted during the transaction

If no transaction has been executed before a certain transaction or script, these arguments are not provided.

Lastly, a `testInfo : {String: String}` argument is provided for any additional state. If certain data remains useful throughout multiple steps of tests, transactions may call the `testInfo ()` function (from the TestUtils contract) with two parameters, indicating a key and a value, and thereafter this key-value pair will be provided in the final argument to every transaction and script. Before `testInfo ()` is first called, this argument is not provided.

## Test Output Format

Running the tests produce output in TAP protocol format, which can be prettified with formatters such as `npx tap-spec`. For each step of a test, the success value of test is outputted together with auxiliary data, including the `{String: AnyStruct}` dictionary returned by verification scripts, and the results of transactions.

All events are also individually logged as TAP comments. If an event is the result of `testInfo ()` from TestUtils, it is logged as '[key]=value'. If it is the result of `log ()` from TestUtils, the log text is outputted as a verbatim TAP comment. Otherwise, the event is logged as '(EventContract.EventType); { "event data": "json" }'.
