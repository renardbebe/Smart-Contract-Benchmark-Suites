 

pragma solidity ^0.4.24;

 
 
contract OffersAccessControl {

     
    address public ceoAddress;
     
    address public cooAddress;
     
    address public cfoAddress;
     
    address public lostAndFoundAddress;

     
    uint256 public totalCFOEarnings;
     
    uint256 public totalLostAndFoundBalance;

     
     
     
    bool public frozen = false;

     
    modifier onlyCEO() {
        require(msg.sender == ceoAddress, "only CEO is allowed to perform this operation");
        _;
    }

     
    modifier onlyCOO() {
        require(msg.sender == cooAddress, "only COO is allowed to perform this operation");
        _;
    }

     
    modifier onlyCFO() {
        require(
            msg.sender == cfoAddress &&
            msg.sender != address(0),
            "only CFO is allowed to perform this operation"
        );
        _;
    }

     
    modifier onlyCeoOrCfo() {
        require(
            msg.sender != address(0) &&
            (
                msg.sender == ceoAddress ||
                msg.sender == cfoAddress
            ),
            "only CEO or CFO is allowed to perform this operation"
        );
        _;
    }

     
    modifier onlyLostAndFound() {
        require(
            msg.sender == lostAndFoundAddress &&
            msg.sender != address(0),
            "only LostAndFound is allowed to perform this operation"
        );
        _;
    }

     
     
    function setCEO(address _newCEO) external onlyCEO {
        require(_newCEO != address(0), "new CEO address cannot be the zero-account");
        ceoAddress = _newCEO;
    }

     
     
    function setCOO(address _newCOO) public onlyCEO {
        require(_newCOO != address(0), "new COO address cannot be the zero-account");
        cooAddress = _newCOO;
    }

     
     
    function setCFO(address _newCFO) external onlyCEO {
        require(_newCFO != address(0), "new CFO address cannot be the zero-account");
        cfoAddress = _newCFO;
    }

     
     
    function setLostAndFound(address _newLostAndFound) external onlyCEO {
        require(_newLostAndFound != address(0), "new lost and found cannot be the zero-account");
        lostAndFoundAddress = _newLostAndFound;
    }

     
    function withdrawTotalCFOEarnings() external onlyCFO {
         
        uint256 balance = totalCFOEarnings;
        totalCFOEarnings = 0;
        cfoAddress.transfer(balance);
    }

     
    function withdrawTotalLostAndFoundBalance() external onlyLostAndFound {
         
        uint256 balance = totalLostAndFoundBalance;
        totalLostAndFoundBalance = 0;
        lostAndFoundAddress.transfer(balance);
    }

     
    modifier whenNotFrozen() {
        require(!frozen, "contract needs to not be frozen");
        _;
    }

     
    modifier whenFrozen() {
        require(frozen, "contract needs to be frozen");
        _;
    }

     
     
     
     
     
    function freeze() external onlyCeoOrCfo whenNotFrozen {
        frozen = true;
    }

}

 
 
contract ERC721 {
     
    function totalSupply() public view returns (uint256 total);
    function balanceOf(address _owner) public view returns (uint256 balance);
    function ownerOf(uint256 _tokenId) external view returns (address owner);
    function approve(address _to, uint256 _tokenId) external;
    function transfer(address _to, uint256 _tokenId) external;
    function transferFrom(address _from, address _to, uint256 _tokenId) external;

     
    event Transfer(address from, address to, uint256 tokenId);
    event Approval(address owner, address approved, uint256 tokenId);

     
     
     
     
     

     
    function supportsInterface(bytes4 _interfaceID) external view returns (bool);
}

 
 
