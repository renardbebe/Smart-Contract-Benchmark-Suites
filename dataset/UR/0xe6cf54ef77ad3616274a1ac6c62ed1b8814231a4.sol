 

pragma solidity ^0.4.23;

 
contract ERC20Basic {
    function totalSupply() public view returns (uint256);
    function balanceOf(address who) public view returns (uint256);
    function transfer(address to, uint256 value) public returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
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

        rate   = _rate;
        wallet = _wallet;
        token  = _token;
        
        
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

        _updatePurchasingState(_beneficiary, weiAmount);

        _forwardFunds();
        _postValidatePurchase(_beneficiary, weiAmount);
    }

     
     
     

     
    function _preValidatePurchase (
        address _beneficiary,
        uint256 _weiAmount
    )
    internal
    {
        require(_beneficiary != address(0));
        require(_weiAmount != 0);
    }

     
    function _postValidatePurchase (
        address _beneficiary,
        uint256 _weiAmount
    )
    internal
    {
         
    }

     
    function _deliverTokens (
        address _beneficiary,
        uint256 _tokenAmount
    )
    internal
    {
        token.transfer(_beneficiary, _tokenAmount);
    }

     
    function _processPurchase (
        address _beneficiary,
        uint256 _tokenAmount
    )
    internal
    {
        _deliverTokens(_beneficiary, _tokenAmount);
    }

     
    function _updatePurchasingState (
        address _beneficiary,
        uint256 _weiAmount
    )
    internal
    {
         
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

 
contract CappedCrowdsale is Crowdsale {
    using SafeMath for uint256;

    uint256 public cap;

     
    constructor(uint256 _cap) public {
        require(_cap > 0);
        cap = _cap;
    }

     
    function capReached() public view returns (bool) {
        return weiRaised >= cap;
    }

     
    function _preValidatePurchase(
        address _beneficiary,
        uint256 _weiAmount
    )
    internal
    {
        super._preValidatePurchase(_beneficiary, _weiAmount);
        require(weiRaised.add(_weiAmount) <= cap);
    }
}

 
contract TimedCrowdsale is Crowdsale {
    using SafeMath for uint256;

    uint256 public openingTime;
    uint256 public closingTime;

     
    modifier onlyWhileOpen {
         
        require(block.timestamp >= openingTime && block.timestamp <= closingTime);
        _;
    }

     
    constructor(uint256 _openingTime, uint256 _closingTime) public {
         
        require(_openingTime >= block.timestamp);
        require(_closingTime >= _openingTime);

        openingTime = _openingTime;
        closingTime = _closingTime;
    }

     
    function hasClosed() public view returns (bool) {
         
        return block.timestamp > closingTime;
    }

     
    function _preValidatePurchase(address _beneficiary, uint256 _weiAmount) internal onlyWhileOpen {
        super._preValidatePurchase(_beneficiary, _weiAmount);
    }
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

 
contract FinalizableCrowdsale is TimedCrowdsale, Ownable {
    using SafeMath for uint256;

    bool public isFinalized = false;

    event Finalized();

     
    function finalize() onlyOwner public {
        require(!isFinalized);
        require(hasClosed());

        finalization();
        emit Finalized();

        isFinalized = true;
    }

     
    function finalization() internal {}
}

 
contract RefundVault is Ownable {
    using SafeMath for uint256;

    enum State { Active, Refunding, Closed }

    mapping (address => uint256) public deposited;
    address public wallet;
    State public state;

    event Closed();
    event RefundsEnabled();
    event Refunded(address indexed beneficiary, uint256 weiAmount);

     
    constructor(address _wallet) public {
        require(_wallet != address(0));
        wallet = _wallet;
        state = State.Active;
    }

     
    function deposit(address investor) onlyOwner public payable {
        require(state == State.Active);
        deposited[investor] = deposited[investor].add(msg.value);
    }

    function close() onlyOwner public {
        require(state == State.Active);
        state = State.Closed;
        emit Closed();
        wallet.transfer(address(this).balance);
    }

    function enableRefunds() onlyOwner public {
        require(state == State.Active);
        state = State.Refunding;
        emit RefundsEnabled();
    }

     
    function refund(address investor) public {
        require(state == State.Refunding);
        uint256 depositedValue = deposited[investor];
        deposited[investor] = 0;
        investor.transfer(depositedValue);
        emit Refunded(investor, depositedValue);
    }
}

 
contract RefundableCrowdsale is FinalizableCrowdsale {
    using SafeMath for uint256;

     
    uint256 public goal;

     
    RefundVault public vault;

     
    constructor(uint256 _goal) public {
        require(_goal > 0);
        vault = new RefundVault(wallet);
        goal  = _goal;
    }

     
    function claimRefund() public {
        require(isFinalized);
        require(!goalReached());

        vault.refund(msg.sender);
    }

     
    function goalReached() public view returns (bool) {
        return weiRaised >= goal;
    }

     
    function finalization() internal {
        if (goalReached()) {
            vault.close();
        } else {
            vault.enableRefunds();
        }

        super.finalization();
    }

     
    function _forwardFunds() internal {
        vault.deposit.value(msg.value)(msg.sender);
    }
}

 
library SafeERC20 {
    function safeTransfer(ERC20Basic token, address to, uint256 value) internal {
        require(token.transfer(to, value));
    }

    function safeTransferFrom(
        ERC20 token,
        address from,
        address to,
        uint256 value
    )
    internal
    {
        require(token.transferFrom(from, to, value));
    }

    function safeApprove(ERC20 token, address spender, uint256 value) internal {
        require(token.approve(spender, value));
    }
}

 
contract AllowanceCrowdsale is Crowdsale {
    using SafeMath for uint256;
    using SafeERC20 for ERC20;

    address public tokenWallet;

     
    constructor(address _tokenWallet) public {
        require(_tokenWallet != address(0));
        tokenWallet = _tokenWallet;
    }

     
    function remainingTokens() public view returns (uint256) {
        return token.allowance(tokenWallet, this);
    }

     
    function _deliverTokens(address _beneficiary, uint256 _tokenAmount) internal {
        token.safeTransferFrom(tokenWallet, _beneficiary, _tokenAmount);
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

 
contract BurnableToken is BasicToken {

    event Burn(address indexed burner, uint256 value);

     
    function burn(uint256 _value) public {
        _burn(msg.sender, _value);
    }

    function _burn(address _who, uint256 _value) internal {
        require(_value <= balances[_who]);
         
         

        balances[_who] = balances[_who].sub(_value);
        totalSupply_ = totalSupply_.sub(_value);
        emit Burn(_who, _value);
        emit Transfer(_who, address(0), _value);
    }
}

 
contract StandardToken is ERC20, BasicToken, Ownable {

    mapping (address => mapping (address => uint256)) internal allowed;


     
    function transferFrom (
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

     
    function approve(address _spender, uint256 _value) public onlyOwner returns (bool) {
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

 
contract StandardBurnableToken is BurnableToken, StandardToken {

     
    function burnFrom(address _from, uint256 _value) public onlyOwner {
        require(_value <= allowed[_from][msg.sender]);
         
         
        allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
        _burn(_from, _value);
    }
}

 
 
 
 
 
 
contract MoleculeCrowdsale is CappedCrowdsale, RefundableCrowdsale, AllowanceCrowdsale {

    mapping(address => bool) public whitelist;
    
     
    mapping (address => uint256) public referrers;
    
    uint internal constant REFERRER_PERCENT = 8;

     
    modifier isWhitelisted(address _beneficiary) {
        require(whitelist[_beneficiary]);
        _;
    }
    
    modifier whenNotPaused() {
        require((block.timestamp > openingTime && block.timestamp < openingTime + (5 weeks)) || (block.timestamp > openingTime + (7 weeks) && block.timestamp < closingTime));
        _;
    }
    
    constructor(
        uint256 _openingTime,
        uint256 _closingTime,
        uint256 _rate,
        address _wallet,
        uint256 _cap,
        StandardBurnableToken _token,
        uint256 _goal
    )
    public
    Crowdsale(_rate, _wallet, _token)
    CappedCrowdsale(_cap)
    TimedCrowdsale(_openingTime, _closingTime)
    RefundableCrowdsale(_goal)
    AllowanceCrowdsale(_wallet)
    {
         
         
        require(_goal <= _cap);
        require(_rate > 0);
    }

     
    function addToWhitelist(address _beneficiary) external onlyOwner {
        whitelist[_beneficiary] = true;
    }

     
    function addManyToWhitelist(address[] _beneficiaries) external onlyOwner {
        for (uint256 i = 0; i < _beneficiaries.length; i++) {
            whitelist[_beneficiaries[i]] = true;
        }
    }

     
    function removeFromWhitelist(address _beneficiary) external onlyOwner {
        whitelist[_beneficiary] = false;
    }
    
    
    function bytesToAddres(bytes source) internal pure returns(address) {
        uint result;
        uint mul = 1;
        for(uint i = 20; i > 0; i--) {
            result += uint8(source[i-1])*mul;
            mul = mul*256;
        }
        return address(result);
    }
    

     
    function _preValidatePurchase(
        address _beneficiary,
        uint256 _weiAmount
    )
    internal
    whenNotPaused
    {
        super._preValidatePurchase(_beneficiary, _weiAmount);
        
        if(block.timestamp <= openingTime + (2 weeks)) {
            require(whitelist[_beneficiary]);
            require(msg.value >= 5 ether);
            rate = 833;
        }else if(block.timestamp > openingTime + (2 weeks) && block.timestamp <= openingTime + (3 weeks)) {
            require(msg.value >= 5 ether);
            rate = 722;
        }else if(block.timestamp > openingTime + (3 weeks) && block.timestamp <= openingTime + (4 weeks)) {
            require(msg.value >= 5 ether);
            rate = 666;
        }else if(block.timestamp > openingTime + (4 weeks) && block.timestamp <= openingTime + (5 weeks)) {
            require(msg.value >= 5 ether);
            rate = 611;
        }else{
            rate = 555;
        }
    }

    function referrerBonus(address _referrer) public view returns (uint256) {
        require(goalReached());
        return referrers[_referrer];
    }
    
     
    function _forwardFunds()
    internal
    {
         
        if(msg.data.length == 20) {
            address referrerAddress = bytesToAddres(bytes(msg.data));
            require(referrerAddress != address(token) && referrerAddress != msg.sender);
            uint256 referrerAmount = msg.value.mul(REFERRER_PERCENT).div(100);
            referrers[referrerAddress] = referrers[referrerAddress].add(referrerAmount);
        }
        
        if(block.timestamp <= openingTime + (2 weeks)) {
            wallet.transfer(msg.value);
        }else{
            vault.deposit.value(msg.value)(msg.sender);
        }
    }
}