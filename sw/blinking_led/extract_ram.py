#!/usr/bin/env python3

# Extract the .text session ELF file for implementation on a soft-core
# Cortex-M0. Based on
# https://anee.me/reversing-an-elf-from-the-ground-up-4fe1ec31db4a

import sys
from elftools.elf.elffile import ELFFile
from capstone import *

def list_sections(filename):
    print('Listing sections:', filename)
    with open(filename, 'rb') as f:
        elffile = ELFFile(f)
        for section in elffile.iter_sections():
            print(section.name)

def extract_assembly(filename):
    print('Extracting assembly file:', filename)
    with open(filename, 'rb') as f:
        elffile = ELFFile(f)
        code = elffile.get_section_by_name('.text')
        opcodes = code.data()
        addr = code['sh_addr']
        print('Entry Point: %x', hex(elffile.header['e_entry']))
        md = Cs(CS_ARCH_ARM, CS_MODE_THUMB)
        for i in md.disasm(opcodes, addr):
            print("0x%x:\t%s\t%s" %(i.address, i.mnemonic, i.op_str))
    return (code, opcodes, addr, md)


if __name__ == '__main__':
    if len(sys.argv) == 2:
        list_sections(sys.argv[1])
        extract_assembly(sys.argv[1])
