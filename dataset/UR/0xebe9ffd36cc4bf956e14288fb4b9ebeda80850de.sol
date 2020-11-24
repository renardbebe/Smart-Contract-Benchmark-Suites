 

 

pragma solidity ^0.5.10;

contract Ownable {
    event TransferredOwnership(address _from, address _to);
    event LockedOwnership(address _locked);

    address payable private _owner;
    bool private _isTransferable;

     
    constructor(address payable _account_, bool _transferable_) internal {
        _owner = _account_;
        _isTransferable = _transferable_;
         
        if (!_isTransferable) {
            emit LockedOwnership(_account_);
        }
        emit TransferredOwnership(address(0), _account_);
    }

     
    modifier onlyOwner() {
        require(_isOwner(msg.sender), "sender is not an owner");
        _;
    }

     
     
     
    function transferOwnership(address payable _account, bool _transferable) external onlyOwner {
         
        require(_isTransferable, "ownership is not transferable");
         
        require(_account != address(0), "owner cannot be set to zero address");
         
        _isTransferable = _transferable;
         
        if (!_transferable) {
            emit LockedOwnership(_account);
        }
         
        emit TransferredOwnership(_owner, _account);
         
        _owner = _account;
    }

     
     
    function isTransferable() external view returns (bool) {
        return _isTransferable;
    }

     
     
     
    function renounceOwnership() external onlyOwner {
         
        require(_isTransferable, "ownership is not transferable");
         
        _owner = address(0);

        emit TransferredOwnership(_owner, address(0));
    }

     
     
    function owner() public view returns (address payable) {
        return _owner;
    }

     
     
    function _isOwner(address _address) internal view returns (bool) {
        return _address == _owner;
    }
}

library SafeMath {
     
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

     
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a, "SafeMath: subtraction overflow");
        uint256 c = a - b;

        return c;
    }

     
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
         
         
         
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

     
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
         
        require(b > 0, "SafeMath: division by zero");
        uint256 c = a / b;
         

        return c;
    }

     
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b != 0, "SafeMath: modulo by zero");
        return a % b;
    }
}

contract ResolverBase {
    bytes4 private constant INTERFACE_META_ID = 0x01ffc9a7;

    function supportsInterface(bytes4 interfaceID) public pure returns(bool) {
        return interfaceID == INTERFACE_META_ID;
    }

    function isAuthorised(bytes32 node) internal view returns(bool);

    modifier authorised(bytes32 node) {
        require(isAuthorised(node));
        _;
    }
}

