 

pragma solidity ^0.4.18;


 
library SafeMath {

   
  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    if (a == 0) {
      return 0;
    }
    uint256 c = a * b;
    assert(c / a == b);
    return c;
  }

   
  function div(uint256 a, uint256 b) internal pure returns (uint256) {
     
    uint256 c = a / b;
     
    return c;
  }

   
  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    assert(b <= a);
    return a - b;
  }

   
  function add(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    assert(c >= a);
    return c;
  }
}



 
contract Ownable {
  address public owner;


  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);


   
  function Ownable() public {
    owner = msg.sender;
  }

   
  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }

   
  function transferOwnership(address newOwner) public onlyOwner {
    require(newOwner != address(0));
   OwnershipTransferred(owner, newOwner);
    owner = newOwner;
  }

}

 
contract Pausable is Ownable {
  event Pause();
  event Unpause();

  bool public paused = false;


   
  modifier whenNotPaused() {
    require(!paused);
    _;
  }

   
  modifier whenPaused() {
    require(paused);
    _;
  }

   
  function pause() onlyOwner whenNotPaused public {
    paused = true;
    Pause();
  }

   
  function unpause() onlyOwner whenPaused public {
    paused = false;
    Unpause();
  }
}


 
contract ERC721 {
  event Transfer(address indexed _from, address indexed _to, uint256 _tokenId);
  event Approval(address indexed _owner, address indexed _approved, uint256 _tokenId);

  function balanceOf(address _owner) public view returns (uint256 _balance);
  function ownerOf(uint256 _tokenId) public view returns (address _owner);
  function transfer(address _to, uint256 _tokenId) public;
  function approve(address _to, uint256 _tokenId) public;
  function takeOwnership(uint256 _tokenId) public;
}


 
 
contract CelebrityMarket is Pausable{

    ERC721 ccContract;

     
    struct Sale {
         
        address seller;
         
        uint256 salePrice;
         
         
        uint64 startedAt;
    }

     
    address public owner;

     
    mapping (uint256 => Sale) tokenIdToSale;

    event SaleCreated(address seller,uint256 tokenId, uint256 salePrice, uint256 startedAt);
    event SaleSuccessful(address seller, uint256 tokenId, uint256 totalPrice, address winner);
    event SaleCancelled(address seller, uint256 tokenId);
    event SaleUpdated(address seller, uint256 tokenId, uint256 oldPrice, uint256 newPrice);
    
     
     
    function CelebrityMarket(address _ccAddress) public {
        ccContract = ERC721(_ccAddress);
        owner = msg.sender;
    }

     
    function() external {}


     
     
     
     
    function withdrawBalance() external {
        require(
            msg.sender == owner
        );
        msg.sender.transfer(address(this).balance);
    }

     
     
     
    function createSale(
        uint256 _tokenId,
        uint256 _salePrice
    )
        public
        whenNotPaused
    {
        require(_owns(msg.sender, _tokenId));
        _escrow(_tokenId);
        Sale memory sale = Sale(
            msg.sender,
            _salePrice,
            uint64(now)
        );
        _addSale(_tokenId, sale);
    }

     
     
     
     
     
    function updateSalePrice(uint256 _tokenId, uint256 _newPrice)
        public
    {
        Sale storage sale = tokenIdToSale[_tokenId];
        require(_isOnSale(sale));
        address seller = sale.seller;
        require(msg.sender == seller);
        _updateSalePrice(_tokenId, _newPrice, seller);
    }

     
     
     
    function buy(uint256 _tokenId)
        public
        payable
        whenNotPaused
    {
         
        _buy(_tokenId, msg.value);
        _transfer(msg.sender, _tokenId);
    }

     
     
     
     
     
    function cancelSale(uint256 _tokenId)
        public
    {
        Sale storage sale = tokenIdToSale[_tokenId];
        require(_isOnSale(sale));
        address seller = sale.seller;
        require(msg.sender == seller);
        _cancelSale(_tokenId, seller);
    }

     
     
     
     
    function cancelSaleWhenPaused(uint256 _tokenId)
        whenPaused
        onlyOwner
        public
    {
        Sale storage sale = tokenIdToSale[_tokenId];
        require(_isOnSale(sale));
        _cancelSale(_tokenId, sale.seller);
    }

     
     
    function getSale(uint256 _tokenId)
        public
        view
        returns
    (
        address seller,
        uint256 salePrice,
        uint256 startedAt
    ) {
        Sale storage sale = tokenIdToSale[_tokenId];
        require(_isOnSale(sale));
        return (
            sale.seller,
            sale.salePrice,
            sale.startedAt
        );
    }

     
     
    function getSalePrice(uint256 _tokenId)
        public
        view
        returns (uint256)
    {
        Sale storage sale = tokenIdToSale[_tokenId];
        require(_isOnSale(sale));
        return sale.salePrice;
    }

     
     
     
    function _owns(address _claimant, uint256 _tokenId) internal view returns (bool) {
        return (ccContract.ownerOf(_tokenId) == _claimant);
    }

     
     
     
    function _escrow(uint256 _tokenId) internal {
         
        ccContract.takeOwnership(_tokenId);
    }

     
     
     
     
    function _transfer(address _receiver, uint256 _tokenId) internal {
         
        ccContract.transfer(_receiver, _tokenId);
    }

     
     
     
     
    function _addSale(uint256 _tokenId, Sale _sale) internal {

        tokenIdToSale[_tokenId] = _sale;
        
        SaleCreated(
            address(_sale.seller),
            uint256(_tokenId),
            uint256(_sale.salePrice),
            uint256(_sale.startedAt)
        );
    }

     
    function _cancelSale(uint256 _tokenId, address _seller) internal {
        _removeSale(_tokenId);
        _transfer(_seller, _tokenId);
        SaleCancelled(_seller, _tokenId);
    }

     
    function _updateSalePrice(uint256 _tokenId, uint256 _newPrice, address _seller) internal {
         
        Sale storage sale = tokenIdToSale[_tokenId];
        uint256 oldPrice = sale.salePrice;
        sale.salePrice = _newPrice;
        SaleUpdated(_seller, _tokenId, oldPrice, _newPrice);
    }

     
     
    function _buy(uint256 _tokenId, uint256 _amount)
        internal
        returns (uint256)
    {
         
        Sale storage sale = tokenIdToSale[_tokenId];

         
         
         
         
        require(_isOnSale(sale));

         
         
        uint256 price = sale.salePrice;

        require(_amount >= price);

         
         
        address seller = sale.seller;

         
         
        _removeSale(_tokenId);

         
        if (price > 0) {
             
             
             
            uint256 ownerCut = _computeCut(price);
            uint256 sellerProceeds = price - ownerCut;

             
             
             
             
             
             
             
             
            seller.transfer(sellerProceeds);
        }

         
         
         
         
        uint256 amountExcess = _amount - price;

         
         
         
        msg.sender.transfer(amountExcess);

         
        SaleSuccessful(seller, _tokenId, price, msg.sender);

        return price;
    }

     
     
    function _removeSale(uint256 _tokenId) internal {
        delete tokenIdToSale[_tokenId];
    }

     
     
    function _isOnSale(Sale storage _sale) internal view returns (bool) {
        return (_sale.startedAt > 0);
    }

     
     
    function _computeCut(uint256 _price) internal pure returns (uint256) {
        return uint256(SafeMath.div(SafeMath.mul(_price, 6), 100));
    }

}