 
        bytes11 actions;
         
        uint128 amount;
         
        uint128 dealBlockNumber;
    }

    mapping (uint256 => Bet) public bets;

    event Deposit(address indexed from, uint256 value);
    event Withdraw(address indexed from, uint256 value);
    event Apply(address indexed from, uint256 value);
    event Deal(uint256 indexed commit);
    event Settle(uint256 indexed commit);
    event Refund(uint256 indexed commit, uint128 amount);
    
     
    constructor() public payable{        
    }

     
    function () public payable {
        if(!isOwner(msg.sender)){
            _deposit(msg.sender, msg.value);
        }        
    }

     
    function totalBalance() public view returns (uint256) {
        return _totalBalance;
    }

     
    function balanceOf(address owner) public view returns (uint256) {
        return _balances[owner];
    }

     
    function lockedOf(address owner) public view returns (uint256) {
        return _locked[owner];
    }

     
    function lastApplyTime(address owner) public view returns (uint256) {
        return _last_apply_time[owner];
    }

     
    function applyAmount(address owner) public view returns (uint256) {
        return _apply_amount[owner];
    }

     
    function deal(address gambler, uint256 commit, uint128 amount, uint8 cutCard, uint8 v, bytes32 r, bytes32 s) 
        public 
        onlyCroupier
    {
         
        bytes32 signatureHash = keccak256(abi.encodePacked(amount, cutCard, commit));        
        require (gambler == ecrecover(signatureHash, v, r, s), "ECDSA signature is not valid.");

        _dealCore(gambler, commit, amount, cutCard);
    }

     
    function settle(uint256 reveal_1, uint256 reveal_2, bytes11 actions, bool win, uint128 amount) 
        public 
        onlyCroupier 
    {
        uint commit = uint(keccak256(abi.encodePacked(reveal_1, reveal_2)));
        Bet storage bet = bets[commit];

         
        address gambler = bet.gambler;
        uint256 value = uint256(bet.amount);
        require(gambler != address(0) && value > 0, "Bet should be in 'active' state.");

         
        require(block.number > bet.dealBlockNumber, "Settle in the same block as placeBet, or before.");
        require(block.number <= uint256(bet.dealBlockNumber).add(expireBlocks), "Bet expired.");        

         
        bet.actions = actions;
        bet.amount = 0;

         
        uint256 lockValue = value.mul(LOCK_RATIO).div(THIS_DIVISOR);
        _locked[gambler] = _locked[gambler].sub(lockValue);

         
        if(win) {
            _balances[gambler] = _balances[gambler].add(uint256(amount));
            _totalBalance = _totalBalance.add(uint256(amount));
        }
        else{
            _balances[gambler] = _balances[gambler].sub(uint256(amount));
            _totalBalance = _totalBalance.sub(uint256(amount));
        }

        emit Settle(commit);
    }

     
    function refund(uint256 commit) public onlyCroupier {
         
        Bet storage bet = bets[commit];
        uint256 value = uint256(bet.amount);
        address gambler = bet.gambler;
        require(gambler != address(0) && value > 0, "Bet should be in 'active' state.");

         
        require (block.number > uint256(bet.dealBlockNumber).add(expireBlocks), "Bet not yet expired.");

         
        uint256 lockValue = value.mul(LOCK_RATIO).div(THIS_DIVISOR);  
        _locked[gambler] = _locked[gambler].sub(lockValue);

        bet.amount = 0;

        emit Refund(commit, uint128(value));
    }

     
    function deposit() public payable returns (bool){
        _deposit(msg.sender, msg.value);
        return true;
    }

     
    function apply(uint256 amount) public returns (bool){
        require(amount <= _balances[msg.sender].sub(_locked[msg.sender]), "Not enough balance.");

        _last_apply_time[msg.sender] = now;
        _apply_amount[msg.sender] = amount;

        emit Apply(msg.sender, amount);
        return true;
    }

     
    function withdraw() public returns (bool){
        require(_apply_amount[msg.sender] > 0, "");
        require(now >= _last_apply_time[msg.sender].add(statedPeriod), "");

        _withdraw(msg.sender, _apply_amount[msg.sender]);

        _apply_amount[msg.sender] = 0;
        return true;
    }

     
    function withdrawProxy(address from) public onlyCroupier returns(bool) {        
        uint256 amount = balanceOf(from);
        _withdraw(from, amount);
        return true;
    }

     
    function _deposit(address from, uint256 value) internal {
        require(from != address(0), "Invalid address.");

        _balances[from] = _balances[from].add(value);
        _totalBalance = _totalBalance.add(value);
        emit Deposit(from, value);
    }

     
    function _withdraw(address from, uint256 value) internal {
        require(from != address(0), "Invalid address.");
        require(value <= _balances[from].sub(_locked[from]), "Not enough balance.");

        _balances[from] = _balances[from].sub(value);
        _totalBalance = _totalBalance.sub(value);        
        
        uint256 fee = value.mul(feeRatio).div(THIS_DIVISOR);
        require(value.sub(fee) <= address(this).balance, "Can't afford.");
        from.transfer(value.sub(fee));
        
        emit Withdraw(from, value);
    }

     
    function _safeTypeConversion(uint256 a, uint128 b) internal pure returns(bool) {
        require(a == uint256(b) && uint128(a) == b, "Not safe type conversion.");
        return true;
    }

     
    function _dealCore(address gambler, uint256 commit, uint128 amount, uint8 cutCard) internal {
         
        Bet storage bet = bets[commit];
        require(bet.gambler == address(0), "Bet should be in 'clean' state.");

         
        require(cutCard <= MAX_CUT_CARD, "Cut card position is not valid.");
    
         
        uint256 value = uint256(amount);
        require(_safeTypeConversion(value, amount), "Not safe type conversion");

        require(value >= minBet && value <= maxBet, "Bet amount is out of range.");

        uint256 lockValue = value.mul(LOCK_RATIO).div(THIS_DIVISOR);        
        require(lockValue <= balanceOf(gambler).sub(lockedOf(gambler)), "Balance is not enough for locked.");

         
        _locked[gambler] = _locked[gambler].add(lockValue);

        bet.gambler = gambler;
        bet.cutCard = cutCard;
        bet.amount = amount;
        bet.dealBlockNumber = uint128(block.number);

        emit Deal(commit);        
    }

     
    function setMaxBet(uint256 input) public onlyOwner {
        maxBet = input;
    }

     
    function setMinBet(uint256 input) public onlyOwner {
        minBet = input;
    }

     
    function setFeeRatio(uint256 input) public onlyOwner {
        feeRatio = input;
    }

     
    function setExpireBlocks(uint256 input) public onlyOwner {
        expireBlocks = input;
    }

     
    function setStatedPeriod(uint256 input) public onlyOwner {
        statedPeriod = input;
    }

     
    function withdrawFunds(uint256 amount) public onlyOwner {
        require(amount <= address(this).balance.sub(_totalBalance), "Not enough funds.");
        msg.sender.transfer(amount);
    }

     
    function kill() public onlyOwner {
        require(_totalBalance == 0, "All of gambler's balances need to be withdrawn.");
        selfdestruct(msg.sender);
    }
}