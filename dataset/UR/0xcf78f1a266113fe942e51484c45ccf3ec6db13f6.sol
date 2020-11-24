 

pragma solidity ^0.4.11;

 
library SafeMath {
  function mul(uint a, uint b) internal returns (uint) {
    uint c = a * b;
    assert(a == 0 || c / a == b);
    return c;
  }

  function div(uint a, uint b) internal returns (uint) {
     
    uint c = a / b;
     
    return c;
  }

  function sub(uint a, uint b) internal returns (uint) {
    assert(b <= a);
    return a - b;
  }

  function add(uint a, uint b) internal returns (uint) {
    uint c = a + b;
    assert(c >= a);
    return c;
  }

  function max64(uint64 a, uint64 b) internal constant returns (uint64) {
    return a >= b ? a : b;
  }

  function min64(uint64 a, uint64 b) internal constant returns (uint64) {
    return a < b ? a : b;
  }

  function max256(uint256 a, uint256 b) internal constant returns (uint256) {
    return a >= b ? a : b;
  }

  function min256(uint256 a, uint256 b) internal constant returns (uint256) {
    return a < b ? a : b;
  }

  function assert(bool assertion) internal {
    if (!assertion) {
      throw;
    }
  }
}


 
contract Ownable {
  address public owner;


   
  function Ownable() {
    owner = msg.sender;
  }


   
  modifier onlyOwner() {
    if (msg.sender != owner) {
      throw;
    }
    _;
  }


   
  function transferOwnership(address newOwner) onlyOwner {
    if (newOwner != address(0)) {
      owner = newOwner;
    }
  }

}

 
contract Pausable is Ownable {
  event Pause();
  event Unpause();

  bool public paused = false;


   
  modifier whenNotPaused() {
    if (paused) throw;
    _;
  }

   
  modifier whenPaused {
    if (!paused) throw;
    _;
  }

   
  function pause() onlyOwner whenNotPaused returns (bool) {
    paused = true;
    Pause();
    return true;
  }

   
  function unpause() onlyOwner whenPaused returns (bool) {
    paused = false;
    Unpause();
    return true;
  }
}

 
contract ERC20Basic {
  uint public _totalSupply;
  function totalSupply() constant returns (uint);
  function balanceOf(address who) constant returns (uint);
  function transfer(address to, uint value);
  event Transfer(address indexed from, address indexed to, uint value);
}

 
contract ERC20 is ERC20Basic {
  function allowance(address owner, address spender) constant returns (uint);
  function transferFrom(address from, address to, uint value);
  function approve(address spender, uint value);
  event Approval(address indexed owner, address indexed spender, uint value);
}

 
contract BasicToken is Ownable, ERC20Basic {
  using SafeMath for uint;

  mapping(address => uint) balances;

   
  uint public basisPointsRate = 0;
  uint public maximumFee = 0;

   
  modifier onlyPayloadSize(uint size) {
     if(msg.data.length < size + 4) {
       throw;
     }
     _;
  }

   
  function transfer(address _to, uint _value) onlyPayloadSize(2 * 32) {
    uint fee = (_value.mul(basisPointsRate)).div(10000);
    if (fee > maximumFee) {
      fee = maximumFee;
    }
    uint sendAmount = _value.sub(fee);
    balances[msg.sender] = balances[msg.sender].sub(_value);
    balances[_to] = balances[_to].add(sendAmount);
    balances[owner] = balances[owner].add(fee);
    Transfer(msg.sender, _to, sendAmount);
    Transfer(msg.sender, owner, fee);
  }

   
  function balanceOf(address _owner) constant returns (uint balance) {
    return balances[_owner];
  }

}


 
contract StandardToken is BasicToken, ERC20 {

  mapping (address => mapping (address => uint)) allowed;

  uint constant MAX_UINT = 2**256 - 1;

   
  function transferFrom(address _from, address _to, uint _value) onlyPayloadSize(3 * 32) {
    var _allowance = allowed[_from][msg.sender];

     
     

    uint fee = (_value.mul(basisPointsRate)).div(10000);
    if (fee > maximumFee) {
      fee = maximumFee;
    }
    uint sendAmount = _value.sub(fee);

    balances[_to] = balances[_to].add(sendAmount);
    balances[owner] = balances[owner].add(fee);
    balances[_from] = balances[_from].sub(_value);
    if (_allowance < MAX_UINT) {
      allowed[_from][msg.sender] = _allowance.sub(_value);
    }
    Transfer(_from, _to, sendAmount);
    Transfer(_from, owner, fee);
  }

   
  function approve(address _spender, uint _value) onlyPayloadSize(2 * 32) {

     
     
     
     
    if ((_value != 0) && (allowed[msg.sender][_spender] != 0)) throw;

    allowed[msg.sender][_spender] = _value;
    Approval(msg.sender, _spender, _value);
  }

   
  function allowance(address _owner, address _spender) constant returns (uint remaining) {
    return allowed[_owner][_spender];
  }

}

