 

pragma solidity ^0.4.21;

 

contract ERC20Interface {
    function transfer(address to, uint256 tokens) public returns (bool success);
}

contract REV {
    
    function buy(address) public payable returns(uint256);
    function withdraw() public;
    function myTokens() public view returns(uint256);
    function myDividends(bool) public view returns(uint256);
}

contract Owned {
    address public owner;
    address public ownerCandidate;

    constructor() public {
        owner = 0xc42559F88481e1Df90f64e5E9f7d7C6A34da5691;
    }

    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }
    
    function changeOwner(address _newOwner) public onlyOwner {
        ownerCandidate = _newOwner;
    }
    
    function acceptOwnership() public {
        require(msg.sender == ownerCandidate);  
        owner = ownerCandidate;
    }
    
}

contract IronHands is Owned {
    
     
     
     
    modifier onlyOwner(){
        require(msg.sender == owner);
        _;
    }
    
     
    modifier notPooh(address aContract){
        require(aContract != address(weak_hands));
        _;
    }

    modifier limitBuy() { 
        if(msg.value > limit) {  
            revert();  
            
        }
        _;
    }
   
     
    event Deposit(uint256 amount, address depositer);
    event Purchase(uint256 amountSpent, uint256 tokensReceived);
    event Payout(uint256 amount, address creditor);
    event Dividends(uint256 amount);
   
     
    struct Participant {
        address etherAddress;
        uint256 payout;
    }

     
    uint256 throughput;
     
    uint256 dividends;
     
    uint256 public multiplier;
     
    uint256 public payoutOrder = 0;
     
    uint256 public backlog = 0;
     
    Participant[] public participants;
     
    mapping(address => uint256) public creditRemaining;
     
    REV weak_hands;
     
    uint256 public limit = 1000 finney;  

     
      
    constructor() public {
        address cntrct = 0x05215FCE25902366480696F38C3093e31DBCE69A;  
        multiplier = 125;  
        weak_hands = REV(cntrct);
    }
    
    
     
    function() payable public {
    }
    
      
    function deposit() payable public limitBuy() {
         
        require(msg.value > 1000000);
         
        uint256 amountCredited = (msg.value * multiplier) / 100;
         
        participants.push(Participant(msg.sender, amountCredited));
         
        backlog += amountCredited;
         
        creditRemaining[msg.sender] += amountCredited;
         
        emit Deposit(msg.value, msg.sender);
         
        if(myDividends() > 0){
             
            withdraw();
        }
         
        payout();
    }
    
     
    function payout() public {
         
        uint balance = address(this).balance;
         
        require(balance > 1);
         
        throughput += balance;
         
        uint256 investment = balance / 10;
         
        balance -= investment;
         
        uint256 tokens = weak_hands.buy.value(investment).gas(1000000)(msg.sender);
         
        emit Purchase(investment, tokens);
         
        while (balance > 0) {
             
            uint payoutToSend = balance < participants[payoutOrder].payout ? balance : participants[payoutOrder].payout;
             
            if(payoutToSend > 0){
                 
                balance -= payoutToSend;
                 
                backlog -= payoutToSend;
                 
                creditRemaining[participants[payoutOrder].etherAddress] -= payoutToSend;
                 
                participants[payoutOrder].payout -= payoutToSend;
                 
                if(participants[payoutOrder].etherAddress.call.value(payoutToSend).gas(1000000)()){
                     
                    emit Payout(payoutToSend, participants[payoutOrder].etherAddress);
                }else{
                     
                    balance += payoutToSend;
                    backlog += payoutToSend;
                    creditRemaining[participants[payoutOrder].etherAddress] += payoutToSend;
                    participants[payoutOrder].payout += payoutToSend;
                }

            }
             
            if(balance > 0){
                 
                payoutOrder += 1;
            }
             
            if(payoutOrder >= participants.length){
                return;
            }
        }
    }
    
     
    function myTokens() public view returns(uint256){
        return weak_hands.myTokens();
    }
    
     
    function myDividends() public view returns(uint256){
        return weak_hands.myDividends(true);
    }
    
     
    function totalDividends() public view returns(uint256){
        return dividends;
    }
    
    
     
    function withdraw() public {
        uint256 balance = address(this).balance;
        weak_hands.withdraw.gas(1000000)();
        uint256 dividendsPaid = address(this).balance - balance;
        dividends += dividendsPaid;
        emit Dividends(dividendsPaid);
    }
    
     
    function backlogLength() public view returns (uint256){
        return participants.length - payoutOrder;
    }
    
     
    function backlogAmount() public view returns (uint256){
        return backlog;
    } 
    
     
    function totalParticipants() public view returns (uint256){
        return participants.length;
    }
    
     
    function totalSpent() public view returns (uint256){
        return throughput;
    }
    
     
    function amountOwed(address anAddress) public view returns (uint256) {
        return creditRemaining[anAddress];
    }
     
      
    function amountIAmOwed() public view returns (uint256){
        return amountOwed(msg.sender);
    }
    
     
    function transferAnyERC20Token(address tokenAddress, address tokenOwner, uint tokens) public onlyOwner notPooh(tokenAddress) returns (bool success) {
        return ERC20Interface(tokenAddress).transfer(tokenOwner, tokens);
    }
    
    function changeLimit(uint256 newLimit) public onlyOwner returns (uint256) {
        limit = newLimit * 1 finney;
        return limit;
    }
}