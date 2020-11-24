 

pragma solidity ^0.4.24;

 
contract ReentrancyGuard {

   
   
  uint private constant REENTRANCY_GUARD_FREE = 1;

   
  uint private constant REENTRANCY_GUARD_LOCKED = 2;

   
  uint private reentrancyLock = REENTRANCY_GUARD_FREE;

   
  modifier nonReentrant() {
    require(reentrancyLock == REENTRANCY_GUARD_FREE);
    reentrancyLock = REENTRANCY_GUARD_LOCKED;
    _;
    reentrancyLock = REENTRANCY_GUARD_FREE;
  }

}

 
library SafeMath {

   
  function mul(uint256 _a, uint256 _b) internal pure returns (uint256 c) {
     
     
     
    if (_a == 0) {
      return 0;
    }

    c = _a * _b;
    assert(c / _a == _b);
    return c;
  }

   
  function div(uint256 _a, uint256 _b) internal pure returns (uint256) {
     
     
     
    return _a / _b;
  }

   
  function sub(uint256 _a, uint256 _b) internal pure returns (uint256) {
    assert(_b <= _a);
    return _a - _b;
  }

   
  function add(uint256 _a, uint256 _b) internal pure returns (uint256 c) {
    c = _a + _b;
    assert(c >= _a);
    return c;
  }
}

 
contract Ownable {
  address public owner;

  event OwnershipRenounced(address indexed previousOwner);
  event OwnershipTransferred(
    address indexed previousOwner,
    address indexed newOwner
  );

   
  constructor() public {
    owner = msg.sender;
  }

   
  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }

   
  function renounceOwnership() public onlyOwner {
    emit OwnershipRenounced(owner);
    owner = address(0);
  }

   
  function transferOwnership(address _newOwner) public onlyOwner {
    _transferOwnership(_newOwner);
  }

   
  function _transferOwnership(address _newOwner) internal {
    require(_newOwner != address(0));
    emit OwnershipTransferred(owner, _newOwner);
    owner = _newOwner;
  }
}

interface ERC20 {
    function totalSupply() external view returns (uint supply);
    function balanceOf(address _owner) external view returns (uint balance);
    function transfer(address _to, uint _value) external returns (bool success);
    function transferFrom(address _from, address _to, uint _value) external returns (bool success);
    function approve(address _spender, uint _value) external returns (bool success);
    function allowance(address _owner, address _spender) external view returns (uint remaining);
    function decimals() external view returns(uint digits);
    event Approval(address indexed _owner, address indexed _spender, uint _value);
}

 

contract JobsBounty is Ownable, ReentrancyGuard {
    using SafeMath for uint256;
    string public companyName;  
    string public jobPost;  
    uint public endDate;  
    
     
     
     
     
    
    address public INDToken;
    
    constructor(string _companyName,
                string _jobPost,
                uint _endDate,
                address _INDToken
                ) public{
        companyName = _companyName;
        jobPost = _jobPost ;
        endDate = _endDate;
        INDToken = _INDToken;
    }
    
     
    function ownBalance() public view returns(uint256) {
        return SafeMath.div(ERC20(INDToken).balanceOf(this),1 ether);
    }
    
    function payOutBounty(address _referrerAddress, address _candidateAddress) external onlyOwner nonReentrant returns(bool){
        assert(block.timestamp >= endDate);
        assert(_referrerAddress != address(0x0));
        assert(_candidateAddress != address(0x0));
        
        uint256 individualAmounts = SafeMath.mul(SafeMath.div((ERC20(INDToken).balanceOf(this)),100),50);
        
         
        assert(ERC20(INDToken).transfer(_candidateAddress, individualAmounts));
        assert(ERC20(INDToken).transfer(_referrerAddress, individualAmounts));
        return true;    
    }
    
     
     
     
    function withdrawERC20Token(address anyToken) external onlyOwner nonReentrant returns(bool){
        assert(block.timestamp >= endDate);
        assert(ERC20(anyToken).transfer(owner, ERC20(anyToken).balanceOf(this)));        
        return true;
    }
    
     
     
    function withdrawEther() external onlyOwner nonReentrant returns(bool){
        if(address(this).balance > 0){
            owner.transfer(address(this).balance);
        }        
        return true;
    }
}