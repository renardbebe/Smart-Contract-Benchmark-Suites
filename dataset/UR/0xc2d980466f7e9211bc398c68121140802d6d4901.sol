 

pragma solidity ^0.4.0;

contract owned {
    address public owner;

    function owned() public {
        owner = msg.sender;
    }

    modifier onlyOwner {
        if(msg.sender != owner) revert();
        _;
    }

    function tranferOwnership(address _newOwner) public onlyOwner() {
        owner = _newOwner;
    }
}

contract Token {
    function mintTokens(address _atAddress, uint256 _amount) public;
}

contract AirdropTokenGeneration is owned {
    Token token;
    mapping(address => bool) canPickUpTokens;
    mapping(address => bool) hasClaimedTokens;
    uint256 amount;

    function setToken(address _token) public onlyOwner {
        token = Token(_token);
    }

    function setAmount(uint256 _amount) public onlyOwner {
        amount = _amount;
    }

    function addAllowanceToPickUpTokens(address[] _addresses) public onlyOwner {
        for(uint256 i = 0; i < _addresses.length; i++) {
            canPickUpTokens[_addresses[i]] = true;
        }
    }

    function pull() public {
        require(canPickUpTokens[msg.sender]);
        require(!hasClaimedTokens[msg.sender]);
        hasClaimedTokens[msg.sender] = true;
        token.mintTokens(msg.sender, amount);
    }

    function getToken() public constant returns(address) {
        return address(token);
    }

    function hasAllowanceToPickupTokens(address _user) public constant returns(bool) {
        return canPickUpTokens[_user];
    }

    function hasAlreadyClaimedTokens(address _user) public constant returns(bool) {
        return hasClaimedTokens[_user];
    }

    function getAmount() public constant returns(uint256) {
        return amount;
    }
}