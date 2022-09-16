%lang starknet

from starkware.cairo.common.cairo_builtins import HashBuiltin, SignatureBuiltin, BitwiseBuiltin

from starkware.cairo.common.math import assert_not_zero, assert_in_range, assert_le

from starkware.starknet.common.syscalls import (
    get_contract_address,
    get_caller_address,
    get_block_number,
    get_block_timestamp,
)
from starkware.cairo.common.uint256 import (
    Uint256,
    uint256_add,
    uint256_sub,
    uint256_le,
    uint256_lt,
    uint256_check,
    uint256_eq,
)
from starkware.cairo.common.alloc import alloc
from starkware.starknet.common.messages import send_message_to_l1

from starkware.cairo.common.cairo_secp.signature import verify_eth_signature_uint256
from starkware.cairo.common.cairo_keccak.keccak import finalize_keccak
//
// Declaring storage vars
// Storage vars are by default not visible through the ABI. They are similar to "private" variables in Solidity
//

@storage_var
func l1_addresses_storage(player_address: felt) -> (l1_address: felt) {
}

//
// Declaring getters
// Public variables should be declared explicitly with a getter
//

@view
func l1_addresses{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    player_address: felt
) -> (l1_address: felt) {
    let (l1_address) = l1_addresses_storage.read(player_address);
    return (l1_address,);
}

// ######## Constructor

@constructor
func constructor{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}() {
    return ();
}

// ######## External functions

@external
func verify_l1_user{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    l1_user: felt, msg_hash: Uint256, r: Uint256, s: Uint256, v: felt
) {
    alloc_locals;
    let (local bitwise_ptr: BitwiseBuiltin*) = alloc();
    // let (local keccak_ptr_start : felt*) = alloc()
    let (local keccak_ptr_start) = alloc();
    let keccak_ptr = keccak_ptr_start;
    verify_eth_signature_uint256{bitwise_ptr=bitwise_ptr, keccak_ptr=keccak_ptr}(
        msg_hash, r, s, v, l1_user
    );
    finalize_keccak{bitwise_ptr=bitwise_ptr}(
        keccak_ptr_start=keccak_ptr_start, keccak_ptr_end=keccak_ptr
    );
    let (caller_address) = get_caller_address();
    l1_addresses_storage.write(caller_address, l1_user);
    return ();
}
