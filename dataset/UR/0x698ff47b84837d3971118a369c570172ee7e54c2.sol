 

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


 
contract V01_Marketplace is Ownable {

     
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
            require(
                tokenAddr.transferFrom(_seller, this, _deposit),  
                "transferFrom failed"
            );
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
            listing.deposit += _additionalDeposit;
            require(
                tokenAddr.transferFrom(_seller, this, _additionalDeposit),
                "transferFrom failed"
            );
        }

        emit ListingUpdated(listing.seller, listingID, _ipfsHash);
    }

     
    function withdrawListing(uint listingID, address _target, bytes32 _ipfsHash) public {
        Listing storage listing = listings[listingID];
        require(msg.sender == listing.depositManager, "Must be depositManager");
        require(_target != 0x0, "No target");
        uint deposit = listing.deposit;
        listing.deposit = 0;  
        require(tokenAddr.transfer(_target, deposit), "transfer failed");  
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
        Offer memory offer = offers[listingID][offerID];
        require(
            msg.sender == offer.buyer || msg.sender == listing.seller,
            "Restricted to buyer or seller"
        );
        require(offer.status == 1, "status != created");
        delete offers[listingID][offerID];
        refundBuyer(offer.buyer, offer.currency, offer.value);
        emit OfferWithdrawn(msg.sender, listingID, offerID, _ipfsHash);
    }

     
    function addFunds(uint listingID, uint offerID, bytes32 _ipfsHash, uint _value) public payable {
        Offer storage offer = offers[listingID][offerID];
        require(msg.sender == offer.buyer, "Buyer must call");
        require(offer.status == 2, "status != accepted");
        offer.value += _value;
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
        emit OfferFundsAdded(msg.sender, listingID, offerID, _ipfsHash);
    }

     
    function finalize(uint listingID, uint offerID, bytes32 _ipfsHash) public {
        Listing storage listing = listings[listingID];
        Offer memory offer = offers[listingID][offerID];
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
        delete offers[listingID][offerID];

        if (msg.sender != offer.buyer) {
            listing.deposit += offer.commission;  
        } else {
             
            payCommission(offer.affiliate, offer.commission);
        }

        paySeller(listing.seller, offer.buyer, offer.currency, offer.value, offer.refund);  

        emit OfferFinalized(msg.sender, listingID, offerID, _ipfsHash);
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
        Listing storage listing = listings[listingID];
        Offer memory offer = offers[listingID][offerID];
        require(msg.sender == offer.arbitrator, "Must be arbitrator");
        require(offer.status == 3, "status != disputed");
        require(_refund <= offer.value, "refund too high");
        delete offers[listingID][offerID];
        if (_ruling & 2 == 2) {
            payCommission(offer.affiliate, offer.commission);
        } else  {  
            listings[listingID].deposit += offer.commission;
        }
        if (_ruling & 1 == 1) {
            refundBuyer(offer.buyer, offer.currency, offer.value);
        } else  {
            paySeller(listing.seller, offer.buyer, offer.currency, offer.value, _refund);  
        }
        emit OfferRuling(offer.arbitrator, listingID, offerID, _ipfsHash, _ruling);
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

     
    function refundBuyer(address buyer, ERC20 currency, uint value) private {
        if (address(currency) == 0x0) {
            require(buyer.send(value), "ETH refund failed");
        } else {
            require(
                currency.transfer(buyer, value),
                "Refund failed"
            );
        }
    }

     
    function paySeller(address seller, address buyer, ERC20 currency, uint offerValue, uint offerRefund) private {
        uint value = offerValue - offerRefund;

        if (address(currency) == 0x0) {
            require(buyer.send(offerRefund), "ETH refund failed");
            require(seller.send(value), "ETH send failed");
        } else {
            require(
                currency.transfer(buyer, offerRefund),
                "Refund failed"
            );
            require(
                currency.transfer(seller, value),
                "Transfer failed"
            );
        }
    }

     
    function payCommission(address affiliate, uint commission) private {
        if (affiliate != 0x0) {
            require(
                tokenAddr.transfer(affiliate, commission),
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