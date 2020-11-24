 

pragma solidity ^0.4.11;


 


 
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


 
contract ERC20Basic {
  uint256 public totalSupply;
  function balanceOf(address who) constant returns (uint256);
  function transfer(address to, uint256 value) returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
}


 
contract ERC20 is ERC20Basic {
  function allowance(address owner, address spender) constant returns (uint256);
  function transferFrom(address from, address to, uint256 value) returns (bool);
  function approve(address spender, uint256 value) returns (bool);
  event Approval(address indexed owner, address indexed spender, uint256 value);
}


 
contract BasicToken is ERC20Basic {
  using SafeMath for uint256;

  mapping(address => uint256) balances;

   
  function transfer(address _to, uint256 _value) returns (bool) {
    balances[msg.sender] = balances[msg.sender].sub(_value);
    balances[_to] = balances[_to].add(_value);
    Transfer(msg.sender, _to, _value);
    return true;
  }

   
  function balanceOf(address _owner) constant returns (uint256 balance) {
    return balances[_owner];
  }
}

 
contract StandardToken is ERC20, BasicToken {

  mapping (address => mapping (address => uint256)) allowed;


   
  function transferFrom(address _from, address _to, uint256 _value) returns (bool) {
    var _allowance = allowed[_from][msg.sender];

     
     

    balances[_to] = balances[_to].add(_value);
    balances[_from] = balances[_from].sub(_value);
    allowed[_from][msg.sender] = _allowance.sub(_value);
    Transfer(_from, _to, _value);
    return true;
  }

   
  function approve(address _spender, uint256 _value) returns (bool) {

     
     
     
     
    require((_value == 0) || (allowed[msg.sender][_spender] == 0));

    allowed[msg.sender][_spender] = _value;
    Approval(msg.sender, _spender, _value);
    return true;
  }

   
  function allowance(address _owner, address _spender) constant returns (uint256 remaining) {
    return allowed[_owner][_spender];
  }
}

 
contract PullPayment {
  using SafeMath for uint256;

  mapping(address => uint256) public payments;
  uint256 public totalPayments;

   
  function asyncSend(address dest, uint256 amount) internal {
    payments[dest] = payments[dest].add(amount);
    totalPayments = totalPayments.add(amount);
  }

   
  function withdrawPayments() {
    address payee = msg.sender;
    uint256 payment = payments[payee];

    require(payment != 0);
    require(this.balance >= payment);

    totalPayments = totalPayments.sub(payment);
    payments[payee] = 0;

    assert(payee.send(payment));
  }
}

 

