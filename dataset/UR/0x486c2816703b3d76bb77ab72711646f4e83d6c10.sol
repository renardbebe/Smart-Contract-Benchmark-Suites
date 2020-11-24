 

pragma solidity =0.5.10;

 
 
 
 
 
 
 

contract ERC20Interface {
    function transferFrom(address from, address to, uint tokens) public returns (bool success);
}

contract IERC20Interface {
    function allowance(address owner, address spender) external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
}

contract RaffleToken is ERC20Interface, IERC20Interface {}

contract RaffleTokenExchange {

     
     
     
     
    RaffleToken constant public raffleContract = RaffleToken(0x0C8cDC16973E88FAb31DD0FCB844DdF0e1056dE2);
     
     
     
    bool public paused;
     
     
     
    address payable public owner;
     
     
     
    uint public nextListingId;
     
     
     
    mapping (uint => Listing) public listingsById;
     
     
     
    mapping (uint => Purchase) public purchasesById;
     
     
     
    uint public nextPurchaseId;

     
     
     
     
    struct Listing {
         
         
         
        uint pricePerToken;
         
         
         
         
        uint initialAmount;
         
         
         
        uint amountLeft;
         
         
         
        address payable seller;
         
         
         
        bool active;
    }
     
     
     
    struct Purchase {
         
         
         
        uint totalAmount;
         
         
         
        uint totalAmountPayed;
         
         
         
        uint timestamp;
    }

     
     
     
     
    event Listed(uint id, uint pricePerToken, uint initialAmount, address seller);
    event Canceled(uint id);
    event Purchased(uint id, uint totalAmount, uint totalAmountPayed, uint timestamp);

     
     
     
     
    modifier onlyContractOwner {
        require(msg.sender == owner, "Function called by non-owner.");
        _;
    }
     
     
     
    modifier onlyUnpaused {
        require(paused == false, "Exchange is paused.");
        _;
    }

     
     
    constructor() public {
        owner = msg.sender;
        nextListingId = 1;
        nextPurchaseId = 1;
    }

     
     
     
     
    function buyRaffle(uint[] calldata amounts, uint[] calldata listingIds) payable external onlyUnpaused {
        require(amounts.length == listingIds.length, "You have to provide amounts for every single listing!");
        uint totalAmount;
        uint totalAmountPayed;
        for (uint i = 0; i < listingIds.length; i++) {
            uint id = listingIds[i];
            uint amount = amounts[i];
            Listing storage listing = listingsById[id];
            require(listing.active, "Listing is not active anymore!");
            listing.amountLeft -= amount;
            require(listing.amountLeft >= 0, "Amount left needs to be higher than 0.");
            if(listing.amountLeft == 0) { listing.active = false; }
            uint amountToPay = listing.pricePerToken * amount;
            listing.seller.transfer(amountToPay);
            totalAmountPayed += amountToPay;
            totalAmount += amount;
            require(raffleContract.transferFrom(listing.seller, msg.sender, amount), 'Token transfer failed!');
        }
        require(totalAmountPayed <= msg.value, 'Overpayed!');
        uint id = nextPurchaseId++;
        Purchase storage purchase = purchasesById[id];
        purchase.totalAmount = totalAmount;
        purchase.totalAmountPayed = totalAmountPayed;
        purchase.timestamp = now;
        emit Purchased(id, totalAmount, totalAmountPayed, now);
    }
     
     
     
    function addListing(uint initialAmount, uint pricePerToken) external onlyUnpaused {
        require(raffleContract.balanceOf(msg.sender) >= initialAmount, "Amount to sell is higher than balance!");
        require(raffleContract.allowance(msg.sender, address(this)) >= initialAmount, "Allowance is to small (increase allowance)!");
        uint id = nextListingId++;
        Listing storage listing = listingsById[id];
        listing.initialAmount = initialAmount;
        listing.amountLeft = initialAmount;
        listing.pricePerToken = pricePerToken;
        listing.seller = msg.sender;
        listing.active = true;
        emit Listed(id, listing.pricePerToken, listing.initialAmount, listing.seller);
    }
     
     
     
    function cancelListing(uint id) external {
        Listing storage listing = listingsById[id];
        require(listing.active, "This listing was turned inactive already!");
        require(listing.seller == msg.sender || owner == msg.sender, "Only the listing owner or the contract owner can cancel the listing!");
        listing.active = false;
        emit Canceled(id);
    }
     
     
     
    function setPaused(bool value) external onlyContractOwner {
        paused = value;
    }
     
     
     
    function withdrawFunds(uint withdrawAmount) external onlyContractOwner {
        owner.transfer(withdrawAmount);
    }
     
     
     
     
    function kill() external onlyContractOwner {
        selfdestruct(owner);
    }
}