 

pragma solidity ^0.4.21;


 
contract ERC20Basic {
  function totalSupply() public view returns (uint256);
  function balanceOf(address who) public view returns (uint256);
  function transfer(address to, uint256 value) public returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
}



 
contract Ownable {
  address public owner;


  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);


   
  function Ownable() public {
    owner = msg.sender;
  }

   
  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }

   
  function transferOwnership(address newOwner) public onlyOwner {
    require(newOwner != address(0));
    emit OwnershipTransferred(owner, newOwner);
    owner = newOwner;
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






 
contract HasNoEther is Ownable {

   
  function HasNoEther() public payable {
    require(msg.value == 0);
  }

   
  function() external {
  }

   
  function reclaimEther() external onlyOwner {
     
    assert(owner.send(address(this).balance));
  }
}


 
contract EOSContractInterface
{
    mapping (address => string) public keys;
    function balanceOf( address who ) constant returns (uint value);
}

 
contract EOSclassic is StandardToken, HasNoEther 
{
     
    string public constant NAME = "EOSclassic";
    string public constant SYMBOL = "EOSC";
    uint8 public constant DECIMALS = 18;

     
    uint public constant TOTAL_SUPPLY = 1000000000 * (10 ** uint(DECIMALS));
    
     
    uint public constant foundersAllocation = 100000000 * (10 ** uint(DECIMALS));   

     
    address public constant eosTokenAddress = 0x86Fa049857E0209aa7D9e616F7eb3b3B78ECfdb0;
    address public constant eosCrowdsaleAddress = 0xd0a6E6C54DbC68Db5db3A091B171A77407Ff7ccf;
    
     
    mapping (address => string) public keys;
    
     
    mapping (address => bool) public eosClassicClaimed;

     
    event LogClaim (address user, uint amount);

     
    event LogRegister (address user, string key);

     
     
     
    constructor() public 
    {
         
        totalSupply_ = TOTAL_SUPPLY;
         
        balances[address(this)] = TOTAL_SUPPLY;
         
        emit Transfer(0x0, address(this), TOTAL_SUPPLY);
        
         
        balances[address(this)] = balances[address(this)].sub(foundersAllocation);
        balances[msg.sender] = balances[msg.sender].add(foundersAllocation);
         
        emit Transfer(address(this), msg.sender, foundersAllocation);
    }

     
    function queryEOSTokenBalance(address _address) view public returns (uint) 
    {
         
        EOSContractInterface eosTokenContract = EOSContractInterface(eosTokenAddress);
        return eosTokenContract.balanceOf(_address);
    }

     
    function queryEOSCrowdsaleKey(address _address) view public returns (string) 
    {
        EOSContractInterface eosCrowdsaleContract = EOSContractInterface(eosCrowdsaleAddress);
        return eosCrowdsaleContract.keys(_address);
    }

     
    function claimEOSclassic() external returns (bool) 
    {
        return claimEOSclassicFor(msg.sender);
    }

     
    function claimEOSclassicFor(address _toAddress) public returns (bool)
    {
         
        require (_toAddress != address(0));
         
        require (isClaimed(_toAddress) == false);
        
         
        uint _eosContractBalance = queryEOSTokenBalance(_toAddress);
        
         
        require (_eosContractBalance > 0);
        
         
        require (_eosContractBalance <= balances[address(this)]);

         
        eosClassicClaimed[_toAddress] = true;
        
         
         
        balances[address(this)] = balances[address(this)].sub(_eosContractBalance);
        balances[_toAddress] = balances[_toAddress].add(_eosContractBalance);
        
         
        emit Transfer(address(this), _toAddress, _eosContractBalance);
        
         
        emit LogClaim(_toAddress, _eosContractBalance);
        
         
        return true;
    }

     
    function isClaimed(address _address) public view returns (bool) 
    {
        return eosClassicClaimed[_address];
    }

     
     
     
     
     
     
    function getMyEOSKey() external view returns (string)
    {
        return getEOSKeyFor(msg.sender);
    }

     
    function getEOSKeyFor(address _address) public view returns (string)
    {
        string memory _eosKey;

         
        _eosKey = keys[_address];

        if (bytes(_eosKey).length > 0) {
             
            return _eosKey;
        } else {
             
            _eosKey = queryEOSCrowdsaleKey(_address);
            return _eosKey;
        }
    }

     
     
     
     
     
     
     
     
    function register(string key) public {
        assert(bytes(key).length <= 64);

        keys[msg.sender] = key;

        emit LogRegister(msg.sender, key);
    }

}