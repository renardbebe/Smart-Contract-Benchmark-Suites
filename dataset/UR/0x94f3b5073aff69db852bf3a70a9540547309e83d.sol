 

pragma solidity ^0.4.4;

contract Token {

     
    function totalSupply() public constant returns (uint256 supply) {}

     
     
    function balanceOf(address _owner) public constant returns (uint256 balance) {}

     
     
     
     
    function transfer(address _to, uint256 _value) public returns (bool success) {}


     
     
     
     
    function approve(address _spender, uint256 _value) returns (bool success) {}

     
     
     
    function allowance(address _owner, address _spender) constant returns (uint256 remaining) {}

    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);

}

contract StandardToken is Token {

    function transfer(address _to, uint256 _value) returns (bool success) {
         
         
         
         
        if (balances[msg.sender] >= _value && _value > 0) {
            balances[msg.sender] -= _value;
            balances[_to] += _value;
            emit Transfer(msg.sender, _to, _value);
            return true;
        } else { return false; }
    }


    function balanceOf(address _owner) constant returns (uint256 balance) {
        return balances[_owner];
    }

    function approve(address _spender, uint256 _value) returns (bool success) {
        allowed[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }

    function allowance(address _owner, address _spender) constant returns (uint256 remaining) {
      return allowed[_owner][_spender];
    }

    mapping (address => uint256) balances;
    mapping (address => mapping (address => uint256)) allowed;
    uint256 public totalSupply;
}

contract USDCCoin is StandardToken {  

     

     
    string public name;                    
    uint8 public decimals;                 
    string public symbol;                  
    string public version = 'V1.0'; 
    uint256 public unitsOneEthCanBuy;      
    uint256 public totalEthInWei;          
    address public fundsWallet;            

     
     
    constructor() {
		totalSupply = 10000000000 * 100000000000000000;  
        balances[msg.sender] = totalSupply;                
                               
        name = "Test USDC Coin";                                    
        decimals = 18;                                                
        symbol = "TUSDC";                                              

        unitsOneEthCanBuy = 10000;                                       
        fundsWallet = msg.sender;                                     
    }

    function() payable{
        
        require( false );
        
    }

     
    function approveAndCall(address _spender, uint256 _value, bytes _extraData) returns (bool success) {
        allowed[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);

         
         
         
        if(!_spender.call(bytes4(bytes32(keccak256("receiveApproval(address,uint256,address,bytes)"))), msg.sender, _value, this, _extraData)) { revert(); }
        return true;
    }
	
	
	function _transfer(address _from, address _to, uint _value) internal {
         
        require(_to != 0x0);
         
        require(balances[_from] >= _value);
         
        require(balances[_to] + _value > balances[_to]);
         
        balances[_from] -= _value;
         
        balances[_to] += _value;
        emit Transfer(_from, _to, _value);
    }


    
     
    function transferTokens(address _to, uint256 _tokens) lockTokenTransferBeforeIco public {
		 
        _transfer(msg.sender, _to, _tokens);
    }
    
    
    modifier lockTokenTransferBeforeIco{
        if(msg.sender != fundsWallet){
           require(now > 1544184000);  
        }
        _;
    }
}