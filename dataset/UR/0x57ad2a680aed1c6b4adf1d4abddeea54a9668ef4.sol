 

pragma solidity 0.4.24;

 
contract ERC20Basic {
  function totalSupply() public view returns (uint256);
  function balanceOf(address who) public view returns (uint256);
  function transfer(address to, uint256 value) public returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
}

 
contract BasicToken is ERC20Basic {
  using SafeMath for uint256;

  mapping(address => uint256) balances;

  uint256 totalSupply_;

   
  function totalSupply() public view returns (uint256) {
    return totalSupply_;
  }

   
  function transfer(address _to, uint256 _value) public returns (bool) {
    require(_to != address(0));
    require(_value <= balances[msg.sender]);

    balances[msg.sender] = balances[msg.sender].sub(_value);
    balances[_to] = balances[_to].add(_value);
    emit Transfer(msg.sender, _to, _value);
    return true;
  }

   
  function balanceOf(address _owner) public view returns (uint256) {
    return balances[_owner];
  }

}


 
contract ERC20 is ERC20Basic {
  function allowance(address owner, address spender)
    public view returns (uint256);

  function transferFrom(address from, address to, uint256 value)
    public returns (bool);

  function approve(address spender, uint256 value) public returns (bool);
  event Approval(
    address indexed owner,
    address indexed spender,
    uint256 value
  );
}


 
contract StandardToken is ERC20, BasicToken {

  mapping (address => mapping (address => uint256)) internal allowed;


   
  function transferFrom(
    address _from,
    address _to,
    uint256 _value
  )
    public
    returns (bool)
  {
    require(_to != address(0));
    require(_value <= balances[_from]);
    require(_value <= allowed[_from][msg.sender]);

    balances[_from] = balances[_from].sub(_value);
    balances[_to] = balances[_to].add(_value);
    allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
    emit Transfer(_from, _to, _value);
    return true;
  }

   
  function approve(address _spender, uint256 _value) public returns (bool) {
    allowed[msg.sender][_spender] = _value;
    emit Approval(msg.sender, _spender, _value);
    return true;
  }

   
  function allowance(
    address _owner,
    address _spender
   )
    public
    view
    returns (uint256)
  {
    return allowed[_owner][_spender];
  }

   
  function increaseApproval(
    address _spender,
    uint256 _addedValue
  )
    public
    returns (bool)
  {
    allowed[msg.sender][_spender] = (
      allowed[msg.sender][_spender].add(_addedValue));
    emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
    return true;
  }

   
  function decreaseApproval(
    address _spender,
    uint256 _subtractedValue
  )
    public
    returns (bool)
  {
    uint256 oldValue = allowed[msg.sender][_spender];
    if (_subtractedValue > oldValue) {
      allowed[msg.sender][_spender] = 0;
    } else {
      allowed[msg.sender][_spender] = oldValue.sub(_subtractedValue);
    }
    emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
    return true;
  }

}


 
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


 
library SafeMath {

   
  function mul(uint256 a, uint256 b) internal pure returns (uint256 c) {
     
     
     
    if (a == 0) {
      return 0;
    }

    c = a * b;
    assert(c / a == b);
    return c;
  }

   
  function div(uint256 a, uint256 b) internal pure returns (uint256) {
     
     
     
    return a / b;
  }

   
  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    assert(b <= a);
    return a - b;
  }

   
  function add(uint256 a, uint256 b) internal pure returns (uint256 c) {
    c = a + b;
    assert(c >= a);
    return c;
  }
}


pragma solidity 0.4.24;

