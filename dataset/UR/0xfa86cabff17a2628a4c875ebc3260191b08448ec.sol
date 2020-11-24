 

pragma solidity ^0.5.2 <0.6.0;

contract Ownable {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

     
    constructor () internal {
        _owner = msg.sender;
        emit OwnershipTransferred(address(0), _owner);
    }

     
    function owner() public view returns (address) {
        return _owner;
    }

     
    modifier onlyOwner() {
        require(isOwner());
        _;
    }

     
    function isOwner() public view returns (bool) {
        return msg.sender == _owner;
    }

     
    function renounceOwnership() public onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

     
    function transferOwnership(address newOwner) public onlyOwner {
        _transferOwnership(newOwner);
    }

     
    function _transferOwnership(address newOwner) internal {
        require(newOwner != address(0));
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}
library RLP {

    uint constant DATA_SHORT_START = 0x80;
    uint constant DATA_LONG_START = 0xB8;
    uint constant LIST_SHORT_START = 0xC0;
    uint constant LIST_LONG_START = 0xF8;

    uint constant DATA_LONG_OFFSET = 0xB7;
    uint constant LIST_LONG_OFFSET = 0xF7;


    struct RLPItem {
        uint _unsafe_memPtr;     
        uint _unsafe_length;     
    }

    struct Iterator {
        RLPItem _unsafe_item;    
        uint _unsafe_nextPtr;    
    }

     

    function next(Iterator memory self) internal pure returns (RLPItem memory subItem) {
        if(hasNext(self)) {
            uint256 ptr = self._unsafe_nextPtr;
            uint256 itemLength = _itemLength(ptr);
            subItem._unsafe_memPtr = ptr;
            subItem._unsafe_length = itemLength;
            self._unsafe_nextPtr = ptr + itemLength;
        }
        else
            revert();
    }

    function next(Iterator memory self, bool strict) internal pure returns (RLPItem memory subItem) {
        subItem = next(self);
        if(strict && !_validate(subItem))
            revert();
        return subItem;
    }

    function hasNext(
        Iterator memory self
    ) internal pure returns (bool) {
        RLP.RLPItem memory item = self._unsafe_item;
        return self._unsafe_nextPtr < item._unsafe_memPtr + item._unsafe_length;
    }

     

     
     
     
    function toRLPItem(bytes memory self) internal pure returns (RLPItem memory) {
        uint len = self.length;
        if (len == 0) {
            return RLPItem(0, 0);
        }
        uint memPtr;
        assembly {
            memPtr := add(self, 0x20)
        }
        return RLPItem(memPtr, len);
    }

     
     
     
     
    function toRLPItem(bytes memory self, bool strict) internal pure returns (RLPItem memory) {
        RLP.RLPItem memory item = toRLPItem(self);
        if(strict) {
            uint len = self.length;
            if(_payloadOffset(item) > len)
                revert();
            if(_itemLength(item._unsafe_memPtr) != len)
                revert();
            if(!_validate(item))
                revert();
        }
        return item;
    }

     
     
     
    function isNull(RLPItem memory self) internal pure returns (bool ret) {
        return self._unsafe_length == 0;
    }

     
     
     
    function isList(RLPItem memory self) internal pure returns (bool ret) {
        if (self._unsafe_length == 0)
            return false;
        uint memPtr = self._unsafe_memPtr;
        assembly {
            ret := iszero(lt(byte(0, mload(memPtr)), 0xC0))
        }
    }

     
     
     
    function isData(RLPItem memory self) internal pure returns (bool ret) {
        if (self._unsafe_length == 0)
            return false;
        uint memPtr = self._unsafe_memPtr;
        assembly {
            ret := lt(byte(0, mload(memPtr)), 0xC0)
        }
    }

     
     
     
    function isEmpty(RLPItem memory self) internal pure returns (bool ret) {
        if(isNull(self))
            return false;
        uint b0;
        uint memPtr = self._unsafe_memPtr;
        assembly {
            b0 := byte(0, mload(memPtr))
        }
        return (b0 == DATA_SHORT_START || b0 == LIST_SHORT_START);
    }

     
     
     
    function items(RLPItem memory self) internal pure returns (uint) {
        if (!isList(self))
            return 0;
        uint b0;
        uint memPtr = self._unsafe_memPtr;
        assembly {
            b0 := byte(0, mload(memPtr))
        }
        uint pos = memPtr + _payloadOffset(self);
        uint last = memPtr + self._unsafe_length - 1;
        uint itms;
        while(pos <= last) {
            pos += _itemLength(pos);
            itms++;
        }
        return itms;
    }

     
     
     
    function iterator(RLPItem memory self) internal pure returns (Iterator memory it) {
        require(isList(self));
        uint ptr = self._unsafe_memPtr + _payloadOffset(self);
        it._unsafe_item = self;
        it._unsafe_nextPtr = ptr;
    }

     
     
     
    function toBytes(RLPItem memory self) internal pure returns (bytes memory bts) {
        uint256 len = self._unsafe_length;
        if (len == 0)
            return bts;
        bts = new bytes(len);
        _copyToBytes(self._unsafe_memPtr, bts, len);
 
 
 
 
 
 
 
 
 
 
 
 
 
 
    }

     
     
     
     
    function toData(RLPItem memory self) internal pure returns (bytes memory bts) {
        require(isData(self));
        (uint256 rStartPos, uint256 len) = _decode(self);
        bts = new bytes(len);
        _copyToBytes(rStartPos, bts, len);
    }

     
     
     
     
    function toList(RLPItem memory self) internal pure returns (RLPItem[] memory list) {
        require(isList(self));
        uint256 numItems = items(self);
        list = new RLPItem[](numItems);
        RLP.Iterator memory it = iterator(self);
        uint idx;
        while(hasNext(it)) {
            list[idx] = next(it);
            idx++;
        }
    }

     
     
     
     
    function toAscii(RLPItem memory self) internal pure returns (string memory str) {
        require(isData(self));
        (uint256 rStartPos, uint256 len) = _decode(self);
        bytes memory bts = new bytes(len);
        _copyToBytes(rStartPos, bts, len);
        str = string(bts);
    }

     
     
     
     
    function toUint(RLPItem memory self) internal pure returns (uint data) {
        require(isData(self));
        (uint256 rStartPos, uint256 len) = _decode(self);
        require(len <= 32);
        assembly {
            data := div(mload(rStartPos), exp(256, sub(32, len)))
        }
    }

     
     
     
     
    function toBool(RLPItem memory self) internal pure returns (bool data) {
        require(isData(self));
        (uint256 rStartPos, uint256 len) = _decode(self);
        require(len == 1);
        uint temp;
        assembly {
            temp := byte(0, mload(rStartPos))
        }
        require(temp == 1 || temp == 0);
        return temp == 1 ? true : false;
    }

     
     
     
     
    function toByte(RLPItem memory self)
    internal
    pure
    returns (byte data)
    {
        require(isData(self));

        (uint256 rStartPos, uint256 len) = _decode(self);

        require(len == 1);

        byte temp;
        assembly {
            temp := byte(0, mload(rStartPos))
        }
        return temp;
    }

     
     
     
     
    function toInt(RLPItem memory self)
    internal
    pure
    returns (int data)
    {
        return int(toUint(self));
    }

     
     
     
     
    function toBytes32(RLPItem memory self)
    internal
    pure
    returns (bytes32 data)
    {
        return bytes32(toUint(self));
    }

     
     
     
     
    function toAddress(RLPItem memory self)
    internal
    pure
    returns (address data)
    {
        (, uint256 len) = _decode(self);
        require(len <= 20);
        return address(toUint(self));
    }

     
    function _payloadOffset(RLPItem memory self)
    private
    pure
    returns (uint)
    {
        if(self._unsafe_length == 0)
            return 0;
        uint b0;
        uint memPtr = self._unsafe_memPtr;
        assembly {
            b0 := byte(0, mload(memPtr))
        }
        if(b0 < DATA_SHORT_START)
            return 0;
        if(b0 < DATA_LONG_START || (b0 >= LIST_SHORT_START && b0 < LIST_LONG_START))
            return 1;
        if(b0 < LIST_SHORT_START)
            return b0 - DATA_LONG_OFFSET + 1;
        return b0 - LIST_LONG_OFFSET + 1;
    }

     
    function _itemLength(uint memPtr)
    private
    pure
    returns (uint len)
    {
        uint b0;
        assembly {
            b0 := byte(0, mload(memPtr))
        }
        if (b0 < DATA_SHORT_START)
            len = 1;
        else if (b0 < DATA_LONG_START)
            len = b0 - DATA_SHORT_START + 1;
        else if (b0 < LIST_SHORT_START) {
            assembly {
                let bLen := sub(b0, 0xB7)  
                let dLen := div(mload(add(memPtr, 1)), exp(256, sub(32, bLen)))  
                len := add(1, add(bLen, dLen))  
            }
        } else if (b0 < LIST_LONG_START) {
            len = b0 - LIST_SHORT_START + 1;
        } else {
            assembly {
                let bLen := sub(b0, 0xF7)  
                let dLen := div(mload(add(memPtr, 1)), exp(256, sub(32, bLen)))  
                len := add(1, add(bLen, dLen))  
            }
        }
    }

     
    function _decode(RLPItem memory self)
    private
    pure
    returns (uint memPtr, uint len)
    {
        require(isData(self));
        uint b0;
        uint start = self._unsafe_memPtr;
        assembly {
            b0 := byte(0, mload(start))
        }
        if (b0 < DATA_SHORT_START) {
            memPtr = start;
            len = 1;
            return (memPtr, len);
        }
        if (b0 < DATA_LONG_START) {
            len = self._unsafe_length - 1;
            memPtr = start + 1;
        } else {
            uint bLen;
            assembly {
                bLen := sub(b0, 0xB7)  
            }
            len = self._unsafe_length - 1 - bLen;
            memPtr = start + bLen + 1;
        }
        return (memPtr, len);
    }

     
    function _copyToBytes(
        uint btsPtr,
        bytes memory tgt,
        uint btsLen) private pure
    {
         
         
        assembly {
            {
                let words := div(add(btsLen, 31), 32)
                let rOffset := btsPtr
                let wOffset := add(tgt, 0x20)

                for { let i := 0 } lt(i, words) { i := add(i, 1) } {
                    let offset := mul(i, 0x20)
                    mstore(add(wOffset, offset), mload(add(rOffset, offset)))
                }

                mstore(add(tgt, add(0x20, mload(tgt))), 0)
            }

        }
    }

     
    function _validate(RLPItem memory self)
    private
    pure
    returns (bool ret)
    {
         
        uint b0;
        uint b1;
        uint memPtr = self._unsafe_memPtr;
        assembly {
            b0 := byte(0, mload(memPtr))
            b1 := byte(1, mload(memPtr))
        }
        if(b0 == DATA_SHORT_START + 1 && b1 < DATA_SHORT_START)
            return false;
        return true;
    }
}
library Object {
    using RLP for bytes;
    using RLP for bytes[];
    using RLP for RLP.RLPItem;
    using RLP for RLP.Iterator;

    struct Data {
        uint sura;
        uint ayat;
        bytes text;
    }

    function createData(bytes memory dataBytes)
        internal
        pure
        returns (Data memory)
    {
        RLP.RLPItem[] memory dataList = dataBytes.toRLPItem().toList();
        return Data({
            sura: dataList[0].toUint(),
            ayat: dataList[1].toUint(),
            text: dataList[2].toBytes()
        });
    }
}

contract Storage is Ownable {
    using Object for bytes;
    using RLP for bytes;
    using RLP for bytes[];
    using RLP for RLP.RLPItem;
    using RLP for RLP.Iterator;

    struct coord {
        uint sura;
        uint ayat;
    }

     
    mapping(bytes32 => bytes) public content;
    mapping(uint => mapping(uint => bytes32)) public coordinates;
    mapping(bytes32 => coord[]) public all_coordinates;

     
    function add_content(
        bytes memory text,
        uint sura,
        uint ayat
    ) public onlyOwner {
        bytes32 hash = keccak256(text);
        if (coordinates[sura][ayat] != 0x0000000000000000000000000000000000000000000000000000000000000000) {
            return;
        }

        coordinates[sura][ayat] = hash;
        all_coordinates[hash].push(coord({sura:sura, ayat: ayat}));
        content[hash] = text;
    }

     
    function add_data(bytes memory data) public onlyOwner {
        RLP.RLPItem[] memory list = data.toRLPItem().toList();

        for (uint index = 0; index < list.length; index++) {
            RLP.RLPItem[] memory item = list[index].toList();

            uint sura = item[0].toUint();
            uint ayat = item[1].toUint();
            bytes memory text = item[2].toData();

            add_content(text, sura, ayat);
        }
    }

     
    function get_ayat_text_by_hash(
        bytes32 ayat_hash
    ) public view returns (bytes  memory text) {
        text = content[ayat_hash];
    }

     
    function get_ayat_text_by_coordinates(
        uint sura,
        uint ayat
    ) public view returns (bytes memory text) {
        bytes32 hash = coordinates[sura][ayat];
        text = content[hash];
    }

     
    function get_ayats_length(
        bytes32 hash
    ) public view returns (uint) {
        return all_coordinates[hash].length;
    }

     
    function get_ayat_coordinates_by_index(
        bytes32 hash,
        uint index
    ) public view returns (uint sura, uint ayat) {
        coord memory data = all_coordinates[hash][index];
        sura = data.sura;
        ayat = data.ayat;
    }

     
    function check_ayat_text(
        bytes memory text
    ) public view returns(bool) {
        bytes32 hash = keccak256(text);
        bytes memory ayat_data = content[hash];
        return ayat_data.length != 0;
    }
}