 

pragma solidity ^ 0.4.8;

contract Project {function studioHandler( address _from, uint256 _value );}

 
 contract Projects {
     
    Project public project_contract;
 
    mapping( address => bool ) public projects;
    mapping( address => bool ) public projectExists;
    mapping( uint => address) public  projectIndex;
    uint projectCount;
    address public owner;
    address public management;
    
    mapping( address => bool ) public mediaTokens;
    mapping( address => uint256 ) public mediaTokensInitialSupply;
    mapping( address => uint8 ) public mediaTokensDecimalUnits;
    mapping( address => string ) public mediaTokensName;
    mapping( address => string ) public mediaTokensSymbol;
    mapping( uint => address) public  mediaTokenIndex;
    uint mediaTokenCount;


 

    event ProjectCall ( address _address, uint _value );


     modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }
     modifier onlyManagement {
        require (  management == msg.sender || owner == msg.sender  );
        _;
    }


    function addProject ( address _project ) public onlyManagement{
        
            projects[ _project ] = true;
        if  ( !projectExists[ _project ]){
            projectExists[ _project ] = true;
            projectIndex[ projectCount ] = _project;
            projectCount++;
        }
    }
    
    function removeProject ( address _project ) public onlyManagement{
        
        projects[ _project ] =false;
        
    }
    
    
    function getProjectCount() public constant returns (uint256){
        
        return projectCount;
        
    }
    
    function getProjectAddress( uint slot ) public constant returns (address){
        
        return projectIndex[slot];
        
    }
    
    function getProjectStatus( address _address) public constant returns (bool) {
        
        return projects[ _address];
    }


    function projectCheck ( address _address, uint256 value ) internal  {
        
       
        
        if( projects[ _address ] ) {
            project_contract = Project (  _address  );
            project_contract.studioHandler  ( msg.sender , value );
         
        }        
        ProjectCall ( _address , value  );
    }

}




contract tokenRecipient {
    function receiveApproval(address _from, uint256 _value, address _token, bytes _extraData);
}



contract ERC20 {

   function totalSupply() constant returns(uint totalSupply);

    function balanceOf(address who) constant returns(uint256);

    function transfer(address to, uint value) returns(bool ok);

    function transferFrom(address from, address to, uint value) returns(bool ok);

    function approve(address spender, uint value) returns(bool ok);

    function allowance(address owner, address spender) constant returns(uint);
    event Transfer(address indexed from, address indexed to, uint value);
    event Approval(address indexed owner, address indexed spender, uint value);

}

