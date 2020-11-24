 

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
library SafeERC20 {
  function safeTransfer(ERC20Basic token, address to, uint256 value) internal {
    assert(token.transfer(to, value));
  }

  function safeTransferFrom(ERC20 token, address from, address to, uint256 value) internal {
    assert(token.transferFrom(from, to, value));
  }

  function safeApprove(ERC20 token, address spender, uint256 value) internal {
    assert(token.approve(spender, value));
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
contract TokenTimelock {
  using SafeERC20 for ERC20Basic;

   
  ERC20Basic public token;

   
  address public beneficiary;

   
  uint256 public releaseTime;

  function TokenTimelock(ERC20Basic _token, address _beneficiary, uint256 _releaseTime) public {
    require(_releaseTime > now);
    token = _token;
    beneficiary = _beneficiary;
    releaseTime = _releaseTime;
  }

   
  function release() public {
    require(now >= releaseTime);

    uint256 amount = token.balanceOf(this);
    require(amount > 0);

    token.safeTransfer(beneficiary, amount);
  }
}
contract BurnableToken is BasicToken {

  event Burn(address indexed burner, uint256 value);

   
  function burn(uint256 _value) public {
    require(_value <= balances[msg.sender]);
     
     

    address burner = msg.sender;
    balances[burner] = balances[burner].sub(_value);
    totalSupply_ = totalSupply_.sub(_value);
    Burn(burner, _value);
  }
}
contract WTRToken is  BurnableToken{
    string public constant name = "WTR";
    string public constant symbol = "WTR";
    uint8 public constant decimals = 4;
    uint256 public totalSupply;
    
    function WTRToken() public 
    {
        totalSupply = 175000000 * 10 ** uint256(decimals);
        balances[msg.sender] = totalSupply;
    }
}
contract WTRCrowdsale is Ownable{
    
    using SafeMath for uint256;
    
    
    uint256 public constant preSaleStart = 1514296800;
    uint256 public constant preSaleEnd = 1519912800;
    
    uint256 public constant SaleStart = 1525183200;
    uint256 public constant SaleEnd = 1530453600;
    
    enum Periods {NotStarted, PreSale, Sale, Finished}
    Periods public period;
    
    WTRToken public token;
    address public wallet;
    uint256 public constant rate = 9000;
    uint256 public balance;
    uint256 public tokens;
    
    mapping(address => uint256) internal balances;
    
    function Crowdsale(address _token, address _wallet) public{
        token = WTRToken(_token);
        wallet = _wallet;
        period = Periods.NotStarted;
    }
    
    function nextState() onlyOwner public{
        require(period == Periods.NotStarted || period == Periods.PreSale || period == Periods.Sale);
        
        if(period == Periods.NotStarted){
            period = Periods.PreSale;
        }
        else if(period == Periods.PreSale){
            period = Periods.Sale;
        }
        else if(period == Periods.Sale){
            period = Periods.Finished;
        }
    }
    
    function buyTokens() internal
    {
        uint256 weiAmount = msg.value;
        tokens = weiAmount.mul(rate);
        bool success = token.transfer(msg.sender, tokens);
        require(success);
        if(period == Periods.PreSale && period == Periods.Sale)
        {
            wallet.transfer(msg.value);
        }
    }
    
    function isValidPeriod() internal constant returns (bool){
        if(period == Periods.PreSale)
        {
            if(now >= preSaleStart && now <= preSaleEnd) return true;
        }
        else if(period == Periods.Sale)
        {
            if(now >= SaleStart && now <= SaleEnd) return true;
        }
        
        return false;
    }
    
    function () public payable{
        require(msg.sender != address(0));
        require(msg.value > 0);
        require(isValidPeriod());
        
        buyTokens();
    }
    
    function burningTokens() public onlyOwner{
        if(period == Periods.Finished){
            token.burn(tokens);
        }
    }
    
}