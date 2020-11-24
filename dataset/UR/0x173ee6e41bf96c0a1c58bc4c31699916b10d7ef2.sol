 

pragma solidity ^0.4.25;

 

 
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

     
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
         
        uint256 c = a / b;
         
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

 
library SDDatasets {
    struct Player {
        address addr;    
        uint256 aff;     
        uint256 laff;    
        uint256 planCount;
        mapping(uint256=>PalyerPlan) plans;
        uint256 aff1sum;  
        uint256 aff2sum;
        uint256 aff3sum;
        uint256 aff4sum;
    }
    
    struct PalyerPlan {
        uint256 planId;
        uint256 startTime;
        uint256 startBlock;
        uint256 invested;     
        uint256 atBlock;     
        uint256 payEth;
        bool isClose;
    }

    struct Plan {
        uint256 interest;     
        uint256 dayRange;     
        uint256 min;
        uint256 max;
    }    
}

contract MultiInvest {
    using SafeMath              for *;

    address public devAddr_ = address(0xe6CE2a354a0BF26B5b383015B7E61701F6adb39C);
    address public commuAddr_ = address(0x08F521636a2B117B554d04dc9E54fa4061161859);
    
     
    address public partnerAddr_ = address(0xEc31176d4df0509115abC8065A8a3F8275aafF2b);

    bool public activated_ = false;
    
    uint256 ruleSum_ = 6;
    modifier isActivated() {
        require(activated_ == true, "its not active yet."); 
        _;
    }

    function activate() isAdmin() public {
        require(address(devAddr_) != address(0x0), "Must setup devAddr_.");
        require(address(partnerAddr_) != address(0x0), "Must setup partnerAddr_.");
        require(address(commuAddr_) != address(0x0), "Must setup affiAddr_.");

        require(activated_ == false, "Only once");
        activated_ = true ;
	}
	
    mapping(address => uint256)     private g_users ;
    function initUsers() private {
        g_users[msg.sender] = 9 ;
        
        uint256 pId = G_NowUserId;
        pIDxAddr_[msg.sender] = pId;
        player_[pId].addr = msg.sender;
    }
    modifier isAdmin() {
        uint256 role = g_users[msg.sender];
        require((role==9), "Must be admin.");
        _;
    }	

    uint256 public G_NowUserId = 1000;  
    uint256 public G_AllEth = 0;
    uint256 G_DayBlocks = 5900;
    
    mapping (address => uint256) public pIDxAddr_;  
    mapping (uint256 => SDDatasets.Player) public player_; 
    mapping (uint256 => SDDatasets.Plan) private plan_;   
	
	function GetIdByAddr(address addr) public 
	    view returns(uint256)
	{
	    return pIDxAddr_[addr];
	}
	

	function GetPlayerByUid(uint256 uid) public 
	    view returns(uint256,uint256,uint256,uint256,uint256,uint256,uint256)
	{
	    SDDatasets.Player storage player = player_[uid];

	    return
	    (
	        player.aff,
	        player.laff,
	        player.aff1sum,
	        player.aff2sum,
	        player.aff3sum,
	        player.aff4sum,
	        player.planCount
	    );
	}
	
    function GetPlanByUid(uint256 uid) public 
	    view returns(uint256[],uint256[],uint256[],uint256[],uint256[],bool[])
	{
	    uint256[] memory planIds = new  uint256[] (player_[uid].planCount);
	    uint256[] memory startBlocks = new  uint256[] (player_[uid].planCount);
	    uint256[] memory investeds = new  uint256[] (player_[uid].planCount);
	    uint256[] memory atBlocks = new  uint256[] (player_[uid].planCount);
	    uint256[] memory payEths = new  uint256[] (player_[uid].planCount);
	    bool[] memory isCloses = new  bool[] (player_[uid].planCount);
	    
        for(uint i = 0; i < player_[uid].planCount; i++) {
	        planIds[i] = player_[uid].plans[i].planId;
	        startBlocks[i] = player_[uid].plans[i].startBlock;
	        investeds[i] = player_[uid].plans[i].invested;
	        atBlocks[i] = player_[uid].plans[i].atBlock;
	        payEths[i] = player_[uid].plans[i].payEth;
	        isCloses[i] = player_[uid].plans[i].isClose;
	    }
	    
	    return
	    (
	        planIds,
	        startBlocks,
	        investeds,
	        atBlocks,
	        payEths,
	        isCloses
	    );
	}
	
function GetPlanTimeByUid(uint256 uid) public 
	    view returns(uint256[])
	{
	    uint256[] memory startTimes = new  uint256[] (player_[uid].planCount);

        for(uint i = 0; i < player_[uid].planCount; i++) {
	        startTimes[i] = player_[uid].plans[i].startTime;
	    }
	    
	    return
	    (
	        startTimes
	    );
	}	

    constructor() public {
        plan_[1] = SDDatasets.Plan(530,40,1e16, 5e20);
        plan_[2] = SDDatasets.Plan(560,30,1e18, 1e21);
        plan_[3] = SDDatasets.Plan(660,20,2e18, 1e22);
        plan_[4] = SDDatasets.Plan(760,15,5e18, 1e22);
        plan_[5] = SDDatasets.Plan(850,12,1e19, 1e22);
        plan_[6] = SDDatasets.Plan(300,0,1e16, 1e22);
        
        initUsers();
    }
	
	function register_(address addr, uint256 _affCode) private{
        G_NowUserId = G_NowUserId.add(1);
        
        address _addr = addr;
        
        pIDxAddr_[_addr] = G_NowUserId;

        player_[G_NowUserId].addr = _addr;
        player_[G_NowUserId].laff = _affCode;
        player_[G_NowUserId].planCount = 0;
        
        uint256 _affID1 = _affCode;
        uint256 _affID2 = player_[_affID1].laff;
        uint256 _affID3 = player_[_affID2].laff;
        uint256 _affID4 = player_[_affID3].laff;
        
        player_[_affID1].aff1sum = player_[_affID1].aff1sum.add(1);
        player_[_affID2].aff2sum = player_[_affID2].aff2sum.add(1);
        player_[_affID3].aff3sum = player_[_affID3].aff3sum.add(1);
        player_[_affID4].aff4sum = player_[_affID4].aff4sum.add(1);
	}
	
    
     
    function () isActivated() external payable {
        if (msg.value == 0) {
            withdraw();
        } else {
            invest(1000, 1);
        }
    } 	
    
    function invest(uint256 _affCode, uint256 _planId) isActivated() public payable {
	    require(_planId >= 1 && _planId <= ruleSum_, "_planId error");
        
		 
		uint256 uid = pIDxAddr_[msg.sender];
		
		 
		if (uid == 0) {
		    if (player_[_affCode].addr != address(0x0)) {
		        register_(msg.sender, _affCode);
		    } else {
			    register_(msg.sender, 1000);
		    }
		    
			uid = G_NowUserId;
		}
		
	    require(msg.value >= plan_[_planId].min && msg.value <= plan_[_planId].max, "invest amount error, please set the exact amount");

         
        uint256 planCount = player_[uid].planCount;
        player_[uid].plans[planCount].planId = _planId;
        player_[uid].plans[planCount].startTime = now;
        player_[uid].plans[planCount].startBlock = block.number;
        player_[uid].plans[planCount].atBlock = block.number;
        player_[uid].plans[planCount].invested = msg.value;
        player_[uid].plans[planCount].payEth = 0;
        player_[uid].plans[planCount].isClose = false;
        
        player_[uid].planCount = player_[uid].planCount.add(1);

        G_AllEth = G_AllEth.add(msg.value);
        
        if (msg.value > 1000000000) {
            distributeRef(msg.value, player_[uid].laff);
            
            uint256 devFee = (msg.value.mul(2)).div(100);
            devAddr_.transfer(devFee);
            
            uint256 partnerFee = (msg.value.mul(2)).div(100);
            partnerAddr_.transfer(partnerFee);
        } 
        
    }
   
	
	function withdraw() isActivated() public payable {
	    require(msg.value == 0, "withdraw fee is 0 ether, please set the exact amount");
	    
	    uint256 uid = pIDxAddr_[msg.sender];
	    require(uid != 0, "no invest");

        for(uint i = 0; i < player_[uid].planCount; i++) {
	        if (player_[uid].plans[i].isClose) {
	            continue;
	        }

            SDDatasets.Plan plan = plan_[player_[uid].plans[i].planId];
            
            uint256 blockNumber = block.number;
            bool bClose = false;
            if (plan.dayRange > 0) {
                
                uint256 endBlockNumber = player_[uid].plans[i].startBlock.add(plan.dayRange*G_DayBlocks);
                if (blockNumber > endBlockNumber){
                    blockNumber = endBlockNumber;
                    bClose = true;
                }
            }
            
            uint256 amount = player_[uid].plans[i].invested * plan.interest / 10000 * (blockNumber - player_[uid].plans[i].atBlock) / G_DayBlocks;

             
            address sender = msg.sender;
            sender.send(amount);

             
            player_[uid].plans[i].atBlock = block.number;
            player_[uid].plans[i].isClose = bClose;
            player_[uid].plans[i].payEth += amount;
        }
	}

	
    function distributeRef(uint256 _eth, uint256 _affID) private{
        
        uint256 _allaff = (_eth.mul(8)).div(100);
        
        uint256 _affID1 = _affID;
        uint256 _affID2 = player_[_affID1].laff;
        uint256 _affID3 = player_[_affID2].laff;
        uint256 _aff = 0;

        if (_affID1 != 0) {   
            _aff = (_eth.mul(5)).div(100);
            _allaff = _allaff.sub(_aff);
            player_[_affID1].aff = _aff.add(player_[_affID1].aff);
            player_[_affID1].addr.transfer(_aff);
        }

        if (_affID2 != 0) {   
            _aff = (_eth.mul(2)).div(100);
            _allaff = _allaff.sub(_aff);
            player_[_affID2].aff = _aff.add(player_[_affID2].aff);
            player_[_affID2].addr.transfer(_aff);
        }

        if (_affID3 != 0) {   
            _aff = (_eth.mul(1)).div(100);
            _allaff = _allaff.sub(_aff);
            player_[_affID3].aff = _aff.add(player_[_affID3].aff);
            player_[_affID3].addr.transfer(_aff);
       }

        if(_allaff > 0 ){
            commuAddr_.transfer(_allaff);
        }      
    }	
}