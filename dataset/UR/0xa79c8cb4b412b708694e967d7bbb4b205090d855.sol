 

pragma solidity 0.5.13;

  

 
 
 
 
library SafeMath {
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    if (a == 0) {
        return 0;
    }
    uint256 c = a * b;
    require(c / a == b, 'SafeMath mul failed');
    return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
     
    uint256 c = a / b;
     
    return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    require(b <= a, 'SafeMath sub failed');
    return a - b;
    }

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    require(c >= a, 'SafeMath add failed');
    return c;
    }
}


 
 
 
    
contract owned {
    address payable public owner;
    address payable internal newOwner;

    event OwnershipTransferred(address indexed _from, address indexed _to);

    constructor() public {
        owner = msg.sender;
    }

    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }

    function transferOwnership(address payable _newOwner) external onlyOwner {
        newOwner = _newOwner;
    }

     
    function acceptOwnership() external {
        require(msg.sender == newOwner);
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
        newOwner = address(0);
    }
}


interface ERC20Essential 
{
	function balanceOf(address _tokenHolder) external view returns (uint256);
    function transfer(address _to, uint256 _amount) external returns (bool);
    function transferFrom(address _from, address _to, uint256 _amount) external returns (bool);
}




interface ERC777Essential 
{
	function balanceOf(address _tokenHolder) external view returns (uint256);
    function transfer(address _to, uint256 _amount) external returns (bool);
    function transferFrom(address _from, address _to, uint256 _amount) external returns (bool);
}



contract tokenSwapping is owned {
  using SafeMath for uint256;
  uint public exchangeRate;
  address public oldTokenContract;
  address public newTokenContract;
  address public ERC777OwnerAddress;
  uint256 internal tokenAmount;
  uint256 internal newTokenAmount;
  
   
  event Exchanged(uint256 curTime, address oldToken, address newToken, address user, uint oldAmount, uint newAmount);
  
  constructor() public {
    exchangeRate=500;  
  }
  
  function updateERC20ContractAddress(address ERC20Contract) external onlyOwner {
    require(ERC20Contract != address(0), 'Invalid ERC20 token address');
    require(ERC20Contract != newTokenContract, 'ERC20 and ERC777 token addresses cannot be same');
	oldTokenContract = ERC20Contract;
  }
  
  function updateERC777ContractAddress(address ERC777Contract) external onlyOwner {
    require(ERC777Contract != address(0), 'Invalid ERC777 token address');
    require(ERC777Contract != oldTokenContract, 'ERC20 and ERC777 token addresses cannot be same');
	newTokenContract = ERC777Contract;
  }
  
  function updateERC777OwnerAddress(address ERC777Owner) external onlyOwner {
    require(ERC777Owner != address(0), 'Invalid ERC20 token address');
    require(ERC777Owner != newTokenContract, 'Owner address cannot be a Contract Address');
    require(ERC777Owner != oldTokenContract, 'Owner address cannot be a Contract Address');
	ERC777OwnerAddress = ERC777Owner;
  }
  
  function updateExchangeRate(uint256 _exchangeRate) external onlyOwner {
	exchangeRate = _exchangeRate;
  }
  
  function tokenSwap() external {
     
	tokenAmount = ERC20Essential(oldTokenContract).balanceOf(msg.sender);
	require(tokenAmount > 0, "Insufficient Old Token Balance");
	newTokenAmount = tokenAmount.div(exchangeRate);
	require(newTokenAmount <= ERC777Essential(newTokenContract).balanceOf(ERC777OwnerAddress), "Insufficient New Token Balance");
    require(ERC20Essential(oldTokenContract).transferFrom(msg.sender, address(this), tokenAmount), 'old tokens could not be transferred');
    require(ERC777Essential(newTokenContract).transferFrom(ERC777OwnerAddress, msg.sender, newTokenAmount), 'new tokens could not be transferred');
    emit Exchanged(now, oldTokenContract, newTokenContract, msg.sender, tokenAmount, newTokenAmount);
	
  }
}