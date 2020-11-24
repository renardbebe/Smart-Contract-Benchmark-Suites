 

 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 



pragma solidity ^0.5.11;


 

contract PylonToken {

    function balanceOf(address _owner) external pure returns (uint256 balance);

    function burnFrom(address _from, uint256 _value) external returns (bool success);

    function mintToken(address _to, uint256 _value) external;

}



contract Pylon_ERC20 {


    string public name = "PYLNT";                
    string public symbol = "PYLNT";              
    uint256 public decimals = 18;                
    uint256 public totalSupply= 633858311346493889668246;   

    PylonToken PLNTToken;   

    mapping (address => mapping (address => uint256)) internal allowed;

    
     
    constructor(address addrPYLNT) public {
        
        PLNTToken = PylonToken(addrPYLNT);      
    }

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);

    
    function balanceOf(address _owner) public view returns (uint256) {
        
        return PLNTToken.balanceOf(address(_owner));
    }

    function transfer(address _to, uint256 _value) public returns (bool) {
        
        allowed[msg.sender][msg.sender] += _value;
        return transferFrom(msg.sender, _to, _value);
    }

     
     

    function transferFrom(address _from, address _to, uint256 _value) public returns (bool){
        
        require(_value <= allowed[_from][msg.sender]);
        PLNTToken.burnFrom(_from, _value);
        PLNTToken.mintToken(_to, _value);

        allowed[_from][msg.sender] -= _value;

        emit Transfer(_from, _to, _value);
        return true;
    }

    function approve(address _spender, uint256 _value) public returns (bool) {
        
        allowed[msg.sender][_spender] = _value;
        
        emit Approval(msg.sender, _spender, _value);
        return true;
    }

    function allowance(address _owner, address _spender) public view returns (uint256) {
        
        return allowed[_owner][_spender];
    }

    
    function approveAndCall(address _spender, uint256 _value, bytes calldata _extraData) external returns (bool success) {
        
        tokenRecipient spender = tokenRecipient(_spender);
        
        if (approve(_spender, _value)) {
            
            spender.receiveApproval(msg.sender, _value, address(this), _extraData);
            return true;
        }
    }

}


interface tokenRecipient {
    
    function receiveApproval(address _from, uint256 _value, address _token, bytes calldata _extraData) external;
}