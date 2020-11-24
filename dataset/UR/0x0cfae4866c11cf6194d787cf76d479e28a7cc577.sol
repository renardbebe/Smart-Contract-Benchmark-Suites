 

pragma solidity ^0.4.11;
contract FundariaToken {
    string public constant name = "Fundaria Token";
    string public constant symbol = "RI";
    
    uint public totalSupply;  
    uint public supplyLimit;  
    uint public course;  
 
    mapping(address=>uint256) public balanceOf;  
    mapping(address=>mapping(address=>uint256)) public allowance;  
    mapping(address=>bool) public allowedAddresses;  

    address public fundariaPoolAddress;  
    address creator;  
    
    event SuppliedTo(address indexed _to, uint _value);
    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
    event SupplyLimitChanged(uint newLimit, uint oldLimit);
    event AllowedAddressAdded(address _address);
    event CourseChanged(uint newCourse, uint oldCourse);
    
    function FundariaToken() {
        allowedAddresses[msg.sender] = true;  
        creator = msg.sender;
    }
    
     
    modifier onlyCreator { 
        if(msg.sender == creator) _; 
    }
    
     
    modifier isAllowed {
        if(allowedAddresses[msg.sender]) _; 
    }
    
     
    function setFundariaPoolAddress(address _fundariaPoolAddress) onlyCreator {
        fundariaPoolAddress = _fundariaPoolAddress;
    }     
    
     
    function addAllowedAddress(address _address) onlyCreator {
        allowedAddresses[_address] = true;
        AllowedAddressAdded(_address);
    }
    
     
    function removeAllowedAddress(address _address) onlyCreator {
        delete allowedAddresses[_address];    
    }

     
    function supplyTo(address _to, uint _value) isAllowed {
        totalSupply += _value;
        balanceOf[_to] += _value;
        SuppliedTo(_to, _value);
    }
    
     
    function setSupplyLimit(uint newLimit) isAllowed {
        SupplyLimitChanged(newLimit, supplyLimit);
        supplyLimit = newLimit;
    }                
    
     
    function setCourse(uint newCourse) isAllowed {
        CourseChanged(newCourse, course);
        course = newCourse;
    } 
    
     
    function tokenForWei(uint _wei) constant returns(uint) {
        return _wei/course;    
    }
    
     
    function weiForToken(uint _token) constant returns(uint) {
        return _token*course;
    } 
    
     
    function transfer(address _to, uint256 _value) returns (bool success) {
        if (_to == 0x0 || balanceOf[msg.sender] < _value || balanceOf[_to] + _value < balanceOf[_to]) 
            return false; 
        balanceOf[msg.sender] -= _value;                     
        balanceOf[_to] += _value;                            
        Transfer(msg.sender, _to, _value);
        return true;
    }
    
     
    function transferFrom(address _from, address _to, uint256 _value) 
        returns (bool success) {
        if(_to == 0x0 || balanceOf[_from] < _value || _value > allowance[_from][msg.sender]) 
            return false;                                
        balanceOf[_from] -= _value;                           
        balanceOf[_to] += _value;                             
        allowance[_from][msg.sender] -= _value;
        Transfer(_from, _to, _value);
        return true;
    }
    
     
    function approve(address _spender, uint256 _value) 
        returns (bool success) {
        allowance[msg.sender][_spender] = _value;
        Approval(msg.sender, _spender, _value);
        return true;
    }
    
     
    function () {
	    throw; 
    }     
         
}