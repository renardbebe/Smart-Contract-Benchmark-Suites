 

pragma solidity ^0.4.18;

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
    Transfer(0x0, _to, _amount);
    return true;
  }

   
  function finishMinting() onlyOwner public returns (bool) {
    mintingFinished = true;
    MintFinished();
    return true;
  }
}

contract Ballot {
    using SafeMath for uint256;
    EthearnalRepToken public tokenContract;

     
    uint256 public ballotStarted;

     
    mapping(address => bool) public votesByAddress;

     
    uint256 public yesVoteSum = 0;

     
    uint256 public noVoteSum = 0;

     
    uint256 public votersLength = 0;

    uint256 public initialQuorumPercent = 51;

    VotingProxy public proxyVotingContract;

     
    bool public isVotingActive = false;

    event FinishBallot(uint256 _time);
    event Vote(address indexed sender, bytes vote);
    
    modifier onlyWhenBallotStarted {
        require(ballotStarted != 0);
        _;
    }

    function Ballot(address _tokenContract) {
        tokenContract = EthearnalRepToken(_tokenContract);
        proxyVotingContract = VotingProxy(msg.sender);
        ballotStarted = getTime();
        isVotingActive = true;
    }
    
    function getQuorumPercent() public constant returns (uint256) {
        require(isVotingActive);
         
        uint256 weeksNumber = getTime().sub(ballotStarted).div(1 weeks);
        if(weeksNumber == 0) {
            return initialQuorumPercent;
        }
        if (initialQuorumPercent < weeksNumber * 10) {
            return 0;
        } else {
            return initialQuorumPercent.sub(weeksNumber * 10);
        }
    }

    function vote(bytes _vote) public onlyWhenBallotStarted {
        require(_vote.length > 0);
        if (isDataYes(_vote)) {
            processVote(true);
        } else if (isDataNo(_vote)) {
            processVote(false);
        }
        Vote(msg.sender, _vote);
    }

    function isDataYes(bytes data) public constant returns (bool) {
         
        return (
            data.length == 3 &&
            (data[0] == 0x59 || data[0] == 0x79) &&
            (data[1] == 0x45 || data[1] == 0x65) &&
            (data[2] == 0x53 || data[2] == 0x73)
        );
    }

     
    function isDataNo(bytes data) public constant returns (bool) {
         
        return (
            data.length == 2 &&
            (data[0] == 0x4e || data[0] == 0x6e) &&
            (data[1] == 0x4f || data[1] == 0x6f)
        );
    }
    
    function processVote(bool isYes) internal {
        require(isVotingActive);
        require(!votesByAddress[msg.sender]);
        votersLength = votersLength.add(1);
        uint256 voteWeight = tokenContract.balanceOf(msg.sender);
        if (isYes) {
            yesVoteSum = yesVoteSum.add(voteWeight);
        } else {
            noVoteSum = noVoteSum.add(voteWeight);
        }
        require(getTime().sub(tokenContract.lastMovement(msg.sender)) > 7 days);
        uint256 quorumPercent = getQuorumPercent();
        if (quorumPercent == 0) {
            isVotingActive = false;
        } else {
            decide();
        }
        votesByAddress[msg.sender] = true;
    }

    function decide() internal {
        uint256 quorumPercent = getQuorumPercent();
        uint256 quorum = quorumPercent.mul(tokenContract.totalSupply()).div(100);
        uint256 soFarVoted = yesVoteSum.add(noVoteSum);
        if (soFarVoted >= quorum) {
            uint256 percentYes = (100 * yesVoteSum).div(soFarVoted);
            if (percentYes >= initialQuorumPercent) {
                 
                proxyVotingContract.proxyIncreaseWithdrawalChunk();
                FinishBallot(now);
                isVotingActive = false;
            } else {
                 
                isVotingActive = false;
                FinishBallot(now);
            }
        }
        
    }

    function getTime() internal returns (uint256) {
         
         
         
        return now;
    }
    
}

