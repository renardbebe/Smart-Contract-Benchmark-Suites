 

pragma solidity >=0.4.22 <0.6.0;

 
library SafeMath {

   
  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
     
     
     
    if (a == 0) {
      return 0;
    }

    uint256 c = a * b;
    require(c / a == b);  

    return c;
  }

   
  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    require(b > 0);  
    uint256 c = a / b;

    return c;
  }

   
  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    require(b <= a);
    uint256 c = a - b;

    return c;
  }

   
  function add(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    require(c >= a);  

    return c;
  }

   
  function mod(uint256 a, uint256 b) internal pure returns (uint256) {
    require(b != 0);
    return a % b;
  }
}

 
contract Ownable {
  using SafeMath for uint256;
  address public owner;
 
   
  constructor() public {
    owner = msg.sender;
  }
 
   
  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }
 
   
  function transferOwnership(address newOwner) public onlyOwner {
    require(newOwner != address(0));   
    owner = newOwner;
  }

   
  function withdraw(address payable destination) public onlyOwner {
    require(destination != address(0));
    destination.transfer(address(this).balance);
  }

   
  function getBalance() public view onlyOwner returns (uint256) {
    return address(this).balance.div(1 szabo);
  }

}

 
contract TaxCredit is Ownable {
  using SafeMath for uint256;

  mapping (address => uint256) private balances;
  mapping (address => string) private emails;
  address[] addresses;
  uint256 public minimumPurchase = 1950 ether;   
  uint256 private _totalSupply;
  uint256 private exchangeRate = (270000 ether / minimumPurchase) + 1;   
  uint256 private discountRate = 1111111111111111111 wei;   

  string public name = "Tax Credit Token";
  string public symbol = "TCT";
  uint public INITIAL_SUPPLY = 20000000;   

  event Transfer(
    address indexed from,
    address indexed to,
    uint256 value
  );

  event Exchange(
    string indexed email,
    address indexed addr,
    uint256 value
  );

  constructor() public {
    mint(msg.sender, INITIAL_SUPPLY);
  }

   
  function totalSupply() public view returns (uint256) {
    return _totalSupply;
  }

   
  function balanceOf(address owner) public view returns (uint256) {
    return balances[owner];
  }

   
  function transferFrom(address from, address to, uint256 value) public onlyOwner {
    require(value <= balances[from]);

    balances[from] = balances[from].sub(value);
    balances[to] = balances[to].add(value);
    emit Transfer(from, to, value);
  }

   
  function mint(address account, uint256 value) public onlyOwner {
    _handleMint(account, value);
  }

   
  function _handleMint(address account, uint256 value) internal {
    require(account != address(0));
    _totalSupply = _totalSupply.add(value);
    balances[account] = balances[account].add(value);
    emit Transfer(address(0), account, value);
  }

   
  function burn(address account, uint256 value) public onlyOwner {
    require(account != address(0));
    require(value <= balances[account]);

    _totalSupply = _totalSupply.sub(value);
    balances[account] = balances[account].sub(value);
    emit Transfer(account, address(0), value);
  }

   
  function exchange(string memory email) public payable {
    require(msg.value > minimumPurchase);
    require(keccak256(bytes(email)) != keccak256(bytes("")));   

    addresses.push(msg.sender);
    emails[msg.sender] = email;
    uint256 tokens = msg.value.mul(exchangeRate);
    tokens = tokens.mul(discountRate);
    tokens = tokens.div(1 ether).div(1 ether);   
    _handleMint(msg.sender, tokens);
    emit Exchange(email, msg.sender, tokens);
  }

   
  function changeMinimumExchange(uint256 newMinimum) public onlyOwner {
    require(newMinimum > 0);   
    minimumPurchase = newMinimum * 1 ether;
    exchangeRate = 270000 ether / minimumPurchase;
  }

   
  function getAllAddresses() public view returns (address[] memory) {
    return addresses;
  }

   
  function getParticipantEmail(address addr) public view returns (string memory) {
    return emails[addr];
  }

   
  function getAllAddresses(string memory email) public view onlyOwner returns (address[] memory) {
    address[] memory all = new address[](addresses.length);
    for (uint32 i = 0; i < addresses.length; i++) {
      if (keccak256(bytes(emails[addresses[i]])) == keccak256(bytes(email))) {
        all[i] = addresses[i];
      }
    }
    return all;
  }

}