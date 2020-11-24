 

pragma solidity 0.4.19;

 

 
contract Ownable {
  address public owner;
  address public creator;


  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);


   
  function Ownable() public {
    owner = msg.sender;
    creator = msg.sender;
  }


   
  modifier onlyOwner() {
    require(msg.sender == owner || msg.sender == creator);
    _;
  }


   
  function transferOwnership(address newOwner) public onlyOwner {
    require(newOwner != address(0));
    OwnershipTransferred(owner, newOwner);
    owner = newOwner;
  }

}


 

 
contract SafeMath {
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

contract ERC20{
  uint public totalSupply;
  function balanceOf(address who) constant public returns (uint);
  function allowance(address owner, address spender) constant public returns (uint);

  function transfer(address to, uint value) public returns (bool ok);
  function transferFrom(address from, address to, uint value) public returns (bool ok);
  function approve(address spender, uint value) public returns (bool ok);
  event Transfer(address indexed from, address indexed to, uint value);
  event Approval(address indexed owner, address indexed spender, uint value);
}

contract TokenSpender {
    function receiveApproval(address _from, uint256 _value, address _token, bytes _extraData) public;
}

contract HYD is ERC20, SafeMath, Ownable{
    string public name;      
    string public symbol;
    uint8 public decimals;    
    uint public initialSupply;
    uint public totalSupply;
    bool public locked;

    mapping(address => uint) balances;
    mapping (address => mapping (address => uint)) allowed;

   
    modifier onlyUnlocked() {
        require(msg.sender == owner || msg.sender == creator || locked==false);
        _;
    }

   

  function HYD() public{
    locked = true;
    initialSupply = 50000000000000;
    totalSupply = initialSupply;
    balances[msg.sender] = initialSupply; 
    name = 'Hyde & Co. Token';         
    symbol = 'HYD';                        
    decimals = 6;                         
  }

  function unlock() public onlyOwner {
    locked = false;
  }

  function burn(uint256 _value) public onlyOwner returns (bool){
    balances[msg.sender] = sub(balances[msg.sender], _value) ;
    totalSupply = sub(totalSupply, _value);
    Transfer(msg.sender, 0x0, _value);
    return true;
  }

  function transfer(address _to, uint _value) public onlyUnlocked returns (bool) {
    uint fromBalance = balances[msg.sender];
    require((_value > 0) && (_value <= fromBalance));
    balances[msg.sender] = sub(balances[msg.sender], _value);
    balances[_to] = add(balances[_to], _value);
    Transfer(msg.sender, _to, _value);
    return true;
  }

  function transferFrom(address _from, address _to, uint _value) public onlyUnlocked returns (bool) {
    uint _allowance = allowed[_from][msg.sender];
    uint fromBalance = balances[_from];
    require(_value <= _allowance && _value <= fromBalance && _value > 0);
    balances[_to] = add(balances[_to], _value);
    balances[_from] = sub(balances[_from], _value);
    allowed[_from][msg.sender] = sub(_allowance, _value);
    Transfer(_from, _to, _value);
    return true;
  }

  function balanceOf(address _owner) public constant returns (uint balance) {
    return balances[_owner];
  }

  function approve(address _spender, uint _value) public returns (bool) {
    allowed[msg.sender][_spender] = _value;
    Approval(msg.sender, _spender, _value);
    return true;
  }

     
  function approveAndCall(address _spender, uint256 _value, bytes _extraData) public {    
      TokenSpender spender = TokenSpender(_spender);
      if (approve(_spender, _value)) {
          spender.receiveApproval(msg.sender, _value, this, _extraData);
      }
  }

  function allowance(address _owner, address _spender) public constant returns (uint remaining) {
    return allowed[_owner][_spender];
  }
  
}