 

pragma solidity ^0.5.0;

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

contract ERC20Basic {
    function totalSupply() public view returns (uint256);
    function balanceOf(address who) public view returns (uint256);
    function transfer(address to, uint256 value) public returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
}
contract ERC20 is ERC20Basic {
    function allowance(address owner, address spender) public view returns (uint256);
    function transferFrom(address from, address to, uint256 value) public returns (bool);
    function approve(address spender, uint256 value) public returns (bool);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

contract MultiSendErc20 {
    using SafeMath for uint256;
    function multisendToken(address token, address[] memory _contributors, uint256[] memory _balances) public {
        ERC20 erc20token = ERC20(token);
        uint8 i = 0;

        for (i; i < _balances.length; i++) {
            erc20token.transferFrom(msg.sender, _contributors[i], _balances[i]);
        }
    }
    
    function sendToken(address token, address _contributor, uint256 _balance) public {
        ERC20 erc20token = ERC20(token);
        erc20token.transferFrom(msg.sender, _contributor, _balance);
    
    }
}