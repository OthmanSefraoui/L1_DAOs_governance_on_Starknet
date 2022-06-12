%lang starknet

from starkware.cairo.common.cairo_builtins import HashBuiltin
from starkware.cairo.common.hash import hash2

from starkware.cairo.common.math import assert_not_zero, assert_in_range, assert_le

from starkware.cairo.common.hash_state import hash_init, hash_update

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

from contracts.L2.token.IERC20 import IERC20

#
# Declaring storage vars
# Storage vars are by default not visible through the ABI. They are similar to "private" variables in Solidity
#

@storage_var
func l1_addresses_storage(player_address : felt) -> (l1_address : felt):
end

@storage_var
func proposals_status_storage(proposal_id : felt) -> (status : felt):
end

@storage_var
func votes_storage(proposal_id : felt, player_address : felt) -> (vote : felt):
end

@storage_var
func l1_governor_address_storage() -> (l1_governor : felt):
end

@storage_var
func dummy_token_address_storage() -> (dummy_token_address : felt):
end

struct proposal_vote:
    member against_votes : felt
    member for_votes : felt
    member abstain_votes : felt
end

struct proposal_core_:
    member vote_start : felt
    member vote_end : felt
    member proposal_hash : Uint256
end

@storage_var
func proposal_cores_storage(proposal_id : felt) -> (proposal_core : proposal_core_):
end

@storage_var
func proposal_votes_storage(proposal_id : felt) -> (proposal_votes : proposal_vote):
end

@storage_var
func has_voted_storage(proposal_id : felt, voter_address : felt) -> (has_voted : felt):
end

@storage_var
func voting_delay() -> (delay : felt):
end

@storage_var
func voting_period() -> (period : felt):
end

@storage_var
func proposal_ids_len() -> (length : felt):
end

#
# Declaring getters
# Public variables should be declared explicitly with a getter
#

@view
func l1_addresses{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
    player_address : felt
) -> (l1_address : felt):
    let (l1_address) = l1_addresses_storage.read(player_address)
    return (l1_address)
end

@view
func proposals_status{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
    proposal_id : felt
) -> (status : felt):
    let (status) = proposals_status_storage.read(proposal_id)
    return (status)
end

@view
func votes_for_count{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
    proposal_id : felt
) -> (votes_for_count : felt):
    let (proposal_vote_instance) = proposal_votes_storage.read(proposal_id)
    let votes_for_count = proposal_vote_instance.for_votes
    return (votes_for_count)
end

@view
func votes_against_count{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
    proposal_id : felt
) -> (votes_against_count : felt):
    let (proposal_vote_instance) = proposal_votes_storage.read(proposal_id)
    let votes_against_count = proposal_vote_instance.against_votes
    return (votes_against_count)
end

@view
func votes_abstain_count{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
    proposal_id : felt
) -> (votes_abstain_count : felt):
    let (proposal_vote_instance) = proposal_votes_storage.read(proposal_id)
    let votes_abstain_count = proposal_vote_instance.abstain_votes
    return (votes_abstain_count)
end

@view
func proposal_vote_start{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
    proposal_id : felt
) -> (vote_start : felt):
    let (proposal_core_instance) = proposal_cores_storage.read(proposal_id)
    let vote_start = proposal_core_instance.vote_start
    return (vote_start)
end

@view
func proposal_vote_end{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
    proposal_id : felt
) -> (vote_end : felt):
    let (proposal_core_instance) = proposal_cores_storage.read(proposal_id)
    let vote_end = proposal_core_instance.vote_end
    return (vote_end)
end

@view
func actual_timestamp{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}() -> (
    timestamp_now : felt
):
    let (block_timestamp) = get_block_timestamp()
    return (block_timestamp)
end

# ######## Constructor

@constructor
func constructor{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
    dummy_token_address : felt, delay : felt, period : felt
):
    voting_delay.write(delay)
    voting_period.write(period)
    dummy_token_address_storage.write(dummy_token_address)
    return ()
end

# ######## External functions

@external
func set_l1_governor{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
    l1_governor_address : felt
):
    l1_governor_address_storage.write(l1_governor_address)
    return ()
end

