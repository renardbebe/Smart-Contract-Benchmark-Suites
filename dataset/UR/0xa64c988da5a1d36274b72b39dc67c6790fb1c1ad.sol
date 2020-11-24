 

pragma solidity ^0.4.20;


 
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

  mapping (address => mapping (address => uint256)) internal allowed;


   
  function transferFrom(address _from, address _to, uint256 _value) public returns (bool) {
    require(_to != address(0));
    require(_value <= balances[_from]);
    require(_value <= allowed[_from][msg.sender]);

    balances[_from] = balances[_from].sub(_value);
    balances[_to] = balances[_to].add(_value);
    allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
    emit Transfer(_from, _to, _value);
    return true;
  }

   
  function approve(address _spender, uint256 _value) public returns (bool) {
    allowed[msg.sender][_spender] = _value;
    emit Approval(msg.sender, _spender, _value);
    return true;
  }

   
  function allowance(address _owner, address _spender) public view returns (uint256) {
    return allowed[_owner][_spender];
  }

   
  function increaseApproval(address _spender, uint _addedValue) public returns (bool) {
    allowed[msg.sender][_spender] = allowed[msg.sender][_spender].add(_addedValue);
    emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
    return true;
  }

   
  function decreaseApproval(address _spender, uint _subtractedValue) public returns (bool) {
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
    emit Pause();
  }

   
  function unpause() onlyOwner whenPaused public {
    paused = false;
    emit Unpause();
  }
}


contract ufoodoToken is StandardToken, Ownable {
    using SafeMath for uint256;

     
    address public vault = this;

    string public name = "ufoodo Token";
    string public symbol = "UFT";
    uint8 public decimals = 18;

     
    uint256 public INITIAL_SUPPLY = 500000000 * (10**uint256(decimals));
     
    uint256 public supplyDAICO = INITIAL_SUPPLY.mul(80).div(100);

    address public salesAgent;
    mapping (address => bool) public owners;

    event SalesAgentPermissionsTransferred(address indexed previousSalesAgent, address indexed newSalesAgent);
    event SalesAgentRemoved(address indexed currentSalesAgent);

     
    function supplySeed() public view returns (uint256) {
        uint256 _supplySeed = INITIAL_SUPPLY.mul(20).div(100);
        return _supplySeed;
    }
     
    function ufoodoToken() public {
        totalSupply_ = INITIAL_SUPPLY;
        balances[msg.sender] = INITIAL_SUPPLY;
        emit Transfer(0x0, msg.sender, INITIAL_SUPPLY);
    }
     
    function transferSalesAgentPermissions(address _salesAgent) onlyOwner public {
        emit SalesAgentPermissionsTransferred(salesAgent, _salesAgent);
        salesAgent = _salesAgent;
    }

     
    function removeSalesAgent() onlyOwner public {
        emit SalesAgentRemoved(salesAgent);
        salesAgent = address(0);
    }

    function transferFromVault(address _from, address _to, uint256 _amount) public {
        require(salesAgent == msg.sender);
        balances[vault] = balances[vault].sub(_amount);
        balances[_to] = balances[_to].add(_amount);
        emit Transfer(_from, _to, _amount);
    }

     
     
    function transferDaico(address _to) public onlyOwner returns(bool) {
        require(now >= 1535810400);

        balances[vault] = balances[vault].sub(supplyDAICO);
        balances[_to] = balances[_to].add(supplyDAICO);
        emit Transfer(vault, _to, supplyDAICO);
        return(true);
    }

}

