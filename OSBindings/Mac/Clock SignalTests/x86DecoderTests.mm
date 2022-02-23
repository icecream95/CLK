//
//  x86DecoderTests.m
//  Clock Signal
//
//  Created by Thomas Harte on 03/01/2021.
//  Copyright 2021 Thomas Harte. All rights reserved.
//

#import <XCTest/XCTest.h>

#include <initializer_list>
#include <optional>
#include <vector>
#include "../../../InstructionSets/x86/Decoder.hpp"

namespace {

using Operation = InstructionSet::x86::Operation;
using Instruction = InstructionSet::x86::Instruction<false>;
using Model = InstructionSet::x86::Model;
using Source = InstructionSet::x86::Source;
using Size = InstructionSet::x86::Size;
using ScaleIndexBase = InstructionSet::x86::ScaleIndexBase;
using SourceSIB = InstructionSet::x86::SourceSIB;

// MARK: - Specific instruction asserts.

template <typename InstructionT> void test(const InstructionT &instruction, int size, Operation operation) {
	XCTAssertEqual(instruction.operation_size(), InstructionSet::x86::Size(size));
	XCTAssertEqual(instruction.operation, operation);
}

template <typename InstructionT> void test(
	const InstructionT &instruction,
	int size,
	Operation operation,
	SourceSIB source,
	std::optional<SourceSIB> destination = std::nullopt,
	std::optional<typename InstructionT::ImmediateT> operand = std::nullopt,
	std::optional<typename InstructionT::DisplacementT> displacement = std::nullopt) {

	XCTAssertEqual(instruction.operation_size(), InstructionSet::x86::Size(size));
	XCTAssertEqual(instruction.operation, operation);
	XCTAssert(instruction.source() == source);
	if(destination) XCTAssert(instruction.destination() == *destination);
	if(operand)	XCTAssertEqual(instruction.operand(), *operand);
	if(displacement) XCTAssertEqual(instruction.displacement(), *displacement);
}

template <typename InstructionT> void test(
	const InstructionT &instruction,
	Operation operation,
	std::optional<typename InstructionT::ImmediateT> operand = std::nullopt,
	std::optional<typename InstructionT::DisplacementT> displacement = std::nullopt) {
	XCTAssertEqual(instruction.operation, operation);
	if(operand)	XCTAssertEqual(instruction.operand(), *operand);
	if(displacement) XCTAssertEqual(instruction.displacement(), *displacement);
}

template <typename InstructionT> void test_far(const InstructionT &instruction, Operation operation, uint16_t segment, uint16_t offset) {
	XCTAssertEqual(instruction.operation, operation);
	XCTAssertEqual(instruction.segment(), segment);
	XCTAssertEqual(instruction.offset(), offset);
}

// MARK: - Decoder

template <Model model> std::vector<typename InstructionSet::x86::Decoder<model>::InstructionT> decode(const std::initializer_list<uint8_t> &stream) {
	// Decode by offering up all data at once.
	std::vector<typename InstructionSet::x86::Decoder<model>::InstructionT> instructions;
	InstructionSet::x86::Decoder<model> decoder;
	instructions.clear();
	const uint8_t *byte = stream.begin();
	while(byte != stream.end()) {
		const auto [size, next] = decoder.decode(byte, stream.end() - byte);
		if(size <= 0) break;
		instructions.push_back(next);
		byte += size;
	}

	// Grab a byte-at-a-time decoding and check that it matches the previous.
	{
		InstructionSet::x86::Decoder<model> decoder;

		auto previous_instruction = instructions.begin();
		for(auto item: stream) {
			const auto [size, next] = decoder.decode(&item, 1);
			if(size > 0) {
				XCTAssert(next == *previous_instruction);
				++previous_instruction;
			}
		}
	}

	return instructions;
}

}

@interface x86DecoderTests : XCTestCase
@end

/*!
	Tests 8086 decoding by throwing a bunch of randomly-generated
	word streams and checking that the result matches what I got from a
	disassembler elsewhere.
*/
@implementation x86DecoderTests

