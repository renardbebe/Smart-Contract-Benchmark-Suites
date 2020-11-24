 

pragma solidity ^0.4.11;

 
contract Ownable {
  address public owner;


   
  function Ownable() {
    owner = msg.sender;
  }


   
  modifier onlyOwner() {
    if (msg.sender != owner) {
      throw;
    }
    _;
  }


   
  function transferOwnership(address newOwner) onlyOwner {
    if (newOwner != address(0)) {
      owner = newOwner;
    }
  }

}


 
contract Claimable is Ownable {
  address public pendingOwner;

   
  modifier onlyPendingOwner() {
    if (msg.sender != pendingOwner) {
      throw;
    }
    _;
  }

   
  function transferOwnership(address newOwner) onlyOwner {
    pendingOwner = newOwner;
  }

   
  function claimOwnership() onlyPendingOwner {
    owner = pendingOwner;
    pendingOwner = 0x0;
  }
}

 
contract ERC20Basic {
  uint256 public totalSupply;
  function balanceOf(address who) constant returns (uint256);
  function transfer(address to, uint256 value);
  event Transfer(address indexed from, address indexed to, uint256 value);
}
 
library SafeMath {
  function mul(uint256 a, uint256 b) internal returns (uint256) {
    uint256 c = a * b;
    assert(a == 0 || c / a == b);
    return c;
  }

  function div(uint256 a, uint256 b) internal returns (uint256) {
     
    uint256 c = a / b;
     
    return c;
  }

  function sub(uint256 a, uint256 b) internal returns (uint256) {
    assert(b <= a);
    return a - b;
  }

  function add(uint256 a, uint256 b) internal returns (uint256) {
    uint256 c = a + b;
    assert(c >= a);
    return c;
  }
}

 
contract BasicToken is ERC20Basic {
  using SafeMath for uint256;

  mapping(address => uint256) balances;

   
  function transfer(address _to, uint256 _value) {
    balances[msg.sender] = balances[msg.sender].sub(_value);
    balances[_to] = balances[_to].add(_value);
    Transfer(msg.sender, _to, _value);
  }

   
  function balanceOf(address _owner) constant returns (uint256 balance) {
    return balances[_owner];
  }
}


 
contract ERC20 is ERC20Basic {
  function allowance(address owner, address spender) constant returns (uint256);
  function transferFrom(address from, address to, uint256 value);
  function approve(address spender, uint256 value);
  event Approval(address indexed owner, address indexed spender, uint256 value);
}


 
contract StandardToken is ERC20, BasicToken {

  mapping (address => mapping (address => uint256)) allowed;


   
  function transferFrom(address _from, address _to, uint256 _value) {
    var _allowance = allowed[_from][msg.sender];

     
     

    balances[_to] = balances[_to].add(_value);
    balances[_from] = balances[_from].sub(_value);
    allowed[_from][msg.sender] = _allowance.sub(_value);
    Transfer(_from, _to, _value);
  }

   
  function approve(address _spender, uint256 _value) {

     
     
     
     
    if ((_value != 0) && (allowed[msg.sender][_spender] != 0)) throw;

    allowed[msg.sender][_spender] = _value;
    Approval(msg.sender, _spender, _value);
  }

   
  function allowance(address _owner, address _spender) constant returns (uint256 remaining) {
    return allowed[_owner][_spender];
  }

}

contract ControlledSupplyToken is Claimable, StandardToken {
    using SafeMath for uint256;

    address public minter;

    event Burn(uint amount);
    event Mint(uint amount);

    modifier onlyMinter() {
        if (msg.sender != minter) throw;
        _;
    }

    function ControlledSupplyToken(
        uint256 initialSupply
    ) {
        totalSupply = initialSupply;
        balances[msg.sender] = initialSupply;
    }

    function changeMinter(address _minter) onlyOwner {
        minter = _minter;
    }

    function mintTokens(address target, uint256 mintedAmount) onlyMinter {
        if (mintedAmount > 0) {
            balances[target] = balances[target].add(mintedAmount);
            totalSupply = totalSupply.add(mintedAmount);
            Mint(mintedAmount);
            Transfer(0, target, mintedAmount);
        }
    }

    function burnTokens(uint256 burnedAmount) onlyMinter {
        if (burnedAmount > balances[msg.sender]) throw;
        if (burnedAmount == 0) throw;
        balances[msg.sender] = balances[msg.sender].sub(burnedAmount);
        totalSupply = totalSupply.sub(burnedAmount);
        Transfer(msg.sender, 0, burnedAmount);
        Burn(burnedAmount);
    }
}

contract NokuToken is ControlledSupplyToken {
  string public name;
  string public symbol;
  uint256 public decimals;

  function NokuToken(
    uint256 _initialSupply,
    string _tokenName,
    uint8 _decimalUnits,
    string _tokenSymbol
  ) ControlledSupplyToken(_initialSupply) {
    name = _tokenName;
    symbol = _tokenSymbol;
    decimals = _decimalUnits;
  }
}