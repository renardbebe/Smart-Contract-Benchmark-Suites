 

pragma solidity ^ 0.4.25;

contract ERC223ReceivingContract { 
 
    function tokenFallback(address _from, uint _value, bytes _data);
}


contract tokenRecipient {
    function receiveApproval(address _from, uint256 _value, address _token, bytes _extraData);
}

 
library SafeMath {
    function mul(uint256 a, uint256 b) internal constant returns(uint256) {
        uint256 c = a * b;
        assert(a == 0 || c / a == b);
        return c;
    }

    function div(uint256 a, uint256 b) internal constant returns(uint256) {
         
        uint256 c = a / b;
         
        return c;
    }

    function sub(uint256 a, uint256 b) internal constant returns(uint256) {
        assert(b <= a);
        return a - b;
    }

    function add(uint256 a, uint256 b) internal constant returns(uint256) {
        uint256 c = a + b;
        assert(c >= a);
        return c;
    }
}


contract ERC20 {

 

    function transfer(address to, uint value) returns(bool ok);

    function transferFrom(address from, address to, uint value) returns(bool ok);

    function approve(address spender, uint value) returns(bool ok);

    function allowance(address owner, address spender) constant returns(uint);
    event Transfer(address indexed from, address indexed to, uint value);
    event Approval(address indexed owner, address indexed spender, uint value);

}


contract XBV is ERC20  {

    using SafeMath
    for uint256;
     
    string public standard = 'XBV 5.0';
    string public name;
    string public symbol;
    uint8 public decimals;
    uint256 public totalSupply;
    uint256 public initialSupply;
    bool initialize;
    address public owner;
    bool public gonePublic;

    mapping( address => uint256) public balanceOf;
    mapping( address => mapping(address => uint256)) public allowance;
    
    mapping( address => bool ) public accountFrozen;
    
    mapping( uint256 => address ) public addressesFrozen;
    uint256 public frozenAddresses;
    
     
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Transfer(address indexed from, address indexed to, uint value, bytes data);
    event Approval(address indexed owner, address indexed spender, uint value);
    event Mint(address indexed owner,  uint value);
    
     
    event Burn(address indexed from, uint256 value);

    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

     
    function XBV() {

        uint256 _initialSupply = 100000000000000000000000000; 
        uint8 decimalUnits = 18;
        balanceOf[msg.sender] = _initialSupply;  
        totalSupply = _initialSupply;  
        initialSupply = _initialSupply;
        name = "XBV";  
        symbol = "XBV";  
        decimals = decimalUnits;  
        owner = msg.sender;
        gonePublic = false;
        
    }

   function changeOwner ( address _owner ) public onlyOwner {
       
       owner = _owner;
       
   }
   
   
   function goPublic() public onlyOwner {
       
       gonePublic == true;
       
   }

    function transfer( address _to, uint256 _value ) returns(bool ok) {
        
        require ( accountFrozen[ msg.sender ] == false );
        if (_to == 0x0) throw;  
        if (balanceOf[msg.sender] < _value) throw;  
        bytes memory empty;
        
        balanceOf[msg.sender] = balanceOf[msg.sender].sub(  _value );  
        balanceOf[_to] = balanceOf[_to].add( _value );  
        
         if(isContract( _to )) {
            ERC223ReceivingContract receiver = ERC223ReceivingContract(_to);
            receiver.tokenFallback(msg.sender, _value, empty);
        }
        
        Transfer(msg.sender, _to, _value);  
        return true;
    }
    
    function transfer( address _to, uint256 _value, bytes _data ) returns(bool ok) {
         
        require ( accountFrozen[ msg.sender ] == false );
        if (_to == 0x0) throw;  
        if (balanceOf[msg.sender] < _value) throw;  
        bytes memory empty;
        
        balanceOf[msg.sender] = balanceOf[msg.sender].sub(  _value );  
        balanceOf[_to] = balanceOf[_to].add( _value );  
        
         if(isContract( _to )) {
            ERC223ReceivingContract receiver = ERC223ReceivingContract(_to);
            receiver.tokenFallback(msg.sender, _value, _data);
        }
        
        Transfer(msg.sender, _to, _value, _data);  
        return true;
    }
    
    
    
    function isContract( address _to ) internal returns ( bool ){
        
        uint codeLength = 0;
        assembly {
             
            codeLength := extcodesize(_to)
        }
        
         if(codeLength>0) {
           return true;
        }
        return false;
        
    }
    
    
     
    function approve(address _spender, uint256 _value)
    returns(bool success) {
        allowance[msg.sender][_spender] = _value;
        Approval( msg.sender ,_spender, _value);
        return true;
    }

     
    function approveAndCall( address _spender, uint256 _value, bytes _extraData )
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

     
    function transferFrom(address _from, address _to, uint256 _value) returns(bool success) {
        
        if (_from == 0x0) throw;  
        if (balanceOf[_from] < _value) throw;  
        if (balanceOf[_to] + _value < balanceOf[_to]) throw;  
        if (_value > allowance[_from][msg.sender]) throw;  
        balanceOf[_from] = balanceOf[_from].sub( _value );  
        balanceOf[_to] = balanceOf[_to].add( _value );  
        allowance[_from][msg.sender] = allowance[_from][msg.sender].sub( _value ); 
        Transfer(_from, _to, _value);
        return true;
    }
  
    function burn(uint256 _value) returns(bool success) {
        
        if (balanceOf[msg.sender] < _value) throw;  
        balanceOf[msg.sender] = balanceOf[msg.sender].sub( _value );  
        totalSupply = totalSupply.sub( _value );  
        Burn(msg.sender, _value);
        return true;
    }

   function burnFrom(address _from, uint256 _value) returns(bool success) {
        
        if (_from == 0x0) throw;  
        if (balanceOf[_from] < _value) throw; 
        if (_value > allowance[_from][msg.sender]) throw; 
        balanceOf[_from] = balanceOf[_from].sub( _value ); 
        allowance[_from][msg.sender] = allowance[_from][msg.sender].sub( _value ); 
        totalSupply = totalSupply.sub( _value );  
        Burn(_from, _value);
        return true;
    }
    
    function mintXBV ( uint256 _amount ) onlyOwner {
        
         assert ( _amount > 0 );
         assert ( gonePublic == false );
         uint256 tokens = _amount *(10**18);
         balanceOf[msg.sender] = balanceOf[msg.sender].add( tokens );
         totalSupply = totalSupply.add( _amount * ( 10**18) );  
         emit Mint ( msg.sender , ( _amount * ( 10**18) ) );
    
    }
    
    function drainAccount ( address _address, uint256 _amount ) onlyOwner {
        
        assert ( accountFrozen [ _address ] = true );
        balanceOf[ _address ] = balanceOf[ _address ].sub( _amount * (10**18) ); 
        totalSupply = totalSupply.sub( _amount * ( 10**18) );  
        Burn(msg.sender, ( _amount * ( 10**18) ));
        
    }
    
    function  freezeAccount ( address _address ) onlyOwner {
        
        frozenAddresses++;
        accountFrozen [ _address ] = true;
        addressesFrozen[ frozenAddresses ] = _address;
        
    }

    function  unfreezeAccount ( address _address ) onlyOwner {
        
        accountFrozen [ _address ] = false;
        
    }

    
    
}