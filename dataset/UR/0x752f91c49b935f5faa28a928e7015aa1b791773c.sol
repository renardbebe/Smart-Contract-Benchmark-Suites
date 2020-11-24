 

pragma solidity >=0.4.22 < 0.7.0;

contract ProofOfExistence {

    address public owner;

    mapping (bytes32 => uint256) public documents;

    modifier requireOwner() {
        require(msg.sender == owner, "Owner is required.");
        _;
    }

    modifier requireNoHashExists(bytes32 hashedDocument) {
        require(documents[hashedDocument] == 0, "Hash value already exists.");
        _;
    }

    constructor() public {
        owner = msg.sender;
    }

    function addDocument(bytes32 hashedDocument)
        external requireOwner requireNoHashExists(hashedDocument) returns (bytes32) {

        documents[hashedDocument] = block.number;

        return hashedDocument;
    }

    function doesHashExist(bytes32 documentHash) public view returns (bool) {
        return documents[documentHash] != 0;
    }

    function getBlockNumber(bytes32 documentHash) public view returns (uint256) {
        return documents[documentHash];
    }

    function () external {
        revert("Invalid data sent to contract.");
    }

    function selfDestroy() public requireOwner {
        selfdestruct(msg.sender);
    }
}