 

pragma solidity ^0.4.25;

 
library SafeMath {

   
  function mul(uint256 _a, uint256 _b) internal pure returns (uint256) {
     
     
     
    if (_a == 0) {
      return 0;
    }

    uint256 c = _a * _b;
    require(c / _a == _b);

    return c;
  }

   
  function div(uint256 _a, uint256 _b) internal pure returns (uint256) {
    require(_b > 0);  
    uint256 c = _a / _b;
     

    return c;
  }

   
  function sub(uint256 _a, uint256 _b) internal pure returns (uint256) {
    require(_b <= _a);
    uint256 c = _a - _b;

    return c;
  }

   
  function add(uint256 _a, uint256 _b) internal pure returns (uint256) {
    uint256 c = _a + _b;
    require(c >= _a);

    return c;
  }

   
  function mod(uint256 a, uint256 b) internal pure returns (uint256) {
    require(b != 0);
    return a % b;
  }
}

 
contract Ownable {
  address public owner;


  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);


   
  constructor() public {
    owner = msg.sender;
  }


   
  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }


   
  function transferOwnership(address newOwner) onlyOwner public {
    require(newOwner != address(0));
    emit OwnershipTransferred(owner, newOwner);
    owner = newOwner;
  }
}

interface token { 
  function transfer(address, uint) external returns (bool);
  function transferFrom(address, address, uint) external returns (bool); 
  function allowance(address, address) external constant returns (uint256);
  function balanceOf(address) external constant returns (uint256);
}

 

