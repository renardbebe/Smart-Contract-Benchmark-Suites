 

pragma solidity ^0.4.26;

contract  UtilEtherLevel  {

 uint ethWei = 1 ether;
     
    function getlevel(uint value) public view returns(uint){
        if(value >= 1 * ethWei && value <= 5 * ethWei){
            
            return 1;
            
        }if(value >= 6 * ethWei && value <= 10 * ethWei){
            
            return 2;
            
        }if(value >= 11 * ethWei && value <= 15 * ethWei){
            
            return 3;
            
        }
            return 0;
    }
     
    function getLineLevel(uint value) public view returns(uint){
        if(value >= 1 * ethWei && value <= 5 * ethWei){
            
            return 1;
            
        }if(value >= 6 * ethWei && value <= 10 * ethWei){
            
            return 2;
            
        }if(value >= 11 * ethWei){
            
            return 3;
        }
    }
    
     
    function getScBylevel(uint level) public pure returns(uint){
        if(level == 1){
            
            return 5;
            
        }if(level == 2){
            
            return 7;
            
        }if(level == 3) {
            
            return 10;
        }
        return 0;
    }
    
     
    function getFireScBylevel(uint level) public pure returns(uint){
        if(level == 1){
            
            return 3;
            
        }if(level == 2){
            
            return 6;
            
        }if(level == 3) {
            
            return 10;
            
        }return 0;
    }
    
     
    function getRecommendScaleBylevelandTim(uint level,uint times) public pure returns(uint){
        if(level == 1 && times == 1){ 
            
            return 50;
            
        }if(level == 2 && times == 1){
            
            return 70;
            
        }if(level == 2 && times == 2){
            
            return 50;
            
        }if(level == 3) {
            if(times == 1){
                
                return 100;
                
            }if(times == 2){
                
                return 80;
                
            }if(times == 3){
                
                return 60;
                
            }if(times >= 4 && times <= 10){
                
                return 10;
                
            }if(times >= 11 && times <= 20){
                
                return 5;
                
            }if(times >= 21){
                
                return 1;
                
            }
        } return 0;
    }
    
    
     function compareStr(string memory _str, string memory str) public pure returns(bool) {
        if (keccak256(abi.encodePacked(_str)) == keccak256(abi.encodePacked(str))) {
            return true;
        }
        return false;
    }
}
contract Etherhonor is UtilEtherLevel {

 

    uint ethWei = 1 ether;
    uint allCount = 0;
    uint oneDayCount = 0;
    uint totalMoney = 0;
    uint totalCount = 0;
	uint private beginTime = 1;
    uint lineCountTimes = 1;
	uint private currentIndex = 0;
	address private owner;
	uint private actStu = 0;

	constructor () public {
        owner = msg.sender;
    }
	struct User{

        address ethAddress;
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

    struct BonusGame{

        address ethAddress;
        uint inputAmount;
        uint resTime;
        string inviteCode;
        string beInvitedCode;
		uint isline;
		uint status;
		uint times;
    }

    mapping (address => User) userMapping;
    mapping (string => address) addressMapping;
    mapping (uint => address) indexMapping;

    BonusGame[] game;


    modifier onlyOwner {
        require (msg.sender == owner, "OnlyOwner methods called by non-owner.");
        _;
    }

    function () public payable {
    }

     function invest(address ethAddress ,uint inputAmount,string  inviteCode,string  beInvitedCode) public payable{

        ethAddress = msg.sender;
  		inputAmount = msg.value;
        uint lineAmount = inputAmount;

        if(!getUserByinviteCode(beInvitedCode)){
          
            require(getUserByinviteCode(beInvitedCode),"Code must exit");
        }
        if(inputAmount < 1 * ethWei || inputAmount > 15 * ethWei || compareStr(inviteCode,"")){
          
            require(inputAmount >= 1 * ethWei && inputAmount <= 15 * ethWei && !compareStr(inviteCode,""), "between 1 and 15");
        }
        User storage userTest = userMapping[ethAddress];
        if(userTest.isVaild && userTest.status != 2){
            if((userTest.lineAmount + userTest.freezeAmount + lineAmount)> (15 * ethWei)){
             
                require((userTest.lineAmount + userTest.freezeAmount + lineAmount) <= 15 * ethWei,"can not beyond 15 eth");
                return;
            }
        }
       totalMoney = totalMoney + inputAmount;
        totalCount = totalCount + 1;
        bool isLine = false;

        uint level =getlevel(inputAmount);
        uint lineLevel = getLineLevel(lineAmount);
        if(beginTime==1){
            
            lineAmount = 0;
            oneDayCount = oneDayCount + inputAmount;
            BonusGame memory invest = BonusGame(ethAddress,inputAmount,now, inviteCode, beInvitedCode ,1,1,0);
            game.push(invest);
            sendFeetoAdmin(inputAmount);
			sendFeetoLuckdraw(inputAmount);
			
        }else{
            
            allCount = allCount + inputAmount;
            isLine = true;
            invest = BonusGame(ethAddress,inputAmount,now, inviteCode, beInvitedCode ,0,1,0);
            inputAmount = 0;
            game.push(invest);
            
        }
          User memory user = userMapping[ethAddress];
            if(user.isVaild && user.status == 1){
                
                user.freezeAmount = user.freezeAmount + inputAmount;
                user.rechargeAmount = user.rechargeAmount + inputAmount;
                user.lineAmount = user.lineAmount + lineAmount;
                level =getlevel(user.freezeAmount);
                lineLevel = getLineLevel(user.freezeAmount + user.freeAmount +user.lineAmount);
                user.level = level;
                user.lineLevel = lineLevel;
                userMapping[ethAddress] = user;

            }else{
                if(isLine){
                    level = 0;
                }
                if(user.isVaild){
                    
                   inviteCode = user.inviteCode;
                   beInvitedCode = user.beInvitedCode;
                   
                }
                user = User(ethAddress,0,inputAmount,inputAmount,0,0,0,0,0,level,now,lineAmount,lineLevel,inviteCode, beInvitedCode ,1,1,true);
                userMapping[ethAddress] = user;

                indexMapping[currentIndex] = ethAddress;
                currentIndex = currentIndex + 1;
            }
            
            address  ethAddressCode = addressMapping[inviteCode];
            
            if(ethAddressCode == 0x0000000000000000000000000000000000000000){
                
                addressMapping[inviteCode] = ethAddress;
                
            }

    }

      function registerUserInfo(address ethAddress ,uint freezeAmount,string  inviteCode,string  beInvitedCode ,uint freeAmount,uint times) public {
          
        require(actStu == 0,"this action was closed");
        freezeAmount = freezeAmount * ethWei;
        freeAmount = freeAmount * ethWei;
        uint level =getlevel(freezeAmount);
        uint lineLevel = getLineLevel(freezeAmount + freeAmount);
        
        if(beginTime==1 && freezeAmount > 0){
            
            BonusGame memory invest = BonusGame(ethAddress,freezeAmount,now, inviteCode, beInvitedCode ,1,1,times);
            game.push(invest);
            
        }
          User memory user = userMapping[ethAddress];
            if(user.isVaild){
                
                user.freeAmount = user.freeAmount + freeAmount;
                user.freezeAmount = user.freezeAmount +  freezeAmount;
                user.rechargeAmount = user.rechargeAmount + freezeAmount +freezeAmount;
                user.level =getlevel(user.freezeAmount);
                user.lineLevel = getLineLevel(user.freezeAmount + user.freeAmount +user.lineAmount);
                userMapping[ethAddress] = user;
                
            }else{
                
                user = User(ethAddress,freeAmount,freezeAmount,freeAmount+freezeAmount,0,0,0,0,0,level,now,0,lineLevel,inviteCode, beInvitedCode ,1,1,true);
                userMapping[ethAddress] = user;

                indexMapping[currentIndex] = ethAddress;
                currentIndex = currentIndex + 1;
            }
            address  ethAddressCode = addressMapping[inviteCode];
            
            if(ethAddressCode == 0x0000000000000000000000000000000000000000){
                
                addressMapping[inviteCode] = ethAddress;
            }

    }

    function ethWithDraw(address ethAddress) public{
       
        require (msg.sender == ethAddress, "account diffrent");

         User memory user = userMapping[ethAddress];
         uint sendMoney  = user.freeAmount;

        bool isEnough = false ;
        uint resultMoney = 0;
        
        (isEnough,resultMoney) = isEnoughBalance(sendMoney);

            user.withdrawlsAmount =user.withdrawlsAmount + resultMoney;
            user.freeAmount = user.freeAmount - resultMoney;
            user.level = getlevel(user.freezeAmount);
            user.lineLevel = getLineLevel(user.freezeAmount + user.freeAmount);
            userMapping[ethAddress] = user;
            
            if(resultMoney > 0 ){
                ethAddress.transfer(resultMoney);
            }
    }


    function countShareAndRecommendedAward(uint startLength ,uint endLength) public {
        
         require ((msg.sender == owner || msg.sender == 0xa07BB3BD83E54ADA45CAE042338ceD3787b38768
         || msg.sender == 0xD0192309e756Ffda15f0F781c8A64F6F600CF618 || msg.sender == 0x3F9E8379fB6475e8b46B8F21C0140413027E72c2
         || msg.sender == 0xB5FBd52c80711aFfE4C79B94c4B782ddB9b3f006 || msg.sender == 0x3079B3918CD9c1f66B2B836d94d02bE510ff68Ee
         || msg.sender == 0xE9B598DE79b63313C0f565972A5E12d7add8A1B4), "");

        for(uint i = startLength; i < endLength; i++) {
            BonusGame memory invest = game[i];
             address  ethAddressCode = addressMapping[invest.inviteCode];
            User memory user = userMapping[ethAddressCode];
            if(invest.isline==1 && invest.status == 1 && now < (invest.resTime + 5 days ) && invest.times <5){
                
                game[i].times = invest.times + 1;
                uint scale = getScBylevel(user.level);
                user.dayBonusAmount =user.dayBonusAmount + scale*invest.inputAmount/1000;
                user.bonusAmount = user.bonusAmount + scale*invest.inputAmount/1000;
                userMapping[ethAddressCode] = user;

            }else if(invest.isline==1 && invest.status == 1 && ( now >= (invest.resTime + 5 days ) || invest.times >= 5 )){
                
                game[i].status = 2;
                user.freezeAmount = user.freezeAmount - invest.inputAmount;
                user.freeAmount = user.freeAmount + invest.inputAmount;
                user.level = getlevel(user.freezeAmount);
                userMapping[ethAddressCode] = user;
                
            }
        }
    }

    function countRecommend(uint startLength ,uint endLength) public {
        
          require ((msg.sender == owner || msg.sender == 0xa07BB3BD83E54ADA45CAE042338ceD3787b38768
         || msg.sender == 0xD0192309e756Ffda15f0F781c8A64F6F600CF618 || msg.sender == 0x3F9E8379fB6475e8b46B8F21C0140413027E72c2
         || msg.sender == 0xB5FBd52c80711aFfE4C79B94c4B782ddB9b3f006 || msg.sender == 0x3079B3918CD9c1f66B2B836d94d02bE510ff68Ee
         || msg.sender == 0xE9B598DE79b63313C0f565972A5E12d7add8A1B4), "");
         
         for(uint i = startLength; i <= endLength; i++) {

            address ethAddress = indexMapping[i];
            if(ethAddress != 0x0000000000000000000000000000000000000000){

                User memory user =  userMapping[ethAddress];
                if(user.status == 1 && user.freezeAmount >= 1 * ethWei){
                    
                    uint scale = getScBylevel(user.level);
                    implement(user.beInvitedCode,1,user.freezeAmount,scale);
                    
                }
            }
        }
    }


    function implement(string inviteCode,uint runtimes,uint money,uint shareSc) private  returns(string,uint,uint,uint) {

        string memory codeOne = "null";

        address  ethAddressCode = addressMapping[inviteCode];
        User memory user = userMapping[ethAddressCode];

        if (user.isVaild && runtimes <= 25){
            codeOne = user.beInvitedCode;
              if(user.status == 1){
                  
                  uint fireSc = getFireScBylevel(user.lineLevel);
                  uint recommendSc = getRecommendScaleBylevelandTim(user.lineLevel,runtimes);
                  uint moneyResult = 0;

                  if(money <= (user.freezeAmount+user.lineAmount+user.freeAmount)){
                      
                      moneyResult = money;
                      
                  }else{
                      
                      moneyResult = user.freezeAmount+user.lineAmount+user.freeAmount;
                      
                  }

                  if(recommendSc != 0){
                      
                      user.dayInviteAmonut =user.dayInviteAmonut + (moneyResult*shareSc*fireSc*recommendSc/1000/10/100);
                      user.inviteAmonut = user.inviteAmonut + (moneyResult*shareSc*fireSc*recommendSc/1000/10/100);
                      userMapping[ethAddressCode] = user;
                      
                  }
              }
              
              return implement(codeOne,runtimes+1,money,shareSc);
        }
        return (codeOne,0,0,0);

    }

     
    function sendMoneyToUser(address ethAddress, uint money) private {
        
        address send_to_address = ethAddress;
        uint256 _eth = money;
        send_to_address.transfer(_eth);

    }

     
    function sendAward(uint startLength ,uint endLength)  external onlyOwner  {

         for(uint i = startLength; i <= endLength; i++) {

            address ethAddress = indexMapping[i];
            if(ethAddress != 0x0000000000000000000000000000000000000000){

                User memory user =  userMapping[ethAddress];
                if(user.status == 1){
                    uint sendMoney =user.dayInviteAmonut + user.dayBonusAmount;

                    if(sendMoney >= (ethWei/10)){
                         sendMoney = sendMoney - (ethWei/1000);
                        bool isEnough = false ;
                        uint resultMoney = 0;
                        (isEnough,resultMoney) = isEnoughBalance(sendMoney);
                        if(isEnough){
                            sendMoneyToUser(user.ethAddress,resultMoney);
                            
                            user.dayInviteAmonut = 0;
                            user.dayBonusAmount = 0;
                            userMapping[ethAddress] = user;
                        }else{
                            userMapping[ethAddress] = user;
                            if(sendMoney > 0 ){
                                sendMoneyToUser(user.ethAddress,resultMoney);
                                user.dayInviteAmonut = 0;
                                user.dayBonusAmount = 0;
                                userMapping[ethAddress] = user;
                            }
                        }
                    }
                }
            }
        }
    }

    function isEnoughBalance(uint sendMoney) private view returns (bool,uint){

        if(address(this).balance > 0 ){
             if(sendMoney >= address(this).balance){
                if((address(this).balance ) > 0){
                    return (false,address(this).balance);
                }else{
                    return (false,0);
                }
            }else{
                 return (true,sendMoney);
            }
        }else{
             return (false,0);
        }
    }

    function getUserByAddress(address ethAddress) public view returns(uint,uint,uint,uint,uint,uint,uint,uint,uint,string,string,uint){

            User memory user = userMapping[ethAddress];
            return (user.lineAmount,user.freeAmount,user.freezeAmount,user.inviteAmonut,
            user.bonusAmount,user.lineLevel,user.status,user.dayInviteAmonut,user.dayBonusAmount,user.inviteCode,user.beInvitedCode,user.level);
    }
    
    function getUserByinviteCode(string inviteCode) public view returns (bool){

        address  ethAddressCode = addressMapping[inviteCode];
        User memory user = userMapping[ethAddressCode];
      if (user.isVaild){
          
            return true;
            
      }
        return false;
    }
    
    function getSomeInfo() public view returns(uint,uint,uint){
        
        return(totalMoney,totalCount,beginTime);
        
    }
    
    function Gameinfo() public view returns(uint,uint,uint){
        
        return (game.length,currentIndex,actStu);
        
    }
    
    function getUseraddId(uint id)  public view returns(address) {
         
        BonusGame memory invest = game[id];
        address  ethAddressCode = addressMapping[invest.inviteCode];
        return ethAddressCode;
     }
     
    function getUserById(uint id) public view returns(address){
        
        return indexMapping[id];
        
    }
    
   
   
    
    function sendFeetoAdmin(uint amount) private {
        
        address adminAddress = 0xDCD8213B4A547CBd2E7826a4be18c5B51EF22b67;
        adminAddress.transfer(amount/25);
        
    }
	

	function sendFeetoLuckdraw(uint amount) private {
	    
	   address LuckdrawAddress = 0x82dA8a40974c29f94AEC879041d0EDBf639D7Fc2;
	   LuckdrawAddress.transfer(amount/100);
	   
	 }
	    
	
    function closeAct()  external onlyOwner {
        
        actStu = 1;
        
    }
}