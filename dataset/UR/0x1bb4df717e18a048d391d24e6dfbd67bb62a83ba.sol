 

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

        rate = _rate;
        wallet = _wallet;
        token = _token;
    }

     
     
     

     
    function() external payable {
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

        _processBonusStateSave(_beneficiary, weiAmount);

        _forwardFunds();
    }

     
     
     

     
    function _preValidatePurchase(
        address _beneficiary,
        uint256 _weiAmount
    )
    internal
    {
        require(_beneficiary != address(0));
        require(_weiAmount != 0);
    }

     
    function _deliverTokens(
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
        _deliverTokens(_beneficiary, _tokenAmount);
    }

     
    function _getTokenAmount(uint256 _weiAmount)
    internal view returns (uint256)
    {
        return _weiAmount.mul(rate);
    }

    function _processBonusStateSave(
        address _beneficiary,
        uint256 _weiAmount
    )
    internal
    {
    }

     
    function _forwardFunds() internal {
        wallet.transfer(msg.value);
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

     
    function _deliverTokens(
        address _beneficiary,
        uint256 _tokenAmount
    )
    internal
    {
        token.safeTransferFrom(tokenWallet, _beneficiary, _tokenAmount);
    }
}


 
contract TimedCrowdsale is Crowdsale {
    using SafeMath for uint256;

    uint256 public openingTime;

     
    modifier onlyWhileOpen {
         
        require(isOpen());
        _;
    }

     
    constructor(uint256 _openingTime) public {
         
        require(_openingTime >= block.timestamp);

        openingTime = _openingTime;
    }

     
    function isOpen() public view returns (bool) {
         
        return block.timestamp >= openingTime;
    }

     
    function _preValidatePurchase(
        address _beneficiary,
        uint256 _weiAmount
    )
    internal
    onlyWhileOpen
    {
        super._preValidatePurchase(_beneficiary, _weiAmount);
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

     
    function renounceOwnership() public onlyOwner {
        emit OwnershipRenounced(owner);
        owner = address(0);
    }

     
    function transferOwnership(address _newOwner) public onlyOwner {
        _transferOwnership(_newOwner);
    }

     
    function _transferOwnership(address _newOwner) internal {
        require(_newOwner != address(0));
        emit OwnershipTransferred(owner, _newOwner);
        owner = _newOwner;
    }
}


contract TecoIco is Crowdsale, AllowanceCrowdsale, TimedCrowdsale, CappedCrowdsale, Ownable {
    using SafeMath for uint256;

    uint256 public bonusPercent;

    mapping(address => uint256) bonuses;

    constructor(uint256 _rate, address _wallet, ERC20 _token, address _tokenWallet, uint256 _openingTime, uint256 _cap)
    Crowdsale(_rate, _wallet, _token)
    AllowanceCrowdsale(_tokenWallet)
    TimedCrowdsale(_openingTime)
    CappedCrowdsale(_cap)
    public
    {
        require(_rate > 0);
        require(_wallet != address(0));
        require(_token != address(0));

        rate = _rate;
        wallet = _wallet;
        token = _token;
    }

    function setRate(uint256 _rate)
    public
    onlyOwner
    {
        rate = _rate;
    }

    function setBonusPercent(uint256 _bonusPercent)
    public
    onlyOwner
    {
        bonusPercent = _bonusPercent;
    }

    function getBonusTokenAmount(uint256 _weiAmount)
    public
    view
    returns (uint256)
    {
        if (bonusPercent > 0) {
            return _weiAmount.mul(rate).mul(bonusPercent).div(100);
        }
        return 0;
    }

    function _getTokenAmount(uint256 _weiAmount)
    internal
    view
    returns (uint256)
    {
        if (bonusPercent > 0) {
            return _weiAmount.mul(rate).mul(100 + bonusPercent).div(100);
        }
        return _weiAmount.mul(rate);
    }

    function _processBonusStateSave(
        address _beneficiary,
        uint256 _weiAmount
    )
    internal
    {
        bonuses[_beneficiary] = bonuses[_beneficiary].add(getBonusTokenAmount(_weiAmount));
        super._processBonusStateSave(_beneficiary, _weiAmount);
    }

    function bonusOf(address _owner) public view returns (uint256) {
        return bonuses[_owner];
    }
}