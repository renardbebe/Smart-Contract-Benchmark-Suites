 

pragma solidity ^0.4.21;


library strings {
    
    struct slice {
        uint _len;
        uint _ptr;
    }

     
    function toSlice(string self) internal pure returns (slice) {
        uint ptr;
        assembly {
            ptr := add(self, 0x20)
        }
        return slice(bytes(self).length, ptr);
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

    
    function concat(slice self, slice other) internal returns (string) {
        var ret = new string(self._len + other._len);
        uint retptr;
        assembly { retptr := add(ret, 32) }
        memcpy(retptr, self._ptr, self._len);
        memcpy(retptr + self._len, other._ptr, other._len);
        return ret;
    }

     
    function count(slice self, slice needle) internal returns (uint cnt) {
        uint ptr = findPtr(self._len, self._ptr, needle._len, needle._ptr) + needle._len;
        while (ptr <= self._ptr + self._len) {
            cnt++;
            ptr = findPtr(self._len - (ptr - self._ptr), ptr, needle._len, needle._ptr) + needle._len;
        }
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

     
    function toString(slice self) internal pure returns (string) {
        var ret = new string(self._len);
        uint retptr;
        assembly { retptr := add(ret, 32) }

        memcpy(retptr, self._ptr, self._len);
        return ret;
    }

}

 
contract StringHelpers {
    using strings for *;
    
    function stringToBytes32(string memory source) internal returns (bytes32 result) {
        bytes memory tempEmptyStringTest = bytes(source);
        if (tempEmptyStringTest.length == 0) {
            return 0x0;
        }
    
        assembly {
            result := mload(add(source, 32))
        }
    }

    function bytes32ToString(bytes32 x) constant internal returns (string) {
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
}


 
contract OperationalControl {
     
     
     
     
     

     
    event ContractUpgrade(address newContract);

     
    address public managerPrimary;
    address public managerSecondary;
    address public bankManager;

     
    mapping(address => uint8) public otherManagers;

     
    bool public paused = false;

     
    bool public error = false;

     
    modifier onlyManager() {
        require(msg.sender == managerPrimary || msg.sender == managerSecondary);
        _;
    }

    modifier onlyBanker() {
        require(msg.sender == bankManager);
        _;
    }

    modifier onlyOtherManagers() {
        require(otherManagers[msg.sender] == 1);
        _;
    }


    modifier anyOperator() {
        require(
            msg.sender == managerPrimary ||
            msg.sender == managerSecondary ||
            msg.sender == bankManager ||
            otherManagers[msg.sender] == 1
        );
        _;
    }

     
    function setOtherManager(address _newOp, uint8 _state) external onlyManager {
        require(_newOp != address(0));

        otherManagers[_newOp] = _state;
    }

     
    function setPrimaryManager(address _newGM) external onlyManager {
        require(_newGM != address(0));

        managerPrimary = _newGM;
    }

     
    function setSecondaryManager(address _newGM) external onlyManager {
        require(_newGM != address(0));

        managerSecondary = _newGM;
    }

     
    function setBanker(address _newBK) external onlyManager {
        require(_newBK != address(0));

        bankManager = _newBK;
    }

     

     
    modifier whenNotPaused() {
        require(!paused);
        _;
    }

     
    modifier whenPaused {
        require(paused);
        _;
    }

     
    modifier whenError {
        require(error);
        _;
    }

     
     
    function pause() external onlyManager whenNotPaused {
        paused = true;
    }

     
     
    function unpause() public onlyManager whenPaused {
         
        paused = false;
    }

     
     
    function hasError() public onlyManager whenPaused {
        error = true;
    }

     
     
    function noError() public onlyManager whenPaused {
        error = false;
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
  function allowance(address owner, address spender) public view returns (uint256);
  function transferFrom(address from, address to, uint256 value) public returns (bool);
  function approve(address spender, uint256 value) public returns (bool);
  event Approval(address indexed owner, address indexed spender, uint256 value);
}


 
contract ERC827 is ERC20 {
  function approveAndCall( address _spender, uint256 _value, bytes _data) public payable returns (bool);
  function transferAndCall( address _to, uint256 _value, bytes _data) public payable returns (bool);
  function transferFromAndCall(
    address _from,
    address _to,
    uint256 _value,
    bytes _data
  )
    public
    payable
    returns (bool);
}

 
contract StandardToken is ERC20, BasicToken {

  mapping (address => mapping (address => uint256)) internal allowed;


   
  function transferFrom(address _from, address _to, uint256 _value) public returns (bool) {
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

   
  function allowance(address _owner, address _spender) public view returns (uint256) {
    return allowed[_owner][_spender];
  }

   
  function increaseApproval(address _spender, uint _addedValue) public returns (bool) {
    allowed[msg.sender][_spender] = allowed[msg.sender][_spender].add(_addedValue);
    emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
    return true;
  }

   
  function decreaseApproval(address _spender, uint _subtractedValue) public returns (bool) {
    uint oldValue = allowed[msg.sender][_spender];
    if (_subtractedValue > oldValue) {
      allowed[msg.sender][_spender] = 0;
    } else {
      allowed[msg.sender][_spender] = oldValue.sub(_subtractedValue);
    }
    emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
    return true;
  }

}


 
 
contract ERC827Token is ERC827, StandardToken {

   
  function approveAndCall(address _spender, uint256 _value, bytes _data) public payable returns (bool) {
    require(_spender != address(this));

    super.approve(_spender, _value);

     
    require(_spender.call.value(msg.value)(_data));

    return true;
  }

   
  function transferAndCall(address _to, uint256 _value, bytes _data) public payable returns (bool) {
    require(_to != address(this));

    super.transfer(_to, _value);

     
    require(_to.call.value(msg.value)(_data));
    return true;
  }

   
  function transferFromAndCall(
    address _from,
    address _to,
    uint256 _value,
    bytes _data
  )
    public payable returns (bool)
  {
    require(_to != address(this));

    super.transferFrom(_from, _to, _value);

     
    require(_to.call.value(msg.value)(_data));
    return true;
  }

   
  function increaseApprovalAndCall(address _spender, uint _addedValue, bytes _data) public payable returns (bool) {
    require(_spender != address(this));

    super.increaseApproval(_spender, _addedValue);

     
    require(_spender.call.value(msg.value)(_data));

    return true;
  }

   
  function decreaseApprovalAndCall(address _spender, uint _subtractedValue, bytes _data) public payable returns (bool) {
    require(_spender != address(this));

    super.decreaseApproval(_spender, _subtractedValue);

     
    require(_spender.call.value(msg.value)(_data));

    return true;
  }

}


  

contract CSCResource is ERC827Token, OperationalControl {

  event Burn(address indexed burner, uint256 value);
  event Mint(address indexed to, uint256 amount);

   
  string public NAME;

   
  string public SYMBOL;

   
  uint public constant DECIMALS = 0;

   
  function CSCResource(string _name, string _symbol, uint _initialSupply) public {

     
    managerPrimary = msg.sender;
    managerSecondary = msg.sender;
    bankManager = msg.sender;

    NAME = _name;
    SYMBOL = _symbol;
    
     
    totalSupply_ = totalSupply_.add(_initialSupply);
    balances[msg.sender] = balances[msg.sender].add(_initialSupply);

    emit Mint(msg.sender, _initialSupply);
    emit Transfer(address(0), msg.sender, _initialSupply);

  }

   
  function burn(uint256 _value) public {
    _burn(msg.sender, _value);
  }

  function _burn(address _who, uint256 _value) internal {
    require(_value <= balances[_who]);
     
     

    balances[_who] = balances[_who].sub(_value);
    totalSupply_ = totalSupply_.sub(_value);
    emit Burn(_who, _value);
    emit Transfer(_who, address(0), _value);
  }  

   
    function mint(address _to, uint256 _amount)  public anyOperator returns (bool) {
        totalSupply_ = totalSupply_.add(_amount);
        balances[_to] = balances[_to].add(_amount);
        emit Mint(_to, _amount);
        emit Transfer(address(0), _to, _amount);
        return true;
    }

}

contract CSCResourceFactory is OperationalControl, StringHelpers {

    event CSCResourceCreated(string resourceContract, address contractAddress, uint256 amount); 

    mapping(uint16 => address) public resourceIdToAddress; 
    mapping(bytes32 => address) public resourceNameToAddress; 
    mapping(uint16 => bytes32) public resourceIdToName; 

    uint16 resourceTypeCount;

    function CSCResourceFactory() public {
        managerPrimary = msg.sender;
        managerSecondary = msg.sender;
        bankManager = msg.sender;

    }

    function createNewCSCResource(string _name, string _symbol, uint _initialSupply) public anyOperator {

        require(resourceNameToAddress[stringToBytes32(_name)] == 0x0);

        address resourceContract = new CSCResource(_name, _symbol, _initialSupply);

        
        resourceIdToAddress[resourceTypeCount] = resourceContract;
        resourceNameToAddress[stringToBytes32(_name)] = resourceContract;
        resourceIdToName[resourceTypeCount] = stringToBytes32(_name);
        
        emit CSCResourceCreated(_name, resourceContract, _initialSupply);

         
        resourceTypeCount += 1;

    }

    function setResourcesPrimaryManager(address _op) public onlyManager {
        
        require(_op != address(0));

        uint16 totalResources = getResourceCount();

        for(uint16 i = 0; i < totalResources; i++) {
            CSCResource resContract = CSCResource(resourceIdToAddress[i]);
            resContract.setPrimaryManager(_op);
        }

    }

    function setResourcesSecondaryManager(address _op) public onlyManager {

        require(_op != address(0));

        uint16 totalResources = getResourceCount();

        for(uint16 i = 0; i < totalResources; i++) {
            CSCResource resContract = CSCResource(resourceIdToAddress[i]);
            resContract.setSecondaryManager(_op);
        }

    }

    function setResourcesBanker(address _op) public onlyManager {

        require(_op != address(0));

        uint16 totalResources = getResourceCount();

        for(uint16 i = 0; i < totalResources; i++) {
            CSCResource resContract = CSCResource(resourceIdToAddress[i]);
            resContract.setBanker(_op);
        }

    }

    function setResourcesOtherManager(address _op, uint8 _state) public anyOperator {

        require(_op != address(0));

        uint16 totalResources = getResourceCount();

        for(uint16 i = 0; i < totalResources; i++) {
            CSCResource resContract = CSCResource(resourceIdToAddress[i]);
            resContract.setOtherManager(_op, _state);
        }

    }

    function withdrawFactoryResourceBalance(uint16 _resId) public onlyBanker {

        require(resourceIdToAddress[_resId] != 0);

        CSCResource resContract = CSCResource(resourceIdToAddress[_resId]);
        uint256 resBalance = resContract.balanceOf(this);
        resContract.transfer(bankManager, resBalance);

    }

    function transferFactoryResourceAmount(uint16 _resId, address _to, uint256 _amount) public onlyBanker {

        require(resourceIdToAddress[_resId] != 0);
        require(_to != address(0));

        CSCResource resContract = CSCResource(resourceIdToAddress[_resId]);
        uint256 resBalance = resContract.balanceOf(this);
        require(resBalance >= _amount);

        resContract.transfer(_to, _amount);
    }

    function mintResource(uint16 _resId, uint256 _amount) public onlyBanker {

        require(resourceIdToAddress[_resId] != 0);
        CSCResource resContract = CSCResource(resourceIdToAddress[_resId]);
        resContract.mint(this, _amount);
    }

    function burnResource(uint16 _resId, uint256 _amount) public onlyBanker {

        require(resourceIdToAddress[_resId] != 0);
        CSCResource resContract = CSCResource(resourceIdToAddress[_resId]);
        resContract.burn(_amount);
    }

    function getResourceName(uint16 _resId) public view returns (bytes32 name) {
        return resourceIdToName[_resId];
    }

    function getResourceCount() public view returns (uint16 resourceTotal) {
        return resourceTypeCount;
    }

    function getResourceBalance(uint16 _resId, address _wallet) public view returns (uint256 amt) {

        require(resourceIdToAddress[_resId] != 0);

        CSCResource resContract = CSCResource(resourceIdToAddress[_resId]);
        return resContract.balanceOf(_wallet);

    }

     
    function getWalletResourceBalance(address _wallet) external view returns(uint256[] resourceBalance){
        require(_wallet != address(0));
        
        uint16 totalResources = getResourceCount();
        
        uint256[] memory result = new uint256[](totalResources);
        
        for(uint16 i = 0; i < totalResources; i++) {
            CSCResource resContract = CSCResource(resourceIdToAddress[i]);
            result[i] = resContract.balanceOf(_wallet);
        }
        
        return result;
    }

}