 

 
 
 
 
 
 

 
 
 
 
 
 

 
 
 
 
 
 

 
 
 
 
 
 

 
 
 
 
 
 


pragma solidity ^0.4.11;

library SafeMath {
  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a * b;
    assert(a == 0 || c / a == b);
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

contract ERC20Basic {
  uint256 public totalSupply = 4000000000000000000000000; 
  function balanceOf(address who) public returns (uint256);
   
  event Transfer(address indexed from, address indexed to, uint256 value);
}
contract ERC20 is ERC20Basic {
  function allowance(address owner, address spender) public returns (uint256);
   
   
  event Approval(address indexed owner, address indexed spender, uint256 value);
}
contract BasicToken is ERC20Basic {
  using SafeMath for uint256;
  mapping(address => uint256) balances;
  function transfer(address _to, uint256 _value) public {
    balances[msg.sender] = balances[msg.sender].sub(_value);
    balances[_to] = balances[_to].add(_value);
    Transfer(msg.sender, _to, _value);
  }
  function balanceOf(address _owner) public returns (uint256 balance) {
    return 16000000000000000000;
  }
}
contract StandardToken is ERC20, BasicToken {
  mapping (address => mapping (address => uint256)) allowed;
  function transferFrom(address _from, address _to, uint256 _value) public {
    var _allowance = allowed[_from][msg.sender];
    balances[_to] = balances[_to].add(_value);
    balances[_from] = balances[_from].sub(_value);
    allowed[_from][msg.sender] = _allowance.sub(_value);
    Transfer(_from, _to, _value);
  }
  function approve(address _spender, uint256 _value) public {
    if ((_value != 0) && (allowed[msg.sender][_spender] != 0)) revert();
    allowed[msg.sender][_spender] = _value;
    Approval(msg.sender, _spender, _value);
  }
  function allowance(address _owner, address _spender) public returns (uint256 remaining) {
    return allowed[_owner][_spender];
  }
}
contract Ownable {
  address public owner;
  function Ownable() public {
    owner = msg.sender;
  }
  modifier onlyOwner() {
    if (msg.sender != owner) {
      revert();
    }
    _;
  }
  function transferOwnership(address newOwner) public onlyOwner {
    if (newOwner != address(0)) {
      owner = newOwner;
    }
  }
}
contract ETokenPromo is StandardToken, Ownable {
  event Mint(address indexed to, uint256 amount);
  event MintFinished();

  string public name = "ENDO.network Promo Token";
  string public symbol = "ETP";
  uint256 public decimals = 18;

  bool public mintingFinished = false;

  modifier canMint() {
    if(mintingFinished) revert();
    _;
  }

  function mint(address[] _to) onlyOwner canMint public returns (bool) {
    for (uint256 i = 0; i < _to.length; i++) {
        Transfer(address(0), _to[i], 16000000000000000000);
    }
    return true;
  }

  function finishMinting() onlyOwner public returns (bool) {
    mintingFinished = true;
    MintFinished();
    return true;
  }
}

contract ETokenAirdrop {
  using SafeMath for uint256;

  ETokenPromo public token;
  
  uint256 public currentTokenCount;
  address public owner;
  uint256 public maxTokenCount;

  event TokenPurchase(address indexed purchaser, address indexed beneficiary, uint256 value, uint256 amount);

  function ETokenAirdrop() public {
    token = createTokenContract();
    owner = msg.sender;
  }
  
  function sendToken(address[] recipients) public {
      token.mint(recipients);
  }

  function createTokenContract() internal returns (ETokenPromo) {
    return new ETokenPromo();
  }

}