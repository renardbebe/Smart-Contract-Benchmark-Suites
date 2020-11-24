 

pragma solidity ^0.4.12;

 

contract CryptoStars {

    address owner;
    string public standard = "STRZ";     
    string public name;                     
    string public symbol;  
    uint8 public decimals;                          
    uint256 public totalSupply;                     
    uint256 public initialPrice;                   
    uint256 public transferPrice;                  
    uint256 public MaxStarIndexAvailable;          
    uint256 public MinStarIndexAvailable;         
    uint public nextStarIndexToAssign = 0;
    uint public starsRemainingToAssign = 0;
    uint public numberOfStarsToReserve;
    uint public numberOfStarsReserved = 0;

    mapping (uint => address) public starIndexToAddress;    
    mapping (uint => string) public starIndexToSTRZName;         
    mapping (uint => string) public starIndexToSTRZMasterName;   

     
    mapping (address => uint256) public balanceOf;

    struct Offer {
        bool isForSale;
        uint starIndex;
        address seller;
        uint minValue;           
        address onlySellTo;      
    }

    struct Bid {
        bool hasBid;
        uint starIndex;
        address bidder;        
        uint value;               
    }

    

     
    mapping (uint => Offer) public starsOfferedForSale;

     
    mapping (uint => Bid) public starBids;

     
     
    mapping (address => uint) public pendingWithdrawals;


    event Assign(address indexed to, uint256 starIndex, string GivenName, string MasterName);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event StarTransfer(address indexed from, address indexed to, uint256 starIndex);
    event StarOffered(uint indexed starIndex, uint minValue, address indexed fromAddress, address indexed toAddress);
    event StarBidEntered(uint indexed starIndex, uint value, address indexed fromAddress);
    event StarBidWithdrawn(uint indexed starIndex, uint value, address indexed fromAddress);
    event StarBidAccepted(uint indexed starIndex, uint value, address indexed fromAddress);
    event StarBought(uint indexed starIndex, uint value, address indexed fromAddress, address indexed toAddress, string GivenName, string MasterName, uint MinStarAvailable, uint MaxStarAvailable);
    event StarNoLongerForSale(uint indexed starIndex);
    event StarMinMax(uint MinStarAvailable, uint MaxStarAvailable, uint256 Price);
    event NewOwner(uint indexed starIndex, address indexed toAddress);

   
    function CryptoStars() payable {
        
        owner = msg.sender;
        totalSupply = 119614;                         
        starsRemainingToAssign = totalSupply;
        numberOfStarsToReserve = 1000;
        name = "CRYPTOSTARS";                         
        symbol = "STRZ";                              
        decimals = 0;                                 
        initialPrice = 99000000000000000;           
        transferPrice = 10000000000000000;           
        MinStarIndexAvailable = 11500;                
        MaxStarIndexAvailable = 12000;                

         
        starIndexToSTRZMasterName[0] = "Sol";
        starIndexToAddress[0] = owner;
        Assign(owner, 0, starIndexToSTRZName[0], starIndexToSTRZMasterName[0]);

         
        starIndexToSTRZMasterName[2001] = "Odyssey";
        starIndexToAddress[2001] = owner;
        Assign(owner, 2001, starIndexToSTRZName[2001], starIndexToSTRZMasterName[2001]);

         
        starIndexToSTRZMasterName[119006] = "Delta Velorum";
        starIndexToAddress[119006] = owner;
        Assign(owner, 119006, starIndexToSTRZName[119006], starIndexToSTRZMasterName[119006]);

         
        starIndexToSTRZMasterName[119088] = "Gamma Camelopardalis";
        starIndexToAddress[119088] = owner;
        Assign(owner, 119088, starIndexToSTRZName[119088], starIndexToSTRZMasterName[119088]);

         
        starIndexToSTRZMasterName[119514] = "Capella";
        starIndexToAddress[119514] = owner;
        Assign(owner, 119514, starIndexToSTRZName[119514], starIndexToSTRZMasterName[119514]);

        Transfer(0x0, owner, 5);

        balanceOf[msg.sender] = 5;

    }


    function reserveStarsForOwner(uint maxForThisRun) {               
        if (msg.sender != owner) throw;
        if (numberOfStarsReserved >= numberOfStarsToReserve) throw;
        uint numberStarsReservedThisRun = 0;
        while (numberOfStarsReserved < numberOfStarsToReserve && numberStarsReservedThisRun < maxForThisRun) {
            starIndexToAddress[nextStarIndexToAssign] = msg.sender;
            Assign(msg.sender, nextStarIndexToAssign,starIndexToSTRZName[nextStarIndexToAssign], starIndexToSTRZMasterName[nextStarIndexToAssign]);
            Transfer(0x0, msg.sender, 1);
            numberStarsReservedThisRun++;
            nextStarIndexToAssign++;
        }
        starsRemainingToAssign -= numberStarsReservedThisRun;
        numberOfStarsReserved += numberStarsReservedThisRun;
        balanceOf[msg.sender] += numberStarsReservedThisRun;
    }

    function setGivenName(uint starIndex, string name) {
        if (starIndexToAddress[starIndex] != msg.sender) throw;      
        starIndexToSTRZName[starIndex] = name;
        Assign(msg.sender, starIndex, starIndexToSTRZName[starIndex], starIndexToSTRZMasterName[starIndex]);   
    }

    function setMasterName(uint starIndex, string name) {
        if (msg.sender != owner) throw;                              
        if (starIndexToAddress[starIndex] != owner) throw;           
       
        starIndexToSTRZMasterName[starIndex] = name;
        Assign(msg.sender, starIndex, starIndexToSTRZName[starIndex], starIndexToSTRZMasterName[starIndex]);   
    }

    function getMinMax(){
        StarMinMax(MinStarIndexAvailable,MaxStarIndexAvailable, initialPrice);
    }

    function setMinMax(uint256 MaxStarIndexHolder, uint256 MinStarIndexHolder) {
        if (msg.sender != owner) throw;
        MaxStarIndexAvailable = MaxStarIndexHolder;
        MinStarIndexAvailable = MinStarIndexHolder;
        StarMinMax(MinStarIndexAvailable,MaxStarIndexAvailable, initialPrice);
    }

    function setStarInitialPrice(uint256 initialPriceHolder) {
        if (msg.sender != owner) throw;
        initialPrice = initialPriceHolder;
        StarMinMax(MinStarIndexAvailable,MaxStarIndexAvailable, initialPrice);
    }

    function setTransferPrice(uint256 transferPriceHolder){
        if (msg.sender != owner) throw;
        transferPrice = transferPriceHolder;
    }

    function getStar(uint starIndex, string strSTRZName, string strSTRZMasterName) {
        if (msg.sender != owner) throw;
       
        if (starIndexToAddress[starIndex] != 0x0) throw;

        starIndexToSTRZName[starIndex] = strSTRZName;
        starIndexToSTRZMasterName[starIndex] = strSTRZMasterName;

        starIndexToAddress[starIndex] = msg.sender;
    
        balanceOf[msg.sender]++;
        Assign(msg.sender, starIndex, starIndexToSTRZName[starIndex], starIndexToSTRZMasterName[starIndex]);
        Transfer(0x0, msg.sender, 1);

    }

    
    function transferStar(address to, uint starIndex) payable {
        if (starIndexToAddress[starIndex] != msg.sender) throw;
        if (msg.value < transferPrice) throw;                        

        starIndexToAddress[starIndex] = to;
        balanceOf[msg.sender]--;
        balanceOf[to]++;
        StarTransfer(msg.sender, to, starIndex);
        Assign(to, starIndex, starIndexToSTRZName[starIndex], starIndexToSTRZMasterName[starIndex]);
        Transfer(msg.sender, to, 1);
        pendingWithdrawals[owner] += msg.value;
         
        Bid bid = starBids[starIndex];
        if (bid.hasBid) {
            pendingWithdrawals[bid.bidder] += bid.value;
            starBids[starIndex] = Bid(false, starIndex, 0x0, 0);
            StarBidWithdrawn(starIndex, bid.value, to);
        }
        
         
        Offer offer = starsOfferedForSale[starIndex];
        if (offer.isForSale) {
             starsOfferedForSale[starIndex] = Offer(false, starIndex, msg.sender, 0, 0x0);
        }

    }

    function starNoLongerForSale(uint starIndex) {
        if (starIndexToAddress[starIndex] != msg.sender) throw;
        starsOfferedForSale[starIndex] = Offer(false, starIndex, msg.sender, 0, 0x0);
        StarNoLongerForSale(starIndex);
        Bid bid = starBids[starIndex];
        if (bid.bidder == msg.sender ) {
             
            pendingWithdrawals[msg.sender] += bid.value;
            starBids[starIndex] = Bid(false, starIndex, 0x0, 0);
            StarBidWithdrawn(starIndex, bid.value, msg.sender);
        }
    }

    function offerStarForSale(uint starIndex, uint minSalePriceInWei) {
        if (starIndexToAddress[starIndex] != msg.sender) throw;
        starsOfferedForSale[starIndex] = Offer(true, starIndex, msg.sender, minSalePriceInWei, 0x0);
        StarOffered(starIndex, minSalePriceInWei, msg.sender, 0x0);
    }

    function offerStarForSaleToAddress(uint starIndex, uint minSalePriceInWei, address toAddress) {
        if (starIndexToAddress[starIndex] != msg.sender) throw;
        starsOfferedForSale[starIndex] = Offer(true, starIndex, msg.sender, minSalePriceInWei, toAddress);
        StarOffered(starIndex, minSalePriceInWei, msg.sender, toAddress);
    }

     
    function buyStar(uint starIndex) payable {
        Offer offer = starsOfferedForSale[starIndex];
        if (!offer.isForSale) throw;                                             
        if (offer.onlySellTo != 0x0 && offer.onlySellTo != msg.sender) throw;    
        if (msg.value < offer.minValue) throw;                                   
        if (offer.seller != starIndexToAddress[starIndex]) throw;                

        address seller = offer.seller;
        
        balanceOf[seller]--;
        balanceOf[msg.sender]++;

        Assign(msg.sender, starIndex,starIndexToSTRZName[starIndex], starIndexToSTRZMasterName[starIndex]);

        Transfer(seller, msg.sender, 1);

        uint amountseller = msg.value*97/100;
        uint amountowner = msg.value*3/100;            

        pendingWithdrawals[owner] += amountowner;    
        pendingWithdrawals[seller] += amountseller;

        starIndexToAddress[starIndex] = msg.sender;
 
        starNoLongerForSale(starIndex);
    
        string STRZName = starIndexToSTRZName[starIndex];
        string STRZMasterName = starIndexToSTRZMasterName[starIndex];

        StarBought(starIndex, msg.value, offer.seller, msg.sender, STRZName, STRZMasterName, MinStarIndexAvailable, MaxStarIndexAvailable);

        Bid bid = starBids[starIndex];
        if (bid.bidder == msg.sender) {
             
            pendingWithdrawals[msg.sender] += bid.value;
            starBids[starIndex] = Bid(false, starIndex, 0x0, 0);
            StarBidWithdrawn(starIndex, bid.value, msg.sender);
        }

    }

    function buyStarInitial(uint starIndex, string strSTRZName) payable {
         
     
        if (starIndex > MaxStarIndexAvailable) throw;      
        if (starIndex < MinStarIndexAvailable) throw;        
        if (starIndexToAddress[starIndex] != 0x0) throw;     
        if (msg.value < initialPrice) throw;                
        
        starIndexToAddress[starIndex] = msg.sender;   
        starIndexToSTRZName[starIndex] = strSTRZName;       
        
        balanceOf[msg.sender]++;                             
        pendingWithdrawals[owner] += msg.value;

        string STRZMasterName = starIndexToSTRZMasterName[starIndex];
        StarBought(starIndex, msg.value, owner, msg.sender, strSTRZName, STRZMasterName ,MinStarIndexAvailable, MaxStarIndexAvailable);

        Assign(msg.sender, starIndex, starIndexToSTRZName[starIndex], starIndexToSTRZMasterName[starIndex]);
        Transfer(0x0, msg.sender, 1);
         
    }

    function enterBidForStar(uint starIndex) payable {

        if (starIndex >= totalSupply) throw;             
        if (starIndexToAddress[starIndex] == 0x0) throw;
        if (starIndexToAddress[starIndex] == msg.sender) throw;
        if (msg.value == 0) throw;

        Bid existing = starBids[starIndex];
        if (msg.value <= existing.value) throw;
        if (existing.value > 0) {
             
            pendingWithdrawals[existing.bidder] += existing.value;
        }

        starBids[starIndex] = Bid(true, starIndex, msg.sender, msg.value);
        StarBidEntered(starIndex, msg.value, msg.sender);
    }

    function acceptBidForStar(uint starIndex, uint minPrice) {
        if (starIndex >= totalSupply) throw;
         
        if (starIndexToAddress[starIndex] != msg.sender) throw;
        address seller = msg.sender;
        Bid bid = starBids[starIndex];
        if (bid.value == 0) throw;
        if (bid.value < minPrice) throw;

        starIndexToAddress[starIndex] = bid.bidder;
        balanceOf[seller]--;
        balanceOf[bid.bidder]++;
        Transfer(seller, bid.bidder, 1);

        starsOfferedForSale[starIndex] = Offer(false, starIndex, bid.bidder, 0, 0x0);
        
        uint amount = bid.value;
        uint amountseller = amount*97/100;
        uint amountowner = amount*3/100;
        
        pendingWithdrawals[seller] += amountseller;
        pendingWithdrawals[owner] += amountowner;                

        string STRZGivenName = starIndexToSTRZName[starIndex];
        string STRZMasterName = starIndexToSTRZMasterName[starIndex];
        StarBought(starIndex, bid.value, seller, bid.bidder, STRZGivenName, STRZMasterName, MinStarIndexAvailable, MaxStarIndexAvailable);
        StarBidWithdrawn(starIndex, bid.value, bid.bidder);
        Assign(bid.bidder, starIndex, starIndexToSTRZName[starIndex], starIndexToSTRZMasterName[starIndex]);
        StarNoLongerForSale(starIndex);

        starBids[starIndex] = Bid(false, starIndex, 0x0, 0);
    }

    function withdrawBidForStar(uint starIndex) {
        if (starIndex >= totalSupply) throw;            
        if (starIndexToAddress[starIndex] == 0x0) throw;
        if (starIndexToAddress[starIndex] == msg.sender) throw;

        Bid bid = starBids[starIndex];
        if (bid.bidder != msg.sender) throw;
        StarBidWithdrawn(starIndex, bid.value, msg.sender);
        uint amount = bid.value;
        starBids[starIndex] = Bid(false, starIndex, 0x0, 0);
         
        pendingWithdrawals[msg.sender] += amount;
    
    }

    function withdraw() {
         
        uint amount = pendingWithdrawals[msg.sender];
         
         
        pendingWithdrawals[msg.sender] = 0;
        msg.sender.send(amount);
    }

    function withdrawPartial(uint withdrawAmount) {
         
         
        if (msg.sender != owner) throw;
        if (withdrawAmount > pendingWithdrawals[msg.sender]) throw;

        pendingWithdrawals[msg.sender] -= withdrawAmount;
        msg.sender.send(withdrawAmount);
    }
}