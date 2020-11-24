 

pragma solidity ^0.5.2;
pragma experimental ABIEncoderV2;

 




 





interface IColony {

  struct Payment {
    address payable recipient;
    bool finalized;
    uint256 fundingPotId;
    uint256 domainId;
    uint256[] skills;
  }

   
   
   
   
   
   
   
   
   
   
   
  function addPayment(
    uint256 _permissionDomainId,
    uint256 _childSkillIndex,
    address payable _recipient,
    address _token,
    uint256 _amount,
    uint256 _domainId,
    uint256 _skillId)
    external returns (uint256 paymentId);

   
   
   
  function getPayment(uint256 _id) external view returns (Payment memory payment);

   
   
   
   
   
   
   
   
  function moveFundsBetweenPots(
    uint256 _permissionDomainId,
    uint256 _fromChildSkillIndex,
    uint256 _toChildSkillIndex,
    uint256 _fromPot,
    uint256 _toPot,
    uint256 _amount,
    address _token
    ) external;

   
   
   
   
   
  function finalizePayment(uint256 _permissionDomainId, uint256 _childSkillIndex, uint256 _id) external;

   
   
   
   
  function claimPayment(uint256 _id, address _token) external;
}
 
library Roles {
    struct Role {
        mapping (address => bool) bearer;
    }

     
    function add(Role storage role, address account) internal {
        require(account != address(0));
        require(!has(role, account));

        role.bearer[account] = true;
    }

     
    function remove(Role storage role, address account) internal {
        require(account != address(0));
        require(has(role, account));

        role.bearer[account] = false;
    }

     
    function has(Role storage role, address account) internal view returns (bool) {
        require(account != address(0));
        return role.bearer[account];
    }
}

 
contract WhitelistAdminRole {
    using Roles for Roles.Role;

    event WhitelistAdminAdded(address indexed account);
    event WhitelistAdminRemoved(address indexed account);

    Roles.Role private _whitelistAdmins;

    constructor () internal {
        _addWhitelistAdmin(msg.sender);
    }

    modifier onlyWhitelistAdmin() {
        require(isWhitelistAdmin(msg.sender));
        _;
    }

    function isWhitelistAdmin(address account) public view returns (bool) {
        return _whitelistAdmins.has(account);
    }

    function addWhitelistAdmin(address account) public onlyWhitelistAdmin {
        _addWhitelistAdmin(account);
    }

    function renounceWhitelistAdmin() public {
        _removeWhitelistAdmin(msg.sender);
    }

    function _addWhitelistAdmin(address account) internal {
        _whitelistAdmins.add(account);
        emit WhitelistAdminAdded(account);
    }

    function _removeWhitelistAdmin(address account) internal {
        _whitelistAdmins.remove(account);
        emit WhitelistAdminRemoved(account);
    }
}

 
contract WhitelistedRole is WhitelistAdminRole {
    using Roles for Roles.Role;

    event WhitelistedAdded(address indexed account);
    event WhitelistedRemoved(address indexed account);

    Roles.Role private _whitelisteds;

    modifier onlyWhitelisted() {
        require(isWhitelisted(msg.sender));
        _;
    }

    function isWhitelisted(address account) public view returns (bool) {
        return _whitelisteds.has(account);
    }

    function addWhitelisted(address account) public onlyWhitelistAdmin {
        _addWhitelisted(account);
    }

    function removeWhitelisted(address account) public onlyWhitelistAdmin {
        _removeWhitelisted(account);
    }

    function renounceWhitelisted() public {
        _removeWhitelisted(msg.sender);
    }

    function _addWhitelisted(address account) internal {
        _whitelisteds.add(account);
        emit WhitelistedAdded(account);
    }

    function _removeWhitelisted(address account) internal {
        _whitelisteds.remove(account);
        emit WhitelistedRemoved(account);
    }
}
 
interface IERC20 {
    function transfer(address to, uint256 value) external returns (bool);

    function approve(address spender, uint256 value) external returns (bool);

    function transferFrom(address from, address to, uint256 value) external returns (bool);

    function totalSupply() external view returns (uint256);

    function balanceOf(address who) external view returns (uint256);

    function allowance(address owner, address spender) external view returns (uint256);

    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval(address indexed owner, address indexed spender, uint256 value);
}