contract NovaBox is Ownable {
  
  using SafeMath for uint;
  token tokenReward;

  
  constructor() public {
    tokenReward = token(0x72FBc0fc1446f5AcCC1B083F0852a7ef70a8ec9f);
  }

  event AirDrop(address to, uint amount, uint randomTicket);
  event DividendsTransferred(address to, uint ethAmount, uint novaAmount);


   
  mapping (address => uint) public contributionsEth;
   
  mapping (address => uint) public contributionsToken;

   
  mapping (address => uint) public indexes;
  mapping (uint => address) public addresses;
  uint256 public lastIndex = 0;

  mapping (address => bool) public addedToList;
  uint _totalTokens = 0;
  uint _totalWei = 0;

  uint pointMultiplier = 1e18;

  mapping (address => uint) public last6EthDivPoints;
  uint public total6EthDivPoints = 0;
   

  mapping (address => uint) public last4EthDivPoints;
  uint public total4EthDivPoints = 0;
   

  mapping (address => uint) public last6TokenDivPoints;
  uint public total6TokenDivPoints = 0;
   

  mapping (address => uint) public last4TokenDivPoints;
  uint public total4TokenDivPoints = 0;
   

  function ethDivsOwing(address _addr) public view returns (uint) {
    return eth4DivsOwing(_addr).add(eth6DivsOwing(_addr));
  }

  function eth6DivsOwing(address _addr) public view returns (uint) {
    if (!addedToList[_addr]) return 0;
    uint newEth6DivPoints = total6EthDivPoints.sub(last6EthDivPoints[_addr]);

    return contributionsToken[_addr].mul(newEth6DivPoints).div(pointMultiplier);
  }

  function eth4DivsOwing(address _addr) public view returns (uint) {
    if (!addedToList[_addr]) return 0;
    uint newEth4DivPoints = total4EthDivPoints.sub(last4EthDivPoints[_addr]);
    return contributionsEth[_addr].mul(newEth4DivPoints).div(pointMultiplier);
  }

  function tokenDivsOwing(address _addr) public view returns (uint) {
    return token4DivsOwing(_addr).add(token6DivsOwing(_addr));    
  }

  function token6DivsOwing(address _addr) public view returns (uint) {
    if (!addedToList[_addr]) return 0;
    uint newToken6DivPoints = total6TokenDivPoints.sub(last6TokenDivPoints[_addr]);
    return contributionsToken[_addr].mul(newToken6DivPoints).div(pointMultiplier);
  }

  function token4DivsOwing(address _addr) public view returns (uint) {
    if (!addedToList[_addr]) return 0;

    uint newToken4DivPoints = total4TokenDivPoints.sub(last4TokenDivPoints[_addr]);
    return contributionsEth[_addr].mul(newToken4DivPoints).div(pointMultiplier);
  }

  function updateAccount(address account) private {
    uint owingEth6 = eth6DivsOwing(account);
    uint owingEth4 = eth4DivsOwing(account);
    uint owingEth = owingEth4.add(owingEth6);

    uint owingToken6 = token6DivsOwing(account);
    uint owingToken4 = token4DivsOwing(account);
    uint owingToken = owingToken4.add(owingToken6);

    if (owingEth > 0) {
       
      account.transfer(owingEth);
    }

    if (owingToken > 0) {
       
      tokenReward.transfer(account, owingToken);
    }

    last6EthDivPoints[account] = total6EthDivPoints;
    last4EthDivPoints[account] = total4EthDivPoints;
    last6TokenDivPoints[account] = total6TokenDivPoints;
    last4TokenDivPoints[account] = total4TokenDivPoints;

    emit DividendsTransferred(account, owingEth, owingToken);

  }



  function addToList(address sender) private {
    addedToList[sender] = true;
     
    if (indexes[sender] == 0) {
      _totalTokens = _totalTokens.add(contributionsToken[sender]);
      _totalWei = _totalWei.add(contributionsEth[sender]);

       
      lastIndex++;
      addresses[lastIndex] = sender;
      indexes[sender] = lastIndex;
    }
  }
  function removeFromList(address sender) private {
    addedToList[sender] = false;
     
    if (indexes[sender] > 0) {
      _totalTokens = _totalTokens.sub(contributionsToken[sender]);
      _totalWei = _totalWei.sub(contributionsEth[sender]);

       
      addresses[indexes[sender]] = addresses[lastIndex];
      indexes[addresses[lastIndex]] = indexes[sender];
      indexes[sender] = 0;
      delete addresses[lastIndex];
      lastIndex--;
    }
  }

   
  function () payable public {
    address sender = msg.sender;
     
    uint codeLength;

     
    assembly {
      codeLength := extcodesize(sender)
    }

     
    require(codeLength == 0);
    
    uint weiAmount = msg.value;
    

    updateAccount(sender);

     
    require(weiAmount > 0);

    uint _89percent = weiAmount.mul(89).div(100);
    uint _6percent = weiAmount.mul(6).div(100);
    uint _4percent = weiAmount.mul(4).div(100);
    uint _1percent = weiAmount.mul(1).div(100);


    


    distributeEth(
      _6percent,  
      _4percent   
    ); 
     
    owner.transfer(_1percent);

    contributionsEth[sender] = contributionsEth[sender].add(_89percent);
     
    if (indexes[sender]>0) {
       
      _totalWei = _totalWei.add(_89percent);
    }

     
    if (contributionsToken[sender]>0) addToList(sender);
  }

   
  function withdrawEth(uint amount) public {
    address sender = msg.sender;
    require(amount>0 && contributionsEth[sender] >= amount);

    updateAccount(sender);

    uint _89percent = amount.mul(89).div(100);
    uint _6percent = amount.mul(6).div(100);
    uint _4percent = amount.mul(4).div(100);
    uint _1percent = amount.mul(1).div(100);

    contributionsEth[sender] = contributionsEth[sender].sub(amount);
     
    if (indexes[sender]>0) {
       
      _totalWei = _totalWei.sub(amount);
    }

     
       
    if (contributionsEth[sender] == 0) removeFromList(sender);

    sender.transfer(_89percent);
    distributeEth(
      _6percent,  
      _4percent   
    );
    owner.transfer(_1percent);   
  }

   
  function depositTokens(address randomAddr, uint randomTicket) public {
    updateAccount(msg.sender);
    

    address sender = msg.sender;
    uint amount = tokenReward.allowance(sender, address(this));
    
     
     
     
    require(amount>0 && tokenReward.transferFrom(sender, address(this), amount));


    uint _89percent = amount.mul(89).div(100);
    uint _6percent = amount.mul(6).div(100);
    uint _4percent = amount.mul(4).div(100);
    uint _1percent = amount.mul(1).div(100);
    
    

    distributeTokens(
      _6percent,  
      _4percent   
      );
    tokenReward.transfer(randomAddr, _1percent);
     
    emit AirDrop(randomAddr, _1percent, randomTicket);

    contributionsToken[sender] = contributionsToken[sender].add(_89percent);

     
    if (indexes[sender]>0) {
       
      _totalTokens = _totalTokens.add(_89percent);
    }

     
    if (contributionsEth[sender]>0) addToList(sender);
  }

   
  function withdrawTokens(uint amount, address randomAddr, uint randomTicket) public {
    address sender = msg.sender;
    updateAccount(sender);
     
     
    require(amount>0 && contributionsToken[sender]>=amount);

    uint _89percent = amount.mul(89).div(100);
    uint _6percent = amount.mul(6).div(100);
    uint _4percent = amount.mul(4).div(100);
    uint _1percent = amount.mul(1).div(100);

    contributionsToken[sender] = contributionsToken[sender].sub(amount);
     
    if (indexes[sender]>0) {
       
      _totalTokens = _totalTokens.sub(amount);
    }

     
    if (contributionsToken[sender] == 0) removeFromList(sender);

    tokenReward.transfer(sender, _89percent);
    distributeTokens(
      _6percent,  
      _4percent   
    );
     
    tokenReward.transfer(randomAddr, _1percent);
    emit AirDrop(randomAddr, _1percent, randomTicket);
  }

  function distributeTokens(uint _6percent, uint _4percent) private {
    uint totalTokens = getTotalTokens();
    uint totalWei = getTotalWei();

    if (totalWei == 0 || totalTokens == 0) return; 

    total4TokenDivPoints = total4TokenDivPoints.add(_4percent.mul(pointMultiplier).div(totalWei));
     

    total6TokenDivPoints = total6TokenDivPoints.add(_6percent.mul(pointMultiplier).div(totalTokens));
     
    
  }

  function distributeEth(uint _6percent, uint _4percent) private {
    uint totalTokens = getTotalTokens();
    uint totalWei = getTotalWei();

    if (totalWei ==0 || totalTokens == 0) return;

    total4EthDivPoints = total4EthDivPoints.add(_4percent.mul(pointMultiplier).div(totalWei));
     

    total6EthDivPoints = total6EthDivPoints.add(_6percent.mul(pointMultiplier).div(totalTokens));
     

  }


   
  function getTotalTokens() public view returns (uint) {
    return _totalTokens;
  }

   
  function getTotalWei() public view returns (uint) {
    return _totalWei;
  }

  function withdrawDivs() public {
    updateAccount(msg.sender);
  }


   
  function getList() public view returns (address[], uint[]) {
    address[] memory _addrs = new address[](lastIndex);
    uint[] memory _contributions = new uint[](lastIndex);

    for (uint i = 1; i <= lastIndex; i++) {
      _addrs[i-1] = addresses[i];
      _contributions[i-1] = contributionsToken[addresses[i]];
    }
    return (_addrs, _contributions);
  }

}