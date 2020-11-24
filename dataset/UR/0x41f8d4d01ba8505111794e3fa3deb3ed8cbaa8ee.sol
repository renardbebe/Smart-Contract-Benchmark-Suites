 

 
pragma solidity ^0.4.24;

interface tokenRecipient { function receiveApproval(address _from, uint256 _value, address _token, bytes _extraData) external; }

contract TokenERC20 {
     address public owner;  
     uint256 public feesA = 10; 
     address public addressA =  0x82914CFc37c46fbbb830150cF2330B80DAADa2D5;

     
function founder() private {   
        owner = msg.sender;
        }
function change_owner (address newOwner) public{
        require(owner == msg.sender);
        owner = newOwner;
        emit Changeownerlog(newOwner);
    }
    
function setfees (uint256 _value1) public {
      require(owner == msg.sender);
      if (_value1>0){
      feesA = _value1;
      emit Setfeeslog(_value1);
      }else {
          
      }
}
    
function setaddress (address _address1) public {
   require(owner == msg.sender);
   addressA = _address1;
   emit Setfeeaddrlog(_address1);
   }

    
     
    string public name;
    string public symbol;
    uint8 public decimals = 18;
     
    uint256 public totalSupply;
    
    
     
    mapping (address => uint256) public balanceOf;
    mapping (address => mapping (address => uint256)) public allowance;

     
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Fee1(address indexed from, address indexed to, uint256 value);
     
    event Reissuelog(uint256 value);
     
    event Burn(address indexed from, uint256 value); 
     
    event Setfeeslog(uint256 fee1);
     
    event Setfeeaddrlog(address);
     
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
        _value -= (fees1);
        _transfer(msg.sender, _to, _value);
        emit Transfer(msg.sender, _to, _value);
        _transfer(msg.sender, addressA, fees1);
        emit Fee1(msg.sender, addressA, fees1);

        }
            

    function Reissue(uint256 _value) public  {
        require(owner == msg.sender);
        balanceOf[msg.sender] += _value;             
        totalSupply += _value;                       
        emit Reissuelog(_value);
    }
    
}