 

pragma solidity ^0.4.24;

contract Pob{

   using SafeMath for *;

 
 
 
                                                                 	
	struct BetItem{
		uint256 id;
		uint256 betCount;
	}
	struct Player {
        address addr;    
        uint256 aff;     
		uint256 withdraw;
		uint256[] purchases;
		uint256 totalPosition;  
		uint256 affId;
    }
	struct Purchase{
		uint256 id;
		address fromAddress;
		uint256 amount;
		uint256 positionCount;
		uint256 betItemId;
	}
	
 
 
 
	event EndTx(address buyer, uint256 _eth, uint256 _positionCount);
	
 
 
 
	uint256 constant private MIN_BET = 0.1 ether;  
	uint256 constant private VOTE_AMOUNT = 0.05 ether;  
	uint256 constant private ITEM_COUNT = 16;  
	uint256 constant private MAX_POSITION_PER_PLAYER = 3000;  
    uint256 constant private PRIZE_WAIT_TIME = 48 hours;      
															  
	address constant private DEV_ADDRESS = 0x6472B7931CB311907Df9229BcB3b3f3E2F413c9C;  

	address private owner;
	uint256 private BET_END_TIME = 1538870400;  
	uint256 private PRIZE_END_TIME;

	uint256 private lastSumary;

	uint256 private purchase_id;  
	uint256 private aff_id = 100;
	uint256 public winner_pool_amount;
	uint256 public buyer_profit_pool_amount;
	uint256 public vote_reward_pool_amount; 
	uint256 private result_vote_count;
	
    mapping (uint256 => BetItem) public betItems;      
    mapping (uint256 => Purchase) public purchases;      
    mapping (address => Player) public players;      
	mapping (uint256 => address) public aff_to_players;  
	
    mapping (uint256 => uint256) public keyNumberToValue;      
															   
    mapping (address => uint256) public resultVotes;      
    mapping (uint256 => uint256) public resultVoteCounts;      


	constructor() 
		public
	{
		 
		setPrizeEndTime();
		for(uint i=1;i<=ITEM_COUNT;i++){
			betItems[i].id=i;
		}
		owner = msg.sender;
	}
	function setPrizeEndTime()
		private
	{
		PRIZE_END_TIME = BET_END_TIME + PRIZE_WAIT_TIME;
	}
	
	function buyPosition(uint256 _aff_id,uint256 betItemId)
		isNotFinished()
        isHuman()
        isWithinLimits(msg.value)
		isValidItem(betItemId)
		public
        payable
	{
		
		uint positionCount = uint(msg.value/MIN_BET);	
		
		require(positionCount>0);
		
		uint256 _totalPositionCount = players[msg.sender].totalPosition+positionCount;
		require(_totalPositionCount<=MAX_POSITION_PER_PLAYER);
		
		purchase_id = purchase_id.add(positionCount);

		
		uint256 eth = positionCount.mul(MIN_BET);
		
		purchases[purchase_id].id = purchase_id;
		purchases[purchase_id].fromAddress = msg.sender;
		purchases[purchase_id].amount = eth;
		purchases[purchase_id].betItemId = betItemId;
		purchases[purchase_id].positionCount=positionCount;
		
		betItems[betItemId].betCount = betItems[betItemId].betCount.add(positionCount);
		
		players[msg.sender].purchases.push(purchase_id);
		players[msg.sender].totalPosition = _totalPositionCount;
		if(players[msg.sender].affId==0){
			 
			players[msg.sender].affId = aff_id;
			aff_to_players[players[msg.sender].affId] = msg.sender;
			aff_id = aff_id+1;
		}
		
		 
		uint256 affAmount = eth/10;
		addToAffiliate(_aff_id,affAmount);
		
		 
		players[DEV_ADDRESS].aff = players[DEV_ADDRESS].aff.add(eth/50);
		
		 
		winner_pool_amount=winner_pool_amount.add(eth/2);
		
		 
		buyer_profit_pool_amount = buyer_profit_pool_amount.add(eth.mul(33)/100);
		updateProfit(positionCount);
		
		 
		vote_reward_pool_amount = vote_reward_pool_amount.add(eth/20);		
			
		emit EndTx(msg.sender,msg.value,positionCount);
	}
	
	function updateProfit(uint _positionCount) 
		private
	{
		require(purchase_id>0);
		uint _lastSumary = lastSumary;
		for(uint i=0;i<_positionCount;i++){
			uint256 _purchase_id = purchase_id.sub(i);
			if(_purchase_id!=0){
				_lastSumary = _lastSumary.add(calculatePositionProfit(_purchase_id));
			}
		}
		lastSumary = _lastSumary;
		keyNumberToValue[purchase_id] = lastSumary;		
	}
	
	function calculatePositionProfit(uint256 currentPurchasedId) 
		public 
		pure 
		returns (uint256)
	{
		if(currentPurchasedId==0)return 0;
		return MIN_BET.mul(33)/100/(currentPurchasedId);
	}
	
	function addToAffiliate(uint256 _aff_id,uint256 affAmount) private{
		address _aff_address = aff_to_players[_aff_id];
		if(_aff_address!= address(0) && _aff_address!=msg.sender){
			players[_aff_address].aff = players[_aff_address].aff.add(affAmount);
		}else{
			winner_pool_amount=winner_pool_amount.add(affAmount);
		}
	}
	
	function getPlayerProfit(address _player)
		public 
		view 
		returns (uint256,uint256,uint256,uint256)
	{
		uint256 _profit = 0;
		for(uint256 i = 0 ;i<players[_player].purchases.length;i++){
			_profit = _profit.add(getProfit(players[_player].purchases[i]));
		}
		
		uint256 _winning_number = getWinningNumber();

		uint256 _player_winning = getPlayerWinning(_player,_winning_number);
		uint256 _player_vote_rewards = getPlayerVoteRewards(_player,_winning_number);
		
		return (_profit,players[_player].aff,_player_winning,_player_vote_rewards);
	}
	
	function getPlayerEarning(address _player)
		public 
		view 
		returns (uint256)
	{
		(uint256 _profit, uint256 _aff, uint256 _winning, uint256 _vote_rewards) = getPlayerProfit(_player);
		return _profit.add(_aff).add(_winning).add(_vote_rewards);
	}
	
	
	function getPlayerWinning(address _player,uint256 _winning_number) 
		public 
		view 
		returns (uint256)
	{
		uint256 _winning = 0;
		if(_winning_number==0){
			return 0;
		}
		uint256 _winningCount=0;
		for(uint256 i = 0 ;i<players[_player].purchases.length;i++){
			if(purchases[players[_player].purchases[i]].betItemId==_winning_number){
				_winningCount=_winningCount.add(purchases[players[_player].purchases[i]].positionCount);
			}
		}
		if(_winningCount>0){
			_winning= _winningCount.mul(winner_pool_amount)/(betItems[_winning_number].betCount);
		}
		
		return _winning;
	}
	
	function getPlayerVoteRewards(address _player,uint256 _winning_number) 
		public 
		view 
		returns (uint256)
	{
		if(_winning_number==0){
			return 0;
		}
		if(resultVotes[_player]==0){
			return 0;
		}
		 
		if(resultVotes[_player]!=_winning_number){
			return 0;
		}
		
		uint256 _correct_vote_count = resultVoteCounts[_winning_number];
		require(_correct_vote_count>0);
		
		return vote_reward_pool_amount/_correct_vote_count;
	}
	
	function getProfit(uint256 currentpurchase_id)
		public 
		view 
		returns (uint256)
	{
		uint256 _positionCount= purchases[currentpurchase_id].positionCount;
		if(_positionCount==0) return 0;
		uint256 _currentPositionProfit=calculatePositionProfit(currentpurchase_id);
		uint256 currentPositionSum = keyNumberToValue[currentpurchase_id];
		uint256 _profit = _currentPositionProfit.add(keyNumberToValue[purchase_id].sub(currentPositionSum));
		for(uint256 i=1;i<_positionCount;i++){
			currentPositionSum  = currentPositionSum.sub(_currentPositionProfit);
			_currentPositionProfit = calculatePositionProfit(currentpurchase_id.sub(i));
			_profit = _profit.add(keyNumberToValue[purchase_id].sub(currentPositionSum)).add(_currentPositionProfit);
		}
		return _profit;
	}
	
	function getSystemInfo() 
		public 
		view 
		returns(uint256, uint256, uint256, uint256,uint256)
	{
		return (winner_pool_amount,buyer_profit_pool_amount,vote_reward_pool_amount,BET_END_TIME
		,purchase_id);
	}
	
	function getSingleBetItemCount(uint256 _betItemId)
		public 
		view
		returns (uint256)
	{
		return betItems[_betItemId].betCount;
	}
	
	function getBetItemCount() 
		public 
		view 
		returns (uint256[ITEM_COUNT])
	{
		uint256[ITEM_COUNT] memory itemCounts;
		for(uint i=0;i<ITEM_COUNT;i++){
			itemCounts[i]=(betItems[i+1].betCount);
		}
		return itemCounts;
	}
	
	function getPlayerInfo(address player) 
		public 
		view 
		returns (uint256,uint256,uint256[],uint256,uint256)
	{
		return (players[player].aff,players[player].withdraw,players[player].purchases,players[player].totalPosition,players[player].affId);
	}
	
	function withdraw()        
		isHuman()
        public
	{
		address _player = msg.sender;
		uint256 _earning = getPlayerEarning(_player);
		
		uint256 _leftEarning = _earning.sub(players[_player].withdraw);
		 
		require(_leftEarning>0);
		
		if(_leftEarning>0){
			players[_player].withdraw = players[_player].withdraw.add(_leftEarning);
			_player.transfer(_leftEarning);
		}
	}
	
	 
	 
	function setBetEndTime(uint256 _newBetEndTime) 
		isOwner()
		public
	{
		BET_END_TIME = _newBetEndTime;
		setPrizeEndTime();
	}
	
	function voteToResult(uint256 betItemId)
		isNotEnded()
        isHuman()
		isValidItem(betItemId)
		public
        payable
	{
		
		require(msg.value == VOTE_AMOUNT);
		
		require(resultVotes[msg.sender]==0, "only allow vote once");
		
		vote_reward_pool_amount = vote_reward_pool_amount.add(VOTE_AMOUNT);
		result_vote_count = result_vote_count.add(1);
		resultVotes[msg.sender] = betItemId;
		resultVoteCounts[betItemId] = resultVoteCounts[betItemId].add(1);
	}
	
	function getWinningNumber() 
		public 
		view 
		returns (uint256)
	{
		 
		if(now < PRIZE_END_TIME){
			return 0;
		}
		uint256 _winningNumber = 0;
		uint256 _max_vote_count=0;
		for(uint256 i=1;i< ITEM_COUNT ; i++){
			if(_max_vote_count<resultVoteCounts[i]){
				_winningNumber = i;
				_max_vote_count = resultVoteCounts[i];
			}
		}
		return _winningNumber;
	}
	
    modifier isNotFinished() {
        require(now < BET_END_TIME, "The voting has finished."); 
        _;
    }
	
	modifier isValidItem(uint256 _itemId) {
        require(_itemId > 0, "Invalid item id"); 
		require(_itemId <= ITEM_COUNT, "Invalid item id"); 
        _;
    }
	
    modifier isNotEnded() {
        require(now < PRIZE_END_TIME, "The contract has finished."); 
        _;
    }
    modifier isHuman() {
        address _addr = msg.sender;
        uint256 _codeLength;
        
        assembly {_codeLength := extcodesize(_addr)}
        require(_codeLength == 0, "human only");
        _;
    }

     
    modifier isWithinLimits(uint256 _eth) {
        require(_eth >= MIN_BET, "has to be greater than min bet");
        require(_eth <= 100000000000000000000000, "too much");
        _;
    }
	
	modifier isOwner() {
		require(msg.sender == owner) ;
		_;
	}
}
 
