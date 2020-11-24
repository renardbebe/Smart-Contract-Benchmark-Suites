 

pragma solidity ^0.4.25;

contract ERC20Token {
    uint256 public totalSupply;
    function balanceOf(address _owner) public constant returns (uint256 balance);
    function transfer(address _to, uint256 _value) public returns (bool success);
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success);
    function approve(address _spender, uint256 _value) public returns (bool success);
    function allowance(address _owner, address _spender) public constant returns (uint256 remaining);
    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
}

contract FutureEdgeAirdrop {
    bool public paused = false;
    modifier ifNotPaused {
        require(!paused);
        _;
    }
    function drop(address tokenAddr, address[] dests, uint256[] balances) public ifNotPaused {
        for (uint i = 0; i < dests.length; i++) {
            ERC20Token(tokenAddr).transferFrom(msg.sender, dests[i], balances[i]);
        }
    }
}