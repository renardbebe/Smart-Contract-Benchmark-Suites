 

pragma solidity 0.5.7;

 
 
 
 
 
 
 
 
 
 

 
 
 
library SafeMath {
    function add(uint a, uint b) internal pure returns (uint c) {
        c = a + b;
        require(c >= a);
    }
    function sub(uint a, uint b) internal pure returns (uint c) {
        require(b <= a);
        c = a - b;
    }
    function mul(uint a, uint b) internal pure returns (uint c) {
        c = a * b;
        require(a == 0 || c / a == b);
    }
    function div(uint a, uint b) internal pure returns (uint c) {
        require(b > 0);
        c = a / b;
    }
}

 
 
 

contract owned {
    address public owner;
    address public newOwner;

    event OwnershipTransferred(address indexed _from, address indexed _to);

    constructor() public {
        owner = msg.sender;
    }

    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }

    function transferOwnership(address _newOwner) public onlyOwner {
        newOwner = _newOwner;
    }
	
    function acceptOwnership() public {
        require(msg.sender == newOwner);
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
        newOwner = address(0);
    }
}

interface tokenRecipient { function receiveApproval(address _from, uint256 _value, address _token, bytes calldata _extraData) external; }

contract TokenERC20 is owned{
    
    using SafeMath for uint;
    
     
    string public name;
    string public symbol;
    uint8 public decimals = 18;
    uint256 public totalSupply;
    address public saleAgent;
    address public nodeAgent;
    bool public tokenTransfer;

     
    mapping (address => uint256) public balanceOf;
    mapping (address => mapping (address => uint256)) public allowance;

     
    event Transfer(address indexed from, address indexed to, uint256 value);
    
     
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);

     
    event Burn(address indexed from, uint256 value);

     
    constructor() public {
        symbol = "GENES";
        name = "Genesis Smart Coin";
        totalSupply = 70000000000 * 10**uint(decimals);
        balanceOf[msg.sender] = totalSupply;
        tokenTransfer = false;                             
    }

     
    function _transfer(address _from, address _to, uint256 _value) internal {
         
        require(tokenTransfer);
         
        require(_to != address(0x0));
         
        require(balanceOf[_from] >= _value);
         
        require(balanceOf[_to] + _value > balanceOf[_to]);
         
        uint256 previousBalances = balanceOf[_from] + balanceOf[_to];
         
        balanceOf[_from] -= _value;
         
        balanceOf[_to] += _value;
        emit Transfer(_from, _to, _value);
         
        assert(balanceOf[_from] + balanceOf[_to] == previousBalances);
    }

     
    function transfer(address _to, uint256 _value) public returns (bool success) {
        require(tokenTransfer || msg.sender == owner || msg.sender == saleAgent || msg.sender == nodeAgent);
        _transfer(msg.sender, _to, _value);
        return true;
    }

     
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {
        require(tokenTransfer);
        require(_value <= allowance[_from][msg.sender]);      
        allowance[_from][msg.sender] -= _value;
        _transfer(_from, _to, _value);
        return true;
    }

     
    function approve(address _spender, uint256 _value) public returns (bool success) {
        require(tokenTransfer);
        allowance[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }

     
    function approveAndCall(address _spender, uint256 _value, bytes memory _extraData) public returns (bool success) {
        require(tokenTransfer);
        tokenRecipient spender = tokenRecipient(_spender);
        if (approve(_spender, _value)) {
            spender.receiveApproval(msg.sender, _value, address(this), _extraData);
            return true;
        }
    }

     
    function burn(uint256 _value) public returns (bool success) {
        require(balanceOf[msg.sender] >= _value);    
        balanceOf[msg.sender] -= _value;             
        totalSupply -= _value;                       
        emit Burn(msg.sender, _value);
        return true;
    }

     
    function burnFrom(address _from, uint256 _value) public returns (bool success) {
        require(balanceOf[_from] >= _value);                 
        require(_value <= allowance[_from][msg.sender]);     
        balanceOf[_from] -= _value;                          
        allowance[_from][msg.sender] -= _value;              
        totalSupply -= _value;                               
        emit Burn(_from, _value);
        return true;
    }
}

contract GenesisToken is owned, TokenERC20 {

    bool public tokenMint;
    bool public exchangeStatus;
    uint256 public sellPrice;
    uint256 public buyPrice;

    mapping (address => bool) public frozenAccount;

     
    event FrozenFunds(address target, bool frozen);

     
    constructor() public {
        tokenMint = true;
        exchangeStatus = false;
        sellPrice = 2500;
        buyPrice = 2500;
    }

     
    function _transfer(address _from, address _to, uint256 _value) internal {
        require (_to != address(0x0));                           
        require (balanceOf[_from] >= _value);                    
        require (balanceOf[_to] + _value >= balanceOf[_to]);     
        require(!frozenAccount[_from]);                          
        require(!frozenAccount[_to]);                            
        balanceOf[_from] -= _value;                              
        balanceOf[_to] += _value;                                
        emit Transfer(_from, _to, _value);
    }

     
     
     
    function mintToken(address target, uint256 mintedAmount) onlyOwner public {
        require(tokenMint);
        balanceOf[target] += mintedAmount;
        totalSupply += mintedAmount;
        emit Transfer(address(0), address(this), mintedAmount);
        emit Transfer(address(this), target, mintedAmount);
    }

     
     
     
    function freezeAccount(address target, bool freeze) onlyOwner public {
        frozenAccount[target] = freeze;
        emit FrozenFunds(target, freeze);
    }

     
     
     
    function setPrices(uint256 newSellPrice, uint256 newBuyPrice) onlyOwner public {
        sellPrice = newSellPrice;
        buyPrice = newBuyPrice;
    }

     
    function buy() payable public {
        require(exchangeStatus);
        uint256 amount = msg.value.mul(buyPrice);                   
        _transfer(address(this), msg.sender, amount);            
    }

     
     
    function sell(uint256 amount) public {
        require(exchangeStatus);
        address myAddress = address(this);
        require(myAddress.balance >= amount.div(sellPrice));     
        _transfer(msg.sender, address(this), amount);            
        msg.sender.transfer(amount.div(sellPrice));              
    }
    
     
     
    function setSaleAgent(address _saleAgent) onlyOwner public {
        saleAgent = _saleAgent;
    }
    
     
     
    function setNodeAgent(address _nodeAgent) onlyOwner public {
        nodeAgent = _nodeAgent;
    }
    
     
     
    function setExchangeStatus(bool _exchangeStatus) onlyOwner public {
        exchangeStatus = _exchangeStatus; 
    }
    
     
    function sendAllTokensToOwner() onlyOwner public {
        _transfer(address(this), owner, balanceOf[address(this)]);
    }
    
     
    function finalizationAfterICO() onlyOwner public {
        tokenMint = false;
        tokenTransfer = true;
    }
}