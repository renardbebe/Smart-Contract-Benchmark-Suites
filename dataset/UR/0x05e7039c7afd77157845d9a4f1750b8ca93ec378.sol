 

pragma solidity ^0.4.24;


 
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


contract GoodLuckCasino is Ownable{
    using SafeMath for uint;

    event LOG_Deposit(bytes32 userID, bytes32 depositID, address walletAddr, uint amount);
    event LOG_Withdraw(address user, uint amount);

    event LOG_Bankroll(address sender, uint value);
    event LOG_OwnerWithdraw(address _to, uint _val);

    event LOG_ContractStopped();
    event LOG_ContractResumed();

    bool public isStopped;

    mapping (bytes32 => mapping(bytes32 => uint)) depositList;

    modifier onlyIfNotStopped {
        require(!isStopped);
        _;
    }

    modifier onlyIfStopped {
        require(isStopped);
        _;
    }

    constructor() public {
    }

    function () payable public {
        revert();
    }

    function bankroll() payable public onlyOwner {
        emit LOG_Bankroll(msg.sender, msg.value);
    }

    function userDeposit(bytes32 _userID, bytes32 _depositID) payable public onlyIfNotStopped {
        depositList[_userID][_depositID] = msg.value;
        emit LOG_Deposit(_userID, _depositID, msg.sender, msg.value);
    }

    function userWithdraw(address _to, uint _amount) public onlyOwner onlyIfNotStopped{
        _to.transfer(_amount);
        emit LOG_Withdraw(_to, _amount);
    }

    function ownerWithdraw(address _to, uint _val) public onlyOwner{
        require(address(this).balance > _val);
        _to.transfer(_val);
        emit LOG_OwnerWithdraw(_to, _val);
    }

    function getUserDeposit(bytes32 _userID, bytes32 _depositID) view public returns (uint) {
        return depositList[_userID][_depositID];
    }

    function stopContract() public onlyOwner onlyIfNotStopped {
        isStopped = true;
        emit LOG_ContractStopped();
    }

    function resumeContract() public onlyOwner onlyIfStopped {
        isStopped = false;
        emit LOG_ContractResumed();
    }
}