 

pragma solidity >=0.4.22 <0.6.0;

interface tokenRecipient { 
    function receiveApproval(address _from, uint256 _value, address _token, bytes  _extraData) external; 
}

interface CitizenInterface {
    function pushGametRefIncome(address _sender) external payable;
    function pushGametRefIncomeToken(address _sender, uint256 _amount) external;
    function addGameWinIncome(address _citizen, uint256 _value, bool _enough) external;
    function addGameEthSpendWin(address _citizen, uint256 _value, uint256 _valuewin, bool _enough) external;
}

library SafeMath {
    int256 constant private INT256_MIN = -2**255;

     
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
         
         
         
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b);

        return c;
    }

     
    function mul(int256 a, int256 b) internal pure returns (int256) {
         
         
         
        if (a == 0) {
            return 0;
        }

        require(!(a == -1 && b == INT256_MIN));  

        int256 c = a * b;
        require(c / a == b);

        return c;
    }

     
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
         
        require(b > 0);
        uint256 c = a / b;
         

        return c;
    }

     
    function div(int256 a, int256 b) internal pure returns (int256) {
        require(b != 0);  
        require(!(b == -1 && a == INT256_MIN));  

        int256 c = a / b;

        return c;
    }

     
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a);
        uint256 c = a - b;

        return c;
    }

     
    function sub(int256 a, int256 b) internal pure returns (int256) {
        int256 c = a - b;
        require((b >= 0 && c <= a) || (b < 0 && c > a));

        return c;
    }

     
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a);

        return c;
    }

     
    function add(int256 a, int256 b) internal pure returns (int256) {
        int256 c = a + b;
        require((b >= 0 && c >= a) || (b < 0 && c < a));

        return c;
    }

     
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b != 0);
        return a % b;
    }
}

