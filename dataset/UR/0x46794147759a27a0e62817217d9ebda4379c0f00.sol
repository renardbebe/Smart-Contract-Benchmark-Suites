 

pragma solidity 0.5.8;

interface IERC20 {
    function transferFrom(address from, address to, uint256 value) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
}

library SafeMath {
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "SafeMath: division by zero");
        uint256 c = a / b;
        return c;
    }
}

contract MeetupQrManager {

    using SafeMath for uint256;
    
    mapping (bytes32 => address[]) public meetups;
    string[] public names;
    
    function transfer(
        string memory name, 
        address tokenContract, 
        address account, 
        address[] memory addresses
    ) public returns(bool) {
        IERC20 token = IERC20(tokenContract);
        uint256 amount = token.allowance(account, address(this));
        
        uint256 length = addresses.length;
        uint256 total = amount.div(length);
        
        bytes32 key = keccak256(bytes(name));
        names.push(name);

        for (uint256 i=0;i<length;i++) {
            require(token.transferFrom(account, addresses[i], total));
            meetups[key].push(addresses[i]);
        }
        return true;
    }
    
    function getAddresses(string memory name) public view returns (address[] memory addresses) {
        bytes32 key = keccak256(bytes(name));
        addresses = meetups[key];
    }
    
}