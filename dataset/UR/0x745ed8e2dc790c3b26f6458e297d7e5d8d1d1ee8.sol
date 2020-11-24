 

pragma solidity > 0.4.99 <0.6.0;

interface IERC20Token {
    function balanceOf(address owner) external returns (uint256);
    function transfer(address to, uint256 amount) external returns (bool);
    function burn(uint256 _value) external returns (bool);
    function decimals() external returns (uint256);
    function approve(address _spender, uint256 _value) external returns (bool success);
    function transferFrom(address _from, address _to, uint256 _value) external returns (bool success);
}

contract Ownable {
  address payable public _owner;

  event OwnershipTransferred(
    address indexed previousOwner,
    address indexed newOwner
  );

   
  constructor() internal {
    _owner = tx.origin;
    emit OwnershipTransferred(address(0), _owner);
  }

   
  function owner() public view returns(address) {
    return _owner;
  }

   
  modifier onlyOwner() {
    require(isOwner());
    _;
  }

   
  function isOwner() public view returns(bool) {
    return msg.sender == _owner;
  }

   
  function renounceOwnership() public onlyOwner {
    emit OwnershipTransferred(_owner, address(0));
    _owner = address(0);
  }

   
  function transferOwnership(address payable newOwner) public onlyOwner {
    _transferOwnership(newOwner);
  }

   
  function _transferOwnership(address payable newOwner) internal {
    require(newOwner != address(0));
    emit OwnershipTransferred(_owner, newOwner);
    _owner = newOwner;
  }
}

 
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

contract TokenSale is Ownable {
    
    using SafeMath for uint256;
    
    string public constant createdBy = "AssetSplit.org - the guys who cut the pizza";
    
    IERC20Token public tokenContract;
    uint256 public tokenPerEther;

    uint256 public tokensSold;
    
    uint256 public earlyBirdsPaid = 0;
    uint256 public earlyBirdBonus = 5;
    uint256 public earlyBirdValue = 900;
    
    uint256 public bonusStage1;
    uint256 public bonusStage2;
    uint256 public bonusStage3;
    
    uint256 public bonusPercentage1;
    uint256 public bonusPercentage2;
    uint256 public bonusPercentage3;

    event Sold(address buyer, uint256 amount);

    constructor(address _tokenContract, uint256 _tokenPerEther, uint256 _bonusStage1, uint256 _bonusPercentage1, uint256 _bonusStage2, uint256 _bonusPercentage2, uint256 _bonusStage3, uint256 _bonusPercentage3) public {
        tokenContract = IERC20Token(_tokenContract);
        tokenPerEther = _tokenPerEther;
        
        bonusStage1 = _bonusStage1.mul(1 ether);
        bonusStage2 = _bonusStage2.mul(1 ether);
        bonusStage3 = _bonusStage3.mul(1 ether);
        bonusPercentage1 = _bonusPercentage1;
        bonusPercentage2 = _bonusPercentage2;
        bonusPercentage3 = _bonusPercentage3;
    }
    
    function buyTokenWithEther() public payable {
        address payable creator = _owner;
        uint256 scaledAmount;
        
        require(msg.value > 0);
        
        if (msg.value < bonusStage1 || bonusStage1 == 0) {
        scaledAmount = msg.value.mul(tokenPerEther).mul(uint256(10) ** tokenContract.decimals()).div(10 ** 18);
        }
        if (bonusStage1 != 0 && msg.value >= bonusStage1) {
            scaledAmount = msg.value.mul(tokenPerEther).mul(uint256(10) ** tokenContract.decimals()).div(10 ** 18).mul(bonusPercentage1).div(100);
        }
        if (bonusStage2 != 0 && msg.value >= bonusStage2) {
            scaledAmount = msg.value.mul(tokenPerEther).mul(uint256(10) ** tokenContract.decimals()).div(10 ** 18).mul(bonusPercentage2).div(100);
        }
        if (bonusStage3 != 0 && msg.value >= bonusStage3) {
            scaledAmount = msg.value.mul(tokenPerEther).mul(uint256(10) ** tokenContract.decimals()).div(10 ** 18).mul(bonusPercentage3).div(100);
            if (earlyBirdsPaid < earlyBirdBonus) {
                earlyBirdsPaid = earlyBirdsPaid.add(1);
                scaledAmount = scaledAmount.add((earlyBirdValue).mul(uint256(10) ** tokenContract.decimals()));
            }
        }
        
        require(tokenContract.balanceOf(address(this)) >= scaledAmount);
        emit Sold(msg.sender, scaledAmount);
        tokensSold = tokensSold.add(scaledAmount);
        creator.transfer(address(this).balance);
        require(tokenContract.transfer(msg.sender, scaledAmount));
    }
    
    function () external payable {
        buyTokenWithEther();
    }
}