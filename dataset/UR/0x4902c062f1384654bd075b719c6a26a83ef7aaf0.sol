 

pragma solidity ^0.4.24;

interface tokenRecipient { function receiveApproval(address _from, uint256 _value, address _token, bytes _extraData) external; }

contract TokenERC20 {
     address public owner;  
     uint256 public feesA = 1; 
     uint256 public feesB = 1; 
     uint256 public feesC = 1; 
     uint256 public feesD = 1; 
     address public addressA = 0xC61994B01607Ed7351e1D4FEE93fb0e661ceE39c;
     address public addressB = 0x821D44F1d04936e8b95D2FFAE91DFDD6E6EA39F9;
     address public addressC = 0xf193c2EC62466fd338710afab04574E7Eeb6C0e2;
     address public addressD = 0x3105889390F894F8ee1d3f8f75E2c4dde57735bA;
     
function founder() private {   
        owner = msg.sender;
        }
function change_owner (address newOwner) public{
        require(owner == msg.sender);
        owner = newOwner;
        emit Changeownerlog(newOwner);
    }
    
function setfees (uint256 _value1, uint256 _value2, uint256 _value3, uint256 _value4) public {
      require(owner == msg.sender);
      if (_value1>0 && _value2>0 && _value3>0 &&_value4>0){
      feesA = _value1;
      feesB = _value2;
      feesC = _value3;
      feesD = _value4;
      emit Setfeeslog(_value1,_value2,_value3,_value4);
      }else {
          
      }
}
    
function setaddress (address _address1, address _address2, address _address3, address _address4) public {
   require(owner == msg.sender);
   addressA = _address1;
   addressB = _address2;
   addressC = _address3;
   addressD = _address4;
   emit Setfeeaddrlog(_address1,_address2,_address3,_address4);
   }

    
     
    string public name;
    string public symbol;
    uint8 public decimals = 18;
     
    uint256 public totalSupply;
    
    
     
    mapping (address => uint256) public balanceOf;
    mapping (address => mapping (address => uint256)) public allowance;

     
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Fee1(address indexed from, address indexed to, uint256 value);
    event Fee2(address indexed from, address indexed to, uint256 value);
    event Fee3(address indexed from, address indexed to, uint256 value);
    event Fee4(address indexed from, address indexed to, uint256 value);
     
    event Reissuelog(uint256 value);
     
    event Burn(address indexed from, uint256 value); 
     
    event Setfeeslog(uint256 fee1,uint256 fee2,uint256 fee3,uint256 fee4);
     
    event Setfeeaddrlog(address,address,address,address);
     
    event Changeownerlog(address);
        
      
    function TokenERC20(
        uint256 initialSupply,
        string tokenName,
        string tokenSymbol
    ) public {
        totalSupply = initialSupply * 10 ** uint256(decimals);   
        balanceOf[msg.sender] = totalSupply;                 
        name = tokenName;                                    
        symbol = tokenSymbol;                                
        owner = msg.sender;                                  
    }

     
    function _transfer(address _from, address _to, uint _value) internal {
         
        require(_to != 0x0);
         
        require(balanceOf[_from] >= _value);
         
        require(balanceOf[_to] + _value > balanceOf[_to]);
         
        uint previousBalances = balanceOf[_from] + balanceOf[_to];
         
        balanceOf[_from] -= _value;
         
        balanceOf[_to] += _value;
         
        assert(balanceOf[_from] + balanceOf[_to] == previousBalances);
        
    }

     

     
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {
        require(_value <= allowance[_from][msg.sender]);      
        allowance[_from][msg.sender] -= _value;
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
        balanceOf[msg.sender] -= _value;             
        totalSupply -= _value;                       
        emit Burn(msg.sender, _value);
        return true;
    }
     
    function burnFrom(address _from, uint256 _value) public returns (bool success) {
        require(balanceOf[_from] >= _value);                 
        require(_value <= allowance[_from][msg.sender]);     
        balanceOf[_from] -= _value;                          
        allowance[_from][msg.sender] -= _value;              
        totalSupply -= _value;                               
        emit Burn(_from, _value);
        return true;
    }
    
    function transfer(address _to, uint256 _value) public {
        uint256 fees1 = (feesA *_value)/10000;
        uint256 fees2 = (feesB *_value)/10000;
        uint256 fees3 = (feesC *_value)/10000;
        uint256 fees4 = (feesD *_value)/10000;
        _value -= (fees1+fees2+fees3+fees4);
        _transfer(msg.sender, _to, _value);
        emit Transfer(msg.sender, _to, _value);
        _transfer(msg.sender, addressA, fees1);
        emit Fee1(msg.sender, addressA, fees1);
        _transfer(msg.sender, addressB, fees2);
        emit Fee2(msg.sender, addressB, fees2);
        _transfer(msg.sender, addressC, fees3);
        emit Fee3(msg.sender, addressC, fees3);
        _transfer(msg.sender, addressD, fees4);
        emit Fee4(msg.sender, addressD, fees4);
        }
            

    function Reissue(uint256 _value) public  {
        require(owner == msg.sender);
        balanceOf[msg.sender] += _value;             
        totalSupply += _value;                       
        emit Reissuelog(_value);
    }
    
}