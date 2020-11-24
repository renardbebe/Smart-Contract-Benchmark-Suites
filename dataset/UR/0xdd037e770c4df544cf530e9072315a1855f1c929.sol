 

pragma solidity 0.5.11;

contract IPackFour {

    struct Purchase {
        uint16 current;
        uint16 count;
        address user;
        uint randomness;
        uint64 commit;
    }

    function purchases(uint p) public view returns (
        uint16 current,
        uint16 count,
        address user,
        uint256 randomness,
        uint64 commit
    );

    function predictPacks(uint id) public view returns (uint16[] memory protos, uint16[] memory purities);

    function getCardDetails(
        uint16 packIndex,
        uint8 cardIndex,
        uint result
    )
        public
        view
        returns (uint16 proto, uint16 purity);

}

contract BaseMigration {

    function convertPurity(uint16 purity)
        public
        pure
        returns (uint8)
    {
        return uint8(4 - (purity / 1000));
    }

    function convertProto(uint16 proto)
        public
        view
        returns (uint16)
    {
        if (proto >= 1 && proto <= 377) {
            return proto;
        }
         
        if (proto == 380) {
            return 400;
        }
         
        if (proto == 381) {
            return 401;
        }
         
        if (proto == 394) {
            return 402;
        }
         
        (bool found, uint index) = getEtherbotsIndex(proto);
        if (found) {
            return uint16(380 + index);
        }
         
        if (proto == 378) {
            return 65000;
        }
         
        if (proto == 379) {
            return 65001;
        }
         
        if (proto == 383) {
            return 65002;
        }
         
        if (proto == 384) {
            return 65003;
        }
        require(false, "BM: unrecognised proto");
    }

    uint16[] internal ebs = [
        400,
        413,
        414,
        421,
        427,
        428,
        389,
        415,
        416,
        422,
        424,
        425,
        426,
        382,
        420,
        417
    ];

    function getEtherbotsIndex(uint16 proto)
        public
        view
        returns (bool, uint16)
    {
        for (uint16 i = 0; i < ebs.length; i++) {
            if (ebs[i] == proto) {
                return (true, i);
            }
        }
        return (false, 0);
    }

}

 
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



contract SplitV1Migration is BaseMigration {

    ICards cards;
    uint public oldLimit;
    uint16 public newLimit;
    uint16 public constant size = 5;

    constructor(
        ICards _cards,
        address[] memory _packs,
        uint _oldLimit,
        uint16 _newLimit
    ) public {

        for (uint i = 0; i < _packs.length; i++) {
            canMigrate[_packs[i]] = true;
        }

        cards = _cards;
        oldLimit = _oldLimit;
        require(_newLimit % size == 0, "limit must be divisible by size");
        newLimit = _newLimit;
    }

    mapping (address => bool) public canMigrate;

    mapping (address => mapping (uint => uint16)) public v1Migrated;

    event Migrated(
        address indexed user,
        address indexed pack,
        uint indexed id,
        uint start,
        uint end,
        uint startID
    );

    function migrateAll(
        IPackFour pack,
        uint[] memory ids
    ) public {
        for (uint i = 0; i < ids.length; i++) {
            migrate(pack, ids[i]);
        }
    }

    struct StackDepthLimit {
        uint16 proto;
        uint16 purity;
        uint16[] protos;
        uint8[] qualities;
    }

    function migrate(
        IPackFour pack,
        uint id
    )
        public
    {

        require(
            canMigrate[address(pack)],
            "V1: must be migrating from an approved pack"
        );

        (
            uint16 current,
            uint16 count,
            address user,
            uint256 randomness,
        ) = pack.purchases(id);

         
        require(
            randomness != 0,
            "V1: must have had randomness set"
        );

        uint16 remaining = ((count - current) * size);

        require(
            remaining > oldLimit,
            "V1: must have not been able to activate in v1"
        );

        remaining -= v1Migrated[address(pack)][id];

        uint16 loopStart = (current * size) + v1Migrated[address(pack)][id];

        uint16 len = remaining > newLimit ? newLimit : remaining;

        StackDepthLimit memory sdl;

        sdl.protos = new uint16[](len);
        sdl.qualities = new uint8[](len);

        uint16 packStart = loopStart / size;

        for (uint16 i = 0; i < len / size; i++) {
            for (uint8 j = 0; j < size; j++) {
                uint index = (i * size) + j;
                (sdl.proto, sdl.purity) = pack.getCardDetails(i + packStart, j, randomness);
                sdl.protos[index] = convertProto(sdl.proto);
                sdl.qualities[index] = convertPurity(sdl.purity);
            }
        }

         
        uint startID = cards.mintCards(user, sdl.protos, sdl.qualities);

        v1Migrated[address(pack)][id] += len;

        uint loopEnd = loopStart + len;

        emit Migrated(user, address(pack), id, loopStart, loopEnd, startID);
    }

}