contract LockableToken is StandardToken, Ownable {
    bool public isLocked = true;
    mapping (address => uint256) public lastMovement;
    event Burn(address _owner, uint256 _amount);


    function unlock() public onlyOwner {
        isLocked = false;
    }

    function transfer(address _to, uint256 _amount) public returns (bool) {
        require(!isLocked);
        lastMovement[msg.sender] = getTime();
        lastMovement[_to] = getTime();
        return super.transfer(_to, _amount);
    }

    function transferFrom(address _from, address _to, uint256 _value) public returns (bool) {
        require(!isLocked);
        lastMovement[_from] = getTime();
        lastMovement[_to] = getTime();
        super.transferFrom(_from, _to, _value);
    }

    function approve(address _spender, uint256 _value) public returns (bool) {
        require(!isLocked);
        super.approve(_spender, _value);
    }

    function burnFrom(address _from, uint256 _value) public  returns (bool) {
        require(_value <= balances[_from]);
        require(_value <= allowed[_from][msg.sender]);
        balances[_from] = balances[_from].sub(_value);
        allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);

        totalSupply = totalSupply.sub(_value);
        Burn(_from, _value);
        return true;
    }

    function getTime() internal returns (uint256) {
         
         
         
        return now;
    }

    function claimTokens(address _token) public onlyOwner {
        if (_token == 0x0) {
            owner.transfer(this.balance);
            return;
        }
    
        ERC20Basic token = ERC20Basic(_token);
        uint256 balance = token.balanceOf(this);
        token.transfer(owner, balance);
    }

}

contract EthearnalRepToken is MintableToken, LockableToken {
    string public constant name = 'Ethearnal Rep Token';
    string public constant symbol = 'ERT';
    uint8 public constant decimals = 18;
}

contract MultiOwnable {
    mapping (address => bool) public ownerRegistry;
    address[] owners;
    address public multiOwnableCreator = 0x0;

    function MultiOwnable() public {
        multiOwnableCreator = msg.sender;
    }

    function setupOwners(address[] _owners) public {
         
        require(multiOwnableCreator == msg.sender);
        require(owners.length == 0);
        for(uint256 idx=0; idx < _owners.length; idx++) {
            require(
                !ownerRegistry[_owners[idx]] &&
                _owners[idx] != 0x0 &&
                _owners[idx] != address(this)
            );
            ownerRegistry[_owners[idx]] = true;
        }
        owners = _owners;
    }

    modifier onlyOwner() {
        require(ownerRegistry[msg.sender] == true);
        _;
    }

    function getOwners() public constant returns (address[]) {
        return owners;
    }
}

