 

 

pragma solidity ^0.5.0;

 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 

 
contract EIP20Interface {


     

    event Transfer(
        address indexed _from,
        address indexed _to,
        uint256 _value
    );

    event Approval(
        address indexed _owner,
        address indexed _spender,
        uint256 _value
    );


     

     
    function name() public view returns (string memory tokenName_);

     
    function symbol() public view returns (string memory tokenSymbol_);

     
    function decimals() public view returns (uint8 tokenDecimals_);

     
    function totalSupply()
        public
        view
        returns (uint256 totalTokenSupply_);

     
    function balanceOf(address _owner) public view returns (uint256 balance_);

     
    function allowance(
        address _owner,
        address _spender
    )
        public
        view
        returns (uint256 allowance_);


     
    function transfer(
        address _to,
        uint256 _value
    )
        public
        returns (bool success_);

     
    function transferFrom(
        address _from,
        address _to,
        uint256 _value
    )
        public
        returns (bool success_);

     
    function approve(
        address _spender,
        uint256 _value
    )
        public
        returns (bool success_);

}

 

pragma solidity ^0.5.0;

 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 


 
library SafeMath {

     

     
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
         
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(
            c / a == b,
            "Overflow when multiplying."
        );

        return c;
    }

     
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
         
        require(
            b > 0,
            "Cannot do attempted division by less than or equal to zero."
        );
        uint256 c = a / b;

         
         

        return c;
    }

     
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(
            b <= a,
            "Underflow when subtracting."
        );
        uint256 c = a - b;

        return c;
    }

     
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(
            c >= a,
            "Overflow when adding."
        );

        return c;
    }

     
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(
            b != 0,
            "Cannot do attempted division by zero (in `mod()`)."
        );

        return a % b;
    }
}

 

pragma solidity ^0.5.0;

 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 



 
contract SimpleStake {

     

    using SafeMath for uint256;


     

     
    event ReleasedStake(
        address indexed _gateway,
        address indexed _to,
        uint256 _amount
    );


     

     
    EIP20Interface public token;

     
    address public gateway;


     

     
    modifier onlyGateway() {
        require(
            msg.sender == gateway,
            "Only gateway can call the function."
        );
        _;
    }


     

     
    constructor(
        EIP20Interface _token,
        address _gateway
    )
        public
    {
        require(
            address(_token) != address(0),
            "Token contract address must not be zero."
        );
        require(
            _gateway != address(0),
            "Gateway contract address must not be zero."
        );

        token = _token;
        gateway = _gateway;
    }


     

     
    function releaseTo(
        address _to,
        uint256 _amount
    )
        external
        onlyGateway
        returns (bool success_)
    {
        require(
            token.transfer(_to, _amount) == true,
            "Token transfer must success."
        );

        emit ReleasedStake(msg.sender, _to, _amount);

        success_ = true;
    }

     
    function getTotalStake()
        external
        view
        returns (uint256 stakedAmount_)
    {
        stakedAmount_ = token.balanceOf(address(this));
    }
}

 

pragma solidity ^0.5.0;

library BytesLib {
    function concat(
        bytes memory _preBytes,
        bytes memory _postBytes
    )
        internal
        pure returns (bytes memory bytes_)
    {
         
        assembly {
             
             
            bytes_ := mload(0x40)

             
             
            let length := mload(_preBytes)
            mstore(bytes_, length)

             
             
             
            let mc := add(bytes_, 0x20)
             
             
            let end := add(mc, length)

            for {
                 
                 
                let cc := add(_preBytes, 0x20)
            } lt(mc, end) {
                 
                mc := add(mc, 0x20)
                cc := add(cc, 0x20)
            } {
                 
                 
                mstore(mc, mload(cc))
            }

             
             
             
            length := mload(_postBytes)
            mstore(bytes_, add(length, mload(bytes_)))

             
             
            mc := end
             
             
            end := add(mc, length)

            for {
                let cc := add(_postBytes, 0x20)
            } lt(mc, end) {
                mc := add(mc, 0x20)
                cc := add(cc, 0x20)
            } {
                mstore(mc, mload(cc))
            }

             
             
             
             
             
            mstore(0x40, and(
              add(add(end, iszero(add(length, mload(_preBytes)))), 31),
              not(31)  
            ))
        }
    }

     
    function leftPad(
        bytes memory _bytes
    )
        internal
        pure
        returns (bytes memory padded_)
    {
        bytes memory padding = new bytes(32 - _bytes.length);
        padded_ = concat(padding, _bytes);
    }

     
    function bytes32ToBytes(bytes32 _inBytes32)
        internal
        pure
        returns (bytes memory bytes_)
    {
        bytes_ = new bytes(32);

         
        assembly {
            mstore(add(32, bytes_), _inBytes32)
        }
    }

}

 

