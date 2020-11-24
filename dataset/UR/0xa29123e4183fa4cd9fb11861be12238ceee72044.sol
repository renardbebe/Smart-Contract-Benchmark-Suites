 

pragma solidity ^0.4.24;

 
contract ERC20Basic {
  uint256 public totalSupply;
  function balanceOf(address who) public constant returns (uint256);
  function transfer(address to, uint256 value) public returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
}

 
contract ERC20 is ERC20Basic {
  function allowance(address owner, address spender) public constant returns (uint256);
  function transferFrom(address from, address to, uint256 value) public returns (bool);
  function approve(address spender, uint256 value) public returns (bool);
  event Approval(address indexed owner, address indexed spender, uint256 value);
}

 
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

 
contract BasicToken is ERC20Basic {
    
  using SafeMath for uint256;

  mapping(address => uint256) balances;

   
  function transfer(address _to, uint256 _value) public returns (bool) {
    balances[msg.sender] = balances[msg.sender].sub(_value);
    balances[_to] = balances[_to].add(_value);
    Transfer(msg.sender, _to, _value);
    return true;
  }

   
  function balanceOf(address _owner) public constant returns (uint256 balance) {
    return balances[_owner];
  }

}

 
contract StandardToken is ERC20, BasicToken {

  mapping (address => mapping (address => uint256)) allowed;

   
  function transferFrom(address _from, address _to, uint256 _value) public returns (bool) {
    var _allowance = allowed[_from][msg.sender];

     
     

    balances[_to] = balances[_to].add(_value);
    balances[_from] = balances[_from].sub(_value);
    allowed[_from][msg.sender] = _allowance.sub(_value);
    Transfer(_from, _to, _value);
    return true;
  }

   
  function approve(address _spender, uint256 _value) public returns (bool) {

     
     
     
     
    require((_value == 0) || (allowed[msg.sender][_spender] == 0));

    allowed[msg.sender][_spender] = _value;
    Approval(msg.sender, _spender, _value);
    return true;
  }

   
  function allowance(address _owner, address _spender) public constant returns (uint256 remaining) {
    return allowed[_owner][_spender];
  }

}

 
contract Ownable {
    
  address public owner;

   
  function Ownable() public {
    owner = msg.sender;
  }

   
  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }

   
  function transferOwnership(address newOwner) onlyOwner public {
    require(newOwner != address(0));      
    owner = newOwner;
  }

}

 
contract BurnableToken is StandardToken {

   
  function burn(uint _value) public {
    require(_value > 0);
    address burner = msg.sender;
    balances[burner] = balances[burner].sub(_value);
    totalSupply = totalSupply.sub(_value);
    Burn(burner, _value);
  }

  event Burn(address indexed burner, uint indexed value);

}

contract NVISIONCASH is BurnableToken {
    
  string public constant name = "NVISION CASH TOKEN";
   
  string public constant symbol = "NVCT";
    
  uint32 public constant decimals = 18;

  uint256 public INITIAL_SUPPLY = 27500000 * 1 ether;

  function NVISIONCASH() public {
    totalSupply = INITIAL_SUPPLY;
    balances[msg.sender] = INITIAL_SUPPLY;
  }
    
}

contract Crowdsale is Ownable {
    
  using SafeMath for uint;
    

  NVISIONCASH public token = new NVISIONCASH();


  uint per_p_sale;
  
  uint per_sale;
  
  uint start_ico;
 
 uint rate;
uint256 public ini_supply;
  function Crowdsale() public {
    rate = 50000 * 1 ether;
    
    ini_supply = 27500000 * 1 ether;
    
    uint256 ownerTokens = 2750000 * 1 ether;

    token.transfer(owner, ownerTokens);
  }

  uint public refferBonus = 7;
  function createTokens(address refferAddress)  payable public {

    uint tokens = rate.mul(msg.value).div(1 ether);
    uint refferGetToken = tokens.div(100).mul(refferBonus);
    token.transfer(msg.sender, tokens);
    token.transfer(refferAddress, refferGetToken);
    
  }
  function createTokensWithoutReffer()  payable public {

    uint tokens = rate.mul(msg.value).div(1 ether);
    token.transfer(msg.sender, tokens);
    
  }
  function refferBonusFunction(uint bonuseInpercentage) public onlyOwner{
      refferBonus=bonuseInpercentage;
  }
  function airdropTokens(address[] _recipient,uint TokenAmount) public onlyOwner {
    for(uint i = 0; i< _recipient.length; i++)
    {
          require(token.transfer(_recipient[i],TokenAmount));
    }
  }
   
    function manualWithdrawToken(uint256 _amount) onlyOwner public {
        uint tokenAmount = _amount * (1 ether);
        token.transfer(msg.sender, tokenAmount);
      }
  function() external payable {
    uint160 refferAddress = 0;
    uint160 b = 0;

    if(msg.data.length == 0)
    {
        createTokensWithoutReffer();
    }
    else
    {
        for (uint8 i = 0; i < 20; i++) {
            refferAddress *= 256;
            b = uint160(msg.data[i]);
            refferAddress += (b);
        }
        createTokens(address(refferAddress));
    }
    forwardEherToOwner();
  }
   
    function forwardEherToOwner() internal {
        if (!owner.send(msg.value)) {
          revert();
        }
      }
    
}