contract OffersConfig is OffersAccessControl {

     
     
     

     
     
    uint256 public globalDuration;
     
    uint256 public minimumTotalValue;
     
     
    uint256 public minimumPriceIncrement;

     
     
     

     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     

     
     
    uint256 public unsuccessfulFee;
     
     
    uint256 public offerCut;

     
     
     

    event GlobalDurationUpdated(uint256 value);
    event MinimumTotalValueUpdated(uint256 value);
    event MinimumPriceIncrementUpdated(uint256 value);
    event OfferCutUpdated(uint256 value);
    event UnsuccessfulFeeUpdated(uint256 value);

     
     
     

     
     
     
     
    function setMinimumTotalValue(uint256 _newMinTotal) external onlyCOO whenNotFrozen {
        _setMinimumTotalValue(_newMinTotal, unsuccessfulFee);
        emit MinimumTotalValueUpdated(_newMinTotal);
    }

     
     
     
     
     
     
    function setGlobalDuration(uint256 _newDuration) external onlyCOO whenNotFrozen {
        require(_newDuration == uint256(uint64(_newDuration)), "new globalDuration value must not underflow");
        globalDuration = _newDuration;
        emit GlobalDurationUpdated(_newDuration);
    }

     
     
     
     
     
    function setOfferCut(uint256 _newOfferCut) external onlyCOO whenNotFrozen {
        _setOfferCut(_newOfferCut);
        emit OfferCutUpdated(_newOfferCut);
    }

     
     
     
     
     
     
     
     
     
    function setUnsuccessfulFee(uint256 _newUnsuccessfulFee) external onlyCOO whenNotFrozen {
        require(minimumTotalValue >= (2 * _newUnsuccessfulFee), "unsuccessful value must be <= half of minimumTotalValue");
        unsuccessfulFee = _newUnsuccessfulFee;
        emit UnsuccessfulFeeUpdated(_newUnsuccessfulFee);
    }

     
     
     
     
     
    function setMinimumPriceIncrement(uint256 _newMinimumPriceIncrement) external onlyCOO whenNotFrozen {
        _setMinimumPriceIncrement(_newMinimumPriceIncrement);
        emit MinimumPriceIncrementUpdated(_newMinimumPriceIncrement);
    }

     
     
     
     
     
     
     
     
     
    function _setMinimumTotalValue(uint256 _newMinTotal, uint256 _unsuccessfulFee) internal {
        require(_newMinTotal >= (2 * _unsuccessfulFee), "minimum value must be >= 2 * unsuccessful fee");
        minimumTotalValue = _newMinTotal;
    }

     
     
    function _setOfferCut(uint256 _newOfferCut) internal {
        require(_newOfferCut <= 1e4, "offer cut must be a valid basis point");
        offerCut = _newOfferCut;
    }

     
     
    function _setMinimumPriceIncrement(uint256 _newMinimumPriceIncrement) internal {
        require(_newMinimumPriceIncrement <= 1e4, "minimum price increment must be a valid basis point");
        minimumPriceIncrement = _newMinimumPriceIncrement;
    }
}

 
 
