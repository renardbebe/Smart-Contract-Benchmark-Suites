 

pragma solidity ^0.4.17;

library SafeMath {
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

contract ERC20Basic {
  uint public totalSupply;
  address public owner;  
  address public animator;  
  function balanceOf(address who) constant public returns (uint);
  function transfer(address to, uint value) public;
  event Transfer(address indexed from, address indexed to, uint value);
  function commitDividend(address who) internal;  
}

contract ERC20 is ERC20Basic {
  function allowance(address owner, address spender) constant public returns (uint);
  function transferFrom(address from, address to, uint value) public;
  function approve(address spender, uint value) public;
  event Approval(address indexed owner, address indexed spender, uint value);
}

contract BasicToken is ERC20Basic {
  using SafeMath for uint;
  mapping(address => uint) balances;

  modifier onlyPayloadSize(uint size) {
     assert(msg.data.length >= size + 4);
     _;
  }
   
  function transfer(address _to, uint _value) public onlyPayloadSize(2 * 32) {
    commitDividend(msg.sender);
    balances[msg.sender] = balances[msg.sender].sub(_value);
    if(_to == address(this)) {
        commitDividend(owner);
        balances[owner] = balances[owner].add(_value);
        Transfer(msg.sender, owner, _value);
    }
    else {
        commitDividend(_to);
        balances[_to] = balances[_to].add(_value);
        Transfer(msg.sender, _to, _value);
    }
  }
   
  function balanceOf(address _owner) constant public returns (uint balance) {
    return balances[_owner];
  }
}

contract StandardToken is BasicToken, ERC20 {
  mapping (address => mapping (address => uint)) allowed;

   
  function transferFrom(address _from, address _to, uint _value) public onlyPayloadSize(3 * 32) {
    var _allowance = allowed[_from][msg.sender];
    commitDividend(_from);
    commitDividend(_to);
    allowed[_from][msg.sender] = _allowance.sub(_value);
    balances[_from] = balances[_from].sub(_value);
    balances[_to] = balances[_to].add(_value);
    Transfer(_from, _to, _value);
  }
   
  function approve(address _spender, uint _value) public {
     
    assert(!((_value != 0) && (allowed[msg.sender][_spender] != 0)));
    allowed[msg.sender][_spender] = _value;
    Approval(msg.sender, _spender, _value);
  }
   
  function allowance(address _owner, address _spender) constant public returns (uint remaining) {
    return allowed[_owner][_spender];
  }
}

 
contract SmartBillions is StandardToken {

     
    string public constant name = "SmartBillions Token";
    string public constant symbol = "PLAY";
    uint public constant decimals = 0;

     
    struct Wallet {
        uint208 balance;  
    	uint16 lastDividendPeriod;  
    	uint32 nextWithdrawBlock;  
    }
    mapping (address => Wallet) wallets;
    struct Bet {
        uint192 value;  
        uint32 betHash;  
        uint32 blockNum;  
    }
    mapping (address => Bet) bets;

    uint public walletBalance = 0;  

     
    uint public investStart = 1;  
    uint public investBalance = 0;  
    uint public investBalanceGot = 0;  
    uint public investBalanceMax = 200000 ether;  
    uint public dividendPeriod = 1;
    uint[] public dividends;  

     
    uint public maxWin = 0;  
    uint public hashFirst = 0;  
    uint public hashLast = 0;  
    uint public hashNext = 0;  
    uint public hashBetSum = 0;  
    uint public hashBetMax = 5 ether;  
    uint[] public hashes;  

     
     
    uint public constant hashesSize = 16384 ;  
    uint public coldStoreLast = 0 ;  

     
    event LogBet(address indexed player, uint bethash, uint blocknumber, uint betsize);
    event LogLoss(address indexed player, uint bethash, uint hash);
    event LogWin(address indexed player, uint bethash, uint hash, uint prize);
    event LogInvestment(address indexed investor, address indexed partner, uint amount);
    event LogRecordWin(address indexed player, uint amount);
    event LogLate(address indexed player,uint playerBlockNumber,uint currentBlockNumber);
    event LogDividend(address indexed investor, uint amount, uint period);

    modifier onlyOwner() {
        assert(msg.sender == owner);
        _;
    }

    modifier onlyAnimator() {
        assert(msg.sender == animator);
        _;
    }

     
    function SmartBillions() public {
        owner = msg.sender;
        animator = msg.sender;
        wallets[owner].lastDividendPeriod = uint16(dividendPeriod);
        dividends.push(0);  
        dividends.push(0);  
    }

 
    
     
    function hashesLength() constant external returns (uint) {
        return uint(hashes.length);
    }
    
     
    function walletBalanceOf(address _owner) constant external returns (uint) {
        return uint(wallets[_owner].balance);
    }
    
     
    function walletPeriodOf(address _owner) constant external returns (uint) {
        return uint(wallets[_owner].lastDividendPeriod);
    }
    
     
    function walletBlockOf(address _owner) constant external returns (uint) {
        return uint(wallets[_owner].nextWithdrawBlock);
    }
    
     
    function betValueOf(address _owner) constant external returns (uint) {
        return uint(bets[_owner].value);
    }
    
     
    function betHashOf(address _owner) constant external returns (uint) {
        return uint(bets[_owner].betHash);
    }
    
     
    function betBlockNumberOf(address _owner) constant external returns (uint) {
        return uint(bets[_owner].blockNum);
    }
    
     
    function dividendsBlocks() constant external returns (uint) {
        if(investStart > 0) {
            return(0);
        }
        uint period = (block.number - hashFirst) / (10 * hashesSize);
        if(period > dividendPeriod) {
            return(0);
        }
        return((10 * hashesSize) - ((block.number - hashFirst) % (10 * hashesSize)));
    }

 

     
    function changeOwner(address _who) external onlyOwner {
        assert(_who != address(0));
        commitDividend(msg.sender);
        commitDividend(_who);
        owner = _who;
    }

     
    function changeAnimator(address _who) external onlyAnimator {
        assert(_who != address(0));
        commitDividend(msg.sender);
        commitDividend(_who);
        animator = _who;
    }

     
    function setInvestStart(uint _when) external onlyOwner {
        require(investStart == 1 && hashFirst > 0 && block.number < _when);
        investStart = _when;
    }

     
    function setBetMax(uint _maxsum) external onlyOwner {
        hashBetMax = _maxsum;
    }

     
    function resetBet() external onlyOwner {
        hashNext = block.number + 3;
        hashBetSum = 0;
    }

     
    function coldStore(uint _amount) external onlyOwner {
        houseKeeping();
        require(_amount > 0 && this.balance >= (investBalance * 9 / 10) + walletBalance + _amount);
        if(investBalance >= investBalanceGot / 2){  
            require((_amount <= this.balance / 400) && coldStoreLast + 4 * 60 * 24 * 7 <= block.number);
        }
        msg.sender.transfer(_amount);
        coldStoreLast = block.number;
    }

     
    function hotStore() payable external {
        walletBalance += msg.value;
        wallets[msg.sender].balance += uint208(msg.value);
        houseKeeping();
    }

 

     
    function houseKeeping() public {
        if(investStart > 1 && block.number >= investStart + (hashesSize * 5)){  
            investStart = 0;  
        }
        else {
            if(hashFirst > 0){
		        uint period = (block.number - hashFirst) / (10 * hashesSize );
                if(period > dividends.length - 2) {
                    dividends.push(0);
                }
                if(period > dividendPeriod && investStart == 0 && dividendPeriod < dividends.length - 1) {
                    dividendPeriod++;
                }
            }
        }
    }

 

     
    function payWallet() public {
        if(wallets[msg.sender].balance > 0 && wallets[msg.sender].nextWithdrawBlock <= block.number){
            uint balance = wallets[msg.sender].balance;
            wallets[msg.sender].balance = 0;
            walletBalance -= balance;
            pay(balance);
        }
    }

    function pay(uint _amount) private {
        uint maxpay = this.balance / 2;
        if(maxpay >= _amount) {
            msg.sender.transfer(_amount);
            if(_amount > 1 finney) {
                houseKeeping();
            }
        }
        else {
            uint keepbalance = _amount - maxpay;
            walletBalance += keepbalance;
            wallets[msg.sender].balance += uint208(keepbalance);
            wallets[msg.sender].nextWithdrawBlock = uint32(block.number + 4 * 60 * 24 * 30);  
            msg.sender.transfer(maxpay);
        }
    }

 

     
    function investDirect() payable external {
        invest(owner);
    }

     
    function invest(address _partner) payable public {
         
        require(investStart > 1 && block.number < investStart + (hashesSize * 5) && investBalance < investBalanceMax);
        uint investing = msg.value;
        if(investing > investBalanceMax - investBalance) {
            investing = investBalanceMax - investBalance;
            investBalance = investBalanceMax;
            investBalanceGot = investBalanceMax;
            investStart = 0;  
            msg.sender.transfer(msg.value.sub(investing));  
        }
        else{
            investBalance += investing;
            investBalanceGot += investing;
        }
        if(_partner == address(0) || _partner == owner){
            walletBalance += investing / 10;
            wallets[owner].balance += uint208(investing / 10);}  
        else{
            walletBalance += (investing * 5 / 100) * 2;
            wallets[owner].balance += uint208(investing * 5 / 100);  
            wallets[_partner].balance += uint208(investing * 5 / 100);}  
        wallets[msg.sender].lastDividendPeriod = uint16(dividendPeriod);  
        uint senderBalance = investing / 10**15;
        uint ownerBalance = investing * 16 / 10**17  ;
        uint animatorBalance = investing * 10 / 10**17  ;
        balances[msg.sender] += senderBalance;
        balances[owner] += ownerBalance ;  
        balances[animator] += animatorBalance ;  
        totalSupply += senderBalance + ownerBalance + animatorBalance;
        Transfer(address(0),msg.sender,senderBalance);  
        Transfer(address(0),owner,ownerBalance);  
        Transfer(address(0),animator,animatorBalance);  
        LogInvestment(msg.sender,_partner,investing);
    }

     
    function disinvest() external {
        require(investStart == 0);
        commitDividend(msg.sender);
        uint initialInvestment = balances[msg.sender] * 10**15;
        Transfer(msg.sender,address(0),balances[msg.sender]);  
        delete balances[msg.sender];  
        investBalance -= initialInvestment;
        wallets[msg.sender].balance += uint208(initialInvestment * 9 / 10);
        payWallet();
    }

     
    function payDividends() external {
        require(investStart == 0);
        commitDividend(msg.sender);
        payWallet();
    }

     
    function commitDividend(address _who) internal {
        uint last = wallets[_who].lastDividendPeriod;
        if((balances[_who]==0) || (last==0)){
            wallets[_who].lastDividendPeriod=uint16(dividendPeriod);
            return;
        }
        if(last==dividendPeriod) {
            return;
        }
        uint share = balances[_who] * 0xffffffff / totalSupply;
        uint balance = 0;
        for(;last<dividendPeriod;last++) {
            balance += share * dividends[last];
        }
        balance = (balance / 0xffffffff);
        walletBalance += balance;
        wallets[_who].balance += uint208(balance);
        wallets[_who].lastDividendPeriod = uint16(last);
        LogDividend(_who,balance,last);
    }

 

    function betPrize(Bet _player, uint24 _hash) constant private returns (uint) {  
        uint24 bethash = uint24(_player.betHash);
        uint24 hit = bethash ^ _hash;
        uint24 matches =
            ((hit & 0xF) == 0 ? 1 : 0 ) +
            ((hit & 0xF0) == 0 ? 1 : 0 ) +
            ((hit & 0xF00) == 0 ? 1 : 0 ) +
            ((hit & 0xF000) == 0 ? 1 : 0 ) +
            ((hit & 0xF0000) == 0 ? 1 : 0 ) +
            ((hit & 0xF00000) == 0 ? 1 : 0 );
        if(matches == 6){
            return(uint(_player.value) * 7000000);
        }
        if(matches == 5){
            return(uint(_player.value) * 20000);
        }
        if(matches == 4){
            return(uint(_player.value) * 500);
        }
        if(matches == 3){
            return(uint(_player.value) * 25);
        }
        if(matches == 2){
            return(uint(_player.value) * 3);
        }
        return(0);
    }
    
     
    function betOf(address _who) constant external returns (uint)  {
        Bet memory player = bets[_who];
        if( (player.value==0) ||
            (player.blockNum<=1) ||
            (block.number<player.blockNum) ||
            (block.number>=player.blockNum + (10 * hashesSize))){
            return(0);
        }
        if(block.number<player.blockNum+256){
            return(betPrize(player,uint24(block.blockhash(player.blockNum))));
        }
        if(hashFirst>0){
            uint32 hash = getHash(player.blockNum);
            if(hash == 0x1000000) {  
                return(uint(player.value));
            }
            else{
                return(betPrize(player,uint24(hash)));
            }
	}
        return(0);
    }

     
    function won() public {
        Bet memory player = bets[msg.sender];
        if(player.blockNum==0){  
            bets[msg.sender] = Bet({value: 0, betHash: 0, blockNum: 1});
            return;
        }
        if((player.value==0) || (player.blockNum==1)){
            payWallet();
            return;
        }
        require(block.number>player.blockNum);  
        if(player.blockNum + (10 * hashesSize) <= block.number){  
            LogLate(msg.sender,player.blockNum,block.number);
            bets[msg.sender] = Bet({value: 0, betHash: 0, blockNum: 1});
            return;
        }
        uint prize = 0;
        uint32 hash = 0;
        if(block.number<player.blockNum+256){
            hash = uint24(block.blockhash(player.blockNum));
            prize = betPrize(player,uint24(hash));
        }
        else {
            if(hashFirst>0){  
                hash = getHash(player.blockNum);
                if(hash == 0x1000000) {  
                     
                    LogLate(msg.sender,player.blockNum,block.number);
                    bets[msg.sender] = Bet({value: 0, betHash: 0, blockNum: 1});
                    return();
                }
                else{
                    prize = betPrize(player,uint24(hash));
                }
	    }
            else{
                LogLate(msg.sender,player.blockNum,block.number);
                bets[msg.sender] = Bet({value: 0, betHash: 0, blockNum: 1});
                return();
            }
        }
        bets[msg.sender] = Bet({value: 0, betHash: 0, blockNum: 1});
        if(prize>0) {
            LogWin(msg.sender,uint(player.betHash),uint(hash),prize);
            if(prize > maxWin){
                maxWin = prize;
                LogRecordWin(msg.sender,prize);
            }
            pay(prize);
        }
        else{
            LogLoss(msg.sender,uint(player.betHash),uint(hash));
        }
    }

     
    function () payable external {
        if(msg.value > 0){
            if(investStart>1){  
                invest(owner);
            }
            else{  
                play();
            }
            return;
        }
         
        if(investStart == 0 && balances[msg.sender]>0){
            commitDividend(msg.sender);}
        won();  
    }

     
    function play() payable public returns (uint) {
        return playSystem(uint(keccak256(msg.sender,block.number)), address(0));
    }

     
    function playRandom(address _partner) payable public returns (uint) {
        return playSystem(uint(keccak256(msg.sender,block.number)), _partner);
    }

     
    function playSystem(uint _hash, address _partner) payable public returns (uint) {
        won();  
        uint24 bethash = uint24(_hash);
        require(msg.value <= 1 ether && msg.value < hashBetMax);
        if(msg.value > 0){
            if(investStart==0) {  
                dividends[dividendPeriod] += msg.value / 20;  
            }
            if(_partner != address(0)) {
                uint fee = msg.value / 100;
                walletBalance += fee;
                wallets[_partner].balance += uint208(fee);  
            }
            if(hashNext < block.number + 3) {
                hashNext = block.number + 3;
                hashBetSum = msg.value;
            }
            else{
                if(hashBetSum > hashBetMax) {
                    hashNext++;
                    hashBetSum = msg.value;
                }
                else{
                    hashBetSum += msg.value;
                }
            }
            bets[msg.sender] = Bet({value: uint192(msg.value), betHash: uint32(bethash), blockNum: uint32(hashNext)});
            LogBet(msg.sender,uint(bethash),hashNext,msg.value);
        }
        putHashes(25);  
        return(hashNext);
    }

 

     
    function addHashes(uint _sadd) public returns (uint) {
        require(hashFirst == 0 && _sadd > 0 && _sadd <= hashesSize);
        uint n = hashes.length;
        if(n + _sadd > hashesSize){
            hashes.length = hashesSize;
        }
        else{
            hashes.length += _sadd;
        }
        for(;n<hashes.length;n++){  
            hashes[n] = 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF;
        }
        if(hashes.length>=hashesSize) {  
            hashFirst = block.number - ( block.number % 10);
            hashLast = hashFirst;
        }
        return(hashes.length);
    }

     
    function addHashes128() external returns (uint) {
        return(addHashes(128));
    }

    function calcHashes(uint32 _lastb, uint32 _delta) constant private returns (uint) {
        return( ( uint(block.blockhash(_lastb  )) & 0xFFFFFF )
            | ( ( uint(block.blockhash(_lastb+1)) & 0xFFFFFF ) << 24 )
            | ( ( uint(block.blockhash(_lastb+2)) & 0xFFFFFF ) << 48 )
            | ( ( uint(block.blockhash(_lastb+3)) & 0xFFFFFF ) << 72 )
            | ( ( uint(block.blockhash(_lastb+4)) & 0xFFFFFF ) << 96 )
            | ( ( uint(block.blockhash(_lastb+5)) & 0xFFFFFF ) << 120 )
            | ( ( uint(block.blockhash(_lastb+6)) & 0xFFFFFF ) << 144 )
            | ( ( uint(block.blockhash(_lastb+7)) & 0xFFFFFF ) << 168 )
            | ( ( uint(block.blockhash(_lastb+8)) & 0xFFFFFF ) << 192 )
            | ( ( uint(block.blockhash(_lastb+9)) & 0xFFFFFF ) << 216 )
            | ( ( uint(_delta) / hashesSize) << 240)); 
    }

    function getHash(uint _block) constant private returns (uint32) {
        uint delta = (_block - hashFirst) / 10;
        uint hash = hashes[delta % hashesSize];
        if(delta / hashesSize != hash >> 240) {
            return(0x1000000);  
        }
        uint slotp = (_block - hashFirst) % 10; 
        return(uint32((hash >> (24 * slotp)) & 0xFFFFFF));
    }
    
     
    function putHash() public returns (bool) {
        uint lastb = hashLast;
        if(lastb == 0 || block.number <= lastb + 10) {
            return(false);
        }
        uint blockn256;
        if(block.number<256) {  
            blockn256 = 0;
        }
        else{
            blockn256 = block.number - 255;
        }
        if(lastb < blockn256) {
            uint num = blockn256;
            num += num % 10;
            lastb = num; 
        }
        uint delta = (lastb - hashFirst) / 10;
        hashes[delta % hashesSize] = calcHashes(uint32(lastb),uint32(delta));
        hashLast = lastb + 10;
        return(true);
    }

     
    function putHashes(uint _num) public {
        uint n=0;
        for(;n<_num;n++){
            if(!putHash()){
                return;
            }
        }
    }
    
}