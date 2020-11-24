 

pragma solidity ^0.5.9;

contract OwnerHelper
{
    address public owner;

    event OwnerTransferPropose(address indexed _from, address indexed _to);

    modifier onlyOwner
    {
        require(msg.sender == owner);
        _;
    }

    constructor() public
    {
        owner = msg.sender;
    }

    function transferOwnership(address _to) onlyOwner public
    {
        require(_to != owner);
        require(_to != address(0x0));
        owner = _to;
        emit OwnerTransferPropose(owner, _to);
    }
}

contract Token {
    function transfer(address _to, uint _value) public returns (bool);
}

contract TokenDistribute is OwnerHelper
{
    uint public E18 = 10 ** 18;

    constructor() public
    {
    }
    
    function multipleTokenDistribute(address _token, address[] memory _addresses, uint[] memory _values) public onlyOwner
    {
        Token t = Token(_token);
        for(uint i = 0; i < _addresses.length ; i++)
        {
            t.transfer(_addresses[i], _values[i]);  
        }
    }
    
    function withDrawToken(address _token, uint _value) public onlyOwner
    {
        Token(_token).transfer(owner, _value);
    }
}