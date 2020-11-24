 

pragma solidity ^0.4.24;

 

contract vsgame {
	using SafeMath for uint256;

	 
    string public name = "FishvsFish Game";
    string public symbol = "FvF";
    
    uint256 public minFee;
    uint256 public maxFee;
    uint256 public jackpotDistribution;
    uint256 public refComm;
    uint256 public durationRound;
    uint256 public devFeeRef;
    uint256 public devFee;


    bool public activated = false;
    
    address public developerAddr;
    
     
    uint256 public rId;

    mapping (address => Indatasets.Player) public player;
    mapping (uint256 => Indatasets.Round) public round;
    mapping (uint256 => mapping (uint256 => mapping (address => uint256))) public playerAmountDeposit;
	mapping (uint256 => mapping (uint256 => mapping (address => uint256))) public playerAmountDepositReal;
	mapping (uint256 => mapping (uint256 => mapping (address => uint256))) public playerRoundAmount;


     

    constructor()
        public
    {
        developerAddr = msg.sender;
    }

     

    modifier senderVerify() {
        require (msg.sender == tx.origin);
        _;
    }

    modifier amountVerify() {
        if(msg.value < 10000000000000000){
            developerAddr.transfer(msg.value);
        }else{
            require(msg.value >= 10000000000000000);
            _;
        }
    }

    modifier playerVerify() {
        require(player[msg.sender].active == true, "Player isn't active.");
        _;
    }

    modifier isActivated() {
        require(activated == true, "Contract hasn't been activated yet."); 
        _;
    }


     
    function activate()
        public
    {
        require(msg.sender == developerAddr);
        require(activated == false, "Contract already activated");
        
		minFee = 5;
		maxFee = 50;
		jackpotDistribution = 70;
		refComm = 25;
		durationRound = 43200;
		rId = 1;
		activated = true;
        devFeeRef = 100;
        devFeeRef = devFeeRef.sub(jackpotDistribution).sub(refComm);
        devFee = 100;
        devFee = devFee.sub(jackpotDistribution);
    
		 

        round[rId].start = now;
        round[rId].end = now.add(172800);
        round[rId].ended = false;
        round[rId].winner = 0;
    }


     

    function invest(uint256 _side)
    	isActivated()
        amountVerify()
        senderVerify()
    	public
        payable
    {
    	uint256 _feeUser = 0;
    	if(_side == 1 || _side == 2){
    		if(now < round[rId].end){
    			_feeUser = buyFish(_side);

                round[rId].devFee = round[rId].devFee.add((_feeUser.mul(devFee)).div(100));
    		} else if(now >= round[rId].end){
    			startRound();
    			_feeUser = buyFish(_side);

                round[rId].devFee = round[rId].devFee.add((_feeUser.mul(devFee)).div(100));
    		}
    	} else {
    		msg.sender.transfer(msg.value);
    	}
    }

     

    function invest(uint256 _side, address _refer)
        isActivated()
        amountVerify()
        senderVerify()
        public
        payable
    {
        uint256 _feeUser = 0;
        if(_side == 1 || _side == 2){
            if(now < round[rId].end){
                _feeUser = buyFish(_side);
                processRef(_feeUser, _refer);
            } else if(now >= round[rId].end){
                startRound();
                _feeUser = buyFish(_side);
                processRef(_feeUser, _refer);
            }
        } else {
            msg.sender.transfer(msg.value);
        }
    }

     

    function buyFish(uint256 _side)
    	private
        returns (uint256)
    {
    	uint256 _rId = rId;
    	uint256 _amount = msg.value;

        if(player[msg.sender].active == false){
            player[msg.sender].active = true;
            player[msg.sender].withdrawRid = _rId;
        }

        uint256 _feeUser = (_amount.mul(getRoundFee())).div(1000000);
        uint256 _depositUser = _amount.sub(_feeUser);

    	playerAmountDeposit[_rId][_side][msg.sender] = playerAmountDeposit[_rId][_side][msg.sender].add(_depositUser);
    	playerAmountDepositReal[_rId][_side][msg.sender] = playerAmountDepositReal[_rId][_side][msg.sender].add(_amount);

    	if(_side == 1){
    		round[_rId].amount1 = round[_rId].amount1.add(_depositUser);
    		if(playerRoundAmount[_rId][1][msg.sender] == 0){
    			playerRoundAmount[_rId][1][msg.sender]++;
    			round[_rId].players1++;
    		}
    	} else if(_side == 2){
    		round[_rId].amount2 = round[_rId].amount2.add(_depositUser);
    		if(playerRoundAmount[_rId][2][msg.sender] == 0){
    			playerRoundAmount[_rId][2][msg.sender]++;
    			round[_rId].players2++;
    		}
    	}

    	 
    	round[_rId+1].jackpotAmount = round[_rId+1].jackpotAmount.add((_feeUser.mul(jackpotDistribution)).div(100));
        return _feeUser;
   	}

     

    function processRef(uint256 _feeUser, address _refer)
        private
    {
        if(_refer != 0x0000000000000000000000000000000000000000 && _refer != msg.sender && player[_refer].active == true){  
            player[_refer].refBalance = player[_refer].refBalance.add((_feeUser.mul(refComm)).div(100));
            round[rId].devFee = round[rId].devFee.add((_feeUser.mul(devFeeRef)).div(100));
        } else {
            round[rId].devFee = round[rId].devFee.add((_feeUser.mul(devFee)).div(100));
        }
    }

   	 

   	function startRound()
   		private
   	{
   		if(round[rId].amount1 > round[rId].amount2){
   			round[rId].winner = 1;
   		} else if(round[rId].amount1 < round[rId].amount2){
   			round[rId].winner = 2;
   		} else if(round[rId].amount1 == round[rId].amount2){
   			round[rId].winner = 3;
   		}

   		developerAddr.transfer(round[rId].devFee);
   		round[rId].ended = true;

   		rId++;

   		round[rId].start = now;
   		round[rId].end = now.add(durationRound);
   		round[rId].ended = false;
   		round[rId].winner = 0;
   	}

     


   	function getPlayerBalance(address _player)
   		public
   		view
   		returns(uint256)
   	{
   		uint256 userWithdrawRId = player[_player].withdrawRid;
   		uint256 potAmount = 0;
   		uint256 userSharePercent = 0;
   		uint256 userSharePot = 0;
   		uint256 userDeposit = 0;

   		uint256 userBalance = 0;

   		for(uint256 i = userWithdrawRId; i < rId; i++){
   			if(round[i].ended == true){
                potAmount = round[i].amount1.add(round[i].amount2).add(round[i].jackpotAmount);
   				if(round[i].winner == 1 && playerAmountDeposit[i][1][_player] > 0){
   					userSharePercent = playerAmountDeposit[i][1][_player].mul(1000000).div(round[i].amount1);
   				} else if(round[i].winner == 2 && playerAmountDeposit[i][2][_player] > 0){
   					userSharePercent = playerAmountDeposit[i][2][_player].mul(1000000).div(round[i].amount2);
                } else if(round[i].winner == 3){
   					if(playerAmountDeposit[i][1][_player] > 0 || playerAmountDeposit[i][2][_player] > 0){
   						userDeposit = playerAmountDeposit[i][1][_player].add(playerAmountDeposit[i][2][_player]);
   						userBalance = userBalance.add(userDeposit);
   					}
   				}
                if(round[i].winner == 1 || round[i].winner == 2){
                    userSharePot = potAmount.mul(userSharePercent).div(1000000);
                    userBalance = userBalance.add(userSharePot);
                    userSharePercent = 0;
                }
   			}
   		}
   		return userBalance;
   	}

   	 

   	function getRefBalance(address _player)
   		public
   		view
   		returns (uint256)
   	{
   		return player[_player].refBalance;
   	}

   	 

   	function withdraw()
        senderVerify()
        playerVerify()
        public
    {
        require(getRefBalance(msg.sender) > 0 || getPlayerBalance(msg.sender) > 0);

    	address playerAddress = msg.sender;
    	uint256 withdrawAmount = 0;
    	if(getRefBalance(playerAddress) > 0){
    		withdrawAmount = withdrawAmount.add(getRefBalance(playerAddress));
    		player[playerAddress].refBalance = 0;
    	}

    	if(getPlayerBalance(playerAddress) > 0){
    		withdrawAmount = withdrawAmount.add(getPlayerBalance(playerAddress));
    		player[playerAddress].withdrawRid = rId;
    	}
    	playerAddress.transfer(withdrawAmount);
    }

     

    function getPlayerInfo(address _player)
    	public
    	view
    	returns (bool, uint256, uint256, uint256)
    {
    	return (player[_player].active, getPlayerBalance(_player), player[_player].refBalance, player[_player].withdrawRid);
    }

     

    function getRoundInfo(uint256 _rId)
    	public
    	view
    	returns (uint256, uint256, bool, uint256, uint256, uint256, uint256, uint256, uint256, uint256)
    {
    	uint256 roundNum = _rId; 
    	return (round[roundNum].start, round[roundNum].end, round[roundNum].ended, round[roundNum].amount1, round[roundNum].amount2, round[roundNum].players1, round[roundNum].players2, round[roundNum].jackpotAmount, round[roundNum].devFee, round[roundNum].winner);
    }

      

    function getUserDeposit(uint256 _rId, uint256 _side, address _player)
    	public
    	view
    	returns (uint256)
    {
    	return playerAmountDeposit[_rId][_side][_player];
    }


      

    function getUserDepositReal(uint256 _rId, uint256 _side, address _player)
    	public
    	view
    	returns (uint256)
    {
    	return playerAmountDepositReal[_rId][_side][_player];
    }

     


    function getRoundFee()
        public
        view
        returns (uint256)
    {
        uint256 roundStart = round[rId].start;
        uint256 _durationRound = 0;

        if(rId == 1){
        	_durationRound = 172800;
        } else {
        	_durationRound = durationRound;
        }

        uint256 remainingTimeInv = now - roundStart;
        uint256 percentTime = (remainingTimeInv * 10000) / _durationRound;
        uint256 feeRound = ((maxFee - minFee) * percentTime) + (minFee * 10000);

        return feeRound;
    }
}

library Indatasets {

	struct Player {
		bool active;			 
		uint256 refBalance; 	 
		uint256 withdrawRid;	 
	}
    
    struct Round {
        uint256 start;           
        uint256 end;             
        bool ended;              
        uint256 amount1;         
        uint256 amount2;         
        uint256 players1;		 
        uint256 players2;		 
        uint256 jackpotAmount;   
        uint256 devFee;			 
        uint256 winner; 		 
    }
}

 
library SafeMath {
    
     
    function add(uint256 a, uint256 b) 
        internal 
        pure 
        returns (uint256) 
    {
        uint256 c = a + b;
        assert(c >= a);
        return c;
    }
    
     
    function sub(uint256 a, uint256 b) 
        internal 
        pure 
        returns (uint256) 
    {
        assert(b <= a);
        return a - b;
    }

     
    function mul(uint256 a, uint256 b) 
        internal 
        pure 
        returns (uint256) 
    {
        if (a == 0) {
            return 0;
        }
        uint256 c = a * b;
        assert(c / a == b);
        return c;
    }
    
     
    function div(uint256 a, uint256 b) 
        internal 
        pure 
        returns (uint256) 
    {
        assert(b > 0);  
        uint256 c = a / b;
        assert(a == b * c + a % b);  
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