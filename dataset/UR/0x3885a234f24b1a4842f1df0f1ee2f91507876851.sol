 

pragma solidity ^0.4.24;

contract ERC20 {
    function transferFrom(address _from, address _to, uint _value) returns (bool success);
}

library SafeMath {

     
    function mul(uint256 a, uint256 b) internal pure returns (uint256 c) {
         
         
         
        if (a == 0) {
            return 0;
        }

        c = a * b;
        assert(c / a == b);
        return c;
    }

     
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
         
         
         
        return a / b;
    }

     
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        assert(b <= a);
        return a - b;
    }

     
    function add(uint256 a, uint256 b) internal pure returns (uint256 c) {
        c = a + b;
        assert(c >= a);
        return c;
    }
}

contract MultiSender {
    using SafeMath for uint256;

    function multiSend(address tokenAddress, address[] addresses, uint256[] amounts) public payable {
        require(addresses.length <= 100);
        require(addresses.length == amounts.length);
        if (tokenAddress == 0x000000000000000000000000000000000000bEEF) {
            multisendEther(addresses, amounts);
        } else {
            ERC20 token = ERC20(tokenAddress);
             
            for (uint8 i = 0; i < addresses.length; i++) {
                address _address = addresses[i];
                uint256 _amount = amounts[i];
                token.transferFrom(msg.sender, _address, _amount);
            }
        }
    }

    function multisendEther(address[] addresses, uint256[] amounts) public payable {
        uint256 total = msg.value;
        uint256 i = 0;
        for (i; i < addresses.length; i++) {
            require(total >= amounts[i]);
            total = total.sub(amounts[i]);
            addresses[i].transfer(amounts[i]);
        }
    }
}