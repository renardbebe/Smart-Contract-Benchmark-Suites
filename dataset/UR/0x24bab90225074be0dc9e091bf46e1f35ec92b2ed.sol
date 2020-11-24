 

pragma solidity ^0.5.0;

contract IToken {
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
}

contract Distributor {
    IToken public token;
    address public owner;
    address public holder;

    constructor(address _token, address _holder) public {
        owner = msg.sender;
        holder = _holder;
        token = IToken(_token);
    }

    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    function distribute(address[] memory addresses, uint[] memory counts) public onlyOwner {
        require(addresses.length == counts.length);
        for (uint i = 0; i < counts.length; i++) {
            token.transferFrom(holder, addresses[i], counts[i]);
        }
    }

    function changeToken(address new_address) public onlyOwner {
        token = IToken(new_address);
    }

    function changeOwner(address new_address) public onlyOwner {
        owner = new_address;
    }

    function changeHolder(address new_address) public onlyOwner {
        holder = new_address;
    }
}