library strings {
    struct slice {
        uint _len;
        uint _ptr;
    }

    function memcpy(uint dest, uint src, uint len) private pure {
         
        for(; len >= 32; len -= 32) {
            assembly {
                mstore(dest, mload(src))
            }
            dest += 32;
            src += 32;
        }

         
        uint mask = 256 ** (32 - len) - 1;
        assembly {
            let srcpart := and(mload(src), not(mask))
            let destpart := and(mload(dest), mask)
            mstore(dest, or(destpart, srcpart))
        }
    }

     
    function toSlice(string memory self) internal pure returns (slice memory) {
        uint ptr;
        assembly {
            ptr := add(self, 0x20)
        }
        return slice(bytes(self).length, ptr);
    }

     
    function len(bytes32 self) internal pure returns (uint) {
        uint ret;
        if (self == 0)
            return 0;
        if (uint(self) & 0xffffffffffffffffffffffffffffffff == 0) {
            ret += 16;
            self = bytes32(uint(self) / 0x100000000000000000000000000000000);
        }
        if (uint(self) & 0xffffffffffffffff == 0) {
            ret += 8;
            self = bytes32(uint(self) / 0x10000000000000000);
        }
        if (uint(self) & 0xffffffff == 0) {
            ret += 4;
            self = bytes32(uint(self) / 0x100000000);
        }
        if (uint(self) & 0xffff == 0) {
            ret += 2;
            self = bytes32(uint(self) / 0x10000);
        }
        if (uint(self) & 0xff == 0) {
            ret += 1;
        }
        return 32 - ret;
    }

     
    function toSliceB32(bytes32 self) internal pure returns (slice memory ret) {
         
        assembly {
            let ptr := mload(0x40)
            mstore(0x40, add(ptr, 0x20))
            mstore(ptr, self)
            mstore(add(ret, 0x20), ptr)
        }
        ret._len = len(self);
    }

     
    function copy(slice memory self) internal pure returns (slice memory) {
        return slice(self._len, self._ptr);
    }

     
    function toString(slice memory self) internal pure returns (string memory) {
        string memory ret = new string(self._len);
        uint retptr;
        assembly { retptr := add(ret, 32) }

        memcpy(retptr, self._ptr, self._len);
        return ret;
    }

     
    function len(slice memory self) internal pure returns (uint l) {
         
        uint ptr = self._ptr - 31;
        uint end = ptr + self._len;
        for (l = 0; ptr < end; l++) {
            uint8 b;
            assembly { b := and(mload(ptr), 0xFF) }
            if (b < 0x80) {
                ptr += 1;
            } else if (b < 0xE0) {
                ptr += 2;
            } else if (b < 0xF0) {
                ptr += 3;
            } else if (b < 0xF8) {
                ptr += 4;
            } else if (b < 0xFC) {
                ptr += 5;
            } else {
                ptr += 6;
            }
        }
    }

     
    function empty(slice memory self) internal pure returns (bool) {
        return self._len == 0;
    }

     
    function compare(slice memory self, slice memory other) internal pure returns (int) {
        uint shortest = self._len;
        if (other._len < self._len)
            shortest = other._len;

        uint selfptr = self._ptr;
        uint otherptr = other._ptr;
        for (uint idx = 0; idx < shortest; idx += 32) {
            uint a;
            uint b;
            assembly {
                a := mload(selfptr)
                b := mload(otherptr)
            }
            if (a != b) {
                 
                uint256 mask = uint256(-1);  
                if (shortest < 32) {
                    mask = ~(2 ** (8 * (32 - shortest + idx)) - 1);
                }
                uint256 diff = (a & mask) - (b & mask);
                if (diff != 0)
                    return int(diff);
            }
            selfptr += 32;
            otherptr += 32;
        }
        return int(self._len) - int(other._len);
    }

     
    function equals(slice memory self, slice memory other) internal pure returns (bool) {
        return compare(self, other) == 0;
    }

     
    function nextRune(slice memory self, slice memory rune) internal pure returns (slice memory) {
        rune._ptr = self._ptr;

        if (self._len == 0) {
            rune._len = 0;
            return rune;
        }

        uint l;
        uint b;
         
        assembly { b := and(mload(sub(mload(add(self, 32)), 31)), 0xFF) }
        if (b < 0x80) {
            l = 1;
        } else if (b < 0xE0) {
            l = 2;
        } else if (b < 0xF0) {
            l = 3;
        } else {
            l = 4;
        }

         
        if (l > self._len) {
            rune._len = self._len;
            self._ptr += self._len;
            self._len = 0;
            return rune;
        }

        self._ptr += l;
        self._len -= l;
        rune._len = l;
        return rune;
    }

     
    function nextRune(slice memory self) internal pure returns (slice memory ret) {
        nextRune(self, ret);
    }

     
    function ord(slice memory self) internal pure returns (uint ret) {
        if (self._len == 0) {
            return 0;
        }

        uint word;
        uint length;
        uint divisor = 2 ** 248;

         
        assembly { word:= mload(mload(add(self, 32))) }
        uint b = word / divisor;
        if (b < 0x80) {
            ret = b;
            length = 1;
        } else if (b < 0xE0) {
            ret = b & 0x1F;
            length = 2;
        } else if (b < 0xF0) {
            ret = b & 0x0F;
            length = 3;
        } else {
            ret = b & 0x07;
            length = 4;
        }

         
        if (length > self._len) {
            return 0;
        }

        for (uint i = 1; i < length; i++) {
            divisor = divisor / 256;
            b = (word / divisor) & 0xFF;
            if (b & 0xC0 != 0x80) {
                 
                return 0;
            }
            ret = (ret * 64) | (b & 0x3F);
        }

        return ret;
    }

     
    function keccak(slice memory self) internal pure returns (bytes32 ret) {
        assembly {
            ret := keccak256(mload(add(self, 32)), mload(self))
        }
    }

     
    function startsWith(slice memory self, slice memory needle) internal pure returns (bool) {
        if (self._len < needle._len) {
            return false;
        }

        if (self._ptr == needle._ptr) {
            return true;
        }

        bool equal;
        assembly {
            let length := mload(needle)
            let selfptr := mload(add(self, 0x20))
            let needleptr := mload(add(needle, 0x20))
            equal := eq(keccak256(selfptr, length), keccak256(needleptr, length))
        }
        return equal;
    }

     
    function beyond(slice memory self, slice memory needle) internal pure returns (slice memory) {
        if (self._len < needle._len) {
            return self;
        }

        bool equal = true;
        if (self._ptr != needle._ptr) {
            assembly {
                let length := mload(needle)
                let selfptr := mload(add(self, 0x20))
                let needleptr := mload(add(needle, 0x20))
                equal := eq(keccak256(selfptr, length), keccak256(needleptr, length))
            }
        }

        if (equal) {
            self._len -= needle._len;
            self._ptr += needle._len;
        }

        return self;
    }

     
    function endsWith(slice memory self, slice memory needle) internal pure returns (bool) {
        if (self._len < needle._len) {
            return false;
        }

        uint selfptr = self._ptr + self._len - needle._len;

        if (selfptr == needle._ptr) {
            return true;
        }

        bool equal;
        assembly {
            let length := mload(needle)
            let needleptr := mload(add(needle, 0x20))
            equal := eq(keccak256(selfptr, length), keccak256(needleptr, length))
        }

        return equal;
    }

     
    function until(slice memory self, slice memory needle) internal pure returns (slice memory) {
        if (self._len < needle._len) {
            return self;
        }

        uint selfptr = self._ptr + self._len - needle._len;
        bool equal = true;
        if (selfptr != needle._ptr) {
            assembly {
                let length := mload(needle)
                let needleptr := mload(add(needle, 0x20))
                equal := eq(keccak256(selfptr, length), keccak256(needleptr, length))
            }
        }

        if (equal) {
            self._len -= needle._len;
        }

        return self;
    }

     
     
    function findPtr(uint selflen, uint selfptr, uint needlelen, uint needleptr) private pure returns (uint) {
        uint ptr = selfptr;
        uint idx;

        if (needlelen <= selflen) {
            if (needlelen <= 32) {
                bytes32 mask = bytes32(~(2 ** (8 * (32 - needlelen)) - 1));

                bytes32 needledata;
                assembly { needledata := and(mload(needleptr), mask) }

                uint end = selfptr + selflen - needlelen;
                bytes32 ptrdata;
                assembly { ptrdata := and(mload(ptr), mask) }

                while (ptrdata != needledata) {
                    if (ptr >= end)
                        return selfptr + selflen;
                    ptr++;
                    assembly { ptrdata := and(mload(ptr), mask) }
                }
                return ptr;
            } else {
                 
                bytes32 hash;
                assembly { hash := keccak256(needleptr, needlelen) }

                for (idx = 0; idx <= selflen - needlelen; idx++) {
                    bytes32 testHash;
                    assembly { testHash := keccak256(ptr, needlelen) }
                    if (hash == testHash)
                        return ptr;
                    ptr += 1;
                }
            }
        }
        return selfptr + selflen;
    }

     
     
    function rfindPtr(uint selflen, uint selfptr, uint needlelen, uint needleptr) private pure returns (uint) {
        uint ptr;

        if (needlelen <= selflen) {
            if (needlelen <= 32) {
                bytes32 mask = bytes32(~(2 ** (8 * (32 - needlelen)) - 1));

                bytes32 needledata;
                assembly { needledata := and(mload(needleptr), mask) }

                ptr = selfptr + selflen - needlelen;
                bytes32 ptrdata;
                assembly { ptrdata := and(mload(ptr), mask) }

                while (ptrdata != needledata) {
                    if (ptr <= selfptr)
                        return selfptr;
                    ptr--;
                    assembly { ptrdata := and(mload(ptr), mask) }
                }
                return ptr + needlelen;
            } else {
                 
                bytes32 hash;
                assembly { hash := keccak256(needleptr, needlelen) }
                ptr = selfptr + (selflen - needlelen);
                while (ptr >= selfptr) {
                    bytes32 testHash;
                    assembly { testHash := keccak256(ptr, needlelen) }
                    if (hash == testHash)
                        return ptr + needlelen;
                    ptr -= 1;
                }
            }
        }
        return selfptr;
    }

     
    function find(slice memory self, slice memory needle) internal pure returns (slice memory) {
        uint ptr = findPtr(self._len, self._ptr, needle._len, needle._ptr);
        self._len -= ptr - self._ptr;
        self._ptr = ptr;
        return self;
    }

     
    function rfind(slice memory self, slice memory needle) internal pure returns (slice memory) {
        uint ptr = rfindPtr(self._len, self._ptr, needle._len, needle._ptr);
        self._len = ptr - self._ptr;
        return self;
    }

     
    function split(slice memory self, slice memory needle, slice memory token) internal pure returns (slice memory) {
        uint ptr = findPtr(self._len, self._ptr, needle._len, needle._ptr);
        token._ptr = self._ptr;
        token._len = ptr - self._ptr;
        if (ptr == self._ptr + self._len) {
             
            self._len = 0;
        } else {
            self._len -= token._len + needle._len;
            self._ptr = ptr + needle._len;
        }
        return token;
    }

     
    function split(slice memory self, slice memory needle) internal pure returns (slice memory token) {
        split(self, needle, token);
    }

     
    function rsplit(slice memory self, slice memory needle, slice memory token) internal pure returns (slice memory) {
        uint ptr = rfindPtr(self._len, self._ptr, needle._len, needle._ptr);
        token._ptr = ptr;
        token._len = self._len - (ptr - self._ptr);
        if (ptr == self._ptr) {
             
            self._len = 0;
        } else {
            self._len -= token._len + needle._len;
        }
        return token;
    }

     
    function rsplit(slice memory self, slice memory needle) internal pure returns (slice memory token) {
        rsplit(self, needle, token);
    }

     
    function count(slice memory self, slice memory needle) internal pure returns (uint cnt) {
        uint ptr = findPtr(self._len, self._ptr, needle._len, needle._ptr) + needle._len;
        while (ptr <= self._ptr + self._len) {
            cnt++;
            ptr = findPtr(self._len - (ptr - self._ptr), ptr, needle._len, needle._ptr) + needle._len;
        }
    }

     
    function contains(slice memory self, slice memory needle) internal pure returns (bool) {
        return rfindPtr(self._len, self._ptr, needle._len, needle._ptr) != self._ptr;
    }

     
    function concat(slice memory self, slice memory other) internal pure returns (string memory) {
        string memory ret = new string(self._len + other._len);
        uint retptr;
        assembly { retptr := add(ret, 32) }
        memcpy(retptr, self._ptr, self._len);
        memcpy(retptr + self._len, other._ptr, other._len);
        return ret;
    }

     
    function join(slice memory self, slice[] memory parts) internal pure returns (string memory) {
        if (parts.length == 0)
            return "";

        uint length = self._len * (parts.length - 1);
        for (uint i = 0; i < parts.length; i++) {
            length += parts[i]._len;
        }

        string memory ret = new string(length);
        uint retptr;
        assembly { retptr := add(ret, 32) }

        for (uint i = 0; i < parts.length; i++) {
            memcpy(retptr, parts[i]._ptr, parts[i]._len);
            retptr += parts[i]._len;
            if (i < parts.length - 1) {
                memcpy(retptr, self._ptr, self._len);
                retptr += self._len;
            }
        }

        return ret;
    }
}

interface ERC165 {
    function supportsInterface(bytes4) external view returns (bool);
}

interface ENS {

     
    event NewOwner(bytes32 indexed node, bytes32 indexed label, address owner);

     
    event Transfer(bytes32 indexed node, address owner);

     
    event NewResolver(bytes32 indexed node, address resolver);

     
    event NewTTL(bytes32 indexed node, uint64 ttl);


    function setSubnodeOwner(bytes32 node, bytes32 label, address owner) external;
    function setResolver(bytes32 node, address resolver) external;
    function setOwner(bytes32 node, address owner) external;
    function setTTL(bytes32 node, uint64 ttl) external;
    function owner(bytes32 node) external view returns (address);
    function resolver(bytes32 node) external view returns (address);
    function ttl(bytes32 node) external view returns (uint64);

}

library Address {
     
    function isContract(address account) internal view returns (bool) {
         
         
         

        uint256 size;
         
        assembly { size := extcodesize(account) }
        return size > 0;
    }
}

interface ERC20 {
    function allowance(address _owner, address _spender) external view returns (uint256);
    function approve(address _spender, uint256 _value) external returns (bool);
    function balanceOf(address _who) external view returns (uint256);
    function totalSupply() external view returns (uint256);
    function transfer(address _to, uint256 _value) external returns (bool);
    function transferFrom(address _from, address _to, uint256 _value) external returns (bool);
}

