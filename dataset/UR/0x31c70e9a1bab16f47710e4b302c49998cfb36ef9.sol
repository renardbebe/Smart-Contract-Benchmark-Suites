 

pragma solidity 0.4.18;

 

contract Ownable {
  address public owner;


  function Ownable() public {
    owner = msg.sender;
  }


  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }

  function transferOwnership(address newOwner) external onlyOwner {
    require(newOwner != address(0));
    owner = newOwner;
  }

}


contract SketchMarket is Ownable {
   
  string public standard = "CryptoSketches";
  string public name;
  string public symbol;
  uint8 public decimals;
  uint256 public totalSupply;

  mapping (address => uint256) public balanceOf;

  event Transfer(address indexed from, address indexed to, uint256 value);
   

   
  mapping(uint256 => string)  public sketchIndexToName;
  mapping(uint256 => string)  public sketchIndexToData;
  mapping(uint256 => address) public sketchIndexToHolder;
  mapping(uint256 => address) public sketchIndexToAuthor;
  mapping(uint256 => uint8)   public sketchIndexToOwnerFlag;

  mapping(address => uint256) public sketchAuthorCount;

  event SketchCreated(address indexed author, uint256 indexed sketchIndex);
   

   

   
   
  uint256 public ownerCut;

   
  uint256 public listingFeeInWei;

  mapping (uint256 => Offer) public sketchIndexToOffer;
  mapping (uint256 => Bid) public sketchIndexToHighestBid;
  mapping (address => uint256) public accountToWithdrawableValue;

  event SketchTransfer(uint256 indexed sketchIndex, address indexed fromAddress, address indexed toAddress);
  event SketchOffered(uint256 indexed sketchIndex, uint256 minValue, address indexed toAddress);
  event SketchBidEntered(uint256 indexed sketchIndex, uint256 value, address indexed fromAddress);
  event SketchBidWithdrawn(uint256 indexed sketchIndex, uint256 value, address indexed fromAddress);
  event SketchBought(uint256 indexed sketchIndex, uint256 value, address indexed fromAddress, address indexed toAddress);
  event SketchNoLongerForSale(uint256 indexed sketchIndex);

  struct Offer {
    bool isForSale;
    uint256 sketchIndex;
    address seller;
    uint256 minValue;    
    address onlySellTo;  
  }

  struct Bid {
    bool hasBid;
    uint256 sketchIndex;
    address bidder;
    uint256 value;
  }
   

   

  function SketchMarket() public payable {
     
    totalSupply = 0;
    name = "CRYPTOSKETCHES";
    symbol = "S̈";
    decimals = 0;  

     
    ownerCut = 375;  
    listingFeeInWei = 5000000000000000;  
  }

  function setOwnerCut(uint256 _ownerCut) external onlyOwner {
    require(_ownerCut == uint256(uint16(_ownerCut)));
    require(_ownerCut <= 10000);
    ownerCut = _ownerCut;
  }

  function setListingFeeInWei(uint256 _listingFeeInWei) external onlyOwner {
    require(_listingFeeInWei == uint256(uint128(_listingFeeInWei)));  
    listingFeeInWei = _listingFeeInWei;
  }

   

  function createSketch(string _name, string _data) external payable {
    require(msg.value == listingFeeInWei);
    require(bytes(_name).length < 256);      
    require(bytes(_data).length < 1048576);  

    accountToWithdrawableValue[owner] += msg.value;  

    sketchIndexToHolder[totalSupply] = msg.sender;
    sketchIndexToAuthor[totalSupply] = msg.sender;
    sketchAuthorCount[msg.sender]++;

    sketchIndexToName[totalSupply] = _name;
    sketchIndexToData[totalSupply] = _data;

    balanceOf[msg.sender]++;

    SketchCreated(msg.sender, totalSupply);

    totalSupply++;
  }

  function setOwnerFlag(uint256 index, uint8 _ownerFlag) external onlyOwner {
    sketchIndexToOwnerFlag[index] = _ownerFlag;
  }

  function getSketch(uint256 index) external view returns (string _name, string _data, address _holder, address _author, uint8 _ownerFlag, uint256 _highestBidValue, uint256 _offerMinValue) {
    require(totalSupply != 0);
    require(index < totalSupply);

    _name = sketchIndexToName[index];
    _data = sketchIndexToData[index];
    _holder = sketchIndexToHolder[index];
    _author = sketchIndexToAuthor[index];
    _ownerFlag = sketchIndexToOwnerFlag[index];
    _highestBidValue = sketchIndexToHighestBid[index].value;
    _offerMinValue = sketchIndexToOffer[index].minValue;
  }

  function getBidCountForSketchesWithHolder(address _holder) external view returns (uint256) {
    uint256 count = balanceOf[_holder];

    if (count == 0) {
      return 0;
    } else {
      uint256 result = 0;
      uint256 totalCount = totalSupply;
      uint256 sketchIndex;

      for (sketchIndex = 0; sketchIndex <= totalCount; sketchIndex++) {
        if ((sketchIndexToHolder[sketchIndex] == _holder) && sketchIndexToHighestBid[sketchIndex].hasBid) {
          result++;
        }
      }
      return result;
    }
  }

  function getSketchesOnOffer() external view returns (uint256[]) {
    if (totalSupply == 0) {
      return new uint256[](0);
    }

    uint256 count = 0;
    uint256 totalCount = totalSupply;
    uint256 sketchIndex;

    for (sketchIndex = 0; sketchIndex <= totalCount; sketchIndex++) {
      if (sketchIndexToOffer[sketchIndex].isForSale) {
        count++;
      }
    }

    if (count == 0) {
      return new uint256[](0);
    }

    uint256[] memory result = new uint256[](count);
    uint256 resultIndex = 0;

    for (sketchIndex = 0; sketchIndex <= totalCount; sketchIndex++) {
      if (sketchIndexToOffer[sketchIndex].isForSale) {
        result[resultIndex] = sketchIndex;
        resultIndex++;
      }
    }
    return result;
  }

  function getSketchesOnOfferWithHolder(address _holder) external view returns (uint256[]) {
    if (totalSupply == 0) {
      return new uint256[](0);
    }

    uint256 count = 0;
    uint256 totalCount = totalSupply;
    uint256 sketchIndex;

    for (sketchIndex = 0; sketchIndex <= totalCount; sketchIndex++) {
      if (sketchIndexToOffer[sketchIndex].isForSale && (sketchIndexToHolder[sketchIndex] == _holder)) {
        count++;
      }
    }

    if (count == 0) {
      return new uint256[](0);
    }

    uint256[] memory result = new uint256[](count);
    uint256 resultIndex = 0;

    for (sketchIndex = 0; sketchIndex <= totalCount; sketchIndex++) {
      if (sketchIndexToOffer[sketchIndex].isForSale && (sketchIndexToHolder[sketchIndex] == _holder)) {
        result[resultIndex] = sketchIndex;
        resultIndex++;
      }
    }
    return result;
  }

  function getSketchesWithHolder(address _holder) external view returns (uint256[]) {
    uint256 count = balanceOf[_holder];

    if (count == 0) {
      return new uint256[](0);
    } else {
      uint256[] memory result = new uint256[](count);
      uint256 totalCount = totalSupply;
      uint256 resultIndex = 0;
      uint256 sketchIndex;

      for (sketchIndex = 0; sketchIndex <= totalCount; sketchIndex++) {
        if (sketchIndexToHolder[sketchIndex] == _holder) {
          result[resultIndex] = sketchIndex;
          resultIndex++;
        }
      }
      return result;
    }
  }

  function getSketchesWithAuthor(address _author) external view returns (uint256[]) {
    uint256 count = sketchAuthorCount[_author];

    if (count == 0) {
      return new uint256[](0);      
    } else {
      uint256[] memory result = new uint256[](count);
      uint256 totalCount = totalSupply;
      uint256 resultIndex = 0;
      uint256 sketchIndex;

      for (sketchIndex = 0; sketchIndex <= totalCount; sketchIndex++) {
        if (sketchIndexToAuthor[sketchIndex] == _author) {
          result[resultIndex] = sketchIndex;
          resultIndex++;
        }
      }
      return result;
    }
  }

   

  modifier onlyHolderOf(uint256 sketchIndex) {
    require(totalSupply != 0);
    require(sketchIndex < totalSupply);
    require(sketchIndexToHolder[sketchIndex] == msg.sender);
    _;
 }

   
  function transferSketch(address to, uint256 sketchIndex) external onlyHolderOf(sketchIndex) {
    require(to != address(0));
    require(balanceOf[msg.sender] > 0);

    if (sketchIndexToOffer[sketchIndex].isForSale) {
      sketchNoLongerForSale(sketchIndex);  
    }

    sketchIndexToHolder[sketchIndex] = to;
    balanceOf[msg.sender]--;
    balanceOf[to]++;

    Transfer(msg.sender, to, 1);  
    SketchTransfer(sketchIndex, msg.sender, to);

     
    Bid storage bid = sketchIndexToHighestBid[sketchIndex];
    if (bid.bidder == to) {
        accountToWithdrawableValue[to] += bid.value;
        sketchIndexToHighestBid[sketchIndex] = Bid(false, sketchIndex, 0x0, 0);
    }
  }

   
  function sketchNoLongerForSale(uint256 _sketchIndex) public onlyHolderOf(_sketchIndex) {
    sketchIndexToOffer[_sketchIndex] = Offer(false, _sketchIndex, msg.sender, 0, 0x0);
    SketchNoLongerForSale(_sketchIndex);
  }

   
  function offerSketchForSale(uint256 _sketchIndex, uint256 _minSalePriceInWei) public onlyHolderOf(_sketchIndex) {
    sketchIndexToOffer[_sketchIndex] = Offer(true, _sketchIndex, msg.sender, _minSalePriceInWei, 0x0);
    SketchOffered(_sketchIndex, _minSalePriceInWei, 0x0);
  }

   
  function offerSketchForSaleToAddress(uint256 _sketchIndex, uint256 _minSalePriceInWei, address _toAddress) public onlyHolderOf(_sketchIndex) {
    require(_toAddress != address(0));
    require(_toAddress != msg.sender);

    sketchIndexToOffer[_sketchIndex] = Offer(true, _sketchIndex, msg.sender, _minSalePriceInWei, _toAddress);
    SketchOffered(_sketchIndex, _minSalePriceInWei, _toAddress);
  }

   
  function acceptBidForSketch(uint256 sketchIndex, uint256 minPrice) public onlyHolderOf(sketchIndex) {
    address seller = msg.sender;    
    require(balanceOf[seller] > 0);

    Bid storage bid = sketchIndexToHighestBid[sketchIndex];
    uint256 price = bid.value;
    address bidder = bid.bidder;

    require(price > 0);
    require(price == uint256(uint128(price)));  
    require(minPrice == uint256(uint128(minPrice)));  
    require(price >= minPrice);  

    sketchIndexToHolder[sketchIndex] = bidder;  
    balanceOf[seller]--;  
    balanceOf[bidder]++;
    Transfer(seller, bidder, 1);

    sketchIndexToOffer[sketchIndex] = Offer(false, sketchIndex, bidder, 0, 0x0);  
    sketchIndexToHighestBid[sketchIndex] = Bid(false, sketchIndex, 0x0, 0);  

    uint256 ownerProceeds = computeCut(price);
    uint256 holderProceeds = price - ownerProceeds;

    accountToWithdrawableValue[seller] += holderProceeds;  
    accountToWithdrawableValue[owner] += ownerProceeds;    

    SketchBought(sketchIndex, price, seller, bidder);  
  }

   
  function buySketch(uint256 sketchIndex) external payable {      
    Offer storage offer = sketchIndexToOffer[sketchIndex];
    uint256 messageValue = msg.value;

    require(totalSupply != 0);
    require(sketchIndex < totalSupply);
    require(offer.isForSale);
    require(offer.onlySellTo == 0x0 || offer.onlySellTo == msg.sender);
    require(messageValue >= offer.minValue);
    require(messageValue == uint256(uint128(messageValue)));  
    require(offer.seller == sketchIndexToHolder[sketchIndex]);  

    address holder = offer.seller;
    require(balanceOf[holder] > 0);

    sketchIndexToHolder[sketchIndex] = msg.sender;  
    balanceOf[holder]--;  
    balanceOf[msg.sender]++;
    Transfer(holder, msg.sender, 1);

    sketchNoLongerForSale(sketchIndex);  

    uint256 ownerProceeds = computeCut(messageValue);
    uint256 holderProceeds = messageValue - ownerProceeds;

    accountToWithdrawableValue[owner] += ownerProceeds;
    accountToWithdrawableValue[holder] += holderProceeds;

    SketchBought(sketchIndex, messageValue, holder, msg.sender);

     
     
    Bid storage bid = sketchIndexToHighestBid[sketchIndex];
    if (bid.bidder == msg.sender) {
        accountToWithdrawableValue[msg.sender] += bid.value;
        sketchIndexToHighestBid[sketchIndex] = Bid(false, sketchIndex, 0x0, 0);  
    }
  }

   
   
   
  function withdraw() external {
      uint256 amount = accountToWithdrawableValue[msg.sender];
       
      accountToWithdrawableValue[msg.sender] = 0;
      msg.sender.transfer(amount);
  }

   
  function enterBidForSketch(uint256 sketchIndex) external payable {
      require(totalSupply != 0);
      require(sketchIndex < totalSupply);
      require(sketchIndexToHolder[sketchIndex] != 0x0);  
      require(sketchIndexToHolder[sketchIndex] != msg.sender);  

      uint256 price = msg.value;  

      require(price > 0);  
      require(price == uint256(uint128(price)));  

      Bid storage existing = sketchIndexToHighestBid[sketchIndex];

      require(price > existing.value);  

      if (existing.value > 0) {
           
          accountToWithdrawableValue[existing.bidder] += existing.value;
      }
      sketchIndexToHighestBid[sketchIndex] = Bid(true, sketchIndex, msg.sender, price);

      SketchBidEntered(sketchIndex, price, msg.sender);
  }

  function withdrawBidForSketch(uint256 sketchIndex) public {
    require(totalSupply != 0);
    require(sketchIndex < totalSupply);
    require(sketchIndexToHolder[sketchIndex] != 0x0);  
    require(sketchIndexToHolder[sketchIndex] != msg.sender);  
      
    Bid storage bid = sketchIndexToHighestBid[sketchIndex];
    require(bid.bidder == msg.sender);  

    SketchBidWithdrawn(sketchIndex, bid.value, msg.sender);

    uint256 amount = bid.value;
    sketchIndexToHighestBid[sketchIndex] = Bid(false, sketchIndex, 0x0, 0);

     
    msg.sender.transfer(amount);
  }

  function computeCut(uint256 price) internal view returns (uint256) {
     
     
     
     
    return price * ownerCut / 10000;
  }

}