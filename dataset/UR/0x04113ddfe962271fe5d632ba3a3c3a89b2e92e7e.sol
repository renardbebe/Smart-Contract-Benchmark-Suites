 

pragma solidity 0.4.23;

contract ERC20BasicInterface {
    function balanceOf(address _owner) public view returns (uint256 balance);
    function transfer(address _to, uint256 _value) public returns (bool success);
}

 
contract DLSDLockBounty3 {
    ERC20BasicInterface constant TOKEN = ERC20BasicInterface(0x8458d484572cEB89ce70EEBBe17Dc84707b241eD);
    address constant OWNER = 0x603F65F7Fc4f650c2F025800F882CFb62BF23580;
    address constant DESTINATION = 0x3135081dE9aEf677b3d7445e6C44Bb385cBD3E6a;
    uint constant UNLOCK_DATE = 1548547199;  

    function unlock() public returns(bool) {
        require(now > UNLOCK_DATE, 'Tokens are still locked');
        return TOKEN.transfer(DESTINATION, TOKEN.balanceOf(address(this)));
    }

    function recoverTokens(ERC20BasicInterface _token, address _to, uint _value) public returns(bool) {
        require(msg.sender == OWNER, 'Access denied');
         
        require(address(_token) != address(TOKEN), 'Can not recover this token');
        return _token.transfer(_to, _value);
    }
}