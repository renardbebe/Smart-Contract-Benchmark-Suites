 

pragma solidity 0.4.18;

 
contract ERC20Basic {
  uint256 public totalSupply;
  function balanceOf(address who) view public returns (uint256);
  function transfer(address to, uint256 value) public returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
}

 
contract ERC20 is ERC20Basic {
  function allowance(address owner, address spender) view public returns (uint256);
  function transferFrom(address from, address to, uint256 value) public returns (bool);
  function approve(address spender, uint256 value) public returns (bool);
  event Approval(address indexed owner, address indexed spender, uint256 value);
}

 
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

 
contract BasicToken is ERC20Basic {
    
  using SafeMath for uint256;

  mapping(address => uint256) balances;
   
  uint public constant timeFreezeTeamTokens = 1540944000;
  
  address public walletTeam = 0x7eF1ac89B028A9Bc20Ce418c1e6973F4c7977eB0;

  modifier onlyPayloadSize(uint size) {
       assert(msg.data.length >= size + 4);
       _;
   }
   
   modifier canTransfer() {
       if(msg.sender == walletTeam){
          require(now > timeFreezeTeamTokens); 
       }
        _;
   }



   
  function transfer(address _to, uint256 _value)canTransfer onlyPayloadSize(2 * 32) public returns (bool) {
    balances[msg.sender] = balances[msg.sender].sub(_value);
    balances[_to] = balances[_to].add(_value);
    Transfer(msg.sender, _to, _value);
    return true;
  }

   
  function balanceOf(address _owner) view public returns (uint256 balance) {
    return balances[_owner];
  }

}

 
contract StandardToken is ERC20, BasicToken {

  mapping (address => mapping (address => uint256)) allowed;

   
  function transferFrom(address _from, address _to, uint256 _value)canTransfer public returns (bool) {
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

   
  function allowance(address _owner, address _spender) view public returns (uint256 remaining) {
    return allowed[_owner][_spender];
  }

}

 
contract Ownable {
    
  address public owner;

   
  function Ownable() public{
    owner = msg.sender;
  }

   
  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }

   
  function transferOwnership(address newOwner) onlyOwner public{
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

 

contract LoanBit is BurnableToken, Ownable {
    
    string public constant name = "LoanBit";
    
    string public constant symbol = "LBT";
    
    uint public constant decimals = 18;
    
    
    
     
    address public walletICO =     0x8ffF4a8c4F1bd333a215f072ef9AEF934F677bFa;
    uint public tokenICO = 31450000*10**decimals; 
    address public walletTeam =    0x7eF1ac89B028A9Bc20Ce418c1e6973F4c7977eB0;
    uint public tokenTeam = 2960000*10**decimals; 
    address public walletAdvisor = 0xB6B01233cE7794D004aF238b3A53A0FcB1c5D8BD;
    uint public tokenAdvisor = 1480000*10**decimals; 
    
     
    
    address public walletAvatar =   0x9E6bA5600cF5f4656697E3aF2A963f56f522991C;
    uint public tokenAvatar = 444000*10**decimals;
    address public walletFacebook = 0x43827ba49d8eBd20afD137791227d3139E5BD074;
    uint public tokenFacebook = 155400*10**decimals;
    address public walletTwitter =  0xeFF945E9F29eA8c7a94F84Fb9fFd711d179ab520;
    uint public tokenTwitter = 155400*10**decimals;
    address public walletBlogs   =  0x16Df4Dc0Dd47dDD47759d54957C021650c76aed1;
    uint public tokenBlogs = 210900*10**decimals;
    address public walletTranslate =  0x19A903405fDcce9b32f48882C698A3842f09253F;
    uint public tokenTranslate = 133200*10**decimals;
    address public walletEmail   =  0x3912AE42372ff35f56d2f7f26313da7F48Fe5248;
    uint public tokenEmail = 11100*10**decimals;
    
     
    address public walletDev = 0xF4e16e79102B19702Cc10Cbcc02c6EC0CcAD8b1D;
    uint public tokenDev = 6000*10**decimals;
    
    function LoanBit()public{
        
        totalSupply = 37000000*10**decimals;
        
        balances[walletICO] = tokenICO;
        transferFrom(this,walletICO, 0);
        
        
        balances[walletTeam] = tokenTeam;
        transferFrom(this,walletTeam, 0);
        
        
        balances[walletAdvisor] = tokenAdvisor;
        transferFrom(this,walletAdvisor, 0);
        
        balances[walletDev] = tokenDev;
        transferFrom(this,walletDev, 0);
        
        balances[walletAvatar] = tokenAvatar;
        transferFrom(this,walletAvatar, 0);
        
        balances[walletFacebook] = tokenFacebook;
        transferFrom(this,walletFacebook, 0);
        
        balances[walletTwitter] = tokenTwitter;
        transferFrom(this,walletTwitter, 0);
        
        balances[walletBlogs] = tokenBlogs;
        transferFrom(this,walletBlogs, 0);
        
        balances[walletTranslate] = tokenTranslate;
        transferFrom(this,walletTranslate, 0);
        
        balances[walletEmail] = tokenEmail;
        transferFrom(this,walletEmail, 0);
        
    }
    
   
}