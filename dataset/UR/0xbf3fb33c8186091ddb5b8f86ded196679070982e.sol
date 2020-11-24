 

pragma solidity 0.4.25;

 
library SafeMath {
    
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a * b;
        assert(a == 0 || c / a == b);
        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
         
        uint256 c = a / b;
         
        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        assert(b <= a);
        return a - b;
    }

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        assert(c >= a);
        return c;
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

interface tokenRecipient { function receiveApproval(address _from, uint256 _oshiAmount, address _token, bytes _extraData) external; }

contract TokenERC20 {
    
    using SafeMath for uint256;
     
    string public name;
    string public symbol;
    uint8 public decimals = 18;
     
    uint256 public M = 10**uint256(decimals); 
    uint256 public totalSupply;

    
     
    mapping (address => uint256) public balanceOf;
    mapping (address => mapping (address => uint256)) public allowed;

     
    
     
    event Transfer(address indexed _from, address indexed _to, uint256 _oshiAmount);
     
    event Approval(address indexed _approvedBy, address _spender, uint256 _oshiAmount);
     
    event Burn(address indexed _from, uint256 _oshiAmount);

     
    constructor(
       uint256 initialSupply,
        string tokenName,
        string tokenSymbol
    )   public {
        
        totalSupply = initialSupply * M;
        balanceOf[msg.sender] = totalSupply;                 
        name = tokenName;                          
        symbol = tokenSymbol;                     
    }
    
     
    function _transfer(address _from, address _to, uint _oshiAmount) internal {
         
        require(_to != 0x0);
         
        balanceOf[_from] = balanceOf[_from].sub(_oshiAmount);
         
        balanceOf[_to] = balanceOf[_to].add(_oshiAmount);
        emit Transfer(_from, _to, _oshiAmount);
        
    }

     
    function transfer(address _to, uint256 _oshiAmount) public {
        _transfer(msg.sender, _to, _oshiAmount);
    }

     
     function transferFrom(address _from, address _to, uint256 _oshiAmount) public returns (bool success) {
        require(_oshiAmount <= balanceOf[_from]);
        allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_oshiAmount);
        require(_oshiAmount > 0 && _from != _to); 
        _transfer(_from, _to, _oshiAmount);
        
        return true;
    }

     
     function approve(address _spender, uint _oshiAmount) public returns (bool success) {
       
        allowed[msg.sender][_spender] = _oshiAmount;
        emit Approval(msg.sender, _spender, _oshiAmount);
        return true;
    }
    
       
    function approveAndCall(address _spender, uint256 _oshiAmount, bytes _extraData)
        public
        returns (bool success) {
        tokenRecipient spender = tokenRecipient(_spender);
        if (approve(_spender, _oshiAmount)) {
            spender.receiveApproval(msg.sender, _oshiAmount, this, _extraData);
            return true;
        }
    }
  
     
    function burn(uint256 _oshiAmount) public returns (bool success) {
    
        balanceOf[msg.sender] = balanceOf[msg.sender].sub(_oshiAmount);             
        totalSupply = totalSupply.sub(_oshiAmount);                       
        emit Burn(msg.sender, _oshiAmount);
        return true;
    }


     
    function burnFrom(address _from, uint256 _oshiAmount)  public returns (bool success) {
        balanceOf[_from] = balanceOf[_from].sub(_oshiAmount);                          
        allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_oshiAmount);              
        totalSupply = totalSupply.sub(_oshiAmount);                               
        emit Burn(_from, _oshiAmount);
        return true;
    }
}
 
 
 

contract Adamcoins is owned, TokenERC20 {
    
    using SafeMath for uint256;
    
    uint256 public sellPrice;                 
    uint256 public buyPrice;                  
    bool public purchasingAllowed = true;
    bool public sellingAllowed = true;

    
    mapping (address => uint) public pendingWithdrawals;
    mapping (address => bool) public frozenAccount;

     
    event FrozenFunds(address target, bool frozen);

     
     constructor(
        uint256 initialSupply,
        string tokenName,
        string tokenSymbol
    ) TokenERC20(initialSupply, tokenName, tokenSymbol) public {}
    
     
     
     
    function isContract(address _addr) view public returns(bool) {
        uint size;
        if (_addr == 0) return false;
        assembly {
            size := extcodesize(_addr)
        }
        return size>0;
    }

     
    function enablePurchasing() onlyOwner public {
        require (msg.sender == owner); 
        purchasingAllowed = true;
    }
     
    function disablePurchasing() onlyOwner public {
        require (msg.sender == owner); 
        purchasingAllowed = false;
    }
    
     
    function enableSelling() onlyOwner public {
        require (msg.sender == owner); 
        sellingAllowed = true;
    }
     
    function disableSelling() onlyOwner public {
        require (msg.sender == owner); 
        sellingAllowed = false;
    }
     
    function _transfer(address _from, address _to, uint _oshiAmount) internal {
        require (_to != 0x0);                                
        require(!frozenAccount[_from]);                      
        require(!frozenAccount[_to]);                        
        balanceOf[_from] = balanceOf[_from].sub(_oshiAmount);     
        balanceOf[_to] = balanceOf[_to].add(_oshiAmount);         
        emit Transfer(_from, _to, _oshiAmount);
    }

     
     
     
    function mintToken(address target, uint256 mintedOshiAmount) onlyOwner public returns (bool) {
        
        balanceOf[target] = balanceOf[target].add(mintedOshiAmount);
        totalSupply = totalSupply.add(mintedOshiAmount);
        emit Transfer(0, address(this), mintedOshiAmount);
        emit Transfer(address(this), target, mintedOshiAmount);
        return true;
    }

     
     
     
    function freezeAccount(address target, bool freeze) onlyOwner public {
        frozenAccount[target] = freeze;
        emit FrozenFunds(target, freeze);
    }

     
     
     
    function setPrices(uint256 newSellPrice, uint256 newBuyPrice) onlyOwner public {
        sellPrice = newSellPrice;
        buyPrice = newBuyPrice;
    
    }

    
	function withdrawEther(uint256 amount) onlyOwner public {
		require(msg.sender == owner);
		owner.transfer(amount);
	}
	 
	 
     
     
	function claimTokens(address _token) onlyOwner public {
        if (_token == 0x0) {
            owner.transfer(address(this).balance);
            return;
        }

        TokenERC20 token = TokenERC20(_token);
        uint balance = token.balanceOf(address(this));
        token.transfer(owner, balance);
        
    }
    
     
    function() public payable {
        
        require(msg.value > 0);
        require(purchasingAllowed);
        uint tokens = (msg.value * M)/buyPrice;  
        
	    pendingWithdrawals[msg.sender] = pendingWithdrawals[msg.sender].add(tokens);  
	}
	
	 
    function withdrawAdamcoins() public {
        require(purchasingAllowed);
        uint withdrawalAmount = pendingWithdrawals[msg.sender];  
        
        pendingWithdrawals[msg.sender] = 0;
        
        _transfer(address(this), msg.sender, withdrawalAmount);     
       
    }
    
     
     
    function sell(uint256 _adamcoinsAmountToSell) public {
        require(sellingAllowed);
        uint256 weiAmount = _adamcoinsAmountToSell.mul(sellPrice);
        require(address(this).balance >= weiAmount);       
        uint adamcoinsAmountToSell = _adamcoinsAmountToSell * M;
        _transfer(msg.sender, address(this), adamcoinsAmountToSell);               
        msg.sender.transfer(weiAmount);           
    }
    
    
}