contract TrivialToken is StandardToken, PullPayment {
     
    uint256 public minEthAmount = 0.005 ether;
    uint256 public minBidPercentage = 10;
    uint256 public tokensPercentageForKeyHolder = 25;
    uint256 public cleanupDelay = 180 days;
    uint256 public freePeriodDuration = 60 days;

     
    string public name;
    string public symbol;
    uint8 public decimals = 0;
    uint256 public totalSupply;

     
    address public artist;
    address public trivial;

     
    uint256 public icoDuration;
    uint256 public icoEndTime;
    uint256 public auctionDuration;
    uint256 public auctionEndTime;
    uint256 public freePeriodEndTime;

     
    uint256 public tokensForArtist;
    uint256 public tokensForTrivial;
    uint256 public tokensForIco;

     
    uint256 public amountRaised;
    address public highestBidder;
    uint256 public highestBid;
    bytes32 public auctionWinnerMessageHash;
    uint256 public nextContributorIndexToBeGivenTokens;
    uint256 public tokensDistributedToContributors;

     
    event IcoStarted(uint256 icoEndTime);
    event IcoContributed(address contributor, uint256 amountContributed, uint256 amountRaised);
    event IcoFinished(uint256 amountRaised);
    event IcoCancelled();
    event AuctionStarted(uint256 auctionEndTime);
    event HighestBidChanged(address highestBidder, uint256 highestBid);
    event AuctionFinished(address highestBidder, uint256 highestBid);
    event WinnerProvidedHash();

     
    enum State {
        Created, IcoStarted, IcoFinished, AuctionStarted, AuctionFinished, IcoCancelled,
        BeforeInitOne, BeforeInitTwo
    }
    State public currentState;

     
    struct DescriptionHash {
        bytes32 descriptionHash;
        uint256 timestamp;
    }
    DescriptionHash public descriptionHash;
    DescriptionHash[] public descriptionHashHistory;

     
    mapping(address => uint) public contributions;
    address[] public contributors;

     
    modifier onlyInState(State expectedState) { require(expectedState == currentState); _; }
    modifier onlyInTokensTrasferingPeriod() {
        require(currentState == State.IcoFinished || (currentState == State.AuctionStarted && now < auctionEndTime));
        _;
    }
    modifier onlyBefore(uint256 _time) { require(now < _time); _; }
    modifier onlyAfter(uint256 _time) { require(now > _time); _; }
    modifier onlyTrivial() { require(msg.sender == trivial); _; }
    modifier onlyArtist() { require(msg.sender == artist); _; }
    modifier onlyAuctionWinner() {
        require(currentState == State.AuctionFinished);
        require(msg.sender == highestBidder);
        _;
    }

    function TrivialToken() {
        currentState = State.BeforeInitOne;
    }

    function initOne(
        string _name,
        string _symbol,
        uint8 _decimals,
        uint256 _icoDuration,
        uint256 _auctionDuration,
        address _artist,
        address _trivial,
        bytes32 _descriptionHash
    )
    onlyInState(State.BeforeInitOne)
    {
        name = _name;
        symbol = _symbol;
        decimals = _decimals;

        icoDuration = _icoDuration;
        auctionDuration = _auctionDuration;

        artist = _artist;
        trivial = _trivial;

        descriptionHash = DescriptionHash(_descriptionHash, now);
        currentState = State.BeforeInitTwo;
    }

    function initTwo(
        uint256 _totalSupply,
        uint256 _tokensForArtist,
        uint256 _tokensForTrivial,
        uint256 _tokensForIco,
        uint256 _minEthAmount,
        uint256 _minBidPercentage,
        uint256 _tokensPercentageForKeyHolder,
        uint256 _cleanupDelay,
        uint256 _freePeriodDuration
    )
    onlyInState(State.BeforeInitTwo) {
        require(
            _totalSupply == SafeMath.add(
                _tokensForArtist,
                SafeMath.add(_tokensForTrivial, _tokensForIco)
            )
        );
        require(_minBidPercentage < 100);
        require(_tokensPercentageForKeyHolder < 100);

        totalSupply = _totalSupply;
        minEthAmount = _minEthAmount;
        minBidPercentage = _minBidPercentage;
        tokensPercentageForKeyHolder = _tokensPercentageForKeyHolder;
        cleanupDelay = _cleanupDelay;
        freePeriodDuration = _freePeriodDuration;

        tokensForArtist = _tokensForArtist;
        tokensForTrivial = _tokensForTrivial;
        tokensForIco = _tokensForIco;

        currentState = State.Created;
    }

     
    function startIco()
    onlyInState(State.Created)
    onlyTrivial() {
        icoEndTime = SafeMath.add(now, icoDuration);
        freePeriodEndTime = SafeMath.add(icoEndTime, freePeriodDuration);
        currentState = State.IcoStarted;
        IcoStarted(icoEndTime);
    }

    function contributeInIco() payable
    onlyInState(State.IcoStarted)
    onlyBefore(icoEndTime) {
        require(msg.value > minEthAmount);

        if (contributions[msg.sender] == 0) {
            contributors.push(msg.sender);
        }
        contributions[msg.sender] = SafeMath.add(contributions[msg.sender], msg.value);
        amountRaised = SafeMath.add(amountRaised, msg.value);

        IcoContributed(msg.sender, msg.value, amountRaised);
    }

    function distributeTokens(uint256 contributorsNumber)
    onlyInState(State.IcoStarted)
    onlyAfter(icoEndTime) {
        for (uint256 i = 0; i < contributorsNumber && nextContributorIndexToBeGivenTokens < contributors.length; ++i) {
            address currentContributor = contributors[nextContributorIndexToBeGivenTokens++];
            uint256 tokensForContributor = SafeMath.div(
                SafeMath.mul(tokensForIco, contributions[currentContributor]),
                amountRaised   
            );
            balances[currentContributor] = tokensForContributor;
            tokensDistributedToContributors = SafeMath.add(tokensDistributedToContributors, tokensForContributor);
        }
    }

    function finishIco()
    onlyInState(State.IcoStarted)
    onlyAfter(icoEndTime) {
        if (amountRaised == 0) {
            currentState = State.IcoCancelled;
            return;
        }

         
        require(nextContributorIndexToBeGivenTokens >= contributors.length);

        balances[artist] = SafeMath.add(balances[artist], tokensForArtist);
        balances[trivial] = SafeMath.add(balances[trivial], tokensForTrivial);
        uint256 leftovers = SafeMath.sub(tokensForIco, tokensDistributedToContributors);
        balances[artist] = SafeMath.add(balances[artist], leftovers);

        if (!artist.send(this.balance)) {
            asyncSend(artist, this.balance);
        }
        currentState = State.IcoFinished;
        IcoFinished(amountRaised);
    }

    function checkContribution(address contributor) constant returns (uint) {
        return contributions[contributor];
    }

     
    function canStartAuction() returns (bool) {
        bool isArtist = msg.sender == artist;
        bool isKeyHolder = balances[msg.sender] >= SafeMath.div(
        SafeMath.mul(totalSupply, tokensPercentageForKeyHolder), 100);
        return isArtist || isKeyHolder;
    }

    function startAuction()
    onlyAfter(freePeriodEndTime)
    onlyInState(State.IcoFinished) {
        require(canStartAuction());

         
        if (balances[msg.sender] == totalSupply) {
             
            highestBidder = msg.sender;
            currentState = State.AuctionFinished;
            AuctionFinished(highestBidder, highestBid);
            return;
        }

        auctionEndTime = SafeMath.add(now, auctionDuration);
        currentState = State.AuctionStarted;
        AuctionStarted(auctionEndTime);
    }

    function bidInAuction() payable
    onlyInState(State.AuctionStarted)
    onlyBefore(auctionEndTime) {
         
        require(msg.value >= minEthAmount);
        uint256 bid = calculateUserBid();

         
        if (highestBid >= minEthAmount) {
             
            uint256 minimalOverBid = SafeMath.add(highestBid, SafeMath.div(
                SafeMath.mul(highestBid, minBidPercentage), 100
            ));
            require(bid >= minimalOverBid);
             
             
            uint256 amountToReturn = SafeMath.sub(SafeMath.sub(
                this.balance, msg.value
            ), totalPayments);
            if (!highestBidder.send(amountToReturn)) {
                asyncSend(highestBidder, amountToReturn);
            }
        }

        highestBidder = msg.sender;
        highestBid = bid;
        HighestBidChanged(highestBidder, highestBid);
    }

    function calculateUserBid() private returns (uint256) {
        uint256 bid = msg.value;
        uint256 contribution = balanceOf(msg.sender);
        if (contribution > 0) {
             
             
             
            bid = SafeMath.div(
                SafeMath.mul(msg.value, totalSupply),
                SafeMath.sub(totalSupply, contribution)
            );
        }
        return bid;
    }

    function finishAuction()
    onlyInState(State.AuctionStarted)
    onlyAfter(auctionEndTime) {
        require(highestBid > 0);   
        currentState = State.AuctionFinished;
        AuctionFinished(highestBidder, highestBid);
    }

    function withdrawShares(address holder) public
    onlyInState(State.AuctionFinished) {
        uint256 availableTokens = balances[holder];
        require(availableTokens > 0);
        balances[holder] = 0;

        if (holder != highestBidder) {
            holder.transfer(
                SafeMath.div(SafeMath.mul(highestBid, availableTokens), totalSupply)
            );
        }
    }

     

    function contributorsCount() constant returns (uint256) { return contributors.length; }

     
     

     

    function setDescriptionHash(bytes32 _descriptionHash)
    onlyArtist() {
        descriptionHashHistory.push(descriptionHash);
        descriptionHash = DescriptionHash(_descriptionHash, now);
    }

    function setAuctionWinnerMessageHash(bytes32 _auctionWinnerMessageHash)
    onlyAuctionWinner() {
        auctionWinnerMessageHash = _auctionWinnerMessageHash;
        WinnerProvidedHash();
    }

    function killContract()
    onlyTrivial() {
        require(
            (
                currentState == State.AuctionFinished &&
                now > SafeMath.add(auctionEndTime, cleanupDelay)  
            ) ||
            currentState == State.IcoCancelled  
        );
        selfdestruct(trivial);
    }

     
    function getContractState() constant returns (
        uint256, uint256, uint256, uint256, uint256,
        uint256, uint256, address, uint256, State,
        uint256, uint256, uint256
    ) {
        return (
            icoEndTime, auctionDuration, auctionEndTime,
            tokensForArtist, tokensForTrivial, tokensForIco,
            amountRaised, highestBidder, highestBid, currentState,
            tokensPercentageForKeyHolder, minBidPercentage,
            freePeriodEndTime
        );
    }

    function transfer(address _to, uint _value)
    onlyInTokensTrasferingPeriod() returns (bool) {
        if (currentState == State.AuctionStarted) {
            require(_to != highestBidder);
            require(msg.sender != highestBidder);
        }
        return BasicToken.transfer(_to, _value);
    }

    function transferFrom(address _from, address _to, uint256 _value)
    onlyInTokensTrasferingPeriod() returns (bool) {
        if (currentState == State.AuctionStarted) {
            require(_to != highestBidder);
            require(_from != highestBidder);
        }
        return StandardToken.transferFrom(_from, _to, _value);
    }

    function () payable {
        if (currentState == State.IcoStarted) {
            contributeInIco();
        }
        else if (currentState == State.AuctionStarted) {
            bidInAuction();
        }
        else {
            revert();
        }
    }
}