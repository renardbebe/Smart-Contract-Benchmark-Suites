 

pragma solidity ^0.4.19;

 
contract ERC20Token {
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool) {}
    function allowance(address _owner, address _spender) constant returns (uint256 remaining) {}
    
}

contract MultiSend {
    ERC20Token public _STCnContract;
    address public _multiSendOwner;
    uint256 public tokensApproved;
    
    function MultiSend () {
        address c = 0x420C42cE1370c0Ec3ca87D9Be64A7002E78e6709;  
        _STCnContract = ERC20Token(c); 
        _multiSendOwner = msg.sender;
        tokensApproved = 0;  
    }
    
     
    
    function dropCoinsSingle(address[] dests, uint256 tokens) {
        require(msg.sender == _multiSendOwner && tokensApproved >= (dests.length * tokens));
        uint256 i = 0;
        while (i < dests.length) {
            _STCnContract.transferFrom(_multiSendOwner, dests[i], tokens);
            i += 1;
        }
        updateTokensApproved();
    }
    
     
    
    function dropCoinsMulti(address[] dests, uint256[] tokens) {
        require(msg.sender == _multiSendOwner);
        uint256 i = 0;
        while (i < dests.length) {
            _STCnContract.transferFrom(_multiSendOwner, dests[i], tokens[i]);
            i += 1;
        }
        updateTokensApproved();
    }
    
    function updateTokensApproved () {
        tokensApproved = _STCnContract.allowance(_multiSendOwner, this);
    }
    
}