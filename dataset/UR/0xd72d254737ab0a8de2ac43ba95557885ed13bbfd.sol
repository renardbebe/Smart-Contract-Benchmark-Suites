 

pragma solidity ^0.4.13;

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

contract ERC20Basic {
  function totalSupply() public view returns (uint256);
  function balanceOf(address _who) public view returns (uint256);
  function transfer(address _to, uint256 _value) public returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
}

contract ERC20 is ERC20Basic {
  function allowance(address _owner, address _spender)
    public view returns (uint256);

  function transferFrom(address _from, address _to, uint256 _value)
    public returns (bool);

  function approve(address _spender, uint256 _value) public returns (bool);
  event Approval(
    address indexed owner,
    address indexed spender,
    uint256 value
  );
}

library SafeERC20 {
  function safeTransfer(
    ERC20Basic _token,
    address _to,
    uint256 _value
  )
    internal
  {
    require(_token.transfer(_to, _value));
  }

  function safeTransferFrom(
    ERC20 _token,
    address _from,
    address _to,
    uint256 _value
  )
    internal
  {
    require(_token.transferFrom(_from, _to, _value));
  }

  function safeApprove(
    ERC20 _token,
    address _spender,
    uint256 _value
  )
    internal
  {
    require(_token.approve(_spender, _value));
  }
}

contract MenloTokenTimelock is Ownable {
  using SafeERC20 for ERC20Basic;

   
  ERC20Basic public token;

  mapping (address => uint256) public balance;

   
  uint256 public releaseTime;

  constructor(ERC20Basic _token, uint256 _releaseTime) public {
    require(_releaseTime > now, "Release time should be in the future");
    token = _token;
    releaseTime = _releaseTime;
  }

  function deposit(address _beneficiary, uint256 _amount) public onlyOwner {
    balance[_beneficiary] += _amount;
  }

   
  function release() public {
    require(getBlockTimestamp() >= releaseTime, "Release time should be now or in the past");

    uint256 _amount = token.balanceOf(this);
    require(_amount > 0, "Contract balance should be greater than zero");

    require(balance[msg.sender] > 0, "Sender balance should be greater than zero");
    require(_amount >= balance[msg.sender], "Expected contract balance to be greater than or equal to sender balance");
    token.transfer(msg.sender, balance[msg.sender]);
    balance[msg.sender] = 0;
  }

  function getBlockTimestamp() internal view returns (uint256) {
    return block.timestamp;
  }
}