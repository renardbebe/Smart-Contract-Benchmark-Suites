 

pragma solidity ^0.4.20;


 
 
 
library SafeMath {
    function add(uint a, uint b) internal pure returns (uint c) {
        c = a + b;
        require(c >= a);
    }
    function sub(uint a, uint b) internal pure returns (uint c) {
        require(b <= a);
        c = a - b;
    }
    function mul(uint a, uint b) internal pure returns (uint c) {
        c = a * b;
        require(a == 0 || c / a == b);
    }
    function div(uint a, uint b) internal pure returns (uint c) {
        require(b > 0);
        c = a / b;
    }
}


contract Token {

     
    function totalSupply() public view returns (uint);

     
     
    function balanceOf(address tokenOwner) public view returns (uint balance);

     
     
     
     
     
    function transfer(address to, uint tokens) public returns (bool success);

     
     
     
     
     
     
    function transferFrom(address from, address to, uint tokens) public returns (bool success);

     
     
     
     
     
    function approve(address spender, uint tokens) public returns (bool success);

     
     
     
    function allowance(address tokenOwner, address spender) public view returns (uint remaining);
    
  
    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);

}

contract StandardToken is Token {
    
    using SafeMath for uint;

    mapping (address => uint256) balances;
    mapping (address => mapping (address => uint256)) allowed;
    uint256 public totalSupply;
    
    
     
     
     
     
    function transfer(address to, uint tokens) public returns (bool success) {
        require(to != address(0));
        require(tokens > 0);
        require(balances[msg.sender] >= tokens); 
        
        balances[msg.sender] = balances[msg.sender].sub(tokens);
        balances[to] = balances[to].add(tokens);
        emit Transfer(msg.sender, to, tokens);
        return true;
    }


     
     
     
     
     
     
     
     
    function approve(address spender, uint tokens) public returns (bool success) {
        require(spender != address(0));
        require(tokens > 0);
        
        allowed[msg.sender][spender] = tokens;
        emit Approval(msg.sender, spender, tokens);
        return true;
    }


     
     
     
     
     
     
     
     
    function transferFrom(address from, address to, uint tokens) public returns (bool success) {
        require(from != address(0));
        require(to != address(0));
        require(tokens > 0);
        require(balances[from] >= tokens);
        require(allowed[from][msg.sender] >= tokens);
        
        balances[from] = balances[from].sub(tokens);
        allowed[from][msg.sender] = allowed[from][msg.sender].sub(tokens);
        balances[to] = balances[to].add(tokens);
        emit Transfer(from, to, tokens);
        return true;
    }


     
     
     
    function balanceOf(address tokenOwner) public view returns (uint balance) {
        return balances[tokenOwner];
    }


     
     
     
    function totalSupply() public view returns (uint) {
        return totalSupply;
    }

     
     
     
     
    function allowance(address tokenOwner, address spender) public view returns (uint remaining) {
        return allowed[tokenOwner][spender];
    }

}

contract KillerWhale is StandardToken {  

     

     
    string public name;                    
    uint8 public decimals;                 
    string public symbol;                  
    string public version = 'H1.0'; 
    uint256 public unitsOneEthCanBuy;      
    uint256 public totalEthInWei;          
    address public fundsWallet;            

     
     
    function KillerWhale() {
        name = "KillerWhale";                                           
        decimals = 18;                                                
        symbol = "KWT";                                              
        unitsOneEthCanBuy = 100;                                       
        fundsWallet = 0x3f17dE50F2D1CA4209c2028677B328E34581d4Dc;                                     
        totalSupply = 888000000 * 10 ** uint256(decimals);                         
        balances[0x3f17dE50F2D1CA4209c2028677B328E34581d4Dc] = totalSupply;                
        
        emit Transfer(address(0),0x3f17dE50F2D1CA4209c2028677B328E34581d4Dc,totalSupply);
    }


    function() public payable{
        totalEthInWei = totalEthInWei + msg.value;
        uint256 amount = msg.value * unitsOneEthCanBuy;

         
        require(balances[fundsWallet] >= amount);

        balances[fundsWallet] = balances[fundsWallet].sub(amount);
        balances[msg.sender] = balances[msg.sender].add(amount);

        emit Transfer(fundsWallet, msg.sender, amount);  

         
        fundsWallet.transfer(msg.value);                               
    }


     
    function approveAndCall(address _spender, uint256 _value, bytes _extraData) public returns (bool success) {
        allowed[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);

         
         
         
        if(!_spender.call(bytes4(bytes32(keccak256("receiveApproval(address,uint256,address,bytes)"))), msg.sender, _value, this, _extraData)) { revert(); }
        return true;
    }
}