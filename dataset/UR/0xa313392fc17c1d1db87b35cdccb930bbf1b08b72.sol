 

pragma solidity ^0.5.8;

contract ERC20Interface {
  function totalSupply() public view returns (uint);
  function balanceOf(address tokenOwner) public view returns (uint balance);
  function allowance(address tokenOwner, address spender) public view returns (uint remaining);
  function transfer(address to, uint tokens) public returns (bool success);
  function approve(address spender, uint tokens) public returns (bool success);
  function transferFrom(address from, address to, uint tokens) public returns (bool success);

  event Transfer(address indexed from, address indexed to, uint tokens);
  event Approval(address indexed tokenOwner, address indexed spender, uint tokens);
}


 
 
 
 
 
contract Multisig {

  address[] public owners;

  mapping (address => mapping(address => uint)) withdrawalRequests;
  mapping (address => mapping(address => address[])) withdrawalApprovals;

  mapping (address => address[]) ownershipAdditions;
  mapping (address => address[]) ownershipRemovals;

  event ApproveNewOwner(address indexed approver, address indexed subject);
  event ApproveRemovalOfOwner(address indexed approver, address indexed subject);
  event OwnershipChange(address indexed owner, bool indexed isAddition, bool indexed isRemoved);
  event Deposit(address indexed tokenContract, address indexed sender, uint amount);
  event Withdrawal(address indexed tokenContract, address indexed recipient, uint amount);
  event WithdrawalRequest(address indexed tokenContract, address indexed recipient, uint amount);
  event WithdrawalApproval(address indexed tokenContract, address indexed approver, address indexed recipient, uint amount);

  function getOwners()
    public
    view
  returns(address[] memory) {
    return owners;
  }

  function getOwnershipAdditions(address _account)
    public
    view
  returns(address[] memory) {
    return ownershipAdditions[_account];
  }

  function getOwnershipRemovals(address _account)
    public
    view
  returns(address[] memory) {
    return ownershipRemovals[_account];
  }

  function getWithdrawalApprovals(address _erc20, address _account)
    public
    view
  returns(uint amount, address[] memory approvals) {
    amount = withdrawalRequests[_erc20][_account];
    approvals = withdrawalApprovals[_erc20][_account];
  }

  function getMinimumApprovals()
    public
    view
  returns(uint approvalCount) {
    approvalCount = (owners.length + 1) / 2;
  }

  modifier isOwner(address _test) {
    require(_isOwner(_test) == true, "address must be an owner");
    _;
  }

  modifier isNotOwner(address _test) {
    require(_isOwner(_test) == false, "address must NOT be an owner");
    _;
  }

  modifier isNotMe(address _test) {
    require(msg.sender != _test, "test must not be sender");
    _;
  }

  constructor(address _owner2, address _owner3)
    public
  {
    require(msg.sender != _owner2, "owner 1 and 2 can't be the same");
    require(msg.sender != _owner3, "owner 1 and 3 can't be the same");
    require(_owner2 != _owner3, "owner 2 and 3 can't be the same");
    require(_owner2 != address(0), "owner 2 can't be the zero address");
    require(_owner3 != address(0), "owner 2 can't be the zero address");
    owners.push(msg.sender);
    owners.push(_owner2);
    owners.push(_owner3);
  }

  function _isOwner(address _test)
    internal
    view
  returns(bool) {
    for(uint i = 0; i < owners.length; i++) {
      if(_test == owners[i]) {
        return true;
      }
    }
    return false;
  }

   
   
  function approveOwner(address _address)
    public
    isOwner(msg.sender)
    isNotOwner(_address)
    isNotMe(_address)
  {
    require(owners.length < 10, "no more than 10 owners");
    for(uint i = 0; i < ownershipAdditions[_address].length; i++) {
      require(ownershipAdditions[_address][i] != msg.sender, "sender has not already approved this removal");
    }
    ownershipAdditions[_address].push(msg.sender);
    emit ApproveNewOwner(msg.sender, _address);
  }

   
  function acceptOwnership()
    external
    isNotOwner(msg.sender)
  {
    require(
      ownershipAdditions[msg.sender].length >= getMinimumApprovals(),
      "sender doesn't have enough ownership approvals");
    owners.push(msg.sender);
    delete ownershipAdditions[msg.sender];
    emit OwnershipChange(msg.sender, true, false);
  }

   
   
   
  function removeOwner(address _address)
    public
    isOwner(msg.sender)
    isOwner(_address)
    isNotMe(_address)
  {
    require(owners.length > 3, "can't remove below 3 owners - add a new owner first");
    uint i;
    for(i = 0; i < ownershipRemovals[_address].length; i++) {
      require(ownershipRemovals[_address][i] != msg.sender, "sender must not have already approved this removal");
    }
    emit ApproveRemovalOfOwner(msg.sender, _address);
    ownershipRemovals[_address].push(msg.sender);
     
     
    if(ownershipRemovals[_address].length >= getMinimumApprovals()) {
      for(i = 0; i < owners.length; i++) {
        if(owners[i] == _address) {
          uint lastSlot = owners.length - 1;
          owners[i] = owners[lastSlot];
          owners[lastSlot] = address(0);
          owners.length = lastSlot;
          break;
        }
      }
      delete ownershipRemovals[_address];
      emit OwnershipChange(_address, false, true);
    }
  }

   
   
   
  function vetoRemoval(address _address)
    public
    isOwner(msg.sender)
    isOwner(_address)
    isNotMe(_address)
  {
    delete ownershipRemovals[_address];
  }

   
   
  function vetoOwnership(address _address)
    public
    isOwner(msg.sender)
    isNotMe(_address)
  {
    delete ownershipAdditions[_address];
  }

   
   
   
  function vetoWithdrawal(address _tokenContract, address _requestor)
    public
    isOwner(msg.sender)
  {
    delete withdrawalRequests[_tokenContract][_requestor];
    delete withdrawalApprovals[_tokenContract][_requestor];
  }

   
   
   
   
   
   
  function depositERC20(address _tokenContract, uint _amount)
    public
    isOwner(msg.sender)
  {
    ERC20Interface erc20 = ERC20Interface(_tokenContract);
    emit Deposit(_tokenContract, msg.sender, _amount);
    erc20.transferFrom(msg.sender, address(this), _amount);
  }

   
   
  function depositEth()
    public
    payable
    isOwner(msg.sender)
  {
    emit Deposit(address(0), msg.sender, msg.value);
  }


   
   
   
   
   
   
  function approveWithdrawal(address _tokenContract, address _recipient, uint _amount)
    public
    isOwner(msg.sender)
  {
    ERC20Interface erc20 = ERC20Interface(_tokenContract);
     
    require(_amount > 0, "can't withdraw zero");
    if (_recipient == msg.sender) {
      if(_tokenContract == address(0)) {
        require(_amount <= address(this).balance, "can't withdraw more ETH than the balance");
      } else {
        require(_amount <= erc20.balanceOf(address(this)), "can't withdraw more erc20 tokens than balance");
      }
      delete withdrawalApprovals[_tokenContract][_recipient];
      withdrawalRequests[_tokenContract][_recipient] = _amount;
      withdrawalApprovals[_tokenContract][_recipient].push(msg.sender);
      emit WithdrawalRequest(_tokenContract, _recipient, _amount);
    } else {
      require(
        withdrawalApprovals[_tokenContract][_recipient].length >= 1,
        "you can't initiate a withdrawal request for another user");
      require(
        withdrawalRequests[_tokenContract][_recipient] == _amount,
        "approval amount must exactly match withdrawal request");
      for(uint i = 0; i < withdrawalApprovals[_tokenContract][_recipient].length; i++) {
        require(
          withdrawalApprovals[_tokenContract][_recipient][i] != msg.sender,
          "sender has not already approved this withdrawal");
      }
      withdrawalApprovals[_tokenContract][_recipient].push(msg.sender);
    }
    emit WithdrawalApproval(_tokenContract, msg.sender, _recipient, _amount);
  }

   
   
   
  function completeWithdrawal(address _tokenContract, uint _amount)
    external
    isOwner(msg.sender)
  {
    require(
      withdrawalApprovals[_tokenContract][msg.sender].length >= getMinimumApprovals(),
      "insufficient approvals to complete this withdrawal");
    require(withdrawalRequests[_tokenContract][msg.sender] == _amount, "incorrect withdrawal amount specified");
    delete withdrawalRequests[_tokenContract][msg.sender];
    delete withdrawalApprovals[_tokenContract][msg.sender];
    emit Withdrawal(_tokenContract, msg.sender, _amount);
    if(_tokenContract == address(0)) {
      require(_amount <= address(this).balance, "can't withdraw more ETH than the balance");
      msg.sender.transfer(_amount);
    } else {
      ERC20Interface erc20 = ERC20Interface(_tokenContract);
      require(_amount <= erc20.balanceOf(address(this)), "can't withdraw more erc20 tokens than balance");
      erc20.transfer(msg.sender, _amount);
    }
  }
}