contract AddrResolver is ResolverBase {
    bytes4 constant private ADDR_INTERFACE_ID = 0x3b3b57de;

    event AddrChanged(bytes32 indexed node, address a);

    mapping(bytes32=>address) addresses;

     
    function setAddr(bytes32 node, address addr) external authorised(node) {
        addresses[node] = addr;
        emit AddrChanged(node, addr);
    }

     
    function addr(bytes32 node) public view returns (address) {
        return addresses[node];
    }

    function supportsInterface(bytes4 interfaceID) public pure returns(bool) {
        return interfaceID == ADDR_INTERFACE_ID || super.supportsInterface(interfaceID);
    }
}

contract ContentHashResolver is ResolverBase {
    bytes4 constant private CONTENT_HASH_INTERFACE_ID = 0xbc1c58d1;

    event ContenthashChanged(bytes32 indexed node, bytes hash);

    mapping(bytes32=>bytes) hashes;

     
    function setContenthash(bytes32 node, bytes calldata hash) external authorised(node) {
        hashes[node] = hash;
        emit ContenthashChanged(node, hash);
    }

     
    function contenthash(bytes32 node) external view returns (bytes memory) {
        return hashes[node];
    }

    function supportsInterface(bytes4 interfaceID) public pure returns(bool) {
        return interfaceID == CONTENT_HASH_INTERFACE_ID || super.supportsInterface(interfaceID);
    }
}

contract NameResolver is ResolverBase {
    bytes4 constant private NAME_INTERFACE_ID = 0x691f3431;

    event NameChanged(bytes32 indexed node, string name);

    mapping(bytes32=>string) names;

     
    function setName(bytes32 node, string calldata name) external authorised(node) {
        names[node] = name;
        emit NameChanged(node, name);
    }

     
    function name(bytes32 node) external view returns (string memory) {
        return names[node];
    }

    function supportsInterface(bytes4 interfaceID) public pure returns(bool) {
        return interfaceID == NAME_INTERFACE_ID || super.supportsInterface(interfaceID);
    }
}

contract ABIResolver is ResolverBase {
    bytes4 constant private ABI_INTERFACE_ID = 0x2203ab56;

    event ABIChanged(bytes32 indexed node, uint256 indexed contentType);

    mapping(bytes32=>mapping(uint256=>bytes)) abis;

     
    function setABI(bytes32 node, uint256 contentType, bytes calldata data) external authorised(node) {
         
        require(((contentType - 1) & contentType) == 0);

        abis[node][contentType] = data;
        emit ABIChanged(node, contentType);
    }

     
    function ABI(bytes32 node, uint256 contentTypes) external view returns (uint256, bytes memory) {
        mapping(uint256=>bytes) storage abiset = abis[node];

        for (uint256 contentType = 1; contentType <= contentTypes; contentType <<= 1) {
            if ((contentType & contentTypes) != 0 && abiset[contentType].length > 0) {
                return (contentType, abiset[contentType]);
            }
        }

        return (0, bytes(""));
    }

    function supportsInterface(bytes4 interfaceID) public pure returns(bool) {
        return interfaceID == ABI_INTERFACE_ID || super.supportsInterface(interfaceID);
    }
}

