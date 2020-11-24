 

pragma solidity ^0.4.19;

 

contract ContractReceiverInterface {
    function receiveApproval(
        address from,
        uint256 _amount,
        address _token,
        bytes _data) public;
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

 

contract SafeContract is Ownable {

     
    function transferAnyERC20Token(address _tokenAddress, uint256 _tokens, address _beneficiary) public onlyOwner returns (bool success) {
        return ERC20Basic(_tokenAddress).transfer(_beneficiary, _tokens);
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

 

 
contract ERC20 is ERC20Basic {
  function allowance(address owner, address spender) public view returns (uint256);
  function transferFrom(address from, address to, uint256 value) public returns (bool);
  function approve(address spender, uint256 value) public returns (bool);
  event Approval(address indexed owner, address indexed spender, uint256 value);
}

 

contract DetailedERC20 is ERC20 {
  string public name;
  string public symbol;
  uint8 public decimals;

  function DetailedERC20(string _name, string _symbol, uint8 _decimals) public {
    name = _name;
    symbol = _symbol;
    decimals = _decimals;
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

 

 
contract FriendsFingersToken is DetailedERC20, MintableToken, BurnableToken, SafeContract {

    address public builder;

    modifier canTransfer() {
        require(mintingFinished);
        _;
    }

    function FriendsFingersToken(
        string _name,
        string _symbol,
        uint8 _decimals
    )
    DetailedERC20 (_name, _symbol, _decimals)
    public
    {
        builder = owner;
    }

    function transfer(address _to, uint _value) canTransfer public returns (bool) {
        return super.transfer(_to, _value);
    }

    function transferFrom(address _from, address _to, uint _value) canTransfer public returns (bool) {
        return super.transferFrom(_from, _to, _value);
    }

    function approveAndCall(address _spender, uint256 _amount, bytes _extraData) public returns (bool success) {
        require(approve(_spender, _amount));

        ContractReceiverInterface(_spender).receiveApproval(
            msg.sender,
            _amount,
            this,
            _extraData
        );

        return true;
    }

}

 

 
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

   
  function () external payable {
    buyTokens(msg.sender);
  }

   
  function buyTokens(address beneficiary) public payable {
    require(beneficiary != address(0));
    require(validPurchase());

    uint256 weiAmount = msg.value;

     
    uint256 tokens = getTokenAmount(weiAmount);

     
    weiRaised = weiRaised.add(weiAmount);

    token.mint(beneficiary, tokens);
    TokenPurchase(msg.sender, beneficiary, weiAmount, tokens);

    forwardFunds();
  }

   
  function hasEnded() public view returns (bool) {
    return now > endTime;
  }

   
   
  function createTokenContract() internal returns (MintableToken) {
    return new MintableToken();
  }

   
  function getTokenAmount(uint256 weiAmount) internal view returns(uint256) {
    return weiAmount.mul(rate);
  }

   
   
  function forwardFunds() internal {
    wallet.transfer(msg.value);
  }

   
  function validPurchase() internal view returns (bool) {
    bool withinPeriod = now >= startTime && now <= endTime;
    bool nonZeroPurchase = msg.value != 0;
    return withinPeriod && nonZeroPurchase;
  }

}

 

 
contract CappedCrowdsale is Crowdsale {
  using SafeMath for uint256;

  uint256 public cap;

  function CappedCrowdsale(uint256 _cap) public {
    require(_cap > 0);
    cap = _cap;
  }

   
   
  function hasEnded() public view returns (bool) {
    bool capReached = weiRaised >= cap;
    return capReached || super.hasEnded();
  }

   
   
  function validPurchase() internal view returns (bool) {
    bool withinCap = weiRaised.add(msg.value) <= cap;
    return withinCap && super.validPurchase();
  }

}

 

 
contract FinalizableCrowdsale is Crowdsale, Ownable {
  using SafeMath for uint256;

  bool public isFinalized = false;

  event Finalized();

   
  function finalize() onlyOwner public {
    require(!isFinalized);
    require(hasEnded());

    finalization();
    Finalized();

    isFinalized = true;
  }

   
  function finalization() internal {
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

 

 
contract FriendsFingersCrowdsale is CappedCrowdsale, FinalizableCrowdsale, Pausable, SafeContract {

    enum State { Active, Refunding, Closed, Blocked, Expired }

    uint256 public id;
    uint256 public previousRoundId;
    uint256 public nextRoundId;

     
    FriendsFingersToken public token;

     
    uint256 public round;

     
    uint256 public goal;

    string public crowdsaleInfo;

    uint256 public friendsFingersRatePerMille;
    address public friendsFingersWallet;

    uint256 public investorCount = 0;
    mapping (address => uint256) public deposited;
    State public state;

    event Closed();
    event Expired();
    event RefundsEnabled();
    event Refunded(address indexed beneficiary, uint256 weiAmount);

    function FriendsFingersCrowdsale(
        uint256 _id,
        uint256 _cap,
        uint256 _goal,
        uint256 _startTime,
        uint256 _endTime,
        uint256 _rate,
        address _wallet,
        FriendsFingersToken _token,
        string _crowdsaleInfo,
        uint256 _round,
        uint256 _previousRoundId,
        uint256 _friendsFingersRatePerMille,
        address _friendsFingersWallet
    ) public
    CappedCrowdsale (_cap)
    FinalizableCrowdsale ()
    Crowdsale (_startTime, _endTime, _rate, _wallet)
    {
        require(_endTime <= _startTime + 30 days);
        require(_token != address(0));

        require(_round <= 5);
        if (_round == 1) {
            if (_id == 1) {
                require(_goal >= 0);
            } else {
                require(_goal > 0);
            }
        } else {
            require(_goal == 0);
        }
        require(_cap > 0);
        require(_cap >= _goal);

        goal = _goal;

        crowdsaleInfo = _crowdsaleInfo;

        token = _token;

        round = _round;
        previousRoundId = _previousRoundId;
        state = State.Active;

        id = _id;

        friendsFingersRatePerMille = _friendsFingersRatePerMille;
        friendsFingersWallet = _friendsFingersWallet;
    }

     
    function buyTokens(address beneficiary) whenNotPaused public payable {
        require(beneficiary != address(0));
        require(validPurchase());

        uint256 weiAmount = msg.value;

         
        uint256 tokens = getTokenAmount(weiAmount);

         
        weiRaised = weiRaised.add(weiAmount);

        token.mint(beneficiary, tokens);
        TokenPurchase(
            msg.sender,
            beneficiary,
            weiAmount,
            tokens
        );

        forwardFunds();
    }

     

     
    function claimRefund() whenNotPaused public {
        require(state == State.Refunding || state == State.Blocked);
        address investor = msg.sender;

        uint256 depositedValue = deposited[investor];
        deposited[investor] = 0;
        investor.transfer(depositedValue);
        Refunded(investor, depositedValue);
    }

    function finalize() whenNotPaused public {
        super.finalize();
    }

     

    function goalReached() view public returns (bool) {
        return weiRaised >= goal;
    }

     

    function updateCrowdsaleInfo(string _crowdsaleInfo) onlyOwner public {
        require(!hasEnded());
        crowdsaleInfo = _crowdsaleInfo;
    }

    function blockCrowdsale() onlyOwner public {
        require(state == State.Active);
        state = State.Blocked;
    }

    function setnextRoundId(uint256 _nextRoundId) onlyOwner public {
        nextRoundId = _nextRoundId;
    }

    function setFriendsFingersRate(uint256 _newFriendsFingersRatePerMille) onlyOwner public {
        require(_newFriendsFingersRatePerMille >= 0);
        require(_newFriendsFingersRatePerMille <= friendsFingersRatePerMille);
        friendsFingersRatePerMille = _newFriendsFingersRatePerMille;
    }

    function setFriendsFingersWallet(address _friendsFingersWallet) onlyOwner public {
        require(_friendsFingersWallet != address(0));
        friendsFingersWallet = _friendsFingersWallet;
    }

     

    function safeWithdrawal() onlyOwner public {
        require(now >= endTime + 1 years);
        friendsFingersWallet.transfer(this.balance);
    }

    function setExpiredAndWithdraw() onlyOwner public {
        require((state == State.Refunding || state == State.Blocked) && now >= endTime + 1 years);
        state = State.Expired;
        friendsFingersWallet.transfer(this.balance);
        Expired();
    }

     

     
    function createTokenContract() internal returns (MintableToken) {
        return MintableToken(address(0));
    }

     
     
    function validPurchase() internal view returns (bool) {
        bool isActive = state == State.Active;
        return isActive && super.validPurchase();
    }

     
    function forwardFunds() internal {
        if (deposited[msg.sender] == 0) {
            investorCount++;
        }
        deposited[msg.sender] = deposited[msg.sender].add(msg.value);
    }

     
    function finalization() internal {
        require(state == State.Active);

        if (goalReached()) {
            state = State.Closed;
            Closed();

            if (friendsFingersRatePerMille > 0) {
                uint256 friendsFingersFee = weiRaised.mul(friendsFingersRatePerMille).div(1000);
                friendsFingersWallet.transfer(friendsFingersFee);
            }

            wallet.transfer(this.balance);
        } else {
            state = State.Refunding;
            RefundsEnabled();
        }

        if (friendsFingersRatePerMille > 0) {
            uint256 friendsFingersSupply = cap.mul(rate).mul(friendsFingersRatePerMille).div(1000);
            token.mint(owner, friendsFingersSupply);
        }

        token.transferOwnership(owner);

        super.finalization();
    }

}

 

 
contract FriendsFingersBuilder is Pausable, SafeContract {
    using SafeMath for uint256;

    event CrowdsaleStarted(address ffCrowdsale);
    event CrowdsaleClosed(address ffCrowdsale);

    uint public version = 1;
    string public website = "https://www.friendsfingers.com";
    uint256 public friendsFingersRatePerMille = 50;  
    address public friendsFingersWallet;
    mapping (address => bool) public enabledAddresses;

    uint256 public crowdsaleCount = 0;
    mapping (uint256 => address) public crowdsaleList;
    mapping (address => address) public crowdsaleCreators;

    modifier onlyOwnerOrEnabledAddress() {
        require(enabledAddresses[msg.sender] || msg.sender == owner);
        _;
    }

    modifier onlyOwnerOrCreator(address _ffCrowdsale) {
        require(msg.sender == crowdsaleCreators[_ffCrowdsale] || msg.sender == owner);
        _;
    }

    function FriendsFingersBuilder(address _friendsFingersWallet) public {
        setMainWallet(_friendsFingersWallet);
    }

     
    function () public payable {
        require(msg.value != 0);
        friendsFingersWallet.transfer(msg.value);
    }

     

    function startCrowdsale(
        string _tokenName,
        string _tokenSymbol,
        uint8 _tokenDecimals,
        uint256 _cap,
        uint256 _goal,
        uint256 _creatorSupply,
        uint256 _startTime,
        uint256 _endTime,
        uint256 _rate,
        address _wallet,
        string _crowdsaleInfo
    ) whenNotPaused public returns (FriendsFingersCrowdsale)
    {
        crowdsaleCount++;
        uint256 _round = 1;

        FriendsFingersToken token = new FriendsFingersToken(
            _tokenName,
            _tokenSymbol,
            _tokenDecimals
        );

        if (_creatorSupply > 0) {
            token.mint(_wallet, _creatorSupply);
        }

        FriendsFingersCrowdsale ffCrowdsale = new FriendsFingersCrowdsale(
        crowdsaleCount,
        _cap,
        _goal,
        _startTime,
        _endTime,
        _rate,
        _wallet,
        token,
        _crowdsaleInfo,
        _round,
        0,
        friendsFingersRatePerMille,
        friendsFingersWallet
        );

        if (crowdsaleCount > 1) {
            ffCrowdsale.pause();
        }

        token.transferOwnership(address(ffCrowdsale));

        addCrowdsaleToList(address(ffCrowdsale));

        return ffCrowdsale;
    }

    function restartCrowdsale(
        address _ffCrowdsale,
        uint256 _cap,
        uint256 _startTime,
        uint256 _endTime,
        uint256 _rate,
        string _crowdsaleInfo
    ) whenNotPaused onlyOwnerOrCreator(_ffCrowdsale) public returns (FriendsFingersCrowdsale)
    {
        FriendsFingersCrowdsale ffCrowdsale = FriendsFingersCrowdsale(_ffCrowdsale);
         
        require(ffCrowdsale.nextRoundId() == 0);
         
        require(ffCrowdsale.goalReached());
        require(_rate < ffCrowdsale.rate());

        ffCrowdsale.finalize();

        crowdsaleCount++;
        uint256 _round = ffCrowdsale.round();
        _round++;

        FriendsFingersToken token = ffCrowdsale.token();

        FriendsFingersCrowdsale newFriendsFingersCrowdsale = new FriendsFingersCrowdsale(
            crowdsaleCount,
            _cap,
            0,
            _startTime,
            _endTime,
            _rate,
            ffCrowdsale.wallet(),
            token,
            _crowdsaleInfo,
            _round,
            ffCrowdsale.id(),
            friendsFingersRatePerMille,
            friendsFingersWallet
        );

        token.transferOwnership(address(newFriendsFingersCrowdsale));

        ffCrowdsale.setnextRoundId(crowdsaleCount);

        addCrowdsaleToList(address(newFriendsFingersCrowdsale));

        return newFriendsFingersCrowdsale;
    }

    function closeCrowdsale(address _ffCrowdsale) onlyOwnerOrCreator(_ffCrowdsale) public {
        FriendsFingersCrowdsale ffCrowdsale = FriendsFingersCrowdsale(_ffCrowdsale);
        ffCrowdsale.finalize();

        FriendsFingersToken token = ffCrowdsale.token();
        token.finishMinting();
        token.transferOwnership(crowdsaleCreators[_ffCrowdsale]);

        CrowdsaleClosed(ffCrowdsale);
    }

    function updateCrowdsaleInfo(address _ffCrowdsale, string _crowdsaleInfo) onlyOwnerOrCreator(_ffCrowdsale) public {
        FriendsFingersCrowdsale ffCrowdsale = FriendsFingersCrowdsale(_ffCrowdsale);
        ffCrowdsale.updateCrowdsaleInfo(_crowdsaleInfo);
    }

     

    function changeEnabledAddressStatus(address _address, bool _status) onlyOwner public {
        require(_address != address(0));
        enabledAddresses[_address] = _status;
    }

    function setDefaultFriendsFingersRate(uint256 _newFriendsFingersRatePerMille) onlyOwner public {
        require(_newFriendsFingersRatePerMille >= 0);
        require(_newFriendsFingersRatePerMille < friendsFingersRatePerMille);
        friendsFingersRatePerMille = _newFriendsFingersRatePerMille;
    }

    function setMainWallet(address _newFriendsFingersWallet) onlyOwner public {
        require(_newFriendsFingersWallet != address(0));
        friendsFingersWallet = _newFriendsFingersWallet;
    }

    function setFriendsFingersRateForCrowdsale(address _ffCrowdsale, uint256 _newFriendsFingersRatePerMille) onlyOwner public {
        FriendsFingersCrowdsale ffCrowdsale = FriendsFingersCrowdsale(_ffCrowdsale);
        ffCrowdsale.setFriendsFingersRate(_newFriendsFingersRatePerMille);
    }

    function setFriendsFingersWalletForCrowdsale(address _ffCrowdsale, address _newFriendsFingersWallet) onlyOwner public {
        FriendsFingersCrowdsale ffCrowdsale = FriendsFingersCrowdsale(_ffCrowdsale);
        ffCrowdsale.setFriendsFingersWallet(_newFriendsFingersWallet);
    }

     

    function pauseCrowdsale(address _ffCrowdsale) onlyOwnerOrEnabledAddress public {
        FriendsFingersCrowdsale ffCrowdsale = FriendsFingersCrowdsale(_ffCrowdsale);
        ffCrowdsale.pause();
    }

    function unpauseCrowdsale(address _ffCrowdsale) onlyOwnerOrEnabledAddress public {
        FriendsFingersCrowdsale ffCrowdsale = FriendsFingersCrowdsale(_ffCrowdsale);
        ffCrowdsale.unpause();
    }

    function blockCrowdsale(address _ffCrowdsale) onlyOwnerOrEnabledAddress public {
        FriendsFingersCrowdsale ffCrowdsale = FriendsFingersCrowdsale(_ffCrowdsale);
        ffCrowdsale.blockCrowdsale();
    }

    function safeTokenWithdrawalFromCrowdsale(address _ffCrowdsale, address _tokenAddress, uint256 _tokens) onlyOwnerOrEnabledAddress public {
        FriendsFingersCrowdsale ffCrowdsale = FriendsFingersCrowdsale(_ffCrowdsale);
        ffCrowdsale.transferAnyERC20Token(_tokenAddress, _tokens, friendsFingersWallet);
    }

    function safeWithdrawalFromCrowdsale(address _ffCrowdsale) onlyOwnerOrEnabledAddress public {
        FriendsFingersCrowdsale ffCrowdsale = FriendsFingersCrowdsale(_ffCrowdsale);
        ffCrowdsale.safeWithdrawal();
    }

    function setExpiredAndWithdraw(address _ffCrowdsale) onlyOwnerOrEnabledAddress public {
        FriendsFingersCrowdsale ffCrowdsale = FriendsFingersCrowdsale(_ffCrowdsale);
        ffCrowdsale.setExpiredAndWithdraw();
    }

     

    function addCrowdsaleToList(address ffCrowdsale) internal {
        crowdsaleList[crowdsaleCount] = ffCrowdsale;
        crowdsaleCreators[ffCrowdsale] = msg.sender;

        CrowdsaleStarted(ffCrowdsale);
    }

}