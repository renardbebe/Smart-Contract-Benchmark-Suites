 

pragma solidity 0.5.3;
 
 
 
 
 
 
 
 
 

 
   
     
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
    	using SafeMath for uint256;
    	
        constructor() public {
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
    
    interface tokenRecipient { function receiveApproval(address _from, uint256 _value, address _token, bytes calldata _extraData) external ; }
    
    contract TokenERC20 {
         
        using SafeMath for uint256;
    	string public name = "MICATOKEN";
        string public symbol = "MICA";
        uint8 public decimals = 18;          
        uint256 public totalSupply          = 65000000000 * (1 ether);   
        uint256 public tokensForCrowdsale   = 50000000000 * (1 ether);
        uint256 public tokensForTeam        = 5000000000  * (1 ether);
        uint256 public tokensForOwner       = 10000000000  * (1 ether);
        
		address public teamWallet = 0x7f1637fAcaCe03069D3cf1C29015a353B89243f8;
    
         
        mapping (address => uint256) public balanceOf;
        mapping (address => mapping (address => uint256)) public allowance;
    
         
        event Transfer(address indexed from, address indexed to, uint256 value);
    
         
        event Burn(address indexed from, uint256 value);
    
         
        constructor() public {
			 
            balanceOf[address(this)] = tokensForCrowdsale;           
            balanceOf[teamWallet] = tokensForTeam;          
            balanceOf[msg.sender] = tokensForOwner;         

             
            emit Transfer(address(0), address(this), tokensForCrowdsale);
            emit Transfer(address(0), teamWallet, tokensForTeam);
            emit Transfer(address(0), address(msg.sender), tokensForOwner);
        }
    
         
        function _transfer(address _from, address _to, uint _value) internal {
             
            require(_to != address(0x0));
             
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
    
         
        function approveAndCall(address _spender, uint256 _value, bytes memory _extraData)
            public
            returns (bool success) {
            tokenRecipient spender = tokenRecipient(_spender);
            if (approve(_spender, _value)) {
                spender.receiveApproval(msg.sender, _value, address(this), _extraData);
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
    
     
     
     
    
    contract MICATOKEN is owned, TokenERC20 {

    	using SafeMath for uint256;
    	uint256 public startTime = 0;  
    	uint256 public endTime = 9999999999999999999999;  
		uint256 public exchangeRate = 50000000;  
		uint256 public tokensSold = 0;  
		
        mapping (address => bool) public frozenAccount;
    
         
        event FrozenFunds(address target, bool frozen);
    
         
        constructor() TokenERC20() public {}

         
        function _transfer(address _from, address _to, uint _value) internal {
            require (_to != address(0x0));                       
            require(!frozenAccount[_from]);                      
            require(!frozenAccount[_to]);                        
             
            balanceOf[_from] = balanceOf[_from].sub(_value);     
            balanceOf[_to] = balanceOf[_to].add(_value);         
            emit Transfer(_from, _to, _value);
        }
        
         
        function () payable external {
            require(endTime > now && startTime < now, 'ICO is not running');
            uint256 ethervalueWEI=msg.value;
             
            uint256 token = ethervalueWEI.mul(exchangeRate);  
            tokensSold = tokensSold.add(token);
            _transfer(address(this), msg.sender, token);      
            forwardEherToOwner();
        }
        
         
        function forwardEherToOwner() internal {
            owner.transfer(msg.value); 
          }
        
         
         
		 
		function startIco(uint256 start_,uint256 end_, uint256 exchangeRateInWei, uint256 TokensAllocationForICO) onlyOwner public {
			require(start_ < end_);
			uint256 tokenAmount = TokensAllocationForICO.mul(1 ether);
			require(balanceOf[msg.sender] > tokenAmount);
			startTime=start_;
			endTime=end_;
			exchangeRate = exchangeRateInWei;
			transfer(address(this),tokenAmount);
        }    	
        
         
         
		function stopICO() onlyOwner public{
            endTime = 0;
            uint256 tokenAmount=balanceOf[address(this)];
            _transfer(address(this), msg.sender, tokenAmount);
        }
        
         
        function isICORunning() public view returns(bool){
            if(endTime > now && startTime < now){
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
            _transfer(address(this), msg.sender, tokenAmount);
          }
          
         
        function manualWithdrawEther()onlyOwner public{
			uint256 amount=address(this).balance;
			owner.transfer(amount);
		}
		
         
         
         
        function mintToken(address target, uint256 mintedAmount) onlyOwner public {
            balanceOf[target] = balanceOf[target].add(mintedAmount);
            totalSupply = totalSupply.add(mintedAmount);
           emit Transfer(address(0), address(this), mintedAmount);
           emit Transfer(address(this), target, mintedAmount);
        }
    
         
         
         
        function freezeAccount(address target, bool freeze) onlyOwner public {
            frozenAccount[target] = freeze;
          emit  FrozenFunds(target, freeze);
        }



    }