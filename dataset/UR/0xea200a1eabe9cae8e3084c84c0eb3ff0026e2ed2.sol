 

pragma solidity 0.5.8;

 
interface IERC20 {
    function transfer(address to, uint256 value) external returns (bool);

    function approve(address spender, uint256 value) external returns (bool);

    function transferFrom(address from, address to, uint256 value) external returns (bool);

    function totalSupply() external view returns (uint256);

    function balanceOf(address who) external view returns (uint256);

    function allowance(address owner, address spender) external view returns (uint256);
}

 
contract Airdrop {
  IERC20 private _token = IERC20(0x00FbE7398D9F0D53fBaef6E2F4C6Ab0e7c31f5D7);

   
  function doAirdrop(address[] calldata addresses) external returns (uint256) {
    uint256 i = 0;

    while (i < addresses.length) {
      _token.transferFrom(msg.sender, addresses[i], 100 * 1 ether);
      i += 1;
    }

    return i;
  }
}