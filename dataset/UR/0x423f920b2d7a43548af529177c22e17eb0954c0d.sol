 

 
 
pragma solidity ^0.4.8;

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
         
         
         
         
        if (balances[msg.sender] >= _value && _value > 0) {
            balances[msg.sender] -= _value;
            balances[_to] += _value;
            Transfer(msg.sender, _to, _value);
            return true;
        } else { return false; }
    }

    function transferFrom(address _from, address _to, uint256 _value) returns (bool success) {
         
         
        if (balances[_from] >= _value && allowed[_from][msg.sender] >= _value && _value > 0) {
            balances[_to] += _value;
            balances[_from] -= _value;
            allowed[_from][msg.sender] -= _value;
            Transfer(_from, _to, _value);
            return true;
        } else { return false; }
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

    mapping (address => uint256) balances;
    mapping (address => mapping (address => uint256)) allowed;
}
 


contract RGXToken is StandardToken {
    
     
    string public name;
    string public symbol;
    uint8 public decimals = 0;
    string public version = 'v1';
    
     
    address owner; 
    uint public fundingStart;
    uint256 public minContrib = 1;
    uint256 public frozenSupply = 0;
    uint8 public discountMultiplier;
    
    modifier fundingOpen() {
        require(now >= fundingStart);
        _;
    }
    
    modifier onlyBy(address _account) {
        require(msg.sender == _account);
        _;
    }
    
    function () payable fundingOpen() { 

        require(msg.sender != owner);
        
        uint256 _value = msg.value / 1 finney;

        require(_value >= minContrib); 
        
        require(balances[owner] >= (_value - frozenSupply) && _value > 0); 
        
        balances[owner] -= _value;
        balances[msg.sender] += _value;
        Transfer(owner, msg.sender, _value);
        
    }
    
    function RGXToken (
                       string _name,
                       string _symbol,
                       uint256 _initialAmount,
                       uint _fundingStart,
                       uint8 _discountMultiplier
                       ) {
        name = _name;
        symbol = _symbol;
        owner = msg.sender;
        balances[msg.sender] = _initialAmount;                
        totalSupply = _initialAmount;                         
        fundingStart = _fundingStart;                         
        discountMultiplier = _discountMultiplier;
    }
    
    function isFundingOpen() constant returns (bool yes) {
        return (now >= fundingStart);
    }
    
    function freezeSupply(uint256 _value) onlyBy(owner) {
        require(balances[owner] >= _value);
        frozenSupply = _value;
    }
    
    function setMinimum(uint256 _value) onlyBy(owner) {
        minContrib = _value;
    }
    
    function timeFundingStart(uint _fundingStart) onlyBy(owner) {
        fundingStart = _fundingStart;
    }

    function withdraw() onlyBy(owner) {
        msg.sender.transfer(this.balance);
    }
    
    function kill() onlyBy(owner) {
        selfdestruct(owner);
    }

}