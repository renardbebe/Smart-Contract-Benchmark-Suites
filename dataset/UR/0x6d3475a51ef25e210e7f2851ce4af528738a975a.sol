 

pragma solidity ^0.4.11;

 
contract Ownable {
  address public owner;

  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

   
  function Ownable() {
    owner = msg.sender;
  }


   
  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }


   
  function transferOwnership(address newOwner) onlyOwner public {
    require(newOwner != address(0));
    OwnershipTransferred(owner, newOwner);
    owner = newOwner;
  }

}


 
contract Pausable is Ownable {
  event Pause();
  event Unpause();

  bool public paused = false;


   
  modifier whenNotPaused() {
    require(!paused);
    _;
  }

   
  modifier whenPaused() {
    require(paused);
    _;
  }

   
  function pause() onlyOwner whenNotPaused public {
    paused = true;
    Pause();
  }

   
  function unpause() onlyOwner whenPaused public {
    paused = false;
    Unpause();
  }
}


contract Token {
     
     
    uint256 public totalSupply;

     
     
    function balanceOf(address _owner) constant returns (uint256 balance);

     
     
     
     
    function transfer(address _to, uint256 _value) returns (bool success);

     
     
     
     
     
    function transferFrom(address _from, address _to, uint256 _value) returns (bool success);

     
     
     
     
    function approve(address _spender, uint256 _value) returns (bool success);

     
     
     
    function allowance(address _owner, address _spender) constant returns (uint256 remaining);

    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
}


contract StandardToken is Token {

    function transfer(address _to, uint256 _value) returns (bool success) {
        require(balances[msg.sender] >= _value && balances[_to] + _value > balances[_to]);
        balances[msg.sender] -= _value;
        balances[_to] += _value;
        Transfer(msg.sender, _to, _value);
        return true;
    }

    function transferFrom(address _from, address _to, uint256 _value) returns (bool success) {
        require(balances[_from] >= _value && allowed[_from][msg.sender] >= _value && balances[_to] + _value > balances[_to]);
        balances[_to] += _value;
        balances[_from] -= _value;
        allowed[_from][msg.sender] -= _value;
        Transfer(_from, _to, _value);
        return true;
    }

    function balanceOf(address _owner) constant returns (uint256 balance) {
        return balances[_owner];
    }

    function approve(address _spender, uint256 _value) returns (bool success) {
        allowed[msg.sender][_spender] = _value;
        Approval(msg.sender, _spender, _value);
        return true;
    }

    function allowance(address _owner, address _spender) constant returns (uint256 remaining) {
      return allowed[_owner][_spender];
    }

    mapping (address => uint256) public balances;  
    mapping (address => mapping (address => uint256)) public allowed;  
}


contract BQCCToken is StandardToken, Pausable {

    string public constant name = "BQCC Token";
    string public constant symbol = "BQCC";
    uint8 public constant decimals = 6;
    uint256 public constant totalSupply = 1000000000000000;

     
    struct BalanceLock {
        uint256 amount;
        uint256 unlockDate;
    }

     
    mapping (address => BalanceLock) public balanceLocks;

     
    event BalanceLocked(address indexed _owner, uint256 _oldLockedAmount,
    uint256 _newLockedAmount, uint256 _expiry);

     
    function BQCCToken()
        Pausable() {
        balances[msg.sender] = totalSupply;
        Transfer(0x0, msg.sender, totalSupply);
    }

     
       
    function lockBalance(address addr, uint256 _value,uint256 lockingDays) onlyOwner {

         
        if (balanceLocks[addr].unlockDate > now) {  
             
            require(_value >= balanceLocks[addr].amount);
        }
         
        require(balances[addr] >= _value);
         
        uint256 lockingPeriod = lockingDays*24*3600;
         
        uint256 _expiry = now + lockingPeriod;
        BalanceLocked(addr, balanceLocks[addr].amount, _value, _expiry);
        balanceLocks[addr] = BalanceLock(_value, _expiry);
    }

     
     
    function availableBalance(address _owner) constant returns(uint256) {
        if (balanceLocks[_owner].unlockDate < now) {
            return balances[_owner];
        } else {
            assert(balances[_owner] >= balanceLocks[_owner].amount);
            return balances[_owner] - balanceLocks[_owner].amount;
        }
    }

     
       
    function transfer(address _to, uint256 _value) whenNotPaused returns (bool success) {
        require(availableBalance(msg.sender) >= _value);
        return super.transfer(_to, _value);
    }

     
    function transferFrom(address _from, address _to, uint256 _value) whenNotPaused
        returns (bool success) {
        require(availableBalance(_from) >= _value);
        return super.transferFrom(_from, _to, _value);
    }
}