 

pragma solidity ^0.4.18;

interface tokenRecipient { function receiveApproval(address _from, uint256 _value, address _token, bytes _extraData) public; }

 
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

contract EZToken {
    using SafeMath for uint256;

     
    string public name = "EZToken" ;
    string public symbol = "EZT";
    uint8 public decimals = 8;
    uint256 totalSupply_ = 0;
    uint256 constant icoSupply = 11500000;
    uint256 constant foundersSupply = 3500000;
    uint256 constant yearlySupply = 3500000;
    
    
    
    mapping (address => uint) public freezedAccounts;

    
    uint constant founderFronzenUntil = 1530403200;   
    uint constant year1FronzenUntil = 1546300800;  
    uint constant year2FronzenUntil = 1577836800;  
    uint constant year3FronzenUntil = 1609459200;  
    uint constant year4FronzenUntil = 1640995200;  
    uint constant year5FronzenUntil = 1672531200;  
    uint constant year6FronzenUntil = 1704067200;  
    uint constant year7FronzenUntil = 1735689600;  
    uint constant year8FronzenUntil = 1767225600;  
    uint constant year9FronzenUntil = 1798761600;  
    uint constant year10FronzenUntil = 1830297600;  
    
     
    mapping (address => uint256) internal balances;
    mapping (address => mapping (address => uint256)) internal allowed;


     
    event Transfer(address indexed from, address indexed to, uint256 value);

     
    event Burn(address indexed from, uint256 value);

    event Approval(address indexed owner, address indexed spender, uint256 value);

     
    function EZToken(address _founderAddress, address _year1, address _year2, address _year3, address _year4, address _year5, address _year6, address _year7, address _year8, address _year9, address _year10 ) public {
        totalSupply_ = 50000000 * 10 ** uint256(decimals);
        
        balances[msg.sender] = icoSupply * 10 ** uint256(decimals);                 
        Transfer(address(0), msg.sender, icoSupply);
        
        _setFreezedBalance(_founderAddress, foundersSupply, founderFronzenUntil);

        _setFreezedBalance(_year1, yearlySupply, year1FronzenUntil);
        _setFreezedBalance(_year2, yearlySupply, year2FronzenUntil);
        _setFreezedBalance(_year3, yearlySupply, year3FronzenUntil);
        _setFreezedBalance(_year4, yearlySupply, year4FronzenUntil);
        _setFreezedBalance(_year5, yearlySupply, year5FronzenUntil);
        _setFreezedBalance(_year6, yearlySupply, year6FronzenUntil);
        _setFreezedBalance(_year7, yearlySupply, year7FronzenUntil);
        _setFreezedBalance(_year8, yearlySupply, year8FronzenUntil);
        _setFreezedBalance(_year9, yearlySupply, year9FronzenUntil);
        _setFreezedBalance(_year10, yearlySupply, year10FronzenUntil);
    }
    
     
    function totalSupply() public view returns (uint256) {
        return totalSupply_;
    }

     
    function _setFreezedBalance(address _owner, uint256 _amount, uint _lockedUntil) internal {
        require(_owner != address(0));
        require(balances[_owner] == 0);
        freezedAccounts[_owner] = _lockedUntil;
        balances[_owner] = _amount * 10 ** uint256(decimals);     
    }

     
    function balanceOf(address _owner) public constant returns (uint256 balance) {
        return balances[_owner];
    }
    
     
    function allowance(address _owner, address _spender) public constant returns (uint256 remaining) {
        return allowed[_owner][_spender];
    }

     
    function transfer(address _to, uint256 _value) public returns (bool) {
        require(_to != address(0));
        require(_value <= balances[msg.sender]);
        require(freezedAccounts[msg.sender] == 0 || freezedAccounts[msg.sender] < now);
        require(freezedAccounts[_to] == 0 || freezedAccounts[_to] < now);

        balances[msg.sender] = balances[msg.sender].sub(_value);
        balances[_to] = balances[_to].add(_value);
        Transfer(msg.sender, _to, _value);
        return true;
    }

     
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool) {
        require(_to != address(0));
        require(_value <= balances[_from]);
        require(_value <= allowed[_from][msg.sender]);
        require(freezedAccounts[_from] == 0 || freezedAccounts[_from] < now);
        require(freezedAccounts[_to] == 0 || freezedAccounts[_to] < now);

        balances[_from] = balances[_from].sub(_value);
        balances[_to] = balances[_to].add(_value);
        allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
        Transfer(_from, _to, _value);
        return true;
    }

    

     
    function approve(address _spender, uint256 _value) public returns (bool success) {
        allowed[msg.sender][_spender] = _value;
        Approval(msg.sender, _spender, _value);
        return true;
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


     
    function burn(uint256 _value) public {
        require(_value <= balances[msg.sender]);
         
         

        address burner = msg.sender;
        balances[burner] = balances[burner].sub(_value);
        totalSupply_ = totalSupply_.sub(_value);
        Burn(burner, _value);
    }
}