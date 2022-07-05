# hdl4nn-tutorial
This repository will soon contain Verilog code and documents for firmware implementations of RPC trigger algorithms using Hardware Description Language (HDL), as discussed in [EPJC volume 82, 576 (2022) ](https://link.springer.com/article/10.1140/epjc/s10052-022-10521-8).

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://github.com/rustemos/hdl4nn/blob/34b17b0d44bb2de3cf85fb743afeeff594d9d86b/LICENSE)

# Dependencies
These macros require vivado 2019.2

# Getting Started
Those Verilog documents constitute a neural network: three fully connected hidden layers with 20 nodes in each layer.

## Top module: trigger.v
This module is the top-level module, it utilizes the Component instantiation to incorporate all submodules(hidden layers) into a neuron network.

## IP core:
Distributed Memory Generator(8.0) was used as a cache for weights.
----------
Adder/Substrater(12.0) was used as a DSP adder in Output Block in each hidden layer.

## Time frequency: 400 MHz
Set by constrain file.
