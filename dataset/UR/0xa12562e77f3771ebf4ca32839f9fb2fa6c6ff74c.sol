 

 

pragma solidity ^0.4.21;

 
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

contract Airdrop {

    event AirdropEvent(address indexed tokencontract, address[] destinations,uint[] indexed amounts);

    function doAirDrop(address erc20TokenAddr, uint[] amounts, address[] addresses) public {
        
        IERC20 erc20Token = IERC20(erc20TokenAddr);
        uint allowance = erc20Token.allowance(msg.sender, address(this));

        for (uint i = 0; i < addresses.length; i++) {
          if (addresses[i] != address(0) && amounts[i] != 0) {
            if (allowance >= amounts[i]) {
              if (erc20Token.transferFrom(msg.sender, addresses[i], amounts[i])) {
                allowance -= amounts[i];
              }
            }
          }
        }

        emit AirdropEvent(erc20TokenAddr, addresses, amounts);
    }
}