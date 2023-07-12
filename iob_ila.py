#!/usr/bin/env python3

import os
import shutil

from iob_module import iob_module
import iob_colors
from ilaGenerateVerilog import generate_verilog_source
from ilaGenerateSource import generate_driver_source
from ilaBase import get_format_data
from iob_verilog_instance import iob_verilog_instance

# Submodules
from iob_lib import iob_lib
from iob_utils import iob_utils
from iob_reg_r import iob_reg_r
from iob_reg_re import iob_reg_re
from iob_ram_t2p import iob_ram_t2p


class iob_ila(iob_module):
    name = "iob_ila"
    version = "V0.10"
    flows = "sim emb doc"
    setup_dir = os.path.dirname(__file__)

    @classmethod
    def _specific_setup(cls):
        # Hardware headers & modules
        iob_module.generate("iob_s_port")
        iob_module.generate("iob_s_portmap")
        iob_lib.setup()
        iob_utils.setup()
        iob_module.generate("clk_en_rst_portmap")
        iob_module.generate("clk_en_rst_port")
        iob_reg_r.setup()
        iob_reg_re.setup()
        iob_ram_t2p.setup()

        # Verilog modules instances
        # TODO

        # Copy ilaDataToVCD script to the build directory
        os.makedirs(os.path.join(cls.build_dir,"scripts"), exist_ok=True)
        shutil.copy(os.path.join(cls.setup_dir,"scripts/ilaBase.py"), os.path.join(cls.build_dir,"scripts/"))
        shutil.copy(os.path.join(cls.setup_dir,"scripts/ilaDataToVCD.py"), os.path.join(cls.build_dir,"scripts/"))

    # Given an instance name and its corresponding format_data, store them in the `ilaInstanceFormats.py` library for usage with the `ilaDataToVCD.py` script.
    @classmethod
    def __add_format_to_library(cls, ila_instance_name, ila_format_data):
        # Create library if it does not exist
        if not os.path.isfile(os.path.join(cls.build_dir, "scripts/ilaInstanceFormats.py")):
            with open(os.path.join(cls.build_dir, "scripts/ilaInstanceFormats.py"), "w") as f:
                f.write("#!/usr/bin/env python3\n")
                f.write("# This script is a library of data formats for each iob-ila instance.\n")
            # Add execute permission
            os.chmod(os.path.join(cls.build_dir, "scripts/ilaInstanceFormats.py"), 0o755)

        # Add format of this intance to the file
        with open(os.path.join(cls.build_dir, "scripts/ilaInstanceFormats.py"), "a") as f:
            f.write(f"{ila_instance_name}={ila_format_data}\n")


    @classmethod
    def generate_system_wires(cls, ila_instance: iob_verilog_instance, system_source_file, sampling_clk, trigger_list, probe_list):
        # Make sure output file exists
        assert os.path.isfile(os.path.join(cls.build_dir, system_source_file)), f"{iob_colors.FAIL}ILA: Output file '{cls.build_dir}/{system_source_file}' not found!{iob_colors.ENDC}"

        # Connect sampling clock
        generated_verilog_code=f"// Auto-generated connections for {ila_instance.name}\n"
        generated_verilog_code+=f"assign {ila_instance.name}_sampling_clk = {sampling_clk};\n"

        # Generate verilog code for ILA connections
        generated_verilog_code += generate_verilog_source(ila_instance.name, get_format_data(trigger_list, probe_list))

        # Read system source file
        with open(f"{cls.build_dir}/{system_source_file}", "r") as system_source:
            lines = system_source.readlines()
        # Find `endmodule`
        for idx, line in enumerate(lines):
            if line.startswith("endmodule"):
                endmodule_index = idx - 1
                break
        else:
            raise Exception(f"{iob_colors.FAIL}ILA: Could not find 'endmodule' declaration in '{cls.build_dir}/{system_source_file}'!{iob_colors.ENDC}")

        # Insert ILA generated connections in the system source code
        for line in generated_verilog_code.splitlines(True):
            lines.insert(endmodule_index, "   "+line)
            endmodule_index += 1

        # Write new system source file with ILA connections
        with open(f"{cls.build_dir}/{system_source_file}", "w") as system_source:
            system_source.writelines(lines)

        # Add 'TOP.' prefix to every probe and trigger
        for i in range(len(probe_list)):
            probe_list[i] = ("TOP."+probe_list[i][0], probe_list[i][1])
        for i in range(len(trigger_list)):
            trigger_list[i] = "TOP."+trigger_list[i]

        # If the ILA instance has an internal sampling clock counter, add a probe for it in the probe_list
        if "CLK_COUNTER" in ila_instance.parameters and ila_instance.parameters["CLK_COUNTER"] == "1":
            if "CLK_COUNTER_W" in ila_instance.parameters:
                clk_width = ila_instance.parameters["CLK_COUNTER_W"]
            else:
                clk_width = next(i['val'] for i in cls.confs if i['name']=="CLK_COUNTER_W")
            # Insert sampling clock counter probe at the start of the list
            probe_list.insert(0, (f"TOP.{ila_instance.name}.sampling_clk_counter", int(clk_width)))

        # Add format data of this instance to the library
        cls.__add_format_to_library(ila_instance.name, get_format_data(trigger_list, probe_list))

        ## Generate driver source aswell
        cls.generate_driver_sources(ila_instance.name, trigger_list, probe_list)

    @classmethod
    def generate_driver_sources(cls, ila_instance_name, trigger_list, probe_list):
        # Generate ila_format_data from trigger_list and probe_list
        ila_format_data = get_format_data(trigger_list, probe_list)

        # Generate driver source file
        generate_driver_source(ila_instance_name, ila_format_data, os.path.join(cls.build_dir, "software/src/", f"{ila_instance_name}.h"))



    @classmethod
    def _setup_confs(cls):
        super()._setup_confs(
            [
                # Macros
                {
                    "name": "SINGLE_TYPE",
                    "type": "M",
                    "val": "0",
                    "min": "NA",
                    "max": "NA",
                    "descr": "Define value used to select trigger of type SINGLE.",
                },
                {
                    "name": "CONTINUOUS_TYPE",
                    "type": "M",
                    "val": "1",
                    "min": "NA",
                    "max": "NA",
                    "descr": "Define value used to select trigger of type CONTINUOUS.",
                },
                {
                    "name": "REDUCE_OR",
                    "type": "M",
                    "val": "0",
                    "min": "NA",
                    "max": "NA",
                    "descr": "Define value used to select the 'OR' logic between the triggers. It the value is different, it uses 'AND' logic.",
                },
                # Parameters
                {
                    "name": "ADDR_W",
                    "type": "P",
                    "val": "`IOB_ILA_SWREG_ADDR_W",
                    "min": "NA",
                    "max": "NA",
                    "descr": "Address bus width",
                },
                {
                    "name": "DATA_W",
                    "type": "P",
                    "val": "32",
                    "min": "NA",
                    "max": "NA",
                    "descr": "Data bus width",
                },
                # {
                #    "name": "WDATA_W",
                #    "type": "P",
                #    "val": "32",
                #    "min": "NA",
                #    "max": "NA",
                #    "descr": "",
                # },
                {
                    "name": "SIGNAL_W",
                    "type": "P",
                    "val": "32",
                    "min": "NA",
                    "max": "9999",
                    "descr": "Width of the sampler signal input",
                },
                {
                    "name": "BUFFER_W",
                    "type": "P",
                    "val": "16",
                    "min": "NA",
                    "max": "NA",
                    "descr": "Size of the buffer to store samples.",
                },
                {
                    "name": "TRIGGER_W",
                    "type": "P",
                    "val": "32",
                    "min": "NA",
                    "max": "9999",
                    "descr": "Width of the trigger input",
                },
                {
                    "name": "CLK_COUNTER",
                    "type": "P",
                    "val": "0",
                    "min": "0",
                    "max": "1",
                    "descr": "Select if ILA should contain an internal sampling clock counter. If enabled, will connect its value to the lsb CLK_COUNTER_W bits of the sample_data. Useful to obtain timestamps of samples.",
                },
                {
                    "name": "CLK_COUNTER_W",
                    "type": "P",
                    "val": "16",
                    "min": "NA",
                    "max": "NA",
                    "descr": "Width of the clock counter input",
                },
            ]
        )

    @classmethod
    def _setup_ios(cls):
        cls.ios += [
            {"name": "iob_s_port", "descr": "CPU native interface", "ports": []},
            {
                "name": "general",
                "descr": "GENERAL INTERFACE SIGNALS",
                "ports": [
                    {
                        "name": "clk_i",
                        "type": "I",
                        "n_bits": "1",
                        "descr": "System clock input",
                    },
                    {
                        "name": "arst_i",
                        "type": "I",
                        "n_bits": "1",
                        "descr": "System reset, asynchronous and active high",
                    },
                    {
                        "name": "cke_i",
                        "type": "I",
                        "n_bits": "1",
                        "descr": "System reset, asynchronous and active high",
                    },
                ],
            },
            {
                "name": "ila",
                "descr": "ILA specific interface",
                "ports": [
                    {
                        "name": "signal",
                        "type": "I",
                        "n_bits": "SIGNAL_W",
                        "descr": "",
                    },
                    {
                        "name": "trigger",
                        "type": "I",
                        "n_bits": "TRIGGER_W",
                        "descr": "",
                    },
                    {
                        "name": "sampling_clk",
                        "type": "I",
                        "n_bits": "1",
                        "descr": "",
                    },
                ],
            },
        ]

    @classmethod
    def _setup_regs(cls):
        cls.regs += [
            {
                "name": "misc",
                "descr": "Miscellaneous registers",
                "regs": [
                    {
                        "name": "MISCELLANEOUS",
                        "type": "W",
                        "n_bits": 32,
                        "rst_val": 0,
                        "addr": -1,
                        "log2n_items": 0,
                        "autologic": True,
                        "descr": "Set of bits to enable different features. Includes softreset and others",
                    },
                ],
            },
            {
                "name": "trigger",
                "descr": "Trigger configuration",
                "regs": [
                    {
                        "name": "TRIGGER_TYPE",
                        "type": "W",
                        "n_bits": 32,
                        "rst_val": 0,
                        "addr": -1,
                        "log2n_items": 0,
                        "autologic": True,
                        "descr": "Single or continuous",
                    },
                    {
                        "name": "TRIGGER_NEGATE",
                        "type": "W",
                        "n_bits": 32,
                        "rst_val": 0,
                        "addr": -1,
                        "log2n_items": 0,
                        "autologic": True,
                        "descr": "Software negate the trigger value",
                    },
                    {
                        "name": "TRIGGER_MASK",
                        "type": "W",
                        "n_bits": 32,
                        "rst_val": 0,
                        "addr": -1,
                        "log2n_items": 0,
                        "autologic": True,
                        "descr": "Bitmask used to enable or disable individual triggers (1 enables the trigger, 0 disables)",
                    },
                ],
            },
            {
                "name": "data_select",
                "descr": "Data selection (for reading)",
                "regs": [
                    {
                        "name": "INDEX",
                        "type": "W",
                        "n_bits": 16,
                        "rst_val": 0,
                        "addr": -1,
                        "log2n_items": 0,
                        "autologic": True,
                        "descr": "Since it is a debug core and performance is not a priority, samples are accessed by first setting the index to read and then reading the value of SAMPLE_DATA",
                    },
                    {
                        "name": "SIGNAL_SELECT",
                        "type": "W",
                        "n_bits": 8,
                        "rst_val": 0,
                        "addr": -1,
                        "log2n_items": 0,
                        "autologic": True,
                        "descr": "Signals bigger than DATA_W bits are partition into DATA_W parts, this selects which part to read",
                    },
                ],
            },
            {
                "name": "data_read",
                "descr": "Data reading",
                "regs": [
                    {
                        "name": "SAMPLE_DATA",
                        "type": "R",
                        "n_bits": 32,
                        "rst_val": 0,
                        "addr": -1,
                        "log2n_items": 0,
                        "autologic": True,
                        "descr": "Value of the samples for the index set in ILA_INDEX and part set in ILA_SIGNAL_SELECT",
                    },
                    {
                        "name": "N_SAMPLES",
                        "type": "R",
                        "n_bits": 16,
                        "rst_val": 0,
                        "addr": -1,
                        "log2n_items": 0,
                        "autologic": True,
                        "descr": "Number of samples collected so far",
                    },
                    {
                        "name": "CURRENT_DATA",
                        "type": "R",
                        "n_bits": 32,
                        "rst_val": 0,
                        "addr": -1,
                        "log2n_items": 0,
                        "autologic": True,
                        "descr": "The current value of signal (not necessarily stored in the buffer) for the specific ILA_SIGNAL_SELECT (not affected by delay)",
                    },
                    {
                        "name": "CURRENT_TRIGGERS",
                        "type": "R",
                        "n_bits": 32,
                        "rst_val": 0,
                        "addr": -1,
                        "log2n_items": 0,
                        "autologic": True,
                        "descr": "The current value of trigger (the value directly from the trigger signal, not affected by trigger type, negation or delay)",
                    },
                    {
                        "name": "CURRENT_ACTIVE_TRIGGERS",
                        "type": "R",
                        "n_bits": 32,
                        "rst_val": 0,
                        "addr": -1,
                        "log2n_items": 0,
                        "autologic": True,
                        "descr": "This value is affected by negation and trigger type. For continuous triggers, returns if the trigger has been activated. For single triggers, returns whether the signal is currently asserted",
                    },
                ],
            },
        ]

    @classmethod
    def _setup_block_groups(cls):
        cls.block_groups += []