contract SeedSale is Ownable, Pausable {
    using SafeMath for uint256;

     
    ufoodoToken public token;

     
     
    uint256 public constant seedStartTime = 1522591200;
     
    uint256 public constant seedEndTime = 1527775200;

    uint256 public seedSupply_ = 0;

     
    uint256 public fundsRaised = 140 ether;

     
    uint256 public fundsRaisedFinalized = 140 ether;  

     
    uint256 public releasedLockedAmount = 0;

     
    uint256 public pendingUFT = 0;
     
    uint256 public concludeUFT = 0;

    uint256 public constant softCap = 200 ether;
    uint256 public constant hardCap = 3550 ether;
    uint256 public constant minContrib = 0.1 ether;

    uint256 public lockedTeamUFT = 0;
    uint256 public privateReservedUFT = 0;

     
    bool public SoftCapReached = false;
    bool public hardCapReached = false;
    bool public seedSaleFinished = false;

     
    bool public refundAllowed = false;

     
    address public fundWallet = 0xf7d4C80DE0e2978A1C5ef3267F488B28499cD22E;

     
    mapping(address => uint256) public weiContributedPending;
     
    mapping(address => uint256) public weiContributedConclude;
     
    mapping(address => uint256) public pendingAmountUFT;

    event OpenTier(uint256 activeTier);
    event LogContributionPending(address contributor, uint256 amountWei, uint256 tokenAmount, uint256 activeTier, uint256 timestamp);
    event LogContributionConclude(address contributor, uint256 amountWei, uint256 tokenAmount, uint256 timeStamp);
    event ValidationFailed(address contributor, uint256 amountWeiRefunded, uint timestamp);

     
    uint public activeTier = 0;

     
    uint256[8] public tierCap = [
        400 ether,
        420 ether,
        380 ether,
        400 ether,
        410 ether,
        440 ether,
        460 ether,
        500 ether
    ];

     
     
    uint256[8] public tierTokens = [
        17500,  
        16875,  
        16250,  
        15625,  
        15000,  
        13750,  
        13125,  
        12500   
    ];

     
    uint256[8] public activeFundRaisedTier = [
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0
    ];

     
    function SeedSale(address _vault) public {
        token = ufoodoToken(_vault);
        privateReservedUFT = token.supplySeed().mul(4).div(100);
        lockedTeamUFT = token.supplySeed().mul(20).div(100);
        seedSupply_ = token.supplySeed();
    }

    function seedStarted() public view returns (bool) {
        return now >= seedStartTime;
    }

    function seedEnded() public view returns (bool) {
        return now >= seedEndTime || fundsRaised >= hardCap;
    }

    modifier checkContribution() {
        require(canContribute());
        _;
    }

    function canContribute() internal view returns(bool) {
        if(!seedStarted() || seedEnded()) {
            return false;
        }
        if(msg.value < minContrib) {
            return false;
        }
        return true;
    }

     
    function() payable public whenNotPaused {
        buyUFT(msg.sender);
    }

     
    function buyUFT(address contributor) public whenNotPaused checkContribution payable {
        uint256 weiAmount = msg.value;
        uint256 refund = 0;
        uint256 _tierIndex = activeTier;
        uint256 _activeTierCap = tierCap[_tierIndex];
        uint256 _activeFundRaisedTier = activeFundRaisedTier[_tierIndex];

        require(_activeFundRaisedTier < _activeTierCap);

         
        uint256 tierCapOverSold = _activeTierCap.sub(_activeFundRaisedTier);

         
         
        if(tierCapOverSold < weiAmount) {
            weiAmount = tierCapOverSold;
            refund = msg.value.sub(weiAmount);

        }
         
        uint256 amountUFT = weiAmount.mul(tierTokens[_tierIndex]);

         
        fundsRaised = fundsRaised.add(weiAmount);
        activeFundRaisedTier[_tierIndex] = activeFundRaisedTier[_tierIndex].add(weiAmount);
        weiContributedPending[contributor] = weiContributedPending[contributor].add(weiAmount);
        pendingAmountUFT[contributor] = pendingAmountUFT[contributor].add(amountUFT);
        pendingUFT = pendingUFT.add(amountUFT);

         
        if(refund > 0) {
            msg.sender.transfer(refund);
        }

        emit LogContributionPending(contributor, weiAmount, amountUFT, _tierIndex, now);
    }

    function softCapReached() public returns (bool) {
        if (fundsRaisedFinalized >= softCap) {
            SoftCapReached = true;
            return true;
        }
        return false;
    }

     
     
     
    function nextTier() onlyOwner public {
        require(paused == true);
        require(activeTier < 7);
        uint256 _tierIndex = activeTier;
        activeTier = _tierIndex +1;
        emit OpenTier(activeTier);
    }

     
     
     
    function validationPassed(address contributor) onlyOwner public returns (bool) {
        require(contributor != 0x0);

        uint256 amountFinalized = pendingAmountUFT[contributor];
        pendingAmountUFT[contributor] = 0;
        token.transferFromVault(token, contributor, amountFinalized);

         
        uint256 _fundsRaisedFinalized = fundsRaisedFinalized.add(weiContributedPending[contributor]);
        fundsRaisedFinalized = _fundsRaisedFinalized;
        concludeUFT = concludeUFT.add(amountFinalized);

        weiContributedConclude[contributor] = weiContributedConclude[contributor].add(weiContributedPending[contributor]);

        emit LogContributionConclude(contributor, weiContributedPending[contributor], amountFinalized, now);
        softCapReached();
         

        return true;
    }

     
     
    function validationFailed(address contributor) onlyOwner public returns (bool) {
        require(contributor != 0x0);
        require(weiContributedPending[contributor] > 0);

        uint256 currentBalance = weiContributedPending[contributor];

        weiContributedPending[contributor] = 0;
        contributor.transfer(currentBalance);
        emit ValidationFailed(contributor, currentBalance, now);
        return true;
    }

     
    function refund() public {
        require(refundAllowed);
        require(!SoftCapReached);
        require(weiContributedPending[msg.sender] > 0);

        uint256 currentBalance = weiContributedPending[msg.sender];

        weiContributedPending[msg.sender] = 0;
        msg.sender.transfer(currentBalance);
    }


    
    function withdrawFunds(uint256 _weiAmount) public onlyOwner {
        require(SoftCapReached);
        fundWallet.transfer(_weiAmount);
    }

     
    function seedSaleTokenLeft(address _tokenContract) public onlyOwner {
        require(seedEnded());
        uint256 amountLeft = pendingUFT.sub(concludeUFT);
        token.transferFromVault(token, _tokenContract, amountLeft );
    }


    function vestingToken(address _beneficiary) public onlyOwner returns (bool) {
      require(SoftCapReached);
      uint256 release_1 = seedStartTime.add(180 days);
      uint256 release_2 = release_1.add(180 days);
      uint256 release_3 = release_2.add(180 days);
      uint256 release_4 = release_3.add(180 days);

       
      uint256 lockedAmount_1 = lockedTeamUFT.mul(25).div(100);
      uint256 lockedAmount_2 = lockedTeamUFT.mul(25).div(100);
      uint256 lockedAmount_3 = lockedTeamUFT.mul(25).div(100);
      uint256 lockedAmount_4 = lockedTeamUFT.mul(25).div(100);

      if(seedStartTime >= release_1 && releasedLockedAmount < lockedAmount_1) {
        token.transferFromVault(token, _beneficiary, lockedAmount_1 );
        releasedLockedAmount = releasedLockedAmount.add(lockedAmount_1);
        return true;

      } else if(seedStartTime >= release_2 && releasedLockedAmount < lockedAmount_2.mul(2)) {
        token.transferFromVault(token, _beneficiary, lockedAmount_2 );
        releasedLockedAmount = releasedLockedAmount.add(lockedAmount_2);
        return true;

      } else if(seedStartTime >= release_3 && releasedLockedAmount < lockedAmount_3.mul(3)) {
        token.transferFromVault(token, _beneficiary, lockedAmount_3 );
        releasedLockedAmount = releasedLockedAmount.add(lockedAmount_3);
        return true;

      } else if(seedStartTime >= release_4 && releasedLockedAmount < lockedAmount_4.mul(4)) {
        token.transferFromVault(token, _beneficiary, lockedAmount_4 );
        releasedLockedAmount = releasedLockedAmount.add(lockedAmount_4);
        return true;
      }

    }

     
    function transferPrivateReservedUFT(address _beneficiary, uint256 _amount) public onlyOwner {
        require(SoftCapReached);
        require(_amount > 0);
        require(privateReservedUFT >= _amount);

        token.transferFromVault(token, _beneficiary, _amount);
        privateReservedUFT = privateReservedUFT.sub(_amount);

    }

     function finalizeSeedSale() public onlyOwner {
        if(seedStartTime >= seedEndTime && SoftCapReached) {

         
        uint256 bountyAmountUFT = token.supplySeed().mul(5).div(100);
        token.transferFromVault(token, fundWallet, bountyAmountUFT);

         
        uint256 reservedCompanyUFT = token.supplySeed().mul(20).div(100);
        token.transferFromVault(token, fundWallet, reservedCompanyUFT);

        } else if(seedStartTime >= seedEndTime && !SoftCapReached) {

             
            refundAllowed = true;

            token.transferFromVault(token, owner, seedSupply_);
            seedSupply_ = 0;

        }
    }

}