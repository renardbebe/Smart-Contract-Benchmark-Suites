 

pragma solidity 0.4.24;


 
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


 
contract Ownable {
    address public owner;
    address public pendingOwner;
    bool isOwnershipTransferActive = false;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

     
    constructor() public {
        owner = msg.sender;
    }

     
    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can do that.");
        _;
    }

     
    modifier onlyPendingOwner() {
        require(isOwnershipTransferActive);
        require(msg.sender == pendingOwner, "Only nominated pretender can do that.");
        _;
    }

     
    function transferOwnership(address _newOwner) public onlyOwner {
        pendingOwner = _newOwner;
        isOwnershipTransferActive = true;
    }

     
    function acceptOwnership() public onlyPendingOwner {
        emit OwnershipTransferred(owner, pendingOwner);
        owner = pendingOwner;
        isOwnershipTransferActive = false;
        pendingOwner = address(0);
    }
}


 
contract ERC20 {
    function totalSupply() public view returns (uint256);
    function balanceOf(address _owner) public view returns (uint256);
    function transfer(address _to, uint256 _value) public returns (bool);

    function transferFrom(address _from, address _to, uint256 _value) public returns (bool);
    function approve(address _spender, uint256 _value) public returns (bool);
    function allowance(address _owner, address _spender) public view returns (uint256);

    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
}


 
contract AurumPresale is Ownable {
    using SafeMath for uint256;

     
    uint256 public constant RATE = 7500;

     
    uint256 public constant CAP = 1000 ether;

     
    ERC20 public token;

     
    uint256 public openingTime;

     
    uint256 public closingTime;

     
    uint256 public totalWeiRaised;

     
    address controller;
    bool isControllerSpecified = false;

     
    event TokenPurchase(
        address indexed purchaser,
        address indexed beneficiary,
        uint256 value,
        uint256 amount
    );

    constructor(ERC20 _token, uint256 _openingTime, uint256 _closingTime) public {
        require(_token != address(0));
        require(_openingTime >= now);
        require(_closingTime > _openingTime);

        token = _token;
        openingTime = _openingTime;
        closingTime = _closingTime;

        require(token.balanceOf(msg.sender) >= RATE.mul(CAP));
    }


    modifier onlyWhileActive() {
        require(isActive(), "Presale has closed.");
        _;
    }

     
    modifier minThreshold(uint256 _amount) {
        require(msg.value >= _amount, "Not enough Ether provided.");
        _;
    }

    modifier onlyController() {
        require(isControllerSpecified);
        require(msg.sender == controller, "Only controller can do that.");
        _;
    }

     
    function () external payable {
        buyTokens(msg.sender);
    }

     
    function reclaimToken(ERC20 _token) external onlyOwner {
        require(!isActive());
        uint256 tokenBalance = _token.balanceOf(this);
        require(_token.transfer(owner, tokenBalance));
    }

     
    function reclaimEther() external onlyOwner {
        owner.transfer(address(this).balance);
    }

     
    function specifyController(address _controller) external onlyOwner {
        controller = _controller;
        isControllerSpecified = true;
    }

     
    function markFunding(address _beneficiary, uint256 _weiRaised)
        external
        onlyController
        onlyWhileActive
    {
        require(_beneficiary != address(0));
        require(_weiRaised >= 20 finney);

        enroll(controller, _beneficiary, _weiRaised);
    }

     
    function isActive() public view returns (bool) {
        return now >= openingTime && now <= closingTime && !capReached();
    }

     
    function buyTokens(address _beneficiary)
        public
        payable
        onlyWhileActive
        minThreshold(20 finney)
    {
        require(_beneficiary != address(0));

        uint256 newWeiRaised = msg.value;
        uint256 newTotalWeiRaised = totalWeiRaised.add(newWeiRaised);

        uint256 refundValue = 0;
        if (newTotalWeiRaised > CAP) {
            newWeiRaised = CAP.sub(totalWeiRaised);
            refundValue = newTotalWeiRaised.sub(CAP);
        }

        enroll(msg.sender, _beneficiary, newWeiRaised);

        if (refundValue > 0) {
            msg.sender.transfer(refundValue);
        }
    }

     
    function capReached() internal view returns (bool) {
        return totalWeiRaised >= CAP;
    }

     
    function getTokenAmount(uint256 _weiAmount) internal pure returns (uint256) {
        return _weiAmount.mul(RATE);
    }

     
    function enroll(address _purchaser, address _beneficiary, uint256 _value) private {
         
        totalWeiRaised = totalWeiRaised.add(_value);

         
        uint256 tokenAmount = getTokenAmount(_value);

        require(token.transfer(_beneficiary, tokenAmount));
        emit TokenPurchase(_purchaser, _beneficiary, _value, tokenAmount);
    }

}