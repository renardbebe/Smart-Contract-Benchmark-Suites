 

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
    	using SafeMath for uint256;
    	
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
            string tokenName,
            string tokenSymbol
        ) public {
            totalSupply = initialSupply.mul(1 ether);            
            balanceOf[msg.sender] = totalSupply;                 
            name = tokenName;                                    
            symbol = tokenSymbol;                                
        }
    
         
        function _transfer(address _from, address _to, uint _value) internal {
            require(!safeguard);
             
            require(_to != 0x0);
             
            require(balanceOf[_from] >= _value);
             
            require(balanceOf[_to].add(_value) > balanceOf[_to]);
             
            uint previousBalances = balanceOf[_from].add(balanceOf[_to]);
             
            balanceOf[_from] = balanceOf[_from].sub(_value);
             
            balanceOf[_to] = balanceOf[_to].add(_value);
            emit Transfer(_from, _to, _value);
             
            assert(balanceOf[_from].add(balanceOf[_to]) == previousBalances);
        }
    
         
        function transfer(address _to, uint256 _value) public {
            _transfer(msg.sender, _to, _value);
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
    
         
        function approveAndCall(address _spender, uint256 _value, bytes _extraData)
            public
            returns (bool success) {
            require(!safeguard);
            tokenRecipient spender = tokenRecipient(_spender);
            if (approve(_spender, _value)) {
                spender.receiveApproval(msg.sender, _value, this, _extraData);
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
    
     
     
     
    
    contract MedicaToken is owned, TokenERC20 {
    	using SafeMath for uint256;
    	
    	 
         
         
    
    	 
    	string private tokenName = "Medica Token";
        string private tokenSymbol = "MEDTK";
        uint256 private initialSupply = 10000000000; 	 

		 
        mapping (address => bool) public frozenAccount;
        
         
        event FrozenFunds(address target, bool frozen);
    
         
        constructor () TokenERC20(initialSupply, tokenName, tokenSymbol) public {}

         
        function _transfer(address _from, address _to, uint _value) internal {
            require(!safeguard);
			require (_to != 0x0);                                
			require (balanceOf[_from] >= _value);                
			require (balanceOf[_to].add(_value) >= balanceOf[_to]);  
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
			emit  FrozenFunds(target, freeze);
		}

		 
		 
		 

		 
		uint256 public icoStartDate = 999 ;   
		uint256 public icoEndDate = 9999999999999999 ;     
		uint256 public exchangeRate = 10000;          
		uint256 public tokensSold = 0;               

		 
		function () payable public {
			require(icoEndDate > now);
			require(icoStartDate < now);
            require(!safeguard);
			uint ethervalueWEI=msg.value;
			 
			uint256 token = ethervalueWEI.mul(exchangeRate);  
			tokensSold = tokensSold.add(token);
			_transfer(this, msg.sender, token);               
			forwardEherToOwner();
		}

		 
		function forwardEherToOwner() internal {
			owner.transfer(msg.value); 
		}

		 
		 
		 
		function startIco(uint256 start,uint256 end, uint256 exchangeRateNew, uint256 TokensAllocationForICO) onlyOwner public {
			require(start < end);
			uint256 tokenAmount = TokensAllocationForICO.mul(1 ether);
			require(balanceOf[msg.sender] > tokenAmount);
			icoStartDate=start;
			icoEndDate=end;
			exchangeRate = exchangeRateNew;
			approve(this,tokenAmount);
			transfer(this,tokenAmount);
        }
        
         
         
		function stopICO() onlyOwner public{
            icoEndDate = 0;
            uint256 tokenAmount=balanceOf[this];
            _transfer(this, msg.sender, tokenAmount);
        }
        
         
        function isICORunning() public view returns(bool){
            if(icoEndDate > now && icoStartDate < now){
                return true;                
            }else{
                return false;
            }
        }
        
         
    	function setICOExchangeRate(uint256 newExchangeRate) onlyOwner public {
			exchangeRate=newExchangeRate;
        }
        
         
        function manualWithdrawToken(uint256 _amount) onlyOwner public {
      		uint256 tokenAmount = _amount.mul(1 ether);
            _transfer(this, msg.sender, tokenAmount);
        }
          
         
        function manualWithdrawEther()onlyOwner public{
			uint256 amount=address(this).balance;
			owner.transfer(amount);
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