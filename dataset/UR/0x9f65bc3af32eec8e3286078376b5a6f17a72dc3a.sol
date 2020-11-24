 

pragma solidity ^0.5.0;

 

contract ERC20 {
    function transferFrom(address from, address to, uint256 value) public returns (bool) {}
}

contract MultiSender {
    
     
    function multiSend(address _tokenAddr, address[] memory _to, uint256[] memory _value) public returns (bool _success) {
        assert(_to.length == _value.length);
        assert(_to.length <= 150);
        ERC20 _token = ERC20(_tokenAddr);
        for (uint8 i = 0; i < _to.length; i++) {
            assert((_token.transferFrom(msg.sender, _to[i], _value[i])) == true);
        }
        return true;
    }
}