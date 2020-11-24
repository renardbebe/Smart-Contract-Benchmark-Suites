 

pragma solidity ^0.4.16;

 

 
 
library SafeMath {
  function mul(uint256 a, uint256 b) internal constant returns (uint256) {
    uint256 c = a * b;
    assert(a == 0 || c / a == b);
    return c;
  }

  function div(uint256 a, uint256 b) internal constant returns (uint256) {
     
    uint256 c = a / b;
     
    return c;
  }

  function sub(uint256 a, uint256 b) internal constant returns (uint256) {
    assert(b <= a);
    return a - b;
  }

  function add(uint256 a, uint256 b) internal constant returns (uint256) {
    uint256 c = a + b;
    assert(c >= a);
    return c;
  }
}

contract Token {
    uint256 public totalSupply;
    function balanceOf(address who) public constant returns (uint256);
    function transfer(address to, uint256 value) public returns (bool);
    function allowance(address owner, address spender) public constant returns (uint256);
    function transferFrom(address from, address to, uint256 value) public returns (bool);
    function approve(address spender, uint256 value) public returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

 
contract Ownable {
  address public owner;


   
  function Ownable() {
    owner = msg.sender;
  }


   
  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }


   
  function transferOwnership(address newOwner) onlyOwner {
    require(newOwner != address(0));      
    owner = newOwner;
  }

}

contract StandardToken is Token, Ownable {
    using SafeMath for uint256;
    mapping (address => mapping (address => uint256)) internal allowed;

  mapping(address => uint256) balances;

   
  function transfer(address _to, uint256 _value) public returns (bool) {
    require(_to != address(0));
    require(_value <= balances[msg.sender]);

     
    balances[msg.sender] = balances[msg.sender].sub(_value);
    balances[_to] = balances[_to].add(_value);
    Transfer(msg.sender, _to, _value);
    return true;
  }

   
  function balanceOf(address _owner) public constant returns (uint256 balance) {
    return balances[_owner];
  }


   
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

   
  function allowance(address _owner, address _spender) public constant returns (uint256 remaining) {
    return allowed[_owner][_spender];
  }

   
  function increaseApproval (address _spender, uint _addedValue) public returns (bool success) {
    allowed[msg.sender][_spender] = allowed[msg.sender][_spender].add(_addedValue);
    Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
    return true;
  }

  function decreaseApproval (address _spender, uint _subtractedValue) public returns (bool success) {
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

contract XZEN is StandardToken {
    using SafeMath for uint256;

    string public constant name = "XZEN PreToken";
    string public constant symbol = "XZNP";
    uint256 public constant decimals = 18;
    uint256 public constant tokenCreationCapPreICO =  55000000*10**decimals;
    address public multiSigWallet = 0x51cf183cbe4e4c80297c49ff5017770fdd95c06d;
    address public teamWallet = 0x2BeB722Dc6E80D0C61e63240ca44B8a6D538e3Ae;

     
    uint public oneTokenInWei = 31847133757962;
    uint startDate = 1510592400;

    function XZEN() {
        owner = teamWallet;
        balances[teamWallet] = 55000000*10**decimals;
        totalSupply = totalSupply.add(balances[teamWallet]);
        Transfer(0x0, teamWallet, balances[teamWallet]);
    }

    function () payable {
        createTokens();
    }

    function createTokens() internal  {
        uint multiplier = 10 ** decimals;
        uint256 tokens = (msg.value.mul(multiplier) / oneTokenInWei);
         
        if(now <= startDate + 1 days) {
            tokens += tokens / 100 * 5;  
        }
        if (balances[teamWallet] < tokens) revert();
        balances[teamWallet] -= tokens;        
        balances[msg.sender] += tokens;
        
         
        multiSigWallet.transfer(msg.value);
        Transfer(teamWallet, msg.sender, tokens);
    }

    function setEthPrice(uint _tokenPrice) external onlyOwner {
        oneTokenInWei = _tokenPrice;
    }
    
    function replaceMultisig(address newMultisig) external onlyOwner {
        multiSigWallet = newMultisig;
    }

}