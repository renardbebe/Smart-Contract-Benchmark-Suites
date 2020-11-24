 

pragma solidity ^0.4.4;


contract TestNetworkToken {

     
    string public constant name = "Test Network Token";
    string public constant symbol = "TNT";
    uint8 public constant decimals = 18;   

    uint256 public constant tokenCreationRate = 1000;

     
    uint256 totalTokens;
    
    mapping (address => uint256) balances;

    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Refund(address indexed _from, uint256 _value);

     

     
    function transfer(address _to, uint256 _value) returns (bool) {
        return false;
    }

    function totalSupply() external constant returns (uint256) {
        return totalTokens;
    }

    function balanceOf(address _owner) external constant returns (uint256) {
        return balances[_owner];
    }

     

    function create() payable external {
         
        if (msg.value == 0) throw;

        var numTokens = msg.value * tokenCreationRate;

        totalTokens += numTokens;

         
        balances[msg.sender] += numTokens;

         
        Transfer(0x0, msg.sender, numTokens);
    }

    function refund() external {
        var tokenValue = balances[msg.sender];
        if (tokenValue == 0) throw;
        balances[msg.sender] = 0;
        totalTokens -= tokenValue;

        var ethValue = tokenValue / tokenCreationRate;
        Refund(msg.sender, ethValue);
        Transfer(msg.sender, 0x0, tokenValue);

        if (!msg.sender.send(ethValue)) throw;
    }

     
    
    function kill() {
        if(totalTokens > 0) throw;

        selfdestruct(msg.sender);
    }
}