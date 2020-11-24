 

 
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
    emit OwnershipTransferred(owner, newOwner);
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
    emit Transfer(msg.sender, _to, _value);
    return true;
  }

   
  function balanceOf(address _owner) public view returns (uint256 balance) {
    return balances[_owner];
  }

}

 
contract StandardToken is ERC20, BasicToken {

  mapping (address => mapping (address => uint256)) allowed;


   
  function transferFrom(address _from, address _to, uint256 _value) public returns (bool) {
    require(_to != address(0));
    require(_value <= balances[_from]);
    uint256 _allowance = allowed[_from][msg.sender];

    balances[_from] = balances[_from].sub(_value);
    balances[_to] = balances[_to].add(_value);
    allowed[_from][msg.sender] = _allowance.sub(_value);
    emit Transfer(_from, _to, _value);
    return true;
  }

   
  function approve(address _spender, uint256 _value) public returns (bool) {
    allowed[msg.sender][_spender] = _value;
    emit Approval(msg.sender, _spender, _value);
    return true;
  }

   
  function allowance(address _owner, address _spender) public constant returns (uint256 remaining) {
    return allowed[_owner][_spender];
  }

   
  function increaseApproval (address _spender, uint _addedValue) public returns (bool) {
    allowed[msg.sender][_spender] = allowed[msg.sender][_spender].add(_addedValue);
    emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
    return true;
  }

   
  function decreaseApproval (address _spender, uint _subtractedValue) public returns (bool) {
    uint oldValue = allowed[msg.sender][_spender];
    if (_subtractedValue > oldValue) {
      allowed[msg.sender][_spender] = 0;
    } else {
      allowed[msg.sender][_spender] = oldValue.sub(_subtractedValue);
    }
    emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
    return true;
  }

}


 
contract GainmersTOKEN is StandardToken, Ownable {
    string  public  constant name = "Gain Token";
    string  public  constant symbol = "GMR";
    uint8   public  constant decimals = 18;

    uint256 public  totalSupply;
    uint    public  transferableStartTime;
    address public  tokenSaleContract;
   

    modifier onlyWhenTransferEnabled() 
    {
        if ( now < transferableStartTime ) {
            require(msg.sender == tokenSaleContract || msg.sender == owner);
        }
        _;
    }

    modifier validDestination(address to) 
    {
        require(to != address(this));
        _;
    }

    modifier onlySaleContract()
    {
        require(msg.sender == tokenSaleContract);
        _;
    }

    function GainmersTOKEN(
        uint tokenTotalAmount, 
        uint _transferableStartTime, 
        address _admin) public 
    {
        
        totalSupply = tokenTotalAmount * (10 ** uint256(decimals));

        balances[msg.sender] = totalSupply;
        emit Transfer(address(0x0), msg.sender, totalSupply);

        transferableStartTime = _transferableStartTime;
        tokenSaleContract = msg.sender;

        transferOwnership(_admin); 

    }

     
    function transfer(address _to, uint _value)
        public
        validDestination(_to)
        onlyWhenTransferEnabled
        returns (bool) 
    {
        return super.transfer(_to, _value);
    }

     
    function transferFrom(address _from, address _to, uint _value)
        public
        validDestination(_to)
        onlyWhenTransferEnabled
        returns (bool) 
    {
        return super.transferFrom(_from, _to, _value);
    }

    event Burn(address indexed _burner, uint _value);

     
    function burn(uint _value) 
        public
        onlyWhenTransferEnabled
        onlyOwner
        returns (bool)
    {
        balances[msg.sender] = balances[msg.sender].sub(_value);
        totalSupply = totalSupply.sub(_value);
        emit Burn(msg.sender, _value);
        emit Transfer(msg.sender, address(0x0), _value);
        return true;
    }

     
    function burnFrom(address _from, uint256 _value) 
        public
        onlyWhenTransferEnabled
        onlyOwner
        returns(bool) 
    {
        assert(transferFrom(_from, msg.sender, _value));
        return burn(_value);
    }

     
    function enableTransferEarlier ()
        public
        onlySaleContract
    {
        transferableStartTime = now + 2 days;
    }


     
    function emergencyERC20Drain(ERC20 token, uint amount )
        public
        onlyOwner 
    {
        token.transfer(owner, amount);
    }

}

 
 
