#!/usr/bin/env python3

import os
import sys

from iob_module import iob_module
from setup import setup

# Submodules
from iob_lib import iob_lib
from iob_utils import iob_utils
from iob_clkenrst_portmap import iob_clkenrst_portmap
from iob_clkenrst_port import iob_clkenrst_port
from iob_reg import iob_reg
from iob_reg_r import iob_reg_r
from iob_reg_re import iob_reg_re


class iob_ila(iob_module):
    name = "iob_ila"
    version = "V0.10"
    flows = "sim emb doc"
    setup_dir = os.path.dirname(__file__)

    @classmethod
    def _run_setup(cls):
        # Hardware headers & modules
        iob_module.generate("iob_s_port")
        iob_module.generate("iob_s_portmap")
        iob_lib.setup()
        iob_utils.setup()
        iob_clkenrst_portmap.setup()
        iob_clkenrst_port.setup()
        iob_reg.setup()
        iob_reg_r.setup()
        iob_reg_re.setup()

        cls._setup_confs()
        cls._setup_ios()
        cls._setup_regs()
        cls._setup_block_groups()

        # Verilog modules instances
        # TODO

        # Copy sources of this module to the build directory
        super()._run_setup()

        # Setup core using LIB function
        setup(cls)

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
                    "val": "0",
                    "min": "NA",
                    "max": "NA",
                    "descr": "Width of the sampler signal input",
                },
                {
                    "name": "BUFFER_W",
                    "type": "P",
                    "val": "0",
                    "min": "NA",
                    "max": "NA",
                    "descr": "Size of the buffer to store samples.",
                },
                {
                    "name": "TRIGGER_W",
                    "type": "P",
                    "val": "0",
                    "min": "NA",
                    "max": "32",
                    "descr": "Width of the trigger input",
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
