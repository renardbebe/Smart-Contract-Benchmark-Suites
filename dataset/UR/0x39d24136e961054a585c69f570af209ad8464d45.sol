 

pragma solidity ^0.4.21;

 

contract ERC20Interface {
    function transfer(address to, uint256 tokens) public returns (bool success);
}

contract EPX {

    function fund() public payable returns(uint256){}
    function withdraw() public {}
    function dividends(address) public returns(uint256) {}
    function balanceOf() public view returns(uint256) {}
}

contract PHX {
    function mine() public {}
}

contract Owned {
    address public owner;
    address public ownerCandidate;

    function Owned() public {
        owner = msg.sender;
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
    
    
    address phxContract = 0x14b759A158879B133710f4059d32565b4a66140C;
    
     
     
     
    modifier onlyOwner(){
        require(msg.sender == owner);
        _;
    }
    
     
    modifier notEthPyramid(address aContract){
        require(aContract != address(ethpyramid));
        _;
    }
   
     
    event Deposit(uint256 amount, address depositer);
    event Purchase(uint256 amountSpent, uint256 tokensReceived);
    event Payout(uint256 amount, address creditor);
    event Dividends(uint256 amount);
    event Donation(uint256 amount, address donator);
    event ContinuityBreak(uint256 position, address skipped, uint256 amount);
    event ContinuityAppeal(uint256 oldPosition, uint256 newPosition, address appealer);

     
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
     
    EPX ethpyramid;
    PHX phx;

     
    function IronHands(uint multiplierPercent, address addr) public {
        multiplier = multiplierPercent;
        ethpyramid = EPX(addr);
        phx = PHX(phxContract);
    }
    
    
    function minePhx() public onlyOwner {
        phx.mine.gas(1000000)();
        
    }
    
     
    function() payable public {
    }
    
      
    function deposit() payable public {
         
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
         
        uint investment = balance / 2;
         
        balance -= investment;
         
        address(ethpyramid).call.value(investment).gas(1000000)();
         
         
         
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
        return ethpyramid.balanceOf();
    }
    
     
    function myDividends() public view returns(uint256){
        return ethpyramid.dividends(address(this));
    }
    
     
    function totalDividends() public view returns(uint256){
        return dividends;
    }
    
    
     
    function withdraw() public {
        uint256 balance = address(this).balance;
        ethpyramid.withdraw.gas(1000000)();
        uint256 dividendsPaid = address(this).balance - balance;
        dividends += dividendsPaid;
        emit Dividends(dividendsPaid);
    }
    
     
    function donate() payable public {
        emit Donation(msg.value, msg.sender);
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
    
     
    function transferAnyERC20Token(address tokenAddress, address tokenOwner, uint tokens) public onlyOwner notEthPyramid(tokenAddress) returns (bool success) {
        return ERC20Interface(tokenAddress).transfer(tokenOwner, tokens);
    }
    
}