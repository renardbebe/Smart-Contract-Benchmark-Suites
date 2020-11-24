 

pragma solidity ^0.5.5;							
 
contract SafeMath { 
  function safeMul(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a * b;
    assert(a == 0 || c / a == b);
    return c;  
    }
  function safeDiv(uint256 a, uint256 b) internal pure returns (uint256) {	
    return a/b;  
    }
  function safeSub(uint256 a, uint256 b) internal pure returns (uint256) {
    assert(b <= a);
    return a - b;  
    }
  function safeAdd(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    assert(c>=a && c>=b);
    return c;  
    }  
  function safePower(uint a, uint b) internal pure returns (uint256) {
      uint256 c = a**b;
      return c;  
    }
}
contract Token {
  function totalSupply() public view returns (uint256 supply) {}
  function balanceOf(address _owner) public view returns (uint256 balance) {}
  function transfer(address _to, uint256 _value) public returns (bool success) {}
  function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {}
  function approve(address _spender, uint256 _value) public returns (bool success) {}
  function allowance(address _owner, address _spender) public view returns (uint256 remaining) {}
  function burn(uint256 _value) public returns (bool success){}
  function mintToken(address _target, uint256 _mintedAmount) public returns (bool success) {}
  mapping (address => uint256) public newPrice;
  address public issueContract;
}

contract TokenUSDT {
  function transferFrom(address _from, address _to, uint256 _value) public  {}
  function transfer(address _to, uint256 _value) public  {}
}

interface tokenRecipient { function receiveApproval(address _from, uint256 _value, address _token, bytes calldata _extraData) external; }

