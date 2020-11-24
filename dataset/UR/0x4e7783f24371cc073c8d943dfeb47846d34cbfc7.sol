 

pragma solidity ^0.5.11;

 
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


contract OldToken is IERC721 {

    function getCard(uint id) public view returns (uint16, uint16);
    function totalSupply() public view returns (uint);

}

contract ICards is IERC721 {

    function getDetails(uint tokenId) public view returns (uint16 proto, uint8 quality);
    function setQuality(uint tokenId, uint8 quality) public;
    function burn(uint tokenId) public;
    function batchMintCards(address to, uint16[] memory _protos, uint8[] memory _qualities) public returns (uint);
    function mintCards(address to, uint16[] memory _protos, uint8[] memory _qualities) public returns (uint);
    function mintCard(address to, uint16 _proto, uint8 _quality) public returns (uint);
    function batchSize() public view returns (uint);
}



contract DirectMigration {

    uint threshold;
    OldToken old;
    ICards cards;
    uint limit;

    event Migrated(address indexed user, uint oldStart, uint oldEnd, uint newStart);
    event NonGenesisMigrated(address indexed user, uint oldID, uint newID);

    constructor(OldToken _old, ICards _cards, uint _threshold, uint _limit) public {
        old = _old;
        cards = _cards;
        threshold = _threshold;
        limit = _limit;
    }

    struct IM {
        uint16 proto;
        uint16 purity;

        uint16 p;
        uint8 q;
        uint id;
    }

    uint public migrated;

    function activatedMigration() public returns (uint current) {
        uint start = migrated;
        address first = old.ownerOf(start);
        current = start;
        address owner = first;
        uint last = old.totalSupply();

        while (owner == first && current < start + limit) {
            current++;
            if (current >= last) {
                break;
            }
            owner = old.ownerOf(current);
        }

        uint size = current - start;

        require(size > 0, "size is zero");

        uint16[] memory protos = new uint16[](size);
        uint8[] memory qualities = new uint8[](size);

         
        IM memory im;
        
        uint count = 0;

        for (uint i = 0; i < size; i++) {
            (im.proto, im.purity) = old.getCard(start+i);
            im.p = convertProto(im.proto);
            im.q = convertPurity(im.purity);
            if (im.p > 377) {
                im.id = cards.mintCard(first, im.p, im.q);
                emit NonGenesisMigrated(first, start + i, im.id);
            } else {
                protos[count] = im.p;
                qualities[count] = im.q;
                count++;
            }
        }

         
        assembly{mstore(protos, count)}
        assembly{mstore(qualities, count)}

        uint newStart;
        if (count <= threshold) {
            newStart = cards.mintCards(first, protos, qualities);
        } else {
            newStart = cards.batchMintCards(first, protos, qualities);
        }

        migrated = current;

        emit Migrated(first, start, current, newStart);

        return current;
    }


    function convertPurity(uint16 purity) public pure returns (uint8) {
        return uint8((purity / 1000) + 2);
    }

    function convertProto(uint16 proto) public view returns (uint16) {
        if (proto >= 1 && proto <= 377) {
            return proto;
        }
         
        if (proto == 380) {
            return 400;
        }
         
        if (proto == 394) {
            return 401;
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
        require(false, "unrecognised proto");
    }

    uint16[] internal ebs = [400, 413, 414, 421, 427, 428, 389, 415, 416, 422, 424, 425, 426, 382, 420, 417];

    function getEtherbotsIndex(uint16 proto) public view returns (bool, uint16) {
        for (uint16 i = 0; i < ebs.length; i++) {
            if (ebs[i] == proto) {
                return (true, i);
            }
        }
        return (false, 0);
    }

}