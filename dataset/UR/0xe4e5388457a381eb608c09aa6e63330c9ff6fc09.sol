 

pragma solidity ^0.4.8;

 

 
 
pragma solidity ^0.4.14;

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

     
    function toSlice(string self) internal pure returns (slice) {
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

     
    function toSliceB32(bytes32 self) internal pure returns (slice ret) {
         
        assembly {
            let ptr := mload(0x40)
            mstore(0x40, add(ptr, 0x20))
            mstore(ptr, self)
            mstore(add(ret, 0x20), ptr)
        }
        ret._len = len(self);
    }

     
    function copy(slice self) internal pure returns (slice) {
        return slice(self._len, self._ptr);
    }

     
    function toString(slice self) internal pure returns (string) {
        string memory ret = new string(self._len);
        uint retptr;
        assembly { retptr := add(ret, 32) }

        memcpy(retptr, self._ptr, self._len);
        return ret;
    }

     
    function len(slice self) internal pure returns (uint l) {
         
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

     
    function empty(slice self) internal pure returns (bool) {
        return self._len == 0;
    }

     
    function compare(slice self, slice other) internal pure returns (int) {
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
                 
                uint256 mask = ~(2 ** (8 * (32 - shortest + idx)) - 1);
                uint256 diff = (a & mask) - (b & mask);
                if (diff != 0)
                    return int(diff);
            }
            selfptr += 32;
            otherptr += 32;
        }
        return int(self._len) - int(other._len);
    }

     
    function equals(slice self, slice other) internal pure returns (bool) {
        return compare(self, other) == 0;
    }

     
    function nextRune(slice self, slice rune) internal pure returns (slice) {
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

     
    function nextRune(slice self) internal pure returns (slice ret) {
        nextRune(self, ret);
    }

     
    function ord(slice self) internal pure returns (uint ret) {
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

     
    function keccak(slice self) internal pure returns (bytes32 ret) {
        assembly {
            ret := keccak256(mload(add(self, 32)), mload(self))
        }
    }

     
    function startsWith(slice self, slice needle) internal pure returns (bool) {
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

     
    function beyond(slice self, slice needle) internal pure returns (slice) {
        if (self._len < needle._len) {
            return self;
        }

        bool equal = true;
        if (self._ptr != needle._ptr) {
            assembly {
                let length := mload(needle)
                let selfptr := mload(add(self, 0x20))
                let needleptr := mload(add(needle, 0x20))
                equal := eq(sha3(selfptr, length), sha3(needleptr, length))
            }
        }

        if (equal) {
            self._len -= needle._len;
            self._ptr += needle._len;
        }

        return self;
    }

     
    function endsWith(slice self, slice needle) internal pure returns (bool) {
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

     
    function until(slice self, slice needle) internal pure returns (slice) {
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

    event log_bytemask(bytes32 mask);

     
     
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
                assembly { hash := sha3(needleptr, needlelen) }

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

     
    function find(slice self, slice needle) internal pure returns (slice) {
        uint ptr = findPtr(self._len, self._ptr, needle._len, needle._ptr);
        self._len -= ptr - self._ptr;
        self._ptr = ptr;
        return self;
    }

     
    function rfind(slice self, slice needle) internal pure returns (slice) {
        uint ptr = rfindPtr(self._len, self._ptr, needle._len, needle._ptr);
        self._len = ptr - self._ptr;
        return self;
    }

     
    function split(slice self, slice needle, slice token) internal pure returns (slice) {
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

     
    function split(slice self, slice needle) internal pure returns (slice token) {
        split(self, needle, token);
    }

     
    function rsplit(slice self, slice needle, slice token) internal pure returns (slice) {
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

     
    function rsplit(slice self, slice needle) internal pure returns (slice token) {
        rsplit(self, needle, token);
    }

     
    function count(slice self, slice needle) internal pure returns (uint cnt) {
        uint ptr = findPtr(self._len, self._ptr, needle._len, needle._ptr) + needle._len;
        while (ptr <= self._ptr + self._len) {
            cnt++;
            ptr = findPtr(self._len - (ptr - self._ptr), ptr, needle._len, needle._ptr) + needle._len;
        }
    }

     
    function contains(slice self, slice needle) internal pure returns (bool) {
        return rfindPtr(self._len, self._ptr, needle._len, needle._ptr) != self._ptr;
    }

     
    function concat(slice self, slice other) internal pure returns (string) {
        string memory ret = new string(self._len + other._len);
        uint retptr;
        assembly { retptr := add(ret, 32) }
        memcpy(retptr, self._ptr, self._len);
        memcpy(retptr + self._len, other._ptr, other._len);
        return ret;
    }

     
    function join(slice self, slice[] parts) internal pure returns (string) {
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

contract CryptoNumismat 
{
    
    using strings for *;
    
    address owner;

    string public standard = 'CryptoNumismat';
    string public name;
    string public symbol;
    uint8 public decimals;
    uint256 public totalSupply;

    struct Buy 
    {
        uint cardIndex;
        address seller;
        uint minValue;   
        uint intName;
        string name;
    }
    
    struct UnitedBuy 
    {
        uint cardIndex;
        address seller;
        uint intName;
        string name;
    }

    mapping (uint => Buy) public cardsForSale;
    mapping (uint => UnitedBuy) public UnitedCardsForSale;
    mapping (address => bool) public admins;
    mapping (address => string) public nicknames;

    event Assign(uint indexed _cardIndex, address indexed _seller, uint256 _value, uint _intName, string _name);
    event Transfer(address indexed _from, address indexed _to, uint _cardIndex, uint256 _value);
    
    function CryptoNumismat() public payable 
    {
        owner = msg.sender;
        admins[owner] = true;
        
        totalSupply = 1000;                          
        name = "cryptonumismat";                     
        symbol = "$";                                
        decimals = 0;                                
    }
    
    modifier onlyOwner() 
    {
        require(msg.sender == owner);
        _;
    }
    
    modifier onlyAdmins() 
    {
        require(admins[msg.sender]);
        _;
    }
    
    function setOwner(address _owner) onlyOwner() public 
    {
        owner = _owner;
    }
    
    function addAdmin(address _admin) onlyOwner() public
    {
        admins[_admin] = true;
    }
    
    function removeAdmin(address _admin) onlyOwner() public
    {
        delete admins[_admin];
    }
    
    function withdrawAll() onlyOwner() public 
    {
        owner.transfer(this.balance);
    }

    function withdrawAmount(uint256 _amount) onlyOwner() public 
    {
        require(_amount <= this.balance);
        
        owner.transfer(_amount);
    }
    
     
     

    function addCard(string _type, uint _intName, string _name, uint _cardIndex, uint256 _value, address _ownAddress) public onlyAdmins()
    {
        require(_cardIndex <= 1000);
        require(_cardIndex > 0);
        
        require(cardsForSale[_cardIndex].cardIndex != _cardIndex);
        require(UnitedCardsForSale[_intName].intName != _intName);
        
        address seller = _ownAddress;
        uint256 _value2 = (_value * 1000000000);
        
        if (strings.equals(_type.toSlice(), "Common".toSlice()))
        {
            cardsForSale[_cardIndex] = Buy(_cardIndex, seller, _value2, _intName, _name);
            Assign(_cardIndex, seller, _value2, _intName, _name);
        }
        else if (strings.equals(_type.toSlice(), "United".toSlice()))
        {
            UnitedCardsForSale[_intName] = UnitedBuy(_cardIndex, seller, _intName, _name);
            cardsForSale[_cardIndex] = Buy(_cardIndex, seller, _value2,  _intName, _name);
            Assign(_cardIndex, seller, _value2, _intName, _name);
        }
    }
    
    function displayCard(uint _cardIndex) public constant returns(uint, address, uint256, uint, string) 
    {
        require(_cardIndex <= 1000);
        require(_cardIndex > 0);
        
        require (cardsForSale[_cardIndex].cardIndex == _cardIndex);
            
        return(cardsForSale[_cardIndex].cardIndex, 
        cardsForSale[_cardIndex].seller,
        cardsForSale[_cardIndex].minValue,
        cardsForSale[_cardIndex].intName,
        cardsForSale[_cardIndex].name);
    }
    
    function setNick(string _newNick) public
    {
        nicknames[msg.sender] = _newNick;      
    }
    
    function displayNick(address _owner) public constant returns(string)
    {
        return nicknames[_owner];
    }
    
    
    uint256 private limit1 = 0.05 ether;
    uint256 private limit2 = 0.5 ether;
    uint256 private limit3 = 5 ether;
    uint256 private limit4 = 50 ether;
    
    function calculateNextPrice(uint256 _startPrice) public constant returns (uint256 _finalPrice)
    {
        if (_startPrice < limit1)
            _startPrice =  _startPrice * 10 / 4;
        else if (_startPrice < limit2)
            _startPrice =  _startPrice * 10 / 5;
        else if (_startPrice < limit3)
            _startPrice =  _startPrice * 10 / 6;
        else if (_startPrice < limit4)
            _startPrice =  _startPrice * 10 / 7;
        else
            _startPrice =  _startPrice * 10 / 8;
            
        return (_startPrice / 1000000) * 1000000;
    }
    
    function calculateDevCut(uint256 _startPrice) public constant returns (uint256 _cut)
    {
        if (_startPrice < limit2)
            _startPrice =  _startPrice * 5 / 100;
        else if (_startPrice < limit3)
            _startPrice =  _startPrice * 4 / 100;
        else if (_startPrice < limit4)
            _startPrice =  _startPrice * 3 / 100;
        else
            _startPrice =  _startPrice * 2 / 100;
            
        return (_startPrice / 1000000) * 1000000;
    }
    
    function buy(uint _cardIndex) public payable
    {
        require(_cardIndex <= 1000);
        require(_cardIndex > 0);
        require(cardsForSale[_cardIndex].cardIndex == _cardIndex);
        require(cardsForSale[_cardIndex].seller != msg.sender);
        require(msg.sender != address(0));
        require(msg.sender != owner);
        require(cardsForSale[_cardIndex].minValue > 0);
        require(msg.value >= cardsForSale[_cardIndex].minValue);
        
        address _buyer = msg.sender;
        address _seller = cardsForSale[_cardIndex].seller;
        string _name = cardsForSale[_cardIndex].name;
        uint _intName = cardsForSale[_cardIndex].intName;
        
        address _UnitedOwner = UnitedCardsForSale[_intName].seller;
        
        uint256 _price = cardsForSale[_cardIndex].minValue;
        
        uint256 _nextPrice = calculateNextPrice(_price);
        uint256 _devCut = calculateDevCut(_price);
        
        uint256 _totalPrice = _price - _devCut - (_devCut / 4);
        uint256 _extra = msg.value - _price;
        
        _seller.transfer(_totalPrice);
        _UnitedOwner.transfer((_devCut / 4));
        
        if (_extra > 0)
        {
            Transfer(_buyer, _buyer, _cardIndex, _extra);
            
            _buyer.transfer(_extra);
        }
        
        cardsForSale[_cardIndex].seller = _buyer;
        cardsForSale[_cardIndex].minValue = _nextPrice;
        
        if (_cardIndex == UnitedCardsForSale[_intName].cardIndex)
            UnitedCardsForSale[_intName].seller = _buyer;
        
        
        Transfer(_buyer, _seller, _cardIndex, _totalPrice);
        Assign(_cardIndex, _buyer, _nextPrice, _intName, _name); 
    }
}