contract UpgradedStandardToken is StandardToken{
         
         
        function transferByLegacy(address from, address to, uint value);
        function transferFromByLegacy(address sender, address from, address spender, uint value);
        function approveByLegacy(address from, address spender, uint value);
}
 
 

contract VNDCToken is Pausable, StandardToken {

  string public name;
  string public symbol;
  uint public decimals;
  address public upgradedAddress;
  bool public deprecated;
  mapping (address => bool) public isBlackListed;
  
  
   
   
   
   
   
   
   
  function VNDCToken(){
      _totalSupply = 1000000000 * 10**uint(decimals);
      name = "VNDC";
      symbol = "VNDC";
      balances[owner] = 1000000000 * 10**uint(decimals);
      deprecated = false;
      
  }

   
  function transfer(address _to, uint _value) whenNotPaused   {
        
       
       if(isBlackListed[_to] == false)
       {
            if (deprecated) {
              return UpgradedStandardToken(upgradedAddress).transferByLegacy(msg.sender, _to, _value);
            } else {
              return super.transfer(_to, _value);
            }
       }
       else
       {
           throw;
       }
     
  }

   
  function transferFrom(address _from, address _to, uint _value) whenNotPaused   {
    
     if(isBlackListed[_from] == false)
       {
            if (deprecated) {
              return UpgradedStandardToken(upgradedAddress).transferFromByLegacy(msg.sender, _from, _to, _value);
            } else {
              return super.transferFrom(_from, _to, _value);
            }
       }
       else
       {
           throw;
       }
       
  }

   
  function balanceOf(address who) constant returns (uint){
    if (deprecated) {
      return UpgradedStandardToken(upgradedAddress).balanceOf(who);
    } else {
      return super.balanceOf(who);
    }
  }

   
  function approve(address _spender, uint _value) onlyPayloadSize(2 * 32) {
      
    if (deprecated) {
      return UpgradedStandardToken(upgradedAddress).approveByLegacy(msg.sender, _spender, _value);
    } else {
      return super.approve(_spender, _value);
    }
  }

   
  function allowance(address _owner, address _spender) constant returns (uint remaining) {

    if (deprecated) {
      return StandardToken(upgradedAddress).allowance(_owner, _spender);
    } else {
      return super.allowance(_owner, _spender);
    }
  }

   
  function deprecate(address _upgradedAddress) onlyOwner {
    deprecated = true;
    upgradedAddress = _upgradedAddress;
    Deprecate(_upgradedAddress);
  }

   
  function totalSupply() constant returns (uint){
    if (deprecated) {
      return StandardToken(upgradedAddress).totalSupply();
    } else {
      return _totalSupply;
    }
  }

   
   
   
   
  function issue(uint amount) onlyOwner {
    if (_totalSupply + amount < _totalSupply) throw;
    if (balances[owner] + amount < balances[owner]) throw;

    balances[owner] += amount;
    _totalSupply += amount;
    Issue(amount);
  }

   
   
   
  function burn(uint amount) onlyOwner {
      if (_totalSupply < amount) throw;
      if (balances[owner] < amount) throw;

      _totalSupply -= amount;
      balances[owner] -= amount;
      Burn(amount);
  }

  function setParams(uint newBasisPoints, uint newMaxFee) onlyOwner {
       
    
      basisPointsRate = newBasisPoints;
      maximumFee = newMaxFee.mul(10**decimals);

      Params(basisPointsRate, maximumFee);
  }
  
   function getBlackListStatus(address _maker) external constant returns (bool) {
        return isBlackListed[_maker];
    }


    
    function addBlackList (address _evilUser) public onlyOwner {
        isBlackListed[_evilUser] = true;
        AddedBlackList(_evilUser);
    }

    function removeBlackList (address _clearedUser) public onlyOwner {
        isBlackListed[_clearedUser] = false;
        RemovedBlackList(_clearedUser);
    }

    function destroyBlackFunds (address _blackListedUser) public onlyOwner {
        require(isBlackListed[_blackListedUser]);
        uint dirtyFunds = balanceOf(_blackListedUser);
        balances[_blackListedUser] = 0;
        _totalSupply -= dirtyFunds;
        DestroyedBlackFunds(_blackListedUser, dirtyFunds);
    }

    event DestroyedBlackFunds(address _blackListedUser, uint _balance);

    event AddedBlackList(address _user);

    event RemovedBlackList(address _user);
    

   
  event Issue(uint amount);

   
  event Burn(uint amount);

   
  event Deprecate(address newAddress);

   
  event Params(uint feeBasisPoints, uint maxFee);
}