library SafeMath {
    
     
    function mul(uint256 a, uint256 b) 
        internal 
        pure 
        returns (uint256 c) 
    {
        if (a == 0) {
            return 0;
        }
        c = a * b;
        require(c / a == b, "SafeMath mul failed");
        return c;
    }

     
    function sub(uint256 a, uint256 b)
        internal
        pure
        returns (uint256) 
    {
        require(b <= a, "SafeMath sub failed");
        return a - b;
    }

     
    function add(uint256 a, uint256 b)
        internal
        pure
        returns (uint256 c) 
    {
        c = a + b;
        require(c >= a, "SafeMath add failed");
        return c;
    }
    
     
    function sqrt(uint256 x)
        internal
        pure
        returns (uint256 y) 
    {
        uint256 z = ((add(x,1)) / 2);
        y = x;
        while (z < y) 
        {
            y = z;
            z = ((add((x / z),z)) / 2);
        }
    }
    
     
    function sq(uint256 x)
        internal
        pure
        returns (uint256)
    {
        return (mul(x,x));
    }
    
     
    function pwr(uint256 x, uint256 y)
        internal 
        pure 
        returns (uint256)
    {
        if (x==0)
            return (0);
        else if (y==0)
            return (1);
        else 
        {
            uint256 z = x;
            for (uint256 i=1; i < y; i++)
                z = mul(z,x);
            return (z);
        }
    }
}