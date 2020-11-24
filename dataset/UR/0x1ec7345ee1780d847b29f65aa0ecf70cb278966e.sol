 

pragma solidity ^0.4.18;

 
contract Ownable {
  address public owner;

   
  function Ownable() public {
    owner = msg.sender;
  }

   
  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }

}

 
library SafeMath {
  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a * b;
    assert(a == 0 || c / a == b);
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

 
contract EtherTv is Ownable {
  using SafeMath for uint256;

  Show[] private shows;
  uint256 public devOwed;

   
  mapping (address => uint256) public userDividends;

   
  event ShowPurchased(
    uint256 _tokenId,
    address oldOwner,
    address newOwner,
    uint256 price,
    uint256 nextPrice
  );

   
  uint256 constant private FIRST_CAP  = 0.5 ether;
  uint256 constant private SECOND_CAP = 1.0 ether;
  uint256 constant private THIRD_CAP  = 3.0 ether;
  uint256 constant private FINAL_CAP  = 5.0 ether;

   
  struct Show {
    uint256 price;   
    uint256 payout;  
    address owner;   
  }

  function createShow(uint256 _payoutPercentage) onlyOwner() public {
     
    require(_payoutPercentage > 0);
    
     
    var show = Show({
      price: 0.005 ether,
      payout: _payoutPercentage,
      owner: this
    });

    shows.push(show);
  }

  function createMultipleShows(uint256[] _payoutPercentages) onlyOwner() public {
    for (uint256 i = 0; i < _payoutPercentages.length; i++) {
      createShow(_payoutPercentages[i]);
    }
  }

  function getShow(uint256 _showId) public view returns (
    uint256 price,
    uint256 nextPrice,
    uint256 payout,
    uint256 effectivePayout,
    address owner
  ) {
    var show = shows[_showId];
    price = show.price;
    nextPrice = getNextPrice(show.price);
    payout = show.payout;
    effectivePayout = show.payout.mul(10000).div(getTotalPayout());
    owner = show.owner;
  }

   
  function getNextPrice (uint256 _price) private pure returns (uint256 _nextPrice) {
    if (_price < FIRST_CAP) {
      return _price.mul(200).div(100);
    } else if (_price < SECOND_CAP) {
      return _price.mul(135).div(100);
    } else if (_price < THIRD_CAP) {
      return _price.mul(125).div(100);
    } else if (_price < FINAL_CAP) {
      return _price.mul(117).div(100);
    } else {
      return _price.mul(115).div(100);
    }
  }

  function calculatePoolCut (uint256 _price) private pure returns (uint256 _poolCut) {
    if (_price < FIRST_CAP) {
      return _price.mul(7).div(100);  
    } else if (_price < SECOND_CAP) {
      return _price.mul(6).div(100);  
    } else if (_price < THIRD_CAP) {
      return _price.mul(5).div(100);  
    } else if (_price < FINAL_CAP) {
      return _price.mul(4).div(100);  
    } else {
      return _price.mul(3).div(100);  
    }
  }

   
  function purchaseShow(uint256 _tokenId) public payable {
    var show = shows[_tokenId];
    uint256 price = show.price;
    address oldOwner = show.owner;
    address newOwner = msg.sender;

     
    require(price > 0);
    require(msg.value >= price);
    require(oldOwner != msg.sender);

    uint256 purchaseExcess = msg.value.sub(price);

     
    
     
    uint256 devCut = price.mul(4).div(100);
    devOwed = devOwed.add(devCut);

     
    uint256 shareholderCut = calculatePoolCut(price);
    distributeDividends(shareholderCut);

     
    uint256 excess = price.sub(devCut).sub(shareholderCut);

    if (oldOwner != address(this)) {
      oldOwner.transfer(excess);
    }

     
    uint256 nextPrice = getNextPrice(price);
    show.price = nextPrice;

     
    show.owner = newOwner;

     
    if (purchaseExcess > 0) {
      newOwner.transfer(purchaseExcess);
    }

     
    ShowPurchased(_tokenId, oldOwner, newOwner, price, nextPrice);
  }

  function distributeDividends(uint256 _shareholderCut) private {
    uint256 totalPayout = getTotalPayout();

    for (uint256 i = 0; i < shows.length; i++) {
      var show = shows[i];
      var payout = _shareholderCut.mul(show.payout).div(totalPayout);
      userDividends[show.owner] = userDividends[show.owner].add(payout);
    }
  }

  function getTotalPayout() private view returns(uint256) {
    uint256 totalPayout = 0;

    for (uint256 i = 0; i < shows.length; i++) {
      var show = shows[i];
      totalPayout = totalPayout.add(show.payout);
    }

    return totalPayout;
  }

   
  function withdraw() onlyOwner public {
    owner.transfer(devOwed);
    devOwed = 0;
  }

   
  function withdrawDividends() public {
    uint256 dividends = userDividends[msg.sender];
    userDividends[msg.sender] = 0;
    msg.sender.transfer(dividends);
  }

}