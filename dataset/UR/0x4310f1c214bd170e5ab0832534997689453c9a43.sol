 

 

pragma solidity 0.4.15;


contract ERC20TokenInterface {

     
    function totalSupply() constant returns (uint256 supply);

     
     
    function balanceOf(address _owner) constant public returns (uint256 balance);

     
     
     
     
    function transfer(address _to, uint256 _value) public returns (bool success);

     
     
     
     
     
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success);

     
     
     
     
    function approve(address _spender, uint256 _value) public returns (bool success);

     
     
     
    function allowance(address _owner, address _spender) constant public returns (uint256 remaining);

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);

}


contract DickheadCash is ERC20TokenInterface {

    string public constant name = "DickheadCash";
    string public constant symbol = "DICK";
    uint256 public constant decimals = 0;
    uint256 public totalTokens = 1 * (10 ** decimals);
    uint8 public constant MAX_TRANSFERS = 7;

    mapping (address => bool) public received;
    mapping (address => uint8) public transfers;
    mapping (address => uint256) public balances;
    mapping (address => mapping (address => uint256)) public allowed;


    function DickheadCash() {
        balances[msg.sender] = totalTokens;
        received[msg.sender] = true;
    }

    function totalSupply() constant returns (uint256) {
        return totalTokens;
    }

    function transfersRemaining() returns (uint8) {
        return MAX_TRANSFERS - transfers[msg.sender];
    }

    function transfer(address _to, uint256 _value) public returns (bool) {
        if (_value > 1) return false;
        if (transfers[msg.sender] >= MAX_TRANSFERS) return false;
        if (received[_to]) return false;
        if (received[msg.sender]) {
            balances[_to] = _value;
            transfers[msg.sender]++;
            if (!received[_to]) received[_to] = true;
            totalTokens += _value;
            Transfer(msg.sender, _to, _value);
            return true;
        }
        return false;
    }

    function transferFrom(address _from, address _to, uint256 _value) public returns (bool) {
        return false;
    }

    function balanceOf(address _owner) constant public returns (uint256) {
        return balances[_owner];
    }

    function approve(address _spender, uint256 _value) public returns (bool) {
        return false;
    }

    function allowance(address _owner, address _spender) constant public returns (uint256 remaining) {
        return 0;
    }

}