 

pragma solidity ^0.4.25;

 

 
contract Ownable {
  address private _owner;

  event OwnershipTransferred(
    address indexed previousOwner,
    address indexed newOwner
  );

   
  constructor() internal {
    _owner = msg.sender;
    emit OwnershipTransferred(address(0), _owner);
  }

   
  function owner() public view returns(address) {
    return _owner;
  }

   
  modifier onlyOwner() {
    require(isOwner());
    _;
  }

   
  function isOwner() public view returns(bool) {
    return msg.sender == _owner;
  }

   
  function renounceOwnership() public onlyOwner {
    emit OwnershipTransferred(_owner, address(0));
    _owner = address(0);
  }

   
  function transferOwnership(address newOwner) public onlyOwner {
    _transferOwnership(newOwner);
  }

   
  function _transferOwnership(address newOwner) internal {
    require(newOwner != address(0));
    emit OwnershipTransferred(_owner, newOwner);
    _owner = newOwner;
  }
}

 

 
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

 

 
interface IERC20 {
  function totalSupply() external view returns (uint256);

  function balanceOf(address who) external view returns (uint256);

  function allowance(address owner, address spender)
    external view returns (uint256);

  function transfer(address to, uint256 value) external returns (bool);

  function approve(address spender, uint256 value)
    external returns (bool);

  function transferFrom(address from, address to, uint256 value)
    external returns (bool);

  event Transfer(
    address indexed from,
    address indexed to,
    uint256 value
  );

  event Approval(
    address indexed owner,
    address indexed spender,
    uint256 value
  );
}

 

contract Batch is Ownable {
    using SafeMath for uint256;

    address public constant daiContractAddress = 0x89d24a6b4ccb1b6faa2625fe562bdd9a23260359;
    uint256 public constant daiGift = 1000000000000000000;
    uint256 public constant ethGift = 5500000000000000;
    uint256 public constant size = 80;

    function distributeEth(address[] _recipients)
        public
        payable
        onlyOwner
    {
        require(_recipients.length == size, "recipients array has incorrect size");
        require(msg.value == ethGift * size, "msg.value is not exact");

        for (uint i = 0; i < _recipients.length; i++) {
            _recipients[i].transfer(ethGift);
        }
    }

    function distributeDai(address[] _recipients)
        public
        onlyOwner
    {
        require(_recipients.length == size, "recipients array has incorrect size");

        uint256 distribution = daiGift.mul(size);
        IERC20 daiContract = IERC20(daiContractAddress);
        uint256 allowance = daiContract.allowance(msg.sender, address(this));
        require(
            allowance >= distribution,
            "contract not allowed to transfer enough tokens"
        );

        for (uint i = 0; i < _recipients.length; i++) {
            daiContract.transferFrom(msg.sender, _recipients[i], daiGift);
        }
    }
}