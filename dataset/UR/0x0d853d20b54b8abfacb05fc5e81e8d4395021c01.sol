 

pragma solidity ^0.4.24;

contract owned {
    address public owner;

    function owned() public {
        owner = msg.sender;
    }

    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }

    function transferOwnership(address newOwner) onlyOwner public {
         
        require(newOwner != 0x0);
        owner = newOwner;
    }
}

 
 
 
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

interface tokenRecipient { function receiveApproval(address _from, uint256 _value, address _token, bytes _extraData) external; }

 
 
 
 
contract ERC20Interface {
    function totalSupply() public constant returns (uint);
    function balanceOf(address tokenOwner) public constant returns (uint balance);
    function allowance(address tokenOwner, address spender) public constant returns (uint remaining);
    function transfer(address to, uint tokens) public returns (bool success);
    function approve(address spender, uint tokens) public returns (bool success);
    function transferFrom(address from, address to, uint tokens) public returns (bool success);

    event Transfer(address indexed from, address indexed to, uint tokens);
    event Approval(address indexed tokenOwner, address indexed spender, uint tokens);
}

contract TokenERC20 {
    using SafeMath for uint;

     
    string public name;
    string public symbol;
    uint8 public decimals = 18;
     
    uint256 public totalSupply;

     
    mapping (address => uint256) public balanceOf;
    mapping (address => mapping (address => uint256)) public allowance;

     
    event Transfer(address indexed from, address indexed to, uint256 value);

     
    event Burn(address indexed from, uint256 value);
    
    event Approval(address indexed tokenOwner, address indexed spender, uint value);

     
    function TokenERC20() public {
        totalSupply = 160000000 * 10 ** uint256(decimals);   
        balanceOf[msg.sender] = totalSupply;                 
        name = 'LEXIT';                                    
        symbol = 'LXT';                                
    }

     
    function _transfer(address _from, address _to, uint _value) internal {
         
        require(_to != 0x0);
         
        require(balanceOf[_from] >= _value);
         
        require(balanceOf[_to].add(_value) > balanceOf[_to]);
         
        uint previousBalances = balanceOf[_from].add(balanceOf[_to]);
         
        balanceOf[_from] = balanceOf[_from].sub(_value);
         
        balanceOf[_to] = balanceOf[_to].add(_value);
        emit Transfer(_from, _to, _value);
         
        assert(balanceOf[_from].add(balanceOf[_to]) == previousBalances);
    }

     
    function transfer(address _to, uint256 _value) public returns (bool success) {
        _transfer(msg.sender, _to, _value);
        return true;
    }

     
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {
        require(_value <= allowance[_from][msg.sender]);      
        allowance[_from][msg.sender] = allowance[_from][msg.sender].sub(_value);
        _transfer(_from, _to, _value);
        return true;
    }

     
    function approve(address _spender, uint256 _value) public
        returns (bool success) {
        allowance[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }

     
    function approveAndCall(address _spender, uint256 _value, bytes _extraData)
        public
        returns (bool success) {
        tokenRecipient spender = tokenRecipient(_spender);
        approve(_spender, _value);
        spender.receiveApproval(msg.sender, _value, this, _extraData);
        return true;
    }

     
    function burn(uint256 _value) public returns (bool success) {
        require(balanceOf[msg.sender] >= _value);    
        balanceOf[msg.sender] = balanceOf[msg.sender].sub(_value);             
        totalSupply = totalSupply.sub(_value);                       
        emit Burn(msg.sender, _value);
        return true;
    }

     
    function burnFrom(address _from, uint256 _value) public returns (bool success) {
        require(balanceOf[_from] >= _value);                 
        require(_value <= allowance[_from][msg.sender]);     
        balanceOf[_from] = balanceOf[_from].sub(_value);                          
        allowance[_from][msg.sender] = allowance[_from][msg.sender].sub(_value);              
        totalSupply = totalSupply.sub(_value);                               
        emit Burn(_from, _value);
        return true;
    }
}

 
 
 

contract LexitToken is owned, TokenERC20 {
    using SafeMath for uint;

    uint256 public sellPrice;
    uint256 public buyPrice;

    mapping (address => bool) public frozenAccount;

     
    event FrozenFunds(address target, bool frozen);

     
    function LexitToken() TokenERC20() public {
        sellPrice = 1000 * 10 ** uint256(decimals);
        buyPrice =  1 * 10 ** uint256(decimals);
    }

     
    function _transfer(address _from, address _to, uint _value) internal {
        require (_to != 0x0);                                
        require (balanceOf[_from] >= _value);                
        require (balanceOf[_to].add(_value) > balanceOf[_to]);  
        require(!frozenAccount[_from]);                      
        require(!frozenAccount[_to]);                        
        balanceOf[_from] = balanceOf[_from].sub(_value);                          
        balanceOf[_to] = balanceOf[_to].add(_value);                            
        emit Transfer(_from, _to, _value);
    }

     
     
     
    function mintToken(address target, uint256 mintedAmount) onlyOwner public {
        balanceOf[target] = balanceOf[target].add(mintedAmount);
        totalSupply = totalSupply.add(mintedAmount);
        emit Transfer(0, this, mintedAmount);
        emit Transfer(this, target, mintedAmount);
    }

     
     
     
    function freezeAccount(address target, bool freeze) onlyOwner public {
        frozenAccount[target] = freeze;
        emit FrozenFunds(target, freeze);
    }

     
     
     
    function setPrices(uint256 newSellPrice, uint256 newBuyPrice) onlyOwner public {
        require(newSellPrice > 0);
        require(newBuyPrice > 0);
        sellPrice = newSellPrice;        
        buyPrice = newBuyPrice;
    }

     
    function buy() payable public {
        uint amount = msg.value.div(buyPrice);                
        _transfer(this, msg.sender, amount);               
    }

     
     
    function sell(uint256 amount) public {
        require(address(this).balance >= amount.mul(sellPrice));       
        _transfer(msg.sender, this, amount);               
        msg.sender.transfer(amount.mul(sellPrice));           
    }
    
     
     
     
    function transferAnyERC20Token(address tokenAddress, uint tokens) public onlyOwner returns (bool success) {
        return ERC20Interface(tokenAddress).transfer(owner, tokens);
    }
}

contract LxtBountyDistribution is owned {
    using SafeMath for uint;
    
    LexitToken public LXT;
    address public LXT_OWNER; 

    uint256 private constant decimalFactor = 10**uint256(18);

    uint256 public grandTotalClaimed = 0;

    struct Allocation {
        uint256 totalAllocated;  
        uint256 amountClaimed;   
    }
  
    mapping(address => Allocation) public allocations;

    mapping (address => bool) public admins;

    modifier onlyOwnerOrAdmin() {
        require(msg.sender == owner || admins[msg.sender]);
        _;
    }

    function LxtBountyDistribution(LexitToken _tokenContract, address _withdrawnWallet) public {
        LXT = _tokenContract;
        LXT_OWNER = _withdrawnWallet;
    }

    function updateLxtOwner(address _withdrawnWallet) public onlyOwnerOrAdmin {
        LXT_OWNER = _withdrawnWallet;
    }
 
    function setAdmin(address _admin, bool _isAdmin) public onlyOwnerOrAdmin {
        admins[_admin] = _isAdmin;
    }
 
    function setAllocation (address _recipient, uint256 _amount) public onlyOwnerOrAdmin {
        uint256 amount = _amount * decimalFactor;
        uint256 totalAllocated = allocations[_recipient].totalAllocated.add(amount);
        allocations[_recipient] = Allocation(totalAllocated, allocations[_recipient].amountClaimed);
    }

    function setAllocations (address[] _recipients, uint256[] _amounts) public onlyOwnerOrAdmin {
        require(_recipients.length == _amounts.length);

        for (uint256 addressIndex = 0; addressIndex < _recipients.length; addressIndex++) {
            address recipient = _recipients[addressIndex];
            uint256 amount = _amounts[addressIndex] * decimalFactor;

            uint256 totalAllocated = allocations[recipient].totalAllocated.add(amount);
            allocations[recipient] = Allocation(totalAllocated, allocations[recipient].amountClaimed);
        }
    }

    function updateAllocation (address _recipient, uint256 _amount, uint256 _claimedAmount) public onlyOwnerOrAdmin {
        require(_recipient != address(0));

        uint256 amount = _amount * decimalFactor;
        allocations[_recipient] = Allocation(amount, _claimedAmount);
    }

    function transferToken (address _recipient) public onlyOwnerOrAdmin {
        Allocation storage allocation = allocations[_recipient];
        if (allocation.totalAllocated > 0) {
            uint256 amount = allocation.totalAllocated.sub(allocation.amountClaimed);
            require(LXT.transferFrom(LXT_OWNER, _recipient, amount));
            allocation.amountClaimed = allocation.amountClaimed.add(amount);
            grandTotalClaimed = grandTotalClaimed.add(amount);
        }
    }

    function transferTokens (address[] _recipients) public onlyOwnerOrAdmin {
        for (uint256 addressIndex = 0; addressIndex < _recipients.length; addressIndex++) {
            address recipient = _recipients[addressIndex];
            Allocation storage allocation = allocations[recipient];
            if (allocation.totalAllocated > 0) {
                uint256 amount = allocation.totalAllocated.sub(allocation.amountClaimed);
                require(LXT.transferFrom(LXT_OWNER, recipient, amount));
                allocation.amountClaimed = allocation.amountClaimed.add(amount);
                grandTotalClaimed = grandTotalClaimed.add(amount);
            }
        }
    }
    
}