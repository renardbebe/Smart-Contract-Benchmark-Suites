 

pragma solidity ^0.4.13;
  
  
  
  
  
  
  
  
 contract ERC20 {
      
     function totalSupply() constant returns (uint256 totalSupply);
  
      
     function balanceOf(address _owner) constant returns (uint256 balance);
  
      
     function transfer(address _to, uint256 _value) returns (bool success);
  
      
     function transferFrom(address _from, address _to, uint256 _value) returns (bool success);
  
      
      
      
     function approve(address _spender, uint256 _value) returns (bool success);
  
      
     function allowance(address _owner, address _spender) constant returns (uint256 remaining);
  
      
     event Transfer(address indexed _from, address indexed _to, uint256 _value);
  
      
     event Approval(address indexed _owner, address indexed _spender, uint256 _value);
 }
  
 contract Owned {
    address public owner;

    function Owned() {
        owner = msg.sender;
    }

    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }

    function transferOwnership(address newOwner) onlyOwner {
        owner = newOwner;
    }
}
  
 contract MidnightCoin is ERC20, Owned {
     string public constant symbol = "MNC";
     string public constant name = "Midnight Coin";
     uint8 public constant decimals = 18;
     uint256 _totalSupply = 100000000000000000000;
     uint public constant FREEZE_PERIOD = 1 years;
     uint public crowdSaleStartTimestamp;
     string public lastLoveLetter = "";
     
      
     mapping(address => uint256) balances;
  
      
     mapping(address => mapping (address => uint256)) allowed;
     

      
     function MidnightCoin() {
         owner = msg.sender;
         balances[owner] = 1000000000000000000;
         crowdSaleStartTimestamp = now + 7 days;
     }
  
     function totalSupply() constant returns (uint256 totalSupply) {
         totalSupply = _totalSupply;
     }
  
      
     function balanceOf(address _owner) constant returns (uint256 balance) {
         return balances[_owner];
     }
  
      
     function transfer(address _to, uint256 _amount) returns (bool success) {
         if (balances[msg.sender] >= _amount 
             && _amount > 0
             && balances[_to] + _amount > balances[_to]) {
             balances[msg.sender] -= _amount;
             balances[_to] += _amount;
             Transfer(msg.sender, _to, _amount);
             return true;
         } else {
             return false;
         }
     }
  
      
      
      
      
      
      
     function transferFrom(
     address _from,
         address _to,
         uint256 _amount
     ) returns (bool success) {
         if (balances[_from] >= _amount
             && allowed[_from][msg.sender] >= _amount
             && _amount > 0
             && balances[_to] + _amount > balances[_to]) {
             balances[_from] -= _amount;
             allowed[_from][msg.sender] -= _amount;
             balances[_to] += _amount;
             Transfer(_from, _to, _amount);
             return true;
         } else {
             return false;
         }
     }
  
      
      
     function approve(address _spender, uint256 _amount) returns (bool success) {
         allowed[msg.sender][_spender] = _amount;
         Approval(msg.sender, _spender, _amount);
         return true;
     }
  
     function allowance(address _owner, address _spender) constant returns (uint256 remaining) {
         return allowed[_owner][_spender];
     }
     
      
     
     function kill() onlyOwner {
        selfdestruct(owner);
     }

     function withdraw() public onlyOwner {
        require( _totalSupply == 0 );
        owner.transfer(this.balance);
     }
  
     function buyMNC(string _loveletter) payable{
        require (now > crowdSaleStartTimestamp);
        require( _totalSupply >= msg.value);
        balances[msg.sender] += msg.value;
        _totalSupply -= msg.value;
        lastLoveLetter = _loveletter;
     }
     
     function sellMNC(uint256 _amount) {
        require (now > crowdSaleStartTimestamp + FREEZE_PERIOD);
        require( balances[msg.sender] >= _amount);
        balances[msg.sender] -= _amount;
        _totalSupply += _amount;
        msg.sender.transfer(_amount);
     }
     
     function() payable{
        buyMNC("Hi! I am anonymous holder");
     }
     
 }