 

pragma solidity ^0.4.19;

 
 

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


contract Token {
     
     
    uint256 public totalSupply;

     
     
    function balanceOf(address _owner) constant public returns (uint256 balance);

     
     
     
     
    function transfer(address _to, uint256 _value) public returns (bool success);

     
     
     
     
     
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success);

     
     
     
     
    function approve(address _spender, uint256 _value) public returns (bool success);

     
     
     
    function allowance(address _owner, address _spender) constant public returns (uint256 remaining);

    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
}

 

contract StandardToken is Token {
    using SafeMath for uint256;

    function transfer(address _to, uint256 _value) public returns (bool success) {
        require(_to != address(0));
        require(_value <= balances[msg.sender]);

         
        balances[msg.sender] = balances[msg.sender].sub(_value);
        balances[_to] = balances[_to].add(_value);
        Transfer(msg.sender, _to, _value);
        return true;

    }

    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {
        require(_to != address(0));
        require(_value <= balances[_from]);
        require(_value <= allowed[_from][msg.sender]);

        balances[_from] = balances[_from].sub(_value);
        balances[_to] = balances[_to].add(_value);
        allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
        Transfer(_from, _to, _value);
        return true;
    }

    function balanceOf(address _owner) constant public returns (uint256 balance) {
        return balances[_owner];
    }

    function approve(address _spender, uint256 _value) public returns (bool success) {
        allowed[msg.sender][_spender] = _value;
        Approval(msg.sender, _spender, _value);
        return true;
    }

    function allowance(address _owner, address _spender) constant public returns (uint256 remaining) {
      return allowed[_owner][_spender];
    }

     
  function increaseApproval(address _spender, uint _addedValue) public returns (bool) {
    allowed[msg.sender][_spender] = allowed[msg.sender][_spender].add(_addedValue);
    Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
    return true;
  }

  function decreaseApproval(address _spender, uint _subtractedValue) public returns (bool) {
    uint oldValue = allowed[msg.sender][_spender];
    if (_subtractedValue > oldValue) {
        allowed[msg.sender][_spender] = 0;
    } else {
        allowed[msg.sender][_spender] = oldValue.sub(_subtractedValue);
    }
    Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
    return true;
   }


    mapping (address => uint256) balances;
    mapping (address => mapping (address => uint256)) allowed;
}

contract HumanStandardToken is StandardToken {

    function () public {
         
        throw;
    }

     

     
    string public name;                    
    uint8 public decimals;                 
    string public symbol;                  
    string public version = 'H0.1';        

    function HumanStandardToken (
        uint256 _initialAmount,
        string _tokenName,
        uint8 _decimalUnits,
        string _tokenSymbol
        ) internal {
        balances[msg.sender] = _initialAmount;                
        totalSupply = _initialAmount;                         
        name = _tokenName;                                    
        decimals = _decimalUnits;                             
        symbol = _tokenSymbol;                                
    }

     
    function approveAndCall(address _spender, uint256 _value, bytes _extraData) public returns (bool success) {
        allowed[msg.sender][_spender] = _value;
        Approval(msg.sender, _spender, _value);

         
         
         
        if(!_spender.call(bytes4(bytes32(keccak256("receiveApproval(address,uint256,address,bytes)"))), msg.sender, _value, this, _extraData)) { throw; }
        return true;
    }
}

contract YEEToken is HumanStandardToken(10000000000000000000000000000,"Yee - A Blockchain-powered & Cloud-based Social Ecosystem",18,"YEE"){
 function () public {
         
        throw;
    }
 
 function YEEToken () public {
  
    }
}

contract YeeLockerForYeePartner {
    address public accountLocked;    
    uint256 public timeLockedStart;       
    uint256 public amountNeedToBeLock;   
    uint256 public unlockPeriod;       
    uint256 public unlockPeriodNum;    
    
    address  private yeeTokenAddress = 0x922105fAd8153F516bCfB829f56DC097a0E1D705;
    YEEToken private yeeToken = YEEToken(yeeTokenAddress);
    
    event EvtUnlock(address lockAccount, uint256 value);
    
    function _balance() public view returns(uint256 amount){
        return yeeToken.balanceOf(this);
    }
    
    function unlockCurrentAvailableFunds() public returns(bool result){
        uint256 amount = getCurrentAvailableFunds();
        if ( amount == 0 ){
            return false;
        }
        else{
            bool ret = yeeToken.transfer(accountLocked, amount);
            EvtUnlock(accountLocked, amount);
            return ret;
        }
    }
    
    function getNeedLockFunds() public view returns(uint256 needLockFunds){
        uint256 count = (now - timeLockedStart)/unlockPeriod + 1;  
        if ( count > unlockPeriodNum ){
            return 0;
        }
        else{
            uint256 needLock = amountNeedToBeLock / unlockPeriodNum * (unlockPeriodNum - count );
            return needLock;
        }
    }

    function getCurrentAvailableFunds() public view returns(uint256 availableFunds){
        uint256 balance = yeeToken.balanceOf(this);
        uint256 needLock = getNeedLockFunds();
        if ( balance > needLock ){
            return balance - needLock;
        }
        else{
            return 0;
        }
    }
    
    function getNeedLockFundsFromPeriod(uint256 endTime, uint256 startTime) public view returns(uint256 needLockFunds){
        uint256 count = (endTime - startTime)/unlockPeriod + 1;  
        if ( count > unlockPeriodNum ){
            return 0;
        }
        else{
            uint256 needLock = amountNeedToBeLock / unlockPeriodNum * (unlockPeriodNum - count );
            return needLock;
        }
    }
    
    function YeeLockerForYeePartner() public {
         
         
        accountLocked = msg.sender;
        uint256 base = 1000000000000000000;
        amountNeedToBeLock = 1000000000 * base;  
        unlockPeriod = 91 days;
        unlockPeriodNum = 20;
        timeLockedStart = now;
    }
}