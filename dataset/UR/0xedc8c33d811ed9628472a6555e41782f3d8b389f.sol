 

 

pragma solidity ^0.4.21;

contract ERC20Basic {
  function totalSupply() public view returns (uint256);
  function balanceOf(address who) public view returns (uint256);
  function transfer(address to, uint256 value) public returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
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
    return a / b;
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
  mapping(address => bool   ) isInvestor;
  address[] public arrInvestors;
  
  uint256 totalSupply_;

  function totalSupply() public view returns (uint256) {
    return totalSupply_;
  }

  function addInvestor(address _newInvestor) internal {
    if (!isInvestor[_newInvestor]){
       isInvestor[_newInvestor] = true;
       arrInvestors.push(_newInvestor);
    }  
      
  }
    function getInvestorsCount() public view returns(uint256) {
        return arrInvestors.length;
        
    }

 
  function transfer(address _to, uint256 _value) public returns (bool) {
    if (balances[msg.sender] >= 1 ether){
        require(_value >= 1 ether);      
    } else {
        require(_value == balances[msg.sender]);  
    }
    
    require(_to != address(0));
    require(_value <= balances[msg.sender]);

    balances[msg.sender] = balances[msg.sender].sub(_value);
    balances[_to] = balances[_to].add(_value);
    addInvestor(_to);
    emit Transfer(msg.sender, _to, _value);
    return true;
  }


    function transferToken(address _to, uint256 _value) public returns (bool) {
        return transfer(_to, _value.mul(1 ether));
    }


  function balanceOf(address _owner) public view returns (uint256 balance) {
    return balances[_owner];
  }

}

 

contract BurnableToken is BasicToken {

  event Burn(address indexed burner, uint256 value);

  function burn(uint256 _value) public {
    _burn(msg.sender, _value);
  }

  function _burn(address _who, uint256 _value) internal {
    require(_value <= balances[_who]);
    balances[_who] = balances[_who].sub(_value);
    totalSupply_ = totalSupply_.sub(_value);
    emit Burn(_who, _value);
    emit Transfer(_who, address(0), _value);
  }
}


contract GoldenCurrencyToken is BurnableToken {
  string public constant name = "Pre-ICO Golden Currency Token";
  string public constant symbol = "PGCT";
  uint32 public constant decimals = 18;
  uint256 public INITIAL_SUPPLY = 7600000 * 1 ether;

  function GoldenCurrencyToken() public {
    totalSupply_ = INITIAL_SUPPLY;
    balances[msg.sender] = INITIAL_SUPPLY;      
  }
}
  

 contract Ownable {
  address public owner;
  address candidate;
  address public manager1;
  address public manager2;

  function Ownable() public {
    owner = msg.sender;
    manager1 = msg.sender;
    manager2 = msg.sender;
  }

  modifier onlyOwner() {
    require(msg.sender == owner || msg.sender == manager1 || msg.sender == manager2);
    _;
  }


  function transferOwnership(address newOwner) public onlyOwner {
    require(newOwner != address(0));
    candidate = newOwner;
  }

  function confirmOwnership() public {
    require(candidate == msg.sender);
    owner = candidate;
    delete candidate;
  }

  function transferManagment1(address newManager) public onlyOwner {
    require(newManager != address(0));
    manager1 = newManager;
  }

  function transferManagment2(address newManager) public onlyOwner {
    require(newManager != address(0));
    manager2 = newManager;
  }
}


contract Crowdsale is Ownable {
  using SafeMath for uint;    
  address myAddress = this;    

    address public profitOwner = 0x0;  
    uint public  tokenRate = 500;
    uint start = 1523450379;         
    uint finish = 1531785599;        
    uint256 period1 = 1523836800;    
    uint256 period2 = 1525132800;    
    uint256 period3 = 1527811200;    
  
  event TokenRates(uint256 indexed value);

  GoldenCurrencyToken public token = new GoldenCurrencyToken();
  
    modifier saleIsOn() {
        require(now > start && now < finish);
        _;
    }

    function setProfitOwner (address _newProfitOwner) public onlyOwner {
        require(_newProfitOwner != address(0));
        profitOwner = _newProfitOwner;
    }

    function saleTokens(address _newInvestor, uint256 _value) public saleIsOn onlyOwner payable {
         
         
        require (_newInvestor!= address(0));
        require (_value >= 1);
        _value = _value.mul(1 ether);
        token.transfer(_newInvestor, _value);
    }  
    

    function createTokens() saleIsOn internal {

    require(profitOwner != address(0));
    uint tokens = tokenRate.mul(msg.value);
    require (tokens.div(1 ether) >= 100);   

    profitOwner.transfer(msg.value);
    
    uint bonusTokens = 0;
         



    if(now < period2) {
      bonusTokens = tokens.div(4);
    } else if(now >= period2 && now < period3) {
      bonusTokens = tokens.div(5);
    } else if(now >= period3 && now < finish) {
      bonusTokens = tokens.div(100).mul(15);
    }

    uint tokensWithBonus = tokens.add(bonusTokens);
    token.transfer(msg.sender, tokensWithBonus);
  }
 
 
   function setTokenRate(uint newRate) public onlyOwner {
      tokenRate = newRate;
      emit TokenRates(newRate);
  }
   
  function changePeriods(uint256 _start, uint256 _period1, uint256 _period2, uint256 _period3, uint256 _finish) public onlyOwner {
    start = _start;
    finish = _finish;
    period1 = _period1;
    period2 = _period2;
    period3 = _period3;
  }
  
 
  function() external payable {
    createTokens();
  }    
 
}