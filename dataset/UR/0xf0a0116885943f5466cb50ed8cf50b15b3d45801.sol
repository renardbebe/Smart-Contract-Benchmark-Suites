 

pragma solidity ^0.4.13;

 

contract ReentrancyGuard {

   
  bool private reentrancy_lock = false;

   
  modifier nonReentrant() {
    require(!reentrancy_lock);
    reentrancy_lock = true;
    _;
    reentrancy_lock = false;
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

contract Destructible is Ownable {

  function Destructible() public payable { }

   
  function destroy() onlyOwner public {
    selfdestruct(owner);
  }

  function destroyAndSend(address _recipient) onlyOwner public {
    selfdestruct(_recipient);
  }
}

contract ERC20Basic {
  function totalSupply() public view returns (uint256);
  function balanceOf(address who) public view returns (uint256);
  function transfer(address to, uint256 value) public returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
}

contract ShopInterface
{
    ERC20Basic public object;
    function buyObject(address _beneficiary) public payable;
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

contract TokenDestructible is Ownable {

  function TokenDestructible() public payable { }

   
  function destroy(address[] tokens) onlyOwner public {

     
    for (uint256 i = 0; i < tokens.length; i++) {
      ERC20Basic token = ERC20Basic(tokens[i]);
      uint256 balance = token.balanceOf(this);
      token.transfer(owner, balance);
    }

     
    selfdestruct(owner);
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

contract EthercraftFarm is Ownable, ReentrancyGuard, Destructible, TokenDestructible, Pausable {
    using SafeMath for uint8;
    using SafeMath for uint256;

     

    event Prepped(address indexed shop, address indexed object, uint256 iterations);
    event Reapped(address indexed object, uint256 balance);

    mapping (address => mapping (address => uint256)) public balanceOfToken;
    mapping (address => uint256) public totalOfToken;

    function() payable public {
         
    }

    function prep(address _shop, uint8 _iterations) nonReentrant whenNotPaused external {
        require(_shop != address(0));

        uint256 _len = 1;
        if (_iterations > 1)
            _len = uint256(_iterations);

        require(_len > 0);
        ShopInterface shop = ShopInterface(_shop);
        for (uint256 i = 0; i < _len.mul(100); i++)
            shop.buyObject(this);

        address object = shop.object();
        balanceOfToken[msg.sender][object] = balanceOfToken[msg.sender][object].add(uint256(_len.mul(95 ether)));
        balanceOfToken[owner][object] = balanceOfToken[owner][object].add(uint256(_len.mul(5 ether)));
        totalOfToken[object] = totalOfToken[object].add(uint256(_len.mul(100 ether)));

        Prepped(_shop, object, _len);
    }

    function reap(address _object) nonReentrant external {
        require(_object != address(0));
        require(balanceOfToken[msg.sender][_object] > 0);

         
        if (msg.sender == owner)
            owner.transfer(this.balance);

        uint256 balance = balanceOfToken[msg.sender][_object];
        balance = balance.sub(balance % (1 ether));  
        ERC20Basic(_object).transfer(msg.sender, balance);
        balanceOfToken[msg.sender][_object] = 0;
        totalOfToken[_object] = totalOfToken[_object].sub(balance);

        Reapped(_object, balance);
    }

     
    function transferAnyERC20Token(address _token, uint256 _value) external onlyOwner returns (bool success) {
        require(_token != address(0));
        require(_value > 0);
         
        require(_value <= ERC20Basic(_token).balanceOf(this).sub(this.totalOfToken(_token)));

         
        if (msg.sender == owner)
            owner.transfer(this.balance);

        return ERC20Basic(_token).transfer(owner, _value);
    }

}