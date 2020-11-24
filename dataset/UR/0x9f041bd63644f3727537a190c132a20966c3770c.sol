 

pragma solidity ^0.4.17;

 
contract BatchTokenSender {
     
    address public donationAddress;

     
    function BatchTokenSender (address _donationAddress) public {
        donationAddress = _donationAddress;
    }

     
    function encodeTransfer (uint96 _lotsNumber, address _to)
    public pure returns (uint256 _encodedTransfer) {
        return (_lotsNumber << 160) | uint160 (_to);
    }

     
    function batchSend (
        Token _token, uint160 _lotSize, uint256 [] _transfers) public {
        uint256 count = _transfers.length;
        for (uint256 i = 0; i < count; i++) {
            uint256 transfer = _transfers [i];
            uint256 value = (transfer >> 160) * _lotSize;
            address to = address (
                transfer & 0x00FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF);
            if (!_token.transferFrom (msg.sender, to, value)) revert ();
        }
    }
}

 
contract Token {
     
    function totalSupply ()
    public constant returns (uint256 supply);

     
    function balanceOf (address _owner)
    public constant returns (uint256 balance);

     
    function transfer (address _to, uint256 _value)
    public returns (bool success);

     
    function transferFrom (address _from, address _to, uint256 _value)
    public returns (bool success);

     
    function approve (address _spender, uint256 _value)
    public returns (bool success);

     
    function allowance (address _owner, address _spender)
    public constant returns (uint256 remaining);

     
    event Transfer (address indexed _from, address indexed _to, uint256 _value);

     
    event Approval (
        address indexed _owner, address indexed _spender, uint256 _value);
}