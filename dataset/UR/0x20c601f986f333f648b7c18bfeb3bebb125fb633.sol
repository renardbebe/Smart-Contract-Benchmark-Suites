 

 


 

 




 
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



 
contract ERC20Basic {
  function totalSupply() public view returns (uint256);
  function balanceOf(address who) public view returns (uint256);
  function transfer(address to, uint256 value) public returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
}


contract Recoverable is Ownable {

   
  function Recoverable() {
  }

   
   
  function recoverTokens(ERC20Basic token) onlyOwner public {
    token.transfer(owner, tokensToBeReturned(token));
  }

   
   
   
  function tokensToBeReturned(ERC20Basic token) public returns (uint) {
    return token.balanceOf(this);
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


contract PaymentSplitter is Recoverable {
  using SafeMath for uint256;  

   
  struct Party {
    address addr;
    uint256 slices;
  }

   
   
   
  uint256 constant MAX_PARTIES = 100;
   
  uint256 public totalSlices;
   
  Party[] public parties;

   
   
  event Deposit(address indexed sender, uint256 value);
   
   
  event Split(address indexed who, uint256 value);
   
  event SplitTo(address indexed to, uint256 value);

   
   
   
  function PaymentSplitter(address[] addresses, uint[] slices) public {
    require(addresses.length == slices.length, "addresses and slices must be equal length.");
    require(addresses.length > 0 && addresses.length < MAX_PARTIES, "Amount of parties is either too many, or zero.");

    for(uint i=0; i<addresses.length; i++) {
      parties.push(Party(addresses[i], slices[i]));
      totalSlices = totalSlices.add(slices[i]);
    }
  }

   
   
   
  function split() external {
    uint256 totalBalance = this.balance;
    uint256 slice = totalBalance.div(totalSlices);

    for(uint i=0; i<parties.length; i++) {
      uint256 amount = slice.mul(parties[i].slices);

      parties[i].addr.send(amount);
      emit SplitTo(parties[i].addr, amount);
    }

    emit Split(msg.sender, totalBalance);
  }

   
  function() public payable {
    emit Deposit(msg.sender, msg.value);
  }
}