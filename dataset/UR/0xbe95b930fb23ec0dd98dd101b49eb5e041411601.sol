 

pragma solidity ^0.5.0;
pragma experimental ABIEncoderV2;

 
contract CommitMe {
    
     

    struct Commitment {
        address creator;
        uint256 block;
        uint256 timestamp;
    }


     

    mapping (bytes32 => Commitment) public commitments;


     

     
    function commit(bytes32 _hash) public {
        Commitment storage commitment = commitments[_hash];
        
        require(
            !commitmentExists(_hash),
            "Commitment with that hash already exists, try adding a salt."
        );

        commitment.creator = msg.sender;
        commitment.block = block.number;
        commitment.timestamp = block.timestamp;
    }

     
    function verify(
        bytes memory _message
    )
        public
        view
        returns (Commitment memory)
    {
        bytes32 hash = keccak256(_message);
        Commitment memory commitment = commitments[hash];

        require(
            commitmentExists(hash),
            "Commitment with that hash does not exist."
        );

        return commitment;
    }


     

     
    function commitmentExists(bytes32 _hash) private view returns (bool) {
        return commitments[_hash].creator != address(0);
    }
}