 

pragma solidity 0.4.24;


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


 
contract CGCXTimelockFixedBasic {
  using SafeERC20 for ERC20;

   
  ERC20 public token;

   
  address public beneficiary;

   
  uint256 public releaseTime = 1540857600;

  constructor(
    address _token,
    address _beneficiary
  )
    public
  {
    require(_beneficiary != address(0));
     
    token = ERC20(_token);
    beneficiary = _beneficiary;
  }

   
  function release() public {
    uint256 amount;
     
    if (block.timestamp >= releaseTime) {
      amount = token.balanceOf(this);
      require(amount > 0);
      token.safeTransfer(beneficiary, amount);
      releaseTime = 0;
    } else {
      revert();
    }
  }


}