contract OffersBase is OffersConfig {
     

     
     
     
     
     
     
     
     
    event OfferCreated(
        uint256 tokenId,
        address bidder,
        uint256 expiresAt,
        uint256 total,
        uint256 offerPrice
    );

     
     
     
     
     
    event OfferCancelled(
        uint256 tokenId,
        address bidder,
        uint256 bidderReceived,
        uint256 fee
    );

     
     
     
     
     
     
     
    event OfferFulfilled(
        uint256 tokenId,
        address bidder,
        address owner,
        uint256 ownerReceived,
        uint256 fee
    );

     
     
     
     
     
     
     
    event OfferUpdated(
        uint256 tokenId,
        address bidder,
        uint256 newExpiresAt,
        uint256 totalRaised
    );

     
     
     
     
     
     
    event ExpiredOfferRemoved(
      uint256 tokenId,
      address bidder,
      uint256 bidderReceived,
      uint256 fee
    );

     
     
     
     
     
    event BidderWithdrewFundsWhenFrozen(
        uint256 tokenId,
        address bidder,
        uint256 amount
    );


     
     
     
     
     
    event PushFundsFailed(
        uint256 tokenId,
        address to,
        uint256 amount
    );

     

     
    struct Offer {
         
        uint64 expiresAt;
         
        address bidder;
         
         
         
         
        uint16 offerCut;
         
        uint128 total;
         
         
         
        uint128 unsuccessfulFee;
    }

     
     
     
     
    mapping (uint256 => Offer) public tokenIdToOffer;

     
     
     
     
     
     
     
    function _computeMinimumOverbidPrice(uint256 _offerPrice) internal view returns (uint256) {
        return _offerPrice * (1e4 + minimumPriceIncrement) / 1e4;
    }

     
     
     
     
     
     
    function _computeOfferPrice(uint256 _total, uint256 _offerCut) internal pure returns (uint256) {
        return _total * 1e4 / (1e4 + _offerCut);
    }

     
     
     
     
     
     
     
    function _offerExists(uint256 _expiresAt) internal pure returns (bool) {
        return _expiresAt > 0;
    }

     
     
     
     
     
    function _isOfferActive(uint256 _expiresAt) internal view returns (bool) {
        return now < _expiresAt;
    }

     
     
     
     
     
     
     
    function _tryPushFunds(uint256 _tokenId, address _to, uint256 _amount) internal {
         
         
        bool success = _to.send(_amount);
        if (!success) {
             
             
            totalLostAndFoundBalance = totalLostAndFoundBalance + _amount;

             
            emit PushFundsFailed(_tokenId, _to, _amount);
        }
    }
}

 
 
 
contract Offers is OffersBase {

     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     

     
     
     
    bytes4 constant InterfaceSignature_ERC721 = bytes4(0x9a20483d);

     
    ERC721 public nonFungibleContract;

     
     
     
     
     
     
     
     
    constructor(
      address _nftAddress,
      address _cooAddress,
      uint256 _globalDuration,
      uint256 _minimumTotalValue,
      uint256 _minimumPriceIncrement,
      uint256 _unsuccessfulFee,
      uint256 _offerCut
    ) public {
         
        ceoAddress = msg.sender;

         
        ERC721 candidateContract = ERC721(_nftAddress);
        require(candidateContract.supportsInterface(InterfaceSignature_ERC721), "NFT Contract needs to support ERC721 Interface");
        nonFungibleContract = candidateContract;

        setCOO(_cooAddress);

         
        globalDuration = _globalDuration;
        unsuccessfulFee = _unsuccessfulFee;
        _setOfferCut(_offerCut);
        _setMinimumPriceIncrement(_minimumPriceIncrement);
        _setMinimumTotalValue(_minimumTotalValue, _unsuccessfulFee);
    }

     
     
     
     
     
     
     
     
     
    function createOffer(uint256 _tokenId) external payable whenNotFrozen {
         
         
        require(msg.value >= minimumTotalValue, "offer total value must be above minimumTotalValue");

        uint256 _offerCut = offerCut;

         
        uint256 offerPrice = _computeOfferPrice(msg.value, _offerCut);

        Offer storage previousOffer = tokenIdToOffer[_tokenId];
        uint256 previousExpiresAt = previousOffer.expiresAt;

        uint256 toRefund = 0;

         
        if (_offerExists(previousExpiresAt)) {
            uint256 previousOfferTotal = uint256(previousOffer.total);

             
             
             
             
             
            if (_isOfferActive(previousExpiresAt)) {
                uint256 previousPriceForOwner = _computeOfferPrice(previousOfferTotal, uint256(previousOffer.offerCut));
                uint256 minimumOverbidPrice = _computeMinimumOverbidPrice(previousPriceForOwner);
                require(offerPrice >= minimumOverbidPrice, "overbid price must match minimum price increment criteria");
            }

            uint256 cfoEarnings = previousOffer.unsuccessfulFee;
             
             
            toRefund = previousOfferTotal - cfoEarnings;

            totalCFOEarnings += cfoEarnings;
        }

        uint256 newExpiresAt = now + globalDuration;

         
         
        address previousBidder;
        if (toRefund > 0) {
            previousBidder = previousOffer.bidder;
        }

        tokenIdToOffer[_tokenId] = Offer(
            uint64(newExpiresAt),
            msg.sender,
            uint16(_offerCut),
            uint128(msg.value),
            uint128(unsuccessfulFee)
        );

         
        if (toRefund > 0) {
             
             
            _tryPushFunds(
                _tokenId,
                previousBidder,
                toRefund
            );
        }

        emit OfferCreated(
            _tokenId,
            msg.sender,
            newExpiresAt,
            msg.value,
            offerPrice
        );
    }

     
     
     
     
    function cancelOffer(uint256 _tokenId) external whenNotFrozen {
         
        Offer storage offer = tokenIdToOffer[_tokenId];
        uint256 expiresAt = offer.expiresAt;
        require(_offerExists(expiresAt), "offer to cancel must exist");
        require(_isOfferActive(expiresAt), "offer to cancel must not be expired");

        address bidder = offer.bidder;
        require(msg.sender == bidder, "caller must be bidder of offer to be cancelled");

         
        uint256 total = uint256(offer.total);
         
        uint256 toRefund = _computeOfferPrice(total, offer.offerCut);
        uint256 cfoEarnings = total - toRefund;

         
        delete tokenIdToOffer[_tokenId];

         
        totalCFOEarnings += cfoEarnings;

         
        _tryPushFunds(_tokenId, bidder, toRefund);

        emit OfferCancelled(
            _tokenId,
            bidder,
            toRefund,
            cfoEarnings
        );
    }

     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
    function fulfillOffer(uint256 _tokenId, uint128 _minOfferPrice) external whenNotFrozen {
         
        Offer storage offer = tokenIdToOffer[_tokenId];
        uint256 expiresAt = offer.expiresAt;
        require(_offerExists(expiresAt), "offer to fulfill must exist");
        require(_isOfferActive(expiresAt), "offer to fulfill must not be expired");

         
        address owner = nonFungibleContract.ownerOf(_tokenId);

        require(msg.sender == cooAddress || msg.sender == owner, "only COO or the owner can fulfill order");

         
        uint256 total = uint256(offer.total);
         
        uint256 offerPrice = _computeOfferPrice(total, offer.offerCut);

         
        require(offerPrice >= _minOfferPrice, "cannot fulfill offer – offer price too low");

         
        address bidder = offer.bidder;

         
        delete tokenIdToOffer[_tokenId];

         
        nonFungibleContract.transferFrom(owner, bidder, _tokenId);

         
         
        uint256 cfoEarnings = total - offerPrice;
        totalCFOEarnings += cfoEarnings;

         
        _tryPushFunds(_tokenId, owner, offerPrice);

        emit OfferFulfilled(
            _tokenId,
            bidder,
            owner,
            offerPrice,
            cfoEarnings
        );
    }

     
     
     
     
     
    function batchRemoveExpired(uint256[] _tokenIds) external whenNotFrozen {
        uint256 len = _tokenIds.length;

         
        uint256 cumulativeCFOEarnings = 0;

        for (uint256 i = 0; i < len; i++) {
            uint256 tokenId = _tokenIds[i];
            Offer storage offer = tokenIdToOffer[tokenId];
            uint256 expiresAt = offer.expiresAt;

             
            if (!_offerExists(expiresAt)) {
                continue;
            }
             
            if (_isOfferActive(expiresAt)) {
                continue;
            }

             
            address bidder = offer.bidder;

             
            uint256 cfoEarnings = uint256(offer.unsuccessfulFee);

             
            uint256 toRefund = uint256(offer.total) - cfoEarnings;

             
            delete tokenIdToOffer[tokenId];

             
            cumulativeCFOEarnings += cfoEarnings;

             
             
            _tryPushFunds(
                tokenId,
                bidder,
                toRefund
            );

            emit ExpiredOfferRemoved(
                tokenId,
                bidder,
                toRefund,
                cfoEarnings
            );
        }

         
        if (cumulativeCFOEarnings > 0) {
            totalCFOEarnings += cumulativeCFOEarnings;
        }
    }

     
     
     
     
     
     
     
    function updateOffer(uint256 _tokenId) external payable whenNotFrozen {
         
        Offer storage offer = tokenIdToOffer[_tokenId];
        uint256 expiresAt = uint256(offer.expiresAt);
        require(_offerExists(expiresAt), "offer to update must exist");
        require(_isOfferActive(expiresAt), "offer to update must not be expired");

        require(msg.sender == offer.bidder, "caller must be bidder of offer to be updated");

        uint256 newExpiresAt = now + globalDuration;

         
        if (msg.value > 0) {
             
            offer.total += uint128(msg.value);
        }

        offer.expiresAt = uint64(newExpiresAt);

        emit OfferUpdated(_tokenId, msg.sender, newExpiresAt, msg.value);

    }

     
     
     
     
     
    function bidderWithdrawFunds(uint256 _tokenId) external whenFrozen {
         
        Offer storage offer = tokenIdToOffer[_tokenId];
        require(_offerExists(offer.expiresAt), "offer to withdraw funds from must exist");
        require(msg.sender == offer.bidder, "only bidders can withdraw their funds in escrow");

         
        uint256 total = uint256(offer.total);

        delete tokenIdToOffer[_tokenId];

         
        msg.sender.transfer(total);

        emit BidderWithdrewFundsWhenFrozen(_tokenId, msg.sender, total);
    }

     
    function() external payable {
        revert("we don't accept any payments!");
    }
}