- (void)testSequence1 {
	// Sequences the Online Disassembler believes to exist but The 8086 Book does not:
	//
	// 0x6a 0x65	push $65
	// 0x65 0x6d	gs insw (%dx),%es:(%di)
	// 0x67 0x61	addr32 popa
	// 0x6c			insb (%dx), %es:(%di)
	// 0xc9			leave
	//
	const auto instructions = decode<Model::i8086>({
		0x2d, 0x77, 0xea, 0x72, 0xfc, 0x4b, 0xb5, 0x28, 0xc3, 0xca, 0x26, 0x48, /* 0x65, 0x6d, */ 0x7b, 0x9f,
		0xc2, 0x65, 0x42, 0x4e, 0xef, 0x70, 0x20, 0x94, 0xc4, 0xd4, 0x93, 0x43, 0x3c, 0x8e, /* 0x6a, 0x65, */
		0x1a, 0x78, 0x45, 0x10, 0x7f, 0x3c, 0x19, 0x5a, 0x16, 0x31, 0x64, 0x2c, 0xe7, 0xc6, 0x7d, 0xb0,
		0xb5, 0x49, /* 0x67, 0x61, */ 0xba, 0xc0, 0xcb, 0x14, 0x7e, 0x71, 0xd0, 0x50, 0x78, 0x3d, 0x03, 0x1d,
		0xe5, 0xc9, 0x97, 0xc3, 0x9b, 0xe6, 0xd3, /* 0x6c, */ 0x58, 0x4d, 0x76, 0x80, 0x44, 0xd6, 0x9f, 0xa5,
		0xbd, 0xa1, 0x12, 0xc5, 0x29, /* 0xc9, */ 0x9e, 0xd8, 0xf3, 0xcf, 0x92, 0x39, 0x5d, 0x90, 0x15, 0xc3,
		0xb8, 0xad, 0xe8, 0xc8, 0x16, 0x4a, 0xb0, 0x9e, 0xf9, 0xbf, 0x56, 0xea, 0x4e, 0xfd, 0xe4, 0x5a,
		0x23, 0xaa, 0x2c, 0x5b, 0x2a, 0xd2, 0xf7, 0x5f, 0x18, 0x86, 0x90, 0x25, 0x64, 0xb7, 0xc3
	});

	// 63 instructions are expected.
	XCTAssertEqual(instructions.size(), 63);

	// sub		$0xea77,%ax
	// jb		0x00000001
	// dec		%bx
	// mov		$0x28,%ch
	test(instructions[0], 2, Operation::SUB, Source::Immediate, Source::eAX, 0xea77);
	test(instructions[1], Operation::JB, std::nullopt, 0xfffc);
	test(instructions[2], 2, Operation::DEC, Source::eBX, Source::eBX);
	test(instructions[3], 1, Operation::MOV, Source::Immediate, Source::CH, 0x28);

	// ret
	// lret		$0x4826
	// [[ omitted: gs insw (%dx),%es:(%di) ]]
	// jnp		0xffffffaf
	// ret		$0x4265
	test(instructions[4], Operation::RETN);
	test(instructions[5], Operation::RETF, 0x4826);
	test(instructions[6], Operation::JNP, std::nullopt, 0xff9f);
	test(instructions[7], Operation::RETN, 0x4265);

	// dec		%si
	// out		%ax,(%dx)
	// jo		0x00000037
	// xchg		%ax,%sp
	test(instructions[8], 2, Operation::DEC, Source::eSI, Source::eSI);
	test(instructions[9], 2, Operation::OUT, Source::eAX, Source::eDX);
	test(instructions[10], Operation::JO, std::nullopt, 0x20);
	test(instructions[11], 2, Operation::XCHG, Source::eAX, Source::eSP);

	// ODA has:
	// 	c4		(bad)
	// 	d4 93	aam		$0x93
	//
	// That assumes that upon discovering that the d4 doesn't make a valid LES,
	// it can become an instruction byte. I'm not persuaded. So I'm taking:
	//
	//	c4 d4	(bad)
	//	93		XCHG AX, BX
	test(instructions[12], Operation::Invalid);
	test(instructions[13], 2, Operation::XCHG, Source::eAX, Source::eBX);

	// inc		%bx
	// cmp		$0x8e,%al
	// [[ omitted: push		$0x65 ]]
	// sbb		0x45(%bx,%si),%bh
	// adc		%bh,0x3c(%bx)
	test(instructions[14], 2, Operation::INC, Source::eBX, Source::eBX);
	test(instructions[15], 1, Operation::CMP, Source::Immediate, Source::eAX, 0x8e);
	test(instructions[16], 1, Operation::SBB, ScaleIndexBase(Source::eBX, Source::eSI), Source::BH, std::nullopt, 0x45);
	test(instructions[17], 1, Operation::ADC, Source::BH, ScaleIndexBase(Source::eBX), std::nullopt, 0x3c);

	// sbb		%bx,0x16(%bp,%si)
	// xor		%sp,0x2c(%si)
	// out		%ax,$0xc6
	// jge		0xffffffe0
	test(instructions[18], 2, Operation::SBB, Source::eBX, ScaleIndexBase(Source::eBP, Source::eSI), std::nullopt, 0x16);
	test(instructions[19], 2, Operation::XOR, Source::eSP, ScaleIndexBase(Source::eSI), std::nullopt, 0x2c);
	test(instructions[20], 2, Operation::OUT, Source::eAX, Source::DirectAddress, 0xc6);
	test(instructions[21], Operation::JNL, std::nullopt, 0xffb0);

	// mov		$0x49,%ch
	// [[ omitted: addr32	popa ]]
	// mov		$0xcbc0,%dx
	// adc		$0x7e,%al
	// jno		0x0000000b
	test(instructions[22], 1, Operation::MOV, Source::Immediate, Source::CH, 0x49);
	test(instructions[23], 2, Operation::MOV, Source::Immediate, Source::eDX, 0xcbc0);
	test(instructions[24], 1, Operation::ADC, Source::Immediate, Source::eAX, 0x7e);
	test(instructions[25], Operation::JNO, std::nullopt, 0xffd0);

	// push		%ax
	// js		0x0000007b
	// add		(%di),%bx
	// in		$0xc9,%ax
	test(instructions[26], 2, Operation::PUSH, Source::eAX);
	test(instructions[27], Operation::JS, std::nullopt, 0x3d);
	test(instructions[28], 2, Operation::ADD, ScaleIndexBase(Source::eDI), Source::eBX);
	test(instructions[29], 2, Operation::IN, Source::DirectAddress, Source::eAX, 0xc9);

	// xchg		%ax,%di
	// ret
	// fwait
	// out		%al,$0xd3
	test(instructions[30], 2, Operation::XCHG, Source::eAX, Source::eDI);
	test(instructions[31], Operation::RETN);
	test(instructions[32], Operation::WAIT);
	test(instructions[33], 1, Operation::OUT, Source::eAX, Source::DirectAddress, 0xd3);

	// [[ omitted: insb		(%dx),%es:(%di) ]]
	// pop		%ax
	// dec		%bp
	// jbe		0xffffffcc
	// inc		%sp
	test(instructions[34], 2, Operation::POP, Source::eAX);
	test(instructions[35], 2, Operation::DEC, Source::eBP, Source::eBP);
	test(instructions[36], Operation::JBE, std::nullopt, 0xff80);
	test(instructions[37], 2, Operation::INC, Source::eSP, Source::eSP);

	// (bad)
	// lahf
	// movsw	%ds:(%si),%es:(%di)
	// mov		$0x12a1,%bp
	test(instructions[38], Operation::Invalid);
	test(instructions[39], Operation::LAHF);
	test(instructions[40], 2, Operation::MOVS); /* Arguments are implicit. */
	test(instructions[41], 2, Operation::MOV, Source::Immediate, Source::eBP, 0x12a1);

	// lds		(%bx,%di),%bp
	// [[ omitted: leave ]]
	// sahf
	// fdiv		%st(3),%st
	// iret
	test(instructions[42], 2, Operation::LDS);
	test(instructions[43], Operation::SAHF);
	test(instructions[44], Operation::ESC);
	test(instructions[45], Operation::IRET);

	// xchg		%ax,%dx
	// cmp		%bx,-0x70(%di)
	// adc		$0xb8c3,%ax
	// lods		%ds:(%si),%ax
	test(instructions[46], 2, Operation::XCHG, Source::eAX, Source::eDX);
	test(instructions[47], 2, Operation::CMP, Source::eBX, ScaleIndexBase(Source::eDI), std::nullopt, 0xff90);
	test(instructions[48], 2, Operation::ADC, Source::Immediate, Source::eAX, 0xb8c3);
	test(instructions[49], 2, Operation::LODS);

	// call		0x0000172d
	// dec		%dx
	// mov		$0x9e,%al
	// stc
	test(instructions[50], Operation::CALLD, uint16_t(0x16c8));
	test(instructions[51], 2, Operation::DEC, Source::eDX, Source::eDX);
	test(instructions[52], 1, Operation::MOV, Source::Immediate, Source::eAX, 0x9e);
	test(instructions[53], Operation::STC);

	// mov		$0xea56,%di
	// dec		%si
	// std
	// in		$0x5a,%al
	test(instructions[54], 2, Operation::MOV, Source::Immediate, Source::eDI, 0xea56);
	test(instructions[55], 2, Operation::DEC, Source::eSI, Source::eSI);
	test(instructions[56], Operation::STD);
	test(instructions[57], 1, Operation::IN, Source::DirectAddress, Source::eAX, 0x5a);

	// and		0x5b2c(%bp,%si),%bp
	// sub		%dl,%dl
	// negw		0x18(%bx)
	// xchg		%dl,0x6425(%bx,%si)
	test(instructions[58], 2, Operation::AND, ScaleIndexBase(Source::eBP, Source::eSI), Source::eBP, std::nullopt, 0x5b2c);
	test(instructions[59], 1, Operation::SUB, Source::eDX, Source::eDX);
	test(instructions[60], 2, Operation::NEG, ScaleIndexBase(Source::eBX), ScaleIndexBase(Source::eBX), std::nullopt, 0x18);
	test(instructions[61], 1, Operation::XCHG, ScaleIndexBase(Source::eBX, Source::eSI), Source::eDX, std::nullopt, 0x6425);

	// mov		$0xc3,%bh
	test(instructions[62], 1, Operation::MOV, Source::Immediate, Source::BH, 0xc3);
}

- (void)test83 {
	const auto instructions = decode<Model::i8086>({
		0x83, 0x10, 0x80,	// adcw		$0xff80,(%bx,%si)
		0x83, 0x3b, 0x04,	// cmpw		$0x4,(%bp,%di)
		0x83, 0x2f, 0x09,	// subw		$0x9,(%bx)
	});

	XCTAssertEqual(instructions.size(), 3);
	test(instructions[0], 2, Operation::ADC, Source::Immediate, ScaleIndexBase(Source::eBX, Source::eSI), 0xff80);
	test(instructions[1], 2, Operation::CMP, Source::Immediate, ScaleIndexBase(Source::eBP, Source::eDI), 0x4);
	test(instructions[2], 2, Operation::SUB, Source::Immediate, ScaleIndexBase(Source::eBX), 0x9);
}

- (void)testFar {
	const auto instructions = decode<Model::i8086>({
		0x9a, 0x12, 0x34, 0x56, 0x78,	// lcall 0x7856, 0x3412
	});

	XCTAssertEqual(instructions.size(), 1);
	test_far(instructions[0], Operation::CALLF, 0x7856, 0x3412);
}

- (void)testSequence2 {
}

@end
