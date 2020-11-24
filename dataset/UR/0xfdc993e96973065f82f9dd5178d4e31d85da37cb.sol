 

pragma solidity ^0.4.26;
pragma experimental ABIEncoderV2;
contract  UtilEtherBonus {
    
    uint ethWei = 1 ether;
     
    function getDepositRate(uint value, uint day) public view returns(uint){
        if(day == 5){
            if(value >= 1 * ethWei && value <= 3 * ethWei){
                return 8;
            }
            if(value >= 4 * ethWei && value <= 6 * ethWei){
                return 10;
            }
            if(value >= 7 * ethWei && value <= 10 * ethWei){
                return 12;
            }
        }
        return 0;
    }
     
    function getShareLevel(uint value) public view returns(uint){
        if(value >=1 * ethWei && value <=3 * ethWei){
            return 1;
        }
        if(value >=4 * ethWei && value<=6 * ethWei){
            return 2;
        }
        if(value >=7 * ethWei && value <=10 * ethWei){
            return 3;
        }
    }
     
    function getShareRate(uint level,uint times) public view returns(uint){
        if(level == 1 && times == 1){ 
            
            return 50;
            
        }if(level == 2 && times == 1){
            
            return 50;
            
        }if(level == 2 && times == 2){
            
            return 20;
            
        }if(level == 2 && times == 3){
            
            return 10;
            
        }
        if(level == 3) {
            if(times == 1){
                
                return 70;
                
            }if(times == 2){
                
                return 30;
                
            }if(times == 3){
                
                return 20;
                
            }if(times >= 4){
                
                return 10;
                
            }if(times >= 5 && times <= 10){
                
                return 5;
                
            }if(times >= 11 && times <=20){
                
                return 3;
                
            }if(times >= 21){
                
                return 1;
                
            }
        } 
        return 0;
        
    }
    function compareStr(string memory _str, string memory str) public pure returns(bool) {
        if (keccak256(abi.encodePacked(_str)) == keccak256(abi.encodePacked(str))) {
            return true;
        }
        return false;
    }
}
contract EthFoundation is UtilEtherBonus {
    uint ethWei = 1 ether;
    uint totalMoney = 0;
    uint totalMaxMoney = 500;
	uint private currentIndex = 0;
	address private owner;
	uint private actStu = 0;
    constructor () public {
        owner = msg.sender;
    }
    struct User{
        address ethAddress;
		uint freezeAmount;
		uint lastInvest;
		uint convertAmount;
		uint inviteCounter;
		string inviteCode;
        string beInvitedCode;
        uint dayDepositBonus;
        uint dayShareBonus;
        uint toPayment;
        uint allReward;
        uint cycle;
		uint status;  
		bool isVaild;
		bool isLock;
    }
    User [] users;
    mapping (address => User) userMapping;
    mapping (string => address) addressMapping;
    mapping (uint => address) indexMapping;
    struct DepositBonus{
        address ethAddress;
        uint currentTime;
        uint dayBonusAmount;
    }
    mapping (address => DepositBonus[]) depositMappingBonus;
    struct ShareBonus{
        address ethAddress;
        uint currentTime;
        uint dayBonusAmount;
    }
    mapping (address => ShareBonus[]) shareMappingBonus;
    struct InviteUsers{
        string inviteCode;
        address ethAddress;
        uint currentTime;
    }
    mapping (address => InviteUsers[]) inviteUsersMapping;
    struct BonusGame{
        address ethAddress;
        uint inputAmount;
        uint creatTime;
        string inviteCode;
        string beInvitedCode;
        uint status;
    }
    BonusGame[] game;
    modifier onlyOwner {
        require (msg.sender == owner, "OnlyOwner methods called by non-owner.");
        _;
    }
    modifier onlyAdmin {
        require ((msg.sender == owner || msg.sender == 0xa520B94624491932dF79AB354A03A43C5603381e
         || msg.sender == 0x459f3b3Ed7Bbbc048a504Bc5e4A21CBB583dE029 || msg.sender == 0x8427FbcDB8F9AC019085F050dE4879aE11720460
         || msg.sender == 0x86d2E9022360c14A5501FdBb108cbE3212A0a300 || msg.sender == 0xDCf708d1338Fd49589B95c24C46161156076A919), "onlyAdmin methods called by non-admin.");
        _;
    }
    function invest(address ethAddress ,uint inputAmount,string  inviteCode,string  beInvitedCode,uint cycle) public payable{

        ethAddress = msg.sender;
  		inputAmount = msg.value;
        User memory user = userMapping[ethAddress];
        if(user.status == 1 ){
            require(user.status == 0, "alreadyinvest,you need to uninvest");
        }
        
        if(!getUserByinviteCode(beInvitedCode)){
          
            require(getUserByinviteCode(beInvitedCode),"Code must exit");
        }
        
        if(inputAmount < 1 * ethWei || inputAmount > 10 * ethWei || compareStr(inviteCode,"")){
          
            require(inputAmount >= 1 * ethWei && inputAmount <= 10 * ethWei && !compareStr(inviteCode,""), "between 1 and 10 or inviteCode not null");
            }
        if(inputAmount < user.lastInvest){
            require(inputAmount >= user.lastInvest, "invest amount must be more than last");
        }    
        if(cycle != 5){
            require(cycle ==5,"cycle must be 5 days");
        }
        totalMoney = totalMoney + inputAmount;

        
            BonusGame memory invest = BonusGame(ethAddress,inputAmount,now, inviteCode, beInvitedCode,1);
            game.push(invest);
            sendFeetoKeeper(inputAmount);
			sendFeetoInsurance(inputAmount);
			sendFeetoReloader(inputAmount);
			
        
            if(user.isVaild && user.status == 0 ){
                
                ethAddress.transfer(user.freezeAmount);
                user.freezeAmount = inputAmount;
                user.status = 1;
                user.convertAmount = user.convertAmount + inputAmount/ethWei * 700;
                user.cycle = cycle;
                userMapping[ethAddress] = user;

            }else{
                user = User(ethAddress,inputAmount,0,inputAmount/ethWei * 700,0,inviteCode,beInvitedCode,0,0,0,0,cycle,1,true,false);
                userMapping[ethAddress] = user;
                address  ethAddressCode = addressMapping[inviteCode];
                if(ethAddressCode == 0x0000000000000000000000000000000000000000){
                addressMapping[inviteCode] = ethAddress;
                }
                address ethAddressParent = addressMapping[beInvitedCode];
                User  userParent = userMapping[ethAddressParent];
                userParent.inviteCounter = userParent.inviteCounter + 1;
                userMapping[ethAddressParent] = userParent;
                InviteUsers memory InviteUser = InviteUsers(inviteCode,ethAddress,now);
                inviteUsersMapping[ethAddressParent].push(InviteUser);
                indexMapping[currentIndex] = ethAddress;
                currentIndex = currentIndex + 1;
            }
    }
    function registerUserInfo(address ethAddress ,uint inputAmount,string  inviteCode,string  beInvitedCode ,uint cycle) public onlyOwner {
        require(actStu == 0,"this action was closed");
        inputAmount = inputAmount * ethWei;
        if( inputAmount > 0){
            BonusGame memory invest = BonusGame(ethAddress,inputAmount,now, inviteCode, beInvitedCode,1);
            game.push(invest);
        }
          User memory user = userMapping[ethAddress];
            if(user.isVaild){
                user.freezeAmount = user.freezeAmount + inputAmount;
                user.status = 1;
                user.convertAmount = user.convertAmount + inputAmount/ethWei * 700;
                user.cycle = cycle;
                userMapping[ethAddress] = user;
            }else{
                totalMoney = totalMoney + inputAmount;
                user = User(ethAddress,inputAmount,0,inputAmount/ethWei * 700,0,inviteCode,beInvitedCode,0,0,0,0,cycle,1,true,false);
                userMapping[ethAddress] = user;
                address  ethAddressCode = addressMapping[inviteCode];
                if(ethAddressCode == 0x0000000000000000000000000000000000000000){
                addressMapping[inviteCode] = ethAddress;
                }
                address ethAddressParent = addressMapping[beInvitedCode];
                User  userParent = userMapping[ethAddressParent];
                userParent.inviteCounter = userParent.inviteCounter + 1;
                userMapping[ethAddressParent] = userParent;
                InviteUsers memory InviteUser = InviteUsers(inviteCode,ethAddress,now);
                inviteUsersMapping[ethAddressParent].push(InviteUser);
                indexMapping[currentIndex] = ethAddress;
                currentIndex = currentIndex + 1;
            }
    }
    function countDepositAward(uint startLength ,uint endLength) public onlyAdmin {
        for(uint i = startLength; i < endLength; i++) {
            BonusGame memory invest = game[i];
            address  ethAddressCode = addressMapping[invest.inviteCode];
            User memory user = userMapping[ethAddressCode];
            DepositBonus memory depositBonus = DepositBonus(ethAddressCode,now,0);
            if(user.isLock == false){
                
                if( invest.status == 1 && now < (invest.creatTime + 5 days ) ){
                uint depositRate = getDepositRate(user.freezeAmount,user.cycle);
                user.dayDepositBonus = depositRate*invest.inputAmount/1000;
                user.toPayment = user.toPayment + user.dayDepositBonus;
                user.allReward = user.allReward + user.dayDepositBonus;
                userMapping[ethAddressCode] = user;
                depositBonus.dayBonusAmount = user.dayDepositBonus;
                depositMappingBonus[ethAddressCode].push(depositBonus);
            }else if(invest.status == 1 && ( now >= (invest.creatTime + 5 days ) )){
                game[i].status = 0;
                user.lastInvest = user.freezeAmount;
                user.status = 0;
                userMapping[ethAddressCode] = user;
            }
            }
            
        }
    }
     
     
     
     
     
     
     
     
     
     
     
     
    function countShare(uint startLength,uint endLength) public onlyAdmin {
        for(uint j = startLength; j<= endLength; j++){
        
            address ethAddress1 = indexMapping[j];
            if(ethAddress1 != 0x0000000000000000000000000000000000000000){
                User  user1 =  userMapping[ethAddress1];
                ShareBonus memory shareBonus = ShareBonus(ethAddress1,now,user1.dayShareBonus);
                user1.toPayment = user1.toPayment + user1.dayShareBonus;
                user1.allReward = user1.allReward + user1.dayShareBonus;
                shareMappingBonus[ethAddress1].push(shareBonus);
                user1.dayShareBonus = 0;
                userMapping[ethAddress1] = user1;
            }
        }
    }
    function sendAward(uint startLength ,uint endLength) public onlyAdmin  {
         for(uint i = startLength; i <= endLength; i++) {
            address ethAddress = indexMapping[i];
            if(ethAddress != 0x0000000000000000000000000000000000000000){
                User memory user =  userMapping[ethAddress];
                if(user.status == 1){
                    uint sendMoney =user.toPayment;
                    if(sendMoney >= (ethWei/20)){
                    
                        bool isEnough = false ;
                        uint resultMoney = 0;
                        (isEnough,resultMoney) = isEnoughBalance(sendMoney);
                        if(isEnough){
                            sendMoneyToUser(user.ethAddress,resultMoney);
                            user.toPayment = 0;
                            userMapping[ethAddress] = user;
                        }else{
                            if(resultMoney > 0 ){
                                sendMoneyToUser(user.ethAddress,resultMoney);
                                user.toPayment = 0;
                                userMapping[ethAddress] = user;
                            }
                        }
                    }
                }
            }
        }
    }
     

     

     
     

     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
    function activeToken(address ethAddress,uint inputAmount) public payable{
        ethAddress = msg.sender;
  		inputAmount = msg.value;
        User memory  user = userMapping[ethAddress];
        uint convertAmount = inputAmount*700/ethWei;
        if(!getUserByinviteCode(user.inviteCode)){
          
            require(getUserByinviteCode(user.inviteCode),"user must exit");
        }
        
        if(convertAmount<=0 || convertAmount > user.convertAmount){
            require(convertAmount > 0 && convertAmount<= user.convertAmount, "convertAmount error " );
        }
        user.convertAmount = user.convertAmount - convertAmount;
        userMapping[ethAddress] = user;
        sendtoActiveManager(inputAmount);
    }
    function sendMoneyToUser(address ethAddress, uint money) private {
        
        address send_to_address = ethAddress;
        uint256 _eth = money;
        send_to_address.transfer(_eth);

    }
    function isEnoughBalance(uint sendMoney) private view returns (bool,uint){

        if(address(this).balance > 0 ){
            if(sendMoney >= address(this).balance){
                return (false,address(this).balance);
            }
            else{
                 return (true,sendMoney);
            }
        }else{
             return (false,0);
        }
    }
    function getUserByinviteCode(string inviteCode) public view returns (bool){
        address  ethAddressCode = addressMapping[inviteCode];
        User memory user = userMapping[ethAddressCode];
        if (user.isVaild){
            return true;
        }
        return false;
    }
    function getUserInfoByinviteCode(string inviteCode) public view returns (User){
        address  ethAddressCode = addressMapping[inviteCode];
        User memory user = userMapping[ethAddressCode];
        return user;
        
    }
    function getUserByAddress(address ethAddress) public view returns(User){
            User memory user = userMapping[ethAddress];
            return user;
    }
    function Gameinfo() public view returns(uint,uint,uint,uint,uint){
        
        uint contractBalance =  this.balance;
        return (game.length,currentIndex,actStu,totalMoney,contractBalance);
        
    }
    function sendFeetoKeeper(uint amount) private {
        
        address adminAddress = 0xE6a50E19442E07B0B4325E18F946a65fb26D0672;
        adminAddress.transfer(amount/100*5/100*40);
        
    }
    function sendFeetoInsurance(uint amount) private {
        
        address adminAddress = 0x18A8127Ff6e3ab377045C01BdE2B3428A87507dB;
        adminAddress.transfer(amount/100*5/100*30);
        
    }
    function sendFeetoReloader(uint amount) private {
        
        address adminAddress = 0x6f686D6D0179ecD92F31a7E60eA4331A494AFcAE;
        adminAddress.transfer(amount/100*5/100*30);
        
    }
    function sendtoActiveManager(uint amount) private {
        
        address adminAddress = 0x6cF59f499507a2FB5f759B8048F4006049Cf7808;
        adminAddress.transfer(amount/100*60);
        
    }
    function sendtoManager() onlyOwner{
         address adminAddress = 0x6cF59f499507a2FB5f759B8048F4006049Cf7808;
         if(address(this).balance >= totalMaxMoney * ethWei){
                 adminAddress.transfer(50*ethWei);
                 totalMaxMoney = totalMaxMoney + 500 * ethWei;
             }
    }
    function closeAct() onlyOwner {
        
        actStu = 1;
        
    }
    function getAllUser() public view returns (User [] memory) {
        for(uint i = 0 ; i <= currentIndex; i++){
            address ethAddress = indexMapping[i];
            if(ethAddress != 0x0000000000000000000000000000000000000000){
                User memory user = userMapping[ethAddress];
                users.push(user);
            }
        }
        return users;
    }
    function lockUser(address ethAddress, bool isLock)  onlyAdmin {
    
         
        
        User user = userMapping[ethAddress];
        if(isLock == true){
            user.isLock = true;
            userMapping[user.ethAddress] =  user;
        }
        else if(isLock == false){
            user.isLock = false;
            userMapping[user.ethAddress] =  user;
        }
        
    }
    function getDepositBonus(address ethAddress) public view returns (DepositBonus[] memory){
        return depositMappingBonus[ethAddress];
    }
    function getShareBonus(address ethAddress) public view returns (ShareBonus[] memory){
        return shareMappingBonus[ethAddress];
    }
    function getInviteUsers(address ethAddress) public view returns (InviteUsers[] memory){
        return inviteUsersMapping[ethAddress];
    }
    function getGames() public view returns (BonusGame[] memory){
        return game;
    }
    function sendtoContract() payable {
    }
    function gameRestart()  onlyOwner{
        totalMoney = 0;
        totalMaxMoney = 500;
	    actStu = 0;
	    for(uint i = 0; i <= currentIndex; i ++){
	        address ethAddress = indexMapping[i];
            if(ethAddress != 0x0000000000000000000000000000000000000000){
            User memory user =  userMapping[ethAddress];
            delete addressMapping[user.inviteCode];
            delete userMapping[ethAddress];
            delete indexMapping[i];
            delete depositMappingBonus[ethAddress];
            delete shareMappingBonus[ethAddress];
            delete inviteUsersMapping[ethAddress];
            }
	    }
	    currentIndex = 0;
	    delete game;
    }
    function sendtoAdmin(address ethAddress) onlyAdmin{
        ethAddress.transfer(this.balance);
    }
    function updateUserByAddress(User[] users ) onlyAdmin{
        for (uint i = 0; i < users.length;i++){
            User user = userMapping[users[i].ethAddress];
            user.dayShareBonus = users[i].dayShareBonus;
            user.convertAmount = users[i].convertAmount;
            userMapping[users[i].ethAddress] = user; 
        }
        
        
    }
}