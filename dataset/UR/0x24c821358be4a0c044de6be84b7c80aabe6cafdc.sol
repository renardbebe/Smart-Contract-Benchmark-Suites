 

pragma solidity 0.4.25;

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

contract ERC20 {
  function totalSupply() public view returns (uint256);
  function balanceOf(address who) public view returns (uint256);
  function transfer(address to, uint256 value) public returns (bool);
  function allowance(address owner, address spender)
    public view returns (uint256);

  function transferFrom(address from, address to, uint256 value)
    public returns (bool);

  function approve(address spender, uint256 value) public returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
  event Approval(
    address indexed owner,
    address indexed spender,
    uint256 value
  );
}


library SafeERC20 {
  function safeTransfer(ERC20 token, address to, uint256 value) internal {
    require(token.transfer(to, value));
  }

  function safeTransferFrom(
    ERC20 token,
    address from,
    address to,
    uint256 value
  )
    internal
  {
    require(token.transferFrom(from, to, value));
  }

  function safeApprove(ERC20 token, address spender, uint256 value) internal {
    require(token.approve(spender, value));
  }
}


 
contract CGCXMarchMassLock is Ownable {
  using SafeERC20 for ERC20;

   
  ERC20 public token;

   
  mapping (address => uint256) public lockups;

   
  uint256 public releaseTime;

  constructor(address _token, uint256 _releaseTime) public {
     
    token = ERC20(_token);
    releaseTime = _releaseTime;
  }

  function release() public  {
    releaseFrom(msg.sender);
  }

  function releaseFrom(address _beneficiary) public {
    require(block.timestamp >= releaseTime);
    uint256 amount = lockups[_beneficiary];
    require(amount > 0);
    token.safeTransfer(_beneficiary, amount);
    lockups[_beneficiary] = 0;
  }

  function releaseFromMultiple(address[] _addresses) public {
    for (uint256 i = 0; i < _addresses.length; i++) {
      releaseFrom(_addresses[i]);
    }
  } 

  function submit(address[] _addresses, uint256[] _amounts) public onlyOwner {
    for (uint256 i = 0; i < _addresses.length; i++) {
      lockups[_addresses[i]] = _amounts[i];
    }
  }

}