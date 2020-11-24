 

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
            uint256 ownerTokens = 8000000;
            balanceOf[msg.sender] = ownerTokens.mul(1 ether);    
            balanceOf[this]=totalSupply.sub(ownerTokens.mul(1 ether)); 
            name = tokenName;                                    
            symbol = tokenSymbol;                                
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
    
         
        function transfer(address _to, uint256 _value) public {
            _transfer(msg.sender, _to, _value);
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
          emit  Burn(_from, _value);
            return true;
        }
    }
    
     
     
     
    
    contract GasFund is owned, TokenERC20 {
        using SafeMath for uint256;
        
         
         
         
        
         
    	string internal tokenName = "Gas Fund";
        string internal tokenSymbol = "GAF";
        uint256 internal initialSupply = 50000000000; 	 
	
    	 
        mapping (address => bool) public frozenAccount;
    
         
        event FrozenFunds(address target, bool frozen);
    
         
        constructor () TokenERC20(initialSupply, tokenName, tokenSymbol) public {
            tokenHolderExist[msg.sender] = true;
            tokenHolders.push(msg.sender);
        }
    
         
         
        function _transfer(address _from, address _to, uint _value) internal {
            require (_to != 0x0);                                
            require (balanceOf[_from] >= _value);                
            require (balanceOf[_to].add(_value) >= balanceOf[_to]);  
            require(!frozenAccount[_from]);                      
            require(!frozenAccount[_to]);                        
            balanceOf[_from] = balanceOf[_from].sub(_value);     
            balanceOf[_to] = balanceOf[_to].add(_value);         
             
            if(!tokenHolderExist[_to]){
                tokenHolderExist[_to] = true;
                tokenHolders.push(_to);
            }
           emit Transfer(_from, _to, _value);
        }
    
         
        function freezeAccount(address target, bool freeze) onlyOwner public {
            frozenAccount[target] = freeze;
          emit  FrozenFunds(target, freeze);
        }
    
         
         
         
    
         
        uint256 public icoStartDate = 1540800000 ;   
        uint256 public icoEndDate   = 1548057600 ;   
        uint256 public exchangeRate = 1000;          
        uint256 public totalTokensForICO = 12000000; 
        uint256 public tokensSold = 0;               
        bool internal withdrawTokensOnlyOnce = true; 
        
         
		function () payable public {
    		require(icoEndDate > now);
    		require(icoStartDate < now);
    		uint ethervalueWEI=msg.value;
    		uint256 token = ethervalueWEI.mul(exchangeRate);     
    		uint256 totalTokens = token.add(purchaseBonus(token));  
    		tokensSold = tokensSold.add(totalTokens);
    		_transfer(this, msg.sender, totalTokens);            
    		forwardEherToOwner();                                
		}
        
        
         
		function forwardEherToOwner() internal {
			owner.transfer(msg.value); 
		}
		
		 
		function purchaseBonus(uint256 _tokenAmount) public view returns(uint256){
		    uint256 first24Hours = icoStartDate + 86400;     
		    uint256 week1 = first24Hours + 604800;     
		    uint256 week2 = week1 + 604800;            
		    uint256 week3 = week2 + 604800;            
		    uint256 week4 = week3 + 604800;            
		    uint256 week5 = week4 + 604800;            
		    uint256 week6 = week5 + 604800;            
		    uint256 week7 = week6 + 604800;            

		    if(now < (first24Hours)){ 
                return _tokenAmount.div(2);              
		    }
		    else if(now > first24Hours && now < week1){
		        return _tokenAmount.mul(40).div(100);    
		    }
		    else if(now > week1 && now < week2){
		        return _tokenAmount.mul(30).div(100);    
		    }
		    else if(now > week2 && now < week3){
		        return _tokenAmount.mul(25).div(100);    
		    }
		    else if(now > week3 && now < week4){
		        return _tokenAmount.mul(20).div(100);    
		    }
		    else if(now > week4 && now < week5){
		        return _tokenAmount.mul(15).div(100);    
		    }
		    else if(now > week5 && now < week6){
		        return _tokenAmount.mul(10).div(100);    
		    }
		    else if(now > week6 && now < week7){
		        return _tokenAmount.mul(5).div(100);    
		    }
		    else{
		        return 0;
		    }
		}
        
        
         
        function isICORunning() public view returns(bool){
            if(icoEndDate > now && icoStartDate < now){
                return true;                
            }else{
                return false;
            }
        }
        
        
         
        function withdrawTokens() onlyOwner public {
            require(icoEndDate < now);
            require(withdrawTokensOnlyOnce);
            uint256 tokens = (totalTokensForICO.mul(1 ether)).sub(tokensSold);
            _transfer(this, msg.sender, tokens);
            withdrawTokensOnlyOnce = false;
        }
        
        
         
         
         
        
        uint256 public dividendStartDate = 1549008000;   
        uint256 public dividendMonthCounter = 0;
        uint256 public monthlyAllocation = 6594333;
        
         
        mapping(address => bool) public tokenHolderExist;
        
         
        address[] public tokenHolders;
        
         
        uint256 public tokenHolderIndex = 0;
        
        
        event DividendPaid(uint256 totalDividendPaidThisRound, uint256 lastAddressIndex);

         
        function checkDividendPaymentAvailable() public view returns (uint256){
            require(now > (dividendStartDate.add(dividendMonthCounter.mul(2592000))));
            return tokenHolders.length;
        }
        
         
        function runDividendPayment() public { 
            if(now > (dividendStartDate.add(dividendMonthCounter.mul(2592000)))){
                uint256 totalDividendPaidThisRound = 0;
                 
                uint256 totalTokensHold = totalSupply.sub(balanceOf[this]);
                for(uint256 i = 0; i < 150; i++){
                    if(tokenHolderIndex < tokenHolders.length){
                        uint256 userTokens = balanceOf[tokenHolders[tokenHolderIndex]];
                        if(userTokens > 0){
                            uint256 dividendPercentage =  userTokens.div(totalTokensHold);
                            uint256 dividend = monthlyAllocation.mul(1 ether).mul(dividendPercentage);
                            _transfer(this, tokenHolders[tokenHolderIndex], dividend);
                            tokenHolderIndex++;
                            totalDividendPaidThisRound = totalDividendPaidThisRound.add(dividend);
                        }
                    }else{
                         
                        tokenHolderIndex = 0;
                        dividendMonthCounter++;
                        monthlyAllocation = monthlyAllocation.add(monthlyAllocation.mul(15).div(1000));  
                        break;
                    }
                }
                 
                emit DividendPaid(totalDividendPaidThisRound,  tokenHolderIndex);
            }
        }
    }