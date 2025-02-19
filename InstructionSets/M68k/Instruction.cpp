//
//  Instruction.cpp
//  Clock Signal
//
//  Created by Thomas Harte on 12/05/2022.
//  Copyright © 2022 Thomas Harte. All rights reserved.
//

#include "Instruction.hpp"

#include <cassert>

using namespace InstructionSet::M68k;

std::string Preinstruction::operand_description(int index, int opcode) const {
	switch(mode(index)) {
		default:	assert(false);

		case AddressingMode::None:
			return "";

		case AddressingMode::DataRegisterDirect:
			return std::string("D") + std::to_string(reg(index));

		case AddressingMode::AddressRegisterDirect:
			return std::string("A") + std::to_string(reg(index));
		case AddressingMode::AddressRegisterIndirect:
			return std::string("(A") + std::to_string(reg(index)) + ")";
		case AddressingMode::AddressRegisterIndirectWithPostincrement:
			return std::string("(A") + std::to_string(reg(index)) + ")+";
		case AddressingMode::AddressRegisterIndirectWithPredecrement:
			return std::string("-(A") + std::to_string(reg(index)) + ")";
		case AddressingMode::AddressRegisterIndirectWithDisplacement:
			return std::string("(d16, A") + std::to_string(reg(index)) + ")";
		case AddressingMode::AddressRegisterIndirectWithIndex8bitDisplacement:
			return std::string("(d8, A") + std::to_string(reg(index)) + ", Xn)";

		case AddressingMode::ProgramCounterIndirectWithDisplacement:
			return "(d16, PC)";
		case AddressingMode::ProgramCounterIndirectWithIndex8bitDisplacement:
			return "(d8, PC, Xn)";

		case AddressingMode::AbsoluteShort:
			return "(xxx).w";
		case AddressingMode::AbsoluteLong:
			return "(xxx).l";

		case AddressingMode::ImmediateData:
			return "#";

		case AddressingMode::Quick:
			if(opcode == -1) {
				return "Q";
			}
			return std::to_string(int(quick(uint16_t(opcode), operation)));
	}
}

