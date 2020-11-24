 

pragma solidity ^0.4.15;


 
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


 
contract Ownable {
  address public owner;


  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);


   
  function Ownable() {
    owner = msg.sender;
  }


   
  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }


   
  function transferOwnership(address newOwner) onlyOwner public {
    require(newOwner != address(0));
    OwnershipTransferred(owner, newOwner);
    owner = newOwner;
  }

}




 
contract Pausable is Ownable {
  event Pause();
  event Unpause();

  bool public paused = false;


   
  modifier whenNotPaused() {
    require(!paused);
    _;
  }

   
  modifier whenPaused() {
    require(paused);
    _;
  }

   
  function pause() onlyOwner whenNotPaused public {
    paused = true;
    Pause();
  }

   
  function unpause() onlyOwner whenPaused public {
    paused = false;
    Unpause();
  }
}



 
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





 
contract BasicToken is ERC20Basic {
  using SafeMath for uint256;

  mapping(address => uint256) balances;



   
  function transfer(address _to, uint256 _value) public returns (bool) {
    require(_to != address(0));

     
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
    require(_to != address(0));

    uint256 _allowance = allowed[_from][msg.sender];

     
     

    balances[_from] = balances[_from].sub(_value);
    balances[_to] = balances[_to].add(_value);
    allowed[_from][msg.sender] = _allowance.sub(_value);
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

   
  function increaseApproval (address _spender, uint _addedValue)
    returns (bool success) {
    allowed[msg.sender][_spender] = allowed[msg.sender][_spender].add(_addedValue);
    Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
    return true;
  }

  function decreaseApproval (address _spender, uint _subtractedValue)
    returns (bool success) {
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



 
contract BurnableToken is StandardToken {

    event Burn(address indexed burner, uint256 value);

     
    function burn(uint256 _value) public {
        require(_value > 0);

        address burner = msg.sender;
        balances[burner] = balances[burner].sub(_value);
        totalSupply = totalSupply.sub(_value);
        Burn(burner, _value);
    }
}

 



 
contract QuantstampToken is StandardToken, BurnableToken, Ownable {

     
    string  public constant name = "Quantstamp Token";
    string  public constant symbol = "QSP";
    uint8   public constant decimals = 18;
    uint256 public constant INITIAL_SUPPLY      = 1000000000 * (10 ** uint256(decimals));
    uint256 public constant CROWDSALE_ALLOWANCE =  650000000 * (10 ** uint256(decimals));
    uint256 public constant ADMIN_ALLOWANCE     =  350000000 * (10 ** uint256(decimals));

     
    uint256 public crowdSaleAllowance;       
    uint256 public adminAllowance;           
    address public crowdSaleAddr;            
    address public adminAddr;                
    bool    public transferEnabled = false;  

     
    modifier onlyWhenTransferEnabled() {
        if (!transferEnabled) {
            require(msg.sender == adminAddr || msg.sender == crowdSaleAddr);
        }
        _;
    }

     
    modifier validDestination(address _to) {
        require(_to != address(0x0));
        require(_to != address(this));
        require(_to != owner);
        require(_to != address(adminAddr));
        require(_to != address(crowdSaleAddr));
        _;
    }

     
    function QuantstampToken(address _admin) {
         
         
         
         
        require(msg.sender != _admin);

        totalSupply = INITIAL_SUPPLY;
        crowdSaleAllowance = CROWDSALE_ALLOWANCE;
        adminAllowance = ADMIN_ALLOWANCE;

         
        balances[msg.sender] = totalSupply;
        Transfer(address(0x0), msg.sender, totalSupply);

        adminAddr = _admin;
        approve(adminAddr, adminAllowance);
    }

     
    function setCrowdsale(address _crowdSaleAddr, uint256 _amountForSale) external onlyOwner {
        require(!transferEnabled);
        require(_amountForSale <= crowdSaleAllowance);

         
        uint amount = (_amountForSale == 0) ? crowdSaleAllowance : _amountForSale;

         
        approve(crowdSaleAddr, 0);
        approve(_crowdSaleAddr, amount);

        crowdSaleAddr = _crowdSaleAddr;
    }

     
    function enableTransfer() external onlyOwner {
        transferEnabled = true;
        approve(crowdSaleAddr, 0);
        approve(adminAddr, 0);
        crowdSaleAllowance = 0;
        adminAllowance = 0;
    }

     
    function transfer(address _to, uint256 _value) public onlyWhenTransferEnabled validDestination(_to) returns (bool) {
        return super.transfer(_to, _value);
    }

     
    function transferFrom(address _from, address _to, uint256 _value) public onlyWhenTransferEnabled validDestination(_to) returns (bool) {
        bool result = super.transferFrom(_from, _to, _value);
        if (result) {
            if (msg.sender == crowdSaleAddr)
                crowdSaleAllowance = crowdSaleAllowance.sub(_value);
            if (msg.sender == adminAddr)
                adminAllowance = adminAllowance.sub(_value);
        }
        return result;
    }

     
    function burn(uint256 _value) public {
        require(transferEnabled || msg.sender == owner);
        require(balances[msg.sender] >= _value);
        super.burn(_value);
        Transfer(msg.sender, address(0x0), _value);
    }
}

 



 
contract QuantstampMainSale is Pausable {

    using SafeMath for uint256;

    uint public constant RATE = 5000;        
    uint public constant GAS_LIMIT_IN_WEI = 50000000000 wei;

    bool public fundingCapReached = false;   
    bool public saleClosed = false;          
    bool private rentrancy_lock = false;     

    uint public fundingCap;                  
    uint256 public cap;                      

    uint public minContribution;             
    uint public amountRaised;                
    uint public refundAmount;                

    uint public startTime;                   
    uint public deadline;                    
    uint public capTime;                     

    address public beneficiary;              

    QuantstampToken public tokenReward;      

    mapping(address => uint256) public balanceOf;    
    mapping(address => uint256) public mainsaleBalanceOf;  

    mapping(address => bool) public registry;        

     
    event CapReached(address _beneficiary, uint _amountRaised);
    event FundTransfer(address _backer, uint _amount, bool _isContribution);
    event RegistrationStatusChanged(address target, bool isRegistered);

     
    modifier beforeDeadline()   { require (currentTime() < deadline); _; }
    modifier afterDeadline()    { require (currentTime() >= deadline); _; }
    modifier afterStartTime()   { require (currentTime() >= startTime); _; }
    modifier saleNotClosed()    { require (!saleClosed); _; }

    modifier nonReentrant() {
        require(!rentrancy_lock);
        rentrancy_lock = true;
        _;
        rentrancy_lock = false;
    }

     
    function QuantstampMainSale(
        address ifSuccessfulSendTo,
        uint fundingCapInEthers,
        uint minimumContributionInWei,
        uint start,
        uint durationInMinutes,
        uint initialCap,
        uint capDurationInMinutes,
        address addressOfTokenUsedAsReward
    ) {
        require(ifSuccessfulSendTo != address(0) && ifSuccessfulSendTo != address(this));
        require(addressOfTokenUsedAsReward != address(0) && addressOfTokenUsedAsReward != address(this));
        require(durationInMinutes > 0);
        beneficiary = ifSuccessfulSendTo;
        fundingCap = fundingCapInEthers * 1 ether;
        minContribution = minimumContributionInWei;
        startTime = start;
        deadline = start + (durationInMinutes * 1 minutes);
        capTime = start + (capDurationInMinutes * 1 minutes);
        cap = initialCap * 1 ether;
        tokenReward = QuantstampToken(addressOfTokenUsedAsReward);
    }


    function () payable {
        buy();
    }


    function buy()
        payable
        public
        whenNotPaused
        beforeDeadline
        afterStartTime
        saleNotClosed
        nonReentrant
    {
        uint amount = msg.value;
        require(amount >= minContribution);

         
        require(registry[msg.sender]);

        amountRaised = amountRaised.add(amount);

         
         
        if(amountRaised > fundingCap){
            uint overflow = amountRaised.sub(fundingCap);
            amount = amount.sub(overflow);
            amountRaised = fundingCap;
             
            msg.sender.transfer(overflow);
        }


         
        balanceOf[msg.sender] = balanceOf[msg.sender].add(amount);

         
        mainsaleBalanceOf[msg.sender] = mainsaleBalanceOf[msg.sender].add(amount);


        if (currentTime() <= capTime) {
            require(tx.gasprice <= GAS_LIMIT_IN_WEI);
            require(mainsaleBalanceOf[msg.sender] <= cap);

        }

         
        if (!tokenReward.transferFrom(tokenReward.owner(), msg.sender, amount.mul(RATE))) {
            revert();
        }

        FundTransfer(msg.sender, amount, true);
        updateFundingCap();
    }

    function setCap(uint _cap) public onlyOwner {
        cap = _cap;
    }

     
    function registerUser(address contributor)
        public
        onlyOwner
    {
        require(contributor != address(0));
        registry[contributor] = true;
        RegistrationStatusChanged(contributor, true);
    }

      
    function deactivate(address contributor)
        public
        onlyOwner
    {
        require(registry[contributor]);
        registry[contributor] = false;
        RegistrationStatusChanged(contributor, false);
    }

     
    function registerUsers(address[] contributors)
        external
        onlyOwner
    {
        for (uint i = 0; i < contributors.length; i++) {
            registerUser(contributors[i]);
        }
    }

     
    function terminate() external onlyOwner {
        saleClosed = true;
    }

     
    function allocateTokens(address _to, uint amountWei, uint amountMiniQsp) public
            onlyOwner nonReentrant
    {
        amountRaised = amountRaised.add(amountWei);
        require(amountRaised <= fundingCap);

        balanceOf[_to] = balanceOf[_to].add(amountWei);

        if (!tokenReward.transferFrom(tokenReward.owner(), _to, amountMiniQsp)) {
            revert();
        }

        FundTransfer(_to, amountWei, true);
        updateFundingCap();
    }


     
    function ownerSafeWithdrawal() external onlyOwner nonReentrant {
        uint balanceToSend = this.balance;
        beneficiary.transfer(balanceToSend);
        FundTransfer(beneficiary, balanceToSend, false);
    }

     
    function updateFundingCap() internal {
        assert (amountRaised <= fundingCap);
        if (amountRaised == fundingCap) {
             
            fundingCapReached = true;
            saleClosed = true;
            CapReached(beneficiary, amountRaised);
        }
    }

     
    function currentTime() constant returns (uint _currentTime) {
        return now;
    }

    function setDeadline(uint timestamp) public onlyOwner {
        deadline = timestamp;
    }
}