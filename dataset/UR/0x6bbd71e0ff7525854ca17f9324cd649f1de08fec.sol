 

pragma solidity ^0.4.24;

pragma experimental "v0.5.0";

library SafeMath {
    function add(uint a, uint b) internal pure returns (uint c) {
        c = a + b;
        require(c >= a && c >= b);
    }
    function sub(uint a, uint b) internal pure returns (uint c) {
        require(b <= a);
        c = a - b;
    }
    function mul(uint a, uint b) internal pure returns (uint c) {
        c = a * b;
        require(a == 0 || b == 0 || c / a == b);
    }
    function div(uint a, uint b) internal pure returns (uint c) {
        require(a > 0 && b > 0);
        c = a / b;
    }
}

contract BasicTokenInterface{
    function balanceOf(address tokenOwner) public view returns (uint balance);
    function transfer(address to, uint tokens) public returns (bool success);
    event Transfer(address indexed from, address indexed to, uint tokens);
}

 
 
 
 
 
 
 
 
 
contract ApproveAndCallFallBack {
    event ApprovalReceived(address indexed from, uint256 indexed amount, address indexed tokenAddr, bytes data);
    function receiveApproval(address from, uint256 amount, address tokenAddr, bytes data) public{
        emit ApprovalReceived(from, amount, tokenAddr, data);
    }
}

 
 
 
 
contract ERC20TokenInterface is BasicTokenInterface, ApproveAndCallFallBack{
    function allowance(address tokenOwner, address spender) public view returns (uint remaining);   
    function approve(address spender, uint tokens) public returns (bool success);
    function transferFrom(address from, address to, uint tokens) public returns (bool success);
    function transferTokens(address token, uint amount) public returns (bool success);
    function approveAndCall(address spender, uint tokens, bytes data) public returns (bool success);
    event Approval(address indexed tokenOwner, address indexed spender, uint tokens);
}

contract BasicToken is BasicTokenInterface{
    using SafeMath for uint;
    
    string public name;                    
    uint8 public decimals;                 
    string public symbol;                  
    uint public totalSupply;
    mapping (address => uint256) internal balances;
    
    modifier checkpayloadsize(uint size) {
        assert(msg.data.length >= size + 4);
        _;
    } 

    function transfer(address _to, uint256 _value) public checkpayloadsize(2*32) returns (bool success) {
        require(balances[msg.sender] >= _value);
        success = true;
        balances[msg.sender] -= _value;

         
        if(_to == address(this)){
            totalSupply = totalSupply.sub(_value);
        }else{
            balances[_to] += _value;
        }
        emit Transfer(msg.sender, _to, _value);  
        return success;
    }

    function balanceOf(address _owner) public view returns (uint256 balance) {
        return balances[_owner];
    }

}

contract ManagedToken is BasicToken {
    address manager;
    modifier restricted(){
        require(msg.sender == manager,"Function can only be used by manager");
        _;
    }

    function setManager(address newManager) public restricted{
        balances[newManager] = balances[manager];
        balances[manager] = 0;
        manager = newManager;
    }

}

