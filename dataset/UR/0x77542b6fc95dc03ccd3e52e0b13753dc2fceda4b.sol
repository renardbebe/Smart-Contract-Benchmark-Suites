 

pragma solidity 0.4.21;
 
contract Ownable {

  address public owner;

   
  function Ownable() public {
    owner = msg.sender;
  }

   
  function changeOwner(address newOwner) public ownerOnly {
    require(newOwner != address(0));
    owner = newOwner;
  }

   
  modifier ownerOnly() {
    require(msg.sender == owner);
    _;
  }
}

  
contract EmergencySafe is Ownable{ 

  event PauseToggled(bool isPaused);

  bool public paused;


   
  modifier isNotPaused() {
    require(!paused);
    _;
  }

   
  modifier isPaused() {
    require(paused);
    _; 
  }

   
  function EmergencySafe() public {
    paused = false;
  }

   
  function emergencyERC20Drain(ERC20Interface token, uint amount) public ownerOnly{
    token.transfer(owner, amount);
  }

   
  function emergencyEthDrain(uint amount) public ownerOnly returns (bool){
    return owner.send(amount);
  }

   
  function togglePause() public ownerOnly {
    paused = !paused;
    emit PauseToggled(paused);
  }
}


  
contract Upgradeable is Ownable{

  address public lastContract;
  address public nextContract;
  bool public isOldVersion;
  bool public allowedToUpgrade;

   
  function Upgradeable() public {
    allowedToUpgrade = true;
  }

   
  function upgradeTo(Upgradeable newContract) public ownerOnly{
    require(allowedToUpgrade && !isOldVersion);
    nextContract = newContract;
    isOldVersion = true;
    newContract.confirmUpgrade();   
  }

   
  function confirmUpgrade() public {
    require(lastContract == address(0));
    lastContract = msg.sender;
  }
}

  
contract IXTPaymentContract is Ownable, EmergencySafe, Upgradeable{

  event IXTPayment(address indexed from, address indexed to, uint value, string indexed action);

  ERC20Interface public tokenContract;

  mapping(string => uint) private actionPrices;
  mapping(address => bool) private allowed;

   
  modifier allowedOnly() {
    require(allowed[msg.sender] || msg.sender == owner);
    _;
  }

   
  function IXTPaymentContract(address tokenAddress) public {
    tokenContract = ERC20Interface(tokenAddress);
    allowed[owner] = true;
  }

   
  function transferIXT(address from, address to, string action) public allowedOnly isNotPaused returns (bool) {
    if (isOldVersion) {
      IXTPaymentContract newContract = IXTPaymentContract(nextContract);
      return newContract.transferIXT(from, to, action);
    } else {
      uint price = actionPrices[action];

      if(price != 0 && !tokenContract.transferFrom(from, to, price)){
        return false;
      } else {
        emit IXTPayment(from, to, price, action);     
        return true;
      }
    }
  }

   
  function setTokenAddress(address erc20Token) public ownerOnly isNotPaused {
    tokenContract = ERC20Interface(erc20Token);
  }

   
  function setAction(string action, uint price) public ownerOnly isNotPaused {
    actionPrices[action] = price;
  }

   
  function getActionPrice(string action) public view returns (uint) {
    return actionPrices[action];
  }


   
  function setAllowed(address allowedAddress) public ownerOnly {
    allowed[allowedAddress] = true;
  }

   
  function removeAllowed(address allowedAddress) public ownerOnly {
    allowed[allowedAddress] = false;
  }
}

contract ERC20Interface {
    uint public totalSupply;
    function balanceOf(address tokenOwner) public constant returns (uint balance);
    function allowance(address tokenOwner, address spender) public constant returns (uint remaining);
    function transfer(address to, uint tokens) public returns (bool success);
    function approve(address spender, uint tokens) public returns (bool success);
    function transferFrom(address from, address to, uint tokens) public returns (bool success);

    event Transfer(address indexed from, address indexed to, uint tokens);
    event Approval(address indexed tokenOwner, address indexed spender, uint tokens);
}