contract BaseToken is ERC20 {

    
    string public standard = 'Token 1.0';
    string public name;
    string public symbol;
    uint8 public decimals;
    uint256 public totalSupply;
    uint256 public initialSupply;


    address public owner;
    
    

     
    mapping( address => uint256) public balanceOf;
    mapping( uint => address) public accountIndex;
    mapping (address => bool) public frozenAccount;
    uint accountCount;
    
   
    mapping(address => mapping(address => uint256)) public allowance;

     
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint value);
    event FrozenFunds ( address target, bool frozen );

     
    

     
    function BaseToken( uint256 _initialSupply, uint8 _decimalUnits, string _name, string _symbol, address _owner ) {

        appendTokenHolders( _owner );
        balanceOf[ _owner ] = _initialSupply;  
        totalSupply = _initialSupply;  
        initialSupply = _initialSupply;
        name = _name;  
        symbol = _symbol;  
        decimals = _decimalUnits;  
        owner = msg.sender;
            

    }

     
    function balanceOf(address tokenHolder) constant returns(uint256) {

        return balanceOf[tokenHolder];
    }

    function totalSupply() constant returns(uint256) {

        return totalSupply;
    }

     
     

    function getAccountCount() constant returns(uint256) {

        return accountCount;
    }

     
    function getAddress(uint slot) constant returns(address) {

        return accountIndex[slot];

    }

     
    

    function appendTokenHolders(address tokenHolder) private {

        if (balanceOf[tokenHolder] == 0) {
            accountIndex[accountCount] = tokenHolder;
            accountCount++;
        }

    }

     
    function transfer(address _to, uint256 _value) returns(bool ok) {
        
        if (_to == 0x0) throw;  
        if (balanceOf[msg.sender] < _value) throw;  
        if (balanceOf[_to] + _value < balanceOf[_to]) throw;  
        
        appendTokenHolders(_to);
        balanceOf[msg.sender] -= _value;  
        balanceOf[_to] += _value;  
        Transfer(msg.sender, _to, _value);  
        return true;
        
    }

     
    function approve(address _spender, uint256 _value) returns(bool success) {
        
        allowance[msg.sender][_spender] = _value;
        Approval( msg.sender ,_spender, _value);
        return true;
        
    }

     
    function approveAndCall(address _spender, uint256 _value, bytes _extraData) returns(bool success) {
        
        tokenRecipient spender = tokenRecipient(_spender);
        if (approve(_spender, _value)) {
            spender.receiveApproval(msg.sender, _value, this, _extraData);
            return true;
        }
        
    }

    function allowance(address _owner, address _spender) constant returns(uint256 remaining) {
        
        return allowance[_owner][_spender];
    
        
    }

     
    function transferFrom(address _from, address _to, uint256 _value) returns(bool success) {
        
        if (_to == 0x0) throw;  
        if (balanceOf[_from] < _value) throw;  
        if (balanceOf[_to] + _value < balanceOf[_to]) throw;  
        if (_value > allowance[_from][msg.sender]) throw;  
         
        appendTokenHolders(_to);
        balanceOf[_from] -= _value;  
        balanceOf[_to] += _value;  
        allowance[_from][msg.sender] -= _value;
        Transfer(_from, _to, _value);
        return true;
    }
   
    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }

   
     
    
   
    
}


