 

pragma solidity ^0.4.18;

contract TittyBase {

    event Transfer(address indexed from, address indexed to);
    event Creation(address indexed from, uint256 tittyId, uint256 wpId);
    event AddAccessory(uint256 tittyId, uint256 accessoryId);

    struct Accessory {

        uint256 id;
        string name;
        uint256 price;
        bool isActive;

    }

    struct Titty {

        uint256 id;
        string name;
        string gender;
        uint256 originalPrice;
        uint256 salePrice;
        uint256[] accessories;
        bool forSale;
    }

     
    Titty[] Titties;
    Accessory[] Accessories;
    mapping (uint256 => address) public tittyIndexToOwner;
    mapping (address => uint256) public ownerTittiesCount;
    mapping (uint256 => address) public tittyApproveIndex;

    function _transfer(address _from, address _to, uint256 _tittyId) internal {

        ownerTittiesCount[_to]++;

        tittyIndexToOwner[_tittyId] = _to;
        if (_from != address(0)) {
            ownerTittiesCount[_from]--;
            delete tittyApproveIndex[_tittyId];
        }

        Transfer(_from, _to);

    }

    function _changeTittyPrice (uint256 _newPrice, uint256 _tittyId) internal {

        require(tittyIndexToOwner[_tittyId] == msg.sender);
        Titty storage _titty = Titties[_tittyId];
        _titty.salePrice = _newPrice;

        Titties[_tittyId] = _titty;
    }

    function _setTittyForSale (bool _forSale, uint256 _tittyId) internal {

        require(tittyIndexToOwner[_tittyId] == msg.sender);
        Titty storage _titty = Titties[_tittyId];
        _titty.forSale = _forSale;

        Titties[_tittyId] = _titty;
    }

    function _changeName (string _name, uint256 _tittyId) internal {

        require(tittyIndexToOwner[_tittyId] == msg.sender);
        Titty storage _titty = Titties[_tittyId];
        _titty.name = _name;

        Titties[_tittyId] = _titty;
    }

    function addAccessory (uint256 _id, string _name, uint256 _price, uint256 tittyId ) internal returns (uint) {

        Accessory memory _accessory = Accessory({

            id: _id,
            name: _name,
            price: _price,
            isActive: true

        });

        Titty storage titty = Titties[tittyId];
        uint256 newAccessoryId = Accessories.push(_accessory) - 1;
        titty.accessories.push(newAccessoryId);
        AddAccessory(tittyId, newAccessoryId);

        return newAccessoryId;

    }

    function totalAccessories(uint256 _tittyId) public view returns (uint256) {

        Titty storage titty = Titties[_tittyId];
        return titty.accessories.length;

    }

    function getAccessory(uint256 _tittyId, uint256 _aId) public view returns (uint256 id, string name,  uint256 price, bool active) {

        Titty storage titty = Titties[_tittyId];
        uint256 accId = titty.accessories[_aId];
        Accessory storage accessory = Accessories[accId];
        id = accessory.id;
        name = accessory.name;
        price = accessory.price;
        active = accessory.isActive;

    }

    function createTitty (uint256 _id, string _gender, uint256 _price, address _owner, string _name) internal returns (uint) {
        
        Titty memory _titty = Titty({
            id: _id,
            name: _name,
            gender: _gender,
            originalPrice: _price,
            salePrice: _price,
            accessories: new uint256[](0),
            forSale: false
        });

        uint256 newTittyId = Titties.push(_titty) - 1;

        Creation(
            _owner,
            newTittyId,
            _id
        );

        _transfer(0, _owner, newTittyId);
        return newTittyId;
    }

    

}


 
 
contract ERC721 {
    function implementsERC721() public pure returns (bool);
    function totalSupply() public view returns (uint256 total);
    function balanceOf(address _owner) public view returns (uint256 balance);
    function ownerOf(uint256 _tokenId) public view returns (address owner);
    function approve(address _to, uint256 _tokenId) public;
    function transferFrom(address _from, address _to, uint256 _tokenId) public;
    function transfer(address _to, uint256 _tokenId) public;
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);

     
     
     
     
     
}








