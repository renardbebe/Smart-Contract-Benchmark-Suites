 

pragma solidity ^0.4.24;

 
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


contract BasicToken is ERC20Basic {
  using SafeMath for uint256;

  mapping(address => uint256) balances;


  function transfer(address _to, uint256 _value) returns (bool) {
    balances[msg.sender] = balances[msg.sender].sub(_value);
    balances[_to] = balances[_to].add(_value);
    Transfer(msg.sender, _to, _value);
    return true;
  }


  function balanceOf(address _owner) constant returns (uint256 balance) {
    return balances[_owner];
  }

}


contract ERC20 is ERC20Basic {
  function allowance(address owner, address spender) constant returns (uint256);
  function transferFrom(address from, address to, uint256 value) returns (bool);
  function approve(address spender, uint256 value) returns (bool);
  event Approval(address indexed owner, address indexed spender, uint256 value);
}


contract StandardToken is ERC20, BasicToken {

  mapping (address => mapping (address => uint256)) allowed;


  
  function transferFrom(address _from, address _to, uint256 _value) returns (bool) {
    var _allowance = allowed[_from][msg.sender];
    balances[_to] = balances[_to].add(_value);
    balances[_from] = balances[_from].sub(_value);
    allowed[_from][msg.sender] = _allowance.sub(_value);
    Transfer(_from, _to, _value);
    return true;
  }

 
  function approve(address _spender, uint256 _value) returns (bool) {

    require((_value == 0) || (allowed[msg.sender][_spender] == 0));

    allowed[msg.sender][_spender] = _value;
    Approval(msg.sender, _spender, _value);
    return true;
  }

  function allowance(address _owner, address _spender) constant returns (uint256 remaining) {
    return allowed[_owner][_spender];
  }

}

contract Ownable {
  address public owner;
  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
   
   
    
   
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
 

contract token{ 
    function transfer(address receiver, uint amount){  } 
    
}

contract SendTokensContract is Ownable,BasicToken {
  using SafeMath for uint;
  mapping (address => uint) public bals;
  mapping (address => uint) public releaseTimes;
  mapping (address => bytes32[]) public referenceCodes;
  mapping (bytes32 => address[]) public referenceAddresses;
  address public addressOfTokenUsedAsReward;
  token tokenReward;

  event TokensSent
    (address to, uint256 value, uint256 timeStamp, bytes32 referenceCode);

  function setTokenReward(address _tokenContractAddress) public onlyOwner {
    tokenReward = token(_tokenContractAddress);
    addressOfTokenUsedAsReward = _tokenContractAddress;
  }

  function sendTokens(address _to, 
    uint _value, 
    uint _timeStamp, 
    bytes32 _referenceCode) public onlyOwner {
    bals[_to] = bals[_to].add(_value);
    releaseTimes[_to] = _timeStamp;
    referenceCodes[_to].push(_referenceCode);
    referenceAddresses[_referenceCode].push(_to);
    emit TokensSent(_to, _value, _timeStamp, _referenceCode);
  }

  function getReferenceCodesOfAddress(address _addr) public constant 
  returns (bytes32[] _referenceCodes) {
    return referenceCodes[_addr];
  }

  function getReferenceAddressesOfCode(bytes32 _code) public constant
  returns (address[] _addresses) {
    return referenceAddresses[_code];
  }

  function withdrawTokens() public {
    require(bals[msg.sender] > 0);
    require(now >= releaseTimes[msg.sender]);
    tokenReward.transfer(msg.sender,bals[msg.sender]);
     
    bals[msg.sender] = 0;
  }
}

 


contract RWSC is StandardToken,SendTokensContract {

  string public constant name = "Real-World Smart Contract";
  string public constant symbol = "RWSC";
  uint256 public constant decimals = 18;
  
  uint256 public constant INITIAL_SUPPLY = 888888888 * 10 ** uint256(decimals);

  
  function RWSC() {
    totalSupply = INITIAL_SUPPLY;
    balances[msg.sender] = INITIAL_SUPPLY;
    owner=msg.sender;
  }
  

  function Airdrop(ERC20 token, address[] _addresses, uint256 amount) public {
        for (uint256 i = 0; i < _addresses.length; i++) {
            token.transfer(_addresses[i], amount);
        }
    }
 

 
}