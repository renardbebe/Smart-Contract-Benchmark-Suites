 

pragma solidity ^0.4.8;

contract Token {
    function balanceOf(address) public constant returns (uint);
    function transfer(address, uint) public returns (bool);
}

contract Vault {
    Token constant public token = Token(0xa645264C5603E96c3b0B078cdab68733794B0A71);
    address constant public recipient = 0x0007013D71C0946126d404Fd44b3B9c97F3418e7;
     
    uint constant public unlockedAt = 1515999600;
    
    function unlock() public {
        if (now < unlockedAt) throw;
        uint vaultBalance = token.balanceOf(address(this));
        token.transfer(recipient, vaultBalance);
    }
}