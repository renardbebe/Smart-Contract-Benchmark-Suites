 

pragma solidity ^0.4.24;
 
 
 
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

contract ERC20 {
    function transfer(address _to, uint256 _value) external returns (bool);
    function transferFrom(address _from, address _to, uint256 _value) external returns (bool);
}


contract V00_Marketplace is Ownable {

     
    event MarketplaceData  (address indexed party, bytes32 ipfsHash);
    event AffiliateAdded   (address indexed party, bytes32 ipfsHash);
    event AffiliateRemoved (address indexed party, bytes32 ipfsHash);
    event ListingCreated   (address indexed party, uint indexed listingID, bytes32 ipfsHash);
    event ListingUpdated   (address indexed party, uint indexed listingID, bytes32 ipfsHash);
    event ListingWithdrawn (address indexed party, uint indexed listingID, bytes32 ipfsHash);
    event ListingArbitrated(address indexed party, uint indexed listingID, bytes32 ipfsHash);
    event ListingData      (address indexed party, uint indexed listingID, bytes32 ipfsHash);
    event OfferCreated     (address indexed party, uint indexed listingID, uint indexed offerID, bytes32 ipfsHash);
    event OfferAccepted    (address indexed party, uint indexed listingID, uint indexed offerID, bytes32 ipfsHash);
    event OfferFinalized   (address indexed party, uint indexed listingID, uint indexed offerID, bytes32 ipfsHash);
    event OfferWithdrawn   (address indexed party, uint indexed listingID, uint indexed offerID, bytes32 ipfsHash);
    event OfferFundsAdded  (address indexed party, uint indexed listingID, uint indexed offerID, bytes32 ipfsHash);
    event OfferDisputed    (address indexed party, uint indexed listingID, uint indexed offerID, bytes32 ipfsHash);
    event OfferRuling      (address indexed party, uint indexed listingID, uint indexed offerID, bytes32 ipfsHash, uint ruling);
    event OfferData        (address indexed party, uint indexed listingID, uint indexed offerID, bytes32 ipfsHash);

    struct Listing {
        address seller;      
        uint deposit;        
        address depositManager;  
    }

    struct Offer {
        uint value;          
        uint commission;     
        uint refund;         
        ERC20 currency;      
        address buyer;       
        address affiliate;   
        address arbitrator;  
        uint finalizes;      
        uint8 status;        
    }

    Listing[] public listings;
    mapping(uint => Offer[]) public offers;  
    mapping(address => bool) public allowedAffiliates;

    ERC20 public tokenAddr;  

    constructor(address _tokenAddr) public {
        owner = msg.sender;
        setTokenAddr(_tokenAddr);  
        allowedAffiliates[0x0] = true;  
    }

     
    function totalListings() public view returns (uint) {
        return listings.length;
    }

     
    function totalOffers(uint listingID) public view returns (uint) {
        return offers[listingID].length;
    }

     
    function createListing(bytes32 _ipfsHash, uint _deposit, address _depositManager)
        public
    {
        _createListing(msg.sender, _ipfsHash, _deposit, _depositManager);
    }

     
    function createListingWithSender(
        address _seller,
        bytes32 _ipfsHash,
        uint _deposit,
        address _depositManager
    )
        public returns (bool)
    {
        require(msg.sender == address(tokenAddr), "Token must call");
        _createListing(_seller, _ipfsHash, _deposit, _depositManager);
        return true;
    }

     
    function _createListing(
        address _seller,
        bytes32 _ipfsHash,   
        uint _deposit,       
        address _depositManager  
    )
        private
    {
        /* require(_deposit > 0);  
        require(_depositManager != 0x0, "Must specify depositManager");

        listings.push(Listing({
            seller: _seller,
            deposit: _deposit,
            depositManager: _depositManager
        }));

        if (_deposit > 0) {
            tokenAddr.transferFrom(_seller, this, _deposit);  
        }
        emit ListingCreated(_seller, listings.length - 1, _ipfsHash);
    }

     
    function updateListing(
        uint listingID,
        bytes32 _ipfsHash,
        uint _additionalDeposit
    ) public {
        _updateListing(msg.sender, listingID, _ipfsHash, _additionalDeposit);
    }

    function updateListingWithSender(
        address _seller,
        uint listingID,
        bytes32 _ipfsHash,
        uint _additionalDeposit
    )
        public returns (bool)
    {
        require(msg.sender == address(tokenAddr), "Token must call");
        _updateListing(_seller, listingID, _ipfsHash, _additionalDeposit);
        return true;
    }

    function _updateListing(
        address _seller,
        uint listingID,
        bytes32 _ipfsHash,       
        uint _additionalDeposit  
    ) private {
        Listing storage listing = listings[listingID];
        require(listing.seller == _seller, "Seller must call");

        if (_additionalDeposit > 0) {
            tokenAddr.transferFrom(_seller, this, _additionalDeposit);
            listing.deposit += _additionalDeposit;
        }

        emit ListingUpdated(listing.seller, listingID, _ipfsHash);
    }

     
    function withdrawListing(uint listingID, address _target, bytes32 _ipfsHash) public {
        Listing storage listing = listings[listingID];
        require(msg.sender == listing.depositManager, "Must be depositManager");
        require(_target != 0x0, "No target");
        tokenAddr.transfer(_target, listing.deposit);  
        emit ListingWithdrawn(_target, listingID, _ipfsHash);
    }

     
    function makeOffer(
        uint listingID,
        bytes32 _ipfsHash,    
        uint _finalizes,      
        address _affiliate,   
        uint256 _commission,  
        uint _value,          
        ERC20 _currency,      
        address _arbitrator   
    )
        public
        payable
    {
        bool affiliateWhitelistDisabled = allowedAffiliates[address(this)];
        require(
            affiliateWhitelistDisabled || allowedAffiliates[_affiliate],
            "Affiliate not allowed"
        );

        if (_affiliate == 0x0) {
             
            require(_commission == 0, "commission requires affiliate");
        }

        offers[listingID].push(Offer({
            status: 1,
            buyer: msg.sender,
            finalizes: _finalizes,
            affiliate: _affiliate,
            commission: _commission,
            currency: _currency,
            value: _value,
            arbitrator: _arbitrator,
            refund: 0
        }));

        if (address(_currency) == 0x0) {  
            require(msg.value == _value, "ETH value doesn't match offer");
        } else {  
            require(msg.value == 0, "ETH would be lost");
            require(
                _currency.transferFrom(msg.sender, this, _value),
                "transferFrom failed"
            );
        }

        emit OfferCreated(msg.sender, listingID, offers[listingID].length-1, _ipfsHash);
    }

     
    function makeOffer(
        uint listingID,
        bytes32 _ipfsHash,
        uint _finalizes,
        address _affiliate,
        uint256 _commission,
        uint _value,
        ERC20 _currency,
        address _arbitrator,
        uint _withdrawOfferID
    )
        public
        payable
    {
        withdrawOffer(listingID, _withdrawOfferID, _ipfsHash);
        makeOffer(listingID, _ipfsHash, _finalizes, _affiliate, _commission, _value, _currency, _arbitrator);
    }

     
    function acceptOffer(uint listingID, uint offerID, bytes32 _ipfsHash) public {
        Listing storage listing = listings[listingID];
        Offer storage offer = offers[listingID][offerID];
        require(msg.sender == listing.seller, "Seller must accept");
        require(offer.status == 1, "status != created");
        require(
            listing.deposit >= offer.commission,
            "deposit must cover commission"
        );
        if (offer.finalizes < 1000000000) {  
            offer.finalizes = now + offer.finalizes;
        }
        listing.deposit -= offer.commission;  
        offer.status = 2;  
        emit OfferAccepted(msg.sender, listingID, offerID, _ipfsHash);
    }

     
    function withdrawOffer(uint listingID, uint offerID, bytes32 _ipfsHash) public {
        Listing storage listing = listings[listingID];
        Offer storage offer = offers[listingID][offerID];
        require(
            msg.sender == offer.buyer || msg.sender == listing.seller,
            "Restricted to buyer or seller"
        );
        require(offer.status == 1, "status != created");
        refundBuyer(listingID, offerID);
        emit OfferWithdrawn(msg.sender, listingID, offerID, _ipfsHash);
        delete offers[listingID][offerID];
    }

     
    function addFunds(uint listingID, uint offerID, bytes32 _ipfsHash, uint _value) public payable {
        Offer storage offer = offers[listingID][offerID];
        require(msg.sender == offer.buyer, "Buyer must call");
        require(offer.status == 2, "status != accepted");
        if (address(offer.currency) == 0x0) {  
            require(
                msg.value == _value,
                "sent != offered value"
            );
        } else {  
            require(msg.value == 0, "ETH must not be sent");
            require(
                offer.currency.transferFrom(msg.sender, this, _value),
                "transferFrom failed"
            );
        }
        offer.value += _value;
        emit OfferFundsAdded(msg.sender, listingID, offerID, _ipfsHash);
    }

     
    function finalize(uint listingID, uint offerID, bytes32 _ipfsHash) public {
        Listing storage listing = listings[listingID];
        Offer storage offer = offers[listingID][offerID];
        if (now <= offer.finalizes) {  
            require(
                msg.sender == offer.buyer,
                "Only buyer can finalize"
            );
        } else {  
            require(
                msg.sender == offer.buyer || msg.sender == listing.seller,
                "Seller or buyer must finalize"
            );
        }
        require(offer.status == 2, "status != accepted");
        paySeller(listingID, offerID);  
        if (msg.sender == offer.buyer) {  
            payCommission(listingID, offerID);
        }
        emit OfferFinalized(msg.sender, listingID, offerID, _ipfsHash);
        delete offers[listingID][offerID];
    }

     
    function dispute(uint listingID, uint offerID, bytes32 _ipfsHash) public {
        Listing storage listing = listings[listingID];
        Offer storage offer = offers[listingID][offerID];
        require(
            msg.sender == offer.buyer || msg.sender == listing.seller,
            "Must be seller or buyer"
        );
        require(offer.status == 2, "status != accepted");
        require(now <= offer.finalizes, "Already finalized");
        offer.status = 3;  
        emit OfferDisputed(msg.sender, listingID, offerID, _ipfsHash);
    }

     
    function executeRuling(
        uint listingID,
        uint offerID,
        bytes32 _ipfsHash,
        uint _ruling,  
        uint _refund
    ) public {
        Offer storage offer = offers[listingID][offerID];
        require(msg.sender == offer.arbitrator, "Must be arbitrator");
        require(offer.status == 3, "status != disputed");
        require(_refund <= offer.value, "refund too high");
        offer.refund = _refund;
        if (_ruling & 1 == 1) {
            refundBuyer(listingID, offerID);
        } else  {
            paySeller(listingID, offerID);
        }
        if (_ruling & 2 == 2) {
            payCommission(listingID, offerID);
        } else  {  
            listings[listingID].deposit += offer.commission;
        }
        emit OfferRuling(offer.arbitrator, listingID, offerID, _ipfsHash, _ruling);
        delete offers[listingID][offerID];
    }

     
    function updateRefund(uint listingID, uint offerID, uint _refund, bytes32 _ipfsHash) public {
        Offer storage offer = offers[listingID][offerID];
        Listing storage listing = listings[listingID];
        require(msg.sender == listing.seller, "Seller must call");
        require(offer.status == 2, "status != accepted");
        require(_refund <= offer.value, "Excessive refund");
        offer.refund = _refund;
        emit OfferData(msg.sender, listingID, offerID, _ipfsHash);
    }

     
    function refundBuyer(uint listingID, uint offerID) private {
        Offer storage offer = offers[listingID][offerID];
        if (address(offer.currency) == 0x0) {
            require(offer.buyer.send(offer.value), "ETH refund failed");
        } else {
            require(
                offer.currency.transfer(offer.buyer, offer.value),
                "Refund failed"
            );
        }
    }

     
    function paySeller(uint listingID, uint offerID) private {
        Listing storage listing = listings[listingID];
        Offer storage offer = offers[listingID][offerID];
        uint value = offer.value - offer.refund;

        if (address(offer.currency) == 0x0) {
            require(offer.buyer.send(offer.refund), "ETH refund failed");
            require(listing.seller.send(value), "ETH send failed");
        } else {
            require(
                offer.currency.transfer(offer.buyer, offer.refund),
                "Refund failed"
            );
            require(
                offer.currency.transfer(listing.seller, value),
                "Transfer failed"
            );
        }
    }

     
    function payCommission(uint listingID, uint offerID) private {
        Offer storage offer = offers[listingID][offerID];
        if (offer.affiliate != 0x0) {
            require(
                tokenAddr.transfer(offer.affiliate, offer.commission),
                "Commission transfer failed"
            );
        }
    }

     
    function addData(bytes32 ipfsHash) public {
        emit MarketplaceData(msg.sender, ipfsHash);
    }

     
    function addData(uint listingID, bytes32 ipfsHash) public {
        emit ListingData(msg.sender, listingID, ipfsHash);
    }

     
    function addData(uint listingID, uint offerID, bytes32 ipfsHash) public {
        emit OfferData(msg.sender, listingID, offerID, ipfsHash);
    }

     
    function sendDeposit(uint listingID, address target, uint value, bytes32 ipfsHash) public {
        Listing storage listing = listings[listingID];
        require(listing.depositManager == msg.sender, "depositManager must call");
        require(listing.deposit >= value, "Value too high");
        listing.deposit -= value;
        require(tokenAddr.transfer(target, value), "Transfer failed");
        emit ListingArbitrated(target, listingID, ipfsHash);
    }

     
    function setTokenAddr(address _tokenAddr) public onlyOwner {
        tokenAddr = ERC20(_tokenAddr);
    }

     
    function addAffiliate(address _affiliate, bytes32 ipfsHash) public onlyOwner {
        allowedAffiliates[_affiliate] = true;
        emit AffiliateAdded(_affiliate, ipfsHash);
    }

     
    function removeAffiliate(address _affiliate, bytes32 ipfsHash) public onlyOwner {
        delete allowedAffiliates[_affiliate];
        emit AffiliateRemoved(_affiliate, ipfsHash);
    }
}