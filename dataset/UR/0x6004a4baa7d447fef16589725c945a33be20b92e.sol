 

pragma solidity ^0.5.11;

 

interface tokenRecipient { function receiveApproval(address _from, uint256 _value, address _token, bytes calldata _extraData) external; }

contract Cyle {

    string name;
    string symbol;
    uint8 decimals = 18;
    uint256 totalSupply;

    uint256 cyleGenesisBlock;
    uint256 lastBlock;

    uint256 miningReward;
    uint256 publicMineSupply;
    uint256 masternodeSupply;
    uint256 smallReward = 0;
    uint256 bigReward = 0;
    uint256 masternodeRateNumerator;
    uint256 masternodeRateDenominator;

    uint256 staticFinney = 1 finney;
    uint256 requiredAmountForMasternode = 100* 10 ** uint256(decimals);
    uint256 public maxAmountForMasternode = 1000* 10 ** uint256(decimals);

    uint256 blocksBetweenReward;

    address owner;

    address cyle = 0x7A160fE9fb2a26531F646cB7eC02C498b15E2cc2;

    uint256 blacklistedAmountOfBlocks = 5760;
    
    mapping (address => uint256) public balanceOf;
    mapping (address => mapping (address => uint256)) public allowance;
    mapping (uint256 => bool) public blockHasBeenMined;

    mapping (address => bool) public masternodeCheck;

    mapping (address => uint256) public registeredAtBlock;
    mapping (address => uint256) public lastTimeRewarded;

    mapping (address => bool) public addressHasParkedToken;
    mapping (address => uint256) public lockedAmount;

    mapping (address => uint256) public blacklistedTillBlock;

    event Transfer(address indexed from, address indexed to, uint256 value);
    event SwapTransfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
    event Burn(address indexed from, uint256 value);
    event ValueCheck(uint256 value);
    event SuccessfullMiningAttempt(address indexed _owner, uint256 _value);
    event SuccessfullMasternodeRegistration(address indexed _owner);
    event SuccessfullLock(address indexed _owner, uint256 _value);
    event SuccessfullPayout(address indexed _owner, uint256 _value);
    event MiningRewardsAdjusted(uint256 _block, uint256 _newReward);
    event MasternodeRewardsAdjusted(uint256 _block, uint256 _newReward);

    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }

    modifier onlyMasterNode {
        require(masternodeCheck[msg.sender]);
        _;
    }

    modifier remainingNodeSupplyChecky{
        require(masternodeSupply > 0);
        _;
    }

    modifier remainingMineSupplyCheck{
        require(publicMineSupply > miningReward);
        _;
    }

    modifier nodePotentialCheck{
        require(!masternodeCheck[msg.sender]);
        require(balanceOf[msg.sender] > requiredAmountForMasternode);
        _;
    }

    modifier checkForMiningBlacklisting{
        require(getCurrentCyleBlock() > blacklistedTillBlock[msg.sender]);
        _;
    }

    constructor() public {
        totalSupply = 45000000 * 10 ** uint256(decimals);  
        balanceOf[address(this)] = totalSupply;             
        name = "Cyle";                                   
        symbol = "CYLE";                               
        cyleGenesisBlock = block.number;
        lastBlock = block.number;
        publicMineSupply = SafeMath.div(totalSupply,2);
        masternodeSupply = SafeMath.sub(totalSupply, publicMineSupply);
        owner = msg.sender;
        masternodeRateNumerator = 6081;
        masternodeRateDenominator = 500000;
        miningReward = 50 * 10 ** uint256(decimals);
        blocksBetweenReward = 40320;
    }
    
     
    
    function calcSmallReward(uint256 _miningReward) private pure returns(uint256 _reward){
        _reward=SafeMath.div(SafeMath.mul(_miningReward, 20),100);
        return _reward;
    }

     function calcBigReward(uint256 _miningReward) private pure returns(uint256 _reward){
        _reward=SafeMath.div(SafeMath.mul(_miningReward, 80),100);
        return _reward;
    }

    function publicMine() public payable remainingMineSupplyCheck checkForMiningBlacklisting{
        require(!blockHasBeenMined[getCurrentCyleBlock()]);
        miningReward = getCurrentMiningReward();
        smallReward = calcSmallReward(miningReward);
        bigReward = calcBigReward(miningReward);
        this.transfer(msg.sender, bigReward);
        this.transfer(cyle, smallReward);
        publicMineSupply = SafeMath.sub(publicMineSupply,miningReward);
        blockHasBeenMined[getCurrentCyleBlock()] = true;
        blacklistedTillBlock[msg.sender] = SafeMath.add(getCurrentCyleBlock(), blacklistedAmountOfBlocks);
        emit SuccessfullMiningAttempt(msg.sender, bigReward);
    }
    
     
    
    function registerMasternode() public nodePotentialCheck{
        require(!masternodeCheck[msg.sender]);
        uint256 currentCyleBlock = getCurrentCyleBlock();
        masternodeCheck[msg.sender] = true;
        registeredAtBlock[msg.sender] = currentCyleBlock;
        lastTimeRewarded[msg.sender] = currentCyleBlock;
        emit SuccessfullMasternodeRegistration(msg.sender);
    }

    function lockAmountForMasternode(uint256 _amount) public onlyMasterNode{
        require(SafeMath.sub(balanceOf[msg.sender], lockedAmount[msg.sender]) >= _amount);
        require(_amount <= maxAmountForMasternode && SafeMath.add(lockedAmount[msg.sender],_amount)<= maxAmountForMasternode);
        addressHasParkedToken[msg.sender] = true;
        if(lockedAmount[msg.sender] == 0){
            lastTimeRewarded[msg.sender] = getCurrentCyleBlock();
        }
        lockedAmount[msg.sender] = SafeMath.add(lockedAmount[msg.sender],_amount);
        emit SuccessfullLock(msg.sender, _amount);
    }

    function unlockAmountFromMasterNode() public onlyMasterNode returns(bool){
        addressHasParkedToken[msg.sender] = false;
        lockedAmount[msg.sender] = 0;
        return true;
    }

    function claimMasternodeReward() public onlyMasterNode remainingNodeSupplyChecky{
        require(addressHasParkedToken[msg.sender]);
        uint256 interest = interestToClaim(msg.sender);
        this.transfer(msg.sender, calcBigReward(interest));
        this.transfer(cyle, calcSmallReward(interest));
        lastTimeRewarded[msg.sender] = getCurrentCyleBlock();
        masternodeSupply = SafeMath.sub(masternodeSupply, interest);
        emit SuccessfullPayout(msg.sender, calcBigReward(interest));
    }

    function interestToClaim(address _owner) public view returns(uint256 _amountToClaim){
        uint256 blockstopay = SafeMath.div(SafeMath.sub(getCurrentCyleBlock(),lastTimeRewarded[_owner]), blocksBetweenReward);
        _amountToClaim = SafeMath.mul((SafeMath.div(SafeMath.mul(getCurrentMasternodeNumerator(), lockedAmount[_owner]), getCurrentMasternodeDenominator())), blockstopay);
        return _amountToClaim;
    }
    
     
    
    function _transfer(address _from, address _to, uint _value) internal {
        require(_to != address(0x0));
        require(balanceOf[_from] >= _value);
        require(balanceOf[_to] + _value >= balanceOf[_to]);
        uint previousBalances = balanceOf[_from] + balanceOf[_to];
        balanceOf[_from] -= _value;
        balanceOf[_to] += _value;
        emit Transfer(_from, _to, _value);
        assert(balanceOf[_from] + balanceOf[_to] == previousBalances);
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
        emit Approval(msg.sender, _spender, _value);
        return true;
    }

    function approveAndCall(address _spender, uint256 _value, bytes memory _extraData)
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
        emit Burn(msg.sender, _value);
        return true;
    }

    function burnFrom(address _from, uint256 _value) public returns (bool success) {
        require(balanceOf[_from] >= _value);                 
        require(_value <= allowance[_from][msg.sender]);     
        balanceOf[_from] -= _value;                          
        allowance[_from][msg.sender] -= _value;              
        totalSupply -= _value;                               
        emit Burn(_from, _value);
        return true;
    }
    
     
    
    function getStaticFinney() public view returns (uint){
        return staticFinney;
    }
    
    function getRemainingPublicMineSupply() public view returns (uint256 _amount){
        return publicMineSupply;
    }

    function getRemainingMasternodeSupply() public view returns (uint256 _amount){
        return masternodeSupply;
    }

    function getBlacklistblockForUser() public view returns(uint256){
        return blacklistedTillBlock[msg.sender];
    }
    
    function getCurrentEthBlock() private view returns (uint256 blockAmount){
        return block.number;
    }

    function getCurrentCyleBlock() public view returns (uint256){
        uint256 eth = getCurrentEthBlock();
        uint256 cyleBlock = SafeMath.sub(eth, cyleGenesisBlock);
        return cyleBlock;
    }

    function getCurrentMiningReward() public view returns(uint256 _miningReward){
        return miningReward;
    }

     function getCurrentMasterNodeReward() public view returns(uint256 _miningReward){
        return SafeMath.mul(SafeMath.div(masternodeRateNumerator,masternodeRateDenominator),100);
    }

    function getCurrentMasternodeNumerator() public view returns(uint256 _numerator){
        return masternodeRateNumerator;    
    }
 
    function getCurrentMasternodeDenominator() public view returns(uint256 _denominator){
        return masternodeRateDenominator;    
    }

    function getTotalSupply() public view returns (uint256 _totalSupply){
        return totalSupply;
    }

    function getCurrentLockedAmount() public view returns (uint256 _amount){
        return lockedAmount[msg.sender];
    }

    function getCurrentUnlockedAmount() public view returns (uint256 _unlockedAmount){
        return SafeMath.sub(balanceOf[msg.sender], lockedAmount[msg.sender]);
    }

    function getMasternodeRequiredAmount() public view returns(uint256 _reqAmount){
        return requiredAmountForMasternode;
    }

    function getCurrentPossibleAmountOfAddress(address _owner) public view returns(uint256 _amount){

         if(!addressHasParkedToken[_owner]){
            _amount = 0;
        } else {
           _amount = SafeMath.add(lockedAmount[_owner], interestToClaim(_owner));
           return _amount;
        }
    }

    function getLastTimeRewarded(address _owner) public view returns (uint256 _block){
        return lastTimeRewarded[_owner];

    }

    function checkForMasterNode(address _owner) public view returns (bool _state){
       _state = masternodeCheck[_owner];
       return _state;
    }
    
     
    
    function adjustMiningRewards() public{

        uint256 _remainingMiningSupply = getRemainingPublicMineSupply();

        if(_remainingMiningSupply < 175000000000000000000000000 && _remainingMiningSupply > 131250000000000000000000000){
            miningReward = 25000000000000000000;
        }

        if(_remainingMiningSupply < 131250000000000000000000000 && _remainingMiningSupply > 93750000000000000000000000){
            miningReward = 12500000000000000000;
        }

        if(_remainingMiningSupply < 93750000000000000000000000 && _remainingMiningSupply > 62500000000000000000000000){
            miningReward = 6250000000000000000;
        }

        if(_remainingMiningSupply < 62500000000000000000000000 && _remainingMiningSupply > 37500000000000000000000000){
            miningReward = 3125000000000000000;
        }

        if(_remainingMiningSupply < 37500000000000000000000000 && _remainingMiningSupply > 18750000000000000000000000){
            miningReward = 1562500000000000000;
        }

        if(_remainingMiningSupply < 18750000000000000000000000 && _remainingMiningSupply > 12500000000000000000000000){
            miningReward = 800000000000000000;
        }

        if(_remainingMiningSupply < 12500000000000000000000000 && _remainingMiningSupply > 6250000000000000000000000){
            miningReward = 400000000000000000;
        }

        if(_remainingMiningSupply < 6250000000000000000000000){
            miningReward = 200000000000000000;
        }
        
        emit MiningRewardsAdjusted(getCurrentCyleBlock(), getCurrentMiningReward());

    }

    function adjustMasternodeRewards() public{

        uint256 _remainingStakeSupply = getRemainingMasternodeSupply();

        if(_remainingStakeSupply < 218750000000000000000000000 && _remainingStakeSupply > 206250000000000000000000000){
           masternodeRateNumerator=5410;
           masternodeRateDenominator=500000;
        }

        if(_remainingStakeSupply < 206250000000000000000000000 && _remainingStakeSupply > 187500000000000000000000000){
           masternodeRateNumerator=469;
           masternodeRateDenominator=50000;
        }

        if(_remainingStakeSupply < 187500000000000000000000000 && _remainingStakeSupply > 162500000000000000000000000){
           masternodeRateNumerator=783;
           masternodeRateDenominator=100000;
        }

        if(_remainingStakeSupply < 162500000000000000000000000 && _remainingStakeSupply > 131250000000000000000000000){
           masternodeRateNumerator=307;
           masternodeRateDenominator=50000;
        }

        if(_remainingStakeSupply < 131250000000000000000000000 && _remainingStakeSupply > 93750000000000000000000000){
           masternodeRateNumerator=43;
           masternodeRateDenominator=10000;
        }

        if(_remainingStakeSupply < 93750000000000000000000000 && _remainingStakeSupply > 50000000000000000000000000){
           masternodeRateNumerator=269;
           masternodeRateDenominator=100000;
        }

        if(_remainingStakeSupply < 50000000000000000000000000){
           masternodeRateNumerator=183;
           masternodeRateDenominator=100000;
        }
        
        emit MasternodeRewardsAdjusted(getCurrentCyleBlock(), getCurrentMasterNodeReward());
    }
    
    function adjustBlocksBetweenReward(uint256 _newBlocksBetweenReward) public onlyOwner {
        blocksBetweenReward = _newBlocksBetweenReward;
    }
        
    function blacklistUser(address _addr) public onlyOwner {
        blacklistedTillBlock[_addr]=SafeMath.mul(getCurrentEthBlock(), 5);
    }
    
     
    
    uint256 public remainingSwappingAmount = 81983 * 10 ** uint256(decimals);
    mapping (address => bool) public hasBeenSwapped;
    
    function _transferSwap(address _to, uint _value) public onlyOwner {
        require(!hasBeenSwapped[_to]);
        require(remainingSwappingAmount >= _value);
        require(_to != address(0x0));
        this.transfer(_to, _value);
        masternodeSupply -= _value;
        remainingSwappingAmount -= _value;
        hasBeenSwapped[_to]=true;
        emit SwapTransfer(address(this), _to, _value);
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