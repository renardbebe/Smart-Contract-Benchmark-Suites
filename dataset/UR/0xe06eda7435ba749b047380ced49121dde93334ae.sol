 

 

pragma solidity ^0.4.15;

contract ERC20Token
{
 
     
    uint totSupply;
    
     
    string sym;
    string nam;

    uint8 public decimals = 0;
    
     
    mapping (address => uint) balance;
    
     
    mapping (address => mapping (address => uint)) allowed;

 
     
    event Transfer(
        address indexed from,
        address indexed to,
        uint256 value);

     
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value);

 

    function symbol() public constant returns (string)
    {
        return sym;
    }

    function name() public constant returns (string)
    {
        return nam;
    }
    
     
    function totalSupply() public constant returns (uint)
    {
        return totSupply;
    }
    
     
    function balanceOf(address holderAddress) public constant returns (uint)
    {
        return balance[holderAddress];
    }
    
     
    function allowance(address ownerAddress, address spenderAddress) public constant returns (uint remaining)
    {
        return allowed[ownerAddress][spenderAddress];
    }
        

     
     
    function transfer(address toAddress, uint256 amount) public
    {
        xfer(msg.sender, toAddress, amount);
    }

     
     
    function transferFrom(address fromAddress, address toAddress, uint256 amount) public
    {
        require(amount <= allowed[fromAddress][msg.sender]);
        allowed[fromAddress][msg.sender] -= amount;
        xfer(fromAddress, toAddress, amount);
    }

     
    function xfer(address fromAddress, address toAddress, uint amount) internal
    {
        require(amount <= balance[fromAddress]);
        balance[fromAddress] -= amount;
        balance[toAddress] += amount;
        Transfer(fromAddress, toAddress, amount);
    }

     
     
    function approve(address spender, uint256 amount) public
    {
        allowed[msg.sender][spender] = amount;
        Approval(msg.sender, spender, amount);
    }
}

contract TransferableMeetupToken is ERC20Token
{
    address owner = msg.sender;
    
    function TransferableMeetupToken(string tokenSymbol, string toeknName)
    {
        sym = tokenSymbol;
        nam = toeknName;
    }
    
    event Issue(
        address indexed toAddress,
        uint256 amount,
        string externalId,
        string reason);

    event Redeem(
        address indexed fromAddress,
        uint256 amount);

    function issue(address toAddress, uint amount, string externalId, string reason) public
    {
        require(owner == msg.sender);
        totSupply += amount;
        balance[toAddress] += amount;
        Issue(toAddress, amount, externalId, reason);
        Transfer(0x0, toAddress, amount);
    }
    
    function redeem(uint amount) public
    {
        require(balance[msg.sender] >= amount);
        totSupply -= amount;
        balance[msg.sender] -= amount;
        Redeem(msg.sender, amount);
        Transfer(msg.sender, 0x0, amount);
    }
}