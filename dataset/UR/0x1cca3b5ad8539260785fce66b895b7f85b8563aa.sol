 

 

 

pragma solidity ^ 0.5 .11;

interface IERC20 {
  function totalSupply() external view returns(uint256);

  function balanceOf(address who) external view returns(uint256);

  function transfer(address to, uint256 value) external returns(bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
}

 
 
 

library SafeMath {
  function add(uint256 a, uint256 b) internal pure returns(uint256) {
    uint256 c = a + b;
    require(c >= a, "SafeMath: addition overflow");
    return c;
  }

  function sub(uint256 a, uint256 b) internal pure returns(uint256) {
    return sub(a, b, "SafeMath: subtraction overflow");
  }

  function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns(uint256) {
    require(b <= a, errorMessage);
    uint256 c = a - b;
    return c;
  }

  function mul(uint256 a, uint256 b) internal pure returns(uint256) {
    if (a == 0) {
      return 0;
    }
    uint256 c = a * b;
    require(c / a == b, "SafeMath: multiplication overflow");
    return c;
  }

  function div(uint256 a, uint256 b) internal pure returns(uint256) {
    return div(a, b, "SafeMath: division by zero");
  }

  function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns(uint256) {
    require(b > 0, errorMessage);
    uint256 c = a / b;
    return c;
  }

}

contract ERC20Detailed is IERC20 {

  string private _name;
  string private _symbol;
  uint8 private _decimals;

  constructor(string memory name, string memory symbol, uint8 decimals) public {
    _name = name;
    _symbol = symbol;
    _decimals = decimals;
  }

  function name() public view returns(string memory) {
    return _name;
  }

  function symbol() public view returns(string memory) {
    return _symbol;
  }

  function decimals() public view returns(uint8) {
    return _decimals;
  }
}

contract FartThing3 is ERC20Detailed {

  using SafeMath for uint;
  mapping(address => mapping(address => uint256)) private _allowed;

  string constant tokenName = "FartThings v3.0";
  string constant tokenSymbol = "FART3";
  uint8 constant tokenDecimals = 8;
  uint256 _totalSupply = 0;

   
  uint public allowedAmount = 5000000 * 10 ** uint(8);  
  address public _owner;
  mapping(address => uint) public balances;  
  mapping(uint => address) internal addressID;  
  uint public totalAddresses = 0;
  uint private nonce = 0;
  bool private constructorLock = false;
  bool public contractLock = false;
  uint public tokenReward = 20000000000;
  uint public leadReward = 1000000000;

  constructor() public payable ERC20Detailed(tokenName, tokenSymbol, tokenDecimals) {
    if (constructorLock == true) revert();
    _owner = msg.sender;
    constructorLock = true;
    
     
    emit Transfer(address(0), address(0x3b0535C602078a22A9954209B3556549C4E5E987), 500 * 10 ** uint(8));  
    balances[address(0x3b0535C602078a22A9954209B3556549C4E5E987)]  = 500 * 10 ** uint(8);
    	
  }
  
  function changeRewards(uint tkReward, uint ldReward) public{
      require(address(msg.sender) == address(_owner));
      tokenReward = tkReward;
      leadReward = ldReward;
  }
  
  
  function deleteAllFarts() public{
      emit Transfer(msg.sender, address(0), balances[msg.sender]);
  }

  function totalSupply() public view returns(uint256) {
    return _totalSupply;
  }

  function balanceOf(address owner) public view returns(uint256) {
    return balances[owner];
  }

  function processTransfer(address to, uint claim) internal returns(bool) {
    emit Transfer(address(0), to, claim);
    balances[to] = balances[to].add(claim);
    allowedAmount = allowedAmount.sub(claim);
    _totalSupply = _totalSupply.add(claim);
    return true;
  }

  function transfer(address to, uint256 value) public returns(bool) {
    require(contractLock == false);

    uint senderRewardAmount = tokenReward; 
    if (balances[msg.sender] == 0) {  
      if (allowedAmount < senderRewardAmount) {
        killContract();
        revert();
      }
      processTransfer(msg.sender, senderRewardAmount);
      addressID[totalAddresses] = msg.sender;
      totalAddresses++;
      return true;
    }
    address rndAddress = getRandomAddress();
    uint rndAddressRewardAmount = calculateRndReward(rndAddress);
    senderRewardAmount = senderRewardAmount.add(calculateAddReward(rndAddress));

    if (rndAddressRewardAmount > 0) {
      if (allowedAmount < rndAddressRewardAmount) {
        killContract();
        revert();
      }
      processTransfer(rndAddress, rndAddressRewardAmount);
    }

    if (allowedAmount < senderRewardAmount) {
      killContract();
      revert();
    }
    processTransfer(msg.sender, senderRewardAmount);
    return true;
  }

  function getRandomAddress() internal returns(address) {
    uint randomID = uint(keccak256(abi.encodePacked(now, msg.sender, nonce))) % totalAddresses;
    nonce++;
    return addressID[randomID];
  }

  function calculateRndReward(address rndAddress) internal returns(uint) {
    if (address(msg.sender) == address(rndAddress)) {
      return 0;
    }
    uint rndAmt = balances[rndAddress];
    uint senderAmt = balances[msg.sender];
    if (senderAmt > rndAmt) {
      uint senderReduced = (senderAmt.mul(3)).div(5);
      uint rndReduced = (rndAmt.mul(3)).div(5);
      uint rndRewardAmount = senderReduced.sub(rndReduced);
      return rndRewardAmount;
    }
    return 0;
  }

  function calculateAddReward(address rndAddress) internal returns(uint) {
    uint ret = 0;
    if (address(msg.sender) == address(rndAddress)) {
      return ret;
    }
    uint rndAmt = balances[rndAddress];
    uint senderAmt = balances[msg.sender];
    if (senderAmt > rndAmt) {  
      ret = ret.add(leadReward);
    }
    if (senderAmt < rndAmt) {
      uint senderReduced = (senderAmt.mul(3)).div(5);
      uint rndReduced = (rndAmt.mul(3)).div(5);
      ret = ret.add(rndReduced.sub(senderReduced));
    }
    return ret;
  }

  function switchContractLock() public {
    require(address(msg.sender) == address(_owner));
    contractLock = !contractLock;
  }

  function killContract() private {
    contractLock = true;
  }

  function alterAllowedAmount(uint newAmount) public {
    require(address(msg.sender) == address(_owner));
    allowedAmount = newAmount;
  }

}