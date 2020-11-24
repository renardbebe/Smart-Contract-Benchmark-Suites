 

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




 
contract AirSwapToken is StandardToken, Pausable {

    string public constant name = "AirSwap Token";
    string public constant symbol = "AST";
    uint8 public constant decimals = 4;
    uint256 public constant totalSupply = 5000000000000;

     
     
    uint256 becomesTransferable = 1508249410;

     
     
    uint256 lockingPeriod = 604800;

     
    modifier onlyAfter(uint256 _time) {
        require(now >= _time);
        _;
    }

     
    modifier onlyAfterOrOwner(uint256 _time, address _from) {
        if (_from != owner) {
            require(now >= _time);
        }
        _;
    }

     
    struct BalanceLock {
        uint256 amount;
        uint256 unlockDate;
    }

     
    mapping (address => BalanceLock) public balanceLocks;

     
    event BalanceLocked(address indexed _owner, uint256 _oldLockedAmount,
    uint256 _newLockedAmount, uint256 _expiry);

     
    function AirSwapToken(address _deployer, address _owner, uint256 _balance)
        Pausable() {
        transferOwnership(_owner);
        balances[_deployer] = totalSupply - _balance;
        balances[_owner] = _balance;
        Transfer(0x0, _deployer, totalSupply);
        Transfer(_deployer, _owner, _balance);
    }

     
    function lockBalance(uint256 _value) {

         
        if (balanceLocks[msg.sender].unlockDate > now) {
             
            require(_value >= balanceLocks[msg.sender].amount);
        }
         
        require(balances[msg.sender] >= _value);

         
        uint256 _expiry = now + lockingPeriod;
        BalanceLocked(msg.sender, balanceLocks[msg.sender].amount, _value, _expiry);
        balanceLocks[msg.sender] = BalanceLock(_value, _expiry);
    }

     
    function availableBalance(address _owner) constant returns(uint256) {
        if (balanceLocks[_owner].unlockDate < now) {
            return balances[_owner];
        } else {
            assert(balances[_owner] >= balanceLocks[_owner].amount);
            return balances[_owner] - balanceLocks[_owner].amount;
        }
    }

     
    function transfer(address _to, uint256 _value)
        onlyAfter(becomesTransferable) whenNotPaused
        returns (bool success) {
        require(availableBalance(msg.sender) >= _value);
        return super.transfer(_to, _value);
    }

     
    function transferFrom(address _from, address _to, uint256 _value)
        onlyAfterOrOwner(becomesTransferable, _from) whenNotPaused
        returns (bool success) {
        require(availableBalance(_from) >= _value);
        return super.transferFrom(_from, _to, _value);
    }
}