 

pragma solidity ^0.4.17;



 
library SafeMath {
  function mul(uint a, uint b) internal returns (uint) {
    uint c = a * b;
    assert(a == 0 || c / a == b);
    return c;
  }

  function div(uint a, uint b) internal returns (uint) {
     
    uint c = a / b;
     
    return c;
  }

  function sub(uint a, uint b) internal returns (uint) {
    assert(b <= a);
    return a - b;
  }

  function add(uint a, uint b) internal returns (uint) {
    uint c = a + b;
    assert(c >= a);
    return c;
  }

  function max64(uint64 a, uint64 b) internal constant returns (uint64) {
    return a >= b ? a : b;
  }

  function min64(uint64 a, uint64 b) internal constant returns (uint64) {
    return a < b ? a : b;
  }

  function max256(uint256 a, uint256 b) internal constant returns (uint256) {
    return a >= b ? a : b;
  }

  function min256(uint256 a, uint256 b) internal constant returns (uint256) {
    return a < b ? a : b;
  }

  function assert(bool assertion) internal {
    if (!assertion) {
      throw;
    }
  }
}


 
contract ERC20Basic {
  uint public totalSupply;
  function balanceOf(address who) constant returns (uint);
  function transfer(address to, uint value) returns (bool);
  event Transfer(address indexed from, address indexed to, uint value);
}




 
contract BasicToken is ERC20Basic {
  using SafeMath for uint;

  mapping(address => uint) balances;

   
  modifier onlyPayloadSize(uint size) {
     if(msg.data.length < size + 4) {
       throw;
     }
     _;
  }

   
  function transfer(address _to, uint _value) onlyPayloadSize(2 * 32) returns (bool){
    require(_to != address(0));
    require(_value <= balances[msg.sender]);

    balances[msg.sender] = balances[msg.sender].sub(_value);
    balances[_to] = balances[_to].add(_value);
    Transfer(msg.sender, _to, _value);
    return true;
  }

   
  function balanceOf(address _owner) constant returns (uint balance) {
    return balances[_owner];
  }

}




 
contract ERC20 is ERC20Basic {
  function allowance(address owner, address spender) constant returns (uint);
  function transferFrom(address from, address to, uint value) returns (bool);
  function approve(address spender, uint value) returns (bool);
  event Approval(address indexed owner, address indexed spender, uint value);
}




 
contract StandardToken is BasicToken, ERC20 {

  mapping (address => mapping (address => uint)) allowed;


   
  function transferFrom(address _from, address _to, uint _value) onlyPayloadSize(3 * 32) returns (bool) {
    var _allowance = allowed[_from][msg.sender];

    require(_to != address(0));
    require(_value <= balances[_from]);
    require(_value <= _allowance);

    balances[_to] = balances[_to].add(_value);
    balances[_from] = balances[_from].sub(_value);
    allowed[_from][msg.sender] = _allowance.sub(_value);
    Transfer(_from, _to, _value);

    return true;
  }

   
  function approve(address _spender, uint _value) returns (bool) {

     
     
     
     
    if ((_value != 0) && (allowed[msg.sender][_spender] != 0)) throw;

    allowed[msg.sender][_spender] = _value;
    Approval(msg.sender, _spender, _value);

    return true;
  }

   
  function allowance(address _owner, address _spender) constant returns (uint remaining) {
    return allowed[_owner][_spender];
  }

}

 
 contract SolaToken is StandardToken {
   
  string public constant name = "Sola Token";
  string public constant symbol = "SOL";
  uint8  public constant decimals = 6;

   
   
  uint256 public constant FUTURE_DEVELOPMENT_FUND = 55e6 * (10 ** uint256(decimals));
  uint256 public constant INCENT_FUND_VESTING     = 27e6 * (10 ** uint256(decimals));
  uint256 public constant INCENT_FUND_NON_VESTING = 3e6  * (10 ** uint256(decimals));
  uint256 public constant TEAM_FUND               = 15e6 * (10 ** uint256(decimals));
  uint256 public constant SALE_FUND               = 50e6 * (10 ** uint256(decimals));

   
  uint64 public constant PUBLIC_START_TIME = 1514210400;  
  
   
   
  address public openLedgerAddress;
  address public futureDevelopmentFundAddress;
  address public incentFundAddress;
  address public teamFundAddress;
  
   
  bool public saleTokensHaveBeenMinted = false;
  bool public fundsTokensHaveBeenMinted = false;

  function SolaToken(address _openLedger, address _futureDevelopmentFund, address _incentFund, address _teamFund) {
    openLedgerAddress = _openLedger;
    futureDevelopmentFundAddress = _futureDevelopmentFund;
    incentFundAddress = _incentFund;
    teamFundAddress = _teamFund;
  }

  function mint(address _to, uint256 _value) private {
    totalSupply = totalSupply.add(_value);
    balances[_to] = balances[_to].add(_value);

    Transfer(0x0, _to, _value);
  }

  function mintFundsTokens() public {
    require(!fundsTokensHaveBeenMinted);

    fundsTokensHaveBeenMinted = true;

    mint(futureDevelopmentFundAddress, FUTURE_DEVELOPMENT_FUND);
    mint(incentFundAddress, INCENT_FUND_VESTING + INCENT_FUND_NON_VESTING);
    mint(teamFundAddress, TEAM_FUND);
}

  function mintSaleTokens(uint256 _value) public {
    require(!saleTokensHaveBeenMinted);
    require(_value <= SALE_FUND);

    saleTokensHaveBeenMinted = true;

    mint(openLedgerAddress, _value);
  }
}