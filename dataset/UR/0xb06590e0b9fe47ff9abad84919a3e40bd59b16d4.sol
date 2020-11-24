 

 
 
 
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

contract Claimable is Ownable {
  address public pendingOwner;

   
  modifier onlyPendingOwner() {
    require(msg.sender == pendingOwner);
    _;
  }

   
  function transferOwnership(address newOwner) onlyOwner public {
    pendingOwner = newOwner;
  }

   
  function claimOwnership() onlyPendingOwner public {
    emit OwnershipTransferred(owner, pendingOwner);
    owner = pendingOwner;
    pendingOwner = address(0);
  }
}

contract AmmuNationStore is Claimable{

    using SafeMath for uint256;

    GTAInterface public token;

    uint256 private tokenSellPrice;  
    uint256 private tokenBuyPrice;  
    uint256 public buyDiscount;  

    event Buy(address buyer, uint256 amount, uint256 payed);
    event Robbery(address robber);

    constructor (address _tokenAddress) public {
        token = GTAInterface(_tokenAddress);
    }

     

     
     
    function depositGTA(uint256 amount) onlyOwner public {
        require(token.transferFrom(msg.sender, this, amount), "Insufficient funds");
    }

    function withdrawGTA(uint256 amount) onlyOwner public {
        require(token.transfer(msg.sender, amount), "Amount exceeds the available balance");
    }

    function robCashier() onlyOwner public {
        msg.sender.transfer(address(this).balance);
        emit Robbery(msg.sender);
    }

     

     
    function setTokenPrices(uint256 _newSellPrice, uint256 _newBuyPrice) onlyOwner public {
        tokenSellPrice = _newSellPrice;
        tokenBuyPrice = _newBuyPrice;
    }


    function buy() payable public returns (uint256){
         
         
        uint256 value = msg.value.mul(1 ether);
        uint256 _buyPrice = tokenBuyPrice;
        if (buyDiscount > 0) {
             
            _buyPrice = _buyPrice.sub(_buyPrice.mul(buyDiscount).div(100));
        }
        uint256 amount = value.div(_buyPrice);
        require(token.balanceOf(this) >= amount, "Sold out");
        require(token.transfer(msg.sender, amount), "Couldn't transfer token");
        emit Buy(msg.sender, amount, msg.value);
        return amount;
    }

     
     
     
     

    function applyDiscount(uint256 discount) onlyOwner public {
        buyDiscount = discount;
    }

    function getTokenBuyPrice() public view returns (uint256) {
        uint256 _buyPrice = tokenBuyPrice;
        if (buyDiscount > 0) {
            _buyPrice = _buyPrice.sub(_buyPrice.mul(buyDiscount).div(100));
        }
        return _buyPrice;
    }

    function getTokenSellPrice() public view returns (uint256) {
        return tokenSellPrice;
    }
}

 
interface GTAInterface {

    function transferFrom(address _from, address _to, uint256 _value) external returns (bool);

    function transfer(address to, uint256 value) external returns (bool);

    function balanceOf(address _owner) external view returns (uint256);

}