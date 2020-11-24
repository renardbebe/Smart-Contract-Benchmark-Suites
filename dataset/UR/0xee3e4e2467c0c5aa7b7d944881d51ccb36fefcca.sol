 

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

 

 
contract StandardToken is ERC20 {

    using SafeMath for uint256;

    mapping(address => uint256) balances;

    mapping (address => mapping (address => uint256)) internal allowed;

     
    function transfer(address _to, uint256 _value) public returns (bool) {
        require(_to != address(0));
        require(_value <= balances[msg.sender]);

         
        balances[msg.sender] = balances[msg.sender].sub(_value);
        balances[_to] = balances[_to].add(_value);
        Transfer(msg.sender, _to, _value);
        return true;
    }

     
    function balanceOf(address _owner) public constant returns (uint256 balance) {
        return balances[_owner];
    }

     
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

     
    function allowance(address _owner, address _spender) public constant returns (uint256) {
        return allowed[_owner][_spender];
    }

     
    function increaseApproval (address _spender, uint _addedValue) public returns (bool) {
        allowed[msg.sender][_spender] = allowed[msg.sender][_spender].add(_addedValue);
        Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
        return true;
    }

    function decreaseApproval (address _spender, uint _subtractedValue) public returns (bool) {
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
        require(_value <= balances[msg.sender]);

        address burner = msg.sender;
        balances[burner] = balances[burner].sub(_value);
        totalSupply = totalSupply.sub(_value);
        Burn(burner, _value);
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

 

 
contract Claimable is Ownable {
    address public pendingOwner;

     
    modifier onlyPendingOwner() {
        require(msg.sender == pendingOwner);
        _;
    }

     
    function transferOwnership(address newOwner) onlyOwner public {
        pendingOwner = newOwner;
    }

     
    function claimOwnership() onlyPendingOwner public {
        OwnershipTransferred(owner, pendingOwner);
        owner = pendingOwner;
        pendingOwner = address(0);
    }
}

 

 
contract ReleasableToken is ERC20, Claimable {

     
    address public releaseAgent;

     
    bool public released = false;

     
    mapping (address => bool) public transferAgents;

     
    modifier canTransfer(address _sender) {
        if(!released) {
            assert(transferAgents[_sender]);
        }
        _;
    }

     
    function setReleaseAgent(address addr) onlyOwner inReleaseState(false) public {
        require(addr != 0x0);
         
        releaseAgent = addr;
    }

     
    function setTransferAgent(address addr, bool state) onlyOwner inReleaseState(false) public {
        require(addr != 0x0);
        transferAgents[addr] = state;
    }

     
    function releaseTokenTransfer() public onlyReleaseAgent {
        released = true;
    }

     
    modifier inReleaseState(bool releaseState) {
        require(releaseState == released);
        _;
    }

     
    modifier onlyReleaseAgent() {
        require(msg.sender == releaseAgent);
        _;
    }

    function transfer(address _to, uint _value) canTransfer(msg.sender) returns (bool success) {
         
        return super.transfer(_to, _value);
    }

    function transferFrom(address _from, address _to, uint _value) canTransfer(_from) returns (bool success) {
         
        return super.transferFrom(_from, _to, _value);
    }

}

 

 
contract CrowdsaleToken is BurnableToken, ReleasableToken {
    uint public decimals;
}

 

 
contract FinalizeAgent {

  function isFinalizeAgent() public constant returns(bool) {
    return true;
  }

  function isSane() public constant returns (bool);

  function finalizeCrowdsale();

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

 

 
contract InvestmentPolicyCrowdsale is Pausable {

     
    bool public requireCustomerId = false;

     
    bool public requiredSignedAddress = false;

     
    address public signerAddress;

    event InvestmentPolicyChanged(bool newRequireCustomerId, bool newRequiredSignedAddress, address newSignerAddress);

     
    function setRequireCustomerId(bool value) onlyOwner external{
        requireCustomerId = value;
        InvestmentPolicyChanged(requireCustomerId, requiredSignedAddress, signerAddress);
    }

     
    function setRequireSignedAddress(bool value, address _signerAddress) external onlyOwner {
        requiredSignedAddress = value;
        signerAddress = _signerAddress;
        InvestmentPolicyChanged(requireCustomerId, requiredSignedAddress, signerAddress);
    }

     
    function buyWithSignedAddress(uint128 customerId, uint8 v, bytes32 r, bytes32 s) external payable {
        require(requiredSignedAddress);
        bytes memory prefix = "\x19Ethereum Signed Message:\n32";
        bytes32 hash = sha3(prefix, sha3(msg.sender));
        assert(ecrecover(hash, v, r, s) == signerAddress);
        require(customerId != 0);   
        investInternal(msg.sender, customerId);
    }

     
    function buyWithCustomerId(uint128 customerId) external payable {
        require(requireCustomerId);
        require(customerId != 0);
        investInternal(msg.sender, customerId);
    }


    function investInternal(address receiver, uint128 customerId) whenNotPaused internal;
}

 

 
contract PricingStrategy {

   
  uint public presaleMaxValue = 0;

  function isPricingStrategy() external constant returns (bool) {
      return true;
  }

  function getPresaleMaxValue() public constant returns (uint) {
      return presaleMaxValue;
  }

  function isPresaleFull(uint weiRaised) public constant returns (bool);

  function getAmountOfTokens(uint value, uint weiRaised) public constant returns (uint tokensAmount);
}

 

 

contract AlgoryCrowdsale is InvestmentPolicyCrowdsale {

     
    uint constant public MAX_INVESTMENTS_BEFORE_MULTISIG_CHANGE = 5;

    using SafeMath for uint;

     
    CrowdsaleToken public token;

     
    PricingStrategy public pricingStrategy;

     
    FinalizeAgent public finalizeAgent;

     
    address public multisigWallet;

     
    address public beneficiary;

     
    uint public presaleStartsAt;

     
    uint public startsAt;

     
    uint public endsAt;

     
    uint public tokensSold = 0;

     
    uint public weiRaised = 0;

     
    uint public whitelistWeiRaised = 0;

     
    uint public presaleWeiRaised = 0;

     
    uint public investorCount = 0;

     
    uint public loadedRefund = 0;

     
    uint public weiRefunded = 0;

     
    bool public finalized = false;

     
    bool public allowRefund = false;

     
    bool private isPreallocated = false;

     
    mapping (address => uint256) public investedAmountOf;

     
    mapping (address => uint256) public tokenAmountOf;

     
    mapping (address => uint) public earlyParticipantWhitelist;

     
    enum State{Unknown, Preparing, PreFunding, Funding, Success, Failure, Finalized, Refunding}

     
    event Invested(address investor, uint weiAmount, uint tokenAmount, uint128 customerId);

     
    event Refund(address investor, uint weiAmount);

     
    event Whitelisted(address addr, uint value);

     
    event TimeBoundaryChanged(string timeBoundary, uint timestamp);

     
    modifier inState(State state) {
        require(getState() == state);
        _;
    }

    function AlgoryCrowdsale(address _token, address _beneficiary, PricingStrategy _pricingStrategy, address _multisigWallet, uint _presaleStart, uint _start, uint _end) public {
        owner = msg.sender;
        token = CrowdsaleToken(_token);
        beneficiary = _beneficiary;

        presaleStartsAt = _presaleStart;
        startsAt = _start;
        endsAt = _end;

        require(now < presaleStartsAt && presaleStartsAt <= startsAt && startsAt < endsAt);

        setPricingStrategy(_pricingStrategy);
        setMultisigWallet(_multisigWallet);

        require(beneficiary != 0x0 && address(token) != 0x0);
        assert(token.balanceOf(beneficiary) == token.totalSupply());

    }

    function prepareCrowdsale() onlyOwner external {
        require(!isPreallocated);
        require(isAllTokensApproved());
        preallocateTokens();
        isPreallocated = true;
    }

     
    function() payable {
        require(!requireCustomerId);  
        require(!requiredSignedAddress);  
        investInternal(msg.sender, 0);
    }

    function setFinalizeAgent(FinalizeAgent agent) onlyOwner external{
        finalizeAgent = agent;
        require(finalizeAgent.isFinalizeAgent());
        require(finalizeAgent.isSane());
    }

    function setPresaleStartsAt(uint presaleStart) inState(State.Preparing) onlyOwner external {
        require(presaleStart <= startsAt && presaleStart < endsAt);
        presaleStartsAt = presaleStart;
        TimeBoundaryChanged('presaleStartsAt', presaleStartsAt);
    }

    function setStartsAt(uint start) onlyOwner external {
        require(presaleStartsAt < start && start < endsAt);
        State state = getState();
        assert(state == State.Preparing || state == State.PreFunding);
        startsAt = start;
        TimeBoundaryChanged('startsAt', startsAt);
    }

    function setEndsAt(uint end) onlyOwner external {
        require(end > startsAt && end > presaleStartsAt);
        endsAt = end;
        TimeBoundaryChanged('endsAt', endsAt);
    }

    function loadEarlyParticipantsWhitelist(address[] participantsArray, uint[] valuesArray) onlyOwner external {
        address participant = 0x0;
        uint value = 0;
        for (uint i = 0; i < participantsArray.length; i++) {
            participant = participantsArray[i];
            value = valuesArray[i];
            setEarlyParticipantWhitelist(participant, value);
        }
    }

     
    function finalize() inState(State.Success) onlyOwner whenNotPaused external {
        require(!finalized);
        finalizeAgent.finalizeCrowdsale();
        finalized = true;
    }

    function allowRefunding(bool val) onlyOwner external {
        State state = getState();
        require(paused || state == State.Success || state == State.Failure || state == State.Refunding);
        allowRefund = val;
    }

    function loadRefund() inState(State.Failure) external payable {
        require(msg.value != 0);
        loadedRefund = loadedRefund.add(msg.value);
    }

    function refund() inState(State.Refunding) external {
        require(allowRefund);
        uint256 weiValue = investedAmountOf[msg.sender];
        require(weiValue != 0);
        investedAmountOf[msg.sender] = 0;
        weiRefunded = weiRefunded.add(weiValue);
        Refund(msg.sender, weiValue);
        msg.sender.transfer(weiValue);
    }

    function setPricingStrategy(PricingStrategy _pricingStrategy) onlyOwner public {
        State state = getState();
        if (state == State.PreFunding || state == State.Funding) {
            require(paused);
        }
        pricingStrategy = _pricingStrategy;
        require(pricingStrategy.isPricingStrategy());
    }

    function setMultisigWallet(address wallet) onlyOwner public {
        require(wallet != 0x0);
        require(investorCount <= MAX_INVESTMENTS_BEFORE_MULTISIG_CHANGE);
        multisigWallet = wallet;
    }

    function setEarlyParticipantWhitelist(address participant, uint value) onlyOwner public {
        require(value != 0 && participant != 0x0);
        require(value <= pricingStrategy.getPresaleMaxValue());
        assert(!pricingStrategy.isPresaleFull(whitelistWeiRaised));
        if(earlyParticipantWhitelist[participant] > 0) {
            whitelistWeiRaised = whitelistWeiRaised.sub(earlyParticipantWhitelist[participant]);
        }
        earlyParticipantWhitelist[participant] = value;
        whitelistWeiRaised = whitelistWeiRaised.add(value);
        Whitelisted(participant, value);
    }

    function getTokensLeft() public constant returns (uint) {
        return token.allowance(beneficiary, this);
    }

    function isCrowdsaleFull() public constant returns (bool) {
        return getTokensLeft() == 0;
    }

    function getState() public constant returns (State) {
        if(finalized) return State.Finalized;
        else if (!isPreallocated) return State.Preparing;
        else if (address(finalizeAgent) == 0) return State.Preparing;
        else if (block.timestamp < presaleStartsAt) return State.Preparing;
        else if (block.timestamp >= presaleStartsAt && block.timestamp < startsAt) return State.PreFunding;
        else if (block.timestamp <= endsAt && block.timestamp >= startsAt && !isCrowdsaleFull()) return State.Funding;
        else if (!allowRefund && isCrowdsaleFull()) return State.Success;
        else if (!allowRefund && block.timestamp > endsAt) return State.Success;
        else if (allowRefund && weiRaised > 0 && loadedRefund >= weiRaised) return State.Refunding;
        else return State.Failure;
    }

     
    function isAllTokensApproved() private constant returns (bool) {
        return getTokensLeft() == token.totalSupply() - tokensSold
                && token.transferAgents(beneficiary);
    }

    function isBreakingCap(uint tokenAmount) private constant returns (bool limitBroken) {
        return tokenAmount > getTokensLeft();
    }

    function investInternal(address receiver, uint128 customerId) whenNotPaused internal{
        State state = getState();
        require(state == State.PreFunding || state == State.Funding);
        uint weiAmount = msg.value;
        uint tokenAmount = 0;


        if (state == State.PreFunding) {
            require(earlyParticipantWhitelist[receiver] > 0);
            require(weiAmount <= earlyParticipantWhitelist[receiver]);
            assert(!pricingStrategy.isPresaleFull(presaleWeiRaised));
        }

        tokenAmount = pricingStrategy.getAmountOfTokens(weiAmount, weiRaised);
        require(tokenAmount > 0);
        if (investedAmountOf[receiver] == 0) {
            investorCount++;
        }

        investedAmountOf[receiver] = investedAmountOf[receiver].add(weiAmount);
        tokenAmountOf[receiver] = tokenAmountOf[receiver].add(tokenAmount);
        weiRaised = weiRaised.add(weiAmount);
        tokensSold = tokensSold.add(tokenAmount);

        if (state == State.PreFunding) {
            presaleWeiRaised = presaleWeiRaised.add(weiAmount);
            earlyParticipantWhitelist[receiver] = earlyParticipantWhitelist[receiver].sub(weiAmount);
        }

        require(!isBreakingCap(tokenAmount));

        assignTokens(receiver, tokenAmount);

        require(multisigWallet.send(weiAmount));

        Invested(receiver, weiAmount, tokenAmount, customerId);
    }

    function assignTokens(address receiver, uint tokenAmount) private {
        require(token.transferFrom(beneficiary, receiver, tokenAmount));
    }

     
    function preallocateTokens() private {
        uint multiplier = 10 ** 18;
        assignTokens(0xc8337b3e03f5946854e6C5d2F5f3Ad0511Bb2599, 4300000 * multiplier);  
        assignTokens(0x354d755460A677B60A2B5e025A3b7397856b518E, 4100000 * multiplier);  
        assignTokens(0x6AC724A02A4f47179A89d4A7532ED7030F55fD34, 2400000 * multiplier);  
    }

}