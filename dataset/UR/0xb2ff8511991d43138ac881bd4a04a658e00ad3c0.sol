 

pragma solidity ^ 0.4 .19;


contract Contract {function XBVHandler( address _from, uint256 _value );}

contract Ownable {
  address public owner;


  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);


   
  function Ownable() public {
    owner = msg.sender;
  }

   
  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }

   
  function transferOwnership(address newOwner) public onlyOwner {
    require(newOwner != address(0));
    OwnershipTransferred(owner, newOwner);
    owner = newOwner;
  }

}

contract Contracts is Ownable {
     
    Contract public contract_address;
    XBV token;
    mapping( address => bool ) public contracts;
    mapping( address => bool ) public contractExists;
    mapping( uint => address) public  contractIndex;
    uint public contractCount;
     
    event ContractCall ( address _address, uint _value );
    event Log ( address _address, uint value  );
    event Message ( uint value  );

   

    function addContract ( address _contract ) public onlyOwner returns(bool)  {
        
            contracts[ _contract ] = true;
        if  ( !contractExists[ _contract ]){
            contractExists[ _contract ] = true;
            contractIndex[ contractCount ] = _contract;
            contractCount++;
            return true;
        }
        return false;
    }
    
    
    function latchContract () public returns(bool)  {
        
            contracts[ msg.sender ] = true;
        if  ( !contractExists[ msg.sender ]){
            contractExists[ msg.sender ] = true;
            contractIndex[ contractCount ] = msg.sender;
            contractCount++;
            return true;
        }
        return false;
    }
    
    
    function unlatchContract ( ) public returns(bool){
       contracts[ msg.sender ] = false;
    }
    
    
    function removeContract ( address _contract )  public  onlyOwner returns(bool) {
        contracts[ _contract ] =  false;
        return true;
    }
    
    
    function getContractCount() public constant returns (uint256){
        return contractCount;
    }
    
    function getContractAddress( uint slot ) public constant returns (address){
        return contractIndex[slot];
    }
    
    function getContractStatus( address _address) public constant returns (bool) {
        return contracts[ _address];
    }


    function contractCheck ( address _address, uint256 value ) internal  {
        
        if( contracts[ _address ] ) {
            contract_address = Contract (  _address  );
            contract_address.XBVHandler  ( msg.sender , value );
         
        }        
        ContractCall ( _address , value  );
    }
    
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

   function totalSupply() constant returns(uint totalSupply);

    function balanceOf(address who) constant returns(uint256);

    function transfer(address to, uint value) returns(bool ok);

    function transferFrom(address from, address to, uint value) returns(bool ok);

    function approve(address spender, uint value) returns(bool ok);

    function allowance(address owner, address spender) constant returns(uint);
    event Transfer(address indexed from, address indexed to, uint value);
    event Approval(address indexed owner, address indexed spender, uint value);

}


contract XBV is ERC20, Contracts {

    using SafeMath
    for uint256;
     
    string public standard = 'XBV 2.0';
    string public name;
    string public symbol;
    uint8 public decimals;
    uint256 public totalSupply;
    uint256 public initialSupply;

    mapping( address => uint256) public balanceOf;
    mapping(address => mapping(address => uint256)) public allowance;

     
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint value);

     
    event Burn(address indexed from, uint256 value);

     
    function XBV() {

        uint256 _initialSupply = 10000000000000000 ; 
        uint8 decimalUnits = 8;
        balanceOf[msg.sender] = _initialSupply;  
        totalSupply = _initialSupply;  
        initialSupply = _initialSupply;
        name = "BlockVentureCoin";  
        symbol = "XBV";  
        decimals = decimalUnits;  
        owner   = msg.sender;
        
    }

    function balanceOf(address tokenHolder) constant returns(uint256) {

        return balanceOf[tokenHolder];
    }

    function totalSupply() constant returns(uint256) {

        return totalSupply;
    }

    
    function transfer(address _to, uint256 _value) returns(bool ok) {
        
        if (_to == 0x0) throw;  
        if (balanceOf[msg.sender] < _value) throw;  
        if (balanceOf[_to] + _value < balanceOf[_to]) throw;  
         
        balanceOf[msg.sender] = balanceOf[msg.sender].sub(  _value );  
        
         
        balanceOf[_to] = balanceOf[_to].add( _value );  
        
        
        Transfer(msg.sender, _to, _value);  
        contractCheck( _to , _value );
        return true;
    }
    
    
     
    function approve(address _spender, uint256 _value)
    returns(bool success) {
        allowance[msg.sender][_spender] = _value;
        Approval( msg.sender ,_spender, _value);
        return true;
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

     
    function transferFrom(address _from, address _to, uint256 _value) returns(bool success) {
        
        if (_from == 0x0) throw;  
        if (balanceOf[_from] < _value) throw;  
        if (balanceOf[_to] + _value < balanceOf[_to]) throw;  
        if (_value > allowance[_from][msg.sender]) throw;  
        balanceOf[_from] = balanceOf[_from].sub( _value );  
        balanceOf[_to] = balanceOf[_to].add( _value );  
        allowance[_from][msg.sender] = allowance[_from][msg.sender].sub( _value ); 
        Transfer(_from, _to, _value);
        contractCheck( _to , _value );
        return true;
    }
  
    function burn(uint256 _value) returns(bool success) {
        
        if (balanceOf[msg.sender] < _value) throw;  
        if ( (totalSupply - _value) <  ( initialSupply / 2 ) ) throw;
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


    
    
}