 

 

pragma solidity ^0.5.2;

 
contract Ownable {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

     
    constructor () internal {
        _owner = msg.sender;
        emit OwnershipTransferred(address(0), _owner);
    }

     
    function owner() public view returns (address) {
        return _owner;
    }

     
    modifier onlyOwner() {
        require(isOwner());
        _;
    }

     
    function isOwner() public view returns (bool) {
        return msg.sender == _owner;
    }

     
    function renounceOwnership() public onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

     
    function transferOwnership(address newOwner) public onlyOwner {
        _transferOwnership(newOwner);
    }

     
    function _transferOwnership(address newOwner) internal {
        require(newOwner != address(0));
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

 

pragma solidity ^0.5.2;

 
library SafeMath {
     
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
         
         
         
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b);

        return c;
    }

     
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
         
        require(b > 0);
        uint256 c = a / b;
         

        return c;
    }

     
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a);
        uint256 c = a - b;

        return c;
    }

     
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a);

        return c;
    }

     
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b != 0);
        return a % b;
    }
}

 

pragma solidity ^0.5.2;



contract DollarAuction is Ownable {
    using SafeMath for uint256;

    uint256 constant bidFee = 1e15;
    uint256 constant minimumBidDelta = 1e15;
    uint256 constant sixHours = 6 * 60 * 60;
    uint256 constant twentyFourHours = sixHours * 4;
    uint256 constant tenthEth = 1e17;
    uint256 public expiryTime;
    uint256 public prize;
    address payable public lastDonor;
    address payable public winningBidder;
    address payable public losingBidder;
    uint256 public winningBid;
    uint256 public losingBid;

    constructor() public payable {
        reset();
    }

    modifier onlyActiveAuction() {
        require(isActiveAuction(), "Auction not active");
        _;
    }

    modifier onlyInactiveAuction() {
        require(!isActiveAuction(), "Auction not expired");
        _;
    }

    function increasePrize() public payable onlyActiveAuction {
        require(msg.value >= tenthEth, "Must increase by at least 0.1ETH");

        prize = prize.add(msg.value);
        lastDonor = msg.sender;
    }

    function bid() public payable onlyActiveAuction {
        uint bidAmount = msg.value.sub(bidFee);

        require(bidAmount > winningBid.add(minimumBidDelta), "Bid too small");

        repayThirdPlace();
        updateLosingBidder();
        updateWinningBidder(bidAmount, msg.sender);

        if(expiryTime < block.timestamp + sixHours){
            expiryTime = block.timestamp + sixHours;
        }
    }

    function withdrawPrize() public onlyInactiveAuction {
        require(msg.sender == winningBidder || isOwner(), "not authorized");

        winningBidder.transfer(prize);
        address payable o = address(uint160(owner()));
        uint256 bids = winningBid.add(losingBid);
        lastDonor.transfer(bids);
        o.transfer(address(this).balance);

        prize = 0;
    }

    function restart() public payable onlyOwner onlyInactiveAuction {
        reset();
    }

    function collectedFees() public view onlyOwner returns (uint) {
        return address(this).balance.sub(prize).sub(winningBid).sub(losingBid);
    }

    function reset() internal onlyOwner {
        expiryTime = block.timestamp + 2*twentyFourHours;
        prize = msg.value;
        lastDonor = msg.sender;
        winningBidder = msg.sender;
        losingBidder = msg.sender;
        winningBid = 0;
        losingBid = 0;
    }

    function updateWinningBidder(uint256 _bid, address payable _bidder) internal {
        winningBid = _bid;
        winningBidder = _bidder;
    }

    function updateLosingBidder() internal {
        losingBidder = winningBidder;
        losingBid = winningBid;
    }

    function repayThirdPlace() internal {
        losingBidder.transfer(losingBid);
    }

    function isActiveAuction() public view returns(bool) {
        return block.timestamp < expiryTime;
    }

     
    function() external payable {
        bid();
    }
}