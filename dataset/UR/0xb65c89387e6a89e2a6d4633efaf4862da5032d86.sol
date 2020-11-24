 

pragma solidity ^0.4.23;

 
library SafeMath {

     
    function mul(uint256 a, uint256 b) internal pure returns (uint256 c) {
        if (a == 0) {
            return 0;
        }
        c = a * b;
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

     
    function add(uint256 a, uint256 b) internal pure returns (uint256 c) {
        c = a + b;
        assert(c >= a);
        return c;
    }
}

 
contract ERC20Basic {
    function totalSupply() public view returns (uint256);
    function balanceOf(address who) public view returns (uint256);
    function transfer(address to, uint256 value) public returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
}

 
contract Ownable {
    address public owner;


    event OwnershipRenounced(address indexed previousOwner);
    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );


     
    constructor() public {
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

     
    function renounceOwnership() public onlyOwner {
        emit OwnershipRenounced(owner);
        owner = address(0);
    }
}

 
contract ERC20 is ERC20Basic {
    function allowance(address owner, address spender)
    public view returns (uint256);

    function transferFrom(address from, address to, uint256 value)
    public returns (bool);

    function approve(address spender, uint256 value) public returns (bool);
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
}

 
contract Crowdsale {
    using SafeMath for uint256;

     
    ERC20 public token;

     
    address public wallet;

     
    uint256 public rate;

     
    uint256 public weiRaised;

     
    event TokenPurchase(
        address indexed purchaser,
        address indexed beneficiary,
        uint256 value,
        uint256 amount
    );

     
    constructor(uint256 _rate, address _wallet, ERC20 _token) public {
        require(_rate > 0);
        require(_wallet != address(0));
        require(_token != address(0));

        rate = _rate;
        wallet = _wallet;
        token = _token;
    }

     
     
     

     
    function () external payable {
        buyTokens(msg.sender);
    }

     
    function buyTokens(address _beneficiary) public payable {

        uint256 weiAmount = msg.value;
        _preValidatePurchase(_beneficiary, weiAmount);

         
        uint256 tokens = _getTokenAmount(weiAmount);

         
        weiRaised = weiRaised.add(weiAmount);

        _processPurchase(_beneficiary, tokens);
        emit TokenPurchase(
            msg.sender,
            _beneficiary,
            weiAmount,
            tokens
        );

        _forwardFunds();
    }

     
     
     

     
    function _preValidatePurchase(
        address _beneficiary,
        uint256 _weiAmount
    )
    internal view
    {
        require(_beneficiary != address(0));
        require(_weiAmount != 0);
        require(weiRaised.add(_weiAmount) != 0);
    }

     
    function _allocateTokens(
        address _beneficiary,
        uint256 _tokenAmount
    )
    internal
    {
        token.transfer(_beneficiary, _tokenAmount);
    }

     
    function _processPurchase(
        address _beneficiary,
        uint256 _tokenAmount
    )
    internal
    {
        _allocateTokens(_beneficiary, _tokenAmount);
    }

     
    function _getTokenAmount(uint256 _weiAmount)
    internal view returns (uint256)
    {
        return _weiAmount.mul(rate);
    }

     
    function _forwardFunds() internal {
        wallet.transfer(msg.value);
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
        emit Transfer(msg.sender, _to, _value);
        return true;
    }

     
    function balanceOf(address _owner) public view returns (uint256) {
        return balances[_owner];
    }

}

 
contract StandardToken is ERC20, BasicToken {

    mapping (address => mapping (address => uint256)) internal allowed;


     
    function transferFrom(
        address _from,
        address _to,
        uint256 _value
    )
    public
    returns (bool)
    {
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

     
    function allowance(
        address _owner,
        address _spender
    )
    public
    view
    returns (uint256)
    {
        return allowed[_owner][_spender];
    }

     
    function increaseApproval(
        address _spender,
        uint _addedValue
    )
    public
    returns (bool)
    {
        allowed[msg.sender][_spender] = (
        allowed[msg.sender][_spender].add(_addedValue));
        emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
        return true;
    }

     
    function decreaseApproval(
        address _spender,
        uint _subtractedValue
    )
    public
    returns (bool)
    {
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

 
contract MintableToken is StandardToken, Ownable {
    event Mint(address indexed to, uint256 amount);
    event MintFinished();

    bool public mintingFinished = false;


    modifier canMint() {
        require(!mintingFinished);
        _;
    }

    modifier hasMintPermission() {
        require(msg.sender == owner);
        _;
    }

     
    function mint(
        address _to,
        uint256 _amount
    )
    hasMintPermission
    canMint
    public
    returns (bool)
    {
        totalSupply_ = totalSupply_.add(_amount);
        balances[_to] = balances[_to].add(_amount);
        emit Mint(_to, _amount);
        emit Transfer(address(0), _to, _amount);
        return true;
    }

     
    function finishMinting() onlyOwner canMint external returns (bool) {
        mintingFinished = true;
        emit MintFinished();
        return true;
    }
}

 
contract CappedCrowdsale is Crowdsale {
    using SafeMath for uint256;

    uint256 public cap;

     
    constructor(uint256 _cap) public {
        require(_cap > 0);
        cap = _cap;
    }

     
    function capReached() external view returns (bool) {
        return weiRaised >= cap;
    }

     
    function _preValidatePurchase(
        address _beneficiary,
        uint256 _weiAmount
    )
    internal view
    {
        super._preValidatePurchase(_beneficiary, _weiAmount);
        require(weiRaised.add(_weiAmount) <= cap);
    }

}

 
contract IndividuallyCappedCrowdsale is Crowdsale, CappedCrowdsale {
    using SafeMath for uint256;

    mapping(address => uint256) public contributions;
    uint256 public individualCap;
    uint256 public miniumInvestment;

     
    constructor(uint256 _individualCap, uint256 _miniumInvestment) public {
        require(_individualCap > 0);
        require(_miniumInvestment > 0);
        individualCap = _individualCap;
        miniumInvestment = _miniumInvestment;
    }


     
    function _preValidatePurchase(address _beneficiary, uint256 _weiAmount) internal view {
        super._preValidatePurchase(_beneficiary, _weiAmount);
        require(_weiAmount <= individualCap);
        require(_weiAmount >= miniumInvestment);
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

     
    function pause() onlyOwner whenNotPaused external {
        paused = true;
        emit Pause();
    }

     
    function unpause() onlyOwner whenPaused external {
        paused = false;
        emit Unpause();
    }
}


contract Namahecrowdsale is Pausable, IndividuallyCappedCrowdsale {

    using SafeMath for uint256;

    uint256 public openingTime;
    uint256 public closingTime;
    bool public isFinalized = false;

    bool public quarterFirst = true;
    bool public quarterSecond = true;
    bool public quarterThird = true;
    bool public quarterFourth = true;

    uint256 public rate = 1000;
    bool public preAllocationsPending = true;          
    uint256 public totalAllocated = 0;
    mapping(address => uint256) public allocated;      
    address[] public allocatedAddresses;               

    address public constant _controller  = 0x6E21c63511b0dD8f2C67BB5230C5b831f6cd7986;
    address public constant _reserve     = 0xE4627eE46f9E0071571614ca86441AFb42972A66;
    address public constant _promo       = 0x894387C61144f1F3a2422D17E61638B3263286Ee;
    address public constant _holding     = 0xC7592b24b4108b387A9F413fa4eA2506a7F32Ae9;

    address public constant _founder_one = 0x3f7dB633ABAb31A687dd1DFa0876Df12Bfc18DBE;
    address public constant _founder_two = 0xCDb0EF350717d743d47A358EADE1DF2CB71c1E4F;

    uint256 public constant PROMO_TOKEN_AMOUNT   = 6000000E18;  
    uint256 public constant RESERVE_TOKEN_AMOUNT = 24000000E18;  
    uint256 public constant TEAM_TOKEN_AMOUNT    = 15000000E18;  

    uint256 public constant QUARTERLY_RELEASE    = 3750000E18;  

    MintableToken public token;

    event AllocationApproved(address indexed purchaser, uint256 amount);
    event Finalized();

    constructor (
        uint256 _openingTime,
        uint256 _closingTime,
        uint256 _cap,
        uint256 _miniumInvestment,
        uint256 _individualCap,
        MintableToken _token
    )

    public
    Crowdsale(rate, _controller, _token)
    CappedCrowdsale(_cap)
    IndividuallyCappedCrowdsale(_individualCap, _miniumInvestment)
    {
        openingTime = _openingTime;
        closingTime = _closingTime;
        token = _token;

    }

     
    modifier onlyWhileOpen {
        require(block.timestamp >= openingTime && block.timestamp <= closingTime);
        _;
    }

     
    function doPreAllocations() external onlyOwner returns (bool) {
        require(preAllocationsPending);

         
        token.transfer(_promo, PROMO_TOKEN_AMOUNT);

         
         
        _allocateTokens(_founder_one, TEAM_TOKEN_AMOUNT);
        _allocateTokens(_founder_two, TEAM_TOKEN_AMOUNT);

         
        _allocateTokens(_reserve, RESERVE_TOKEN_AMOUNT);

        totalAllocated = totalAllocated.add(PROMO_TOKEN_AMOUNT);
        preAllocationsPending = false;
        return true;
    }

     
    function approveAllocation(address _beneficiary) external onlyOwner returns (bool) {
        require(_beneficiary != address(0));
        require(_beneficiary != _founder_one);
        require(_beneficiary != _founder_two);
        require(_beneficiary != _reserve);

        uint256 allocatedTokens = allocated[_beneficiary];
        token.transfer(_beneficiary, allocated[_beneficiary]);
        allocated[_beneficiary] = 0;
        emit AllocationApproved(_beneficiary, allocatedTokens);

        return true;
    }

     
    function releaseReservedTokens() external onlyOwner {
        require(block.timestamp > (openingTime.add(52 weeks)));
        require(allocated[_reserve] > 0);

        token.transfer(_reserve, RESERVE_TOKEN_AMOUNT);
        allocated[_reserve] = 0;
    }

     
    function finalize() external onlyOwner {
        require(!isFinalized);
        require(hasClosed());
        require(!preAllocationsPending);

        finalization();
        emit Finalized();

        isFinalized = true;
    }

     
    function extendCrowdsale(uint256 _closingTime) external onlyOwner {
        require(_closingTime > closingTime);
        require(block.timestamp <= openingTime.add(36 weeks));

        closingTime = _closingTime;
    }

     
    function releaseFounderTokens() external onlyOwner returns (bool) {
        if (quarterFirst && block.timestamp >= (openingTime.add(10 weeks))) {
            quarterFirst = false;
            token.transfer(_founder_one, QUARTERLY_RELEASE);
            token.transfer(_founder_two, QUARTERLY_RELEASE);
            allocated[_founder_one] = allocated[_founder_one].sub(QUARTERLY_RELEASE);
            allocated[_founder_two] = allocated[_founder_two].sub(QUARTERLY_RELEASE);
            totalAllocated = totalAllocated.sub(QUARTERLY_RELEASE);
            totalAllocated = totalAllocated.sub(QUARTERLY_RELEASE);

        }

        if (quarterSecond && block.timestamp >= (openingTime.add(22 weeks))) {
            quarterSecond = false;
            token.transfer(_founder_one, QUARTERLY_RELEASE);
            token.transfer(_founder_two, QUARTERLY_RELEASE);
            allocated[_founder_one] = allocated[_founder_one].sub(QUARTERLY_RELEASE);
            allocated[_founder_two] = allocated[_founder_two].sub(QUARTERLY_RELEASE);
            totalAllocated = totalAllocated.sub(QUARTERLY_RELEASE);
            totalAllocated = totalAllocated.sub(QUARTERLY_RELEASE);
        }

        if (quarterThird && block.timestamp >= (openingTime.add(34 weeks))) {
            quarterThird = false;
            token.transfer(_founder_one, QUARTERLY_RELEASE);
            token.transfer(_founder_two, QUARTERLY_RELEASE);
            allocated[_founder_one] = allocated[_founder_one].sub(QUARTERLY_RELEASE);
            allocated[_founder_two] = allocated[_founder_two].sub(QUARTERLY_RELEASE);
            totalAllocated = totalAllocated.sub(QUARTERLY_RELEASE);
            totalAllocated = totalAllocated.sub(QUARTERLY_RELEASE);
        }

        if (quarterFourth && block.timestamp >= (openingTime.add(46 weeks))) {
            quarterFourth = false;
            token.transfer(_founder_one, QUARTERLY_RELEASE);
            token.transfer(_founder_two, QUARTERLY_RELEASE);
            allocated[_founder_one] = allocated[_founder_one].sub(QUARTERLY_RELEASE);
            allocated[_founder_two] = allocated[_founder_two].sub(QUARTERLY_RELEASE);
            totalAllocated = totalAllocated.sub(QUARTERLY_RELEASE);
            totalAllocated = totalAllocated.sub(QUARTERLY_RELEASE);
        }

        return true;
    }

     
    function hasClosed() public view returns (bool) {
        return block.timestamp > closingTime;
    }

     
    function getRate() public view returns (uint256) {

        if (block.timestamp <= (openingTime.add(14 days))) {return rate.add(200);}
        if (block.timestamp <= (openingTime.add(28 days))) {return rate.add(100);}
        if (block.timestamp <= (openingTime.add(49 days))) {return rate.add(50);}

        return rate;
    }

     
    function reclaimAllocated() internal {

        uint256 unapprovedTokens = 0;
        for (uint256 i = 0; i < allocatedAddresses.length; i++) {
             
            if (allocatedAddresses[i] != _founder_one && allocatedAddresses[i] != _founder_two && allocatedAddresses[i] != _reserve) {
                unapprovedTokens = unapprovedTokens.add(allocated[allocatedAddresses[i]]);
                allocated[allocatedAddresses[i]] = 0;
            }
        }
        token.transfer(_holding, unapprovedTokens);
    }

     
    function reclaimBalanceTokens() internal {

        uint256 balanceTokens = token.balanceOf(this);
        balanceTokens = balanceTokens.sub(allocated[_founder_one]);
        balanceTokens = balanceTokens.sub(allocated[_founder_two]);
        balanceTokens = balanceTokens.sub(allocated[_reserve]);
        token.transfer(_controller, balanceTokens);
    }

     
    function finalization() internal {
        reclaimAllocated();
        reclaimBalanceTokens();
    }

     
    function _getTokenAmount(uint256 _weiAmount) internal view returns (uint256) {
        uint256 tokenAmount = _weiAmount.mul(getRate());
        return tokenAmount;
    }

     
    function _preValidatePurchase(address _beneficiary, uint256 _weiAmount) internal view onlyWhileOpen whenNotPaused {
        super._preValidatePurchase(_beneficiary, _weiAmount);
    }

     
    function _allocateTokens(address _beneficiary, uint256 _tokenAmount) internal {
         
        require(token.balanceOf(this) >= totalAllocated.add(_tokenAmount));
        allocated[_beneficiary] = allocated[_beneficiary].add(_tokenAmount);
        totalAllocated = totalAllocated.add(_tokenAmount);
        allocatedAddresses.push(_beneficiary);

    }
}