 

pragma solidity ^0.4.24;

contract Owned {
    address public owner;

    constructor() public {
        owner = msg.sender;
    }

    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }

    function transferOwnership(address newOwner) public onlyOwner {
        owner = newOwner;
    }
}


contract SafeMath {
    function mul(uint a, uint b) internal pure returns (uint) {
        uint c = a * b;
        assert(a == 0 || c / a == b);
        return c;
    }

    function div(uint a, uint b) internal pure returns (uint) {
        assert(b > 0);
        uint c = a / b;
        assert(a == b * c + a % b);
        return c;
    }

    function sub(uint a, uint b) internal pure returns (uint) {
        assert(b <= a);
        return a - b;
    }

    function add(uint a, uint b) internal pure returns (uint) {
        uint c = a + b;
        assert(c >= a);
        return c;
    }
}

interface Qobi {
    function transfer(address _to, uint256 _value) external returns (bool success);
    function balanceOf(address _owner) external view returns (uint256 balance);
}

 
contract Airdrop is SafeMath, Owned {
    Qobi public token;
    event CandySent(address user, uint256 amount);

    constructor(address _addressOfToken) public {
        token = Qobi(_addressOfToken);
    }

    function sendCandy(address[] dests, uint256[] values) onlyOwner public returns(bool success) {
        require(dests.length > 0);
        require(dests.length == values.length);

         
        uint256 totalAmount = 0;
        for (uint i = 0; i < values.length; i++) {
            totalAmount = add(totalAmount, values[i]);
        }

        require(totalAmount > 0, "total amount must > 0");
        require(totalAmount < token.balanceOf(address(this)), "total amount must < this address token balance ");

        for (uint j = 0; j < dests.length; j++) {
            token.transfer(dests[j], values[j]);  
            emit CandySent(dests[j], values[j]);
        }

        return true;
    }
}