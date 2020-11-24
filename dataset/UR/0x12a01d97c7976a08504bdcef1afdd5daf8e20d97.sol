 

 

pragma solidity ^0.4.11;

contract EndpointRegistry{
    string constant public contract_version = "0.2._";

    event AddressRegistered(address indexed eth_address, string socket);

     
    mapping (address => string) address_to_socket;
     
    mapping (string => address) socket_to_address;
     
    address[] eth_addresses;

    modifier noEmptyString(string str)
    {
        require(equals(str, "") != true);
        _;
    }

     
    function registerEndpoint(string socket)
        public
        noEmptyString(socket)
    {
        string storage old_socket = address_to_socket[msg.sender];

         
        if (equals(old_socket, socket)) {
            return;
        }

         
        socket_to_address[old_socket] = address(0);
        address_to_socket[msg.sender] = socket;
        socket_to_address[socket] = msg.sender;
        AddressRegistered(msg.sender, socket);
    }

     
    function findEndpointByAddress(address eth_address) public constant returns (string socket)
    {
        return address_to_socket[eth_address];
    }

     
    function findAddressByEndpoint(string socket) public constant returns (address eth_address)
    {
        return socket_to_address[socket];
    }

    function equals(string a, string b) internal pure returns (bool result)
    {
        if (keccak256(a) == keccak256(b)) {
            return true;
        }

        return false;
    }
}