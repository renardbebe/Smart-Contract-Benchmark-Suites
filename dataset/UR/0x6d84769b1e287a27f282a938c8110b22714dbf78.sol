 

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
        require(paused == false);
        _;
    }
}
interface ABIO_Token {
    function owner() external returns (address);
    function transfer(address receiver, uint amount) external;
    function burnMyBalance() external;
}
interface ABIO_ICO{
    function deadline() external returns (uint);
    function weiRaised() external returns (uint);
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
    event ChangeMinInvestment(address operator, uint oldMin, uint newMin);

          
         function changeTreasury(address _newTreasury) external onlyOwner{
             treasury = _newTreasury;
             emit ChangeTreasury(msg.sender, _newTreasury);
         }

          
         function changeMinInvestment(uint _newMin) external onlyOwner{
             emit ChangeMinInvestment(msg.sender, minInvestment, _newMin);
             minInvestment = _newMin;
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

          
         function tokenFallback(address _from, uint _value, bytes _data) external{
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
contract ABIO_preICO is ABIO_BaseICO{
    address ICOAddress;
    ABIO_ICO ICO;
    uint finalDeadline;

    constructor(address _abioAddress, uint _lenInMins, uint _minWeiInvestment, address _treasury, uint _priceInWei, uint _goalInWei){
        treasury = _treasury;
        abioToken = ABIO_Token(_abioAddress);

        weiPerABIO = _priceInWei;
        fundingGoal = _goalInWei;
        minInvestment = _minWeiInvestment;

        startDate = now;
        length = _lenInMins * 1 minutes;
     }
      
    function supplyICOContract(address _addr) public onlyOwner{
        require(_addr != 0x0);
        ICOAddress = _addr;
        ICO = ABIO_ICO(_addr);
        if(!fundingGoalReached && weiRaised + ICO.weiRaised() >= fundingGoal){goalReached();}
        finalDeadline = ICO.deadline();
    }

    function goalReached() internal{
        fundingGoalReached = true;
        emit SoftcapReached(treasury, fundingGoal);
    }

     
    function extGoalReached() afterDeadline external{
        require(ICOAddress != 0x0);  
        require(msg.sender == ICOAddress);
        goalReached();
    }

     
    function safeWithdrawal() afterDeadline stopOnPause{
        if (!fundingGoalReached && now >= finalDeadline) {
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
        else if (fundingGoalReached && treasury == msg.sender) {
            if (treasury.send(weiRaised)) {
                emit FundsWithdrawn(treasury, weiRaised);
            } else if (treasury.send(address(this).balance)){
                emit FundsWithdrawn(treasury, address(this).balance);
            }
        }
    }

}