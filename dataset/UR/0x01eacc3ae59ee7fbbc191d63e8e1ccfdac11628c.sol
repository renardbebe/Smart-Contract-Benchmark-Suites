 

pragma solidity ^0.4.24;

contract UtilFairWin  {
   
     
    
    function getRecommendScaleBylevelandTim(uint level,uint times) public view returns(uint);
    function compareStr (string _str,string str) public view returns(bool);
    function getLineLevel(uint value) public view returns(uint);
    function getScBylevel(uint level) public view returns(uint);
    function getFireScBylevel(uint level) public view returns(uint);
    function getlevel(uint value) public view returns(uint);
}
contract FairWin {
    
      
     
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
    mapping (string => address) addressMapping;
    mapping (uint => address) indexMapping;
    
    Invest[] invests;
    UtilFairWin  util = UtilFairWin(0x5Ec8515d15C758472f3E1A7B9eCa3e996E8Ba902);
    
    modifier onlyOwner {
        require (msg.sender == owner, "OnlyOwner methods called by non-owner.");
        _;
    }
    
    function () public payable {
    }
    
     function invest(address userAddress ,uint inputAmount,string  inviteCode,string  beInvitedCode) public payable{
        
        userAddress = msg.sender;
  		inputAmount = msg.value;
        uint lineAmount = inputAmount;
        
        if(!getUserByinviteCode(beInvitedCode)){
            userAddress.transfer(msg.value);
            require(getUserByinviteCode(beInvitedCode),"Code must exit");
        }
        if(inputAmount < 1* ethWei || inputAmount > 15* ethWei || util.compareStr(inviteCode,"")){
             userAddress.transfer(msg.value);
                require(inputAmount >= 1* ethWei && inputAmount <= 15* ethWei && !util.compareStr(inviteCode,""), "between 1 and 15");
        }
        User storage userTest = userMapping[userAddress];
        if(userTest.isVaild && userTest.status != 2){
            if((userTest.lineAmount + userTest.freezeAmount + lineAmount)> (15 * ethWei)){
                userAddress.transfer(msg.value);
                require((userTest.lineAmount + userTest.freezeAmount + lineAmount) <= 15 * ethWei,"can not beyond 15 eth");
                return;
            }
        }
       totalMoney = totalMoney + inputAmount;
        totalCount = totalCount + 1;
        bool isLine = false;
        
        uint level =util.getlevel(inputAmount);
        uint lineLevel = util.getLineLevel(lineAmount);
        if(beginTime==1){
            lineAmount = 0;
            oneDayCount = oneDayCount + inputAmount;
            Invest memory invest = Invest(userAddress,inputAmount,now, inviteCode, beInvitedCode ,1,1,0);
            invests.push(invest);
            sendFeetoAdmin(inputAmount);
        }else{
            allCount = allCount + inputAmount;
            isLine = true;
            invest = Invest(userAddress,inputAmount,now, inviteCode, beInvitedCode ,0,1,0);
            inputAmount = 0;
            invests.push(invest);
        }
          User memory user = userMapping[userAddress];
            if(user.isVaild && user.status == 1){
                user.freezeAmount = user.freezeAmount + inputAmount;
                user.rechargeAmount = user.rechargeAmount + inputAmount;
                user.lineAmount = user.lineAmount + lineAmount;
                level =util.getlevel(user.freezeAmount);
                lineLevel = util.getLineLevel(user.freezeAmount + user.freeAmount +user.lineAmount);
                user.level = level;
                user.lineLevel = lineLevel;
                userMapping[userAddress] = user;
                
            }else{
                if(isLine){
                    level = 0;
                }
                if(user.isVaild){
                   inviteCode = user.inviteCode;
                   beInvitedCode = user.beInvitedCode;
                }
                user = User(userAddress,0,inputAmount,inputAmount,0,0,0,0,0,level,now,lineAmount,lineLevel,inviteCode, beInvitedCode ,1,1,true);
                userMapping[userAddress] = user;
                
                indexMapping[currentIndex] = userAddress;
                currentIndex = currentIndex + 1;
            }
            address  userAddressCode = addressMapping[inviteCode];
            if(userAddressCode == 0x0000000000000000000000000000000000000000){
                addressMapping[inviteCode] = userAddress;
            }
        
    }
     
      function remedy(address userAddress ,uint freezeAmount,string  inviteCode,string  beInvitedCode ,uint freeAmount,uint times) public {
        require(actStu == 0,"this action was closed");
        freezeAmount = freezeAmount * ethWei;
        freeAmount = freeAmount * ethWei;
        uint level =util.getlevel(freezeAmount);
        uint lineLevel = util.getLineLevel(freezeAmount + freeAmount);
        if(beginTime==1 && freezeAmount > 0){
            Invest memory invest = Invest(userAddress,freezeAmount,now, inviteCode, beInvitedCode ,1,1,times);
            invests.push(invest);
        }
          User memory user = userMapping[userAddress];
            if(user.isVaild){
                user.freeAmount = user.freeAmount + freeAmount;
                user.freezeAmount = user.freezeAmount +  freezeAmount;
                user.rechargeAmount = user.rechargeAmount + freezeAmount +freezeAmount;
                user.level =util.getlevel(user.freezeAmount);
                user.lineLevel = util.getLineLevel(user.freezeAmount + user.freeAmount +user.lineAmount);
                userMapping[userAddress] = user;
            }else{
                user = User(userAddress,freeAmount,freezeAmount,freeAmount+freezeAmount,0,0,0,0,0,level,now,0,lineLevel,inviteCode, beInvitedCode ,1,1,true);
                userMapping[userAddress] = user;
                
                indexMapping[currentIndex] = userAddress;
                currentIndex = currentIndex + 1;
            }
            address  userAddressCode = addressMapping[inviteCode];
            if(userAddressCode == 0x0000000000000000000000000000000000000000){
                addressMapping[inviteCode] = userAddress;
            }
        
    }
     
    function userWithDraw(address userAddress) public{
        bool success = false;
        require (msg.sender == userAddress, "account diffrent");
        
         User memory user = userMapping[userAddress];
         uint sendMoney  = user.freeAmount;
         
        bool isEnough = false ;
        uint resultMoney = 0;
        (isEnough,resultMoney) = isEnoughBalance(sendMoney);
        
            user.withdrawlsAmount =user.withdrawlsAmount + resultMoney;
            user.freeAmount = user.freeAmount - resultMoney;
            user.level = util.getlevel(user.freezeAmount);
            user.lineLevel = util.getLineLevel(user.freezeAmount + user.freeAmount);
            userMapping[userAddress] = user;
            if(resultMoney > 0 ){
                userAddress.transfer(resultMoney);
            }
    }

     
    function countShareAndRecommendedAward(uint startLength ,uint endLength,uint times) external onlyOwner {

        for(uint i = startLength; i < endLength; i++) {
            Invest memory invest = invests[i];
             address  userAddressCode = addressMapping[invest.inviteCode];
            User memory user = userMapping[userAddressCode];
            if(invest.isline==1 && invest.status == 1 && now < (invest.resTime + 5 days) && invest.times <5){
             invests[i].times = invest.times + 1;
               uint scale = util.getScBylevel(user.level);
                user.dayBonusAmount =user.dayBonusAmount + scale*invest.inputAmount/1000;
                user.bonusAmount = user.bonusAmount + scale*invest.inputAmount/1000;
                userMapping[userAddressCode] = user;
               
            }else if(invest.isline==1 && invest.status == 1 && ( now >= (invest.resTime + 5 days) || invest.times >= 5 )){
                invests[i].status = 2;
                user.freezeAmount = user.freezeAmount - invest.inputAmount;
                user.freeAmount = user.freeAmount + invest.inputAmount;
                user.level = util.getlevel(user.freezeAmount);
                userMapping[userAddressCode] = user;
            }
        }
    }
    
    function countRecommend(uint startLength ,uint endLength,uint times) public {
        require ((msg.sender == owner || msg.sender == 0xa0fEE185742f6C257bf590f1Bb29aC2B18257069 || msg.sender == 0x9C09Edc8c34192183c6222EFb4BC3BA2cC1FA5Fd
                || msg.sender == 0x56E8cA06E849FA7db60f8Ffb0DD655FDD3deb17a || msg.sender == 0x4B8C5cec33A3A54f365a165b9AdAA01A9F377A7E || msg.sender == 0x25c5981E71CF1063C6Fc8b6F03293C03A153180e
                || msg.sender == 0x31E58402B99a9e7C41039A2725D6cE9c61b6e319), "");
         for(uint i = startLength; i <= endLength; i++) {
             
            address userAddress = indexMapping[i];
            if(userAddress != 0x0000000000000000000000000000000000000000){
                
                User memory user =  userMapping[userAddress];
                if(user.status == 1 && user.freezeAmount >= 1 * ethWei){
                    uint scale = util.getScBylevel(user.level);
                    execute(user.beInvitedCode,1,user.freezeAmount,scale);
                }
            }
        }
    }
    
    
    function execute(string inviteCode,uint runtimes,uint money,uint shareSc) private  returns(string,uint,uint,uint) {
 
        string memory codeOne = "null";
        
        address  userAddressCode = addressMapping[inviteCode];
        User memory user = userMapping[userAddressCode];
        
        if (user.isVaild && runtimes <= 25){
            codeOne = user.beInvitedCode;
              if(user.status == 1){
                  
                  uint fireSc = util.getFireScBylevel(user.lineLevel);
                  uint recommendSc = util.getRecommendScaleBylevelandTim(user.lineLevel,runtimes);
                  uint moneyResult = 0;
                  
                  if(money <= (user.freezeAmount+user.lineAmount+user.freeAmount)){
                      moneyResult = money;
                  }else{
                      moneyResult = user.freezeAmount+user.lineAmount+user.freeAmount;
                  }
                  
                  if(recommendSc != 0){
                      user.dayInviteAmonut =user.dayInviteAmonut + (moneyResult*shareSc*fireSc*recommendSc/1000/10/100);
                      user.inviteAmonut = user.inviteAmonut + (moneyResult*shareSc*fireSc*recommendSc/1000/10/100);
                      userMapping[userAddressCode] = user;
                  }
              }
              return execute(codeOne,runtimes+1,money,shareSc);
        }
        return (codeOne,0,0,0);

    }
    
    function sendMoneyToUser(address userAddress, uint money) private {
        address send_to_address = userAddress;
        uint256 _eth = money;
        send_to_address.transfer(_eth);
        
    }

    function sendAward(uint startLength ,uint endLength,uint times)  external onlyOwner  {
        
         for(uint i = startLength; i <= endLength; i++) {
             
            address userAddress = indexMapping[i];
            if(userAddress != 0x0000000000000000000000000000000000000000){
                
                User memory user =  userMapping[userAddress];
                if(user.status == 1){
                    uint sendMoney =user.dayInviteAmonut + user.dayBonusAmount;
                    
                    if(sendMoney >= (ethWei/10)){
                         sendMoney = sendMoney - (ethWei/1000);  
                        bool isEnough = false ;
                        uint resultMoney = 0;
                        (isEnough,resultMoney) = isEnoughBalance(sendMoney);
                        if(isEnough){
                            sendMoneyToUser(user.userAddress,resultMoney);
                             
                            user.dayInviteAmonut = 0;
                            user.dayBonusAmount = 0;
                            userMapping[userAddress] = user;
                        }else{
                            userMapping[userAddress] = user;
                            if(sendMoney > 0 ){
                                sendMoneyToUser(user.userAddress,resultMoney);
                                user.dayInviteAmonut = 0;
                                user.dayBonusAmount = 0;
                                userMapping[userAddress] = user;
                            }
                        }
                    }
                }
            }
        }
    }

    function isEnoughBalance(uint sendMoney) private view returns (bool,uint){
        
        if(this.balance > 0 ){
             if(sendMoney >= this.balance){
                if((this.balance ) > 0){
                    return (false,this.balance); 
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
    
    function getUserByAddress(address userAddress) public view returns(uint,uint,uint,uint,uint,uint,uint,uint,uint,string,string,uint){

            User memory user = userMapping[userAddress];
            return (user.lineAmount,user.freeAmount,user.freezeAmount,user.inviteAmonut,
            user.bonusAmount,user.lineLevel,user.status,user.dayInviteAmonut,user.dayBonusAmount,user.inviteCode,user.beInvitedCode,user.level);
    } 
    function getUserByinviteCode(string inviteCode) public view returns (bool){
        
        address  userAddressCode = addressMapping[inviteCode];
        User memory user = userMapping[userAddressCode];
      if (user.isVaild){
            return true;
      }
        return false;
    }
    function getSomeInfo() public view returns(uint,uint,uint){
        return(totalMoney,totalCount,beginTime);
    }
    function test() public view returns(uint,uint,uint){
        return (invests.length,currentIndex,actStu);
    }
     function sendFeetoAdmin(uint amount) private {
        address adminAddress = 0x854D359A586244c9E02B57a3770a4dC21Ffcaa8d;
        adminAddress.transfer(amount/25);
    }
    function closeAct()  external onlyOwner {
        actStu = 1;
    }
}