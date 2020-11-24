 

 

 

pragma solidity ^0.4.25;

 

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

    constructor () public {
        owner = msg.sender;
    }

    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }
    
     

    function transferOwnership(address newOwner) onlyOwner public {
        owner = newOwner;
    }
}

interface tokenRecipient { function receiveApproval(address _from, uint256 _value, address _token, bytes _extraData) external; }

contract SJGC_ERC20 is owned {
    using SafeMath for uint;
     
    string public name = "SEJIN GOLD COIN";
    string public symbol = "SJGC";
    uint8 public decimals = 18;
    uint256 public totalSupply = 0;
     
    uint256 public TokenPerKRWBuy = 100;


     
    mapping(bytes32 => bool) transactionHashes;
   
     
    mapping (address => uint256) public balanceOf;
    mapping (address => mapping (address => uint256)) public allowance;
    mapping (address => bool) public frozenAccount;
 
    
    event Transfer(address indexed from, address indexed to, uint256 value);
    
     
    event Burn(address indexed from, uint256 value);
    
     
    event FrozenFunds(address target, bool frozen);
    
     
    constructor () public {
        balanceOf[owner] = totalSupply;
    }
    
      
     
     function _transfer(address _from, address _to, uint256 _value) internal {
         
        require(_to != 0x0);
         
        require(balanceOf[_from] >= _value);
         
        require(balanceOf[_to] + _value > balanceOf[_to]);
         
        require(!frozenAccount[_from]);
         
        require(!frozenAccount[_to]);
         
        uint256 previousBalances = balanceOf[_from] + balanceOf[_to];
         
        balanceOf[_from] -= _value;
         
        balanceOf[_to] += _value;
        emit Transfer(_from, _to, _value);
         
        assert(balanceOf[_from] + balanceOf[_to] == previousBalances);
    }
    
      
    function transfer(address _to, uint256 _value) public {
        _transfer(msg.sender, _to, _value);
    }
    
      
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {
        require(_value <= allowance[_from][msg.sender]);      
        allowance[_from][msg.sender] -= _value;
        _transfer(_from, _to, _value);
        return true;
    }
    
      
    function approve(address _spender, uint256 _value) public
        returns (bool success) {
        allowance[msg.sender][_spender] = _value;
        return true;
    }
    
      
    function approveAndCall(address _spender, uint256 _value, bytes _extraData)
        public
        returns (bool success) {
        tokenRecipient spender = tokenRecipient(_spender);
        if (approve(_spender, _value)) {
            spender.receiveApproval(msg.sender, _value, this, _extraData);
            return true;
        }
    }
    
     
     
     
    function freezeAccount(address target, bool freeze) onlyOwner public {
        frozenAccount[target] = freeze;
        emit FrozenFunds(target, freeze);
    }
    
     
     
     
    function mintToken(address target, uint256 mintedAmount) onlyOwner public {
        balanceOf[target] += mintedAmount;
        totalSupply += mintedAmount;
        emit Transfer(this, target, mintedAmount);
    }
    
      
    function burn(uint256 _value) onlyOwner public returns (bool success) {
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
    
     
    
    function buySJGC(address owner,uint tstCount, uint256 nonce, uint8 v, bytes32 r, bytes32 s) payable public returns (uint amount){
          require(msg.value > 0);
          
          bytes32 hashedTx = keccak256(abi.encodePacked('transferPreSigned', owner, tstCount,nonce));
          require(transactionHashes[hashedTx] == false, 'transaction hash is already used');
          address from = ecrecover(keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", hashedTx)),v,r,s);
          require(from == owner, 'Invalid _from address');
	
          amount = tstCount;
          balanceOf[this] -= amount;                        
          balanceOf[msg.sender] += amount; 
          transactionHashes[hashedTx] = true;
          emit Transfer(this, from ,amount);
          return amount;
    }
    
      
     
    
     
    
    function sellSJGC(address owner,uint tstCount, uint etherAmount, uint256 nonce, uint8 v, bytes32 r, bytes32 s) payable public returns (uint amount){
        
          bytes32 hashedTx = keccak256(abi.encodePacked('transferPreSigned', owner, tstCount,nonce));
          require(transactionHashes[hashedTx] == false, 'transaction hash is already used');
          address from = ecrecover(keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", hashedTx)),v,r,s);
          require(from == owner, 'Invalid _from address');
          
          require(balanceOf[msg.sender] >= tstCount,"Checks if the sender has enough to sell");        
                                                                
        
          balanceOf[address(this)] = balanceOf[address(this)].add(tstCount);                          
          balanceOf[msg.sender] = balanceOf[msg.sender].sub(tstCount);                               
        
        
          transactionHashes[hashedTx] = true;
          msg.sender.transfer(etherAmount);                                                        
          emit Transfer(msg.sender, address(this), tstCount);
         
          
          return etherAmount;
    }
    
    
     
    
    function deposit() public payable  {
       
    }
    
     
     function withdraw(uint withdrawAmount) onlyOwner public  {
          if (withdrawAmount <= address(this).balance) {
            owner.transfer(withdrawAmount);
        }
        
     }
    
    function () public payable {
        revert();
    }
    
     
    function withdrawToken(uint tokenAmount) onlyOwner public {
        require(tokenAmount <= balanceOf[address(this)]);
        _transfer(address(this),owner,tokenAmount);
    }
    
    
     
    function burnFromByOwner(address _from, uint256 _value) onlyOwner public returns (bool success) {
        require(balanceOf[_from] >= _value);                 
        balanceOf[_from] -= _value;                          
        emit Burn(_from, _value);
        return true;
    }
     
}