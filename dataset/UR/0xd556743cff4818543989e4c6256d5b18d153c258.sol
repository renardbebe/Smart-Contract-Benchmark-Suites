 

pragma solidity ^0.4.23;

 

contract ZTHReceivingContract {
    function tokenFallback(address _from, uint _value, bytes _data) public returns (bool);
}

contract ZTHInterface {
    function transfer(address _to, uint _value) public returns (bool);
    function approve(address spender, uint tokens) public returns (bool);
}

contract Zethell is ZTHReceivingContract {
    using SafeMath for uint;

    address private owner;
    address private bankroll;

     
    uint    private houseTake;
    
     
    uint    public tokensInPlay;
    
     
    uint    public contractBalance;
    
     
    address public currentWinner;

     
    uint    public gameStarted;
    
     
    uint    public gameEnds;
    
     
    bool    public gameActive;

    address private ZTHTKNADDR;
    address private ZTHBANKROLL;
    ZTHInterface private     ZTHTKN;

    mapping (uint => bool) validTokenBet;
    mapping (uint => uint) tokenToTimer;

     
    event GameEnded(
        address winner,
        uint tokensWon,
        uint timeOfWin
    );

     
    event HouseRetrievedTake(
        uint timeTaken,
        uint tokensWithdrawn
    );

     
    event TokensWagered(
        address _wagerer,
        uint _wagered,
        uint _newExpiry
    );

    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }

    modifier onlyBankroll {
        require(msg.sender == bankroll);
        _; 
    }

    modifier onlyOwnerOrBankroll {
        require(msg.sender == owner || msg.sender == bankroll);
        _;
    }

    constructor(address ZethrAddress, address BankrollAddress) public {

         
        ZTHTKNADDR = ZethrAddress;
        ZTHBANKROLL = BankrollAddress;

         
        owner         = msg.sender;
        bankroll      = ZTHBANKROLL;
        currentWinner = ZTHBANKROLL;

         
        ZTHTKN = ZTHInterface(ZTHTKNADDR);
        ZTHTKN.approve(ZTHBANKROLL, 2**256 - 1);

         
        validTokenBet[5e18]  = true;
        validTokenBet[10e18] = true;
        validTokenBet[25e18] = true;
        validTokenBet[50e18] = true;

         
        tokenToTimer[5e18]  = 60 minutes;
        tokenToTimer[10e18] = 40 minutes;
        tokenToTimer[25e18] = 25 minutes;
        tokenToTimer[50e18] = 15 minutes;
        
         
        gameStarted = now;
        gameEnds    = now;
        gameActive  = true;
    }
    
     
    function() public payable { revert(); }

     
    struct TKN { address sender; uint value; }
    function tokenFallback(address _from, uint _value, bytes  ) public returns (bool){
        TKN memory          _tkn;
        _tkn.sender       = _from;
        _tkn.value        = _value;
        _stakeTokens(_tkn);
        return true;
    }

     
     
     
     
     
     
     
    function _stakeTokens(TKN _tkn) private {
   
        require(gameActive); 
        require(_zthToken(msg.sender));
        require(validTokenBet[_tkn.value]);
        
        if (now > gameEnds) { _settleAndRestart(); }

        address _customerAddress = _tkn.sender;
        uint    _wagered         = _tkn.value;

        uint rightNow      = now;
        uint timePurchased = tokenToTimer[_tkn.value];
        uint newGameEnd    = rightNow.add(timePurchased);

        gameStarted   = rightNow;
        gameEnds      = newGameEnd;
        currentWinner = _customerAddress;

        contractBalance = contractBalance.add(_wagered);
        uint houseCut   = _wagered.div(100);
        uint toAdd      = _wagered.sub(houseCut);
        houseTake       = houseTake.add(houseCut);
        tokensInPlay    = tokensInPlay.add(toAdd);

        emit TokensWagered(_customerAddress, _wagered, newGameEnd);

    }

     
     
     
     
    function _settleAndRestart() private {
        gameActive      = false;
        uint payment = tokensInPlay/2;
        contractBalance = contractBalance.sub(payment);

        if (tokensInPlay > 0) { ZTHTKN.transfer(currentWinner, payment);
            if (address(this).balance > 0){
                ZTHBANKROLL.transfer(address(this).balance);
            }}

        emit GameEnded(currentWinner, payment, now);

         
        tokensInPlay  = tokensInPlay.sub(payment);
        gameActive    = true;
    }

     
    function balanceOf() public view returns (uint) {
        return contractBalance;
    }

     
    function addTokenTime(uint _tokenAmount, uint _timeBought) public onlyOwner {
        validTokenBet[_tokenAmount] = true;
        tokenToTimer[_tokenAmount]  = _timeBought;
    }

     
    function removeTokenTime(uint _tokenAmount) public onlyOwner {
        validTokenBet[_tokenAmount] = false;
        tokenToTimer[_tokenAmount]  = 232 days;
    }

     
    function retrieveHouseTake() public onlyOwnerOrBankroll {
        uint toTake = houseTake;
        houseTake = 0;
        contractBalance = contractBalance.sub(toTake);
        ZTHTKN.transfer(bankroll, toTake);

        emit HouseRetrievedTake(now, toTake);
    }

     
    function pauseGame() public onlyOwner {
        gameActive = false;
    }

     
    function resumeGame() public onlyOwner {
        gameActive = true;
    }

     
    function changeOwner(address _newOwner) public onlyOwner {
        owner = _newOwner;
    }

     
    function changeBankroll(address _newBankroll) public onlyOwner {
        bankroll = _newBankroll;
    }

     
    function _zthToken(address _tokenContract) private view returns (bool) {
       return _tokenContract == ZTHTKNADDR;
    }
}

 

 
library SafeMath {

     
    function mul(uint a, uint b) internal pure returns (uint) {
        if (a == 0) {
            return 0;
        }
        uint c = a * b;
        assert(c / a == b);
        return c;
    }

     
    function div(uint a, uint b) internal pure returns (uint) {
         
        uint c = a / b;
         
        return c;
    }

     
    function sub(uint a, uint b) internal pure returns (uint) {
        assert(b <= a);
        return a - b;
    }

     
    function add(uint a, uint b) internal pure returns (uint) {
        uint c = a + b;
        assert(c >= a);
        return c;
    }
}