contract EthearnalRepTokenCrowdsale is MultiOwnable {
    using SafeMath for uint256;

     

     
    EthearnalRepToken public token;

     
     
    uint256 etherRateUsd = 1000;

     
    uint256 public tokenRateUsd = 1000;

     
    uint256 public constant saleStartDate = 1519830000;

     
    uint256 public constant saleEndDate = 1522540799;

     
    uint256 public constant teamTokenRatio = uint256(1 * 1000) / 3;

     
    enum State {
        BeforeMainSale,  
        MainSale,  
        MainSaleDone,  
        Finalized  
    }

     
    uint256 public saleCapUsd = 30 * (10**6);

     
    uint256 public weiRaised = 0;

     
     
    bool public isFinalized = false;

     
    address public teamTokenWallet = 0x0;

     
    mapping(address => uint256) public raisedByAddress;

     
    mapping(address => bool) public whitelist;
     
    uint256 public whitelistedInvestorCounter;


     
    uint256 hourLimitByAddressUsd = 1000;

     
    Treasury public treasuryContract = Treasury(0x0);

     
    
    event ChangeReturn(address indexed recipient, uint256 amount);
    event TokenPurchase(address indexed buyer, uint256 weiAmount, uint256 tokenAmount);
     

    function EthearnalRepTokenCrowdsale(
        address[] _owners,
        address _treasuryContract,
        address _teamTokenWallet
    ) {
        require(_owners.length > 1);
        require(_treasuryContract != address(0));
        require(_teamTokenWallet != address(0));
        require(Treasury(_treasuryContract).votingProxyContract() != address(0));
        require(Treasury(_treasuryContract).tokenContract() != address(0));
        treasuryContract = Treasury(_treasuryContract);
        teamTokenWallet = _teamTokenWallet;
        setupOwners(_owners);
    }

    function() public payable {
        if (whitelist[msg.sender]) {
            buyForWhitelisted();
        } else {
            buyTokens();
        }
    }

    function setTokenContract(address _token) public onlyOwner {
        require(_token != address(0) && token == address(0));
        require(EthearnalRepToken(_token).owner() == address(this));
        require(EthearnalRepToken(_token).totalSupply() == 0);
        require(EthearnalRepToken(_token).isLocked());
        require(!EthearnalRepToken(_token).mintingFinished());
        token = EthearnalRepToken(_token);
    }

    function buyForWhitelisted() public payable {
        require(token != address(0));
        address whitelistedInvestor = msg.sender;
        require(whitelist[whitelistedInvestor]);
        uint256 weiToBuy = msg.value;
        require(weiToBuy > 0);
        uint256 tokenAmount = getTokenAmountForEther(weiToBuy);
        require(tokenAmount > 0);
        weiRaised = weiRaised.add(weiToBuy);
        raisedByAddress[whitelistedInvestor] = raisedByAddress[whitelistedInvestor].add(weiToBuy);
        forwardFunds(weiToBuy);
        assert(token.mint(whitelistedInvestor, tokenAmount));
        TokenPurchase(whitelistedInvestor, weiToBuy, tokenAmount);
    }

    function buyTokens() public payable {
        require(token != address(0));
        address recipient = msg.sender;
        State state = getCurrentState();
        uint256 weiToBuy = msg.value;
        require(
            (state == State.MainSale) &&
            (weiToBuy > 0)
        );
        weiToBuy = min(weiToBuy, getWeiAllowedFromAddress(recipient));
        require(weiToBuy > 0);
        weiToBuy = min(weiToBuy, convertUsdToEther(saleCapUsd).sub(weiRaised));
        require(weiToBuy > 0);
        uint256 tokenAmount = getTokenAmountForEther(weiToBuy);
        require(tokenAmount > 0);
        uint256 weiToReturn = msg.value.sub(weiToBuy);
        weiRaised = weiRaised.add(weiToBuy);
        raisedByAddress[recipient] = raisedByAddress[recipient].add(weiToBuy);
        if (weiToReturn > 0) {
            recipient.transfer(weiToReturn);
            ChangeReturn(recipient, weiToReturn);
        }
        forwardFunds(weiToBuy);
        require(token.mint(recipient, tokenAmount));
        TokenPurchase(recipient, weiToBuy, tokenAmount);
    }

     
    function finalizeByAdmin() public onlyOwner {
        finalize();
    }

     

    function forwardFunds(uint256 _weiToBuy) internal {
        treasuryContract.transfer(_weiToBuy);
    }

     
    function convertUsdToEther(uint256 usdAmount) constant internal returns (uint256) {
        return usdAmount.mul(1 ether).div(etherRateUsd);
    }

     
    function getTokenRateEther() public constant returns (uint256) {
         
        return convertUsdToEther(tokenRateUsd).div(1000);
    }

     
    function getTokenAmountForEther(uint256 weiAmount) constant internal returns (uint256) {
        return weiAmount
            .div(getTokenRateEther())
            .mul(10 ** uint256(token.decimals()));
    }

     
    function isReadyToFinalize() internal returns (bool) {
        return(
            (weiRaised >= convertUsdToEther(saleCapUsd)) ||
            (getCurrentState() == State.MainSaleDone)
        );
    }

     
    function min(uint256 a, uint256 b) internal returns (uint256) {
        return (a < b) ? a: b;
    }

     
    function max(uint256 a, uint256 b) internal returns (uint256) {
        return (a > b) ? a: b;
    }

     
    function ceil(uint a, uint b) internal returns (uint) {
        return ((a.add(b).sub(1)).div(b)).mul(b);
    }

     
    function getWeiAllowedFromAddress(address _sender) internal returns (uint256) {
        uint256 secondsElapsed = getTime().sub(saleStartDate);
        uint256 fullHours = ceil(secondsElapsed, 3600).div(3600);
        fullHours = max(1, fullHours);
        uint256 weiLimit = fullHours.mul(convertUsdToEther(hourLimitByAddressUsd));
        return weiLimit.sub(raisedByAddress[_sender]);
    }

    function getTime() internal returns (uint256) {
         
         
         
        return now;
    }

     
    function getCurrentState() internal returns (State) {
        return getStateForTime(getTime());
    }

     
    function getStateForTime(uint256 unixTime) internal returns (State) {
        if (isFinalized) {
             
             
            return State.Finalized;
        }
        if (unixTime < saleStartDate) {
            return State.BeforeMainSale;
        }
        if (unixTime < saleEndDate) {
            return State.MainSale;
        }
        return State.MainSaleDone;
    }

     
    function finalize() private {
        if (!isFinalized) {
            require(isReadyToFinalize());
            isFinalized = true;
            mintTeamTokens();
            token.unlock();
            treasuryContract.setCrowdsaleFinished();
        }
    }

     
    function mintTeamTokens() private {
         
        uint256 tokenAmount = token.totalSupply().mul(teamTokenRatio).div(1000);
        token.mint(teamTokenWallet, tokenAmount);
    }


    function whitelistInvestor(address _newInvestor) public onlyOwner {
        if(!whitelist[_newInvestor]) {
            whitelist[_newInvestor] = true;
            whitelistedInvestorCounter++;
        }
    }
    function whitelistInvestors(address[] _investors) external onlyOwner {
        require(_investors.length <= 250);
        for(uint8 i=0; i<_investors.length;i++) {
            address newInvestor = _investors[i];
            if(!whitelist[newInvestor]) {
                whitelist[newInvestor] = true;
                whitelistedInvestorCounter++;
            }
        }
    }
    function blacklistInvestor(address _investor) public onlyOwner {
        if(whitelist[_investor]) {
            delete whitelist[_investor];
            if(whitelistedInvestorCounter != 0) {
                whitelistedInvestorCounter--;
            }
        }
    }

    function claimTokens(address _token, address _to) public onlyOwner {
        if (_token == 0x0) {
            _to.transfer(this.balance);
            return;
        }
    
        ERC20Basic token = ERC20Basic(_token);
        uint256 balance = token.balanceOf(this);
        token.transfer(_to, balance);
    }

}

