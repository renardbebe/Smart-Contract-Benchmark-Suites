 

 
pragma solidity ^0.4.20;

 
 
 
contract SafeMath {
  uint256 constant private MAX_UINT256 =
    0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF;

   
  function safeAdd (uint256 x, uint256 y)
  pure internal
  returns (uint256 z) {
    assert (x <= MAX_UINT256 - y);
    return x + y;
  }

   
  function safeSub (uint256 x, uint256 y)
  pure internal
  returns (uint256 z) {
    assert (x >= y);
    return x - y;
  }

   
  function safeMul (uint256 x, uint256 y)
  pure internal
  returns (uint256 z) {
    if (y == 0) return 0;  
    assert (x <= MAX_UINT256 / y);
    return x * y;
  }
}

contract Token {
   
  function totalSupply () public view returns (uint256 supply);

   
  function balanceOf (address _owner) public view returns (uint256 balance);

   
  function transfer (address _to, uint256 _value)
  public returns (bool success);

   
  function transferFrom (address _from, address _to, uint256 _value)
  public returns (bool success);

   
  function approve (address _spender, uint256 _value)
  public returns (bool success);

   
  function allowance (address _owner, address _spender)
  public view returns (uint256 remaining);

   
  event Transfer (address indexed _from, address indexed _to, uint256 _value);

   
  event Approval (
    address indexed _owner, address indexed _spender, uint256 _value);
}

contract OrisSpace {
   
  function start (uint256 _returnAmount) public;
}

