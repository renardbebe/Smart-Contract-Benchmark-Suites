 

pragma solidity ^0.4.18;


 
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

 
 
 
contract TkoWhitelist is Ownable{

    using SafeMath for uint256;

     
    address public admin;

    mapping(address => uint256) internal totalIndividualWeiAmount;
    mapping(address => bool) internal whitelist;

    event AdminChanged(address indexed previousAdmin, address indexed newAdmin);


     
    function TkoWhitelist (address _admin) public {
        require(_admin != address(0));
        admin = _admin;
    }

     
    modifier onlyOwnerOrAdmin() {
        require(msg.sender == owner || msg.sender == admin);
        _;
    }

     
    function changeAdmin(address newAdmin) public onlyOwner {
        require(newAdmin != address(0));
        emit AdminChanged(admin, newAdmin);
        admin = newAdmin;
    }


     
    function isWhitelisted(address _beneficiary) external view onlyOwnerOrAdmin returns (bool) {
        return whitelist[_beneficiary];
    }

     
    function addToWhitelist(address _beneficiary) external onlyOwnerOrAdmin {
        whitelist[_beneficiary] = true;
    }

     
    function addManyToWhitelist(address[] _beneficiaries) external onlyOwnerOrAdmin {
        for (uint256 i = 0; i < _beneficiaries.length; i++) {
            whitelist[_beneficiaries[i]] = true;
        }
    }

     
    function removeFromWhitelist(address _beneficiary) external onlyOwnerOrAdmin {
        whitelist[_beneficiary] = false;
    }

     
    function getTotalIndividualWeiAmount(address _beneficiary) external view onlyOwnerOrAdmin returns (uint256) {
        return totalIndividualWeiAmount[_beneficiary];
    }

     
    function setTotalIndividualWeiAmount(address _beneficiary,uint256 _totalWeiAmount) external onlyOwner {
        totalIndividualWeiAmount[_beneficiary] = _totalWeiAmount;
    }

     
    function addTotalIndividualWeiAmount(address _beneficiary,uint256 _weiAmount) external onlyOwner {
        totalIndividualWeiAmount[_beneficiary] = totalIndividualWeiAmount[_beneficiary].add(_weiAmount);
    }

}