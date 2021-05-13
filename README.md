# Smart-Contract-Benchmark-Suites: A Unified Dataset
***Empirical Evaluation of Smart Contract Testing: What Is the Best Choice?***


## Overview
*DATASET:* The 46,186 contracts are available in `/dataset` folder.

*RESULTS:* The experimental results of each category are in `/experiments-config` folder.

*TOOLS:* nine representive tools for experiments are listed below:
* [Securify](https://github.com/eth-sri/securify) v1.0.0
* [SmartCheck](https://github.com/smartdec/smartcheck) v2.0.0
* [Slither](https://github.com/crytic/slither) v0.8.0
* [Oyente](https://github.com/enzymefinance/oyente) v0.2.0
* [Mythril](https://github.com/ConsenSys/mythril) v0.22.19
* [Osiris](https://github.com/christoftorres/Osiris) v0.0.1
* [ContractFuzzer](https://github.com/gongbell/ContractFuzzer) v1.0.0
* [sFuzz](https://github.com/duytai/sFuzz) v1.0.0
* [ILF](https://github.com/eth-sri/ilf) v1.0.0

:star: More information pleasr refer to our [paper]().


## Getting Started
Step1. Prepare the tools.

\> Follow the instructions on each tool's page or pull the images from Docker Hub.

Step2. Select some contracts as the test suite.

\> Use all or randomly select a subset of contracts from each category.

Step3. Run each tool with different settings.

\> Provide each tool with different runtime parameters, and count the execution results.



## Detailed Description
To make up for the lack of a unified test set, we construct a benchmark suite with contracts crawled from Etherscan, SolidiFI repository, Common Vulnerabilities and Exposures library and Smart Contract Weakness Classification and Test Cases library. They can be classified into three categories: 1) unlabeled real-world contracts; 2) contracts with manually injected bugs; 3) confirmed vulnerable contracts. We believe that the evaluation results will generalize due to the size and diversity of our benchmarks.

We also provide the statistical data of our experiments for reference.
