 

pragma solidity ^0.5.11;
 
 
 
 

contract ERC20Interface {
    function totalSupply() public view returns (uint);
    function balanceOf(address tokenOwner) public view returns (uint balance);
    function transfer(address to, uint tokens) public returns (bool success);

    
    function allowance(address tokenOwner, address spender) public view returns (uint remaining);
    function approve(address spender, uint tokens) public returns (bool success);
    function transferFrom(address from, address to, uint tokens) public returns (bool success);
    
    event Transfer(address indexed from, address indexed to, uint tokens);
    event Approval(address indexed tokenOwner, address indexed spender, uint tokens);
}

contract AcunarToken is ERC20Interface{
    string public name = "Acunar";
    string public symbol = "ACN";
    uint public decimals = 0;
    
    uint public supply;
    address public founder;
    
    mapping(address => uint) public balances;
    
    mapping(address => mapping(address => uint)) allowed;
    
     
    
    
    event Transfer(address indexed from, address indexed to, uint tokens);
    event Approval(address indexed tokenOwner, address indexed spender, uint tokens);


    constructor() public{
        supply = 200000000;
        founder = msg.sender;
        balances[founder] = supply;
    }
    
    
    function allowance(address tokenOwner, address spender) view public returns(uint){
        return allowed[tokenOwner][spender];
    }
    
    
     
    function approve(address spender, uint tokens) public returns(bool){
        require(balances[msg.sender] >= tokens);
        require(tokens > 0);
        
        allowed[msg.sender][spender] = tokens;
        emit Approval(msg.sender, spender, tokens);
        return true;
    }
    
     
    function transferFrom(address from, address to, uint tokens) public returns(bool){
        require(allowed[from][to] >= tokens);
        require(balances[from] >= tokens);
        
        balances[from] -= tokens;
        balances[to] += tokens;
        
        
        allowed[from][to] -= tokens;
        
        return true;
    }
    
    function totalSupply() public view returns (uint){
        return supply;
    }
    
    function balanceOf(address tokenOwner) public view returns (uint balance){
         return balances[tokenOwner];
     }
     
     
    function transfer(address to, uint tokens) public returns (bool success){
         require(balances[msg.sender] >= tokens && tokens > 0);
         
         balances[to] += tokens;
         balances[msg.sender] -= tokens;
         emit Transfer(msg.sender, to, tokens);
         return true;
     }
}


contract AcunarIEO is AcunarToken{
    address public admin;
    
    
     
     
    address payable public deposit;
    
     
    uint tokenPrice = 0.0001 ether;
    
     
    uint public hardCap =21000 ether;
    
    uint public raisedAmount;
    
    uint public saleStart = now;
    uint public saleEnd = now + 14515200;  
    uint public coinTradeStart = saleEnd + 15120000;  
    
    uint public maxInvestment = 30 ether;
    uint public minInvestment = 0.1 ether;
    
    enum State { beforeStart, running, afterEnd, halted}
    State public ieoState;
    
    
    modifier onlyAdmin(){
        require(msg.sender == admin);
        _;
    }
    
    event Invest(address investor, uint value, uint tokens);
    
    
     
    constructor(address payable _deposit) public{
        deposit = _deposit;
        admin = msg.sender;
        ieoState = State.beforeStart;
    }
    
     
    function halt() public onlyAdmin{
        ieoState = State.halted;
    }
    
     
    function unhalt() public onlyAdmin{
        ieoState = State.running;
    }
    
    
     
     
    function changeDepositAddress(address payable newDeposit) public onlyAdmin{
        deposit = newDeposit;
    }
    
    
     
    function getCurrentState() public view returns(State){
        if(ieoState == State.halted){
            return State.halted;
        }else if(block.timestamp < saleStart){
            return State.beforeStart;
        }else if(block.timestamp >= saleStart && block.timestamp <= saleEnd){
            return State.running;
        }else{
            return State.afterEnd;
        }
    }
    
    
    function invest() payable public returns(bool){
         
        ieoState = getCurrentState();
        require(ieoState == State.running);
        
        require(msg.value >= minInvestment && msg.value <= maxInvestment);
        
        uint tokens = msg.value / tokenPrice;
        
         
        require(raisedAmount + msg.value <= hardCap);
        
        raisedAmount += msg.value;
        
         
        balances[msg.sender] += tokens;
        balances[founder] -= tokens;
        
        deposit.transfer(msg.value); 
        
         
        emit Invest(msg.sender, msg.value, tokens);
        
        return true;
        

    }
    
     
    function () payable external{
        invest();
    }
    
    
    
    function burn() public returns(bool){
        ieoState = getCurrentState();
        require(ieoState == State.afterEnd);
        balances[founder] = 0;
        
    }
    
    
    function transfer(address to, uint value) public returns(bool){
        require(block.timestamp > coinTradeStart);
        super.transfer(to, value);
    }
    
    function transferFrom(address _from, address _to, uint _value) public returns(bool){
        require(block.timestamp > coinTradeStart);
        super.transferFrom(_from, _to, _value);
    }
    
}