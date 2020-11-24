 

pragma solidity 0.5.1;

contract JNS {
    mapping (string => address) strToAddr;
    mapping (address => string) addrToStr;
    address payable private wallet;

    constructor (address payable _wallet) public {
        require(_wallet != address(0), "You must inform a valid address");
        wallet = _wallet;
    }
    
    function registerAddress (string memory _nickname, address _address) public payable returns (bool) {
        require (msg.value >= 1000000000000000, "Send more money");
        require (strToAddr[_nickname] == address(0), "Name already registered");
        require (keccak256(abi.encodePacked(addrToStr[_address])) == keccak256(abi.encodePacked("")), "Address already registered");
        
        strToAddr[_nickname] = _address;
        addrToStr[_address] = _nickname;

        wallet.transfer(msg.value);
        return true;
    }
    
    function getAddress (string memory _nickname) public view returns (address _address) {
        _address = strToAddr[_nickname];
    }
    
    function getNickname (address _address) public view returns (string memory _nickname) {
        _nickname = addrToStr[_address];
    }
}