contract SparksterToken is StandardToken, Ownable{
	using strings for *;
	using SafeMath for uint256;
	struct Member {
		address walletAddress;
		mapping(uint256 => bool) groupMemberships;  
		mapping(uint256 => uint256) ethBalance;  
		mapping(uint256 => uint256) tokenBalance;  
		uint256 max1;  
		int256 transferred;  
		bool exists;  
	}

	struct Group {
		bool distributed;  
		bool distributing;  
		bool unlocked;  
		uint256 groupNumber;  
		uint256 ratio;  
		uint256 startTime;  
		uint256 phase1endTime;  
		uint256 phase2endTime;  
		uint256 deadline;  
		uint256 max2;  
		uint256 max3;  
		uint256 ethTotal;  
		uint256 cap;  
		uint256 howManyDistributed;
	}

	bool internal transferLock = true;  
	bool internal allowedToSell = false;
	bool internal allowedToPurchase = false;
	string public name;									  
	string public symbol;								  
	uint8 public decimals;							 
	uint256 internal maxGasPrice;  
	uint256 internal nextGroupNumber;
	uint256 public sellPrice;  
	address[] internal allMembers;	
	address[] internal allNonMembers;
	mapping(address => bool) internal nonMemberTransfers;
	mapping(address => Member) internal members;
	mapping(uint256 => Group) internal groups;
	mapping(uint256 => address[]) internal associations;  
	uint256 internal openGroupNumber;
	event PurchaseSuccess(address indexed _addr, uint256 _weiAmount,uint256 _totalEthBalance,uint256 _totalTokenBalance);
	event DistributeDone(uint256 groupNumber);
	event UnlockDone(uint256 groupNumber);
	event GroupCreated(uint256 groupNumber, uint256 startTime, uint256 phase1endTime, uint256 phase2endTime, uint256 deadline, uint256 phase2cap, uint256 phase3cap, uint256 cap, uint256 ratio);
	event ChangedAllowedToSell(bool allowedToSell);
	event ChangedAllowedToPurchase(bool allowedToPurchase);
	event ChangedTransferLock(bool transferLock);
	event SetSellPrice(uint256 sellPrice);
	event Added(address walletAddress, uint256 group, uint256 tokens, uint256 maxContribution1);
	event SplitTokens(uint256 splitFactor);
	event ReverseSplitTokens(uint256 splitFactor);
	
	 
	modifier onlyPayloadSize(uint size) {	 
		require(msg.data.length == size + 4);
		_;
	}

	modifier canTransfer() {
		require(!transferLock);
		_;
	}

	modifier canPurchase() {
		require(allowedToPurchase);
		_;
	}

	modifier canSell() {
		require(allowedToSell);
		_;
	}

	function() public payable {
		purchase();
	}

	constructor() public {
		name = "Sparkster";									 
		decimals = 18;					  
		symbol = "SPRK";							 
		setMaximumGasPrice(40);
		 
		mintTokens(435000000);
	}
	
	function setMaximumGasPrice(uint256 gweiPrice) public onlyOwner returns(bool success) {
		maxGasPrice = gweiPrice.mul(10**9);  
		return true;
	}
	
	function parseAddr(string _a) pure internal returns (address){  
		bytes memory tmp = bytes(_a);
		uint160 iaddr = 0;
		uint160 b1;
		uint160 b2;
		for (uint i=2; i<2+2*20; i+=2){
			iaddr *= 256;
			b1 = uint160(tmp[i]);
			b2 = uint160(tmp[i+1]);
			if ((b1 >= 97)&&(b1 <= 102)) b1 -= 87;
			else if ((b1 >= 48)&&(b1 <= 57)) b1 -= 48;
			if ((b2 >= 97)&&(b2 <= 102)) b2 -= 87;
			else if ((b2 >= 48)&&(b2 <= 57)) b2 -= 48;
			iaddr += (b1*16+b2);
		}
		return address(iaddr);
	}

	function parseInt(string _a, uint _b) pure internal returns (uint) {
		bytes memory bresult = bytes(_a);
		uint mint = 0;
		bool decim = false;
		for (uint i = 0; i < bresult.length; i++) {
			if ((bresult[i] >= 48) && (bresult[i] <= 57)) {
				if (decim) {
					if (_b == 0) break;
						else _b--;
				}
				mint *= 10;
				mint += uint(bresult[i]) - 48;
			} else if (bresult[i] == 46) decim = true;
		}
		return mint;
	}

	function mintTokens(uint256 amount) public onlyOwner {
		 
		uint256 decimalAmount = amount.mul(uint(10)**decimals);
		totalSupply_ = totalSupply_.add(decimalAmount);
		balances[msg.sender] = balances[msg.sender].add(decimalAmount);
		emit Transfer(address(0), msg.sender, decimalAmount);  
	}
	
	function purchase() public canPurchase payable{
		require(msg.sender != address(0));  
		Member storage memberRecord = members[msg.sender];
		Group storage openGroup = groups[openGroupNumber];
		require(openGroup.ratio > 0);  
		require(memberRecord.exists && memberRecord.groupMemberships[openGroup.groupNumber] && !openGroup.distributing && !openGroup.distributed && !openGroup.unlocked);  
		uint256 currentTimestamp = block.timestamp;
		require(currentTimestamp >= openGroup.startTime && currentTimestamp <= openGroup.deadline);																  
		require(tx.gasprice <= maxGasPrice);  
		uint256 weiAmount = msg.value;																		 
		require(weiAmount >= 0.1 ether);
		uint256 ethTotal = openGroup.ethTotal.add(weiAmount);  
		require(ethTotal <= openGroup.cap);														 
		uint256 userETHTotal = memberRecord.ethBalance[openGroup.groupNumber].add(weiAmount);	 
		if(currentTimestamp <= openGroup.phase1endTime){																			  
			require(userETHTotal <= memberRecord.max1);														  
		} else if (currentTimestamp <= openGroup.phase2endTime) {  
			require(userETHTotal <= openGroup.max2);  
		} else {  
			require(userETHTotal <= openGroup.max3);  
		}
		uint256 tokenAmount = weiAmount.mul(openGroup.ratio);						  
		uint256 newLeftOver = balances[owner].sub(tokenAmount);  
		openGroup.ethTotal = ethTotal;								  
		memberRecord.ethBalance[openGroup.groupNumber] = userETHTotal;														  
		memberRecord.tokenBalance[openGroup.groupNumber] = memberRecord.tokenBalance[openGroup.groupNumber].add(tokenAmount);  
		balances[owner] = newLeftOver;  
		owner.transfer(weiAmount);  
		emit PurchaseSuccess(msg.sender,weiAmount,memberRecord.ethBalance[openGroup.groupNumber],memberRecord.tokenBalance[openGroup.groupNumber]); 
	}
	
	function sell(uint256 amount) public canSell {  
		uint256 decimalAmount = amount.mul(uint(10)**decimals);  
		if (members[msg.sender].exists) {  
			int256 sellValue = members[msg.sender].transferred + int(decimalAmount);
			require(sellValue >= members[msg.sender].transferred);  
			require(sellValue <= int(getUnlockedBalanceLimit(msg.sender)));  
			members[msg.sender].transferred = sellValue;
		}
		balances[msg.sender] = balances[msg.sender].sub(decimalAmount);  
		 
		uint256 totalCost = amount.mul(sellPrice);  
		require(address(this).balance >= totalCost);  
		balances[owner] = balances[owner].add(decimalAmount);  
		msg.sender.transfer(totalCost);  
		emit Transfer(msg.sender, owner, decimalAmount);  
	}

	function fundContract() public onlyOwner payable {  
	}

	function setSellPrice(uint256 thePrice) public onlyOwner {
		sellPrice = thePrice;
		emit SetSellPrice(sellPrice);
	}
	
	function setAllowedToSell(bool value) public onlyOwner {
		allowedToSell = value;
		emit ChangedAllowedToSell(allowedToSell);
	}

	function setAllowedToPurchase(bool value) public onlyOwner {
		allowedToPurchase = value;
		emit ChangedAllowedToPurchase(allowedToPurchase);
	}
	
	function createGroup(uint256 startEpoch, uint256 phase1endEpoch, uint256 phase2endEpoch, uint256 deadlineEpoch, uint256 phase2cap, uint256 phase3cap, uint256 etherCap, uint256 ratio) public onlyOwner returns (bool success, uint256 createdGroupNumber) {
		Group storage theGroup = groups[nextGroupNumber];
		theGroup.groupNumber = nextGroupNumber;
		theGroup.startTime = startEpoch;
		theGroup.phase1endTime = phase1endEpoch;
		theGroup.phase2endTime = phase2endEpoch;
		theGroup.deadline = deadlineEpoch;
		theGroup.max2 = phase2cap;
		theGroup.max3 = phase3cap;
		theGroup.cap = etherCap;
		theGroup.ratio = ratio;
		createdGroupNumber = nextGroupNumber;
		nextGroupNumber++;
		success = true;
		emit GroupCreated(createdGroupNumber, startEpoch, phase1endEpoch, phase2endEpoch, deadlineEpoch, phase2cap, phase3cap, etherCap, ratio);
	}

	function createGroup() public onlyOwner returns (bool success, uint256 createdGroupNumber) {
		return createGroup(0, 0, 0, 0, 0, 0, 0, 0);
	}

	function getGroup(uint256 groupNumber) public view onlyOwner returns(bool distributed, bool unlocked, uint256 phase2cap, uint256 phase3cap, uint256 cap, uint256 ratio, uint256 startTime, uint256 phase1endTime, uint256 phase2endTime, uint256 deadline, uint256 ethTotal, uint256 howManyDistributed) {
		require(groupNumber < nextGroupNumber);
		Group storage theGroup = groups[groupNumber];
		distributed = theGroup.distributed;
		unlocked = theGroup.unlocked;
		phase2cap = theGroup.max2;
		phase3cap = theGroup.max3;
		cap = theGroup.cap;
		ratio = theGroup.ratio;
		startTime = theGroup.startTime;
		phase1endTime = theGroup.phase1endTime;
		phase2endTime = theGroup.phase2endTime;
		deadline = theGroup.deadline;
		ethTotal = theGroup.ethTotal;
		howManyDistributed = theGroup.howManyDistributed;
	}

	function getHowManyLeftToDistribute(uint256 groupNumber) public view returns(uint256 howManyLeftToDistribute) {
		require(groupNumber < nextGroupNumber);
		Group storage theGroup = groups[groupNumber];
		howManyLeftToDistribute = associations[groupNumber].length - theGroup.howManyDistributed;  
	}
	
	function getMembersInGroup(uint256 groupNumber) public view returns (address[]) {
		require(groupNumber < nextGroupNumber);  
		return associations[groupNumber];
	}

	function addMember(address walletAddress, uint256 groupNumber, uint256 tokens, uint256 maxContribution1) public onlyOwner returns (bool success) {
		Member storage theMember = members[walletAddress];
		Group storage theGroup = groups[groupNumber];
		require(groupNumber < nextGroupNumber);  
		require(!theGroup.distributed && !theGroup.distributing && !theGroup.unlocked);  
		require(!theMember.exists);  
		theMember.walletAddress = walletAddress;
		theMember.groupMemberships[groupNumber] = true;
		balances[owner] = balances[owner].sub(tokens);
		theMember.tokenBalance[groupNumber] = tokens;
		theMember.max1 = maxContribution1;
		theMember.transferred = -int(balances[walletAddress]);  
		theMember.exists = true;
		associations[groupNumber].push(walletAddress);  
		 
		allMembers.push(walletAddress);  
		 
		emit Added(walletAddress, groupNumber, tokens, maxContribution1);
		return true;
	}

	function addMemberToGroup(address walletAddress, uint256 groupNumber) public onlyOwner returns(bool success) {
		Member storage memberRecord = members[walletAddress];
		require(memberRecord.exists && groupNumber < nextGroupNumber && !memberRecord.groupMemberships[groupNumber]);  
		memberRecord.groupMemberships[groupNumber] = true;
		associations[groupNumber].push(walletAddress);
		return true;
	}
	function upload(string uploadedData) public onlyOwner returns (bool success) {
		 
		strings.slice memory uploadedSlice = uploadedData.toSlice();
		strings.slice memory nextRecord = "".toSlice();
		strings.slice memory nextDatum = "".toSlice();
		strings.slice memory recordSeparator = "|".toSlice();
		strings.slice memory datumSeparator = ":".toSlice();
		while (!uploadedSlice.empty()) {
			nextRecord = uploadedSlice.split(recordSeparator);
			nextDatum = nextRecord.split(datumSeparator);
			address memberAddress = parseAddr(nextDatum.toString());
			nextDatum = nextRecord.split(datumSeparator);
			uint256 memberGroup = parseInt(nextDatum.toString(), 0);
			nextDatum = nextRecord.split(datumSeparator);
			uint256 memberTokens = parseInt(nextDatum.toString(), 0);
			nextDatum = nextRecord.split(datumSeparator);
			uint256 memberMaxContribution1 = parseInt(nextDatum.toString(), 0);
			addMember(memberAddress, memberGroup, memberTokens, memberMaxContribution1);
		}
		return true;
	}
	
	function distribute(uint256 groupNumber, uint256 howMany) public onlyOwner returns (bool success) {
		Group storage theGroup = groups[groupNumber];
		require(groupNumber < nextGroupNumber && !theGroup.distributed );  
		uint256 inclusiveStartIndex = theGroup.howManyDistributed;
		uint256 exclusiveEndIndex = inclusiveStartIndex.add(howMany);
		theGroup.distributing = true;
		uint256 n = associations[groupNumber].length;
		require(n > 0 );  
		if (exclusiveEndIndex > n) {  
			exclusiveEndIndex = n;
		}
		for (uint256 i = inclusiveStartIndex; i < exclusiveEndIndex; i++) {  
			address memberAddress = associations[groupNumber][i];
			Member storage currentMember = members[memberAddress];
			uint256 balance = currentMember.tokenBalance[groupNumber];
			if (balance > 0) {  
				balances[memberAddress] = balances[memberAddress].add(balance);
				emit Transfer(owner, memberAddress, balance);  
			}
			theGroup.howManyDistributed++;
		}
		if (theGroup.howManyDistributed == n) {  
			theGroup.distributed = true;
			theGroup.distributing = false;
			emit DistributeDone(groupNumber);
		}
		return true;
	}

	function getUnlockedBalanceLimit(address walletAddress) internal view returns(uint256 balance) {
		Member storage theMember = members[walletAddress];
		if (!theMember.exists) {
			return balances[walletAddress];
		}
		for (uint256 i = 0; i < nextGroupNumber; i++) {
			if (groups[i].unlocked) {
				balance = balance.add(theMember.tokenBalance[i]);
			}
		}
		return balance;
	}

	function getUnlockedTokens(address walletAddress) public view returns(uint256 balance) {
		Member storage theMember = members[walletAddress];
		if (!theMember.exists) {
			return balances[walletAddress];
		}
		return uint256(int(getUnlockedBalanceLimit(walletAddress)) - theMember.transferred);
	}

	function unlock(uint256 groupNumber) public onlyOwner returns (bool success) {
		Group storage theGroup = groups[groupNumber];
		require(theGroup.distributed && !theGroup.unlocked);  
		theGroup.unlocked = true;
		emit UnlockDone(groupNumber);
		return true;
	}
	
	function setTransferLock(bool value) public onlyOwner {
		transferLock = value;
		emit ChangedTransferLock(transferLock);
	}
	
	function burn(uint256 amount) public onlyOwner {
		 
		 
		balances[msg.sender] = balances[msg.sender].sub(amount);  
		totalSupply_ = totalSupply_.sub(amount);  
		emit Transfer(msg.sender, address(0), amount);
	}
	
	function splitTokensBeforeDistribution(uint256 splitFactor) public onlyOwner returns (bool success) {
		 
		uint256 n = allMembers.length;
		uint256 ownerBalance = balances[msg.sender];
		uint256 increaseSupplyBy = ownerBalance.mul(splitFactor).sub(ownerBalance);  
		balances[msg.sender] = balances[msg.sender].mul(splitFactor);
		totalSupply_ = totalSupply_.mul(splitFactor);
		emit Transfer(address(0), msg.sender, increaseSupplyBy);  
		for (uint256 i = 0; i < n; i++) {
			Member storage currentMember = members[allMembers[i]];
			 
			currentMember.transferred = currentMember.transferred * int(splitFactor);
			 
			for (uint256 j = 0; j < nextGroupNumber; j++) {
				uint256 memberBalance = currentMember.tokenBalance[j];
				uint256 multiplier = memberBalance.mul(splitFactor);
				currentMember.tokenBalance[j] = multiplier;
			}
		}
		 
		n = nextGroupNumber;
		require(n > 0);  
		for (i = 0; i < n; i++) {
			Group storage currentGroup = groups[i];
			currentGroup.ratio = currentGroup.ratio.mul(splitFactor);
		}
		emit SplitTokens(splitFactor);
		return true;
	}
	
	function reverseSplitTokensBeforeDistribution(uint256 splitFactor) public onlyOwner returns (bool success) {
		 
		uint256 n = allMembers.length;
		uint256 ownerBalance = balances[msg.sender];
		uint256 decreaseSupplyBy = ownerBalance.sub(ownerBalance.div(splitFactor));
		 
		totalSupply_ = totalSupply_.div(splitFactor);
		balances[msg.sender] = ownerBalance.div(splitFactor);
		 
		emit Transfer(msg.sender, address(0), decreaseSupplyBy);
		for (uint256 i = 0; i < n; i++) {
			Member storage currentMember = members[allMembers[i]];
			 
			currentMember.transferred = currentMember.transferred / int(splitFactor);
			for (uint256 j = 0; j < nextGroupNumber; j++) {
				uint256 memberBalance = currentMember.tokenBalance[j];
				uint256 divier = memberBalance.div(splitFactor);
				currentMember.tokenBalance[j] = divier;
			}
		}
		 
		n = nextGroupNumber;
		require(n > 0);  
		for (i = 0; i < n; i++) {
			Group storage currentGroup = groups[i];
			currentGroup.ratio = currentGroup.ratio.div(splitFactor);
		}
		emit ReverseSplitTokens(splitFactor);
		return true;
	}

	function splitTokensAfterDistribution(uint256 splitFactor) public onlyOwner returns (bool success) {
		splitTokensBeforeDistribution(splitFactor);
		uint256 n = allMembers.length;
		for (uint256 i = 0; i < n; i++) {
			address currentMember = allMembers[i];
			uint256 memberBalance = balances[currentMember];
			if (memberBalance > 0) {
				uint256 multiplier1 = memberBalance.mul(splitFactor);
				uint256 increaseMemberSupplyBy = multiplier1.sub(memberBalance);
				balances[currentMember] = multiplier1;
				emit Transfer(address(0), currentMember, increaseMemberSupplyBy);
			}
		}
		n = allNonMembers.length;
		for (i = 0; i < n; i++) {
			address currentNonMember = allNonMembers[i];
			 
			if (members[currentNonMember].exists) {
				continue;
			}
			uint256 nonMemberBalance = balances[currentNonMember];
			if (nonMemberBalance > 0) {
				uint256 multiplier2 = nonMemberBalance.mul(splitFactor);
				uint256 increaseNonMemberSupplyBy = multiplier2.sub(nonMemberBalance);
				balances[currentNonMember] = multiplier2;
				emit Transfer(address(0), currentNonMember, increaseNonMemberSupplyBy);
			}
		}
		emit SplitTokens(splitFactor);
		return true;
	}

	function reverseSplitTokensAfterDistribution(uint256 splitFactor) public onlyOwner returns (bool success) {
		reverseSplitTokensBeforeDistribution(splitFactor);
		uint256 n = allMembers.length;
		for (uint256 i = 0; i < n; i++) {
			address currentMember = allMembers[i];
			uint256 memberBalance = balances[currentMember];
			if (memberBalance > 0) {
				uint256 divier1 = memberBalance.div(splitFactor);
				uint256 decreaseMemberSupplyBy = memberBalance.sub(divier1);
				balances[currentMember] = divier1;
				emit Transfer(currentMember, address(0), decreaseMemberSupplyBy);
			}
		}
		n = allNonMembers.length;
		for (i = 0; i < n; i++) {
			address currentNonMember = allNonMembers[i];
			 
			if (members[currentNonMember].exists) {
				continue;
			}
			uint256 nonMemberBalance = balances[currentNonMember];
			if (nonMemberBalance > 0) {
				uint256 divier2 = nonMemberBalance.div(splitFactor);
				uint256 decreaseNonMemberSupplyBy = nonMemberBalance.sub(divier2);
				balances[currentNonMember] = divier2;
				emit Transfer(currentNonMember, address(0), decreaseNonMemberSupplyBy);
			}
		}
		emit ReverseSplitTokens(splitFactor);
		return true;
	}

	function changeMaxContribution(address memberAddress, uint256 newMax1) public onlyOwner {
		 
		Member storage theMember = members[memberAddress];
		require(theMember.exists);  
		theMember.max1 = newMax1;
	}
	
	function transfer(address _to, uint256 _value) public onlyPayloadSize(2 * 32) canTransfer returns (bool success) {		
		 
		Member storage fromMember = members[msg.sender];
		if (fromMember.exists) {  
			int256 transferValue = fromMember.transferred + int(_value);
			require(transferValue >= fromMember.transferred);  
			require(transferValue <= int(getUnlockedBalanceLimit(msg.sender)));  
			fromMember.transferred = transferValue;
		}
		 
		 
		if (!fromMember.exists && msg.sender != owner) {
			bool fromTransferee = nonMemberTransfers[msg.sender];
			if (!fromTransferee) {  
				nonMemberTransfers[msg.sender] = true;
				allNonMembers.push(msg.sender);
			}
		}
		if (!members[_to].exists && _to != owner) {
			bool toTransferee = nonMemberTransfers[_to];
			if (!toTransferee) {  
				nonMemberTransfers[_to] = true;
				allNonMembers.push(_to);
			}
		} else if (members[_to].exists) {  
			int256 transferInValue = members[_to].transferred - int(_value);
			require(transferInValue <= members[_to].transferred);  
			members[_to].transferred = transferInValue;
		}
		return super.transfer(_to, _value);
	}

	function transferFrom(address _from, address _to, uint256 _value) public onlyPayloadSize(3 * 32) canTransfer returns (bool success) {
		 
		Member storage fromMember = members[_from];
		if (fromMember.exists) {  
			int256 transferValue = fromMember.transferred + int(_value);
			require(transferValue >= fromMember.transferred);  
			require(transferValue <= int(getUnlockedBalanceLimit(msg.sender)));  
			fromMember.transferred = transferValue;
		}
		 
		 
		if (!fromMember.exists && _from != owner) {
			bool fromTransferee = nonMemberTransfers[_from];
			if (!fromTransferee) {  
				nonMemberTransfers[_from] = true;
				allNonMembers.push(_from);
			}
		}
		if (!members[_to].exists && _to != owner) {
			bool toTransferee = nonMemberTransfers[_to];
			if (!toTransferee) {  
				nonMemberTransfers[_to] = true;
				allNonMembers.push(_to);
			}
		} else if (members[_to].exists) {  
			int256 transferInValue = members[_to].transferred - int(_value);
			require(transferInValue <= members[_to].transferred);  
			members[_to].transferred = transferInValue;
		}
		return super.transferFrom(_from, _to, _value);
	}

	function setOpenGroup(uint256 groupNumber) public onlyOwner returns (bool success) {
		require(groupNumber < nextGroupNumber);
		openGroupNumber = groupNumber;
		return true;
	}

	function getUndistributedBalanceOf(address walletAddress, uint256 groupNumber) public view returns (uint256 balance) {
		Member storage theMember = members[walletAddress];
		require(theMember.exists);
		if (groups[groupNumber].distributed)  
			return 0;
		return theMember.tokenBalance[groupNumber];
	}

	function checkMyUndistributedBalance(uint256 groupNumber) public view returns (uint256 balance) {
		return getUndistributedBalanceOf(msg.sender, groupNumber);
	}

	function transferRecovery(address _from, address _to, uint256 _value) public onlyOwner returns (bool success) {
		 
		allowed[_from][msg.sender] = allowed[_from][msg.sender].add(_value);  
		Member storage fromMember = members[_from];
		if (fromMember.exists) {
			int256 oldTransferred = fromMember.transferred;
			fromMember.transferred -= int(_value);  
			require(oldTransferred >= fromMember.transferred);  
		}
		return transferFrom(_from, _to, _value);
	}
}