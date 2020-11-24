 

 
pragma solidity ^0.4.18;


 
contract ERC20Basic {
  uint256 public totalSupply;
  function balanceOf(address who) public view returns (uint256);
  function transfer(address to, uint256 value) public returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
}

 
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

 
pragma solidity ^0.4.18;






 
contract BasicToken is ERC20Basic {
  using SafeMath for uint256;

  mapping(address => uint256) balances;

   
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

 
pragma solidity ^0.4.18;





 
contract ERC20 is ERC20Basic {
  function allowance(address owner, address spender) public view returns (uint256);
  function transferFrom(address from, address to, uint256 value) public returns (bool);
  function approve(address spender, uint256 value) public returns (bool);
  event Approval(address indexed owner, address indexed spender, uint256 value);
}

 
pragma solidity ^0.4.18;






 
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

 
pragma solidity ^0.4.18;


 
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

 
pragma solidity ^0.4.18;







 

contract MintableToken is StandardToken, Ownable {
  event Mint(address indexed to, uint256 amount);
  event MintFinished();

  bool public mintingFinished = false;


  modifier canMint() {
    require(!mintingFinished);
    _;
  }

   
  function mint(address _to, uint256 _amount) onlyOwner canMint public returns (bool) {
    totalSupply = totalSupply.add(_amount);
    balances[_to] = balances[_to].add(_amount);
    Mint(_to, _amount);
    Transfer(address(0), _to, _amount);
    return true;
  }

   
  function finishMinting() onlyOwner canMint public returns (bool) {
    mintingFinished = true;
    MintFinished();
    return true;
  }
}

 
pragma solidity ^0.4.18;




 
contract Crowdsale {
  using SafeMath for uint256;

   
  MintableToken public token;

   
  uint256 public startTime;
  uint256 public endTime;

   
  address public wallet;

   
  uint256 public rate;

   
  uint256 public weiRaised;

   
  event TokenPurchase(address indexed purchaser, address indexed beneficiary, uint256 value, uint256 amount);


  function Crowdsale(uint256 _startTime, uint256 _endTime, uint256 _rate, address _wallet) public {
    require(_startTime >= now);
    require(_endTime >= _startTime);
    require(_rate > 0);
    require(_wallet != address(0));

    token = createTokenContract();
    startTime = _startTime;
    endTime = _endTime;
    rate = _rate;
    wallet = _wallet;
  }

   
   
  function createTokenContract() internal returns (MintableToken) {
    return new MintableToken();
  }


   
  function () external payable {
    buyTokens(msg.sender);
  }

   
  function buyTokens(address beneficiary) public payable {
    require(beneficiary != address(0));
    require(validPurchase());

    uint256 weiAmount = msg.value;

     
    uint256 tokens = weiAmount.mul(rate);

     
    weiRaised = weiRaised.add(weiAmount);

    token.mint(beneficiary, tokens);
    TokenPurchase(msg.sender, beneficiary, weiAmount, tokens);

    forwardFunds();
  }

   
   
  function forwardFunds() internal {
    wallet.transfer(msg.value);
  }

   
  function validPurchase() internal view returns (bool) {
    bool withinPeriod = now >= startTime && now <= endTime;
    bool nonZeroPurchase = msg.value != 0;
    return withinPeriod && nonZeroPurchase;
  }

   
  function hasEnded() public view returns (bool) {
    return now > endTime;
  }


}

 
pragma solidity ^0.4.18;




 
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

 
pragma solidity ^0.4.18;






 
contract TokenVesting is Ownable {
  using SafeMath for uint256;
  using SafeERC20 for ERC20Basic;

  event Released(uint256 amount);
  event Revoked();

   
  address public beneficiary;

  uint256 public cliff;
  uint256 public start;
  uint256 public duration;

  bool public revocable;

  mapping (address => uint256) public released;
  mapping (address => bool) public revoked;

   
  function TokenVesting(address _beneficiary, uint256 _start, uint256 _cliff, uint256 _duration, bool _revocable) public {
    require(_beneficiary != address(0));
    require(_cliff <= _duration);

    beneficiary = _beneficiary;
    revocable = _revocable;
    duration = _duration;
    cliff = _start.add(_cliff);
    start = _start;
  }

   
  function release(ERC20Basic token) public {
    uint256 unreleased = releasableAmount(token);

    require(unreleased > 0);

    released[token] = released[token].add(unreleased);

    token.safeTransfer(beneficiary, unreleased);

    Released(unreleased);
  }

   
  function revoke(ERC20Basic token) public onlyOwner {
    require(revocable);
    require(!revoked[token]);

    uint256 balance = token.balanceOf(this);

    uint256 unreleased = releasableAmount(token);
    uint256 refund = balance.sub(unreleased);

    revoked[token] = true;

    token.safeTransfer(owner, refund);

    Revoked();
  }

   
  function releasableAmount(ERC20Basic token) public view returns (uint256) {
    return vestedAmount(token).sub(released[token]);
  }

   
  function vestedAmount(ERC20Basic token) public view returns (uint256) {
    uint256 currentBalance = token.balanceOf(this);
    uint256 totalBalance = currentBalance.add(released[token]);

    if (now < cliff) {
      return 0;
    } else if (now >= start.add(duration) || revoked[token]) {
      return totalBalance;
    } else {
      return totalBalance.mul(now.sub(start)).div(duration);
    }
  }
}

 
pragma solidity ^0.4.18;





 
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

 
pragma solidity ^0.4.18;




 

contract PausableToken is StandardToken, Pausable {

  function transfer(address _to, uint256 _value) public whenNotPaused returns (bool) {
    return super.transfer(_to, _value);
  }

  function transferFrom(address _from, address _to, uint256 _value) public whenNotPaused returns (bool) {
    return super.transferFrom(_from, _to, _value);
  }

  function approve(address _spender, uint256 _value) public whenNotPaused returns (bool) {
    return super.approve(_spender, _value);
  }

  function increaseApproval(address _spender, uint _addedValue) public whenNotPaused returns (bool success) {
    return super.increaseApproval(_spender, _addedValue);
  }

  function decreaseApproval(address _spender, uint _subtractedValue) public whenNotPaused returns (bool success) {
    return super.decreaseApproval(_spender, _subtractedValue);
  }
}

 
 
pragma solidity ^0.4.18;




contract MtnToken is MintableToken, PausableToken {
    string public constant name = "MedToken";
    string public constant symbol = "MTN";
    uint8 public constant decimals = 18;

     
    function MtnToken() public {
         
        paused = true;
    }
}

 
 
pragma solidity ^0.4.18;






contract MtnCrowdsale is Ownable, Crowdsale {
     
    uint256 public constant TOTAL_TOKEN_CAP = 500e6 * 1e18;    
    uint256 public constant CROWDSALE_TOKENS = 175e6 * 1e18;   
    uint256 public constant TOTAL_TEAM_TOKENS = 170e6 * 1e18;  
    uint256 public constant TEAM_TOKENS0 = 50e6 * 1e18;        
    uint256 public constant TEAM_TOKENS1 = 60e6 * 1e18;        
    uint256 public constant TEAM_TOKENS2 = 60e6 * 1e18;        
    uint256 public constant COMMUNITY_TOKENS = 155e6 * 1e18;   

    uint256 public constant MAX_CONTRIBUTION_USD = 5000;       
    uint256 public constant USD_CENT_PER_TOKEN = 25;           

    uint256 public constant VESTING_DURATION_4Y = 4 years;
    uint256 public constant VESTING_DURATION_2Y = 2 years;

     
    mapping(address => bool) public isWhitelisted;

     
     
    mapping(address => bool) public isManager;

    uint256 public maxContributionInWei;
    uint256 public tokensMinted;                             
    bool public capReached;                                  
    mapping(address => uint256) public totalInvestedPerAddress;

    address public beneficiaryWallet;

     
    address public teamVesting2Years;
    address public teamVesting4Years;
    address public communityVesting4Years;

     
    bool public isCrowdsaleOver;

     
    event ChangedManager(address manager, bool active);
    event PresaleMinted(address indexed beneficiary, uint256 tokenAmount);
    event ChangedInvestorWhitelisting(address indexed investor, bool whitelisted);

     
    modifier onlyManager() {
        require(isManager[msg.sender]);
        _;
    }

     
    modifier onlyPresalePhase() {
        require(now < startTime);
        _;
    }

    modifier onlyCrowdsalePhase() {
        require(now >= startTime && now < endTime && !isCrowdsaleOver);
        _;
    }

    modifier respectCrowdsaleCap(uint256 _amount) {
        require(tokensMinted.add(_amount) <= CROWDSALE_TOKENS);
        _;
    }

    modifier onlyCrowdSaleOver() {
        require(isCrowdsaleOver || now > endTime || capReached);
        _;
    }

    modifier onlyValidAddress(address _address) {
        require(_address != address(0));
        _;
    }

     
    function MtnCrowdsale(
        uint256 _startTime,
        uint256 _endTime,
        uint256 _usdPerEth,
        address _wallet,
        address _beneficiaryWallet
        )
        Crowdsale(_startTime, _endTime, (_usdPerEth.mul(1e2)).div(USD_CENT_PER_TOKEN), _wallet)
        public
        onlyValidAddress(_beneficiaryWallet)
    {
        require(TOTAL_TOKEN_CAP == CROWDSALE_TOKENS.add(TOTAL_TEAM_TOKENS).add(COMMUNITY_TOKENS));
        require(TOTAL_TEAM_TOKENS == TEAM_TOKENS0.add(TEAM_TOKENS1).add(TEAM_TOKENS2));
        setManager(msg.sender, true);

        beneficiaryWallet = _beneficiaryWallet;

        maxContributionInWei = (MAX_CONTRIBUTION_USD.mul(1e18)).div(_usdPerEth);

        mintTeamTokens();
        mintCommunityTokens();
    }

     
    function createTokenContract() internal returns (MintableToken) {
        return new MtnToken();
    }

     
    function setManager(address _manager, bool _active) public onlyOwner onlyValidAddress(_manager) {
        isManager[_manager] = _active;
        ChangedManager(_manager, _active);
    }

     
    function whiteListInvestor(address _investor) public onlyManager onlyValidAddress(_investor) {
        isWhitelisted[_investor] = true;
        ChangedInvestorWhitelisting(_investor, true);
    }

     
    function batchWhiteListInvestors(address[] _investors) public onlyManager {
        for (uint256 c; c < _investors.length; c = c.add(1)) {
            whiteListInvestor(_investors[c]);
        }
    }

     
    function unWhiteListInvestor(address _investor) public onlyManager onlyValidAddress(_investor) {
        isWhitelisted[_investor] = false;
        ChangedInvestorWhitelisting(_investor, false);
    }

    
    function mintTokenPreSale(address _beneficiary, uint256 _amount) public onlyOwner onlyPresalePhase onlyValidAddress(_beneficiary) respectCrowdsaleCap(_amount) {
        require(_amount > 0);

        tokensMinted = tokensMinted.add(_amount);
        token.mint(_beneficiary, _amount);
        PresaleMinted(_beneficiary, _amount);
    }

    
    function batchMintTokenPresale(address[] _beneficiaries, uint256[] _amounts) public onlyOwner onlyPresalePhase {
        require(_beneficiaries.length == _amounts.length);

        for (uint256 i; i < _beneficiaries.length; i = i.add(1)) {
            mintTokenPreSale(_beneficiaries[i], _amounts[i]);
        }
    }

    
    function buyTokens(address _beneficiary) public payable onlyCrowdsalePhase onlyValidAddress(_beneficiary) {
        require(isWhitelisted[msg.sender]);
        require(validPurchase());

        uint256 overflowTokens;
        uint256 refundWeiAmount;
        bool overMaxInvestmentAllowed;

        uint256 investedWeiAmount = msg.value;

         
         
        uint256 totalInvestedWeiAmount = investedWeiAmount.add(totalInvestedPerAddress[msg.sender]);
        if (totalInvestedWeiAmount > maxContributionInWei) {
            overMaxInvestmentAllowed = true;
            refundWeiAmount = totalInvestedWeiAmount.sub(maxContributionInWei);
            investedWeiAmount = investedWeiAmount.sub(refundWeiAmount);
        }

        uint256 tokenAmount = investedWeiAmount.mul(rate);
        uint256 tempMintedTokens = tokensMinted.add(tokenAmount);  

         
         
        if (tempMintedTokens >= CROWDSALE_TOKENS) {
            capReached = true;
            overflowTokens = tempMintedTokens.sub(CROWDSALE_TOKENS);
            tokenAmount = tokenAmount.sub(overflowTokens);
            refundWeiAmount = overflowTokens.div(rate);
            investedWeiAmount = investedWeiAmount.sub(refundWeiAmount);
        }

        weiRaised = weiRaised.add(investedWeiAmount);

        tokensMinted = tokensMinted.add(tokenAmount);
        TokenPurchase(msg.sender, _beneficiary, investedWeiAmount, tokenAmount);
        totalInvestedPerAddress[msg.sender] = totalInvestedPerAddress[msg.sender].add(investedWeiAmount);
        token.mint(_beneficiary, tokenAmount);

         
         
        if (capReached || overMaxInvestmentAllowed) {
            msg.sender.transfer(refundWeiAmount);
            wallet.transfer(investedWeiAmount);
        } else {
            forwardFunds();
        }
    }

    
    function closeCrowdsale() public onlyOwner onlyCrowdsalePhase {
        isCrowdsaleOver = true;
    }

    
    function finalize() public onlyOwner onlyCrowdSaleOver {
         
        MintableToken(token).finishMinting();
        PausableToken(token).unpause();
    }

     

     
    function mintTeamTokens() private {
        token.mint(beneficiaryWallet, TEAM_TOKENS0);

        TokenVesting newVault1 = new TokenVesting(beneficiaryWallet, now, 0, VESTING_DURATION_2Y, false);
        teamVesting2Years = address(newVault1);  
        token.mint(address(newVault1), TEAM_TOKENS1);

        TokenVesting newVault2 = new TokenVesting(beneficiaryWallet, now, 0, VESTING_DURATION_4Y, false);
        teamVesting4Years = address(newVault2);  
        token.mint(address(newVault2), TEAM_TOKENS2);
    }

     
    function mintCommunityTokens() private {
        TokenVesting newVault = new TokenVesting(beneficiaryWallet, now, 0, VESTING_DURATION_4Y, false);
        communityVesting4Years = address(newVault);  
        token.mint(address(newVault), COMMUNITY_TOKENS);
    }

     
    function validPurchase() internal view respectCrowdsaleCap(0) returns (bool) {
        require(!capReached);
        require(totalInvestedPerAddress[msg.sender] < maxContributionInWei);

        return super.validPurchase();
    }
}