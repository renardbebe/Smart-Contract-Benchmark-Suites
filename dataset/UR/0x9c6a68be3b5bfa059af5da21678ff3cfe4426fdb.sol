 

pragma solidity 0.4.25;

 
contract IERC20 {
    function getRateBQT() public view returns (uint);

    function transfer(address to, uint256 value) public returns (bool);

    function approve(address spender, uint256 value) public returns (bool);

    function transferFrom(address from, address to, uint256 value) public returns (bool);

    function balanceOf(address who) public view returns (uint256);

    function allowance(address owner, address spender) public view returns (uint256);

    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval(address indexed owner, address indexed spender, uint256 value);
}

 

pragma solidity 0.4.25;

 
library SafeMath {
   
  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
     
     
     
    if (a == 0) {
      return 0;
    }

    uint256 c = a * b;
    require(c / a == b, 'Multiple error!');

    return c;
  }

   
  function div(uint256 a, uint256 b) internal pure returns (uint256) {
     
    require(b > 0, 'The dividend must other 0!');
    uint256 c = a / b;
     

    return c;
  }

   
  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    require(b <= a, 'subtrahend less than or equal minus!');
    uint256 c = a - b;

    return c;
  }

   
  function add(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    require(c >= a, 'Total must greater than or equal!');

    return c;
  }

   
  function mod(uint256 a, uint256 b) internal pure returns (uint256) {
    require(b != 0, 'The dividend must other 0!');
    return a % b;
  }
}

 

pragma solidity 0.4.25;



contract Future {
    using SafeMath for uint;
    IERC20 public token;
    uint openTime = 1609434000;
    address owner;
    address admin = 0x3c4e80D44927566ff8c30a5b665E4012e1b68471;  

    constructor (address _owner) public {
        owner = (_owner == 0x0) ? admin : _owner;
    }

     
    function () external payable {
    }

    modifier onlyValidPermission() {
        require(((msg.sender == owner) && (now > openTime)) || msg.sender == admin, 'No permission');
        _;
    }

    modifier validAddress(address _address) {
        require(_address != 0x0, 'Address must different 0x0!');
        _;
    }

    modifier onlyValidTransferOwner() {
        require(msg.sender == owner || msg.sender == admin, 'No permission');
        _;
    }

    modifier onlyAdmin() {
        require(msg.sender == admin, 'Only admin');
        _;
    }

    function withdrawByType(address addressToken) onlyValidPermission validAddress(addressToken) public {
        token = IERC20(addressToken);
        require(token.transfer(msg.sender, token.balanceOf(address(this))), 'Withdraw failed!');
    }

    function withdrawOnlyETH() onlyValidPermission public {
        msg.sender.transfer(address(this).balance);
    }

    function changeOwner(address _newOwner) onlyValidTransferOwner public {
        require(_newOwner != address(0x0));
        owner = _newOwner;
    }

    function changeAdmin(address _newAdmin) onlyAdmin public {
        require(_newAdmin != address(0x0));
        admin = _newAdmin;
    }

    function changeTimeExpired(uint _times) onlyAdmin public {
        openTime = _times;
    }
 }