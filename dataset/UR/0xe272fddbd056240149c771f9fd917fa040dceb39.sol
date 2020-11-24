 

pragma solidity ^0.4.22;

 
contract Ownable {
  address public owner;


  event OwnershipRenounced(address indexed previousOwner);
  event OwnershipTransferred(
    address indexed previousOwner,
    address indexed newOwner
  );


   
  constructor() public {
    owner = msg.sender;
  }

   
  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }

   
  function renounceOwnership() public onlyOwner {
    emit OwnershipRenounced(owner);
    owner = address(0);
  }

   
  function transferOwnership(address _newOwner) public onlyOwner {
    _transferOwnership(_newOwner);
  }

   
  function _transferOwnership(address _newOwner) internal {
    require(_newOwner != address(0));
    emit OwnershipTransferred(owner, _newOwner);
    owner = _newOwner;
  }
}

 
contract Destructible is Ownable {
   
  function destroy() public onlyOwner {
    selfdestruct(owner);
  }

  function destroyAndSend(address _recipient) public onlyOwner {
    selfdestruct(_recipient);
  }
}

 
interface ERC165 {

   
  function supportsInterface(bytes4 _interfaceId)
    external
    view
    returns (bool);
}

 
contract ERC721Basic is ERC165 {

  bytes4 internal constant InterfaceId_ERC721 = 0x80ac58cd;
   

  bytes4 internal constant InterfaceId_ERC721Enumerable = 0x780e9d63;
   

  bytes4 internal constant InterfaceId_ERC721Metadata = 0x5b5e139f;
   

  event Transfer(
    address indexed _from,
    address indexed _to,
    uint256 indexed _tokenId
  );
  event Approval(
    address indexed _owner,
    address indexed _approved,
    uint256 indexed _tokenId
  );
  event ApprovalForAll(
    address indexed _owner,
    address indexed _operator,
    bool _approved
  );

  function balanceOf(address _owner) public view returns (uint256 _balance);
  function ownerOf(uint256 _tokenId) public view returns (address _owner);

  function approve(address _to, uint256 _tokenId) public;
  function getApproved(uint256 _tokenId)
    public view returns (address _operator);

  function setApprovalForAll(address _operator, bool _approved) public;
  function isApprovedForAll(address _owner, address _operator)
    public view returns (bool);

  function transferFrom(address _from, address _to, uint256 _tokenId) public;
  function safeTransferFrom(address _from, address _to, uint256 _tokenId)
    public;

  function safeTransferFrom(
    address _from,
    address _to,
    uint256 _tokenId,
    bytes _data
  )
    public;
}

 
contract ERC721Enumerable is ERC721Basic {
  function totalSupply() public view returns (uint256);
  function tokenOfOwnerByIndex(
    address _owner,
    uint256 _index
  )
    public
    view
    returns (uint256 _tokenId);

  function tokenByIndex(uint256 _index) public view returns (uint256);
}


 
contract ERC721Metadata is ERC721Basic {
  function name() external view returns (string _name);
  function symbol() external view returns (string _symbol);
  function tokenURI(uint256 _tokenId) public view returns (string);
}


 
contract ERC721 is ERC721Basic, ERC721Enumerable, ERC721Metadata {
}

 
contract SupportsInterfaceWithLookup is ERC165 {

  bytes4 public constant InterfaceId_ERC165 = 0x01ffc9a7;
   

   
  mapping(bytes4 => bool) internal supportedInterfaces;

   
  constructor()
    public
  {
    _registerInterface(InterfaceId_ERC165);
  }

   
  function supportsInterface(bytes4 _interfaceId)
    external
    view
    returns (bool)
  {
    return supportedInterfaces[_interfaceId];
  }

   
  function _registerInterface(bytes4 _interfaceId)
    internal
  {
    require(_interfaceId != 0xffffffff);
    supportedInterfaces[_interfaceId] = true;
  }
}

 
library SafeMath {

   
  function mul(uint256 _a, uint256 _b) internal pure returns (uint256) {
     
     
     
    if (_a == 0) {
      return 0;
    }

    uint256 c = _a * _b;
    require(c / _a == _b);

    return c;
  }

   
  function div(uint256 _a, uint256 _b) internal pure returns (uint256) {
    require(_b > 0);  
    uint256 c = _a / _b;
     

    return c;
  }

   
  function sub(uint256 _a, uint256 _b) internal pure returns (uint256) {
    require(_b <= _a);
    uint256 c = _a - _b;

    return c;
  }

   
  function add(uint256 _a, uint256 _b) internal pure returns (uint256) {
    uint256 c = _a + _b;
    require(c >= _a);

    return c;
  }

   
  function mod(uint256 a, uint256 b) internal pure returns (uint256) {
    require(b != 0);
    return a % b;
  }
}

 
library AddressUtils {

   
  function isContract(address _account) internal view returns (bool) {
    uint256 size;
     
     
     
     
     
     
     
    assembly { size := extcodesize(_account) }
    return size > 0;
  }

}

 
contract ERC721Receiver {
   
  bytes4 internal constant ERC721_RECEIVED = 0x150b7a02;

   
  function onERC721Received(
    address _operator,
    address _from,
    uint256 _tokenId,
    bytes _data
  )
    public
    returns(bytes4);
}

 
contract ERC721BasicToken is SupportsInterfaceWithLookup, ERC721Basic {

  using SafeMath for uint256;
  using AddressUtils for address;

   
   
  bytes4 private constant ERC721_RECEIVED = 0x150b7a02;

   
  mapping (uint256 => address) internal tokenOwner;

   
  mapping (uint256 => address) internal tokenApprovals;

   
  mapping (address => uint256) internal ownedTokensCount;

   
  mapping (address => mapping (address => bool)) internal operatorApprovals;

  constructor()
    public
  {
     
    _registerInterface(InterfaceId_ERC721);
  }

   
  function balanceOf(address _owner) public view returns (uint256) {
    require(_owner != address(0));
    return ownedTokensCount[_owner];
  }

   
  function ownerOf(uint256 _tokenId) public view returns (address) {
    address owner = tokenOwner[_tokenId];
    require(owner != address(0));
    return owner;
  }

   
  function approve(address _to, uint256 _tokenId) public {
    address owner = ownerOf(_tokenId);
    require(_to != owner);
    require(msg.sender == owner || isApprovedForAll(owner, msg.sender));

    tokenApprovals[_tokenId] = _to;
    emit Approval(owner, _to, _tokenId);
  }

   
  function getApproved(uint256 _tokenId) public view returns (address) {
    return tokenApprovals[_tokenId];
  }

   
  function setApprovalForAll(address _to, bool _approved) public {
    require(_to != msg.sender);
    operatorApprovals[msg.sender][_to] = _approved;
    emit ApprovalForAll(msg.sender, _to, _approved);
  }

   
  function isApprovedForAll(
    address _owner,
    address _operator
  )
    public
    view
    returns (bool)
  {
    return operatorApprovals[_owner][_operator];
  }

   
  function transferFrom(
    address _from,
    address _to,
    uint256 _tokenId
  )
    public
  {
    require(isApprovedOrOwner(msg.sender, _tokenId));
    require(_to != address(0));

    clearApproval(_from, _tokenId);
    removeTokenFrom(_from, _tokenId);
    addTokenTo(_to, _tokenId);

    emit Transfer(_from, _to, _tokenId);
  }

   
  function safeTransferFrom(
    address _from,
    address _to,
    uint256 _tokenId
  )
    public
  {
     
    safeTransferFrom(_from, _to, _tokenId, "");
  }

   
  function safeTransferFrom(
    address _from,
    address _to,
    uint256 _tokenId,
    bytes _data
  )
    public
  {
    transferFrom(_from, _to, _tokenId);
     
    require(checkAndCallSafeTransfer(_from, _to, _tokenId, _data));
  }

   
  function _exists(uint256 _tokenId) internal view returns (bool) {
    address owner = tokenOwner[_tokenId];
    return owner != address(0);
  }

   
  function isApprovedOrOwner(
    address _spender,
    uint256 _tokenId
  )
    internal
    view
    returns (bool)
  {
    address owner = ownerOf(_tokenId);
     
     
     
    return (
      _spender == owner ||
      getApproved(_tokenId) == _spender ||
      isApprovedForAll(owner, _spender)
    );
  }

   
  function _mint(address _to, uint256 _tokenId) internal {
    require(_to != address(0));
    addTokenTo(_to, _tokenId);
    emit Transfer(address(0), _to, _tokenId);
  }

   
  function _burn(address _owner, uint256 _tokenId) internal {
    clearApproval(_owner, _tokenId);
    removeTokenFrom(_owner, _tokenId);
    emit Transfer(_owner, address(0), _tokenId);
  }

   
  function clearApproval(address _owner, uint256 _tokenId) internal {
    require(ownerOf(_tokenId) == _owner);
    if (tokenApprovals[_tokenId] != address(0)) {
      tokenApprovals[_tokenId] = address(0);
    }
  }

   
  function addTokenTo(address _to, uint256 _tokenId) internal {
    require(tokenOwner[_tokenId] == address(0));
    tokenOwner[_tokenId] = _to;
    ownedTokensCount[_to] = ownedTokensCount[_to].add(1);
  }

   
  function removeTokenFrom(address _from, uint256 _tokenId) internal {
    require(ownerOf(_tokenId) == _from);
    ownedTokensCount[_from] = ownedTokensCount[_from].sub(1);
    tokenOwner[_tokenId] = address(0);
  }

   
  function checkAndCallSafeTransfer(
    address _from,
    address _to,
    uint256 _tokenId,
    bytes _data
  )
    internal
    returns (bool)
  {
    if (!_to.isContract()) {
      return true;
    }
    bytes4 retval = ERC721Receiver(_to).onERC721Received(
      msg.sender, _from, _tokenId, _data);
    return (retval == ERC721_RECEIVED);
  }
}

 
contract ERC721Token is SupportsInterfaceWithLookup, ERC721BasicToken, ERC721 {

   
  string internal name_;

   
  string internal symbol_;

   
  mapping(address => uint256[]) internal ownedTokens;

   
  mapping(uint256 => uint256) internal ownedTokensIndex;

   
  uint256[] internal allTokens;

   
  mapping(uint256 => uint256) internal allTokensIndex;

   
  mapping(uint256 => string) internal tokenURIs;

   
  constructor(string _name, string _symbol) public {
    name_ = _name;
    symbol_ = _symbol;

     
    _registerInterface(InterfaceId_ERC721Enumerable);
    _registerInterface(InterfaceId_ERC721Metadata);
  }

   
  function name() external view returns (string) {
    return name_;
  }

   
  function symbol() external view returns (string) {
    return symbol_;
  }

   
  function tokenURI(uint256 _tokenId) public view returns (string) {
    require(_exists(_tokenId));
    return tokenURIs[_tokenId];
  }

   
  function tokenOfOwnerByIndex(
    address _owner,
    uint256 _index
  )
    public
    view
    returns (uint256)
  {
    require(_index < balanceOf(_owner));
    return ownedTokens[_owner][_index];
  }

   
  function totalSupply() public view returns (uint256) {
    return allTokens.length;
  }

   
  function tokenByIndex(uint256 _index) public view returns (uint256) {
    require(_index < totalSupply());
    return allTokens[_index];
  }

   
  function _setTokenURI(uint256 _tokenId, string _uri) internal {
    require(_exists(_tokenId));
    tokenURIs[_tokenId] = _uri;
  }

   
  function addTokenTo(address _to, uint256 _tokenId) internal {
    super.addTokenTo(_to, _tokenId);
    uint256 length = ownedTokens[_to].length;
    ownedTokens[_to].push(_tokenId);
    ownedTokensIndex[_tokenId] = length;
  }

   
  function removeTokenFrom(address _from, uint256 _tokenId) internal {
    super.removeTokenFrom(_from, _tokenId);

     
     
    uint256 tokenIndex = ownedTokensIndex[_tokenId];
    uint256 lastTokenIndex = ownedTokens[_from].length.sub(1);
    uint256 lastToken = ownedTokens[_from][lastTokenIndex];

    ownedTokens[_from][tokenIndex] = lastToken;
     
    ownedTokens[_from].length--;

     
     
     

    ownedTokensIndex[_tokenId] = 0;
    ownedTokensIndex[lastToken] = tokenIndex;
  }

   
  function _mint(address _to, uint256 _tokenId) internal {
    super._mint(_to, _tokenId);

    allTokensIndex[_tokenId] = allTokens.length;
    allTokens.push(_tokenId);
  }

   
  function _burn(address _owner, uint256 _tokenId) internal {
    super._burn(_owner, _tokenId);

     
    if (bytes(tokenURIs[_tokenId]).length != 0) {
      delete tokenURIs[_tokenId];
    }

     
    uint256 tokenIndex = allTokensIndex[_tokenId];
    uint256 lastTokenIndex = allTokens.length.sub(1);
    uint256 lastToken = allTokens[lastTokenIndex];

    allTokens[tokenIndex] = lastToken;
    allTokens[lastTokenIndex] = 0;

    allTokens.length--;
    allTokensIndex[_tokenId] = 0;
    allTokensIndex[lastToken] = tokenIndex;
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
        if (self & 0xffffffffffffffffffffffffffffffff == 0) {
            ret += 16;
            self = bytes32(uint(self) / 0x100000000000000000000000000000000);
        }
        if (self & 0xffffffffffffffff == 0) {
            ret += 8;
            self = bytes32(uint(self) / 0x10000000000000000);
        }
        if (self & 0xffffffff == 0) {
            ret += 4;
            self = bytes32(uint(self) / 0x100000000);
        }
        if (self & 0xffff == 0) {
            ret += 2;
            self = bytes32(uint(self) / 0x10000);
        }
        if (self & 0xff == 0) {
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
            } else if(b < 0xE0) {
                ptr += 2;
            } else if(b < 0xF0) {
                ptr += 3;
            } else if(b < 0xF8) {
                ptr += 4;
            } else if(b < 0xFC) {
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
                if(shortest < 32) {
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
        } else if(b < 0xE0) {
            l = 2;
        } else if(b < 0xF0) {
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
        } else if(b < 0xE0) {
            ret = b & 0x1F;
            length = 2;
        } else if(b < 0xF0) {
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
        for(uint i = 0; i < parts.length; i++)
            length += parts[i]._len;

        string memory ret = new string(length);
        uint retptr;
        assembly { retptr := add(ret, 32) }

        for(i = 0; i < parts.length; i++) {
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

contract CarFactory is Ownable {
    using strings for *;

    uint256 public constant MAX_CARS = 30000 + 150000 + 1000000;
    uint256 public mintedCars = 0;
    address preOrderAddress;
    CarToken token;

    mapping(uint256 => uint256) public tankSizes;
    mapping(uint256 => uint) public savedTypes;
    mapping(uint256 => bool) public giveawayCar;
    
    mapping(uint => uint256[]) public availableIds;
    mapping(uint => uint256) public idCursor;

    event CarMinted(uint256 _tokenId, string _metadata, uint cType);
    event CarSellingBeings();



    modifier onlyPreOrder {
        require(msg.sender == preOrderAddress, "Not authorized");
        _;
    }

    modifier isInitialized {
        require(preOrderAddress != address(0), "No linked preorder");
        require(address(token) != address(0), "No linked token");
        _;
    }

    function uintToString(uint v) internal pure returns (string) {
        uint maxlength = 100;
        bytes memory reversed = new bytes(maxlength);
        uint i = 0;
        while (v != 0) {
            uint remainder = v % 10;
            v = v / 10;
            reversed[i++] = byte(48 + remainder);
        }
        bytes memory s = new bytes(i);  
        for (uint j = 0; j < i; j++) {
            s[j] = reversed[i - j - 1];  
        }
        string memory str = string(s);   
        return str;  
    }

    function mintFor(uint cType, address newOwner) public onlyPreOrder isInitialized returns (uint256) {
        require(mintedCars < MAX_CARS, "Factory has minted the max number of cars");
        
        uint256 _tokenId = nextAvailableId(cType);
        require(!token.exists(_tokenId), "Token already exists");

        string memory id = uintToString(_tokenId).toSlice().concat(".json".toSlice());

        uint256 tankSize = tankSizes[_tokenId];
        string memory _metadata = "https://vault.warriders.com/".toSlice().concat(id.toSlice());

        token.mint(_tokenId, _metadata, cType, tankSize, newOwner);
        mintedCars++;
        
        return _tokenId;
    }

    function giveaway(uint256 _tokenId, uint256 _tankSize, uint cType, bool markCar, address dst) public onlyOwner isInitialized {
        require(dst != address(0), "No destination address given");
        require(!token.exists(_tokenId), "Token already exists");
        require(dst != owner);
        require(dst != address(this));
        require(_tankSize <= token.maxTankSizes(cType));
            
        tankSizes[_tokenId] = _tankSize;
        savedTypes[_tokenId] = cType;

        string memory id = uintToString(_tokenId).toSlice().concat(".json".toSlice());
        string memory _metadata = "https://vault.warriders.com/".toSlice().concat(id.toSlice());

        token.mint(_tokenId, _metadata, cType, _tankSize, dst);
        mintedCars++;

        giveawayCar[_tokenId] = markCar;
    }

    function setTokenMeta(uint256[] _tokenIds, uint256[] ts, uint[] cTypes) public onlyOwner isInitialized {
        for (uint i = 0; i < _tokenIds.length; i++) {
            uint256 _tokenId = _tokenIds[i];
            uint cType = cTypes[i];
            uint256 _tankSize = ts[i];

            require(_tankSize <= token.maxTankSizes(cType));
            
            tankSizes[_tokenId] = _tankSize;
            savedTypes[_tokenId] = cType;
            
            
            availableIds[cTypes[i]].push(_tokenId);
        }
    }
    
    function nextAvailableId(uint cType) private returns (uint256) {
        uint256 currentCursor = idCursor[cType];
        
        require(currentCursor < availableIds[cType].length);
        
        uint256 nextId = availableIds[cType][currentCursor];
        idCursor[cType] = currentCursor + 1;
        return nextId;
    }

     
    function attachPreOrder(address dst) public onlyOwner {
        require(preOrderAddress == address(0));
        require(dst != address(0));

         
        PreOrder preOrder = PreOrder(dst);

        preOrderAddress = address(preOrder);
    }

     
    function attachToken(address dst) public onlyOwner {
        require(address(token) == address(0));
        require(dst != address(0));

         
        CarToken ct = CarToken(dst);

        token = ct;
    }
}

contract CarToken is ERC721Token, Ownable {
    using strings for *;
    
    address factory;

     
    uint public constant UNKNOWN_TYPE = 0;
    uint public constant SUV_TYPE = 1;
    uint public constant TANKER_TYPE = 2;
    uint public constant HOVERCRAFT_TYPE = 3;
    uint public constant TANK_TYPE = 4;
    uint public constant LAMBO_TYPE = 5;
    uint public constant DUNE_BUGGY = 6;
    uint public constant MIDGRADE_TYPE2 = 7;
    uint public constant MIDGRADE_TYPE3 = 8;
    uint public constant HATCHBACK = 9;
    uint public constant REGULAR_TYPE2 = 10;
    uint public constant REGULAR_TYPE3 = 11;
    
    string public constant METADATA_URL = "https://vault.warriders.com/";
    
     
    uint public PREMIUM_TYPE_COUNT = 5;
     
    uint public MIDGRADE_TYPE_COUNT = 3;
     
    uint public REGULAR_TYPE_COUNT = 3;

    mapping(uint256 => uint256) public maxBznTankSizeOfPremiumCarWithIndex;
    mapping(uint256 => uint256) public maxBznTankSizeOfMidGradeCarWithIndex;
    mapping(uint256 => uint256) public maxBznTankSizeOfRegularCarWithIndex;

     
    mapping(uint256 => bool) public isSpecial;
     
    mapping(uint256 => uint) public carType;
     
    mapping(uint => uint256) public carTypeTotalSupply;
     
    mapping(uint => uint256) public carTypeSupply;
     
    mapping(uint => bool) public isTypeSpecial;

     
    mapping(uint256 => uint256) public tankSizes;
    
     
    mapping(uint => uint256) public maxTankSizes;
    
    mapping (uint => uint[]) public premiumTotalSupplyForCar;
    mapping (uint => uint[]) public midGradeTotalSupplyForCar;
    mapping (uint => uint[]) public regularTotalSupplyForCar;

    modifier onlyFactory {
        require(msg.sender == factory, "Not authorized");
        _;
    }

    constructor(address factoryAddress) public ERC721Token("WarRiders", "WR") {
        factory = factoryAddress;

        carTypeTotalSupply[UNKNOWN_TYPE] = 0;  
        carTypeTotalSupply[SUV_TYPE] = 20000;  
        carTypeTotalSupply[TANKER_TYPE] = 9000;  
        carTypeTotalSupply[HOVERCRAFT_TYPE] = 600;  
        carTypeTotalSupply[TANK_TYPE] = 300;  
        carTypeTotalSupply[LAMBO_TYPE] = 100;  
        carTypeTotalSupply[DUNE_BUGGY] = 40000;  
        carTypeTotalSupply[MIDGRADE_TYPE2] = 50000;  
        carTypeTotalSupply[MIDGRADE_TYPE3] = 60000;  
        carTypeTotalSupply[HATCHBACK] = 200000;  
        carTypeTotalSupply[REGULAR_TYPE2] = 300000;  
        carTypeTotalSupply[REGULAR_TYPE3] = 500000;  
        
        maxTankSizes[SUV_TYPE] = 200;  
        maxTankSizes[TANKER_TYPE] = 450;  
        maxTankSizes[HOVERCRAFT_TYPE] = 300;  
        maxTankSizes[TANK_TYPE] = 200;  
        maxTankSizes[LAMBO_TYPE] = 250;  
        maxTankSizes[DUNE_BUGGY] = 120;  
        maxTankSizes[MIDGRADE_TYPE2] = 110;  
        maxTankSizes[MIDGRADE_TYPE3] = 100;  
        maxTankSizes[HATCHBACK] = 90;  
        maxTankSizes[REGULAR_TYPE2] = 70;  
        maxTankSizes[REGULAR_TYPE3] = 40;  
        
        maxBznTankSizeOfPremiumCarWithIndex[1] = 200;  
        maxBznTankSizeOfPremiumCarWithIndex[2] = 450;  
        maxBznTankSizeOfPremiumCarWithIndex[3] = 300;  
        maxBznTankSizeOfPremiumCarWithIndex[4] = 200;  
        maxBznTankSizeOfPremiumCarWithIndex[5] = 250;  
        maxBznTankSizeOfMidGradeCarWithIndex[1] = 100;  
        maxBznTankSizeOfMidGradeCarWithIndex[2] = 110;  
        maxBznTankSizeOfMidGradeCarWithIndex[3] = 120;  
        maxBznTankSizeOfRegularCarWithIndex[1] = 40;  
        maxBznTankSizeOfRegularCarWithIndex[2] = 70;  
        maxBznTankSizeOfRegularCarWithIndex[3] = 90;  

        isTypeSpecial[HOVERCRAFT_TYPE] = true;
        isTypeSpecial[TANK_TYPE] = true;
        isTypeSpecial[LAMBO_TYPE] = true;
    }

    function isCarSpecial(uint256 tokenId) public view returns (bool) {
        return isSpecial[tokenId];
    }

    function getCarType(uint256 tokenId) public view returns (uint) {
        return carType[tokenId];
    }

    function mint(uint256 _tokenId, string _metadata, uint cType, uint256 tankSize, address newOwner) public onlyFactory {
         
         
        require(carTypeSupply[cType] < carTypeTotalSupply[cType], "This type has reached total supply");
        
         
        require(tankSize <= maxTankSizes[cType], "Tank size provided bigger than max for this type");
        
        if (isPremium(cType)) {
            premiumTotalSupplyForCar[cType].push(_tokenId);
        } else if (isMidGrade(cType)) {
            midGradeTotalSupplyForCar[cType].push(_tokenId);
        } else {
            regularTotalSupplyForCar[cType].push(_tokenId);
        }

        super._mint(newOwner, _tokenId);
        super._setTokenURI(_tokenId, _metadata);

        carType[_tokenId] = cType;
        isSpecial[_tokenId] = isTypeSpecial[cType];
        carTypeSupply[cType] = carTypeSupply[cType] + 1;
        tankSizes[_tokenId] = tankSize;
    }
    
    function isPremium(uint cType) public pure returns (bool) {
        return cType == SUV_TYPE || cType == TANKER_TYPE || cType == HOVERCRAFT_TYPE || cType == TANK_TYPE || cType == LAMBO_TYPE;
    }
    
    function isMidGrade(uint cType) public pure returns (bool) {
        return cType == DUNE_BUGGY || cType == MIDGRADE_TYPE2 || cType == MIDGRADE_TYPE3;
    }
    
    function isRegular(uint cType) public pure returns (bool) {
        return cType == HATCHBACK || cType == REGULAR_TYPE2 || cType == REGULAR_TYPE3;
    }
    
    function getTotalSupplyForType(uint cType) public view returns (uint256) {
        return carTypeSupply[cType];
    }
    
    function getPremiumCarsForVariant(uint variant) public view returns (uint[]) {
        return premiumTotalSupplyForCar[variant];
    }
    
    function getMidgradeCarsForVariant(uint variant) public view returns (uint[]) {
        return midGradeTotalSupplyForCar[variant];
    }

    function getRegularCarsForVariant(uint variant) public view returns (uint[]) {
        return regularTotalSupplyForCar[variant];
    }

    function getPremiumCarSupply(uint variant) public view returns (uint) {
        return premiumTotalSupplyForCar[variant].length;
    }
    
    function getMidgradeCarSupply(uint variant) public view returns (uint) {
        return midGradeTotalSupplyForCar[variant].length;
    }

    function getRegularCarSupply(uint variant) public view returns (uint) {
        return regularTotalSupplyForCar[variant].length;
    }
    
    function exists(uint256 _tokenId) public view returns (bool) {
        return super._exists(_tokenId);
    }
}

contract PreOrder is Destructible {
     
    mapping(uint => uint256) public currentTypePrice;

     
     
     
    mapping(uint => uint256[]) public premiumCarsBought;
    mapping(uint => uint256[]) public midGradeCarsBought;
    mapping(uint => uint256[]) public regularCarsBought;
    mapping(uint256 => address) public tokenReserve;

    event consumerBulkBuy(uint256[] variants, address reserver, uint category);
    event CarBought(uint256 carId, uint256 value, address purchaser, uint category);
    event Withdrawal(uint256 amount);

    uint256 public constant COMMISSION_PERCENT = 5;

     
    uint256 public constant MAX_PREMIUM = 30000;
     
    uint256 public constant MAX_MIDGRADE = 150000;
     
    uint256 public constant MAX_REGULAR = 1000000;

     
    uint public PREMIUM_TYPE_COUNT = 5;
     
    uint public MIDGRADE_TYPE_COUNT = 3;
     
    uint public REGULAR_TYPE_COUNT = 3;

    uint private midgrade_offset = 5;
    uint private regular_offset = 6;

    uint256 public constant GAS_REQUIREMENT = 250000;

     
    uint public constant PREMIUM_CATEGORY = 1;
     
    uint public constant MID_GRADE_CATEGORY = 2;
     
    uint public constant REGULAR_CATEGORY = 3;
    
    mapping(address => uint256) internal commissionRate;
    
    address internal constant OPENSEA = 0x5b3256965e7C3cF26E11FCAf296DfC8807C01073;

     
    mapping(uint => uint256) internal percentIncrease;
    mapping(uint => uint256) internal percentBase;
     

     
    uint256 public premiumHold = 30000;
    uint256 public midGradeHold = 150000;
    uint256 public regularHold = 1000000;

    bool public premiumOpen = false;
    bool public midgradeOpen = false;
    bool public regularOpen = false;

     
    CarToken public token;
     
    CarFactory internal factory;

    address internal escrow;

    modifier premiumIsOpen {
         
        require(premiumHold > 0, "No more premium cars");
        require(premiumOpen, "Premium store not open for sale");
        _;
    }

    modifier midGradeIsOpen {
         
        require(midGradeHold > 0, "No more midgrade cars");
        require(midgradeOpen, "Midgrade store not open for sale");
        _;
    }

    modifier regularIsOpen {
         
        require(regularHold > 0, "No more regular cars");
        require(regularOpen, "Regular store not open for sale");
        _;
    }

    modifier onlyFactory {
         
        require(msg.sender == address(factory), "Not authorized");
        _;
    }

    modifier onlyFactoryOrOwner {
         
        require(msg.sender == address(factory) || msg.sender == owner, "Not authorized");
        _;
    }

    function() public payable { }

    constructor(
        address tokenAddress,
        address tokenFactory,
        address e
    ) public {
        token = CarToken(tokenAddress);

        factory = CarFactory(tokenFactory);

        escrow = e;

         
        percentIncrease[1] = 100008;
        percentBase[1] = 100000;
        percentIncrease[2] = 100015;
        percentBase[2] = 100000;
        percentIncrease[3] = 1002;
        percentBase[3] = 1000;
        percentIncrease[4] = 1004;
        percentBase[4] = 1000;
        percentIncrease[5] = 102;
        percentBase[5] = 100;
        
        commissionRate[OPENSEA] = 10;
    }
    
    function setCommission(address referral, uint256 percent) public onlyOwner {
        require(percent > COMMISSION_PERCENT);
        require(percent < 95);
        percent = percent - COMMISSION_PERCENT;
        
        commissionRate[referral] = percent;
    }
    
    function setPercentIncrease(uint256 increase, uint256 base, uint cType) public onlyOwner {
        require(increase > base);
        
        percentIncrease[cType] = increase;
        percentBase[cType] = base;
    }

    function openShop(uint category) public onlyOwner {
        require(category == 1 || category == 2 || category == 3, "Invalid category");

        if (category == PREMIUM_CATEGORY) {
            premiumOpen = true;
        } else if (category == MID_GRADE_CATEGORY) {
            midgradeOpen = true;
        } else if (category == REGULAR_CATEGORY) {
            regularOpen = true;
        }
    }

     
    function setTypePrice(uint cType, uint256 price) public onlyOwner {
        if (currentTypePrice[cType] == 0) {
            require(price > 0, "Price already set");
            currentTypePrice[cType] = price;
        }
    }

     
    function withdraw(uint256 amount) public onlyOwner {
        uint256 balance = address(this).balance;

        require(amount <= balance, "Requested to much");
        owner.transfer(amount);

        emit Withdrawal(amount);
    }

    function reserveManyTokens(uint[] cTypes, uint category) public payable returns (bool) {
        if (category == PREMIUM_CATEGORY) {
            require(premiumOpen, "Premium is not open for sale");
        } else if (category == MID_GRADE_CATEGORY) {
            require(midgradeOpen, "Midgrade is not open for sale");
        } else if (category == REGULAR_CATEGORY) {
            require(regularOpen, "Regular is not open for sale");
        } else {
            revert();
        }

        address reserver = msg.sender;

        uint256 ether_required = 0;
        for (uint i = 0; i < cTypes.length; i++) {
            uint cType = cTypes[i];

            uint256 price = priceFor(cType);

            ether_required += (price + GAS_REQUIREMENT);

            currentTypePrice[cType] = price;
        }

        require(msg.value >= ether_required);

        uint256 refundable = msg.value - ether_required;

        escrow.transfer(ether_required);

        if (refundable > 0) {
            reserver.transfer(refundable);
        }

        emit consumerBulkBuy(cTypes, reserver, category);
    }

     function buyBulkPremiumCar(address referal, uint[] variants, address new_owner) public payable premiumIsOpen returns (bool) {
         uint n = variants.length;
         require(n <= 10, "Max bulk buy is 10 cars");

         for (uint i = 0; i < n; i++) {
             buyCar(referal, variants[i], false, new_owner, PREMIUM_CATEGORY);
         }
     }

     function buyBulkMidGradeCar(address referal, uint[] variants, address new_owner) public payable midGradeIsOpen returns (bool) {
         uint n = variants.length;
         require(n <= 10, "Max bulk buy is 10 cars");

         for (uint i = 0; i < n; i++) {
             buyCar(referal, variants[i], false, new_owner, MID_GRADE_CATEGORY);
         }
     }

     function buyBulkRegularCar(address referal, uint[] variants, address new_owner) public payable regularIsOpen returns (bool) {
         uint n = variants.length;
         require(n <= 10, "Max bulk buy is 10 cars");

         for (uint i = 0; i < n; i++) {
             buyCar(referal, variants[i], false, new_owner, REGULAR_CATEGORY);
         }
     }

    function buyCar(address referal, uint cType, bool give_refund, address new_owner, uint category) public payable returns (bool) {
        require(category == PREMIUM_CATEGORY || category == MID_GRADE_CATEGORY || category == REGULAR_CATEGORY);
        if (category == PREMIUM_CATEGORY) {
            require(cType == 1 || cType == 2 || cType == 3 || cType == 4 || cType == 5, "Invalid car type");
            require(premiumHold > 0, "No more premium cars");
            require(premiumOpen, "Premium store not open for sale");
        } else if (category == MID_GRADE_CATEGORY) {
            require(cType == 6 || cType == 7 || cType == 8, "Invalid car type");
            require(midGradeHold > 0, "No more midgrade cars");
            require(midgradeOpen, "Midgrade store not open for sale");
        } else if (category == REGULAR_CATEGORY) {
            require(cType == 9 || cType == 10 || cType == 11, "Invalid car type");
            require(regularHold > 0, "No more regular cars");
            require(regularOpen, "Regular store not open for sale");
        }

        uint256 price = priceFor(cType);
        require(price > 0, "Price not yet set");
        require(msg.value >= price, "Not enough ether sent");
         
        currentTypePrice[cType] = price;  

        uint256 _tokenId = factory.mintFor(cType, new_owner);  
        
        if (category == PREMIUM_CATEGORY) {
            premiumCarsBought[cType].push(_tokenId);
            premiumHold--;
        } else if (category == MID_GRADE_CATEGORY) {
            midGradeCarsBought[cType - 5].push(_tokenId);
            midGradeHold--;
        } else if (category == REGULAR_CATEGORY) {
            regularCarsBought[cType - 8].push(_tokenId);
            regularHold--;
        }

        if (give_refund && msg.value > price) {
            uint256 change = msg.value - price;

            msg.sender.transfer(change);
        }

        if (referal != address(0)) {
            require(referal != msg.sender, "The referal cannot be the sender");
            require(referal != tx.origin, "The referal cannot be the tranaction origin");
            require(referal != new_owner, "The referal cannot be the new owner");

             
            uint256 totalCommision = COMMISSION_PERCENT + commissionRate[referal];

            uint256 commision = (price * totalCommision) / 100;

            referal.transfer(commision);
        }

        emit CarBought(_tokenId, price, new_owner, category);
    }

     
    function priceFor(uint cType) public view returns (uint256) {
        uint256 percent = percentIncrease[cType];
        uint256 base = percentBase[cType];

        uint256 currentPrice = currentTypePrice[cType];
        uint256 nextPrice = (currentPrice * percent);

         
        return nextPrice / base;
    }

    function sold(uint256 _tokenId) public view returns (bool) {
        return token.exists(_tokenId);
    }
}