contract RefundInvestorsBallot {

    using SafeMath for uint256;
    EthearnalRepToken public tokenContract;

     
    uint256 public ballotStarted;

     
    mapping(address => bool) public votesByAddress;

     
    uint256 public yesVoteSum = 0;

     
    uint256 public noVoteSum = 0;

     
    uint256 public votersLength = 0;

    uint256 public initialQuorumPercent = 51;

    VotingProxy public proxyVotingContract;

     
    bool public isVotingActive = false;
    uint256 public requiredMajorityPercent = 65;

    event FinishBallot(uint256 _time);
    event Vote(address indexed sender, bytes vote);
    
    modifier onlyWhenBallotStarted {
        require(ballotStarted != 0);
        _;
    }

    function vote(bytes _vote) public onlyWhenBallotStarted {
        require(_vote.length > 0);
        if (isDataYes(_vote)) {
            processVote(true);
        } else if (isDataNo(_vote)) {
            processVote(false);
        }
        Vote(msg.sender, _vote);
    }

    function isDataYes(bytes data) public constant returns (bool) {
         
        return (
            data.length == 3 &&
            (data[0] == 0x59 || data[0] == 0x79) &&
            (data[1] == 0x45 || data[1] == 0x65) &&
            (data[2] == 0x53 || data[2] == 0x73)
        );
    }

     
    function isDataNo(bytes data) public constant returns (bool) {
         
        return (
            data.length == 2 &&
            (data[0] == 0x4e || data[0] == 0x6e) &&
            (data[1] == 0x4f || data[1] == 0x6f)
        );
    }
    
    function processVote(bool isYes) internal {
        require(isVotingActive);
        require(!votesByAddress[msg.sender]);
        votersLength = votersLength.add(1);
        uint256 voteWeight = tokenContract.balanceOf(msg.sender);
        if (isYes) {
            yesVoteSum = yesVoteSum.add(voteWeight);
        } else {
            noVoteSum = noVoteSum.add(voteWeight);
        }
        require(getTime().sub(tokenContract.lastMovement(msg.sender)) > 7 days);
        uint256 quorumPercent = getQuorumPercent();
        if (quorumPercent == 0) {
            isVotingActive = false;
        } else {
            decide();
        }
        votesByAddress[msg.sender] = true;
    }

    function getTime() internal returns (uint256) {
         
         
         
        return now;
    }

    function RefundInvestorsBallot(address _tokenContract) {
        tokenContract = EthearnalRepToken(_tokenContract);
        proxyVotingContract = VotingProxy(msg.sender);
        ballotStarted = getTime();
        isVotingActive = true;
    }

    function decide() internal {
        uint256 quorumPercent = getQuorumPercent();
        uint256 quorum = quorumPercent.mul(tokenContract.totalSupply()).div(100);
        uint256 soFarVoted = yesVoteSum.add(noVoteSum);
        if (soFarVoted >= quorum) {
            uint256 percentYes = (100 * yesVoteSum).div(soFarVoted);
            if (percentYes >= requiredMajorityPercent) {
                 
                proxyVotingContract.proxyEnableRefunds();
                FinishBallot(now);
                isVotingActive = false;
            } else {
                 
                isVotingActive = false;
            }
        }
    }
    
    function getQuorumPercent() public constant returns (uint256) {
        uint256 isMonthPassed = getTime().sub(ballotStarted).div(5 weeks);
        if(isMonthPassed == 1){
            return 0;
        }
        return initialQuorumPercent;
    }
    
}

