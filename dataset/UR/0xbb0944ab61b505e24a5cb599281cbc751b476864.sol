 

pragma solidity ^0.4.24;


 
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

contract Whitelist is Ownable {
    mapping(address => bool) whitelist;
    event AddedToWhitelist(address indexed account);
    event RemovedFromWhitelist(address indexed account);

    modifier onlyWhitelisted() {
        require(isWhitelisted(msg.sender));
        _;
    }

    function add(address _address) public onlyOwner {
        whitelist[_address] = true;
        emit AddedToWhitelist(_address);
    }

    function remove(address _address) public onlyOwner {
        whitelist[_address] = false;
        emit RemovedFromWhitelist(_address);
    }

    function isWhitelisted(address _address) public view returns(bool) {
        return whitelist[_address];
    }
}


 
contract ERC20Basic {
  function totalSupply() public view returns (uint256);
  function balanceOf(address who) public view returns (uint256);
  function transfer(address to, uint256 value) public returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
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






 
contract ERC20 is ERC20Basic {
  function allowance(address owner, address spender) public view returns (uint256);
  function transferFrom(address from, address to, uint256 value) public returns (bool);
  function approve(address spender, uint256 value) public returns (bool);
  event Approval(address indexed owner, address indexed spender, uint256 value);
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


contract CrowdfundableToken is MintableToken {
    string public name;
    string public symbol;
    uint8 public decimals;
    uint256 public cap;

    function CrowdfundableToken(uint256 _cap, string _name, string _symbol, uint8 _decimals) public {
        require(_cap > 0);
        require(bytes(_name).length > 0);
        require(bytes(_symbol).length > 0);
        cap = _cap;
        name = _name;
        symbol = _symbol;
        decimals = _decimals;
    }

     
    function mint(address _to, uint256 _amount) onlyOwner canMint public returns (bool) {
        require(totalSupply_.add(_amount) <= cap);
        return super.mint(_to, _amount);
    }

     
    function transfer(address _to, uint256 _value) public returns (bool) {
        require(mintingFinished == true);
        return super.transfer(_to, _value);
    }

     
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool) {
        require(mintingFinished == true);
        return super.transferFrom(_from, _to, _value);
    }

    function burn(uint amount) public {
        totalSupply_ = totalSupply_.sub(amount);
        balances[msg.sender] = balances[msg.sender].sub(amount);
    }
}

contract Minter is Ownable {
    using SafeMath for uint;

     

    event Minted(address indexed account, uint etherAmount, uint tokenAmount);
    event Reserved(uint etherAmount);
    event MintedReserved(address indexed account, uint etherAmount, uint tokenAmount);
    event Unreserved(uint etherAmount);

     

    CrowdfundableToken public token;
    uint public saleEtherCap;
    uint public confirmedSaleEther;
    uint public reservedSaleEther;

     

    modifier onlyInUpdatedState() {
        updateState();
        _;
    }

    modifier upToSaleEtherCap(uint additionalEtherAmount) {
        uint totalEtherAmount = confirmedSaleEther.add(reservedSaleEther).add(additionalEtherAmount);
        require(totalEtherAmount <= saleEtherCap);
        _;
    }

    modifier onlyApprovedMinter() {
        require(canMint(msg.sender));
        _;
    }

    modifier atLeastMinimumAmount(uint etherAmount) {
        require(etherAmount >= getMinimumContribution());
        _;
    }

    modifier onlyValidAddress(address account) {
        require(account != 0x0);
        _;
    }

     

    constructor(CrowdfundableToken _token, uint _saleEtherCap) public onlyValidAddress(address(_token)) {
        require(_saleEtherCap > 0);

        token = _token;
        saleEtherCap = _saleEtherCap;
    }

     

    function transferTokenOwnership() external onlyOwner {
        token.transferOwnership(owner);
    }

    function reserve(uint etherAmount) external
        onlyInUpdatedState
        onlyApprovedMinter
        upToSaleEtherCap(etherAmount)
        atLeastMinimumAmount(etherAmount)
    {
        reservedSaleEther = reservedSaleEther.add(etherAmount);
        updateState();
        emit Reserved(etherAmount);
    }

    function mintReserved(address account, uint etherAmount, uint tokenAmount) external
        onlyInUpdatedState
        onlyApprovedMinter
    {
        reservedSaleEther = reservedSaleEther.sub(etherAmount);
        confirmedSaleEther = confirmedSaleEther.add(etherAmount);
        token.mint(account, tokenAmount);
        updateState();
        emit MintedReserved(account, etherAmount, tokenAmount);
    }

    function unreserve(uint etherAmount) public
        onlyInUpdatedState
        onlyApprovedMinter
    {
        reservedSaleEther = reservedSaleEther.sub(etherAmount);
        updateState();
        emit Unreserved(etherAmount);
    }

    function mint(address account, uint etherAmount, uint tokenAmount) public
        onlyInUpdatedState
        onlyApprovedMinter
        upToSaleEtherCap(etherAmount)
    {
        confirmedSaleEther = confirmedSaleEther.add(etherAmount);
        token.mint(account, tokenAmount);
        updateState();
        emit Minted(account, etherAmount, tokenAmount);
    }

     
    function getMinimumContribution() public view returns(uint);

     
    function updateState() public;

     
    function canMint(address sender) public view returns(bool);

     
    function getTokensForEther(uint etherAmount) public view returns(uint);
}

contract Tge is Minter {
    using SafeMath for uint;

     

    uint constant public MIMIMUM_CONTRIBUTION_AMOUNT_PREICO = 1 ether;
    uint constant public MIMIMUM_CONTRIBUTION_AMOUNT_ICO = 1 ether / 5;
    
    uint constant public PRICE_MULTIPLIER_PREICO1 = 2600500;
    uint constant public PRICE_MULTIPLIER_PREICO2 = 2510800;

    uint constant public PRICE_MULTIPLIER_ICO1 = 2275400;
    uint constant public PRICE_MULTIPLIER_ICO2 = 2206400;
    uint constant public PRICE_MULTIPLIER_ICO3 = 2080300;
    uint constant public PRICE_MULTIPLIER_ICO4 = 2022500;
    uint constant public PRICE_MULTIPLIER_ICO5 = 1916000;
    uint constant public PRICE_MULTIPLIER_ICO6 = 1820200;
    uint constant public PRICE_DIVIDER = 1000;

     

    event StateChanged(uint from, uint to);
    event PrivateIcoInitialized(uint _cap, uint _tokensForEther, uint _startTime, uint _endTime, uint _minimumContribution);
    event PrivateIcoFinalized();

     

     
    address public crowdsale;
    address public deferredKyc;
    address public referralManager;
    address public allocator;
    address public airdropper;

     
    enum State {Presale, Preico1, Preico2, Break, Ico1, Ico2, Ico3, Ico4, Ico5, Ico6, FinishingIco, Allocating, Airdropping, Finished}
    State public currentState = State.Presale;
    mapping(uint => uint) public startTimes;
    mapping(uint => uint) public etherCaps;

     
    bool public privateIcoFinalized = true;
    uint public privateIcoCap = 0;
    uint public privateIcoTokensForEther = 0;
    uint public privateIcoStartTime = 0;
    uint public privateIcoEndTime = 0;
    uint public privateIcoMinimumContribution = 0;

     

    modifier onlyInState(State _state) {
        require(_state == currentState);
        _;
    }

    modifier onlyValidAddress(address account) {
        require(account != 0x0);
        _;
    }

     

    constructor(
        CrowdfundableToken _token,
        uint _saleEtherCap
    ) public Minter(_token, _saleEtherCap) { }

     
    function setupStates(uint saleStart, uint singleStateEtherCap, uint[] stateLengths) internal {
        require(!isPrivateIcoActive());

        startTimes[uint(State.Preico1)] = saleStart;
        setStateLength(State.Preico1, stateLengths[0]);
        setStateLength(State.Preico2, stateLengths[1]);
        setStateLength(State.Break, stateLengths[2]);
        setStateLength(State.Ico1, stateLengths[3]);
        setStateLength(State.Ico2, stateLengths[4]);
        setStateLength(State.Ico3, stateLengths[5]);
        setStateLength(State.Ico4, stateLengths[6]);
        setStateLength(State.Ico5, stateLengths[7]);
        setStateLength(State.Ico6, stateLengths[8]);

         
         
         
        etherCaps[uint(State.Preico1)] = singleStateEtherCap;
        etherCaps[uint(State.Preico2)] = singleStateEtherCap.mul(2);
        etherCaps[uint(State.Ico1)] = singleStateEtherCap.mul(3);
        etherCaps[uint(State.Ico2)] = singleStateEtherCap.mul(4);
        etherCaps[uint(State.Ico3)] = singleStateEtherCap.mul(5);
        etherCaps[uint(State.Ico4)] = singleStateEtherCap.mul(6);
        etherCaps[uint(State.Ico5)] = singleStateEtherCap.mul(7);
        etherCaps[uint(State.Ico6)] = singleStateEtherCap.mul(8);
    }

    function setup(
        address _crowdsale,
        address _deferredKyc,
        address _referralManager,
        address _allocator,
        address _airdropper,
        uint saleStartTime,
        uint singleStateEtherCap,
        uint[] stateLengths
    )
    public
    onlyOwner
    onlyInState(State.Presale)
    onlyValidAddress(_crowdsale)
    onlyValidAddress(_deferredKyc)
    onlyValidAddress(_referralManager)
    onlyValidAddress(_allocator)
    onlyValidAddress(_airdropper)
    {
        require(stateLengths.length == 9);  
        require(saleStartTime >= now);
        require(singleStateEtherCap > 0);
        crowdsale = _crowdsale;
        deferredKyc = _deferredKyc;
        referralManager = _referralManager;
        allocator = _allocator;
        airdropper = _airdropper;
        setupStates(saleStartTime, singleStateEtherCap, stateLengths);
    }

     

    function moveState(uint from, uint to) external onlyInUpdatedState onlyOwner {
        require(uint(currentState) == from);
        advanceStateIfNewer(State(to));
    }

     
    function transferTokenOwnership() external onlyInUpdatedState onlyOwner {
        require(currentState == State.Finished);
        token.transferOwnership(owner);
    }

     
    function getTokensForEther(uint etherAmount) public view returns(uint) {
        uint tokenAmount = 0;
        if (isPrivateIcoActive()) tokenAmount = etherAmount.mul(privateIcoTokensForEther).div(PRICE_DIVIDER);
        else if (currentState == State.Preico1) tokenAmount = etherAmount.mul(PRICE_MULTIPLIER_PREICO1).div(PRICE_DIVIDER);
        else if (currentState == State.Preico2) tokenAmount = etherAmount.mul(PRICE_MULTIPLIER_PREICO2).div(PRICE_DIVIDER);
        else if (currentState == State.Ico1) tokenAmount = etherAmount.mul(PRICE_MULTIPLIER_ICO1).div(PRICE_DIVIDER);
        else if (currentState == State.Ico2) tokenAmount = etherAmount.mul(PRICE_MULTIPLIER_ICO2).div(PRICE_DIVIDER);
        else if (currentState == State.Ico3) tokenAmount = etherAmount.mul(PRICE_MULTIPLIER_ICO3).div(PRICE_DIVIDER);
        else if (currentState == State.Ico4) tokenAmount = etherAmount.mul(PRICE_MULTIPLIER_ICO4).div(PRICE_DIVIDER);
        else if (currentState == State.Ico5) tokenAmount = etherAmount.mul(PRICE_MULTIPLIER_ICO5).div(PRICE_DIVIDER);
        else if (currentState == State.Ico6) tokenAmount = etherAmount.mul(PRICE_MULTIPLIER_ICO6).div(PRICE_DIVIDER);

        return tokenAmount;
    }

    function isSellingState() public view returns(bool) {
        if (currentState == State.Presale) return isPrivateIcoActive();
        return (
            uint(currentState) >= uint(State.Preico1) &&
            uint(currentState) <= uint(State.Ico6) &&
            uint(currentState) != uint(State.Break)
        );
    }

    function isPrivateIcoActive() public view returns(bool) {
        return now >= privateIcoStartTime && now < privateIcoEndTime;
    }

    function initPrivateIco(uint _cap, uint _tokensForEther, uint _startTime, uint _endTime, uint _minimumContribution) external onlyOwner {
        require(_startTime > privateIcoEndTime);  
        require(now >= privateIcoEndTime);  
        require(privateIcoFinalized);  
        require(_tokensForEther > 0);
        require(_endTime > _startTime);
        require(_endTime < startTimes[uint(State.Preico1)]);

        privateIcoCap = _cap;
        privateIcoTokensForEther = _tokensForEther;
        privateIcoStartTime = _startTime;
        privateIcoEndTime = _endTime;
        privateIcoMinimumContribution = _minimumContribution;
        privateIcoFinalized = false;
        emit PrivateIcoInitialized(_cap, _tokensForEther, _startTime, _endTime, _minimumContribution);
    }

    function finalizePrivateIco() external onlyOwner {
        require(!isPrivateIcoActive());
        require(now >= privateIcoEndTime);  
        require(!privateIcoFinalized);
        require(reservedSaleEther == 0);  

        privateIcoFinalized = true;
        confirmedSaleEther = 0;
        emit PrivateIcoFinalized();
    }

     

     
    function getMinimumContribution() public view returns(uint) {
        if (currentState == State.Preico1 || currentState == State.Preico2) {
            return MIMIMUM_CONTRIBUTION_AMOUNT_PREICO;
        }
        if (uint(currentState) >= uint(State.Ico1) && uint(currentState) <= uint(State.Ico6)) {
            return MIMIMUM_CONTRIBUTION_AMOUNT_ICO;
        }
        if (isPrivateIcoActive()) {
            return privateIcoMinimumContribution;
        }
        return 0;
    }

     
    function canMint(address account) public view returns(bool) {
        if (currentState == State.Presale) {
             
            return account == crowdsale || account == deferredKyc;
        }
        else if (isSellingState()) {
             
             
             
            return account == crowdsale || account == deferredKyc || account == referralManager;
        }
        else if (currentState == State.Break || currentState == State.FinishingIco) {
             
             
             
            return account == crowdsale || account == deferredKyc || account == referralManager;
        }
        else if (currentState == State.Allocating) {
             
             
             
             
            return account == allocator;
        }
        else if (currentState == State.Airdropping) {
             
            return account == airdropper;
        }
        return false;
    }

     
    function updateState() public {
        updateStateBasedOnTime();
        updateStateBasedOnContributions();
    }

    function updateStateBasedOnTime() internal {
         
        if (now >= startTimes[uint(State.FinishingIco)]) advanceStateIfNewer(State.FinishingIco);
        else if (now >= startTimes[uint(State.Ico6)]) advanceStateIfNewer(State.Ico6);
        else if (now >= startTimes[uint(State.Ico5)]) advanceStateIfNewer(State.Ico5);
        else if (now >= startTimes[uint(State.Ico4)]) advanceStateIfNewer(State.Ico4);
        else if (now >= startTimes[uint(State.Ico3)]) advanceStateIfNewer(State.Ico3);
        else if (now >= startTimes[uint(State.Ico2)]) advanceStateIfNewer(State.Ico2);
        else if (now >= startTimes[uint(State.Ico1)]) advanceStateIfNewer(State.Ico1);
        else if (now >= startTimes[uint(State.Break)]) advanceStateIfNewer(State.Break);
        else if (now >= startTimes[uint(State.Preico2)]) advanceStateIfNewer(State.Preico2);
        else if (now >= startTimes[uint(State.Preico1)]) advanceStateIfNewer(State.Preico1);
    }

    function updateStateBasedOnContributions() internal {
         
        uint totalEtherContributions = confirmedSaleEther.add(reservedSaleEther);
        if(isPrivateIcoActive()) {
             
            require(totalEtherContributions <= privateIcoCap);
            return;
        }
        
        if (!isSellingState()) {
            return;
        }
        
        else if (int(currentState) < int(State.Break)) {
             
            if (totalEtherContributions >= etherCaps[uint(State.Preico2)]) advanceStateIfNewer(State.Break);
            else if (totalEtherContributions >= etherCaps[uint(State.Preico1)]) advanceStateIfNewer(State.Preico2);
        }
        else {
             
            if (totalEtherContributions >= etherCaps[uint(State.Ico6)]) advanceStateIfNewer(State.FinishingIco);
            else if (totalEtherContributions >= etherCaps[uint(State.Ico5)]) advanceStateIfNewer(State.Ico6);
            else if (totalEtherContributions >= etherCaps[uint(State.Ico4)]) advanceStateIfNewer(State.Ico5);
            else if (totalEtherContributions >= etherCaps[uint(State.Ico3)]) advanceStateIfNewer(State.Ico4);
            else if (totalEtherContributions >= etherCaps[uint(State.Ico2)]) advanceStateIfNewer(State.Ico3);
            else if (totalEtherContributions >= etherCaps[uint(State.Ico1)]) advanceStateIfNewer(State.Ico2);
        }
    }

    function advanceStateIfNewer(State newState) internal {
        if (uint(newState) > uint(currentState)) {
            emit StateChanged(uint(currentState), uint(newState));
            currentState = newState;
        }
    }

    function setStateLength(State state, uint length) internal {
         
        startTimes[uint(state)+1] = startTimes[uint(state)].add(length);
    }

    function isInitialized() public view returns(bool) {
        return crowdsale != 0x0 && referralManager != 0x0 && allocator != 0x0 && airdropper != 0x0 && deferredKyc != 0x0;
    }
}


contract LockingContract is Ownable {
    using SafeMath for uint256;

    event NotedTokens(address indexed _beneficiary, uint256 _tokenAmount);
    event ReleasedTokens(address indexed _beneficiary);
    event ReducedLockingTime(uint256 _newUnlockTime);

    ERC20 public tokenContract;
    mapping(address => uint256) public tokens;
    uint256 public totalTokens;
    uint256 public unlockTime;

    function isLocked() public view returns(bool) {
        return now < unlockTime;
    }

    modifier onlyWhenUnlocked() {
        require(!isLocked());
        _;
    }

    modifier onlyWhenLocked() {
        require(isLocked());
        _;
    }

    function LockingContract(ERC20 _tokenContract, uint256 _unlockTime) public {
        require(_unlockTime > now);
        require(address(_tokenContract) != 0x0);
        unlockTime = _unlockTime;
        tokenContract = _tokenContract;
    }

    function balanceOf(address _owner) public view returns (uint256 balance) {
        return tokens[_owner];
    }

     
     
     
    function noteTokens(address _beneficiary, uint256 _tokenAmount) external onlyOwner onlyWhenLocked {
        uint256 tokenBalance = tokenContract.balanceOf(this);
        require(tokenBalance >= totalTokens.add(_tokenAmount));

        tokens[_beneficiary] = tokens[_beneficiary].add(_tokenAmount);
        totalTokens = totalTokens.add(_tokenAmount);
        emit NotedTokens(_beneficiary, _tokenAmount);
    }

    function releaseTokens(address _beneficiary) public onlyWhenUnlocked {
        require(msg.sender == owner || msg.sender == _beneficiary);
        uint256 amount = tokens[_beneficiary];
        tokens[_beneficiary] = 0;
        require(tokenContract.transfer(_beneficiary, amount)); 
        totalTokens = totalTokens.sub(amount);
        emit ReleasedTokens(_beneficiary);
    }

    function reduceLockingTime(uint256 _newUnlockTime) public onlyOwner onlyWhenLocked {
        require(_newUnlockTime >= now);
        require(_newUnlockTime < unlockTime);
        unlockTime = _newUnlockTime;
        emit ReducedLockingTime(_newUnlockTime);
    }
}


contract DeferredKyc is Ownable {
    using SafeMath for uint;

     

    event AddedToKyc(address indexed investor, uint etherAmount, uint tokenAmount);
    event Approved(address indexed investor, uint etherAmount, uint tokenAmount);
    event Rejected(address indexed investor, uint etherAmount, uint tokenAmount);
    event RejectedWithdrawn(address indexed investor, uint etherAmount);
    event ApproverTransferred(address newApprover);
    event TreasuryUpdated(address newTreasury);

     

    address public treasury;
    Minter public minter;
    address public approver;
    mapping(address => uint) public etherInProgress;
    mapping(address => uint) public tokenInProgress;
    mapping(address => uint) public etherRejected;

      

    modifier onlyApprover() {
        require(msg.sender == approver);
        _;
    }

    modifier onlyValidAddress(address account) {
        require(account != 0x0);
        _;
    }

     

    constructor(Minter _minter, address _approver, address _treasury)
        public
        onlyValidAddress(address(_minter))
        onlyValidAddress(_approver)
        onlyValidAddress(_treasury)
    {
        minter = _minter;
        approver = _approver;
        treasury = _treasury;
    }

     

    function updateTreasury(address newTreasury) external onlyOwner {
        treasury = newTreasury;
        emit TreasuryUpdated(newTreasury);
    }

    function addToKyc(address investor) external payable onlyOwner {
        minter.reserve(msg.value);
        uint tokenAmount = minter.getTokensForEther(msg.value);
        require(tokenAmount > 0);
        emit AddedToKyc(investor, msg.value, tokenAmount);

        etherInProgress[investor] = etherInProgress[investor].add(msg.value);
        tokenInProgress[investor] = tokenInProgress[investor].add(tokenAmount);
    }

    function approve(address investor) external onlyApprover {
        minter.mintReserved(investor, etherInProgress[investor], tokenInProgress[investor]);
        emit Approved(investor, etherInProgress[investor], tokenInProgress[investor]);
        
        uint value = etherInProgress[investor];
        etherInProgress[investor] = 0;
        tokenInProgress[investor] = 0;
        treasury.transfer(value);
    }

    function reject(address investor) external onlyApprover {
        minter.unreserve(etherInProgress[investor]);
        emit Rejected(investor, etherInProgress[investor], tokenInProgress[investor]);

        etherRejected[investor] = etherRejected[investor].add(etherInProgress[investor]);
        etherInProgress[investor] = 0;
        tokenInProgress[investor] = 0;
    }

    function withdrawRejected() external {
        uint value = etherRejected[msg.sender];
        etherRejected[msg.sender] = 0;
        (msg.sender).transfer(value);
        emit RejectedWithdrawn(msg.sender, value);
    }

    function forceWithdrawRejected(address investor) external onlyApprover {
        uint value = etherRejected[investor];
        etherRejected[investor] = 0;
        (investor).transfer(value);
        emit RejectedWithdrawn(investor, value);
    }

    function transferApprover(address newApprover) external onlyApprover {
        approver = newApprover;
        emit ApproverTransferred(newApprover);
    }
}

contract SingleLockingContract is Ownable {
    using SafeMath for uint256;

     

    event ReleasedTokens(address indexed _beneficiary);

     

    ERC20 public tokenContract;
    uint256 public unlockTime;
    address public beneficiary;

     

    modifier onlyWhenUnlocked() {
        require(!isLocked());
        _;
    }

    modifier onlyWhenLocked() {
        require(isLocked());
        _;
    }

     

    function SingleLockingContract(ERC20 _tokenContract, uint256 _unlockTime, address _beneficiary) public {
        require(_unlockTime > now);
        require(address(_tokenContract) != 0x0);
        require(_beneficiary != 0x0);

        unlockTime = _unlockTime;
        tokenContract = _tokenContract;
        beneficiary = _beneficiary;
    }

     

    function isLocked() public view returns(bool) {
        return now < unlockTime;
    }

    function balanceOf() public view returns (uint256 balance) {
        return tokenContract.balanceOf(address(this));
    }

    function releaseTokens() public onlyWhenUnlocked {
        require(msg.sender == owner || msg.sender == beneficiary);
        require(tokenContract.transfer(beneficiary, balanceOf())); 
        emit ReleasedTokens(beneficiary);
    }
}

contract Crowdsale is Ownable {
    using SafeMath for uint;

     

    event Bought(address indexed account, uint etherAmount);
    event SaleNoted(address indexed account, uint etherAmount, uint tokenAmount);
    event SaleLockedNoted(address indexed account, uint etherAmount, uint tokenAmount, uint lockingPeriod, address lockingContract);

     

    Minter public minter;
    DeferredKyc public deferredKyc;

     

    modifier onlyValidAddress(address account) {
        require(account != 0x0);
        _;
    }

     

    function updateTreasury(address newTreasury) external onlyOwner onlyValidAddress(newTreasury) {
        deferredKyc.updateTreasury(newTreasury);
    }

    constructor(Minter _minter, address _approver, address _treasury)
        public
        onlyValidAddress(address(_minter))
        onlyValidAddress(_approver)
        onlyValidAddress(_treasury)
    {
        minter = _minter;
        deferredKyc = new DeferredKyc(_minter, _approver, _treasury);
    }

     
    
    function buy() public payable {
        deferredKyc.addToKyc.value(msg.value)(msg.sender);
        emit Bought(msg.sender, msg.value);
    }

    function noteSale(address account, uint etherAmount, uint tokenAmount) public onlyOwner {
        minter.mint(account, etherAmount, tokenAmount);
        emit SaleNoted(account, etherAmount, tokenAmount);
    }

    function noteSaleLocked(address account, uint etherAmount, uint tokenAmount, uint lockingPeriod) public onlyOwner {
        SingleLockingContract lockingContract = new SingleLockingContract(ERC20(minter.token()), now.add(lockingPeriod), account);
        minter.mint(address(lockingContract), etherAmount, tokenAmount);
        emit SaleLockedNoted(account, etherAmount, tokenAmount, lockingPeriod, address(lockingContract));
    }

    function() public payable {
        buy();
    }
}