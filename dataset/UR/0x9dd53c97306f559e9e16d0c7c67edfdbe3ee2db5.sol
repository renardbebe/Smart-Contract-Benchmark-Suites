 

pragma solidity ^0.5.0;

contract ZTY {

    mapping (address => uint256) public balances;
    mapping (address => mapping (address => uint256)) public allowed;
    uint256 public sellPrice;
    uint256 public buyPrice;
    uint256 public numDecimalsBuyPrice;
    uint256 public numDecimalsSellPrice;
    string public name;                   
    uint8 public decimals;                
    string public symbol;                 
    address payable public  owner;
    uint256 public totalSupply;

    constructor () public {
        balances[msg.sender] = 4485600000000000000000000000;
        totalSupply = 4485600000000000000000000000;
        name = "Zity";
        decimals = 18;
        symbol = "ZTY";
        owner = msg.sender;
        sellPrice = 8;
        numDecimalsSellPrice = 10000;
        buyPrice = 8;
        numDecimalsBuyPrice = 10000;
    }

    function recieveFunds() external payable {
        emit ReciveFunds(msg.sender,msg.value);   
    } 
    
    function returnFunds(uint256 _value) public onlyOwner {
        require (address (this).balance >= _value);
        owner.transfer (_value);
        emit ReturnFunds(msg.sender, _value);
    }
    
    function getBalance() public view returns(uint256) { 
        return address(this).balance; 
    }    

    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }
    function transferOwnership(address payable newOwner) public onlyOwner {
        owner = newOwner;
        emit TransferOwnership(newOwner); 
    }
    
    function setPrices(uint256 newSellPrice, uint256 newnumDecimalsSellPrice, uint256 newBuyPrice, uint256 newnumDecimalsBuyPrice) public onlyOwner {
        sellPrice = newSellPrice;
        buyPrice = newBuyPrice;
        numDecimalsBuyPrice = newnumDecimalsBuyPrice;
        numDecimalsSellPrice = newnumDecimalsSellPrice;
        emit SetPrices(newSellPrice, newnumDecimalsSellPrice, newBuyPrice, newnumDecimalsBuyPrice);
    }

    function buy()public payable  returns (uint256 _value){
        _value = (msg.value * numDecimalsBuyPrice) / buyPrice;
        require (balances[address (this)] >= _value);
        balances[msg.sender] += _value;
        balances[address (this)] -= _value;
        emit Buy(address (this), msg.sender, _value);
        return _value;
    }  

    function sell(uint256 _value) public returns (uint256 revenue){
        require(balances[msg.sender] >= _value);
        balances[address (this)] += _value;         
        balances[msg.sender] -= _value;                  
        revenue =   (_value * sellPrice) /numDecimalsSellPrice;
        msg.sender.transfer(revenue);
        emit Sell(msg.sender, address (this), _value);             
        return revenue;                                   
    }   

    function transfer(address _to, uint256 _value) public returns (bool success) {
        require (_to != address(0x0));
        require(balances[msg.sender] >= _value);
        balances[msg.sender] -= _value;
        balances[_to] += _value;
        emit Transfer(msg.sender, _to, _value); 
        return true;
    }

    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {
        uint256 allowance = allowed[_from][msg.sender];
        require (_to != address(0x0));
        require(balances[_from] >= _value && allowance >= _value);
        balances[_to] += _value;
        balances[_from] -= _value;
        allowed[_from][msg.sender] -= _value;
        emit Transfer(_from, _to, _value); 
        return true;
    }

    function balanceOf(address _owner) public view returns (uint256 balance) {
        return balances[_owner];
    }

    function approve(address _spender, uint256 _value) public returns (bool success) {
        allowed[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value); 
        return true;
    }

    function allowance(address _owner, address _spender) public view returns (uint256 remaining) {
        return allowed[_owner][_spender];
    }
 
    function burn(uint256 _value) public onlyOwner returns (bool success) {
        require(balances[msg.sender] >= _value);    
        balances[msg.sender] -= _value;             
        totalSupply -= _value;                       
        emit Burn(msg.sender, _value);
        return true;
    }
    
    function selfdestructcontract () public onlyOwner {
        selfdestruct(owner);
        
    }
    
    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Sell(address indexed _from, address indexed _to, uint256 _value);
    event Buy(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
    event Burn(address indexed _from, uint256 value);
    event SetPrices(uint256 newSellPrice, uint256 newnumDecimalsSellPrice, uint256 newBuyPrice, uint256 newnumDecimalsBuyPrice);
    event TransferOwnership(address indexed newOwner);
    event ReturnFunds(address indexed _from, uint256 _value);
    event ReciveFunds(address indexed _from, uint256 _value);
}