contract ModifiedCrowdsale {
    using SafeMath for uint256;

     
    StandardToken public token; 

     
    uint256 public startTime;
    uint256 public endTime;

      
    uint256 public rate;

     
    address public wallet;

     
    uint256 public weiRaised;

     
    event TokenPurchase(address indexed purchaser, uint256 value, uint256 amount);
     
     event TokenSaleSoldOut();
     
    function ModifiedCrowdsale(uint256 _startTime, uint256 _endTime, uint256 _rate, address _wallet) public  {
        
        require(_startTime >= now);
        require(_endTime >= _startTime);
        require(_rate > 0);
        require(_wallet != 0x0);

        startTime = _startTime;
        endTime = _endTime;
        rate = _rate;
        wallet = _wallet;
        
        token = createTokenContract(); 
    }

     
     
    function createTokenContract() 
        internal 
        returns(StandardToken) 
    {
        return new StandardToken();
    }

     
    function () external payable {
        buyTokens(msg.sender);
    }

     
    function buyTokens(address _beneficiary) public   payable {
        require(validPurchase());
        uint256 weiAmount = msg.value;

         
        uint256 tokens = weiAmount.mul(rate);
        tokens += getBonus(tokens);

         
        weiRaised = weiRaised.add(weiAmount);

        require(token.transfer(_beneficiary, tokens)); 
        emit TokenPurchase(_beneficiary, weiAmount, tokens);

        forwardFunds();

        postBuyTokens();
    }

     
    function postBuyTokens () internal  
    {emit TokenSaleSoldOut();
    }

     
     
    function forwardFunds() 
       internal 
    {
        wallet.transfer(msg.value);
    }

     
    function validPurchase()  internal  view
        returns(bool) 
    {
        bool withinPeriod = now >= startTime && now <= endTime;
        bool nonZeroPurchase = msg.value != 0;
        bool nonInvalidAccount = msg.sender != 0;
        return withinPeriod && nonZeroPurchase && nonInvalidAccount;
    }

     
    function hasEnded() 
        public 
        constant 
        returns(bool) 
    {
        return now > endTime;
    }


     
    function getBonus(uint256 _tokens) internal view returns (uint256 bonus) {
        require(_tokens != 0);
        if (startTime <= now && now < startTime + 7 days ) {
            return _tokens.div(5);
        } else if (startTime + 7 days <= now && now < startTime + 14 days ) {
            return _tokens.div(10);
        } else if (startTime + 14 days <= now && now < startTime + 21 days ) {
            return _tokens.div(20);
        }

        return 0;
    }
}

 
contract CappedCrowdsale is ModifiedCrowdsale {
  using SafeMath for uint256;

  uint256 public cap;

  function CappedCrowdsale(uint256 _cap) public {
    require(_cap > 0);
    cap = _cap;
  }

   
   
   
  function validPurchase() internal view returns (bool) {
    bool withinCap = weiRaised.add(msg.value) <= cap;
    return super.validPurchase() && withinCap;
  }

   
   
  function hasEnded() public constant returns (bool) {
    bool capReached = weiRaised >= cap;
    return super.hasEnded() || capReached;
  }

}



 
contract GainmersSALE is Ownable, CappedCrowdsale {
    
     
    uint public constant TotalTOkenSupply = 100000000;

     
    uint private constant Hardcap = 30000 ether;

     
    uint private constant RateExchange = 1660;

   

     

     
    address public constant TeamWallet = 0x6009267Cb183AEC8842cb1d020410f172dD2d50F;
    uint public constant TeamWalletAmount = 10000000e18; 
    
      
    address public constant TeamAdvisorsWallet = 0x3925848aF4388a3c10cd73F3529159de5f0C686c;
    uint public constant AdvisorsAmount = 10000000e18;
    
      
    address public constant 
    ReinvestWallet = 0x1cc1Bf6D3100Ce4EE3a398bEdE33A7e3a42225D7;
    uint public constant ReinvestAmount = 15000000e18;

      
    address public constant BountyCampaingWallet = 0xD36FcA0DAd25554922d860dA18Ac47e4F9513672
    ;
    uint public constant BountyAmount = 5000000e18;

    

     
    uint public constant AfterSaleTransferableTime = 2 days;


    function GainmersSALE(uint256 _startTime, uint256 _endTime) public
      CappedCrowdsale(Hardcap)
      ModifiedCrowdsale(_startTime,
                         _endTime, 
                         RateExchange, 
                         TeamWallet)
    {
        
        token.transfer(TeamWallet, TeamWalletAmount);
        token.transfer(TeamAdvisorsWallet, AdvisorsAmount);
        token.transfer(ReinvestWallet, ReinvestAmount);
        token.transfer(BountyCampaingWallet, BountyAmount);


        
    }

     
    function createTokenContract () 
      internal 
      returns(StandardToken) 
    {
        return new GainmersTOKEN(TotalTOkenSupply,
         endTime.add(AfterSaleTransferableTime),
        TeamWallet);
    }



     
    function drainRemainingToken () 
      public
      onlyOwner
    {
        require(hasEnded());
        token.transfer(TeamWallet, token.balanceOf(this));
    }


     

    function postBuyTokens ()  internal {
        if ( weiRaised >= Hardcap ) {  
            GainmersTOKEN gainmersToken = GainmersTOKEN (token);
            gainmersToken.enableTransferEarlier();
            emit TokenSaleSoldOut();
        }
    }
}