std::string Preinstruction::to_string(int opcode) const {
	bool flip_operands = false;
	const char *instruction;

	switch(operation) {
		case Operation::Undefined:	return "None";
		case Operation::NOP:		instruction = "NOP";		break;
		case Operation::ABCD:		instruction = "ABCD";		break;
		case Operation::SBCD:		instruction = "SBCD";		break;
		case Operation::NBCD:		instruction = "NBCD";		break;

		case Operation::ADDb:		instruction = "ADD.b";		break;
		case Operation::ADDw:		instruction = "ADD.w";		break;
		case Operation::ADDl:		instruction = "ADD.l";		break;

		case Operation::ADDAw:
			if(mode<0>() == AddressingMode::Quick) {
				instruction = "ADD.w";
			} else {
				instruction = "ADDA.w";
			}
		break;
		case Operation::ADDAl:
			if(mode<0>() == AddressingMode::Quick) {
				instruction = "ADD.l";
			} else {
				instruction = "ADDA.l";
			}
		break;

		case Operation::ADDXb:		instruction = "ADDX.b";	break;
		case Operation::ADDXw:		instruction = "ADDX.w";	break;
		case Operation::ADDXl:		instruction = "ADDX.l";	break;

		case Operation::SUBb:		instruction = "SUB.b";	break;
		case Operation::SUBw:		instruction = "SUB.w";	break;
		case Operation::SUBl:		instruction = "SUB.l";	break;

		case Operation::SUBAw:
			if(mode<0>() == AddressingMode::Quick) {
				instruction = "SUB.w";
			} else {
				instruction = "SUBA.w";
			}
		break;
		case Operation::SUBAl:
			if(mode<0>() == AddressingMode::Quick) {
				instruction = "SUB.l";
			} else {
				instruction = "SUBA.l";
			}
		break;

		case Operation::SUBXb:		instruction = "SUBX.b";	break;
		case Operation::SUBXw:		instruction = "SUBX.w";	break;
		case Operation::SUBXl:		instruction = "SUBX.l";	break;

		case Operation::MOVEb:		instruction = "MOVE.b";	break;
		case Operation::MOVEw:		instruction = "MOVE.w";	break;
		case Operation::MOVEl:
			if(mode<0>() == AddressingMode::Quick) {
				instruction = "MOVE.q";
			} else {
				instruction = "MOVE.l";
			}
		break;

		case Operation::MOVEAw:		instruction = "MOVEA.w";	break;
		case Operation::MOVEAl:		instruction = "MOVEA.l";	break;

		case Operation::LEA:		instruction = "LEA";		break;
		case Operation::PEA:		instruction = "PEA";		break;

		case Operation::MOVEtoSR:		instruction = "MOVEtoSR";		break;
		case Operation::MOVEfromSR:		instruction = "MOVEfromSR";		break;
		case Operation::MOVEtoCCR:		instruction = "MOVEtoCCR";		break;
		case Operation::MOVEtoUSP:		instruction = "MOVEtoUSP";		break;
		case Operation::MOVEfromUSP:	instruction = "MOVEfromUSP";	break;

		case Operation::ORItoSR:	instruction = "ORItoSR";	break;
		case Operation::ORItoCCR:	instruction = "ORItoCCR";	break;
		case Operation::ANDItoSR:	instruction = "ANDItoSR";	break;
		case Operation::ANDItoCCR:	instruction = "ANDItoCCR";	break;
		case Operation::EORItoSR:	instruction = "EORItoSR";	break;
		case Operation::EORItoCCR:	instruction = "EORItoCCR";	break;

		case Operation::BTST:	instruction = "BTST";	break;
		case Operation::BCLR:	instruction = "BCLR";	break;
		case Operation::BCHG:	instruction = "BCHG";	break;
		case Operation::BSET:	instruction = "BSET";	break;

		case Operation::CMPb:	instruction = "CMP.b";	break;
		case Operation::CMPw:	instruction = "CMP.w";	break;
		case Operation::CMPl:	instruction = "CMP.l";	break;

		case Operation::CMPAw:	instruction = "CMPA.w";	break;
		case Operation::CMPAl:	instruction = "CMPA.l";	break;

		case Operation::TSTb:	instruction = "TST.b";	break;
		case Operation::TSTw:	instruction = "TST.w";	break;
		case Operation::TSTl:	instruction = "TST.l";	break;

		case Operation::JMP:	instruction = "JMP";	break;
		case Operation::JSR:	instruction = "JSR";	break;
		case Operation::RTS:	instruction = "RTS";	break;
		case Operation::DBcc:	instruction = "DBcc";	break;
		case Operation::Scc:	instruction = "Scc";	break;

		case Operation::Bccb:
		case Operation::Bccl:
		case Operation::Bccw:	instruction = "Bcc";	break;

		case Operation::BSRb:
		case Operation::BSRl:
		case Operation::BSRw:	instruction = "BSR";	break;

		case Operation::CLRb:	instruction = "CLR.b";	break;
		case Operation::CLRw:	instruction = "CLR.w";	break;
		case Operation::CLRl:	instruction = "CLR.l";	break;

		case Operation::NEGXb:	instruction = "NEGX.b";	break;
		case Operation::NEGXw:	instruction = "NEGX.w";	break;
		case Operation::NEGXl:	instruction = "NEGX.l";	break;

		case Operation::NEGb:	instruction = "NEG.b";	break;
		case Operation::NEGw:	instruction = "NEG.w";	break;
		case Operation::NEGl:	instruction = "NEG.l";	break;

		case Operation::ASLb:	instruction = "ASL.b";	break;
		case Operation::ASLw:	instruction = "ASL.w";	break;
		case Operation::ASLl:	instruction = "ASL.l";	break;
		case Operation::ASLm:	instruction = "ASL.w";	break;

		case Operation::ASRb:	instruction = "ASR.b";	break;
		case Operation::ASRw:	instruction = "ASR.w";	break;
		case Operation::ASRl:	instruction = "ASR.l";	break;
		case Operation::ASRm:	instruction = "ASR.w";	break;

		case Operation::LSLb:	instruction = "LSL.b";	break;
		case Operation::LSLw:	instruction = "LSL.w";	break;
		case Operation::LSLl:	instruction = "LSL.l";	break;
		case Operation::LSLm:	instruction = "LSL.w";	break;

		case Operation::LSRb:	instruction = "LSR.b";	break;
		case Operation::LSRw:	instruction = "LSR.w";	break;
		case Operation::LSRl:	instruction = "LSR.l";	break;
		case Operation::LSRm:	instruction = "LSR.w";	break;

		case Operation::ROLb:	instruction = "ROL.b";	break;
		case Operation::ROLw:	instruction = "ROL.w";	break;
		case Operation::ROLl:	instruction = "ROL.l";	break;
		case Operation::ROLm:	instruction = "ROL.w";	break;

		case Operation::RORb:	instruction = "ROR.b";	break;
		case Operation::RORw:	instruction = "ROR.w";	break;
		case Operation::RORl:	instruction = "ROR.l";	break;
		case Operation::RORm:	instruction = "ROR.w";	break;

		case Operation::ROXLb:	instruction = "ROXL.b";	break;
		case Operation::ROXLw:	instruction = "ROXL.w";	break;
		case Operation::ROXLl:	instruction = "ROXL.l";	break;
		case Operation::ROXLm:	instruction = "ROXL.w";	break;

		case Operation::ROXRb:	instruction = "ROXR.b";	break;
		case Operation::ROXRw:	instruction = "ROXR.w";	break;
		case Operation::ROXRl:	instruction = "ROXR.l";	break;
		case Operation::ROXRm:	instruction = "ROXR.w";	break;

		case Operation::MOVEMtoMl:	instruction = "MOVEM.l";	break;
		case Operation::MOVEMtoMw:	instruction = "MOVEM.w";	break;
		case Operation::MOVEMtoRl:
			instruction = "MOVEM.l";
			flip_operands = true;
		break;
		case Operation::MOVEMtoRw:
			instruction = "MOVEM.w";
			flip_operands = true;
		break;

		case Operation::MOVEPl:	instruction = "MOVEP.l";	break;
		case Operation::MOVEPw:	instruction = "MOVEP.w";	break;

		case Operation::ANDb:	instruction = "AND.b";	break;
		case Operation::ANDw:	instruction = "AND.w";	break;
		case Operation::ANDl:	instruction = "AND.l";	break;

		case Operation::EORb:	instruction = "EOR.b";	break;
		case Operation::EORw:	instruction = "EOR.w";	break;
		case Operation::EORl:	instruction = "EOR.l";	break;

		case Operation::NOTb:	instruction = "NOT.b";	break;
		case Operation::NOTw:	instruction = "NOT.w";	break;
		case Operation::NOTl:	instruction = "NOT.l";	break;

		case Operation::ORb:	instruction = "OR.b";	break;
		case Operation::ORw:	instruction = "OR.w";	break;
		case Operation::ORl:	instruction = "OR.l";	break;

		case Operation::MULU:	instruction = "MULU";	break;
		case Operation::MULS:	instruction = "MULS";	break;
		case Operation::DIVU:	instruction = "DIVU";	break;
		case Operation::DIVS:	instruction = "DIVS";	break;

		case Operation::RTE:	instruction = "RTE";	break;
		case Operation::RTR:	instruction = "RTR";	break;

		case Operation::TRAP:	instruction = "TRAP";	break;
		case Operation::TRAPV:	instruction = "TRAPV";	break;
		case Operation::CHK:	instruction = "CHK";	break;

		case Operation::EXG:	instruction = "EXG";	break;
		case Operation::SWAP:	instruction = "SWAP";	break;

		case Operation::TAS:	instruction = "TAS";	break;

		case Operation::EXTbtow:	instruction = "EXT.w";	break;
		case Operation::EXTwtol:	instruction = "EXT.l";	break;

		case Operation::LINKw:	instruction = "LINK";	break;
		case Operation::UNLINK:	instruction = "UNLINK";	break;

		case Operation::STOP:	instruction = "STOP";	break;
		case Operation::RESET:	instruction = "RESET";	break;

		default:
			assert(false);
	}

	const std::string operand1 = operand_description(0 ^ int(flip_operands), opcode);
	const std::string operand2 = operand_description(1 ^ int(flip_operands), opcode);

	std::string result = instruction;
	if(!operand1.empty()) result += std::string(" ") + operand1;
	if(!operand2.empty()) result += std::string(", ") + operand2;

	return result;
}
