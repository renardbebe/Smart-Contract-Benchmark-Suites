 

pragma solidity 0.5.10;

contract ERC20Interface {
    function totalSupply() public view returns (uint);
    function balanceOf(address tokenOwner) public view returns (uint balance);
    function allowance(address tokenOwner, address spender) public view returns (uint remaining);
    function transfer(address to, uint tokens) public returns (bool success);
    function approve(address spender, uint tokens) public returns (bool success);
    function transferFrom(address from, address to, uint tokens) public returns (bool success);

    uint8 public decimals;

    event Transfer(address indexed from, address indexed to, uint tokens);
    event Approval(address indexed tokenOwner, address indexed spender, uint tokens);
}

contract Redirector {
    address public owner;

    modifier onlyOwner() {
        require(msg.sender == owner, "Only the owner can perform this action.");
        _;
    }

    function changeOwner(address newOwner)
    external
    onlyOwner() {
        owner = newOwner;
    }

    address payable public recipient;

    function changeRecipient(address payable newRecipient)
    external
    onlyOwner() {
        recipient = newRecipient;
    }

    constructor(address _owner, address payable _recipient)
    public {
        owner = _owner;
        recipient = _recipient;
    }

    function pumpNative()
    external {
        recipient.transfer(getNativeBalance());
    }

    function pumpTokens(ERC20Interface token)
    external {
        token.transfer(recipient, getTokenBalance(token));
    }

    function getNativeBalance()
    public
    view
    returns (uint) {
        return address(this).balance;
    }

    function getTokenBalance(ERC20Interface token)
    public
    view
    returns (uint) {
        return token.balanceOf(address(this));
    }

     
    function () external payable {}
     
    function tokenFallback(address _from, uint _value, bytes calldata _data) external {}
}