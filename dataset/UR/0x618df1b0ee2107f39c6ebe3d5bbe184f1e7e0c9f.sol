 

pragma solidity ^0.4.13;

library Strings {
    struct slice {
        uint _len;
        uint _ptr;
    }

    function memcpy(uint dest, uint src, uint len) private {
         
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

     
    function toSlice(string self) internal returns (slice) {
        uint ptr;
        assembly {
            ptr := add(self, 0x20)
        }
        return slice(bytes(self).length, ptr);
    }

     
    function len(bytes32 self) internal returns (uint) {
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

     
    function toSliceB32(bytes32 self) internal returns (slice ret) {
         
        assembly {
            let ptr := mload(0x40)
            mstore(0x40, add(ptr, 0x20))
            mstore(ptr, self)
            mstore(add(ret, 0x20), ptr)
        }
        ret._len = len(self);
    }

     
    function copy(slice self) internal returns (slice) {
        return slice(self._len, self._ptr);
    }

     
    function toString(slice self) internal returns (string) {
        var ret = new string(self._len);
        uint retptr;
        assembly { retptr := add(ret, 32) }

        memcpy(retptr, self._ptr, self._len);
        return ret;
    }

     
    function len(slice self) internal returns (uint) {
         
        var ptr = self._ptr - 31;
        var end = ptr + self._len;
        for (uint len = 0; ptr < end; len++) {
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
        return len;
    }

     
    function empty(slice self) internal returns (bool) {
        return self._len == 0;
    }

     
    function compare(slice self, slice other) internal returns (int) {
        uint shortest = self._len;
        if (other._len < self._len)
            shortest = other._len;

        var selfptr = self._ptr;
        var otherptr = other._ptr;
        for (uint idx = 0; idx < shortest; idx += 32) {
            uint a;
            uint b;
            assembly {
                a := mload(selfptr)
                b := mload(otherptr)
            }
            if (a != b) {
                 
                uint mask = ~(2 ** (8 * (32 - shortest + idx)) - 1);
                var diff = (a & mask) - (b & mask);
                if (diff != 0)
                    return int(diff);
            }
            selfptr += 32;
            otherptr += 32;
        }
        return int(self._len) - int(other._len);
    }

     
    function equals(slice self, slice other) internal returns (bool) {
        return compare(self, other) == 0;
    }

     
    function nextRune(slice self, slice rune) internal returns (slice) {
        rune._ptr = self._ptr;

        if (self._len == 0) {
            rune._len = 0;
            return rune;
        }

        uint len;
        uint b;
         
        assembly { b := and(mload(sub(mload(add(self, 32)), 31)), 0xFF) }
        if (b < 0x80) {
            len = 1;
        } else if(b < 0xE0) {
            len = 2;
        } else if(b < 0xF0) {
            len = 3;
        } else {
            len = 4;
        }

         
        if (len > self._len) {
            rune._len = self._len;
            self._ptr += self._len;
            self._len = 0;
            return rune;
        }

        self._ptr += len;
        self._len -= len;
        rune._len = len;
        return rune;
    }

     
    function nextRune(slice self) internal returns (slice ret) {
        nextRune(self, ret);
    }

     
    function ord(slice self) internal returns (uint ret) {
        if (self._len == 0) {
            return 0;
        }

        uint word;
        uint len;
        uint div = 2 ** 248;

         
        assembly { word:= mload(mload(add(self, 32))) }
        var b = word / div;
        if (b < 0x80) {
            ret = b;
            len = 1;
        } else if(b < 0xE0) {
            ret = b & 0x1F;
            len = 2;
        } else if(b < 0xF0) {
            ret = b & 0x0F;
            len = 3;
        } else {
            ret = b & 0x07;
            len = 4;
        }

         
        if (len > self._len) {
            return 0;
        }

        for (uint i = 1; i < len; i++) {
            div = div / 256;
            b = (word / div) & 0xFF;
            if (b & 0xC0 != 0x80) {
                 
                return 0;
            }
            ret = (ret * 64) | (b & 0x3F);
        }

        return ret;
    }

     
    function keccak(slice self) internal returns (bytes32 ret) {
        assembly {
            ret := sha3(mload(add(self, 32)), mload(self))
        }
    }

     
    function startsWith(slice self, slice needle) internal returns (bool) {
        if (self._len < needle._len) {
            return false;
        }

        if (self._ptr == needle._ptr) {
            return true;
        }

        bool equal;
        assembly {
            let len := mload(needle)
            let selfptr := mload(add(self, 0x20))
            let needleptr := mload(add(needle, 0x20))
            equal := eq(sha3(selfptr, len), sha3(needleptr, len))
        }
        return equal;
    }

     
    function beyond(slice self, slice needle) internal returns (slice) {
        if (self._len < needle._len) {
            return self;
        }

        bool equal = true;
        if (self._ptr != needle._ptr) {
            assembly {
                let len := mload(needle)
                let selfptr := mload(add(self, 0x20))
                let needleptr := mload(add(needle, 0x20))
                equal := eq(sha3(selfptr, len), sha3(needleptr, len))
            }
        }

        if (equal) {
            self._len -= needle._len;
            self._ptr += needle._len;
        }

        return self;
    }

     
    function endsWith(slice self, slice needle) internal returns (bool) {
        if (self._len < needle._len) {
            return false;
        }

        var selfptr = self._ptr + self._len - needle._len;

        if (selfptr == needle._ptr) {
            return true;
        }

        bool equal;
        assembly {
            let len := mload(needle)
            let needleptr := mload(add(needle, 0x20))
            equal := eq(sha3(selfptr, len), sha3(needleptr, len))
        }

        return equal;
    }

     
    function until(slice self, slice needle) internal returns (slice) {
        if (self._len < needle._len) {
            return self;
        }

        var selfptr = self._ptr + self._len - needle._len;
        bool equal = true;
        if (selfptr != needle._ptr) {
            assembly {
                let len := mload(needle)
                let needleptr := mload(add(needle, 0x20))
                equal := eq(sha3(selfptr, len), sha3(needleptr, len))
            }
        }

        if (equal) {
            self._len -= needle._len;
        }

        return self;
    }

     
     
    function findPtr(uint selflen, uint selfptr, uint needlelen, uint needleptr) private returns (uint) {
        uint ptr;
        uint idx;

        if (needlelen <= selflen) {
            if (needlelen <= 32) {
                 
                assembly {
                    let mask := not(sub(exp(2, mul(8, sub(32, needlelen))), 1))
                    let needledata := and(mload(needleptr), mask)
                    let end := add(selfptr, sub(selflen, needlelen))
                    ptr := selfptr
                    loop:
                    jumpi(exit, eq(and(mload(ptr), mask), needledata))
                    ptr := add(ptr, 1)
                    jumpi(loop, lt(sub(ptr, 1), end))
                    ptr := add(selfptr, selflen)
                    exit:
                }
                return ptr;
            } else {
                 
                bytes32 hash;
                assembly { hash := sha3(needleptr, needlelen) }
                ptr = selfptr;
                for (idx = 0; idx <= selflen - needlelen; idx++) {
                    bytes32 testHash;
                    assembly { testHash := sha3(ptr, needlelen) }
                    if (hash == testHash)
                        return ptr;
                    ptr += 1;
                }
            }
        }
        return selfptr + selflen;
    }

     
     
    function rfindPtr(uint selflen, uint selfptr, uint needlelen, uint needleptr) private returns (uint) {
        uint ptr;

        if (needlelen <= selflen) {
            if (needlelen <= 32) {
                 
                assembly {
                    let mask := not(sub(exp(2, mul(8, sub(32, needlelen))), 1))
                    let needledata := and(mload(needleptr), mask)
                    ptr := add(selfptr, sub(selflen, needlelen))
                    loop:
                    jumpi(ret, eq(and(mload(ptr), mask), needledata))
                    ptr := sub(ptr, 1)
                    jumpi(loop, gt(add(ptr, 1), selfptr))
                    ptr := selfptr
                    jump(exit)
                    ret:
                    ptr := add(ptr, needlelen)
                    exit:
                }
                return ptr;
            } else {
                 
                bytes32 hash;
                assembly { hash := sha3(needleptr, needlelen) }
                ptr = selfptr + (selflen - needlelen);
                while (ptr >= selfptr) {
                    bytes32 testHash;
                    assembly { testHash := sha3(ptr, needlelen) }
                    if (hash == testHash)
                        return ptr + needlelen;
                    ptr -= 1;
                }
            }
        }
        return selfptr;
    }

     
    function find(slice self, slice needle) internal returns (slice) {
        uint ptr = findPtr(self._len, self._ptr, needle._len, needle._ptr);
        self._len -= ptr - self._ptr;
        self._ptr = ptr;
        return self;
    }

     
    function rfind(slice self, slice needle) internal returns (slice) {
        uint ptr = rfindPtr(self._len, self._ptr, needle._len, needle._ptr);
        self._len = ptr - self._ptr;
        return self;
    }

     
    function split(slice self, slice needle, slice token) internal returns (slice) {
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

     
    function split(slice self, slice needle) internal returns (slice token) {
        split(self, needle, token);
    }

     
    function rsplit(slice self, slice needle, slice token) internal returns (slice) {
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

     
    function rsplit(slice self, slice needle) internal returns (slice token) {
        rsplit(self, needle, token);
    }

     
    function count(slice self, slice needle) internal returns (uint count) {
        uint ptr = findPtr(self._len, self._ptr, needle._len, needle._ptr) + needle._len;
        while (ptr <= self._ptr + self._len) {
            count++;
            ptr = findPtr(self._len - (ptr - self._ptr), ptr, needle._len, needle._ptr) + needle._len;
        }
    }

     
    function contains(slice self, slice needle) internal returns (bool) {
        return rfindPtr(self._len, self._ptr, needle._len, needle._ptr) != self._ptr;
    }

     
    function concat(slice self, slice other) internal returns (string) {
        var ret = new string(self._len + other._len);
        uint retptr;
        assembly { retptr := add(ret, 32) }
        memcpy(retptr, self._ptr, self._len);
        memcpy(retptr + self._len, other._ptr, other._len);
        return ret;
    }

     
    function join(slice self, slice[] parts) internal returns (string) {
        if (parts.length == 0)
            return "";

        uint len = self._len * (parts.length - 1);
        for(uint i = 0; i < parts.length; i++)
            len += parts[i]._len;

        var ret = new string(len);
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

library ConvertStringByte {
  function bytes32ToString(bytes32 x) constant returns (string) {
    bytes memory bytesString = new bytes(32);
    uint charCount = 0;
    for (uint j = 0; j < 32; j++) {
      byte char = byte(bytes32(uint(x) * 2 ** (8 * j)));
      if (char != 0) {
          bytesString[charCount] = char;
          charCount++;
      }
    }
    bytes memory bytesStringTrimmed = new bytes(charCount);
    for (j = 0; j < charCount; j++) {
      bytesStringTrimmed[j] = bytesString[j];
    }
    return string(bytesStringTrimmed);
  }

  function stringToBytes32(string memory source) returns (bytes32 result) {
    assembly {
      result := mload(add(source, 32))
    }
  }
}


 
contract Ownable {
  address public owner;


   
  function Ownable() {
    owner = msg.sender;
  }


   
  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }


   
  function transferOwnership(address newOwner) onlyOwner {
    if (newOwner != address(0)) {
      owner = newOwner;
    }
  }

}


contract Platinum is Ownable {
  using SafeMath for uint256;
  using Strings for *;

   
  string public version = "0.0.1";
   
  string public unit = "oz";
   
  uint256 public total;
   
  struct Bullion {
    string index;
    string unit;
    uint256 amount;
    string ipfs;
  }
  bytes32[] public storehouseIndex;
  mapping (bytes32 => Bullion) public storehouse;
   
  address public token;
   
  uint256 public rate = 10;
   
  PlatinumToken coin;





   
  function Platinum() {

  }




   
  event Stock (
    string index,
    string unit,
    uint256 amount,
    string ipfs,
    uint256 total
  );

  event Ship (
    string index,
    uint256 total
  );

  event Mint (
    uint256 amount,
    uint256 total
  );

  event Alchemy (
    uint256 amount,
    uint256 total
  );

  event Buy (
    string index,
    address from,
    uint256 fee,
    uint256 price
  );






   

   
  function stock(string _index, string _unit, uint256 _amount, string _ipfs) onlyOwner returns (bool) {
    bytes32 _bindex = ConvertStringByte.stringToBytes32(_index);

    require(_amount > 0);
    require(_unit.toSlice().equals(unit.toSlice()));
    require(!(storehouse[_bindex].amount > 0));

    Bullion bullion = storehouse[_bindex];
    bullion.index = _index;
    bullion.unit = _unit;
    bullion.amount = _amount;
    bullion.ipfs = _ipfs;

     
    storehouseIndex.push(_bindex);
     
    storehouse[_bindex] = bullion;

     
    total = total.add(_amount);

    Stock(bullion.index, bullion.unit, bullion.amount, bullion.ipfs, total);

    return true;
  }

   
  function ship(string _index) onlyOwner returns (bool) {
    bytes32 _bindex = ConvertStringByte.stringToBytes32(_index);

    require(storehouse[_bindex].amount > 0);
    Bullion bullion = storehouse[_bindex];
    require(total.sub(bullion.amount) >= 0);

    uint256 tmpAmount = bullion.amount;

    for (uint256 index = 0; index < storehouseIndex.length; index++) {
      Bullion _bullion = storehouse[storehouseIndex[index]];
      if (_bullion.index.toSlice().equals(_index.toSlice())) {
         
        delete storehouseIndex[index];
      }
    }
     
    delete storehouse[_bindex];
     
    total = total.sub(tmpAmount);

    Ship(bullion.index, total);

    return true;
  }

   
  function mint(uint256 _ptAmount) onlyOwner returns (bool) {
    require(token != 0x0);

    uint256 amount = convert2PlatinumToken(_ptAmount);
     
    bool produced = coin.produce(amount);
    require(produced);

    total = total.sub(_ptAmount);

    Mint(_ptAmount, total);

    return true;
  }

   
  function alchemy(uint256 _tokenAmount) onlyOwner returns (bool) {
    require(token != 0x0);

    uint256 amount = convert2Platinum(_tokenAmount);
    bool reduced = coin.reduce(_tokenAmount);
    require(reduced);

    total = total.add(amount);

    Alchemy(amount, total);

    return true;
  }

   
  function setRate(uint256 _rate) onlyOwner returns (bool) {
    require(_rate > 0);

    rate = _rate;
    return true;
  }

   
  function setTokenAddress(address _address) onlyOwner returns (bool) {
    require(_address != 0x0);

    coin = PlatinumToken(_address);
    token = _address;
    return true;
  }

   
  function buy(string _index, address buyer) onlyOwner returns (bool) {
    require(token != 0x0);
    bytes32 _bindex = ConvertStringByte.stringToBytes32(_index);
    uint256 fee = coin.fee();
    require(storehouse[_bindex].amount > 0);

    Bullion bullion = storehouse[_bindex];
    uint256 tokenPrice = convert2PlatinumToken(bullion.amount);
    uint256 tokenPriceFee = tokenPrice.add(fee);

     
    bool transfered = coin.transferFrom(buyer, coin.owner(), tokenPriceFee);
    require(transfered);

     
    bool reduced = coin.reduce(tokenPrice);
    require(reduced);

     
    for (uint256 index = 0; index < storehouseIndex.length; index++) {
      Bullion _bullion = storehouse[storehouseIndex[index]];
      if (_bullion.index.toSlice().equals(_index.toSlice())) {
         
        delete storehouseIndex[index];
      }
    }
     
    delete storehouse[_bindex];

    Buy(_index, buyer, fee, tokenPrice);

    return true;
  }





   

   
  function convert2Platinum(uint256 _amount) constant returns (uint256) {
    return _amount.div(rate);
  }

   
  function convert2PlatinumToken(uint256 _amount) constant returns (uint256) {
    return _amount.mul(rate);
  }

   
  function info(string _index) constant returns (string, string, uint256, string) {
    bytes32 _bindex = ConvertStringByte.stringToBytes32(_index);
    require(storehouse[_bindex].amount > 0);

    Bullion bullion = storehouse[_bindex];

    return (bullion.index, bullion.unit, bullion.amount, bullion.ipfs);
  }
}


 
library SafeMath {
  function mul(uint256 a, uint256 b) internal constant returns (uint256) {
    uint256 c = a * b;
    assert(a == 0 || c / a == b);
    return c;
  }

  function div(uint256 a, uint256 b) internal constant returns (uint256) {
     
    uint256 c = a / b;
     
    return c;
  }

  function sub(uint256 a, uint256 b) internal constant returns (uint256) {
    assert(b <= a);
    return a - b;
  }

  function add(uint256 a, uint256 b) internal constant returns (uint256) {
    uint256 c = a + b;
    assert(c >= a);
    return c;
  }
}

 
contract ERC20Basic {
  uint256 public totalSupply;
  function balanceOf(address who) constant returns (uint256);
  function transfer(address to, uint256 value) returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
}

 
contract ERC20 is ERC20Basic {
  function allowance(address owner, address spender) constant returns (uint256);
  function transferFrom(address from, address to, uint256 value) returns (bool);
  function approve(address spender, uint256 value) returns (bool);
  event Approval(address indexed owner, address indexed spender, uint256 value);
}


contract PlatinumToken is Ownable, ERC20 {
  using SafeMath for uint256;
   

   
  string public version = "0.0.1";
   
  string public name;
   
  string public symbol;
   
  uint256 public decimals;
   
  address public platinum;

  mapping (address => mapping (address => uint256)) allowed;
  mapping(address => uint256) balances;
   
  uint256 public totalSupply;
   
  uint256 public fee = 10;

   
  function PlatinumToken(
    uint256 initialSupply,
    string tokenName,
    uint8 decimalUnits,
    string tokenSymbol
    ) {
    balances[msg.sender] = initialSupply;
    totalSupply = initialSupply;
    name = tokenName;
    symbol = tokenSymbol;
    decimals = decimalUnits;
  }

   
  modifier isPlatinumContract() {
    require(platinum != 0x0);
    require(msg.sender == platinum);
    _;
  }

  modifier isOwnerOrPlatinumContract() {
    require(msg.sender != address(0) && (msg.sender == platinum || msg.sender == owner));
    _;
  }

   
  function produce(uint256 amount) isPlatinumContract returns (bool) {
    balances[owner] = balances[owner].add(amount);
    totalSupply = totalSupply.add(amount);

    return true;
  }

   
  function reduce(uint256 amount) isPlatinumContract returns (bool) {
    require(balances[owner].sub(amount) >= 0);
    require(totalSupply.sub(amount) >= 0);

    balances[owner] = balances[owner].sub(amount);
    totalSupply = totalSupply.sub(amount);

    return true;
  }

   
  function setPlatinumAddress(address _address) onlyOwner returns (bool) {
    require(_address != 0x0);

    platinum = _address;
    return true;
  }

   
  function setFee(uint256 _fee) onlyOwner returns (bool) {
    require(_fee >= 0);

    fee = _fee;
    return true;
  }

   
  function transfer(address _to, uint256 _value) onlyOwner returns (bool) {
    balances[owner] = balances[owner].sub(_value);
    balances[_to] = balances[_to].add(_value);

    Transfer(owner, _to, _value);

    return true;
  }

   
  function balanceOf(address _owner) constant returns (uint256 balance) {
    return balances[_owner];
  }

   
  function transferFrom(address _from, address _to, uint256 _value) isOwnerOrPlatinumContract returns (bool) {
    var _allowance = allowed[_from][owner];

    uint256 valueSubFee = _value.sub(fee);

    balances[_to] = balances[_to].add(valueSubFee);
    balances[_from] = balances[_from].sub(_value);
    balances[owner] = balances[owner].add(fee);
    allowed[_from][owner] = _allowance.sub(_value);

    Transfer(_from, _to, _value);

    return true;
  }

   
  function approve(address _dummy, uint256 _value) returns (bool) {
     
     
     
     
    require((_value == 0) || (allowed[msg.sender][owner] == 0));

    allowed[msg.sender][owner] = _value;
    Approval(msg.sender, owner, _value);
    return true;
  }

   
  function allowance(address _owner, address _spender) constant returns (uint256 remaining) {
    return allowed[_owner][_spender];
  }

   
  function suicide() onlyOwner returns (bool) {
    selfdestruct(owner);
    return true;
  }
}