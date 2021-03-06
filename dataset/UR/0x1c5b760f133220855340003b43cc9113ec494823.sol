 

pragma solidity 0.4.25;   

 
 
 
     
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
    
    interface tokenRecipient { function receiveApproval(address _from, uint256 _value, address _token, bytes  _extraData) external; }


 
 
 
    
    contract TokenERC20 {
         
        using SafeMath for uint256;
        string public name;
        string public symbol;
        uint8 public decimals = 18;  
        uint256 public totalSupply;
        bool public safeguard = false;   
    
         
        mapping (address => uint256) public balanceOf;
        mapping (address => mapping (address => uint256)) public allowance;
    
         
        event Transfer(address indexed from, address indexed to, uint256 value);
    
         
        event Burn(address indexed from, uint256 value);
    
         
        constructor (
            uint256 initialSupply,
            string memory tokenName,
            string memory tokenSymbol
        ) public {
            totalSupply = initialSupply.mul(1 ether);        
            balanceOf[msg.sender] = totalSupply;             
            name = tokenName;                                
            symbol = tokenSymbol;                            
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
    
         
        function approveAndCall(address _spender, uint256 _value, bytes memory _extraData)
            public
            returns (bool success) {
            require(!safeguard);
            tokenRecipient spender = tokenRecipient(_spender);
            if (approve(_spender, _value)) {
                spender.receiveApproval(msg.sender, _value, address(this), _extraData);
                return true;
            }
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
    
 
 
 
    
    contract Cointorox is owned, TokenERC20 {
        
         
         
         
        bool public whitelistingStatus = false;
        mapping (address => bool) public whitelisted;
        
         
        function changeWhitelistingStatus() onlyOwner public{
            if (whitelistingStatus == false){
                whitelistingStatus = true;
            }
            else{
                whitelistingStatus = false;    
            }
        }
        
         
        function whitelistUser(address userAddress) onlyOwner public{
            require(whitelistingStatus == true);
            require(userAddress != address(0x0));
            whitelisted[userAddress] = true;
        }
        
         
        function whitelistManyUsers(address[] memory userAddresses) onlyOwner public{
            require(whitelistingStatus == true);
            uint256 addressCount = userAddresses.length;
            require(addressCount <= 150);
            for(uint256 i = 0; i < addressCount; i++){
                require(userAddresses[i] != address(0x0));
                whitelisted[userAddresses[i]] = true;
            }
        }
        
        
        
         
         
         
    
         
        string private tokenName = "Cointorox";
        string private tokenSymbol = "OROX";
        uint256 private initialSupply = 10000000;   
        
        
         
        mapping (address => bool) public frozenAccount;
        
         
        event FrozenFunds(address target, bool frozen);
    
         
        constructor () TokenERC20(initialSupply, tokenName, tokenSymbol) public {}

         
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

          
         
        function manualWithdrawEther()onlyOwner public{
            address(owner).transfer(address(this).balance);
        }
        
         
        function destructContract()onlyOwner public{
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