contract TokenDAA {
    
    modifier onlyCoreContract() {
        require(isCoreContract[msg.sender], "admin required");
        _;
    }
    
    modifier onlyAdmin() {
        require(msg.sender == devTeam1, "admin required");
        _;
    }
    
    using SafeMath for *;
     
    string public name;
    string public symbol;
    uint8 public decimals = 10;
    uint256 public totalSupply;
    uint256 public totalSupplyBurned;
    uint256 public unitRate;
     
    mapping (address => uint256) public balanceOf;
    mapping (address => uint256) public totalSupplyByAddress;
    mapping (address => mapping (address => uint256)) public allowance;
    
     
    uint256 public HARD_TOTAL_SUPPLY = 20000000;
    uint256 public HARD_TOTAL_SUPPLY_BY_LEVEL = 200000;
    uint8 public MAX_LEVEL = 9;
    uint8 public MAX_ROUND = 10;
    uint256[10] public ETH_WIN = [uint(55),60,65,70,75,80,85,90,95,100];  
    uint256[10] public ETH_LOSE = [uint(50),55,60,65,70,75,80,85,90,95];  
    uint8 public currentRound = 1;
    uint8 public currentLevel = 0;
    mapping (uint256 => mapping(uint256 =>uint256)) public totalSupplyByLevel;

     
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
    event Burn(address indexed from, uint256 value, uint256 creationDate);
    
     
    mapping (address => bool) public isCoreContract;
    uint256 public coreContractSum;
    address[] public coreContracts;
    CitizenInterface CitizenContract;
    address devTeam1;
    address devTeam2;
    address devTeam3;
    address devTeam4;
    
     
    uint256 LIMIT_FREEZE_TOKEN = 10;
 

    struct Profile{
        uint256 citizenBalanceToken;
        uint256 citizenBalanceEth;
        mapping(uint256=>uint256) citizenFrozenBalance;
        uint256 lastDividendPulledRound;
    }

    uint256 public currentRoundDividend=1;
    struct DividendRound{
        uint256 totalEth;
        uint256 totalEthCredit;
        uint256 totalToken;
        uint256 totalTokenCredit;
        uint256 totalFrozenBalance;
        uint256 endRoundTime;
    }
    uint8 public BURN_TOKEN_PERCENT = 50;
    uint8 public DIVIDEND_FOR_CURRENT_PERCENT = 70;
    uint8 public DIVIDEND_KEEP_NEXT_PERCENT = 30;
    uint256 public NEXT_DEVIDEND_ROUND= 1209600;  
    uint256 public clockDevidend;
    
    mapping (uint256 => DividendRound) public dividendRound;
    mapping (address => Profile) public citizen;
    

     
     
    constructor(address[4] _devTeam) public {
         
        totalSupply = 0;
        unitRate = 10 ** uint256(decimals);
        HARD_TOTAL_SUPPLY = HARD_TOTAL_SUPPLY.mul(unitRate);
        HARD_TOTAL_SUPPLY_BY_LEVEL = HARD_TOTAL_SUPPLY_BY_LEVEL.mul(unitRate);
        LIMIT_FREEZE_TOKEN = LIMIT_FREEZE_TOKEN.mul(unitRate);
        
        for (uint i = 0; i < ETH_WIN.length; i++){
            ETH_WIN[i] = ETH_WIN[i].mul(10 ** uint256(15));
            ETH_LOSE[i]= ETH_LOSE[i].mul(10 ** uint256(15));
        }
        balanceOf[msg.sender] = totalSupply;                 
        name = "DABANKING";                                    
        symbol = "DAA";                                
        clockDevidend = 1561899600;
        
        devTeam1 = _devTeam[0];
        devTeam2 = _devTeam[1];
        devTeam3 = _devTeam[2];
        devTeam4 = _devTeam[3];
    }
    

     
    function joinNetwork(address[3] _contract)
        public
    {
        require(address(CitizenContract) == 0x0,"already setup");
        CitizenContract = CitizenInterface(_contract[2]);
        for(uint256 i =0; i<3; i++){
            isCoreContract[_contract[i]]=true;
            coreContracts.push(_contract[i]);
        }
        coreContractSum = 3;
    }
    
    function changeDev4(address _address) public onlyAdmin(){
        require(_address!=0x0,"Invalid address");
        devTeam4 = _address;
    }

    function addCoreContract(address _address) public   
        onlyAdmin()
    {
        require(_address!=0x0,"Invalid address");
        isCoreContract[_address] = true;
        coreContracts.push(_address);
        coreContractSum+=1;
    }
    
    function balanceOf(address _sender) public view returns(uint256) {
        return balanceOf[_sender] - citizen[_sender].citizenFrozenBalance[currentRoundDividend];
    }  
    
    function getBalanceOf(address _sender) public view returns(uint256) {
        return balanceOf[_sender] - citizen[_sender].citizenFrozenBalance[currentRoundDividend];
    } 

     
    function _transfer(address _from, address _to, uint _value) internal {
         
        require(_to != address(0x0));
         
        require(getBalanceOf(_from) >= _value);
         
        require(balanceOf[_to] + _value >= balanceOf[_to]);
         
        uint previousBalances = balanceOf[_from] + balanceOf[_to];
         
        balanceOf[_from] -= _value;
         
        balanceOf[_to] += _value;
        if (_to == address(this)){
            citizen[msg.sender].citizenBalanceToken += _value;
        }

        emit Transfer(_from, _to, _value);
         
        assert(balanceOf[_from] + balanceOf[_to] == previousBalances);
    }

    function citizenFreeze(uint _value) public returns (bool success) {
        require(balanceOf[msg.sender]-citizen[msg.sender].citizenFrozenBalance[currentRoundDividend]>= _value);
        require(citizen[msg.sender].citizenFrozenBalance[currentRoundDividend] + _value >= LIMIT_FREEZE_TOKEN,"Must over than limit");
        citizen[msg.sender].citizenFrozenBalance[currentRoundDividend] += _value;
        dividendRound[currentRoundDividend].totalFrozenBalance += _value;
        return true;
    }
    
    function citizenUnfreeze() public returns (bool success) {
        require(citizen[msg.sender].citizenFrozenBalance[currentRoundDividend]>0);
        dividendRound[currentRoundDividend].totalFrozenBalance -= citizen[msg.sender].citizenFrozenBalance[currentRoundDividend];
        citizen[msg.sender].citizenFrozenBalance[currentRoundDividend]=0;
        return true;
    }
    
    function getCitizenFreezing(address _sender) public view returns(uint256){
        return citizen[_sender].citizenFrozenBalance[currentRoundDividend];
    }    
    
    function getCitizenFreezingBuyRound(address _sender, uint256 _round) public view returns(uint256){
        return citizen[_sender].citizenFrozenBalance[_round];
    } 
    
    function getCitizenDevidendBuyRound(address _sender, uint256 _round) public view returns(uint256){
        uint256 _totalEth = dividendRound[_round].totalEth;
        if (dividendRound[_round].totalEthCredit==0&&dividendRound[_round].totalFrozenBalance>0){
            return _totalEth*citizen[_sender].citizenFrozenBalance[_round]/dividendRound[_round].totalFrozenBalance;
        }
        return 0;
    }
    
    function getDividendView(address _sender) public view returns(uint256){
        uint256 _last_round = citizen[_sender].lastDividendPulledRound;
        if (_last_round + 100 < currentRoundDividend) _last_round = currentRoundDividend - 100;
        uint256 _sum;
        uint256 _citizen_fronzen;
        uint256 _totalEth;
        for (uint256 i = _last_round;i<currentRoundDividend;i++){
            _totalEth = dividendRound[i].totalEth;
            if (dividendRound[i].totalEthCredit==0&&dividendRound[i].totalFrozenBalance>0){
                _citizen_fronzen = citizen[_sender].citizenFrozenBalance[i];
                _sum = _sum.add(_totalEth.mul(_citizen_fronzen).div(dividendRound[i].totalFrozenBalance));
            }
        }
        return _sum;
    }
    
    function getDividendPull(address _sender, uint256 _value) public returns(uint256){
        uint256 _last_round = citizen[_sender].lastDividendPulledRound;
        if (_last_round + 100 < currentRoundDividend) _last_round = currentRoundDividend - 100;
        uint256 _sum;
        uint256 _citizen_fronzen;
        uint256 _totalEth;
        for (uint256 i = _last_round;i<currentRoundDividend;i++){
            _totalEth = dividendRound[i].totalEth;
            if (dividendRound[i].totalEthCredit==0&&dividendRound[i].totalFrozenBalance>0){
                _citizen_fronzen = citizen[_sender].citizenFrozenBalance[i];
                _sum = _sum.add(_totalEth.mul(_citizen_fronzen).div(dividendRound[i].totalFrozenBalance));
            }
        }
        if (_value.add(_sum)==0){
            require(dividendRound[currentRoundDividend].totalEthCredit==0);   
        }
        if (citizen[_sender].citizenBalanceEth>0&&dividendRound[currentRoundDividend].totalEthCredit==0){
            _sum = _sum.add(citizen[_sender].citizenBalanceEth);
            citizen[_sender].citizenBalanceEth = 0;
        }
        _sender.transfer(_sum);
        citizen[_sender].lastDividendPulledRound = currentRoundDividend;
        return _sum;
    }
    
     
    function endDividendRound() public {
        require(msg.sender==devTeam4);
        require(now>clockDevidend);
        dividendRound[currentRoundDividend].endRoundTime = now;
        uint256 _for_next_round;
        if (dividendRound[currentRoundDividend].totalEthCredit>0){
             
            _for_next_round = dividendRound[currentRoundDividend].totalEth;
           dividendRound[currentRoundDividend+1].totalEth = _for_next_round;
           dividendRound[currentRoundDividend+1].totalEthCredit = dividendRound[currentRoundDividend].totalEthCredit;
        }
        else{
            _for_next_round = dividendRound[currentRoundDividend].totalEth*DIVIDEND_KEEP_NEXT_PERCENT/100;
            dividendRound[currentRoundDividend].totalEth = dividendRound[currentRoundDividend].totalEth*DIVIDEND_FOR_CURRENT_PERCENT/100;
            dividendRound[currentRoundDividend+1].totalEth = _for_next_round;
        }
        if (dividendRound[currentRoundDividend].totalTokenCredit>0){
            dividendRound[currentRoundDividend+1].totalToken = dividendRound[currentRoundDividend].totalToken;
            dividendRound[currentRoundDividend+1].totalTokenCredit = dividendRound[currentRoundDividend].totalTokenCredit;
        }
        else{
             
            _for_next_round = dividendRound[currentRoundDividend].totalToken*BURN_TOKEN_PERCENT/100;
            dividendRound[currentRoundDividend+1].totalToken = _for_next_round;
            burnFrom(address(this),_for_next_round);
            burnFrom(devTeam2,_for_next_round*4/6);
             
             
             
        }
        currentRoundDividend+=1;
        clockDevidend= clockDevidend.add(NEXT_DEVIDEND_ROUND);
    }
    
     
    function nextDividendRound() onlyAdmin() public {
        require(dividendRound[currentRoundDividend].totalEth>0);
        dividendRound[currentRoundDividend].endRoundTime = now;
        currentRoundDividend+=1;
         
    }
    
    
    function citizenDeposit(uint _value) public returns (bool success) {
        require(getBalanceOf(msg.sender)>=_value);
        _transfer(msg.sender, address(this), _value);
        return true;
    }
    
    function citizenUseDeposit(address _citizen, uint _value) onlyCoreContract() public{
        require(citizen[_citizen].citizenBalanceToken >= _value,"Not enough Token");
        dividendRound[currentRoundDividend].totalToken += _value;
        if (dividendRound[currentRoundDividend].totalToken>dividendRound[currentRoundDividend].totalTokenCredit&&dividendRound[currentRoundDividend].totalTokenCredit>0){
            dividendRound[currentRoundDividend].totalToken = dividendRound[currentRoundDividend].totalToken.sub(dividendRound[currentRoundDividend].totalTokenCredit);
            dividendRound[currentRoundDividend].totalTokenCredit=0;
        }
        citizen[_citizen].citizenBalanceToken-=_value;
    }
    
    function pushDividend() public payable{
        uint256 _value = msg.value;
        dividendRound[currentRoundDividend].totalEth = dividendRound[currentRoundDividend].totalEth.add(_value);
        if (dividendRound[currentRoundDividend].totalEth>dividendRound[currentRoundDividend].totalEthCredit&&dividendRound[currentRoundDividend].totalEthCredit>0){
            dividendRound[currentRoundDividend].totalEth = dividendRound[currentRoundDividend].totalEth.sub(dividendRound[currentRoundDividend].totalEthCredit);
            dividendRound[currentRoundDividend].totalEthCredit=0;
        }
    }
    
    function payOut(address _winner, uint256 _unit, uint256 _value, uint256 _valuebet) onlyCoreContract() public{
        if (_unit==0){
            citizenMintToken(_winner,_valuebet,1);
            if (dividendRound[currentRoundDividend].totalEth<_value){
                 
                citizen[_winner].citizenBalanceEth+=_value;
                CitizenContract.addGameEthSpendWin(_winner, _valuebet, _value, false);
                dividendRound[currentRoundDividend].totalEthCredit+=_value;
            }
            else{
                _winner.transfer(_value);
                CitizenContract.addGameEthSpendWin(_winner, _valuebet, _value, true);
                dividendRound[currentRoundDividend].totalEth = dividendRound[currentRoundDividend].totalEth.sub(_value);
            }
        }
        else{
            if (dividendRound[currentRoundDividend].totalToken<_value){
                dividendRound[currentRoundDividend].totalTokenCredit += _value;
                citizen[_winner].citizenBalanceToken+=_value;
            }
            else {
                dividendRound[currentRoundDividend].totalToken -= _value;
                citizen[_winner].citizenBalanceToken+=_value;
            }
        }
    }
    
     
    function pushGameRefIncome(address _sender,uint256 _unit, uint256 _value) public onlyCoreContract(){
        if (_unit==1){
            dividendRound[currentRoundDividend].totalEth = dividendRound[currentRoundDividend].totalEth.sub(_value);
            CitizenContract.pushGametRefIncome.value(_value)(_sender);
        }else{
            CitizenContract.pushGametRefIncomeToken(_sender,_value);
        }
        
    }

    function citizenWithdrawDeposit(uint _value) public returns (bool success){
        require(citizen[msg.sender].citizenBalanceToken >=_value);
        _transfer(address(this),msg.sender,_value);
        citizen[msg.sender].citizenBalanceToken-=_value;
        return true;
    }
    
    function ethToToken(uint256 _ethAmount, int8 _is_win) private view returns(uint256){
        if (_is_win==1) {
            return uint256(_ethAmount) * unitRate / uint256(ETH_WIN[currentLevel]);}
        return _ethAmount * unitRate / uint256(ETH_LOSE[currentLevel]) ;
    }    

    function citizenMintToken(address _buyer, uint256 _buyPrice, int8 _is_win) public onlyCoreContract() returns(uint256) {
        uint256 revTokens = ethToToken( _buyPrice, _is_win);

        if (revTokens*10/6 + totalSupplyByLevel[currentRound][currentLevel] > HARD_TOTAL_SUPPLY_BY_LEVEL){
            uint256 revTokenCurrentLevel = HARD_TOTAL_SUPPLY_BY_LEVEL.sub(totalSupplyByLevel[currentRound][currentLevel]);
            revTokenCurrentLevel = revTokenCurrentLevel*6/10;
            balanceOf[_buyer]= balanceOf[_buyer].add(revTokenCurrentLevel);
            emit Transfer(0x0, _buyer, revTokenCurrentLevel);
            totalSupplyByAddress[_buyer] = totalSupplyByAddress[_buyer].add(revTokenCurrentLevel);
            balanceOf[devTeam2] = balanceOf[devTeam2].add(revTokenCurrentLevel*4/6);
            emit Transfer(0x0, devTeam2, revTokenCurrentLevel*4/6);
            
            totalSupply = totalSupply.add(revTokenCurrentLevel*10/6);
            totalSupplyByLevel[currentRound][currentLevel] = HARD_TOTAL_SUPPLY_BY_LEVEL;
            
             
            if (currentLevel+1>MAX_LEVEL){
                if(currentRound+1>MAX_ROUND){
                    return revTokenCurrentLevel;
                }
                currentRound+=1;
                currentLevel=0;
            } else {
                currentLevel+=1;
            }
            
             
            return revTokenCurrentLevel;
        } else {
            balanceOf[_buyer]= balanceOf[_buyer].add(revTokens);
            emit Transfer(0x0, _buyer, revTokens);
            totalSupplyByAddress[_buyer] = totalSupplyByAddress[_buyer].add(revTokens);
            balanceOf[devTeam2] = balanceOf[devTeam2].add(revTokens*4/6);
            emit Transfer(0x0, devTeam2, revTokens*4/6);
            
            totalSupply = totalSupply.add(revTokens*10/6);
            totalSupplyByLevel[currentRound][currentLevel] = totalSupplyByLevel[currentRound][currentLevel].add(revTokens*10/6);
            return revTokens;
        }
    }
    
    function getCitizenBalanceEth(address _sender) view public returns(uint256){
        return citizen[_sender].citizenBalanceEth;
    } 

     
    function transfer(address _to, uint256 _value) public returns (bool success) {
        _transfer(msg.sender, _to, _value);
        return true;
    }

     
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {
        require(_value <= allowance[_from][msg.sender]);      
        allowance[_from][msg.sender] -= _value;
        _transfer(_from, _to, _value);
        return true;
    }

     
    function approve(address _spender, uint256 _value) public
        returns (bool success) {
        allowance[msg.sender][_spender] = _value;
         
        return true;
    }

     
    function approveAndCall(address _spender, uint256 _value, bytes _extraData)
        public
        returns (bool success) {
        tokenRecipient spender = tokenRecipient(_spender);
        if (approve(_spender, _value)) {
            spender.receiveApproval(msg.sender, _value, address(this), _extraData);
            return true;
        }
    }

     
    function burn(uint256 _value) public returns (bool success) {
        require(balanceOf[msg.sender] >= _value);    
        balanceOf[msg.sender] -= _value;             
        totalSupply -= _value;                       
        emit Burn(msg.sender, _value, now);
        return true;
    }

     
    function burnFrom(address _from, uint256 _value) public returns (bool success) {
        require(balanceOf[_from] >= _value);                 
         
        balanceOf[_from] -= _value;                          
         
        totalSupply -= _value;                               
        totalSupplyBurned += _value;
        emit Burn(_from, _value, now);
        return true;
    }
}