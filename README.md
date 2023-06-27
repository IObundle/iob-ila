# Integrated Logic Analyzer #

## What is this repository for? ##

The IObundle Integrated Logic Analyzer (ILA) is a RISC-V-based Peripheral. It is
written in Verilog and includes a C software driver. It allows the sampling
of any signal from the system and provides an interface that allows a RISC-V
processor to access the sampled values.

## Integrate in SoC ##

* Check out [IOb-SoC-SUT](https://github.com/IObundle/iob-soc-sut)

## Usage

The ILA submodule uses hierarchical references to probe signals inside other Verilog modules. This is supported by most tools, including Icarus Verilog, Verilator, and Vivado. However, some tools, like Quartus, do not support hierarchical references, therefore cannot synthesize this peripheral. 

The main class that describes this core is located in the `iob_ila.py` Python module. It contains a set of methods useful to set up and instantiate this core.

The `iob_ila.generate_system_wires(...)` method (example below) is used to configure the signals, triggers and clock of each ILA instance. This method will generate the necessary Verilog wires in the Verilog source file provided. It will also generate a software header for the provided instance, with the format `<instance_name>.h`, with useful driver macros. It also adds the data format of the current instance to the `ilaInstanceFormats.py` Python library of the build directory.

The following steps describe the process of creating an ILA peripheral in an IOb-SoC-based system:
1) Import the `iob_ila` class
2) Run the `iob_ila.setup()` method to copy the required sources of this module to the build directory.
3) Run the `iob_ila.instance(...)` method to create a Verilog instance of the ILA peripheral.
4) Use this core as a peripheral of an IOb-SoC-based system:
    1) Add the created instance to the peripherals list of the IOb-SoC-based system.
    2) Call the `_run_setup()` method of IOb-SoC to create the system Verilog source in the build directory.
    3) Call the `iob_ila.generate_system_wires(...)` method to generate and insert the probe wires inside the ILA source file.
    4) Use the `_setup_portmap()` method of IOb-SoC to map IOs of the ILA peripheral to the internal system wires.
    5) Write the firmware to run in the system, including the `iob-ila.h` C header and use its driver functions to control this core.

To export the sampled data and convert it to a VCD file, do:
1) Call the `ila_output_data(...)` driver function to export the data.
2) Place the data in a file. If using an IOb-SoC-based system, you can use the `uart_sendfile(...)` UART function to transfer the data to a file.
3) Convert that data file to a VCD file using the `scripts/ilaDataToVCD.py` Python script located in the build directory.
4) Open the converted VCD file with a wave viewer, such as `gtkwave`.

## Example configuration

The `iob_soc_tester.py` script of the [IOb-SoC-SUT](https://github.com/IObundle/iob-soc-sut) system, uses the following lines of code to instantiate an ILA peripheral with the instance name `ILA0`:
```Python
# Import the iob_ila class
from iob_ila import iob_ila

# Class of the Tester system
class iob_soc_tester(iob_soc):
  ...
  # Method that runs the setup process of the Tester system
  @classmethod
  def _run_setup(cls):
    ...
    # Setup the ILA module (Copies every file and dependency required to the build directory)
    iob_ila.setup()
    ...
    # Create a Verilog instance of this module, named 'ILA0', and add it to the peripherals list of the system.
    cls.peripherals.append(
        iob_ila.instance(
            "ILA0", # Verilog instance name
            "Tester Integrated Logic Analyzer for SUT signals", # Instance description

            # Verilog parameters to pass to this instance.
            # In this example, we sample a 32-bit signal and a 5-bit signal (37 bits total).
            # In this example, we use a 1-bit trigger.
            parameters={"SIGNAL_W": "37", "TRIGGER_W": "1"},
        )
    )
    ...
    # Run IOb-SoC setup (will also copy the Tester sources)
    super()._run_setup()
    ...

    # Generate Verilog wires to probe signals (they are internal to the Tester system)
    iob_ila.generate_system_wires(
        "hardware/src/iob_soc_tester.v",  # Name of the system file to generate the probe wires
        "ILA0",  # Name of the ILA peripheral instance to connect the wires
        sampling_clk="clk_i",  # Name of the internal system signal to use as the sampling clock

        # List of signals to use as triggers (using hierarchical referencing).
        trigger_list=[
            "SUT0.AXISTREAMIN0.tvalid_i"
        ],

        # List of signals to probe (using hierarchical referencing). Each list entry has the signal name and width.
        probe_list=[
            ("SUT0.AXISTREAMIN0.tdata_i", 32),
            ("SUT0.AXISTREAMIN0.fifo.level_o", 5),
        ],
    )
  ...
  # Tester system method to map IOs of peripherals
  @classmethod
  def _setup_portmap(cls):
      super()._setup_portmap()
      cls.peripheral_portmap += [
          ...
          # ILA IO --- Connect IOs of Integrated Logic Analyzer to internal system signals
          (
              {
                  "corename": "ILA0",
                  "if_name": "ila",
                  "port": "signal",
                  "bits": [],
              },
              {
                  "corename": "internal",
                  "if_name": "ILA0",
                  "port": "",
                  "bits": [],
              },
          ),
          (
              {
                  "corename": "ILA0",
                  "if_name": "ila",
                  "port": "trigger",
                  "bits": [],
              },
              {
                  "corename": "internal",
                  "if_name": "ILA0",
                  "port": "",
                  "bits": [],
              },
          ),
          (
              {
                  "corename": "ILA0",
                  "if_name": "ila",
                  "port": "sampling_clk",
                  "bits": [],
              },
              {
                  "corename": "internal",
                  "if_name": "ILA0",
                  "port": "",
                  "bits": [],
              },
          ),
      ]

```

## Brief description of C interface ##

The ILA works by storing the values of the signals when the triggers are asserted according to configuration.

An example of some C code is given, with explanations:

```C
ila_init(ILA_BASE); // Initializes the ILA module

ila_set_reduce_type(ILA_REDUCE_TYPE_OR); // ILA only stores signals if ANY trigger is asserted

ila_set_time_offset(0); // Store the signal in the same cycle as the trigger being asserted (other valid options are -1 (store the value in the previous cycle) and 1 (store the value in the next cycle)

ila_set_different_signal_storing(TRUE); // Only store signals if they are different from the previous signals stored (even if triggers are asserted)

ila_set_trigger_type(0,ILA_TRIGGER_TYPE_CONTINUOUS); // Sets the trigger 0 to continuous (after the trigger signal is asserted, the trigger remains active even if the signal de-asserts, use ila_reset() to disable continuous triggers)

ila_set_trigger_negated(0,TRUE); // The trigger 0 is asserted if the signal goes from one to zero (if continuous) or if the signal is zero (if single)

ila_set_trigger_enabled(0,TRUE); // Enables the trigger 0 (the first $trigger in the format file) (recommended to configure the trigger fully before enabling it)

// Code that is to be profiled

int samples = ila_number_samples(); // How many samples ILA as registered

int buffer_size = ila_output_data_size(samples, data_words_per_sample); // How much memory is needed to dump all the signals registered by ILA
// The `data_words_per_sample` argument is the number of register words required for each sample. This value is auto-generated for each ILA instance in the respective `<instance_name>.h` header file.

ila_output_data(buffer, start_sample_num, end_sample_num, data_words_per_sample); // Dumps samples the amount of signal information for a buffer of minimum size buffer_size (text format, dump to a file so ILA can generate VCD file)
```
