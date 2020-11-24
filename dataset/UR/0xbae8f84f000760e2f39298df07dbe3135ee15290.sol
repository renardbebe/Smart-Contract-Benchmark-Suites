 

pragma solidity ^0.5.0;

 
 
 
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

 
interface IERC20 {
     
    function totalSupply() external view returns (uint256);

     
    function balanceOf(address account) external view returns (uint256);

     
    function transfer(address recipient, uint256 amount) external returns (bool);

     
    function allowance(address owner, address spender) external view returns (uint256);

     
    function approve(address spender, uint256 amount) external returns (bool);

     
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

     
    event Transfer(address indexed from, address indexed to, uint256 value);

     
    event Approval(address indexed owner, address indexed spender, uint256 value);
}
 
contract Owned {
    constructor() public { owner = msg.sender; }
    address payable owner;

     
     
     
     
     
     
     
    modifier onlyOwner {
        require(
            msg.sender == owner,
            "Only owner can call this function."
        );
        _;
    }
}

 
 
interface HEX{
	
	 
	
    struct XfLobbyEntryStore {
        uint96 rawAmount;
        address referrerAddr;
    }
	
    struct XfLobbyQueueStore {
        uint40 headIndex;
        uint40 tailIndex;
        mapping(uint256 => XfLobbyEntryStore) entries;
    }
	
	function xfLobbyMembers(uint256 i, address _XfLobbyQueueStore) external view returns(uint40 headIndex, uint40 tailIndex);
	function xfLobbyEnter(address referrerAddr) external payable;
	function currentDay() external view returns (uint256);
	function xfLobbyExit(uint256 enterDay, uint256 count) external;
	
	
	 
	 
	
     
    function totalSupply() external view returns (uint256);

     
    function balanceOf(address account) external view returns (uint256);

     
    function transfer(address recipient, uint256 amount) external returns (bool);

     
    function allowance(address owner, address spender) external view returns (uint256);

     
    function approve(address spender, uint256 amount) external returns (bool);

     
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

     
    event Transfer(address indexed from, address indexed to, uint256 value);

     
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

 
 
interface ERC20Distributor{
    function distributeTokens() external;
}

 

contract HEXAutomator is Owned{
	HEX public HEXcontract = HEX(0x2b591e99afE9f32eAA6214f7B7629768c40Eeb39);
	ERC20Distributor public Distributor;
	
	uint256[] public openLobbyDays;
	
	bool public autoDistribution = true;
	uint256 public distributionWeekday = 5; 
	uint256 public distributionCycle = 1;
	uint256 public distributionCycleCounter = 0;
		
	constructor(ERC20Distributor _distAddr) public {
        Distributor = ERC20Distributor(_distAddr);
    }
	
	function () payable external{
		require(msg.value > 0);
		
		 
		HEXcontract.xfLobbyEnter.value(msg.value)(address(this));
		openLobbyDays.push(hexCurrentDay());
		
		 
		selfLobbyExitAll();
		
		 
		withdrawHEXToDistributor();
		
		 
		checkAutoDistribution();
	}
	
	 
	function hexCurrentDay() public view 
		returns(uint256 currentDay){
		return HEXcontract.currentDay();
	}
	
	 
	function selfLobbyExitAll() public {
		for(uint i = 0; i < openLobbyDays.length; i++)
		{
			if(openLobbyDays[i] < hexCurrentDay()){
				if(selfLobbyExit(openLobbyDays[i], 0)){
					if(i < openLobbyDays.length - 1){
						openLobbyDays[i] = openLobbyDays[openLobbyDays.length - 1];
					}
					delete openLobbyDays[openLobbyDays.length - 1];
					openLobbyDays.length--;
				}
			}
		}
	}
	
	 
	 
	function selfLobbyExit(uint256 _enterDay, uint256 _count) public returns(bool){
		require(_enterDay < hexCurrentDay());
		
		(uint40 HEX_headIndex, uint40 HEX_tailIndex) = 
			HEXcontract.xfLobbyMembers(_enterDay, address(this));
			
		if(HEX_tailIndex > 0 && HEX_headIndex < HEX_tailIndex){
			HEXcontract.xfLobbyExit(_enterDay, _count);
			distributionCycleCounter++;
			return true;
		} else {
			return false;
		}
	}
	
	 
	function withdrawHEXToDistributor() public {
		uint256 HEX_balance = HEXcontract.balanceOf(address(this));
		if(HEX_balance > 0){
			HEXcontract.transfer(address(Distributor), HEX_balance);
		}
	}
	
	 
	 
	function checkAutoDistribution() private {
		if(autoDistribution){
			if((distributionWeekday != 0 && (hexCurrentDay() + 7 - distributionWeekday) % 7 == 0) || 
				(distributionCycle != 0 && distributionCycleCounter >= distributionCycle)){
				if(HEXcontract.balanceOf(address(Distributor)) > 0){
					distributionCycleCounter = 0;
					Distributor.distributeTokens();
				}
			}
		}
	}
	
	 
	function changeDistributor(ERC20Distributor _distAddr) public onlyOwner{
        Distributor = ERC20Distributor(_distAddr);
	}
	
	 
	function switchAutoDistribution() public onlyOwner{
		if(autoDistribution){
			autoDistribution = false;
		} else {
			autoDistribution = true;
		}
	}
	
	 
	 
	function changeDistributionWeekday(int256 _weekday) public onlyOwner{
		require(_weekday >= -1, "_weekday must be between -1 to 6");
		require(_weekday <= 6, "_weekday must be between -1 to 6");
		if(_weekday >= 0){
			distributionWeekday = 5 + uint256(_weekday);
			 
			 
		} else {
			distributionWeekday = 0;
		}
	}
	
	 
	 
	function changeDistributionCycle(uint256 _cycle) public onlyOwner{
		require(_cycle < 350, "Can't go higher than 350 cycles/days");
		distributionCycle = _cycle;
	}
		
	 
	 
	function withdrawERC20(IERC20 _token) public onlyOwner {
		require(_token.balanceOf(address(this)) > 0, "no balance");
		require(address(_token) != address(HEXcontract), "can't withdraw HEX, must use distributor");
		_token.transfer(owner, _token.balanceOf(address(this)));
	}

	 
	 
	 
	function kill(bool _die) public onlyOwner {
		require(_die, "If you are sure, send me true for _die");
		selfdestruct(owner);
	}
}