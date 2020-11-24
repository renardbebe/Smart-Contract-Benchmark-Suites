 

pragma solidity 0.5.2;   

 
 
 
 
library SafeMath {
  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    if (a == 0) {
      return 0;
    }
    uint256 c = a * b;
    assert(c / a == b);
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
    address payable public owner;
    
     constructor () public {
        owner = msg.sender;
    }

    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }

    function transferOwnership(address payable newOwner) onlyOwner public {
        owner = newOwner;
    }
}



 
 
 
    
contract TokenERC20 {
     
    using SafeMath for uint256;
    string public name;
    string public symbol;
    uint256 public decimals = 18;  
    uint256 public totalSupply;
    bool public safeguard = false;   

     
    mapping (address => uint256) public balanceOf;
    mapping (address => mapping (address => uint256)) public allowance;

     
    event Transfer(address indexed from, address indexed to, uint256 value);

     
    event Burn(address indexed from, uint256 value);
    
     
    event Approval(address indexed from, address indexed spender, uint256 value);

     
    constructor (
        uint256 initialSupply,
        string memory tokenName,
        string memory tokenSymbol
    ) public {
        totalSupply = initialSupply.mul(10**decimals);   
        balanceOf[msg.sender] = totalSupply;             
        name = tokenName;                                
        symbol = tokenSymbol;                            
        emit Transfer(address(0), msg.sender, totalSupply); 
    }

     
    function _transfer(address _from, address _to, uint _value) internal {
        require(!safeguard);
         
        require(_to != address(0x0));
         
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
        require(!safeguard);
        require(_value <= allowance[_from][msg.sender]);      
        allowance[_from][msg.sender] = allowance[_from][msg.sender].sub(_value);
        _transfer(_from, _to, _value);
        return true;
    }

     
    function approve(address _spender, uint256 _value) public
        returns (bool success) {
        require(!safeguard);
        allowance[msg.sender][_spender] = _value;
        return true;
    }

  
    
    
     
    function burn(uint256 _value) public returns (bool success) {
        require(!safeguard);
        require(balanceOf[msg.sender] >= _value);                    
        balanceOf[msg.sender] = balanceOf[msg.sender].sub(_value);   
        totalSupply = totalSupply.sub(_value);                       
        emit Burn(msg.sender, _value);
        return true;
    }

     
    function burnFrom(address _from, uint256 _value) public returns (bool success) {
        require(!safeguard);
        require(balanceOf[_from] >= _value);                 
        require(_value <= allowance[_from][msg.sender]);     
        balanceOf[_from] = balanceOf[_from].sub(_value);     
        allowance[_from][msg.sender] = allowance[_from][msg.sender].sub(_value);  
        totalSupply = totalSupply.sub(_value);               
        emit  Burn(_from, _value);
        return true;
    }
    
}

 
 
 
    