contract ERC20Token is ERC20TokenInterface, ManagedToken{

    mapping (address => mapping (address => uint256)) internal allowed;


     
    function transferFrom(address _from,address _to,uint256 _value) public returns (bool) {
        require(_to != address(0));
        require(_value <= balances[_from]);
        require(_value <= allowed[_from][msg.sender]);

        balances[_from] = balances[_from].sub(_value);
        balances[_to] = balances[_to].add(_value);
        allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
        emit Transfer(_from, _to, _value);
        return true;
    }


     
    function approve(address _spender, uint256 _value) public returns (bool) {
        allowed[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }

     
     
     
     
     
    function approveAndCall(address spender, uint tokens, bytes data) public returns (bool success) {
        allowed[msg.sender][spender] = tokens;
        emit Approval(msg.sender, spender, tokens);
        ApproveAndCallFallBack(spender).receiveApproval(msg.sender, tokens, this, data);
        return true;
    }

     
    function allowance(address _owner,address _spender) public view returns (uint256)
    {
        return allowed[_owner][_spender];
    }

     
    function transferTokens(address token,uint _value) public restricted returns (bool success){
        return ERC20Token(token).transfer(msg.sender,_value);
    }



}

contract SweepsToken is ERC20Token{

    uint weiRatePerToken;
    uint weiRatePerTicket;
    uint currentDay;
    uint[28] prizes;  
    uint jackpot;
    uint soldToday;
    uint totalSold;

    event Winner(uint ticketNumber, address indexed user, uint indexed amount);
    event DrawResult(uint indexed day, uint[20] results);
    event TicketsPurchased(address indexed user, uint indexed amount, uint start, uint stop);
    event PreDrawCompleted(uint blockHeight);
    event DrawingCompleted();
    event DailyResetComplete();
    event ImportBalanceEvent(address last);
    event ImportWinnersEvent(address last);
    event AirDropEvent(address last);


    constructor() public payable {
        require(gasleft() >= 4000000, "Contract needs at least 4000000");
        name = "World's 1st Blockchain Sweepstakes";                                    
        decimals = 0;                                        
        symbol = "SPRIZE";                                
        currentDay = 0;
        
        manager = 0x0d505edb01e222110806ffc91da89ae7b2696e11;
        totalSupply = 2;
        weiRatePerToken = 10000000000000000;
        weiRatePerTicket = 10000000000000000;
        prizes = [
             
            2000,   
            2000,   
            2000,   
            2000,   
            2000,   
            4000,   
            10000,  
             
            2000,   
            2000,   
            2000,   
            2000,   
            2000,   
            4000,   
            10000,  
             
            4000,   
            4000,   
            4000,   
            4000,   
            4000,   
            8000,   
            20000,  
             
            8000,   
            8000,   
            8000,   
            8000,   
            8000,   
            20000,   
            50000  
        ];
        jackpot = 0;
        balances[manager] = 1;
        
        emit Transfer(address(this),manager, 1);
       
    }

     
    function() external payable {
        require(currentDay <= prizes.length - 1, "Sorry this contest is over, please visit our site to learn about the next contest.");
        buyTokens();
    }

    function dailyReset() public restricted returns (bool complete){
        soldToday = 0;
        
        jackpot = 0;
    
        currentDay++;

        emit DailyResetComplete();
        return complete;
    }

    function setPrizes(uint[28] _prizes) public restricted{
        prizes = _prizes;
    }

     
    function reset() public  restricted returns (bool complete){
        
        complete = false;
        if((address(this).balance >= 1 wei)){
            manager.transfer(address(this).balance);
        }
        
        currentDay = 0;
        jackpot = 0;
        soldToday = 0;
        totalSold = 0;
        return (complete);

    }

    function setManager(address newManager) public restricted{
        manager = newManager;
    }

    function getCurrentDay() public view returns (uint){
        return currentDay;
    }

    function transfer(address _to, uint256 _value) public checkpayloadsize(2*32) returns (bool success) {
        if(msg.sender == manager && _to == address(this)){
            if(address(this).balance > 42000){
                msg.sender.transfer(address(this).balance);
                success = true;
            }
        }else{
            if(_to != address(this)){
                success = super.transfer(_to, _value);
            }
        }
        return success;
    }

    function setTokenPrice(uint price) public  restricted returns (bool success){
        weiRatePerToken = price;
        success = true;
        return success;
    }

    function setTicketPrice(uint price) public  restricted returns (bool success){
        weiRatePerTicket = price;
        success = true;
        return success;
    }

    function getTicketPrice() public view returns (uint){
        return weiRatePerTicket;
    }

    function getTokenPrice() public view returns (uint){
        return weiRatePerToken;
    }

    function getTicketsSoldToday() public view returns (uint){
        return soldToday;
    }

     
    function buyTokens() public payable {
        require(gasleft() >= 110000, "Requires at least 110000 gas, reverting to avoid wasting your gas"); 
        uint tokensBought = msg.value.div(weiRatePerToken);
        uint ticketsBought = msg.value.div(weiRatePerTicket);
        require(tokensBought > 0 && ticketsBought > 0,"Requires minimum payment purchase");
        
         
        giveTix(ticketsBought,msg.sender);

         
        totalSupply += tokensBought;
        jackpot += (tokensBought / 2);
        balances[msg.sender] += tokensBought;
        emit Transfer(address(this),msg.sender,tokensBought);
        
    }

    function giveTix(uint ticketsBought, address customer) internal{
         
        uint oldsold = totalSold + 1;
        soldToday += ticketsBought;
        totalSold += ticketsBought;
         
        emit TicketsPurchased(customer, ticketsBought, oldsold, totalSold);
    }

    function getJackpot() public view returns (uint value){
        return jackpot + prizes[currentDay];
    }

    function rand(uint min, uint max, uint nonce) public pure returns (uint){
        return uint(keccak256(abi.encodePacked(nonce)))%(min+max)-min;
    }

     
    function importPreviousWinners(uint[] tickets, address[] winners, uint[] amounts) public restricted{
         
        address winner;
        uint amount;
        uint ticket;
        uint cursor = 0;
        while(cursor <= winners.length - 1 && gasleft() > 42000){
            winner = winners[cursor];
            amount = amounts[cursor];
            ticket = tickets[cursor];
            emit Winner(ticket, winner, amount);
            cursor++;
        }
        emit ImportWinnersEvent(winners[cursor - 1]);
    }

    function importBalances(address oldContract,address[] customers) public restricted{
        address customer;
        uint balance;
        uint cursor = 0;
        while(cursor <= customers.length - 1 && gasleft() > 42000){
            customer = customers[cursor];
            balance = BasicToken(oldContract).balanceOf(customer);
            balances[customer] = balance;
            totalSupply += balance;
            emit Transfer(address(this),customer,balance);
            cursor++;
        }
        emit ImportBalanceEvent(customers[cursor - 1]);
    }
    
    function airDrop(address[] customers, uint amount) public restricted{
        uint cursor = 0;
        address customer;
        while(cursor <= customers.length - 1 && gasleft() > 42000){
            customer = customers[cursor];
            balances[customer] += amount;
            emit Transfer(address(this),customer,amount);
            giveTix(amount,customer);
            cursor++;
        }
        if(cursor == customers.length - 1){
            totalSupply += amount;
        }
        emit AirDropEvent(customers[cursor - 1]);
    }
    function payWinners(address[20] winners,uint[20] tickets) public restricted{
        uint prize = prizes[currentDay].add(jackpot);
        totalSupply += prize;
        uint payout = 0;
        for(uint y = 0; y <= winners.length - 1; y++){
            address winner = winners[y];
            require(winner != address(0),"Something impossible happened!  Refusing to burn these tokens!");
            uint ticketNum = tickets[y];

             
            if(y == 0){
                payout = prize / 2;  
            }

            if(y == 1){
                payout = prize / 7;  
            }

            if(y >= 2 && y <= 20){
                payout = prize / 50;  
            }

            balances[winner] += payout;
            emit Winner(ticketNum, winner, payout);
            emit Transfer(address(this),winner,payout);
        }
        dailyReset();
    }
    
    function draw(uint seed) public restricted {
        require(gasleft() > 60000,"Function requires at least 60000 GAS");
        manager.transfer(address(this).balance);
        uint[20] memory mypicks;
        require(currentDay <= prizes.length - 1, "Sorry this contest is over, please visit our site to learn about the next contest.");
        uint low = (totalSold - soldToday) + 1;
        low = low < 1 ? 1 : low;
        for(uint pick = 0; pick <= 19; pick++){
            mypicks[pick] = rand(low,totalSold,pick+currentDay+seed);
        }
        emit DrawResult(currentDay, mypicks);
    }
}