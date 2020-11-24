 

pragma solidity ^0.4.13;

 

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

contract ShopInterface
{
    ObjectInterface public object;
    function buyObject(address _beneficiary) public payable;
}

contract ReentrancyGuard {

   
  bool private reentrancy_lock = false;

   
  modifier nonReentrant() {
    require(!reentrancy_lock);
    reentrancy_lock = true;
    _;
    reentrancy_lock = false;
  }

}

contract EthercraftFarm is Ownable, ReentrancyGuard {
    using SafeMath for uint256;

     
    mapping (address => mapping (address => uint256)) public tokenBalanceOf;

    function() payable public {
         
    }

    function prep(address _shop, uint8 _iterations) nonReentrant external {
        require(_shop != address(0));

        uint8 _len = 1;
        if (_iterations > 1)
            _len = _iterations;

        ShopInterface shop = ShopInterface(_shop);
        for (uint8 i = 0; i < _len * 100; i++) {
            shop.buyObject(this);
        }

        ObjectInterface object = ObjectInterface(shop.object());
        tokenBalanceOf[msg.sender][object] = tokenBalanceOf[msg.sender][object].add(uint256(_len * 99 ether));
        tokenBalanceOf[owner][object] = tokenBalanceOf[owner][object].add(uint256(_len * 1 ether));
    }

    function reap(address _object) nonReentrant external {
        require(_object != address(0));
        require(tokenBalanceOf[msg.sender][_object] > 0);

         
        if (msg.sender == owner)
            owner.transfer(this.balance);

        ObjectInterface(_object).transfer(msg.sender, tokenBalanceOf[msg.sender][_object]);
        tokenBalanceOf[msg.sender][_object] = 0;
    }

}

contract ObjectInterface
{
    function transfer(address to, uint256 value) public returns (bool);
}