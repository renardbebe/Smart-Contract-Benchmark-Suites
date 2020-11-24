 

pragma solidity 0.5.11;


 
interface IERC165 {
     
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}


 
contract IERC721 is IERC165 {
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

     
    function balanceOf(address owner) public view returns (uint256 balance);

     
    function ownerOf(uint256 tokenId) public view returns (address owner);

     
    function safeTransferFrom(address from, address to, uint256 tokenId) public;
     
    function transferFrom(address from, address to, uint256 tokenId) public;
    function approve(address to, uint256 tokenId) public;
    function getApproved(uint256 tokenId) public view returns (address operator);

    function setApprovalForAll(address operator, bool _approved) public;
    function isApprovedForAll(address owner, address operator) public view returns (bool);


    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data) public;
}


contract ICards is IERC721 {

    struct Batch {
        uint48 userID;
        uint16 size;
    }

    function batches(uint index) public view returns (uint48 userID, uint16 size);

    function userIDToAddress(uint48 id) public view returns (address);

    function getDetails(
        uint tokenId
    )
        public
        view
        returns (
        uint16 proto,
        uint8 quality
    );

    function setQuality(
        uint tokenId,
        uint8 quality
    ) public;

    function mintCards(
        address to,
        uint16[] memory _protos,
        uint8[] memory _qualities
    )
        public
        returns (uint);

    function mintCard(
        address to,
        uint16 _proto,
        uint8 _quality
    )
        public
        returns (uint);

    function burn(uint tokenId) public;

    function batchSize()
        public
        view
        returns (uint);
}

contract MigrationMigration {

    uint public batchIndex;
    ICards public oldCards;
    ICards public newCards;
    uint public constant batchSize = 1251;

    constructor(ICards _oldCards, ICards _newCards) public {
        oldCards = _oldCards;
        newCards = _newCards;

    }

    event Migrated(uint batchIndex, uint startID);

    function migrate() public {

        (uint48 userID, uint16 size) = oldCards.batches(batchIndex * batchSize);
        require(size > 0, "must be cards in this batch");
        uint16[] memory protos = new uint16[](size);
        uint8[] memory qualities = new uint8[](size);
        uint startID = batchIndex * batchSize;
        for (uint i = 0; i < size; i++) {
            (protos[i], qualities[i]) = oldCards.getDetails(startID + i);
        }
        address user = oldCards.userIDToAddress(userID);
        newCards.mintCards(user, protos, qualities);
        emit Migrated(batchIndex, startID);
        batchIndex++;
    }

}