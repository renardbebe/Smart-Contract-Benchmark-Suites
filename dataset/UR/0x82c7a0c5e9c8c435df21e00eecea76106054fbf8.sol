 

pragma solidity ^0.4.18;

contract KimAccessControl {
   
  address public ceoAddress;
  address public cfoAddress;
  address public cooAddress;


   
  modifier onlyCEO() {
      require(msg.sender == ceoAddress);
      _;
  }

   
  modifier onlyCFO() {
      require(msg.sender == cfoAddress);
      _;
  }

   
  modifier onlyCOO() {
      require(msg.sender == cooAddress);
      _;
  }

   
   
  function setCEO(address _newCEO) external onlyCEO {
      require(_newCEO != address(0));

      ceoAddress = _newCEO;
  }

   
   
  function setCFO(address _newCFO) external onlyCEO {
      require(_newCFO != address(0));

      cfoAddress = _newCFO;
  }

   
   
  function setCOO(address _newCOO) external onlyCEO {
      require(_newCOO != address(0));

      cooAddress = _newCOO;
  }


}



contract KimContract is KimAccessControl{

   
   
  string public name;
  string public symbol;
   
  uint256 public totalSupply;
   
  uint256 public kimsCreated;
   
  uint256 public kimsOnAuction;
   
  uint256 public sellerCut;
   
  uint constant feeDivisor = 100;

   
  mapping (address => uint256) public balanceOf;
   
  mapping (uint => address) public tokenToOwner;
   
  mapping (uint256 => TokenAuction) public tokenAuction;
   
  mapping (address => uint) public pendingWithdrawals;

   
  event Transfer(address indexed from, address indexed to, uint256 value);
  event TokenAuctionCreated(uint256 tokenIndex, address seller, uint256 sellPrice);
  event TokenAuctionCompleted(uint256 tokenIndex, address seller, address buyer, uint256 sellPrice);
  event Withdrawal(address to, uint256 amount);

   
  function KimContract() public {
     
    ceoAddress = msg.sender;
     
    cooAddress = msg.sender;
     
    totalSupply = 5000;
     
    balanceOf[this] = totalSupply;               
     
    name = "KimJongCrypto";
    symbol = "KJC";
     
    sellerCut = 95;
  }

   
  struct TokenAuction {
    bool isForSale;
    uint256 tokenIndex;
    address seller;
    uint256 sellPrice;
    uint256 startedAt;
  }


   
   
   
   
  function releaseSomeKims(uint256 howMany) external onlyCOO {
     
     
    uint256 marketAverage = averageKimSalePrice();
    for(uint256 counter = 0; counter < howMany; counter++) {
       
      tokenToOwner[counter] = this;
       
      _tokenAuction(kimsCreated, this, marketAverage);
       
      kimsCreated++;
    }
  }


   
   
  function sellToken(uint256 tokenIndex, uint256 sellPrice) public {
     
    TokenAuction storage tokenOnAuction = tokenAuction[tokenIndex];
     
    address seller = msg.sender;
     
    require(_owns(seller, tokenIndex));
     
    require(tokenOnAuction.isForSale == false);
     
    _tokenAuction(tokenIndex, seller, sellPrice);
  }


   
  function _tokenAuction(uint256 tokenIndex, address seller, uint256 sellPrice) internal {
     
    tokenAuction[tokenIndex] = TokenAuction(true, tokenIndex, seller, sellPrice, now);
     
    TokenAuctionCreated(tokenIndex, seller, sellPrice);
     
    kimsOnAuction++;
  }

   
   
  function buyKim(uint256 tokenIndex) public payable {
     
    TokenAuction storage tokenOnAuction = tokenAuction[tokenIndex];
     
    uint256 sellPrice = tokenOnAuction.sellPrice;
     
    require(tokenOnAuction.isForSale == true);
     
    require(msg.value >= sellPrice);
     
    address seller = tokenOnAuction.seller;
     
    address buyer = msg.sender;
     
     
    _completeAuction(tokenIndex, seller, buyer, sellPrice);
  }



   
  function _completeAuction(uint256 tokenIndex, address seller, address buyer, uint256 sellPrice) internal {
     
    address thisContract = this;
     
    uint256 auctioneerCut = _computeCut(sellPrice);
     
    uint256 sellerProceeds = sellPrice - auctioneerCut;
     
    if (seller == thisContract) {
       
      pendingWithdrawals[seller] += sellerProceeds + auctioneerCut;
       
      tokenAuction[tokenIndex] = TokenAuction(false, tokenIndex, 0, 0, 0);
       
      TokenAuctionCompleted(tokenIndex, seller, buyer, sellPrice);
    } else {  
       
      pendingWithdrawals[seller] += sellerProceeds;
       
      pendingWithdrawals[this] += auctioneerCut;
       
      tokenAuction[tokenIndex] = TokenAuction(false, tokenIndex, 0, 0, 0);
       
      TokenAuctionCompleted(tokenIndex, seller, buyer, sellPrice);
    }
    _transfer(seller, buyer, tokenIndex);
    kimsOnAuction--;
  }


   
   
  function cancelKimAuction(uint kimIndex) public {
    require(_owns(msg.sender, kimIndex));
     
    TokenAuction storage tokenOnAuction = tokenAuction[kimIndex];
     
    require(tokenOnAuction.isForSale == true);
     
    tokenAuction[kimIndex] = TokenAuction(false, kimIndex, 0, 0, 0);
  }








   
   
   
  function _computeCut(uint256 sellPrice) internal view returns (uint) {
    return sellPrice * sellerCut / 1000;
  }





 
  function _transfer(address _from, address _to, uint _value) internal {
       
      require(_to != 0x0);
       
      balanceOf[_from]--;
       
      balanceOf[_to]++;
       
      tokenToOwner[_value] = _to;
      Transfer(_from, _to, 1);
  }



   
    
  function transfer(address _to, uint256 _value) public {
      require(_owns(msg.sender, _value));
      _transfer(msg.sender, _to, _value);
  }


   
  function _owns(address _claimant, uint256 _tokenId) internal view returns (bool) {
    return tokenToOwner[_tokenId] == _claimant;
  }


   
   
  function averageKimSalePrice() public view returns (uint256) {
    uint256 sumOfAllKimAuctions = 0;
    if (kimsOnAuction == 0){
      return 0;
      } else {
        for (uint256 i = 0; i <= kimsOnAuction; i++) {
          sumOfAllKimAuctions += tokenAuction[i].sellPrice;
        }
        return sumOfAllKimAuctions / kimsOnAuction;
      }
  }



   
  function withdraw() {
      uint amount = pendingWithdrawals[msg.sender];
      require(amount > 0);
       
       
      pendingWithdrawals[msg.sender] = 0;
      msg.sender.transfer(amount);
      Withdrawal(msg.sender, amount);
  }



   
  function withdrawBalance() external onlyCFO {
      uint balance = pendingWithdrawals[this];
      pendingWithdrawals[this] = 0;
      cfoAddress.transfer(balance);
      Withdrawal(cfoAddress, balance);
  }






}