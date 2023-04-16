 <<<<< Vx73 YNC (Yamaha Network Control) Protocol Overview Document  Rev 1.0 Jul/8/2012 >>>>>

This document package is for the person who controls Vx73 by YNC via Ethernet.
Please refer to the following for the composition and the content of each document.


- File Composition

    readme.txt (This document)

    doc ---+--- V673_3073_FuncTree_1.7a.xls
           +--- V673_3073_ETHERNET_IF_Spec_e_1.01.xls
           +--- How_to_get_actual_YNC_commands.doc
           +--- IR_RX-V673-3073_rev1.0_Full.xls
           |
           +--- YNC_Cmd_Samples -------+--- YNC_RX-A720_GET_x.txt
                                       +--- YNC_RX-A720_PUT_x.txt
                                       +--- YNC_RX-A820_GET_x.txt
                                              :

 1. V673_3073_FuncTree_xxx.xls
    -> It defines all YNC commands as a form of function tree. And also it offers the command generation
        tool function using macro programming.
    -> Refer to following item 3 for the usage of the command automatic generation.  

 2. V673_3073_ETHERNET_IF_Spec_e_xxx.xls
    -> This is YNC interface specification.

 3. How_to_get_actual_YNC_commands.doc
    -> It is an explanation of the method of the command automatic operation generation of using the
       above-mentioned item 1, and an explanation of the usage of all command list of following item 5. 

 4. IR_RX-V673-3073_revxxx_Full.xls
    -> IR (Remote signal) code table
    -> Use this table by the "System - Rempte_Signal" command.

 5. YNC_Cmd_Samples
    -> It is an actual all YNC command of each region and each model list. 
    -> Refer to the above-mentioned item 3 for the usage. 


--- <history> ----------------------------------------------------------------------------------------------

Rev 1.0 Jul/9/2012
 - First Edition
Rev 0.9 May/21/2012
 - Initial Draft
