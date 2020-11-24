 

pragma solidity ^0.4.23;

library SafeMath {

     
    function mul(uint256 _a, uint256 _b) internal pure returns (uint256) {
         
         
         
        if (_a == 0) {
            return 0;
        }

        uint256 c = _a * _b;
        require(c / _a == _b);

        return c;
    }

     
    function div(uint256 _a, uint256 _b) internal pure returns (uint256) {
        require(_b > 0);  
        uint256 c = _a / _b;
         

        return c;
    }

     
    function sub(uint256 _a, uint256 _b) internal pure returns (uint256) {
        require(_b <= _a);
        uint256 c = _a - _b;

        return c;
    }

     
    function add(uint256 _a, uint256 _b) internal pure returns (uint256) {
        uint256 c = _a + _b;
        require(c >= _a);

        return c;
    }

     
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b != 0);
        return a % b;
    }
}

contract FiftyFifty{
    using SafeMath for uint;  
     
    uint[11] betValues = [0.125 ether, 0.250 ether, 0.500 ether, 1.00 ether, 2.00 ether, 4.00 ether, 8.00 ether, 16.00 ether, 32.00 ether, 64.00 ether];
     
    uint[11] returnValues = [0.2375 ether, 0.475 ether, 0.950 ether, 1.90 ether, 3.80 ether, 7.60 ether, 15.20 ether, 30.40 ether, 60.80 ether, 121.60 ether];
     
    uint[11] jackpotValues = [0.05 ether, 0.010 ether, 0.020 ether, 0.04 ether, 0.08 ether, 0.16 ether, 0.32 ether, 0.64 ether, 1.28 ether, 2.56 ether];
     
    uint[11] fees = [0.0025 ether, 0.005 ether, 0.010 ether, 0.020 ether, 0.040 ether, 0.080 ether, 0.16 ether, 0.32 ether, 0.64 ether, 1.28 ether];
    uint roundNumber;  
    mapping(uint => uint) jackpot;
     
    mapping(uint => mapping(uint => address[])) roundToBetValueToUsers;
     
    mapping(uint => mapping(uint => uint)) roundToBetValueToTotalBet;
     
    mapping(uint => uint) public roundToTotalBet;
     
    mapping(uint => address) currentUser;
    address owner;
    uint ownerDeposit;

     
    event Jackpot(address indexed _user, uint _value, uint indexed _round, uint _now);
    event Bet(address indexed _winner,address indexed _user,uint _bet, uint _payBack, uint _now);


    constructor() public {
        owner = msg.sender;
        roundNumber = 1;
    }

    modifier onlyOwner () {
        require(msg.sender == owner);
        _;
    }

    function changeOwner(address _owner) external onlyOwner{
        owner = _owner;
    }

     

    function() public payable {
         
        uint valueNumber = checkValue(msg.value);
         
        uint randJackpot = (uint(blockhash(block.number - 1)) + roundNumber) % 10000;
        if(jackpot[roundNumber] != 0 && randJackpot <= 1){
             
            uint randJackpotBetValue = uint(blockhash(block.number - 1)) % roundToTotalBet[roundNumber];
             
            uint betNum=0;
            uint addBetValue = 0;
             
            while(randJackpotBetValue > addBetValue){
                 
                addBetValue += roundToBetValueToTotalBet[roundNumber][betNum];
                betNum++;
            }
             
            uint randJackpotUser = uint(blockhash(block.number - 1)) % roundToBetValueToUsers[roundNumber][betNum.sub(1)].length;
            address user = roundToBetValueToUsers[roundNumber][valueNumber][randJackpotUser];
            uint jp = jackpot[roundNumber];
            user.transfer(jp);
            emit Jackpot(user, jp, roundNumber, now);
            roundNumber = roundNumber.add(1);
        }
        if(currentUser[valueNumber] == address(0)){
             
            currentUser[valueNumber] = msg.sender;
            emit Bet(address(0), msg.sender, betValues[valueNumber], 0, now);
        }else{
             
            uint rand = uint(blockhash(block.number-1)) % 2;
            ownerDeposit = ownerDeposit.add(fees[valueNumber]);
            if(rand == 0){
                 
                currentUser[valueNumber].transfer(returnValues[valueNumber]);
                emit Bet(currentUser[valueNumber], msg.sender, betValues[valueNumber], returnValues[valueNumber], now);
            }else{
                 
                msg.sender.transfer(returnValues[valueNumber]);
                emit Bet(msg.sender, msg.sender, betValues[valueNumber], returnValues[valueNumber], now);
            }
             
            delete currentUser[valueNumber];
        }
         
        jackpot[roundNumber] = jackpot[roundNumber].add(jackpotValues[valueNumber]);
        roundToBetValueToUsers[roundNumber][valueNumber].push(currentUser[valueNumber]);
        roundToTotalBet[roundNumber] = roundToTotalBet[roundNumber].add(betValues[valueNumber]);
        roundToBetValueToTotalBet[roundNumber][valueNumber] = roundToBetValueToTotalBet[roundNumber][valueNumber].add(betValues[valueNumber]);
    }

     
    function checkValue(uint sendValue) internal view returns(uint) {
         
        uint num = 0;
        while (sendValue != betValues[num]){
            if(num == 11){
                revert();
            }
            num++;
        }
        return num;
    }

    function roundToBetValueToUsersLength(uint _roundNum, uint _betNum) public view returns(uint){
        return roundToBetValueToUsers[_roundNum][_betNum].length;
    }

    function withdrawDeposit() public onlyOwner{
        owner.transfer(ownerDeposit);
        ownerDeposit = 0;
    }

    function currentJackpot() public view  returns(uint){
        return jackpot[roundNumber];
    }

}