contract TheStudioToken is ERC20, Projects  {
    
    
    uint associateproducer;
    uint producer;
    uint executiveproducer;
    
    event newMediaTokenCreated ( string _name , address _address , string _symbol );
    
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint value);
    
   
     
    string public standard = 'Token 1.0';
    string public name;
    string public symbol;
    uint8 public decimals;
    uint256 public totalSupply;
    uint256 public initialSupply;
    

    
    BaseToken public mediaToken;
    
     
    
    
       
    
    

     
    mapping( address => uint256) public balanceOf;
    mapping( uint => address) public accountIndex;
    mapping( address =>bool ) public accountFreeze;
    uint accountCount;
    
   
    mapping(address => mapping(address => uint256)) public allowance;

     
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint value);
    event FrozenFunds ( address target, bool frozen );
    event FrozenMediaTokenFunds ( address mediatoken, address target, bool frozen );

     
    event Burn(address indexed from, uint256 value);
    
    
   
    
    function TheStudioToken() {

        associateproducer = 2500;  
        producer = 10000;           
        executiveproducer = 100000;
        uint256 _initialSupply = 5000000000000000;  
        appendTokenHolders(msg.sender);
        balanceOf[msg.sender] = _initialSupply;  
        totalSupply = _initialSupply;  
        initialSupply = _initialSupply;
        name = "STUDIO";  
        symbol = "STDO";  
        decimals = 8;  
        owner = msg.sender;

    }
        
    

    
      function appendTokenHolders(address tokenHolder) private {

        if (balanceOf[tokenHolder] == 0) {
            accountIndex[accountCount] = tokenHolder;
            accountCount++;
        }

    }
    
    
     function studioLevel ( address _address ) public constant returns(string){
        
        if ( balanceOf [ _address] == 0 ) return "NO LOVE";
        if ( balanceOf [ _address] < associateproducer * 100000000 ) return "FAN";
        if ( balanceOf [ _address] < producer * 100000000  ) return "ASSOCIATE PRODUCER";
        if ( balanceOf [ _address] < executiveproducer * 100000000  ) return "PRODUCER";
        return "EXECUTIVE PRODUCER";
        
    }
    
     function transferOwnership(address newOwner) public onlyOwner {

        owner = newOwner;
    }
    
    
    
     function assignManagement(address _management ) public onlyOwner {

        management = _management;
    }
    
    
     
    
    function newMediaToken ( uint256 _initialSupply, uint8 _decimalUnits, string _name, string _symbol ) public onlyManagement {
        
        BaseToken _mediaToken = new BaseToken(  _initialSupply,  _decimalUnits,  _name,  _symbol, owner  );
        mediaTokens[ _mediaToken ] = true;
        mediaTokenIndex[ mediaTokenCount ] = _mediaToken;
        mediaTokensInitialSupply[ _mediaToken ] = _initialSupply;
        mediaTokensDecimalUnits[ _mediaToken ] = _decimalUnits;
        mediaTokensName[ _mediaToken ] = _name;
        mediaTokensSymbol[ _mediaToken ] = _symbol;
        mediaTokenCount++;
        newMediaTokenCreated ( _name , _mediaToken , _symbol );
        
       
        
        
        
        
        
    }
    
    
    
    
     function transfer(address _to, uint256 _value) returns(bool ok) {
        
        if (_to == 0x0) throw;  
        if (balanceOf[msg.sender] < _value) throw;  
        if (balanceOf[_to] + _value < balanceOf[_to]) throw;  
        if ( accountFreeze[ msg.sender ]  ) throw;
        appendTokenHolders(_to);
        balanceOf[msg.sender] -= _value;  
        balanceOf[_to] += _value;  
        Transfer(msg.sender, _to, _value);  
        projectCheck( _to , _value );
        return true;
    }
    
    
    function transferFrom(address _from, address _to, uint256 _value) returns(bool success) {
    
        if (_to == 0x0) throw;  
        if (balanceOf[_from] < _value) throw;  
        if (balanceOf[_to] + _value < balanceOf[_to]) throw;  
        if (_value > allowance[_from][msg.sender]) throw;  
        if ( accountFreeze[ _from ]  ) throw;
        appendTokenHolders(_to);
        balanceOf[_from] -= _value;  
        balanceOf[_to] += _value;  
        allowance[_from][msg.sender] -= _value;
        Transfer(_from, _to, _value);
        projectCheck( _to , _value );
        return true;
    }
    
     function approve(address _spender, uint256 _value)  returns(bool success) {
        allowance[msg.sender][_spender] = _value;
        Approval( msg.sender ,_spender, _value);
        return true;
    }
    
      
    
     
    function balanceOf(address tokenHolder) constant returns(uint256) {

        return balanceOf[tokenHolder];
    }

    function totalSupply() constant returns(uint256) {

        return totalSupply;
    }

     
     

    function getAccountCount() constant returns(uint256) {

        return accountCount;
    }

     
    function getAddress(uint slot) constant returns(address) {

        return accountIndex[slot];

    }

 
   
     function burn(uint256 _value) returns(bool success) {
        if (balanceOf[msg.sender] < _value) throw;  
        if ( (totalSupply - _value) <  ( initialSupply / 2 ) ) throw;
        balanceOf[msg.sender] -= _value;  
        totalSupply -= _value;  
        Burn(msg.sender, _value);
        return true;
    }

    function burnFrom(address _from, uint256 _value) returns(bool success) {
        if (balanceOf[_from] < _value) throw;  
        if (_value > allowance[_from][msg.sender]) throw;  
       if ( (totalSupply - _value) <  ( initialSupply / 2 )) throw;
        balanceOf[_from] -= _value;  
        totalSupply -= _value;  
        Burn(_from, _value);
        return true;
    }

    modifier onlyOwner {
        require( msg.sender == owner );
        _;
    }

   
    
    function freezeAccount ( address _account ) public onlyOwner{
        
        accountFreeze [ _account ] = true;
        FrozenFunds ( _account , true );
        
        
    }
    
    function unfreezeAccount ( address _account ) public onlyOwner{
        
         accountFreeze [ _account ] = false;
         FrozenFunds ( _account , false );
        
        
    }
   

     
    function approveAndCall(address _spender, uint256 _value, bytes _extraData)
    returns(bool success) {
        tokenRecipient spender = tokenRecipient(_spender);
        if (approve(_spender, _value)) {
            spender.receiveApproval(msg.sender, _value, this, _extraData);
            return true;
        }
    }

    function allowance(address _owner, address _spender) constant returns(uint256 remaining) {
        return allowance[_owner][_spender];
    }
    
  
     
    
    
    
}