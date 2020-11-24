 

pragma solidity ^0.4.25;

 
library SafeMath {

     
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a, "SafeMath: subtraction overflow");
        uint256 c = a - b;

        return c;
    }

     
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

   function mul(uint256 a, uint256 b) internal pure returns (uint256) {
         
         
         
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

}

contract ERC20Basic {
  uint256 public totalSupply;
  function balanceOf(address who) public view returns (uint256);
  function transfer(address to, uint256 value) public returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
}

 
contract ERC20 is ERC20Basic {
  function allowance(address owner, address spender) public view returns (uint256);
  function transferFrom(address from, address to, uint256 value) public returns (bool);
  function approve(address spender, uint256 value) public returns (bool);
  event Approval(address indexed owner, address indexed spender, uint256 value);
}

 
library SafeERC20 {
  function safeTransfer(ERC20Basic token, address to, uint256 value) internal {
    assert(token.transfer(to, value));
  }

  function safeTransferFrom(ERC20 token, address from, address to, uint256 value) internal {
    assert(token.transferFrom(from, to, value));
  }

  function safeApprove(ERC20 token, address spender, uint256 value) internal {
    assert(token.approve(spender, value));
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

   
  function transferOwnership(address newOwner) public onlyOwner {
    require(newOwner != address(0));
    emit OwnershipTransferred(owner, newOwner);
    owner = newOwner;
  }

}

 
contract BiggDistribution is Ownable {

  using SafeMath for uint256;
  using SafeERC20 for ERC20;

  uint256 private constant decimalFactor = 10**uint256(18);

  uint256 public startTime;
  ERC20 public tokenContract;
  uint256 public AVAILABLE_DISTRIBUTION_SUPPLY  =   10000000 * decimalFactor;
  

  uint256 public totalDistributed = 0;
  uint256 public totalCount = 0;
  uint256 public batchNumber = 0;

   
  mapping (address => bool) public distributed;

  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }

  event BIGGDistributed(uint256 indexed _batchNumber, uint256 _distributionAmount,  uint256 _distributionCount, uint256 _totalCount, uint256 _totalDistributed, uint256 _totalLeft);
  event BIGGDistributionUnprocessed(uint256 indexed _batchNumber, uint256 _index, address _recipient,  uint256 _amount, bool _distributed);


  constructor(address _tokenContract, uint256 _startTime) public {
    require(_startTime >= now);
    startTime = _startTime;
    tokenContract = ERC20(_tokenContract);
  }


  function distributeTokens(address[] memory _recipient, uint256[] memory _amount) public onlyOwner {
    require(now >= startTime);
    require(_recipient.length == _amount.length);

    uint256 distributedCount = 0;
    uint256 distributedAmount = 0;
    uint256 ethAmount;
    uint256 totalLeft;

    totalLeft = tokenContract.balanceOf(address(this));
    batchNumber = batchNumber.add(1);
    for(uint256 i = 0; i < _recipient.length; i++)
    {
        if (!distributed[_recipient[i]] && _recipient[i] != address(0) && _amount[i] != 0) {
          ethAmount = _amount[i].mul(decimalFactor);
          if (totalLeft >= ethAmount)
            tokenContract.transfer(_recipient[i], ethAmount);
          else
            require(false, "Cannot process batch, no more tokens left.");
          distributed[_recipient[i]] = true;
          distributedAmount = distributedAmount.add(ethAmount);
          distributedCount = distributedCount.add(1);
          totalCount = totalCount.add(1);
          totalLeft = totalLeft.sub(ethAmount);
          totalDistributed = totalDistributed.add(ethAmount);
        } else {
          emit BIGGDistributionUnprocessed(batchNumber, i+1, _recipient[i], _amount[i], distributed[_recipient[i]]);
        }

    }
    
    emit BIGGDistributed(batchNumber, distributedAmount, distributedCount, totalCount, totalDistributed, totalLeft);

  }

  function closeContract() public onlyOwner {  
    tokenContract.transfer(owner, tokenContract.balanceOf(this));
    selfdestruct(owner);   
  }
}