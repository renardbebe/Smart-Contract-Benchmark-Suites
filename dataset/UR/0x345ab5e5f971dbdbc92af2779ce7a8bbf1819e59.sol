 

pragma solidity ^0.4.0;

contract TwentyDollars {
     

    struct Bid {
        address owner;
        uint256 amount;
    }

    address owner;
    uint256 public gameValue;
    uint256 public gameEndBlock;
    
    Bid public highestBid;
    Bid public secondHighestBid;
    mapping (address => uint256) public balances;

    
     

    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    modifier onlyBiddingOpen() {
        require(block.number < gameEndBlock);
        _;
    }

    modifier onlyBiddingClosed() {
        require(biddingClosed());
        _;
    }

    modifier onlyHighestBidder() {
        require(msg.sender == highestBid.owner);
        _;
    }
    
    
     
    
    constructor() public payable {
        owner = msg.sender;
        gameValue = msg.value;
        gameEndBlock = block.number + 40000;
    }


     

    function bid() public payable onlyBiddingOpen {
         
        require(msg.value > highestBid.amount);

         
        balances[secondHighestBid.owner] += secondHighestBid.amount;
        secondHighestBid = highestBid;
        highestBid.owner = msg.sender;
        highestBid.amount = msg.value;
        
         
        gameEndBlock += 10;
    }
    
    function withdraw() public {
        uint256 balance = balances[msg.sender];
        require(balance > 0);
        balances[msg.sender] = 0;
        msg.sender.transfer(balance);
    }

    function winnerWithdraw() public onlyBiddingClosed onlyHighestBidder {
        address highestBidder = highestBid.owner;
        require(highestBidder != address(0));
        delete highestBid.owner;
        highestBidder.transfer(gameValue);
    }

    function ownerWithdraw() public onlyOwner onlyBiddingClosed {
         
        uint256 winnerAllocation = (highestBid.owner == address(0)) ? 0 : gameValue;
        owner.transfer(getContractBalance() - winnerAllocation);
    }

    function getMyBalance() public view returns (uint256) {
        return balances[msg.sender];
    }
    
    function getContractBalance() public view returns (uint256) {
        return address(this).balance;
    }
    
    function biddingClosed() public view returns (bool) {
        return block.number >= gameEndBlock;
    }
    
    
     

    function () public payable {
        bid();
    }
}