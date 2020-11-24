 

pragma solidity ^0.4.16;

contract SSOrgToken {
     
    address public owner;
    string public name;
    string public symbol;
    uint8 public constant decimals = 2;
    uint256 public totalSupply;

     
    mapping (address => uint256) public balanceOf;
    mapping (address => uint8) public sellTypeOf;
    mapping (address => uint256) public sellTotalOf;
    mapping (address => uint256) public sellPriceOf;

     
    event Transfer(address indexed from, address indexed to, uint256 value);

     
    function SSOrgToken(
        string tokenName,
        string tokenSymbol,
        uint256 tokenSupply
    ) public {
        name = tokenName;
        symbol = tokenSymbol;
        totalSupply = tokenSupply * 10 ** uint256(decimals);
        balanceOf[msg.sender] = totalSupply;                 
        owner = msg.sender;
    }

     
    function transfer(address _to, uint256 _value) public returns (bool) {
         
        require(_to != 0x0);
         
        require(balanceOf[msg.sender] >= _value);
         
        require(balanceOf[_to] + _value > balanceOf[_to]);
         
        balanceOf[msg.sender] -= _value;
         
        balanceOf[_to] += _value;
        Transfer(msg.sender, _to, _value);
        return true;
    }

    function setSellInfo(uint8 newSellType, uint256 newSellTotal, uint256 newSellPrice) public returns (uint256) {
        require(newSellPrice > 0 && newSellTotal >= 0);
        if (newSellTotal > sellTotalOf[msg.sender]) {
            require(balanceOf[msg.sender] >= newSellTotal - sellTotalOf[msg.sender]);
            balanceOf[msg.sender] -= newSellTotal - sellTotalOf[msg.sender];
        } else {
            balanceOf[msg.sender] += sellTotalOf[msg.sender] - newSellTotal;
        }
        sellTotalOf[msg.sender] = newSellTotal;
        sellPriceOf[msg.sender] = newSellPrice;
        sellTypeOf[msg.sender] = newSellType;
        return balanceOf[msg.sender];
    }

    function buy(address seller) payable public returns (uint256 amount) {
        amount = msg.value / sellPriceOf[seller];         
        require(sellTypeOf[seller] == 0 ? sellTotalOf[seller] == amount : sellTotalOf[seller] >= amount);
        balanceOf[msg.sender] += amount;                   
        sellTotalOf[seller] -= amount;                         
        Transfer(seller, msg.sender, amount);                
        seller.transfer(msg.value);
        return amount;                                     
    }
}