@external
func vote{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
    proposal_id : felt, vote : felt
):
    alloc_locals
    let (block_timestamp) = get_block_timestamp()
    let (proposal_core_instance) = proposal_cores_storage.read(proposal_id)
    let vote_end = proposal_core_instance.vote_end
    let vote_start = proposal_core_instance.vote_start
    assert_le(vote_start, block_timestamp)
    assert_le(block_timestamp, vote_end)
    let (sender_address) = get_caller_address()
    assert_not_zero(sender_address)
    let (has_voted) = has_voted_storage.read(proposal_id, sender_address)
    assert has_voted = 0
    let (dummy_token_address) = dummy_token_address_storage.read()
    let (weight) = IERC20.balanceOf(contract_address=dummy_token_address, account=sender_address)
    let weight_low = weight.low
    assert_in_range(vote, 0, 3)
    votes_storage.write(proposal_id, sender_address, vote)
    let (proposal_vote_instance) = proposal_votes_storage.read(proposal_id)
    let for_votes_ = proposal_vote_instance.for_votes
    let against_votes_ = proposal_vote_instance.against_votes
    let abstain_votes_ = proposal_vote_instance.abstain_votes
    if vote == 0:
        let new_vote_weight = against_votes_ + weight_low
        let proposal_vote_instance_after = proposal_vote(
            against_votes=new_vote_weight, for_votes=for_votes_, abstain_votes=abstain_votes_
        )
        proposal_votes_storage.write(proposal_id, proposal_vote_instance_after)
    else:
        if vote == 1:
            let new_vote_weight = for_votes_ + weight_low
            let proposal_vote_instance_after = proposal_vote(
                against_votes=against_votes_,
                for_votes=new_vote_weight,
                abstain_votes=abstain_votes_,
            )
            proposal_votes_storage.write(proposal_id, proposal_vote_instance_after)
        else:
            if vote == 2:
                let new_vote_weight = abstain_votes_ + weight_low
                let proposal_vote_instance_after = proposal_vote(
                    against_votes=against_votes_,
                    for_votes=for_votes_,
                    abstain_votes=new_vote_weight,
                )
                proposal_votes_storage.write(proposal_id, proposal_vote_instance_after)
            else:
                assert 1 = 0
                tempvar syscall_ptr = syscall_ptr
                tempvar pedersen_ptr = pedersen_ptr
                tempvar range_check_ptr = range_check_ptr
            end
        end
    end
    has_voted_storage.write(proposal_id, sender_address, 1)
    return ()
end

@external
func send_votes_toL1{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
    proposal_id : felt
):
    let (proposal_status) = proposals_status_storage.read(proposal_id)
    assert proposal_status = 1
    let (block_timestamp) = get_block_timestamp()
    let (proposal_core_instance) = proposal_cores_storage.read(proposal_id)
    let vote_end = proposal_core_instance.vote_end
    assert_le(vote_end, block_timestamp)
    let (message_payload : felt*) = alloc()
    let (proposal_vote_instance) = proposal_votes_storage.read(proposal_id)
    assert message_payload[0] = proposal_vote_instance.against_votes
    assert message_payload[1] = proposal_vote_instance.for_votes
    assert message_payload[2] = proposal_vote_instance.abstain_votes
    assert message_payload[3] = proposal_core_instance.proposal_hash.low
    assert message_payload[4] = proposal_core_instance.proposal_hash.high
    let (l1_governor) = l1_governor_address_storage.read()
    send_message_to_l1(to_address=l1_governor, payload_size=5, payload=message_payload)
    proposals_status_storage.write(proposal_id, 2)
    return ()
end

@external
func set_l1_address{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
    l1_address : felt
):
    let (sender_address) = get_caller_address()
    l1_addresses_storage.write(sender_address, l1_address)
    return ()
end

@external
func create_proposal{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
    proposal_hash_ : Uint256
):
    alloc_locals
    let (current_proposal_id) = proposal_ids_len.read()
    let proposal_id = current_proposal_id + 1
    proposal_ids_len.write(proposal_id)
    let (current_timestamp) = get_block_timestamp()
    let (delay) = voting_delay.read()
    let (period) = voting_period.read()
    let vote_start = current_timestamp + delay
    let vote_end = vote_start + period
    let proposal_vote_instance = proposal_vote(against_votes=0, for_votes=0, abstain_votes=0)
    let proposal_core_instance = proposal_core_(
        vote_start=vote_start, vote_end=vote_end, proposal_hash=proposal_hash_
    )
    proposal_votes_storage.write(proposal_id, proposal_vote_instance)
    proposal_cores_storage.write(proposal_id, proposal_core_instance)
    proposals_status_storage.write(proposal_id, 1)
    return ()
end