library SafeERC20 {
    using SafeMath for uint256;
    using Address for address;

    function safeTransfer(ERC20 token, address to, uint256 value) internal {
        callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(ERC20 token, address from, address to, uint256 value) internal {
        callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    function safeApprove(ERC20 token, address spender, uint256 value) internal {
         
         
         
         
        require((value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(ERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).add(value);
        callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(ERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).sub(value);
        callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

     
    function callOptionalReturn(ERC20 token, bytes memory data) internal {
         
         

         
         
         
         
         
        require(address(token).isContract(), "SafeERC20: call to non-contract");

         
        (bool success, bytes memory returndata) = address(token).call(data);
        require(success, "SafeERC20: low-level call failed");

        if (returndata.length > 0) {  
             
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

library BytesUtils {

    using SafeMath for uint256;

     
     
     
    function _bytesToAddress(bytes memory _bts, uint _from) internal pure returns (address) {

        require(_bts.length >= _from.add(20), "slicing out of range");

        bytes20 convertedAddress;
        uint startByte = _from.add(32);  

        assembly {
            convertedAddress := mload(add(_bts, startByte))
        }

        return address(convertedAddress);
    }

     
     
     
    function _bytesToBytes4(bytes memory _bts, uint _from) internal pure returns (bytes4) {
        require(_bts.length >= _from.add(4), "slicing out of range");

        bytes4 slicedBytes4;
        uint startByte = _from.add(32);  

        assembly {
            slicedBytes4 := mload(add(_bts, startByte))
        }

        return slicedBytes4;

    }

     
     
     
     
     
    function _bytesToUint256(bytes memory _bts, uint _from) internal pure returns (uint) {
        require(_bts.length >= _from.add(32), "slicing out of range");

        uint convertedUint256;
        uint startByte = _from.add(32);  
        
        assembly {
            convertedUint256 := mload(add(_bts, startByte))
        }

        return convertedUint256;
    }
}

contract Balanceable {

     
     
     
     
    function _balance(address _address, address _asset) internal view returns (uint) {
        if (_asset != address(0)) {
            return ERC20(_asset).balanceOf(_address);
        } else {
            return _address.balance;
        }
    }
}

contract PubkeyResolver is ResolverBase {
    bytes4 constant private PUBKEY_INTERFACE_ID = 0xc8690233;

    event PubkeyChanged(bytes32 indexed node, bytes32 x, bytes32 y);

    struct PublicKey {
        bytes32 x;
        bytes32 y;
    }

    mapping(bytes32=>PublicKey) pubkeys;

     
    function setPubkey(bytes32 node, bytes32 x, bytes32 y) external authorised(node) {
        pubkeys[node] = PublicKey(x, y);
        emit PubkeyChanged(node, x, y);
    }

     
    function pubkey(bytes32 node) external view returns (bytes32 x, bytes32 y) {
        return (pubkeys[node].x, pubkeys[node].y);
    }

    function supportsInterface(bytes4 interfaceID) public pure returns(bool) {
        return interfaceID == PUBKEY_INTERFACE_ID || super.supportsInterface(interfaceID);
    }
}

contract TextResolver is ResolverBase {
    bytes4 constant private TEXT_INTERFACE_ID = 0x59d1d43c;

    event TextChanged(bytes32 indexed node, string indexedKey, string key);

    mapping(bytes32=>mapping(string=>string)) texts;

     
    function setText(bytes32 node, string calldata key, string calldata value) external authorised(node) {
        texts[node][key] = value;
        emit TextChanged(node, key, key);
    }

     
    function text(bytes32 node, string calldata key) external view returns (string memory) {
        return texts[node][key];
    }

    function supportsInterface(bytes4 interfaceID) public pure returns(bool) {
        return interfaceID == TEXT_INTERFACE_ID || super.supportsInterface(interfaceID);
    }
}

contract Transferrable {

    using SafeERC20 for ERC20;


     
     
     
     
     
    function _safeTransfer(address payable _to, address _asset, uint _amount) internal {
         
        if (_asset == address(0)) {
            _to.transfer(_amount);
        } else {
            ERC20(_asset).safeTransfer(_to, _amount);
        }
    }
}

contract InterfaceResolver is ResolverBase, AddrResolver {
    bytes4 constant private INTERFACE_INTERFACE_ID = bytes4(keccak256("interfaceImplementer(bytes32,bytes4)"));
    bytes4 private constant INTERFACE_META_ID = 0x01ffc9a7;

    event InterfaceChanged(bytes32 indexed node, bytes4 indexed interfaceID, address implementer);

    mapping(bytes32=>mapping(bytes4=>address)) interfaces;

     
    function setInterface(bytes32 node, bytes4 interfaceID, address implementer) external authorised(node) {
        interfaces[node][interfaceID] = implementer;
        emit InterfaceChanged(node, interfaceID, implementer);
    }

     
    function interfaceImplementer(bytes32 node, bytes4 interfaceID) external view returns (address) {
        address implementer = interfaces[node][interfaceID];
        if(implementer != address(0)) {
            return implementer;
        }

        address a = addr(node);
        if(a == address(0)) {
            return address(0);
        }

        (bool success, bytes memory returnData) = a.staticcall(abi.encodeWithSignature("supportsInterface(bytes4)", INTERFACE_META_ID));
        if(!success || returnData.length < 32 || returnData[31] == 0) {
             
            return address(0);
        }

        (success, returnData) = a.staticcall(abi.encodeWithSignature("supportsInterface(bytes4)", interfaceID));
        if(!success || returnData.length < 32 || returnData[31] == 0) {
             
            return address(0);
        }

        return a;
    }

    function supportsInterface(bytes4 interfaceID) public pure returns(bool) {
        return interfaceID == INTERFACE_INTERFACE_ID || super.supportsInterface(interfaceID);
    }
}

interface IController {
    function isController(address) external view returns (bool);
    function isAdmin(address) external view returns (bool);
}


 
 
 
 
 
contract Controller is IController, Ownable, Transferrable {

    event AddedController(address _sender, address _controller);
    event RemovedController(address _sender, address _controller);

    event AddedAdmin(address _sender, address _admin);
    event RemovedAdmin(address _sender, address _admin);

    event Claimed(address _to, address _asset, uint _amount);

    event Stopped(address _sender);
    event Started(address _sender);

    mapping (address => bool) private _isAdmin;
    uint private _adminCount;

    mapping (address => bool) private _isController;
    uint private _controllerCount;

    bool private _stopped;

     
     
    constructor(address payable _ownerAddress_) Ownable(_ownerAddress_, false) public {}

     
    modifier onlyAdmin() {
        require(isAdmin(msg.sender), "sender is not an admin");
        _;
    }

     
    modifier onlyAdminOrOwner() {
        require(_isOwner(msg.sender) || isAdmin(msg.sender), "sender is not an admin");
        _;
    }

     
    modifier notStopped() {
        require(!isStopped(), "controller is stopped");
        _;
    }

     
     
    function addAdmin(address _account) external onlyOwner notStopped {
        _addAdmin(_account);
    }

     
     
    function removeAdmin(address _account) external onlyOwner {
        _removeAdmin(_account);
    }

     
    function adminCount() external view returns (uint) {
        return _adminCount;
    }

     
     
    function addController(address _account) external onlyAdminOrOwner notStopped {
        _addController(_account);
    }

     
     
    function removeController(address _account) external onlyAdminOrOwner {
        _removeController(_account);
    }

     
     
    function controllerCount() external view returns (uint) {
        return _controllerCount;
    }

     
     
    function isAdmin(address _account) public view notStopped returns (bool) {
        return _isAdmin[_account];
    }

     
     
    function isController(address _account) public view notStopped returns (bool) {
        return _isController[_account];
    }

     
     
    function isStopped() public view returns (bool) {
        return _stopped;
    }

     
    function _addAdmin(address _account) private {
        require(!_isAdmin[_account], "provided account is already an admin");
        require(!_isController[_account], "provided account is already a controller");
        require(!_isOwner(_account), "provided account is already the owner");
        require(_account != address(0), "provided account is the zero address");
        _isAdmin[_account] = true;
        _adminCount++;
        emit AddedAdmin(msg.sender, _account);
    }

     
    function _removeAdmin(address _account) private {
        require(_isAdmin[_account], "provided account is not an admin");
        _isAdmin[_account] = false;
        _adminCount--;
        emit RemovedAdmin(msg.sender, _account);
    }

     
    function _addController(address _account) private {
        require(!_isAdmin[_account], "provided account is already an admin");
        require(!_isController[_account], "provided account is already a controller");
        require(!_isOwner(_account), "provided account is already the owner");
        require(_account != address(0), "provided account is the zero address");
        _isController[_account] = true;
        _controllerCount++;
        emit AddedController(msg.sender, _account);
    }

     
    function _removeController(address _account) private {
        require(_isController[_account], "provided account is not a controller");
        _isController[_account] = false;
        _controllerCount--;
        emit RemovedController(msg.sender, _account);
    }

     
    function stop() external onlyAdminOrOwner {
        _stopped = true;
        emit Stopped(msg.sender);
    }

     
    function start() external onlyOwner {
        _stopped = false;
        emit Started(msg.sender);
    }

     
    function claim(address payable _to, address _asset, uint _amount) external onlyAdmin notStopped {
        _safeTransfer(_to, _asset, _amount);
        emit Claimed(_to, _asset, _amount);
    }
}

contract PublicResolver is ABIResolver, AddrResolver, ContentHashResolver, InterfaceResolver, NameResolver, PubkeyResolver, TextResolver {
    ENS ens;

     
    mapping(bytes32=>mapping(address=>mapping(address=>bool))) public authorisations;

    event AuthorisationChanged(bytes32 indexed node, address indexed owner, address indexed target, bool isAuthorised);

    constructor(ENS _ens) public {
        ens = _ens;
    }

     
    function setAuthorisation(bytes32 node, address target, bool isAuthorised) external {
        authorisations[node][msg.sender][target] = isAuthorised;
        emit AuthorisationChanged(node, msg.sender, target, isAuthorised);
    }

    function isAuthorised(bytes32 node) internal view returns(bool) {
        address owner = ens.owner(node);
        return owner == msg.sender || authorisations[node][owner][msg.sender];
    }
}

contract ENSResolvable {
     
    ENS private _ens;

     
    address private _ensRegistry;

     
    constructor(address _ensReg_) internal {
        _ensRegistry = _ensReg_;
        _ens = ENS(_ensRegistry);
    }

     
    function ensRegistry() external view returns (address) {
        return _ensRegistry;
    }

     
     
     
    function _ensResolve(bytes32 _node) internal view returns (address) {
        return PublicResolver(_ens.resolver(_node)).addr(_node);
    }

}

contract Controllable is ENSResolvable {
     
    bytes32 private _controllerNode;

     
     
    constructor(bytes32 _controllerNode_) internal {
        _controllerNode = _controllerNode_;
    }

     
    modifier onlyController() {
        require(_isController(msg.sender), "sender is not a controller");
        _;
    }

     
    modifier onlyAdmin() {
        require(_isAdmin(msg.sender), "sender is not an admin");
        _;
    }

     
    function controllerNode() external view returns (bytes32) {
        return _controllerNode;
    }

     
    function _isController(address _account) internal view returns (bool) {
        return IController(_ensResolve(_controllerNode)).isController(_account);
    }

     
    function _isAdmin(address _account) internal view returns (bool) {
        return IController(_ensResolve(_controllerNode)).isAdmin(_account);
    }

}

interface ILicence {
    function load(address, uint) external payable;
    function updateLicenceAmount(uint) external;
}


 
 
contract Licence is Transferrable, ENSResolvable, Controllable {

    using SafeMath for uint256;
    using SafeERC20 for ERC20;

     
     
     

    event UpdatedLicenceDAO(address _newDAO);
    event UpdatedCryptoFloat(address _newFloat);
    event UpdatedTokenHolder(address _newHolder);
    event UpdatedTKNContractAddress(address _newTKN);
    event UpdatedLicenceAmount(uint _newAmount);

    event TransferredToTokenHolder(address _from, address _to, address _asset, uint _amount);
    event TransferredToCryptoFloat(address _from, address _to, address _asset, uint _amount);

    event Claimed(address _to, address _asset, uint _amount);

     
    uint constant public MAX_AMOUNT_SCALE = 1000;
    uint constant public MIN_AMOUNT_SCALE = 1;

    address private _tknContractAddress = 0xaAAf91D9b90dF800Df4F55c205fd6989c977E73a;  

    address payable private _cryptoFloat;
    address payable private _tokenHolder;
    address private _licenceDAO;

    bool private _lockedCryptoFloat;
    bool private _lockedTokenHolder;
    bool private _lockedLicenceDAO;
    bool private _lockedTKNContractAddress;

     
     
    uint private _licenceAmountScaled;

     
    modifier onlyDAO() {
        require(msg.sender == _licenceDAO, "the sender isn't the DAO");
        _;
    }

     
     
     
     
     
     
     
    constructor(uint _licence_, address payable _float_, address payable _holder_, address _tknAddress_, address _ens_, bytes32 _controllerNode_) ENSResolvable(_ens_) Controllable(_controllerNode_) public {
        require(MIN_AMOUNT_SCALE <= _licence_ && _licence_ <= MAX_AMOUNT_SCALE, "licence amount out of range");
        _licenceAmountScaled = _licence_;
        _cryptoFloat = _float_;
        _tokenHolder = _holder_;
        if (_tknAddress_ != address(0)) {
            _tknContractAddress = _tknAddress_;
        }
    }

     
    function() external payable {}

     
     
    function licenceAmountScaled() external view returns (uint) {
        return _licenceAmountScaled;
    }

     
     
    function cryptoFloat() external view returns (address) {
        return _cryptoFloat;
    }

     
     
    function tokenHolder() external view returns (address) {
        return _tokenHolder;
    }

     
     
    function licenceDAO() external view returns (address) {
        return _licenceDAO;
    }

     
     
    function tknContractAddress() external view returns (address) {
        return _tknContractAddress;
    }

     
     
    function lockFloat() external onlyAdmin {
        _lockedCryptoFloat = true;
    }

     
     
    function lockHolder() external onlyAdmin {
        _lockedTokenHolder = true;
    }

     
     
    function lockLicenceDAO() external onlyAdmin {
        _lockedLicenceDAO = true;
    }

     
     
    function lockTKNContractAddress() external onlyAdmin {
        _lockedTKNContractAddress = true;
    }

     
     
    function updateFloat(address payable _newFloat) external onlyAdmin {
        require(!floatLocked(), "float is locked");
        _cryptoFloat = _newFloat;
        emit UpdatedCryptoFloat(_newFloat);
    }

     
     
    function updateHolder(address payable _newHolder) external onlyAdmin {
        require(!holderLocked(), "holder contract is locked");
        _tokenHolder = _newHolder;
        emit UpdatedTokenHolder(_newHolder);
    }

     
     
    function updateLicenceDAO(address _newDAO) external onlyAdmin {
        require(!licenceDAOLocked(), "DAO is locked");
        _licenceDAO = _newDAO;
        emit UpdatedLicenceDAO(_newDAO);
    }

     
     
    function updateTKNContractAddress(address _newTKN) external onlyAdmin {
        require(!tknContractAddressLocked(), "TKN is locked");
        _tknContractAddress = _newTKN;
        emit UpdatedTKNContractAddress(_newTKN);
    }

     
     
    function updateLicenceAmount(uint _newAmount) external onlyDAO {
        require(MIN_AMOUNT_SCALE <= _newAmount && _newAmount <= MAX_AMOUNT_SCALE, "licence amount out of range");
        _licenceAmountScaled = _newAmount;
        emit UpdatedLicenceAmount(_newAmount);
    }

     
     
     
    function load(address _asset, uint _amount) external payable {
        uint loadAmount = _amount;
         
        if (_asset == _tknContractAddress) {
            ERC20(_asset).safeTransferFrom(msg.sender, _cryptoFloat, loadAmount);
        } else {
            loadAmount = _amount.mul(MAX_AMOUNT_SCALE).div(_licenceAmountScaled + MAX_AMOUNT_SCALE);
            uint licenceAmount = _amount.sub(loadAmount);

            if (_asset != address(0)) {
                ERC20(_asset).safeTransferFrom(msg.sender, _tokenHolder, licenceAmount);
                ERC20(_asset).safeTransferFrom(msg.sender, _cryptoFloat, loadAmount);
            } else {
                require(msg.value == _amount, "ETH sent is not equal to amount");
                _tokenHolder.transfer(licenceAmount);
                _cryptoFloat.transfer(loadAmount);
            }

            emit TransferredToTokenHolder(msg.sender, _tokenHolder, _asset, licenceAmount);
        }

        emit TransferredToCryptoFloat(msg.sender, _cryptoFloat, _asset, loadAmount);
    }

     
    function claim(address payable _to, address _asset, uint _amount) external onlyAdmin {
        _safeTransfer(_to, _asset, _amount);
        emit Claimed(_to, _asset, _amount);
    }

     
    function floatLocked() public view returns (bool) {
        return _lockedCryptoFloat;
    }

     
    function holderLocked() public view returns (bool) {
        return _lockedTokenHolder;
    }

     
    function licenceDAOLocked() public view returns (bool) {
        return _lockedLicenceDAO;
    }

     
    function tknContractAddressLocked() public view returns (bool) {
        return _lockedTKNContractAddress;
    }
}

interface ITokenWhitelist {
    function getTokenInfo(address) external view returns (string memory, uint256, uint256, bool, bool, bool, uint256);
    function getStablecoinInfo() external view returns (string memory, uint256, uint256, bool, bool, bool, uint256);
    function tokenAddressArray() external view returns (address[] memory);
    function redeemableTokens() external view returns (address[] memory);
    function methodIdWhitelist(bytes4) external view returns (bool);
    function getERC20RecipientAndAmount(address, bytes calldata) external view returns (address, uint);
    function stablecoin() external view returns (address);
    function updateTokenRate(address, uint, uint) external;
}


 
contract TokenWhitelist is ENSResolvable, Controllable, Transferrable {
    using strings for *;
    using SafeMath for uint256;
    using BytesUtils for bytes;

    event UpdatedTokenRate(address _sender, address _token, uint _rate);

    event UpdatedTokenLoadable(address _sender, address _token, bool _loadable);
    event UpdatedTokenRedeemable(address _sender, address _token, bool _redeemable);

    event AddedToken(address _sender, address _token, string _symbol, uint _magnitude, bool _loadable, bool _redeemable);
    event RemovedToken(address _sender, address _token);

    event AddedMethodId(bytes4 _methodId);
    event RemovedMethodId(bytes4 _methodId);
    event AddedExclusiveMethod(address _token, bytes4 _methodId);
    event RemovedExclusiveMethod(address _token, bytes4 _methodId);

    event Claimed(address _to, address _asset, uint _amount);

     
    bytes4 private constant _APPROVE = 0x095ea7b3;  
    bytes4 private constant _BURN = 0x42966c68;  
    bytes4 private constant _TRANSFER= 0xa9059cbb;  
    bytes4 private constant _TRANSFER_FROM = 0x23b872dd;  

    struct Token {
        string symbol;     
        uint magnitude;    
        uint rate;         
        bool available;    
        bool loadable;     
        bool redeemable;     
        uint lastUpdate;   
    }

    mapping(address => Token) private _tokenInfoMap;

     
    mapping(bytes4 => bool) private _methodIdWhitelist;

    address[] private _tokenAddressArray;

     
    uint private _redeemableCounter;

     
    address private _stablecoin;

     
    bytes32 private _oracleNode;

     
     
     
     
     
    constructor(address _ens_, bytes32 _oracleNode_, bytes32 _controllerNode_, address _stablecoinAddress_) ENSResolvable(_ens_) Controllable(_controllerNode_) public {
        _oracleNode = _oracleNode_;
        _stablecoin = _stablecoinAddress_;
         
        _methodIdWhitelist[_APPROVE] = true;
        _methodIdWhitelist[_BURN] = true;
        _methodIdWhitelist[_TRANSFER] = true;
        _methodIdWhitelist[_TRANSFER_FROM] = true;
    }

    modifier onlyAdminOrOracle() {
        address oracleAddress = _ensResolve(_oracleNode);
        require (_isAdmin(msg.sender) || msg.sender == oracleAddress, "either oracle or admin");
        _;
    }

     
     
     
     
     
     
     
    function addTokens(address[] calldata _tokens, bytes32[] calldata _symbols, uint[] calldata _magnitude, bool[] calldata _loadable, bool[] calldata _redeemable, uint _lastUpdate) external onlyAdmin {
         
        require(_tokens.length == _symbols.length && _tokens.length == _magnitude.length && _tokens.length == _loadable.length && _tokens.length == _loadable.length, "parameter lengths do not match");
         
        for (uint i = 0; i < _tokens.length; i++) {
             
            require(!_tokenInfoMap[_tokens[i]].available, "token already available");
             
            string memory symbol = _symbols[i].toSliceB32().toString();
             
            _tokenInfoMap[_tokens[i]] = Token({
                symbol : symbol,
                magnitude : _magnitude[i],
                rate : 0,
                available : true,
                loadable : _loadable[i],
                redeemable: _redeemable[i],
                lastUpdate : _lastUpdate
                });
             
            _tokenAddressArray.push(_tokens[i]);
             
            if (_redeemable[i]){
                _redeemableCounter = _redeemableCounter.add(1);
            }
             
            emit AddedToken(msg.sender, _tokens[i], symbol, _magnitude[i], _loadable[i], _redeemable[i]);
        }
    }

     
     
    function removeTokens(address[] calldata _tokens) external onlyAdmin {
         
        for (uint i = 0; i < _tokens.length; i++) {
             
            address token = _tokens[i];
             
            require(_tokenInfoMap[token].available, "token is not available");
             
            if (_tokenInfoMap[token].redeemable){
                _redeemableCounter = _redeemableCounter.sub(1);
            }
             
            delete _tokenInfoMap[token];
             
            for (uint j = 0; j < _tokenAddressArray.length.sub(1); j++) {
                if (_tokenAddressArray[j] == token) {
                    _tokenAddressArray[j] = _tokenAddressArray[_tokenAddressArray.length.sub(1)];
                    break;
                }
            }
            _tokenAddressArray.length--;
             
            emit RemovedToken(msg.sender, token);
        }
    }

     
     
    function getERC20RecipientAndAmount(address _token, bytes calldata _data) external view returns (address, uint) {
         
         
        require(_data.length >= 4 + 32, "not enough method-encoding bytes");
         
        bytes4 signature = _data._bytesToBytes4(0);
         
        require(isERC20MethodSupported(_token, signature), "unsupported method");
         
        if (signature == _BURN) {
             
            return (_token, _data._bytesToUint256(4));
        } else if (signature == _TRANSFER_FROM) {
             
            require(_data.length >= 4 + 32 + 32 + 32, "not enough data for transferFrom");
            return ( _data._bytesToAddress(4 + 32 + 12), _data._bytesToUint256(4 + 32 + 32));
        } else {  
             
            require(_data.length >= 4 + 32 + 32, "not enough data for transfer/appprove");
            return (_data._bytesToAddress(4 + 12), _data._bytesToUint256(4 + 32));
        }
    }

     
    function setTokenLoadable(address _token, bool _loadable) external onlyAdmin {
         
        require(_tokenInfoMap[_token].available, "token is not available");

         
        _tokenInfoMap[_token].loadable = _loadable;

        emit UpdatedTokenLoadable(msg.sender, _token, _loadable);
    }

     
    function setTokenRedeemable(address _token, bool _redeemable) external onlyAdmin {
         
        require(_tokenInfoMap[_token].available, "token is not available");

         
        _tokenInfoMap[_token].redeemable = _redeemable;

        emit UpdatedTokenRedeemable(msg.sender, _token, _redeemable);
    }

     
     
     
     
    function updateTokenRate(address _token, uint _rate, uint _updateDate) external onlyAdminOrOracle {
         
        require(_tokenInfoMap[_token].available, "token is not available");
         
        _tokenInfoMap[_token].rate = _rate;
         
        _tokenInfoMap[_token].lastUpdate = _updateDate;
         
        emit UpdatedTokenRate(msg.sender, _token, _rate);
    }

     
    function claim(address payable _to, address _asset, uint _amount) external onlyAdmin {
        _safeTransfer(_to, _asset, _amount);
        emit Claimed(_to, _asset, _amount);
    }

     
     
     
     
     
     
     
     
     
    function getTokenInfo(address _a) external view returns (string memory, uint256, uint256, bool, bool, bool, uint256) {
        Token storage tokenInfo = _tokenInfoMap[_a];
        return (tokenInfo.symbol, tokenInfo.magnitude, tokenInfo.rate, tokenInfo.available, tokenInfo.loadable, tokenInfo.redeemable, tokenInfo.lastUpdate);
    }

     
     
     
     
     
     
     
     
    function getStablecoinInfo() external view returns (string memory, uint256, uint256, bool, bool, bool, uint256) {
        Token storage stablecoinInfo = _tokenInfoMap[_stablecoin];
        return (stablecoinInfo.symbol, stablecoinInfo.magnitude, stablecoinInfo.rate, stablecoinInfo.available, stablecoinInfo.loadable, stablecoinInfo.redeemable, stablecoinInfo.lastUpdate);
    }

     
     
    function tokenAddressArray() external view returns (address[] memory) {
        return _tokenAddressArray;
    }

     
     
    function redeemableTokens() external view returns (address[] memory) {
        address[] memory redeemableAddresses = new address[](_redeemableCounter);
        uint redeemableIndex = 0;
        for (uint i = 0; i < _tokenAddressArray.length; i++) {
            address token = _tokenAddressArray[i];
            if (_tokenInfoMap[token].redeemable){
                redeemableAddresses[redeemableIndex] = token;
                redeemableIndex += 1;
            }
        }
        return redeemableAddresses;
    }


     
     
    function isERC20MethodSupported(address _token, bytes4 _methodId) public view returns (bool) {
        require(_tokenInfoMap[_token].available, "non-existing token");
        return (_methodIdWhitelist[_methodId]);
    }

     
     
    function isERC20MethodWhitelisted(bytes4 _methodId) external view returns (bool) {
        return (_methodIdWhitelist[_methodId]);
    }

     
     
    function redeemableCounter() external view returns (uint) {
        return _redeemableCounter;
    }

     
     
    function stablecoin() external view returns (address) {
        return _stablecoin;
    }

     
     
    function oracleNode() external view returns (bytes32) {
        return _oracleNode;
    }
}

contract TokenWhitelistable is ENSResolvable {

     
    bytes32 private _tokenWhitelistNode;

     
     
    constructor(bytes32 _tokenWhitelistNode_) internal {
        _tokenWhitelistNode = _tokenWhitelistNode_;
    }

     
     
    function tokenWhitelistNode() external view returns (bytes32) {
        return _tokenWhitelistNode;
    }

     
     
     
     
     
     
     
     
     
    function _getTokenInfo(address _a) internal view returns (string memory, uint256, uint256, bool, bool, bool, uint256) {
        return ITokenWhitelist(_ensResolve(_tokenWhitelistNode)).getTokenInfo(_a);
    }

     
     
     
     
     
     
     
     
    function _getStablecoinInfo() internal view returns (string memory, uint256, uint256, bool, bool, bool, uint256) {
        return ITokenWhitelist(_ensResolve(_tokenWhitelistNode)).getStablecoinInfo();
    }

     
     
    function _tokenAddressArray() internal view returns (address[] memory) {
        return ITokenWhitelist(_ensResolve(_tokenWhitelistNode)).tokenAddressArray();
    }

     
     
    function _redeemableTokens() internal view returns (address[] memory) {
        return ITokenWhitelist(_ensResolve(_tokenWhitelistNode)).redeemableTokens();
    }

     
     
     
     
    function _updateTokenRate(address _token, uint _rate, uint _updateDate) internal {
        ITokenWhitelist(_ensResolve(_tokenWhitelistNode)).updateTokenRate(_token, _rate, _updateDate);
    }

     
     
    function _getERC20RecipientAndAmount(address _destination, bytes memory _data) internal view returns (address, uint) {
        return ITokenWhitelist(_ensResolve(_tokenWhitelistNode)).getERC20RecipientAndAmount(_destination, _data);
    }

     
     
    function _isTokenAvailable(address _a) internal view returns (bool) {
        ( , , , bool available, , , ) = _getTokenInfo(_a);
        return available;
    }

     
     
    function _isTokenRedeemable(address _a) internal view returns (bool) {
        ( , , , , , bool redeemable, ) = _getTokenInfo(_a);
        return redeemable;
    }

     
     
    function _isTokenLoadable(address _a) internal view returns (bool) {
        ( , , , , bool loadable, , ) = _getTokenInfo(_a);
        return loadable;
    }

     
     
    function _stablecoin() internal view returns (address) {
        return ITokenWhitelist(_ensResolve(_tokenWhitelistNode)).stablecoin();
    }

}

contract ControllableOwnable is Controllable, Ownable {
     
    modifier onlyOwnerOrController() {
        require (_isOwner(msg.sender) || _isController(msg.sender), "either owner or controller");
        _;
    }
}


 
 
 
contract AddressWhitelist is ControllableOwnable {
    using SafeMath for uint256;

    event AddedToWhitelist(address _sender, address[] _addresses);
    event SubmittedWhitelistAddition(address[] _addresses, bytes32 _hash);
    event CancelledWhitelistAddition(address _sender, bytes32 _hash);

    event RemovedFromWhitelist(address _sender, address[] _addresses);
    event SubmittedWhitelistRemoval(address[] _addresses, bytes32 _hash);
    event CancelledWhitelistRemoval(address _sender, bytes32 _hash);

    mapping(address => bool) public whitelistMap;
    address[] public whitelistArray;
    address[] private _pendingWhitelistAddition;
    address[] private _pendingWhitelistRemoval;
    bool public submittedWhitelistAddition;
    bool public submittedWhitelistRemoval;
    bool public isSetWhitelist;

     
    modifier hasNoOwnerOrZeroAddress(address[] memory _addresses) {
        for (uint i = 0; i < _addresses.length; i++) {
            require(!_isOwner(_addresses[i]), "provided whitelist contains the owner address");
            require(_addresses[i] != address(0), "provided whitelist contains the zero address");
        }
        _;
    }

     
    modifier noActiveSubmission() {
        require(!submittedWhitelistAddition && !submittedWhitelistRemoval, "whitelist operation has already been submitted");
        _;
    }

     
    function pendingWhitelistAddition() external view returns (address[] memory) {
        return _pendingWhitelistAddition;
    }

     
    function pendingWhitelistRemoval() external view returns (address[] memory) {
        return _pendingWhitelistRemoval;
    }

     
     
    function setWhitelist(address[] calldata _addresses) external onlyOwner hasNoOwnerOrZeroAddress(_addresses) {
         
        require(!isSetWhitelist, "whitelist has already been initialized");
         
        for (uint i = 0; i < _addresses.length; i++) {
             
            whitelistMap[_addresses[i]] = true;
             
            whitelistArray.push(_addresses[i]);
        }
        isSetWhitelist = true;
         
        emit AddedToWhitelist(msg.sender, _addresses);
    }

     
     
    function submitWhitelistAddition(address[] calldata _addresses) external onlyOwner noActiveSubmission hasNoOwnerOrZeroAddress(_addresses) {
         
        require(isSetWhitelist, "whitelist has not been initialized");
         
        require(_addresses.length > 0, "pending whitelist addition is empty");
         
        _pendingWhitelistAddition = _addresses;
         
        submittedWhitelistAddition = true;
         
        emit SubmittedWhitelistAddition(_addresses, calculateHash(_addresses));
    }

     
     
     
    function confirmWhitelistAddition(bytes32 _hash) external onlyController {
         
        require(submittedWhitelistAddition, "whitelist addition has not been submitted");
         
        require(_hash == calculateHash(_pendingWhitelistAddition), "hash of the pending whitelist addition do not match");
         
        for (uint i = 0; i < _pendingWhitelistAddition.length; i++) {
             
            if (!whitelistMap[_pendingWhitelistAddition[i]]) {
                 
                whitelistMap[_pendingWhitelistAddition[i]] = true;
                whitelistArray.push(_pendingWhitelistAddition[i]);
            }
        }
         
        emit AddedToWhitelist(msg.sender, _pendingWhitelistAddition);
         
        delete _pendingWhitelistAddition;
         
        submittedWhitelistAddition = false;
    }

     
    function cancelWhitelistAddition(bytes32 _hash) external onlyOwnerOrController {
         
        require(submittedWhitelistAddition, "whitelist addition has not been submitted");
         
        require(_hash == calculateHash(_pendingWhitelistAddition), "hash of the pending whitelist addition does not match");
         
        delete _pendingWhitelistAddition;
         
        submittedWhitelistAddition = false;
         
        emit CancelledWhitelistAddition(msg.sender, _hash);
    }

     
     
    function submitWhitelistRemoval(address[] calldata _addresses) external onlyOwner noActiveSubmission {
         
        require(isSetWhitelist, "whitelist has not been initialized");
         
        require(_addresses.length > 0, "pending whitelist removal is empty");
         
        _pendingWhitelistRemoval = _addresses;
         
        submittedWhitelistRemoval = true;
         
        emit SubmittedWhitelistRemoval(_addresses, calculateHash(_addresses));
    }

     
    function confirmWhitelistRemoval(bytes32 _hash) external onlyController {
         
        require(submittedWhitelistRemoval, "whitelist removal has not been submitted");
         
        require(_hash == calculateHash(_pendingWhitelistRemoval), "hash of the pending whitelist removal does not match the confirmed hash");
         
        for (uint i = 0; i < _pendingWhitelistRemoval.length; i++) {
             
            if (whitelistMap[_pendingWhitelistRemoval[i]]) {
                whitelistMap[_pendingWhitelistRemoval[i]] = false;
                for (uint j = 0; j < whitelistArray.length.sub(1); j++) {
                    if (whitelistArray[j] == _pendingWhitelistRemoval[i]) {
                        whitelistArray[j] = whitelistArray[whitelistArray.length - 1];
                        break;
                    }
                }
                whitelistArray.length--;
            }
        }
         
        emit RemovedFromWhitelist(msg.sender, _pendingWhitelistRemoval);
         
        delete _pendingWhitelistRemoval;
         
        submittedWhitelistRemoval = false;
    }

     
    function cancelWhitelistRemoval(bytes32 _hash) external onlyOwnerOrController {
         
        require(submittedWhitelistRemoval, "whitelist removal has not been submitted");
         
        require(_hash == calculateHash(_pendingWhitelistRemoval), "hash of the pending whitelist removal do not match");
         
        delete _pendingWhitelistRemoval;
         
        submittedWhitelistRemoval = false;
         
        emit CancelledWhitelistRemoval(msg.sender, _hash);
    }

     
    function calculateHash(address[] memory _addresses) public pure returns (bytes32) {
        return keccak256(abi.encodePacked(_addresses));
    }
}

 
 
library DailyLimitTrait {
    using SafeMath for uint256;

    event UpdatedAvailableLimit();

    struct DailyLimit {
        uint value;
        uint available;
        uint limitTimestamp;
        uint pending;
        bool updateable;
    }

     
     
    function _getAvailableLimit(DailyLimit storage self) internal view returns (uint) {
        if (now > self.limitTimestamp.add(24 hours)) {
            return self.value;
        } else {
            return self.available;
        }
    }

     
    function _enforceLimit(DailyLimit storage self, uint _amount) internal {
         
        _updateAvailableLimit(self);
        require(self.available >= _amount, "available has to be greater or equal to use amount");
        self.available = self.available.sub(_amount);
    }

     
     
    function _setLimit(DailyLimit storage self, uint _amount) internal {
         
        require(!self.updateable, "daily limit not updateable");
         
        _modifyLimit(self, _amount);
         
        self.updateable = true;
    }

     
     
    function _submitLimitUpdate(DailyLimit storage self, uint _amount) internal {
         
        require(self.updateable, "daily limit is still updateable");
         
        self.pending = _amount;
    }

     
    function _confirmLimitUpdate(DailyLimit storage self, uint _amount) internal {
         
        require(self.pending == _amount, "confirmed and submitted limits dont match");
         
        _modifyLimit(self, self.pending);
    }

     
    function _updateAvailableLimit(DailyLimit storage self) private {
        if (now > self.limitTimestamp.add(24 hours)) {
             
            self.limitTimestamp = now;
             
            self.available = self.value;
            emit UpdatedAvailableLimit();
        }
    }

     
     
    function _modifyLimit(DailyLimit storage self, uint _amount) private {
         
        _updateAvailableLimit(self);
         
        self.value = _amount;
         
        if (self.available > self.value) {
            self.available = self.value;
        }
    }
}


 
contract SpendLimit is ControllableOwnable {
    event SetSpendLimit(address _sender, uint _amount);
    event SubmittedSpendLimitUpdate(uint _amount);

    using DailyLimitTrait for DailyLimitTrait.DailyLimit;

    DailyLimitTrait.DailyLimit internal _spendLimit;

     
    constructor(uint _limit_) internal {
        _spendLimit = DailyLimitTrait.DailyLimit(_limit_, _limit_, now, 0, false);
    }

     
     
    function setSpendLimit(uint _amount) external onlyOwner {
        _spendLimit._setLimit(_amount);
        emit SetSpendLimit(msg.sender, _amount);
    }

     
     
    function submitSpendLimitUpdate(uint _amount) external onlyOwner {
        _spendLimit._submitLimitUpdate(_amount);
        emit SubmittedSpendLimitUpdate(_amount);
    }

     
    function confirmSpendLimitUpdate(uint _amount) external onlyController {
        _spendLimit._confirmLimitUpdate(_amount);
        emit SetSpendLimit(msg.sender, _amount);
    }

    function spendLimitAvailable() external view returns (uint) {
        return _spendLimit._getAvailableLimit();
    }

    function spendLimitValue() external view returns (uint) {
        return _spendLimit.value;
    }

    function spendLimitUpdateable() external view returns (bool) {
        return _spendLimit.updateable;
    }

    function spendLimitPending() external view returns (uint) {
        return _spendLimit.pending;
    }
}


 
contract GasTopUpLimit is ControllableOwnable {

    event SetGasTopUpLimit(address _sender, uint _amount);
    event SubmittedGasTopUpLimitUpdate(uint _amount);

    uint constant private _MINIMUM_GAS_TOPUP_LIMIT = 1 finney;
    uint constant private _MAXIMUM_GAS_TOPUP_LIMIT = 500 finney;

    using DailyLimitTrait for DailyLimitTrait.DailyLimit;

    DailyLimitTrait.DailyLimit internal _gasTopUpLimit;

     
    constructor() internal {
        _gasTopUpLimit = DailyLimitTrait.DailyLimit(_MAXIMUM_GAS_TOPUP_LIMIT, _MAXIMUM_GAS_TOPUP_LIMIT, now, 0, false);
    }

     
     
    function setGasTopUpLimit(uint _amount) external onlyOwner {
        require(_MINIMUM_GAS_TOPUP_LIMIT <= _amount && _amount <= _MAXIMUM_GAS_TOPUP_LIMIT, "gas top up amount is outside the min/max range");
        _gasTopUpLimit._setLimit(_amount);
        emit SetGasTopUpLimit(msg.sender, _amount);
    }

     
     
    function submitGasTopUpLimitUpdate(uint _amount) external onlyOwner {
        require(_MINIMUM_GAS_TOPUP_LIMIT <= _amount && _amount <= _MAXIMUM_GAS_TOPUP_LIMIT, "gas top up amount is outside the min/max range");
        _gasTopUpLimit._submitLimitUpdate(_amount);
        emit SubmittedGasTopUpLimitUpdate(_amount);
    }

     
    function confirmGasTopUpLimitUpdate(uint _amount) external onlyController {
        _gasTopUpLimit._confirmLimitUpdate(_amount);
        emit SetGasTopUpLimit(msg.sender, _amount);
    }

    function gasTopUpLimitAvailable() external view returns (uint) {
        return _gasTopUpLimit._getAvailableLimit();
    }

    function gasTopUpLimitValue() external view returns (uint) {
        return _gasTopUpLimit.value;
    }

    function gasTopUpLimitUpdateable() external view returns (bool) {
        return _gasTopUpLimit.updateable;
    }

    function gasTopUpLimitPending() external view returns (uint) {
        return _gasTopUpLimit.pending;
    }
}


 
contract LoadLimit is ControllableOwnable {

    event SetLoadLimit(address _sender, uint _amount);
    event SubmittedLoadLimitUpdate(uint _amount);

    uint constant private _MINIMUM_LOAD_LIMIT = 1 finney;
    uint private _maximumLoadLimit;

    using DailyLimitTrait for DailyLimitTrait.DailyLimit;

    DailyLimitTrait.DailyLimit internal _loadLimit;

     
     
    function setLoadLimit(uint _amount) external onlyOwner {
        require(_MINIMUM_LOAD_LIMIT <= _amount && _amount <= _maximumLoadLimit, "card load amount is outside the min/max range");
        _loadLimit._setLimit(_amount);
        emit SetLoadLimit(msg.sender, _amount);
    }

     
     
    function submitLoadLimitUpdate(uint _amount) external onlyOwner {
        require(_MINIMUM_LOAD_LIMIT <= _amount && _amount <= _maximumLoadLimit, "card load amount is outside the min/max range");
        _loadLimit._submitLimitUpdate(_amount);
        emit SubmittedLoadLimitUpdate(_amount);
    }

     
    function confirmLoadLimitUpdate(uint _amount) external onlyController {
        _loadLimit._confirmLimitUpdate(_amount);
        emit SetLoadLimit(msg.sender, _amount);
    }

    function loadLimitAvailable() external view returns (uint) {
        return _loadLimit._getAvailableLimit();
    }

    function loadLimitValue() external view returns (uint) {
        return _loadLimit.value;
    }

    function loadLimitUpdateable() external view returns (bool) {
        return _loadLimit.updateable;
    }

    function loadLimitPending() external view returns (uint) {
        return _loadLimit.pending;
    }

     
     
    function _initializeLoadLimit(uint _maxLimit) internal {
        _maximumLoadLimit = _maxLimit;
        _loadLimit = DailyLimitTrait.DailyLimit(_maximumLoadLimit, _maximumLoadLimit, now, 0, false);
    }
}


 
contract Vault is AddressWhitelist, SpendLimit, ERC165, Transferrable, Balanceable, TokenWhitelistable {

    using SafeMath for uint256;
    using SafeERC20 for ERC20;

    event Received(address _from, uint _amount);
    event Transferred(address _to, address _asset, uint _amount);
    event BulkTransferred(address _to, address[] _assets);

     
    bytes4 private constant _ERC165_INTERFACE_ID = 0x01ffc9a7;  

     
     
     
     
     
     
    constructor(address payable _owner_, bool _transferable_, bytes32 _tokenWhitelistNode_, bytes32 _controllerNode_, uint _spendLimit_) SpendLimit(_spendLimit_) Ownable(_owner_, _transferable_) Controllable(_controllerNode_) TokenWhitelistable(_tokenWhitelistNode_) public {}

     
    modifier isNotZero(uint _value) {
        require(_value != 0, "provided value cannot be zero");
        _;
    }

     
    function() external payable {
        emit Received(msg.sender, msg.value);
    }

     
    function supportsInterface(bytes4 _interfaceID) external view returns (bool) {
        return _interfaceID == _ERC165_INTERFACE_ID;
    }

     
     
     
     
    function bulkTransfer(address payable _to, address[] calldata _assets) external onlyOwner {
         
        require(_assets.length != 0, "asset array should be non-empty");
         
        for (uint i = 0; i < _assets.length; i++) {
            uint amount = _balance(address(this), _assets[i]);
             
            transfer(_to, _assets[i], amount);
        }

        emit BulkTransferred(_to, _assets);
    }

     
     
     
     
    function transfer(address payable _to, address _asset, uint _amount) public onlyOwner isNotZero(_amount) {
         
        require(_to != address(0), "_to address cannot be set to 0x0");

         
        if (!whitelistMap[_to]) {
             
            uint etherValue = _amount;
             
            if (_asset != address(0)) {
                etherValue = convertToEther(_asset, _amount);
            }
             
             
            _spendLimit._enforceLimit(etherValue);
        }
         
        _safeTransfer(_to, _asset, _amount);
         
        emit Transferred(_to, _asset, _amount);
    }

     
     
     
    function convertToEther(address _token, uint _amount) public view returns (uint) {
         
        (,uint256 magnitude, uint256 rate, bool available, , , ) = _getTokenInfo(_token);
         
        if (available) {
            require(rate != 0, "token rate is 0");
             
            return _amount.mul(rate).div(magnitude);
        }
        return 0;
    }
}


 
contract Wallet is ENSResolvable, Vault, GasTopUpLimit, LoadLimit {

    using SafeERC20 for ERC20;
    using Address for address;

    event ToppedUpGas(address _sender, address _owner, uint _amount);
    event LoadedTokenCard(address _asset, uint _amount);
    event ExecutedTransaction(address _destination, uint _value, bytes _data, bytes _returndata);
    event UpdatedAvailableLimit();

    string constant public WALLET_VERSION = "2.2.0";
    uint constant private _DEFAULT_MAX_STABLECOIN_LOAD_LIMIT = 10000;  

     
    bytes32 private _licenceNode;

     
     
     
     
     
     
     
     
    constructor(address payable _owner_, bool _transferable_, address _ens_, bytes32 _tokenWhitelistNode_, bytes32 _controllerNode_, bytes32 _licenceNode_, uint _spendLimit_) ENSResolvable(_ens_) Vault(_owner_, _transferable_, _tokenWhitelistNode_, _controllerNode_, _spendLimit_) public {
         
        ( ,uint256 stablecoinMagnitude, , , , , ) = _getStablecoinInfo();
        require(stablecoinMagnitude > 0, "stablecoin not set");
        _initializeLoadLimit(_DEFAULT_MAX_STABLECOIN_LOAD_LIMIT * stablecoinMagnitude);
        _licenceNode = _licenceNode_;
    }

     
     
    function topUpGas(uint _amount) external isNotZero(_amount) onlyOwnerOrController {
         
        _gasTopUpLimit._enforceLimit(_amount);
         
        owner().transfer(_amount);
         
        emit ToppedUpGas(msg.sender, owner(), _amount);
    }

     
     
     
     
    function loadTokenCard(address _asset, uint _amount) external payable onlyOwner {
         
        require(_isTokenLoadable(_asset), "token not loadable");
         
        uint stablecoinValue = convertToStablecoin(_asset, _amount);
         
        _loadLimit._enforceLimit(stablecoinValue);
         
        address licenceAddress = _ensResolve(_licenceNode);
        if (_asset != address(0)) {
            ERC20(_asset).safeApprove(licenceAddress, _amount);
            ILicence(licenceAddress).load(_asset, _amount);
        } else {
            ILicence(licenceAddress).load.value(_amount)(_asset, _amount);
        }

        emit LoadedTokenCard(_asset, _amount);

    }

     
     
     
     
    function executeTransaction(address _destination, uint _value, bytes calldata _data) external onlyOwner returns (bytes memory) {
         
         
        if (!whitelistMap[_destination]) {
            _spendLimit._enforceLimit(_value);
        }
         
        if (address(_destination).isContract() && _isTokenAvailable(_destination)) {
             
            address to;
            uint amount;
            (to, amount) = _getERC20RecipientAndAmount(_destination, _data);
            if (!whitelistMap[to]) {
                 
                 
                uint etherValue = convertToEther(_destination, amount);
                _spendLimit._enforceLimit(etherValue);
            }
             
             
            ERC20(_destination).callOptionalReturn(_data);

             
            bytes memory b = new bytes(32);
            b[31] = 0x01;

            emit ExecutedTransaction(_destination, _value, _data, b);
            return b;
        }

        (bool success, bytes memory returndata) = _destination.call.value(_value)(_data);
        require(success, "low-level call failed");

        emit ExecutedTransaction(_destination, _value, _data, returndata);
         
        return returndata;
    }

     
    function licenceNode() external view returns (bytes32) {
        return _licenceNode;
    }

     
     
     
    function convertToStablecoin(address _token, uint _amount) public view returns (uint) {
         
        if (_token == _stablecoin()) {
            return _amount;
        }
        uint amountToSend = _amount;

         
        if (_token != address(0)) {
             
             
            (,uint256 magnitude, uint256 rate, bool available, , , ) = _getTokenInfo(_token);
             
            require(available, "token is not available");
            require(rate != 0, "token rate is 0");
             
            amountToSend = _amount.mul(rate).div(magnitude);
        }
         
         
        ( ,uint256 stablecoinMagnitude, uint256 stablecoinRate, bool stablecoinAvailable, , , ) = _getStablecoinInfo();
         
        require(stablecoinAvailable, "token is not available");
        require(stablecoinRate != 0, "stablecoin rate is 0");
         
        return amountToSend.mul(stablecoinMagnitude).div(stablecoinRate);
    }

}