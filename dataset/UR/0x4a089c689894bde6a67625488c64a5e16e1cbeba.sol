 

pragma solidity ^0.4.13;

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

contract MintableToken is StandardToken, Ownable {
  event Mint(address indexed to, uint256 amount);
  event MintFinished();

  bool public mintingFinished = false;


  modifier canMint() {
    require(!mintingFinished);
    _;
  }

   
  function mint(address _to, uint256 _amount) onlyOwner canMint public returns (bool) {
    totalSupply_ = totalSupply_.add(_amount);
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

contract NectarToken is MintableToken {
    string public name = "Nectar";
    string public symbol = "NCT";
    uint8 public decimals = 18;

    bool public transfersEnabled = false;
    event TransfersEnabled();

     
    modifier whenTransfersEnabled() {
        require(transfersEnabled);
        _;
    }

    modifier whenTransfersNotEnabled() {
        require(!transfersEnabled);
        _;
    }

    function enableTransfers() onlyOwner whenTransfersNotEnabled public {
        transfersEnabled = true;
        TransfersEnabled();
    }

    function transfer(address to, uint256 value) public whenTransfersEnabled returns (bool) {
        return super.transfer(to, value);
    }

    function transferFrom(address from, address to, uint256 value) public whenTransfersEnabled returns (bool) {
        return super.transferFrom(from, to, value);
    }

     
    function approveAndCall(address _spender, uint256 _value, bytes _extraData) public returns (bool success) {
        allowed[msg.sender][_spender] = _value;
        Approval(msg.sender, _spender, _value);

         
         
         

         
        require(_spender.call(bytes4(bytes32(keccak256("receiveApproval(address,uint256,address,bytes)"))), msg.sender, _value, this, _extraData));
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
    Pause();
  }

   
  function unpause() onlyOwner whenPaused public {
    paused = false;
    Unpause();
  }
}

contract NectarCrowdsale is Ownable, Pausable {
    using SafeMath for uint256;

     
    uint256 constant maxCapUsd = 50000000;
     
    uint256 constant minimumPurchaseUsd = 100;

     
    uint256 constant tranche1ThresholdUsd = 5000000;
    uint256 constant tranche1Rate = 37604;
    uint256 constant tranche2ThresholdUsd = 10000000;
    uint256 constant tranche2Rate = 36038;
    uint256 constant tranche3ThresholdUsd = 15000000;
    uint256 constant tranche3Rate = 34471;
    uint256 constant tranche4ThresholdUsd = 20000000;
    uint256 constant tranche4Rate = 32904;
    uint256 constant standardTrancheRate= 31337;

     
    NectarToken public token;

     
    uint256 public startTime;

     
    uint256 public endTime;

     
    uint256 public weiUsdExchangeRate;

     
    address public wallet;

     
    address public purchaseAuthorizer;

     
    uint256 public weiRaised;

     
    uint256 public capUsd;

     
    uint256 public cap;

     
    uint256 public minimumPurchase;

     
    bool public isCanceled;

     
    bool public isFinalized;

     
    mapping (uint256 => bool) public purchases;

     
    event PreSaleMinting(address indexed purchaser, uint256 amount);

     
    event TokenPurchase(address indexed purchaser, uint256 value, uint256 amount);

     
    event Canceled();

     
    event Finalized();

     
    function NectarCrowdsale(
        uint256 _startTime,
        uint256 _endTime,
        uint256 _initialWeiUsdExchangeRate,
        address _wallet,
        address _purchaseAuthorizer
    )
        public
    {
        require(_startTime >= now);
        require(_endTime >= _startTime);
        require(_initialWeiUsdExchangeRate > 0);
        require(_wallet != address(0));
        require(_purchaseAuthorizer != address(0));

        token = createTokenContract();
        startTime = _startTime;
        endTime = _endTime;
        weiUsdExchangeRate = _initialWeiUsdExchangeRate;
        wallet = _wallet;
        purchaseAuthorizer = _purchaseAuthorizer;

        capUsd = maxCapUsd;

         
        updateCapAndExchangeRate();

        isCanceled = false;
        isFinalized = false;
    }

     
    function () external payable {
        revert();
    }

     
    modifier onlyPreSale() {
        require(now < startTime);
        _;
    }

     
    function mintPreSale(address purchaser, uint256 tokenAmount) public onlyOwner onlyPreSale {
        require(purchaser != address(0));
        require(tokenAmount > 0);

        token.mint(purchaser, tokenAmount);
        PreSaleMinting(purchaser, tokenAmount);
    }

     
    function buyTokens(uint256 authorizedAmount, uint256 nonce, bytes sig) public payable whenNotPaused {
        require(msg.sender != address(0));
        require(validPurchase(authorizedAmount, nonce, sig));

        uint256 weiAmount = msg.value;

         
        uint256 rate = currentTranche();
        uint256 tokens = weiAmount.mul(rate);

         
        weiRaised = weiRaised.add(weiAmount);
        purchases[nonce] = true;

        token.mint(msg.sender, tokens);
        TokenPurchase(msg.sender, weiAmount, tokens);

        forwardFunds();
    }

     
    function cancel() public onlyOwner {
        require(!isCanceled);
        require(!hasEnded());

        Canceled();
        isCanceled = true;
    }

     
    function finalize() public onlyOwner {
        require(!isFinalized);
        require(hasEnded());

        finalization();
        Finalized();

        isFinalized = true;
    }

     
    function setExchangeRate(uint256 _weiUsdExchangeRate) public onlyOwner onlyPreSale {
        require(_weiUsdExchangeRate > 0);

        weiUsdExchangeRate = _weiUsdExchangeRate;
        updateCapAndExchangeRate();
    }

     
    function setCapUsd(uint256 _capUsd) public onlyOwner onlyPreSale {
        require(_capUsd <= maxCapUsd);

        capUsd = _capUsd;
        updateCapAndExchangeRate();
    }

     
    function enableTransfers() public onlyOwner {
        require(isFinalized);
        require(hasEnded());

        token.enableTransfers();
    }

     
    function currentTranche() public view returns (uint256) {
        uint256 currentFundingUsd = weiRaised.div(weiUsdExchangeRate);
        if (currentFundingUsd <= tranche1ThresholdUsd) {
            return tranche1Rate;
        } else if (currentFundingUsd <= tranche2ThresholdUsd) {
            return tranche2Rate;
        } else if (currentFundingUsd <= tranche3ThresholdUsd) {
            return tranche3Rate;
        } else if (currentFundingUsd <= tranche4ThresholdUsd) {
            return tranche4Rate;
        } else {
            return standardTrancheRate;
        }
    }

     
    function hasEnded() public view returns (bool) {
        bool afterEnd = now > endTime;
        bool capMet = weiRaised >= cap;
        return afterEnd || capMet || isCanceled;
    }

     
    function totalCollected() public view returns (uint256) {
        uint256 presale = maxCapUsd.sub(capUsd);
        uint256 crowdsale = weiRaised.div(weiUsdExchangeRate);
        return presale.add(crowdsale);
    }

     
    function createTokenContract() internal returns (NectarToken) {
        return new NectarToken();
    }

     
    function finalization() internal {
         
        uint256 tokens = token.totalSupply().mul(3).div(10);
        token.mint(wallet, tokens);
    }

     
    function forwardFunds() internal {
        wallet.transfer(msg.value);
    }

     
    function updateCapAndExchangeRate() internal {
        cap = capUsd.mul(weiUsdExchangeRate);
        minimumPurchase = minimumPurchaseUsd.mul(weiUsdExchangeRate);
    }

     
    function validPurchase(uint256 authorizedAmount, uint256 nonce, bytes sig) internal view returns (bool) {
         
        bytes memory prefix = "\x19Ethereum Signed Message:\n84";
        bytes32 hash = keccak256(prefix, msg.sender, authorizedAmount, nonce);
        bool validAuthorization = ECRecovery.recover(hash, sig) == purchaseAuthorizer;

        bool validNonce = !purchases[nonce];
        bool withinPeriod = now >= startTime && now <= endTime;
        bool aboveMinimum = msg.value >= minimumPurchase;
        bool belowAuthorized = msg.value <= authorizedAmount;
        bool belowCap = weiRaised.add(msg.value) <= cap;
        return validAuthorization && validNonce && withinPeriod && aboveMinimum && belowAuthorized && belowCap;
    }
}

library ECRecovery {

   
  function recover(bytes32 hash, bytes sig) public pure returns (address) {
    bytes32 r;
    bytes32 s;
    uint8 v;

     
    if (sig.length != 65) {
      return (address(0));
    }

     
    assembly {
      r := mload(add(sig, 32))
      s := mload(add(sig, 64))
      v := byte(0, mload(add(sig, 96)))
    }

     
    if (v < 27) {
      v += 27;
    }

     
    if (v != 27 && v != 28) {
      return (address(0));
    } else {
      return ecrecover(hash, v, r, s);
    }
  }

}