contract TittyOwnership is TittyBase, ERC721 {

    string public name = "CryptoTittes";
    string public symbol = "CT";

    function implementsERC721() public pure returns (bool) {
        return true;
    }

    function _isOwner(address _user, uint256 _tittyId) internal view returns (bool) {
        return tittyIndexToOwner[_tittyId] == _user;
    }

    function _approve(uint256 _tittyId, address _approved) internal {
         tittyApproveIndex[_tittyId] = _approved; 
    }

    function _approveFor(address _user, uint256 _tittyId) internal view returns (bool) {
         return tittyApproveIndex[_tittyId] == _user; 
    }

    function totalSupply() public view returns (uint256 total) {
        return Titties.length - 1;
    }

    function balanceOf(address _owner) public view returns (uint256 balance) {
        return ownerTittiesCount[_owner];
    }
    
    function ownerOf(uint256 _tokenId) public view returns (address owner) {
        owner = tittyIndexToOwner[_tokenId];
        require(owner != address(0));
    }

    function approve(address _to, uint256 _tokenId) public {
        require(_isOwner(msg.sender, _tokenId));
        _approve(_tokenId, _to);
        Approval(msg.sender, _to, _tokenId);
    }

    function transferFrom(address _from, address _to, uint256 _tokenId) public {
        require(_approveFor(msg.sender, _tokenId));
        require(_isOwner(_from, _tokenId));

        _transfer(_from, _to, _tokenId);
        

    }
    function transfer(address _to, uint256 _tokenId) public {
        require(_to != address(0));
        require(_isOwner(msg.sender, _tokenId));

        _transfer(msg.sender, _to, _tokenId);
    }



}

contract TittyPurchase is TittyOwnership {

    address private wallet;
    address private boat;

    function TittyPurchase(address _wallet, address _boat) public {
        wallet = _wallet;
        boat = _boat;

        createTitty(0, "unissex", 1000000000, address(0), "genesis");
    }

    function purchaseNew(uint256 _id, string _name, string _gender, uint256 _price) public payable {

        if (msg.value == 0 && msg.value != _price)
            revert();

        uint256 boatFee = calculateBoatFee(msg.value);
        createTitty(_id, _gender, _price, msg.sender, _name);
        wallet.transfer(msg.value - boatFee);
        boat.transfer(boatFee);

    }

    function purchaseExistent(uint256 _tittyId) public payable {

        Titty storage titty = Titties[_tittyId];
        uint256 fee = calculateFee(titty.salePrice);
        if (msg.value == 0 && msg.value != titty.salePrice)
            revert();
        
        uint256 val = msg.value - fee;
        address owner = tittyIndexToOwner[_tittyId];
        _approve(_tittyId, msg.sender);
        transferFrom(owner, msg.sender, _tittyId);
        owner.transfer(val);
        wallet.transfer(fee);

    }

    function purchaseAccessory(uint256 _tittyId, uint256 _accId, string _name, uint256 _price) public payable {

        if (msg.value == 0 && msg.value != _price)
            revert();

        wallet.transfer(msg.value);
        addAccessory(_accId, _name, _price,  _tittyId);
        
        
    }

    function getAmountOfTitties() public view returns(uint) {
        return Titties.length;
    }

    function getLatestId() public view returns (uint) {
        return Titties.length - 1;
    }

    function getTittyByWpId(address _owner, uint256 _wpId) public view returns (bool own, uint256 tittyId) {
        
        for (uint256 i = 1; i<=totalSupply(); i++) {
            Titty storage titty = Titties[i];
            bool isOwner = _isOwner(_owner, i);
            if (titty.id == _wpId && isOwner) {
                return (true, i);
            }
        }
        
        return (false, 0);
    }

    function belongsTo(address _account, uint256 _tittyId) public view returns (bool) {
        return _isOwner(_account, _tittyId);
    }

    function changePrice(uint256 _price, uint256 _tittyId) public {
        _changeTittyPrice(_price, _tittyId);
    }

    function changeName(string _name, uint256 _tittyId) public {
        _changeName(_name, _tittyId);
    }

    function makeItSellable(uint256 _tittyId) public {
        _setTittyForSale(true, _tittyId);
    }

    function calculateFee (uint256 _price) internal pure returns(uint) {
        return (_price * 10)/100;
    }

    function calculateBoatFee (uint256 _price) internal pure returns(uint) {
        return (_price * 25)/100;
    }

    function() external {}

    function getATitty(uint256 _tittyId)
        public 
        view 
        returns (
        uint256 id,
        string name,
        string gender,
        uint256 originalPrice,
        uint256 salePrice,
        bool forSale
        ) {

            Titty storage titty = Titties[_tittyId];
            id = titty.id;
            name = titty.name;
            gender = titty.gender;
            originalPrice = titty.originalPrice;
            salePrice = titty.salePrice;
            forSale = titty.forSale;
        }

}

