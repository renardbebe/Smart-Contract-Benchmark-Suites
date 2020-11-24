 

pragma solidity ^0.4.17;
 

contract REALotteryWheel{
    
    uint16 public round_count = 0;
    bytes32 public last_hash;
    address public controller;
    
    mapping (uint16 => bytes32) public hashes;
    
    function REALotteryWheel() public {
        controller = msg.sender;
        last_hash = keccak256(block.number, now);    
    }
    
    function do_spin(bytes32 s) internal {
        round_count = round_count + 1;
        last_hash = keccak256(block.number,now,s);
        hashes[round_count] = last_hash;
    }

    function spin(bytes32 s) public { 
    	if(controller != msg.sender) revert();
    	do_spin(s);
    }

    function get_hash (uint16 i) constant returns (bytes32){
        return hashes[i];
    }
    
    function () payable {
        do_spin(bytes32(msg.value));
    }
    
}