 

pragma solidity ^0.4.18;

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

contract ERC20Basic {
  function totalSupply() public view returns (uint256);
  function balanceOf(address who) public view returns (uint256);
  function transfer(address to, uint256 value) public returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
}

contract ERC20 is ERC20Basic {
  function allowance(address owner, address spender) public view returns (uint256);
  function transferFrom(address from, address to, uint256 value) public returns (bool);
  function approve(address spender, uint256 value) public returns (bool);
  event Approval(address indexed owner, address indexed spender, uint256 value);
}

contract Ownable {
  address public owner;


  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);


   
  function Ownable() public {
    owner = msg.sender;
  }

   
  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }

   
  function transferOwnership(address newOwner) public onlyOwner {
    require(newOwner != address(0));
    OwnershipTransferred(owner, newOwner);
    owner = newOwner;
  }

}

contract BasicToken is ERC20Basic {
  using SafeMath for uint256;

  mapping(address => uint256) balances;

  uint256 totalSupply_;

   
  function totalSupply() public view returns (uint256) {
    return totalSupply_;
  }

   
  function transfer(address _to, uint256 _value) public returns (bool) {
    require(_to != address(0));
    require(_value <= balances[msg.sender]);

     
    balances[msg.sender] = balances[msg.sender].sub(_value);
    balances[_to] = balances[_to].add(_value);
    Transfer(msg.sender, _to, _value);
    return true;
  }

   
  function balanceOf(address _owner) public view returns (uint256 balance) {
    return balances[_owner];
  }

}

contract StandardToken is ERC20, BasicToken {

  mapping (address => mapping (address => uint256)) internal allowed;


   
  function transferFrom(address _from, address _to, uint256 _value) public returns (bool) {
    require(_to != address(0));
    require(_value <= balances[_from]);
    require(_value <= allowed[_from][msg.sender]);

    balances[_from] = balances[_from].sub(_value);
    balances[_to] = balances[_to].add(_value);
    allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
    Transfer(_from, _to, _value);
    return true;
  }

   
  function approve(address _spender, uint256 _value) public returns (bool) {
    allowed[msg.sender][_spender] = _value;
    Approval(msg.sender, _spender, _value);
    return true;
  }

   
  function allowance(address _owner, address _spender) public view returns (uint256) {
    return allowed[_owner][_spender];
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

}

contract ThemisToken is Ownable, StandardToken {

  string public constant name = "Themis Token";
  string public constant symbol = "THM";
  uint8 public constant decimals = 18;

  uint256 public angelSupply;                             
  uint256 public earlyBirdsSupply;                        
  uint256 public foundationSupply;                        
  uint256 public teamSupply;                              
  uint256 public marketingSupply;                         
  uint256 public optionSupply;                            

  address public angelAddress;                            
  address public earlyBirdsAddress;                       
  address public teamAddress;                             
  address public foundationAddress;                       
  address public marketingAddress;                        
  address public optionAddress;                           

   
  function ThemisToken() public {
    totalSupply_        =  3000000000 * 1e18;
    angelSupply         =   300000000 * 1e18;              
    earlyBirdsSupply    =   600000000 * 1e18;              
    teamSupply          =   450000000 * 1e18;              
    foundationSupply    =   750000000 * 1e18;              
    marketingSupply     =   600000000 * 1e18;              
    optionSupply        =   300000000 * 1e18;              

    angelAddress         = 0xD58aE13Eb1e8CDb92088709A6868d32C993FAd74;   
    earlyBirdsAddress    = 0xac9EaB9C4c403441fb8592529A3cE534E68246ED;   
    teamAddress          = 0x4d06220df2BC77C3E47b72611AA79915611Ed23B;   
    foundationAddress    = 0xDa2AB3712A490cC6Df661E3ae398BeA24434349F;   
    marketingAddress     = 0x9f160Ed0F3B8d5180Eb5cC97c43CF7Fe1efFE02C;   
    optionAddress        = 0x47343c223F3605aC541a8eC61e5Fd41EBDdEc9d1;   

    releaseAngelTokens();
    releaseEarlyBirdsTokens();
    releaseFoundationTokens();
    releaseTeamTokens();
    releaseMarketingTokens();
    releaseOptionTokens();

     
     
  }

   
   
   
  function releaseAngelTokens() internal returns(bool success) {
      require(angelSupply > 0);
      balances[angelAddress] = angelSupply;
      Transfer(0x0, angelAddress, angelSupply);
      angelSupply = 0;
      return true;
  }

   
   
   
  function releaseEarlyBirdsTokens() internal returns(bool success) {
      require(earlyBirdsSupply > 0);
      balances[earlyBirdsAddress] = earlyBirdsSupply;
      Transfer(0x0, earlyBirdsAddress, earlyBirdsSupply);
      earlyBirdsSupply = 0;
      return true;
  }

   
   
   
  function releaseTeamTokens() internal returns(bool success) {
    require(teamSupply > 0);
    balances[teamAddress] = teamSupply;
    Transfer(0x0, teamAddress, teamSupply);
    teamSupply = 0;
    return true;
  }

   
   
   
  function releaseFoundationTokens() internal returns(bool success) {
    require(foundationSupply > 0);
    balances[foundationAddress] = foundationSupply;
    Transfer(0x0, foundationAddress, foundationSupply);
    foundationSupply = 0;
    return true;
  }

   
   
   
  function releaseMarketingTokens() internal returns(bool success) {
    require(marketingSupply > 0);
    balances[marketingAddress] = marketingSupply;
    Transfer(0x0, marketingAddress, marketingSupply);
    marketingSupply = 0;
    return true;
  }

   
   
   
  function releaseOptionTokens() internal returns(bool success) {
      require(optionSupply > 0);
      balances[optionAddress] = optionSupply;
      Transfer(0x0, optionAddress, optionSupply);
      optionSupply = 0;
      return true;
  }

}