contract CTAuction {

    struct Auction {
         
         
         
        uint auctionEnd;

         
        address highestBidder;
        uint highestBid;

         
        uint minimumBid;

         
        bool ended;

         
        uint titty;

         
        address beneficiary;

         
        uint buyNowPrice;
    }

    Auction[] Auctions;

    address public owner; 
    address public ctWallet; 
    address public tittyContractAddress;

     
    mapping(address => uint) pendingReturns;

     
    TittyPurchase public tittyContract;

     
    event HighestBidIncreased(uint auction, address bidder, uint amount);
    event AuctionEnded(address winner, uint amount);
    event BuyNow(address buyer, uint amount);
    event AuctionCancel(uint auction);
    event NewAuctionCreated(uint auctionId, uint titty);
    event DidNotFinishYet(uint time, uint auctionTime);
    event NotTheContractOwner(address owner, address sender);

     
     
     
     

     
     
     
    function CTAuction(
        address _tittyPurchaseAddress,
        address _wallet
    ) public 
    {   
        tittyContractAddress = _tittyPurchaseAddress;
        tittyContract = TittyPurchase(_tittyPurchaseAddress);
        ctWallet = _wallet;
        owner = msg.sender; 
    }

    function createAuction(uint _biddingTime, uint _titty, uint _minimumBid, uint _buyNowPrice) public {

        address ownerAddress = tittyContract.ownerOf(_titty);
        require(msg.sender == ownerAddress);

        Auction memory auction = Auction({
            auctionEnd: now + _biddingTime,
            titty: _titty,
            beneficiary: msg.sender,
            highestBidder: 0,
            highestBid: 0,
            ended: false,
            minimumBid: _minimumBid,
            buyNowPrice: _buyNowPrice
        });

        uint auctionId = Auctions.push(auction) - 1;
        NewAuctionCreated(auctionId, _titty);
    }

    function getTittyOwner(uint _titty) public view returns (address) {
        address ownerAddress = tittyContract.ownerOf(_titty);
        return ownerAddress;
    } 

     
     
     
     
    function bid(uint _auction) public payable {

        Auction memory auction = Auctions[_auction];

         
         
        require(now <= auction.auctionEnd);

         
        require(msg.value >= auction.minimumBid);

         
         
        require(msg.value > auction.highestBid);

        if (auction.highestBid != 0) {
             
             
             
             
             
            pendingReturns[auction.highestBidder] += auction.highestBid;
        }
        auction.highestBidder = msg.sender;
        auction.highestBid = msg.value;
        Auctions[_auction] = auction;
        HighestBidIncreased(_auction, msg.sender, msg.value);
    }

    function buyNow(uint _auction) public payable {

        Auction memory auction = Auctions[_auction];

        require(now >= auction.auctionEnd);  
        require(!auction.ended);  

         
        require(msg.value == auction.buyNowPrice);

         
        require(auction.highestBid == 0);

         
        auction.ended = true;
        Auctions[_auction] = auction;
        BuyNow(msg.sender, msg.value);

         
        tittyContract.transferFrom(auction.beneficiary, msg.sender, auction.titty);
        uint fee = calculateFee(msg.value);
        ctWallet.transfer(fee);
        auction.beneficiary.transfer(msg.value-fee);
    }

     
    function withdraw() public returns (bool) {
        uint amount = pendingReturns[msg.sender];
        require(amount > 0);
         
         
         
        pendingReturns[msg.sender] = 0;

        if (!msg.sender.send(amount)) {
             
            pendingReturns[msg.sender] = amount;
            return false;
        }
        
        return true;
    }

    function auctionCancel(uint _auction) public {

        Auction memory auction = Auctions[_auction];

         
        require(msg.sender == auction.beneficiary);

         
        require(now >= auction.auctionEnd);

         
        require(auction.highestBid == 0);

        auction.ended = true;
        Auctions[_auction] = auction;
        AuctionCancel(_auction);

    }

     
     
    function auctionEnd(uint _auction) public {

         
        require (owner == msg.sender);

        Auction memory auction = Auctions[_auction];

        require (now >= auction.auctionEnd);  
        require(!auction.ended);  

         
        auction.ended = true;
        Auctions[_auction] = auction;
        AuctionEnded(auction.highestBidder, auction.highestBid);
        if (auction.highestBid != 0) {
             
            tittyContract.transferFrom(auction.beneficiary, auction.highestBidder, auction.titty);
            uint fee = calculateFee(auction.highestBid);
            ctWallet.transfer(fee);
            auction.beneficiary.transfer(auction.highestBid-fee);
        }

    }

    function getAuctionInfo(uint _auction) public view returns (uint end, address beneficiary, uint maxBid, address maxBidder) {

        Auction storage auction = Auctions[_auction];

        end = auction.auctionEnd;
        beneficiary = auction.beneficiary;
        maxBid = auction.highestBid;
        maxBidder = auction.highestBidder;
    }

    function calculateFee (uint256 _price) internal pure returns(uint) {
        return (_price * 10)/100;
    }
}