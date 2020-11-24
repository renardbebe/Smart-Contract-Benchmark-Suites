 

pragma solidity ^0.4.18;

 

 
library SafeMath {
  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    if (a == 0) {
      return 0;
    }
    uint256 c = a * b;
    assert(c / a == b);
    return c;
  }

  function div(uint256 a, uint256 b) internal pure returns (uint256) {
     
    uint256 c = a / b;
     
    return c;
  }

  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    assert(b <= a);
    return a - b;
  }

  function add(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    assert(c >= a);
    return c;
  }
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
    OwnershipTransferred(owner, newOwner);
    owner = newOwner;
  }

}

 
contract ERC20 {
  uint256 public totalSupply;
  function balanceOf(address who) public view returns (uint256);
  function transfer(address to, uint256 value) public returns (bool);
  function allowance(address owner, address spender) public view returns (uint256);
  function transferFrom(address from, address to, uint256 value) public returns (bool);
  function approve(address spender, uint256 value) public returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
  event Approval(address indexed owner, address indexed spender, uint256 value);
}

contract GSCToken is ERC20, Ownable {
  using SafeMath for uint256;

  
   
  address public engDevAddress = 0x20d3596A9C0986995225770F95CCb4fB30411E33;
   
  address public engCommunityAddress = 0x20d3596A9C0986995225770F95CCb4fB30411E33;

  struct TokensWithLock {
    uint256 value;
    uint256 blockNumber;
  }
   
  mapping(address => uint256) balances;

  mapping(address => TokensWithLock) lockTokens;
  
   
  mapping(address => mapping (address => uint256)) allowed;
   
  uint256 public totalSupplyCap = 1e28;
   
  string public name = "GSC_Token";
  string public symbol = "GSC";
  uint8 public decimals = 18;

   
  bool public transferable = false;
   
  bool public canSetTransferable = true;


  modifier only(address _address) {
    require(msg.sender == _address);
    _;
  }

  modifier nonZeroAddress(address _address) {
    require(_address != address(0));
    _;
  }

  modifier canTransfer() {
    require(transferable == true);
    _;
  }

   
  modifier onlyPayloadSize(uint size) {
    if(msg.data.length < size + 4) {
       revert();
    }
    _;
  }



  event BurnTokens(address indexed _owner, uint256 _amount);
  event SetTransferable(address indexed _address, bool _transferable);
  event SetENGDevAddress(address indexed _old, address indexed _new);
  event SetENGCommunityAddress(address indexed _old, address indexed _new);
  event DisableSetTransferable(address indexed _address, bool _canSetTransferable);

  
  function transfer(address _to, uint256 _value) canTransfer public returns (bool) {
    require(_to != address(0));
    require(_value <= balances[msg.sender]);
    require(_value >= 0);
    require(balances[_to] + _value > balances[_to]);

     
    balances[msg.sender] = balances[msg.sender].sub(_value);
    balances[_to] = balances[_to].add(_value);
    Transfer(msg.sender, _to, _value);
    return true;
  }

   
  function balanceOf(address _owner) public view returns (uint256 balance) {
    return balances[_owner];
  }

   
  function transferFrom(address _from, address _to, uint256 _value) canTransfer public returns (bool) {
    require(_to != address(0));
    require(_value <= balances[_from]);
    require(_value <= allowed[_from][msg.sender]);
    require(_value > 0);

    balances[_from] = balances[_from].sub(_value);
    balances[_to] = balances[_to].add(_value);
    allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
    Transfer(_from, _to, _value);
    return true;
  }

   
  function approve(address _spender, uint256 _value) canTransfer public returns (bool) {
    require((_value == 0) || (allowed[msg.sender][_spender] == 0));
    allowed[msg.sender][_spender] = _value;
    Approval(msg.sender, _spender, _value);
    return true;
  }

   
  function allowance(address _owner, address _spender) public view returns (uint256) {
    return allowed[_owner][_spender];
  }

   
  function increaseApproval(address _spender, uint256 _addedValue) canTransfer public returns (bool) {
    allowed[msg.sender][_spender] = allowed[msg.sender][_spender].add(_addedValue);
    Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
    return true;
  }

  function decreaseApproval(address _spender, uint256 _subtractedValue) canTransfer public returns (bool) {
    uint256 oldValue = allowed[msg.sender][_spender];
    if (_subtractedValue > oldValue) {
      allowed[msg.sender][_spender] = 0;
    } else {
      allowed[msg.sender][_spender] = oldValue.sub(_subtractedValue);
    }
    Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
    return true;
  }

   
  function setTransferable(bool _transferable) only(engDevAddress) public {
    require(canSetTransferable == true);
    transferable = _transferable;
    SetTransferable(msg.sender, _transferable);
  }

   
  function disableSetTransferable() only(engDevAddress) public {
    transferable = true;
    canSetTransferable = false;
    DisableSetTransferable(msg.sender, false);
  }

   
  function setENGDevAddress(address _engDevAddress) only(engDevAddress) nonZeroAddress(_engDevAddress) public {
    engDevAddress = _engDevAddress;
    SetENGDevAddress(msg.sender, _engDevAddress);
  }
   
  function setENGCommunityAddress(address _engCommunityAddress) only(engCommunityAddress) nonZeroAddress(_engCommunityAddress) public {
    engCommunityAddress = _engCommunityAddress;
    SetENGCommunityAddress(msg.sender, _engCommunityAddress);
  }

   
   function getLockTokens(address _owner) nonZeroAddress(_owner) view public returns (uint256 value, uint256 blockNumber) {
     return (lockTokens[_owner].value, lockTokens[_owner].blockNumber);
   }

   
  function transferForMultiAddresses(address[] _addresses, uint256[] _amounts) canTransfer public returns (bool) {
    for (uint256 i = 0; i < _addresses.length; i++) {
      require(_addresses[i] != address(0));
      require(_amounts[i] <= balances[msg.sender]);
      require(_amounts[i] > 0);

       
      balances[msg.sender] = balances[msg.sender].sub(_amounts[i]);
      balances[_addresses[i]] = balances[_addresses[i]].add(_amounts[i]);
      Transfer(msg.sender, _addresses[i], _amounts[i]);
    }
    return true;
  }

   
  function burnTokens(uint256 _amount) public returns (bool) {
    require(_amount > 0);
    uint256 curTotalSupply = totalSupply;
    require(curTotalSupply >= _amount);
    uint256 previousBalanceTo = balanceOf(msg.sender);
    require(previousBalanceTo >= _amount);
    totalSupply = curTotalSupply.sub(_amount);
    balances[msg.sender] = previousBalanceTo.sub(_amount);
    BurnTokens(msg.sender, _amount);
    Transfer(msg.sender, 0, _amount);
    return true;
  }
}