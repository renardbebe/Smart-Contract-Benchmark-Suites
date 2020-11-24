 

pragma solidity 0.4.24;

 
contract PubKeyTrust {
	address public owner;
	string public constant HASH_TYPE = "sha256";

	 
	mapping(bytes20 => bytes32) private users;
	
	 
	mapping(bytes32 => uint) private merkleTreeRoots;

	constructor() public {
		owner = msg.sender;
		merkleTreeRoots[bytes32(0)] = block.number;
	}

	modifier onlyByOwner()
	{
		if (msg.sender != owner)
			require(false);
		else
			_;
	}

	 
	function addMerkleTreeRoot(bytes32 merkleTreeRoot, bytes userIDsPacked) public onlyByOwner {

		if (merkleTreeRoot == bytes32(0)) require(false);

		bool addedUser = false;

		uint numUserIDs = userIDsPacked.length / 20;
		for (uint i = 0; i < numUserIDs; i++)
		{
			bytes20 userID;
			assembly {
				userID := mload(add(userIDsPacked, add(32, mul(20, i))))
			}

			bytes32 existingMerkleTreeRoot = users[userID];
			if (existingMerkleTreeRoot == bytes32(0))
			{
				users[userID] = merkleTreeRoot;
				addedUser = true;
			}
		}

		if (addedUser && (merkleTreeRoots[merkleTreeRoot] == 0))
		{
			merkleTreeRoots[merkleTreeRoot] = block.number;
		}
	}

	function getMerkleTreeRoot(bytes20 userID) public view returns (bytes32) {

		return users[userID];
	}

	function getBlockNumber(bytes32 merkleTreeRoot) public view returns (uint) {

		return merkleTreeRoots[merkleTreeRoot];
	}

    function getUserInfo(bytes20 userID) public view returns (bytes32, uint) {
        
        bytes32 merkleTreeRoot = users[userID];
        uint blockNumber = merkleTreeRoots[merkleTreeRoot];
        
        return (merkleTreeRoot, blockNumber);
    }	
}