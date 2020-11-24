 

 
pragma solidity ^0.5.0;

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
     
    function balanceOf(address _owner) public view returns(uint256 balance);
     
    function transfer(address _to,uint256 _value) public returns(bool success);
    function transferFrom(address _from,address _to,uint256 _value)public returns(bool success);
    function approve(address _spender,uint256 _value)public returns(bool success);
    function allowance(address _owner, address _spender) public view returns (uint256 remaining);
    
    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
}
contract TFOR is Token{
    event Redeem(uint256 _amount);
    event AddedBlackList(address _addr);
    event RemovedBlackList(address _addr);
     
    using SafeMath for uint256;
     
    string public name;
     
    uint8 public decimals;
    
    string public symbol;
     
    address public owner;
     
    bool public deprecated;
     
    mapping(address=>uint256) public balances;
    mapping(address=>mapping (address=>uint256)) allowed;
    
    mapping (address => bool) public isBlackListed;
    
    constructor(address _owner)public payable{
        name="TFOR";
        owner=_owner;
        decimals=16;
        totalSupply=430000000* 10 ** uint256(decimals); 
        balances[owner]=totalSupply;
        symbol="TFOR";
        deprecated=false;
         
    }
    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }
    function transferOwnership(address _newOwner)onlyOwner public {
        if (_newOwner != address(0)) {
            owner = _newOwner;
        }
    }
    function addBlackList (address _evilUser) public onlyOwner {
        isBlackListed[_evilUser] = true;
        emit AddedBlackList(_evilUser);
    }

    function removeBlackList (address _clearedUser) public onlyOwner {
        isBlackListed[_clearedUser] = false;
        emit RemovedBlackList(_clearedUser);
    }

    function redeem(uint amount) public onlyOwner {
        require(totalSupply >= amount);
        require(balances[owner] >= amount);
        totalSupply -= amount;
        balances[owner] -= amount;
        emit Redeem(amount);
    }
    
    function pause()public onlyOwner{
        deprecated=true;
    }
    function unpause()public onlyOwner{
        deprecated=false;
    }
     
    function transfer(address _to,uint256 _value) public returns(bool success){
        require(deprecated==false&&isBlackListed[msg.sender]==false);
         
         require(balances[msg.sender]>=_value&&balances[_to]+_value>balances[_to]);
          
         require(msg.sender!=address(0));
         balances[msg.sender]=balances[msg.sender].sub(_value);
         balances[_to]=balances[_to].add(_value);
          
         emit Transfer(msg.sender, _to, _value);
         return true;
    }
     
    function transferFrom(address _from,address _to,uint256 _value) public returns(bool){
        require(deprecated==false&&isBlackListed[msg.sender]==false);
        require(balances[_from] >= _value && allowed[_from][msg.sender] >= _value);
        balances[_to]=balances[_to].add(_value);
        balances[_from]=balances[_from].sub(_value);
        allowed[_from][msg.sender]=allowed[_from][msg.sender].sub(_value);
        emit Transfer(_from,_to,_value);
        return true;
    }
    function balanceOf(address _owner)public view returns(uint256){
           return balances[_owner];
    }
    function approve(address _spender,uint256 _value) public returns(bool success){
        require(deprecated==false&&isBlackListed[msg.sender]==false);
        allowed[msg.sender][_spender]=_value;
         
        emit Approval(msg.sender, _spender, _value);
        return true;
    }
     
    function allowance(address _owner, address _spender) public view returns (uint256 remaining) {
        return allowed[_owner][_spender]; 
    }
}