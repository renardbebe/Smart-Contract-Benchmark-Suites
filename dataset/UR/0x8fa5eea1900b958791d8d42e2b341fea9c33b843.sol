 

pragma solidity ^0.4.11;


contract Better{
    event Bet(address indexed _from, uint team, uint _value);
    event Claim(address indexed _from, uint _value);
    event Transfer(address indexed _from, address indexed _to, uint _value);
    event LogManualWinnerUpdated(uint winner);

     
    uint public constant STATE_BET_ENABLED=0;
    uint public constant STATE_BET_DISABLED=1;
    uint public constant  STATE_CLAIM_ENABLED=2;
    
    uint private constant NO_TEAM=0;
    uint[33] private _pools;   
    
    uint public DEV_TAX_DIVISOR;     
    uint public  _startTime;     
    uint public  _endTime;   

    uint private _totalPrize;
    uint private _winnerTeam;
    uint private _numberBets;
    
    address public creatorAddr;
    
    
    mapping (address => mapping (uint => uint)) private _bets;
    
    function Better(uint passDevTaxDivisor, uint passStartTime, uint passEndTime) public {
        creatorAddr=msg.sender;
        DEV_TAX_DIVISOR=passDevTaxDivisor;
        _startTime=passStartTime;
        _endTime=passEndTime;
        
        _winnerTeam=NO_TEAM;

        _totalPrize=0;
        _numberBets=0;
        for(uint i =0; i<33; i++)_pools[i]=0;  
    }
    
    
    modifier onlyCreator {
        require(msg.sender == creatorAddr);
        _;
    }
    
    modifier onlyBeforeWinner {
        require(_winnerTeam == NO_TEAM);
        _;
    }
    
    modifier onlyAfterWinner {
        require(_winnerTeam != NO_TEAM);
        _;
    }
    
    modifier onlyAfterEndTime() {
        require(now >= _endTime);
        _;
    }
    
    modifier onlyBeforeStartTime() {
        require(now <= _startTime);
        _;
    }

    function setWinnerManually(uint winnerTeam) public onlyCreator onlyBeforeWinner returns (bool){
         _winnerTeam = winnerTeam;
         emit LogManualWinnerUpdated(winnerTeam);
    }
    
    function updateEndTimeManually(uint passEndTime) public onlyCreator onlyBeforeWinner returns (bool){
        _endTime=passEndTime;
    }
    
    function updateStartTimeManually(uint passStartTime) public onlyCreator onlyBeforeWinner returns (bool){
        _startTime=passStartTime;
    }
    
    function bet(uint team) public onlyBeforeWinner onlyBeforeStartTime payable returns (bool)  {
        require(msg.value>0);
        require(team >0);
        
        uint devTax= SafeMath.div(msg.value,DEV_TAX_DIVISOR);
        uint finalValue=SafeMath.sub(msg.value,devTax);
        
        assert(finalValue>0 && devTax>0);
        
        creatorAddr.transfer(devTax);
        
        _pools[team]=SafeMath.add(_pools[team],finalValue);
        _bets[msg.sender][team]=SafeMath.add(_bets[msg.sender][team],finalValue);
        _totalPrize=SafeMath.add(_totalPrize,finalValue);
        
        _numberBets++;
        emit Bet(msg.sender,team,msg.value);
        return true;
    }
    
    function claim() public onlyAfterWinner onlyAfterEndTime returns (bool){
        uint moneyInvested= _bets[msg.sender][_winnerTeam];
        require(moneyInvested>0);
        
        uint moneyTeam= _pools[_winnerTeam];
        

        uint aux= SafeMath.mul(_totalPrize,moneyInvested);
        uint wonAmmount= SafeMath.div(aux,moneyTeam);
        
        _bets[msg.sender][_winnerTeam]=0;
        msg.sender.transfer(wonAmmount);
        
        emit Claim(msg.sender,wonAmmount);
        return true;
    }

    function getMyBet(uint teamNumber) public constant returns (uint teamBet) {
       return (_bets[msg.sender][teamNumber]);
    }
    
    function getPools() public constant returns (uint[33] pools) {
        return _pools;
    }
    
    function getTotalPrize() public constant returns (uint prize){
        return _totalPrize;
    }
    
    function getNumberOfBets() public constant returns (uint numberBets){
        return _numberBets;
    }
    
    function getWinnerTeam() public constant returns (uint winnerTeam){
        return _winnerTeam;
    }
    

    function getState() public constant returns (uint state){
        if(now<_startTime)return STATE_BET_ENABLED;
        if(now<_endTime)return STATE_BET_DISABLED;
        else return STATE_CLAIM_ENABLED;
    }
    
    function getDev() public constant returns (string signature){
        return 'chelinho139';
    }
    function () public payable {
        throw;
    }
    

 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
}


library SafeMath {

     
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }
        uint256 c = a * b;
        assert(c / a == b);
        return c;
    }

     
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
         
        uint256 c = a / b;
         
        return c;
    }

     
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        assert(b <= a);
        return a - b;
    }

     
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        assert(c >= a);
        return c;
    }
}