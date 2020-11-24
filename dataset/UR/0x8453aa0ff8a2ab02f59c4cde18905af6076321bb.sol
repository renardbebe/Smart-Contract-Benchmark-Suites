 

pragma solidity ^0.4.19;

 
contract TokenERC20 {
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool) {}
}

contract MultiSend {
    TokenERC20 public _ERC20Contract;
    address public _multiSendOwner;
    
    function MultiSend () {
        address c = 0x7cE31d775ee8AE8058ed7e599e5F14Bb1535f223;  
        _ERC20Contract = TokenERC20(c); 
        _multiSendOwner = msg.sender;
    }
    
     
    function dropCoins(address[] dests, uint256 tokens) {
        require(msg.sender == _multiSendOwner);
        uint256 amount = tokens;
        uint256 i = 0;
        while (i < dests.length) {
            _ERC20Contract.transferFrom(_multiSendOwner, dests[i], amount);
            i += 1;
        }
    }
    
}