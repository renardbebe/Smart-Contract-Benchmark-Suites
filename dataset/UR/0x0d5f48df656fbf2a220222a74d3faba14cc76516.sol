 

pragma solidity 0.4.18;

 
contract PubKeyTrust {
	address public owner;

	 
	string[] public hashTypes;

	 
	struct MerkleInfo {
		bytes merkleTreeRoot;
		uint blockNumber;
	}
	MerkleInfo[] public merkleTreeRoots;

	 
	mapping(bytes20 => mapping(uint8 => uint)) public users;

	event HashTypeAdded(uint8 hashTypeID);
	event MerkleTreeRootAdded(uint8 hashTypeID, bytes merkleTreeRoot);

	function PubKeyTrust() public {
		owner = msg.sender;
		merkleTreeRoots.push(MerkleInfo(new bytes(0), block.number));
	}

	modifier onlyByOwner()
	{
		if (msg.sender != owner)
			require(false);
		else
			_;
	}

	function numHashTypes() public view returns (uint) {

		return hashTypes.length;
	}

	function addHashType(string description) public onlyByOwner returns(bool, uint8) {

		uint hashTypeID = hashTypes.length;

		 
		 
		 
		 
		if (hashTypeID >= 256) require(false);
		if (bytes(description).length == 0) require(false);
		if (bytes(description).length > 64) require(false);

		 
		for (uint i = 0; i < hashTypeID; i++)
		{
			if (stringsEqual(hashTypes[i], description)) {
				return (false, uint8(0));
			}
		}

		 
		hashTypes.push(description);
		HashTypeAdded(uint8(hashTypeID));

		return (true, uint8(hashTypeID));
	}

	 
	function addMerkleTreeRoot(uint8 hashTypeID, bytes merkleTreeRoot, bytes userIDsPacked) public onlyByOwner {

		if (hashTypeID >= hashTypes.length) require(false);
		if (merkleTreeRoot.length == 0) require(false);

		uint index = merkleTreeRoots.length;
		bool addedIndexForUser = false;

		uint numUserIDs = userIDsPacked.length / 20;
		for (uint i = 0; i < numUserIDs; i++)
		{
			bytes20 userID;
			assembly {
				userID := mload(add(userIDsPacked, add(32, mul(20, i))))
			}

			uint existingIndex = users[userID][hashTypeID];
			if (existingIndex == 0)
			{
				users[userID][hashTypeID] = index;
				addedIndexForUser = true;
			}
		}

		if (addedIndexForUser)
		{
			merkleTreeRoots.push(MerkleInfo(merkleTreeRoot, block.number));
			MerkleTreeRootAdded(hashTypeID, merkleTreeRoot);
		}
	}

	function getMerkleTreeRoot(bytes20 userID, uint8 hashTypeID) public view returns (bytes) {

		uint merkleTreeRootsIndex = users[userID][hashTypeID];
		if (merkleTreeRootsIndex == 0) {
			return new bytes(0);
		}
		else {
			MerkleInfo storage merkleInfo = merkleTreeRoots[merkleTreeRootsIndex];
			return merkleInfo.merkleTreeRoot;
		}
	}

	function getBlockNumber(bytes20 userID, uint8 hashTypeID) public view returns (uint) {

		uint merkleTreeRootsIndex = users[userID][hashTypeID];
		if (merkleTreeRootsIndex == 0) {
			return 0;
		}
		else {
			MerkleInfo storage merkleInfo = merkleTreeRoots[merkleTreeRootsIndex];
			return merkleInfo.blockNumber;
		}
	}

	 
	function stringsEqual(string storage _a, string memory _b) internal view returns (bool) {

		bytes storage a = bytes(_a);
		bytes memory b = bytes(_b);
		if (a.length != b.length) {
			return false;
		}
		for (uint i = 0; i < a.length; i++) {
			if (a[i] != b[i]) {
				return false;
			}
		}
		return true;
	}
}