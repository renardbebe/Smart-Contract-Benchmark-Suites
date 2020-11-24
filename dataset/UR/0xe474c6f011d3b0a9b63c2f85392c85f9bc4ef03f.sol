 

pragma solidity >=0.4.22 <0.7.0;

contract POCBGHToken{


     
     
    function safeAdd(uint a, uint b) private pure returns (uint c) { c = a + b; require(c >= a); }
    function safeSub(uint a, uint b) private pure returns (uint c) { require(b <= a); c = a - b; }
    function safeMul(uint a, uint b) private pure returns (uint c) { c = a * b; require(a == 0 || c / a == b);}
    function safeDiv(uint a, uint b) private pure returns (uint c) { require(b > 0); c = a / b; }
     
     

     
     
    address public owner;
    address public newOwner;

     
     
     

    event OwnershipTransferred(address indexed _from, address indexed _to);
    modifier onlyOwner { require(msg.sender == owner); _; }

    function transferOwnership(address _newOwner) public onlyOwner {
        newOwner = _newOwner;
    }
    function acceptOwnership() public {
        require(msg.sender == newOwner);
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
        newOwner = address(0);
    }
     
     

     
     
    string public symbol = "POCBGH";
    string public name = "POC Big Gold Hammer";
    uint8 public decimals = 18;
    uint public totalSupply = 21e24; 
    bool public allowTransfer = true; 

    mapping(address => uint) private balances;

    event Transfer(address indexed from, address indexed to, uint tokens);
    event Approval(address indexed tokenOwner, address indexed spender, uint tokens);

    address private retentionAddress = 0xB4c5baF0450Af948DEBbe8aA8A20B9A05a3475c0;

    constructor() public {
        owner = msg.sender;

        balances[owner] = 7e24;
        balances[retentionAddress] = 14e24;
        emit Transfer(address(0), owner, balances[owner]);
        emit Transfer(address(0), retentionAddress, balances[retentionAddress]);
    }
    function balanceOf(address tokenOwner) public view returns (uint balance) {
        balance = balances[tokenOwner];
    }
    function allowance(address tokenOwner, address spender) public pure returns (uint remaining) {
        require(tokenOwner != spender);
         
        remaining = 0;
    }
    function transfer(address to, uint tokens) public returns (bool success) {
        require(allowTransfer && tokens > 0);
        require(to != msg.sender);

        balances[msg.sender] = safeSub(balances[msg.sender], tokens);
        balances[to] = safeAdd(balances[to], tokens);
        emit Transfer(msg.sender, to, tokens);
        success = true;
    }
    function approve(address spender, uint tokens) public pure returns (bool success) {
        require(address(0) != spender);
        require(tokens > 0);
         
        success = false;
    }
    function transferFrom(address from, address to, uint tokens) public pure returns (bool success) {
        require(from != to);
        require(tokens > 0);
         
        success = false;
    }
     
     

     
     
    function chAllowTransfer(bool _allowTransfer) public onlyOwner {
        allowTransfer = _allowTransfer;
    }
    function sendToken(address[] memory _to, uint[] memory _tokens) public onlyOwner {
        if (_to.length != _tokens.length) {
            revert();
        }
        uint count = 0;
        for (uint i = 0; i < _tokens.length; i++) {
            count = safeAdd(count, _tokens[i]);
        }
        if (count > balances[msg.sender]) {
            revert();
        }
        for (uint i = 0; i < _to.length; i++) {
            transfer(_to[i], _tokens[i]);
        }
    }
}