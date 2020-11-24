 

pragma solidity ^0.4.24;
contract Ownable{
    address public owner;
    event ownerTransfer(address indexed oldOwner, address indexed newOwner);
    event ownerGone(address indexed oldOwner);

    constructor(){
        owner = msg.sender;
    }
    modifier onlyOwner(){
        require(msg.sender == owner);
        _;
    }
    function changeOwner(address _newOwner) public onlyOwner{
        require(_newOwner != address(0x0));
        emit ownerTransfer(owner, _newOwner);
        owner = _newOwner;
    }
}
contract Haltable is Ownable{
    bool public paused;
    event ContractPaused(address by);
    event ContractUnpaused(address by);

     
    constructor(){
        paused = true;
    }
    function pause() public onlyOwner {
        paused = true;
        emit ContractPaused(owner);
    }
    function unpause() public onlyOwner {
        paused = false;
        emit ContractUnpaused(owner);
    }
    modifier stopOnPause(){
        if(msg.sender != owner){
            require(paused == false);
        }
        _;
    }
}
interface ABIO_Token {
    function owner() external returns (address);
    function transfer(address receiver, uint amount) external;
    function burnMyBalance() external;
}
interface ABIO_preICO{
    function weiRaised() external returns (uint);
    function fundingGoal() external returns (uint);
    function extGoalReached() external returns (uint);
}
contract ABIO_BaseICO is Haltable{
    mapping(address => uint256) ethBalances;

    uint public weiRaised; 
    uint public abioSold; 
    uint public volume;  

    uint public startDate;
    uint public length;
    uint public deadline;
    bool public restTokensBurned;

    uint public weiPerABIO;  
    uint public minInvestment;
    uint public fundingGoal;
    bool public fundingGoalReached;
    address public treasury;

    ABIO_Token public abioToken;

    event ICOStart(uint volume, uint weiPerABIO, uint minInvestment);
    event SoftcapReached(address recipient, uint totalAmountRaised);
    event FundsReceived(address backer, uint amount);
    event FundsWithdrawn(address receiver, uint amount);

    event ChangeTreasury(address operator, address newTreasury);
    event PriceAdjust(address operator, uint multipliedBy ,uint newMin, uint newPrice);

          
         function changeTreasury(address _newTreasury) external onlyOwner{
             treasury = _newTreasury;
             emit ChangeTreasury(msg.sender, _newTreasury);
         }

          
         function adjustPrice(uint _multiplier) external onlyOwner{
             require(_multiplier < 400 && _multiplier > 25);
             minInvestment = minInvestment * _multiplier / 100;
             weiPerABIO = weiPerABIO * _multiplier / 100;
             emit PriceAdjust(msg.sender, _multiplier, minInvestment, weiPerABIO);
         }

          
         function () payable stopOnPause{
             require(now < deadline);
             require(msg.value >= minInvestment);
             uint amount = msg.value;
             ethBalances[msg.sender] += amount;
             weiRaised += amount;
             if(!fundingGoalReached && weiRaised >= fundingGoal){goalReached();}

             uint ABIOAmount = amount / weiPerABIO ;
             abioToken.transfer(msg.sender, ABIOAmount);
             abioSold += ABIOAmount;
             emit FundsReceived(msg.sender, amount);
         }

          
         function tokenFallback(address _from, uint _value, bytes) external{
             require(msg.sender == address(abioToken));
             require(_from == abioToken.owner() || _from == owner);
             volume = _value;
             paused = false;
             deadline = now + length;
             emit ICOStart(_value, weiPerABIO, minInvestment);
         }

          
         function burnRestTokens() afterDeadline{
                 require(!restTokensBurned);
                 abioToken.burnMyBalance();
                 restTokensBurned = true;
         }

         function isRunning() view returns (bool){
             return (now < deadline);
         }

         function goalReached() internal;

         modifier afterDeadline() { if (now >= deadline) _; }
}


contract ABIO_ICO is ABIO_BaseICO{
    ABIO_preICO PICO;
    uint weiRaisedInPICO;
    uint abioSoldInPICO;

    event Prolonged(address oabiotor, uint newDeadline);
    bool didProlong;
    constructor(address _abioAddress, address _treasury, address _PICOAddr, uint _lenInMins,uint _minInvestment, uint _priceInWei){
         abioToken = ABIO_Token(_abioAddress);
         treasury = _treasury;

         PICO = ABIO_preICO(_PICOAddr);
         weiRaisedInPICO = PICO.weiRaised();
         fundingGoal = PICO.fundingGoal();
         if (weiRaisedInPICO >= fundingGoal){
             goalReached();
         }
         minInvestment = _minInvestment;

         startDate = now;
         length = _lenInMins * 1 minutes;
         weiPerABIO = _priceInWei;
         fundingGoal = PICO.fundingGoal();
    }

     
    function goalReached() internal {
        emit SoftcapReached(treasury, fundingGoal);
        fundingGoalReached = true;
        if (weiRaisedInPICO < fundingGoal){
            PICO.extGoalReached();
        }
    }

     
    function safeWithdrawal() afterDeadline stopOnPause{
        if (!fundingGoalReached) {
            uint amount = ethBalances[msg.sender];
            ethBalances[msg.sender] = 0;
            if (amount > 0) {
                if (msg.sender.send(amount)) {
                    emit FundsWithdrawn(msg.sender, amount);
                } else {
                    ethBalances[msg.sender] = amount;
                }
            }
        }
        else if (fundingGoalReached) {
            require(treasury == msg.sender);
            if (treasury.send(weiRaised)) {
                emit FundsWithdrawn(treasury, weiRaised);
            } else if (treasury.send(address(this).balance)){
                emit FundsWithdrawn(treasury, address(this).balance);
            }
        }
    }

     
    function prolong(uint _timeInMins) external onlyOwner{
        require(!didProlong);
        require(now <= deadline - 4 days);
        uint t = _timeInMins * 1 minutes;
        require(t <= 3 weeks);
        deadline += t;
        length += t;

        didProlong = true;
        emit Prolonged(msg.sender, deadline);
    }
}