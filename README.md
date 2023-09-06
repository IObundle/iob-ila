# Integrated Logic Analyzer #

## What is this repository for? ##

The IObundle Integrated Logic Analyzer (ILA) is a RISC-V-based Peripheral. It is
written in Verilog and includes a C software driver. It allows the sampling
of any signal from the system and provides an interface that allows a RISC-V
processor to access the sampled values.
It optionally contains an internal Monitor, based on the [IOb-PFSM core](https://github.com/IObundle/iob-pfsm).
It also provides a [Direct Memory Access (DMA)](#direct-memory-access-(dma)) interface using an AXI4-Stream interface.

## Integrate in SoC ##

* Check out [IOb-SoC-SUT](https://github.com/IObundle/iob-soc-sut)

## Usage

The ILA submodule uses hierarchical references to probe signals inside other Verilog modules. This is supported by most tools, including Icarus Verilog, Verilator, and Vivado. However, some tools, like Quartus, do not support hierarchical references, therefore cannot synthesize this peripheral. 

The main class that describes this core is located in the `iob_ila.py` Python module. It contains a set of methods useful to set up and instantiate this core.

The `iob_ila.generate_system_wires(...)` method (example below) is used to configure the signals, triggers, and clock of each ILA instance. This method will generate the necessary Verilog wires in the Verilog source file provided. It will also generate a software header for the provided instance, with the format `<instance_name>.h`, with useful driver macros. It also adds the data format of the current instance to the `ilaInstanceFormats.py` Python library of the build directory.

The following steps describe the process of creating an ILA peripheral in an IOb-SoC-based system:
1) Import the `iob_ila` class
2) Add the `iob_ila` class to the submodules list. This will copy the required sources of this module to the build directory.
3) Run the `iob_ila(...)` constructor to create a Verilog instance of the ILA peripheral.
    1) Optionally, set the `MONITOR` Verilog parameter to `1` to enable the internal Monitor, based on the IOb-PFSM.
4) To use this core as a peripheral of an IOb-SoC-based system:
    1) Add the created instance to the peripherals list of the IOb-SoC-based system.
    2) Call the `iob_ila.generate_system_wires(...)` method to generate and insert the probe wires inside the ILA source file.
    3) Use the `_setup_portmap()` method of IOb-SoC to map IOs of the ILA peripheral to the internal system wires.
    4) Write the firmware to run in the system, including the `iob-ila.h` C header, and use its driver functions to control this core.

To export the sampled data and convert it to a VCD file, do:
1) Call the `ila_output_data(...)` driver function to export the data.
2) Place the data in a file. If using an IOb-SoC-based system, you can use the `uart_sendfile(...)` UART function to transfer the data to a file.
3) Convert that data file to a VCD file using the `scripts/ilaDataToVCD.py` Python script located in the build directory.
4) Open the converted VCD file with a wave viewer, such as `gtkwave`.

## Internal Monitor 

The optional internal Monitor is an IOb-PFSM core programmed with a specialized bitstream to check for signal conditions and timings, and can also control the ILA.

To generate and load the bitstream to the monitor, follow the same steps as described in the [IOb-PFSM](https://github.com/IObundle/iob-pfsm) repository.

The Monitor software registers are integrated with the ILA address space.
To obtain the Monitor base address for use with the IOb-PFSM drivers, use the `ila_get_monitor_base_addr()` driver function.

## Example configuration

The `iob_soc_tester.py` script of the [IOb-SoC-SUT](https://github.com/IObundle/iob-soc-sut) system, uses the following lines of code to instantiate an ILA peripheral with the instance name `ILA0`:
```Python
# Import the iob_ila class
from iob_ila import iob_ila

# Class of the Tester system
class iob_soc_tester(iob_soc):
  ...
  @classmethod
  def _create_submodules_list(cls):
      """Create submodules list with dependencies of this module"""
      super()._create_submodules_list(
          [
              iob_ila,
              ...
          ]
      )
  # Method that runs the setup process of the Tester system
  @classmethod
  def _specific_setup(cls):
    ...
    # Create a Verilog instance of this module, named 'ILA0', and add it to the peripherals list of the system.
    cls.peripherals.append(
        iob_ila(
            "ILA0", # Verilog instance name
            "Tester Integrated Logic Analyzer for SUT signals", # Instance description

            # Verilog parameters to pass to this instance.
            parameters={
                # Configure the ILA buffer to hold 2^4=16 samples
                "BUFFER_W": "4",
                # Sample a 32-bit signal, a 5-bit signal, and a 1-bit signal (38 bits total).
                "SIGNAL_W": "38",
                # Use a 1-bit trigger.
                "TRIGGER_W": "1",
                # Enable the internal clock counter.
                "CLK_COUNTER": "1",
                # Enable the internal Monitor based on the IOb-PFSM.
                "MONITOR": "1",
                # Configure the Monitor PFSM with 2^2=4 states
                "MONITOR_STATE_W": "2",
            },
        )
    ...

    # Generate Verilog wires to probe signals (they are internal to the Tester system)
    iob_ila.generate_system_wires(
        cls.ila0_instance, # ILA instance object
        "hardware/src/iob_soc_tester.v",  # Name of the system file to generate the probe wires
        sampling_clk="clk_i",  # Name of the internal system signal to use as the sampling clock

        # List of signals to use as triggers (using hierarchical referencing).
        trigger_list=[
            "SUT0.AXISTREAMIN0.tvalid_i"
        ],

        # List of signals to probe (using hierarchical referencing). Each list entry has the signal name and width.
        probe_list=[
            ("SUT0.AXISTREAMIN0.tdata_i", 32),
            ("SUT0.AXISTREAMIN0.fifo.level_o", 5),
            ("PFSM0.output_ports", 1),
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

## Direct Memory Access (DMA)

This peripheral provides a DMA interface using AXI4-Stream.

* Check out [IOb-DMA](https://github.com/IObundle/iob-dma) for more details.

The `iob_soc_tester.py` script of the [IOb-SoC-SUT](https://github.com/IObundle/iob-soc-sut) system, provides examples of an ILA peripheral configured to use the DMA interface.

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

void ila_set_circular_buffer(int value); // Enable/Disable circular buffer

// If CIRCULAR_BUFFER=0: Returns the number of samples currently stored in the ila buffer
// If CIRCULAR_BUFFER=1: Returns the index of the last sample stored in the ila buffer
int n_samples = ila_number_samples();

int buffer_size = ila_output_data_size(samples, data_words_per_sample); // How much memory is needed to dump all the signals registered by ILA
// The `data_words_per_sample` argument is the number of register words required for each sample. This value is auto-generated for each ILA instance in the respective `<instance_name>.h` header file.

// Output ila data to later be transformed into a vcd file (need to generate source from format file, otherwise linker error)
int n_samples = ila_output_data(char* buffer, int start, int end, int buffer_size, int ila_dword_size);

// Returns Monitor base address based on ILA base address.
// The base address returned is used to initialize the internal Monitor driver functions.
uint32_t MONITOR_BASE = ila_get_monitor_base_addr(int base_address);

// Since the internal Monitor is an IOb-PFSM core, then their driver functions are the same.
// Check out the IOb-PFSM repository for more information on the Monitor drivers: https://github.com/IObundle/iob-pfsm
```