contract Treasury is MultiOwnable {
    using SafeMath for uint256;

     
    uint256 public weiWithdrawed = 0;

     
    uint256 public weiUnlocked = 0;

     
    bool public isCrowdsaleFinished = false;

     
    address teamWallet = 0x0;

     
    EthearnalRepTokenCrowdsale public crowdsaleContract;
    EthearnalRepToken public tokenContract;
    bool public isRefundsEnabled = false;

     
    uint256 public withdrawChunk = 0;
    VotingProxy public votingProxyContract;
    uint256 public refundsIssued = 0;
    uint256 public percentLeft = 0;


    event Deposit(uint256 amount);
    event Withdraw(uint256 amount);
    event UnlockWei(uint256 amount);
    event RefundedInvestor(address indexed investor, uint256 amountRefunded, uint256 tokensBurn);

    function Treasury(address _teamWallet) public {
        require(_teamWallet != 0x0);
         
        teamWallet = _teamWallet;
    }

     
    function() public payable {
        require(msg.sender == address(crowdsaleContract));
        Deposit(msg.value);
    }

    function setVotingProxy(address _votingProxyContract) public onlyOwner {
        require(votingProxyContract == address(0x0));
        votingProxyContract = VotingProxy(_votingProxyContract);
    }

     
    function setCrowdsaleContract(address _address) public onlyOwner {
         
        require(crowdsaleContract == address(0x0));
        require(_address != 0x0);
        crowdsaleContract = EthearnalRepTokenCrowdsale(_address); 
    }

    function setTokenContract(address _address) public onlyOwner {
         
        require(tokenContract == address(0x0));
        require(_address != 0x0);
        tokenContract = EthearnalRepToken(_address);
    }

     
    function setCrowdsaleFinished() public {
        require(crowdsaleContract != address(0x0));
        require(msg.sender == address(crowdsaleContract));
        withdrawChunk = getWeiRaised().div(10);
        weiUnlocked = withdrawChunk;
        isCrowdsaleFinished = true;
    }

     
    function withdrawTeamFunds() public onlyOwner {
        require(isCrowdsaleFinished);
        require(weiUnlocked > weiWithdrawed);
        uint256 toWithdraw = weiUnlocked.sub(weiWithdrawed);
        weiWithdrawed = weiUnlocked;
        teamWallet.transfer(toWithdraw);
        Withdraw(toWithdraw);
    }

    function getWeiRaised() public constant returns(uint256) {
       return crowdsaleContract.weiRaised();
    }

    function increaseWithdrawalChunk() {
        require(isCrowdsaleFinished);
        require(msg.sender == address(votingProxyContract));
        weiUnlocked = weiUnlocked.add(withdrawChunk);
        UnlockWei(weiUnlocked);
    }

    function getTime() internal returns (uint256) {
         
         
         
        return now;
    }

    function enableRefunds() public {
        require(msg.sender == address(votingProxyContract));
        isRefundsEnabled = true;
    }
    
    function refundInvestor(uint256 _tokensToBurn) public {
        require(isRefundsEnabled);
        require(address(tokenContract) != address(0x0));
        if (refundsIssued == 0) {
            percentLeft = percentLeftFromTotalRaised().mul(100*1000).div(1 ether);
        }
        uint256 tokenRate = crowdsaleContract.getTokenRateEther();
        uint256 toRefund = tokenRate.mul(_tokensToBurn).div(1 ether);
        
        toRefund = toRefund.mul(percentLeft).div(100*1000);
        require(toRefund > 0);
        tokenContract.burnFrom(msg.sender, _tokensToBurn);
        msg.sender.transfer(toRefund);
        refundsIssued = refundsIssued.add(1);
        RefundedInvestor(msg.sender, toRefund, _tokensToBurn);
    }

    function percentLeftFromTotalRaised() public constant returns(uint256) {
        return percent(this.balance, getWeiRaised(), 18);
    }

    function percent(uint numerator, uint denominator, uint precision) internal constant returns(uint quotient) {
         
        uint _numerator  = numerator * 10 ** (precision+1);
         
        uint _quotient =  ((_numerator / denominator) + 5) / 10;
        return ( _quotient);
    }

    function claimTokens(address _token, address _to) public onlyOwner {    
        ERC20Basic token = ERC20Basic(_token);
        uint256 balance = token.balanceOf(this);
        token.transfer(_to, balance);
    }
}