contract BountyPayout is WhitelistedRole {

  uint256 constant DAI_DECIMALS = 10^18;
  uint256 constant PERMISSION_DOMAIN_ID = 1;
  uint256 constant CHILD_SKILL_INDEX = 0;
  uint256 constant DOMAIN_ID = 1;
  uint256 constant SKILL_ID = 0;

  address public colonyAddr;
  address public daiAddr;
  address public leapAddr;

  enum PayoutType { Gardener, Worker, Reviewer }
  event Payout(
    bytes32 indexed bountyId,
    PayoutType indexed payoutType,
    address indexed recipient,
    uint256 amount,
    uint256 paymentId
  );

  constructor(
    address _colonyAddr,
    address _daiAddr,
    address _leapAddr) public {
    colonyAddr = _colonyAddr;
    daiAddr = _daiAddr;
    leapAddr = _leapAddr;
  }

  function _isRepOnly(uint256 amount) internal returns (bool) {
    return ((amount & 0x01) == 1);
  }

  function _makeColonyPayment(address payable _worker, uint256 _amount) internal returns (uint256) {

    IColony colony = IColony(colonyAddr);
     
    uint256 paymentId = colony.addPayment(
      PERMISSION_DOMAIN_ID,
      CHILD_SKILL_INDEX,
      _worker,
      leapAddr,
      _amount,
      DOMAIN_ID,
      SKILL_ID
    );
    IColony.Payment memory payment = colony.getPayment(paymentId);

     
    colony.moveFundsBetweenPots(
      1,  
      0,  
      CHILD_SKILL_INDEX,
      1,  
      payment.fundingPotId,
      _amount,
      leapAddr
    );
    colony.finalizePayment(PERMISSION_DOMAIN_ID, CHILD_SKILL_INDEX, paymentId);

     
    colony.claimPayment(paymentId, leapAddr);
    return paymentId;
  }

  function _payout(
    address payable _gardenerAddr,
    uint256 _gardenerDaiAmount,
    address payable _workerAddr,
    uint256 _workerDaiAmount,
    address payable _reviewerAddr,
    uint256 _reviewerDaiAmount,
    bytes32 _bountyId
  ) internal {
    IERC20 dai = IERC20(daiAddr);

     
     
     
    require(_gardenerDaiAmount > DAI_DECIMALS, "gardener amount too small");
    uint256 paymentId = _makeColonyPayment(_gardenerAddr, _gardenerDaiAmount);
    if (!_isRepOnly(_gardenerDaiAmount)) {
      dai.transferFrom(msg.sender, _gardenerAddr, _gardenerDaiAmount);
    }
    emit Payout(_bountyId, PayoutType.Gardener, _gardenerAddr, _gardenerDaiAmount, paymentId);

     
    if (_workerDaiAmount > 0) {
      paymentId = _makeColonyPayment(_workerAddr, _workerDaiAmount);
      if (!_isRepOnly(_workerDaiAmount)) {
        dai.transferFrom(msg.sender, _workerAddr, _workerDaiAmount);
      }
      emit Payout(_bountyId, PayoutType.Worker, _workerAddr, _workerDaiAmount, paymentId);
    }

     
    if (_reviewerDaiAmount > 0) {
      paymentId = _makeColonyPayment(_reviewerAddr, _reviewerDaiAmount);
      if (!_isRepOnly(_reviewerDaiAmount)) {
        dai.transferFrom(msg.sender, _reviewerAddr, _reviewerDaiAmount);
      }
      emit Payout(_bountyId, PayoutType.Reviewer, _reviewerAddr, _reviewerDaiAmount, paymentId);
    }
  }

  
  function payout(
    bytes32 _gardener,
    bytes32 _worker,
    bytes32 _reviewer,
    bytes32 _bountyId
  ) public onlyWhitelisted {
    _payout(
      address(bytes20(_gardener)),
      uint96(uint256(_gardener)),
      address(bytes20(_worker)),
      uint96(uint256(_worker)),
      address(bytes20(_reviewer)),
      uint96(uint256(_reviewer)),
      _bountyId
    );
  }

  function payoutReviewedDelivery(
    bytes32 _gardener,
    bytes32 _reviewer,
    bytes32 _bountyId
  ) public onlyWhitelisted {
    _payout(
      address(bytes20(_gardener)),
      uint96(uint256(_gardener)),
      address(bytes20(_gardener)),
      0,
      address(bytes20(_reviewer)),
      uint96(uint256(_reviewer)),
      _bountyId
    );
  }

  function payoutNoReviewer(
    bytes32 _gardener,
    bytes32 _worker,
    bytes32 _bountyId
  ) public onlyWhitelisted {
    _payout(
      address(bytes20(_gardener)),
      uint96(uint256(_gardener)),
      address(bytes20(_worker)),
      uint96(uint256(_worker)),
      address(bytes20(_gardener)),
      0,
      _bountyId
    );
  }
}