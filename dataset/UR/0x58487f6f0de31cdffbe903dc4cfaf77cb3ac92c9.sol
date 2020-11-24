 

 

pragma solidity 0.4.24;

 
contract Ownable {
    address private owner_;
    event OwnershipRenounced(address indexed previousOwner);
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

     
    constructor() public {
        owner_ = msg.sender;
    }

     
    function owner() public view returns(address) {
        return owner_;
    }

     
    modifier onlyOwner() {
        require(msg.sender == owner_, "Only the owner can call this function.");
        _;
    }

     
    function renounceOwnership() public onlyOwner {
        emit OwnershipRenounced(owner_);
        owner_ = address(0);
    }

     
    function transferOwnership(address _newOwner) public onlyOwner {
        _transferOwnership(_newOwner);
    }

     
    function _transferOwnership(address _newOwner) internal {
        require(_newOwner != address(0), "Cannot transfer ownership to zero address.");
        emit OwnershipTransferred(owner_, _newOwner);
        owner_ = _newOwner;
    }
}

 
library SafeMath {

     
    function mul(uint256 _a, uint256 _b) internal pure returns (uint256 c) {
         
         
         
        if (_a == 0) {
            return 0;
        }

        c = _a * _b;
        assert(c / _a == _b);
        return c;
    }

     
    function div(uint256 _a, uint256 _b) internal pure returns (uint256) {
         
         
         
        return _a / _b;
    }

     
    function sub(uint256 _a, uint256 _b) internal pure returns (uint256) {
        assert(_b <= _a);
        return _a - _b;
    }

     
    function add(uint256 _a, uint256 _b) internal pure returns (uint256 c) {
        c = _a + _b;
        assert(c >= _a);
        return c;
    }
}

contract LivenSale is Ownable {

    using SafeMath for uint256;

    uint256 public maximumContribution = 1000 ether;
    uint256 public minimumContribution = 100 finney;
    uint256 public totalWeiRaised;
    uint256 public endTimestamp;
    uint256 public constant SIX_WEEKS_IN_SECONDS = 86400 * 7 * 6;

    bool public saleEnded = false;
    address public proceedsAddress;

    mapping (address => uint256) public weiContributed;

    constructor (address _proceedsAddress) public {
        proceedsAddress = _proceedsAddress;
        endTimestamp = block.timestamp + SIX_WEEKS_IN_SECONDS;
    }

    function () public payable {
        buyTokens();
    }

    function buyTokens () public payable {
        require(!saleEnded && block.timestamp < endTimestamp, "Campaign has ended. No more contributions possible.");
        require(msg.value >= minimumContribution, "No contributions below 0.1 ETH.");
        require(weiContributed[msg.sender] < maximumContribution, "Contribution cap already reached.");

        uint purchaseAmount = msg.value;
        uint weiToReturn;
        
         
        uint remainingContributorAllowance = maximumContribution.sub(weiContributed[msg.sender]);
        if (remainingContributorAllowance < purchaseAmount) {
            purchaseAmount = remainingContributorAllowance;
            weiToReturn = msg.value.sub(purchaseAmount);
        }

         
        weiContributed[msg.sender] = weiContributed[msg.sender].add(purchaseAmount);
        totalWeiRaised = totalWeiRaised.add(purchaseAmount);

         
        proceedsAddress.transfer(purchaseAmount);

         
        if (weiToReturn > 0) {
            address(msg.sender).transfer(weiToReturn);
        }
    }

    function extendSale (uint256 _seconds) public onlyOwner {
        endTimestamp += _seconds;
    }

    function endSale () public onlyOwner {
        saleEnded = true;
    }
}