contract UNDTISSUE is SafeMath{
    address payable public owner;
    address public tokenAddress;
    uint8   public decimals;
    uint256 public totalSupply;
    address public manager;     
    uint256 public tokenNumber;     
    uint256 public fee; 
    address public managerToken;    
    uint16  public upAmountRate; 
    bool    public pauseIssue;
    bool    public pauseRedeem;
    uint256 public blockPerDay;
    uint256 public issueDiv;
    mapping (address => uint8) public tokenDecimals;    
    mapping (address => bool) public isNPA;     
    mapping (uint => address) public tokenPool;   
    mapping (address => uint256) public tokenSupply;     
    mapping (address => uint256) public upAmount;  
    mapping (address => bool) public isTransferFrom;   
    mapping (address => mapping (address => uint)) public tokens; 
    mapping (uint256 => mapping (address => uint256)) public totalRedeemOne;
    mapping (uint256 => mapping (address => uint256)) public totalIssue;
    event Withdraw(address token, address user, uint amount, uint balance);
    event SetManagerToken(address add);
    event SetPauseIssue(bool pause);
    event SetPauseRedeem(bool pause);
    event SetNPA(address token,bool isNPA);
    event SetAssetsUpperLimit(address token,uint256 value);
    event SetManager(address add);
    event ChangeOwner(address add);
    event SetFee(uint256 value);

     
    constructor (uint8 decimalUnits,address monetaryTokenAddress,address managerTokenAddress) public{    
        owner = msg.sender;    
        decimals = decimalUnits;
        manager = msg.sender;
        fee = (10 ** 16);
        upAmountRate = 100;
        tokenAddress = monetaryTokenAddress;		
        managerToken = managerTokenAddress;			
        blockPerDay  = 6000;			
        issueDiv = 10;					
    }
	
	 
    function setManagerToken(address _add)public  {        
        require (msg.sender == owner) ; 
        managerToken = _add;						
        emit SetManagerToken(_add);
    } 
    
	 
    function setPauseIssue(bool _pause)public     {   
        require (msg.sender == manager) ; 
        pauseIssue = _pause; 
        emit SetPauseIssue(_pause);
    }						
	
	 
    function setPauseRedeem(bool _pause)public     {   
        require (msg.sender == manager) ; 
        pauseRedeem = _pause; 
        emit SetPauseRedeem(_pause);
    }						 

     
    function setAssets(address _token,uint256 _value,uint8 _tokenDecimals,bool _isTransferFrom)public returns (bool success) {
        require (msg.sender == owner) ; 
        require (_token != address(0x0)) ;
        require (_value > 0) ;        
        if (upAmount[_token] == 0) {			
            tokenPool[tokenNumber] = _token ;	
            isNPA[_token] = false ;				
            tokenSupply[_token] = 0 ;			
            upAmount[_token] = _value ;			
            tokenDecimals[_token] = _tokenDecimals;	
            tokenNumber = safeAdd(tokenNumber,1) ;		
            isTransferFrom[_token] = _isTransferFrom;		
        }
        else
        {
            upAmount[_token] = _value ;
            tokenDecimals[_token] = _tokenDecimals;
            isTransferFrom[_token] = _isTransferFrom;
        }
        return true; 
    }  
    
     
    function setNPA(address _token,bool _isNPA)public returns (bool success) {
        require (msg.sender == manager) ; 
        require (_token != address(0x0)) ;        
        isNPA[_token] = _isNPA ;   
        emit SetNPA(_token,_isNPA);     
        return true;
    }   

     
    function setAssetsUpperLimit(address _token,uint256 _value)public returns (bool success) {
        require (msg.sender == manager) ;	
        require (_token != address(0x0)) ;     
        require (_value > 0) ;   
        upAmount[_token] = _value ;  
        emit SetAssetsUpperLimit(_token,_value);       
        return true; 
    }    

      
    function setAssetsUpAmountRate(uint16 _value)public returns (bool success) {
        require (msg.sender == manager) ; 
        require (_value > 0) ;   
        upAmountRate = _value ;
        return true;
    }

     
    function setFee(uint256 _value)public returns (bool success) {
        require (msg.sender == manager) ;
        require (_value <= 10**18) ;		 
        fee = _value ;
        emit SetFee(_value);       
        return true;
    }
   
	 
    function setIssueDiv(uint256 _value)public returns (bool success) {
        require (msg.sender == manager) ;
        require (_value >= 1) ;
        issueDiv = _value ;
        return true;
    }

     
    function setManager(address _add)public returns (bool success) {
        require (msg.sender == owner) ;
        require (_add != address(0x0)) ;
        manager = _add ;
        emit SetManager(_add); 
        return true;
    }    

	 
    function changeOwner(address payable _add)public returns (bool success) {
        require (msg.sender == owner) ;
        require (_add != address(0x0)) ;
        owner = _add ;
        emit ChangeOwner(_add); 
        return true; 
    } 

     
     function getAssetsUpperLimit(address _add) public view returns (uint256 _amount) {
        _amount = safeDiv(safeMul(upAmount[_add] , upAmountRate) , 100);	
        return _amount;
    }    

     
    function() external payable  {}

     
    function withdrawEther(uint amount) public{
      require(msg.sender == owner);
      owner.transfer(amount); 
    }

     
    function withdrawToken(address token, uint amount) public{
        require (token != address(0x0));
        require (tokens[token][msg.sender] >= amount);
        tokens[token][msg.sender] = safeSub(tokens[token][msg.sender], amount);   
        if(isTransferFrom[token]){
                require (Token(token).transfer(msg.sender, amount));
        }else{  
                TokenUSDT(token).transfer(msg.sender, amount);                          
        }
        emit Withdraw(token, msg.sender, amount, tokens[token][msg.sender]);
    }
    
    function balanceOf(address token, address user) public view returns (uint) {
        return tokens[token][user];
    }

    
  function issue(address _token, uint256 _amount) public returns (bool success) {		
        require (_token != address(0x0) && !pauseIssue) ;  
        require (isNPA[_token] == false) ;			
        uint256 _mintedAmount = safeDiv(safeMul(_amount , safePower(10,decimals)) , safePower(10,tokenDecimals[_token])) ;	
        require (safeAdd(totalIssue[safeDiv(block.number , blockPerDay)][_token],_mintedAmount) <= safeDiv(safeDiv(safeMul(upAmount[_token] , upAmountRate) , 100),issueDiv)) ; 
        require (safeDiv(safeMul(upAmount[_token] , upAmountRate) , 100) >= safeAdd(tokenSupply[_token],_mintedAmount)) ; 
        require (_mintedAmount >= safePower(10,decimals));	
        if(isTransferFrom[_token]){																
             require (Token(_token).transferFrom(msg.sender, address(this), _amount));			
        }else{
            TokenUSDT(_token).transferFrom(msg.sender, address(this), _amount);					
        }
        require(Token(tokenAddress).mintToken(msg.sender,_mintedAmount));		
        tokenSupply[_token] = safeAdd(tokenSupply[_token],_mintedAmount);		
        totalSupply = safeAdd(totalSupply,_mintedAmount);						
        totalIssue[safeDiv(block.number , blockPerDay)][_token] = safeAdd(totalIssue[safeDiv(block.number , blockPerDay)][_token],_mintedAmount);  
        return true; 
    }

     
    function getTokenIssueAmount() public view returns (uint256[256] memory _amount) {
        for (uint i = 0; i < tokenNumber && i < 256; i++) {
            _amount[i] = tokenSupply[tokenPool[i]];
        }
        return  _amount;
    }

     
    function getTokenPoolAddress() public view returns (address[256] memory _token) {
        for (uint i = 0; i < tokenNumber && i < 256; i++) {
            _token[i] = tokenPool[i];
        }
        return  _token;
    }

     
    function getTokenUpAmount() public view returns (uint256[256] memory _amount) {
        for (uint i = 0; i < tokenNumber && i < 256; i++) {
            _amount[i] = upAmount[tokenPool[i]];
        }
        return  _amount;
    }

     
    function getTokenDecimals() public view returns (uint8[256] memory _decimals) {
        for (uint i = 0; i < tokenNumber && i < 256; i++) {
            _decimals[i] = tokenDecimals[tokenPool[i]];
        }
        return  _decimals;
    }
    
     
    function getTokenIsNPA() public view returns (bool[256] memory _isNPA) {
        for (uint i = 0; i < tokenNumber && i < 256; i++) {
            _isNPA[i] = isNPA[tokenPool[i]];
        }
        return  _isNPA;
    }
    
	 
    function getRedeemOneFee(address _token,uint256 _amount) public view returns (uint256 _Fee) {
        _Fee =  safeAdd( safeDiv( safeMul(safeAdd(totalRedeemOne[safeDiv(block.number , blockPerDay)][_token] , _amount), 100) , tokenSupply[_token]),1);
        if (safeSub(tokenSupply[_token],_amount) > safeDiv(safeDiv(safeMul(upAmount[_token] , upAmountRate) , 100),2)) { _Fee = 1; }
        _Fee = safeMul(fee,_Fee);
        uint256 _udaoPrice = Token(Token(managerToken).issueContract()).newPrice(tokenAddress);	
        return safeDiv(safeMul(_amount , _Fee) , _udaoPrice);	
    }
    
     	
    function redeem(uint256 _amount) public returns (bool success) {
    require (_amount >= safePower(10,decimals) && !pauseRedeem) ;  
    if(fee > 0){
        uint256 _udaoPrice = Token(Token(managerToken).issueContract()).newPrice(tokenAddress);
        if(_udaoPrice > 0){
            uint256 _amountFee =  safeDiv(safeMul(_amount , fee) , _udaoPrice);	
            require (Token(managerToken).transferFrom(msg.sender,address(this),_amountFee));	
            require (Token(managerToken).burn(_amountFee)); }
        }
        address _token;
        uint _value = 0;
        uint _npavalue = 0;
        for (uint k = 0; k < tokenNumber; k++) {		
            _token = tokenPool[k];
            if (isNPA[_token]) {                
                _npavalue = safeAdd(_npavalue , tokenSupply[_token]);		
            }
        }
        for (uint i = 0; i < tokenNumber; i++) {		
            _token = tokenPool[i];
            if (isNPA[_token]) {continue;}
            _value = safeDiv(safeMul(_amount  , tokenSupply[_token])  , safeSub(totalSupply , _npavalue)) ;	
            if(_value > 0){
                if(isTransferFrom[_token]){	
                      require (Token(_token).transfer(msg.sender, safeDiv(safeMul(_value , safePower(10,tokenDecimals[_token])) , safePower(10,decimals))));
                }else{  
                      TokenUSDT(_token).transfer(msg.sender, safeDiv(safeMul(_value , safePower(10,tokenDecimals[_token])) , safePower(10,decimals)));
                }               
                tokenSupply[_token] = safeSub(tokenSupply[_token],_value);  
            }    
        }
        require (Token(tokenAddress).transferFrom(msg.sender,address(this),_amount));	
        require(Token(tokenAddress).burn(_amount)); 
        totalSupply = safeSub(totalSupply,_amount);							
        return true;  
    }    

     		
    function redeemNPA(uint256 _amount,address _token,bool _isReceiveToken) public returns (bool success) {	
        uint _value = safeDiv(safeMul(_amount , safePower(10,tokenDecimals[_token])) , safePower(10,decimals)) ;	
        require (_amount > 0 && !pauseRedeem) ;  
        require (isNPA[_token] == true) ;
        require (_amount <= tokenSupply[_token]) ;  
        require (Token(tokenAddress).transferFrom(msg.sender,address(this),_amount));
        require(Token(tokenAddress).burn(_amount));    
        if(_isReceiveToken == true) {		
            if(isTransferFrom[_token]){
             require (Token(_token).transfer(msg.sender, _value));
            }else{  
                 TokenUSDT(_token).transfer(msg.sender, _value);                        
            }            
        }
        else{ tokens[_token][msg.sender] = safeAdd(tokens[_token][msg.sender], _value);}    
        tokenSupply[_token] = safeSub(tokenSupply[_token],_amount);							
        totalSupply = safeSub(totalSupply,_amount);											
        return true;  
    }

     		
    function redeemOne(uint256 _amount,address _token) public returns (bool success) {
    require (_amount >= safePower(10,decimals) && !pauseRedeem) ; 
    require (isNPA[_token] == false) ;								
    totalRedeemOne[safeDiv(block.number , blockPerDay)][_token] = safeAdd(totalRedeemOne[safeDiv(block.number , blockPerDay)][_token],_amount);		
    if(fee > 0){
        uint256 _udaoPrice = Token(Token(managerToken).issueContract()).newPrice(tokenAddress);		
        uint256 _redeemOneFee =safeAdd( safeDiv( safeMul(totalRedeemOne[safeDiv(block.number , blockPerDay)][_token] , 100) , tokenSupply[_token]),1);		
        if (safeSub(tokenSupply[_token],_amount) > safeDiv(safeDiv(safeMul(upAmount[_token] , upAmountRate) , 100),2)) { _redeemOneFee = 1; }	
        _redeemOneFee = safeMul(fee,_redeemOneFee);		
        if(_udaoPrice > 0){									
            uint256 _amountFee =  safeDiv(safeMul(_amount , _redeemOneFee) , _udaoPrice);		
            require (Token(managerToken).transferFrom(msg.sender,address(this),_amountFee));
            require (Token(managerToken).burn(_amountFee)); }
        }
        uint _value = safeDiv(safeMul(_amount , safePower(10,tokenDecimals[_token])) , safePower(10,decimals)) ;	
        if(isTransferFrom[_token]){
             require (Token(_token).transfer(msg.sender, _value));
        }else{  
             TokenUSDT(_token).transfer(msg.sender, _value);
        }
        tokenSupply[_token] = safeSub(tokenSupply[_token],_amount);     
        require (Token(tokenAddress).transferFrom(msg.sender,address(this),_amount));
        require(Token(tokenAddress).burn(_amount));
        totalSupply = safeSub(totalSupply,_amount);						
        return true;  
    }
}