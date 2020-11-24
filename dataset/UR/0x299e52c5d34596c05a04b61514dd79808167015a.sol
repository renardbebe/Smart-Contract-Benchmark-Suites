 

pragma solidity ^0.5.0;

 
interface IERC20 {
     
    function totalSupply() external view returns (uint256);

     
    function balanceOf(address account) external view returns (uint256);

     
    function transfer(address recipient, uint256 amount) external returns (bool);

     
    function allowance(address owner, address spender) external view returns (uint256);

     
    function approve(address spender, uint256 amount) external returns (bool);

     
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

     
    event Transfer(address indexed from, address indexed to, uint256 value);

     
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

contract TreasureHunt {
  bool public isActive;
  bytes32 hashedSecret;
  address DGX_TOKEN_ADDRESS;

   
   
  constructor(bytes32 _hashedSecret, address _dgx_token_address) public {
     
    hashedSecret = _hashedSecret;

     
    DGX_TOKEN_ADDRESS = _dgx_token_address;

     
    isActive = true;
  }

  function unlockTreasure(bytes32 _secret) public {
     
    require(isActive, "treasure inactive");

     
     
    require(keccak256(abi.encodePacked(_secret)) == hashedSecret, "incorrect secret");

     
     
    uint256 _dgxBalance = IERC20(DGX_TOKEN_ADDRESS).balanceOf(address(this));
    require(IERC20(DGX_TOKEN_ADDRESS).transfer(msg.sender, _dgxBalance), "could not transfer DGX");

     
    isActive = false;
  }
}