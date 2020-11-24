 

pragma solidity ^0.4.18;

 
contract ERC20Basic {
  uint256 public totalSupply;
  function balanceOf(address who) public constant returns (uint256);
  function transfer(address to, uint256 value) public returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
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




 
contract ERC20 is ERC20Basic {
  function allowance(address owner, address spender) public constant returns (uint256);
  function transferFrom(address from, address to, uint256 value) public returns (bool);
  function approve(address spender, uint256 value) public returns (bool);
  event Approval(address indexed owner, address indexed spender, uint256 value);
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


 
contract Contactable is Ownable{

    string public contactInformation;

     
    function setContactInformation(string info) onlyOwner public {
         contactInformation = info;
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

contract IRefundHandler {
    function handleRefundRequest(address _contributor) external;
}


contract LOCIcoin is StandardToken, Ownable, Contactable {
    string public name = "";
    string public symbol = "";
    uint256 public constant decimals = 18;

    mapping (address => bool) internal allowedOverrideAddresses;

    bool public tokenActive = false;

    modifier onlyIfTokenActiveOrOverride() {
         
         
        require(tokenActive || msg.sender == owner || allowedOverrideAddresses[msg.sender]);
        _;
    }

    modifier onlyIfTokenInactive() {
        require(!tokenActive);
        _;
    }

    modifier onlyIfValidAddress(address _to) {
         
        require(_to != 0x0);
         
        require(_to != address(this));
        _;
    }

    event TokenActivated();

    function LOCIcoin(uint256 _totalSupply, string _contactInformation ) public {
        totalSupply = _totalSupply;
        contactInformation = _contactInformation;

         
        balances[msg.sender] = _totalSupply;
    }

     
     
     
    function approve(address _spender, uint256 _value) public onlyIfTokenActiveOrOverride onlyIfValidAddress(_spender) returns (bool) {
        return super.approve(_spender, _value);
    }

     
     
     
    function transfer(address _to, uint256 _value) public onlyIfTokenActiveOrOverride onlyIfValidAddress(_to) returns (bool) {
        return super.transfer(_to, _value);
    }

    function ownerSetOverride(address _address, bool enable) external onlyOwner {
        allowedOverrideAddresses[_address] = enable;
    }

    function ownerSetVisible(string _name, string _symbol) external onlyOwner onlyIfTokenInactive {        

         
         
         
         
        name = _name;
        symbol = _symbol;
    }

    function ownerActivateToken() external onlyOwner onlyIfTokenInactive {
        require(bytes(symbol).length > 0);

        tokenActive = true;
        TokenActivated();
    }

    function claimRefund(IRefundHandler _refundHandler) external {
        uint256 _balance = balances[msg.sender];

         
        require(_balance > 0);

         
        balances[msg.sender] = 0;

         
         
         
         
         
         
        _refundHandler.handleRefundRequest(msg.sender);

         
         
         
         
         
        balances[owner] = balances[owner].add(_balance);
        Transfer(msg.sender, owner, _balance);
    }
}


contract LOCIsale is Ownable, Pausable, IRefundHandler {
    using SafeMath for uint256;

     
     
    LOCIcoin internal token;

     
    uint256 public start;                
    uint256 public end;                  

    bool public isPresale;               
    bool public isRefunding = false;     

    uint256 public minFundingGoalWei;    
    uint256 public minContributionWei;   
    uint256 public maxContributionWei;   

    uint256 public weiRaised;        
    uint256 public weiRaisedAfterDiscounts;  
    uint256 internal weiForRefund;   

    uint256 public peggedETHUSD;     
    uint256 public hardCap;          
    uint256 public reservedTokens;   
    uint256 public baseRateInCents;  
    uint256 internal startingTokensAmount;  

    mapping (address => uint256) public contributions;

    struct DiscountTranche {
         
         
        uint256 end;
         
        uint8 discount;
         
        uint8 round;
         
        uint256 roundWeiRaised;
         
        uint256 roundTokensSold;
    }
    DiscountTranche[] internal discountTranches;
    uint8 internal currentDiscountTrancheIndex = 0;
    uint8 internal discountTrancheLength = 0;

    event ContributionReceived(address indexed buyer, bool presale, uint8 rate, uint256 value, uint256 tokens);
    event RefundsEnabled();
    event Refunded(address indexed buyer, uint256 weiAmount);
    event ToppedUp();
    event PegETHUSD(uint256 pegETHUSD);

    function LOCIsale(
        address _token,                 
        uint256 _peggedETHUSD,           
        uint256 _hardCapETHinWei,        
        uint256 _reservedTokens,         
        bool _isPresale,                 
        uint256 _minFundingGoalWei,      
        uint256 _minContributionWei,     
        uint256 _maxContributionWei,     
        uint256 _start,                  
        uint256 _durationHours,          
        uint256 _baseRateInCents,        
        uint256[] _hourBasedDiscounts    
    ) public {
        require(_token != 0x0);
         
        require(_maxContributionWei == 0 || _maxContributionWei > _minContributionWei);
         
        require(_durationHours > 0);

        token = LOCIcoin(_token);

        peggedETHUSD = _peggedETHUSD;
        hardCap = _hardCapETHinWei;
        reservedTokens = _reservedTokens;

        isPresale = _isPresale;

        start = _start;
        end = start.add(_durationHours.mul(1 hours));

        minFundingGoalWei = _minFundingGoalWei;
        minContributionWei = _minContributionWei;
        maxContributionWei = _maxContributionWei;

        baseRateInCents = _baseRateInCents;

         
         
        uint256 _end = start;

        uint _tranche_round = 0;

        for (uint i = 0; i < _hourBasedDiscounts.length; i += 2) {
             
            _end = _end.add(_hourBasedDiscounts[i].mul(1 hours));

             
            require(_end <= end);

            _tranche_round += 1;

            discountTranches.push(DiscountTranche({ end:_end,
                                                    discount:uint8(_hourBasedDiscounts[i + 1]),
                                                    round:uint8(_tranche_round),
                                                    roundWeiRaised:0,
                                                    roundTokensSold:0}));

            discountTrancheLength = uint8(i+1);
        }
    }

    function determineDiscountTranche() internal returns (uint256, uint8, uint8) {
        if (currentDiscountTrancheIndex >= discountTranches.length) {
            return(0, 0, 0);
        }

        DiscountTranche storage _dt = discountTranches[currentDiscountTrancheIndex];
        if (_dt.end < now) {
             
            while (++currentDiscountTrancheIndex < discountTranches.length) {
                _dt = discountTranches[currentDiscountTrancheIndex];
                if (_dt.end > now) {
                    break;
                }
            }
        }

         
         
        if (_dt.round > 1 && _dt.roundTokensSold > 0 && _dt.round < discountTranches.length) {
            uint256 _trancheCountExceptForOne = discountTranches.length-1;
            uint256 _tokensSoldFirstRound = discountTranches[0].roundTokensSold;
            uint256 _allowedTokensThisRound = (startingTokensAmount.sub(_tokensSoldFirstRound)).div(_trancheCountExceptForOne);

            if (_dt.roundTokensSold > _allowedTokensThisRound) {
                currentDiscountTrancheIndex = currentDiscountTrancheIndex + 1;
                _dt = discountTranches[currentDiscountTrancheIndex];
            }
        }

        uint256 _end = 0;
        uint8 _rate = 0;
        uint8 _round = 0;

         
         
        if (currentDiscountTrancheIndex < discountTranches.length) {
            _end = _dt.end;
            _rate = _dt.discount;
            _round = _dt.round;
        } else {
            _end = end;
            _rate = 0;
            _round = discountTrancheLength + 1;
        }

        return (_end, _rate, _round);
    }

    function() public payable whenNotPaused {
        require(!isRefunding);
        require(msg.sender != 0x0);
        require(msg.value >= minContributionWei);
        require(start <= now && end >= now);

         
        uint256 _weiContributionAllowed = maxContributionWei > 0 ? maxContributionWei.sub(contributions[msg.sender]) : msg.value;
        if (maxContributionWei > 0) {
            require(_weiContributionAllowed > 0);
        }

         
        uint256 _tokensRemaining = token.balanceOf(address(this)).sub( reservedTokens );
        require(_tokensRemaining > 0);

        if (startingTokensAmount == 0) {
            startingTokensAmount = _tokensRemaining;  
        }

         
        uint256 _weiContribution = msg.value;
        if (_weiContribution > _weiContributionAllowed) {
            _weiContribution = _weiContributionAllowed;
        }

         
        if (hardCap > 0 && weiRaised.add(_weiContribution) > hardCap) {
            _weiContribution = hardCap.sub( weiRaised );
        }

         
        uint256 _tokens = _weiContribution.mul(peggedETHUSD).mul(100).div(baseRateInCents);
        var (, _rate, _round) = determineDiscountTranche();
        if (_rate > 0) {
            _tokens = _weiContribution.mul(peggedETHUSD).mul(100).div(_rate);
        }

        if (_tokens > _tokensRemaining) {
             
            _tokens = _tokensRemaining;
            if (_rate > 0) {
                _weiContribution = _tokens.mul(_rate).div(100).div(peggedETHUSD);
            } else {
                _weiContribution = _tokens.mul(baseRateInCents).div(100).div(peggedETHUSD);
            }
        }

         
        contributions[msg.sender] = contributions[msg.sender].add(_weiContribution);
        ContributionReceived(msg.sender, isPresale, _rate, _weiContribution, _tokens);

        require(token.transfer(msg.sender, _tokens));

        weiRaised = weiRaised.add(_weiContribution);  

        if (discountTrancheLength > 0 && _round > 0 && _round <= discountTrancheLength) {
            discountTranches[_round-1].roundWeiRaised = discountTranches[_round-1].roundWeiRaised.add(_weiContribution);
            discountTranches[_round-1].roundTokensSold = discountTranches[_round-1].roundTokensSold.add(_tokens);
        }
        if (discountTrancheLength > 0 && _round > discountTrancheLength) {
            weiRaisedAfterDiscounts = weiRaisedAfterDiscounts.add(_weiContribution);
        }

        uint256 _weiRefund = msg.value.sub(_weiContribution);
        if (_weiRefund > 0) {
            msg.sender.transfer(_weiRefund);
        }
    }

     
    function ownerTopUp() external payable {}

    function setReservedTokens( uint256 _reservedTokens ) onlyOwner public {
        reservedTokens = _reservedTokens;        
    }

    function pegETHUSD(uint256 _peggedETHUSD) onlyOwner public {
        peggedETHUSD = _peggedETHUSD;
        PegETHUSD(peggedETHUSD);
    }

    function setHardCap( uint256 _hardCap ) onlyOwner public {
        hardCap = _hardCap;
    }

    function peggedETHUSD() constant onlyOwner public returns(uint256) {
        return peggedETHUSD;
    }

    function hardCapETHInWeiValue() constant onlyOwner public returns(uint256) {
        return hardCap;
    }

    function weiRaisedDuringRound(uint8 round) constant onlyOwner public returns(uint256) {
        require( round > 0 && round <= discountTrancheLength );
        return discountTranches[round-1].roundWeiRaised;
    }

    function tokensRaisedDuringRound(uint8 round) constant onlyOwner public returns(uint256) {
        require( round > 0 && round <= discountTrancheLength );
        return discountTranches[round-1].roundTokensSold;
    }

    function weiRaisedAfterDiscountRounds() constant onlyOwner public returns(uint256) {
        return weiRaisedAfterDiscounts;
    }

    function totalWeiRaised() constant onlyOwner public returns(uint256) {
        return weiRaised;
    }

    function setStartingTokensAmount(uint256 _startingTokensAmount) onlyOwner public {
        startingTokensAmount = _startingTokensAmount;
    }

    function ownerEnableRefunds() external onlyOwner {
         
         
        require(paused || now > end);
        require(!isRefunding);

        weiForRefund = this.balance;
        isRefunding = true;
        RefundsEnabled();
    }

    function ownerTransferWei(address _beneficiary, uint256 _value) external onlyOwner {
        require(_beneficiary != 0x0);
        require(_beneficiary != address(token));
         
        require(minFundingGoalWei == 0 || weiRaised >= minFundingGoalWei);

         
        uint256 _amount = _value > 0 ? _value : this.balance;

        _beneficiary.transfer(_amount);
    }

    function ownerRecoverTokens(address _beneficiary) external onlyOwner {
        require(_beneficiary != 0x0);
        require(_beneficiary != address(token));
        require(paused || now > end);

        uint256 _tokensRemaining = token.balanceOf(address(this));
        if (_tokensRemaining > 0) {
            token.transfer(_beneficiary, _tokensRemaining);
        }
    }

    function handleRefundRequest(address _contributor) external {
         
         
         
         

        require(isRefunding);
         
         
        require(msg.sender == address(token));

        uint256 _wei = contributions[_contributor];

         
         
        require(_wei > 0);

         
        if (weiRaised > weiForRefund) {
            uint256 _n  = weiForRefund.mul(_wei).div(weiRaised);
            require(_n < _wei);
            _wei = _n;
        }

         
         
         
         
        contributions[_contributor] = 0;

         
        _contributor.transfer(_wei);

        Refunded(_contributor, _wei);
    }
}