contract VotingProxy is Ownable {
    using SafeMath for uint256;    
    Treasury public treasuryContract;
    EthearnalRepToken public tokenContract;
    Ballot public currentIncreaseWithdrawalTeamBallot;
    RefundInvestorsBallot public currentRefundInvestorsBallot;

    function  VotingProxy(address _treasuryContract, address _tokenContract) {
        treasuryContract = Treasury(_treasuryContract);
        tokenContract = EthearnalRepToken(_tokenContract);
    }

    function startincreaseWithdrawalTeam() onlyOwner {
        require(treasuryContract.isCrowdsaleFinished());
        require(address(currentRefundInvestorsBallot) == 0x0 || currentRefundInvestorsBallot.isVotingActive() == false);
        if(address(currentIncreaseWithdrawalTeamBallot) == 0x0) {
            currentIncreaseWithdrawalTeamBallot =  new Ballot(tokenContract);
        } else {
            require(getDaysPassedSinceLastTeamFundsBallot() > 2);
            currentIncreaseWithdrawalTeamBallot =  new Ballot(tokenContract);
        }
    }

    function startRefundInvestorsBallot() public {
        require(treasuryContract.isCrowdsaleFinished());
        require(address(currentIncreaseWithdrawalTeamBallot) == 0x0 || currentIncreaseWithdrawalTeamBallot.isVotingActive() == false);
        if(address(currentRefundInvestorsBallot) == 0x0) {
            currentRefundInvestorsBallot =  new RefundInvestorsBallot(tokenContract);
        } else {
            require(getDaysPassedSinceLastRefundBallot() > 2);
            currentRefundInvestorsBallot =  new RefundInvestorsBallot(tokenContract);
        }
    }

    function getDaysPassedSinceLastRefundBallot() public constant returns(uint256) {
        return getTime().sub(currentRefundInvestorsBallot.ballotStarted()).div(1 days);
    }

    function getDaysPassedSinceLastTeamFundsBallot() public constant returns(uint256) {
        return getTime().sub(currentIncreaseWithdrawalTeamBallot.ballotStarted()).div(1 days);
    }

    function proxyIncreaseWithdrawalChunk() public {
        require(msg.sender == address(currentIncreaseWithdrawalTeamBallot));
        treasuryContract.increaseWithdrawalChunk();
    }

    function proxyEnableRefunds() public {
        require(msg.sender == address(currentRefundInvestorsBallot));
        treasuryContract.enableRefunds();
    }

    function() {
        revert();
    }

    function getTime() internal returns (uint256) {
         
         
         
        return now;
    }

    function claimTokens(address _token) public onlyOwner {
        if (_token == 0x0) {
            owner.transfer(this.balance);
            return;
        }
    
        ERC20Basic token = ERC20Basic(_token);
        uint256 balance = token.balanceOf(this);
        token.transfer(owner, balance);
    }

}