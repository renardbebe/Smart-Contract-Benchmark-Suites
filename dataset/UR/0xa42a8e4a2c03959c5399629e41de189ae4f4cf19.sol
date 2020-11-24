 

pragma solidity ^0.4.24;

contract J8TTokenInterface {
  function balanceOf(address who) public constant returns (uint256);
  function transferFrom(address from, address to, uint256 value) public returns (bool);
  function allowance(address _owner, address _spender) public constant returns (uint256 remaining);
  function approve(address spender, uint256 value) public returns (bool);
}

contract FeeInterface {
  function getFee(uint _base, uint _amount) external view returns (uint256 fee);
}



 
contract Ownable {
  address private _owner;
  address private _admin;

  event OwnershipTransferred(
    address indexed previousOwner,
    address indexed newOwner
  );

  event AdministrationTransferred(
    address indexed previousAdmin,
    address indexed newAdmin
  );


   
  constructor() public {
    _owner = msg.sender;
  }

   
  function owner() public view returns(address) {
    return _owner;
  }

   
  function admin() public view returns(address) {
    return _admin;
  }

   
  modifier onlyOwner() {
    require(isOwner());
    _;
  }

   
  modifier onlyAdmin() {
    require(isAdmin());
    _;
  }

   
  function isOwner() public view returns(bool) {
    return msg.sender == _owner;
  }

   
  function isAdmin() public view returns(bool) {
    return msg.sender == _admin;
  }

   
  function transferOwnership(address newOwner) public onlyOwner {
    _transferOwnership(newOwner);
  }


   
  function _transferOwnership(address newOwner) internal {
    require(newOwner != address(0));
    emit OwnershipTransferred(_owner, newOwner);
    _owner = newOwner;
  }

   
  function transferAdministration(address newAdmin) public onlyOwner {
    _transferAdministration(newAdmin);
  }

   
  function _transferAdministration(address newAdmin) internal {
    require(newAdmin != address(0));
    require(newAdmin != address(this));
    emit AdministrationTransferred(_admin, newAdmin);
    _admin = newAdmin;
  }

}

 

contract Pausable is Ownable {

  event Paused();
  event Unpaused();

  bool private _paused = false;

   
  function paused() public view returns(bool) {
    return _paused;
  }

   
  modifier whenNotPaused() {
    require(!_paused, "Contract is paused");
    _;
  }

   
  modifier whenPaused() {
    require(_paused, "Contract is not paused");
    _;
  }

   
  function pause() public onlyOwner whenNotPaused {
    _paused = true;
    emit Paused();
  }

   
  function unpause() public onlyOwner whenPaused {
    _paused = false;
    emit Unpaused();
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

contract WalletCoordinator is Pausable {

  using SafeMath for uint256;

  J8TTokenInterface public tokenContract;
  FeeInterface public feeContract;
  address public custodian;

  event TransferSuccess(
    address indexed fromAddress,
    address indexed toAddress,
    uint amount,
    uint networkFee
  );

  event TokenAddressUpdated(
    address indexed oldAddress,
    address indexed newAddress
  );

  event FeeContractAddressUpdated(
    address indexed oldAddress,
    address indexed newAddress
  );

  event CustodianAddressUpdated(
    address indexed oldAddress,
    address indexed newAddress
  );

   
  function transfer(address _fromAddress, address _toAddress, uint _amount, uint _baseFee) public onlyAdmin whenNotPaused {
    require(_amount > 0, "Amount must be greater than zero");
    require(_fromAddress != _toAddress,  "Addresses _fromAddress and _toAddress are equal");
    require(_fromAddress != address(0), "Address _fromAddress is 0x0");
    require(_fromAddress != address(this), "Address _fromAddress is smart contract address");
    require(_toAddress != address(0), "Address _toAddress is 0x0");
    require(_toAddress != address(this), "Address _toAddress is smart contract address");

    uint networkFee = feeContract.getFee(_baseFee, _amount);
    uint fromBalance = tokenContract.balanceOf(_fromAddress);

    require(_amount <= fromBalance, "Insufficient account balance");

    require(tokenContract.transferFrom(_fromAddress, _toAddress, _amount.sub(networkFee)), "transferFrom did not succeed");
    require(tokenContract.transferFrom(_fromAddress, custodian, networkFee), "transferFrom fee did not succeed");

    emit TransferSuccess(_fromAddress, _toAddress, _amount, networkFee);
  }

  function getFee(uint _base, uint _amount) public view returns (uint256) {
    return feeContract.getFee(_base, _amount);
  }

  function setTokenInterfaceAddress(address _newAddress) external onlyOwner whenPaused returns (bool) {
    require(_newAddress != address(this), "The new token address is equal to the smart contract address");
    require(_newAddress != address(0), "The new token address is equal to 0x0");
    require(_newAddress != address(tokenContract), "The new token address is equal to the old token address");

    address _oldAddress = tokenContract;
    tokenContract = J8TTokenInterface(_newAddress);

    emit TokenAddressUpdated(_oldAddress, _newAddress);

    return true;
  }

  function setFeeContractAddress(address _newAddress) external onlyOwner whenPaused returns (bool) {
    require(_newAddress != address(this), "The new fee contract address is equal to the smart contract address");
    require(_newAddress != address(0), "The new fee contract address is equal to 0x0");

    address _oldAddress = feeContract;
    feeContract = FeeInterface(_newAddress);

    emit FeeContractAddressUpdated(_oldAddress, _newAddress);

    return true;
  }

  function setCustodianAddress(address _newAddress) external onlyOwner returns (bool) {
    require(_newAddress != address(this), "The new custodian address is equal to the smart contract address");
    require(_newAddress != address(0), "The new custodian address is equal to 0x0");

    address _oldAddress = custodian;
    custodian = _newAddress;

    emit CustodianAddressUpdated(_oldAddress, _newAddress);

    return true;
  }
}