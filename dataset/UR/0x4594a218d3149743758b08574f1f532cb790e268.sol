 

pragma  solidity ^0.4.24;

library SafeMath {

   
  function mul(uint256 a, uint256 b) internal pure returns (uint256 c) {
     
     
     
    if (a == 0) {
      return 0;
    }

    c = a * b;
    assert(c / a == b);
    return c;
  }

   
  function div(uint256 a, uint256 b) internal pure returns (uint256) {
     
     
     
    return a / b;
  }

   
  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    assert(b <= a);
    return a - b;
  }

   
  function add(uint256 a, uint256 b) internal pure returns (uint256 c) {
    c = a + b;
    assert(c >= a);
    return c;
  }
}

contract Ownable{
  address public owner;
  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

   
  constructor() public {
      owner = msg.sender;
  } 
    
   
  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }
  
     
  function transferOwnership(address newOwner) onlyOwner public {
    require(newOwner != address(0));
    emit OwnershipTransferred(owner, newOwner);
    owner = newOwner;
  }
    
}

contract VTEXP is Ownable {
  
  event Mint(address indexed to, uint256 amount);
  event MintFinished();

  event Transfer(address indexed from, address indexed to, uint256 value);
  using SafeMath for uint256;
  string public constant name = "VTEX Promo Token";
  string public constant symbol = "VTEXP";
  uint8 public constant decimals = 5;   
  bool public mintingFinished = false;
  uint256 public totalSupply;
  mapping(address => uint256) balances;

  modifier canMint() {
    require(!mintingFinished);
    _;
  }
  
   
  function mint(address _to, uint256 _amount) onlyOwner canMint public returns (bool) {

    totalSupply = totalSupply.add(_amount);
    require(totalSupply <= 10000000000000);
    balances[_to] = balances[_to].add(_amount);
    emit  Mint(_to, _amount);
    emit Transfer(address(0), _to, _amount);

    return true;
  }

   
  function finishMinting() onlyOwner canMint public returns (bool) {
    mintingFinished = true;
    emit MintFinished();
    return true;
  }
 
  function transfer(address _to, uint256 _value) public returns (bool) {
    require(_to != address(0));
    require(_value <= totalSupply);

      balances[_to] = balances[_to].add(_value);
      totalSupply = totalSupply.sub(_value);
      balances[msg.sender] = balances[msg.sender].sub(_value);
      emit Transfer(msg.sender, _to, _value);
      return true;
  }

  function balanceOf(address _owner) public constant returns (uint256 balance) {
    return balances[_owner];
  }

  function balanceEth(address _owner) public constant returns (uint256 balance) {
    return _owner.balance;
  }
    

}