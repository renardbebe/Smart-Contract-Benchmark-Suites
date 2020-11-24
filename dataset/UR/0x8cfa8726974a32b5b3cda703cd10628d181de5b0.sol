 

pragma solidity 0.5.11;  


 
 
 
 
library SafeMath {
   
  function add(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    require(c >= a, "SafeMath: addition overflow");

    return c;
  }

   
  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    require(b <= a, "SafeMath: subtraction overflow");
    uint256 c = a - b;

    return c;
  }

   
  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
     
     
     
    if (a == 0) {
      return 0;
    }

    uint256 c = a * b;
    require(c / a == b, "SafeMath: multiplication overflow");

    return c;
  }

   
  function div(uint256 a, uint256 b) internal pure returns (uint256) {
     
    require(b > 0, "SafeMath: division by zero");
    uint256 c = a / b;
     

    return c;
  }

   
  function mod(uint256 a, uint256 b) internal pure returns (uint256) {
    require(b != 0, "SafeMath: modulo by zero");
    return a % b;
  }
}

 
 
 

 
contract owned {
  address payable public owner;

    constructor () public {
    owner = msg.sender;
  }

  modifier onlyOwner {
    require(msg.sender == owner, 'not the owner');
    _;
  }

  function transferOwnership(address payable newOwner) public onlyOwner {
    owner = newOwner;
  }
}

 
 
 

contract SETIcoin is owned {
   
  using SafeMath for uint256;
  string public name = "South East Trading Investment";
  string public symbol = "SETI";
  uint256 public decimals = 18;  
  uint256 public totalSupply = 600000000 * (10 ** decimals) ;  
  bool public safeguard;  


   
  mapping (address => uint256) public balanceOf;
  mapping (address => mapping (address => uint256)) public allowance;
  mapping (address => bool) public frozenAccount;


   
  event FrozenAccounts(address target, bool frozen);

   
  event Transfer(address indexed from, address indexed to, uint256 value);

   
  event Burn(address indexed from, uint256 value);

   
  event Approval(address indexed tokenOwner, address indexed spender, uint256 indexed tokenAmount);


   
  constructor () public {

     
    balanceOf[owner] = totalSupply;

    emit Transfer(address(0), msg.sender, totalSupply);

  }

   
  function _transfer(address _from, address _to, uint _value) internal {
    require(!safeguard, 'safeguard is active');
     
    require(_to != address(0x0), 'zero address');

    uint previousBalances = balanceOf[_from].add(balanceOf[_to]);
    balanceOf[_from] = balanceOf[_from].sub(_value);
    balanceOf[_to] = balanceOf[_to].add(_value);

    assert(balanceOf[_from].add(balanceOf[_to]) == previousBalances);

    emit Transfer(_from, _to, _value);
  }

   
  function transfer(address _to, uint256 _value) public returns (bool success) {
    _transfer(msg.sender, _to, _value);
    return true;
  }

   
  function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {
    allowance[_from][msg.sender] = allowance[_from][msg.sender].sub(_value);
    _transfer(_from, _to, _value);
    return true;
  }

   
  function approve(address _spender, uint256 _value) public returns (bool success) {
    require(!safeguard, 'safeguard is active');
    allowance[msg.sender][_spender] = _value;
    emit Approval(msg.sender, _spender, _value);
    return true;
  }


   
  function burn(uint256 _value) public returns (bool success) {
    require(!safeguard, 'safeguard is active');
    balanceOf[msg.sender] = balanceOf[msg.sender].sub(_value);
    totalSupply = totalSupply.sub(_value);
    emit Burn(msg.sender, _value);
    emit Transfer(msg.sender, address(0), _value);
    return true;
  }


   
   
   
  function freezeAccount(address target, bool freeze) public onlyOwner {
    frozenAccount[target] = freeze;
    emit FrozenAccounts(target, freeze);
  }



   
  function manualWithdrawEther() public onlyOwner {
    address(owner).transfer(address(this).balance);
  }

  function manualWithdrawTokens(uint256 tokenAmount) public onlyOwner {
     
    _transfer(address(this), owner, tokenAmount);
  }



   
  function changeSafeguardStatus() public onlyOwner {
    if (safeguard == false) {
      safeguard = true;
    }
    else {
      safeguard = false;
    }
  }

   
   
   

   
  function airdrop(address[] memory recipients, uint[] memory tokenAmount) public onlyOwner {
    uint256 addressCount = recipients.length;
    require(addressCount <= 150, 'address count over 150');
    for(uint i = 0; i < addressCount; i++) {
       
      _transfer(address(this), recipients[i], tokenAmount[i]);
    }
  }
}