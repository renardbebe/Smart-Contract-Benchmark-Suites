 

pragma solidity ^0.4.19;

 
contract TokenERC20 {
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool) {}
}

contract MultiSend {
    TokenERC20 public _ERC20Contract;
    address public _multiSendOwner;
    
    function MultiSend () {
        address c = 0xc3761EB917CD790B30dAD99f6Cc5b4Ff93C4F9eA;  
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