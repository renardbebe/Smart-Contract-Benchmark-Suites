 

pragma solidity ^0.4.11;


 
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

pragma solidity ^0.4.11;


 
contract ERC20Basic {
  uint256 public totalSupply;
  function balanceOf(address who) constant returns (uint256);
  function transfer(address to, uint256 value);
  event Transfer(address indexed from, address indexed to, uint256 value);
}

pragma solidity ^0.4.11;




 
contract ERC20 is ERC20Basic {
  function allowance(address owner, address spender) constant returns (uint256);
  function transferFrom(address from, address to, uint256 value);
  function approve(address spender, uint256 value);
  event Approval(address indexed owner, address indexed spender, uint256 value);
}

pragma solidity ^0.4.11;




 
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

pragma solidity ^0.4.11;




 
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

pragma solidity ^0.4.11;



contract ACFToken is StandardToken {

    string public name = "ArtCoinFund";
    string public symbol = "ACF";
    uint256 public decimals = 18;
    uint256 public INITIAL_SUPPLY = 750000 * 10**18;

    function ACFToken() {
        totalSupply = INITIAL_SUPPLY;
        balances[msg.sender] = INITIAL_SUPPLY;
    }

}

pragma solidity ^0.4.11;



contract ACFPreSale is Ownable{

    uint public startTime = 1509494400;    
    uint public endTime = 1510704000;      

    address public ACFWallet;            

    uint public totalCollected = 0;      
    bool public saleStopped = false;     
    bool public saleFinalized = false;   

    ACFToken public token;               


    uint constant public minInvestment = 0.1 ether;     
    uint public minFundingGoal = 150 ether;           

     
    mapping (address => bool) public whitelist;

     
    mapping(address => uint) public balances;

    event NewBuyer(address indexed holder, uint256 ACFAmount, uint256 amount);
     
    event Whitelisted(address addr, bool status);
     
    event Refunded(address investor, uint value);

    function ACFPreSale (
    address _token,
    address _ACFWallet
    )
    {
        token = ACFToken(_token);
        ACFWallet = _ACFWallet;
         
        setWhitelistStatus(ACFWallet, true);
        transferOwnership(ACFWallet);
    }

     
    function setWhitelistStatus(address addr, bool status)
    onlyOwner {
        whitelist[addr] = status;
        Whitelisted(addr, status);
    }

     
    function getRate() constant public returns (uint256) {
        return 20;
    }

     
    function getTokensLeft() public constant returns (uint) {
        return token.balanceOf(this);
    }

    function () public payable {
        doPayment(msg.sender);
    }

    function doPayment(address _owner)
    only_during_sale_period_or_whitelisted(_owner)
    only_sale_not_stopped
    non_zero_address(_owner)
    minimum_value(minInvestment)
    internal {

        uint256 tokensLeft = getTokensLeft();

        if(tokensLeft <= 0){
             
            throw;
        }
         
        uint256 tokenAmount = SafeMath.mul(msg.value, getRate());
         
        if(tokenAmount > tokensLeft) {
             
            tokenAmount = tokensLeft;

             
            uint256 change = SafeMath.sub(msg.value, SafeMath.div(tokenAmount, getRate()));
            if(!_owner.send(change)) throw;

        }
         
        token.transfer(_owner, tokenAmount);
         
        balances[_owner] = SafeMath.add(balances[_owner], msg.value);
         
        totalCollected = SafeMath.add(totalCollected, msg.value);

        NewBuyer(_owner, tokenAmount, msg.value);
    }

     
     
    function emergencyStopSale()
    only_sale_not_stopped
    onlyOwner
    public {
        saleStopped = true;
    }

     
     
    function restartSale()
    only_during_sale_period
    only_sale_stopped
    onlyOwner
    public {
        saleStopped = false;
    }


     
     
    function moveFunds()
    onlyOwner
    public {
         
        if (!ACFWallet.send(this.balance)) throw;
    }


    function finalizeSale()
    only_after_sale
    onlyOwner
    public {
        doFinalizeSale();
    }

    function doFinalizeSale()
    internal {
        if (totalCollected >= minFundingGoal){
             
            if (!ACFWallet.send(this.balance)) throw;
        }
         
        token.transfer(ACFWallet, getTokensLeft());

        saleFinalized = true;
        saleStopped = true;
    }

     
    function refund()
    only_sale_refundable {
        address investor = msg.sender;
        if(balances[investor] == 0) throw;  
        uint amount = balances[investor];
         
        delete balances[investor];
         
        if(!investor.send(amount)) throw;

        Refunded(investor, amount);
    }

    function getNow() internal constant returns (uint) {
        return now;
    }

    modifier only(address x) {
        if (msg.sender != x) throw;
        _;
    }

    modifier only_during_sale_period {
        if (getNow() < startTime) throw;
        if (getNow() >= endTime) throw;
        _;
    }

     
    modifier only_during_sale_period_or_whitelisted(address x) {
        if (getNow() < startTime && !whitelist[x]) throw;
        if (getNow() >= endTime) throw;
        _;
    }

    modifier only_after_sale {
        if (getNow() < endTime) throw;
        _;
    }

    modifier only_sale_stopped {
        if (!saleStopped) throw;
        _;
    }

    modifier only_sale_not_stopped {
        if (saleStopped) throw;
        _;
    }

    modifier non_zero_address(address x) {
        if (x == 0) throw;
        _;
    }

    modifier minimum_value(uint256 x) {
        if (msg.value < x) throw;
        _;
    }

    modifier only_sale_refundable {
        if (getNow() < endTime) throw;  
        if (totalCollected >= minFundingGoal) throw;  
        _;
    }

}