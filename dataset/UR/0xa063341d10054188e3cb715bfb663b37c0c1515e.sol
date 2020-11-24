 

pragma solidity ^0.5.1;

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

contract DiagonToken is ERC20Interface {
    
    string public name = "Diagon Coin";
    string public symbol = "DGN";
    uint public decimals = 6;
    
    uint public supply;
    address public founder;
    
    mapping(address => uint) public balances;
    
    mapping(address => mapping(address => uint)) allowed;
    
    event Transfer(address indexed from, address indexed to, uint tokens);
    event Approval(address indexed tokenOwner, address indexed spender, uint tokens);
    
    constructor () public {
        supply = 40000000000000;
        founder = msg.sender;
        balances[founder] = supply;
    }
    
    function allowance(address tokenOwner, address spender) view public returns(uint) {
        return allowed[tokenOwner][spender];
    }
    
    function approve(address spender, uint tokens) public returns(bool) {
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
    
    function balanceOf(address tokenOwner) public view returns (uint balance) {
        return balances[tokenOwner];
    }
    
    function transfer(address to, uint tokens) public returns (bool success) {
        require(balances[msg.sender] >= tokens && tokens > 0);
        
        balances[to] += tokens;
        balances[msg.sender] -= tokens;
        emit Transfer(msg.sender, to, tokens);
        return true;
    }
    
}

contract FiatContract {
    function ETH(uint _id) public view returns (uint256);
    function USD(uint _id) public view returns (uint256);
    function EUR(uint _id) public view returns (uint256);
    function GBP(uint _id) public view returns (uint256);
    function updatedAt(uint _id) public view returns (uint);
}

contract DiagonICO is DiagonToken {

    address public admin;
    address payable public deposit;
    FiatContract public fiatPrice;
    
     
    uint public tokenPrice;
    uint public psTokenPrice;
    
    uint public hardCap;
    
    uint public raisedAmount;
    
    uint public saleStart = 1568628000;
    
    uint public saleEnd = 1582588799;
    
    uint public coinTradeStart = saleEnd;  
    
    uint public maxInvestment;
    uint public minInvestment;
    
    
    enum State { beforeStart, running, afterEnd, halted }
    State public icoState;
    
    modifier onlyAdmin() {
        require(msg.sender == admin);
        _;
    }
    
    event Invest(address investor, uint value, uint tokens);
    
    constructor(address payable _deposit) public {
        deposit = _deposit;
        admin = msg.sender;
        fiatPrice = FiatContract(0x8055d0504666e2B6942BeB8D6014c964658Ca591);

        uint256 ethCent = fiatPrice.USD(0);

        tokenPrice = ethCent * 20;
        hardCap = ethCent * 450000000;
        maxInvestment = ethCent * 450000000;
        minInvestment = ethCent * 2000;

        icoState = State.beforeStart;
    }

    function tokenBalance() public view returns (uint) {
        return (balances[msg.sender]);
    }

    function erc20Address() public view returns (address) {
        address erc20Adr = msg.sender;
        return erc20Adr;
    }
    
     
    function halt() public onlyAdmin {
        icoState = State.halted;
    }
    
     
    function unhalt() public onlyAdmin{
        icoState = State.running;
    }
    
    function changeDepositAddress(address payable newDeposit) public onlyAdmin {
        deposit = newDeposit;
    }
    
    function getCurrentState() public view returns(State) {
        if(icoState == State.halted) {
            return State.halted;
        }else if(block.timestamp < saleStart){
            return State.beforeStart;
        } else if(block.timestamp >= saleStart && block.timestamp <= saleEnd){
            return State.running;
        } else {
            return State.afterEnd;
        }
    }
    
    function invest() payable public returns(bool){
         
        icoState = getCurrentState();
        
        require(icoState == State.running);
        
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
    
     
    function burn() public returns(bool){
        require(msg.sender == admin);
        icoState = getCurrentState();
        require(icoState == State.afterEnd);
        balances[founder] = 0;
    }
    
     
    function () payable external {
        invest();
    }
    
    function transfer(address to, uint value) public returns(bool){
        if (block.timestamp < coinTradeStart) {
            require(msg.sender == admin);
            super.transfer(to, value);
        } else {
            require(block.timestamp > coinTradeStart);
            super.transfer(to, value);
        }
    }
    
    function transferFrom(address _from, address _to, uint _value) public returns(bool){
        require(block.timestamp > coinTradeStart);
        super.transferFrom(_from, _to, _value);
    }
}