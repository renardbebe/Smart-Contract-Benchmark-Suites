 

pragma solidity 0.5.2;

 
library SafeMath {

   
  function mul(uint256 a, uint256 b) internal pure returns (uint256 c) {
    if (a == 0) {
      return 0;
    }
    c = a * b;
    assert(c / a == b);
    return c;
  }

   
  function div(uint256 a, uint256 b) internal pure returns (uint256) {
     
     
     
    return a / b;
  }

   
  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    assert(b <= a);
    return a - b;
  }

   
  function add(uint256 a, uint256 b) internal pure returns (uint256 c) {
    c = a + b;
    assert(c >= a);
    return c;
  }
}

 
interface IERC20 {
  function totalSupply() external view returns (uint256);

  function balanceOf(address who) external view returns (uint256);

  function allowance(address owner, address spender)
    external view returns (uint256);

  function transfer(address to, uint256 value) external returns (bool);

  function approve(address spender, uint256 value)
    external returns (bool);

  function transferFrom(address from, address to, uint256 value)
    external returns (bool);

  event Transfer(
    address indexed from,
    address indexed to,
    uint256 value
  );

  event Approval(
    address indexed owner,
    address indexed spender,
    uint256 value
  );
}

contract PurchaseContract {
    
  using SafeMath for uint256;
  
  uint requestedProducts;
  
  address applicationAddress = 0x8eDE6C5CDfFd4C6a8e6Da2157A37CE45A0602dB0;

  IERC20 token;

  struct Product {
    uint id;
    uint price;
    uint unconfirmedRequests;
    address[] buyers;
    mapping (address => bool) isConfirmed;
    address retailer;
    address model;
  }

  Product[] products;
  
  event Purchase(uint _id, uint _price, address _buyer, address _retailer, address _model);
  
  constructor(address _tokenAddress) public {
    token = IERC20(_tokenAddress);
  }

  function addProduct(uint _productId, uint _price) public {
    require(_productId > 0);
    require(_price > 0);
    
    Product memory _product = findProductById(_productId);
    require(_product.id == 0);
    
    _product.id = _productId;
    _product.price = _price;
    _product.retailer = msg.sender;
    _product.model = address(0);
    
    products.push(_product);
    
  }

  function addProducts(uint[] calldata _productIds, uint[] calldata _prices) external {
    require(_productIds.length > 0);
    require(_prices.length > 0);
    require(_productIds.length == _prices.length);

    for(uint i = 0; i < _productIds.length; i++) {
      addProduct(_productIds[i], _prices[i]);
    }
  }
  
  function purchaseRequest(uint _productId) external {
    (Product memory _product, uint index) = findProductAndIndexById(_productId);
    require(_productId != 0 && _product.id == _productId);
    require(_product.price <= token.balanceOf(msg.sender));
    
    products[index] = _product;
    
    if(products[index].unconfirmedRequests == 0){
       requestedProducts = requestedProducts.add(1);
    }
    
    if(!isBuyerExist(index, msg.sender)) {
        products[index].unconfirmedRequests = products[index].unconfirmedRequests.add(1);
        products[index].buyers.push(msg.sender);
    } else if(products[index].isConfirmed[msg.sender]){
        products[index].unconfirmedRequests = products[index].unconfirmedRequests.add(1);
    }
    
    
    products[index].isConfirmed[msg.sender] = false;
  }
  
  function isBuyerExist(uint _index, address _buyer) internal view returns(bool) {
    
    for(uint y = 0; y < products[_index].buyers.length; y++) {
      if(products[_index].buyers[y] == _buyer) {
        return true;
      }
    }
    
    return false;
    
  }

  function getProductPrice(uint _productId) external view returns(uint) {
    Product memory _product = findProductById(_productId);
    return _product.price;
  }

  function getProductRetailer(uint _productId) external view returns(address) {
    Product memory _product = findProductById(_productId);
    return _product.retailer;
  }
  
  function getProductBuyers(uint _productId) public view returns(address[] memory) {
    Product memory _product = findProductById(_productId);
    return _product.buyers;
  }
  
  function getRequestedProducts() public view returns(uint[] memory) {
    uint index;
    uint[] memory results = new uint[](requestedProducts);
    for(uint i = 0; i < products.length; i++) {
        if(products[i].unconfirmedRequests > 0) {
            results[index] = products[i].id;
            index = index.add(1);
        }
    }
    return results;
  }
  
  function getRequestedProductsBy(address _buyer) public view returns(uint[] memory) {
    uint index;
    
    for(uint i = 0; i < products.length; i++) {
        if(products[i].unconfirmedRequests > 0 && isBuyerExist(i, _buyer) && products[i].isConfirmed[_buyer] == false) {
            index = index.add(1);
        }
    }
    
    uint[] memory results = new uint[](index);
    index = 0;
    
    for(uint i = 0; i < products.length; i++) {
        if(products[i].unconfirmedRequests > 0 && isBuyerExist(i, _buyer) && products[i].isConfirmed[_buyer] == false) {
            results[index] = products[i].id;
            index = index.add(1);
        }
    }
    return results;
  }
  
  function getProductBuyersWithUnconfirmedRequests(uint _productId) external view returns(address[] memory) {
    uint index;
    (Product memory _product, uint i) = findProductAndIndexById(_productId);
    address[] memory buyers = getProductBuyers(_productId);
    address[] memory results = new address[](_product.unconfirmedRequests);
    
    for(uint y = 0; y < buyers.length; y++) {
      if(!products[i].isConfirmed[buyers[y]]) {
        results[index] = buyers[y];
        index = index.add(1);
      }
    }
    
    return results;
  }
  
  function isClientPayed(uint _productId, address _client) external view returns(bool) {
    uint index = findProductIndexById(_productId);
    return products[index].isConfirmed[_client];
  }

  function confirmPurchase(uint _productId, address _buyer, address _model) external {
    require(_productId != 0);

    (Product memory _product, uint index) = findProductAndIndexById(_productId);
    
    require(msg.sender == _product.retailer && _product.buyers.length != 0 && isBuyerExist(index, _buyer) && !products[index].isConfirmed[_buyer] && token.allowance(_buyer, address(this)) >= _product.price); 
    
    _product.model = _model;

    token.transferFrom(_buyer, _product.retailer, _product.price.mul(90).div(100));
    token.transferFrom(_buyer, _product.model, _product.price.mul(4).div(100));
    token.transferFrom(_buyer, applicationAddress, _product.price.mul(5).div(100));
    
    products[index] = _product;
    
    products[index].isConfirmed[_buyer] = true;
    
    products[index].unconfirmedRequests = products[index].unconfirmedRequests.sub(1);
    if(products[index].unconfirmedRequests == 0){
       requestedProducts = requestedProducts.sub(1);
    }
    
    emit Purchase(_productId, _product.price, _buyer, _product.retailer, _model);
  }

  function findProductAndIndexById(uint _productId) internal view returns(Product memory, uint) {
    for(uint i = 0; i < products.length; i++) {
       if(products[i].id == _productId){
         return (products[i], i);
       }
    }
    
    Product memory product;
    
    return (product, 0);
  }
  
  function findProductIndexById(uint _productId) internal view returns(uint) {
    for(uint i = 0; i < products.length; i++) {
       if(products[i].id == _productId){
         return i;
       }
    }
    
    return 0;
  }
  
  function findProductById(uint _productId) internal view returns(Product memory) {
    for(uint i = 0; i < products.length; i++) {
       if(products[i].id == _productId){
         return products[i];
       }
    }
    
    Product memory product;
    
    return product;
  }
  
  
}