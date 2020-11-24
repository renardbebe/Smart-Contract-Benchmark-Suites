 

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

contract Token {  function transfer(address _to, uint256 _value) public returns (bool success) {} }

interface tokenRecipient { function receiveApproval(address _from, uint256 _value, address _token, bytes calldata _extraData) external; }

contract UniondaoToken is SafeMath{
    string public name;    string public symbol;    uint8 public decimals;    uint256 public totalSupply;  address payable public owner;
    mapping (address => uint256) public balanceOf; 
    mapping (address => mapping (address => uint256)) public allowance;
    mapping (address => address) public gather;
    address public issueContract;     
    address public manager;
    uint256 public totalSupplyLimit;
    bool    public pauseMint;
    mapping (address => uint256) public addressToAccounts;
    mapping (uint256 => address) public accountsToAddress;
    uint256 public accountsNumber;
    uint256 private accountBin;
    event Transfer(address indexed from, address indexed to, uint256 value); 
    event Burn(address indexed from, uint256 value);   
    event TransferAndSendMsg(address indexed _from, address indexed _to, uint256 _value, string _msg);
    event Approval(address indexed owner, address indexed spender, uint256 value);  
    event SetPauseMint(bool pause);
    event SetManager(address add);
    event SetOwner(address add);
    event SetIssueContract(address add);
    event SetAccountBin(uint256 accountBin);
    
    constructor ( 
        uint256 initialSupply,string memory tokenName,string memory tokenSymbol) public{
        balanceOf[msg.sender] = initialSupply;               
        totalSupply = initialSupply;                         
        name = tokenName;                                    
        symbol = tokenSymbol;                                
        decimals = 18;                                       
        owner = msg.sender;
        manager = msg.sender;
        totalSupplyLimit = 100000000 * (10 ** uint256(decimals));
        accountBin = 888888;
    }
    
    function transfer(address _to, uint256 _value) public  returns (bool success){ 
        require (_to != address(0x0));                         
        require (_value >= 0) ;				
        require (balanceOf[msg.sender] >= _value) ;            
        require (safeAdd(balanceOf[_to] , _value) >= balanceOf[_to]) ;  
        balanceOf[msg.sender] = safeSub(balanceOf[msg.sender], _value);  
        balanceOf[_to] = safeAdd(balanceOf[_to], _value);                
        emit Transfer(msg.sender, _to, _value);                    
        if(gather[_to] != address(0x0) && gather[_to] != _to){			
          balanceOf[_to] = safeSub(balanceOf[_to], _value);  
          balanceOf[gather[_to]] = safeAdd(balanceOf[gather[_to]], _value);  
          emit Transfer( _to,gather[_to], _value);}                     
        return true;
    }
    
    function transferAndSendMsg(address _to, uint256 _value, string memory _msg) public returns (bool success){ 		
        emit TransferAndSendMsg(msg.sender, _to, _value,_msg);
        return transfer( _to,  _value);    
    }
    
    function approve(address _spender, uint256 _value) public returns (bool success) { 
        allowance[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;    
    }
    
    function transferFrom(address _from, address _to, uint256 _value)public returns (bool success) { 
        require (_to != address(0x0)) ;                                 
        require (_value >= 0) ;		
        require (balanceOf[_from] >= _value) ;                  
        require (safeAdd(balanceOf[_to] , _value) >= balanceOf[_to]) ;   
        require (_value <= allowance[_from][msg.sender]) ;      
        balanceOf[_from] = safeSub(balanceOf[_from], _value);                            
        balanceOf[_to] = safeAdd(balanceOf[_to], _value);                              
        allowance[_from][msg.sender] = safeSub(allowance[_from][msg.sender], _value);
        emit Transfer(_from, _to, _value);
        if(gather[_to] != address(0x0) && gather[_to] != _to)        {
          balanceOf[_to] = safeSub(balanceOf[_to], _value);                      
          balanceOf[gather[_to]] = safeAdd(balanceOf[gather[_to]], _value);                             
          emit Transfer( _to,gather[_to], _value);   }                   
          return true; 
      }
      
    function approveAndCall(address _spender, uint256 _value, bytes memory _extraData) public returns (bool success) {
        tokenRecipient spender = tokenRecipient(_spender);
        if (approve(_spender, _value)) {
            spender.receiveApproval(msg.sender, _value, address(this), _extraData);
            return true;}
    }

    function burn(uint256 _value) public returns (bool success) {
        require (balanceOf[msg.sender] >= _value ) ;             
        require (_value > 0) ; 
        balanceOf[msg.sender] = safeSub(balanceOf[msg.sender], _value);             
        totalSupply = safeSub(totalSupply,_value);                                 
        emit Burn(msg.sender, _value);				
        emit Transfer(msg.sender, address(0x0), _value);
        return true;
    } 

    function mintToken(address _target, uint256 _mintedAmount) public returns (bool success) {
        require(msg.sender == issueContract && !pauseMint && safeAdd(totalSupply,_mintedAmount) <= totalSupplyLimit);
        balanceOf[_target] = safeAdd(balanceOf[_target],_mintedAmount);
        totalSupply = safeAdd(totalSupply,_mintedAmount);
        emit Transfer(address(0x0), _target, _mintedAmount);
        return true;
    }  
    
    function setSymbol(string memory _symbol)public   {        
        require (msg.sender == owner) ; 
        symbol = _symbol;    
    } 

    function setName(string memory _name)public {        
        require (msg.sender == owner) ; 
        name = _name;    
    } 
    
    function setGather(address _add)public{         
        require (_add != address(0x0) && isContract(_add) == false) ;		
        gather[msg.sender] = _add;    } 
    
    function isContract(address _addr) private view returns (bool is_contract) { 
      uint length;
      assembly { length := extcodesize(_addr) }    
      return (length>0);
    }  

    function setPauseMint(bool _pause)public     {   
        require (msg.sender == manager) ; 
        pauseMint = _pause; 
        emit SetPauseMint(_pause);
    }		

    function setManager(address _add)public{
        require (msg.sender == owner && _add != address(0x0)) ;
        manager = _add ;    
        emit SetManager(_add);
    }    

    function setOwner(address payable _add)public{
        require (msg.sender == owner && _add != address(0x0)) ;
        owner = _add ;     
        emit SetOwner(_add);
    } 

    function setIssueContract(address _add)public{
        require (msg.sender == owner) ;
        issueContract = _add ;    
        emit SetIssueContract(_add);
    }

    function setAccountBin(uint256 _accountBin)public{
        require (msg.sender == owner && _accountBin >= 100000 && _accountBin < 1000000) ;
        accountBin = _accountBin ;	
        emit SetAccountBin(_accountBin);
    }
    
    function() external payable  {} 
    
    function withdrawToken(address token, uint amount) public{ 
      require(msg.sender == owner);
      if (token == address(0x0)) owner.transfer(amount); 
      else require (Token(token).transfer(owner, amount));
    }

    function createAccount(address _add)public returns(uint256){		
        require (_add != address(0x0));
        require (addressToAccounts[_add] == 0) ;				
        uint256 _account = getAccountByLuhn(accountBin,accountsNumber+1);	
        require (accountsToAddress[_account] == address(0x0)) ;	
        if (accountsNumber > 10000000) {require (burn(10000000000000000));}    
        addressToAccounts[_add] = _account ;	
        accountsToAddress[_account] = _add ;	
        accountsNumber = accountsNumber + 1 ;
        return accountsNumber;
    }    

    function getAccountByLuhn(uint256 _bin,uint256 _accountNumber) public pure returns(uint256){	
        uint256 _sum = 0;
        uint256 _tempAccount;
        uint256 _temp;
        _tempAccount = _bin * safePower(10,12) + _accountNumber;
        for (uint8 i = 0; i < 18; i++) {
            if (i % 2 == 1){
                _temp = 2 * ((_tempAccount / safePower(10,18-i-1)) % 10);
                _sum = _sum + (_temp >= 10 ? _temp - 9 : _temp);
            }
            else{
                _sum = _sum + ((_tempAccount / safePower(10,18-i-1)) % 10);
            }
        }
        _temp = (10 - _sum % 10) % 10;
        return _tempAccount * 10 + _temp;
    }

    function transferAndSendMsgByAccount(uint256 _to, uint256 _value, string memory _msg) public returns (bool success){ 
        require(accountsToAddress[_to] != address(0x0));
        emit TransferAndSendMsg(msg.sender, accountsToAddress[_to], _value,_msg);
        return transfer(accountsToAddress[_to],  _value);    
    }
}