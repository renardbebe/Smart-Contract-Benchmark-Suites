 

pragma solidity ^0.4.21;


 
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



 
contract ERC20 is ERC20Basic {
  function allowance(address owner, address spender) public view returns (uint256);
  function transferFrom(address from, address to, uint256 value) public returns (bool);
  function approve(address spender, uint256 value) public returns (bool);
  event Approval(address indexed owner, address indexed spender, uint256 value);
}


contract LockingContract is Ownable {
    using SafeMath for uint256;

    event NotedTokens(address indexed _beneficiary, uint256 _tokenAmount);
    event ReleasedTokens(address indexed _beneficiary);
    event ReducedLockingTime(uint256 _newUnlockTime);

    ERC20 public tokenContract;
    mapping(address => uint256) public tokens;
    uint256 public totalTokens;
    uint256 public unlockTime;

    function isLocked() public view returns(bool) {
        return now < unlockTime;
    }

    modifier onlyWhenUnlocked() {
        require(!isLocked());
        _;
    }

    modifier onlyWhenLocked() {
        require(isLocked());
        _;
    }

    function LockingContract(ERC20 _tokenContract, uint256 _unlockTime) public {
        require(_unlockTime > now);
        require(address(_tokenContract) != 0x0);
        unlockTime = _unlockTime;
        tokenContract = _tokenContract;
    }

    function balanceOf(address _owner) public view returns (uint256 balance) {
        return tokens[_owner];
    }

     
     
     
    function noteTokens(address _beneficiary, uint256 _tokenAmount) external onlyOwner onlyWhenLocked {
        uint256 tokenBalance = tokenContract.balanceOf(this);
        require(tokenBalance >= totalTokens.add(_tokenAmount));

        tokens[_beneficiary] = tokens[_beneficiary].add(_tokenAmount);
        totalTokens = totalTokens.add(_tokenAmount);
        emit NotedTokens(_beneficiary, _tokenAmount);
    }

    function releaseTokens(address _beneficiary) public onlyWhenUnlocked {
        require(msg.sender == owner || msg.sender == _beneficiary);
        uint256 amount = tokens[_beneficiary];
        tokens[_beneficiary] = 0;
        require(tokenContract.transfer(_beneficiary, amount)); 
        totalTokens = totalTokens.sub(amount);
        emit ReleasedTokens(_beneficiary);
    }

    function reduceLockingTime(uint256 _newUnlockTime) public onlyOwner onlyWhenLocked {
        require(_newUnlockTime >= now);
        require(_newUnlockTime < unlockTime);
        unlockTime = _newUnlockTime;
        emit ReducedLockingTime(_newUnlockTime);
    }
}