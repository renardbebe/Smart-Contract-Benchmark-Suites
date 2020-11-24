 

pragma solidity ^0.4.13;

interface tokenRecipient { function receiveApproval(address _from, uint256 _value, address _token, bytes _extraData) external; }

contract TokenERC20 {
     
    string public name;
    string public symbol;
    uint8 public decimals;
    
    uint256 public totalSupply;

     
    mapping (address => uint256) public balanceOf;
    mapping (address => mapping (address => uint256)) public allowance;

     
    event Transfer(address indexed from, address indexed to, uint256 value);

     
    event Burn(address indexed from, uint256 value);

     
    constructor (uint256 initialSupply, string tokenName, string tokenSymbol, uint8 _decimals) public {
        decimals = _decimals;
        totalSupply = initialSupply * 10 ** uint256(decimals);   
        emit Transfer(this, this, totalSupply);
        balanceOf[this] = totalSupply;                       
        name = tokenName;                                    
        symbol = tokenSymbol;                                
    }

     
    function _transfer(address _from, address _to, uint _value) internal {
        require(_to != 0x0, "Prevent transfer to 0x0 address. Use burn() instead");
        require(balanceOf[_from] >= _value, "Check if the sender has enough");
        require(balanceOf[_to] + _value > balanceOf[_to], "Check for overflows");

         
        uint previousBalances = balanceOf[_from] + balanceOf[_to];
         
        balanceOf[_from] -= _value;
         
        balanceOf[_to] += _value;
        emit Transfer(_from, _to, _value);
         
        assert(balanceOf[_from] + balanceOf[_to] == previousBalances);
    }

     
    function transfer(address _to, uint256 _value) public {
        _transfer(msg.sender, _to, _value);
    }

     
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {
        require(_value <= allowance[_from][msg.sender], "allowance too low");      
        allowance[_from][msg.sender] -= _value;
        _transfer(_from, _to, _value);
        return true;
    }

     
    function approve(address _spender, uint256 _value) public returns (bool success) {
        allowance[msg.sender][_spender] = _value;
        return true;
    }

     
    function approveAndCall(address _spender, uint256 _value, bytes _extraData) public returns (bool success) {
        tokenRecipient spender = tokenRecipient(_spender);
        if (approve(_spender, _value)) {
            spender.receiveApproval(msg.sender, _value, this, _extraData);
            return true;
        }
    }

     
    function burn(uint256 _value) public returns (bool success) {
        require(balanceOf[msg.sender] >= _value, "balance insufficient");    
        balanceOf[msg.sender] -= _value;             
        totalSupply -= _value;                       
        emit Burn(msg.sender, _value);
        return true;
    }

     
    function burnFrom(address _from, uint256 _value) public returns (bool success) {
        require(balanceOf[_from] >= _value, "balance insufficient");  
        require(_value <= allowance[_from][msg.sender], "allowance too low");     
        balanceOf[_from] -= _value;                          
        allowance[_from][msg.sender] -= _value;              
        totalSupply -= _value;                               
        emit Burn(_from, _value);
        return true;
    }
}

contract owned {
    address public owner;

    constructor() public {
        owner = msg.sender;
    }

    modifier onlyOwner {
        require(msg.sender == owner, "not the owner");
        _;
    }

    function transferOwnership(address newOwner) public onlyOwner {
        owner = newOwner;
    }
}

contract Germoney is owned, TokenERC20 {

    uint256 public price;

     
    constructor (uint256 _price) TokenERC20(13000000000, "Germoney", "GER", 2) public {
        require (_price > 0, "price can not be 0");
        price = _price;
    }

     
    function _transfer(address _from, address _to, uint _value) internal {
        require (_to != 0x0, "not allowed. Use burn instead");      
        require (balanceOf[_from] >= _value, "balance insufficient");
        require (balanceOf[_to] + _value > balanceOf[_to], "overflow detected");
        balanceOf[_from] -= _value;                          
        balanceOf[_to] += _value;                            
        emit Transfer(_from, _to, _value);
    }

    function _buy(uint256 ethToBuy) internal {
        uint amount = ethToBuy / price;               
        _transfer(this, msg.sender, amount);     
    }
     
    function buy() public payable {
        _buy(msg.value);      
    }

    function() public payable {
        _buy(msg.value);      
    }

    function withdraw(address _to) external onlyOwner {
        _to.transfer(address(this).balance);
    }
}