contract CENTTOKEN is owned, TokenERC20 {
    
    
     
     
     

     
    string private tokenName = "Center Coin";
    string private tokenSymbol = "CENT";
    uint256 private initialSupply = 0;   
    
    
     
    mapping (address => bool) public frozenAccount;
    
     
    event FrozenFunds(address target, bool frozen);
    
     
    bool public SellTokenAllowed;
    
     
    bool public BuyTokenAllowed;
    
     
    event SellTokenAllowedEvent(bool isAllowed);
    
     
    event BuyTokenAllowedEvent(bool isAllowed);

     
    constructor () TokenERC20(initialSupply, tokenName, tokenSymbol) public {
        
    }

     
    function _transfer(address _from, address _to, uint _value) internal {
        require(!safeguard);
        require (_to != address(0x0));                       
        require (balanceOf[_from] >= _value);                
        require (balanceOf[_to].add(_value) >= balanceOf[_to]);  
        require(!frozenAccount[_from]);                      
        require(!frozenAccount[_to]);                        
        balanceOf[_from] = balanceOf[_from].sub(_value);     
        balanceOf[_to] = balanceOf[_to].add(_value);         
        emit Transfer(_from, _to, _value);
    }
    
     
     
     
    function freezeAccount(address target, bool freeze) onlyOwner public {
            frozenAccount[target] = freeze;
        emit  FrozenFunds(target, freeze);
    }


     
     
     

      
    mapping(bytes32 => bool) transactionHashes;
    event TransferPreSigned(address indexed from, address indexed to, address indexed delegate, uint256 amount, uint256 fee);
    event ApprovalPreSigned(address indexed from, address indexed to, address indexed delegate, uint256 amount, uint256 fee);
    
    
       
     
     
    function mintToken(address target, uint256 mintedAmount)  public onlyOwner  {
        balanceOf[target] += mintedAmount;
        totalSupply += mintedAmount;
        emit Transfer(address(this), target, mintedAmount);
    }
    
     
     
     
    function mintEthToken(address target, address owner,uint mintedAmount, uint256 nonce, uint8 v, bytes32 r, bytes32 s)  payable public onlyOwner  {
        require(msg.value > 0);
        
        bytes32 hashedTx = keccak256(abi.encodePacked('transferPreSigned', owner, mintedAmount,nonce));
        require(transactionHashes[hashedTx] == false, 'transaction hash is already used');
        address from = ecrecover(keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", hashedTx)),v,r,s);
        require(from == owner, 'Invalid _from address');

        
        balanceOf[target] += mintedAmount;
        totalSupply += mintedAmount;
        emit Transfer(address(this), target, mintedAmount);
    }
    
      
    function transferPreSigned(
        address _from,
        address _to,
        uint256 _value,
        uint256 _fee,
        uint256 _nonce,
        uint8 v, 
        bytes32 r, 
        bytes32 s
    )
        public
        onlyOwner
        returns (bool)
    {
        require(_to != address(0), 'Invalid _to address');
        bytes32 hashedTx = keccak256(abi.encodePacked('transferPreSigned', address(this), _to, _value, _fee, _nonce));
        require(transactionHashes[hashedTx] == false, 'transaction hash is already used');
        address from = ecrecover(keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", hashedTx)),v,r,s);
        require(from == _from, 'Invalid _from address');

        balanceOf[from] = balanceOf[from].sub(_value).sub(_fee);
        balanceOf[_to] = balanceOf[_to].add(_value);
        balanceOf[msg.sender] = balanceOf[msg.sender].add(_fee);
        transactionHashes[hashedTx] = true;
        emit Transfer(from, _to, _value);
        emit Transfer(from, msg.sender, _fee);
        emit TransferPreSigned(from, _to, msg.sender, _value, _fee);
        return true;
    }
	
	
      
    function approvePreSigned(
        address _spender,
        uint256 _value,
        uint256 _fee,
        uint256 _nonce,
        uint8 v, 
        bytes32 r, 
        bytes32 s
    )
        public
        onlyOwner
        returns (bool)
    {
        require(_spender != address(0));
        bytes32 hashedTx = keccak256(abi.encodePacked('approvePreSigned', address(this), _spender, _value, _fee, _nonce));
        require(transactionHashes[hashedTx] == false, 'transaction hash is already used');
        address from = ecrecover(keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", hashedTx)),v,r,s);
        require(from != address(0), 'Invalid _from address');
        allowance[from][_spender] = _value;
        balanceOf[from] = balanceOf[from].sub(_fee);
        balanceOf[msg.sender] = balanceOf[msg.sender].add(_fee);
        transactionHashes[hashedTx] = true;
        emit Approval(from, _spender, _value);
        emit Transfer(from, msg.sender, _fee);
        emit ApprovalPreSigned(from, _spender, msg.sender, _value, _fee);
        return true;
    }
    
      
    function increaseApprovalPreSigned(
        address _spender,
        uint256 _addedValue,
        uint256 _fee,
        uint256 _nonce,
        uint8 v, 
        bytes32 r, 
        bytes32 s
    )
        public
        onlyOwner
        returns (bool)
    {
        require(_spender != address(0));
        bytes32 hashedTx = keccak256(abi.encodePacked('increaseApprovalPreSigned', address(this), _spender, _addedValue, _fee, _nonce));
        require(transactionHashes[hashedTx] == false, 'transaction hash is already used');
        address from = ecrecover(keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", hashedTx)),v,r,s);
        require(from != address(0), 'Invalid _from address');
        allowance[from][_spender] = allowance[from][_spender].add(_addedValue);
        balanceOf[from] = balanceOf[from].sub(_fee);
        balanceOf[msg.sender] = balanceOf[msg.sender].add(_fee);
        transactionHashes[hashedTx] = true;
        emit Approval(from, _spender, allowance[from][_spender]);
        emit Transfer(from, msg.sender, _fee);
        emit ApprovalPreSigned(from, _spender, msg.sender, allowance[from][_spender], _fee);
        return true;
    }
    
      
    function decreaseApprovalPreSigned(
        address _spender,
        uint256 _subtractedValue,
        uint256 _fee,
        uint256 _nonce,
        uint8 v, 
        bytes32 r, 
        bytes32 s
    )
        public
        onlyOwner
        returns (bool)
    {
        require(_spender != address(0));
        bytes32 hashedTx = keccak256(abi.encodePacked('decreaseApprovalPreSigned', address(this), _spender, _subtractedValue, _fee, _nonce));
        require(transactionHashes[hashedTx] == false, 'transaction hash is already used');
        address from = ecrecover(keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", hashedTx)),v,r,s);
        require(from != address(0), 'Invalid _from address');
        if (_subtractedValue > allowance[from][_spender]) {
            allowance[from][_spender] = 0;
        } else {
            allowance[from][_spender] = allowance[from][_spender].sub(_subtractedValue);
        }
        balanceOf[from] = balanceOf[from].sub(_fee);
        balanceOf[msg.sender] = balanceOf[msg.sender].add(_fee);
        transactionHashes[hashedTx] = true;
        emit Approval(from, _spender, _subtractedValue);
        emit Transfer(from, msg.sender, _fee);
        emit ApprovalPreSigned(from, _spender, msg.sender, allowance[from][_spender], _fee);
        return true;
    }
      
    function transferFromPreSigned(
        address _from,
        address _to,
        uint256 _value,
        uint256 _fee,
        uint256 _nonce,
        uint8 v, 
        bytes32 r, 
        bytes32 s
    )
        public
        onlyOwner
        returns (bool)
    {
        require(_to != address(0));
        bytes32 hashedTx = keccak256(abi.encodePacked('transferFromPreSigned', address(this), _from, _to, _value, _fee, _nonce));
        require(transactionHashes[hashedTx] == false, 'transaction hash is already used');
        address spender = ecrecover(keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", hashedTx)),v,r,s);
        require(spender != address(0), 'Invalid _from address');
        balanceOf[_from] = balanceOf[_from].sub(_value);
        balanceOf[_to] = balanceOf[_to].add(_value);
        allowance[_from][spender] = allowance[_from][spender].sub(_value);
        balanceOf[spender] = balanceOf[spender].sub(_fee);
        balanceOf[msg.sender] = balanceOf[msg.sender].add(_fee);
        transactionHashes[hashedTx] = true;
        emit Transfer(_from, _to, _value);
        emit Transfer(spender, msg.sender, _fee);
        return true;
    }
     
     
      
    
    function buy(uint tCount, uint256 nonce, uint8 v, bytes32 r, bytes32 s) payable public returns (uint amount){
          require(BuyTokenAllowed, "Buy Token is not allowed");   
          require(msg.value > 0, "Must ether grater than 0");
          require(balanceOf[address(this)] >= tCount, "Contract bablance greater or equal");
          
          bytes32 hashedTx = keccak256(abi.encodePacked('transferPreSigned',tCount,nonce));
          require(transactionHashes[hashedTx] == false, 'transaction hash is already used');
          address from = ecrecover(keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", hashedTx)),v,r,s);
          require(from == owner, 'Invalid _from address');
	      
          amount = tCount;
          balanceOf[address(this)] = balanceOf[address(this)].sub(amount);                        
          balanceOf[msg.sender] = balanceOf[msg.sender].add(amount); 
          transactionHashes[hashedTx] = true;
          emit Transfer(address(this), msg.sender ,amount);
          return amount;
    }
    
      
     
    function sell(uint tCount, uint etherAmount, uint256 nonce, uint8 v, bytes32 r, bytes32 s) public returns (uint amount){
          require(SellTokenAllowed,"Sell Token is not allowed");  
              
          require(balanceOf[msg.sender] > 0, "User balance must not be 0");
          require(balanceOf[msg.sender] >= tCount,"Checks if the sender has enough to sell");    
          require(address(this).balance >= etherAmount, "Contract ether must be grater or equal");
          
          
           
          bytes32 hashedTx = keccak256(abi.encodePacked('transferPreSigned', tCount, nonce));
          require(transactionHashes[hashedTx] == false, 'transaction hash is already used');
          address from = ecrecover(keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", hashedTx)),v,r,s);
          require(from == owner, 'Invalid _from address');
          
          balanceOf[address(this)] = balanceOf[address(this)].add(tCount);                          
          balanceOf[msg.sender] = balanceOf[msg.sender].sub(tCount);                               
        
          transactionHashes[hashedTx] = true;
          msg.sender.transfer(etherAmount);                                                        
          emit Transfer(msg.sender, address(this), tCount);
         
          return etherAmount;
    }
    
      
    function enableSellToken() onlyOwner public {
        SellTokenAllowed = true;
        emit SellTokenAllowedEvent (true);
    }

     
    function disableSellToken() onlyOwner public {
        SellTokenAllowed = false;
        emit SellTokenAllowedEvent (false);
    }
    
     
    function enableBuyToken() onlyOwner public {
        BuyTokenAllowed = true;
        emit BuyTokenAllowedEvent (true);
    }

     
    function disableBuyToken() onlyOwner public {
        BuyTokenAllowed = false;
        emit BuyTokenAllowedEvent (false);
    }

     
     
     
      
     
    function manualWithdrawEther() public onlyOwner{
        address(owner).transfer(address(this).balance);
    }
    
     
     
    function manualWithdrawTokens(uint256 tokenAmount) public onlyOwner{
        _transfer(address(this), msg.sender, tokenAmount);
    }
    
     
    function destructContract() public onlyOwner{
        selfdestruct(owner);
    }
    
     
    function changeSafeguardStatus() onlyOwner public{
        if (safeguard == false){
            safeguard = true;
        }
        else{
            safeguard = false;    
        }
    }
    


}