pragma solidity ^0.5.0;

 
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

     

     

    function next(
        Iterator memory self
    )
        internal
        pure
        returns (RLPItem memory subItem_)
    {
        require(hasNext(self));
        uint ptr = self._unsafe_nextPtr;
        uint itemLength = _itemLength(ptr);
        subItem_._unsafe_memPtr = ptr;
        subItem_._unsafe_length = itemLength;
        self._unsafe_nextPtr = ptr + itemLength;
    }

    function next(
        Iterator memory self,
        bool strict
    )
        internal
        pure
        returns (RLPItem memory subItem_)
    {
        subItem_ = next(self);
        require(!(strict && !_validate(subItem_)));
    }

    function hasNext(Iterator memory self) internal pure returns (bool) {
        RLPItem memory item = self._unsafe_item;
        return self._unsafe_nextPtr < item._unsafe_memPtr + item._unsafe_length;
    }

     

     
    function toRLPItem(
        bytes memory self
    )
        internal
        pure
        returns (RLPItem memory)
    {
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

     
    function toRLPItem(
        bytes memory self,
        bool strict
    )
        internal
        pure
        returns (RLPItem memory)
    {
        RLPItem memory item = toRLPItem(self);
        if(strict) {
            uint len = self.length;
            require(_payloadOffset(item) <= len);
            require(_itemLength(item._unsafe_memPtr) == len);
            require(_validate(item));
        }
        return item;
    }

     
    function isNull(RLPItem memory self) internal pure returns (bool ret) {
        return self._unsafe_length == 0;
    }

     
    function isList(RLPItem memory self) internal pure returns (bool ret) {
        if (self._unsafe_length == 0) {
            return false;
        }
        uint memPtr = self._unsafe_memPtr;

         
        assembly {
            ret := iszero(lt(byte(0, mload(memPtr)), 0xC0))
        }
    }

     
    function isData(RLPItem memory self) internal pure returns (bool ret) {
        if (self._unsafe_length == 0) {
            return false;
        }
        uint memPtr = self._unsafe_memPtr;

         
        assembly {
            ret := lt(byte(0, mload(memPtr)), 0xC0)
        }
    }

     
    function isEmpty(RLPItem memory self) internal pure returns (bool ret) {
        if(isNull(self)) {
            return false;
        }
        uint b0;
        uint memPtr = self._unsafe_memPtr;

         
        assembly {
            b0 := byte(0, mload(memPtr))
        }
        return (b0 == DATA_SHORT_START || b0 == LIST_SHORT_START);
    }

     
    function items(RLPItem memory self) internal pure returns (uint) {
        if (!isList(self)) {
            return 0;
        }
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

     
    function iterator(
        RLPItem memory self
    )
        internal
        pure
        returns (Iterator memory it_)
    {
        require (isList(self));
        uint ptr = self._unsafe_memPtr + _payloadOffset(self);
        it_._unsafe_item = self;
        it_._unsafe_nextPtr = ptr;
    }

     
    function toBytes(
        RLPItem memory self
    )
        internal
        pure
        returns (bytes memory bts_)
    {
        uint len = self._unsafe_length;
        if (len == 0) {
            return bts_;
        }
        bts_ = new bytes(len);
        _copyToBytes(self._unsafe_memPtr, bts_, len);
    }

     
    function toData(
        RLPItem memory self
    )
        internal
        pure
        returns (bytes memory bts_)
    {
        require(isData(self));
        uint rStartPos;
        uint len;
        (rStartPos, len) = _decode(self);
        bts_ = new bytes(len);
        _copyToBytes(rStartPos, bts_, len);
    }

     
    function toList(
        RLPItem memory self
    )
        internal
        pure
        returns (RLPItem[] memory list_)
    {
        require(isList(self));
        uint numItems = items(self);
        list_ = new RLPItem[](numItems);
        Iterator memory it = iterator(self);
        uint idx = 0;
        while(hasNext(it)) {
            list_[idx] = next(it);
            idx++;
        }
    }

     
    function toAscii(
        RLPItem memory self
    )
        internal
        pure
        returns (string memory str_)
    {
        require(isData(self));
        uint rStartPos;
        uint len;
        (rStartPos, len) = _decode(self);
        bytes memory bts = new bytes(len);
        _copyToBytes(rStartPos, bts, len);
        str_ = string(bts);
    }

     
    function toUint(RLPItem memory self) internal pure returns (uint data_) {
        require(isData(self));
        uint rStartPos;
        uint len;
        (rStartPos, len) = _decode(self);
        if (len > 32 || len == 0) {
            revert();
        }

         
        assembly {
            data_ := div(mload(rStartPos), exp(256, sub(32, len)))
        }
    }

     
    function toBool(RLPItem memory self) internal pure returns (bool data) {
        require(isData(self));
        uint rStartPos;
        uint len;
        (rStartPos, len) = _decode(self);
        require(len == 1);
        uint temp;

         
        assembly {
            temp := byte(0, mload(rStartPos))
        }
        require (temp <= 1);

        return temp == 1 ? true : false;
    }

     
    function toByte(RLPItem memory self) internal pure returns (byte data) {
        require(isData(self));
        uint rStartPos;
        uint len;
        (rStartPos, len) = _decode(self);
        require(len == 1);
        uint temp;

         
        assembly {
            temp := byte(0, mload(rStartPos))
        }

        return byte(uint8(temp));
    }

     
    function toInt(RLPItem memory self) internal pure returns (int data) {
        return int(toUint(self));
    }

     
    function toBytes32(
        RLPItem memory self
    )
        internal
        pure
        returns (bytes32 data)
    {
        return bytes32(toUint(self));
    }

     
    function toAddress(
        RLPItem memory self
    )
        internal
        pure
        returns (address data)
    {
        require(isData(self));
        uint rStartPos;
        uint len;
        (rStartPos, len) = _decode(self);
        require (len == 20);

         
        assembly {
            data := div(mload(rStartPos), exp(256, 12))
        }
    }

     
    function _payloadOffset(RLPItem memory self) private pure returns (uint) {
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

     
    function _itemLength(uint memPtr) private pure returns (uint len) {
        uint b0;

         
        assembly {
            b0 := byte(0, mload(memPtr))
        }
        if (b0 < DATA_SHORT_START) {
            len = 1;
        } else if (b0 < DATA_LONG_START) {
            len = b0 - DATA_SHORT_START + 1;
        } else if (b0 < LIST_SHORT_START) {
             
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

     
    function _decode(
        RLPItem memory self
    )
        private
        pure
        returns (uint memPtr_, uint len_)
    {
        require(isData(self));
        uint b0;
        uint start = self._unsafe_memPtr;

         
        assembly {
            b0 := byte(0, mload(start))
        }
        if (b0 < DATA_SHORT_START) {
            memPtr_ = start;
            len_ = 1;

            return (memPtr_, len_);
        }
        if (b0 < DATA_LONG_START) {
            len_ = self._unsafe_length - 1;
            memPtr_ = start + 1;
        } else {
            uint bLen;

             
            assembly {
                bLen := sub(b0, 0xB7)  
            }
            len_ = self._unsafe_length - 1 - bLen;
            memPtr_ = start + bLen + 1;
        }
    }

     
    function _copyToBytes(
        uint btsPtr,
        bytes memory tgt,
        uint btsLen
    )
        private
        pure
    {
         
         
         
        assembly {
                let i := 0  
                let stopOffset := add(btsLen, 31)
                let rOffset := btsPtr
                let wOffset := add(tgt, 32)
                for {} lt(i, stopOffset) { i := add(i, 32) }
                {
                    mstore(add(wOffset, i), mload(add(rOffset, i)))
                }
        }
    }

     
    function _validate(RLPItem memory self) private pure returns (bool ret) {
         
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

 

pragma solidity ^0.5.0;
 


library MerklePatriciaProof {
     
    function verify(
        bytes32 value,
        bytes calldata encodedPath,
        bytes calldata rlpParentNodes,
        bytes32 root
    )
        external
        pure
        returns (bool)
    {
        RLP.RLPItem memory item = RLP.toRLPItem(rlpParentNodes);
        RLP.RLPItem[] memory parentNodes = RLP.toList(item);

        bytes memory currentNode;
        RLP.RLPItem[] memory currentNodeList;

        bytes32 nodeKey = root;
        uint pathPtr = 0;

        bytes memory path = _getNibbleArray2(encodedPath);
        if(path.length == 0) {return false;}

        for (uint i=0; i<parentNodes.length; i++) {
            if(pathPtr > path.length) {return false;}

            currentNode = RLP.toBytes(parentNodes[i]);
            if(nodeKey != keccak256(abi.encodePacked(currentNode))) {return false;}
            currentNodeList = RLP.toList(parentNodes[i]);

            if(currentNodeList.length == 17) {
                if(pathPtr == path.length) {
                    if(keccak256(abi.encodePacked(RLP.toBytes(currentNodeList[16]))) == value) {
                        return true;
                    } else {
                        return false;
                    }
                }

                uint8 nextPathNibble = uint8(path[pathPtr]);
                if(nextPathNibble > 16) {return false;}
                nodeKey = RLP.toBytes32(currentNodeList[nextPathNibble]);
                pathPtr += 1;
            } else if(currentNodeList.length == 2) {

                 
                uint traverseLength = _nibblesToTraverse(RLP.toData(currentNodeList[0]), path, pathPtr);

                if(pathPtr + traverseLength == path.length) {  
                    if(keccak256(abi.encodePacked(RLP.toData(currentNodeList[1]))) == value) {
                        return true;
                    } else {
                        return false;
                    }
                } else if (traverseLength == 0) {  
                    return false;
                } else {  
                    pathPtr += traverseLength;
                    nodeKey = RLP.toBytes32(currentNodeList[1]);
                }

            } else {
                return false;
            }
        }
    }

    function verifyDebug(
        bytes32 value,
        bytes memory not_encodedPath,
        bytes memory rlpParentNodes,
        bytes32 root
    )
        public
        pure
        returns (bool res_, uint loc_, bytes memory path_debug_)
    {
        RLP.RLPItem memory item = RLP.toRLPItem(rlpParentNodes);
        RLP.RLPItem[] memory parentNodes = RLP.toList(item);

        bytes memory currentNode;
        RLP.RLPItem[] memory currentNodeList;

        bytes32 nodeKey = root;
        uint pathPtr = 0;

        bytes memory path = _getNibbleArray2(not_encodedPath);
        path_debug_ = path;
        if(path.length == 0) {
            loc_ = 0;
            res_ = false;
            return (res_, loc_, path_debug_);
        }

        for (uint i=0; i<parentNodes.length; i++) {
            if(pathPtr > path.length) {
                loc_ = 1;
                res_ = false;
                return (res_, loc_, path_debug_);
            }

            currentNode = RLP.toBytes(parentNodes[i]);
            if(nodeKey != keccak256(abi.encodePacked(currentNode))) {
                res_ = false;
                loc_ = 100 + i;
                return (res_, loc_, path_debug_);
            }
            currentNodeList = RLP.toList(parentNodes[i]);

            loc_ = currentNodeList.length;

            if(currentNodeList.length == 17) {
                if(pathPtr == path.length) {
                    if(keccak256(abi.encodePacked(RLP.toBytes(currentNodeList[16]))) == value) {
                        res_ = true;
                        return (res_, loc_, path_debug_);
                    } else {
                        loc_ = 3;
                        return (res_, loc_, path_debug_);
                    }
                }

                uint8 nextPathNibble = uint8(path[pathPtr]);
                if(nextPathNibble > 16) {
                    loc_ = 4;
                    return (res_, loc_, path_debug_);
                }
                nodeKey = RLP.toBytes32(currentNodeList[nextPathNibble]);
                pathPtr += 1;
            } else if(currentNodeList.length == 2) {
                pathPtr += _nibblesToTraverse(RLP.toData(currentNodeList[0]), path, pathPtr);

                if(pathPtr == path.length) { 
                    if(keccak256(abi.encodePacked(RLP.toData(currentNodeList[1]))) == value) {
                        res_ = true;
                        return (res_, loc_, path_debug_);
                    } else {
                        loc_ = 5;
                        return (res_, loc_, path_debug_);
                    }
                }
                 
                if(_nibblesToTraverse(RLP.toData(currentNodeList[0]), path, pathPtr) == 0) {
                    loc_ = 6;
                    res_ = (keccak256(abi.encodePacked()) == value);
                    return (res_, loc_, path_debug_);
                }

                nodeKey = RLP.toBytes32(currentNodeList[1]);
            } else {
                loc_ = 7;
                return (res_, loc_, path_debug_);
            }
        }

        loc_ = 8;
    }

    function _nibblesToTraverse(
        bytes memory encodedPartialPath,
        bytes memory path,
        uint pathPtr
    )
        private
        pure
        returns (uint len_)
    {
         
         
        bytes memory partialPath = _getNibbleArray(encodedPartialPath);
        bytes memory slicedPath = new bytes(partialPath.length);

         
         
        for(uint i=pathPtr; i<pathPtr+partialPath.length; i++) {
            byte pathNibble = path[i];
            slicedPath[i-pathPtr] = pathNibble;
        }

        if(keccak256(abi.encodePacked(partialPath)) == keccak256(abi.encodePacked(slicedPath))) {
            len_ = partialPath.length;
        } else {
            len_ = 0;
        }
    }

     
    function _getNibbleArray(
        bytes memory b
    )
        private
        pure
        returns (bytes memory nibbles_)
    {
        if(b.length>0) {
            uint8 offset;
            uint8 hpNibble = uint8(_getNthNibbleOfBytes(0,b));
            if(hpNibble == 1 || hpNibble == 3) {
                nibbles_ = new bytes(b.length*2-1);
                byte oddNibble = _getNthNibbleOfBytes(1,b);
                nibbles_[0] = oddNibble;
                offset = 1;
            } else {
                nibbles_ = new bytes(b.length*2-2);
                offset = 0;
            }

            for(uint i=offset; i<nibbles_.length; i++) {
                nibbles_[i] = _getNthNibbleOfBytes(i-offset+2,b);
            }
        }
    }

     
    function _getNibbleArray2(
        bytes memory b
    )
        private
        pure
        returns (bytes memory nibbles_)
    {
        nibbles_ = new bytes(b.length*2);
        for (uint i = 0; i < nibbles_.length; i++) {
            nibbles_[i] = _getNthNibbleOfBytes(i, b);
        }
    }

    function _getNthNibbleOfBytes(
        uint n,
        bytes memory str
    )
        private
        pure returns (byte)
    {
        return byte(n%2==0 ? uint8(str[n/2])/0x10 : uint8(str[n/2])%0x10);
    }
}

 

pragma solidity ^0.5.0;

 
 
 
 
 
 
 
 
 
 
 
 
 
 



library GatewayLib {

     

    bytes32 constant public STAKE_INTENT_TYPEHASH = keccak256(
        abi.encode(
            "StakeIntent(uint256 amount,address beneficiary,address gateway)"
        )
    );

    bytes32 constant public REDEEM_INTENT_TYPEHASH = keccak256(
        abi.encode(
            "RedeemIntent(uint256 amount,address beneficiary,address gateway)"
        )
    );


     

     
    function proveAccount(
        bytes calldata _rlpAccount,
        bytes calldata _rlpParentNodes,
        bytes calldata _encodedPath,
        bytes32 _stateRoot
    )
        external
        pure
        returns (bytes32 storageRoot_)
    {
         
        RLP.RLPItem memory accountItem = RLP.toRLPItem(_rlpAccount);

         
        RLP.RLPItem[] memory accountArray = RLP.toList(accountItem);

         
        storageRoot_ = RLP.toBytes32(accountArray[2]);

         
        bytes32 hashedAccount = keccak256(
            abi.encodePacked(_rlpAccount)
        );

         
        require(
            MerklePatriciaProof.verify(
                hashedAccount,
                _encodedPath,
                _rlpParentNodes,
                _stateRoot
            ),
            "Account proof is not verified."
        );

    }

     
    function hashStakeIntent(
        uint256 _amount,
        address _beneficiary,
        address _gateway
    )
        external
        pure
        returns (bytes32 stakeIntentHash_)
    {
        stakeIntentHash_ = keccak256(
            abi.encode(
                STAKE_INTENT_TYPEHASH,
                _amount,
                _beneficiary,
                _gateway
            )
        );
    }

     
    function hashRedeemIntent(
        uint256 _amount,
        address _beneficiary,
        address _gateway
    )
        external
        pure
        returns (bytes32 redeemIntentHash_)
    {
        redeemIntentHash_ = keccak256(
            abi.encode(
                REDEEM_INTENT_TYPEHASH,
                _amount,
                _beneficiary,
                _gateway
            )
        );
    }
}

 

pragma solidity ^0.5.0;

 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 




library MessageBus {

     

    using SafeMath for uint256;


     

     
    enum MessageStatus {
        Undeclared,
        Declared,
        Progressed,
        DeclaredRevocation,
        Revoked
    }

     
    enum MessageBoxType {
        Outbox,
        Inbox
    }


     

     
    struct MessageBox {

         
        mapping(bytes32 => MessageStatus) outbox;

         
        mapping(bytes32 => MessageStatus) inbox;
    }

     
    struct Message {

         
        bytes32 intentHash;

         
        uint256 nonce;

         
        uint256 gasPrice;

         
        uint256 gasLimit;

         
        address sender;

         
        bytes32 hashLock;

         
        uint256 gasConsumed;
    }


     

    bytes32 public constant MESSAGE_TYPEHASH = keccak256(
        abi.encode(
            "Message(bytes32 intentHash,uint256 nonce,uint256 gasPrice,uint256 gasLimit,address sender,bytes32 hashLock)"
        )
    );

     
    uint8 public constant OUTBOX_OFFSET = 0;

     
    uint8 public constant INBOX_OFFSET = 1;


     

     
    function declareMessage(
        MessageBox storage _messageBox,
        Message storage _message
    )
        external
        returns (bytes32 messageHash_)
    {
        messageHash_ = messageDigest(_message);
        require(
            _messageBox.outbox[messageHash_] == MessageStatus.Undeclared,
            "Message on source must be Undeclared."
        );

         
        _messageBox.outbox[messageHash_] = MessageStatus.Declared;
    }

     
    function confirmMessage(
        MessageBox storage _messageBox,
        Message storage _message,
        bytes calldata _rlpParentNodes,
        uint8 _messageBoxOffset,
        bytes32 _storageRoot
    )
        external
        returns (bytes32 messageHash_)
    {
        messageHash_ = messageDigest(_message);
        require(
            _messageBox.inbox[messageHash_] == MessageStatus.Undeclared,
            "Message on target must be Undeclared."
        );

         
        bytes memory path = BytesLib.bytes32ToBytes(
            storageVariablePathForStruct(
                _messageBoxOffset,
                OUTBOX_OFFSET,
                messageHash_
            )
        );

         
        require(
            MerklePatriciaProof.verify(
                keccak256(abi.encodePacked(MessageStatus.Declared)),
                path,
                _rlpParentNodes,
                _storageRoot
            ),
            "Merkle proof verification failed."
        );

         
        _messageBox.inbox[messageHash_] = MessageStatus.Declared;
    }

     
    function progressOutbox(
        MessageBox storage _messageBox,
        Message storage _message,
        bytes32 _unlockSecret
    )
        external
        returns (bytes32 messageHash_)
    {
        require(
            _message.hashLock == keccak256(abi.encode(_unlockSecret)),
            "Invalid unlock secret."
        );

        messageHash_ = messageDigest(_message);
        require(
            _messageBox.outbox[messageHash_] == MessageStatus.Declared,
            "Message on source must be Declared."
        );

         
        _messageBox.outbox[messageHash_] = MessageStatus.Progressed;
    }

     
    function progressOutboxWithProof(
        MessageBox storage _messageBox,
        Message storage _message,
        bytes calldata _rlpParentNodes,
        uint8 _messageBoxOffset,
        bytes32 _storageRoot,
        MessageStatus _messageStatus
    )
        external
        returns (bytes32 messageHash_)
    {
        messageHash_ = messageDigest(_message);

        if(_messageBox.outbox[messageHash_] == MessageStatus.Declared) {

             
            require(
                _messageStatus == MessageStatus.Declared ||
                _messageStatus == MessageStatus.Progressed,
                "Message on target must be Declared or Progressed."
            );

        } else if (_messageBox.outbox[messageHash_] == MessageStatus.DeclaredRevocation) {

             
            require(
                _messageStatus == MessageStatus.Progressed,
                "Message on target must be Progressed."
            );

        } else {
            revert("Status of message on source must be Declared or DeclareRevocation.");
        }

        bytes memory storagePath = BytesLib.bytes32ToBytes(
            storageVariablePathForStruct(
                _messageBoxOffset,
                INBOX_OFFSET,
                messageHash_
            )
        );

         
        require(
            MerklePatriciaProof.verify(
                keccak256(abi.encodePacked(_messageStatus)),
                storagePath,
                _rlpParentNodes,
                _storageRoot),
            "Merkle proof verification failed."
        );

        _messageBox.outbox[messageHash_] = MessageStatus.Progressed;
    }

     
    function progressInbox(
        MessageBox storage _messageBox,
        Message storage _message,
        bytes32 _unlockSecret
    )
        external
        returns (bytes32 messageHash_)
    {
        require(
            _message.hashLock == keccak256(abi.encode(_unlockSecret)),
            "Invalid unlock secret."
        );

        messageHash_ = messageDigest(_message);
        require(
            _messageBox.inbox[messageHash_] == MessageStatus.Declared,
            "Message on target status must be Declared."
        );

        _messageBox.inbox[messageHash_] = MessageStatus.Progressed;
    }

     
    function progressInboxWithProof(
        MessageBox storage _messageBox,
        Message storage _message,
        bytes calldata _rlpParentNodes,
        uint8 _messageBoxOffset,
        bytes32 _storageRoot,
        MessageStatus _messageStatus
    )
        external
        returns (bytes32 messageHash_)
    {
         
        require(
            _messageStatus == MessageStatus.Declared ||
            _messageStatus == MessageStatus.Progressed,
            "Message on source must be Declared or Progressed."
        );

        messageHash_ = messageDigest(_message);
        require(
            _messageBox.inbox[messageHash_] == MessageStatus.Declared,
            "Message on target must be Declared."
        );

         
        bytes memory path = BytesLib.bytes32ToBytes(
            storageVariablePathForStruct(
                _messageBoxOffset,
                OUTBOX_OFFSET,
                messageHash_
            )
        );

         
        require(
            MerklePatriciaProof.verify(
                keccak256(abi.encodePacked(_messageStatus)),
                path,
                _rlpParentNodes,
                _storageRoot
            ),
            "Merkle proof verification failed."
        );

        _messageBox.inbox[messageHash_] = MessageStatus.Progressed;
    }

     
    function declareRevocationMessage(
        MessageBox storage _messageBox,
        Message storage _message
    )
        external
        returns (bytes32 messageHash_)
    {
        messageHash_ = messageDigest(_message);
        require(
            _messageBox.outbox[messageHash_] == MessageStatus.Declared,
            "Message on source must be Declared."
        );

        _messageBox.outbox[messageHash_] = MessageStatus.DeclaredRevocation;
    }

     
    function confirmRevocation(
        MessageBox storage _messageBox,
        Message storage _message,
        bytes calldata _rlpParentNodes,
        uint8 _messageBoxOffset,
        bytes32 _storageRoot
    )
        external
        returns (bytes32 messageHash_)
    {
        messageHash_ = messageDigest(_message);
        require(
            _messageBox.inbox[messageHash_] == MessageStatus.Declared,
            "Message on target must be Declared."
        );

         
        bytes memory path = BytesLib.bytes32ToBytes(
            storageVariablePathForStruct(
                _messageBoxOffset,
                OUTBOX_OFFSET,
                messageHash_
            )
        );

         
        require(
            MerklePatriciaProof.verify(
                keccak256(abi.encodePacked(MessageStatus.DeclaredRevocation)),
                path,
                _rlpParentNodes,
                _storageRoot
            ),
            "Merkle proof verification failed."
        );

        _messageBox.inbox[messageHash_] = MessageStatus.Revoked;
    }

     
    function progressOutboxRevocation(
        MessageBox storage _messageBox,
        Message storage _message,
        uint8 _messageBoxOffset,
        bytes calldata _rlpParentNodes,
        bytes32 _storageRoot,
        MessageStatus _messageStatus
    )
        external
        returns (bytes32 messageHash_)
    {
        require(
            _messageStatus == MessageStatus.Revoked,
            "Message on target status must be Revoked."
        );

        messageHash_ = messageDigest(_message);
        require(
            _messageBox.outbox[messageHash_] ==
            MessageStatus.DeclaredRevocation,
            "Message status on source must be DeclaredRevocation."
        );

         
        bytes memory path = BytesLib.bytes32ToBytes(
            storageVariablePathForStruct(
                _messageBoxOffset,
                INBOX_OFFSET,
                messageHash_
            )
        );

         
        require(
            MerklePatriciaProof.verify(
                keccak256(abi.encodePacked(_messageStatus)),
                path,
                _rlpParentNodes,
                _storageRoot
            ),
            "Merkle proof verification failed."
        );

        _messageBox.outbox[messageHash_] = MessageStatus.Revoked;
    }

     
    function messageTypehash() public pure returns(bytes32 messageTypehash_) {
        messageTypehash_ = MESSAGE_TYPEHASH;
    }


     

     
    function messageDigest(
        bytes32 _intentHash,
        uint256 _nonce,
        uint256 _gasPrice,
        uint256 _gasLimit,
        address _sender,
        bytes32 _hashLock
    )
        public
        pure
        returns (bytes32 messageHash_)
    {
        messageHash_ = keccak256(
            abi.encode(
                MESSAGE_TYPEHASH,
                _intentHash,
                _nonce,
                _gasPrice,
                _gasLimit,
                _sender,
                _hashLock
            )
        );
    }


     

     
    function messageDigest(
        Message storage _message
    )
        private
        view
        returns (bytes32 messageHash_)
    {
        messageHash_ = messageDigest(
            _message.intentHash,
            _message.nonce,
            _message.gasPrice,
            _message.gasLimit,
            _message.sender,
            _message.hashLock
        );
    }

     
    function storageVariablePathForStruct(
        uint8 _structPosition,
        uint8 _offset,
        bytes32 _key
    )
        private
        pure
        returns(bytes32 storagePath_)
    {
        if(_offset > 0){
            _structPosition = _structPosition + _offset;
        }

        bytes memory indexBytes = BytesLib.leftPad(
            BytesLib.bytes32ToBytes(bytes32(uint256(_structPosition)))
        );

        bytes memory keyBytes = BytesLib.leftPad(BytesLib.bytes32ToBytes(_key));
        bytes memory path = BytesLib.concat(keyBytes, indexBytes);

        storagePath_ = keccak256(
            abi.encodePacked(keccak256(abi.encodePacked(path)))
        );
    }
}

 

pragma solidity ^0.5.0;

 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 

 
interface OrganizationInterface {

     
    function isOrganization(
        address _organization
    )
        external
        view
        returns (bool isOrganization_);

     
    function isWorker(address _worker) external view returns (bool isWorker_);

}

 

pragma solidity ^0.5.0;

 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 


 
contract Organized {


     

     
    OrganizationInterface public organization;


     

    modifier onlyOrganization()
    {
        require(
            organization.isOrganization(msg.sender),
            "Only the organization is allowed to call this method."
        );

        _;
    }

    modifier onlyWorker()
    {
        require(
            organization.isWorker(msg.sender),
            "Only whitelisted workers are allowed to call this method."
        );

        _;
    }


     

     
    constructor(OrganizationInterface _organization) public {
        require(
            address(_organization) != address(0),
            "Organization contract address must not be zero."
        );

        organization = _organization;
    }

}

 

pragma solidity ^0.5.0;

 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 

 
interface StateRootInterface {

     
    function getLatestStateRootBlockHeight()
        external
        view
        returns (uint256 height_);

     
    function getStateRoot(uint256 _blockHeight)
        external
        view
        returns (bytes32 stateRoot_);

}

 

pragma solidity ^0.5.0;

 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 








 
contract GatewayBase is Organized {

     

    using SafeMath for uint256;


     

     
    event GatewayProven(
        address _gateway,
        uint256 _blockHeight,
        bytes32 _storageRoot,
        bool _wasAlreadyProved
    );

    event BountyChangeInitiated(
        uint256 _currentBounty,
        uint256 _proposedBounty,
        uint256 _unlockHeight
    );

    event BountyChangeConfirmed(
        uint256 _currentBounty,
        uint256 _changedBounty
    );


     

     
    uint8 constant MESSAGE_BOX_OFFSET = 7;

     
    uint8 constant REVOCATION_PENALTY = 150;

     
     
    uint256 public constant BOUNTY_CHANGE_UNLOCK_PERIOD = 201600;


     

     
    StateRootInterface public stateRootProvider;

     
    bytes public encodedGatewayPath;

     
    address public remoteGateway;

     
    uint256 public bounty;

     
    uint256 public proposedBounty;

     
    uint256 public proposedBountyUnlockHeight;


     

     
    MessageBus.MessageBox internal messageBox;

     
    mapping(bytes32 => MessageBus.Message) public messages;

     
    mapping(uint256 => bytes32) internal storageRoots;


     

     
    mapping(address => bytes32) private inboxActiveProcess;

     
    mapping(address => bytes32) private outboxActiveProcess;


     

     
    constructor(
        StateRootInterface _stateRootProvider,
        uint256 _bounty,
        OrganizationInterface _organization
    )
        Organized(_organization)
        public
    {
        require(
            address(_stateRootProvider) != address(0),
            "State root provider contract address must not be zero."
        );

        stateRootProvider = _stateRootProvider;
        bounty = _bounty;

         
        messageBox = MessageBus.MessageBox();
        encodedGatewayPath = '';
        remoteGateway = address(0);
    }


     

     
    function proveGateway(
        uint256 _blockHeight,
        bytes calldata _rlpAccount,
        bytes calldata _rlpParentNodes
    )
        external
        returns (bool  )
    {
         
        require(
            _rlpAccount.length != 0,
            "Length of RLP account must not be 0."
        );

         
        require(
            _rlpParentNodes.length != 0,
            "Length of RLP parent nodes is 0"
        );

        bytes32 stateRoot = stateRootProvider.getStateRoot(_blockHeight);

         
        require(
            stateRoot != bytes32(0),
            "State root must not be zero"
        );

         
        bytes32 provenStorageRoot = storageRoots[_blockHeight];

        if (provenStorageRoot != bytes32(0)) {

             
             
            emit GatewayProven(
                remoteGateway,
                _blockHeight,
                provenStorageRoot,
                true
            );

             
            return true;
        }

        bytes32 storageRoot = GatewayLib.proveAccount(
            _rlpAccount,
            _rlpParentNodes,
            encodedGatewayPath,
            stateRoot
        );

        storageRoots[_blockHeight] = storageRoot;

         
         
        emit GatewayProven(
            remoteGateway,
            _blockHeight,
            storageRoot,
            false
        );

        return true;
    }

     
    function getNonce(address _account)
        external
        view
        returns (uint256)
    {
         
        return _getOutboxNonce(_account);
    }

     
    function initiateBountyAmountChange(uint256 _proposedBounty)
        external
        onlyOrganization
        returns(uint256)
    {
        return initiateBountyAmountChangeInternal(_proposedBounty, BOUNTY_CHANGE_UNLOCK_PERIOD);
    }

     
    function confirmBountyAmountChange()
        external
        onlyOrganization
        returns (
            uint256 changedBountyAmount_,
            uint256 previousBountyAmount_
        )
    {
        require(
            proposedBounty != bounty,
            "Proposed bounty should be different from existing bounty."
        );
        require(
            proposedBountyUnlockHeight < block.number,
            "Confirm bounty amount change can only be done after unlock period."
        );

        changedBountyAmount_ = proposedBounty;
        previousBountyAmount_ = bounty;

        bounty = proposedBounty;

        proposedBounty = 0;
        proposedBountyUnlockHeight = 0;

        emit BountyChangeConfirmed(previousBountyAmount_, changedBountyAmount_);
    }

     
    function getOutboxMessageStatus(
        bytes32 _messageHash
    )
        external
        view
        returns (MessageBus.MessageStatus status_)
    {
        status_ = messageBox.outbox[_messageHash];
    }

     
    function getInboxMessageStatus(
        bytes32 _messageHash
    )
        external
        view
        returns (MessageBus.MessageStatus status_)
    {
        status_ = messageBox.inbox[_messageHash];
    }

     
    function getInboxActiveProcess(
        address _account
    )
        external
        view
        returns (
            bytes32 messageHash_,
            MessageBus.MessageStatus status_
        )
    {
        messageHash_ = inboxActiveProcess[_account];
        status_ = messageBox.inbox[messageHash_];
    }

     
    function getOutboxActiveProcess(
        address _account
    )
        external
        view
        returns (
            bytes32 messageHash_,
            MessageBus.MessageStatus status_
        )
    {
        messageHash_ = outboxActiveProcess[_account];
        status_ = messageBox.outbox[messageHash_];
    }


     

     
    function feeAmount(
        uint256 _gasConsumed,
        uint256 _gasLimit,
        uint256 _gasPrice,
        uint256 _initialGas
    )
        internal
        view
        returns (
            uint256 fee_,
            uint256 totalGasConsumed_
        )
    {
        totalGasConsumed_ = _initialGas.add(
            _gasConsumed
        ).sub(
            gasleft()
        );

        if (totalGasConsumed_ < _gasLimit) {
            fee_ = totalGasConsumed_.mul(_gasPrice);
        } else {
            fee_ = _gasLimit.mul(_gasPrice);
        }
    }

     
    function getMessage(
        bytes32 _intentHash,
        uint256 _accountNonce,
        uint256 _gasPrice,
        uint256 _gasLimit,
        address _account,
        bytes32 _hashLock
    )
        internal
        pure
        returns (MessageBus.Message memory)
    {
        return MessageBus.Message({
            intentHash : _intentHash,
            nonce : _accountNonce,
            gasPrice : _gasPrice,
            gasLimit : _gasLimit,
            sender : _account,
            hashLock : _hashLock,
            gasConsumed : 0
        });
    }

     
    function _getOutboxNonce(address _account)
        internal
        view
        returns (uint256  )
    {

        bytes32 previousProcessMessageHash = outboxActiveProcess[_account];
        return getMessageNonce(previousProcessMessageHash);
    }

     
    function _getInboxNonce(address _account)
        internal
        view
        returns (uint256  )
    {

        bytes32 previousProcessMessageHash = inboxActiveProcess[_account];
        return getMessageNonce(previousProcessMessageHash);
    }

     
    function storeMessage(
        MessageBus.Message memory _message
    )
        internal
        returns (bytes32 messageHash_)
    {
        messageHash_ = MessageBus.messageDigest(
            _message.intentHash,
            _message.nonce,
            _message.gasPrice,
            _message.gasLimit,
            _message.sender,
            _message.hashLock
        );

        messages[messageHash_] = _message;
    }

     
    function registerOutboxProcess(
        address _account,
        uint256 _nonce,
        bytes32 _messageHash

    )
        internal
    {
        require(
            _nonce == _getOutboxNonce(_account),
            "Invalid nonce."
        );

        bytes32 previousMessageHash = outboxActiveProcess[_account];

        if (previousMessageHash != bytes32(0)) {

            MessageBus.MessageStatus status =
                messageBox.outbox[previousMessageHash];

            require(
                status == MessageBus.MessageStatus.Progressed ||
                status == MessageBus.MessageStatus.Revoked,
                "Previous process is not completed."
            );

            delete messages[previousMessageHash];
        }

         
        outboxActiveProcess[_account] = _messageHash;

    }

     
    function registerInboxProcess(
        address _account,
        uint256 _nonce,
        bytes32 _messageHash
    )
        internal
    {
        require(
            _nonce == _getInboxNonce(_account),
            "Invalid nonce"
        );

        bytes32 previousMessageHash = inboxActiveProcess[_account];

        if (previousMessageHash != bytes32(0)) {

            MessageBus.MessageStatus status =
                messageBox.inbox[previousMessageHash];

            require(
                status == MessageBus.MessageStatus.Progressed ||
                status == MessageBus.MessageStatus.Revoked,
                "Previous process is not completed"
            );

            delete messages[previousMessageHash];
        }

         
        inboxActiveProcess[_account] = _messageHash;
    }

     
    function penaltyFromBounty(uint256 _bounty)
        internal
        pure
        returns(uint256 penalty_)
    {
        penalty_ = _bounty.mul(REVOCATION_PENALTY).div(100);
    }

     
    function initiateBountyAmountChangeInternal(
        uint256 _proposedBounty,
        uint256 _bountyChangePeriod
    )
        internal
        returns(uint256)
    {
        proposedBounty = _proposedBounty;
        proposedBountyUnlockHeight = block.number.add(_bountyChangePeriod);

        emit BountyChangeInitiated(
            bounty,
            _proposedBounty,
            proposedBountyUnlockHeight
        );

        return _proposedBounty;
    }

     

     
    function getMessageNonce(bytes32 _messageHash)
        private
        view
        returns(uint256)
    {
        if (_messageHash == bytes32(0)) {
            return 1;
        }

        MessageBus.Message storage message =
        messages[_messageHash];

        return message.nonce.add(1);
    }
}

 

pragma solidity ^0.5.0;

 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 


 




 
contract EIP20Gateway is GatewayBase {

     

     
    event StakeIntentDeclared(
        bytes32 indexed _messageHash,
        address _staker,
        uint256 _stakerNonce,
        address _beneficiary,
        uint256 _amount
    );

     
    event StakeProgressed(
        bytes32 indexed _messageHash,
        address _staker,
        uint256 _stakerNonce,
        uint256 _amount,
        bool _proofProgress,
        bytes32 _unlockSecret
    );

     
    event RevertStakeIntentDeclared(
        bytes32 indexed _messageHash,
        address _staker,
        uint256 _stakerNonce,
        uint256 _amount
    );

     
    event StakeReverted(
        bytes32 indexed _messageHash,
        address _staker,
        uint256 _stakerNonce,
        uint256 _amount
    );

     
    event RedeemIntentConfirmed(
        bytes32 indexed _messageHash,
        address _redeemer,
        uint256 _redeemerNonce,
        address _beneficiary,
        uint256 _amount,
        uint256 _blockHeight,
        bytes32 _hashLock
    );

     
    event UnstakeProgressed(
        bytes32 indexed _messageHash,
        address _redeemer,
        address _beneficiary,
        uint256 _redeemAmount,
        uint256 _unstakeAmount,
        uint256 _rewardAmount,
        bool _proofProgress,
        bytes32 _unlockSecret
    );

     
    event RevertRedeemIntentConfirmed(
        bytes32 indexed _messageHash,
        address _redeemer,
        uint256 _redeemerNonce,
        uint256 _amount
    );

     
    event RevertRedeemComplete(
        bytes32 indexed _messageHash,
        address _redeemer,
        uint256 _redeemerNonce,
        uint256 _amount
    );


     

     
    struct Stake {

         
        uint256 amount;

         
        address beneficiary;

         
        uint256 bounty;
    }

     
    struct Unstake {

         
        uint256 amount;

         
        address beneficiary;
    }


     

     
    bool public activated;

     
    SimpleStake public stakeVault;

     
    EIP20Interface public token;

     
    EIP20Interface public baseToken;

     
    address public burner;

     
    mapping(bytes32   => Stake) stakes;

     
    mapping(bytes32   => Unstake) unstakes;


     

     
    modifier isActive() {
        require(
            activated == true,
            "Gateway is not activated."
        );
        _;
    }


     

     
    constructor(
        EIP20Interface _token,
        EIP20Interface _baseToken,
        StateRootInterface _stateRootProvider,
        uint256 _bounty,
        OrganizationInterface _organization,
        address _burner
    )
        GatewayBase(
            _stateRootProvider,
            _bounty,
            _organization
        )
        public
    {
        require(
            address(_token) != address(0),
            "Token contract address must not be zero."
        );
        require(
            address(_baseToken) != address(0),
            "Base token contract address for bounty must not be zero"
        );
        token = _token;
        baseToken = _baseToken;
        burner = _burner;
         
        activated = false;
         
        stakeVault = new SimpleStake(_token, address(this));
    }


     

     
    function stake(
        uint256 _amount,
        address _beneficiary,
        uint256 _gasPrice,
        uint256 _gasLimit,
        uint256 _nonce,
        bytes32 _hashLock
    )
        external
        isActive
        returns (bytes32 messageHash_)
    {
        address staker = msg.sender;

        require(
            _amount > uint256(0),
            "Stake amount must not be zero."
        );

        require(
            _beneficiary != address(0),
            "Beneficiary address must not be zero."
        );

         
        require(
            _amount > _gasPrice.mul(_gasLimit),
            "Maximum possible reward must be less than the stake amount."
        );

         
        bytes32 intentHash = GatewayLib.hashStakeIntent(
            _amount,
            _beneficiary,
            address(this)
        );

        MessageBus.Message memory message = getMessage(
            intentHash,
            _nonce,
            _gasPrice,
            _gasLimit,
            staker,
            _hashLock
        );

        messageHash_ = storeMessage(message);

        registerOutboxProcess(
            staker,
            _nonce,
            messageHash_
        );

         
        stakes[messageHash_] = Stake({
            amount : _amount,
            beneficiary : _beneficiary,
            bounty : bounty
        });

         
        MessageBus.declareMessage(
            messageBox,
            messages[messageHash_]
        );

         
        require(
            token.transferFrom(staker, address(this), _amount),
            "Stake amount must be transferred to gateway"
        );

         
        require(
            baseToken.transferFrom(staker, address(this), bounty),
            "Bounty amount must be transferred to gateway"
        );

        emit StakeIntentDeclared(
            messageHash_,
            staker,
            _nonce,
            _beneficiary,
            _amount
        );
    }

     
    function progressStake(
        bytes32 _messageHash,
        bytes32 _unlockSecret
    )
        external
        returns (
            address staker_,
            uint256 stakeAmount_
        )
    {
        require(
            _messageHash != bytes32(0),
            "Message hash must not be zero"
        );

         
        MessageBus.Message storage message = messages[_messageHash];

         
        MessageBus.progressOutbox(
            messageBox,
            message,
            _unlockSecret
        );

        (staker_, stakeAmount_) = progressStakeInternal(
            _messageHash,
            message,
            _unlockSecret,
            false
        );
    }

     
    function progressStakeWithProof(
        bytes32 _messageHash,
        bytes calldata _rlpParentNodes,
        uint256 _blockHeight,
        uint256 _messageStatus
    )
        external
        returns (
            address staker_,
            uint256 stakeAmount_
        )
    {
        require(
            _messageHash != bytes32(0),
            "Message hash must not be zero."
        );
        require(
            _rlpParentNodes.length > 0,
            "RLP encoded parent nodes must not be zero."
        );

        bytes32 storageRoot = storageRoots[_blockHeight];

        require(
            storageRoot != bytes32(0),
            "Storage root must not be zero."
        );

         
        MessageBus.Message storage message = messages[_messageHash];

        MessageBus.progressOutboxWithProof(
            messageBox,
            message,
            _rlpParentNodes,
            MESSAGE_BOX_OFFSET,
            storageRoot,
            MessageBus.MessageStatus(_messageStatus)
        );

        (staker_, stakeAmount_) = progressStakeInternal(
            _messageHash,
            message,
            bytes32(0),
            true
        );
    }

     
    function revertStake(
        bytes32 _messageHash
    )
        external
        returns (
            address staker_,
            uint256 stakerNonce_,
            uint256 amount_
        )
    {
        require(
            _messageHash != bytes32(0),
            "Message hash must not be zero."
        );

        MessageBus.Message storage message = messages[_messageHash];

        require(
            message.sender == msg.sender,
            "Only staker can revert stake."
        );

         
        MessageBus.declareRevocationMessage(
            messageBox,
            message
        );

        staker_ = message.sender;
        stakerNonce_ = message.nonce;
        amount_ = stakes[_messageHash].amount;

         
        uint256 penalty = penaltyFromBounty(stakes[_messageHash].bounty);

         
        require(
            baseToken.transferFrom(msg.sender, burner, penalty),
            "Staker must approve gateway for penalty amount."
        );

        emit RevertStakeIntentDeclared(
            _messageHash,
            staker_,
            stakerNonce_,
            amount_
        );
    }

     
    function progressRevertStake(
        bytes32 _messageHash,
        uint256 _blockHeight,
        bytes calldata _rlpParentNodes
    )
        external
        returns (
            address staker_,
            uint256 stakerNonce_,
            uint256 amount_
        )
    {
        require(
            _messageHash != bytes32(0),
            "Message hash must not be zero."
        );
        require(
            _rlpParentNodes.length > 0,
            "RLP parent nodes must not be zero."
        );

         
        MessageBus.Message storage message = messages[_messageHash];
        require(
            message.intentHash != bytes32(0),
            "StakeIntentHash must not be zero."
        );

         
        bytes32 storageRoot = storageRoots[_blockHeight];
        require(
            storageRoot != bytes32(0),
            "Storage root must not be zero."
        );

        amount_ = stakes[_messageHash].amount;

        require(
            amount_ > 0,
            "Stake request must exist."
        );

        staker_ = message.sender;
        stakerNonce_ = message.nonce;
        uint256 stakeBounty = stakes[_messageHash].bounty;

         
        MessageBus.progressOutboxRevocation(
            messageBox,
            message,
            MESSAGE_BOX_OFFSET,
            _rlpParentNodes,
            storageRoot,
            MessageBus.MessageStatus.Revoked
        );

        delete stakes[_messageHash];

         
        token.transfer(message.sender, amount_);

         
        baseToken.transfer(burner, stakeBounty);

        emit StakeReverted(
            _messageHash,
            staker_,
            stakerNonce_,
            amount_
        );
    }

     
    function confirmRedeemIntent(
        address _redeemer,
        uint256 _redeemerNonce,
        address _beneficiary,
        uint256 _amount,
        uint256 _gasPrice,
        uint256 _gasLimit,
        uint256 _blockHeight,
        bytes32 _hashLock,
        bytes calldata _rlpParentNodes
    )
        external
        returns (bytes32 messageHash_)
    {
         
        uint256 initialGas = gasleft();

        require(
            _redeemer != address(0),
            "Redeemer address must not be zero."
        );
        require(
            _beneficiary != address(0),
            "Beneficiary address must not be zero."
        );
        require(
            _amount != 0,
            "Redeem amount must not be zero."
        );
        require(
            _rlpParentNodes.length > 0,
            "RLP encoded parent nodes must not be zero."
        );

         
        require(
            _amount > _gasPrice.mul(_gasLimit),
            "Maximum possible reward must be less than the redeem amount."
        );

        bytes32 intentHash = hashRedeemIntent(
            _amount,
            _beneficiary
        );

        MessageBus.Message memory message = MessageBus.Message(
            intentHash,
            _redeemerNonce,
            _gasPrice,
            _gasLimit,
            _redeemer,
            _hashLock,
            0  
        );
        messageHash_ = storeMessage(message);

        registerInboxProcess(
            message.sender,
            message.nonce,
            messageHash_
        );

        unstakes[messageHash_] = Unstake({
            amount : _amount,
            beneficiary : _beneficiary
        });

        confirmRedeemIntentInternal(
            messages[messageHash_],
            _blockHeight,
            _rlpParentNodes
        );

         
        emit RedeemIntentConfirmed(
            messageHash_,
            _redeemer,
            _redeemerNonce,
            _beneficiary,
            _amount,
            _blockHeight,
            _hashLock
        );

         
        messages[messageHash_].gasConsumed = initialGas.sub(gasleft());
    }

     
    function progressUnstake(
        bytes32 _messageHash,
        bytes32 _unlockSecret
    )
        external
        returns (
            uint256 redeemAmount_,
            uint256 unstakeAmount_,
            uint256 rewardAmount_
        )
    {
         
        uint256 initialGas = gasleft();

        require(
            _messageHash != bytes32(0),
            "Message hash must not be zero."
        );

        MessageBus.Message storage message = messages[_messageHash];

        MessageBus.progressInbox(
            messageBox,
            message,
            _unlockSecret
        );
        (redeemAmount_, unstakeAmount_, rewardAmount_) =
        progressUnstakeInternal(_messageHash, initialGas, _unlockSecret, false);

    }

     
    function penalty(bytes32 _messageHash)
        external
        view
        returns (uint256 penalty_)
    {
        penalty_ = super.penaltyFromBounty(stakes[_messageHash].bounty);
    }

     
    function progressUnstakeWithProof(
        bytes32 _messageHash,
        bytes calldata _rlpParentNodes,
        uint256 _blockHeight,
        uint256 _messageStatus
    )
        external
        returns (
            uint256 redeemAmount_,
            uint256 unstakeAmount_,
            uint256 rewardAmount_
        )
    {
         
        uint256 initialGas = gasleft();

        require(
            _messageHash != bytes32(0),
            "Message hash must not be zero."
        );
        require(
            _rlpParentNodes.length > 0,
            "RLP parent nodes must not be zero"
        );

         
        bytes32 storageRoot = storageRoots[_blockHeight];
        require(
            storageRoot != bytes32(0),
            "Storage root must not be zero"
        );

        MessageBus.Message storage message = messages[_messageHash];

        MessageBus.progressInboxWithProof(
            messageBox,
            message,
            _rlpParentNodes,
            MESSAGE_BOX_OFFSET,
            storageRoot,
            MessageBus.MessageStatus(_messageStatus)
        );

        (redeemAmount_, unstakeAmount_, rewardAmount_) =
        progressUnstakeInternal(_messageHash, initialGas, bytes32(0), true);
    }

     
    function confirmRevertRedeemIntent(
        bytes32 _messageHash,
        uint256 _blockHeight,
        bytes calldata _rlpParentNodes
    )
        external
        returns (
            address redeemer_,
            uint256 redeemerNonce_,
            uint256 amount_
        )
    {

        require(
            _messageHash != bytes32(0),
            "Message hash must not be zero."
        );
        require(
            _rlpParentNodes.length > 0,
            "RLP parent nodes must not be zero."
        );

        amount_ = unstakes[_messageHash].amount;

        require(
            amount_ > uint256(0),
            "Unstake amount must not be zero."
        );

        delete unstakes[_messageHash];

         
        MessageBus.Message storage message = messages[_messageHash];
        require(
            message.intentHash != bytes32(0),
            "RevertRedeem intent hash must not be zero."
        );

         
        bytes32 storageRoot = storageRoots[_blockHeight];
        require(
            storageRoot != bytes32(0),
            "Storage root must not be zero."
        );

         
        MessageBus.confirmRevocation(
            messageBox,
            message,
            _rlpParentNodes,
            MESSAGE_BOX_OFFSET,
            storageRoot
        );

        redeemer_ = message.sender;
        redeemerNonce_ = message.nonce;

        emit RevertRedeemIntentConfirmed(
            _messageHash,
            redeemer_,
            redeemerNonce_,
            amount_
        );
    }

     
    function activateGateway(
            address _coGatewayAddress
    )
        external
        onlyOrganization
        returns (bool success_)
    {

        require(
            _coGatewayAddress != address(0),
            "Co-gateway address must not be zero."
        );
        require(
            remoteGateway == address(0),
            "Gateway was already activated once."
        );

        remoteGateway = _coGatewayAddress;

         
        encodedGatewayPath = BytesLib.bytes32ToBytes(
            keccak256(abi.encodePacked(remoteGateway))
        );
        activated = true;
        success_ = true;
    }

     
    function deactivateGateway()
        external
        onlyOrganization
        returns (bool success_)
    {
        require(
            activated == true,
            "Gateway is already deactivated."
        );
        activated = false;
        success_ = true;
    }


     

     
    function confirmRedeemIntentInternal(
        MessageBus.Message storage _message,
        uint256 _blockHeight,
        bytes memory _rlpParentNodes
    )
        private
        returns (bool)
    {
         
        bytes32 storageRoot = storageRoots[_blockHeight];
        require(
            storageRoot != bytes32(0),
            "Storage root must not be zero."
        );

         
        MessageBus.confirmMessage(
            messageBox,
            _message,
            _rlpParentNodes,
            MESSAGE_BOX_OFFSET,
            storageRoot
        );

        return true;
    }

     
    function progressStakeInternal(
        bytes32 _messageHash,
        MessageBus.Message storage _message,
        bytes32 _unlockSecret,
        bool _proofProgress
    )
        private
        returns (
            address staker_,
            uint256 stakeAmount_
        )
    {

         
        staker_ = _message.sender;

         
        stakeAmount_ = stakes[_messageHash].amount;

        require(
            stakeAmount_ > 0,
            "Stake request must exist."
        );

        uint256 stakedBounty = stakes[_messageHash].bounty;

        delete stakes[_messageHash];

         
        token.transfer(address(stakeVault), stakeAmount_);

        baseToken.transfer(msg.sender, stakedBounty);

        emit StakeProgressed(
            _messageHash,
            staker_,
            _message.nonce,
            stakeAmount_,
            _proofProgress,
            _unlockSecret
        );
    }

     
    function progressUnstakeInternal(
        bytes32 _messageHash,
        uint256 _initialGas,
        bytes32 _unlockSecret,
        bool _proofProgress
    )
        private
        returns (
            uint256 redeemAmount_,
            uint256 unstakeAmount_,
            uint256 rewardAmount_
        )
    {

        Unstake storage unStake = unstakes[_messageHash];
         
        MessageBus.Message storage message = messages[_messageHash];

        redeemAmount_ = unStake.amount;

        require(
            redeemAmount_ > 0,
            "Unstake request must exist."
        );
         
        (rewardAmount_, message.gasConsumed) = feeAmount(
            message.gasConsumed,
            message.gasLimit,
            message.gasPrice,
            _initialGas
        );

        unstakeAmount_ = redeemAmount_.sub(rewardAmount_);

        address beneficiary = unstakes[_messageHash].beneficiary;

        delete unstakes[_messageHash];

         
        stakeVault.releaseTo(beneficiary, unstakeAmount_);

         
        stakeVault.releaseTo(msg.sender, rewardAmount_);

        emit UnstakeProgressed(
            _messageHash,
            message.sender,
            beneficiary,
            redeemAmount_,
            unstakeAmount_,
            rewardAmount_,
            _proofProgress,
            _unlockSecret
        );

    }

     
    function hashRedeemIntent(
        uint256 _amount,
        address _beneficiary
    )
        private
        view
        returns(bytes32)
    {
        return GatewayLib.hashRedeemIntent(
            _amount,
            _beneficiary,
            remoteGateway
        );
    }

}