contract OrgonToken is Token {
   
  function createTokens (uint256 _value) public returns (bool);

   
  function burnTokens (uint256 _value) public returns (bool);
}

 
contract JustPriceProtocol is SafeMath {
   
  uint256 internal constant TWO_128 = 0x100000000000000000000000000000000;

   
  uint256 internal constant SALE_START_TIME = 1524117600;

   
  uint256 internal constant RESERVE_DEADLINE = 1531008000;

   
  uint256 internal constant RESERVE_MAX_AMOUNT = 72500 ether;

   
  uint256 internal constant RESERVE_MIN_AMOUNT = 30000 ether;

   
  uint256 internal constant RESERVE_MAX_TOKENS = 82881476.72e9;

   
  uint256 internal constant RESERVE_RATIO = 72500 ether / 725000000e9;

   
  uint256 internal constant RESERVE_THRESHOLD_1 = 10000 ether;

   
  uint256 internal constant RESERVE_PRICE_1 = 0.00080 ether / 1e9;

   
  uint256 internal constant RESERVE_THRESHOLD_2 = 20000 ether;

   
  uint256 internal constant RESERVE_PRICE_2 = 0.00082 ether / 1e9;

   
  uint256 internal constant RESERVE_THRESHOLD_3 = 30000 ether;

   
  uint256 internal constant RESERVE_PRICE_3 = 0.00085 ether / 1e9;

   
  uint256 internal constant RESERVE_THRESHOLD_4 = 40000 ether;

   
  uint256 internal constant RESERVE_PRICE_4 = 0.00088 ether / 1e9;

   
  uint256 internal constant RESERVE_THRESHOLD_5 = 50000 ether;

   
  uint256 internal constant RESERVE_PRICE_5 = 0.00090 ether / 1e9;

   
  uint256 internal constant RESERVE_THRESHOLD_6 = 60000 ether;

   
  uint256 internal constant RESERVE_PRICE_6 = 0.00092 ether / 1e9;

   
  uint256 internal constant RESERVE_THRESHOLD_7 = 70000 ether;

   
  uint256 internal constant RESERVE_PRICE_7 = 0.00095 ether / 1e9;

   
  uint256 internal constant RESERVE_THRESHOLD_8 = 72500 ether;

   
  uint256 internal constant RESERVE_PRICE_8 = 0.00098 ether / 1e9;

   
  uint256 internal constant GROWTH_MAX_TOKENS = 1000000000e9;

   
  uint256 internal constant GROWTH_MAX_DURATION = 285 days;

   
  uint256 internal constant GROWTH_MIN_DELIVERED_NUMERATOR = 75;

   
  uint256 internal constant GROWTH_MIN_DELIVERED_DENOMINATIOR = 100;

   
  uint256 internal constant REQUIRED_VOTES_NUMERATIOR = 51;

   
  uint256 internal constant REQUIRED_VOTES_DENOMINATOR = 100;

   
  uint256 internal constant FEE_DENOMINATOR = 20000;

   
  uint256 internal constant FEE_CHANGE_DELAY = 650 days;

   
  uint256 internal constant MIN_FEE = 1;

   
  uint256 internal constant MAX_FEE = 2000;

   
  function JustPriceProtocol (
    OrgonToken _orgonToken, OrisSpace _orisSpace, address _k1)
  public {
    orgonToken = _orgonToken;
    orisSpace = _orisSpace;
    k1 = _k1;
  }

   
  function () public payable {
    require (msg.data.length == 0);

    buyTokens ();
  }

   
  function buyTokens () public payable {
    require (msg.value > 0);

    updateStage ();

    if (stage == Stage.RESERVE)
      buyTokensReserve ();
    else if (stage == Stage.GROWTH || stage == Stage.LIFE)
      buyTokensGrowthLife ();
    else revert ();  
  }

   
  function sellTokens (uint256 _value) public {
    require (_value > 0);
    require (_value < TWO_128);

    updateStage ();
    require (stage == Stage.LIFE);

    assert (reserveAmount < TWO_128);
    uint256 totalSupply = orgonToken.totalSupply ();
    require (totalSupply < TWO_128);

    require (_value <= totalSupply);

    uint256 toPay = safeMul (
      reserveAmount,
      safeSub (
        TWO_128,
        pow_10 (safeSub (TWO_128, (_value << 128) / totalSupply)))) >> 128;

    require (orgonToken.transferFrom (msg.sender, this, _value));
    require (orgonToken.burnTokens (_value));

    reserveAmount = safeSub (reserveAmount, toPay);

    msg.sender.transfer (toPay);
  }

   
  function deliver (address [] _investors) public {
    updateStage ();
    require (
      stage == Stage.BEFORE_GROWTH ||
      stage == Stage.GROWTH ||
      stage == Stage.LIFE);

    for (uint256 i = 0; i < _investors.length; i++) {
      address investorAddress = _investors [i];
      Investor storage investor = investors [investorAddress];

      uint256 toDeliver = investor.tokensBought;
      investor.tokensBought = 0;
      investor.etherInvested = 0;

      if (toDeliver > 0) {
        require (orgonToken.transfer (investorAddress, toDeliver));
        reserveTokensDelivered = safeAdd (reserveTokensDelivered, toDeliver);

        Delivery (investorAddress, toDeliver);
      }
    }

    if (stage == Stage.BEFORE_GROWTH &&
      safeMul (reserveTokensDelivered, GROWTH_MIN_DELIVERED_DENOMINATIOR) >=
        safeMul (reserveTokensSold, GROWTH_MIN_DELIVERED_NUMERATOR)) {
      stage = Stage.GROWTH;
      growthDeadline = currentTime () + GROWTH_MAX_DURATION;
      feeChangeEnableTime = currentTime () + FEE_CHANGE_DELAY;
    }
  }

   
  function refund (address [] _investors) public {
    updateStage ();
    require (stage == Stage.REFUND);

    for (uint256 i = 0; i < _investors.length; i++) {
      address investorAddress = _investors [i];
      Investor storage investor = investors [investorAddress];

      uint256 toBurn = investor.tokensBought;
      uint256 toRefund = investor.etherInvested;

      investor.tokensBought = 0;
      investor.etherInvested = 0;

      if (toBurn > 0)
        require (orgonToken.burnTokens (toBurn));

      if (toRefund > 0) {
        investorAddress.transfer (toRefund);

        Refund (investorAddress, toRefund);
      }
    }
  }

  function vote (address _newK1) public {
    updateStage ();

    require (stage == Stage.LIFE);
    require (!k1Changed);

    uint256 votesCount = voteNumbers [msg.sender];
    if (votesCount > 0) {
      address oldK1 = votes [msg.sender];
      if (_newK1 != oldK1) {
        if (oldK1 != address (0)) {
          voteResults [oldK1] = safeSub (voteResults [oldK1], votesCount);

          VoteRevocation (msg.sender, oldK1, votesCount);
        }

        votes [msg.sender] = _newK1;

        if (_newK1 != address (0)) {
          voteResults [_newK1] = safeAdd (voteResults [_newK1], votesCount);
          Vote (msg.sender, _newK1, votesCount);

          if (safeMul (voteResults [_newK1], REQUIRED_VOTES_DENOMINATOR) >=
            safeMul (totalVotesNumber, REQUIRED_VOTES_NUMERATIOR)) {
            k1 = _newK1;
            k1Changed = true;

            K1Change (_newK1);
          }
        }
      }
    }
  }

   
  function setFee (uint256 _fee) public {
    require (msg.sender == k1);

    require (_fee >= MIN_FEE);
    require (_fee <= MAX_FEE);

    updateStage ();

    require (stage == Stage.GROWTH || stage == Stage.LIFE);
    require (currentTime () >= feeChangeEnableTime);

    require (safeSub (_fee, 1) <= fee);
    require (safeAdd (_fee, 1) >= fee);

    if (fee != _fee) {
      fee = _fee;

      FeeChange (_fee);
    }
  }

   
  function outstandingTokens (address _investor) public view returns (uint256) {
    return investors [_investor].tokensBought;
  }

   
  function getStage (uint256 _currentTime) public view returns (Stage) {
    Stage currentStage = stage;

    if (currentStage == Stage.BEFORE_RESERVE) {
      if (_currentTime >= SALE_START_TIME)
        currentStage = Stage.RESERVE;
      else return currentStage;
    }

    if (currentStage == Stage.RESERVE) {
      if (_currentTime >= RESERVE_DEADLINE) {
        if (reserveAmount >= RESERVE_MIN_AMOUNT)
          currentStage = Stage.BEFORE_GROWTH;
        else currentStage = Stage.REFUND;
      }

      return currentStage;
    }

    if (currentStage == Stage.GROWTH) {
      if (_currentTime >= growthDeadline) {
        currentStage = Stage.LIFE;
      }
    }

    return currentStage;
  }

   
  function totalEligibleVotes () public view returns (uint256) {
    return totalVotesNumber;
  }

   
  function eligibleVotes (address _investor) public view returns (uint256) {
    return voteNumbers [_investor];
  }

   
  function votesFor (address _newK1) public view returns (uint256) {
    return voteResults [_newK1];
  }

   
  function buyTokensReserve () internal {
    require (stage == Stage.RESERVE);

    uint256 toBuy = 0;
    uint256 toRefund = msg.value;
    uint256 etherInvested = 0;
    uint256 tokens;
    uint256 tokensValue;

    if (reserveAmount < RESERVE_THRESHOLD_1) {
      tokens = min (
        toRefund,
        safeSub (RESERVE_THRESHOLD_1, reserveAmount)) /
        RESERVE_PRICE_1;

      if (tokens > 0) {
        tokensValue = safeMul (tokens, RESERVE_PRICE_1);

        toBuy = safeAdd (toBuy, tokens);
        toRefund = safeSub (toRefund, tokensValue);
        etherInvested = safeAdd (etherInvested, tokensValue);
        reserveAmount = safeAdd (reserveAmount, tokensValue);
      }
    }

    if (reserveAmount < RESERVE_THRESHOLD_2) {
      tokens = min (
        toRefund,
        safeSub (RESERVE_THRESHOLD_2, reserveAmount)) /
        RESERVE_PRICE_2;

      if (tokens > 0) {
        tokensValue = safeMul (tokens, RESERVE_PRICE_2);

        toBuy = safeAdd (toBuy, tokens);
        toRefund = safeSub (toRefund, tokensValue);
        etherInvested = safeAdd (etherInvested, tokensValue);
        reserveAmount = safeAdd (reserveAmount, tokensValue);
      }
    }

    if (reserveAmount < RESERVE_THRESHOLD_3) {
      tokens = min (
        toRefund,
        safeSub (RESERVE_THRESHOLD_3, reserveAmount)) /
        RESERVE_PRICE_3;

      if (tokens > 0) {
        tokensValue = safeMul (tokens, RESERVE_PRICE_3);

        toBuy = safeAdd (toBuy, tokens);
        toRefund = safeSub (toRefund, tokensValue);
        etherInvested = safeAdd (etherInvested, tokensValue);
        reserveAmount = safeAdd (reserveAmount, tokensValue);
      }
    }

    if (reserveAmount < RESERVE_THRESHOLD_4) {
      tokens = min (
        toRefund,
        safeSub (RESERVE_THRESHOLD_4, reserveAmount)) /
        RESERVE_PRICE_4;

      if (tokens > 0) {
        tokensValue = safeMul (tokens, RESERVE_PRICE_4);

        toBuy = safeAdd (toBuy, tokens);
        toRefund = safeSub (toRefund, tokensValue);
        etherInvested = safeAdd (etherInvested, tokensValue);
        reserveAmount = safeAdd (reserveAmount, tokensValue);
      }
    }

    if (reserveAmount < RESERVE_THRESHOLD_5) {
      tokens = min (
        toRefund,
        safeSub (RESERVE_THRESHOLD_5, reserveAmount)) /
        RESERVE_PRICE_5;

      if (tokens > 0) {
        tokensValue = safeMul (tokens, RESERVE_PRICE_5);

        toBuy = safeAdd (toBuy, tokens);
        toRefund = safeSub (toRefund, tokensValue);
        etherInvested = safeAdd (etherInvested, tokensValue);
        reserveAmount = safeAdd (reserveAmount, tokensValue);
      }
    }

    if (reserveAmount < RESERVE_THRESHOLD_6) {
      tokens = min (
        toRefund,
        safeSub (RESERVE_THRESHOLD_6, reserveAmount)) /
        RESERVE_PRICE_6;

      if (tokens > 0) {
        tokensValue = safeMul (tokens, RESERVE_PRICE_6);

        toBuy = safeAdd (toBuy, tokens);
        toRefund = safeSub (toRefund, tokensValue);
        etherInvested = safeAdd (etherInvested, tokensValue);
        reserveAmount = safeAdd (reserveAmount, tokensValue);
      }
    }

    if (reserveAmount < RESERVE_THRESHOLD_7) {
      tokens = min (
        toRefund,
        safeSub (RESERVE_THRESHOLD_7, reserveAmount)) /
        RESERVE_PRICE_7;

      if (tokens > 0) {
        tokensValue = safeMul (tokens, RESERVE_PRICE_7);

        toBuy = safeAdd (toBuy, tokens);
        toRefund = safeSub (toRefund, tokensValue);
        etherInvested = safeAdd (etherInvested, tokensValue);
        reserveAmount = safeAdd (reserveAmount, tokensValue);
      }
    }

    if (reserveAmount < RESERVE_THRESHOLD_8) {
      tokens = min (
        toRefund,
        safeSub (RESERVE_THRESHOLD_8, reserveAmount)) /
        RESERVE_PRICE_8;

      if (tokens > 0) {
        tokensValue = safeMul (tokens, RESERVE_PRICE_8);

        toBuy = safeAdd (toBuy, tokens);
        toRefund = safeSub (toRefund, tokensValue);
        etherInvested = safeAdd (etherInvested, tokensValue);
        reserveAmount = safeAdd (reserveAmount, tokensValue);
      }
    }

    if (toBuy > 0) {
      Investor storage investor = investors [msg.sender];

      investor.tokensBought = safeAdd (
        investor.tokensBought, toBuy);

      investor.etherInvested = safeAdd (
        investor.etherInvested, etherInvested);

      reserveTokensSold = safeAdd (reserveTokensSold, toBuy);

      require (orgonToken.createTokens (toBuy));

      voteNumbers [msg.sender] = safeAdd (voteNumbers [msg.sender], toBuy);
      totalVotesNumber = safeAdd (totalVotesNumber, toBuy);

      Investment (msg.sender, etherInvested, toBuy);

      if (safeSub (RESERVE_THRESHOLD_8, reserveAmount) <
        RESERVE_PRICE_8) {

        orisSpace.start (0);

        stage = Stage.BEFORE_GROWTH;
      }
    }

    if (toRefund > 0)
      msg.sender.transfer (toRefund);
  }

   
  function buyTokensGrowthLife () internal {
    require (stage == Stage.GROWTH || stage == Stage.LIFE);

    require (msg.value < TWO_128);

    uint256 totalSupply = orgonToken.totalSupply ();
    assert (totalSupply < TWO_128);

    uint256 toBuy = safeMul (
      totalSupply,
      safeSub (
        root_10 (safeAdd (TWO_128, (msg.value << 128) / reserveAmount)),
        TWO_128)) >> 128;

    reserveAmount = safeAdd (reserveAmount, msg.value);
    require (reserveAmount < TWO_128);

    if (toBuy > 0) {
      require (orgonToken.createTokens (toBuy));
      require (orgonToken.totalSupply () < TWO_128);

      uint256 feeAmount = safeMul (toBuy, fee) / FEE_DENOMINATOR;

      require (orgonToken.transfer (msg.sender, safeSub (toBuy, feeAmount)));

      if (feeAmount > 0)
        require (orgonToken.transfer (k1, feeAmount));

      if (stage == Stage.GROWTH) {
        uint256 votesCount = toBuy;

        totalSupply = orgonToken.totalSupply ();
        if (totalSupply >= GROWTH_MAX_TOKENS) {
          stage = Stage.LIFE;
          votesCount = safeSub (
            votesCount,
            safeSub (totalSupply, GROWTH_MAX_TOKENS));
        }

        voteNumbers [msg.sender] =
          safeAdd (voteNumbers [msg.sender], votesCount);
        totalVotesNumber = safeAdd (totalVotesNumber, votesCount);
      }
    }
  }

   
  function updateStage () internal returns (Stage) {
    Stage currentStage = getStage (currentTime ());
    if (stage != currentStage) {
      if (currentStage == Stage.BEFORE_GROWTH) {
         
        uint256 tokensToBurn =
          safeSub (
            safeAdd (
              safeAdd (
                safeSub (RESERVE_MAX_AMOUNT, reserveAmount),
                safeSub (RESERVE_RATIO, 1)) /
                RESERVE_RATIO,
              reserveTokensSold),
            RESERVE_MAX_TOKENS);

        orisSpace.start (tokensToBurn);
        if (tokensToBurn > 0)
          require (orgonToken.burnTokens (tokensToBurn));
      }

      stage = currentStage;
    }
  }

   
  function min (uint256 x, uint256 y) internal pure returns (uint256) {
    return x < y ? x : y;
  }

   
  function root_10 (uint256 x) internal pure returns (uint256 y) {
    uint256 shift = 0;

    while (x > TWO_128) {
      x >>= 10;
      shift += 1;
    }

    if (x == TWO_128 || x == 0) y = x;
    else {
      uint256 x128 = x << 128;
      y = TWO_128;

      uint256 t = x;
      while (true) {
        t <<= 10;
        if (t < TWO_128) y >>= 1;
        else break;
      }

      for (uint256 i = 0; i < 16; i++) {
        uint256 y9;

        if (y == TWO_128) y9 = y;
        else {
          uint256 y2 = (y * y) >> 128;
          uint256 y4 = (y2 * y2) >> 128;
          uint256 y8 = (y4 * y4) >> 128;
          y9 = (y * y8) >> 128;
        }

        y = (9 * y + x128 / y9) / 10;

        assert (y <= TWO_128);
      }
    }

    y <<= shift;
  }

   
  function pow_10 (uint256 x) internal pure returns (uint256) {
    require (x <= TWO_128);

    if (x == TWO_128) return x;
    else {
      uint256 x2 = (x * x) >> 128;
      uint256 x4 = (x2 * x2) >> 128;
      uint256 x8 = (x4 * x4) >> 128;
      return (x2 * x8) >> 128;
    }
  }

   
  function currentTime () internal view returns (uint256) {
    return block.timestamp;
  }

   
  enum Stage {
    BEFORE_RESERVE,  
    RESERVE,  
    BEFORE_GROWTH,  
    GROWTH,  
    LIFE,  
    REFUND  
  }

   
  OrgonToken internal orgonToken;

   
  OrisSpace internal orisSpace;

   
  address internal k1;

   
  Stage internal stage = Stage.BEFORE_RESERVE;

   
  uint256 internal reserveAmount;

   
  uint256 internal reserveTokensSold;

   
  uint256 internal reserveTokensDelivered;

   
  uint256 internal growthDeadline;

   
  mapping (address => Investor) internal investors;

   
  mapping (address => uint256) internal voteNumbers;

   
  mapping (address => address) internal votes;

   
  mapping (address => uint256) internal voteResults;

   
  uint256 internal totalVotesNumber;

   
  bool internal k1Changed = false;

   
  uint256 internal fee = 2;

   
  uint256 internal feeChangeEnableTime;

   
  struct Investor {
     
    uint256 tokensBought;

     
    uint256 etherInvested;
  }

   
  event Investment (address indexed investor, uint256 value, uint256 amount);

   
  event Delivery (address indexed investor, uint256 amount);

   
  event Refund (address indexed investor, uint256 value);

   
  event K1Change (address k1);

   
  event Vote (address indexed investor, address indexed newK1, uint256 votes);

   
  event VoteRevocation (
    address indexed investor, address indexed newK1, uint256 votes);

   
  event FeeChange (uint256 fee);
}