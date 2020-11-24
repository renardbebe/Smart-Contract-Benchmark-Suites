 

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
    
    interface tokenRecipient { function receiveApproval(address _from, uint256 _value, address _token, bytes _extraData) external; }
    
    contract TokenERC20 {
         
        using SafeMath for uint256;
    	string public name;
        string public symbol;
        uint8 public decimals = 8;       
        uint256 public totalSupply;
        uint256 public reservedForICO;
    
         
        mapping (address => uint256) public balanceOf;
        mapping (address => mapping (address => uint256)) public allowance;
    
         
        event Transfer(address indexed from, address indexed to, uint256 value);
    
         
        event Burn(address indexed from, uint256 value);
    
         
        constructor (
            uint256 initialSupply,
            uint256 allocatedForICO,
            string tokenName,
            string tokenSymbol
        ) public {
            totalSupply = initialSupply.mul(1e8);                
            reservedForICO = allocatedForICO.mul(1e8);           
            balanceOf[this] = reservedForICO;                    
            balanceOf[msg.sender]=totalSupply.sub(reservedForICO);  
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
    
     
     
     
    
    contract FTKA is owned, TokenERC20 {
        
         
         
         
        
         
    	string internal tokenName = "FTKA";
        string internal tokenSymbol = "FTKA";
        uint256 internal initialSupply = 1000000000; 	  
        uint256 private allocatedForICO = 800000000;      
	
    	 
        mapping (address => bool) public frozenAccount;
    
         
        event FrozenFunds(address target, bool frozen);
    
         
        constructor () TokenERC20(initialSupply, allocatedForICO, tokenName, tokenSymbol) public { }
    
         
         
        function _transfer(address _from, address _to, uint _value) internal {
            require (_to != 0x0);                                
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
    
         
         
         
    
         
        uint256 public icoStartDate = 1542326400 ;       
        uint256 public icoEndDate   = 1554076799 ;       
        uint256 public exchangeRate = 5000;              
        uint256 public tokensSold = 0;                   
        bool internal withdrawTokensOnlyOnce = true;     
        
         
        mapping(address => uint256) public investorContribution;  
        address[] public icoContributors;                    
        uint256 public tokenHolderIndex = 0;                 
        uint256 public totalContributors = 0;                
        
        
         
		function () payable public {
		    if(msg.sender == owner && msg.value > 0){
    		    processRewards();    
		    }
		    else{
		        processICO();        
		    }
		}
        
         
         function processICO() internal {
            require(icoEndDate > now);
    		require(icoStartDate < now);
    		uint ethervalueWEI=msg.value;
    		uint256 token = ethervalueWEI.div(1e10).mul(exchangeRate); 
    		uint256 totalTokens = token.add(purchaseBonus(token));     
    		tokensSold = tokensSold.add(totalTokens);
    		_transfer(this, msg.sender, totalTokens);                  
    		forwardEherToOwner();                                      
    		 
            if(investorContribution[msg.sender] == 0){
                icoContributors.push(msg.sender);
                totalContributors++;
            }
            investorContribution[msg.sender] = investorContribution[msg.sender].add(totalTokens);
            
         }
         
          
         function processRewards() internal {
             for(uint256 i = 0; i < 150; i++){
                    if(tokenHolderIndex < totalContributors){
                        uint256 userContribution = investorContribution[icoContributors[tokenHolderIndex]];
                        if(userContribution > 0){
                            uint256 rewardPercentage =  userContribution.mul(1000).div(tokensSold);
                            uint256 reward = msg.value.mul(rewardPercentage).div(1000);
                            icoContributors[tokenHolderIndex].transfer(reward);
                            tokenHolderIndex++;
                        }
                    }else{
                         
                        tokenHolderIndex = 0;
                       break;
                    }
                }
         }
        
         
		function forwardEherToOwner() internal {
			owner.transfer(msg.value); 
		}
		
		 
		function purchaseBonus(uint256 _tokenAmount) public view returns(uint256){
		    uint256 week1 = icoStartDate + 604800;     
		    uint256 week2 = week1 + 604800;            
		    uint256 week3 = week2 + 604800;            
		    uint256 week4 = week3 + 604800;            
		    uint256 week5 = week4 + 604800;            

		    if(now > icoStartDate && now < week1){
		        return _tokenAmount.mul(25).div(100);    
		    }
		    else if(now > week1 && now < week2){
		        return _tokenAmount.mul(20).div(100);    
		    }
		    else if(now > week2 && now < week3){
		        return _tokenAmount.mul(15).div(100);    
		    }
		    else if(now > week3 && now < week4){
		        return _tokenAmount.mul(10).div(100);    
		    }
		    else if(now > week4 && now < week5){
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
        
        
         
        function manualWithdrawToken(uint256 _amount) onlyOwner public {
            uint256 tokenAmount = _amount.mul(1 ether);
            _transfer(this, msg.sender, tokenAmount);
        }
          
         
        function manualWithdrawEther()onlyOwner public{
            address(owner).transfer(address(this).balance);
        }
        
    }